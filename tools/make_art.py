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


def make_grass():
    """바닥 풀밭 타일 (16x16, 반복해서 깔려요)."""
    base, dark, light = (74, 124, 89), (58, 102, 72), (104, 156, 106)
    img = Image.new("RGBA", (16, 16), base)
    for x, y in [(2, 3), (3, 2), (10, 5), (11, 4), (6, 11), (7, 10), (13, 13), (14, 12)]:
        img.putpixel((x, y), light)
    for x, y in [(2, 4), (11, 5), (7, 11), (14, 13), (5, 6), (12, 9), (1, 13)]:
        img.putpixel((x, y), dark)
    img.save(OUT / "grass.png")


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


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    make_fox()
    make_grass()
    make_rock()
    print("assets/ 폴더에 그림을 만들었어요.")
