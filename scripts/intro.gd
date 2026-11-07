class_name LapaIntro
extends CanvasLayer
## Opening police bulletin, "Alerta Rio", about the ghost vigilante of Lapa, watched by the ghost
## himself: Caio, at night in his own room (assets/room/room.glb), in the desk chair in front of the
## old tube TV he later uses as a computer. The newscast renders into a 4:3 SubViewport; a second one
## runs it through the CRT shader, and that picture is the TV's glass, the same `pc_screen` surface
## where MARÉ's page shows later. The camera starts from the room's own view, Caio's back to it,
## goes past his shoulder up to the glass; the screen's light is the room's. When the set goes off
## the dark glass reflects him (a camera mirrored through the glass): out of breath, his right hand
## still glowing cyan from the Avesso until it fades. The bulletin is a flash-forward: the card that
## follows, "DUAS HORAS ANTES", sends the player back to the bar, where it all happened (night 1).
## The running order, the words and who says them come from assets/intro/plantao.json: the people on the set talk in made-up syllables
## (tools/build_intro_audio.py) and the subtitles under the picture carry the words, through tr().
## Presentation only: finishing or skipping emits `finished`.
signal finished
const ActorVisual = preload("res://scripts/actor_visual.gd")
const CRT = preload("res://shaders/crt.gdshader")
const MOSAIC = preload("res://shaders/mosaic.gdshader")
const ResultScreen = preload("res://scripts/result_screen.gd")
const PLAN_PATH := "res://assets/intro/plantao.json"
static var PLAN: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PLAN_PATH))
static var DURATION: float = PLAN.duration
static var POWER_OFF: float = PLAN.power_off
## After the set goes dark: the first night is what the news was about, two hours earlier.
const EPILOGUE := "26 DE OUTUBRO, 21:50.\nDUAS HORAS ANTES."
## After the set goes off (plantao.json "after"): when the glow has left his hand, when the card comes up.
static var AFTER: Dictionary = PLAN.after
static var EPILOGUE_AT: float = POWER_OFF+float(PLAN.after.black)
const RESOLUTION := Vector2i(640,480)
## The room the set stands in, rendered at the window's size so the picture on the glass reads.
const ROOM_RESOLUTION := Vector2i(1280,800)
const ROOM_SCENE := "res://assets/room/room.glb"
## The room's own view (scripts/room.gd), where the opening starts; then past Caio's left shoulder
## (SHOULDER) to square in front of the glass, the glass filling SCREEN_FILL of the picture's
## height, SCREEN_CLOSE by the time it goes off.
const ROOM_VIEW := [Vector3(.9,2.15,2.6),Vector3(-.7,1.25,-3.4)]
const ROOM_FOV := 48.0
const SCREEN_FOV := 30.0
const SCREEN_FILL := .66
const SCREEN_CLOSE := .74
const SHOULDER := Vector3(-2.08,1.5,-2.35)
const WALK_IN := Vector2(3.0,4.1)   # seconds: from the room's view up to the glass
## Once it is off: nearer the glass with a wider lens, so the reflection holds him from his hands
## (where the glow is) to his head.
const MIRROR_DISTANCE := .32
const MIRROR_FOV := 46.0
## Caio in the desk chair, a little right of the glass so the camera can pass his head. The chair
## is the room's own, pulled up under him (CHAIR_TURN: how far round it is from the room's).
const CAIO_SEAT := Vector3(-1.65,0,-3.3)
const SEAT_BACK := .33   # the sitting clip's hips sit this far behind the feet
const CHAIR_TURN := 0.0
const SOUND := {"set":"res://assets/audio/intro/plantao.ogg","off":"res://assets/audio/intro/tv_off.ogg","room":"res://assets/audio/intro/room.ogg","after":"res://assets/audio/intro/after.ogg"}
const SOUND_DB := {"set":-3.0,"off":-5.0,"room":-15.0,"after":-4.0}
const GLASS = preload("res://shaders/tv_glass.gdshader")
const Campaign = preload("res://scripts/campaign.gd")
## The TV itself, which its own picture does not light: a tube throws its light into the room,
## not back on the cabinet round it (a separate visual layer, left out of the screen's light).
const SET_PARTS := ["Monitor","Hotspot_pc"]
const DRIFT := .15   # how far the sound may stray from the picture before it is put back
const STUDIO := Vector3(300,0,0)
const ANCHOR_START := Vector3(-3.4,0,-.8)
const ANCHOR_MARK := Vector3(-.4,0,.3)
const WITNESS_SPOT := Vector3(-16.6,.07,9.3)
const COP_SPOT := Vector3(-10.0,.07,9.6)
const SIREN := Vector3(-12.2,1.7,12.45)
## The other programmes' sets, each far from the rest in the newscast's world.
const OFICINA := Vector3(0,0,300)
const PRESS := Vector3(-300,0,0)
const IML := Vector3(0,0,-300)
const CASTELAR_MARK := Vector3(0,0,-.62)
const CADAVER_START := Vector3(-.05,0,-6.2)   # deep in the corridor; his lane runs between the pulled-out tray (x < -.59) and the gurney (x > .4)
const CADAVER_SPEED := .3   # the dead walk slowly
const CADAVER_STOP := -3.1  # where he stops, in full view, looking up at the camera
## Shot list: start time, shot, headline on the lower third ("" hides it).
static var SHOTS: Array = PLAN.shots
## What is said: start, end, who, the line. On the sound it is nonsense; the subtitle has the words.
static var CAPTIONS: Array = PLAN.lines
## Who is talking, as the subtitle names them.
static var SPEAKERS: Dictionary = PLAN.speakers
static var TICKER: String = PLAN.ticker

