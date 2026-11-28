"""Fonte de dígitos 5x7 feita à mão (playtest ID 33): na Pixelify Sans o "2" e o "5" são quase
iguais. Gera assets/fonts/slime_digits.png + slime_digits.fnt (BMFont em texto, importado
pelo Godot); assets/fonts/ui_font.tres usa estes dígitos e cai na Pixelify para o resto.
Uso: python tools/build_digit_font.py
"""
from PIL import Image

GLYPHS = {
    "0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
    "1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
    "2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],  # base reta, diagonal
    "3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
    "4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
    "5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],  # topo reto, canto vivo
    "6": ["..##.", ".#...", "#....", "####.", "#...#", "#...#", ".###."],
    "7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
    "8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],  # dois anéis fechados
    "9": [".###.", "#...#", "#...#", ".####", "....#", "...#.", ".##.."],
    "/": ["....#", "...#.", "...#.", "..#..", ".#...", ".#...", "#...."],
}
W, H, CELL = 5, 7, 8
SIZE, LINE, BASE = 11, 14, 11  # alinhado à Pixelify em 11 px (dígitos com 7 px de altura)

atlas = Image.new("RGBA", (CELL * len(GLYPHS), CELL), (0, 0, 0, 0))
lines = [
    f'info face="SlimeDigits" size={SIZE} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1',
    f"common lineHeight={LINE} base={BASE} scaleW={atlas.width} scaleH={atlas.height} pages=1 packed=0",
    'page id=0 file="slime_digits.png"',
    f"chars count={len(GLYPHS)}",
]
for i, (ch, rows) in enumerate(GLYPHS.items()):
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            if c == "#":
                atlas.putpixel((i * CELL + x, y), (255, 255, 255, 255))
    lines.append(f"char id={ord(ch)} x={i * CELL} y=0 width={W} height={H} xoffset=0 yoffset={BASE - H} xadvance={W + 1} page=0 chnl=15")
atlas.save("assets/fonts/slime_digits.png")
open("assets/fonts/slime_digits.fnt", "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
print("ok", len(GLYPHS), "glifos")
