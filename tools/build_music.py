# Hotline Rio, menu theme. Synthesised here (no third-party licence, no Content ID).
# 40 s in a seamless loop: 16 bars at 96 BPM in A minor, Lapa at three in the morning.
#   - a slow bossa progression, Am9 Fmaj7 Dm9 E7b9 Am9 Fmaj7 Bm7b5 E7#5, on a detuned synth pad that
#     ducks on every beat, synthwave style;
#   - a partido-alto bass line and a quiet bateria: surdo, tamborim and ganza, a clap on 2 and 4;
#   - a lone electric piano melody with a dotted-eighth echo in the second half, a soft arpeggio
#     before it;
#   - far off, a police siren rising and falling, and the hiss of the city.
# Everything that rings past the end (notes, reverb, echoes) wraps round to the start, and the
# filters and reverb work on the whole loop at once (FFT, circular), so the loop has no seam.
# Writes assets/audio/menu_theme.ogg (tools/music_kit.py is the synth).
# Use: blender -b --factory-startup --python tools/build_music.py
import os, sys, math
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import music_kit as kit
from music_kit import hz, place, envelope, saw, spectrum_filter, reverb, pump, epiano, surdo, tamborim, ganza, clap, RATE

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, '..', 'assets', 'audio', 'menu_theme.ogg'))
BPM = 96
BARS = 16
BEAT = 60.0 / BPM
STEP = BEAT / 4                     # one sixteenth
DUR = BARS * 4 * BEAT               # 40 s
N = int(round(DUR * RATE))
t = np.arange(N) / RATE

def bus(): return kit.bus(N)

# ---------------------------------------------------------------- harmony
# Each chord lasts two bars: pad voicing around middle C, and the bass root.
CHORDS = [
    ([57, 60, 64, 67, 71], 45),   # Am9
    ([53, 57, 60, 64, 69], 41),   # Fmaj7
    ([57, 60, 64, 65, 69], 50),   # Dm9
    ([56, 59, 62, 65, 68], 52),   # E7b9 (the diminished shape over E)
    ([57, 60, 64, 67, 71], 45),   # Am9
    ([53, 57, 60, 64, 69], 41),   # Fmaj7
    ([57, 59, 62, 65, 69], 47),   # Bm7b5
    ([56, 60, 62, 64, 68], 52),   # E7#5
]
CHORD_LEN = 8 * BEAT

# Pad: two detuned saws per note, wide, slow to open, overlapping into the next chord.
pad = bus()
for c, (notes, _) in enumerate(CHORDS):
    n = int((CHORD_LEN + 1.6) * RATE)
    k = np.arange(n) / RATE
    env = envelope(n, .9, 1.6, hold=CHORD_LEN)
    left = np.zeros(n); right = np.zeros(n)
    for j, m in enumerate(notes):
        f = hz(m)
        center = saw(f, k, 2800, phase=j * 2)   # shared by both ears, so the pad holds in mono
        left += center; right += center
        left += .6 * saw(f * 2 ** (-7 / 1200), k, 2400, phase=j) + .3 * saw(f * 2 ** (5 / 1200), k, 1600, phase=j + 1)
        right += .6 * saw(f * 2 ** (7 / 1200), k, 2400, phase=j + 2) + .3 * saw(f * 2 ** (-4 / 1200), k, 1600, phase=j + 3)
    place(pad, c * CHORD_LEN, left * env * .12, right * env * .12)
pad = spectrum_filter(pad, low=140, high=2600)
# Sidechain pump: the pad dips with every beat and swells back.
pad = pump(pad, t, BEAT, .38)

# Bass: partido-alto figure in sixteenths (position, interval, length), the last bar of each chord
# walking chromatically into the next root.
FIGURE = [(0, 0, 3), (3, 0, 2), (6, 7, 2), (10, 12, 1), (12, 7, 2), (14, 0, 2)]
bass = bus()
for c, (_, root) in enumerate(CHORDS):
    next_root = CHORDS[(c + 1) % len(CHORDS)][1]
    for half in range(2):
        figure = FIGURE if half == 0 else FIGURE[:-1] + [(14, 0, 1), (15, next_root - root - 1, 1)]
        for pos, interval, length in figure:
            f = hz(root + interval)
            n = int((length * STEP + .08) * RATE)
            k = np.arange(n) / RATE
            env = envelope(n, .006, .06, hold=length * STEP * .9) * (.75 + .25 * np.exp(-k / .12))
            tone = np.sin(2 * np.pi * f * k) + .45 * saw(f, k, 1400) + .25 * np.sin(4 * np.pi * f * k)
            place(bass, c * CHORD_LEN + half * 4 * BEAT + pos * STEP, tone * env * .42)

