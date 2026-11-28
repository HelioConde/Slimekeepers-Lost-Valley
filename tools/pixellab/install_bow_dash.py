"""Instala o tiro com arco e a esquiva rápida (2026-11-28, aprovados pelo usuário).
Arco: movimento shoot_bow do skeleton-v3 no estado "Bow Equipped" (8 quadros); no oeste
o último quadro deitava o arco e vira o primeiro. Esquiva: poses escritas no skeleton-v3
(passo longo e baixo, 6 quadros) no lugar do rolamento. Quadros do PixelLab: 160 px com a
pose de 128 px em (16, 16); no jogo vão para 192 px em (16, 16), como a espada.
Uso: python tools/pixellab/install_bow_dash.py <bow aren.zip> <bow moni.zip> <dash aren.zip> <dash moni.zip> [raiz]
"""
import io
import os
import sys
import zipfile

from PIL import Image

DIRS = ("south", "east", "north", "west")


def paste(data: bytes) -> Image.Image:
    img = Image.open(io.BytesIO(data)).convert("RGBA")
    assert img.size == (160, 160), img.size
    frame = Image.new("RGBA", (192, 192))
    frame.paste(img, (16, 16))
    return frame


def install(zip_path: str, state: str, anim: str, out_root: str, frames: int, fix_west_last: bool) -> None:
    z = zipfile.ZipFile(zip_path)
    for d in DIRS:
        os.makedirs(f"{out_root}/{d}", exist_ok=True)
        for old in os.listdir(f"{out_root}/{d}"):
            if old.startswith("frame_"):
                os.remove(os.path.join(out_root, d, old))
        for i in range(frames):
            src = 0 if (fix_west_last and d == "west" and i == frames - 1) else i
            paste(z.read(f"{state}/animations/{anim}/{d}/frame_{src:03d}.png")).save(f"{out_root}/{d}/frame_{i:03d}.png")
        print(out_root, d, frames)


def main() -> None:
    bow_aren, bow_moni, dash_aren, dash_moni = sys.argv[1:5]
    root = sys.argv[5] if len(sys.argv) > 5 else "assets"
    for zp, art in ((bow_aren, "player"), (bow_moni, "player_moni")):
        install(zp, "Bow_Equipped", "shoot_bow", f"{root}/{art}/tools/bow", 8, True)
    for zp, art in ((dash_aren, "player"), (dash_moni, "player_moni")):
        install(zp, "Idle", "dash_dodge", f"{root}/{art}/actions/dash", 6, False)


if __name__ == "__main__":
    main()
