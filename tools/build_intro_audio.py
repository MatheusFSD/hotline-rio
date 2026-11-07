# The opening newscast's sound, written with the synth (tools/music_kit.py): no samples, no voices
# recorded, no third-party licence. It follows assets/intro/plantao.json, the running order the
# picture and the subtitles also read, so every voice starts on its subtitle and every cut has its
# snow. Writes assets/audio/intro:
#   - plantao.ogg: the set from the click that turns it on to the moment it goes off, out of its
#     own little speaker: the PLANTÃO stinger, the bed under the studio, the snow on every cut, the
#     siren and the crowd on the street, the snap on "8 suspeitos", the VOLTAMOS sting, and the
#     people on it talking;
#   - tv_off.ogg: the tube collapsing to a dot, then ticking as it cools;
#   - room.ogg: the dark room around the set, a seamless loop (the city, crickets, the fridge);
#   - virada_1.ogg: the special report closing Act 1 (assets/news/virada_1_tv.json), the same way:
#     the tram workshop's sirens and radio, Castelar's press pit (shutters, murmur, applause on
#     ORDEM NA CASA), then the computer coming on and MARÉ typing over the IML's silent footage;
#   - after.ogg: once the set is off (plantao.json "after"): Caio out of breath, slowing down as the
#     glow leaves his hand.
#
# Nobody on the set speaks a language. Like the Sims, they talk in made-up syllables with the
# rhythm and the melody of what the subtitle says: each Portuguese word becomes a nonsense word of
# as many syllables, always the same one for the same word ("CORTA PRA MIM" twice sounds twice
# alike), stressed where Portuguese stresses it, rising and falling with the punctuation. The voices
# are formant synthesis: a glottal buzz shaped by four resonances that glide from vowel to vowel,
# noise for the s, the sh, the f and the bursts of the stops. The anchor shouts, the witness is
# out of breath, the lieutenant reads a statement.
# Use: blender -b --factory-startup --python tools/build_intro_audio.py
import os, sys, json, math, re, zlib, unicodedata
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import music_kit as kit
from music_kit import RATE, hz, spectrum_filter as band

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..'))
def program(path):
    return json.load(open(os.path.join(ROOT, *path.split('/')), encoding='utf-8'))
PLAN = program('assets/intro/plantao.json')
# Every programme on the set and the track it gets.
PROGRAMS = [('assets/intro/plantao.json', 'plantao.ogg'), ('assets/news/virada_1_tv.json', 'virada_1.ogg')]
OUT = os.path.join(ROOT, 'assets', 'audio', 'intro')
kit.seed(1026)

def clock(seconds):
    return np.arange(int(round(seconds * RATE))) / RATE

def noise(n, low=None, high=None, order=3, rng=None):
    r = rng if rng is not None else kit.rng
    return band(r.normal(0, 1, (1, n)), low=low, high=high, order=order)[0]