## The programme on the set: the opening (assets/intro/plantao.json) or another newscast in the same
## format (assets/news/*_tv.json). The statics above are the opening's, for the tests.
var plan: Dictionary
var shots: Array
var lines: Array
var speakers: Dictionary
var duration: float
var power_off: float
var after: Dictionary          # the reflection after the set goes off; only the opening has one
var reflects := false
var epilogue_text := ""
var epilogue_at := INF
var time := 0.0
var done := false
var lamps: Array
var current_shot := ""
var viewport: SubViewport
var camera: Camera3D
var environment: Environment
var crt: ShaderMaterial
var tube: SubViewport
var room: SubViewport
var room_camera: Camera3D
var screen_light: OmniLight3D
var set_glow: OmniLight3D   # the little the picture spills back on its own cabinet
var screen_material := ShaderMaterial.new()
var screen_node: MeshInstance3D
var screen_centre: Vector3
var screen_normal: Vector3   # out of the glass, into the room
var screen_right: Vector3    # across the glass, the picture's width
var screen_down: Vector3     # down the glass, the picture's height
var chair: Node3D
var caio: Dictionary
var caio_clip := ""
var hand_glow: MeshInstance3D
var hand_light: OmniLight3D
var raise: TwoBoneIK3D        # his right hand up in front of him once the set is off
var look: LookAtModifier3D    # …and his eyes on it
var night_fill: OmniLight3D   # the street through the window, all there is once the set is off
var mirror: SubViewport
var mirror_camera: Camera3D
var reflect_eye := Vector3.ZERO   # where the camera settles so his reflection is in the middle
var after_sound: AudioStreamPlayer
var frame_dt := 0.0
var set_sound: AudioStreamPlayer
var off_sound: AudioStreamPlayer
var room_sound: AudioStreamPlayer
var powered_off := false
var subtitle: PanelContainer
var speaker: Label
var anchor: Dictionary
var witness: Dictionary
var cop: Dictionary
var ghost
var gunman
var ghost_data: Dictionary
var gunman_data: Dictionary
var alarm: OmniLight3D
var sirens: Array[OmniLight3D] = []
var souza: Dictionary
var perito: Dictionary
var castelar: Dictionary
var cadaver: Dictionary
var flash: OmniLight3D       # the press's cameras
var moon: DirectionalLight3D  # the night over every set but the IML's corridor
var loki: Control            # MARÉ's page in LOKI, round the IML's footage
var loki_status: Label
var loki_message: Label
var loki_clock: Label
var loki_boot: Control
var heavy := SystemFont.new()
var mono := SystemFont.new()
var bug: Control
var live_dot: ColorRect
var lower: Control
var headline: Label
var ticker: Label
var ticker_strip: Control
var caption: Label
var plantao: Control
var plantao_band: ColorRect
var plantao_word: Label
var cctv: Control
var cctv_clock: Label
var rec: Label
var outro: Control
var mosaic: ColorRect
var epilogue: Control
var epilogue_line: Label

func _init(world_lamps: Array = [],program := PLAN_PATH) -> void:
	lamps = world_lamps
	layer = 20
	plan = PLAN if program == PLAN_PATH else JSON.parse_string(FileAccess.get_file_as_string(program))
	shots = plan.shots
	lines = plan.lines
	speakers = plan.speakers
	duration = float(plan.duration)
	power_off = float(plan.power_off)
	after = plan.get("after",{})
	reflects = after.has("calm")
	if after.has("black"):
		epilogue_text = EPILOGUE
		epilogue_at = power_off+float(after.black)

## Which sets a programme needs, by the shots it uses.
func has_shot(name: String) -> bool:
	return shots.any(func(s): return s[1] == name)

func _ready() -> void:
	heavy.font_names = PackedStringArray(["Arial Black","Impact","Arial"])
	heavy.font_weight = 900
	mono.font_names = PackedStringArray(["Courier New","Consolas","Monospace"])
	mono.font_weight = 700
	_build_world()
	_build_graphics()
	_build_tv()
	_build_sound()
	_update(0.0)

func _process(delta: float) -> void:
	advance(delta)
	# Keep the sound on the picture: a hitch in loading must not leave the voices behind.
	if set_sound.playing and absf(set_sound.get_playback_position()-time) > DRIFT: set_sound.seek(time)

func advance(dt: float) -> void:
	if done: return
	time += dt
	if time >= duration:
		_finish()
		return
	_update(dt)

func skip() -> void:
	# First press turns the set off; a second one leaves immediately.
	if done: return
	if time < power_off: time = power_off
	else: _finish()

func _input(event: InputEvent) -> void:
	if done: return
	var key: bool = event is InputEventKey and event.pressed and not event.echo
	var click: bool = event is InputEventMouseButton and event.pressed
	if key or click:
		skip()
		get_viewport().set_input_as_handled()

func _finish() -> void:
	done = true
	finished.emit()
	queue_free()

func shot_at(t: float) -> Array:
	var current: Array = shots[0]
	for entry in shots:
		if t >= entry[0]: current = entry
	return current

func line_at(t: float) -> Array:
	## The line being said at `t`: start, end, who, words; empty between lines.
	for entry in lines:
		if t >= entry[0] and t < entry[1]: return entry
	return []

func caption_at(t: float) -> String:
	var entry := line_at(t)
	return entry[3] if entry else ""

# ---------------------------------------------------------------- 3D world
func _build_world() -> void:
	viewport = SubViewport.new()
	viewport.size = RESOLUTION
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var world := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("0b0f18")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("aab4cc")
	environment.ambient_light_energy = .55
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.adjustment_enabled = true
	world.environment = environment
	viewport.add_child(world)
	camera = Camera3D.new()
	camera.near = .05
	camera.far = 150
	viewport.add_child(camera)
	camera.current = true
	var studio := (load("res://assets/intro/studio.glb") as PackedScene).instantiate() as Node3D
	viewport.add_child(studio)
	studio.position = STUDIO
	_crisp(studio)
	moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55,-35,0)
	moon.light_color = Color("c9d4f0")
	moon.light_energy = .55
	viewport.add_child(moon)
	# Studio: warm key, blue fill, red rim, and a red alarm that pulses during the plantão.
	_light(STUDIO+Vector3(.6,2.6,2.6),Color("fff1d8"),2.2,7.0)
	_light(STUDIO+Vector3(-3.5,2.2,2.0),Color("6f8cff"),1.2,6.0)
	_light(STUDIO+Vector3(.4,2.8,-2.2),Color("ff3030"),1.6,5.0)
	alarm = _light(STUDIO+Vector3(0,3.4,1.0),Color("ff1a1a"),0.0,9.0)
	anchor = _person("res://assets/intro/anchor.glb",STUDIO+ANCHOR_START)
	_add_tie(anchor)
	if has_shot("cctv"): _build_lapa()
	if has_shot("oficina"): _build_oficina()
	if has_shot("press"): _build_press()
	if has_shot("loki"): _build_iml()

func _set_piece(path: String,at: Vector3) -> Node3D:
	var set_piece := (load(path) as PackedScene).instantiate() as Node3D
	viewport.add_child(set_piece)
	set_piece.position = at
	_crisp(set_piece)
	return set_piece

