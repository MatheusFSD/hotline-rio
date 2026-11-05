extends Node3D
## Presentation only: helps a living fighter read against the scenery from the far camera.
## A stepped PS1 contact shadow under the hips, a faint banded rim on the silhouette (cool for
## the hero, warm for the gunmen) and a render layer that the level's figure light picks up.
## The dead lose all three and settle into the scene. Nothing here touches the simulation,
## animation timing or collision; ActorVisual only gains one when the level asks for it.
const FIGURE_LAYER := 2   # render layer lit by main.gd's figure light, on top of the scene's lights
const RIM := preload("res://shaders/figure_rim.gdshader")
const HERO_RIM := Color("8fe8e2")    # the spectre's cyan, held way down
const ENEMY_RIM := Color("ffc7a1")   # warm, like the bar lamps
const RIM_STRENGTH := .26
const HERO_RIM_STRENGTH := .42
const GOD_RIM := Color("ffd23f")      # modo deus: the hero outlined in gold
const GOD_RIM_STRENGTH := .8
const AVESSO_RIM := Color("9b5cff")   # Olho do Avesso: what lives in the casca, seen from the spectre
const AVESSO_RIM_STRENGTH := 1.0
const HERO_FRINGE := Color(.42,.95,.9,.36)   # spectral residue at the edge of the hero's shadow
const SHADOW_SIZE := 1.1
const SHADOW_ALPHA := .62
const SHADOW_PHASING := .15   # an intangible body barely darkens the floor
const SHADOW_HEIGHT := .085   # above every floor slab (the pavement tops out at .07)
const FADE := 5.0

var visual
var rim: ShaderMaterial
var shadow: MeshInstance3D
var shadow_material: StandardMaterial3D
var presence := 1.0
var figure := false
var pelvis := -1
var rim_strength := RIM_STRENGTH
var base_rim := ENEMY_RIM
var base_strength := RIM_STRENGTH
var golden := false
var revealed := false

func setup(owner_visual: Node3D,hero: bool) -> void:
	visual = owner_visual
	pelvis = visual.skeleton.find_bone("pelvis")
	base_strength = HERO_RIM_STRENGTH if hero else RIM_STRENGTH
	base_rim = HERO_RIM if hero else ENEMY_RIM
	rim_strength = base_strength
	rim = ShaderMaterial.new()
	rim.shader = RIM
	rim.set_shader_parameter("rim_color",base_rim)
	# The skin materials are the actor's own copies, so the rim never leaks to other actors.
	for node in visual.model.find_children("*","MeshInstance3D",true,false):
		for surface in node.get_surface_override_material_count():
			var mat := node.get_surface_override_material(surface) as BaseMaterial3D
			if mat: mat.next_pass = rim
	var blob := Gradient.new()
	# A firm core right under the feet, then lighter steps outward, like the furniture's contact shade.
	if hero:
		blob.offsets = PackedFloat32Array([0.0,.3,.55,.8,1.0])
		blob.colors = PackedColorArray([Color(0,0,0,1),Color(0,0,0,.8),Color(0,0,0,.4),HERO_FRINGE,Color(HERO_FRINGE,0)])
	else:
		blob.offsets = PackedFloat32Array([0.0,.3,.62,1.0])
		blob.colors = PackedColorArray([Color(0,0,0,1),Color(0,0,0,.8),Color(0,0,0,.35),Color(0,0,0,0)])
	var texture := GradientTexture2D.new()
	texture.gradient = blob
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(.5,.5)
	texture.fill_to = Vector2(1,.5)
	texture.width = 16   # sampled nearest: a stepped, low-res blob
	texture.height = 16
	shadow_material = StandardMaterial3D.new()
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	shadow_material.albedo_texture = texture
	shadow_material.albedo_color = Color(1,1,1,SHADOW_ALPHA)   # the gradient carries the colour
	var plane := PlaneMesh.new()
	plane.size = Vector2(SHADOW_SIZE,SHADOW_SIZE)
	shadow = MeshInstance3D.new()
	shadow.name = "ContactShadow"
	shadow.mesh = plane
	shadow.material_override = shadow_material
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.top_level = true
	add_child(shadow)
	_set_figure(true)

func refresh() -> void:
	## A new weapon model joins the figure layer too.
	_set_figure(figure)

func _set_figure(alive: bool) -> void:
	figure = alive
	rim.set_shader_parameter("strength",rim_strength if alive else 0.0)
	var layers := 1 | (1 << (FIGURE_LAYER-1)) if alive else 1
	for node in visual.model.find_children("*","MeshInstance3D",true,false): node.layers = layers

func update(data: Dictionary,dt: float,paused: bool) -> void:
	# Gold for the hero in modo deus, and for the Síndico, whatever casca he wears.
	var gilded: bool = bool(data.get("god",false)) or bool(data.get("sindico",false))
	if gilded != golden or bool(data.get("revealed",false)) != revealed:
		golden = gilded
		revealed = bool(data.get("revealed",false))
		rim.set_shader_parameter("rim_color",GOD_RIM if golden else (AVESSO_RIM if revealed else base_rim))
		rim_strength = GOD_RIM_STRENGTH if golden else (AVESSO_RIM_STRENGTH if revealed else base_strength)
		_set_figure(figure)
	if bool(data.alive) != figure: _set_figure(data.alive)
	if not paused:
		var target := (SHADOW_PHASING if visual.phasing else 1.0) if data.alive else 0.0
		if data.get("kind","human") != "human": target = 0.0   # what lives in the Avesso casts no shadow
		presence = move_toward(presence,target,dt*FADE)
	shadow_material.albedo_color.a = SHADOW_ALPHA*presence
	shadow.visible = presence > .01
	# Under the hips, so leans, kicks and the minigun stance carry it along.
	var hips: Vector3 = visual.skeleton.global_transform*visual.skeleton.get_bone_global_pose(pelvis).origin
	shadow.global_position = Vector3(hips.x,SHADOW_HEIGHT,hips.z)
