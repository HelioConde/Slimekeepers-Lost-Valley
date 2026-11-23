"""Instala o golpe da foice (2026-11-23; corte DE LADO, varrendo rente ao mato — pedido do
usuário). Cada direção foi animada no PixelLab (v3) a partir da pose parada com a foice,
que é o recorte de 144 px do golpe do machado na posição OFF do quadro de 192 px. O quadro
0 de cada animação é essa pose: acha onde ela está no canvas novo e cola todos os quadros
no quadro de 192 px na mesma posição do machado. Oeste espelha o leste.
Uso: python tools/pixellab/install_sickle.py <pasta sweep/<arte>/<dir>/frame_NNN.png> <pasta das poses 144 px>
"""
import os
import sys

import numpy as np
from PIL import Image, ImageOps

OFF = {"south": (24, 24), "east": (36, 24), "north": (40, 20)}


def load(p):
    return np.array(Image.open(p).convert("RGBA")).astype(int)


def match(small, big):
    """(dx, dy) de small dentro de big; pode sair das bordas (canvas menor que 144)."""
    best = None
    sh, sw = small.shape[:2]
    bh, bw = big.shape[:2]
    for dy in range(-sh // 3, bh - sh * 2 // 3):
        for dx in range(-sw // 3, bw - sw * 2 // 3):
            y0, x0 = max(dy, 0), max(dx, 0)
            y1, x1 = min(dy + sh, bh), min(dx + sw, bw)
            a = big[y0:y1, x0:x1]
            b = small[y0 - dy:y1 - dy, x0 - dx:x1 - dx]
            mask = (a[..., 3] > 0) | (b[..., 3] > 0)
            if mask.sum() < 200:
                continue
            d = np.abs(a - b)[mask].sum() / mask.sum()
            if best is None or d < best[0]:
                best = (d, dx, dy)
    return best


def main() -> None:
    src, rest = sys.argv[1], sys.argv[2]
    for art in ("player", "player_moni"):
        for d, (ox, oy) in OFF.items():
            folder = os.path.join(src, art, d)
            files = sorted(f for f in os.listdir(folder) if f.endswith(".png"))
            diff, dx, dy = match(load(os.path.join(rest, f"{art}_{d}_000.png")), load(os.path.join(folder, files[0])))
            print(art, d, "encaixe", dx, dy, "diferença", round(diff, 2))
            out = f"assets/{art}/tools/sickle/{d}"
            os.makedirs(out, exist_ok=True)
            for old in os.listdir(out):
                if old.startswith("frame_"):
                    os.remove(os.path.join(out, old))
            if d == "east":
                west = f"assets/{art}/tools/sickle/west"
                os.makedirs(west, exist_ok=True)
                for old in os.listdir(west):
                    if old.startswith("frame_"):
                        os.remove(os.path.join(west, old))
            for i, f in enumerate(files):
                frame = Image.new("RGBA", (192, 192))
                img = Image.open(os.path.join(folder, f)).convert("RGBA")
                frame.paste(img, (ox - dx, oy - dy))  # canvas vazio: copia o alfa (posição pode ser negativa)
                frame.save(f"{out}/frame_{i:03d}.png")
                if d == "east":
                    ImageOps.mirror(frame).save(f"assets/{art}/tools/sickle/west/frame_{i:03d}.png")


if __name__ == "__main__":
    main()
