extends TextureRect
## Behind the main menu: Lapa at night, the Bar do Arco cordoned off under the Arcos and the hero
## waiting on the pavement. Rendered small and enlarged without smoothing, so the menu reads as a
## still from the game; the camera breathes, the police light sweeps the facades, and now and then
## the hero slips into the spectre for a moment.
const ActorVisual = preload("res://scripts/actor_visual.gd")
const Main = preload("res://scripts/main.gd")
const SCALE := 3                      # how many window pixels each rendered pixel covers
const EYE := Vector3(-1.0,1.3,16.5)
const LOOK := Vector3(-9.0,1.9,8.5)
const HERO := Vector2(-6.2,9.5)
const DOOR := Vector2(-8.9,7.9)       # he watches the cordoned-off front door
const SIREN := Vector3(-12.2,1.7,12.45)   # the police car's light bar (tools/build_intro.py)
const SPECTRE_EVERY := 9.0
const SPECTRE_FOR := 1.6

var view: SubViewport
var camera: Camera3D
var hero
var hero_data: Dictionary
var sirens: Array[OmniLight3D] = []
var time := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	view = SubViewport.new()
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	_fit()
	get_viewport().size_changed.connect(_fit)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("0b0f18")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8f9cc0")
	environment.ambient_light_energy = .45
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled = true
	environment.fog_light_color = Color("1a2236")
	environment.fog_density = .012
	world.environment = environment
	view.add_child(world)
	for path in ["res://assets/environment/lapa.glb","res://assets/intro/street.glb"]:
		var set_piece := (load(path) as PackedScene).instantiate() as Node3D
		view.add_child(set_piece)
		_crisp(set_piece)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55,-35,0)
	moon.light_color = Color("c9d4f0")
	moon.light_energy = .5
	view.add_child(moon)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Main.Simulation.LEVELS[0]))
	for lamp in Main.level_lamps(layout): _light(lamp[0],Color(lamp[1]),lamp[2],lamp[3])
	for color in ["ff2020","2a5cff"]: sirens.append(_light(SIREN,Color(color),0.0,9.0))
	camera = Camera3D.new()
	camera.fov = 38
	camera.far = 160
	view.add_child(camera)
	camera.current = true
	hero = ActorVisual.new()
	view.add_child(hero)
	hero.setup("res://assets/characters/hero.glb")
	hero_data = {"p":HERO,"angle":atan2(DOOR.y-HERO.y,DOOR.x-HERO.x),"alive":true,"moving":false,"velocity":Vector2.ZERO,
		"recoil":0.0,"reload":0.0,"phasing":false,"mana":100.0}
	advance(0.0)

## The small render follows the window, always enlarged by the same amount.
func _fit() -> void:
	var window := get_viewport().get_visible_rect().size
	view.size = Vector2i(maxi(160,int(window.x/SCALE)),maxi(100,int(window.y/SCALE)))
	texture = view.get_texture()

func _process(delta: float) -> void:
	advance(delta)

func advance(dt: float) -> void:
	time += dt
	# Someone watching from across the street: a slow breath, never a cut.
	var breath := Vector3(sin(time*.21)*.35,sin(time*.33)*.08,cos(time*.17)*.25)
	camera.look_at_from_position(EYE+breath,LOOK+Vector3(sin(time*.13)*.2,0,0))
	# The police light turns: red and blue taking turns, slow enough to read as a sweep.
	var turn := fmod(time*1.4,1.0)
	sirens[0].light_energy = 2.4*smoothstep(.0,.15,turn)*(1.0-smoothstep(.35,.5,turn))
	sirens[1].light_energy = 2.4*smoothstep(.5,.65,turn)*(1.0-smoothstep(.85,1.0,turn))
	hero_data.phasing = fmod(time,SPECTRE_EVERY) > SPECTRE_EVERY-SPECTRE_FOR
	hero.sync(hero_data,dt,false)

func _light(position: Vector3,color: Color,energy: float,reach: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = .8
	view.add_child(light)
	return light

func _crisp(root: Node) -> void:
	for node in root.find_children("*","MeshInstance3D",true,false):
		for surface in node.mesh.get_surface_count():
			var mat := node.mesh.surface_get_material(surface) as BaseMaterial3D
			if mat:
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				mat.roughness = 1.0
				mat.metallic = 0.0
