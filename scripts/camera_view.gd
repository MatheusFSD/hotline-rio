extends Node3D
## Presentation only: the security cameras of sim.cameras. Each is a small housing on a wall
## bracket with a red light, and its cone painted on the floor, cut short by whatever solid stands
## in the way, as the simulation sees it. Amber while it watches, red while it sees the hero,
## gone when it is broken (the housing hangs dead from its bracket). No lights: unlit geometry.
const MOUNT := 2.3
const RAYS := 14
const WATCH := Color(1.0,.62,.18,.16)
const SEEN := Color(1.0,.16,.12,.36)

var sim
var units: Array[Node3D] = []
var cones: Array[MeshInstance3D] = []
var cone_material := StandardMaterial3D.new()
var housing_material := StandardMaterial3D.new()
var lens_material := StandardMaterial3D.new()
var led_material := StandardMaterial3D.new()
var cube := BoxMesh.new()
var clock := 0.0

func setup(simulation) -> void:
	sim = simulation
	cube.size = Vector3.ONE
	cone_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cone_material.vertex_color_use_as_albedo = true
	cone_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	cone_material.render_priority = 1
	housing_material.albedo_color = Color("d8d8d2")
	lens_material.albedo_color = Color("141618")
	led_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	led_material.albedo_color = Color("ff3020")
	rebuild()

func rebuild() -> void:
	for node in units+cones: node.queue_free()
	units.clear()
	cones.clear()
	for camera in sim.cameras:
		var unit := Node3D.new()
		unit.position = Vector3(camera.p.x,MOUNT,camera.p.y)
		add_child(unit)
		var head := Node3D.new()
		head.name = "head"
		unit.add_child(head)
		_part(unit,lens_material,Vector3(0,.12,0),Vector3(.05,.24,.05))          # bracket down from the ceiling line
		_part(head,housing_material,Vector3(.12,0,0),Vector3(.32,.13,.14))       # housing, pointing along +x
		_part(head,lens_material,Vector3(.29,0,0),Vector3(.03,.1,.1))            # lens
		_part(head,led_material,Vector3(.02,.08,0),Vector3(.04,.03,.04),"led")
		units.append(unit)
		var cone := MeshInstance3D.new()
		cone.mesh = ImmediateMesh.new()
		cone.material_override = cone_material
		cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(cone)
		cones.append(cone)

func _part(parent: Node3D,mat: Material,at: Vector3,size: Vector3,name := "") -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = cube
	mesh.material_override = mat
	mesh.position = at
	mesh.scale = size
	if name != "": mesh.name = name
	parent.add_child(mesh)
	return mesh

func update(dt: float,paused: bool) -> void:
	if not paused: clock += dt
	if units.size() != sim.cameras.size(): rebuild()
	for i in units.size():
		var camera: Dictionary = sim.cameras[i]
		var head: Node3D = units[i].get_node("head")
		head.rotation = Vector3(0,-float(camera.angle),0) if camera.alive else Vector3(0,-float(camera.base),-1.1)
		head.get_node("led").visible = camera.alive and (camera.seeing or fmod(clock,1.2) < .15)
		var mesh: ImmediateMesh = cones[i].mesh
		mesh.clear_surfaces()
		if not camera.alive: continue
		# The floor it watches: a fan of rays, each stopped at the first solid.
		var color: Color = SEEN if camera.seeing else WATCH
		var origin: Vector2 = camera.p
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var previous := Vector2.INF
		for k in RAYS+1:
			var a: float = camera.angle-camera.fov+2.0*camera.fov*k/RAYS
			var reach: Vector2 = origin+Vector2.from_angle(a)*camera.range
			var t: float = sim.wall_hit(origin,reach)
			var end: Vector2 = origin.lerp(reach,minf(t,1.0)) if t != INF else reach
			if previous != Vector2.INF:
				for v in [origin,previous,end]:
					mesh.surface_set_color(Color(color,color.a*(1.0 if v != origin else 1.6)))
					mesh.surface_add_vertex(Vector3(v.x,.07,v.y))
			previous = end
		mesh.surface_end()
