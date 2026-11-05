# The short cues around a night (tools/music_kit.py is the synth):
#   - entrance.ogg: the walk-in. 17 s loop, 8 bars at 112 BPM in D minor, a walking bass under the
#     hero's walk, brushes, a guitar that barely speaks, the horn thinking of the night ahead;
#   - entrance_hit.ogg: its end, as he stops and the camera pulls back: one hit, ringing out;
#   - night_clear.ogg: the night is clean. Barely a sound effect: a hit on the title's landing, a run
#     up the guitar, and a D major the rest of the game does not have;
#   - sfx/tally_tick.ogg, sfx/slam.ogg, sfx/slam_heavy.ogg: the result screens. A digit turning, a
#     letter thrown against the glass like a street sign, and the grade's heavier one;
#   - sfx/whoosh.ogg: the katana cutting only the air, played as the blade lands on nothing.
# Use: blender -b --factory-startup --python tools/build_music_cues.py
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import music_kit as kit
from music_kit import RATE, place, spectrum_filter as band

HERE = os.path.dirname(os.path.abspath(__file__))
AUDIO = os.path.normpath(os.path.join(HERE, '..', 'assets', 'audio'))
kit.seed(1313)

def timeline(seconds):
    return int(round(seconds * RATE))

# ---------------------------------------------------------------- the walk-in
BPM = 112
BARS = 8
BEAT = 60.0 / BPM
STEP = BEAT / 4
BAR = 4 * BEAT
N = timeline(BARS * BAR)
t = np.arange(N) / RATE
CHORDS = [([53, 57, 60, 64], 38), ([50, 53, 57, 60], 34), ([50, 55, 58, 64], 40), ([49, 55, 60, 65], 33)]   # Dm9 Bbmaj7 Em7b5 A7#9
walk = kit.bus(N); brushes = kit.bus(N); guitar = kit.bus(N); wash = kit.bus(N); lead = kit.bus(N)
WALK = [0, 7, 12, 10]   # root, fifth, octave, seventh: one note a step
for bar in range(BARS):
    notes, root = CHORDS[bar // 2 % 4]
    next_root = CHORDS[(bar + 1) // 2 % 4][1]
    for beat in range(4):
        m = next_root - 1 if bar % 2 == 1 and beat == 3 else root + WALK[beat]
        place(walk, bar * BAR + beat * BEAT, kit.low(m, BEAT * .8, .6, cut=900))
    for s in range(16):
        g = kit.ganza((.5 if s % 4 == 2 else .18) * .35)
        place(brushes, bar * BAR + s * STEP, g, np.roll(g, 41))
    for beat in (1, 3): place(brushes, bar * BAR + beat * BEAT, kit.rim(.2))
    if bar % 2 == 0:
        kit.strum(guitar, bar * BAR, notes, 6 * STEP, .2, spread=.012)
        left, right = kit.pad([m + 12 for m in notes], 2 * BAR, .05, cut=1800)
        place(wash, bar * BAR, left, right)
    kit.strum(guitar, bar * BAR + 10 * STEP, notes, 3 * STEP, .12)
for bar, s, m, length in [(2, 8, 69, 4), (2, 12, 72, 4), (3, 0, 74, 8), (6, 8, 74, 4), (6, 12, 72, 4), (7, 0, 69, 6), (7, 6, 64, 10)]:
    place(lead, bar * BAR + s * STEP, kit.horn(m, length * STEP * .92, .4))
lead = band(lead, low=350, high=2800) + band(lead, low=900, high=1700) * .8
guitar = kit.wow(band(guitar, low=120, high=3600), .003, 7)
wash = kit.wow(band(wash, low=180, high=1600), .005, 5)
wet = kit.reverb(guitar * .4 + lead * .7 + wash * .4 + brushes * .1, 1.8, seed=3)
mix = kit.master({'walk': walk * .27, 'brushes': brushes * 3.2, 'guitar': guitar * 2.2, 'wash': wash * 1.7, 'lead': lead * .95}, (.55 * wet.mean(axis=0) + .45 * wet) * .5)
kit.write(os.path.join(AUDIO, 'entrance.ogg'), mix, section=2 * BAR)

def chord_hit(target, at, notes, root, level):
    """Everything on one instant: the low note, the guitar, the piano, the horn."""
    place(target, at, kit.low(root, .5, level * .9))
    place(target, at, kit.kick(level))
    kit.strum(target, at, notes, .6, level * .35, spread=.004)
    for m in notes:
        place(target, at, kit.epiano(m + 12, .5, level * .16))
        place(target, at, kit.horn(m + 12, .22, level * .22, vibrato=.002))

N = timeline(3.0)
hit = kit.bus(N)
chord_hit(hit, .004, [53, 57, 60, 64], 38, 1.0)
place(hit, .004, kit.snare(.5, .16))
wet = kit.reverb(band(hit, low=200), 2.2, seed=4)
kit.write(os.path.join(AUDIO, 'entrance_hit.ogg'), np.tanh(hit * .9 + (.55 * wet.mean(axis=0) + .45 * wet) * .9) * np.clip((3.0 - np.arange(N) / RATE) / 1.6, 0, 1))

# ---------------------------------------------------------------- the night is clean
LAND = .08           # the title's landing on the result screen
N = timeline(3.2)
clear = kit.bus(N)
chord_hit(clear, LAND, [49, 55, 60, 65], 33, .9)   # the A7#9 that has hung over the whole game
step = 60.0 / 124 / 4
for k, m in enumerate([57, 60, 64, 67, 69, 72, 76]):
    place(clear, LAND + (2 + k) * step, kit.nylon(m, 3 * step, .34 + k * .03))
    hit_t = kit.tamborim() * .14
    place(clear, LAND + (2 + k) * step, hit_t * .6, hit_t)
RESOLVE = LAND + 9 * step
chord_hit(clear, RESOLVE, [54, 57, 61, 64, 66], 38, 1.0)   # and it opens on D major
for m in (69, 74, 78): place(clear, RESOLVE, kit.horn(m, .7, .34, vibrato=.008))
place(clear, RESOLVE, kit.hat(.3, .8) * .7, kit.hat(.3, .8))
wet = kit.reverb(band(clear, low=180), 1.6, seed=5)
fade = np.clip((3.2 - np.arange(N) / RATE) / 1.4, 0, 1)
kit.write(os.path.join(AUDIO, 'night_clear.ogg'), np.tanh(clear * .9 + (.55 * wet.mean(axis=0) + .45 * wet) * .7) * fade)

# ---------------------------------------------------------------- the result screen
def sign(seconds, partials, body, level):
    """A sheet of metal hitting glass: the thud, the crack, and what rings in the metal."""
    n = timeline(seconds); k = np.arange(n) / RATE
    f = 44 + body * np.exp(-k / .02)
    thud = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-k / (seconds * .3))
    crack = kit.rng.normal(0, 1, n) * np.exp(-k / .012)
    ring = sum(np.sin(2 * np.pi * p * k + j) * np.exp(-k / (seconds * .22 / (1 + j * .35))) for j, p in enumerate(partials)) / len(partials)
    out = (thud + crack * .55 + ring * 1.2) * level
    out[:int(.0008 * RATE)] *= np.linspace(0, 1, int(.0008 * RATE))
    out[-int(.02 * RATE):] *= np.linspace(1, 0, int(.02 * RATE))
    return np.stack([out, np.roll(out, 11)])

SFX = os.path.join(AUDIO, 'sfx')
kit.write(os.path.join(SFX, 'slam.ogg'), sign(.5, [412, 1130, 1870, 2760, 3910], 120, 1.0))
kit.write(os.path.join(SFX, 'slam_heavy.ogg'), sign(1.0, [233, 690, 1270, 2110, 3180], 170, 1.0))
n = timeline(.03); k = np.arange(n) / RATE
tick = np.sign(np.sin(2 * np.pi * 1320 * k)) * np.exp(-k / .007) * .5 + kit.rng.normal(0, .1, n) * np.exp(-k / .003)
kit.write(os.path.join(SFX, 'tally_tick.ogg'), np.stack([tick, tick]))

# The blade through the air: noise rising in pitch and falling off, crossing from one ear to the
# other, with the steel's faint ring on top. It starts as the sim's strike lands, so it is quick.
STRIKE = .07
n = timeline(.28); k = np.arange(n) / RATE
air = kit.rng.normal(0, 1, (1, n))
whoosh = np.zeros(n)
for low_f, high_f, at, width, level in ((260, 800, STRIKE - .07, .05, .6), (700, 2200, STRIKE - .025, .035, 1.0), (1800, 5200, STRIKE, .022, .75), (800, 2400, STRIKE + .04, .05, .5)):
    whoosh += band(air, low=low_f, high=high_f, order=3)[0] * np.exp(-((k - at) / width) ** 2) * level
ring = (np.sin(2 * np.pi * 5230 * k) + .6 * np.sin(2 * np.pi * 7840 * k)) * np.exp(-np.maximum(k - STRIKE, 0) / .05) * (k >= STRIKE - .02) * .012
whoosh = (whoosh + ring) * np.clip(k / .02, 0, 1)
across = np.clip(k / (2 * STRIKE), 0, 1)
kit.write(os.path.join(SFX, 'whoosh.ogg'), np.stack([whoosh * (1.2 - .7 * across), whoosh * (.5 + .7 * across)]))
