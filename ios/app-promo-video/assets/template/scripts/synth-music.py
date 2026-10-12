"""Synthesizes the promo's music bed: a swung 16th-note funk groove at 120 BPM
(one beat = 15 frames at 30 fps) over an Em7 – A7 dorian vamp.

Before the drums drop in, a filtered clav teases the riff; a snare fill leads
into the groove, and the track ends on a single stab that rings out.
Deterministic, so the WAV is generated rather than committed.

Usage: python3 scripts/synth-music.py <seconds> <beat-in-beat> <out.wav>
  beat-in-beat: beat index where the groove drops (the end of the intro scene).
"""

import sys
import wave

import numpy as np

SR = 44100
BPM = 120
BEAT = 60 / BPM
SIXTEENTH = BEAT / 4
SWING = 0.58  # share of each 8th the first 16th gets; 0.5 is straight

# Two-bar vamp: bar 1 on Em7, bar 2 on A7.
CHORDS = [
    {"root": 40, "stab": [55, 59, 62, 66]},  # Em9-ish: G B D F#
    {"root": 45, "stab": [55, 61, 64, 67]},  # A7/13: G C# E G
]

# Bass per 16th step: (semitones above root, velocity, kind) or None.
# kind: "n" normal, "g" muted ghost, "p" octave pop.
BASS = [
    (0, 1.0, "n"), None, (0, 0.4, "g"), (12, 0.9, "p"),
    None, (0, 0.4, "g"), (10, 0.8, "n"), (12, 0.9, "p"),
    (0, 0.9, "n"), None, (7, 0.7, "n"), (0, 0.4, "g"),
    (10, 0.8, "n"), (12, 0.9, "p"), (7, 0.7, "n"), (5, 0.6, "n"),
]
KICK = [1, 0, 0, 0.7, 0, 0, 0, 0, 0, 0, 0.9, 0, 0, 0, 0, 0]
SNARE = [0, 0, 0, 0, 1, 0, 0, 0.25, 0, 0.2, 0, 0, 1, 0, 0.3, 0]
CLAV = [0, 0, 0, 0, 0, 0, 0.8, 0, 0, 0.6, 0, 0, 0, 0, 0.8, 0]


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def step_time(step):
    """Start time of a 16th step, with swing applied to the off-16ths."""
    pair, odd = divmod(step, 2)
    return pair * 2 * SIXTEENTH + (odd * 2 * SIXTEENTH * SWING)


def lowpass(signal, cutoff):
    alpha = 1 - np.exp(-2 * np.pi * cutoff / SR)
    out = np.empty_like(signal)
    acc = 0.0
    for i, x in enumerate(signal):
        acc += alpha * (x - acc)
        out[i] = acc
    return out


def t_axis(seconds):
    return np.arange(int(seconds * SR)) / SR


def bass_note(freq, kind):
    t = t_axis(0.22 if kind != "g" else 0.06)
    # Square-ish body plus a bright attack, saturated like a slapped string.
    tone = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(2 * np.pi * freq * 2 * t)
    tone += 0.15 * np.sign(np.sin(2 * np.pi * freq * t))
    decay = {"n": 14, "g": 60, "p": 18}[kind]
    click = np.exp(-t * 400) * (0.8 if kind == "p" else 0.3)
    return np.tanh(2.2 * (tone * np.exp(-t * decay) + click))


def kick():
    t = t_axis(0.3)
    pitch = 48 + 110 * np.exp(-t * 35)
    return np.sin(2 * np.pi * np.cumsum(pitch) / SR) * np.exp(-t * 11)


def snare(rng):
    t = t_axis(0.18)
    noise = rng.standard_normal(len(t))
    noise -= lowpass(noise, 1500)
    body = np.sin(2 * np.pi * 190 * t) * np.exp(-t * 30)
    return (0.8 * noise * np.exp(-t * 22) + 0.6 * body)


