"""Verify the restorable checkpoint and byte preservation of original art/core scenes."""
from pathlib import Path
import json
import zipfile
import zlib

root = Path(__file__).resolve().parent.parent
archive = root / "docs/backups/before_forest_v2_20261027.zip"
with zipfile.ZipFile(archive) as checkpoint:
    invalid = checkpoint.testzip()
    art = [info for info in checkpoint.infolist()
           if info.filename.startswith("assets/") and info.filename.lower().endswith(".png")]
    changed_art = [info.filename for info in art
                   if not (root / info.filename).exists()
                   or zlib.crc32((root / info.filename).read_bytes()) != info.CRC]
    scenes = ["scenes/world.tscn", "scenes/regions/ClareiraDoDespertar.tscn", "scenes/player.tscn"]
    preserved = {name: zlib.crc32((root / name).read_bytes()) == checkpoint.getinfo(name).CRC
                 for name in scenes}
    changed_sources = [info.filename for info in checkpoint.infolist()
                       if info.filename.startswith(("scripts/", "scenes/", "tools/"))
                       and (root / info.filename).is_file()
                       and zlib.crc32((root / info.filename).read_bytes()) != info.CRC]
    known = {info.filename for info in checkpoint.infolist()}
new_sources = sorted(str(path.relative_to(root)).replace("\\", "/")
                     for folder in ("scripts", "scenes", "tools", "tests")
                     for path in (root / folder).rglob("*") if path.is_file()
                     and str(path.relative_to(root)).replace("\\", "/") not in known)
report = {"checkpoint_valid": invalid is None, "original_png_count": len(art),
          "changed_original_pngs": changed_art, "preserved_original_scenes": preserved,
          "changed_sources": changed_sources, "new_sources": new_sources}
(root / "docs/world/forest_v2/preservation_audit.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2), encoding="utf8")
print(json.dumps({key: report[key] for key in ("checkpoint_valid", "original_png_count",
      "changed_original_pngs", "preserved_original_scenes")}, ensure_ascii=False))
raise SystemExit(0 if invalid is None and not changed_art and all(preserved.values()) else 1)
