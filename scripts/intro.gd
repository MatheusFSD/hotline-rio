class_name LapaIntro
extends CanvasLayer
## Opening police bulletin, "Alerta Rio", about the ghost vigilante of Lapa, watched on an
## old tube TV. The newscast renders into a 4:3 SubViewport shown through a CRT shader and
## framed by a TV set in a dark room. Presentation only: finishing or skipping emits `finished`.
signal finished
const ActorVisual = preload("res://scripts/actor_visual.gd")
const CRT = preload("res://shaders/crt.gdshader")
const MOSAIC = preload("res://shaders/mosaic.gdshader")
const ResultScreen = preload("res://scripts/result_screen.gd")
const DURATION := 35.5
const POWER_OFF := 31.0
## After the set goes dark: where the first night stands in the story.
const EPILOGUE := "26 DE OUTUBRO.\nCATORZE DIAS DEPOIS DO BECO."
const EPILOGUE_AT := 31.9
const RESOLUTION := Vector2i(640,480)
const SCREEN_RECT := Rect2(206,116,688,516)
const STUDIO := Vector3(300,0,0)
const ANCHOR_START := Vector3(-3.4,0,-.8)
const ANCHOR_MARK := Vector3(-.4,0,.3)
const WITNESS_SPOT := Vector3(-16.6,.07,9.3)
const COP_SPOT := Vector3(-10.0,.07,9.6)
const SIREN := Vector3(-12.2,1.7,12.45)
## Shot list: start time, shot, headline on the lower third ("" hides it).
const SHOTS := [
	[0.0,"plantao",""],
	[3.2,"anchor_medium","PLANTÃO: TIROTEIO NA LAPA"],
	[9.0,"anchor_close","VIGILANTE FANTASMA ATERRORIZA A LAPA"],
	[12.0,"cctv","IMAGENS DA CÂMERA DE SEGURANÇA DO BAR"],
	[17.0,"witness","TESTEMUNHA: \"ELE PASSOU PELA PAREDE\""],
	[20.5,"cop","TEN. ELIAS SOUZA — POLÍCIA MILITAR"],
	[23.5,"anchor_point","8 SUSPEITOS ARMADOS NO BAR DO ARCO"],
	[29.5,"outro",""]]
## Closed captions stand in for the audio: start, end, line.
const CAPTIONS := [
	[3.4,5.8,"BOA NOITE! CORTA PRA MIM, CORTA PRA MIM!"],
	[5.8,9.0,"OLHA O QUE TÁ ACONTECENDO AGORA NA LAPA, MINHA GENTE!"],
	[9.1,12.0,"TESTEMUNHAS FALAM DE UM VIGILANTE FANTASMA!"],
	[12.2,14.6,"OLHA A IMAGEM! OLHA A IMAGEM!"],
	[14.6,17.0,"ELE ATRAVESSA O BALCÃO COMO SE NÃO FOSSE NADA!"],
	[17.2,20.4,"[TESTEMUNHA] ELE PASSOU PELA PAREDE, MOÇO! TAVA TODO AZUL!"],
	[20.7,23.4,"[POLICIAL] ÁREA ISOLADA. SÃO OITO ELEMENTOS ARMADOS LÁ DENTRO."],
	[23.7,26.2,"OITO BANDIDOS NO BAR DO ARCO... E UM FANTASMA SOLTO NA LAPA!"],
	[26.2,29.4,"VOCÊ QUE TÁ EM CASA: NÃO SAI DE CASA!"]]
const TICKER := "PM CERCA BAR NA LAPA   •   BAR DO ARCO: DONO HOSPITALIZADO   •   MORADORES RELATAM \"HOMEM QUE ATRAVESSA PAREDE\"   •   RUA DO RIACHUELO INTERDITADA   •   BONDE DE SANTA TERESA SUSPENSO   •   "

var time := 0.0
var done := false
var lamps: Array
var current_shot := ""
var viewport: SubViewport
var camera: Camera3D
var environment: Environment
var crt: ShaderMaterial
var room_glow: TextureRect
var anchor: Dictionary
var witness: Dictionary
var cop: Dictionary
var ghost
var gunman
var ghost_data: Dictionary
var gunman_data: Dictionary
var alarm: OmniLight3D
var sirens: Array[OmniLight3D] = []
var heavy := SystemFont.new()
var mono := SystemFont.new()
var bug: Control
var live_dot: ColorRect
var lower: Control
var headline: Label
var ticker: Label
var ticker_strip: Control
var caption_box: CenterContainer
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

func _init(world_lamps: Array = []) -> void:
	lamps = world_lamps
	layer = 20

