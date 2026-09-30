"""임시 픽셀 아트(PNG)를 만드는 스크립트예요.

실행: python3 tools/make_art.py  (Pillow 필요: pip install pillow)
만들어진 그림은 assets/ 폴더에 저장돼요. 나중에 다운받은 에셋으로 덮어써도 돼요.
"""
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "assets"

PALETTE = {
    ".": (0, 0, 0, 0),          # 투명
    "o": (59, 31, 36, 255),     # 테두리 (진한 갈색)
    "c": (255, 127, 80, 255),   # 코랄 주황
    "d": (214, 88, 52, 255),    # 주황 그림자
    "w": (255, 241, 214, 255),  # 크림색
    "k": (27, 27, 42, 255),     # 눈
    "n": (42, 26, 30, 255),     # 코
}


def mirror(half_rows):
    """왼쪽 절반(8칸)을 좌우 대칭으로 붙여서 16칸 줄을 만들어요."""
    return [row + row[::-1] for row in half_rows]


# ── 앞모습 (아래쪽을 볼 때) ──────────────────────────────
FRONT_HEAD = mirror([
    "........",
    "...oo...",
    "...oco..",
    "...owco.",
    "...owcoo",
    "..occccc",
    ".occcccc",
    ".occkccc",
    ".owwwccc",
    "..owwwwn",
    "...owwww",
    "...occcc",
    "..occwww",
    "..occcww",
])

# ── 뒷모습 (위쪽을 볼 때) ────────────────────────────────
BACK_HEAD = mirror([
    "........",
    "...oo...",
    "...odo..",
    "...oddo.",
    "...odcoo",
    "..occccc",
    ".occcccc",
    ".occcccc",
    ".occcccc",
    "..occccc",
    "...ooccc",
    "...occcd",
    "..occcdd",
    "..occcdc",
])
# 뒷모습에는 꼬리가 보여요 (가운데 아래, 끝이 하얀 꼬리)
BACK_TAIL = {(12, 6): "d", (12, 9): "d", (13, 6): "d", (13, 7): "w", (13, 8): "w", (13, 9): "d",
             (14, 6): "o", (14, 7): "w", (14, 8): "w", (14, 9): "o", (15, 7): "o", (15, 8): "o"}

# 앞/뒷모습 다리: [가만히, 왼발 들기, 가만히, 오른발 들기]
FB_LEGS = [
    ["...oddo..oddo...", "...oooo..oooo..."],
    ["...oooo..oddo...", ".........oooo..."],
    ["...oddo..oddo...", "...oooo..oooo..."],
    ["...oddo..oooo...", "...oooo........."],
]

# ── 옆모습 (오른쪽을 볼 때, 왼쪽은 좌우 뒤집어서 써요) ──────
SIDE_BODY = [
    "................",
    "................",
    "..........o.o...",
    ".........ococo..",
    "..oo.....occcco.",
    ".owwo...occckco.",
    ".owwco..occcwwwn",
    ".occco..owwwwwo.",
    "..occcoooccwoo..",
    "..odccccccwwo...",
    "...odcccccwwo...",
    "....occcccco....",
    "....oddddddo....",
]
SIDE_LEGS = [
    ["....od.o.od.o...", "....oo...oo....."],
    ["...od...o.od....", "...oo.....oo...."],
    ["....od.o.od.o...", "....oo...oo....."],
    [".....odod.oo....", ".....oo..oo....."],
]


def frame(rows):
    img = Image.new("RGBA", (16, 16))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            img.putpixel((x, y), PALETTE[ch])
    return img


def with_overlay(rows, overlay):
    rows = [list(r) for r in rows]
    for (y, x), ch in overlay.items():
        rows[y][x] = ch
    return ["".join(r) for r in rows]


def make_fox():
    """코랄 스프라이트 시트: 가로 4칸(걷기 동작) × 세로 3줄(아래/위/옆)."""
    sheet = Image.new("RGBA", (16 * 4, 16 * 3))
    for i in range(4):
        down = frame(FRONT_HEAD + FB_LEGS[i])
        up = frame(with_overlay(BACK_HEAD + FB_LEGS[i], BACK_TAIL))
        side_rows = SIDE_BODY + SIDE_LEGS[i]
        side = frame(side_rows + ["." * 16] * (16 - len(side_rows)))
        sheet.paste(down, (i * 16, 0))
        sheet.paste(up, (i * 16, 16))
        sheet.paste(side, (i * 16, 32))
    sheet.save(OUT / "coral.png")


