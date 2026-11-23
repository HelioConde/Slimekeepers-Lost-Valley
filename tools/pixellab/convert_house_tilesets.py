"""Converte os tilesets PixelLab da casa (piso, parede, telhado) para o jogo.

Para cada folha: remove a grama (o "outro" terreno) por cor, deixando-a
transparente, e grava <nome>.png + <nome>.json com {"NW,NE,SW,SE": [x, y]}.
Estados dos cantos: m = material (piso/parede/telhado), f = face da parede
(transition), e = vazio. Uso: python convert_house_tilesets.py <pasta_download> <pasta_saida>
"""
import json
import sys
from pathlib import Path
from PIL import Image

# Qual terreno PixelLab é o material em cada folha (o gerador padrão trocou o piso).
MATERIAL = {"floor": "lower", "roof": "upper", "wall": "upper"}


def is_grass(r, g, b):
    # Esverdeado (grama e as sombras dela); madeira, telha e pedra cinza ficam.
    return g > r + 4 and g > b + 4


def convert(name, src, dst):
    meta = json.loads((src / f"{name}.json").read_text(encoding="utf-8"))
    sheet = Image.open(src / f"{name}.png").convert("RGBA")
    px = sheet.load()
    for y in range(sheet.height):
        for x in range(sheet.width):
            r, g, b, a = px[x, y]
            if a and is_grass(r, g, b):
                px[x, y] = (0, 0, 0, 0)
    material = MATERIAL[name]
    code = {material: "m", "transition": "f"}
    tiles = {}
    for tile in meta["tileset_data"]["tiles"]:
        c = tile["corners"]
        key = ",".join(code.get(c[k], "e") for k in ("NW", "NE", "SW", "SE"))
        box = tile["bounding_box"]
        tiles.setdefault(key, [box["x"], box["y"]])
    sheet.save(dst / f"{name}.png")
    (dst / f"{name}.json").write_text(json.dumps({"tile": 32, "tiles": tiles}, indent=1), encoding="utf-8")
    print(name, len(tiles), "tiles")


if __name__ == "__main__":
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    dst.mkdir(parents=True, exist_ok=True)  # pasta de saída nova não quebra a conversão
    for name in ("floor", "wall", "roof"):
        convert(name, src, dst)
