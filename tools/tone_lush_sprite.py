"""Pós-processo dos sprites de vegetação V6 gerados no PixelLab.

Uso: python tools/tone_lush_sprite.py ORIGEM DESTINO [--strip-ground Y] [--shift DX DY]
                                       [--soften K] [--tips K]

--strip-ground Y  remove pixels verdes (tufo de grama do gerador) a partir da linha Y
--shift DX DY     desloca o sprite para alinhar a base do tronco aos sprites antigos
--soften K        suaviza realces amarelo-lima (0..1; 0.32 nas árvores aprovadas)
--tips K          suaviza ainda mais os pixels mais claros (pontas de pinheiro)
"""
import argparse
import colorsys

import numpy as np
from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("src")
    parser.add_argument("dst")
    parser.add_argument("--strip-ground", type=int, default=None)
    parser.add_argument("--shift", type=int, nargs=2, default=(0, 0))
    parser.add_argument("--soften", type=float, default=0.32)
    parser.add_argument("--tips", type=float, default=0.0)
    args = parser.parse_args()

    image = np.asarray(Image.open(args.src).convert("RGBA")).copy()
    height, width, _ = image.shape
    if args.strip_ground is not None:
        for y in range(args.strip_ground, height):
            for x in range(width):
                r, g, _b, alpha = (int(v) for v in image[y, x])
                if alpha and g >= r - 4:
                    image[y, x] = 0
    out = image.astype(float) / 255.0
    for y in range(height):
        for x in range(width):
            r, g, b, alpha = out[y, x]
            if alpha == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r, g, b)
            deg = h * 360.0
            if 45.0 <= deg <= 110.0 and v > 0.45:
                k = min(1.0, (v - 0.45) / 0.4)
                s *= 1.0 - args.soften * k
                v *= 1.0 - 0.375 * args.soften * k
                deg += 8.0 * k
                if args.tips and v > 0.62:
                    t = min(1.0, (v - 0.62) / 0.2)
                    s *= 1.0 - args.tips * t
                    v *= 1.0 - 0.25 * args.tips * t
                    deg += 10.0 * args.tips * t
                out[y, x, :3] = colorsys.hsv_to_rgb((deg % 360.0) / 360.0, s, v)
    toned = Image.fromarray((out * 255.0 + 0.5).astype(np.uint8))
    canvas = Image.new("RGBA", toned.size)
    canvas.alpha_composite(toned, tuple(args.shift))
    canvas.save(args.dst)


if __name__ == "__main__":
    main()