func _build_lapa() -> void:
	## The opening: the bar as the nights show it, cut at 1.4 m to be seen from above, closed again
	## for the cameras of the news (bar_shell.glb); the street; the witness, the lieutenant, the CCTV.
	for path in ["res://assets/environment/lapa.glb","res://assets/intro/street.glb","res://assets/intro/bar_shell.glb"]: _set_piece(path,Vector3.ZERO)
	for lamp in lamps: _light(lamp[0],Color(lamp[1]),lamp[2],lamp[3])
	for color in ["ff2020","2a5cff"]: sirens.append(_light(SIREN,Color(color),0.0,7.5))
	witness = _person("res://assets/intro/witness.glb",WITNESS_SPOT)
	cop = _person("res://assets/intro/cop.glb",COP_SPOT)
	_face(witness,Vector3(-15.5,1.5,11.5))
	_face(cop,Vector3(-9.0,1.5,12.1))
	_play(witness,"Idle_Talking_Loop")
	_play(cop,"Idle_Loop")
	# Security-camera scene: the spectre crosses the counter while a gunman stands guard.
	ghost = ActorVisual.new()
	viewport.add_child(ghost)
	ghost.setup("res://assets/characters/hero.glb")
	# Brighter than in play so the spectre survives the washed-out security footage.
	ghost.ghost_material.emission = Color("3a8cff")
	ghost.ghost_material.emission_energy_multiplier = 2.4
	gunman = ActorVisual.new()
	viewport.add_child(gunman)
	gunman.setup("res://assets/characters/enemy_a.glb")
	ghost_data = {"p":Vector2(-8.3,-2.6),"angle":PI,"alive":true,"moving":true,"velocity":Vector2(-.78,0),"recoil":0.0,"reload":0.0,"phasing":true,"mana":100.0}
	gunman_data = {"p":Vector2(-6.9,-5.1),"angle":atan2(2.5,-2.4),"alive":true,"moving":false,"velocity":Vector2.ZERO,"recoil":0.0,"reload":0.0}

func _build_oficina() -> void:
	## Night outside the tram workshop: Souza at the tape, the forensic man kneeling by the sheet.
	_set_piece("res://assets/news/virada_1/oficina.glb",OFICINA)
	for color in ["ff2020","2a5cff"]: sirens.append(_light(OFICINA+Vector3(-6.2,1.8,4.6),Color(color),0.0,9.0))
	_light(OFICINA+Vector3(4.1,3.9,3.9),Color("ffcf73"),1.6,9.0)    # the street lamp
	_light(OFICINA+Vector3(0,3.0,1.0),Color("8fa4ff"),.6,9.0)
	souza = _person("res://assets/intro/cop.glb",OFICINA+Vector3(-.6,0,1.6))
	_face(souza,OFICINA+Vector3(3.0,1.5,6.5))
	_play(souza,"Idle_Talking_Loop")
	perito = _person("res://assets/news/virada_1/perito.glb",OFICINA+Vector3(-2.3,0,-1.1))
	_face(perito,OFICINA+Vector3(-2.6,0,-1.9))
	_play(perito,"Fixing_Kneeling")

func _build_press() -> void:
	## Castelar's press conference: the slogan wall, the podium, the press's flashes. He is only ever
	## framed from the waist up (the floor would show he has no shadow).
	_set_piece("res://assets/news/virada_1/press.glb",PRESS)
	_light(PRESS+Vector3(1.2,2.6,2.2),Color("fff1d8"),2.0,7.0)
	_light(PRESS+Vector3(-1.8,2.0,1.6),Color("9fb4ff"),.9,6.0)
	flash = _light(PRESS+Vector3(.4,1.6,2.0),Color.WHITE,0.0,6.0)
	castelar = _person("res://assets/news/virada_1/castelar.glb",PRESS+CASTELAR_MARK)
	castelar.node.rotation.y = 0.0
	_play(castelar,"Idle_Talking_Loop")

func _build_iml() -> void:
	## The IML corridor on the security camera MARÉ sends: the body walking out of the drawer. The
	## ceiling lights cast shadows; he casts none.
	_set_piece("res://assets/news/virada_1/iml.glb",IML)
	for z in [-1.0,-3.6,-6.2,-8.8]:
		var tube_light := SpotLight3D.new()
		tube_light.position = IML+Vector3(0,2.9,z)
		tube_light.rotation_degrees = Vector3(-90,0,0)
		tube_light.spot_angle = 75
		tube_light.spot_range = 5.0
		tube_light.light_energy = 1.5
		tube_light.light_color = Color("e8f4ff")
		tube_light.shadow_enabled = true
		viewport.add_child(tube_light)
	cadaver = _person("res://assets/news/virada_1/cadaver.glb",IML+CADAVER_START)
	for mesh in cadaver.node.find_children("*","MeshInstance3D",true,false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_face(cadaver,IML+Vector3(CADAVER_START.x,0,1.0))
	_play(cadaver,"Zombie_Walk_Fwd_Loop")

func _light(position: Vector3,color: Color,energy: float,reach: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = .8
	viewport.add_child(light)
	return light

func _crisp(root: Node) -> void:
	for node in root.find_children("*","MeshInstance3D",true,false):
		for surface in node.mesh.get_surface_count():
			var mat := node.mesh.surface_get_material(surface) as BaseMaterial3D
			if mat:
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				mat.roughness = 1.0
				mat.metallic = 0.0

func _person(path: String,position: Vector3,stage: Node = null) -> Dictionary:
	var model := (load(path) as PackedScene).instantiate() as Node3D
	(stage if stage else viewport).add_child(model)
	model.position = position
	_crisp(model)
	var player: AnimationPlayer = model.find_children("*","AnimationPlayer",true,false)[0]
	return {"node":model,"player":player,"skeleton":model.find_children("*","Skeleton3D",true,false)[0],"clip":""}

static func clip_name(person: Dictionary,clip: String) -> StringName:
	# Godot's importer turns "Walk_Loop" into a looping "Walk".
	for name in [clip,clip.trim_suffix("_Loop")]:
		if person.player.has_animation(name): return name
	return &""

func _play(person: Dictionary,clip: String,blend := .25) -> void:
	if person.clip == clip: return
	person.clip = clip
	var name := clip_name(person,clip)
	if name != &"": person.player.play(name,blend)

func _face(person: Dictionary,target: Vector3) -> void:
	var direction: Vector3 = target-person.node.position
	person.node.rotation.y = atan2(direction.x,direction.z)

func _add_tie(person: Dictionary) -> void:
	# Red tie hung from the chest bone, calibrated on the rest pose like the pistol.
	var skeleton: Skeleton3D = person.skeleton
	var socket := BoneAttachment3D.new()
	socket.bone_name = "spine_03"
	skeleton.add_child(socket)
	socket.on_skeleton_update()
	var top := skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("neck_01")).origin
	var low := skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("spine_02")).origin
	var front: Vector3 = person.node.global_basis.z.normalized()
	var up := (top-low).normalized()
	var tie := Node3D.new()
	socket.add_child(tie)
	tie.global_basis = Basis(up.cross(front).normalized(),up,front)
	tie.global_position = top+front*.13-up*.06
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("a3161a")
	mat.roughness = 1.0
	# Knot, then a blade leaning forward over the chest.
	for entry in [[Vector3(.065,.055,.03),Vector3.ZERO,0.0],[Vector3(.085,.36,.018),Vector3(0,-.2,.01),-.16]]:
		var piece := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = entry[0]
		piece.mesh = mesh
		piece.position = entry[1]
		piece.rotation.x = entry[2]
		piece.material_override = mat
		tie.add_child(piece)