func _ready() -> void:
	heavy.font_names = PackedStringArray(["Arial Black","Impact","Arial"])
	heavy.font_weight = 900
	mono.font_names = PackedStringArray(["Courier New","Consolas","Monospace"])
	mono.font_weight = 700
	_build_world()
	_build_graphics()
	_build_tv()
	_update(0.0)

func _process(delta: float) -> void:
	advance(delta)

func advance(dt: float) -> void:
	if done: return
	time += dt
	if time >= DURATION:
		_finish()
		return
	_update(dt)

func skip() -> void:
	# First press turns the set off; a second one leaves immediately.
	if done: return
	if time < POWER_OFF: time = POWER_OFF
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

static func shot_at(t: float) -> Array:
	var current: Array = SHOTS[0]
	for entry in SHOTS:
		if t >= entry[0]: current = entry
	return current

static func caption_at(t: float) -> String:
	for entry in CAPTIONS:
		if t >= entry[0] and t < entry[1]: return entry[2]
	return ""

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
	for path in ["res://assets/environment/lapa.glb","res://assets/intro/street.glb"]:
		var set_piece := (load(path) as PackedScene).instantiate() as Node3D
		viewport.add_child(set_piece)
		_crisp(set_piece)
	var studio := (load("res://assets/intro/studio.glb") as PackedScene).instantiate() as Node3D
	viewport.add_child(studio)
	studio.position = STUDIO
	_crisp(studio)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55,-35,0)
	moon.light_color = Color("c9d4f0")
	moon.light_energy = .55
	viewport.add_child(moon)
	for lamp in lamps: _light(lamp[0],Color(lamp[1]),lamp[2],lamp[3])
	# Studio: warm key, blue fill, red rim, and a red alarm that pulses during the plantão.
	_light(STUDIO+Vector3(.6,2.6,2.6),Color("fff1d8"),2.2,7.0)
	_light(STUDIO+Vector3(-3.5,2.2,2.0),Color("6f8cff"),1.2,6.0)
	_light(STUDIO+Vector3(.4,2.8,-2.2),Color("ff3030"),1.6,5.0)
	alarm = _light(STUDIO+Vector3(0,3.4,1.0),Color("ff1a1a"),0.0,9.0)
	for color in ["ff2020","2a5cff"]: sirens.append(_light(SIREN,Color(color),0.0,7.5))
	anchor = _person("res://assets/intro/anchor.glb",STUDIO+ANCHOR_START)
	_add_tie(anchor)
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

func _person(path: String,position: Vector3) -> Dictionary:
	var model := (load(path) as PackedScene).instantiate() as Node3D
	viewport.add_child(model)
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
	var entry := shot_at(time)
	var local: float = time-entry[0]
	if entry[1] != current_shot:
		current_shot = entry[1]
		_enter_shot(current_shot)
	_frame_shot(current_shot,local,dt)
	_update_graphics(entry,local)
	_update_power(local)
	var flashing := fmod(time*2.5,1.0) < .5
	sirens[0].light_energy = 2.6 if flashing else 0.0
	sirens[1].light_energy = 0.0 if flashing else 2.6

func _enter_shot(name: String) -> void:
	var cctv_look := name == "cctv"
	# Dim, contrasty security footage in which the glowing spectre stands out.
	environment.adjustment_saturation = .6 if cctv_look else 1.0
	environment.adjustment_contrast = 1.45 if cctv_look else 1.0
	environment.adjustment_brightness = .72 if cctv_look else 1.0
	if name == "cctv":
		ghost_data.p = Vector2(-8.3,-2.6)
		ghost.clear_effects()

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
	if time >= POWER_OFF:
		var k := time-POWER_OFF
		flash = smoothstep(0.0,.25,k)
		open_y = lerpf(1.0,.006,smoothstep(0.0,.3,k))
		open_x = lerpf(1.0,0.0,smoothstep(.3,.6,k))
		snow = .3
	crt.set_shader_parameter("open_x",open_x)
	crt.set_shader_parameter("open_y",open_y)
	crt.set_shader_parameter("flash",flash)
	crt.set_shader_parameter("static_amount",snow)
	room_glow.modulate.a = open_x*open_y*.85
	epilogue.visible = time >= EPILOGUE_AT
	if epilogue.visible: epilogue_line.visible_ratio = clampf((time-EPILOGUE_AT-.3)*28.0/EPILOGUE.length(),0,1)

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
	bug.add_child(_text("COM JAIRO TROVÃO",10,Color.WHITE,heavy,Vector2(24,46)))
	_box(Color("c4161c"),Rect2(526,16,98,22),bug)
	live_dot = _box(Color.WHITE,Rect2(533,23,8,8),bug)
	bug.add_child(_text("AO VIVO",13,Color.WHITE,heavy,Vector2(546,18)))
	bug.add_child(_text("23:52",14,Color.WHITE,heavy,Vector2(570,40)))
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
	ticker = _text(tr(TICKER)+tr(TICKER),14,Color.WHITE,heavy,Vector2(0,4))
	clip.add_child(ticker)
	_box(Color("c4161c"),Rect2(0,436,104,26),ticker_strip)
	ticker_strip.add_child(_text("PLANTÃO",13,Color("ffd21a"),heavy,Vector2(14,441)))
	# Closed captions: white capitals on a black box.
	caption_box = CenterContainer.new()
	caption_box.position = Vector2(0,300)
	caption_box.size = Vector2(640,44)
	caption_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(caption_box)
	caption = _text("",15,Color.WHITE,mono)
	var black := StyleBoxFlat.new()
	black.bg_color = Color(0,0,0,.88)
	black.content_margin_left = 8
	black.content_margin_right = 8
	black.content_margin_top = 3
	black.content_margin_bottom = 3
	caption.add_theme_stylebox_override("normal",black)
	caption_box.add_child(caption)

