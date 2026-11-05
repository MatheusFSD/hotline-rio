# Night one, "Último Gole": the Bar do Arco, in the Lapa, the night the dead waiter comes back.
# 62 s in a seamless loop: 32 bars at 124 BPM in D minor. A bossa that is running.
#   - a bossa progression, Dm9 G13 Cm9 F13 Bbmaj7 Eb9#11 Em7b5 A7#9, on a nylon guitar with the thumb
#     on the bass, the way it is played at a table in the back of the bar;
#   - under it, what makes it run: a pulsing bass in sixteenths, a four-on-the-floor kick from bar 4,
#     a gated snare and a saw arpeggio from bar 8, everything ducking on the beat, Hotline Miami style;
#   - a worn tape of electric piano wandering in pitch, stuttering on the chords: the vaporwave;
#   - from bar 16 a lone muted horn, the noir, its echo bouncing round the room;
#   - rim on the bossa clave, ganza, tamborim and a cuíca groaning at the turn of the phrase;
#   - and the bar itself: its murmur, and a glass now and then.
# Writes assets/audio/night_01.ogg (tools/music_kit.py is the synth).
# Use: blender -b --factory-startup --python tools/build_music_lapa.py
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import music_kit as kit
from music_kit import RATE, place, spectrum_filter as band

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, '..', 'assets', 'audio', 'night_01.ogg'))
BPM = 124
BARS = 32
BEAT = 60.0 / BPM
STEP = BEAT / 4
BAR = 4 * BEAT
DUR = BARS * BAR
N = int(round(DUR * RATE))
t = np.arange(N) / RATE
kit.seed(1925)
def bus(): return kit.bus(N)

