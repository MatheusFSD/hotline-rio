extends Node3D
const Simulation = preload("res://scripts/simulation.gd")
const ActorVisual = preload("res://scripts/actor_visual.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const Intro = preload("res://scripts/intro.gd")
const Room = preload("res://scripts/room.gd")
const SoundBoard = preload("res://scripts/sound_board.gd")
const Entrance = preload("res://scripts/level_entrance.gd")
const SceneryGrade = preload("res://scripts/scenery_grade.gd")
const ActorLook = preload("res://scripts/actor_look.gd")
const ResultScreen = preload("res://scripts/result_screen.gd")
const ExitMarker = preload("res://scripts/exit_marker.gd")
const Hud = preload("res://scripts/hud.gd")
const MissionScreen = preload("res://scripts/mission_screen.gd")
const Campaign = preload("res://scripts/campaign.gd")
const ClueMarker = preload("res://scripts/clue_marker.gd")
const ActCard = preload("res://scripts/act_card.gd")
const NewsCard = preload("res://scripts/news_card.gd")
const AvessoView = preload("res://scripts/avesso_view.gd")
const PatientView = preload("res://scripts/patient_view.gd")
const CameraView = preload("res://scripts/camera_view.gd")
const CAMERA_HOME := Vector3(0,33,23.7)
const CAMERA_TARGET := Vector3(0,0,-1.8)
const CAMERA_SIZE := 26.5
## Kill beat, in real seconds: zoom in, slow motion while fully zoomed, then zoom out.
const KILL_ZOOM := .09
const ZOOM_IN_TIME := .08
const SLOWMO_TIME := .4
const SLOWMO_EASE := .15
const SLOWMO_SCALE := .3
const ZOOM_OUT_TIME := .35
## Death beat, in real seconds: a hard zoom onto the hero, then slow motion with a slow push-in
## and a slight roll, and only then the death screen.
## A kill holds the world dead still for a few frames, real time, before the zoom and the slow motion
## take it: the blow lands. The rest keeps a minigun's run of kills from stuttering.
const HIT_STOP := {"katana":.07,"shotgun":.06}
const HIT_STOP_BULLET := .045
const HIT_STOP_REST := .14
## The last enemy down: a longer hold, the music drops out and comes back filtered, opening up.
const LAST_STOP := .16
const DROP_DEPTH_DB := -24.0
const DROP_HOLD := .5
const DROP_RETURN := .7
## Slow motion muffles the night's music, down to this cutoff at the deepest; the death's too.
const MUSIC_BUS := "Music"
const MUFFLED_HZ := 700.0
const OPEN_HZ := 20000.0
## The aim: it opens on each shot, turns through a reload, and an X is left on each kill.
const AIM_KICK := .7
const AIM_RETURN := 14.0
const AIM_SPIN := 1.2          # turns per second while reloading
const MARK_TIME := .45
const RETRY_GUARD := .3         # R is also the reload: a tap as he dies must not skip his death
const DEATH_ZOOM := .62        # the frame shrinks to 38% of the gameplay view
const DEATH_ZOOM_IN := .22
const DEATH_SLOWMO := 2.0
const DEATH_SCALE := .2
const DEATH_PUSH := .12        # extra push-in across the slow motion
const DEATH_ROLL := 5.0        # degrees of camera roll across the slow motion
## Mouse wheel zoom, from the full view (CAMERA_SIZE, the farthest) in to PLAYER_ZOOM_MIN: never so
## close that the PS1 models and textures show their seams. The closer view follows the hero but
## never shows anything the full view would not. Kill, walk-in and death framing start from it.
const PLAYER_ZOOM_MIN := 15.0
const PLAYER_ZOOM_STEP := 2.3
const PLAYER_ZOOM_RATE := 10.0   # easing per second toward the size the wheel asked for
## Soft key light that only reaches the living (ActorLook's figure layer): it lifts heads,
## shoulders and guns above the floor they stand on. Travel direction, color, energy.
const FIGURE_LIGHT := [Vector3(.3,-1.0,-.45),"fff0dc",.42]
var sim := Simulation.new()
var camera: Camera3D
var room
var kill_zoom := 0.0
var kill_time := -1.0
var death_time := -1.0     # real seconds since the hero fell, while the death beat runs
var camera_basis: Basis
var exit_marker
var clue_markers: Array = []   # one per clue of the level, in the order of sim.clues
var act_card   # the end of an act, between its last room and what comes next
var news       # the act's newscast, after its card
var avesso     # shadow-flames and hanging shells of the casca rule
var camera_view   # the level's security cameras and their cones
var patient_view   # the sedated patients in their beds (night eleven)
var level_nodes: Array[Node] = []   # scenery, lamps, collision, cast and exit of the level on stage
var world_environment: Environment
var phase_tint: ColorRect
var phase_view := 0.0
var actors: Array[Node3D] = []
var guests: Array[Node3D] = []   # the party's guests (Simulation.civilians), in order
var lamp_lights: Array[OmniLight3D] = []   # the level's lamps, which the breaker puts out
var moon_light: DirectionalLight3D
## Lit and blacked out (the breaker, docs/fase9.md): moon energy and colour, ambient energy.
const LIT := [.55,Color("c9d4f0"),.62]
const BLACKOUT := [.12,Color("6a80c0"),.1]
var hud: Hud
## How the main menu opens this scene: the night to start on, its gun, and whether the newscast
## plays first (a new game). Launching main.tscn directly keeps these defaults.
static var opening := {"level":0,"weapon":"pistol","news":true}
var overlay   # MissionScreen: the night's card and the pause
var overlay_place: Label
var overlay_title: Label
var overlay_body: Label
var overlay_button: Button
var results   # death and level-clear screens; the overlay keeps briefing and pause
var aim_marker: MeshInstance3D
var last_state := ""
var fire_armed := true
var hit_stop := 0.0
var alerted_before: Array[bool] = []
var all_down := false
var music_drop := -1.0          # real seconds since the last enemy fell, while the drop runs
var music_bus := -1
var aim_kick := 0.0
var kill_marks: Array[Dictionary] = []
var aim_material: StandardMaterial3D
var hit_stop_rest := 0.0
var effects
var entrance          # the level's opening walk-in while it plays
var cinematics := false   # newscast and walk-ins: real launches only, tests opt in
var scenery_bounds: AABB  # the camera never frames past the built scenery
var view_size := CAMERA_SIZE      # gameplay framing the wheel asked for, kept across nights
var view_current := CAMERA_SIZE   # the same, eased
const MUSIC_DB := -6.0
const MUSIC_SUNK := .4      # how far a death drags the night's music down
var music: AudioStreamPlayer
var music_path := ""        # what it is playing, "" when it is not
var music_fade: Tween
var music_carries := false  # the next stage goes on from where this one's mix is
const DEATH_MUSIC := "res://assets/audio/death.ogg"
var death_music: AudioStreamPlayer
const ENTRANCE_MUSIC := "res://assets/audio/entrance.ogg"
const ENTRANCE_HIT := "res://assets/audio/entrance_hit.ogg"
const NIGHT_CLEAR := "res://assets/audio/night_clear.ogg"
var entrance_music: AudioStreamPlayer
var cue: AudioStreamPlayer   # one short shot of music: the walk-in's end, the night clear
var sound: SoundBoard

func _ready() -> void:
	_setup_camera()
	_setup_lighting()
	effects = CombatEffects.new()
	add_child(effects)
	effects.setup(camera,sim)
	_setup_ui()
	_setup_cursor()
	music = AudioStreamPlayer.new()
	add_child(music)
	_setup_music_bus()
	music.bus = MUSIC_BUS
	death_music = AudioStreamPlayer.new()
	add_child(death_music)
	sound = SoundBoard.new()
	add_child(sound)
	entrance_music = AudioStreamPlayer.new()
	add_child(entrance_music)
	cue = AudioStreamPlayer.new()
	add_child(cue)
	results.slammed.connect(sound.slam)
	results.ticked.connect(sound.tick)
	get_tree().auto_accept_quit = false   # the window close goes through _quit_game
	sim.weapon = opening.weapon
	load_level(requested_level())
	_play_intro.call_deferred()

## The night's music (layout "music", from tools/build_music_*.py). It starts as the night does; a
## death only holds it, and the retry picks it up where it was. The Síndico's stages are mixes of one
## song: the next picks up on the same beat.
func _play_music() -> void:
	var path: String = sim.layout.get("music","")
	var carried := music_carries and music.playing
	music_carries = false
	if path == music_path: return
	if path == "":
		_fade_music()
		return
	var from := music.get_playback_position() if carried else 0.0
	if music_fade: music_fade.kill()
	var stream := load(path) as AudioStreamOggVorbis
	stream.loop = true
	music.stream = stream
	music.volume_db = MUSIC_DB if carried else -30.0
	music.play(from)
	music_path = path
	if not carried:
		music_fade = create_tween()
		music_fade.tween_property(music,"volume_db",MUSIC_DB,.6)

## The walk-in has its own music, looping for as long as he walks.
func _play_entrance_music() -> void:
	_fade_music(.3)
	var stream := load(ENTRANCE_MUSIC) as AudioStreamOggVorbis
	stream.loop = true
	entrance_music.stream = stream
	entrance_music.volume_db = MUSIC_DB
	entrance_music.play()

## He stops and the camera pulls back: the walk-in's music ends on its hit.
func _end_entrance_music() -> void:
	if not entrance_music.playing: return
	entrance_music.stop()
	_play_cue(ENTRANCE_HIT)

func _play_cue(path: String) -> void:
	cue.stream = load(path)
	cue.volume_db = MUSIC_DB
	cue.play()

## The night is over: the music goes down and stops.
func _fade_music(seconds := 1.2) -> void:
	music_path = ""
	if not music.playing: return
	if music_fade: music_fade.kill()
	music_fade = create_tween()
	music_fade.tween_property(music,"volume_db",-40.0,seconds)
	music_fade.tween_callback(music.stop)

## Leaving, the music stops. Closing the window stops it a few frames early, as the menu does: the
## audio server only lets go of a playback on its next mix.
## The hero is down: across the slow motion the night's music sinks like a tape running out.
func _sink_music() -> void:
	if music_path == "": return
	if music_fade: music_fade.kill()
	music.pitch_scale = lerpf(1.0,MUSIC_SUNK,clampf(death_time/.6,0,1))
	music.volume_db = lerpf(MUSIC_DB,-40.0,clampf(death_time/DEATH_SLOWMO,0,1))

## The slow motion is over, the death screen is up: the night's music held, the death's playing.
func _play_death_music() -> void:
	music.stream_paused = true
	var stream := load(DEATH_MUSIC) as AudioStreamOggVorbis
	stream.loop = true
	death_music.stream = stream
	death_music.volume_db = MUSIC_DB
	death_music.play()

## A retry: the death's music gone, the night's back from where it was held.
func _end_death_music() -> void:
	death_music.stop()
	music.stream_paused = false
	music.pitch_scale = 1.0
	if music_path != "": music.volume_db = MUSIC_DB

func _stop_audio() -> void:
	if music: music.stop()
	if death_music: death_music.stop()
	if entrance_music: entrance_music.stop()
	if cue: cue.stop()
	if sound: sound.silence()

func _exit_tree() -> void:
	_stop_audio()
	get_tree().auto_accept_quit = true

func _quit_game() -> void:
	_stop_audio()
	for i in 3: await get_tree().process_frame
	get_tree().quit()

static func requested_level() -> int:
	## `-- --level=2` opens straight on that night; the newscast belongs to the first one.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="): return clampi(int(arg.get_slice("=",1))-1,0,Simulation.LEVELS.size()-1)
	return clampi(opening.level,0,Simulation.LEVELS.size()-1)

static func level_lamps(layout: Dictionary) -> Array:
	## Warm practical lights from the level file: position (x, height, z), color, energy, range.
	var lamps := []
	for lamp in layout.lamps: lamps.append([Vector3(lamp[0][0],lamp[0][1],lamp[0][2]),lamp[1],float(lamp[2]),float(lamp[3])])
	return lamps

func load_level(index: int) -> void:
	## Puts one night on stage: the scenery, lamps, collision, cast and exit described by its file
	## in Simulation.LEVELS. Camera, lighting rig, HUD and screens stay for every level.
	for node in level_nodes: node.queue_free()
	level_nodes.clear()
	actors.clear()
	guests.clear()
	effects.clear()
	sim.mods = Campaign.mods()   # the upgrades earned so far change the rules of this night
	sim.known_clues = Campaign.state.clues
	sim.load_level(index)
	var environment := (load(sim.layout.scene) as PackedScene).instantiate()
	_stage(environment)
	scenery_bounds = AABB()
	for node in environment.find_children("*","MeshInstance3D",true,false):
		var box: AABB = node.global_transform*node.get_aabb()
		scenery_bounds = box if scenery_bounds.size == Vector3.ZERO else scenery_bounds.merge(box)
	_setup_environment_materials(environment)
	exit_marker = ExitMarker.new()
	_stage(exit_marker)
	exit_marker.setup(sim.layout.exit)
	clue_markers.clear()
	for clue in sim.clues:
		var marker := ClueMarker.new()
		_stage(marker)
		marker.setup(clue.rect)
		clue_markers.append(marker)
	avesso = AvessoView.new()
	_stage(avesso)
	avesso.setup(sim)
	camera_view = CameraView.new()
	_stage(camera_view)
	camera_view.setup(sim)
	patient_view = PatientView.new()
	_stage(patient_view)
	patient_view.setup(sim)
	_setup_lamps()
	_setup_colliders()
	_setup_actors()
	_show_hero_weapon()
	last_state = ""   # the briefing takes this level's words
	# Night twelve goes out live while Jairo is alive to broadcast it.
	hud.set_rec(int(sim.layout.get("night",0)) == 12 and not bool(Campaign.state.get("jairo_dead",false)))
	update_ui()

func _stage(node: Node) -> void:
	add_child(node)
	level_nodes.append(node)

func _play_intro() -> void:
	# The newscast opens real launches only; tests instance this scene directly.
	cinematics = get_tree().current_scene == self
	if not cinematics or sim.level != 0 or not opening.news: return
	add_child(Intro.new(level_lamps(sim.layout)))

func _setup_camera() -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.position = CAMERA_HOME
	camera.look_at(CAMERA_TARGET)
	camera_basis = camera.basis
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CAMERA_SIZE
	camera.current = true
	camera.near = .1
	camera.far = 120

func _setup_environment_materials(root: Node) -> void:
	# PSX look: tiny scenery textures stay crisp instead of being blurred.
	for node in root.find_children("*","MeshInstance3D",true,false):
		for surface in node.mesh.get_surface_count():
			var mat := node.mesh.surface_get_material(surface) as BaseMaterial3D
			if mat:
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				mat.roughness = 1.0
				mat.metallic = 0.0
				if mat.resource_name == "Lapa_cap":
					# Floor-plan cut: wall tops read as solid black under any light.
					mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					mat.albedo_color = Color.BLACK
	# Calmer floors and roofs, so the fighters lead the frame (scripts/scenery_grade.gd).
	SceneryGrade.apply(root)
	SceneryGrade.shade(root,sim.layout)

func _setup_lighting() -> void:
	# Lapa at night: cool moonlight and ambient, warm lamps inside the bar.
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("141a24")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("aab4cc")
	env.ambient_light_energy = .62
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.adjustment_enabled = true
	world.environment = env
	world_environment = env
	add_child(world)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55,-35,0)
	moon.light_color = Color("c9d4f0")
	moon.light_energy = .55
	moon.shadow_enabled = false
	add_child(moon)
	moon_light = moon
	var figure_light := DirectionalLight3D.new()
	figure_light.basis = Basis.looking_at(FIGURE_LIGHT[0],Vector3.BACK)
	figure_light.light_color = Color(FIGURE_LIGHT[1])
	figure_light.light_energy = FIGURE_LIGHT[2]
	figure_light.light_cull_mask = 1 << (ActorLook.FIGURE_LAYER-1)
	figure_light.shadow_enabled = false
	add_child(figure_light)

