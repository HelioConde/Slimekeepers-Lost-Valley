"""Monta e harmoniza os tiles de chão V8 (PixelLab, Wang por cantos).

Uso: python tools/tone_ground_tiles.py FOLHA.png METADADOS.json DESTINO.png
         [--upper-value K] [--upper-sat K] [--lower-value K] [--lower-sat K]

Reorganiza a folha no atlas canônico 4x4 (índice = NW*8 + NE*4 + SW*2 + SE,
com 1 = terreno de cima) e ajusta valor/saturação de cada terreno pela matiz,
para casar com a luminância do chão antigo (a grama do gerador vinha ~30% mais
clara que a do jogo).
"""
import argparse
import colorsys
import json

import numpy as np
from PIL import Image


def tone(pixel, value, sat):
    r, g, b = pixel
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    return colorsys.hsv_to_rgb(h, min(1.0, s * sat), min(1.0, v * value))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("sheet")
    parser.add_argument("metadata")
    parser.add_argument("dst")
    parser.add_argument("--upper-value", type=float, default=0.8)
    parser.add_argument("--upper-sat", type=float, default=0.9)
    parser.add_argument("--lower-value", type=float, default=1.0)
    parser.add_argument("--lower-sat", type=float, default=1.0)
    parser.add_argument("--upper-hues", type=float, nargs=2, default=(55.0, 115.0))
    args = parser.parse_args()

    meta = json.load(open(args.metadata, encoding="utf-8"))
    sheet = Image.open(args.sheet).convert("RGBA")
    atlas = Image.new("RGBA", (128, 128))
    for tile in meta["tileset_data"]["tiles"]:
        corners = tile["corners"]
        box = tile["bounding_box"]
        index = sum(bit for key, bit in (("NW", 8), ("NE", 4), ("SW", 2), ("SE", 1)) if corners[key] == "upper")
        atlas.paste(sheet.crop((box["x"], box["y"], box["x"] + 32, box["y"] + 32)), ((index % 4) * 32, (index // 4) * 32))

    data = np.asarray(atlas).astype(float) / 255.0
    low, high = args.upper_hues
    for y in range(data.shape[0]):
        for x in range(data.shape[1]):
            r, g, b, a = data[y, x]
            if a == 0:
                continue
            hue = colorsys.rgb_to_hsv(r, g, b)[0] * 360.0
            upper = low <= hue <= high
            data[y, x, :3] = tone((r, g, b), args.upper_value if upper else args.lower_value,
                                  args.upper_sat if upper else args.lower_sat)
    Image.fromarray((data * 255.0 + 0.5).astype(np.uint8)).save(args.dst)


if __name__ == "__main__":
    main()
