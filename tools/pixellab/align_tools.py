"""Alinha animações de ferramenta (PixelLab v3, canvas variável) ao sprite parado.

Uso: python tools/pixellab/align_tools.py PASTA_ANIMACOES PASTA_INICIOS QUEM DESTINO_ARTE
PASTA_ANIMACOES: <animação>/<direção>/frame_NNN.png do ZIP do personagem.
PASTA_INICIOS: <quem>_<ferramenta>_<direção>.png, o quadro inicial enviado (rotação
128 px + ícone da barra na mão). O quadro 0 de cada animação é esse quadro: o encaixe
dele dá o deslocamento. Saída: DESTINO_ARTE/tools/<ferramenta>/<direção>/frame_NNN.png
em 192x192 com a rotação centrada (mesmo centro do sprite parado), sem o quadro 0.
Oeste, sudoeste e noroeste são o espelho de leste, sudeste e nordeste.
"""
import sys, os
import numpy as np
from PIL import Image, ImageOps

ANIMS = {"water": "water_green", "hoe": "hoe_item", "axe": "axe_hatchet"}
MIRROR = {"east": "west", "south-east": "south-west", "north-east": "north-west"}
SIZE, PAD = 192, 32  # rotação 128 centrada no canvas 192


def load(p):
    return np.array(Image.open(p).convert("RGBA")).astype(int)


def match(small, big):
    """Melhor (diferença, dx, dy) de small dentro de big (mesma ideia de align_wake.py)."""
    best = None
    sh, sw = small.shape[:2]
    bh, bw = big.shape[:2]
    for dy in range(-32, bh - sh + 33):  # o quadro inicial cabe quase todo no canvas gerado
        for dx in range(-32, bw - sw + 33):
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


def clean_trails(img):
    """Tira rastros de golpe (arcos brancos soltos que o v3 desenha): pixel quase
    branco com 4+ vizinhos transparentes (3 passadas). Brilhos da lâmina têm contorno ao redor
    e ficam. Não usar no regador: a água respingada seria apagada."""
    a = np.array(img)
    h, w = a.shape[:2]
    for _ in range(3):  # arcos de 2 px de largura somem em camadas
        alpha = a[..., 3]
        white = (a[..., :3].astype(int).min(axis=2) >= 225) & (alpha > 0)
        clear = np.pad(alpha == 0, 1, constant_values=True)
        empty = sum(clear[1 + oy:h + 1 + oy, 1 + ox:w + 1 + ox].astype(int)
                    for oy in (-1, 0, 1) for ox in (-1, 0, 1) if oy or ox)
        a[white & (empty >= 4), 3] = 0
    return Image.fromarray(a)


anims, starts, who, dst = sys.argv[1:5]
for tool, anim in ANIMS.items():
    for direction in ["south", "south-east", "east", "north-east", "north"]:
        src = os.path.join(anims, anim, direction)
        names = sorted(f for f in os.listdir(src) if f.endswith(".png"))
        d, dx, dy = match(load(os.path.join(starts, f"{who}_{tool}_{direction}.png")), load(os.path.join(src, names[0])))
        assert d < 8, f"{tool}/{direction}: encaixe ruim ({d:.1f})"
        out = []
        for name in names[1:]:
            frame = Image.open(os.path.join(src, name)).convert("RGBA")
            canvas = Image.new("RGBA", (SIZE, SIZE))
            # A rotação está em (dx, dy) no quadro: vai para (PAD, PAD). paste recorta bordas.
            canvas.paste(frame, (PAD - dx, PAD - dy), frame)
            out.append(clean_trails(canvas) if tool != "water" else canvas)
        targets = [(direction, out)]
        if direction in MIRROR:
            targets.append((MIRROR[direction], [ImageOps.mirror(f) for f in out]))
        for target, frames in targets:
            folder = os.path.join(dst, "tools", tool, target)
            os.makedirs(folder, exist_ok=True)
            for old in os.listdir(folder):
                if old.startswith("frame_"):
                    os.remove(os.path.join(folder, old))
            for i, f in enumerate(frames):
                f.save(os.path.join(folder, f"frame_{i:03d}.png"))
        print(f"{who} {tool} {direction}: diff {d:.2f} offset ({dx},{dy}) {len(out)} frames")
