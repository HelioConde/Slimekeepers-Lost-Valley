"""Check native capture output; requires Pillow. Does not modify images."""
from pathlib import Path
from PIL import Image, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[1] / "docs/world/day_night"
TIMES = ("manha", "dia", "tarde", "anoitecendo", "noite", "madrugada")
REGIONS = ("FlorestaDoDespertarV2", "ValeDasNascentes")


def luminance(image):
    rgb = ImageStat.Stat(image.convert("RGB")).mean
    return sum(a * b for a, b in zip(rgb, (.2126, .7152, .0722))) / 255


for region in REGIONS:
    images = {time: Image.open(ROOT / f"{region}_{time}.png").convert("RGB") for time in TIMES}
    day = images["dia"]
    for time, image in images.items():
        assert image.size == (1280, 720), (region, time, "resolution")
        # Interior of the fixed mission panel, Menu and instruction bar.
        for rect in ((30, 30, 470, 100), (1135, 30, 1240, 65), (270, 670, 1000, 695)):
            assert ImageChops.difference(day.crop(rect), image.crop(rect)).getbbox() is None, (region, time, "HUD tint")
    levels = {time: luminance(image.crop((30, 170, 1250, 590))) for time, image in images.items()}
    assert levels["dia"] > levels["noite"] > levels["madrugada"] > .12, (region, levels)
    assert levels["noite"] < levels["dia"] * .8, (region, "night is not distinct")
    print(region, "six captures, fixed HUD, distinct readable night: PASS")

forest = {time: Image.open(ROOT / f"{REGIONS[0]}_{time}.png") for time in ("dia", "reflection_off")}
for name, rect in (("trail", (660, 425, 680, 450)), ("water", (990, 390, 1010, 410))):
    assert luminance(forest["reflection_off"].crop(rect)) < luminance(forest["dia"].crop(rect)) * .8, name
print("Trail and water obey night tint: PASS")

for region in REGIONS:
    on = Image.open(ROOT / f"{region}_noite.png").convert("RGB")
    off = Image.open(ROOT / f"{region}_reflection_off.png").convert("RGB")
    moving = Image.open(ROOT / f"{region}_reflection_motion.png").convert("RGB")
    for comparison, label in ((off, "visible reflection"), (moving, "animated shimmer")):
        delta = ImageChops.difference(on, comparison)
        changed = sum(delta.convert("L").histogram()[9:])
        assert changed > 100, (region, label, changed)
        for rect in ((30, 30, 470, 100), (1135, 30, 1240, 65), (615, 260, 660, 350)):
            assert delta.crop(rect).getbbox() is None, (region, label, "HUD/player changed")
    print(region, "native reflection on/off and animation: PASS")
