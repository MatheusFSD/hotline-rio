# The synth every track of Hotline Rio is written with (build_music*.py). No samples, no third-party
# licence, no Content ID. Everything works on a whole loop at once: notes wrap round the end, filters
# and reverb are circular (FFT), the tape wobble runs a whole number of cycles, so no loop has a seam.
# Written out with Blender's audio module (aud).
import os
import numpy as np

RATE = 32000
rng = np.random.default_rng(1958)

def seed(n):
    global rng
    rng = np.random.default_rng(n)

def hz(midi): return 440.0 * 2 ** ((midi - 69) / 12.0)

def bus(n): return np.zeros((2, n))

def place(target, start, left, right=None):
    """Add a note at `start` seconds, wrapping whatever runs past the end back to the start."""
    right = left if right is None else right
    N = target.shape[1]
    i = int(round(start * RATE)) % N
    n = len(left)
    first = min(n, N - i)
    target[0, i:i + first] += left[:first]; target[1, i:i + first] += right[:first]
    if n > first:
        target[0, :n - first] += left[first:]; target[1, :n - first] += right[first:]

def envelope(n, attack, release, hold=None, decay=None):
    """Attack, then either a held level for `hold` s or an exponential decay, then a release."""
    k = np.arange(n) / RATE
    env = np.clip(k / max(attack, 1e-4), 0, 1)
    if decay: env = env * np.exp(-np.maximum(k - attack, 0) / decay)
    if hold is not None: env = env * np.clip((hold + release - k) / release, 0, 1)
    else: env = env * np.clip((n / RATE - k) / release, 0, 1)
    return env

def saw(f, k, cut, phase=0.0):
    """Band-limited saw: harmonics up to `cut` Hz, which also makes it a gentle low-pass."""
    out = np.zeros_like(k)
    for h in range(1, max(1, int(cut / f)) + 1):
        out += np.sin(2 * np.pi * h * f * k + phase * h) / h
    return out * .6

def spectrum_filter(x, low=None, high=None, order=2):
    """Butterworth-shaped magnitude in the frequency domain: circular, so the loop stays whole."""
    spec = np.fft.rfft(x, axis=-1)
    f = np.fft.rfftfreq(x.shape[-1], 1 / RATE)
    gain = np.ones_like(f)
    if high: gain /= np.sqrt(1 + (f / high) ** (2 * order))
    if low: gain *= 1 / np.sqrt(1 + (low / np.maximum(f, 1e-3)) ** (2 * order))
    return np.fft.irfft(spec * gain, n=x.shape[-1], axis=-1)

def reverb(x, seconds, damp=3500, seed=0):
    """Circular convolution with a decaying noise tail, different in each ear."""
    N = x.shape[-1]
    out = np.zeros_like(x)
    r = np.random.default_rng(seed)
    k = np.arange(int(seconds * RATE)) / RATE
    for ch in range(2):
        tail = r.normal(0, 1, len(k)) * np.exp(-k * 6.9 / seconds)
        tail = spectrum_filter(tail[None, :], high=damp)[0]
        tail[:int(.012 * RATE)] *= np.linspace(0, 1, int(.012 * RATE))   # a little pre-delay
        ir = np.zeros(N); ir[:len(tail)] = tail / np.sqrt(np.sum(tail ** 2))
        out[ch] = np.fft.irfft(np.fft.rfft(x[ch]) * np.fft.rfft(ir), n=N)
    return out

def pump(x, t, beat, amount, fall=.16):
    """Sidechain: the sound dips with every beat and swells back."""
    since = np.mod(t, beat)
    return x * (1 - amount * np.exp(-since / fall) * (1 - np.exp(-since / .006)))

def wow(x, depth, cycles):
    """Vaporwave's worn tape: the pitch wanders, `depth` seconds either way, `cycles` times per loop."""
    n = x.shape[-1]
    k = np.arange(n, dtype=float)
    warp = k + depth * RATE * (np.sin(2 * np.pi * cycles * k / n) + .4 * np.sin(2 * np.pi * (cycles * 3 + 1) * k / n))
    return np.stack([np.interp(warp, k, x[ch], period=n) for ch in range(2)])

def echo(x, delay, taps, gain):
    """Bounces between the ears, losing `gain` each time. Only the repeats, not the sound itself."""
    out = np.zeros_like(x)
    for tap in range(1, taps + 1):
        out[tap % 2] += np.roll(x[0] + x[1], int(round(tap * delay * RATE))) * gain ** tap * .5
    return out

# ---------------------------------------------------------------- pitched
def epiano(m, seconds, level):
    """Electric piano: FM, the bell of the attack fading into a soft tone."""
    n = int((seconds + 1.2) * RATE); k = np.arange(n) / RATE
    f = hz(m)
    index = .3 + 1.9 * np.exp(-k / .25)
    tone = np.sin(2 * np.pi * f * k + index * np.sin(2 * np.pi * f * k)) + .15 * np.sin(2 * np.pi * 2 * f * k)
    return tone * envelope(n, .004, .35, hold=seconds) * np.exp(-k / 1.8) * level

