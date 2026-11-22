"""Alinha quadros do despertar (canvas PixelLab variável) ao sprite parado.

Uso: python tools/pixellab/align_wake.py ROTACAO_SUL.png PASTA_BRUTA PASTA_DESTINO
PASTA_BRUTA tem sit_down/, sit_idle/... com 0.png..N.png. sit_down/0 = rotação sul
(de pé) dá o recorte; o quadro 0 de cada pose sentada = último de sit_down e dá o
encaixe dela. stand_up é sit_down de trás para frente.
"""
import sys, os
import numpy as np
from PIL import Image


def load(p):
    return np.array(Image.open(p).convert('RGBA')).astype(int)


def match(small, big):
    """Melhor (dx, dy) de small dentro de big (canvas pode ser maior ou menor)."""
    best = None
    sh, sw = small.shape[:2]
    bh, bw = big.shape[:2]
    for dy in range(-sh + 8, bh - 8):
        for dx in range(-sw + 8, bw - 8):
            y0, x0 = max(dy, 0), max(dx, 0)
            y1, x1 = min(dy + sh, bh), min(dx + sw, bw)
            if y1 - y0 < sh // 2 or x1 - x0 < sw // 2:
                continue
            a = big[y0:y1, x0:x1]
            b = small[y0 - dy:y1 - dy, x0 - dx:x1 - dx]
            mask = (a[..., 3] > 0) | (b[..., 3] > 0)
            d = np.abs(a - b)[mask].sum() / max(mask.sum(), 1)
            if best is None or d < best[0]:
                best = (d, dx, dy)
    return best


rot = load(sys.argv[1])
raw, dst = sys.argv[2], sys.argv[3]
frames = lambda n: sorted([f for f in os.listdir(os.path.join(raw, n)) if f.endswith('.png')], key=lambda f: int(f.split('.')[0]))
down = [os.path.join(raw, 'sit_down', f) for f in frames('sit_down')]
d, cx, cy = match(rot, load(down[0]))  # recorte (W x H da rotação) dentro do canvas de sit_down
print('crop', cx, cy, 'diff', round(d, 2))
H, W = rot.shape[:2]
seated = load(down[-1])
plan = {'stand_up': (list(reversed(down)), 0, 0)}
for n in sorted(d for d in os.listdir(raw) if os.path.isdir(os.path.join(raw, d))):
    if n == 'sit_down':
        continue
    fs = [os.path.join(raw, n, f) for f in frames(n)]
    d, ox, oy = match(load(fs[0]), seated)  # pose dentro do canvas de sit_down
    print(n, 'offset', ox, oy, 'diff', round(d, 2))
    plan[n] = (fs, ox, oy)
for name, (files, ox, oy) in plan.items():
    out = os.path.join(dst, name, 'south')
    os.makedirs(out, exist_ok=True)
    for i, f in enumerate(files):
        im = Image.open(f).convert('RGBA')
        canvas = Image.new('RGBA', (max(im.width + ox, seated.shape[1]) + 64, max(im.height + oy, seated.shape[0]) + 64))
        canvas.alpha_composite(im, (ox + 32, oy + 32))
        canvas.crop((cx + 32, cy + 32, cx + 32 + W, cy + 32 + H)).save(os.path.join(out, 'frame_%03d.png' % i))
    print(name, len(files))