func _update_graphics(entry: Array,local: float) -> void:
	var name: String = entry[1]
	plantao.visible = name == "plantao" and time > .9
	plantao_band.color = Color("c4161c") if fmod(time*4.0,1.0) < .5 else Color("7d0b10")
	plantao_word.visible = fmod(time*3.0,1.0) < .72
	outro.visible = name == "outro"
	cctv.visible = name == "cctv"
	rec.visible = fmod(time*2.0,1.0) < .6
	cctv_clock.text = "26/10/2026  23:47:%02d" % (12+int(local))
	bug.visible = name != "outro"
	live_dot.visible = fmod(time*1.5,1.0) < .6
	lower.visible = entry[2] != "" and local > .35
	headline.text = entry[2]
	ticker_strip.visible = name not in ["plantao","outro"]
	ticker.position.x = -fposmod(time*72.0,ticker.get_minimum_size().x/2.0)
	caption.text = caption_at(time)
	caption_box.visible = caption.text != ""
	mosaic.visible = name == "witness"
	if mosaic.visible:
		var skeleton: Skeleton3D = witness.skeleton
		var head := skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin
		var center := camera.unproject_position(head+Vector3(0,.09,0))
		mosaic.position = center-mosaic.size/2
	var glow := {"plantao":Color("ff2a2a"),"cctv":Color("7dffa0"),"witness":Color("5a7dff"),"cop":Color("ff4a4a"),"outro":Color("ffd21a")}
	room_glow.self_modulate = glow.get(name,Color("9fc4ff"))

