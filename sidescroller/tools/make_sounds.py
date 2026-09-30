"""게임에 쓰는 효과음과 배경 음악(WAV)을 코드로 만드는 스크립트예요.

실행: python3 tools/make_sounds.py  (파이썬만 있으면 돼요. 따로 설치할 것 없음)
- 효과음: assets/sounds/*.wav
- 배경 음악: assets/music/*.wav  (처음과 끝이 자연스럽게 이어져서 계속 반복돼요)

8비트 게임기처럼 네모파, 세모파, 잡음을 섞어서 소리를 만들어요.
나중에 다운받은 소리로 같은 이름의 파일을 덮어쓰면 바로 바뀌어요.
"""
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RATE = 22050  # 1초에 몇 번 소리를 기록할지

rnd = random.Random(3)


# ── 기본 소리 모양 (파형) ───────────────────────────────

def square(phase, duty=0.5):
    return 1.0 if (phase % 1.0) < duty else -1.0


def triangle(phase):
    p = phase % 1.0
    return 4.0 * p - 1.0 if p < 0.5 else 3.0 - 4.0 * p


def saw(phase):
    return 2.0 * (phase % 1.0) - 1.0


def sine(phase):
    return math.sin(2 * math.pi * phase)


def noise(_phase):
    return rnd.uniform(-1.0, 1.0)


WAVES = {"square": square, "triangle": triangle, "saw": saw, "sine": sine, "noise": noise}


def midi_to_freq(note):
    return 440.0 * 2 ** ((note - 69) / 12)


# ── 소리 하나 만들기 ────────────────────────────────────

def tone(freq, length, wave_name="square", volume=0.5, attack=0.005, decay=None,
         freq_end=None, duty=0.5, vibrato=0.0, lowpass=None):
    """소리 조각 하나를 만들어요.

    freq_end를 주면 음 높이가 freq → freq_end로 미끄러져요.
    decay를 주면 그 시간 동안 소리가 점점 작아져요 (없으면 끝까지 유지하다 짧게 끝나요).
    """
    n = int(length * RATE)
    out = []
    phase = 0.0
    fn = WAVES[wave_name]
    smooth = 0.0
    for i in range(n):
        t = i / RATE
        f = freq if freq_end is None else freq + (freq_end - freq) * (i / max(n - 1, 1))
        if vibrato:
            f *= 1.0 + vibrato * math.sin(2 * math.pi * 6 * t)
        phase += f / RATE
        s = square(phase, duty) if wave_name == "square" else fn(phase)
        if lowpass:
            smooth += (s - smooth) * lowpass
            s = smooth
        # 볼륨 모양: 살짝 커졌다가(attack) 점점 작아져요(decay)
        env = min(1.0, t / attack) if attack > 0 else 1.0
        if decay:
            env *= max(0.0, 1.0 - t / decay) ** 2
        else:
            env *= min(1.0, (length - t) / 0.02)
        out.append(s * env * volume)
    return out


def mix(*parts, offsets=None):
    """여러 소리 조각을 겹쳐요. offsets로 각 조각이 시작하는 시간(초)을 정해요."""
    offsets = offsets or [0.0] * len(parts)
    total = max(int(o * RATE) + len(p) for p, o in zip(parts, offsets))
    out = [0.0] * total
    for p, o in zip(parts, offsets):
        start = int(o * RATE)
        for i, s in enumerate(p):
            out[start + i] += s
    return out


def seq(*parts, gap=0.0):
    """소리 조각들을 차례대로 이어 붙여요."""
    out = []
    for p in parts:
        out.extend(p)
        out.extend([0.0] * int(gap * RATE))
    return out


