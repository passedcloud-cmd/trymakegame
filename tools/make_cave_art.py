"""캄캄한 동굴에 쓰는 임시 픽셀 아트를 만드는 스크립트예요.

실행: python3 tools/make_cave_art.py  (Pillow 필요: pip install pillow)
만들어진 그림은 assets/cave/ 폴더에 저장돼요.
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "cave"
T = 16
CLEAR = (0, 0, 0, 0)
OUTLINE = (20, 16, 26, 255)


def rgba(r, g, b, a=255):
    return (r, g, b, a)


def speckle(img, ox, oy, colors, count, seed, w=T, h=T):
    rnd = random.Random(seed)
    for _ in range(count):
        img.putpixel((ox + rnd.randrange(w), oy + rnd.randrange(h)), rnd.choice(colors))


def make_tiles():
    """동굴 타일 (가로 5칸): 바닥, 바닥(자갈), 바닥(금), 벽, 벽 앞면."""
    img = Image.new("RGBA", (T * 5, T), CLEAR)
    d = ImageDraw.Draw(img)
    floor, floor_d, floor_l = rgba(64, 58, 74), rgba(50, 44, 60), rgba(82, 76, 94)
    wall, wall_d, wall_l = rgba(34, 28, 42), rgba(24, 20, 30), rgba(52, 46, 62)

    # 0: 바닥
    d.rectangle([0, 0, 15, 15], fill=floor)
    speckle(img, 0, 0, [floor_d, floor_l], 14, 1)
    # 1: 바닥 + 자갈
    d.rectangle([T, 0, T + 15, 15], fill=floor)
    speckle(img, T, 0, [floor_d], 8, 2)
    for x, y in [(3, 4), (10, 10), (12, 3)]:
        d.rectangle([T + x, y, T + x + 1, y + 1], fill=floor_l)
        d.line([T + x, y + 2, T + x + 1, y + 2], fill=floor_d)
    # 2: 바닥 + 금
    d.rectangle([T * 2, 0, T * 2 + 15, 15], fill=floor)
    speckle(img, T * 2, 0, [floor_d], 8, 3)
    d.line([T * 2 + 2, 5, T * 2 + 6, 8], fill=floor_d)
    d.line([T * 2 + 6, 8, T * 2 + 7, 13], fill=floor_d)
    d.line([T * 2 + 6, 8, T * 2 + 11, 9], fill=floor_d)
    # 3: 벽 (위에서 본 바위 덩어리)
    d.rectangle([T * 3, 0, T * 3 + 15, 15], fill=wall)
    speckle(img, T * 3, 0, [wall_d, wall_l], 16, 4)
    for x, y in [(2, 3), (9, 9)]:
        d.arc([T * 3 + x, y, T * 3 + x + 5, y + 4], 180, 360, fill=wall_l)
    # 4: 벽 앞면 (아래쪽이 바닥과 닿는 벽 - 절벽처럼 보여요)
    ox = T * 4
    d.rectangle([ox, 0, ox + 15, 15], fill=wall)
    speckle(img, ox, 0, [wall_d, wall_l], 6, 5, h=6)
    d.rectangle([ox, 6, ox + 15, 15], fill=rgba(74, 64, 84))
    for x in (2, 6, 11, 14):
        d.line([ox + x, 7, ox + x, 14], fill=rgba(58, 50, 68))
    d.line([ox, 6, ox + 15, 6], fill=wall_l)
    d.line([ox, 15, ox + 15, 15], fill=OUTLINE)
    img.save(OUT / "tiles.png")


def make_crystal():
    """빛나는 수정 (16x24). 캄캄한 동굴에서 길잡이가 돼요."""
    img = Image.new("RGBA", (16, 24), CLEAR)
    d = ImageDraw.Draw(img)
    c, c_l, c_d = rgba(110, 220, 230), rgba(210, 250, 255), rgba(60, 150, 180)
    d.ellipse([2, 20, 13, 23], fill=rgba(10, 10, 20, 120))
    for pts in [[(7, 2), (10, 8), (9, 21), (5, 21), (4, 8)],
                [(3, 10), (5, 13), (5, 21), (1, 21), (1, 13)],
                [(12, 8), (14, 12), (14, 21), (10, 21), (10, 12)]]:
        d.polygon(pts, fill=c, outline=OUTLINE)
    d.line([6, 6, 6, 18], fill=c_l)
    d.line([12, 12, 12, 19], fill=c_l)
    d.line([8, 9, 8, 20], fill=c_d)
    img.save(OUT / "crystal.png")


def make_veil():
    """그림자 장막 (32x16, 2칸: 꿈틀거리는 모습). 별빛을 비추면 사라져요."""
    sheet = Image.new("RGBA", (64, 16), CLEAR)
    for frame in range(2):
        rnd = random.Random(10 + frame)
        img = Image.new("RGBA", (32, 16), rgba(30, 14, 46, 215))
        for _ in range(70):
            x, y = rnd.randrange(32), rnd.randrange(16)
            img.putpixel((x, y), rnd.choice([rgba(80, 40, 120, 230), rgba(12, 6, 20, 240), rgba(120, 70, 170, 200)]))
        # 소용돌이 무늬
        d = ImageDraw.Draw(img)
        for i, x in enumerate(range(2 + frame * 3, 32, 9)):
            d.arc([x, 3 + (i % 2) * 3, x + 6, 9 + (i % 2) * 3], 0, 270, fill=rgba(150, 100, 200, 230))
        # 빛나는 눈 한 쌍
        if frame == 0:
            img.putpixel((14, 7), rgba(230, 200, 255))
            img.putpixel((18, 7), rgba(230, 200, 255))
        sheet.paste(img, (frame * 32, 0))
    sheet.save(OUT / "veil.png")


def make_mushroom():
    """빛나는 버섯 (16x16). 먹으면 최대 체력이 늘어요."""
    img = Image.new("RGBA", (16, 16), CLEAR)
    d = ImageDraw.Draw(img)
    d.ellipse([3, 13, 12, 15], fill=rgba(10, 10, 20, 120))
    d.rectangle([6, 8, 9, 14], fill=rgba(235, 225, 210), outline=OUTLINE)
    d.chord([1, 1, 14, 13], 180, 360, fill=rgba(120, 230, 170), outline=OUTLINE)
    d.line([2, 7, 13, 7], fill=OUTLINE)
    for x, y in [(4, 4), (9, 3), (11, 5)]:
        d.rectangle([x, y, x + 1, y + 1], fill=rgba(230, 255, 240))
    img.save(OUT / "glow_mushroom.png")


def make_jar_icon():
    """반딧불이 병 아이콘 (9x9)."""
    rows = [
        ".ooooo...",
        "..obo....",
        ".oyyyo...",
        "oyywyyo..",
        "oyyyyyo..",
        "oywyyyo..",
        "oyyyywo..",
        ".ooooo...",
        ".........",
    ]
    colors = {".": CLEAR, "o": rgba(40, 50, 60), "b": rgba(140, 100, 60),
              "y": rgba(180, 230, 120), "w": rgba(250, 255, 200)}
    img = Image.new("RGBA", (9, 9), CLEAR)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            img.putpixel((x, y), colors[ch])
    img.save(OUT / "jar_icon.png")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    make_tiles()
    make_crystal()
    make_veil()
    make_mushroom()
    make_jar_icon()
    print("assets/cave/ 폴더에 그림을 만들었어요.")
