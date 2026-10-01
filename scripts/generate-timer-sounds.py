#!/usr/bin/env python3
"""Generate Ritli's original, short PCM notification tones without external assets."""

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44_100
OUTPUT = Path(__file__).resolve().parents[1] / "Ritli" / "Resources" / "Sounds"


def bell(t, frequency):
    if t < 0:
        return 0
    attack = min(1, t / 0.012)
    return attack * (
        math.sin(2 * math.pi * frequency * t) * math.exp(-3 * t)
        + 0.25 * math.sin(2 * math.pi * frequency * 2 * t) * math.exp(-5 * t)
        + 0.12 * math.sin(2 * math.pi * frequency * 3 * t) * math.exp(-7 * t)
    )


def pulse(t):
    if not 0 <= t < 0.38:
        return 0
    envelope = math.sin(math.pi * t / 0.38) ** 2
    return envelope * (
        math.sin(2 * math.pi * 440 * t)
        + 0.15 * math.sin(2 * math.pi * 880 * t)
    )


def write_sound(name, duration, signal):
    samples = [signal(index / SAMPLE_RATE) for index in range(int(duration * SAMPLE_RATE))]
    peak = max(abs(sample) for sample in samples)
    pcm = bytearray()
    for index, sample in enumerate(samples):
        remaining = (len(samples) - 1 - index) / SAMPLE_RATE
        fade = min(1, remaining / 0.08)
        pcm.extend(struct.pack("<h", round(sample / peak * 0.55 * fade * 32767)))
    with wave.open(str(OUTPUT / name), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(SAMPLE_RATE)
        audio.writeframes(pcm)


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    write_sound("ritli-gentle-bell.wav", 2.0, lambda t: bell(t, 523.25))
    write_sound("ritli-clear-chime.wav", 2.2, lambda t: sum(
        bell(t - offset, frequency)
        for offset, frequency in [(0, 523.25), (0.24, 659.25), (0.48, 783.99)]
    ))
    write_sound("ritli-soft-pulse.wav", 1.3, lambda t: sum(pulse(t - offset) for offset in [0, 0.42, 0.84]))