func _setup_lamps() -> void:
	lamp_lights.clear()
	for lamp in level_lamps(sim.layout):
		var light := OmniLight3D.new()
		light.position = lamp[0]
		light.light_color = Color(lamp[1])
		light.light_energy = lamp[2]
		light.omni_range = lamp[3]
		light.omni_attenuation = .8
		light.shadow_enabled = false
		_stage(light)
		lamp_lights.append(light)
	_light_up()

## A landing light used up goes dark (the lamp standing on that pad).
func _pad_out(p: Vector2) -> void:
	var lamps := level_lamps(sim.layout)
	for i in lamp_lights.size():
		if Vector2(lamps[i][0].x,lamps[i][0].z).distance_to(p) < 1.0: create_tween().tween_property(lamp_lights[i],"light_energy",0.0,.3)

## Every lamp at its energy, the moon and the ambient as usual.
func _light_up() -> void:
	var lamps := level_lamps(sim.layout)
	for i in lamp_lights.size(): lamp_lights[i].light_energy = lamps[i][2]
	moon_light.light_energy = LIT[0]
	moon_light.light_color = LIT[1]
	world_environment.ambient_light_energy = LIT[2]

## The breaker trips: the lamps stutter and go out; a faint blue moon and the screens stay.
func _blackout() -> void:
	for light in lamp_lights:
		var out := create_tween()
		out.tween_property(light,"light_energy",light.light_energy*.3,.04)
		out.tween_property(light,"light_energy",light.light_energy,.05)
		out.tween_property(light,"light_energy",0.0,.06)
	var night := create_tween().set_parallel()
	night.tween_property(moon_light,"light_energy",BLACKOUT[0],.15)
	night.tween_property(moon_light,"light_color",BLACKOUT[1],.15)
	night.tween_property(world_environment,"ambient_light_energy",BLACKOUT[2],.15)