# ---------------------------------------------------------------- shots
func _update(dt: float) -> void:
	frame_dt = dt
	var entry := shot_at(time)
	var local: float = time-entry[0]
	if entry[1] != current_shot:
		current_shot = entry[1]
		_enter_shot(current_shot)
	_frame_shot(current_shot,local,dt)
	_update_graphics(entry,local)
	_update_power(local)
	var flashing := fmod(time*2.5,1.0) < .5
	if sirens:
		sirens[0].light_energy = 2.6 if flashing else 0.0
		sirens[1].light_energy = 0.0 if flashing else 2.6

func _enter_shot(name: String) -> void:
	var cctv_look := name in ["cctv","loki"]
	# Dim, contrasty security footage in which the glowing spectre stands out.
	environment.adjustment_saturation = .6 if cctv_look else 1.0
	environment.adjustment_contrast = 1.45 if cctv_look else 1.0
	environment.adjustment_brightness = .72 if cctv_look else 1.0
	if name == "cctv":
		ghost_data.p = Vector2(-8.3,-2.6)
		ghost.clear_effects()
	# Indoors at the IML only the ceiling's tubes light the corridor, and they cast shadows: the
	# gurney has one on the white floor, the man walking past it has none.
	var corridor := name == "loki"
	environment.ambient_light_energy = .1 if corridor else .55
	moon.visible = not corridor
	if corridor: cadaver.node.position = IML+CADAVER_START

func _handheld(t: float,amount := 1.0) -> Vector3:
	return Vector3(sin(t*1.7)+sin(t*3.1)*.4,sin(t*2.3)*.7+sin(t*4.7)*.2,0)*.012*amount

func _aim(from: Vector3,to: Vector3,fov: float) -> void:
	camera.look_at_from_position(from,to)
	camera.fov = fov

func _frame_shot(name: String,t: float,dt: float) -> void:
	var mark := STUDIO+ANCHOR_MARK
	match name:
		"plantao":
			var k := smoothstep(0.0,3.2,t)
			_aim((STUDIO+Vector3(4.4,2.5,7.8)).lerp(STUDIO+Vector3(2.9,2.0,6.4),k),STUDIO+Vector3(-.4,1.3,-1.4),52)
			var walk := clampf((t-.3)/2.6,0,1)
			anchor.node.position = (STUDIO+ANCHOR_START).lerp(mark,walk)
			if walk < 1:
				_play(anchor,"Walk_Formal_Loop")
				_face(anchor,anchor.node.position+(mark-(STUDIO+ANCHOR_START)))
			else:
				_play(anchor,"Idle_Talking_Loop")
				_face(anchor,camera.global_position)
			alarm.light_energy = 3.0 if sin(t*12.0) > 0 else 0.4
		"anchor_medium":
			alarm.light_energy = 0
			_settle_anchor("Idle_Talking_Loop")
			# Hurried control room: a snap zoom on "minha gente".
			var zoom := smoothstep(2.5,2.75,t)
			_aim(STUDIO+Vector3(-.15,1.5,3.3)+_handheld(t),mark+Vector3(0,1.32,0),lerpf(40,29,zoom))
		"anchor_close":
			_settle_anchor("Idle_Talking_Loop")
			_aim(STUDIO+Vector3(-.3,1.6,2.2)+_handheld(t,1.3),mark+Vector3(0,1.5,0),lerpf(32,25,t/3.0))
		"cctv":
			# Ceiling camera above the stools: the spectre crosses the counter, then the wall.
			_aim(Vector3(-7.7,2.2,-.2),Vector3(-10.8,1.15,-2.6),52)
			ghost_data.p += ghost_data.velocity*dt
			ghost.sync(ghost_data,dt,false)
			gunman.sync(gunman_data,dt,false)
		"witness":
			_aim(Vector3(-15.5,1.47,11.5)+_handheld(t,1.6),WITNESS_SPOT+Vector3(0,1.38,0),36)
		"cop":
			_play(cop,"Idle_Talking_Loop")
			_aim(Vector3(-9.0,1.52,12.1)+_handheld(t,1.4),COP_SPOT+Vector3(0,1.45,0),36)
		"anchor_point":
			_settle_anchor("Spell_Simple_Shoot" if t > 2.6 and t < 4.4 else "Idle_Talking_Loop")
			var snap := smoothstep(2.6,2.8,t)
			var shake := _handheld(t*3.0,4.0*snap*(1.0-smoothstep(3.2,4.2,t)))
			_aim(STUDIO+Vector3(-.3,1.58,2.4)+_handheld(t,1.2)+shake,mark+Vector3(0,1.45,0),lerpf(34,21,snap))
		"outro":
			_settle_anchor("Idle_Loop")
			_aim(STUDIO+Vector3(3.4,2.2,6.6),STUDIO+Vector3(-.4,1.3,-1.4),50)
		"oficina":
			# The station's camera at the tape: across the cones to the sheet, Souza talking.
			var k := smoothstep(0.0,6.0,t)
			_aim((OFICINA+Vector3(-.4,1.55,6.6)).lerp(OFICINA+Vector3(-1.4,1.45,5.2),k)+_handheld(t,1.5),
				(OFICINA+Vector3(-.9,1.0,0)).lerp(OFICINA+Vector3(-2.4,.45,-1.7),k),lerpf(44,36,k))
		"press":
			_play(castelar,"Idle_Talking_Loop")
			_aim(PRESS+Vector3(.3,1.52,1.6)+_handheld(t,.6),PRESS+CASTELAR_MARK+Vector3(0,1.36,0),30)
			_press_flashes(t)
		"press_close":
			# ORDEM NA CASA: he points at the cameras; a slow push on his face.
			_play(castelar,"Spell_Simple_Shoot" if t > .5 and t < 2.2 else "Idle_Talking_Loop")
			_aim(PRESS+Vector3(-.12,1.56,.85)+_handheld(t,.4),PRESS+CASTELAR_MARK+Vector3(0,1.48,0),lerpf(30,22,t/4.0))
			_press_flashes(t+.37)
		"loki":
			# IML, camera 2: high in the corner, the corridor to the doors, the body coming.
			_aim(IML+Vector3(1.25,2.75,.3),IML+Vector3(-.35,.8,-6.0),62)
			# He walks out of the drawer toward the camera, then stops under it and stands there.
			var stop := IML.z+CADAVER_STOP
			if t > 1.2 and cadaver.node.position.z < stop: cadaver.node.position.z = minf(cadaver.node.position.z+CADAVER_SPEED*dt,stop)
			_play(cadaver,"Zombie_Walk_Fwd_Loop" if cadaver.node.position.z < stop-.01 else "Zombie_Idle_Loop")

func _press_flashes(t: float) -> void:
	## The press pit: a camera goes off every so often, from a different place.
	var beat := fmod(t*2.3,1.0)
	var burst := 1.0-smoothstep(0.0,.07,beat) if hash(int(t*2.3))%3 != 0 else 0.0
	flash.light_energy = 6.0*burst
	flash.position = PRESS+Vector3(-1.2+fmod(hash(int(t*2.3))*.37,2.4),1.5,2.2)

