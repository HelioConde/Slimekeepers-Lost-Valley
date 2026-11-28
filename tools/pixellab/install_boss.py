"""Instala a arte dos bosses gigantes (2026-11-28, aprovada pelo usuário): estado "Gigante"
do Brotinho e do Musguinho no PixelLab, animações v3 olhando para a frente (o jogo espelha
para os lados). Da pancada fica só o pouso (quadros 6-8): o salto é feito pelo código e os
quadros 3-5 deformavam o corpo.
Uso: python tools/pixellab/install_boss.py <brotinho.zip> <musguinho.zip> [raiz]
"""
import os
import re
import sys
import zipfile

KEEP = {"boss_idle": None, "boss_charge": None, "boss_hurt": None, "boss_dazed": None, "boss_slam": [6, 7, 8]}


def main() -> None:
    root = sys.argv[3] if len(sys.argv) > 3 else "assets"
    for species, zip_path in (("brotinho", sys.argv[1]), ("musguinho", sys.argv[2])):
        z = zipfile.ZipFile(zip_path)
        for anim, picks in KEEP.items():
            names = sorted(n for n in z.namelist() if re.search(rf"/animations/{anim}/south/frame_\d+\.png$", n))
            if picks is not None:
                names = [names[i] for i in picks]
            out = f"{root}/combat/boss/{species}/{anim.removeprefix('boss_')}"
            os.makedirs(out, exist_ok=True)
            for old in os.listdir(out):
                if old.startswith("frame_"):
                    os.remove(os.path.join(out, old))
            for i, n in enumerate(names):
                with open(f"{out}/frame_{i:03d}.png", "wb") as f:
                    f.write(z.read(n))
            print(species, anim, len(names))


if __name__ == "__main__":
    main()