_strings = {}
def nylon(m, seconds, level):
    """A nylon string, Karplus-Strong: a burst of noise that the string's own delay rounds into a note."""
    key = (m, round(seconds, 3))
    if key not in _strings:
        f = hz(m)
        p = int(RATE / f - .5)
        n = int((seconds + .25) * RATE)
        x = np.zeros(n + 2)
        burst = rng.normal(0, 1, p); burst[1:] = .5 * (burst[1:] + burst[:-1])   # the thumb, not a nail
        x[1:p + 1] = burst
        for i in range(p + 1, n + 2, p):
            end = min(i + p, n + 2)
            x[i:end] = .4975 * (x[i - p:end - p] + x[i - p - 1:end - p - 1])
        k = np.arange(n, dtype=float)
        tuned = np.interp(k * f * (p + .5) / RATE, np.arange(n + 2), x)   # the delay is whole samples; the note is not
        _strings[key] = tuned * envelope(n, .001, .12, hold=seconds)
    return _strings[key] * level

def strum(target, start, notes, seconds, level, spread=.007):
    """The chord rolled off the thumb, low to high, each string a little to its own side."""
    for j, m in enumerate(notes):
        tone = nylon(m, seconds, level)
        side = (j - (len(notes) - 1) / 2) * .12
        place(target, start + j * spread, tone * (1 - side), tone * (1 + side))

def horn(m, seconds, level, vibrato=.006, cut=4200):
    """A muted horn: every harmonic on one wandering phase, a scoop into the note, vibrato that blooms."""
    n = int((seconds + .12) * RATE); k = np.arange(n) / RATE
    f = hz(m) * (1 + vibrato * np.sin(2 * np.pi * 5.2 * k) * np.clip(k / .3, 0, 1)) * (1 - .025 * np.exp(-k / .03))
    phase = 2 * np.pi * np.cumsum(f) / RATE
    tone = np.zeros(n)
    for h in range(1, max(1, int(cut / hz(m))) + 1): tone += np.sin(h * phase) / h
    return tone * envelope(n, .03, .08, hold=seconds) * level * .5

_plucks = {}
def pluck(m, seconds, level, cut=3400):
    """A short detuned saw, the arpeggio of every neon night."""
    key = (m, round(seconds, 3), cut)
    if key not in _plucks:
        n = int((seconds + .03) * RATE); k = np.arange(n) / RATE
        tone = saw(hz(m), k, cut) + .7 * saw(hz(m) * 2 ** (9 / 1200), k, cut, phase=1.0)
        _plucks[key] = tone * envelope(n, .002, .02, hold=seconds) * np.exp(-k / (seconds + .03))
    return _plucks[key] * level

_lows = {}
def low(m, seconds, level, cut=1400):
    """The bass: a sine for the weight, a saw for the bite."""
    key = (m, round(seconds, 3), cut)
    if key not in _lows:
        n = int((seconds + .06) * RATE); k = np.arange(n) / RATE
        f = hz(m)
        _lows[key] = (np.sin(2 * np.pi * f * k) + .55 * saw(f, k, cut)) * envelope(n, .004, .04, hold=seconds) * (.72 + .28 * np.exp(-k / .1))
    return _lows[key] * level

def cuica(m, seconds, level):
    """The cuíca's groan: a voice that slides up and falls back."""
    n = int(seconds * RATE); k = np.arange(n) / RATE
    f = hz(m) * (1 + .4 * np.sin(np.pi * np.clip(k / seconds, 0, 1)) ** 1.4)
    phase = 2 * np.pi * np.cumsum(f) / RATE
    return (np.sin(phase) + .4 * np.sin(2 * phase) + .15 * np.sin(3 * phase)) * envelope(n, .012, .05, hold=seconds - .05) * level

def pad(notes, seconds, level, cut=2400, attack=.9, release=1.6):
    """Detuned saws, wide, slow to open: (left, right)."""
    n = int((seconds + release) * RATE); k = np.arange(n) / RATE
    left = np.zeros(n); right = np.zeros(n)
    for j, m in enumerate(notes):
        f = hz(m)
        center = saw(f, k, cut, phase=j * 2)
        left += center + .6 * saw(f * 2 ** (-7 / 1200), k, cut * .85, phase=j)
        right += center + .6 * saw(f * 2 ** (7 / 1200), k, cut * .85, phase=j + 2)
    env = envelope(n, attack, release, hold=seconds)
    return left * env * level, right * env * level