func _settle_anchor(clip: String) -> void:
	anchor.node.position = STUDIO+ANCHOR_MARK
	anchor.node.rotation.y = .06
	_play(anchor,clip)

func _update_power(local: float) -> void:
	var open_x := 1.0
	var open_y := 1.0
	var flash := 0.0
	var snow := 0.0
	if time < 1.0:
		open_x = smoothstep(0.0,.22,time)
		open_y = lerpf(.006,1.0,smoothstep(.22,.62,time))
		flash = 1.0-smoothstep(.2,.8,time)
		snow = .5*(1.0-time)
	elif local < .16:
		snow = .3*(1.0-local/.16)  # every cut rolls a little snow
	if current_shot == "outro": snow = maxf(snow,.12*local)
	if time >= power_off:
		var k := time-power_off
		flash = smoothstep(0.0,.25,k)
		open_y = lerpf(1.0,.006,smoothstep(0.0,.3,k))
		open_x = lerpf(1.0,0.0,smoothstep(.3,.6,k))
		snow = .3
	crt.set_shader_parameter("open_x",open_x)
	crt.set_shader_parameter("open_y",open_y)
	crt.set_shader_parameter("flash",flash)
	crt.set_shader_parameter("static_amount",snow)
	var lit := open_x*open_y
	screen_light.light_energy = (1.1+flash*1.6)*lit*(.93+.07*sin(time*41.0)) if lit > .01 else 0.0
	set_glow.light_energy = screen_light.light_energy*.22
	set_glow.light_color = screen_light.light_color
	if time >= power_off and not powered_off: _power_down()
	_frame_caio(local)
	_frame_room()
	_frame_mirror()
	epilogue.visible = time >= epilogue_at
	if epilogue.visible: epilogue_line.visible_ratio = clampf((time-epilogue_at-.3)*28.0/epilogue_text.length(),0,1)

# ---------------------------------------------------------------- on-screen graphics
func _text(value: String,size: int,color: Color,font: Font,position := Vector2.ZERO) -> Label:
	var label := Label.new()
	label.text = value
	label.position = position
	label.add_theme_font_override("font",font)
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	return label

func _box(color: Color,rect: Rect2,parent: Node) -> ColorRect:
	var box := ColorRect.new()
	box.color = color
	box.position = rect.position
	box.size = rect.size
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	return box

func _layer(parent: Node) -> Control:
	var control := Control.new()
	control.size = Vector2(RESOLUTION)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(control)
	return control

func _build_graphics() -> void:
	var canvas := CanvasLayer.new()
	viewport.add_child(canvas)
	var root := _layer(canvas)
	mosaic = _box(Color.WHITE,Rect2(0,0,62,74),root)
	var mosaic_material := ShaderMaterial.new()
	mosaic_material.shader = MOSAIC
	mosaic.material = mosaic_material
	cctv = _layer(root)
	var tint := _box(Color(.72,1.0,.78),Rect2(Vector2.ZERO,Vector2(RESOLUTION)),cctv)
	var multiply := CanvasItemMaterial.new()
	multiply.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	tint.material = multiply
	cctv.add_child(_text("CAM 03  BAR DO ARCO",16,Color.WHITE,mono,Vector2(18,62)))
	rec = _text("● REC",16,Color("ff3030"),mono,Vector2(540,62))
	cctv.add_child(rec)
	cctv_clock = _text("",16,Color.WHITE,mono,Vector2(18,326))
	cctv.add_child(cctv_clock)
	plantao = _layer(root)
	_box(Color(0,0,0,.55),Rect2(0,0,640,480),plantao)
	_box(Color("111111"),Rect2(0,162,640,156),plantao)
	plantao_band = _box(Color("c4161c"),Rect2(0,172,640,136),plantao)
	plantao_word = _text("PLANTÃO",76,Color("ffd21a"),heavy)
	plantao_word.size = Vector2(640,136)
	plantao_word.position = Vector2(0,172)
	plantao_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plantao_word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plantao_word.add_theme_constant_override("outline_size",10)
	plantao_word.add_theme_color_override("font_outline_color",Color.BLACK)
	plantao.add_child(plantao_word)
	outro = _layer(root)
	_box(Color("070707"),Rect2(0,0,640,480),outro)
	var back := _text("VOLTAMOS A QUALQUER MOMENTO",30,Color("ffd21a"),heavy)
	back.size = Vector2(640,480)
	back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	outro.add_child(back)
	# Station bug and the live tag.
	bug = _layer(root)
	_box(Color("c4161c"),Rect2(16,14,156,32),bug)
	bug.add_child(_text("ALERTA RIO",20,Color("ffd21a"),heavy,Vector2(24,15)))
	_box(Color("111111"),Rect2(16,46,156,15),bug)
	bug.add_child(_text(plan.get("bug","COM JAIRO TROVÃO"),10,Color.WHITE,heavy,Vector2(24,46)))
	_box(Color("c4161c"),Rect2(526,16,98,22),bug)
	live_dot = _box(Color.WHITE,Rect2(533,23,8,8),bug)
	bug.add_child(_text("AO VIVO",13,Color.WHITE,heavy,Vector2(546,18)))
	bug.add_child(_text(plan.get("clock","23:52"),14,Color.WHITE,heavy,Vector2(570,40)))
	# Lower third and the news ticker.
	lower = _layer(root)
	_box(Color("c4161c"),Rect2(22,356,104,24),lower)
	lower.add_child(_text("URGENTE",14,Color.WHITE,heavy,Vector2(32,358)))
	_box(Color("ffd21a"),Rect2(22,380,596,44),lower)
	headline = _text("",21,Color("111111"),heavy,Vector2(32,387))
	lower.add_child(headline)
	ticker_strip = _layer(root)
	_box(Color("0d1d3f"),Rect2(0,436,640,26),ticker_strip)
	var clip := Control.new()
	clip.position = Vector2(104,436)
	clip.size = Vector2(536,26)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ticker_strip.add_child(clip)
	ticker = _text(tr(plan.ticker)+tr(plan.ticker),14,Color.WHITE,heavy,Vector2(0,4))
	clip.add_child(ticker)
	_box(Color("c4161c"),Rect2(0,436,104,26),ticker_strip)
	ticker_strip.add_child(_text("PLANTÃO",13,Color("ffd21a"),heavy,Vector2(14,441)))
	if has_shot("loki"): _build_loki(root)