def hat(rng, open_hat=False):
    t = t_axis(0.25 if open_hat else 0.04)
    noise = rng.standard_normal(len(t))
    noise -= lowpass(noise, 8000)
    return noise * np.exp(-t * (14 if open_hat else 90))


def clav(notes, length=0.12):
    t = t_axis(length + 0.05)
    out = np.zeros_like(t)
    for note in notes:
        f = hz(note)
        # Pulse-wave pluck: bright, nasal, very short.
        out += np.sign(np.sin(2 * np.pi * f * t)) * 0.5 + np.sin(2 * np.pi * f * 2 * t) * 0.3
    env = np.exp(-t * 28)
    env[int(length * SR):] *= np.linspace(1, 0, len(t) - int(length * SR))
    return out * env / len(notes)


def place(track, clip, start_seconds, gain):
    start = int(start_seconds * SR)
    end = min(start + len(clip), len(track))
    if 0 <= start < len(track):
        track[start:end] += clip[: end - start] * gain


def main():
    seconds = float(sys.argv[1])
    beat_in = int(sys.argv[2])
    out_path = sys.argv[3]

    rng = np.random.default_rng(11)
    n = int(seconds * SR)
    bass, drums, keys, hats = (np.zeros(n) for _ in range(4))

    total_beats = int(seconds / BEAT)
    groove_end = total_beats - 4  # last bar: one stab, then let it ring
    bars = (total_beats + 3) // 4

    for bar in range(bars):
        chord = CHORDS[bar % 2]
        bar_start = bar * 4 * BEAT
        for step in range(16):
            beat = bar * 4 + step / 4
            at = bar_start + step_time(step)
            in_groove = beat_in <= beat < groove_end

            if in_groove:
                if BASS[step]:
                    offset, vel, kind = BASS[step]
                    place(bass, bass_note(hz(chord["root"] + offset), kind), at, 0.32 * vel)
                if KICK[step]:
                    place(drums, kick(), at, 0.75 * KICK[step])
                if SNARE[step]:
                    place(drums, snare(rng), at, 0.32 * SNARE[step])
                accent = 1.0 if step % 2 == 0 else 0.55
                place(hats, hat(rng, open_hat=(step == 14)), at, 0.12 * accent)

            # The clav riff plays through the intro too (filtered later) so the
            # groove has something to land on.
            if CLAV[step] and beat < groove_end:
                place(keys, clav(chord["stab"]), at, 0.16 * CLAV[step])

    # Snare fill on the last beat before the drop.
    for i in range(4):
        place(drums, snare(rng), (beat_in - 1) * BEAT + i * SIXTEENTH, 0.12 + 0.07 * i)

    # Final stab on the downbeat of the last bar, with bass and kick.
    final = groove_end * BEAT
    last_chord = CHORDS[(groove_end // 4) % 2]
    place(keys, clav(last_chord["stab"], length=1.4), final, 0.22)
    place(bass, bass_note(hz(last_chord["root"]), "n"), final, 0.4)
    place(drums, kick(), final, 0.8)

    # Intro clav sits behind a low-pass so the drop opens it up.
    intro_end = int(beat_in * BEAT * SR)
    keys[:intro_end] = lowpass(keys[:intro_end], 1400) * 3.5

    left = bass + drums + keys * 1.0 + hats * 0.7
    right = bass + drums + keys * 0.7 + hats * 1.0
    stereo = np.stack([left, right], axis=1)
    fade = np.ones(n)
    fade[-int(1.2 * SR):] = np.linspace(1, 0, int(1.2 * SR))
    stereo *= fade[:, None]
    stereo = np.tanh(stereo * 1.4)  # glue
    stereo /= np.max(np.abs(stereo)) / 0.85

    with wave.open(out_path, "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes((stereo * 32767).astype(np.int16).tobytes())
    print(f"Wrote {seconds:.1f}s funk bed to {out_path}")


if __name__ == "__main__":
    main()