# ---------------------------------------------------------------- the TV set
func _build_tv() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	_box(Color("0a0b0f"),Rect2(0,0,1280,800),root)
	# Light thrown on the wall by the screen.
	var gradient := Gradient.new()
	gradient.set_color(0,Color(1,1,1,.32))
	gradient.set_color(1,Color(1,1,1,0))
	var radial := GradientTexture2D.new()
	radial.gradient = gradient
	radial.fill = GradientTexture2D.FILL_RADIAL
	radial.fill_from = Vector2(.5,.5)
	radial.fill_to = Vector2(1,.5)
	room_glow = TextureRect.new()
	room_glow.texture = radial
	room_glow.position = Vector2(-60,-180)
	room_glow.size = Vector2(1400,1100)
	room_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(room_glow)
	# Wooden rack under the set.
	_box(Color("3a2416"),Rect2(0,706,1280,94),root)
	_box(Color("5b3a24"),Rect2(0,706,1280,7),root)
	_box(Color("2a190f"),Rect2(0,752,1280,3),root)
	# Rabbit-ear antenna with steel wool on one tip.
	for tip in [Vector2(452,4),Vector2(780,12)]:
		var rod := Line2D.new()
		rod.points = PackedVector2Array([Vector2(616,60),tip])
		rod.width = 4
		rod.default_color = Color("8e9196")
		root.add_child(rod)
	var wool := Panel.new()
	wool.position = Vector2(766,0)
	wool.size = Vector2(30,22)
	wool.add_theme_stylebox_override("panel",_style(Color("9a9a96"),11,0,Color.BLACK))
	root.add_child(wool)
	var base := Panel.new()
	base.position = Vector2(586,44)
	base.size = Vector2(60,18)
	base.add_theme_stylebox_override("panel",_style(Color("1c1c1f"),6,0,Color.BLACK))
	root.add_child(base)
	# Cabinet, bezel and the picture tube.
	var cabinet := Panel.new()
	cabinet.position = Vector2(150,58)
	cabinet.size = Vector2(980,650)
	var cabinet_style := _style(Color("26262a"),34,3,Color("3c3c42"))
	cabinet_style.shadow_color = Color(0,0,0,.7)
	cabinet_style.shadow_size = 36
	cabinet.add_theme_stylebox_override("panel",cabinet_style)
	root.add_child(cabinet)
	var bezel := Panel.new()
	bezel.position = Vector2(188,98)
	bezel.size = Vector2(724,552)
	bezel.add_theme_stylebox_override("panel",_style(Color("0a0a0b"),26,5,Color("17171a")))
	root.add_child(bezel)
	var screen := TextureRect.new()
	screen.texture = viewport.get_texture()
	screen.position = SCREEN_RECT.position
	screen.size = SCREEN_RECT.size
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_SCALE
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt = ShaderMaterial.new()
	crt.shader = CRT
	screen.material = crt
	root.add_child(screen)
	var sheen := Gradient.new()
	sheen.set_color(0,Color(1,1,1,.07))
	sheen.set_color(1,Color(1,1,1,0))
	var sheen_texture := GradientTexture2D.new()
	sheen_texture.gradient = sheen
	sheen_texture.fill_from = Vector2(0,0)
	sheen_texture.fill_to = Vector2(.55,.6)
	var glass := TextureRect.new()
	glass.texture = sheen_texture
	glass.position = SCREEN_RECT.position
	glass.size = SCREEN_RECT.size
	glass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(glass)
	# Control column: brand, dials, channel keys, speaker grille and the power lamp.
	var brand := _text("TELERIO",28,Color("c9cad0"),heavy,Vector2(944,108))
	root.add_child(brand)
	var colour := RichTextLabel.new()
	colour.bbcode_enabled = true
	colour.text = "[color=#e8443a]C[/color][color=#f2b632]O[/color][color=#5fc35a]L[/color][color=#3f8fe0]O[/color][color=#b065d8]R[/color]"
	colour.position = Vector2(948,148)
	colour.size = Vector2(120,24)
	colour.scroll_active = false
	colour.add_theme_font_override("normal_font",heavy)
	colour.add_theme_font_size_override("normal_font_size",15)
	colour.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(colour)
	for entry in [[Vector2(1020,236),34.0,"CANAL",.6],[Vector2(1020,338),28.0,"VOLUME",-.9]]:
		var dial := Dial.new()
		dial.position = entry[0]
		dial.radius = entry[1]
		dial.angle = entry[3]
		root.add_child(dial)
		root.add_child(_text(entry[2],11,Color("7d7e86"),heavy,entry[0]+Vector2(-24,entry[1]+6)))
	for i in 6:
		var key := Panel.new()
		key.position = Vector2(944+i*26,410)
		key.size = Vector2(20,14)
		key.add_theme_stylebox_override("panel",_style(Color("3a3a40"),3,1,Color("4c4c54")))
		root.add_child(key)
	for i in 20: _box(Color("141416"),Rect2(944,446+i*10,156,5),root)
	var lamp := Dial.new()
	lamp.position = Vector2(1092,676)
	lamp.radius = 5
	lamp.lamp = true
	root.add_child(lamp)
	root.add_child(_text("POWER",10,Color("7d7e86"),heavy,Vector2(1030,668)))
	var hint := _text("ENTER OU CLIQUE — PULAR",14,Color("8a8478"),heavy,Vector2(1010,766))
	root.add_child(hint)
	# Once the set is off: the date, typed out in the HUD's terminal font, before the first night.
	epilogue = Control.new()
	epilogue.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	epilogue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(epilogue)
	_box(Color("07050a"),Rect2(0,0,1280,800),epilogue)
	epilogue_line = _text(EPILOGUE,40,Color("f4efe1"),ResultScreen.DIGIT_FONT,Vector2(0,330))
	epilogue_line.size = Vector2(1280,140)
	epilogue_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	epilogue.add_child(epilogue_line)
	epilogue.hide()

func _style(color: Color,radius: int,border: int,border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border)
	style.border_color = border_color
	return style

class Dial extends Control:
	## Round TV knob, or the red power lamp.
	var radius := 30.0
	var angle := 0.0
	var lamp := false
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if lamp:
			draw_circle(Vector2.ZERO,radius*2.2,Color(1,.15,.1,.18))
			draw_circle(Vector2.ZERO,radius,Color("ff3b2f"))
			return
		draw_circle(Vector2.ZERO,radius+5,Color("141416"))
		draw_circle(Vector2.ZERO,radius,Color("3b3b41"))
		draw_circle(Vector2.ZERO,radius*.72,Color("2d2d32"))
		for i in 12:
			var a := TAU*i/12
			draw_line(Vector2.from_angle(a)*(radius+7),Vector2.from_angle(a)*(radius+11),Color("55555c"),2)
		draw_line(Vector2.ZERO,Vector2.from_angle(angle-PI/2)*radius*.85,Color("d8d8de"),4)