# Bateria: from bar 4 on, the ganza alone before it.
drums = bus()
claps = bus()
GANZA = [.45, .2, .3, .75]                       # accent on the last sixteenth of each beat
TAMBORIM = [0, 3, 6, 10, 12]                     # partido alto
for bar in range(BARS):
    start = bar * 4 * BEAT
    full = bar >= 4
    for s in range(16):
        g = ganza(GANZA[s % 4] * (.32 if full else .2))
        place(drums, start + s * STEP, g * .9, np.roll(g, 37))
    if not full: continue
    for beat in range(4):
        open_ = beat in (1, 3)
        place(drums, start + beat * BEAT, surdo(.42 if open_ else .2, open_))
    for s in TAMBORIM:
        hit = tamborim() * .07
        place(drums, start + s * STEP, hit * .6, hit)
    for beat in (1, 3):
        place(claps, start + beat * BEAT, clap() * .12)
drums = spectrum_filter(drums, low=35, high=9000)
ganza_air = spectrum_filter(drums, low=5000)      # keep the ganza bright, the rest warm
drums = spectrum_filter(drums, high=4000) + ganza_air * 2.0
claps = spectrum_filter(claps, low=600, high=6000)

# Electric piano.
# Melody over the second half (bar, sixteenth, note, sixteenths).
MELODY = [(8, 0, 76, 6), (8, 6, 74, 2), (8, 8, 72, 4), (8, 12, 71, 4),
          (9, 2, 72, 2), (9, 4, 69, 8), (9, 14, 67, 2),
          (10, 0, 69, 4), (10, 4, 72, 2), (10, 6, 76, 6), (10, 12, 77, 4),
          (11, 0, 76, 8), (11, 10, 74, 2), (11, 12, 72, 4),
          (12, 0, 74, 6), (12, 6, 72, 2), (12, 8, 69, 4), (12, 12, 65, 4),
          (13, 2, 69, 2), (13, 4, 71, 8),
          (14, 0, 68, 4), (14, 4, 71, 2), (14, 6, 72, 6), (14, 12, 74, 2), (14, 14, 72, 2),
          (15, 0, 71, 6), (15, 8, 68, 8)]
lead = bus()
for bar, s, m, length in MELODY:
    place(lead, bar * 4 * BEAT + s * STEP, epiano(m, length * STEP, .38))
# Dotted-eighth echo, bouncing between the ears.
echo = bus()
for tap in range(1, 6):
    shift = int(round(tap * .75 * BEAT * RATE))
    gain = .42 ** tap
    echo[tap % 2] += np.roll(lead[0] + lead[1], shift) * gain * .5
lead = lead + spectrum_filter(echo, low=300, high=2600)
# A soft arpeggio of the chord tones in the bars before the melody.
arp = bus()
for bar in range(4, 8):
    notes = CHORDS[bar // 2][0]
    for s in range(0, 16, 2):
        m = notes[(s // 2) % len(notes)] + 12
        place(arp, bar * 4 * BEAT + s * STEP, epiano(m, STEP * 1.5, .1) * (.8 if s % 4 else 1.0))
arp = spectrum_filter(arp, high=2200)

# Far away: a police siren rising and falling across a few bars, and the city's hiss.
siren = bus()
n = int(12 * BEAT * RATE)
k = np.arange(n) / RATE
wail = 780 + 330 * (.5 - .5 * np.cos(2 * np.pi * k / 2.4))
tone = np.sin(2 * np.pi * np.cumsum(wail) / RATE) + .3 * np.sin(4 * np.pi * np.cumsum(wail) / RATE)
swell = np.sin(np.pi * k / k[-1]) ** 2
place(siren, 10 * BEAT, tone * swell * .05 * .7, tone * swell * .05)
siren = spectrum_filter(siren, low=500, high=1300)
hiss = spectrum_filter(kit.rng.normal(0, 1, (2, N)), low=200, high=3000) * .006

# ---------------------------------------------------------------- mix
dry = pad * .55 + bass * .62 + drums * .7 + claps * .5 + lead * .85 + arp * .7 + siren
wet = reverb(pad * .35 + claps * .9 + lead * .5 + arp * .5 + siren * 1.4 + drums * .08, 2.6, seed=7)
wet = .55 * wet.mean(axis=0) + .45 * wet   # a room more in front than around
mix = dry + wet * .5 + hiss
mix = np.tanh(mix * 1.3) / 1.3            # a little tape warmth
mix = spectrum_filter(mix, low=28)        # no DC, no rumble
kit.write(OUT, mix)
