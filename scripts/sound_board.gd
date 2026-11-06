extends Node
## The guns, the hero's reloads and bullets going into people (tools/build_sfx.py), and the world
## answering: bullets in walls, furniture, steel and glass, enemies seeing him, brass landing, his feet, changing hands, a breaker and a camera going
## (tools/build_sfx_world.py). These sounds live in the world's time: slow motion drags down whatever is ringing and whatever starts during
## it, and when the death's slow motion ends, what is still ringing is cut.
const SHOTS := {
	"pistol":preload("res://assets/audio/sfx/pistol.ogg"),"smg":preload("res://assets/audio/sfx/smg.ogg"),
	"shotgun":preload("res://assets/audio/sfx/shotgun.ogg"),"rifle":preload("res://assets/audio/sfx/rifle.ogg"),
	"minigun":preload("res://assets/audio/sfx/minigun.ogg")}
const FLESH := preload("res://assets/audio/sfx/flesh.ogg")
## The blade makes one sound, decided as it lands: going into a body, or cutting only the air. Its
## recording of a body already has the air in it, so the two never play together.
const CUT := preload("res://assets/audio/sfx/sword_cut.ogg")
const WHOOSH := preload("res://assets/audio/sfx/whoosh.ogg")
const WHOOSH_VARY := .07   # no two swings alike
## A reload: the pull as it starts and the push right after, in two quick beats. Only the shotgun has
## its own; the rest share one cocking, deeper for the heavier guns.
const RELOAD_OUT := preload("res://assets/audio/sfx/reload_out.ogg")
const RELOAD_IN := preload("res://assets/audio/sfx/reload_in.ogg")
const PUMP_OUT := preload("res://assets/audio/sfx/shotgun_out.ogg")
const PUMP_IN := preload("res://assets/audio/sfx/shotgun_in.ogg")
const RELOAD_PITCH := {"smg":1.05,"rifle":.92,"minigun":.8}
const RELOAD_GAP := .12
const PUMP_GAP := .17
## The result screen. These are not in the world's time: no slow motion drags down a screen.
const SLAM := preload("res://assets/audio/sfx/slam.ogg")
const SLAM_HEAVY := preload("res://assets/audio/sfx/slam_heavy.ogg")
const TICK := preload("res://assets/audio/sfx/tally_tick.ogg")
const TICK_DB := -14.0
## Under the guns, and never so many that they crowd one out: a shotgun's seven pellets in a wall are one
## sound, and a minigun's brass lands as a patter, not every round.
const WALL := preload("res://assets/audio/sfx/wall_hit.ogg")
## What the bullet stopped in (Simulation.SURFACES); stone is the walls'.
const SURFACE_HITS := {"stone":WALL,"wood":preload("res://assets/audio/sfx/wood_hit.ogg"),
	"metal":preload("res://assets/audio/sfx/metal_hit.ogg"),"soft":preload("res://assets/audio/sfx/soft_hit.ogg")}
const GLASS := preload("res://assets/audio/sfx/glass_hit.ogg")
const GLASS_DB := -5.0
const ALERT := preload("res://assets/audio/sfx/alert.ogg")
const ALERT_DB := -12.0
const ALERT_GAP := .25      # a room turning on him at once is one sting
const WALL_VARY := .14
const WALL_DB := -7.0
const WALL_GAP := .06
const WALL_ENEMY_DB := -13.0
const CASING := preload("res://assets/audio/sfx/casing.ogg")
const CASING_VARY := .08
const CASING_DB := -15.0
const CASING_FALL := .62    # seconds in the air, about what combat_effects throws it
const CASING_GAP := .1
const CASING_MAX := 4
const STEPS := [preload("res://assets/audio/sfx/step_a.ogg"),preload("res://assets/audio/sfx/step_b.ogg")]
const STEP_DB := -17.0
const STEP_VARY := .06
const STRIDE := 1.45        # metres between his footfalls at a run
const KATANA_DRAW := preload("res://assets/audio/sfx/katana_draw.ogg")
const GUN_DRAW := preload("res://assets/audio/sfx/gun_draw.ogg")
const DRAW_DB := -6.0
const BREAKER := preload("res://assets/audio/sfx/breaker.ogg")
const CAMERA_BREAK := preload("res://assets/audio/sfx/camera_break.ogg")
const CAMERA_DB := -4.0
const VOICES := 24     # the minigun alone has six rounds ringing at once
const VARY := .03      # no two rounds quite alike
const VOLUME_DB := -4.0   # room for the music under the loudest shot
const ENEMY_DB := -6.0    # an enemy's gun: the same sound, under the hero's
var voices: Array[AudioStreamPlayer] = []
var screen_voices: Array[AudioStreamPlayer] = []
var next_screen := 0
var reload_began := 0.0
var rates: Array[float] = []
var next_voice := 0
var world := 1.0
var cutting: Tween
var reload_stage := 0   # 0 no reload, 1 pulled, 2 pushed
var wall_wait := 0.0
var glass_wait := 0.0
var alert_wait := 0.0
var casing_wait := 0.0
var casings: Array[float] = []   # brass in the air: seconds until each lands
var stride := STRIDE*.5
var foot := 0

func _ready() -> void:
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = VOLUME_DB
		add_child(voice)
		voices.append(voice)
		rates.append(1.0)
	for i in 6:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		screen_voices.append(voice)