# ---------------------------------------------------------------- struck
def surdo(strength, open_):
    n = int((.55 if open_ else .18) * RATE); k = np.arange(n) / RATE
    f = 62 + 34 * np.exp(-k / .03)
    body = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-k / (.32 if open_ else .07))
    return body * strength

def tamborim():
    n = int(.06 * RATE); k = np.arange(n) / RATE
    return (np.sin(2 * np.pi * 980 * k) * .6 + rng.normal(0, .5, n)) * np.exp(-k / .012)

def ganza(level):
    n = int(.05 * RATE); k = np.arange(n) / RATE
    return rng.normal(0, 1, n) * np.exp(-k / .014) * (1 - np.exp(-k / .002)) * level

def clap():
    n = int(.22 * RATE); k = np.arange(n) / RATE
    bursts = sum(np.exp(-np.maximum(k - d, 0) / .008) * (k >= d) for d in (0, .011, .023))
    return rng.normal(0, 1, n) * (bursts * .5 + np.exp(-k / .09) * .5)

def kick(level):
    n = int(.24 * RATE); k = np.arange(n) / RATE
    f = 47 + 125 * np.exp(-k / .022)
    return (np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-k / .12) + rng.normal(0, .25, n) * np.exp(-k / .002)) * level

def snare(level, length=.17):
    """The gated eighties snare: all tail, cut dead."""
    n = int((length + .02) * RATE); k = np.arange(n) / RATE
    body = rng.normal(0, 1, n) * np.exp(-k / (length * .6)) + .7 * np.sin(2 * np.pi * 186 * k) * np.exp(-k / .05)
    return body * np.clip((length + .02 - k) / .02, 0, 1) * level

def rim(level):
    n = int(.05 * RATE); k = np.arange(n) / RATE
    return (np.sin(2 * np.pi * 1720 * k) + .6 * np.sin(2 * np.pi * 2610 * k)) * np.exp(-k / .007) * level

def hat(level, length=.09):
    n = int(length * RATE); k = np.arange(n) / RATE
    return np.diff(rng.normal(0, 1, n + 1)) * np.exp(-k / (length * .4)) * level

# ---------------------------------------------------------------- places
def air(N, low_cut, high_cut, cycles, level):
    """Noise that breathes `cycles` times per loop: a crowd, the wind, a city."""
    k = np.arange(N) / N
    swell = .62 + .28 * np.sin(2 * np.pi * cycles * k) + .1 * np.sin(2 * np.pi * (cycles * 3 + 2) * k + 1)
    return spectrum_filter(rng.normal(0, 1, (2, N)), low=low_cut, high=high_cut) * swell * level

# ---------------------------------------------------------------- mix
def db(x): return 20 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-9)

def master(stems, wet=None):
    """Sums the stems, printing what each one weighs: this tool can measure a mix, not listen to it."""
    print('  ' + '  '.join('%s %.0f' % (name, db(stem)) for name, stem in stems.items()))
    mix = sum(stems.values())
    if wet is not None: mix = mix + wet
    mix = np.tanh(mix * 1.3) / 1.3            # a little tape warmth
    return spectrum_filter(mix, low=28)       # no DC, no rumble

def report(mix, section):
    """Loudness over the loop, the balance of the bands, and the jump across the loop's seam."""
    spec = np.abs(np.fft.rfft(mix.mean(axis=0))) ** 2
    f = np.fft.rfftfreq(mix.shape[1], 1 / RATE)
    bands = [(0, 120), (120, 800), (800, 3000), (3000, 16000)]
    energy = [spec[(f >= a) & (f < b)].sum() for a, b in bands]
    print('  rms %.1f dB, peak %.2f; bands %s' % (db(mix), np.abs(mix).max(),
        '  '.join('%d-%d: %.0f%%' % (a, b, 100 * e / sum(energy)) for (a, b), e in zip(bands, energy))))
    step = int(section * RATE)
    print('  sections ' + ' '.join('%.0f' % db(mix[:, i:i + step]) for i in range(0, mix.shape[1] - step // 2, step)))
    # The loop starts on a downbeat, so the seam is judged against the jump across another downbeat.
    print('  seam %.3f, the next section downbeat %.3f' % (np.abs(mix[:, 0] - mix[:, -1]).max(), np.abs(mix[:, step] - mix[:, step - 1]).max()))

def write(path, mix, section=None):
    import aud
    mix = mix / np.abs(mix).max() * .85
    if section: report(mix, section)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = np.ascontiguousarray(mix.T.astype(np.float32))
    sound = aud.Sound.buffer(data, RATE)
    sound.write(path, RATE, aud.CHANNELS_STEREO, aud.FORMAT_FLOAT32, aud.CONTAINER_OGG, aud.CODEC_VORBIS, 128000, 4096)
    print('MUSIC_READY', path, '%.1f s' % (mix.shape[1] / RATE))