# Each chord lasts two bars: guitar voicing, bass root.
CHORDS = [
    ([53, 57, 60, 64], 38),   # Dm9
    ([53, 59, 64, 69], 43),   # G13
    ([51, 55, 58, 62], 36),   # Cm9
    ([51, 57, 62, 67], 41),   # F13
    ([50, 53, 57, 60], 34),   # Bbmaj7
    ([49, 55, 58, 65], 39),   # Eb9#11
    ([50, 55, 58, 64], 40),   # Em7b5
    ([49, 55, 60, 65], 33),   # A7#9
]
def chord_at(bar): return CHORDS[(bar // 2) % len(CHORDS)]

# Guitar: the bossa figure over two bars, chords off the beat, the thumb walking root and fifth.
COMP = [0, 3, 6, 10, 13, 16, 19, 22, 26, 29]
guitar = bus()
for bar in range(0, BARS, 2):
    notes, root = chord_at(bar)
    start = bar * BAR
    for s in COMP: kit.strum(guitar, start + s * STEP, notes, 2.2 * STEP, .2 if s % 16 == 0 else .15)
    for s, interval in ((0, 0), (8, 7), (16, 0), (24, 7)):
        thumb = root + 12 + interval if root < 40 else root + interval
        place(guitar, start + s * STEP, kit.nylon(thumb, 6 * STEP, .3))
guitar = band(guitar, low=110, high=4800)

# Bass: sixteenths in a broken pulse, walking chromatically into the next chord.
FIGURE = [(0, 0, 2), (3, 0, 1), (4, 12, 1), (6, 0, 2), (8, 0, 2), (11, 7, 1), (12, 12, 1), (14, 0, 2)]
bass = bus()
for bar in range(BARS):
    _, root = chord_at(bar)
    next_root = chord_at(bar + 1)[1]
    walk = bar % 2 == 1
    for s, interval, length in (FIGURE[:-1] + [(14, 0, 1), (15, next_root - root - 1, 1)] if walk else FIGURE):
        place(bass, bar * BAR + s * STEP, kit.low(root + interval, length * STEP * .85, .5))

# Drums.
kicks = bus(); snares = bus(); perc = bus(); cuicas = bus()
GANZA = [.45, .2, .3, .75]
CLAVE = [0, 3, 6, 10, 13]
TAMBORIM = [0, 3, 6, 10, 12]
for bar in range(BARS):
    start = bar * BAR
    for s in range(16):
        g = kit.ganza(GANZA[s % 4] * .32)
        place(perc, start + s * STEP, g, np.roll(g, 37))
    for s in CLAVE: place(perc, start + s * STEP, kit.rim(.16))
    if bar >= 4:
        for beat in range(4): place(kicks, start + beat * BEAT, kit.kick(.75))
    if bar >= 8:
        for beat in (1, 3): place(snares, start + beat * BEAT, kit.snare(.34))
        for beat in range(4): place(perc, start + (beat + .5) * BEAT, kit.hat(.1, .12) * .8, kit.hat(.1, .12))
    if bar >= 16:
        for s in TAMBORIM:
            hit = kit.tamborim() * .13
            place(perc, start + s * STEP, hit * .6, hit)
    if bar >= 4 and bar % 4 == 3:   # the cuíca at the turn of the phrase
        for s, m, length in ((8, 62, 3), (11, 65, 2), (13, 69, 3)):
            tone = kit.cuica(m, length * STEP, .09)
            place(cuicas, start + s * STEP, tone * .7, tone)
for s in range(8, 16):   # the last bar's fill throws it back to the top
    place(snares, (BARS - 1) * BAR + s * STEP, kit.snare(.12 + .03 * (s - 8), .09))

# The saw arpeggio, its filter opening and closing every eight bars.
PATTERN = [0, 2, 1, 3, 2, 0, 3, 1]
arp_dark = bus(); arp_open = bus()
for bar in range(8, BARS):
    notes = chord_at(bar)[0]
    for s in range(16):
        m = notes[PATTERN[s % 8]] + (24 if s % 8 == 7 else 12)
        tone = kit.pluck(m, STEP * .8, .1)
        pan = .75 if s % 2 else 1.0
        place(arp_open, bar * BAR + s * STEP, tone * pan, tone * (1.75 - pan))
arp_dark = band(arp_open, high=800)
arp_open = band(arp_open, low=250, high=3600)
sweep = .5 - .5 * np.cos(2 * np.pi * 4 * t / DUR)
arp = arp_dark * (1 - sweep) + arp_open * sweep

# The vaporwave: electric piano off a worn tape, the chord stuttering, and a detuned pad under it.
tape = bus(); wash = bus()
for bar in range(0, BARS, 2):
    notes = chord_at(bar)[0]
    for s in (0, 6, 8, 14, 16, 22):
        for m in notes: place(tape, bar * BAR + s * STEP, kit.epiano(m + 12, STEP * 1.6, .12 if s % 8 == 0 else .07))
    left, right = kit.pad([m + 12 for m in notes], 2 * BAR, .05, cut=2000)
    place(wash, bar * BAR, left, right)
tape = kit.wow(band(tape, low=180, high=1900), .0035, 29)
wash = kit.wow(band(wash, low=160, high=1800), .005, 13)

# The horn, from bar 16 (bar, sixteenth, note, sixteenths).
MELODY = [(16, 0, 69, 6), (16, 6, 72, 2), (16, 8, 74, 6), (16, 14, 72, 2), (17, 0, 69, 4), (17, 4, 65, 4), (17, 10, 64, 2), (17, 12, 65, 4),
          (18, 0, 71, 6), (18, 6, 69, 2), (18, 8, 67, 4), (18, 12, 69, 4), (19, 0, 64, 8), (19, 10, 65, 2), (19, 12, 67, 4),
          (20, 0, 70, 6), (20, 6, 67, 2), (20, 8, 63, 4), (20, 12, 65, 4), (21, 0, 62, 8), (21, 10, 63, 2), (21, 12, 65, 2), (21, 14, 67, 2),
          (22, 0, 69, 6), (22, 6, 67, 2), (22, 8, 65, 4), (22, 12, 62, 4), (23, 0, 63, 10), (23, 12, 67, 4),
          (24, 0, 69, 8), (24, 10, 70, 2), (24, 12, 72, 4), (25, 0, 74, 6), (25, 6, 72, 2), (25, 8, 69, 8),
          (26, 0, 70, 4), (26, 4, 69, 2), (26, 6, 67, 6), (26, 12, 65, 4), (27, 0, 61, 8), (27, 10, 63, 2), (27, 12, 65, 4),
          (28, 0, 67, 6), (28, 6, 70, 2), (28, 8, 74, 6), (28, 14, 72, 2), (29, 0, 70, 4), (29, 4, 67, 4), (29, 10, 64, 2), (29, 12, 62, 4),
          (30, 0, 61, 6), (30, 6, 64, 2), (30, 8, 67, 4), (30, 12, 72, 4), (31, 0, 73, 8), (31, 8, 69, 8)]
lead = bus()
for bar, s, m, length in MELODY:
    place(lead, bar * BAR + s * STEP, kit.horn(m, length * STEP * .92, .5))
lead = band(lead, low=350, high=3000) + band(lead, low=900, high=1700) * .9   # the mute's nasal bite
lead_echo = band(kit.echo(lead, .75 * BEAT, 4, .42), low=300, high=2400)

# The bar: its murmur, and now and then a glass.
murmur = kit.air(N, 280, 1300, 11, .02)
glasses = bus()
for k in range(26):
    n = int(.18 * RATE); q = np.arange(n) / RATE
    f = kit.rng.choice([3150, 4230, 5180])
    tone = np.sin(2 * np.pi * f * q) * np.exp(-q / .035) * .035
    side = kit.rng.uniform(.3, 1.0)
    place(glasses, kit.rng.uniform(0, DUR), tone * side, tone * (1.3 - side))

# ---------------------------------------------------------------- mix
bass = kit.pump(bass, t, BEAT, .35)
arp = kit.pump(arp, t, BEAT, .45)
tape = kit.pump(tape, t, BEAT, .4)
wash = kit.pump(wash, t, BEAT, .5)
wet = kit.reverb(guitar * .25 + lead * .5 + lead_echo * .5 + tape * .5 + wash * .4 + snares * .45 + perc * .05 + cuicas * .6 + glasses * 1.5, 1.7, seed=7)
wet = .55 * wet.mean(axis=0) + .45 * wet
mix = kit.master({'guitar': guitar * 1.4, 'bass': bass * .38, 'kick': kicks * .55, 'snare': snares * 1.2, 'perc': perc * 1.4, 'cuica': cuicas * 2.2,
                  'arp': arp * 3.0, 'tape': tape * 1.3, 'wash': wash * 1.3, 'lead': lead * .75, 'echo': lead_echo * 1.1, 'bar': (murmur + glasses) * 4}, wet * .5)
kit.write(OUT, mix, section=8 * BAR)
