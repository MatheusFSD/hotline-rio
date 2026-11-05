# The hero's death: what plays over the death screen, once the slow motion is over. The alley behind
# the Bar do Arco, where they killed him the first time.
# 29 s in a seamless loop: 8 bars at 66 BPM in D minor. A bossa at half strength on a worn tape, the
# bass only where the heart would beat, and the first night's horn, falling instead of rising. Rain,
# the bar's music gone, a siren far away that is not coming for anyone.
# Writes assets/audio/death.ogg (tools/music_kit.py is the synth).
# Use: blender -b --factory-startup --python tools/build_music_death.py
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import music_kit as kit
from music_kit import RATE, place, spectrum_filter as band

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, '..', 'assets', 'audio', 'death.ogg'))
BPM = 66
BARS = 8
BEAT = 60.0 / BPM
STEP = BEAT / 4
BAR = 4 * BEAT
DUR = BARS * BAR
N = int(round(DUR * RATE))
t = np.arange(N) / RATE
kit.seed(13)
def bus(): return kit.bus(N)

CHORDS = [
    ([53, 57, 60, 64], 38),   # Dm9
    ([50, 53, 57, 60], 34),   # Bbmaj7
    ([50, 53, 58, 62], 31),   # Gm9
    ([49, 55, 58, 62], 33),   # A7b9
    ([53, 57, 60, 64], 38),   # Dm9
    ([50, 55, 58, 62], 39),   # Ebmaj7
    ([50, 55, 58, 64], 40),   # Em7b5
    ([49, 55, 60, 65], 33),   # A7#9
]

# The guitar: the bossa's figure, only half of it left, each chord let ring.
guitar = bus()
for bar, (notes, root) in enumerate(CHORDS):
    for s, level in ((0, .24), (6, .15), (10, .13)):
        kit.strum(guitar, bar * BAR + s * STEP, notes, 6 * STEP, level, spread=.02)
    place(guitar, bar * BAR, kit.nylon(root + 12, 10 * STEP, .3))
guitar = kit.wow(band(guitar, low=120, high=2800), .006, 5)

# The heart, slowing: two low beats at the top of each bar.
heart = bus()
for bar, (_, root) in enumerate(CHORDS):
    place(heart, bar * BAR, kit.surdo(.5, True))
    place(heart, bar * BAR + 1.5 * STEP, kit.surdo(.28, False))
    place(heart, bar * BAR + 8 * STEP, kit.low(root, 5 * STEP, .35))
heart = band(heart, high=500)

wash = bus()
for bar, (notes, _) in enumerate(CHORDS):
    left, right = kit.pad([m + 12 for m in notes], BAR, .05, cut=1800, attack=.8, release=1.6)
    place(wash, bar * BAR, left, right)
wash = kit.wow(band(wash, low=200, high=1500), .008, 3)

# The horn: night one's opening, turned downward (bar, sixteenth, note, sixteenths).
MELODY = [(1, 0, 74, 8), (1, 8, 72, 2), (1, 10, 69, 6), (2, 0, 70, 6), (2, 6, 67, 2), (2, 8, 65, 8), (3, 0, 64, 10), (3, 10, 61, 6),
          (5, 0, 74, 6), (5, 6, 70, 2), (5, 8, 67, 8), (6, 0, 64, 6), (6, 6, 67, 2), (6, 8, 62, 8), (7, 0, 61, 12), (7, 12, 57, 4)]
lead = bus()
for bar, s, m, length in MELODY:
    place(lead, bar * BAR + s * STEP, kit.horn(m, length * STEP * .95, .45, vibrato=.009))
lead = kit.wow(band(lead, low=320, high=2400) + band(lead, low=800, high=1500) * .8, .004, 7)
lead_echo = band(kit.echo(lead, .75 * BEAT, 3, .4), low=300, high=1900)

# The alley: rain on the stones, tape hiss, and the siren far off.
rain = band(kit.rng.normal(0, 1, (2, N)), low=1200, high=7000) * .012 * (.8 + .2 * np.sin(2 * np.pi * 3 * t / DUR))
drops = bus()
for k in range(110):
    n = int(.02 * RATE); q = np.arange(n) / RATE
    tick = kit.rng.normal(0, 1, n) * np.exp(-q / .004) * kit.rng.uniform(.01, .05)
    side = kit.rng.uniform(.2, 1.0)
    place(drops, kit.rng.uniform(0, DUR), tick * side, tick * (1.2 - side))
drops = band(drops, low=900, high=6000)
siren = bus()
n = int(4 * BAR * RATE)
q = np.arange(n) / RATE
wail = 700 + 260 * (.5 - .5 * np.cos(2 * np.pi * q / 3.1))
siren_tone = np.sin(2 * np.pi * np.cumsum(wail) / RATE) * np.sin(np.pi * q / q[-1]) ** 2 * .05
place(siren, 3 * BAR, siren_tone * .6, siren_tone)
siren = band(siren, low=450, high=1100)

wet = kit.reverb(guitar * .6 + lead * .8 + lead_echo * .7 + wash * .4 + siren * 1.6 + drops * .5, 3.2, damp=2400, seed=31)
wet = .55 * wet.mean(axis=0) + .45 * wet
mix = kit.master({'guitar': guitar * 1.3, 'heart': heart * .7, 'wash': wash * 1.2, 'lead': lead * .6, 'echo': lead_echo * .9,
                  'rain': rain * 7, 'drops': drops * 12, 'siren': siren * 4}, wet * .6)
kit.write(OUT, mix, section=2 * BAR)
