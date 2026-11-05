extends Node3D
## A clue waiting to be picked up, in the exit's voice but smaller and amber: a stepped glow on the
## floor around its spot and a paper card turning above it. No lamp of its own: the levels already
## use the 8 lights an object can take (7 lamps and the exit). A clue carried by an enemy shows up
## on his body once he is down. Presentation only: the simulation decides where it lies
## (Simulation.clue_spot) and when it is taken.
const LIGHT := preload("res://shaders/exit_light.gdshader")
const COLOR := Color(1.0,.78,.32)
const MARGIN := .45
const DROP := Vector2(.8,.8)    # the glow under a body that carries one

var floor_material: ShaderMaterial
var ground: MeshInstance3D
var card: MeshInstance3D
var clock := 0.0
var size := DROP

func setup(area: Rect2) -> void:
	size = area.size if area.size != Vector2.ZERO else DROP
	var plane := PlaneMesh.new()
	plane.size = size+Vector2.ONE*MARGIN*2
	floor_material = ShaderMaterial.new()
	floor_material.shader = LIGHT
	floor_material.set_shader_parameter("glow",COLOR)
	floor_material.set_shader_parameter("half_size",size/2)
	floor_material.set_shader_parameter("plane_size",plane.size)
	ground = MeshInstance3D.new()
	ground.name = "ClueGlow"
	ground.mesh = plane
	ground.material_override = floor_material
	ground.position.y = .075
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)
	var paper := StandardMaterial3D.new()
	paper.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paper.albedo_color = Color("fff1c8")
	var box := BoxMesh.new()
	box.size = Vector3(.3,.02,.22)
	card = MeshInstance3D.new()
	card.name = "ClueCard"
	card.mesh = box
	card.material_override = paper
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(card)
	visible = false

## spot: where the clue lies now, or Vector2.INF while it cannot be taken; shown: not taken yet.
func update(spot: Vector2,shown: bool,dt: float,paused: bool) -> void:
	visible = shown and spot != Vector2.INF
	if not visible: return
	position = Vector3(spot.x,0,spot.y)
	if paused: return
	clock += dt
	var breath := .75+.25*sin(clock*4.0)
	floor_material.set_shader_parameter("strength",breath)
	card.position.y = 1.05+.08*sin(clock*2.2)
	card.rotation = Vector3(.5,clock*1.6,0)