def make_rock():
    """바위 (32x32)."""
    rows = [
        "................................",
        "................................",
        "..........oooooooooo............",
        "........ooccccccccccoo..........",
        ".......occwwwcccccccccoo........",
        "......occwwccccccccccccco.......",
        ".....occwcccccccccccccccoo......",
        "....occcccccccccccccccccccoo....",
        "....occcccccccccccccccccdddco...",
        "...occccccccccccccccccccddddo...",
        "...occcccccccccccccccccdddddo...",
        "..occcccccccccccccccccdddddddo..",
        "..occccccccccccccccccddddddddo..",
        "..occcccccccccccccccdddddddddo..",
        "..ocdcccccccccccccccdddddddddo..",
        "..ocddcccccccccccccddddddddddo..",
        "..oddddccccccccccccddddddddddo..",
        "..odddddcccccccccdddddddddddo...",
        "...odddddddcccccddddddddddddo...",
        "...oddddddddddddddddddddddoo....",
        "....ooddddddddddddddddddoo......",
        "......oooooooooooooooooo........",
    ]
    colors = {".": (0, 0, 0, 0), "o": (40, 40, 52, 255), "c": (150, 150, 165, 255),
              "w": (200, 200, 212, 255), "d": (108, 108, 125, 255)}
    img = Image.new("RGBA", (32, 32))
    top = 32 - len(rows) - 2
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            img.putpixel((x, y + top), colors[ch])
    img.save(OUT / "rock.png")


# ── 부엉이 촌장 ──────────────────────────────────────────
OWL_COLORS = {
    ".": (0, 0, 0, 0),
    "o": (48, 30, 28, 255),     # 테두리
    "b": (140, 98, 68, 255),    # 갈색 깃털
    "w": (240, 222, 190, 255),  # 얼굴 (크림색)
    "y": (255, 214, 90, 255),   # 노란 눈
    "k": (27, 27, 42, 255),     # 눈동자
    "e": (240, 150, 60, 255),   # 부리, 발
    "c": (224, 196, 150, 255),  # 배
    "v": (170, 120, 80, 255),   # 배 무늬
    "g": (120, 170, 110, 255),  # 촌장 목도리 (초록)
}
OWL_TOP = [
    "........",
    "..o.....",
    "..oboooo",
    ".obbbbbb",
    ".obwwwbb",
]
OWL_EYES_OPEN = [".owykywb", ".owykywb"]
OWL_EYES_CLOSED = [".owwwwwb", ".owkkkwb"]
OWL_BOTTOM = [
    ".obwwwbe",
    ".ogggggg",
    ".obbcccc",
    ".obbcvcv",
    "..obcccc",
    "...obbbb",
    "...oeeo.",
    "........",
]


def make_owl():
    """부엉이 촌장: 가로 2칸 (눈 뜬 모습, 눈 감은 모습)."""
    sheet = Image.new("RGBA", (32, 16))
    for i, eyes in enumerate([OWL_EYES_OPEN, OWL_EYES_CLOSED]):
        rows = mirror(OWL_TOP + eyes + OWL_BOTTOM)
        img = Image.new("RGBA", (16, 16))
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                img.putpixel((x, y), OWL_COLORS[ch])
        sheet.paste(img, (i * 16, 0))
    sheet.save(OUT / "owl_chief.png")


def make_talk_icon():
    """NPC 머리 위에 뜨는 말풍선 (11x10)."""
    rows = [
        ".ooooooooo.",
        "owwwwwwwwwo",
        "owwwwwwwwwo",
        "owkwwkwwkwo",
        "owwwwwwwwwo",
        ".ooowwoooo.",
        "...owo.....",
        "...oo......",
    ]
    colors = {".": (0, 0, 0, 0), "o": (27, 27, 42, 255), "w": (255, 250, 235, 255),
              "k": (27, 27, 42, 255)}
    img = Image.new("RGBA", (11, 8))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            img.putpixel((x, y), colors[ch])
    img.save(OUT / "talk_icon.png")


