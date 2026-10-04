#!/usr/bin/env python3
"""Synthesises the game's sound effects and music loop into assets/audio/.

Run from the repo root:  python3 tools/gen_audio.py   (needs numpy)
"""

import os
import wave

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
SR = 22050
rng = np.random.default_rng(7)


def t(dur):
    return np.arange(int(SR * dur)) / SR


def env(n, attack=0.005, decay=8.0):
    x = np.arange(n) / SR
    a = np.clip(x / max(attack, 1e-4), 0, 1)
    return a * np.exp(-x * decay)


def lowpass(x, k):
    kernel = np.ones(k) / k
    return np.convolve(x, kernel, mode="same")


def save(name, x, gain=0.8):
    x = x / (np.max(np.abs(x)) + 1e-9) * gain
    data = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("wrote", name, f"{len(x) / SR:.2f}s")


def bell(freq, dur, decay=5.0):
    tt = t(dur)
    s = np.sin(2 * np.pi * freq * tt) + 0.4 * np.sin(2 * np.pi * freq * 2.01 * tt) + 0.15 * np.sin(2 * np.pi * freq * 3.02 * tt)
    return s * env(len(tt), 0.003, decay)


def pop():
    tt = t(0.09)
    f = np.linspace(500, 1300, len(tt))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(tt), 0.002, 40)


def cash():
    a = bell(1318.5, 0.5, 7)
    b = bell(1760, 0.5, 6)
    out = np.zeros(int(SR * 0.6))
    out[: len(a)] += a
    off = int(SR * 0.07)
    out[off : off + len(b)] += b
    return out


def error():
    tt = t(0.28)
    sq = np.sign(np.sin(2 * np.pi * 170 * tt)) * 0.5
    gate = ((tt < 0.11) | (tt > 0.15)).astype(float)
    return lowpass(sq * gate * env(len(tt), 0.002, 4), 6)


def scrub():
    tt = t(0.22)
    n = rng.standard_normal(len(tt))
    n = n - lowpass(n, 9)
    am = 0.6 + 0.4 * np.sin(2 * np.pi * 18 * tt)
    return n * am * np.sin(np.pi * tt / tt[-1])


def paint():
    tt = t(0.3)
    n = lowpass(rng.standard_normal(len(tt)), 14)
    return n * env(len(tt), 0.004, 12) + 0.3 * np.sin(2 * np.pi * 120 * tt) * env(len(tt), 0.002, 25)


def place():
    tt = t(0.25)
    f = np.linspace(140, 60, len(tt))
    thud = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(tt), 0.002, 18)
    click = lowpass(rng.standard_normal(len(tt)), 3) * env(len(tt), 0.001, 90) * 0.4
    return thud + click


def complete():
    notes = [523.25, 659.25, 783.99, 1046.5]
    out = np.zeros(int(SR * 1.3))
    for i, f in enumerate(notes):
        b = bell(f, 0.9, 4)
        off = int(SR * 0.11 * i)
        out[off : off + len(b)] += b
    return out


def click():
    tt = t(0.035)
    return np.sin(2 * np.pi * 1800 * tt) * env(len(tt), 0.001, 120)


def rip():
    tt = t(0.32)
    n = rng.standard_normal(len(tt))
    crackle = (rng.random(len(tt)) > 0.97).astype(float) * rng.standard_normal(len(tt)) * 2
    body = lowpass(n, 5) + crackle
    return body * np.sin(np.pi * tt / tt[-1]) ** 0.5 * env(len(tt), 0.01, 5)


def whoosh():
    tt = t(0.35)
    n = rng.standard_normal(len(tt))
    out = np.zeros_like(n)
    for i, k in enumerate(np.linspace(30, 3, 8)):
        seg = slice(i * len(n) // 8, (i + 1) * len(n) // 8)
        out[seg] = lowpass(n, int(k))[seg]
    return out * np.sin(np.pi * tt / tt[-1])


def music():
    bpm = 92
    beat = 60 / bpm
    bars = 16
    total = int(SR * beat * 4 * bars)
    out = np.zeros(total + SR * 3)

    def add(sig, start):
        s = int(start * SR)
        out[s : s + len(sig)] += sig

    def note(midi):
        return 440 * 2 ** ((midi - 69) / 12)

    # Cmaj7, Am7, Fmaj7, G6 (two bars each pass, played twice)
    chords = [[48, 55, 59, 64], [45, 52, 55, 60], [41, 48, 52, 57], [43, 50, 52, 59]]
    for bar in range(bars):
        ch = chords[(bar // 2) % 4]
        t0 = bar * 4 * beat
        # pad
        dur = 4 * beat
        tt = t(dur + 0.5)
        pad = sum(np.sin(2 * np.pi * note(m + 12) * tt) + 0.3 * np.sin(2 * np.pi * note(m + 24) * tt * 1.002) for m in ch)
        pad_env = np.clip(tt / 0.6, 0, 1) * np.clip((dur + 0.5 - tt) / 0.6, 0, 1)
        add(pad * pad_env * 0.05, t0)
        # bass
        tt = t(beat * 1.8)
        for b in (0, 2):
            add(np.sin(2 * np.pi * note(ch[0] - 12) * tt) * env(len(tt), 0.01, 2.5) * 0.35, t0 + b * beat)
        # electric piano arpeggio
        pattern = [0, 2, 1, 3, 2, 1, 3, 2] if bar % 2 == 0 else [3, 2, 1, 2, 0, 1, 2, 3]
        for i, idx in enumerate(pattern):
            f = note(ch[idx] + 24)
            tt = t(0.8)
            ep = (np.sin(2 * np.pi * f * tt) + 0.25 * np.sin(2 * np.pi * 2 * f * tt)) * env(len(tt), 0.004, 5)
            add(ep * 0.11, t0 + i * beat / 2)
        # soft kick + shaker
        for b in range(4):
            if b in (0, 2):
                tt = t(0.3)
                f = np.linspace(110, 45, len(tt))
                add(np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(tt), 0.002, 14) * 0.35, t0 + b * beat)
            for h in range(2):
                tt = t(0.06)
                n = rng.standard_normal(len(tt))
                add((n - lowpass(n, 4)) * env(len(tt), 0.002, 60) * (0.05 if h else 0.03), t0 + b * beat + h * beat / 2)
    # wrap the tail into the start so the loop is seamless
    loop = out[:total].copy()
    loop[: len(out) - total] += out[total:]
    return lowpass(loop, 2)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    save("pop", pop(), 0.6)
    save("cash", cash(), 0.55)
    save("error", error(), 0.45)
    save("scrub", scrub(), 0.35)
    save("paint", paint(), 0.6)
    save("place", place(), 0.7)
    save("complete", complete(), 0.6)
    save("click", click(), 0.35)
    save("rip", rip(), 0.5)
    save("whoosh", whoosh(), 0.4)
    save("music", music(), 0.7)
