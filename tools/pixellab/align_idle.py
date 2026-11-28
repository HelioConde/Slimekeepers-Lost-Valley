"""Recorta quadros de idle do PixelLab (canvas v3 de 148-160 px) no quadro de 128 px do jogo.

O quadro 0 do v3 é a própria rotação: acha onde ela está no canvas e recorta
todos os quadros na mesma janela (personagem não pula ao trocar de animação).
Uso: python tools/pixellab/align_idle.py ROTACAO.png PASTA_BRUTA(0.png..N.png ou frame_NNN.png) PASTA_DESTINO
"""
import os
import sys

import numpy as np
from PIL import Image


def load(p):
    return np.array(Image.open(p).convert('RGBA')).astype(int)


def match(small, big):
    """Melhor (dx, dy) de small (rotação) dentro de big (canvas maior ou igual)."""
    best = None
    sh, sw = small.shape[:2]
    bh, bw = big.shape[:2]
    for dy in range(0, bh - sh + 1):
        for dx in range(0, bw - sw + 1):
            a = big[dy:dy + sh, dx:dx + sw]
            mask = (a[..., 3] > 0) | (small[..., 3] > 0)
            d = np.abs(a - small)[mask].sum() / max(mask.sum(), 1)
            if best is None or d < best[0]:
                best = (d, dx, dy)
    return best


def frames(folder):
    files = [f for f in os.listdir(folder) if f.endswith('.png')]
    key = lambda f: int(''.join(c for c in f if c.isdigit()) or 0)
    return [os.path.join(folder, f) for f in sorted(files, key=key)]


def main():
    rot_path, raw, dst = sys.argv[1:4]
    rot = load(rot_path)
    files = frames(raw)
    d, cx, cy = match(rot, load(files[0]))
    print('recorte', cx, cy, 'diferença', round(d, 2))
    os.makedirs(dst, exist_ok=True)
    for old in os.listdir(dst):
        if old.startswith('frame_') and old.endswith('.png'):
            os.remove(os.path.join(dst, old))
    h, w = rot.shape[:2]
    for i, f in enumerate(files):
        Image.open(f).convert('RGBA').crop((cx, cy, cx + w, cy + h)).save(os.path.join(dst, 'frame_%03d.png' % i))
    print(dst, len(files), 'quadros')


if __name__ == '__main__':
    main()