# ── 그림자 슬라임 ────────────────────────────────────────
SLIME_COLORS = {
    ".": (0, 0, 0, 0),
    "o": (25, 18, 40, 255),     # 테두리
    "h": (110, 88, 150, 255),   # 밝은 부분
    "p": (68, 48, 100, 255),    # 몸
    "d": (45, 32, 70, 255),     # 그림자
    "y": (255, 232, 120, 255),  # 빛나는 눈
}
SLIME_BODY = [
    "......oo",
    "....oohh",
    "...ohhpp",
    "..ohpppp",
    "..opyypp",
    "..opyypp",
    ".opppppp",
    ".oddpppp",
    "..oddddd",
    "...ooooo",
]


def make_slime():
    """그림자 슬라임: 가로 2칸 (보통, 납작) - 번갈아 보여서 통통 튀는 느낌을 줘요."""
    sheet = Image.new("RGBA", (32, 16))
    normal = ["........"] * 6 + SLIME_BODY
    # 납작한 모습: 몸 한 줄을 빼고 아래로 내려요.
    squashed = ["........"] * 7 + SLIME_BODY[:5] + SLIME_BODY[6:]
    for i, half in enumerate([normal, squashed]):
        rows = mirror(half)
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                sheet.putpixel((i * 16 + x, y), SLIME_COLORS[ch])
    sheet.save(OUT / "shadow_slime.png")


def make_hearts():
    """체력 하트 (9x8): 꽉 찬 하트, 빈 하트."""
    rows = [
        ".ooo.ooo.",
        "orrrorrro",
        "orwrrrrro",
        "orrrrrrro",
        ".orrrrro.",
        "..orrro..",
        "...oro...",
        "....o....",
    ]
    full = {".": (0, 0, 0, 0), "o": (27, 27, 42, 255), "r": (232, 72, 85, 255),
            "w": (255, 200, 200, 255)}
    empty = {".": (0, 0, 0, 0), "o": (27, 27, 42, 255), "r": (70, 62, 80, 255),
             "w": (70, 62, 80, 255)}
    for name, colors in [("heart_full.png", full), ("heart_empty.png", empty)]:
        img = Image.new("RGBA", (9, 8))
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                img.putpixel((x, y), colors[ch])
        img.save(OUT / name)


def make_tail_swipe():
    """꼬리 휘두르기 효과 (16x24, 오른쪽 방향 초승달 모양)."""
    img = Image.new("RGBA", (16, 24))
    cx, cy = 0.0, 11.5
    for y in range(24):
        for x in range(16):
            dist = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
            if x < 3:
                continue
            if 10 <= dist < 12:
                img.putpixel((x, y), (255, 241, 214, 255))
            elif 8 <= dist < 10:
                img.putpixel((x, y), (255, 160, 100, 220))
    img.save(OUT / "tail_swipe.png")


def make_blinking_npc(filename, colors, rows_open, rows_closed, overlay=None):
    """눈 뜬 모습 / 눈 감은 모습 2칸짜리 NPC 그림을 만들어요.
    rows_*는 왼쪽 절반(8칸)만 적으면 좌우 대칭으로 완성돼요."""
    sheet = Image.new("RGBA", (32, 16))
    for i, half in enumerate([rows_open, rows_closed]):
        rows = mirror(half)
        if overlay:
            rows = with_overlay(rows, overlay)
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                sheet.putpixel((i * 16 + x, y), colors[ch])
    sheet.save(OUT / filename)


def make_raccoon():
    """너구리 상인 (앞치마를 두른 떠돌이 상인)."""
    colors = {
        ".": (0, 0, 0, 0), "o": (40, 32, 36, 255), "g": (140, 135, 140, 255),
        "l": (200, 196, 196, 255), "m": (62, 58, 68, 255), "w": (245, 242, 235, 255),
        "k": (20, 18, 24, 255), "n": (30, 26, 30, 255), "r": (186, 92, 70, 255),
        "y": (230, 190, 90, 255),
    }
    top = [
        "........",
        ".oo.....",
        ".ogo....",
        ".oggoooo",
        "..oggggg",
        ".oglllgg",
        ".ommmmlg",
    ]
    bottom = [
        ".ogllwww",
        "..oglwwn",
        "...ogggg",
        "..ogrrrr",
        "..ogrrrr",
        "..ogryrr",
        "...oggo.",
        "...oooo.",
    ]
    make_blinking_npc("raccoon_merchant.png", colors,
                      top + [".omwkmlg"] + bottom, top + [".omkkmlg"] + bottom)


