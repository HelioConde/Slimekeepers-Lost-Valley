"""Instala a pá (relatório de playtest ID 30) a partir da arte já exportada em
assets/Create_a_Shovel_Equi (Aren cavando; PixelLab suspenso, nada novo foi gerado).
Cada direção: o quadro 0 (parado com a pá) é encaixado no quadro 0 da enxada (192 px)
comparando só onde os dois têm pixel (o corpo); todos os quadros vão para
assets/player/tools/shovel/<dir>/ na mesma posição. Também recorta o ícone 32 px da pá.
Uso: python tools/pixellab/install_shovel.py
"""
import os

import numpy as np
from PIL import Image

SRC = "assets/Create_a_Shovel_Equi/animations/The_adventurer_grips_the_shovel_firmly_with_both_h"
DIRS = {"south": "south", "east": "east-eac09d46", "north": "north", "west": "west"}


def load(p):
    return np.array(Image.open(p).convert("RGBA")).astype(int)


def match(small, big):
    """(dx, dy) de small dentro de big que melhor sobrepõe o corpo (interseção dos alfas)."""
    best = None
    sh, sw = small.shape[:2]
    bh, bw = big.shape[:2]
    for dy in range(-sh // 2, bh - sh // 2):
        for dx in range(-sw // 2, bw - sw // 2):
            y0, x0 = max(dy, 0), max(dx, 0)
            y1, x1 = min(dy + sh, bh), min(dx + sw, bw)
            if y1 <= y0 or x1 <= x0:
                continue
            a = big[y0:y1, x0:x1]
            b = small[y0 - dy:y1 - dy, x0 - dx:x1 - dx]
            both = (a[..., 3] > 0) & (b[..., 3] > 0)
            n = int(both.sum())
            if n < 600:
                continue
            d = np.abs(a - b)[both].sum() / n
            if best is None or d < best[0]:
                best = (d, dx, dy)
    return best


def main() -> None:
    for d, folder in DIRS.items():
        src = os.path.join(SRC, folder)
        files = sorted(f for f in os.listdir(src) if f.endswith(".png"))
        ref = load(f"assets/player/tools/hoe/{d}/frame_000.png")
        diff, dx, dy = match(load(os.path.join(src, files[0])), ref)
        print(d, "encaixe", dx, dy, "diferença", round(diff, 2))
        out = f"assets/player/tools/shovel/{d}"
        os.makedirs(out, exist_ok=True)
        for i, f in enumerate(files):
            frame = Image.new("RGBA", (192, 192))
            frame.paste(Image.open(os.path.join(src, f)).convert("RGBA"), (dx, dy))
            frame.save(f"{out}/frame_{i:03d}.png")
    # Ícone: a pá em pé ao lado do corpo no quadro 0 de costas (sem sobrepor o corpo).
    im = Image.open(os.path.join(SRC, "north", sorted(os.listdir(os.path.join(SRC, "north")))[0])).convert("RGBA")
    a = np.array(im)
    cols = [x for x in range(a.shape[1]) if (a[:, x, 3] > 0).any()]
    body_right = 0
    for x in cols:  # o corpo é o primeiro bloco contínuo de colunas; a pá vem depois de um vão
        if x > body_right + 1 and body_right:
            break
        body_right = x
    tool = im.crop((body_right + 1, 0, a.shape[1], a.shape[0]))
    box = tool.getbbox()
    tool = tool.crop(box)
    scale = 30 / max(tool.size)
    tool = tool.resize((max(1, round(tool.width * scale)), max(1, round(tool.height * scale))), Image.NEAREST)
    icon = Image.new("RGBA", (32, 32))
    icon.paste(tool, ((32 - tool.width) // 2, (32 - tool.height) // 2))
    icon.save("assets/ui/items/pa.png")
    print("ícone", tool.size)


if __name__ == "__main__":
    main()
