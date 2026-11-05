# Night twelve, the Síndico: Praça Mauá, election night, on air. One song in three mixes, one per
# stage, sample for sample the same length, so the game can pass from one to the next on the beat.
# 56 s in a seamless loop: 32 bars at 138 BPM in C minor. The harmony of a bossa gone rotten, Cm9 Cm11
# Abmaj7#11 Dbmaj9 Fm9 Dm7b5 G7b9 G7#5, and in its horn the first night's melody, a tone down and
# much angrier: the same dead waiter, at the top of the city.
#   - night_12_comicio.ogg, the rally: a military snare over a war bateria, brass fanfares, and the
#     crowd chanting OR-DEM NA CA-SA;
#   - night_12_apuracao.ogg, the vote count: the same drive stripped to machines. Teletypes, phones,
#     the Plantão's stinger, the arpeggio in front, the marching far behind;
#   - night_12_heliponto.ogg, the helipad: the wind off the bay, a rotor on the eighths, a ship's
#     horn, and the bossa that started it all, a ghost on a worn tape under a slowed choir.
# Writes those files in assets/audio (tools/music_kit.py is the synth).
# Use: blender -b --factory-startup --python tools/build_music_sindico.py
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import music_kit as kit
from music_kit import RATE, place, spectrum_filter as band

HERE = os.path.dirname(os.path.abspath(__file__))
AUDIO = os.path.normpath(os.path.join(HERE, '..', 'assets', 'audio'))
BPM = 138
BARS = 32
BEAT = 60.0 / BPM
STEP = BEAT / 4
BAR = 4 * BEAT
DUR = BARS * BAR
N = int(round(DUR * RATE))
t = np.arange(N) / RATE
kit.seed(2026)
def bus(): return kit.bus(N)