func _setup_colliders() -> void:
	# Explicit 3D collision shapes also make the cutaway usable from the editor.
	for entry in sim.layout.solids:
		var r := Simulation.rect(entry.r)
		var body := StaticBody3D.new()
		body.name = "Solid_"+entry.type
		body.collision_layer = 1
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(r.size.x,entry.h,r.size.y)
		shape.shape = box
		body.position = Vector3(r.get_center().x,entry.h/2.0,r.get_center().y)
		body.add_child(shape)
		_stage(body)

func _setup_actors() -> void:
	for i in range(sim.enemies.size()+1): _add_actor(i)
	for i in actors.size(): actors[i].sync(sim.player if i==0 else sim.enemies[i-1],0.0,false)
	for i in sim.civilians.size():
		# Guests: the guards' bodies in evening wear, a flute of champagne and no gun.
		var visual := ActorVisual.new()
		_stage(visual)
		visual.setup("res://assets/characters/enemy_%s.glb" % ("b" if i%2 else "a"))
		visual.add_look(false)
		visual.guest = true
		visual.dress(i)
		var pose: String = sim.layout.civilians[i].get("pose","drink")
		visual.set_pose("champagne" if pose == "drink" else pose)
		visual.sync(sim.civilians[i],0.0,false)
		guests.append(visual)

