#!/usr/bin/env python3
"""Make the six UI sounds for Murim Life. No recordings: everything is synthesized.

Run:  python3 tools/make_sounds.py      (from the ui_pack folder)
Writes WAV files to ../sounds/. Change the notes or lengths below and run again.
"""
import os, wave
import numpy as np

SR = 44100
DEST = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sounds")
rng = np.random.default_rng(3)


def save(name, x, peak=0.5):
    x = x / max(1e-9, np.abs(x).max()) * peak
    n = int(0.004 * SR)                      # 4 ms fades so nothing pops
    x[:n] *= np.linspace(0, 1, n)
    x[-n:] *= np.linspace(1, 0, n)
    with wave.open(os.path.join(DEST, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    print(f"{name}.wav  {len(x) / SR * 1000:.0f} ms")


def lowpass(x, a):
    y = np.zeros_like(x); s = 0.0
    for i, v in enumerate(x):
        s += a * (v - s); y[i] = s
    return y


def tap(freq=520, dur=0.09):
    """Soft wooden tap: a sine that glides down a little, plus a puff of dull noise."""
    t = np.arange(int(dur * SR)) / SR
    f = freq * (1 + 0.25 * np.exp(-t * 60))
    tone = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 38)
    thud = lowpass(rng.standard_normal(len(t)), 0.08) * np.exp(-t * 90) * 0.5
    return tone + thud


def pluck(freq, dur=0.5, damp=0.996, soft=0.5):
    """Plucked string (Karplus-Strong), softened so it sounds like silk, not steel."""
    n = int(SR / freq)
    buf = lowpass(rng.uniform(-1, 1, n), soft)
    out = np.zeros(int(dur * SR))
    for i in range(len(out)):
        out[i] = buf[i % n]
        buf[i % n] = damp * 0.5 * (buf[i % n] + buf[(i + 1) % n])
    return out


def mix(*parts):
    """parts = (start in seconds, samples). Returns them layered."""
    end = max(int(o * SR) + len(s) for o, s in parts)
    out = np.zeros(end)
    for o, s in parts:
        out[int(o * SR):int(o * SR) + len(s)] += s
    return out


os.makedirs(DEST, exist_ok=True)
save("ui_tap", tap(), 0.45)                                                          # every ordinary button
save("ui_choice", mix((0, tap(440, 0.07) * 0.5), (0, pluck(293.66, 0.45))), 0.45)    # picking a story choice
save("ui_confirm", mix((0, pluck(293.66, 0.5)), (0.09, pluck(440.0, 0.7))), 0.45)    # confirm, begin life (rising)
save("ui_back", mix((0, pluck(392.0, 0.35)), (0.08, pluck(293.66, 0.5))), 0.4)        # back, close (falling)
t = np.arange(int(0.28 * SR)) / SR
page = lowpass(rng.standard_normal(len(t)), 0.35) * np.sin(np.pi * t / 0.28) ** 2
save("ui_page", page - lowpass(page, 0.02), 0.3)                                      # turning a page, a new month
save("ui_reward", mix((0, pluck(293.66, 0.9)), (0.1, pluck(369.99, 0.9)), (0.2, pluck(440.0, 0.9)), (0.32, pluck(587.33, 1.3))), 0.45)  # breakthrough, reward