def save(samples, path, peak=0.6):
    """WAV 파일로 저장해요. 가장 큰 소리가 peak가 되도록 크기를 맞춰요 (0~1)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    top = max(1e-6, max(abs(s) for s in samples))
    scale = peak / top
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767)) for s in samples))


# ── 효과음 ──────────────────────────────────────────────

def make_sfx():
    out = ROOT / "assets" / "sounds"
    sfx = {
        # 기사
        "swipe": tone(900, 0.12, "noise", 0.5, decay=0.12, lowpass=0.3),
        "jump": tone(260, 0.12, "square", 0.3, decay=0.14, freq_end=520, duty=0.25),
        "land": tone(0, 0.06, "noise", 0.3, decay=0.06, lowpass=0.1),
        "dash": mix(tone(300, 0.2, "noise", 0.45, decay=0.2, lowpass=0.08),
                    tone(200, 0.16, "square", 0.12, decay=0.16, freq_end=500, duty=0.25)),
        "hurt": seq(tone(440, 0.08, "square", 0.4, freq_end=330, duty=0.25),
                    tone(300, 0.14, "square", 0.4, decay=0.14, freq_end=180, duty=0.25)),
        "faint": seq(*[tone(midi_to_freq(n), 0.16, "triangle", 0.45, decay=0.2) for n in (72, 69, 65, 60)]),
        "pogo": tone(500, 0.1, "square", 0.3, decay=0.1, freq_end=900, duty=0.125),
        # 몬스터
        "hit": mix(tone(600, 0.1, "square", 0.35, decay=0.1, freq_end=150, duty=0.25),
                   tone(0, 0.05, "noise", 0.35, decay=0.05)),
        "pop": mix(tone(300, 0.12, "sine", 0.4, decay=0.12, freq_end=900),
                   tone(0, 0.2, "noise", 0.25, decay=0.2, lowpass=0.15), offsets=[0, 0.05]),
        "warn": seq(tone(1200, 0.05, "square", 0.25, duty=0.125), tone(1200, 0.05, "square", 0.25, duty=0.125), gap=0.04),
        "shoot": tone(420, 0.16, "sine", 0.4, decay=0.16, freq_end=240),
        "charge": tone(0, 0.35, "noise", 0.35, attack=0.05, decay=0.35, lowpass=0.05),
        "clink": mix(tone(1800, 0.2, "triangle", 0.35, decay=0.2), tone(2700, 0.15, "sine", 0.2, decay=0.15)),
        "roar": mix(tone(95, 1.0, "saw", 0.5, attack=0.05, decay=1.0, freq_end=70, vibrato=0.08, lowpass=0.2),
                    tone(0, 0.9, "noise", 0.25, attack=0.05, decay=0.9, lowpass=0.06)),
        "boom": mix(tone(90, 0.5, "sine", 0.7, decay=0.5, freq_end=35),
                    tone(0, 0.35, "noise", 0.5, decay=0.35, lowpass=0.12)),
        "slam": mix(tone(110, 0.3, "sine", 0.7, decay=0.3, freq_end=40),
                    tone(0, 0.15, "noise", 0.4, decay=0.15, lowpass=0.2)),
        # 줍기, 강화
        "shard": seq(tone(1320, 0.04, "square", 0.25, duty=0.25), tone(1760, 0.07, "square", 0.25, decay=0.08, duty=0.25)),
        "heal": tone(400, 0.4, "sine", 0.45, decay=0.45, freq_end=900),
        "upgrade": seq(*[tone(midi_to_freq(n), 0.1, "square", 0.3, decay=0.14, duty=0.25) for n in (72, 76, 79, 84, 88)]),
        "clear": mix(*[tone(midi_to_freq(n), 0.3, "square", 0.25, decay=0.35, duty=0.25) for n in (72, 76, 79)],
                     tone(midi_to_freq(84), 0.8, "square", 0.3, decay=0.9, duty=0.25),
                     tone(midi_to_freq(60), 1.0, "triangle", 0.4, decay=1.0),
                     offsets=[0, 0.12, 0.24, 0.36, 0.36]),
        # 대화창, 메뉴
        "blip": tone(700, 0.025, "square", 0.25, duty=0.25),
        "cursor": tone(660, 0.04, "triangle", 0.35, decay=0.05),
        "select": seq(tone(660, 0.04, "square", 0.3, duty=0.25), tone(990, 0.07, "square", 0.3, decay=0.08, duty=0.25)),
        "no": seq(tone(220, 0.08, "square", 0.3, duty=0.5), tone(180, 0.12, "square", 0.3, decay=0.12, duty=0.5)),
        "whoosh": tone(0, 0.45, "noise", 0.35, attack=0.2, decay=0.45, lowpass=0.04),
    }
    # 소리마다 알맞은 크기 (적혀 있지 않으면 0.6)
    loudness = {"blip": 0.25, "cursor": 0.35, "select": 0.45, "boom": 0.85, "slam": 0.85, "roar": 0.8,
                "whoosh": 0.4, "land": 0.3, "jump": 0.4, "shard": 0.35, "warn": 0.4}
    for name, samples in sfx.items():
        save(samples, out / f"{name}.wav", peak=loudness.get(name, 0.6))
    return len(sfx)


# ── 배경 음악 ───────────────────────────────────────────

def render_song(bpm, bars, voices, beats_per_bar=4):
    """voices: [(악기 함수, [(음, 8분음표 길이), ...]), ...]
    끝에서 삐져나온 소리는 처음으로 돌려 보내서, 반복할 때 끊기지 않게 이어져요."""
    eighth = 60.0 / bpm / 2
    total = int(bars * beats_per_bar * 2 * eighth * RATE)
    out = [0.0] * total
    for instrument, notes in voices:
        t = 0.0
        for note, length in notes:
            if note is not None:
                samples = instrument(note, length * eighth)
                start = int(t * RATE)
                for i, s in enumerate(samples):
                    out[(start + i) % total] += s
            t += length * eighth
    return out


def music_box(note, length):
    return mix(tone(midi_to_freq(note), max(length, 0.6), "triangle", 0.35, decay=max(length, 0.6)),
               tone(midi_to_freq(note + 12), 0.4, "sine", 0.08, decay=0.4))


def soft_bass(note, length):
    return tone(midi_to_freq(note), length, "triangle", 0.3, attack=0.02, decay=length * 1.1)


def pluck(note, length):
    return tone(midi_to_freq(note), 0.25, "square", 0.12, decay=0.25, duty=0.25)


def lead(note, length):
    return tone(midi_to_freq(note), length * 0.9, "square", 0.18, duty=0.25, vibrato=0.004)


def bass_square(note, length):
    return tone(midi_to_freq(note), length * 0.8, "square", 0.18, duty=0.5, decay=length)


def kick(_note, _length):
    return tone(120, 0.12, "sine", 0.6, decay=0.12, freq_end=40)


def snare(_note, _length):
    return tone(0, 0.1, "noise", 0.3, decay=0.1, lowpass=0.5)


def hihat(_note, _length):
    return tone(0, 0.03, "noise", 0.1, decay=0.03)


def arp_pattern(chords, octave_up=12, pattern=(0, 1, 2, 1, 0, 1, 2, 1)):
    notes = []
    for chord in chords:
        notes += [(chord[i] + octave_up, 1) for i in pattern]
    return notes


C, AM, F, G, E, DM = [60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62], [52, 56, 59], [50, 53, 57]


def make_music():
    out = ROOT / "assets" / "music"

    # 🏡 마을: 느리고 포근한 오르골
    village_melody = [
        (76, 3), (79, 1), (81, 2), (79, 2),  (76, 4), (72, 4),
        (77, 3), (76, 1), (74, 2), (72, 2),  (74, 6), (None, 2),
        (76, 3), (79, 1), (84, 2), (83, 2),  (81, 4), (76, 4),
        (77, 2), (76, 2), (74, 2), (71, 2),  (72, 6), (None, 2),
    ]
    village_chords = [C, AM, F, G, C, AM, F, C]
    village = render_song(84, 8, [
        (music_box, village_melody),
        (pluck, arp_pattern(village_chords)),
        (soft_bass, [(c[0] - 12, 4) for c in village_chords for _ in range(2)]),
    ])
    save(village, out / "village.wav", peak=0.7)

    # 🌲 1스테이지 숲: 경쾌하게 달리는 느낌
    forest_chords = [C, G, AM, F, C, G, F, G]
    forest_melody = [
        (72, 1), (74, 1), (76, 2), (79, 2), (76, 2),  (74, 2), (71, 2), (67, 4),
        (69, 1), (71, 1), (72, 2), (76, 2), (72, 2),  (77, 4), (76, 2), (74, 2),
        (72, 1), (74, 1), (76, 2), (79, 2), (84, 2),  (83, 2), (79, 2), (74, 4),
        (77, 2), (76, 2), (74, 2), (72, 2),  (74, 4), (71, 4),
    ]
    bass = []
    for chord in forest_chords:
        r = chord[0] - 24
        bass += [(r, 2), (r + 12, 2), (r + 7, 2), (r + 12, 2)]
    forest = render_song(126, 8, [
        (lead, forest_melody),
        (bass_square, bass),
        (hihat, [(1, 1)] * 64),
        (kick, [(1, 4)] * 16),
    ])
    save(forest, out / "forest.wav", peak=0.7)

    # 🕳️ 2스테이지 동굴: 조용하고 신비롭게, 하지만 발걸음은 빠르게
    cave_chords = [AM, E, F, E, AM, E, DM, E]
    cave_notes = arp_pattern(cave_chords, octave_up=12, pattern=(0, 2, 1, 2, 0, 2, 1, 2))
    cave_melody = [
        (81, 6), (79, 2), (76, 8),
        (77, 6), (76, 2), (71, 8),
        (81, 4), (84, 4), (83, 4), (79, 4),
        (77, 4), (74, 4), (76, 8),
    ]
    cave = render_song(112, 8, [
        (pluck, cave_notes),
        (music_box, cave_melody),
        (soft_bass, [(c[0] - 12, 8) for c in cave_chords]),
    ])
    save(cave, out / "cave.wav", peak=0.65)

    # 🐞 3스테이지 둥지 + 보스: 빠르고 긴장감 있게
    boss_chords = [AM, F, G, E, AM, F, G, E]
    boss_melody = [
        (69, 2), (72, 2), (76, 2), (72, 2),  (69, 2), (72, 2), (77, 2), (72, 2),
        (71, 2), (74, 2), (79, 2), (74, 2),  (68, 2), (71, 2), (76, 4),
        (81, 3), (79, 1), (76, 2), (72, 2),  (77, 3), (76, 1), (72, 2), (69, 2),
        (71, 2), (74, 2), (79, 2), (83, 2),  (80, 4), (76, 4),
    ]
    bass_line = []
    for chord in boss_chords:
        r = chord[0] - 24
        bass_line += [(r, 1), (r, 1), (r + 12, 1), (r, 1), (r, 1), (r + 12, 1), (r, 1), (r + 7, 1)]
    boss = render_song(150, 8, [
        (lead, boss_melody),
        (bass_square, bass_line),
        (kick, [(1, 2), (None, 2)] * 16),
        (snare, [(None, 2), (1, 2)] * 16),
        (hihat, [(1, 1)] * 64),
    ])
    save(boss, out / "boss.wav", peak=0.75)

    # 🌟 엔딩: 밝고 따뜻하게
    ending_melody = [
        (72, 2), (76, 2), (79, 2), (84, 2),  (83, 4), (79, 4),
        (81, 2), (79, 2), (76, 2), (72, 2),  (77, 6), (None, 2),
        (76, 2), (79, 2), (84, 3), (83, 1),  (81, 2), (79, 2), (74, 4),
        (77, 2), (81, 2), (79, 2), (77, 2),  (72, 8),
    ]
    ending_chords = [C, G, AM, F, C, G, F, C]
    ending = render_song(96, 8, [
        (music_box, ending_melody),
        (pluck, arp_pattern(ending_chords, pattern=(0, 1, 2, 1, 2, 1, 0, 2))),
        (soft_bass, [(c[0] - 12, 2) for c in ending_chords for _ in range(4)]),
    ])
    save(ending, out / "ending.wav", peak=0.7)
    return 5


if __name__ == "__main__":
    n_sfx = make_sfx()
    n_music = make_music()
    print(f"효과음 {n_sfx}개, 배경 음악 {n_music}곡을 만들었어요.")
