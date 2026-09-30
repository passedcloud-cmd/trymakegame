"""반딧불 마을 맵에 쓰는 임시 픽셀 아트를 만드는 스크립트예요.

실행: python3 tools/make_village_art.py  (Pillow 필요: pip install pillow)
만들어진 그림은 assets/village/ 폴더에 저장돼요.
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "village"
T = 16  # 타일 한 칸 크기

OUTLINE = (34, 30, 38, 255)
CLEAR = (0, 0, 0, 0)


def rgba(r, g, b, a=255):
    return (r, g, b, a)


# ── 바닥 타일 ───────────────────────────────────────────

def speckle(img, ox, oy, colors, count, seed):
    rnd = random.Random(seed)
    for _ in range(count):
        x, y = rnd.randrange(T), rnd.randrange(T)
        img.putpixel((ox + x, oy + y), rnd.choice(colors))


def tile_fill(img, col, row, color):
    ImageDraw.Draw(img).rectangle([col * T, row * T, col * T + T - 1, row * T + T - 1], fill=color)


def tuft(img, x, y, color):
    """풀 한 포기 (V 모양 3픽셀)."""
    for dx, dy in [(0, 0), (-1, -1), (1, -1)]:
        img.putpixel((x + dx, y + dy), color)


def make_tiles():
    """타일 모음 (가로 8칸 × 세로 4줄).

    1줄: 풀, 풀(포기), 꽃밭, 흙길, 흙길(자갈), 물, 물(반짝), 숲 바닥
    2줄: 울타리(가로), 울타리(세로), 울타리 기둥, 덤불, 긴 풀, 연못 윗가장자리, 숲 바닥(풀), 숲 바닥(버섯)
    3줄: 다리(위), 다리(아래), 부서진 다리 왼쪽(위/아래), 부서진 다리 오른쪽(위/아래), 끊어진 틈(물), 바위 땅
    4줄: 절벽, 바위 땅(자갈)
    """
    img = Image.new("RGBA", (T * 8, T * 4), CLEAR)
    grass, grass_d, grass_l = rgba(74, 124, 89), rgba(60, 106, 76), rgba(98, 150, 104)
    path, path_d, path_l = rgba(190, 158, 112), rgba(160, 128, 88), rgba(214, 186, 140)
    water, water_d, water_l = rgba(64, 108, 160), rgba(52, 90, 140), rgba(120, 170, 215)
    forest, forest_d, forest_l = rgba(44, 82, 64), rgba(34, 66, 52), rgba(62, 104, 78)
    wood, wood_d = rgba(150, 102, 64), rgba(104, 68, 44)

    # 0: 풀
    tile_fill(img, 0, 0, grass)
    speckle(img, 0, 0, [grass_d, grass_l], 10, 1)
    # 1: 풀 + 풀 포기
    tile_fill(img, 1, 0, grass)
    speckle(img, T, 0, [grass_d], 6, 2)
    tuft(img, T + 4, 6, grass_l)
    tuft(img, T + 11, 12, grass_l)
    # 2: 꽃밭
    tile_fill(img, 2, 0, grass)
    speckle(img, T * 2, 0, [grass_d], 6, 3)
    for (x, y), c in zip([(3, 3), (11, 5), (6, 11), (13, 13)],
                         [rgba(255, 226, 120), rgba(250, 170, 190), rgba(255, 250, 240), rgba(255, 226, 120)]):
        img.putpixel((T * 2 + x, y), c)
        img.putpixel((T * 2 + x, y + 1), grass_d)
    # 3: 흙길
    tile_fill(img, 3, 0, path)
    speckle(img, T * 3, 0, [path_d, path_l], 12, 4)
    # 4: 흙길 + 자갈
    tile_fill(img, 4, 0, path)
    speckle(img, T * 4, 0, [path_d], 6, 5)
    for x, y in [(3, 4), (10, 9), (6, 13)]:
        ImageDraw.Draw(img).rectangle([T * 4 + x, y, T * 4 + x + 1, y + 1], fill=path_l)
        img.putpixel((T * 4 + x, y + 2), path_d)
        img.putpixel((T * 4 + x + 1, y + 2), path_d)
    # 5: 물
    tile_fill(img, 5, 0, water)
    speckle(img, T * 5, 0, [water_d], 8, 6)
    for x, y in [(2, 4), (9, 10)]:
        for dx in range(4):
            img.putpixel((T * 5 + x + dx, y), water_l)
    # 6: 물 (반짝)
    tile_fill(img, 6, 0, water)
    speckle(img, T * 6, 0, [water_d], 8, 7)
    for x, y in [(5, 3), (11, 12)]:
        for dx in range(3):
            img.putpixel((T * 6 + x + dx, y), water_l)
    img.putpixel((T * 6 + 3, 8), rgba(230, 245, 255))
    # 7: 숲 바닥
    tile_fill(img, 7, 0, forest)
    speckle(img, T * 7, 0, [forest_d, forest_l], 12, 8)

    # 아랫줄 (1) ─ 투명 배경 위에 그리는 것들
    d = ImageDraw.Draw(img)
    # 0: 울타리 가로
    ox, oy = 0, T
    for rail_y in (5, 10):
        d.rectangle([ox, oy + rail_y, ox + 15, oy + rail_y + 1], fill=wood)
        d.line([ox, oy + rail_y + 2, ox + 15, oy + rail_y + 2], fill=wood_d)
    for post_x in (2, 12):
        d.rectangle([ox + post_x - 1, oy + 2, ox + post_x + 1, oy + 14], fill=wood, outline=OUTLINE)
    # 1: 울타리 세로
    ox = T
    d.rectangle([ox + 6, oy, ox + 9, oy + 15], fill=wood)
    d.line([ox + 6, oy, ox + 6, oy + 15], fill=OUTLINE)
    d.line([ox + 9, oy, ox + 9, oy + 15], fill=OUTLINE)
    for y in (3, 11):
        d.line([ox + 7, oy + y, ox + 8, oy + y], fill=wood_d)
    # 2: 울타리 기둥
    ox = T * 2
    d.rectangle([ox + 5, oy + 1, ox + 10, oy + 14], fill=wood, outline=OUTLINE)
    d.line([ox + 6, oy + 2, ox + 9, oy + 2], fill=rgba(186, 136, 90))
    # 3: 덤불
    ox = T * 3
    bush, bush_d, bush_l = rgba(52, 110, 66), rgba(38, 84, 52), rgba(90, 150, 90)
    for cx, cy, r in [(5, 9, 5), (10, 8, 5), (8, 5, 4)]:
        d.ellipse([ox + cx - r, oy + cy - r, ox + cx + r, oy + cy + r], fill=OUTLINE)
    for cx, cy, r in [(5, 9, 4), (10, 8, 4), (8, 5, 3)]:
        d.ellipse([ox + cx - r, oy + cy - r, ox + cx + r, oy + cy + r], fill=bush)
    d.rectangle([ox + 3, oy + 11, ox + 12, oy + 12], fill=bush_d)
    for x, y in [(6, 4), (7, 3), (11, 6), (3, 8)]:
        img.putpixel((ox + x, oy + y), bush_l)
    img.putpixel((ox + 9, oy + 9), rgba(230, 90, 90))  # 빨간 열매
    img.putpixel((ox + 5, oy + 7), rgba(230, 90, 90))
    # 4: 긴 풀 (장식)
    ox = T * 4
    for x, h in [(3, 6), (5, 8), (7, 5), (10, 7), (12, 6)]:
        for y in range(h):
            img.putpixel((ox + x, oy + 14 - y), grass_l if y < h - 2 else rgba(130, 180, 110))
    # 5: 연못 윗가장자리 (흙 테두리 + 물)
    ox = T * 5
    d.rectangle([ox, oy, ox + 15, oy + 15], fill=water)
    d.rectangle([ox, oy, ox + 15, oy + 2], fill=path_d)
    d.line([ox, oy + 3, ox + 15, oy + 3], fill=water_d)
    for dx in range(4):
        img.putpixel((ox + 6 + dx, oy + 9), water_l)
    # 6: 숲 바닥 + 풀
    ox = T * 6
    d.rectangle([ox, oy, ox + 15, oy + 15], fill=forest)
    speckle(img, ox, oy, [forest_d], 8, 9)
    tuft(img, ox + 4, oy + 7, forest_l)
    tuft(img, ox + 12, oy + 12, forest_l)
    # 7: 숲 바닥 + 버섯
    ox = T * 7
    d.rectangle([ox, oy, ox + 15, oy + 15], fill=forest)
    speckle(img, ox, oy, [forest_d], 8, 10)
    d.rectangle([ox + 9, oy + 9, ox + 10, oy + 11], fill=rgba(230, 220, 200))
    d.rectangle([ox + 7, oy + 7, ox + 12, oy + 8], fill=rgba(200, 80, 90))
    img.putpixel((ox + 9, oy + 7), rgba(255, 240, 240))

    # 3줄 ─ 다리와 강
    oy = T * 2
    plank, plank_d, plank_l = rgba(166, 116, 72), rgba(118, 80, 50), rgba(196, 146, 96)

    def bridge(ox, rail_top):
        d.rectangle([ox, oy, ox + 15, oy + 15], fill=plank)
        for x in range(0, 16, 4):
            d.line([ox + x, oy, ox + x, oy + 15], fill=plank_d)
            img.putpixel((ox + x + 2, oy + 5), plank_l)
        rail_y = oy + 1 if rail_top else oy + 13
        d.rectangle([ox, rail_y, ox + 15, rail_y + 1], fill=rgba(100, 66, 42))
        d.line([ox, rail_y + (2 if rail_top else -1), ox + 15, rail_y + (2 if rail_top else -1)], fill=OUTLINE)

    def water_fill(ox):
        d.rectangle([ox, oy, ox + 15, oy + 15], fill=water)
        speckle(img, ox, oy, [water_d], 8, ox)
        for dx in range(4):
            img.putpixel((ox + 5 + dx, oy + 8), water_l)

    bridge(0, True)
    bridge(T, False)
    # 부서진 다리: 한쪽 끝이 들쭉날쭉하게 부서져서 물이 보여요.
    jag = [9, 11, 8, 12, 10, 9, 13, 10, 8, 11, 12, 9, 10, 8, 11, 12]
    for i, (rail_top, right_broken) in enumerate([(True, True), (False, True), (True, False), (False, False)]):
        ox = T * (2 + i)
        water_fill(ox)
        bridge(ox, rail_top)
        for y in range(16):
            cut = jag[y]
            xs = range(cut, 16) if right_broken else range(0, 16 - cut)
            for x in xs:
                img.putpixel((ox + x, oy + y), water if (x + y) % 5 else water_d)
            edge_x = cut - 1 if right_broken else 16 - cut
            img.putpixel((ox + edge_x, oy + y), OUTLINE)
    # 끊어진 틈 (물 위에 부서진 판자 조각이 떠 있어요)
    ox = T * 6
    water_fill(ox)
    d.rectangle([ox + 3, oy + 4, ox + 6, oy + 5], fill=plank_d)
    d.rectangle([ox + 9, oy + 11, ox + 12, oy + 12], fill=plank_d)
    # 바위 땅
    rock, rock_d, rock_l = rgba(118, 110, 104), rgba(96, 88, 84), rgba(146, 138, 128)
    ox = T * 7
    d.rectangle([ox, oy, ox + 15, oy + 15], fill=rock)
    speckle(img, ox, oy, [rock_d, rock_l], 14, 11)

    # 4줄 ─ 절벽, 바위 땅(자갈)
    oy = T * 3
    ox = 0
    d.rectangle([ox, oy, ox + 15, oy + 15], fill=rgba(84, 74, 72))
    for y in (3, 8, 13):
        d.line([ox, oy + y, ox + 15, oy + y], fill=rgba(62, 54, 54))
    for x, y in [(4, 1), (11, 5), (2, 10), (9, 11)]:
        d.line([ox + x, oy + y, ox + x + 3, oy + y], fill=rgba(112, 100, 96))
    ox = T
    d.rectangle([ox, oy, ox + 15, oy + 15], fill=rock)
    speckle(img, ox, oy, [rock_d], 8, 12)
    for x, y in [(3, 4), (10, 10)]:
        d.rectangle([ox + x, oy + y, ox + x + 1, oy + y + 1], fill=rock_l)
        d.line([ox + x, oy + y + 2, ox + x + 1, oy + y + 2], fill=rock_d)

    img.save(OUT / "tiles.png")


# ── 나무 ────────────────────────────────────────────────

def make_tree(filename, leaf, leaf_d, leaf_l):
    """나무 (32x40). 아래쪽 가운데가 나무 밑동이에요."""
    img = Image.new("RGBA", (32, 40), CLEAR)
    d = ImageDraw.Draw(img)
    trunk, trunk_d = rgba(110, 76, 52), rgba(78, 52, 38)
    # 그림자
    d.ellipse([7, 34, 24, 39], fill=rgba(20, 30, 25, 110))
    # 줄기
    d.rectangle([13, 24, 18, 36], fill=trunk, outline=OUTLINE)
    d.line([16, 26, 16, 35], fill=trunk_d)
    # 잎 (동그라미 여러 개)
    blobs = [(16, 13, 12), (9, 18, 7), (23, 18, 7), (16, 7, 8)]
    for cx, cy, r in blobs:
        d.ellipse([cx - r - 1, cy - r - 1, cx + r + 1, cy + r + 1], fill=OUTLINE)
    for cx, cy, r in blobs:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=leaf)
    # 그늘진 아랫부분
    d.chord([4, 12, 28, 26], 20, 160, fill=leaf_d)
    # 밝은 부분
    for cx, cy, r in [(12, 7, 3), (19, 10, 2), (8, 15, 2)]:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=leaf_l)
    img.save(OUT / filename)


# ── 집 ──────────────────────────────────────────────────

def make_house(filename, roof, roof_d, roof_l, sign=None):
    """집 (48x48). 창문에 따뜻한 불빛이 켜져 있어요."""
    img = Image.new("RGBA", (48, 48), CLEAR)
    d = ImageDraw.Draw(img)
    wall, wall_d = rgba(226, 204, 164), rgba(190, 164, 126)
    door, door_d = rgba(124, 82, 54), rgba(90, 58, 40)
    glow, glow_l = rgba(255, 206, 110), rgba(255, 238, 170)

    # 그림자
    d.rectangle([5, 44, 42, 46], fill=rgba(20, 30, 25, 110))
    # 벽
    d.rectangle([6, 22, 41, 44], fill=wall, outline=OUTLINE)
    for x in range(10, 40, 6):
        d.line([x, 23, x, 43], fill=wall_d)
    # 지붕 (사다리꼴)
    top_y, bottom_y = 4, 24
    for y in range(top_y, bottom_y + 1):
        t = (y - top_y) / (bottom_y - top_y)
        half = int(8 + t * 16)
        color = roof_d if (y - top_y) % 5 == 4 else roof
        d.line([24 - half, y, 24 + half - 1, y], fill=color)
        img.putpixel((24 - half, y), OUTLINE)
        img.putpixel((24 + half - 1, y), OUTLINE)
    d.line([16, top_y, 31, top_y], fill=OUTLINE)
    d.line([0, bottom_y, 47, bottom_y], fill=OUTLINE)
    d.line([18, top_y + 1, 29, top_y + 1], fill=roof_l)
    # 굴뚝
    d.rectangle([32, 2, 36, 10], fill=rgba(150, 90, 70), outline=OUTLINE)
    # 문
    d.rectangle([20, 31, 27, 44], fill=door, outline=OUTLINE)
    d.line([23, 32, 23, 43], fill=door_d)
    img.putpixel((26, 38), glow)
    # 창문 (불빛)
    for wx in (10, 31):
        d.rectangle([wx, 28, wx + 6, 34], fill=glow, outline=OUTLINE)
        d.line([wx + 3, 29, wx + 3, 33], fill=door_d)
        d.line([wx + 1, 31, wx + 5, 31], fill=door_d)
        img.putpixel((wx + 1, 29), glow_l)
    # 간판 (선택)
    if sign:
        d.rectangle([17, 25, 30, 29], fill=rgba(170, 120, 70), outline=OUTLINE)
        d.line([19, 27, 28, 27], fill=sign)
    img.save(OUT / filename)


# ── 너구리 가게 ─────────────────────────────────────────

def make_stall():
    """너구리 상인의 노점 (32x32)."""
    img = Image.new("RGBA", (32, 32), CLEAR)
    d = ImageDraw.Draw(img)
    wood, wood_d = rgba(150, 102, 64), rgba(104, 68, 44)
    # 그림자
    d.rectangle([3, 29, 28, 31], fill=rgba(20, 30, 25, 110))
    # 기둥
    d.rectangle([3, 8, 5, 29], fill=wood, outline=OUTLINE)
    d.rectangle([26, 8, 28, 29], fill=wood, outline=OUTLINE)
    # 차양 (빨강/하양 줄무늬)
    d.rectangle([1, 3, 30, 10], fill=OUTLINE)
    for i, x in enumerate(range(2, 30, 4)):
        c = rgba(210, 70, 70) if i % 2 == 0 else rgba(250, 240, 225)
        d.rectangle([x, 4, x + 3, 9], fill=c)
    for x in range(2, 30, 4):
        d.line([x, 10, x + 2, 10], fill=OUTLINE)
    # 판매대
    d.rectangle([2, 19, 29, 28], fill=wood, outline=OUTLINE)
    d.line([3, 23, 28, 23], fill=wood_d)
    # 도토리 상품
    for x in (7, 13, 19):
        d.rectangle([x, 15, x + 3, 16], fill=rgba(110, 70, 40))
        d.rectangle([x, 17, x + 3, 18], fill=rgba(205, 140, 70))
    # 빨간 열매 바구니
    d.rectangle([23, 16, 27, 18], fill=rgba(170, 120, 70), outline=OUTLINE)
    img.putpixel((24, 15), rgba(230, 80, 90))
    img.putpixel((26, 15), rgba(230, 80, 90))
    img.save(OUT / "stall.png")


# ── 가로등, 표지판 ──────────────────────────────────────

def make_lantern():
    """반딧불 가로등 (16x32)."""
    img = Image.new("RGBA", (16, 32), CLEAR)
    d = ImageDraw.Draw(img)
    d.ellipse([3, 28, 12, 31], fill=rgba(20, 30, 25, 110))
    d.rectangle([7, 9, 8, 30], fill=rgba(70, 60, 70), outline=None)
    d.line([6, 30, 9, 30], fill=OUTLINE)
    # 등
    d.rectangle([4, 3, 11, 10], fill=rgba(255, 220, 120), outline=OUTLINE)
    d.rectangle([6, 5, 9, 8], fill=rgba(255, 245, 200))
    d.line([4, 2, 11, 2], fill=OUTLINE)
    d.line([6, 1, 9, 1], fill=OUTLINE)
    img.save(OUT / "lantern.png")


def make_signpost():
    """나무 표지판 (16x16)."""
    img = Image.new("RGBA", (16, 16), CLEAR)
    d = ImageDraw.Draw(img)
    wood, wood_d = rgba(170, 118, 72), rgba(120, 82, 52)
    d.rectangle([7, 8, 8, 15], fill=wood_d)
    d.rectangle([1, 2, 14, 8], fill=wood, outline=OUTLINE)
    # 화살표 →
    d.line([4, 5, 10, 5], fill=wood_d)
    d.line([9, 4, 10, 5], fill=wood_d)
    d.line([9, 6, 10, 5], fill=wood_d)
    img.save(OUT / "signpost.png")


def make_light():
    """불빛 모양 (64x64, 가운데가 밝고 바깥으로 갈수록 투명)."""
    size = 64
    img = Image.new("RGBA", (size, size), CLEAR)
    for y in range(size):
        for x in range(size):
            dist = math.hypot(x - size / 2 + 0.5, y - size / 2 + 0.5) / (size / 2)
            a = max(0.0, 1.0 - dist)
            # 픽셀 게임에 어울리게 밝기를 몇 단계로 뚝뚝 끊어요.
            a = round(a * 4) / 4
            img.putpixel((x, y), (255, 255, 255, int(a * 255)))
    img.save(OUT / "light.png")


def make_star():
    """떨어진 별 (16x16, 2칸: 반짝이는 모습이 번갈아 나와요)."""
    sheet = Image.new("RGBA", (32, 16), CLEAR)
    gold, gold_l, gold_d = rgba(255, 222, 90), rgba(255, 250, 200), rgba(230, 160, 40)
    for frame in range(2):
        img = Image.new("RGBA", (16, 16), CLEAR)
        d = ImageDraw.Draw(img)
        cx, cy = 7.5, 8
        points = []
        for i in range(10):
            angle = -math.pi / 2 + i * math.pi / 5
            r = 7.5 if i % 2 == 0 else 3.2
            points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
        d.polygon(points, fill=gold, outline=gold_d)
        d.polygon([(cx + (px - cx) * 0.45, cy + (py - cy) * 0.45) for px, py in points], fill=gold_l)
        # 반짝임
        sparkle = [(2, 2), (13, 3)] if frame == 0 else [(13, 12), (1, 11)]
        for x, y in sparkle:
            for dx, dy in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]:
                if 0 <= x + dx < 16 and 0 <= y + dy < 16:
                    img.putpixel((x + dx, y + dy), gold_l)
        sheet.paste(img, (frame * 16, 0))
    sheet.save(OUT / "star.png")

    icon = Image.new("RGBA", (9, 9), CLEAR)
    rows = [
        "....o....",
        "...oyo...",
        "oooyyyooo",
        "oyyyyyyyo",
        ".oyyyyyo.",
        "..oyyyo..",
        ".oyyoyyo.",
        ".oyo.oyo.",
        ".oo...oo.",
    ]
    colors = {".": CLEAR, "o": rgba(120, 80, 20), "y": rgba(255, 222, 90)}
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            icon.putpixel((x, y), colors[ch])
    icon.save(OUT / "star_icon.png")


def make_cave():
    """캄캄한 동굴 입구 (32x32)."""
    img = Image.new("RGBA", (32, 32), CLEAR)
    d = ImageDraw.Draw(img)
    stone, stone_d, stone_l = rgba(110, 100, 96), rgba(80, 72, 70), rgba(140, 130, 122)
    d.ellipse([1, 2, 30, 44], fill=OUTLINE)
    d.ellipse([2, 3, 29, 43], fill=stone)
    d.ellipse([7, 9, 24, 44], fill=OUTLINE)
    d.ellipse([8, 10, 23, 44], fill=rgba(12, 10, 18))
    for x, y in [(4, 12), (26, 14), (6, 22), (25, 24), (15, 5)]:
        d.rectangle([x, y, x + 1, y + 1], fill=stone_l)
        img.putpixel((x, y + 2), stone_d)
    # 동굴 안에서 빛나는 두 눈...?
    img.putpixel((13, 20), rgba(160, 120, 200))
    img.putpixel((18, 20), rgba(160, 120, 200))
    img.save(OUT / "cave.png")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    make_tiles()
    make_tree("tree.png", rgba(64, 132, 72), rgba(44, 100, 58), rgba(104, 168, 92))
    make_tree("tree_dark.png", rgba(38, 78, 66), rgba(28, 58, 52), rgba(58, 104, 84))
    make_house("house_coral.png", rgba(226, 110, 70), rgba(186, 82, 52), rgba(250, 150, 110))
    make_house("house_owl.png", rgba(128, 88, 62), rgba(98, 66, 46), rgba(160, 118, 84),
               sign=rgba(255, 220, 120))
    make_house("house_rabbit.png", rgba(222, 140, 160), rgba(186, 108, 128), rgba(246, 184, 196))
    make_house("house_turtle.png", rgba(70, 140, 130), rgba(52, 110, 102), rgba(110, 178, 160))
    make_stall()
    make_lantern()
    make_signpost()
    make_light()
    make_star()
    make_cave()
    print("assets/village/ 폴더에 그림을 만들었어요.")