func _build_loki(root: Control) -> void:
	## The computer coming on by itself: LOKI, MARÉ's page, and in it the IML's camera. The 3D
	## footage shows through the window left in the page.
	loki = _layer(root)
	var page := Color("0b0e14")
	_box(page,Rect2(0,0,640,58),loki)
	_box(page,Rect2(0,384,640,96),loki)
	_box(page,Rect2(0,58,22,326),loki)
	_box(page,Rect2(618,58,22,326),loki)
	_box(Color("26313f"),Rect2(0,0,640,24),loki)
	loki.add_child(_text("LOKI  ·  conexão anônima  ·  14.4 kbps",12,Color("7dffa0"),mono,Vector2(10,5)))
	_box(Color("151b25"),Rect2(10,30,620,20),loki)
	loki.add_child(_text("loki://mare7xq3vkd2pjw.onion/iml/cam2",12,Color("9fb0c4"),mono,Vector2(16,33)))
	for edge in [Rect2(20,56,600,2),Rect2(20,384,600,2),Rect2(20,56,2,330),Rect2(618,56,2,330)]: _box(Color("3c6e52"),edge,loki)
	loki.add_child(_text("IML  ·  CAM 2",14,Color.WHITE,mono,Vector2(32,64)))
	loki_clock = _text("",14,Color.WHITE,mono,Vector2(32,356))
	loki.add_child(loki_clock)
	loki.add_child(_text("MARÉ escreve:",13,Color("7dffa0"),mono,Vector2(24,394)))
	loki_message = _text("",15,Color("e6efe8"),mono,Vector2(24,414))
	loki_message.size = Vector2(592,60)
	loki_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loki_message.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	loki.add_child(loki_message)
	loki_boot = _layer(loki)
	_box(Color("05070a"),Rect2(0,0,640,480),loki_boot)
	var name := _text("LOKI",56,Color("7dffa0"),mono)
	name.size = Vector2(640,400)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loki_boot.add_child(name)
	loki_status = _text("",14,Color("7dffa0"),mono,Vector2(0,280))
	loki_status.size = Vector2(640,20)
	loki_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loki_boot.add_child(loki_status)

func _update_graphics(entry: Array,local: float) -> void:
	var name: String = entry[1]
	plantao.visible = name == "plantao" and time > .9
	plantao_band.color = Color("c4161c") if fmod(time*4.0,1.0) < .5 else Color("7d0b10")
	plantao_word.visible = fmod(time*3.0,1.0) < .72
	outro.visible = name == "outro"
	cctv.visible = name == "cctv"
	rec.visible = fmod(time*2.0,1.0) < .6
	cctv_clock.text = "26/10/2026  21:52:%02d" % (12+int(local))
	bug.visible = name not in ["outro","loki"]
	live_dot.visible = fmod(time*1.5,1.0) < .6
	lower.visible = entry[2] != "" and local > .35
	headline.text = entry[2]
	ticker_strip.visible = name not in ["plantao","outro","loki"]
	if loki:
		loki.visible = name == "loki"
		loki_boot.visible = loki.visible and local < 1.3
		loki_status.text = tr("conectando…") if local < .8 else tr("conexão segura")
		loki_clock.text = "01/11/2026  03:12:%02d" % (4+int(local))
		# Her last message stays on the page, typed out at her speed, until the next one.
		var mare: Array = []
		for said in lines.filter(func(l): return l[2] == "mare" and l[0] <= time): mare = said
		var words: String = tr(mare[3]) if mare else ""
		loki_message.text = words.left(int(clampf((time-(mare[0] if mare else 0.0))*30.0,0,words.length())))
	ticker.position.x = -fposmod(time*72.0,ticker.get_minimum_size().x/2.0)
	var said := line_at(time)
	caption.text = tr(said[3]) if said else ""
	speaker.text = tr(speakers.get(said[2],"")) if said else ""
	subtitle.visible = caption.text != ""
	mosaic.visible = name == "witness"
	if mosaic.visible:
		var skeleton: Skeleton3D = witness.skeleton
		var head := skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin
		var center := camera.unproject_position(head+Vector3(0,.09,0))
		mosaic.position = center-mosaic.size/2
	var glow := {"plantao":Color("ff2a2a"),"cctv":Color("7dffa0"),"witness":Color("5a7dff"),"cop":Color("ff4a4a"),"outro":Color("ffd21a"),
		"oficina":Color("ff5a5a"),"press":Color("fff1d8"),"press_close":Color("fff1d8"),"loki":Color("7dffa0")}
	# The picture lights the room in its colour, washed toward white the way a tube spills it.
	var spill: Color = glow.get(name,Color("9fc4ff")).lerp(Color("dfe6ff"),.45)
	if time < 1.0: spill = Color("dfe6ff")   # snow while it warms up
	if name == "press" or name == "press_close": spill = spill.lerp(Color.WHITE,clampf(flash.light_energy/6.0,0,1))
	screen_light.light_color = screen_light.light_color.lerp(spill,.2)

