"""Copy original PixelLab PNGs and write Godot SpriteFrames; never redraw pixels."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import shutil
import struct

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/slimes/living_v3"


def write_frames(folder: Path, animations: dict[str, dict], canvas: int = 64) -> dict:
    """Every item contains source PNG paths, fps and loop; PNG bytes are preserved."""
    texture_ids: dict[Path, str] = {}
    texture_sizes: dict[Path, tuple] = {}
    output = []
    manifest = {}
    for name, spec in animations.items():
        sources = [Path(p) for p in spec["files"]]
        assert sources, f"Empty animation: {name}"
        destination = folder / "animations" / name
        destination.mkdir(parents=True, exist_ok=True)
        pngs = []
        sizes = set()
        hashes = []
        for i, source in enumerate(sources):
            content = source.read_bytes()
            assert content[:8] == b"\x89PNG\r\n\x1a\n", source
            sizes.add(struct.unpack(">II", content[16:24]))
            target = destination / f"frame_{i:03}.png"
            if source.resolve() != target.resolve():
                shutil.copyfile(source, target)
            assert target.read_bytes() == content, f"Copy changed pixels: {target}"
            texture_ids[target] = str(len(texture_ids) + 1)
            texture_sizes[target] = struct.unpack(">II", content[16:24])
            pngs.append(target)
            hashes.append(hashlib.sha256(content).hexdigest())
        assert len(sizes) == 1, f"Inconsistent canvas in {name}: {sizes}"
        manifest[name] = {
            "frames": len(pngs), "canvas": list(next(iter(sizes))),
            "resource_canvas": [canvas, canvas],
            "fps": spec["fps"], "loop": spec["loop"],
            "source": spec.get("source", "PixelLab"),
            "sha256": hashes,
        }
        output.append((name, pngs, spec))
    padded = {path: size for path, size in texture_sizes.items() if size != (canvas, canvas)}
    lines = [f'[gd_resource type="SpriteFrames" load_steps={len(texture_ids)+len(padded)+1} format=3]', ""]
    for path, identifier in texture_ids.items():
        resource = "res://" + path.relative_to(ROOT).as_posix()
        lines.append(f'[ext_resource type="Texture2D" path="{resource}" id="{identifier}"]')
    for path, (width, height) in padded.items():
        assert width <= canvas and height <= canvas, f"Canvas would crop {path}"
        dx, dy = canvas - width, canvas - height
        identifier = texture_ids[path]
        lines += ["", f'[sub_resource type="AtlasTexture" id="Pad_{identifier}"]',
                  f'atlas = ExtResource("{identifier}")',
                  f'region = Rect2(0, 0, {width}, {height})',
                  f'margin = Rect2({dx / 2.0}, {dy / 2.0}, {dx}, {dy})']
    lines += ["", "[resource]", "animations = ["]
    for index, (name, paths, spec) in enumerate(output):
        frame_entries = ',\n'.join('{"duration": 1.0, "texture": %s}' % (
            f'SubResource("Pad_{texture_ids[p]}")' if p in padded else f'ExtResource("{texture_ids[p]}")') for p in paths)
        lines.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": %s}%s' % (
            frame_entries, str(spec["loop"]).lower(), name, float(spec["fps"]),
            ',' if index + 1 < len(output) else ''))
    lines.append("]")
    (folder / "frames.tres").write_text("\n".join(lines) + "\n", encoding="utf-8")
    (folder / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


def import_bolhinha() -> dict:
    folder = ASSETS / "bolhinha"
    source = folder / "source"
    metadata = json.loads((source / "metadata.json").read_text(encoding="utf-8"))
    existing = metadata["states"][0]["frames"]["animations"]
    mapping = {
        "idle": ("The_slime_performs_a_gentle_rhythmic_bobbing_motio", 5, True),
        "blink": ("Idle", 5, True),
        "move": ("The_slime_executes_a_rhythmic_vertical_bounce_comp", 9, True),
        "happy": ("The_slime_executes_a_rhythmic_vertical_bounce_comp", 11, False),
        "curious": ("The_slime_performs_a_gentle_rhythmic_bobbing_motio", 4, False),
        "plant": ("A_cute_peaceful_water_slime_magically_watering_pla", 8, False),
        "play": ("The_slime_executes_a_rhythmic_vertical_bounce_comp", 10, False),
        "splash": ("The_slime_squashes_downward_to_charge_energy_then", 9, False),
        "drink": ("The_slime_gently_leans_forward_to_submerge_its_mou", 7, False),
    }
    animations = {}
    for name, (original, fps, loop) in mapping.items():
        animations[name] = {"files": [source / p for p in existing[original]["south"]],
                            "fps": fps, "loop": loop, "source": original + "/south"}
    # New paid clips are optional and must already have been approved, generated,
    # checked completed and downloaded. This importer never calls PixelLab.
    for name in ("happy", "curious", "sleep"):
        files = sorted((source / "supplemental" / name).glob("frame_*.png"))
        if files:
            if name == "sleep":
                files = files[4:]  # Closed-eye sustained pose; transition remains in source.
            animations[name] = {"files": files, "fps": 6 if name == "sleep" else 8,
                                "loop": name == "sleep", "source": "supplemental/" + name}
    (source / ".gdignore").touch()
    return write_frames(folder, animations, canvas=76)


def import_new_species(species: str) -> dict:
    folder = (ASSETS if species == "musguinho" else ROOT / "assets/wildlife/living_v3") / species
    source = folder / "source"
    def clip(name: str, fps: int = 8, loop: bool = True) -> dict:
        files = sorted((source / name).glob("frame_*.png"))
        if name == "sleep":
            files = files[4:]
        return {"files": files, "fps": fps, "loop": loop, "source": name}
    if species == "musguinho":
        animations = {name: clip(name, 5 if name in ("idle", "sleep") else 8,
                                 name in ("idle", "move", "sleep"))
                      for name in ("idle", "move", "jump", "happy", "sleep", "plant")}
        animations["play"] = clip("jump", 10, False)
        animations["curious"] = clip("plant", 6, False)
    else:
        animations = {"idle": {"files": [source / "base.png"], "fps": 1,
                                "loop": True, "source": "base"}, "walk": clip("walk")}
        if species == "squirrel":
            animations["forage"] = clip("forage", 6)
        else:
            animations["fly"] = clip("fly", 12)
    (source / ".gdignore").touch()
    return write_frames(folder, animations)


if __name__ == "__main__":
    result = import_bolhinha()
    print(json.dumps({name: {k: v for k, v in spec.items() if k != "sha256"}
                      for name, spec in result.items()}, indent=2))
    for species in ("musguinho", "squirrel", "bird"):
        folder = (ASSETS if species == "musguinho" else ROOT / "assets/wildlife/living_v3") / species
        if (folder / "source/base.png").exists():
            print(species, list(import_new_species(species)))