CHORDS = [
    ([58, 62, 63, 67], 36),   # Cm9
    ([55, 58, 62, 65], 34),   # Cm11 over its seventh
    ([55, 60, 62, 63], 32),   # Abmaj7#11
    ([53, 56, 60, 63], 37),   # Dbmaj9
    ([56, 60, 63, 67], 41),   # Fm9
    ([53, 56, 60, 62], 38),   # Dm7b5
    ([53, 56, 59, 62], 31),   # G7b9
    ([53, 59, 63, 67], 31),   # G7#5
]
def chord_at(bar): return CHORDS[(bar // 2) % len(CHORDS)]

# ---------------------------------------------------------------- the drive, in every mix
# The bass: straight sixteenths, driven until it snarls, with a hole before each beat to breathe.
drive = bus()
for bar in range(BARS):
    _, root = chord_at(bar)
    for s in range(16):
        if s % 4 == 3: continue
        place(drive, bar * BAR + s * STEP, kit.low(root + (12 if s % 8 == 6 else 0), STEP * .75, .55 if s % 4 == 0 else .4, cut=2200))
drive = np.tanh(drive * 2.2) * .5

kicks = bus(); marching = bus(); bateria = bus(); hats = bus()
ACCENTS = [1, 0, .35, .35, 1, 0, .35, .35, 1, .35, .35, .35, 1, 0, .7, .7]   # the rudiment of a parade
GANZA = [.5, .22, .32, .8]
TAMBORIM = [0, 3, 6, 10, 12]
for bar in range(BARS):
    start = bar * BAR
    for beat in range(4):
        place(kicks, start + beat * BEAT, kit.kick(.85))
        place(hats, start + (beat + .5) * BEAT, kit.hat(.12, .1) * .8, kit.hat(.12, .1))
        place(bateria, start + beat * BEAT, kit.surdo(.55 if beat % 2 else .2, beat % 2 == 1))
    for s, level in enumerate(ACCENTS):
        if level:
            hit = kit.snare(.22 * level, .08)
            place(marching, start + s * STEP, hit * .85, np.roll(hit, 23))
        g = kit.ganza(GANZA[s % 4] * .3)
        place(bateria, start + s * STEP, g, np.roll(g, 37))
    for s in TAMBORIM:
        hit = kit.tamborim() * .16
        place(bateria, start + s * STEP, hit, hit * .6)
    for beat in (1, 3): place(marching, start + beat * BEAT, kit.snare(.34, .16))
for s in range(0, 16):   # the roll that throws the loop back to the top
    place(marching, (BARS - 1) * BAR + s * STEP, kit.snare(.1 + .018 * s, .07))

PATTERN = [0, 1, 2, 3, 1, 2, 3, 2]
arp = bus()
for bar in range(BARS):
    notes = chord_at(bar)[0]
    for s in range(16):
        tone = kit.pluck(notes[PATTERN[s % 8]] + (24 if s % 4 == 3 else 12), STEP * .7, .1, cut=4200)
        pan = .7 if s % 2 else 1.0
        place(arp, bar * BAR + s * STEP, tone * pan, tone * (1.7 - pan))
arp = band(arp, low=280, high=4200)

# The horn: night one's melody a tone down, in bars 8 to 23.
MOTIF = [(8, 0, 67, 6), (8, 6, 70, 2), (8, 8, 72, 6), (8, 14, 70, 2), (9, 0, 67, 4), (9, 4, 63, 4), (9, 10, 62, 2), (9, 12, 63, 4),
         (10, 0, 70, 6), (10, 6, 67, 2), (10, 8, 65, 4), (10, 12, 62, 4), (11, 0, 58, 8), (11, 10, 62, 2), (11, 12, 65, 4),
         (12, 0, 67, 8), (12, 8, 62, 8), (13, 0, 63, 6), (13, 6, 67, 2), (13, 8, 72, 8),
         (14, 0, 68, 6), (14, 6, 65, 2), (14, 8, 60, 4), (14, 12, 63, 4), (15, 0, 65, 10), (15, 12, 68, 4),
         (16, 0, 72, 8), (16, 8, 75, 4), (16, 12, 72, 4), (17, 0, 68, 6), (17, 6, 67, 2), (17, 8, 63, 8),
         (18, 0, 65, 4), (18, 4, 68, 4), (18, 8, 74, 6), (18, 14, 72, 2), (19, 0, 68, 8), (19, 8, 65, 8),
         (20, 0, 71, 6), (20, 6, 68, 2), (20, 8, 65, 4), (20, 12, 62, 4), (21, 0, 59, 8), (21, 8, 62, 4), (21, 12, 65, 4),
         (22, 0, 67, 4), (22, 4, 71, 4), (22, 8, 75, 8), (23, 0, 74, 8), (23, 8, 71, 8)]
motif = bus()
for bar, s, m, length in MOTIF:
    place(motif, bar * BAR + s * STEP, kit.horn(m, length * STEP * .92, .5, cut=5200))
motif = band(motif, low=320, high=3400) + band(motif, low=900, high=1800) * .7
motif_echo = band(kit.echo(motif, .75 * BEAT, 4, .42), low=300, high=2400)

# The slowed choir and its wash: an "ah" on a worn tape, an octave under the chords.
choir = bus()
for bar in range(0, BARS, 2):
    left, right = kit.pad([m - 12 for m in chord_at(bar)[0]], 2 * BAR, .07, cut=2200, attack=.5, release=1.2)
    place(choir, bar * BAR, left, right)
choir = band(choir, low=450, high=1500, order=3) * 1.6 + band(choir, low=2200, high=3000, order=2) * .5
choir = kit.wow(choir, .006, 11)

# ---------------------------------------------------------------- the rally
# Brass fanfare: a stab on each chord and its answer, root, fifth and top of the chord.
brass = bus()
for bar in range(0, BARS, 2):
    notes, root = chord_at(bar)
    stack = [root + 24, root + 31, notes[-1], notes[-1] + 12]
    for s, length, level in ((0, 3, .3), (3, 1, .18), (6, 2, .22), (16, 3, .26), (22, 2, .2)):
        for m in stack: place(brass, bar * BAR + s * STEP, kit.horn(m, length * STEP * .85, level, vibrato=.002, cut=6000))
brass = band(brass, low=240, high=5000)

def syllable(low_f, high_f, seconds, level):
    """Hundreds of throats on one vowel: noise through the vowel's band, swelling and cut."""
    n = int(seconds * RATE)
    k = np.arange(n) / RATE
    env = np.clip(k / .03, 0, 1) * np.clip((seconds - k) / .07, 0, 1)
    voice = band(kit.rng.normal(0, 1, (2, n)), low=low_f, high=high_f, order=4) + band(kit.rng.normal(0, 1, (2, n)), low=2 * low_f, high=2 * high_f, order=3) * .4
    return voice * env * level
OR, A, E = (380, 820), (720, 1300), (420, 1900)
CHANT = [(0, OR, 3), (4, E, 3), (8, A, 2), (10, A, 2), (12, A, 3)]   # OR-DEM NA CA-SA
crowd = kit.air(N, 300, 2100, 9, .024)
chant = bus()
for bar in range(0, BARS, 2):
    if bar // 2 % 4 == 3: continue   # every fourth time the crowd only roars
    for s, (a, b), length in CHANT:
        v = syllable(a, b, length * STEP, .3)
        place(chant, bar * BAR + s * STEP, v[0], v[1])

# ---------------------------------------------------------------- the count room
teletype = bus()
for k in range(int(BARS * 16 * 1.4)):
    n = int(.012 * RATE); q = np.arange(n) / RATE
    click = kit.rng.normal(0, 1, n) * np.exp(-q / .003) * kit.rng.uniform(.05, .12)
    place(teletype, int(kit.rng.integers(0, BARS * 32)) * STEP / 2, click * .7, np.roll(click, 3))
teletype = band(teletype, low=1400, high=7000)
phones = bus()
for bar, side in ((5, .3), (13, 1.0), (22, .5), (29, .9)):   # a phone, ringing and ringing in another part of the room
    n = int(2 * BEAT * RATE); q = np.arange(n) / RATE
    ring = (np.sin(2 * np.pi * 440 * q) + np.sin(2 * np.pi * 480 * q)) * (np.sin(2 * np.pi * 20 * q) > 0) * .022
    place(phones, bar * BAR, ring * side, ring * (1.3 - side))
    place(phones, bar * BAR + 3 * BEAT, ring * side, ring * (1.3 - side))
phones = band(phones, low=350, high=1800)
plantao = bus()
for bar in range(0, BARS, 8):   # the Plantão's stinger, opening every eight bars
    for s, m in ((0, 72), (2, 72), (4, 79), (8, 84)):
        place(plantao, bar * BAR + s * STEP, kit.pluck(m, (8 if m == 84 else 1.6) * STEP, .22, cut=5200))
        place(plantao, bar * BAR + s * STEP, kit.pluck(m + 6, (8 if m == 84 else 1.6) * STEP, .1, cut=5200))   # a tritone over it: the news is never good
plantao = band(plantao, low=500, high=3800)

# ---------------------------------------------------------------- the helipad
ghost = bus()
COMP = [0, 3, 6, 10, 13, 16, 19, 22, 26, 29]
for bar in range(0, BARS, 2):
    notes, root = chord_at(bar)
    for s in COMP: kit.strum(ghost, bar * BAR + s * STEP, notes, 2.4 * STEP, .17 if s % 16 == 0 else .12)
    for s in (0, 16): place(ghost, bar * BAR + s * STEP, kit.nylon(root + 12, 8 * STEP, .26))
ghost = kit.wow(band(ghost, low=140, high=3200), .007, 17)
wind = kit.air(N, 220, 1500, 5, .05)
blades = band(kit.rng.normal(0, 1, (2, N)), low=60, high=420, order=3)
since = np.mod(t, BEAT / 2)                  # the rotor's beat on the song's eighths
rotor = blades * np.exp(-since / .045) * .3 * (.55 + .45 * np.sin(2 * np.pi * t / DUR - .9))   # circling, closer and away
ship = bus()
n = int(3.4 * RATE); q = np.arange(n) / RATE
call = (np.sin(2 * np.pi * 73.4 * q) + .6 * np.sin(2 * np.pi * 110.1 * q) + .3 * np.sin(2 * np.pi * 146.8 * q)) * kit.envelope(n, .35, .9, hold=2.5) * .08
place(ship, 12 * BAR, call)   # a ship, far out in the bay

# ---------------------------------------------------------------- the three mixes
drive = kit.pump(drive, t, BEAT, .35)
arp = kit.pump(arp, t, BEAT, .35)
choir = kit.pump(choir, t, BEAT, .3)
ghost_pumped = kit.pump(ghost, t, BEAT, .15)

def wide(wet):
    return .55 * wet.mean(axis=0) + .45 * wet

print('comicio')
wet = kit.reverb(marching * .3 + brass * .55 + motif * .35 + motif_echo * .3 + chant * .9 + crowd * .8 + choir * .4, 2.2, seed=12)
mix = kit.master({'drive': drive * .36, 'kick': kicks * .55, 'marching': marching * .95, 'bateria': bateria * .7, 'hats': hats * 1.2, 'brass': brass * .9,
                  'motif': motif * .7, 'echo': motif_echo * .7, 'arp': arp * 1.2, 'choir': choir * .9, 'chant': chant * 2.4, 'crowd': crowd * 8}, wide(wet) * .5)
kit.write(os.path.join(AUDIO, 'night_12_comicio.ogg'), mix, section=8 * BAR)

print('apuracao')
wet = kit.reverb(motif * .3 + motif_echo * .4 + arp * .3 + plantao * .6 + phones * .9 + marching * .15 + choir * .3, 1.3, seed=13)
mix = kit.master({'drive': drive * .36, 'kick': kicks * .55, 'marching': band(marching, high=1800) * .6, 'bateria': bateria * .35, 'hats': hats * 1.2, 'arp': arp * 2.4,
                  'motif': motif * .55, 'echo': motif_echo * .8, 'choir': choir * .9, 'teletype': teletype * 6, 'phones': phones * 8, 'plantao': plantao * 2.2}, wide(wet) * .5)
kit.write(os.path.join(AUDIO, 'night_12_apuracao.ogg'), mix, section=8 * BAR)

print('heliponto')
wet = kit.reverb(ghost * .6 + motif * .7 + motif_echo * .6 + choir * .7 + arp * .15 + marching * .1 + ship * .6, 3.6, damp=2600, seed=14)
mix = kit.master({'ghost': ghost_pumped * 1.6, 'choir': choir * 1.8, 'drive': band(drive, high=420) * .34, 'kick': kicks * .42, 'bateria': band(bateria, high=900) * .4, 'hats': hats * .7,
                  'arp': band(arp, high=1300) * 1.4, 'motif': motif * .5, 'echo': motif_echo * .7, 'wind': wind * 6, 'rotor': rotor * 5, 'ship': ship * 2}, wide(wet) * .6)
kit.write(os.path.join(AUDIO, 'night_12_heliponto.ogg'), mix, section=8 * BAR)
