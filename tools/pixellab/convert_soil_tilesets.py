"""Converte os tilesets PixelLab da terra arada (seca e molhada) para o jogo.

Mesmo formato da casa (convert_house_tilesets.py): a grama vira transparente e o
mapa de cantos {"NW,NE,SW,SE": [x, y]} usa m = terra, e = vazio. A terra é o
terreno "lower" nas duas folhas (modo pro, grama encadeada como "upper").
Uso: python convert_soil_tilesets.py <pasta_download> <pasta_saida>
(<pasta_download> tem soil_dry.png/.json e soil_wet.png/.json da API de tilesets.)
"""
import json
import sys
from pathlib import Path
from PIL import Image


def is_grass(r, g, b):
    # Terra é marrom (vermelho >= verde); grama e as sombras dela não.
    return g > r


def convert(name, src, dst):
    meta = json.loads((src / f"{name}.json").read_text(encoding="utf-8"))
    sheet = Image.open(src / f"{name}.png").convert("RGBA")
    px = sheet.load()
    for y in range(sheet.height):
        for x in range(sheet.width):
            r, g, b, a = px[x, y]
            if a and is_grass(r, g, b):
                px[x, y] = (0, 0, 0, 0)
    tiles = {}
    data = meta.get("tileset_data", meta)
    for tile in data["tiles"]:
        c = tile["corners"]
        key = ",".join("m" if c[k] == "lower" else "e" for k in ("NW", "NE", "SW", "SE"))
        box = tile["bounding_box"]
        tiles.setdefault(key, [box["x"], box["y"]])
    sheet.save(dst / f"{name}.png")
    (dst / f"{name}.json").write_text(json.dumps({"tile": 32, "tiles": tiles}, indent=1), encoding="utf-8")
    print(name, len(tiles), "tiles")
    assert len(tiles) == 16, "o tileset Wang plano tem 16 combinações de cantos"


if __name__ == "__main__":
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    dst.mkdir(parents=True, exist_ok=True)
    for name in ("soil_dry", "soil_wet"):
        convert(name, src, dst)