func _add_actor(i: int) -> ActorVisual:
	## Actor i: the hero at 0, then the enemies in order. Shells that stand up join at the end.
	var visual := ActorVisual.new()
	_stage(visual)
	var path := "res://assets/characters/hero.glb" if i == 0 else "res://assets/characters/enemy_%s.glb" % ("a" if i%2 else "b")
	visual.setup(path)
	visual.add_look(i == 0)
	if i > 0 and i <= sim.layout.enemies.size():
		var entry: Dictionary = sim.layout.enemies[i-1]
		if entry.get("weapon","pistol") != "pistol": visual.set_weapon(entry.weapon)   # a Guardião rifle
		visual.set_pose(String(entry.get("pose","")))   # unaware everyday pose
		if entry.get("pose","") == "hold": visual.dress(i)   # posing as a guest
		if entry.get("kind","") == "proprietario": visual.violet_phase()
	actors.append(visual)
	return visual

func _rise(event: Dictionary) -> void:
	## A shadow-flame reached a whole body: a corpse loses its damage and gets up; a shell in its
	## bag becomes a new actor, getting up from the floor under the torn bag.
	var i := int(event.victim)
	if i >= actors.size():
		var body := _add_actor(i)
		var guest := int(event.get("guest",-1))
		if int(event.get("patient",-1)) >= 0: body.dress(0,ActorVisual.GOWN)   # out of the hospital bed, in its gown
		elif event.get("style","") == "seated": body.dress(0,Color("8fa0c8") if event.get("name","") == "souza" else Color("a8a8b0"))   # an aide's suit, Souza's uniform
		elif guest >= 0:
			# A guest's corpse got up: the new enemy wears the same evening clothes, the old body goes.
			body.dress(guest)
			guests[guest].visible = false
		else: body.strip()   # out of the bag with nothing on
		body.sync(sim.enemies[i-1],0.0,false)
	actors[i].reset_damage()
	actors[i].clear_effects()
	actors[i].current = ""
	if event.kind == "proprietario": actors[i].violet_phase()
	if event.spare: actors[i].fall_from_bag()

func _drop_spare_actors() -> void:
	## A retry puts the shells back in their bags: the enemies they became leave the stage.
	while actors.size() > sim.enemies.size()+1:
		var visual: Node3D = actors.pop_back()
		level_nodes.erase(visual)
		visual.queue_free()

func _setup_cursor() -> void:
	# Small unlit aiming cross, separate from combat presentation.
	aim_marker = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(.16,.015,.035)
	aim_marker.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("f6d98b")
	aim_marker.material_override = mat
	aim_material = mat
	add_child(aim_marker)
	var cross := MeshInstance3D.new()
	cross.mesh = mesh
	cross.rotation.y = PI/2
	cross.material_override = mat
	aim_marker.add_child(cross)

func _setup_ui() -> void:
	hud = Hud.new()
	add_child(hud)
	phase_tint = hud.phase_tint
	# Mission card and pause, over the level; the controls are listed only here.
	overlay = MissionScreen.new(hud)
	hud.root.add_child(overlay)
	overlay_place = overlay.place
	overlay_title = overlay.title
	overlay_body = overlay.body
	overlay_button = overlay.button
	overlay.confirmed.connect(start_or_resume)
	overlay.menu_requested.connect(go_to_menu)
	results = ResultScreen.new()
	add_child(results)
	results.confirmed.connect(start_or_resume)

func go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

## The Síndico on the helipad shows only to the spectre.
func _show_ghost() -> void:
	for i in range(1,actors.size()):
		if sim.enemies[i-1].get("ghost",false): actors[i].visible = sim.player.phasing or not sim.enemies[i-1].alive

func _next_stage() -> void:
	music_carries = true
	load_level(sim.level+1)

func show_room() -> void:
	# Between nights the protagonist goes home; the next night starts from there.
	if room: return
	_fade_music()
	# The night goes into the campaign: clues on the board, favours, the story unlock, the next night.
	# Guests killed are kept too: they never fail a night, but they go in the papers.
	Campaign.state.civilians_killed = int(Campaign.state.get("civilians_killed",0))+sim.civilians_killed
	if sim.civilians.any(func(c): return c.vip == "jairo"): Campaign.state.jairo_dead = not sim.vip_alive()
	var report := Campaign.complete(sim.level,sim.layout,sim.taken_clues(),(sim.level+1)%Simulation.LEVELS.size(),sim.weapon,cinematics)
	if sim.layout.get("act_end",{}).get("finale",false):
		# The Síndico is down: his card first, then the room where the ending is chosen.
		act_card = ActCard.new(hud,sim.layout.act_end)
		add_child(act_card)
		act_card.confirmed.connect(_finale_room,CONNECT_ONE_SHOT)
		return
	room = Room.new({"kills":sim.kills,"time":sim.elapsed,"attempt":sim.attempt,"weapon":sim.weapon,"level":sim.level,
		"report":report,"campaign":Campaign.state,"persist":cinematics})
	add_child(room)
	room.next_night.connect(_leave_room)

