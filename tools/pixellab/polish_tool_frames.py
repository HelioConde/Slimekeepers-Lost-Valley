"""Golpe das ferramentas de pedra polida (2026-11-23): copia a animação aprovada do machado e
da picareta rudimentares e pinta só a cabeça de pedra (cinzas de pouca saturação) no
azul-acinzentado com brilho dos ícones machado_polido/picareta_polida. Cinzas que já existem
no desenho do personagem parado (ex.: óculos da Moni) ficam como estão.
Uso: python tools/pixellab/polish_tool_frames.py   (gera assets/<arte>/tools/<tool>_polished/)
"""
import colorsys
import os

from PIL import Image

ARTS = ("player", "player_moni")
TOOLS = {"axe": "axe_polished", "pickaxe": "pickaxe_polished"}


def body_greys(art: str) -> set:
    """Cinzas do personagem sem ferramenta (quadros do idle_breath)."""
    found = set()
    base = f"assets/{art}/animations/idle_breath"
    for root, _dirs, files in os.walk(base):
        for f in files:
            if f.endswith(".png"):
                for p in Image.open(os.path.join(root, f)).convert("RGBA").get_flattened_data():
                    if is_stone(p):
                        found.add(p[:3])
    return found


def is_stone(p) -> bool:
    r, g, b, a = p
    if a < 128:
        return False
    _h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return s < 0.13 and 0.33 < v < 0.9


def polish(p):
    r, g, b, a = p
    v = max(r, g, b) / 255
    v = min(1.0, v * 1.08 + 0.04)  # pedra polida: um pouco mais clara
    return (int(min(255, v * 205)), int(min(255, v * 228)), int(min(255, v * 255)), a)


def main() -> None:
    for art in ARTS:
        keep = body_greys(art)
        for src, dst in TOOLS.items():
            base = f"assets/{art}/tools/{src}"
            if not os.path.isdir(base):
                continue
            for d in sorted(os.listdir(base)):
                folder = os.path.join(base, d)
                if not os.path.isdir(folder):
                    continue
                out = f"assets/{art}/tools/{dst}/{d}"
                os.makedirs(out, exist_ok=True)
                changed = 0
                for f in sorted(x for x in os.listdir(folder) if x.endswith(".png")):
                    im = Image.open(os.path.join(folder, f)).convert("RGBA")
                    px = im.load()
                    for y in range(im.height):
                        for x in range(im.width):
                            p = px[x, y]
                            if is_stone(p) and p[:3] not in keep:
                                px[x, y] = polish(p)
                                changed += 1
                    im.save(os.path.join(out, f))
                print(art, dst, d, "pixels pintados:", changed)


if __name__ == "__main__":
    main()
