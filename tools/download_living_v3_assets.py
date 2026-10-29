"""Download only jobs already confirmed completed through PixelLab MCP get_image."""
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import re
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    ledger = json.loads((ROOT / "docs/world/living_v3/pixellab_jobs.json").read_text(encoding="utf-8-sig"))
    tasks = []
    for job in ledger["jobs"]:
        status = "\n".join(item.get("text", "") for item in job.get("statusResult", {}).get("content", []))
        if "status: completed" not in status:
            continue
        # The documented download URL is provided by the completed MCP receipt.
        url = re.search(r"download: (https://\S+)", status).group(1).split("?")[0]
        species, _, animation = job["name"].partition("/")
        category = "wildlife" if species in ("squirrel", "bird") else "slimes"
        source = ROOT / f"assets/{category}/living_v3/{species}/source"
        source.mkdir(parents=True, exist_ok=True)
        (source / ".gdignore").touch()
        if job["kind"] == "base":
            tasks.append((url, source / "base.png"))
        else:
            frames = int(re.search(r"frames: (\d+)", status).group(1))
            folder = source / "supplemental" / animation if species == "bolhinha" else source / animation
            folder.mkdir(parents=True, exist_ok=True)
            tasks.extend((f"{url}?index={i}", folder / f"frame_{i:03}.png") for i in range(frames))
    def download(task):
        url, target = task
        if target.exists():
            return "existing"
        data = urlopen(url, timeout=60).read()
        assert data[:8] == b"\x89PNG\r\n\x1a\n", f"Not PNG: {url}"
        target.write_bytes(data)
        return "downloaded"
    with ThreadPoolExecutor(max_workers=6) as pool:
        results = list(pool.map(download, tasks))
    print(f"Verified-completed frames: {len(tasks)}; downloaded: {results.count('downloaded')}; existing: {results.count('existing')}")


if __name__ == "__main__":
    main()
