extends Node3D
## The level's exit, invisible until every enemy is down. Then light comes out of the ground:
## the stepped floor glow traced around the exit rectangle, a curtain of light rising from its
## edges, motes drifting up and a real light that washes the alley. Presentation only: the
## simulation decides when the exit counts, this only shows where it is.
const LIGHT := preload("res://shaders/exit_light.gdshader")
const COLOR := Color(.35,1.0,.82)
const HEIGHT := 2.4      # metres of rising light
const MARGIN := .6       # floor glow spills this far past the rectangle
const REVEAL := .7       # seconds for the light to come up out of the ground
const MOTES := 14

var rect: Rect2
var floor_material: ShaderMaterial
var curtain: MeshInstance3D
var curtain_material: ShaderMaterial
var lamp: OmniLight3D
var motes: Array[MeshInstance3D] = []
var reveal := 0.0
var clock := 0.0
var open := false
var rng := RandomNumberGenerator.new()

func setup(exit: Array) -> void:
	rect = Rect2(exit[0],exit[1],exit[2],exit[3])
	var center := rect.get_center()
	position = Vector3(center.x,0,center.y)
	var plane := PlaneMesh.new()
	plane.size = rect.size+Vector2.ONE*MARGIN*2
	floor_material = ShaderMaterial.new()
	floor_material.shader = LIGHT
	floor_material.set_shader_parameter("glow",COLOR)
	floor_material.set_shader_parameter("half_size",rect.size/2)
	floor_material.set_shader_parameter("plane_size",plane.size)
	var ground := MeshInstance3D.new()
	ground.name = "ExitGlow"
	ground.mesh = plane
	ground.material_override = floor_material
	ground.position.y = .07
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)
	curtain_material = ShaderMaterial.new()
	curtain_material.shader = LIGHT
	curtain_material.set_shader_parameter("glow",COLOR)
	curtain_material.set_shader_parameter("curtain",true)
	curtain = MeshInstance3D.new()
	curtain.name = "ExitCurtain"
	curtain.mesh = _walls(rect.size/2)
	curtain.material_override = curtain_material
	curtain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(curtain)
	var mote_material := StandardMaterial3D.new()
	mote_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mote_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mote_material.albedo_color = COLOR
	var quad := QuadMesh.new()
	quad.size = Vector2(.07,.07)
	for i in MOTES:
		var mote := MeshInstance3D.new()
		mote.mesh = quad
		mote.material_override = mote_material
		mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mote)
		_respawn(mote,rng.randf()*HEIGHT)
		motes.append(mote)
	lamp = OmniLight3D.new()
	lamp.light_color = COLOR
	lamp.omni_range = 4.0
	lamp.position.y = .4
	lamp.shadow_enabled = false
	add_child(lamp)
	visible = false

func _walls(half: Vector2) -> ArrayMesh:
	## Four upright quads around the rectangle; UV.y runs 0 at the floor to 1 at the top.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [Vector2(-half.x,-half.y),Vector2(half.x,-half.y),Vector2(half.x,half.y),Vector2(-half.x,half.y)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i+1)%4]
		var quad := [[a,0.0],[b,0.0],[b,1.0],[a,0.0],[b,1.0],[a,1.0]]
		for v in quad:
			st.set_uv(Vector2(float(i),v[1]))
			st.add_vertex(Vector3(v[0].x,v[1]*HEIGHT,v[0].y))
	return st.commit()

func _respawn(mote: MeshInstance3D,height := 0.0) -> void:
	mote.position = Vector3(rng.randf_range(-rect.size.x/2,rect.size.x/2),height,rng.randf_range(-rect.size.y/2,rect.size.y/2))

func update(cleared: bool,dt: float,paused: bool) -> void:
	if cleared != open:
		open = cleared
		reveal = 0.0
	visible = open
	if not open or paused: return
	clock += dt
	reveal = minf(1.0,reveal+dt/REVEAL)
	# Rises out of the floor with a little overshoot; the glow flares as it lands, then breathes.
	var u := reveal-1.0
	curtain.scale.y = maxf(.001,1.0+2.2*u*u*u+1.2*u*u)
	var flare := 2.5*(1.0-reveal)*(1.0-reveal)
	var breath := .9+.12*sin(clock*3.2)
	floor_material.set_shader_parameter("strength",breath+flare)
	curtain_material.set_shader_parameter("strength",breath*reveal)
	lamp.light_energy = (1.1+.15*sin(clock*3.2))*reveal+flare*.6
	for mote in motes:
		mote.position.y += dt*rng.randf_range(.5,.9)
		if mote.position.y > HEIGHT*reveal: _respawn(mote)
		mote.transparency = mote.position.y/HEIGHT
