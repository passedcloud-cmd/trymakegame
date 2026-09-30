"""타이틀 화면 그림을 만드는 스크립트예요.

실행: python3 tools/make_title_art.py  (Pillow 필요: pip install pillow)
만들어진 그림은 assets/title/ 폴더에 저장돼요.
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "title"
W, H = 320, 180
rnd = random.Random(5)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def make_background():
    """밤하늘, 달, 언덕, 마을 불빛 (320x180)."""
    img = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(img)
    # 하늘: 위는 짙은 남색, 아래로 갈수록 보랏빛
    top, bottom = (12, 14, 38, 255), (66, 44, 96, 255)
    for y in range(H):
        t = (y / H) ** 1.3
        # 픽셀 게임답게 색을 몇 단계로 뚝뚝 끊어요.
        t = round(t * 10) / 10
        d.line([0, y, W, y], fill=lerp(top, bottom, t))
    # 작은 별 (움직이지 않는 별)
    for _ in range(70):
        x, y = rnd.randrange(W), rnd.randrange(110)
        c = rnd.choice([(200, 210, 255, 255), (255, 240, 200, 255), (150, 160, 210, 255)])
        img.putpixel((x, y), c)
    # 달 (제목 글자와 겹치지 않게 오른쪽 위에 있어요)
    mx, my = 292, 26
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for r, a in [(22, 25), (18, 45)]:
        gd.ellipse([mx - r, my - r, mx + r, my + r], fill=(255, 240, 200, a))
    img.alpha_composite(glow)
    d = ImageDraw.Draw(img)
    d.ellipse([mx - 13, my - 13, mx + 13, my + 13], fill=(255, 244, 210, 255))
    for cx, cy, cr in [(-4, -3, 3), (5, 4, 2), (3, -7, 1)]:
        d.ellipse([mx + cx - cr, my + cy - cr, mx + cx + cr, my + cy + cr], fill=(236, 220, 180, 255))

    # 먼 언덕
    far = (40, 38, 78, 255)
    pts = [(0, H)]
    for x in range(0, W + 1, 2):
        pts.append((x, 126 + 8 * math.sin(x / 40.0) + 4 * math.sin(x / 13.0 + 1)))
    pts.append((W, H))
    d.polygon(pts, fill=far)
    # 먼 숲 (뾰족한 나무 그림자)
    for x in range(200, W, 7):
        base = 126 + 8 * math.sin(x / 40.0) + 4 * math.sin(x / 13.0 + 1)
        h = rnd.randint(8, 14)
        d.polygon([(x - 4, base + 2), (x, base - h), (x + 4, base + 2)], fill=(30, 28, 60, 255))

    # 가까운 언덕 (코랄이 앉아 있는 언덕)
    near = (20, 20, 42, 255)
    pts = [(0, H)]
    for x in range(0, W + 1, 2):
        y = 150 + 6 * math.sin(x / 55.0 + 2)
        if 60 < x < 125:  # 코랄이 앉는 작은 봉우리
            y -= 12 * math.sin((x - 60) / 65.0 * math.pi)
        pts.append((x, y))
    pts.append((W, H))
    d.polygon(pts, fill=near)

    # 마을 지붕과 따뜻한 창문 불빛
    for hx in (170, 196, 226, 250, 282):
        base = 150 + 6 * math.sin(hx / 55.0 + 2)
        w, h = rnd.randint(14, 18), rnd.randint(9, 12)
        d.rectangle([hx - w // 2, base - h, hx + w // 2, base + 4], fill=(26, 24, 48, 255))
        d.polygon([(hx - w // 2 - 3, base - h), (hx, base - h - 8), (hx + w // 2 + 3, base - h)], fill=(26, 24, 48, 255))
        for wx in (hx - 4, hx + 2):
            d.rectangle([wx, base - h + 4, wx + 1, base - h + 5], fill=(255, 200, 110, 255))
    # 가로등 불빛 몇 개
    for lx in (184, 240, 268):
        base = 150 + 6 * math.sin(lx / 55.0 + 2)
        d.line([lx, base - 10, lx, base + 2], fill=(26, 24, 48, 255))
        d.rectangle([lx - 1, base - 12, lx + 1, base - 10], fill=(255, 220, 130, 255))
    # 가까운 나무 그림자
    for tx in (18, 40, 140, 305):
        base = 150 + 6 * math.sin(tx / 55.0 + 2)
        d.ellipse([tx - 9, base - 26, tx + 9, base - 6], fill=(16, 16, 34, 255))
        d.rectangle([tx - 1, base - 8, tx + 1, base + 2], fill=(16, 16, 34, 255))
    img.save(OUT / "title_bg.png")


def make_shooting_star():
    """별똥별 꼬리 (32x8). 오른쪽 끝이 머리예요."""
    img = Image.new("RGBA", (32, 8), (0, 0, 0, 0))
    for x in range(32):
        t = x / 31
        a = int(255 * t ** 2)
        img.putpixel((x, 4), (255, 245, 210, a))
        if x > 20:
            img.putpixel((x, 3), (255, 230, 170, a // 2))
            img.putpixel((x, 5), (255, 230, 170, a // 2))
    for dx, dy in [(0, 0), (-1, 0), (0, -1), (0, 1)]:
        img.putpixel((30 + dx, 4 + dy), (255, 255, 255, 255))
    img.save(OUT / "shooting_star.png")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    make_background()
    make_shooting_star()
    print("assets/title/ 폴더에 그림을 만들었어요.")