func _finale_room() -> void:
	act_card.queue_free()
	act_card = null
	room = Room.new({"kills":sim.kills,"time":sim.elapsed,"attempt":sim.attempt,"weapon":sim.weapon,"level":sim.level,
		"report":{},"campaign":Campaign.state,"persist":cinematics,"finale":true})
	add_child(room)
	room.finale_chosen.connect(_play_finale,CONNECT_ONE_SHOT)

## The TV shows Final A or B (Campaign.ending); the window is Final C.
func _play_finale(kind: String) -> void:
	room.queue_free()
	room = null
	var path := "res://assets/news/final_c.json" if kind == "window" else "res://assets/news/final_%s.json" % Campaign.ending()
	news = NewsCard.new(NewsCard.load_news(path,Campaign.state))
	add_child(news)
	news.finished.connect(_end_game,CONNECT_ONE_SHOT)

func _end_game() -> void:
	## The end: a real launch goes back to the menu; tests start over from the first night.
	news.queue_free()
	news = null
	if cinematics: go_to_menu()
	else: load_level(0)

func _leave_room() -> void:
	# The next night is the next level (back to the first after the last), opening on its briefing
	# with the gun chosen in the room in hand. The last night of an act closes it first.
	sim.weapon = room.equipped
	room.queue_free()
	room = null
	Campaign.state.weapon = sim.weapon
	if sim.layout.has("act_end"):
		act_card = ActCard.new(hud,sim.layout.act_end)
		add_child(act_card)
		act_card.confirmed.connect(_close_act,CONNECT_ONE_SHOT)
		if cinematics: Campaign.save()
		return
	load_level((sim.level+1)%Simulation.LEVELS.size())
	if cinematics: Campaign.save()

func _close_act() -> void:
	## Past the act's card, its newscast comes on before anything else: watched on the TV in
	## Caio's room when the act has one in 3D (act_end "broadcast", the opening's format), else the
	## flat card (act_end "news").
	act_card.queue_free()
	act_card = null
	if sim.layout.act_end.has("broadcast") and news == null:
		news = Intro.new([],sim.layout.act_end.broadcast)
		add_child(news)
		news.finished.connect(_close_news,CONNECT_ONE_SHOT)
		return
	if sim.layout.act_end.has("news") and news == null:
		news = NewsCard.new(NewsCard.load_news(sim.layout.act_end.news,int(Campaign.state.get("civilians_killed",0))))
		add_child(news)
		news.finished.connect(_close_news,CONNECT_ONE_SHOT)
		return
	_after_act()

func _close_news() -> void:
	if is_instance_valid(news): news.queue_free()
	news = null
	_after_act()

func _after_act() -> void:
	## The story goes on to the next night. A card marked "menu" (the last night made so far) sends
	## a real launch back to the main menu instead, with the campaign saved where it stands.
	if cinematics and sim.layout.act_end.get("menu",false): go_to_menu()
	else: load_level((sim.level+1)%Simulation.LEVELS.size())

func equip(weapon: String) -> void:
	sim.weapon = weapon
	_show_hero_weapon()

func switch_weapon() -> void:
	## Katana <-> the gun from the room (F).
	sim.switch_weapon()
	_show_hero_weapon()

func _show_hero_weapon() -> void:
	var held := "katana" if sim.melee else sim.weapon
	if actors[0].weapon != held: actors[0].set_weapon(held)

func start_or_resume() -> void:
	if sim.state == "won":
		results.hide_screen()
		show_room()
		return
	if sim.state == "paused": sim.state = "playing"
	else:
		# A night opens with the walk-in; retrying after a death starts right away.
		var opening: bool = sim.state == "ready" and cinematics
		sim.reset()
		sound.silence()
		_end_death_music()
		_light_up()   # the breaker back on
		effects.clear()
		kill_zoom = 0.0
		kill_time = -1.0
		death_time = -1.0
		hit_stop = 0.0
		hit_stop_rest = 0.0
		alerted_before.clear()
		all_down = false
		music_drop = -1.0
		aim_kick = 0.0
		aim_marker.rotation.y = 0.0
		for mark in kill_marks: mark.node.queue_free()
		kill_marks.clear()
		_update_music_bus(0.0)
		camera.basis = camera_basis
		_apply_kill_zoom()
		phase_view = 0.0
		_apply_phase_view()
		for visual in actors:
			visual.current = ""
			visual.locomotion_time = 0.0
			visual.animator.stop()
			visual.clear_effects()
			visual.reset_damage()
		_drop_spare_actors()
		for visual in guests:
			visual.visible = true
			visual.current = ""
			visual.animator.stop()
			visual.clear_effects()
			visual.reset_damage()
		_show_hero_weapon()
		entrance =Entrance.from_layout(sim.layout,sim.player.p,sim.player.angle) if opening else null
		# A stage of the Síndico keeps the song going under its walk-in.
		if entrance and not music_carries: _play_entrance_music()
		else: _play_music()
		if entrance: begin_entrance()
	fire_armed = false
	update_ui()

func begin_entrance() -> void:
	## Plays the level's walk-in (from level.json) before handing over control.
	if not entrance: entrance = Entrance.from_layout(sim.layout,sim.player.p,sim.player.angle)
	if not entrance: return
	entrance.begin(sim.player)
	sim.state = "entering"
	_frame_entrance(1.0)
	update_ui()

func skip_entrance() -> void:
	if sim.state != "entering": return
	entrance.skip(sim.player)
	_end_entrance()

