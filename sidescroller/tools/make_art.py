"""임시 픽셀 아트(PNG)를 코드로 만드는 스크립트예요.

실행: python3 tools/make_art.py  (Pillow 필요: pip install pillow)
만들어진 그림은 assets/ 폴더에 저장돼요.
다운받은 에셋으로 **같은 이름, 같은 크기**로 덮어쓰면 바로 바뀌어요. (README의 그림 표 참고)

그리는 방법: 색깔 도형(네모, 동그라미)을 겹쳐 그린 다음,
마지막에 바깥쪽에 진한 테두리를 한 줄 둘러서 픽셀 아트처럼 보이게 해요.
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets"
rnd = random.Random(7)

INK = (22, 20, 34, 255)  # 테두리 색


def rgba(r, g, b, a=255):
    return (r, g, b, a)


def new(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def outline(img, color=INK):
    """투명한 칸 중에서 옆(상하좌우)에 색칠된 칸이 있으면 테두리 색으로 칠해요."""
    w, h = img.size
    src = img.load()
    out = img.copy()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 200 and src[nx, ny] != color:
                    dst[x, y] = color
                    break
    return out


def sheet(frames):
    """같은 크기 그림 여러 장을 가로로 이어 붙여요."""
    w, h = frames[0].size
    img = new(w * len(frames), h)
    for i, f in enumerate(frames):
        img.paste(f, (i * w, 0))
    return img


def ellipse(d, box, color):
    d.ellipse(box, fill=color)


def rect(d, x, y, w, h, color):
    d.rectangle((x, y, x + w - 1, y + h - 1), fill=color)


def px(img, x, y, color):
    if 0 <= x < img.size[0] and 0 <= y < img.size[1]:
        img.putpixel((x, y), color)


# ══════════════════════════════════════════════════════
# 🗡️ 주인공: 작은 기사 (24×24, 오른쪽을 보는 그림)
# ══════════════════════════════════════════════════════
HELMET = rgba(236, 236, 242)
HELMET_SHADE = rgba(196, 198, 214)
CLOAK = rgba(58, 66, 112)
CLOAK_SHADE = rgba(40, 45, 80)
SCARF = rgba(214, 62, 72)
SCARF_SHADE = rgba(160, 40, 56)
LEG = rgba(34, 34, 54)
EYE = rgba(18, 16, 28)
STEEL = rgba(210, 222, 240)


def knight(legs=((9, 20), (13, 20)), bob=0, lean=0, scarf="idle", eyes="normal",
           sword=False, leg_h=3, stretch=False):
    img = new(24, 24)
    d = ImageDraw.Draw(img)
    y0 = bob
    x0 = lean

    # 목도리 꼬리 (몸 뒤쪽, 왼쪽으로 휘날려요)
    tails = {
        "idle": [(7, 13), (6, 14), (6, 15)],
        "run0": [(6, 12), (5, 12), (4, 13), (3, 13)],
        "run1": [(6, 13), (5, 13), (4, 12), (3, 12)],
        "up": [(7, 11), (6, 10), (5, 9), (5, 8)],
        "down": [(6, 12), (5, 11), (4, 10)],
        "long": [(6, 12), (5, 12), (4, 12), (3, 13), (2, 13), (1, 13), (0, 12)],
    }
    for tx, ty in tails[scarf]:
        rect(d, tx + x0, ty + y0, 2, 2, SCARF)

    # 다리
    for lx, ly in legs:
        rect(d, lx + x0, ly + y0 if ly + y0 + leg_h <= 23 else 23 - leg_h, 2, leg_h, LEG)

    # 망토 (위가 좁고 아래가 넓은 사다리꼴)
    if stretch:
        d.polygon([(6 + x0, 12 + y0), (16 + x0, 12 + y0), (15 + x0, 19 + y0), (3 + x0, 19 + y0)], fill=CLOAK)
        d.line([(4 + x0, 19 + y0), (15 + x0, 19 + y0)], fill=CLOAK_SHADE)
    else:
        d.polygon([(8 + x0, 12 + y0), (15 + x0, 12 + y0), (17 + x0, 20 + y0), (6 + x0, 20 + y0)], fill=CLOAK)
        d.line([(6 + x0, 20 + y0), (17 + x0, 20 + y0)], fill=CLOAK_SHADE)
        d.line([(7 + x0, 18 + y0), (7 + x0, 19 + y0)], fill=CLOAK_SHADE)

    # 투구 (하얀 동그라미 + 작은 뿔 두 개)
    hx = x0 + (1 if stretch else 0)
    rect(d, 8 + hx, 1 + y0, 2, 3, HELMET)
    rect(d, 15 + hx, 1 + y0, 2, 3, HELMET)
    px(img, 7 + hx, 0 + y0, HELMET)
    px(img, 17 + hx, 0 + y0, HELMET)
    ellipse(d, (6 + hx, 2 + y0, 18 + hx, 13 + y0), HELMET)
    d.arc((6 + hx, 2 + y0, 18 + hx, 13 + y0), 110, 200, fill=HELMET_SHADE)

    # 눈 (오른쪽을 보고 있어서 오른쪽으로 치우쳐 있어요)
    if eyes == "normal":
        rect(d, 11 + hx, 6 + y0, 2, 4, EYE)
        rect(d, 15 + hx, 6 + y0, 2, 4, EYE)
    elif eyes == "hurt":
        for ex in (11, 15):
            px(img, ex + hx, 6 + y0, EYE); px(img, ex + 1 + hx, 7 + y0, EYE)
            px(img, ex + hx, 8 + y0, EYE); px(img, ex + 1 + hx, 6 + y0, EYE)
            px(img, ex + hx, 7 + y0, EYE); px(img, ex + 1 + hx, 8 + y0, EYE)
    elif eyes == "up":
        rect(d, 11 + hx, 5 + y0, 2, 3, EYE)
        rect(d, 15 + hx, 5 + y0, 2, 3, EYE)

    # 목도리 (목에 두른 부분)
    rect(d, 8 + x0, 12 + y0, 9, 2, SCARF)
    rect(d, 8 + x0, 13 + y0, 9, 1, SCARF_SHADE)

    # 바늘 검 (공격할 때)
    if sword:
        d.line([(15 + x0, 15 + y0), (23, 15 + y0)], fill=STEEL)
        rect(d, 14 + x0, 14 + y0, 2, 3, rgba(140, 110, 70))
    return outline(img)


def make_knight():
    frames = [
        knight(),                                              # 0 서 있기 1
        knight(bob=1, scarf="idle"),                           # 1 서 있기 2 (숨쉬기)
        knight(legs=((7, 19), (14, 20)), scarf="run0"),        # 2 달리기 1
        knight(legs=((10, 20), (12, 19)), bob=-1, scarf="run1"),  # 3 달리기 2
        knight(legs=((14, 19), (8, 20)), scarf="run0"),        # 4 달리기 3
        knight(legs=((12, 20), (10, 19)), bob=-1, scarf="run1"),  # 5 달리기 4
        knight(legs=((9, 18), (13, 18)), leg_h=2, scarf="down"),  # 6 점프 (올라감)
        knight(legs=((9, 20), (14, 20)), scarf="up"),          # 7 떨어짐
        knight(legs=((7, 20), (15, 20)), lean=1, sword=True, scarf="run0"),  # 8 공격
        knight(legs=((4, 18), (7, 19)), leg_h=2, scarf="long", stretch=True),  # 9 대시
        knight(legs=((8, 20), (14, 19)), lean=-1, eyes="hurt", scarf="up"),  # 10 맞음
        knight(eyes="up"),                                     # 11 위 보기
    ]
    sheet(frames).save(OUT / "knight.png")


def make_slash():
    """검 휘두르기 효과 (32×24, 오른쪽 방향). 위/아래 공격은 코드에서 돌려서 써요."""
    img = new(32, 24)
    d = ImageDraw.Draw(img)
    d.ellipse((2, 0, 31, 23), fill=rgba(255, 255, 255, 235))
    d.ellipse((-6, 3, 25, 20), fill=rgba(0, 0, 0, 0))
    # 안쪽 가장자리를 하늘색으로
    src = img.load()
    for y in range(24):
        for x in range(1, 32):
            if src[x, y][3] > 0 and src[x - 1, y][3] == 0:
                src[x, y] = rgba(160, 210, 255, 220)
    img.save(OUT / "slash.png")


# ══════════════════════════════════════════════════════
# 🐛 몬스터
# ══════════════════════════════════════════════════════

def crawler(step):
    """이끼벌레 (16×12): 등껍질에 이끼가 낀 느린 벌레"""
    img = new(16, 12)
    d = ImageDraw.Draw(img)
    for i, lx in enumerate((4, 7, 10)):
        off = (i + step) % 2
        rect(d, lx + off, 9, 1, 2, rgba(50, 40, 40))
    ellipse(d, (1, 2, 14, 12), rgba(92, 150, 78))
    rect(d, 1, 9, 14, 1, rgba(64, 108, 58))
    for sx, sy in ((4, 4), (8, 3), (10, 6), (5, 7)):
        rect(d, sx, sy, 2, 1, rgba(138, 190, 96))
    ellipse(d, (11, 6, 15, 10), rgba(120, 96, 70))
    px(img, 13, 7, rgba(255, 230, 120))
    return outline(img)


def charger(kind):
    """뿔딱정벌레 (24×16): 멀리서 보면 뿔을 세우고 돌진해요"""
    img = new(24, 16)
    d = ImageDraw.Draw(img)
    body = rgba(120, 72, 110)
    shade = rgba(84, 48, 80)
    step = 1 if kind == "walk1" else 0
    for i, lx in enumerate((5, 9, 13, 17)):
        rect(d, lx + (step if i % 2 else -step), 12, 1, 3, rgba(40, 30, 40))
    ellipse(d, (2, 3, 19, 14), body)
    d.arc((2, 3, 19, 14), 180, 360, fill=rgba(166, 110, 150))
    rect(d, 2, 11, 17, 2, shade)
    d.line([(10, 4), (10, 12)], fill=shade)
    head_y = 5 if kind == "windup" else 7
    ellipse(d, (15, head_y, 21, head_y + 6), rgba(70, 44, 64))
    # 뿔
    horn = rgba(230, 212, 170)
    if kind == "windup":
        d.line([(19, head_y + 1), (22, head_y - 3)], fill=horn, width=2)
    else:
        d.line([(20, head_y + 2), (23, head_y)], fill=horn, width=2)
    eye = rgba(255, 70, 70) if kind in ("windup", "charge") else rgba(255, 220, 110)
    if kind == "dizzy":
        eye = rgba(160, 160, 200)
    px(img, 18, head_y + 2, eye)
    return outline(img)


def flyer(kind):
    """가시벌 (16×16): 하늘에 떠서 침을 쏴요"""
    img = new(16, 16)
    d = ImageDraw.Draw(img)
    wing = rgba(200, 230, 255, 170)
    if kind == "up":
        ellipse(d, (3, 0, 9, 6), wing)
    else:
        ellipse(d, (2, 4, 9, 9), wing)
    ellipse(d, (2, 6, 12, 13), rgba(236, 190, 60))
    rect(d, 5, 6, 2, 7, rgba(40, 32, 30))
    rect(d, 8, 6, 1, 7, rgba(40, 32, 30))
    ellipse(d, (10, 5, 15, 10), rgba(60, 46, 40))
    px(img, 13, 7, rgba(255, 90, 90) if kind == "windup" else rgba(255, 240, 200))
    # 꼬리 침
    d.line([(1, 11), (0, 13)], fill=rgba(40, 32, 30))
    if kind == "windup":
        ellipse(d, (11, 11, 15, 15), rgba(255, 150, 70))
    return outline(img)


def hopper(kind):
    """통통벼룩 (16×16): 웅크렸다가 크게 뛰어올라요"""
    img = new(16, 16)
    d = ImageDraw.Draw(img)
    body = rgba(80, 130, 200)
    if kind == "crouch":
        ellipse(d, (1, 7, 15, 15), body)
        rect(d, 1, 13, 4, 2, rgba(50, 80, 140))
        rect(d, 11, 13, 4, 2, rgba(50, 80, 140))
        eye_y = 9
    elif kind == "air":
        rect(d, 3, 11, 2, 4, rgba(50, 80, 140))
        rect(d, 11, 11, 2, 4, rgba(50, 80, 140))
        ellipse(d, (2, 1, 14, 12), body)
        eye_y = 4
    else:
        rect(d, 2, 12, 3, 3, rgba(50, 80, 140))
        rect(d, 11, 12, 3, 3, rgba(50, 80, 140))
        ellipse(d, (2, 4, 14, 14), body)
        eye_y = 7
    d.arc((2, 4 if kind != "air" else 1, 14, 14), 200, 300, fill=rgba(140, 190, 240))
    ellipse(d, (8, eye_y, 12, eye_y + 4), rgba(255, 255, 255))
    rect(d, 10, eye_y + 1, 2, 2, rgba(20, 20, 30))
    return outline(img)


def boss(kind):
    """투구벌레 대장 (64×48): 마지막 스테이지 보스"""
    img = new(64, 48)
    d = ImageDraw.Draw(img)
    shell = rgba(58, 52, 74)
    rim = rgba(104, 94, 132)
    dark = rgba(34, 30, 46)
    bob = 1 if kind == "idle1" else 0
    crouch = 3 if kind == "windup" else 0
    top = 8 + bob + crouch
    # 다리
    for i, lx in enumerate((12, 22, 32, 42)):
        rect(d, lx, 40, 3, 7, dark)
        rect(d, lx - 1 + (i % 2), 45, 5, 2, dark)
    # 몸통 (단단한 등껍질)
    ellipse(d, (4, top, 50, 44), shell)
    d.arc((4, top, 50, 44), 190, 340, fill=rim, width=2)
    d.line([(27, top + 2), (27, 42)], fill=dark)
    for sx, sy in ((14, top + 10), (36, top + 12), (20, top + 20), (40, top + 22)):
        ellipse(d, (sx, sy, sx + 4, sy + 3), rim)
    rect(d, 6, 38, 44, 4, dark)
    # 머리와 큰 뿔
    hy = top + 12
    ellipse(d, (42, hy, 60, hy + 16), rgba(46, 40, 60))
    horn = rgba(226, 204, 160)
    if kind == "windup":
        d.polygon([(52, hy + 2), (58, hy - 12), (61, hy - 12), (56, hy + 4)], fill=horn)
    else:
        d.polygon([(54, hy + 4), (63, hy - 4), (63, hy - 1), (57, hy + 8)], fill=horn)
    eye = rgba(255, 150, 60)
    if kind == "windup":
        eye = rgba(255, 60, 60)
    if kind == "stunned":
        eye = rgba(150, 150, 190)
    rect(d, 52, hy + 6, 3, 3, eye)
    rect(d, 47, hy + 7, 2, 2, eye)
    if kind == "stunned":
        for sx in (20, 30, 40):
            px(img, sx, top - 4, rgba(255, 240, 120))
            px(img, sx + 1, top - 5, rgba(255, 240, 120))
    return outline(img)


def make_enemies():
    sheet([crawler(0), crawler(1)]).save(OUT / "crawler.png")
    sheet([charger("walk0"), charger("walk1"), charger("windup"), charger("dizzy")]).save(OUT / "charger.png")
    sheet([flyer("up"), flyer("down"), flyer("windup")]).save(OUT / "flyer.png")
    sheet([hopper("idle"), hopper("crouch"), hopper("air")]).save(OUT / "hopper.png")
    sheet([boss("idle0"), boss("idle1"), boss("windup"), boss("stunned")]).save(OUT / "boss.png")

    # 몬스터가 쏘는 침 구슬 (8×8, 2장)
    frames = []
    for glow in (0, 1):
        img = new(8, 8)
        d = ImageDraw.Draw(img)
        ellipse(d, (1, 1, 6, 6), rgba(255, 120, 60))
        ellipse(d, (2, 2, 4 + glow, 4 + glow), rgba(255, 220, 140))
        frames.append(img)
    sheet(frames).save(OUT / "spit.png")

    # 땅을 타고 달리는 충격파 (16×16)
    img = new(16, 16)
    d = ImageDraw.Draw(img)
    d.polygon([(1, 15), (6, 3), (9, 1), (12, 6), (15, 15)], fill=rgba(255, 150, 60, 230))
    d.polygon([(5, 15), (8, 6), (11, 15)], fill=rgba(255, 230, 150))
    img.save(OUT / "shockwave.png")

    # 떨어지는 돌 (12×12)
    img = new(12, 12)
    d = ImageDraw.Draw(img)
    d.polygon([(2, 1), (8, 0), (11, 5), (9, 10), (3, 11), (0, 6)], fill=rgba(120, 110, 104))
    d.line([(3, 3), (7, 2)], fill=rgba(170, 160, 150))
    img = outline(img)
    img.save(OUT / "rock.png")

    # 돌이 떨어질 자리 표시 (16×4)
    img = new(16, 4)
    d = ImageDraw.Draw(img)
    d.ellipse((0, 0, 15, 3), fill=rgba(255, 70, 90, 200))
    d.ellipse((4, 1, 11, 2), fill=rgba(255, 180, 190, 230))
    img.save(OUT / "warning.png")


# ══════════════════════════════════════════════════════
# 🧑‍🌾 마을 사람들 (16×24, 2장: 보통 / 눈 감음)
# ══════════════════════════════════════════════════════

def villager(robe, robe_shade, head, hat=None, beard=False, extra=None, small=False):
    frames = []
    for blink in (False, True):
        img = new(16, 24)
        d = ImageDraw.Draw(img)
        top = 6 if small else 0
        # 몸 (옷)
        d.polygon([(5, 11 + top // 2), (10, 11 + top // 2), (13, 22), (2, 22)], fill=robe)
        d.line([(2, 22), (13, 22)], fill=robe_shade)
        # 머리
        hy = 3 + top
        ellipse(d, (3, hy, 12, hy + 9), head)
        if hat:
            hat(d, img, hy)
        eye_color = INK
        if blink:
            rect(d, 8, hy + 4, 2, 1, eye_color)
            rect(d, 5, hy + 4, 2, 1, eye_color)
        else:
            rect(d, 8, hy + 3, 1, 2, eye_color)
            rect(d, 5, hy + 3, 1, 2, eye_color)
        if beard:
            d.polygon([(4, hy + 6), (11, hy + 6), (9, hy + 12), (6, hy + 12)], fill=rgba(240, 240, 240))
        if extra:
            extra(d, img)
        frames.append(outline(img))
    return sheet(frames)


def make_villagers():
    # 촌장 할아버지: 갈색 두건, 흰 수염, 지팡이
    def elder_hat(d, img, hy):
        d.pieslice((2, hy - 2, 13, hy + 8), 180, 360, fill=rgba(120, 84, 60))

    def cane(d, img):
        d.line([(14, 10), (14, 22)], fill=rgba(150, 110, 70))
        px(img, 13, 10, rgba(150, 110, 70))
    villager(rgba(150, 110, 80), rgba(110, 80, 60), rgba(236, 200, 170), elder_hat, beard=True,
             extra=cane).save(OUT / "npc_elder.png")

    # 대장장이: 주황 앞치마, 망치
    def smith_band(d, img, hy):
        rect(d, 3, hy + 1, 10, 2, rgba(200, 60, 50))

    def hammer(d, img):
        d.line([(1, 12), (1, 19)], fill=rgba(120, 90, 60))
        rect(d, 0, 10, 3, 3, rgba(150, 150, 160))
        rect(d, 6, 15, 4, 6, rgba(230, 140, 60))
    villager(rgba(90, 80, 80), rgba(60, 54, 54), rgba(210, 160, 120), smith_band,
             extra=hammer).save(OUT / "npc_smith.png")

    # 약초상: 초록 모자에 잎사귀
    def leaf_hat(d, img, hy):
        d.pieslice((2, hy - 3, 13, hy + 7), 180, 360, fill=rgba(80, 150, 90))
        d.line([(8, hy - 3), (11, hy - 6)], fill=rgba(140, 210, 110), width=2)

    def basket(d, img):
        rect(d, 10, 15, 5, 4, rgba(190, 150, 90))
        px(img, 11, 14, rgba(230, 90, 110))
        px(img, 13, 14, rgba(120, 200, 110))
    villager(rgba(110, 160, 120), rgba(80, 120, 90), rgba(245, 214, 190), leaf_hat,
             extra=basket).save(OUT / "npc_herbalist.png")

    # 꼬마: 노란 투구를 쓴 작은 아이
    def kid_helmet(d, img, hy):
        d.pieslice((3, hy - 1, 12, hy + 8), 180, 360, fill=rgba(250, 210, 90))
        rect(d, 4, hy - 3, 2, 3, rgba(250, 210, 90))
        rect(d, 10, hy - 3, 2, 3, rgba(250, 210, 90))
    villager(rgba(90, 170, 200), rgba(60, 120, 150), rgba(250, 226, 200), kid_helmet,
             small=True).save(OUT / "npc_kid.png")


# ══════════════════════════════════════════════════════
# 🧱 바닥 타일 (16×16, 가로 9칸 × 세로 3줄)
#   줄: 0 숲(마을·1스테이지), 1 동굴(2스테이지), 2 둥지(3스테이지)
#   칸: 0 윗면, 1 속, 2 왼쪽 위 모서리, 3 오른쪽 위 모서리, 4 왼쪽 벽, 5 오른쪽 벽,
#       6 발판(아래에서 뚫고 올라갈 수 있어요), 7 장식 1, 8 장식 2
# ══════════════════════════════════════════════════════
THEMES = [
    # (흙, 흙 그림자, 흙 점, 윗면, 윗면 밝은색, 발판, 장식1, 장식2)
    dict(dirt=(104, 70, 54), dirt_dark=(78, 52, 44), speck=(132, 94, 70),
         top=(84, 148, 70), top_light=(132, 196, 92), plank=(156, 110, 66)),
    dict(dirt=(62, 66, 92), dirt_dark=(44, 46, 68), speck=(90, 96, 128),
         top=(96, 104, 140), top_light=(150, 160, 196), plank=(110, 96, 88)),
    dict(dirt=(96, 58, 38), dirt_dark=(68, 40, 30), speck=(126, 80, 46),
         top=(170, 112, 40), top_light=(230, 170, 70), plank=(120, 84, 60)),
]


def fill_dirt(img, t, ox, oy, seed):
    r = random.Random(seed)
    d = ImageDraw.Draw(img)
    rect(d, ox, oy, 16, 16, rgba(*t["dirt"]))
    for _ in range(6):
        x, y = r.randrange(0, 15), r.randrange(0, 15)
        rect(d, ox + x, oy + y, 2, 1, rgba(*t["speck"]))
    for _ in range(4):
        x, y = r.randrange(0, 15), r.randrange(0, 15)
        px(img, ox + x, oy + y, rgba(*t["dirt_dark"]))


def draw_top(img, t, ox, oy, theme):
    d = ImageDraw.Draw(img)
    rect(d, ox, oy, 16, 4, rgba(*t["top"]))
    rect(d, ox, oy, 16, 1, rgba(*t["top_light"]))
    for x in range(16):
        # 들쭉날쭉한 아래쪽 가장자리
        if (x * 7 + theme) % 5 < 2:
            px(img, ox + x, oy + 4, rgba(*t["top"]))
        if (x * 3) % 7 == 0:
            px(img, ox + x, oy + 1, rgba(*t["top_light"]))


def make_tiles():
    img = new(16 * 9, 16 * 3)
    d = ImageDraw.Draw(img)
    for row, t in enumerate(THEMES):
        oy = row * 16
        for col in range(6):
            fill_dirt(img, t, col * 16, oy, row * 100 + col)
        dark = rgba(*t["dirt_dark"])
        # 0 윗면
        draw_top(img, t, 0, oy, row)
        # 2 왼쪽 위 모서리, 3 오른쪽 위 모서리
        draw_top(img, t, 32, oy, row)
        rect(d, 32, oy, 2, 12, rgba(*t["top"]))
        draw_top(img, t, 48, oy, row)
        rect(d, 62, oy, 2, 12, rgba(*t["top"]))
        # 4 왼쪽 벽, 5 오른쪽 벽
        rect(d, 64, oy, 1, 16, dark)
        rect(d, 95, oy, 1, 16, dark)
        # 6 발판
        rect(d, 96, oy, 16, 5, rgba(*t["plank"]))
        rect(d, 96, oy, 16, 1, rgba(min(255, t["plank"][0] + 40), min(255, t["plank"][1] + 40), min(255, t["plank"][2] + 30)))
        rect(d, 96, oy + 4, 16, 1, dark)
        px(img, 99, oy + 2, dark)
        px(img, 108, oy + 2, dark)
        rect(d, 98, oy + 5, 2, 3, dark)
        rect(d, 108, oy + 5, 2, 3, dark)
        # 7, 8 장식 (지나갈 수 있어요)
        if row == 0:
            for gx, gh in ((3, 5), (5, 7), (7, 4), (10, 6), (12, 4)):
                d.line([(112 + gx, oy + 15), (112 + gx, oy + 16 - gh)], fill=rgba(110, 176, 84))
            d.line([(131, oy + 15), (131, oy + 10)], fill=rgba(90, 150, 70))
            ellipse(d, (129, oy + 7, 133, oy + 11), rgba(240, 120, 150))
            px(img, 131, oy + 9, rgba(255, 230, 120))
            ellipse(d, (136, oy + 12, 141, oy + 16), rgba(200, 90, 70))
            rect(d, 138, oy + 14, 1, 2, rgba(236, 226, 200))
        elif row == 1:
            d.polygon([(116, oy + 15), (118, oy + 7), (120, oy + 15)], fill=rgba(120, 200, 230))
            d.polygon([(120, oy + 15), (123, oy + 10), (125, oy + 15)], fill=rgba(170, 230, 250))
            ellipse(d, (132, oy + 11, 138, oy + 16), rgba(90, 96, 128))
            px(img, 134, oy + 12, rgba(130, 140, 170))
        else:
            for gx in (2, 6, 10, 13):
                d.line([(112 + gx, oy + 15), (112 + gx + (1 if gx % 2 else -1), oy + 9)], fill=rgba(150, 90, 50))
            # 작은 돌멩이 두 개 (빛조각과 헷갈리지 않게 어두운 색)
            ellipse(d, (130, oy + 12, 136, oy + 16), rgba(84, 52, 40))
            ellipse(d, (135, oy + 13, 140, oy + 16), rgba(70, 44, 34))
            px(img, 132, oy + 13, rgba(120, 80, 56))
    img.save(OUT / "tiles.png")

    # 가시 (16×16): 밟거나 닿으면 아파요
    img = new(16, 16)
    d = ImageDraw.Draw(img)
    for sx in (0, 5, 10):
        d.polygon([(sx, 15), (sx + 3, 6), (sx + 6, 15)], fill=rgba(190, 190, 206))
        d.line([(sx + 3, 7), (sx + 3, 14)], fill=rgba(240, 240, 250))
    rect(d, 0, 14, 16, 2, rgba(90, 80, 100))
    img.save(OUT / "spikes.png")


# ══════════════════════════════════════════════════════
# 🌄 배경 (320×180). 가로로 끝과 처음이 이어져서 계속 반복돼요.
# ══════════════════════════════════════════════════════

def gradient(img, top, bottom, y0=0, y1=None):
    y1 = y1 or img.size[1]
    d = ImageDraw.Draw(img)
    for y in range(y0, y1):
        k = (y - y0) / max(1, y1 - y0 - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * k) for i in range(3))
        d.line([(0, y), (img.size[0], y)], fill=rgba(*c))


def wave(x, parts):
    """끝과 처음이 이어지는 구불구불한 선 (320칸마다 똑같이 반복)"""
    return sum(a * math.sin(2 * math.pi * (k * x / 320) + p) for a, k, p in parts)


def ridge(img, base, parts, color, bottom=180):
    d = ImageDraw.Draw(img)
    for x in range(320):
        y = int(base + wave(x, parts))
        d.line([(x, y), (x, bottom)], fill=color)


def make_backgrounds():
    # 숲 (1스테이지) 먼 배경: 해질녘 하늘과 먼 언덕
    far = new(320, 180)
    gradient(far, (46, 58, 110), (230, 150, 120))
    d = ImageDraw.Draw(far)
    ellipse(d, (230, 40, 262, 72), rgba(255, 220, 160))
    ridge(far, 110, [(10, 2, 0), (6, 5, 1)], rgba(92, 88, 130))
    ridge(far, 130, [(8, 3, 2), (4, 7, 0)], rgba(66, 72, 108))
    far.save(OUT / "bg_forest_far.png")

    # 숲 가까운 배경: 나무줄기와 잎 그림자 (아래는 투명)
    near = new(320, 180)
    d = ImageDraw.Draw(near)
    for tx in range(10, 320, 46):
        w = 6 + (tx * 7) % 5
        rect(d, tx, 60, w, 120, rgba(40, 56, 60))
        ellipse(d, (tx - 18, 40 + (tx % 20), tx + w + 18, 90 + (tx % 20)), rgba(44, 76, 66))
    ridge(near, 150, [(6, 4, 0.5), (3, 9, 1)], rgba(36, 60, 56))
    near.save(OUT / "bg_forest_near.png")

    # 동굴 (2스테이지)
    far = new(320, 180)
    gradient(far, (20, 22, 40), (44, 52, 86))
    d = ImageDraw.Draw(far)
    r = random.Random(11)
    for _ in range(40):
        x, y = r.randrange(320), r.randrange(180)
        px(far, x, y, rgba(120, 200, 230, 160))
    ridge(far, 140, [(12, 3, 0), (5, 8, 2)], rgba(34, 38, 64))
    far.save(OUT / "bg_cave_far.png")

    near = new(320, 180)
    d = ImageDraw.Draw(near)
    for sx in range(0, 320, 20):
        h = 20 + int(18 * abs(math.sin(sx * 0.37)))
        d.polygon([(sx, 0), (sx + 10, h), (sx + 20, 0)], fill=rgba(30, 32, 54))
    ridge(near, 158, [(8, 5, 0), (4, 11, 1)], rgba(28, 30, 50))
    for cx in (40, 150, 260):
        d.polygon([(cx, 170), (cx + 4, 150), (cx + 8, 170)], fill=rgba(80, 150, 190))
    near.save(OUT / "bg_cave_near.png")

    # 둥지 (3스테이지): 붉은 굴과 벌집 무늬
    far = new(320, 180)
    gradient(far, (40, 20, 24), (110, 56, 40))
    d = ImageDraw.Draw(far)
    for hy in range(0, 180, 14):
        for hx in range(0, 320, 16):
            ox = 8 if (hy // 14) % 2 else 0
            d.regular_polygon(((hx + ox) % 320, hy, 6), 6, fill=None, outline=rgba(130, 70, 46))
    far.save(OUT / "bg_nest_far.png")

    near = new(320, 180)
    d = ImageDraw.Draw(near)
    for rx in range(8, 320, 32):
        length = 30 + (rx * 13) % 40
        for y in range(length):
            x = rx + int(3 * math.sin(y * 0.2 + rx))
            rect(d, x, y, 3, 1, rgba(60, 30, 26))
    ridge(near, 155, [(7, 3, 1), (5, 8, 0)], rgba(56, 28, 24))
    near.save(OUT / "bg_nest_near.png")

    # 마을: 저녁노을과 멀리 보이는 지붕들
    far = new(320, 180)
    gradient(far, (70, 90, 160), (250, 190, 140))
    d = ImageDraw.Draw(far)
    ellipse(d, (60, 50, 96, 86), rgba(255, 236, 180))
    for cx, cy in ((150, 30), (200, 44), (270, 26)):
        ellipse(d, (cx, cy, cx + 40, cy + 10), rgba(255, 220, 200, 200))
    ridge(far, 120, [(8, 2, 1), (5, 5, 0)], rgba(120, 110, 150))
    far.save(OUT / "bg_village_far.png")

    near = new(320, 180)
    d = ImageDraw.Draw(near)
    for i, hx in enumerate(range(0, 320, 40)):
        h = 20 + (i * 7) % 16
        rect(d, hx + 4, 150 - h, 28, h + 30, rgba(90, 84, 120))
        d.polygon([(hx, 150 - h), (hx + 18, 136 - h), (hx + 36, 150 - h)], fill=rgba(76, 70, 104))
        rect(d, hx + 14, 156 - h, 5, 5, rgba(255, 210, 120))
    near.save(OUT / "bg_village_near.png")


# ══════════════════════════════════════════════════════
# 🏠 마을 소품, 🪙 아이템, ❤️ 화면 표시(HUD)
# ══════════════════════════════════════════════════════

def house(wall, roof, w=64, h=56):
    img = new(w, h)
    d = ImageDraw.Draw(img)
    rect(d, 6, 22, w - 12, h - 23, rgba(*wall))
    rect(d, 6, h - 4, w - 12, 3, rgba(max(0, wall[0] - 40), max(0, wall[1] - 40), max(0, wall[2] - 40)))
    d.polygon([(1, 24), (w // 2, 2), (w - 2, 24)], fill=rgba(*roof))
    d.line([(1, 24), (w - 2, 24)], fill=rgba(max(0, roof[0] - 50), max(0, roof[1] - 50), max(0, roof[2] - 50)), width=2)
    # 문과 창문
    rect(d, w // 2 - 6, h - 20, 12, 19, rgba(96, 64, 48))
    px(img, w // 2 + 3, h - 11, rgba(240, 200, 100))
    rect(d, 12, 30, 10, 9, rgba(255, 214, 120))
    rect(d, w - 22, 30, 10, 9, rgba(255, 214, 120))
    d.line([(17, 30), (17, 38)], fill=rgba(120, 90, 60))
    d.line([(w - 17, 30), (w - 17, 38)], fill=rgba(120, 90, 60))
    return outline(img)


def make_props():
    house((226, 208, 170), (190, 80, 70)).save(OUT / "house_1.png")
    house((200, 214, 226), (70, 110, 170)).save(OUT / "house_2.png")
    house((220, 196, 150), (110, 150, 80)).save(OUT / "house_3.png")

    # 대장간 (불빛 나는 화로)
    img = new(64, 56)
    d = ImageDraw.Draw(img)
    rect(d, 4, 20, 56, 35, rgba(120, 110, 110))
    d.polygon([(0, 22), (32, 6), (63, 22)], fill=rgba(70, 64, 70))
    rect(d, 44, 0, 8, 16, rgba(90, 84, 90))
    rect(d, 10, 32, 20, 22, rgba(40, 30, 30))
    ellipse(d, (13, 40, 27, 54), rgba(255, 140, 50))
    ellipse(d, (17, 44, 23, 52), rgba(255, 230, 120))
    rect(d, 38, 38, 16, 6, rgba(70, 70, 80))
    rect(d, 42, 44, 8, 10, rgba(60, 60, 70))
    outline(img).save(OUT / "forge.png")

    # 가로등 (8×32)
    img = new(10, 32)
    d = ImageDraw.Draw(img)
    rect(d, 4, 8, 2, 23, rgba(60, 56, 70))
    rect(d, 2, 30, 6, 2, rgba(60, 56, 70))
    rect(d, 1, 2, 8, 7, rgba(255, 220, 130))
    rect(d, 1, 1, 8, 1, rgba(60, 56, 70))
    outline(img).save(OUT / "lamp.png")

    # 부드러운 불빛 (48×48, 가운데가 밝고 바깥은 투명)
    img = new(48, 48)
    for y in range(48):
        for x in range(48):
            dist = math.hypot(x - 23.5, y - 23.5) / 24
            if dist < 1:
                a = int(90 * (1 - dist) ** 2)
                img.putpixel((x, y), rgba(255, 210, 130, a))
    img.save(OUT / "glow.png")

    # 나무 (40×56)
    img = new(40, 56)
    d = ImageDraw.Draw(img)
    rect(d, 17, 30, 6, 26, rgba(110, 76, 56))
    for bx, by, r in ((20, 16, 14), (10, 26, 10), (30, 26, 10), (20, 30, 11)):
        ellipse(d, (bx - r, by - r, bx + r, by + r), rgba(76, 140, 80))
    for bx, by in ((14, 12), (25, 20), (12, 26)):
        ellipse(d, (bx, by, bx + 5, by + 4), rgba(116, 180, 96))
    outline(img).save(OUT / "tree.png")

    # 표지판 (16×16)
    img = new(16, 16)
    d = ImageDraw.Draw(img)
    rect(d, 7, 8, 2, 8, rgba(110, 80, 56))
    rect(d, 1, 2, 14, 8, rgba(190, 150, 100))
    d.line([(3, 5), (12, 5)], fill=rgba(120, 90, 60))
    d.line([(3, 7), (10, 7)], fill=rgba(120, 90, 60))
    outline(img).save(OUT / "sign.png")

    # 숲으로 가는 문 (48×64): 돌 아치 + 빛나는 문
    frames = []
    for glow in range(4):
        img = new(48, 64)
        d = ImageDraw.Draw(img)
        rect(d, 4, 14, 10, 50, rgba(130, 130, 146))
        rect(d, 34, 14, 10, 50, rgba(130, 130, 146))
        d.pieslice((4, 0, 43, 36), 180, 360, fill=rgba(130, 130, 146))
        d.pieslice((13, 8, 34, 32), 180, 360, fill=rgba(0, 0, 0, 0))
        rect(d, 14, 19, 20, 45, rgba(0, 0, 0, 0))
        c = (110 + glow * 20, 200, 255)
        d.pieslice((14, 9, 33, 31), 180, 360, fill=rgba(*c, 200))
        rect(d, 14, 19, 20, 45, rgba(*c, 200))
        for i in range(5):
            yy = 20 + ((i * 9 + glow * 3) % 40)
            rect(d, 18 + (i * 5) % 12, yy, 2, 2, rgba(255, 255, 255, 220))
        for bx, by in ((6, 24), (36, 40), (8, 50)):
            rect(d, bx, by, 5, 2, rgba(100, 100, 116))
        frames.append(outline(img))
    sheet(frames).save(OUT / "gate.png")

    # 빛조각 (돈, 8×8, 빙글빙글 4장)
    frames = []
    for w in (3, 2, 1, 2):
        img = new(8, 8)
        d = ImageDraw.Draw(img)
        d.polygon([(4 - w, 4), (4, 0), (4 + w, 4), (4, 7)], fill=rgba(140, 220, 255))
        d.line([(4, 1), (4, 3)], fill=rgba(240, 255, 255))
        frames.append(outline(img))
    sheet(frames).save(OUT / "shard.png")

    # 회복 하트 (9×8)
    img = new(11, 10)
    d = ImageDraw.Draw(img)
    ellipse(d, (1, 1, 5, 5), rgba(236, 72, 96))
    ellipse(d, (5, 1, 9, 5), rgba(236, 72, 96))
    d.polygon([(1, 4), (9, 4), (5, 8)], fill=rgba(236, 72, 96))
    px(img, 3, 2, rgba(255, 190, 200))
    outline(img).save(OUT / "heart.png")

    # HUD 체력 (투구 모양 가면, 12×12): 가득 / 빈 칸
    for name, fill, eye in (("mask_full", rgba(240, 240, 246), INK), ("mask_empty", rgba(60, 60, 80, 200), rgba(40, 40, 56))):
        img = new(12, 12)
        d = ImageDraw.Draw(img)
        rect(d, 2, 1, 2, 3, fill)
        rect(d, 8, 1, 2, 3, fill)
        ellipse(d, (1, 2, 10, 11), fill)
        rect(d, 3, 5, 2, 3, eye)
        rect(d, 7, 5, 2, 3, eye)
        outline(img).save(OUT / f"{name}.png")

    # 대화 가능 표시 (말풍선 속 ↑, 11×11)
    img = new(11, 11)
    d = ImageDraw.Draw(img)
    rect(d, 1, 1, 9, 7, rgba(255, 250, 235))
    d.polygon([(4, 8), (6, 8), (5, 9)], fill=rgba(255, 250, 235))
    d.line([(5, 2), (5, 6)], fill=INK)
    d.line([(3, 4), (5, 2)], fill=INK)
    d.line([(7, 4), (5, 2)], fill=INK)
    outline(img).save(OUT / "talk_icon.png")


def make_preview():
    """모든 그림을 한 장에 모아서 확인하기 쉽게 만들어요. (게임에서는 안 써요)"""
    names = ["knight", "slash", "crawler", "charger", "flyer", "hopper", "boss", "spit", "shockwave",
             "rock", "npc_elder", "npc_smith", "npc_herbalist", "npc_kid", "tiles", "spikes", "gate",
             "shard", "heart", "mask_full", "mask_empty", "talk_icon", "house_1", "forge", "tree", "lamp", "sign"]
    imgs = [Image.open(OUT / f"{n}.png") for n in names]
    width = 360
    x = y = row_h = 0
    placed = []
    for im in imgs:
        if x + im.size[0] > width:
            x, y, row_h = 0, y + row_h + 4, 0
        placed.append((im, x, y))
        x += im.size[0] + 4
        row_h = max(row_h, im.size[1])
    canvas = Image.new("RGBA", (width, y + row_h), (120, 130, 150, 255))
    for im, px_, py_ in placed:
        canvas.alpha_composite(im, (px_, py_))
    canvas = canvas.resize((width * 3, (y + row_h) * 3), Image.NEAREST)
    return canvas


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    make_knight()
    make_slash()
    make_enemies()
    make_villagers()
    make_tiles()
    make_backgrounds()
    make_props()
    import sys
    if "--preview" in sys.argv:
        make_preview().save(sys.argv[-1])
    print("그림을 모두 만들었어요:", OUT)
