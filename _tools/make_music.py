"""Generate two soft, seamlessly-looping ambient music beds as WAV files.

They are intentionally gentle (slow pads + light arpeggio) so they never get in
the way of gameplay. Kept short and looped by the audio engine.
"""
import numpy as np
import wave
import os

SR = 22050


def note(freq, t, amp=0.2, detune=0.0):
    return amp * np.sin(2 * np.pi * (freq + detune) * t)


def soft_pad(freqs, dur, amp=0.16):
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)
    sig = np.zeros(n)
    for f in freqs:
        sig += note(f, t, amp) + note(f, t, amp * 0.4, detune=0.6)
    # slow tremolo
    lfo = 0.85 + 0.15 * np.sin(2 * np.pi * (1.0 / dur) * t)
    return sig * lfo


def arp(freqs, dur, step=0.5, amp=0.10):
    n = int(SR * dur)
    out = np.zeros(n)
    idx = 0
    tstep = np.linspace(0, step, int(SR * step), endpoint=False)
    env = np.exp(-3.0 * tstep / step)
    k = 0
    while idx + len(tstep) <= n:
        f = freqs[k % len(freqs)]
        out[idx:idx + len(tstep)] += amp * np.sin(2 * np.pi * f * tstep) * env
        idx += len(tstep)
        k += 1
    return out


def normalize(sig):
    m = np.max(np.abs(sig))
    if m > 0:
        sig = sig / m * 0.75
    return sig


def save(path, sig):
    sig = normalize(sig)
    data = (sig * 32767).astype(np.int16)
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(path, f"{len(sig)/SR:.1f}s")


def build_menu():
    # Warm major-ish pad in two chords, 16s loop.
    seg = 4.0
    # C major-ish then A minor-ish then F then G (I vi IV V)
    chords = [
        [130.81, 196.00, 261.63],  # C G C
        [110.00, 164.81, 220.00],  # A E A
        [174.61, 220.00, 261.63],  # F A C
        [196.00, 246.94, 293.66],  # G B D
    ]
    pad = np.concatenate([soft_pad(c, seg) for c in chords])
    a = arp([523.25, 659.25, 783.99, 659.25], seg * 4, step=0.5, amp=0.06)
    sig = pad + a[:len(pad)]
    save('sounds/music_menu.wav', sig)


def build_game():
    # Slightly more driving, minor feel, 16s loop.
    seg = 4.0
    chords = [
        [110.00, 164.81, 220.00],  # Am
        [130.81, 196.00, 261.63],  # C
        [146.83, 220.00, 293.66],  # Dm
        [164.81, 196.00, 246.94],  # Em
    ]
    pad = np.concatenate([soft_pad(c, seg, amp=0.14) for c in chords])
    a = arp([440.0, 523.25, 587.33, 523.25], seg * 4, step=0.375, amp=0.07)
    sig = pad + a[:len(pad)]
    save('sounds/music_game.wav', sig)


if __name__ == '__main__':
    os.makedirs('sounds', exist_ok=True)
    build_menu()
    build_game()
