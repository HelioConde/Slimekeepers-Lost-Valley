"""Instala o golpe de espada (2026-11-28, aprovado pelo usuário): varrida na frente
(movimento "sweep" do skeleton-v3 do PixelLab no estado "Sword Equipped" de cada
personagem) + rastro de luz branco nos quadros 4-7 (edit_animation), no estilo da
picareta. Os quadros do PixelLab têm 160 px com a pose parada de 128 px em (16, 16);
no jogo as ferramentas usam 192 px com a pose em (32, 32), então colam em (16, 16).
Uso: python tools/pixellab/install_sword.py <pasta com <quem>_<dir>_NNN.png> [raiz de saída]
"""
import os
import sys

from PIL import Image

ARTS = {"aren": "player", "moni": "player_moni"}
DIRS = ("south", "east", "north", "west")
FRAMES = 8


def main() -> None:
    src = sys.argv[1]
    root = sys.argv[2] if len(sys.argv) > 2 else "assets"
    for who, art in ARTS.items():
        for d in DIRS:
            out = f"{root}/{art}/tools/sword/{d}"
            os.makedirs(out, exist_ok=True)
            for old in os.listdir(out):
                if old.startswith("frame_"):
                    os.remove(os.path.join(out, old))
            for i in range(FRAMES):
                img = Image.open(os.path.join(src, f"{who}_{d}_{i:03d}.png")).convert("RGBA")
                assert img.size == (160, 160), img.size
                frame = Image.new("RGBA", (192, 192))
                frame.paste(img, (16, 16))
                frame.save(f"{out}/frame_{i:03d}.png")
            print(art, d, FRAMES, "quadros")


if __name__ == "__main__":
    main()