def make_rabbit():
    """겁많은 토끼 (식은땀 한 방울)."""
    colors = {
        ".": (0, 0, 0, 0), "o": (60, 44, 50, 255), "f": (246, 238, 228, 255),
        "s": (214, 200, 192, 255), "p": (240, 160, 172, 255), "k": (27, 27, 42, 255),
        "n": (230, 120, 140, 255), "b": (250, 190, 196, 255), "d": (120, 190, 240, 255),
    }
    top = [
        "...oo...",
        "..ofpo..",
        "..ofpo..",
        "..ofpo..",
        "..offooo",
        ".offffff",
        ".offffff",
    ]
    bottom = [
        "..offfff",
        "..osffff",
        ".osfffff",
        ".osfffff",
        "..osffff",
        "...offo.",
        "...oooo.",
    ]
    sweat = {(4, 14): "d", (5, 14): "d"}
    make_blinking_npc("timid_rabbit.png", colors,
                      top + [".offkfff", ".obfkffn"] + bottom,
                      top + [".offffff", ".obkkffn"] + bottom, sweat)


def make_baby_rabbit():
    """아기 토끼 (작은 토끼)."""
    colors = {
        ".": (0, 0, 0, 0), "o": (60, 44, 50, 255), "f": (246, 238, 228, 255),
        "s": (214, 200, 192, 255), "p": (240, 160, 172, 255), "k": (27, 27, 42, 255),
        "n": (230, 120, 140, 255), "b": (250, 190, 196, 255),
    }
    top = [
        "........",
        "........",
        "........",
        "...oo...",
        "..opo...",
        "..opo...",
        "..ofoooo",
        ".offffff",
        ".offffff",
    ]
    bottom = [
        "..offfff",
        "..osffff",
        "...offo.",
        "...oooo.",
        "........",
    ]
    make_blinking_npc("baby_rabbit.png", colors,
                      top + [".offkfff", ".offkffn"] + bottom,
                      top + [".offffff", ".offkkfn"] + bottom)


def make_turtle():
    """거북이 할머니 (동그란 안경을 쓴 할머니)."""
    colors = {
        ".": (0, 0, 0, 0), "o": (34, 44, 34, 255), "h": (150, 190, 120, 255),
        "H": (112, 150, 92, 255), "s": (120, 85, 60, 255), "S": (164, 122, 80, 255),
        "q": (222, 178, 70, 255), "k": (27, 27, 42, 255), "y": (228, 208, 150, 255),
        "w": (236, 236, 230, 255), "v": (150, 110, 170, 255),
    }
    top = [
        ".....ooo",
        "....owww",
        "...ohhhh",
        "..ohhhhh",
        "..oqqqhh",
    ]
    bottom = [
        "..oqqqhh",
        "..ohhhhh",
        "...oHhhh",
        ".osovvvv",
        "ossSovyy",
        "osSsoyyy",
        "ossSoyyy",
        ".osoohyy",
        "..ohho..",
        "..oooo..",
    ]
    make_blinking_npc("turtle_grandma.png", colors,
                      top + ["..oqkqhh"] + bottom, top + ["..oqHqhh"] + bottom)


def make_acorn():
    """도토리 (8x8)."""
    rows = [
        "...oo...",
        ".oooooo.",
        "occcccco",
        "oCCCCCCo",
        ".ohaaao.",
        ".oaaaao.",
        "..oaao..",
        "...oo...",
    ]
    colors = {".": (0, 0, 0, 0), "o": (48, 30, 24, 255), "c": (110, 70, 40, 255),
              "C": (140, 95, 55, 255), "a": (205, 140, 70, 255), "h": (240, 190, 115, 255)}
    img = Image.new("RGBA", (8, 8))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            img.putpixel((x, y), colors[ch])
    img.save(OUT / "acorn.png")


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    make_fox()
    make_rock()
    make_owl()
    make_talk_icon()
    make_slime()
    make_hearts()
    make_tail_swipe()
    make_raccoon()
    make_rabbit()
    make_baby_rabbit()
    make_turtle()
    make_acorn()
    print("assets/ 폴더에 그림을 만들었어요.")