# ---------------------------------------------------------------- the TV set
func _build_tv() -> void:
	# The tube: the newscast through the CRT shader, drawn into the texture the glass wears.
	tube = SubViewport.new()
	tube.size = RESOLUTION
	tube.disable_3d = true
	tube.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(tube)
	var picture := TextureRect.new()
	picture.texture = viewport.get_texture()
	picture.size = Vector2(RESOLUTION)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	crt = ShaderMaterial.new()
	crt.shader = CRT
	picture.material = crt
	tube.add_child(picture)
	# The room around the set.
	room = SubViewport.new()
	room.size = ROOM_RESOLUTION
	room.own_world_3d = true
	room.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(room)
	var world := WorldEnvironment.new()
	var dark := Environment.new()
	dark.background_mode = Environment.BG_COLOR
	dark.background_color = Color("040508")
	dark.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	dark.ambient_light_color = Color("26304a")
	dark.ambient_light_energy = .35
	dark.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = dark
	room.add_child(world)
	var set_piece := (load(ROOM_SCENE) as PackedScene).instantiate() as Node3D
	room.add_child(set_piece)
	_crisp(set_piece)
	_dress_room(set_piece)
	screen_material.shader = GLASS
	screen_material.set_shader_parameter("picture",tube.get_texture())
	screen_node.set_surface_override_material(_screen_surface(screen_node),screen_material)
	# The reflection: a camera mirrored through the glass, sharing the room's world, rendered only
	# once the set is off.
	mirror = SubViewport.new()
	mirror.size = Vector2i(320,240)
	mirror.render_target_update_mode = SubViewport.UPDATE_DISABLED
	room.add_child(mirror)
	mirror_camera = Camera3D.new()
	mirror.add_child(mirror_camera)
	mirror_camera.current = true
	screen_material.set_shader_parameter("mirror",mirror.get_texture())
	# Moonlight through the window, and the light the picture throws on the room.
	var moon := OmniLight3D.new()
	moon.position = Vector3(1.5,1.9,-4.2)
	moon.light_color = Color("6f8cff")
	moon.light_energy = .9
	moon.omni_range = 5.5
	moon.omni_attenuation = .9
	room.add_child(moon)
	screen_light = OmniLight3D.new()
	screen_light.position = screen_centre+screen_normal*.45
	screen_light.omni_range = 4.5
	screen_light.omni_attenuation = 1.6
	screen_light.light_color = Color("9fc4ff")
	screen_light.light_cull_mask = 1
	room.add_child(screen_light)
	set_glow = OmniLight3D.new()
	set_glow.position = screen_centre+screen_normal*1.0
	set_glow.omni_range = 2.0
	set_glow.light_cull_mask = 2
	room.add_child(set_glow)
	_seat_caio()
	night_fill = OmniLight3D.new()
	night_fill.position = screen_centre+screen_normal*.5+Vector3(.6,.5,0)
	night_fill.light_color = Color("8fa8e8")
	night_fill.omni_range = 2.5
	night_fill.light_energy = 0.0
	night_fill.light_cull_mask = 1
	room.add_child(night_fill)
	room_camera = Camera3D.new()
	room_camera.fov = ROOM_FOV
	room_camera.near = .02
	room.add_child(room_camera)
	room_camera.current = true
	_frame_room()
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var view := TextureRect.new()
	view.texture = room.get_texture()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(view)
	# Subtitles: who speaks, then what they say, under the set.
	subtitle = PanelContainer.new()
	var shade := StyleBoxFlat.new()
	shade.bg_color = Color(0,0,0,.72)
	shade.set_content_margin_all(10)
	shade.content_margin_left = 18
	shade.content_margin_right = 18
	subtitle.add_theme_stylebox_override("panel",shade)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	subtitle.grow_horizontal = Control.GROW_DIRECTION_BOTH
	subtitle.grow_vertical = Control.GROW_DIRECTION_BEGIN
	subtitle.offset_bottom = -54
	root.add_child(subtitle)
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation",2)
	subtitle.add_child(lines)
	speaker = _subtitle_label(15,Color("ffd21a"))
	lines.add_child(speaker)
	caption = _subtitle_label(24,Color("f4efe1"))
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.custom_minimum_size = Vector2(880,0)
	lines.add_child(caption)
	subtitle.hide()
	var hint := _text("ENTER OU CLIQUE — PULAR",14,Color("8a8478"),heavy,Vector2(1010,766))
	root.add_child(hint)
	# Once the set is off: the date, typed out in the HUD's terminal font, before the first night.
	epilogue = Control.new()
	epilogue.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	epilogue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(epilogue)
	_box(Color("07050a"),Rect2(0,0,1280,800),epilogue)
	epilogue_line = _text(epilogue_text,40,Color("f4efe1"),ResultScreen.DIGIT_FONT,Vector2(0,330))
	epilogue_line.size = Vector2(1280,140)
	epilogue_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	epilogue.add_child(epilogue_line)
	epilogue.hide()

func _subtitle_label(size: int,color: Color) -> Label:
	var label := Label.new()
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # already tr()'d, with its speaker
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font",heavy)
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.add_theme_constant_override("outline_size",6)
	label.add_theme_color_override("font_outline_color",Color.BLACK)
	return label

func _dress_room(set_piece: Node3D) -> void:
	## The room on 26 October: the pistol from the alley on the rack and no other gun, nothing on
	## the board yet, the window shut; the TV left out of its own light.
	var start: Dictionary = Campaign.state if plan.get("room","") == "campaign" else Campaign.fresh()
	for node in set_piece.find_children("*","MeshInstance3D",true,false):
		var name := String(node.name)
		var owner_name := String(node.get_parent().name)
		for surface in node.mesh.get_surface_count():
			var mat := node.mesh.surface_get_material(surface) as BaseMaterial3D
			if mat: mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		for weapon in [name,owner_name]:
			if weapon.begins_with("Weapon_"): node.visible = weapon.trim_prefix("Weapon_") in start.unlocks
		if SET_PARTS.any(func(part): return name.begins_with(part)): node.layers = 2
		if name.begins_with("Hotspot_pc"): screen_node = node
		if name == "Chair": chair = node
	for node in set_piece.find_children("Clue_*","Node3D",true,false): node.visible = String(node.name).trim_prefix("Clue_") in start.get("clues",[])
	for node in set_piece.find_children("Sashes_open*","",true,false): node.visible = false
	# The glass: its middle, which way it faces, its width and height (corners found by their UVs).
	var surface := _screen_surface(screen_node)
	var arrays := screen_node.mesh.surface_get_arrays(surface)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var corner := func(at: Vector2) -> Vector3:
		var best := 0
		for i in uvs.size(): if uvs[i].distance_to(at) < uvs[best].distance_to(at): best = i
		return screen_node.global_transform*vertices[best]
	var top_left: Vector3 = corner.call(Vector2(0,0))
	screen_right = corner.call(Vector2(1,0))-top_left
	screen_down = corner.call(Vector2(0,1))-top_left
	screen_centre = top_left+(screen_right+screen_down)/2
	screen_normal = screen_right.cross(screen_down).normalized()
	if screen_normal.dot((ROOM_VIEW[0] as Vector3)-screen_centre) < 0: screen_normal = -screen_normal

func _screen_surface(node: MeshInstance3D) -> int:
	for surface in node.mesh.get_surface_count():
		var material: Material = node.mesh.surface_get_material(surface)
		if material and String(material.resource_name).ends_with("pc_screen"): return surface
	return 0

func _seat_caio() -> void:
	## Caio in the chair, facing the TV; the chair pulled up under him; the glow kept in his hand.
	caio = _person("res://assets/intro/caio.glb",CAIO_SEAT,room)
	_face(caio,screen_centre)
	_play(caio,"Sitting_Idle_Loop",0.0)
	var turn: float = caio.node.rotation.y
	if chair:
		var box: AABB = chair.global_transform*chair.get_aabb()
		var base := Vector3(box.get_center().x,0,box.get_center().z)
		var seat: Vector3 = CAIO_SEAT+Basis(Vector3.UP,turn)*Vector3(0,0,-SEAT_BACK)
		chair.transform = Transform3D(Basis(Vector3.UP,turn-(PI-.7)+CHAIR_TURN),seat)*Transform3D(Basis(),-base)
	var socket := BoneAttachment3D.new()
	socket.bone_name = "hand_r"
	caio.skeleton.add_child(socket)
	hand_glow = MeshInstance3D.new()
	var orb := SphereMesh.new()
	orb.radius = .06
	orb.height = .11
	orb.radial_segments = 8
	orb.rings = 4
	hand_glow.mesh = orb
	hand_glow.position = Vector3(0,.07,0)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = Color(.3,.92,1.0,.0)
	hand_glow.material_override = glow
	socket.add_child(hand_glow)
	hand_light = OmniLight3D.new()
	hand_light.light_color = Color("5ad8ff")
	hand_light.omni_range = 1.3
	hand_light.light_energy = 0.0
	socket.add_child(hand_light)
	# Once the set is off he lifts that hand in front of his chest, over the desk, and looks at it:
	# a two-bone IK on the right arm and a look-at on the head, both faded in by `influence`.
	var facing: Vector3 = (screen_centre-CAIO_SEAT)*Vector3(1,0,1)
	facing = facing.normalized()
	var right := facing.cross(Vector3.UP)
	var palm := Marker3D.new()
	palm.position = CAIO_SEAT+facing*.12+right*.06+Vector3.UP*1.02
	room.add_child(palm)
	var elbow := Marker3D.new()
	elbow.position = CAIO_SEAT+right*.4+Vector3.UP*.7-facing*.05
	room.add_child(elbow)
	raise = TwoBoneIK3D.new()
	caio.skeleton.add_child(raise)
	raise.setting_count = 1
	raise.set_root_bone_name(0,"upperarm_r")
	raise.set_middle_bone_name(0,"lowerarm_r")
	raise.set_end_bone_name(0,"hand_r")
	raise.set_target_node(0,raise.get_path_to(palm))
	raise.set_pole_node(0,raise.get_path_to(elbow))
	raise.influence = 0.0
	look = LookAtModifier3D.new()
	caio.skeleton.add_child(look)
	look.bone_name = "Head"
	look.target_node = look.get_path_to(palm)
	look.influence = 0.0