func _update_entrance(dt: float) -> void:
	_frame_entrance(entrance.update(dt,sim.player))
	if entrance.pulling_back(): _end_entrance_music()
	if entrance.finished: _end_entrance()

func _end_entrance() -> void:
	_end_entrance_music()   # skipped while he was still walking
	_play_music()
	entrance = null
	sim.state = "playing"
	fire_armed = false
	_apply_kill_zoom()
	update_ui()

func _frame_entrance(closeness: float) -> void:
	# Close on the hero (kept inside the scenery), easing out to the gameplay framing.
	var size := lerpf(view_current,entrance.close,closeness)
	var focus := _inside_scenery(Vector3(sim.player.p.x,1.0,sim.player.p.y),size)
	_frame(_view_focus(view_current).lerp(focus,closeness),size)

func _frame(center: Vector3,size: float) -> void:
	## The one camera rig: same angle always, looking at center with this orthographic size.
	camera.size = size
	camera.position = center+CAMERA_HOME-CAMERA_TARGET

func _inside_scenery(focus: Vector3,size: float) -> Vector3:
	# Slide the framing so a close view does not show past the edge of the built scenery.
	var view := get_viewport().get_visible_rect().size
	var half_width := size*view.x/view.y/2.0
	var pitch := (CAMERA_TARGET-CAMERA_HOME).angle_to(Vector3(0,0,-1))
	var half_depth := size/2.0/sin(pitch)
	var low := scenery_bounds.position
	var high := scenery_bounds.end
	if high.x-low.x > half_width*2: focus.x = clampf(focus.x,low.x+half_width,high.x-half_width)
	if high.z-low.z > half_depth*2: focus.z = clampf(focus.z,low.z+half_depth,high.z-half_depth)
	return focus

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_G:
		sim.toggle_god()   # modo deus, at any moment
		update_ui()
		return
	if event is InputEventMouseButton and event.pressed and sim.state == "entering":
		skip_entrance()
		return
	if sim.state == "playing":
		var wheel: bool = event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]
		var key_f: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F
		if wheel:
			zoom_view(-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
			return
		if key_f:
			switch_weapon()
			return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ENTER:
				if sim.state == "entering": skip_entrance()
				elif sim.state in ["dead","won"]:
					if not results.skip(): start_or_resume()   # the first Enter lands a running tally
				elif sim.state != "playing": start_or_resume()
			KEY_R:
				# The left hand is already there. Not an instant retry: see RETRY_GUARD.
				if sim.state == "dead" and death_time >= RETRY_GUARD: start_or_resume()
			KEY_ESCAPE:
				if sim.state == "entering":
					skip_entrance()
					return
				if sim.state in ["playing","paused"]: sim.state = "paused" if sim.state == "playing" else "playing"
				update_ui()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: _quit_game()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and sim.state == "playing":
		sim.state = "paused"
		if overlay: update_ui()

func aim_position() -> Vector2:
	var mouse := get_viewport().get_mouse_position()
	# Shake moves only presentation. It must not pull the player's aim off target.
	var offset := Vector2(camera.h_offset,camera.v_offset)
	camera.h_offset = 0
	camera.v_offset = 0
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	camera.h_offset = offset.x
	camera.v_offset = offset.y
	# Aim at torso height. Clicking a model's body therefore hits its ground position.
	var hit: Variant = Plane(Vector3.UP,1.15).intersects_ray(origin,direction)
	return Vector2(hit.x,hit.z) if hit != null else sim.player.p

func _physics_process(dt: float) -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): fire_armed = true
	var movement := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	var aim := aim_position()
	# The world runs on scaled time during a kill's slow motion; camera and HUD stay real-time.
	# A hit stop holds it dead: nothing moves, but what is ringing rings on and the camera keeps going.
	var held := hit_stop > 0.0
	hit_stop = maxf(0.0,hit_stop-dt)
	hit_stop_rest = maxf(0.0,hit_stop_rest-dt)
	var world_dt := 0.0 if held else dt*time_scale()
	if not held:
		sim.update(world_dt,{
			"move":movement,"aim":aim,
			"attack":fire_armed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),
			"reload":Input.is_physical_key_pressed(KEY_R),
			"phase":Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_Q) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)})
	sound.set_time(time_scale())
	if sim.state == "entering": _update_entrance(dt)
	for i in actors.size():
		actors[i].sync(sim.player if i == 0 else sim.enemies[i-1],world_dt,sim.state in ["paused","ready","won"])
	_show_ghost()
	for i in guests.size():
		var c: Dictionary = sim.civilians[i]
		if c.state == "gone" or c.used: guests[i].visible = false   # out of the door, or up again as an enemy
		elif guests[i].visible: guests[i].sync(c,world_dt,sim.state in ["paused","ready","won"])
	effects.update(world_dt,sim.state in ["paused","ready"])
	_update_kill_zoom(dt)
	_update_death_beat(dt)
	exit_marker.update(sim.cleared(),dt,sim.state == "paused")
	for i in clue_markers.size():
		var clue: Dictionary = sim.clues[i]
		clue_markers[i].update(sim.clue_spot(clue),not clue.taken and sim.state != "ready",dt,sim.state == "paused")
	sound.follow_reload(sim.player,sim.weapon)
	sound.advance(world_dt,sim.player,sim.state == "playing")
	for event in sim.events:
		sound.hear(event)
		if event.type == "blood" and not event.player and event.gore_allowed: _hold_for_kill(event.get("weapon",""))
		if event.type == "blood" and not event.player: _mark_kill(event.p)
		if event.type == "shot" and event.team == "player": aim_kick = 1.0
		if event.type == "clue": hud.show_clue(event.title,event.text)
		elif event.type == "rise": _rise(event)
		elif event.type == "blackout": _blackout()
		elif event.type == "pad_used": _pad_out(event.p)
	_watch_alerts()
	_watch_last_kill()
	_update_aim(dt,world_dt)
	_update_music_bus(dt)
	avesso.update(world_dt,sim.state in ["paused","ready"])
	camera_view.update(world_dt,sim.state in ["paused","ready"])
	patient_view.update()
	_update_phase_view(dt)
	effects.consume(sim.events,actors,guests)
	aim_marker.position = Vector3(aim.x,1.15,aim.y)
	aim_marker.visible = sim.state == "playing"
	update_ui()

