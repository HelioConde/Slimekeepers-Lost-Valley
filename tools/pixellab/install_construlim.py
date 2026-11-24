"""Instala as animações do Construlim (2026-11-23) em assets/slimes/living_v3/construlim/v3/.
Escolhas depois da revisão quadro a quadro (slime sem braço/perna; pedrinhas presas):
- idle: quadros 0-7 (o 8 tem olhos estranhos); move: os quadros do idle (como o Carreguim);
- blink: 0,1,2,3,2,1,0 da 1ª versão (fecha e volta aos mesmos olhos);
- happy: 1ª versão sem os quadros 3 e 4 (aparecem pezinhos);
- comer: 2ª versão (come a cenoura); receber_carinho: 2ª versão, sem pontinhos soltos;
- sleep e construir: 1ª versão.
Uso: python tools/pixellab/install_construlim.py <pasta animations do zip>
"""
import os
import shutil
import sys

import numpy as np
from PIL import Image

PICK = {
    "idle": ("idle", [0, 1, 2, 3, 4, 5, 6, 7], False),
    "move": ("idle", [0, 1, 2, 3, 4, 5, 6, 7], False),
    "blink": ("blink", [0, 1, 2, 3, 2, 1, 0], False),
    "happy": ("happy", [0, 1, 2, 5, 6, 7, 8], False),
    "sleep": ("sleep", list(range(9)), False),
    "comer": ("comer2", list(range(9)), False),
    "receber_carinho": ("receber_carinho2", list(range(9)), True),
    "construir": ("construir", list(range(9)), False),
}
SMALL = 12  # pedacinhos soltos menores que isto (px) saem


def clean(img: Image.Image) -> Image.Image:
    """Tira componentes pequenos que não encostam no corpo (pedrinha voando)."""
    a = np.array(img)
    solid = a[..., 3] > 0
    seen = np.zeros_like(solid)
    h, w = solid.shape
    parts = []
    for y in range(h):
        for x in range(w):
            if solid[y, x] and not seen[y, x]:
                stack, comp = [(y, x)], []
                seen[y, x] = True
                while stack:
                    cy, cx = stack.pop()
                    comp.append((cy, cx))
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and solid[ny, nx] and not seen[ny, nx]:
                                seen[ny, nx] = True
                                stack.append((ny, nx))
                parts.append(comp)
    biggest = max(len(p) for p in parts) if parts else 0
    for comp in parts:
        if len(comp) < SMALL and len(comp) < biggest:
            for cy, cx in comp:
                a[cy, cx, 3] = 0
    return Image.fromarray(a)


def main() -> None:
    src = sys.argv[1]
    out_root = "assets/slimes/living_v3/construlim/v3"
    for anim, (source, frames, tidy) in PICK.items():
        folder = os.path.join(src, source, "south")
        files = sorted(f for f in os.listdir(folder) if f.endswith(".png"))
        out = os.path.join(out_root, anim)
        if os.path.isdir(out):
            shutil.rmtree(out)
        os.makedirs(out)
        for i, k in enumerate(frames):
            img = Image.open(os.path.join(folder, files[k])).convert("RGBA")
            (clean(img) if tidy else img).save(os.path.join(out, f"frame_{i:03d}.png"))
        print(anim, "<-", source, frames)


if __name__ == "__main__":
    main()
