"""Ícones provisórios 32x32 das armas do protótipo do boss (sem PixelLab, suspenso).
Trocar pela arte aprovada quando o PixelLab for autorizado. Uso: python tools/combat/draw_placeholder_icons.py"""
from PIL import Image, ImageDraw

OUT = "assets/ui/items/%s.png"
OUTLINE = (40, 28, 22, 255)


def save(name, draw_fn):
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(im))
    im.save(OUT % name)


def espada(d):
    for i in range(14):  # lâmina na diagonal
        x, y = 8 + i, 23 - i
        d.rectangle([x, y - 1, x + 1, y], fill=(214, 222, 230, 255))
        d.point((x + 2, y - 1), fill=OUTLINE)
    d.line([(5, 21), (11, 27)], fill=(120, 84, 48, 255), width=3)  # guarda
    d.line([(4, 28), (8, 24)], fill=(92, 60, 36, 255), width=3)  # cabo


def arco(d):
    d.arc([6, 3, 26, 29], start=110, end=250, fill=(130, 86, 46, 255), width=3)
    d.line([(14, 4), (14, 28)], fill=(236, 230, 210, 255), width=1)  # corda


def flecha(d):
    d.line([(6, 26), (25, 7)], fill=(150, 104, 60, 255), width=2)
    d.polygon([(26, 5), (21, 7), (24, 10)], fill=(150, 156, 166, 255))
    d.line([(6, 26), (4, 24)], fill=(230, 230, 230, 255), width=2)
    d.line([(6, 26), (8, 28)], fill=(230, 230, 230, 255), width=2)


def orbe(d):
    d.ellipse([6, 6, 26, 26], fill=(110, 220, 150, 255), outline=(40, 110, 70, 255))
    d.ellipse([10, 9, 17, 15], fill=(210, 255, 225, 255))


for name, fn in [("espada", espada), ("arco", arco), ("flecha", flecha), ("orbe_energia", orbe)]:
    save(name, fn)
print("ok")