func _setup_music_bus() -> void:
	music_bus = AudioServer.get_bus_index(MUSIC_BUS)
	if music_bus < 0:
		AudioServer.add_bus()
		music_bus = AudioServer.bus_count-1
		AudioServer.set_bus_name(music_bus,MUSIC_BUS)
		AudioServer.set_bus_send(music_bus,"Master")
		var muffle := AudioEffectLowPassFilter.new()
		muffle.cutoff_hz = OPEN_HZ
		AudioServer.add_bus_effect(music_bus,muffle)
	AudioServer.set_bus_effect_enabled(music_bus,0,false)

func _update_music_bus(dt: float) -> void:
	## The slow motion's muffle and the last kill's drop, on the night's music only.
	var depth := clampf((1.0-time_scale())/(1.0-SLOWMO_SCALE),0,1)
	var cutoff := OPEN_HZ*pow(MUFFLED_HZ/OPEN_HZ,depth)
	var level := 0.0
	if music_drop >= 0:
		music_drop += dt
		if music_drop < .06: level = DROP_DEPTH_DB*music_drop/.06
		elif music_drop < DROP_HOLD: level = DROP_DEPTH_DB
		else:
			var back := clampf((music_drop-DROP_HOLD)/DROP_RETURN,0,1)
			level = DROP_DEPTH_DB*(1.0-back)*(1.0-back)
			cutoff = minf(cutoff,OPEN_HZ*pow(MUFFLED_HZ/OPEN_HZ,1.0-back))
			if back >= 1.0: music_drop = -1.0
		if music_drop >= 0 and music_drop < DROP_HOLD: cutoff = minf(cutoff,MUFFLED_HZ)
	AudioServer.set_bus_volume_db(music_bus,level)
	var muffle := AudioServer.get_bus_effect(music_bus,0) as AudioEffectLowPassFilter
	muffle.cutoff_hz = cutoff
	AudioServer.set_bus_effect_enabled(music_bus,0,cutoff < OPEN_HZ*.95)

func _watch_alerts() -> void:
	## An enemy turning on him gets a "!" over the head, and the room one sting.
	if alerted_before.size() != sim.enemies.size():
		alerted_before.resize(sim.enemies.size())
		for i in sim.enemies.size(): alerted_before[i] = bool(sim.enemies[i].alerted)
	for i in sim.enemies.size():
		var e: Dictionary = sim.enemies[i]
		var now: bool = e.alive and e.alerted
		if now and not alerted_before[i] and sim.state == "playing" and i+1 < actors.size():
			actors[i+1].alert_flash()
			sound.alert()
		alerted_before[i] = now

func _watch_last_kill() -> void:
	## The last enemy down: hold longer than any kill, a heavy hit, and the music drops and opens back.
	var down: bool = sim.enemies.size() > 0 and sim.kills >= sim.enemies.size()
	if down and not all_down and sim.state in ["playing","won"]:
		hit_stop = maxf(hit_stop,LAST_STOP)
		hit_stop_rest = LAST_STOP+HIT_STOP_REST
		sound.slam(true)
		if sim.state == "playing": music_drop = 0.0
	all_down = down

func _mark_kill(p: Vector2) -> void:
	var mark := Node3D.new()
	var material := aim_material.duplicate() as StandardMaterial3D
	material.albedo_color = Color("ff2a3d")
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true   # drawn over the body it marks
	material.render_priority = 1
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(.34,.015,.06)
	for angle in [PI/4,-PI/4]:
		var bar := MeshInstance3D.new()
		bar.mesh = bar_mesh
		bar.material_override = material
		bar.rotation.y = angle
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mark.add_child(bar)
	mark.position = Vector3(p.x,1.15,p.y)
	add_child(mark)
	kill_marks.append({"node":mark,"material":material,"age":0.0})

func _update_aim(dt: float,world_dt: float) -> void:
	aim_kick *= exp(-AIM_RETURN*dt)
	aim_marker.scale = Vector3.ONE*(1.0+AIM_KICK*aim_kick)
	var quarter := PI/2
	if sim.player.reload > 0 and not sim.player.melee: aim_marker.rotation.y += world_dt*TAU*AIM_SPIN
	else: aim_marker.rotation.y = lerp_angle(aim_marker.rotation.y,roundf(aim_marker.rotation.y/quarter)*quarter,1.0-exp(-18.0*dt))
	for i in range(kill_marks.size()-1,-1,-1):
		var mark: Dictionary = kill_marks[i]
		mark.age += dt
		if mark.age >= MARK_TIME:
			mark.node.queue_free()
			kill_marks.remove_at(i)
			continue
		var pop: float = lerpf(1.8,1.0,clampf(mark.age/.08,0,1))
		mark.node.scale = Vector3.ONE*pop
		mark.material.albedo_color.a = clampf((MARK_TIME-mark.age)/.2,0,1)

func _hold_for_kill(gun: String) -> void:
	if hit_stop_rest > 0.0: return
	hit_stop = HIT_STOP.get(gun,HIT_STOP_BULLET)
	hit_stop_rest = hit_stop+HIT_STOP_REST

func _update_kill_zoom(dt: float) -> void:
	# Each kill (re)starts the beat. Resuming from the current zoom level avoids a jump,
	# and a kill during slow motion simply restarts it with the camera still zoomed.
	if sim.state in ["paused","entering"] or death_time >= 0: return
	view_current = lerpf(view_current,view_size,1.0-exp(-PLAYER_ZOOM_RATE*dt))
	for event in sim.events:
		if event.type == "blood" and not event.player:
			kill_time = ZOOM_IN_TIME*(1.0-sqrt(1.0-kill_zoom))
	if kill_time >= 0:
		kill_time += dt
		if kill_time >= ZOOM_IN_TIME+SLOWMO_TIME+ZOOM_OUT_TIME: kill_time = -1.0
	kill_zoom = _zoom_at(kill_time)
	_apply_kill_zoom()