def smooth(x, seconds):
    w = max(3, int(seconds * RATE) | 1)
    win = np.hanning(w); win /= win.sum()
    return np.convolve(np.pad(x, (w // 2, w // 2), mode='edge'), win, mode='valid')

def add(target, at, x, gain=1.0):
    i = int(round(at * RATE))
    if i >= len(target): return
    n = min(len(x), len(target) - i)
    target[i:i + n] += x[:n] * gain

# ---------------------------------------------------------------- the voices
# Four resonances per vowel (Hz), a man's tract; a woman's runs about 15 % higher.
VOWELS = {'a': (760, 1260, 2550, 3500), 'e': (440, 1950, 2600, 3500), 'E': (600, 1780, 2550, 3500),
    'i': (300, 2250, 2950, 3600), 'o': (470, 900, 2450, 3400), 'O': (620, 1000, 2500, 3400),
    'u': (330, 850, 2350, 3300), 'A': (620, 1300, 2500, 3400)}
VOWEL_ODDS = {'a': .22, 'e': .13, 'E': .08, 'i': .12, 'o': .13, 'O': .07, 'u': .17, 'A': .08}
# Consonants: kind, voiced, the band of their noise (Hz), how loud it is, where F2 heads (locus).
CONSONANTS = {
    'p': ('stop', False, (300, 1500), .5, 900), 't': ('stop', False, (3000, 7000), .45, 1800),
    'k': ('stop', False, (1400, 3400), .5, 2100), 'b': ('stop', True, (200, 1200), .25, 900),
    'd': ('stop', True, (2500, 6000), .22, 1700), 'g': ('stop', True, (1200, 3000), .25, 2000),
    'm': ('nasal', True, None, 0, 1000), 'n': ('nasal', True, None, 0, 1500),
    's': ('fric', False, (4200, 9000), .30, 1700), 'S': ('fric', False, (2100, 5200), .34, 1900),
    'f': ('fric', False, (1200, 8000), .10, 1100), 'v': ('fric', True, (1200, 7000), .07, 1100),
    'z': ('fric', True, (4000, 9000), .16, 1700), 'h': ('aspirate', False, None, .55, None),
    'l': ('liquid', True, None, 0, 1100), 'r': ('tap', True, None, 0, 1500)}
ONSETS = ['b', 'd', 'g', 'p', 't', 'k', 'm', 'n', 's', 'S', 'f', 'v', 'z', 'l', 'h', 'bl', 'pr', 'tr',
    'gr', 'sk', 'fl', '', '', 'n', 'b', 'd', 'l', 'S', 'm']
CODAS = ['', '', '', '', '', 'n', 's', 'l', 'm', 'b']

# Who speaks how: pitch (Hz), how far the stressed syllables jump, syllables a second, how bright
# the buzz is (the harmonics fall as 1/h^tilt), breath in it, formant scale, loudness.
VOICES = {
    'anchor': {'f0': 132, 'accent': .55, 'rate': 7.4, 'tilt': .95, 'breath': .04, 'tract': 1.0, 'jitter': .016, 'gain': 1.0},
    'witness': {'f0': 228, 'accent': .42, 'rate': 6.8, 'tilt': 1.35, 'breath': .16, 'tract': 1.16, 'jitter': .022, 'gain': .85},
    'cop': {'f0': 101, 'accent': .13, 'rate': 5.0, 'tilt': 1.45, 'breath': .05, 'tract': .97, 'jitter': .01, 'gain': .8},
    # The candidate: low, slow, sure of himself, every stress landing like a promise.
    'castelar': {'f0': 94, 'accent': .3, 'rate': 4.4, 'tilt': 1.25, 'breath': .03, 'tract': .95, 'jitter': .006, 'gain': .95}}

def plain(word):
    return ''.join(c for c in unicodedata.normalize('NFD', word.lower()) if unicodedata.category(c) != 'Mn')

def syllable_count(word):
    return max(1, len(re.findall('[aeiouy]+', plain(word))))

def nonsense(word, count):
    """The made-up word a real one becomes: the same every time, as many syllables."""
    r = np.random.default_rng(zlib.crc32(plain(word).encode()))
    vowels, odds = list(VOWEL_ODDS), np.array(list(VOWEL_ODDS.values()))
    out = []
    for i in range(count):
        onset = ONSETS[r.integers(len(ONSETS))] if i or r.random() < .8 else ''
        coda = CODAS[r.integers(len(CODAS))] if i == count - 1 or r.random() < .2 else ''
        out.append((onset, vowels[r.choice(len(vowels), p=odds / odds.sum())], coda))
    return out

def phrases(line):
    """The subtitle cut where it breathes: (words, the mark that ends them)."""
    out = []
    for chunk, mark in re.findall(r'([^,.!?:…]+)([,.!?:…]*)', line.replace('...', '…')):
        words = re.findall(r"[\wÀ-ÿ]+", chunk)
        if words: out.append((words, mark[:1] or ','))
    return out

def score(line, who):
    """Every sound of the line in order: (phoneme, seconds, loudness, pitch above the voice's own)."""
    v = VOICES[who]; beat = 1.0 / v['rate']
    sounds = []
    for p, (words, mark) in enumerate(phrases(line)):
        loud = mark in '!'
        syllables = []
        for word in words:
            n = syllable_count(word)
            stress = n - 2 if n >= 2 else 0
            if re.search('[áéíóúâêô]', word.lower()) and n >= 1:   # a written accent moves it last
                if re.search('[áéíóúâêô][^aeiou]*$', word.lower()): stress = n - 1
            for i, syl in enumerate(nonsense(word, n)): syllables.append((syl, i == stress))
        total = len(syllables)
        for i, ((onset, vowel, coda), stressed) in enumerate(syllables):
            last = i == total - 1
            through = i / max(1, total - 1)
            # Each phrase starts up and drifts down; stressed syllables jump; an exclamation
            # leaps on its last stress, a statement falls.
            pitch = .18 * (1 - through) + (v['accent'] * (1.25 if loud else .8) if stressed else 0)
            if last: pitch += v['accent'] * (.9 if loud else -.35)
            if who == 'witness': pitch += .08 * math.sin(i * 2.3 + p)
            length = beat * (1.3 if stressed else .9) * (1.7 if last else 1.0)
            gain = (1.0 if stressed else .72) * (1.12 if loud and last else 1.0)
            consonants = onset + coda
            vowel_share = max(.45, 1 - .17 * len(consonants))
            for c in onset: sounds.append((c, length * .17, gain, pitch))
            sounds.append((vowel, length * vowel_share, gain, pitch))
            for c in coda: sounds.append((c, length * .17, gain * .8, pitch - .05))
        sounds.append(('_', {'!': .26, '.': .3, '?': .26, ':': .2, '…': .42}.get(mark, .13), 0, 0))
    return sounds

def cascade(x, tracks, widths):
    """Four resonators in a row, their frequencies moving sample by sample."""
    T = 1.0 / RATE
    coeffs = []
    for f, bw in zip(tracks, widths):
        r = math.exp(-math.pi * bw * T)
        b = 2 * r * np.cos(2 * np.pi * f * T); c = -r * r
        coeffs.append(((1 - b - c).tolist(), b.tolist(), [c] * len(x)))
    (a1, b1, c1), (a2, b2, c2), (a3, b3, c3), (a4, b4, c4) = coeffs
    xs = x.tolist(); out = [0.0] * len(xs)
    p1 = q1 = p2 = q2 = p3 = q3 = p4 = q4 = 0.0
    for i in range(len(xs)):
        y = a1[i] * xs[i] + b1[i] * p1 + c1[i] * q1; q1 = p1; p1 = y
        y = a2[i] * y + b2[i] * p2 + c2[i] * q2; q2 = p2; p2 = y
        y = a3[i] * y + b3[i] * p3 + c3[i] * q3; q3 = p3; p3 = y
        y = a4[i] * y + b4[i] * p4 + c4[i] * q4; q4 = p4; p4 = y
        out[i] = y
    return np.array(out)

def speak(line, who, fit=None, seed=0):
    """The line in nonsense, `fit` seconds long at most."""
    v = VOICES[who]
    sounds = score(line, who)
    natural = sum(s[1] for s in sounds[:-1])
    stretch = min(1.12, fit / natural) if fit else 1.0
    sounds = [(c, d * stretch, g, p) for c, d, g, p in sounds[:-1]]
    n = int(sum(s[1] for s in sounds) * RATE) + int(.15 * RATE)
    F = np.zeros((4, n)); voiced = np.zeros(n); pitch = np.zeros(n); asp = np.zeros(n)
    fric = {}
    rng = np.random.default_rng(seed)
    last_vowel = VOWELS['a']
    # The vowel each consonant leans toward: the next one.
    upcoming = []
    nxt = VOWELS['a']
    for c, d, g, p in reversed(sounds):
        if c in VOWELS: nxt = VOWELS[c]
        upcoming.append(nxt)
    upcoming.reverse()
    t = 0
    keys = []                                                          # the melody: a pitch at each vowel
    for (c, d, g, p), ahead in zip(sounds, upcoming):
        i0, i1 = int(t * RATE), int((t + d) * RATE); t += d
        if i1 <= i0: continue
        pitch[i0:i1] = p
        if c == "_": continue                                          # a breath between phrases
        if c in VOWELS:
            F[:, i0:i1] = np.array(VOWELS[c])[:, None]
            # A vowel swells in and sags off, it never holds flat.
            voiced[i0:i1] = g * np.interp(np.linspace(0, 1, i1 - i0), (0, .3, 1), (.8, 1, .68))
            keys.append(((i0 + i1) / 2, p))
            last_vowel = VOWELS[c]
            continue
        kind, voicing, noise_band, level, locus = CONSONANTS[c]
        target = np.array(ahead, dtype=float)
        if locus: target[1] = target[1] * .45 + locus * .55
        target[0] = min(target[0], 350)
        F[:, i0:i1] = target[:, None]
        if kind == 'stop':
            hold = int((i1 - i0) * .55)
            voiced[i0:i0 + hold] = .12 * g if voicing else 0          # the closure
            burst = min(i1, i0 + hold + int(.012 * RATE))
            fric.setdefault(noise_band, np.zeros(n))[i0 + hold:burst] += level * g
            if voicing: voiced[burst:i1] = g * .8
            else: asp[burst:i1] += .5 * g                              # the puff before the vowel
        elif kind == 'nasal':
            F[:, i0:i1] = np.array((270, 1050 if c == 'm' else 1550, 2400, 3300))[:, None]
            voiced[i0:i1] = .45 * g
        elif kind == 'fric':
            fric.setdefault(noise_band, np.zeros(n))[i0:i1] += level * g
            voiced[i0:i1] = .35 * g if voicing else 0
        elif kind == 'aspirate':
            asp[i0:i1] += level * g; voiced[i0:i1] = 0
        elif kind == 'liquid':
            F[:, i0:i1] = np.array((380, 1100, 2700, 3400))[:, None]; voiced[i0:i1] = .7 * g
        elif kind == 'tap':
            F[:, i0:i1] = np.array((450, 1400, 2000, 3300))[:, None]; voiced[i0:i1] = .45 * g
    # Glides between the targets, never a click.
    F = np.stack([smooth(f, .028) for f in F]) * v['tract']
    voiced = smooth(voiced, .012); asp = smooth(asp, .008)
    k = np.arange(n) / RATE
    wobble = smooth(rng.normal(0, 1, n), .03); wobble /= np.abs(wobble).max() + 1e-9
    if keys: pitch = np.interp(np.arange(n), [k_[0] for k_ in keys], [k_[1] for k_ in keys])
    f0 = v['f0'] * (1 + smooth(pitch, .05)) * (1 + v['jitter'] * wobble + .006 * np.sin(2 * np.pi * 5.4 * k))
    phase = 2 * np.pi * np.cumsum(f0) / RATE
    buzz = np.zeros(n)
    for h in range(1, int(4800 / f0.min()) + 1):
        buzz += (h * f0 < 4800) * np.sin(h * phase) / h ** v['tilt']
    breath = rng.normal(0, 1, n) * (.5 + .5 * np.cos(phase))
    source = buzz * voiced * (1 - v['breath']) + breath * (voiced * v['breath'] * 2.2 + asp * 1.6)
    out = cascade(source, F, (75, 95, 140, 220))
    for (lo, hi), env in fric.items():
        out += noise(n, lo, min(hi, RATE / 2 - 500), 3, rng) * smooth(env, .006) * 4.0
    out = np.tanh(out / (np.abs(out).max() + 1e-9) * 1.6) * v['gain']   # the microphone pushed
    out[-int(.01 * RATE):] *= np.linspace(1, 0, int(.01 * RATE))
    return out

# ---------------------------------------------------------------- the station's music
def stab(notes, seconds, level, cut=4500):
    return sum(kit.horn(m, seconds, level, vibrato=0, cut=cut) for m in notes)

def timpani(m, level, decay=.7):
    n = int((decay * 2) * RATE); k = np.arange(n) / RATE
    f = hz(m) * (1 + .06 * np.exp(-k / .05))
    body = np.sin(2 * np.pi * np.cumsum(f) / RATE) + .4 * np.sin(2 * np.pi * np.cumsum(f * 1.5) / RATE)
    return (body * np.exp(-k / decay) + noise(n, 80, 900) * np.exp(-k / .03) * .5) * level

def cymbal(level, decay=1.3):
    n = int(decay * 2 * RATE); k = np.arange(n) / RATE
    return noise(n, 4500, None, 2) * np.exp(-k / decay) * (1 - np.exp(-k / .002)) * level

def whoosh(seconds, level):
    k = clock(seconds)
    x = noise(len(k), 300, 6000) * (k / seconds) ** 2.5
    return x * level

def stinger(target, at):
    """PLANTÃO: three stabs climbing, then the chord held over a timpani roll."""
    for i, (when, chord) in enumerate(((0, (50, 53, 57, 62)), (.3, (50, 53, 57, 62)), (.6, (51, 55, 58, 63)))):
        add(target, at + when, stab(chord, .16, .5))
        add(target, at + when, timpani(38 if i < 2 else 39, .9, .25))
    add(target, at + .9, stab((50, 57, 62, 65, 69), 1.25, .55))
    add(target, at + .9, kit.low(26, 1.3, .9))
    add(target, at + .9, cymbal(.35))
    for j in range(20):                                              # the roll swelling under it
        add(target, at + .9 + j * .06, timpani(38, .15 + .5 * j / 20, .12))
    add(target, at + 2.2, timpani(38, 1.0, .5))

def bed(seconds, bpm=120):
    """Tense, cheap and busy: a pulsing bass in D minor, ticking hats, a rim on two and four."""
    out = np.zeros(int(seconds * RATE) + RATE)
    step = 60.0 / bpm / 2
    line = [38, 38, 38, 38, 41, 41, 40, 40]
    for i in range(int(seconds / step)):
        add(out, i * step, kit.low(line[i % 8], step * .7, .55))
        add(out, i * step, kit.hat(.18 if i % 2 else .3, .05))
        add(out, i * step + step / 2, kit.hat(.1, .03))
        if i % 4 == 2: add(out, i * step, kit.rim(.35))
    left, right = kit.pad((50, 53, 57), seconds, .05, cut=1600)
    add(out, 0, (left + right) / 2)
    return out

def siren(seconds, level):
    """A patrol car's wail down the street, rising and falling."""
    k = clock(seconds)
    f = 720 + 520 * (.5 - .5 * np.cos(2 * np.pi * k / 1.7))
    phase = 2 * np.pi * np.cumsum(f) / RATE
    tone = np.sin(phase) + .33 * np.sin(3 * phase) + .2 * np.sin(5 * phase)
    tone = band(tone[None, :], low=400, high=2600)[0]
    return tone * level

def crowd(seconds, people=7, level=1.0):
    """Onlookers behind the tape: a few voices at once, far off, none of them clear."""
    out = np.zeros(int(seconds * RATE) + RATE)
    r = np.random.default_rng(77)
    words = 'ELE TAVA LÁ DENTRO GENTE OLHA POLÍCIA MEU DEUS QUE ISSO SAI DAQUI MOÇO NINGUÉM VIU'.split()
    for i in range(people):
        who = ['anchor', 'witness', 'cop'][i % 3]
        t = r.random() * .8
        while t < seconds - 1:
            line = ' '.join(r.choice(words, r.integers(3, 7))) + '!'
            voice = speak(line, who, seed=i * 31 + int(t * 10))
            add(out, t, voice, .25 + .2 * r.random())
            t += len(voice) / RATE + .3 + r.random() * 1.2
    out = band(out[None, :], low=250, high=2200)[0][:int(seconds * RATE)]
    return out / (np.abs(out).max() + 1e-9) * level

def squelch(level):
    k = clock(.22)
    return (noise(len(k), 900, 3500) * .6 + np.sin(2 * np.pi * 1850 * k) * (k < .05)) * np.exp(-k / .08) * level

def snow(seconds, level):
    k = clock(seconds)
    return noise(len(k), 700, 7500, 2) * np.exp(-k / (seconds * .45)) * level

# ---------------------------------------------------------------- the set itself
def switch_on():
    """The knob's click, the degauss thudding through the cabinet, the tube waking."""
    k = clock(1.4)
    click = noise(len(k), 1500, None, 2) * np.exp(-k / .004) + np.sin(2 * np.pi * 2300 * k) * np.exp(-k / .015) * .4
    hum = sum(np.sin(2 * np.pi * f * k) / i for i, f in enumerate((60, 120, 180, 240), 1))
    swell = np.clip((k - .05) / .05, 0, 1) * np.exp(-np.maximum(k - .1, 0) / .35)
    rattle = noise(len(k), 90, 600) * swell * .4
    return click * .9 + (hum * .55 + rattle) * swell

def switch_off():
    """The picture snapping to a dot with a falling zap, then the glass ticking as it cools."""
    k = clock(1.6)
    click = noise(len(k), 1500, None, 2) * np.exp(-k / .004)
    f = 60 + 1700 * np.exp(-k / .06)
    zap = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-k / .18) * .5
    ticks = np.zeros(len(k))
    r = np.random.default_rng(5)
    for at in sorted(r.uniform(.3, 1.4, 7)):
        i = int(at * RATE); n = int(.006 * RATE)
        ticks[i:i + n] += r.normal(0, 1, n) * np.exp(-np.arange(n) / (.0015 * RATE)) * (1.5 - at) * .4
    static = noise(len(k), 1000, 8000) * np.exp(-k / .12) * .3
    out = click * .8 + zap + static + ticks
    return out

def speaker(x):
    """Through the set's own speaker, in a small room."""
    x = band(x[None, :], low=170, high=5200, order=2)[0]
    x = np.tanh(x * 1.4) / 1.4
    pad = np.concatenate([x, np.zeros(RATE)])
    wet = kit.reverb(np.stack([pad, pad]), .35, damp=3000, seed=3)
    return np.stack([pad, pad])[:, :len(x)] + wet[:, :len(x)] * .1

def shutter(level):
    """A press camera: the mirror slapping up, the flash whining back."""
    k = clock(.25)
    return (noise(len(k), 1500, None, 2) * np.exp(-k / .006) + np.sin(2 * np.pi * (3200 + 2000 * k) * k) * np.exp(-k / .1) * .08) * level

def applause(seconds, level):
    """A room of supporters clapping: many hands, each a short burst."""
    out = np.zeros(int(seconds * RATE))
    r = np.random.default_rng(31)
    for _ in range(int(seconds * 60)):
        at = r.random() * seconds
        i = int(at * RATE); m = int(.02 * RATE)
        if i + m < len(out): out[i:i + m] += r.normal(0, 1, m) * np.exp(-np.arange(m) / (.004 * RATE)) * (.5 + r.random())
    out = band(out[None, :], low=500, high=6000)[0]
    k = np.arange(len(out)) / RATE
    return out / (np.abs(out).max() + 1e-9) * np.clip(k / .3, 0, 1) * np.clip((seconds - k) / .8, 0, 1) * level

def boot(level):
    """The computer coming on: the PC speaker's beep, the hard disk seeking."""
    k = clock(1.6)
    beep = np.sin(2 * np.pi * 1000 * k) * (k < .18)
    seek = np.zeros(len(k)); r = np.random.default_rng(12)
    for at in r.uniform(.3, 1.5, 14):
        i = int(at * RATE); m = int(.012 * RATE)
        seek[i:i + m] += r.normal(0, 1, m) * np.exp(-np.arange(m) / (.003 * RATE))
    return (beep * .4 + band(seek[None, :], low=1500, high=7000)[0] * .5) * level

def typing(seconds, level, seed):
    """MARÉ at her keyboard, somewhere: a burst of keys, a pause, again."""
    out = np.zeros(int(seconds * RATE)); r = np.random.default_rng(seed); t = 0.0
    while t < seconds - .1:
        i = int(t * RATE); m = int(.03 * RATE)
        if i + m < len(out): out[i:i + m] += (r.normal(0, 1, m) * .6 + np.sin(2 * np.pi * (1800 + 600 * r.random()) * np.arange(m) / RATE)) * np.exp(-np.arange(m) / (.005 * RATE))
        t += .07 + r.random() * .09 + (.35 if r.random() < .08 else 0)
    return out * level

def swell(x, seconds=.15):
    return x * np.clip(np.arange(len(x)) / RATE / seconds, 0, 1)

STUDIO_SHOTS = ('anchor_medium', 'anchor_close')
STREET_SHOTS = ('witness', 'cop', 'oficina')
PRESS_SHOTS = ('press', 'press_close')

def soundtrack(plan):
    """The programme from the click to the moment it goes off, shot by shot: what each kind of
    shot sounds like is decided here, the timing by the running order."""
    end = plan['power_off'] + .3
    n = int(end * RATE)
    tv = np.zeros(n)
    shots = plan['shots']
    spans = [(at, shots[i + 1][0] if i + 1 < len(shots) else end, name) for i, (at, name, _) in enumerate(shots)]
    add(tv, .05, snow(1.0, .35))                                  # the tube warming
    for i, (start, stop, name) in enumerate(spans):
        length = stop - start
        fade = np.clip((length - clock(length + .3)) / .3, 0, 1)
        if name == 'plantao': stinger(tv, start + .85)
        elif name in STUDIO_SHOTS or name == 'cctv':
            music = bed(length + .3)[:len(fade)] * fade
            add(tv, start, music, .5 if name != 'cctv' else .22)
        elif name == 'anchor_point':
            add(tv, start, bed(length + .2, bpm=132)[:len(fade)] * fade, .55)
            snap = start + 2.6
            add(tv, snap - .28, whoosh(.28, .5))
            add(tv, snap, stab((38, 50, 57, 62, 65), .3, .6)); add(tv, snap, timpani(38, 1.0, .6)); add(tv, snap, cymbal(.25, .8))
        elif name in STREET_SHOTS:
            add(tv, start, swell(crowd(length + .2)), .22)
            add(tv, start - .1, siren(length + .3, .12))
            add(tv, start + min(2.6, length * .6), squelch(.25))
        elif name in PRESS_SHOTS:
            add(tv, start, swell(crowd(length + .2, people=9)), .1)
            r = np.random.default_rng(int(start * 10))
            for at in np.sort(r.uniform(0, length, int(length * 2.3))): add(tv, start + at, shutter(.35))
        elif name == 'outro':
            out_at = start + .08
            for j, m in enumerate((57, 62, 65)): add(tv, out_at + j * .12, stab((m, m - 12), .1, .45))
            add(tv, out_at + .36, stab((50, 57, 62, 65, 69), .9, .55)); add(tv, out_at + .36, cymbal(.35)); add(tv, out_at + .36, timpani(38, .9, .6))
        elif name == 'loki':
            add(tv, start, boot(.8))
            add(tv, start + 1.3, noise(int((length - 1.3) * RATE), 3000, 9000) * .02)   # the footage has no sound, only hiss
        if i: add(tv, start, snow(.18, .45))                       # snow on every cut
    # The people on the set, each on the second their subtitle comes up; MARÉ only types.
    for i, (start, stop, who, line) in enumerate(plan['lines']):
        if who in VOICES:
            voice = speak(line, who, fit=stop - start - .25, seed=i)
            print('  %-8s %.2f s of %.2f  %s' % (who, len(voice) / RATE, stop - start, line))
            add(tv, start + .06, voice, 1.0)
        elif who == 'mare':
            add(tv, start, typing(min(stop - start, len(line) / 30.0 + .3), .25, i))
    # ORDEM NA CASA: the room claps.
    for start, stop, who, line in plan['lines']:
        if who == 'castelar' and line.startswith('ORDEM NA CASA'): add(tv, stop - .6, applause(3.2, .35))
    mix = speaker(tv)
    # Out of the speaker's reach: the switch, the degauss and the faint whine of the tube.
    set_ = np.zeros(n)
    add(set_, 0, switch_on(), .9)
    k = np.arange(n) / RATE
    set_ += np.sin(2 * np.pi * 15300 * k) * .006 * np.clip((k - .3) / .3, 0, 1)
    mix = mix + set_[None, :]
    mix[:, -int(.01 * RATE):] *= np.linspace(1, 0, int(.01 * RATE))
    return mix

def room(seconds=12.0):
    """The flat at night, looping: traffic far down the hill, crickets, the fridge."""
    N = int(seconds * RATE)
    city = kit.air(N, 40, 380, 2, .5)
    k = np.arange(N) / RATE
    fridge = np.sin(2 * np.pi * 120 * k) * .025 + np.sin(2 * np.pi * 240 * k) * .01
    crickets = np.zeros(N)
    r = np.random.default_rng(9)
    for at in np.arange(.2, seconds, .85):
        at += r.random() * .2
        for p in range(3):
            i = int((at + p * .033) * RATE) % N; m = int(.018 * RATE)
            idx = (np.arange(m) + i) % N
            crickets[idx] += np.sin(2 * np.pi * 4700 * np.arange(m) / RATE) * np.hanning(m) * .05
    mono = city.mean(axis=0) + fridge + crickets
    return np.stack([mono + city[0] * .3, mono + city[1] * .3])

def breath(seconds, level, inhale):
    """One breath through an open mouth: noise shaped by a loose vowel, in higher and softer."""
    n = int(seconds * RATE); k = np.arange(n) / RATE
    env = np.sin(np.pi * np.clip(k / seconds, 0, 1)) ** (1.6 if inhale else 1.0)
    if not inhale: env *= np.exp(-k / (seconds * .8))
    F = [np.full(n, f) for f in ((420, 2100, 2700, 3500) if inhale else (650, 1500, 2500, 3400))]
    air = cascade(kit.rng.normal(0, 1, n) * env, F, (160, 220, 320, 420))
    air = band(air[None, :], low=250, high=6000)[0]
    return air / (np.abs(air).max() + 1e-9) * level

def aftermath():
    after = PLAN['after']
    out = np.zeros(int((after['black'] + .5) * RATE))
    t, strength = .45, 1.0
    while t < after['black'] - .2:
        period = .75 + .5 * (t / after['black'])             # slowing down as the hand fades
        add(out, t, breath(period * .4, .55 * strength, True))
        add(out, t + period * .42, breath(period * .55, strength, False))
        t += period; strength *= .9
    wet = kit.reverb(np.stack([np.concatenate([out, np.zeros(RATE)])] * 2), .5, damp=2500, seed=4)[:, :len(out)]
    return np.stack([out, out]) + wet * .18

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for path, name in PROGRAMS:
        print(path)
        kit.write(os.path.join(OUT, name), soundtrack(program(path)))
    off = switch_off()
    kit.write(os.path.join(OUT, 'tv_off.ogg'), np.stack([off, off]))
    kit.write(os.path.join(OUT, 'room.ogg'), room())
    kit.write(os.path.join(OUT, 'after.ogg'), aftermath())
    print('INTRO_AUDIO_READY')
