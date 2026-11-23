"""Musguinho aduba (2026-11-23): animação montada dos quadros parados aprovados.

O corpo se encolhe, solta um sopro de musgo/adubo pelo broto e os grãos caem em
arco dos dois lados até o chão, onde brilham e somem. Nada de membros: só o corpo
aprovado e partículas desenhadas aqui (as gerações do PixelLab criavam bolhas
laterais e manchas pretas).
Uso: python tools/make_musguinho_adubar.py
"""
from pathlib import Path

from PIL import Image

ART = Path("assets/slimes/living_v3/musguinho/v3")
OUT = ART / "adubar"
BODY = [0, 2, 4, 4, 5, 6, 6, 5, 4, 2, 0, 0]  # quadros do "parado"
SQUASH = [1.0, 0.97, 0.92, 0.88, 1.04, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
MOSS = [(79, 122, 42, 255), (107, 154, 58, 255), (107, 74, 42, 255), (84, 58, 34, 255)]
SPARK = (214, 240, 150, 255)
GROUND = 54
SPROUT = (40, 12)  # topo do broto no quadro de 64 px
# grão: (x onde cai, cor) — fora do corpo (x 15..49) para não passar pelo rosto
GRAINS = [(10, 0), (55, 2), (6, 3), (59, 1), (13, 2), (52, 0)]


def squash(img: Image.Image, k: float) -> Image.Image:
    if k == 1.0:
        return img
    w, h = img.size
    nh = round(h * k)
    body = img.resize((w, nh), Image.NEAREST)
    out = Image.new("RGBA", img.size)
    out.alpha_composite(body, (0, GROUND - round(GROUND * k)))  # base presa no chão
    return out


def put(img: Image.Image, x: int, y: int, c) -> None:
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def dot(img: Image.Image, x: int, y: int, c) -> None:
    for dx in (0, 1):
        for dy in (0, 1):
            put(img, x + dx, y + dy, c)


def main() -> None:
    OUT.mkdir(exist_ok=True)
    for old in OUT.glob("frame_*.png"):
        old.unlink()
    for f, (src, k) in enumerate(zip(BODY, SQUASH)):
        frame = squash(Image.open(ART / "idle" / f"frame_{src:03d}.png").convert("RGBA"), k)
        t = f - 4  # sopro no quadro 4
        if t >= 0:
            for i, (land, color) in enumerate(GRAINS):
                p = min(1.0, (t + 1) / 4.0)
                x = round(SPROUT[0] + (land - SPROUT[0]) * p)
                y = round(SPROUT[1] - 16 * 4 * p * (1 - p) + (GROUND - 2 - SPROUT[1]) * p * p)  # arco alto
                if p < 1.0:
                    dot(frame, x, y, MOSS[color])
                elif t < 7:  # no chão: grão + brilho curto
                    dot(frame, x, GROUND - 2, MOSS[color])
                    if (t + i) % 2 == 0:
                        put(frame, x, GROUND - 4, SPARK)
        if t == 0:  # sopro saindo do broto
            for dx, dy in [(-1, -1), (1, -1), (0, -2), (-2, 0), (2, 0)]:
                put(frame, SPROUT[0] + dx, SPROUT[1] + dy, SPARK)
        frame.save(OUT / f"frame_{f:03d}.png")
    print("adubar:", len(BODY), "quadros")


if __name__ == "__main__":
    main()
