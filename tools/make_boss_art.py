"""그림자 곰(보스)과 관련된 임시 픽셀 아트를 만드는 스크립트예요.

실행: python3 tools/make_boss_art.py  (Pillow 필요: pip install pillow)
만들어진 그림은 assets/boss/ 폴더에 저장돼요.
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "boss"
CLEAR = (0, 0, 0, 0)
OUTLINE = (40, 26, 20, 255)
FUR = (120, 78, 50, 255)
FUR_D = (92, 58, 38, 255)
FUR_L = (150, 104, 70, 255)
MUZZLE = (206, 166, 124, 255)
NOSE = (40, 30, 30, 255)
CLAW = (236, 226, 210, 255)


def blob(d, box, fill):
    """테두리가 있는 동그라미."""
    x1, y1, x2, y2 = box
    d.ellipse([x1 - 1, y1 - 1, x2 + 1, y2 + 1], fill=OUTLINE)
    d.ellipse(box, fill=fill)


def draw_bear(pose):
    """곰 한 칸 (48x48). pose: idle, windup(두 팔 번쩍), charge(몸을 숙임), dazed(어질어질)."""
    img = Image.new("RGBA", (48, 48), CLEAR)
    d = ImageDraw.Draw(img)
    dy = 3 if pose == "charge" else 0
    # 그림자
    d.ellipse([8, 42, 39, 47], fill=(10, 8, 16, 110))
    # 다리
    for x in (13, 29):
        blob(d, [x, 37, x + 6, 45], FUR_D)
    # 몸통
    blob(d, [8, 20 + dy, 39, 44], FUR)
    d.ellipse([15, 27 + dy, 32, 42], fill=MUZZLE)
    # 팔
    if pose == "windup":
        for x in (1, 38):
            blob(d, [x, 6, x + 8, 22], FUR)
            for cx in range(x + 1, x + 8, 3):
                d.line([cx, 5, cx, 7], fill=CLAW)
    else:
        for x in (4, 36):
            blob(d, [x, 26 + dy, x + 8, 38 + dy], FUR)
            for cx in range(x + 1, x + 8, 3):
                d.line([cx, 38 + dy, cx, 40 + dy], fill=CLAW)
    # 귀
    for x in (10, 30):
        blob(d, [x, 2 + dy, x + 7, 9 + dy], FUR)
        d.ellipse([x + 2, 4 + dy, x + 5, 7 + dy], fill=FUR_D)
    # 머리
    blob(d, [11, 4 + dy, 36, 27 + dy], FUR)
    d.ellipse([15, 6 + dy, 22, 10 + dy], fill=FUR_L)
    # 주둥이, 코
    d.ellipse([18, 16 + dy, 29, 25 + dy], fill=MUZZLE)
    d.rectangle([22, 17 + dy, 25, 19 + dy], fill=NOSE)
    d.line([23, 20 + dy, 23, 22 + dy], fill=NOSE)
    if pose == "dazed":
        # 눈이 뱅글뱅글 (X 모양)
        for x in (16, 28):
            d.line([x, 12 + dy, x + 3, 15 + dy], fill=NOSE)
            d.line([x + 3, 12 + dy, x, 15 + dy], fill=NOSE)
        d.arc([20, 21 + dy, 27, 25 + dy], 0, 180, fill=NOSE)
    else:
        for x in (16, 28):
            d.rectangle([x, 12 + dy, x + 3, 14 + dy], fill=NOSE)
        if pose in ("windup", "charge"):
            d.line([19, 23 + dy, 28, 23 + dy], fill=NOSE)  # 이를 악문 입
    return img


def draw_bear_eyes(pose):
    """그림자에 덮였을 때 빛나는 빨간 눈 (곰 그림 위에 겹쳐 그려요)."""
    img = Image.new("RGBA", (48, 48), CLEAR)
    if pose == "dazed":
        return img
    d = ImageDraw.Draw(img)
    dy = 3 if pose == "charge" else 0
    for x in (16, 28):
        d.rectangle([x, 12 + dy, x + 3, 14 + dy], fill=(255, 90, 110, 255))
        img.putpixel((x + 1, 12 + dy), (255, 220, 220, 255))
    return img


def make_bear():
    poses = ["idle", "windup", "charge", "dazed"]
    sheet = Image.new("RGBA", (48 * 4, 48), CLEAR)
    eyes = Image.new("RGBA", (48 * 4, 48), CLEAR)
    for i, pose in enumerate(poses):
        sheet.paste(draw_bear(pose), (i * 48, 0))
        eyes.paste(draw_bear_eyes(pose), (i * 48, 0))
    sheet.save(OUT / "shadow_bear.png")
    eyes.save(OUT / "shadow_bear_eyes.png")


def make_cub():
    """아기 곰 (16x16, 2칸: 눈 뜸, 눈 감음)."""
    sheet = Image.new("RGBA", (32, 16), CLEAR)
    for frame in range(2):
        img = Image.new("RGBA", (16, 16), CLEAR)
        d = ImageDraw.Draw(img)
        d.ellipse([3, 14, 12, 15], fill=(10, 8, 16, 110))
        blob(d, [4, 9, 11, 14], FUR)
        d.ellipse([6, 10, 9, 13], fill=MUZZLE)
        for x in (2, 10):
            blob(d, [x, 1, x + 3, 4], FUR)
        blob(d, [3, 2, 12, 10], FUR)
        d.ellipse([6, 6, 9, 9], fill=MUZZLE)
        img.putpixel((7, 7), NOSE)
        img.putpixel((8, 7), NOSE)
        if frame == 0:
            img.putpixel((5, 5), NOSE)
            img.putpixel((10, 5), NOSE)
        else:
            d.line([4, 5, 5, 5], fill=NOSE)
            d.line([10, 5, 11, 5], fill=NOSE)
        img.putpixel((4, 7), (240, 150, 150, 255))
        img.putpixel((11, 7), (240, 150, 150, 255))
        sheet.paste(img, (frame * 16, 0))
    sheet.save(OUT / "bear_cub.png")


def make_orb():
    """그림자 구슬 (10x10)."""
    img = Image.new("RGBA", (10, 10), CLEAR)
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, 9, 9], fill=(20, 8, 30, 255))
    d.ellipse([1, 1, 8, 8], fill=(110, 50, 160, 255))
    d.ellipse([3, 2, 6, 5], fill=(200, 150, 240, 255))
    img.save(OUT / "shadow_orb.png")


def make_spike():
    """그림자 가시 (24x24, 2칸: 경고 동그라미, 솟아오른 가시)."""
    sheet = Image.new("RGBA", (48, 24), CLEAR)
    warn = Image.new("RGBA", (24, 24), CLEAR)
    d = ImageDraw.Draw(warn)
    d.ellipse([1, 8, 22, 22], outline=(200, 60, 120, 230))
    d.ellipse([4, 10, 19, 20], fill=(60, 20, 70, 110))
    sheet.paste(warn, (0, 0))
    spike = Image.new("RGBA", (24, 24), CLEAR)
    d = ImageDraw.Draw(spike)
    d.ellipse([2, 16, 21, 22], fill=(30, 12, 40, 200))
    for x, h in [(5, 12), (11, 20), (17, 14)]:
        d.polygon([(x - 3, 20), (x, 20 - h), (x + 3, 20)], fill=(70, 30, 100, 255), outline=(20, 8, 30, 255))
        d.line([x, 21 - h, x, 18], fill=(150, 90, 200, 255))
    sheet.paste(spike, (24, 0))
    sheet.save(OUT / "shadow_spike.png")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    make_bear()
    make_cub()
    make_orb()
    make_spike()
    print("assets/boss/ 폴더에 그림을 만들었어요.")