func raise_at(t: float) -> float:
	## How far up his hand is: up as the set goes off, kept there until the card.
	return smoothstep(.15,.9,t-power_off) if reflects else 0.0

func hand_glow_at(t: float) -> float:
	## The Avesso still in his hand once the set is off, fading while he looks at it.
	if not reflects: return 0.0
	var k := t-power_off
	return smoothstep(.3,.7,k)*(1.0-smoothstep(1.3,float(after.calm),k))

func _frame_caio(_local: float) -> void:
	## He stays in the chair, breathing hard; the Avesso leaves his hand while he looks at it.
	raise.influence = raise_at(time)
	look.influence = raise_at(time)*.8
	var glow := hand_glow_at(time)
	(hand_glow.material_override as StandardMaterial3D).albedo_color.a = .7*glow
	hand_light.light_energy = 2.0*glow

func _bezier(a: Vector3,b: Vector3,c: Vector3,t: float) -> Vector3:
	return a.lerp(b,t).lerp(b.lerp(c,t),t)

func _screen_distance(fill: float) -> float:
	return screen_down.length()/fill/(2.0*tan(deg_to_rad(SCREEN_FOV)/2.0))

func _frame_room() -> void:
	## From the room's own view, Caio's back to us, past his shoulder up to the glass, creeping
	## closer until the set goes off; then a step aside, where the dark glass shows his face.
	var t := minf(time,power_off)
	var walk := smoothstep(WALK_IN.x,WALK_IN.y,t)
	var creep := clampf((t-WALK_IN.y)/(power_off-WALK_IN.y),0,1)
	var close := screen_centre+screen_normal*_screen_distance(lerpf(SCREEN_FILL,SCREEN_CLOSE,creep))
	var eye := _bezier(ROOM_VIEW[0],SHOULDER,close,walk)
	var look: Vector3 = (ROOM_VIEW[1] as Vector3).lerp(screen_centre,smoothstep(0.0,.7,walk))
	room_camera.fov = lerpf(ROOM_FOV,SCREEN_FOV,walk)
	if time >= power_off and reflects:
		if reflect_eye == Vector3.ZERO: reflect_eye = _reflection_eye(screen_centre+screen_normal*MIRROR_DISTANCE)
		var settle := smoothstep(power_off+.3,power_off+1.3,time)
		eye = eye.lerp(reflect_eye,settle)
		room_camera.fov = lerpf(SCREEN_FOV,MIRROR_FOV,settle)
		night_fill.light_energy = .45*settle
	var breathe := Vector3(sin(time*.7),sin(time*.53)*.6,0)*.003
	room_camera.look_at_from_position(eye+breathe,look)

func _reflection_eye(eye: Vector3) -> Vector3:
	## Where to stand, as far from the glass as `eye`, so his head's reflection sits in the middle
	## of it, a little high: the ray to his mirror image must cross the glass there.
	var head: Vector3 = caio.skeleton.global_transform*caio.skeleton.get_bone_global_pose(caio.skeleton.find_bone("Head")).origin
	var across := screen_right.normalized()
	var up := -screen_down.normalized()
	var d := (eye-screen_centre).dot(screen_normal)
	var h := (head-screen_centre).dot(screen_normal)
	var k := d/(d+h)
	var aim := Vector2(0,screen_down.length()*.36)   # his head high in the glass, his hands low
	var hx := (head-screen_centre).dot(across)
	var hy := (head-screen_centre).dot(up)
	return screen_centre+screen_normal*d+across*((aim.x-k*hx)/(1.0-k))+up*((aim.y-k*hy)/(1.0-k))

func _frame_mirror() -> void:
	## The glass as a mirror: the camera's image through it, an off-axis frustum that is exactly
	## the glass, so the reflection lands where it would.
	var showing := smoothstep(power_off+.25,power_off+.9,time)*(1.0-smoothstep(epilogue_at-.4,epilogue_at,time)) if reflects else 0.0
	screen_material.set_shader_parameter("reflection",showing)
	mirror.render_target_update_mode = SubViewport.UPDATE_ALWAYS if showing > 0.0 else SubViewport.UPDATE_DISABLED
	if showing <= 0.0: return
	var eye := room_camera.global_position
	var d := (eye-screen_centre).dot(screen_normal)
	var image := eye-2.0*d*screen_normal
	var basis := Basis.looking_at(screen_normal,-screen_down.normalized())
	mirror_camera.global_transform = Transform3D(basis,image)
	var offset := screen_centre-image
	mirror_camera.set_frustum(screen_down.length(),Vector2(offset.dot(basis.x),offset.dot(basis.y)),maxf(d,.01),30.0)

# ---------------------------------------------------------------- sound
func _build_sound() -> void:
	set_sound = _player("set")
	off_sound = _player("off")
	room_sound = _player("room")
	after_sound = _player("after")
	(room_sound.stream as AudioStreamOggVorbis).loop = true
	room_sound.play()
	set_sound.play()

func _player(key: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(plan.get("sound",SOUND.set) if key == "set" else SOUND[key])
	player.volume_db = SOUND_DB[key]
	add_child(player)
	return player

func _exit_tree() -> void:
	for player in [set_sound,off_sound,room_sound,after_sound]: player.stop()

func _power_down() -> void:
	## The set goes off: its sound stops dead, the tube zaps and ticks; the room goes on.
	powered_off = true
	set_sound.stop()
	off_sound.play()
	if reflects: after_sound.play()   # his breath slowing down (tools/build_intro_audio.py)

func _style(color: Color,radius: int,border: int,border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border)
	style.border_color = border_color
	return style
