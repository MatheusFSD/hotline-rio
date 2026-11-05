# The guns, cut out of the recordings in ../sounds into one-shots for assets/audio/sfx, as mono Ogg.
# Every sound starts on its own attack, so it lands on the frame of the shot. The automatic guns'
# recordings are bursts: each file here is the burst's last round, the only one with its own tail.
# The cocking sounds are split in two: the pull, then the push right after it.
# The pistol's recording has a thin crack and only then, 75 ms in, its bang: the bang goes first, with
# the crack laid over its start, so the whole shot is there from the first sample.
# Use: blender -b --factory-startup --python tools/build_sfx.py
import os
import numpy as np
import aud

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.normpath(os.path.join(HERE, '..', '..', 'sounds'))
OUT = os.path.normpath(os.path.join(HERE, '..', 'assets', 'audio', 'sfx'))
PISTOL = 'freesound_community-perdition-1911-pistol-82365.mp3'
SMG = 'freesound_community-clean-machine-gun-burst-98224.mp3'
SHOTGUN = 'universfield-shotgun-blast-352038.mp3'
RIFLE = 'microsammy-ak-47-firing-8760.mp3'
MINIGUN = 'freesound_community-066496_heavy-machine-gun-50-caliber-28243.mp3'
FLESH = 'u_68csiaifb5-bulletimpact3-442719.mp3'
SWORD = 'dragon-studio-violent-sword-slice-393848.mp3'
COCK = 'freesound_community-pistol-cock-6014.mp3'
PUMP = 'freesound_community-realistic-shotgun-cocking-sound-38640.mp3'

# name: file, from, to (seconds), peak, tail fade (s), and how loud the attack must be to count.
# The peaks balance the guns against each other: the faster a gun, the more rounds ring at once.
CUTS = {
    'pistol':      (PISTOL,  .45, 1.35, .82, .25, .1),
    'smg':         (SMG,    1.345, 1.60, .62, .06, .5),
    'shotgun':     (SHOTGUN, .32, 1.75, .92, .40, .1),
    'rifle':       (RIFLE,  1.905, 2.12, .75, .06, .5),
    'minigun':     (MINIGUN, 1.78, 2.04, .46, .10, .5),
    'flesh':       (FLESH,   .09,  .75, .78, .20, .4),
    'sword_cut':   (SWORD,   .06, 1.15, .85, .30, .3),
    'reload_out':  (COCK,    .10,  .31, .55, .03, .15),
    'reload_in':   (COCK,    .31,  .72, .60, .08, .15),
    'shotgun_out': (PUMP,    .12,  .39, .65, .03, .15),
    'shotgun_in':  (PUMP,    .39,  .84, .70, .08, .15),
}

os.makedirs(OUT, exist_ok=True)
before = sum(os.path.getsize(os.path.join(SOURCE, f)) for f in os.listdir(SOURCE))
after = 0
PISTOL_BANG = .075
for name, (source, start, end, peak, fade, gate) in CUTS.items():
    sound = aud.Sound(os.path.join(SOURCE, source))
    rate = int(sound.specs[0])
    mono = sound.data().mean(axis=1)
    part = mono[int(start * rate):int(end * rate)]
    attack = int(np.argmax(np.abs(part) > gate * np.abs(part).max()))
    part = part[max(0, attack - int(.001 * rate)):].copy()   # a millisecond before the attack
    if name == 'pistol':
        split = int(PISTOL_BANG * rate)
        crack = part[:split] * np.linspace(1, 0, split) ** 2
        part = part[split:].copy()
        part[:split] = part[:split] * .8 + crack * .8
    part[:int(.001 * rate)] *= np.linspace(0, 1, int(.001 * rate))
    tail = min(int(fade * rate), len(part))
    part[-tail:] *= np.linspace(1, 0, tail) ** 2
    part *= peak / np.abs(part).max()
    path = os.path.join(OUT, name + '.ogg')
    data = np.ascontiguousarray(part[:, None].astype(np.float32))
    aud.Sound.buffer(data, rate).write(path, rate, aud.CHANNELS_MONO, aud.FORMAT_FLOAT32, aud.CONTAINER_OGG, aud.CODEC_VORBIS, 64000 if rate > 30000 else 40000, 4096)
    after += os.path.getsize(path)
    back = aud.Sound(path).data().mean(axis=1)   # read back, so what is reported is what the game plays
    first = int(np.argmax(np.abs(back) > .5 * np.abs(back).max()))
    win = int(.01 * rate)
    rms = np.array([np.sqrt(np.mean(back[i:i + win] ** 2)) for i in range(0, min(len(back), int(.25 * rate)) - win, win)])
    full = int(np.argmax(rms > rms.max() / 2)) * 10   # within 6 dB of its loudest
    print('SFX %-12s %.3f s  attack at %3.0f ms  full body at %3d ms  peak %.2f  %5.1f KB' % (name, len(back) / rate, 1000 * first / rate, full, np.abs(back).max(), os.path.getsize(path) / 1024))
print('SFX_READY sources %.0f KB, one-shots %.0f KB' % (before / 1024, after / 1024))