func _zoom_at(t: float) -> float:
	if t < 0: return 0.0
	if t < ZOOM_IN_TIME:
		var u := t/ZOOM_IN_TIME
		return 1.0-(1.0-u)*(1.0-u)
	t -= ZOOM_IN_TIME+SLOWMO_TIME
	if t < 0: return 1.0
	return 1.0-smoothstep(0.0,1.0,t/ZOOM_OUT_TIME)

func _update_death_beat(dt: float) -> void:
	if death_time < 0: return
	var before := death_time
	death_time += dt
	_apply_death_zoom()
	if death_time < DEATH_SLOWMO: _sink_music()
	if before < DEATH_SLOWMO and death_time >= DEATH_SLOWMO:
		results.show_death(_tally())
		sound.cut(.12)
		_play_death_music()

func _apply_death_zoom() -> void:
	# Snap onto the body, then keep creeping in and rolling while the world crawls.
	var zoom_in := 1.0-pow(1.0-clampf(death_time/DEATH_ZOOM_IN,0,1),3)
	var push := smoothstep(0.0,DEATH_SLOWMO,death_time)
	var size := lerpf(view_current,CAMERA_SIZE*(1.0-DEATH_ZOOM)*(1.0-DEATH_PUSH*push),zoom_in)
	var focus := _inside_scenery(Vector3(sim.player.p.x,1.0,sim.player.p.y),size)
	_frame(_view_focus(view_current).lerp(focus,zoom_in),size)
	camera.basis = camera_basis.rotated(camera_basis.z,deg_to_rad(DEATH_ROLL)*push*zoom_in)

func _tally() -> Dictionary:
	return {"kills":sim.kills,"total":sim.enemies.size(),"time":sim.elapsed,"attempt":sim.attempt,"title":sim.layout.get("cleared",""),
		"guests":sim.civilians.size(),"guests_killed":sim.civilians_killed}

func time_scale() -> float:
	if death_time >= 0:
		# The death beat: the world drops to a crawl at once and stays there until the screen.
		return lerpf(1.0,DEATH_SCALE,clampf(death_time/.1,0,1)) if death_time < DEATH_SLOWMO else 1.0
	# Slow motion only once the zoom is complete, easing back to full speed at its end.
	var t := kill_time-ZOOM_IN_TIME
	if kill_time < 0 or t < 0 or t >= SLOWMO_TIME: return 1.0
	return lerpf(1.0,SLOWMO_SCALE,clampf((SLOWMO_TIME-t)/SLOWMO_EASE,0,1))

func _apply_kill_zoom() -> void:
	# Zoom toward the player so the hero and the aim stay put on screen.
	var amount := KILL_ZOOM*kill_zoom
	var focus := Vector3(sim.player.p.x,1.0,sim.player.p.y)
	_frame(_view_focus(view_current).lerp(focus,amount),view_current*(1.0-amount))

func zoom_view(steps: int) -> void:
	## Mouse wheel: negative steps come closer, positive go back out to the full view.
	view_size = clampf(view_size+steps*PLAYER_ZOOM_STEP,PLAYER_ZOOM_MIN,CAMERA_SIZE)

func _view_focus(size: float) -> Vector3:
	## Centre of the gameplay view at this size: on the hero, slid so the view never leaves the
	## full one. At CAMERA_SIZE it is CAMERA_TARGET itself.
	var view := get_viewport().get_visible_rect().size
	var pitch := (CAMERA_TARGET-CAMERA_HOME).angle_to(Vector3(0,0,-1))
	var spare_x := (CAMERA_SIZE-size)*view.x/view.y/2.0
	var spare_z := (CAMERA_SIZE-size)/2.0/sin(pitch)
	return Vector3(clampf(sim.player.p.x,CAMERA_TARGET.x-spare_x,CAMERA_TARGET.x+spare_x),CAMERA_TARGET.y,
		clampf(sim.player.p.y,CAMERA_TARGET.z-spare_z,CAMERA_TARGET.z+spare_z))

func _update_phase_view(dt: float) -> void:
	# While intangible the world drains of colour behind a faint spectral tint.
	if sim.state == "paused": return
	var target := 1.0 if sim.player.phasing else 0.0
	phase_view = lerpf(phase_view,target,1.0-exp(-12.0*dt))
	_apply_phase_view()

func _apply_phase_view() -> void:
	world_environment.adjustment_saturation = 1.0-.55*phase_view
	world_environment.adjustment_brightness = 1.0-.1*phase_view
	phase_tint.color.a = .08*phase_view

func update_ui() -> void:
	if not hud: return
	var gun := sim.stats()
	hud.refresh({"kills":sim.kills,"total":sim.enemies.size(),"elapsed":sim.elapsed,"weapon":gun.name,"melee":sim.player.melee,
		"ammo":sim.player.ammo,"magazine":gun.magazine,"reload":sim.player.reload,"reload_time":gun.reload,
		"mana":sim.player.mana,"phasing":sim.player.phasing,"locked":sim.player.locked,"god":sim.god,"cleared":sim.cleared(),"exit_hint":sim.layout.get("exit_hint",""),
		# Out of the way for the walk-in, the briefing and the death beat.
		"active":sim.state in ["playing","paused"]})
	if last_state == sim.state: return
	last_state = sim.state
	overlay.visible = sim.state in ["ready","paused"]
	if sim.state == "dead": death_time = 0.0   # the death screen waits for the death beat
	elif sim.state == "won":
		# A stage of the Síndico goes straight on to the next one, no screen and no room between.
		if sim.layout.get("chain",false): _next_stage.call_deferred()
		else:
			_fade_music(.15)
			_play_cue(NIGHT_CLEAR)
			results.show_win(_tally())
	else: results.hide_screen()
	match sim.state:
		"ready": overlay.show_briefing(sim.layout.briefing)
		"paused": overlay.show_pause()