func play(stream: AudioStream,rate := 1.0,vary := VARY,gain_db := 0.0) -> void:
	# A free voice, or the one that started longest ago.
	var i := next_voice
	for k in VOICES:
		var candidate := (next_voice+k)%VOICES
		if not voices[candidate].playing:
			i = candidate
			break
	next_voice = (i+1)%VOICES
	rates[i] = rate*randf_range(1.0-vary,1.0+vary)
	voices[i].stream = stream
	voices[i].volume_db = VOLUME_DB+gain_db
	voices[i].pitch_scale = rates[i]*world
	voices[i].play()

## The world's speed right now.
func set_time(scale: float) -> void:
	if cutting: return   # what is left of the slow motion stays dragged down while it goes
	world = scale
	for i in VOICES:
		if voices[i].playing: voices[i].pitch_scale = rates[i]*world

## What the simulation just did: anyone's shot, the blade landing, a bullet into anyone or a wall.
func hear(event: Dictionary) -> void:
	if event.type == "shot":
		play(SHOTS[event.weapon],1.0,VARY,0.0 if event.team == "player" else ENEMY_DB)
		if event.team == "player" and casing_wait <= 0.0 and casings.size() < CASING_MAX:
			casings.append(CASING_FALL*randf_range(.85,1.15))
			casing_wait = CASING_GAP
	elif event.type == "impact":
		if wall_wait > 0.0: return
		wall_wait = WALL_GAP
		play(SURFACE_HITS.get(event.get("surface","stone"),WALL),1.0,WALL_VARY,WALL_DB if event.get("team","player") == "player" else WALL_ENEMY_DB)
	elif event.type == "glass":
		if glass_wait > 0.0: return
		glass_wait = WALL_GAP
		play(GLASS,1.0,WALL_VARY,GLASS_DB)
	elif event.type == "switch": play(KATANA_DRAW if event.melee else GUN_DRAW,1.0,VARY,DRAW_DB)
	elif event.type == "blackout": play(BREAKER,1.0,0.0)
	elif event.type == "camera_down": play(CAMERA_BREAK,1.0,VARY,CAMERA_DB)
	elif event.type == "strike":
		if event.hit: play(CUT)
		else: play(WHOOSH,1.0,WHOOSH_VARY)
	elif event.type == "blood" and event.gore_allowed and event.weapon != "katana": play(FLESH)

## The world's clock for what comes after an event: brass landing, and his feet while he runs. A ghost
## makes no footfall.
func advance(dt: float,hero: Dictionary,walking: bool) -> void:
	wall_wait = maxf(0.0,wall_wait-dt)
	glass_wait = maxf(0.0,glass_wait-dt)
	alert_wait = maxf(0.0,alert_wait-dt)
	casing_wait = maxf(0.0,casing_wait-dt)
	for i in range(casings.size()-1,-1,-1):
		casings[i] -= dt
		if casings[i] <= 0.0:
			casings.remove_at(i)
			play(CASING,1.0,CASING_VARY,CASING_DB)
	var speed: float = (hero.velocity as Vector2).length()
	if not walking or not hero.alive or hero.phasing or speed < .1:
		stride = STRIDE*.5   # the first step comes quickly, not a whole stride after he sets off
		return
	stride += speed*dt
	if stride >= STRIDE:
		stride -= STRIDE
		foot = 1-foot
		play(STEPS[foot],1.0,STEP_VARY,STEP_DB)

## An enemy has just seen him (main.gd sees it turn).
func alert() -> void:
	if alert_wait > 0.0: return
	alert_wait = ALERT_GAP
	play(ALERT,1.0,VARY,ALERT_DB)

## A letter hits the glass.
func slam(heavy: bool) -> void:
	_screen(SLAM_HEAVY if heavy else SLAM,0.0,1.0)

## A digit turns; `progress` (0 to 1) raises it as the number climbs.
func tick(progress: float) -> void:
	_screen(TICK,TICK_DB,1.0+progress*.8)

func _screen(stream: AudioStream,gain_db: float,rate: float) -> void:
	var voice := screen_voices[next_screen]
	next_screen = (next_screen+1)%screen_voices.size()
	voice.stream = stream
	voice.volume_db = gain_db
	voice.pitch_scale = rate
	voice.play()

## Follows the reload on the sim's own clock, so the slow motion stretches it too. A reload dropped
## by a swap just never gets its push.
func follow_reload(hero: Dictionary,weapon: String) -> void:
	if hero.reload <= 0 or not hero.alive:
		reload_stage = 0
		return
	var pump := weapon == "shotgun"
	var rate: float = RELOAD_PITCH.get(weapon,1.0)
	if reload_stage == 0:
		reload_stage = 1
		reload_began = hero.reload
		play(PUMP_OUT if pump else RELOAD_OUT,rate,.01)
	if reload_stage == 1 and reload_began-hero.reload >= (PUMP_GAP if pump else RELOAD_GAP):
		reload_stage = 2
		play(PUMP_IN if pump else RELOAD_IN,rate,.01)

## The death's slow motion is over: what still rings goes, quickly and without rising back.
func cut(seconds: float) -> void:
	if cutting: return
	cutting = create_tween().set_parallel()
	for voice in voices:
		if voice.playing: cutting.tween_property(voice,"volume_db",-40.0,seconds)
	cutting.chain().tween_callback(silence)

func silence() -> void:
	if cutting: cutting.kill()
	cutting = null
	world = 1.0
	reload_stage = 0
	wall_wait = 0.0
	glass_wait = 0.0
	alert_wait = 0.0
	casing_wait = 0.0
	casings.clear()
	stride = STRIDE*.5
	for voice in voices:
		voice.stop()
		voice.volume_db = VOLUME_DB
	for voice in screen_voices: voice.stop()
