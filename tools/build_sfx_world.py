# The small sounds of the world answering, written with the synth (tools/music_kit.py), no samples:
#   - wall_hit: a bullet into masonry, a crack and a little grit;
#   - casing: brass landing, bouncing three times on the floor;
#   - step_a, step_b: the hero's feet, two so they alternate;
#   - katana_draw, gun_draw: changing hands, steel leaving the scabbard or a pistol grip slapped home;
#   - breaker: the fuse box going, a clunk, an arc, the building's hum dying;
#   - camera_break: a security camera shot or cut, its housing cracking and glass falling.
# Every sound starts on its own attack, so it lands on the frame of the event. The levels between them
# live in scripts/sound_board.gd.
# Use: blender -b --factory-startup --python tools/build_sfx_world.py
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import music_kit as kit
from music_kit import RATE, spectrum_filter as band

HERE = os.path.dirname(os.path.abspath(__file__))
SFX = os.path.normpath(os.path.join(HERE, '..', 'assets', 'audio', 'sfx'))
kit.seed(2112)

def clock(seconds):
    return np.arange(int(round(seconds * RATE))) / RATE

def noise(k, low=None, high=None, order=3):
    return band(kit.rng.normal(0, 1, (1, len(k))), low=low, high=high, order=order)[0]

def drop(k, at, decay):
    """Silent until `at`, then an instant hit falling off exponentially."""
    return np.where(k >= at, np.exp(-np.maximum(k - at, 0) / decay), 0.0)

def tone(k, freq):
    return np.sin(2 * np.pi * freq * k)

def out(name, x):
    x = x.copy()
    x[-int(.004 * RATE):] *= np.linspace(1, 0, int(.004 * RATE))   # never ends on a click
    kit.write(os.path.join(SFX, name + '.ogg'), np.stack([x, x]))

# A bullet into masonry: the crack of the chip, the brick's body under it, then grit falling.
k = clock(.22)
sweep = 2 * np.pi * np.cumsum(170 - 80 * np.clip(k / .05, 0, 1)) / RATE
wall = noise(k, 900, 5000) * drop(k, 0, .012) * 1.0
wall += noise(k, 200, 900) * drop(k, 0, .035) * .7
wall += np.sin(sweep) * drop(k, 0, .03) * .55
for at, level in ((.045, .10), (.075, .07), (.11, .05), (.15, .03)):
    wall += noise(k, 3000, 8000) * drop(k, at, .005) * level
out('wall_hit', wall)

# Brass on the floor: a few inharmonic partials, ringing shorter and a little sharper each bounce.
k = clock(.34)
casing = np.zeros(len(k))
for at, level, decay, bend in ((0, 1.0, .03, 1.0), (.092, .52, .022, 1.012), (.158, .28, .016, 1.02), (.204, .13, .012, 1.026)):
    for partial, share in ((3180, 1.0), (4730, .65), (6950, .45), (9120, .25)):
        casing += tone(k - at, partial * bend) * share * level * drop(k, at, decay * (3180 / partial) ** .5)
out('casing', casing)

# A foot on a hard floor: a soft low thump, heel and then a touch of scuff.
for name, pitch, scuff_at in (('step_a', 82, .012), ('step_b', 94, .018)):
    k = clock(.15)
    step = tone(k, pitch) * drop(k, 0, .032) * .9
    step += noise(k, high=420) * drop(k, 0, .028) * .9
    step += noise(k, 1500, 4200) * drop(k, scuff_at, .007) * .16
    out(name, step * np.clip(k / .002, 0, 1))

# Steel leaving the scabbard: a scrape climbing for a moment, then the blade ringing free.
k = clock(.52)
free = .13
scrape = noise(k, 2800, 9000) * np.clip(k / .02, 0, 1) * np.clip((free + .012 - k) / .012, 0, 1) * (.35 + 2.4 * np.clip(k / free, 0, 1)) * .32
ring = sum(tone(k - free, f) * share * drop(k, free, d) for f, share, d in ((3120, .5, .2), (5230, .8, .16), (7840, .45, .1)))
out('katana_draw', scrape + ring * .55)

# A gun coming to hand: cloth, then the grip slapped into the palm and a small steel click.
k = clock(.2)
cloth = noise(k, 400, 2000) * np.exp(-((k - .025) / .018) ** 2) * .35
slap = noise(k, 150, 900) * drop(k, .07, .018) * .8 + tone(k - .07, 140) * drop(k, .07, .02) * .5
click = noise(k, 2200, 7000) * drop(k, .1, .005) * .6 + tone(k - .1, 2650) * drop(k, .1, .009) * .35
out('gun_draw', cloth + slap + click)

# The breaker: the handle's clunk, a stutter of arc, the building's hum sliding down and away.
k = clock(1.15)
clunk = tone(k, 62) * drop(k, 0, .06) * 1.0 + noise(k, 280, 1800) * drop(k, 0, .022) * .9
gate = np.zeros(len(k))
for i in range(11):
    at = .012 + kit.rng.uniform(0, .3)
    gate += drop(k, at, kit.rng.uniform(.004, .014)) * kit.rng.uniform(.35, 1.0)
arc = noise(k, 2500, 9000) * np.minimum(gate, 1.0) * .55
hum_f = 118 * np.exp(-np.maximum(k - .04, 0) / .42) + 24
phase = 2 * np.pi * np.cumsum(hum_f) / RATE
hum = (np.sin(phase) + .5 * np.sin(2 * phase) + .28 * np.sin(3 * phase)) * np.clip((k - .03) / .02, 0, 1) * np.clip((1.15 - k) / .75, 0, 1) ** 2 * .3
out('breaker', clunk + arc + hum)

# A camera breaking: the housing's crack and thud, sparks spitting, bits of glass landing after.
k = clock(.56)
crack = noise(k, 1800, 8000) * drop(k, 0, .014) * 1.0 + noise(k, 300, 1200) * drop(k, 0, .032) * .7
gate = np.zeros(len(k))
for i in range(8):
    gate += drop(k, kit.rng.uniform(.03, .3), kit.rng.uniform(.003, .009)) * kit.rng.uniform(.3, .8)
sparks = noise(k, 3500, 10000) * np.minimum(gate, 1.0) * .4
glass = np.zeros(len(k))
for at, level, f in ((.12, .3, 4380), (.2, .24, 5610), (.27, .18, 3970), (.34, .13, 6240), (.42, .08, 5020)):
    glass += (tone(k - at, f) + .5 * tone(k - at, f * 1.47)) * drop(k, at, .018) * level
out('camera_break', crack + sparks + glass)

# Read back what the game will play: each must start on its attack, and be as short as it claims.
import aud
for name in ('wall_hit', 'casing', 'step_a', 'step_b', 'katana_draw', 'gun_draw', 'breaker', 'camera_break'):
    path = os.path.join(SFX, name + '.ogg')
    back = aud.Sound(path).data().mean(axis=1)
    spec = np.abs(np.fft.rfft(back)) ** 2
    f = np.fft.rfftfreq(len(back), 1 / RATE)
    print('SFX %-13s %.2f s  attack at %3.0f ms  centre %5.0f Hz  %5.1f KB' % (name, len(back) / RATE, 1000 * np.argmax(np.abs(back) > .3 * np.abs(back).max()) / RATE, (spec * f).sum() / spec.sum(), os.path.getsize(path) / 1024))
print('SFX_WORLD_READY')
