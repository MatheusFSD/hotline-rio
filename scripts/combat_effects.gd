class_name LapaCombatEffects
extends Node3D
## Bounded, presentation-only effects. The simulation supplies exact hit endpoints.
const MAX_BITS := 240
## Blood stays until the retry: every stain is one instance of a few blots, so the floor of a whole
## night fits. Past the limit, the oldest in that blot's sheet goes.
const STAIN_SHEETS := 3
const STAINS_PER_SHEET := 2000
const MAX_STAINS := STAIN_SHEETS*STAINS_PER_SHEET
const MAX_TRACES := 180
const KNOCKBACK_WEAPONS := ["shotgun","rifle"]
const KNOCKBACK_REACH := .8   # metres the body is thrown back along the shot
## The camera's push, in metres, on top of the shake: against the hero's shot by the gun's own kick, and
## along the shot that kills. It leans first and settles back, so each gun has a direction and a weight.
const KICK_SHOT := .9
const KICK_KILL := .22
const KICK_DEATH := .5
const KICK_MAX := .45
const KICK_RETURN := 16.0     # per second
const KICK_DEPTH := .79       # a metre of depth is this much of a metre on screen, from this camera
const HERO_SHAKE := .6        # his shots shake less than they did: the push says it now
## Blood by what was hit: pool, splash, droplets light and dark, scattered drops. What lives in a
## casca bleeds ink, blue-black (docs/narrativa.md, 4.3).
const BLOOD := {
	"human":[Color("651e2c"),Color("8d2638"),Color("a52d40"),Color("692030"),Color("89273a")],
	"inquilino":[Color("0e0e1a"),Color("1a1a2e"),Color("23233a"),Color("0e0e1a"),Color("17172a")],
	"proprietario":[Color("0e0e1a"),Color("1a1a2e"),Color("23233a"),Color("0e0e1a"),Color("17172a")]}
## The casca rule's leftovers: the tenant of a torn casca, a snuffed shadow-flame, a ripped bag.
const DUST := {
	"unravel":[Color("0e0e1a"),Color("2a1050"),Color("3b3b4a")],
	"wisp_gone":[Color("2a1050"),Color("5a2aa8"),Color("120822")],
	"tear":[Color("15161c"),Color("2b2d36"),Color("0e0e1a")],
	"blackout":[Color("fff2a0"),Color("ffffff"),Color("ffb347")],   # the breaker's sparks
	"camera_down":[Color("ffd36a"),Color("d8d8d2"),Color("2b2d2b")]}   # sparks and bits of housing
var bits: Array[Dictionary] = []
## A bullet stopped by something leaves a hole in it, and breaks off what it is made of; a pane it
## goes through cracks. Holes and cracks stay until the retry, like the blood.
const DEBRIS := {
	"stone":{"colors":[Color("efbb74"),Color("c9bfae"),Color("8f877a"),Color("b4a28b")],"count":7,"size":Vector3(.06,.06,.06),"speed":2.2,"life":.6},
	"wood":{"colors":[Color("c08a52"),Color("8a5a32"),Color("5e3b20")],"count":7,"size":Vector3(.03,.03,.12),"speed":2.4,"life":.9},
	"metal":{"colors":[Color("fff2a0"),Color("ffb347"),Color("ffffff")],"count":9,"size":Vector3(.03,.03,.03),"speed":4.0,"life":.25},
	"soft":{"colors":[Color("d8d2c4"),Color("a89f90")],"count":6,"size":Vector3(.05,.05,.05),"speed":1.0,"life":.7},
	"spark":{"colors":[Color("efbb74"),Color("b4a28b")],"count":5,"size":Vector3(.06,.06,.06),"speed":2.0,"life":.5}}
const HOLE_RIM := {"stone":Color("b3aa9b"),"wood":Color("a87f52"),"metal":Color("d6d2c8")}
const HOLE_SIZE := {"stone":.075,"wood":.06,"metal":.05}
const MAX_HOLES := 1500
const MAX_CRACKS := 400
const SHARDS := [Color("e8f6fb"),Color("bfdde6"),Color("ffffff")]
var holes: MultiMesh
var cracks: MultiMesh
var hole_total := 0
var crack_total := 0
var stain_sheets: Array[MultiMesh] = []
var sheet_used: Array[int] = []
var stain_total := 0
var growing: Array[Dictionary] = []     # pools still spreading
var traces: Array[Dictionary] = []
var fountains: Array[Dictionary] = []   # cut ends that keep spurting for a moment
var slashes: Array[Dictionary] = []     # katana arcs fading out
var rng := RandomNumberGenerator.new()
var gore_rng := RandomNumberGenerator.new()
var materials: Dictionary = {}
var unit_box := BoxMesh.new()
var trail_mesh := ImmediateMesh.new()
var trail_material := StandardMaterial3D.new()
var camera: Camera3D
var shake := 0.0
var shake_clock := 0.0
var kick := Vector2.ZERO
var simulation

func setup(view: Camera3D,sim) -> void:
	camera = view
	simulation = sim
	rng.seed = 7163
	gore_rng.randomize()
	unit_box.size = Vector3.ONE
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_material.vertex_color_use_as_albedo = true
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh := MeshInstance3D.new()
	mesh.mesh = trail_mesh
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	var stain_material := StandardMaterial3D.new()
	stain_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	stain_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	stain_material.vertex_color_use_as_albedo = true
	stain_material.vertex_color_is_srgb = true
	for i in STAIN_SHEETS: _add_stain_sheet(stain_material)
	holes = _mark_sheet(_hole_mesh(),MAX_HOLES,false)
	cracks = _mark_sheet(_crack_mesh(),MAX_CRACKS,true)

func _mark_sheet(mesh: ArrayMesh,count: int,see_through: bool) -> MultiMesh:
	var mark_material := StandardMaterial3D.new()
	mark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mark_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mark_material.vertex_color_use_as_albedo = true
	mark_material.vertex_color_is_srgb = true
	if see_through: mark_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var sheet := MultiMesh.new()
	sheet.transform_format = MultiMesh.TRANSFORM_3D
	sheet.use_colors = true
	sheet.mesh = mesh
	sheet.instance_count = count
	sheet.visible_instance_count = 0
	var node := MultiMeshInstance3D.new()
	node.multimesh = sheet
	node.material_override = mark_material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.custom_aabb = AABB(Vector3(-200,-1,-200),Vector3(400,8,400))
	add_child(node)
	return sheet

func _hole_mesh() -> ArrayMesh:
	## A dark core in a ring of chipped surface, flat in its own XY plane, facing +Z, radius 1.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var core := Color(.11,.1,.09)
	var ring: Array[Vector3] = []
	var rim: Array[Vector3] = []
	for i in 7:
		var angle := TAU*i/7
		ring.append(Vector3(cos(angle),sin(angle),0)*rng.randf_range(.5,.62))
		rim.append(Vector3(cos(angle+.2),sin(angle+.2),0)*rng.randf_range(.8,1.0))
	for i in 7:
		var j := (i+1)%7
		for v in [Vector3.ZERO,ring[i],ring[j]]:
			st.set_color(core); st.add_vertex(v)
		for v in [ring[i],rim[i],ring[j],ring[j],rim[i],rim[j]]:
			st.set_color(Color.WHITE); st.add_vertex(v)
	return st.commit()

func _crack_mesh() -> ArrayMesh:
	## Spokes running out of the point where it went through, bright at the centre, radius 1.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 8:
		var angle := TAU*i/8+rng.randf_range(-.25,.25)
		var along := Vector3(cos(angle),sin(angle),0)
		var side := Vector3(-along.y,along.x,0)*.035
		var reach := rng.randf_range(.6,1.0)
		var bend := along.rotated(Vector3.BACK,rng.randf_range(-.3,.3))*reach
		var mid := along*reach*.5
		st.set_color(Color(1,1,1,.9)); st.add_vertex(side)
		st.set_color(Color(1,1,1,.9)); st.add_vertex(-side)
		st.set_color(Color(1,1,1,.55)); st.add_vertex(mid)
		st.set_color(Color(1,1,1,.55)); st.add_vertex(mid+side*.6)
		st.set_color(Color(1,1,1,.55)); st.add_vertex(mid-side*.6)
		st.set_color(Color(1,1,1,.2)); st.add_vertex(bend)
	for i in 6:
		var a := TAU*i/6
		var b := TAU*(i+1)/6
		for v in [Vector3.ZERO,Vector3(cos(a),sin(a),0)*.09,Vector3(cos(b),sin(b),0)*.09]:
			st.set_color(Color(1,1,1,.75)); st.add_vertex(v)
	return st.commit()

## The face of rectangle r that point p lies on, as its outward normal.
static func face_normal(r: Rect2,p: Vector2) -> Vector2:
	var gaps := [absf(p.x-r.position.x),absf(p.x-r.end.x),absf(p.y-r.position.y),absf(p.y-r.end.y)]
	var normals := [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]
	var best := 0
	for i in 4: if gaps[i] < gaps[best]: best = i
	return normals[best]

func _mark(sheet: MultiMesh,index: int,at: Vector3,normal: Vector3,size: float,color: Color) -> void:
	var slot := index%sheet.instance_count
	sheet.visible_instance_count = mini(index+1,sheet.instance_count)
	var facing := Basis.looking_at(-normal,Vector3.UP)*Basis(Vector3.BACK,rng.randf()*TAU)
	sheet.set_instance_transform(slot,Transform3D(facing.scaled(Vector3.ONE*size),at+normal*.012))
	sheet.set_instance_color(slot,color)

func _hole(event: Dictionary) -> void:
	var surface: String = event.surface
	if not HOLE_RIM.has(surface): return   # a sofa or a hedge takes it without a mark
	var r: Rect2 = event.rect
	var n := face_normal(r,event.p)
	var height := minf(1.15,float(event.h)-.12)
	if height < .1: return
	_mark(holes,hole_total,Vector3(event.p.x,height,event.p.y),Vector3(n.x,0,n.y),HOLE_SIZE[surface]*rng.randf_range(.85,1.2),HOLE_RIM[surface])
	hole_total += 1

func _crack(event: Dictionary) -> void:
	## On the face of the pane the camera sees, where the bullet crossed it, and its bits on the floor.
	var r: Rect2 = event.rect
	var thin_z := r.size.y <= r.size.x
	var p: Vector2 = event.p
	var at := Vector3(p.x,minf(1.15,float(event.h)-.15),r.end.y+.006) if thin_z else Vector3(r.get_center().x,minf(1.15,float(event.h)-.15),p.y)
	var normal := Vector3.BACK if thin_z else Vector3.RIGHT
	_mark(cracks,crack_total,at,normal,rng.randf_range(.22,.34),Color.WHITE)
	crack_total += 1
	var direction := Vector3(event.direction.x,0,event.direction.y)
	for i in 6:
		_add_bit(at+direction*.08,direction*rng.randf_range(.6,1.8)+Vector3(rng.randf_range(-.8,.8),rng.randf_range(.4,1.6),rng.randf_range(-.8,.8)),SHARDS[i%SHARDS.size()],Vector3(.05,.012,.04),4.0)

func _add_stain_sheet(stain_material: StandardMaterial3D) -> void:
	## One irregular blot, drawn with its own size, turn and colour for every stain.
	var ring := PackedVector3Array()
	for i in 12:
		var edge := Vector2.from_angle(TAU*i/12)*rng.randf_range(.75,1.2)
		ring.append(Vector3(edge.x,0,edge.y))
	var fan := PackedVector3Array()
	for i in 12: fan.append_array([Vector3.ZERO,ring[i],ring[(i+1)%12]])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = fan
	var blot := ArrayMesh.new()
	blot.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var sheet := MultiMesh.new()
	sheet.transform_format = MultiMesh.TRANSFORM_3D
	sheet.use_colors = true
	sheet.mesh = blot
	sheet.instance_count = STAINS_PER_SHEET
	sheet.visible_instance_count = 0
	var node := MultiMeshInstance3D.new()
	node.multimesh = sheet
	node.material_override = stain_material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.custom_aabb = AABB(Vector3(-200,-1,-200),Vector3(400,2,400))
	add_child(node)
	stain_sheets.append(sheet)
	sheet_used.append(0)

func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		materials[key] = mat
	return materials[key]

func clear() -> void:
	for entry in bits: entry.node.queue_free()
	for sheet in stain_sheets: sheet.visible_instance_count = 0
	if holes: holes.visible_instance_count = 0
	if cracks: cracks.visible_instance_count = 0
	hole_total = 0
	crack_total = 0
	sheet_used.fill(0)
	stain_total = 0
	growing.clear()
	bits.clear()
	traces.clear()
	fountains.clear()
	for entry in slashes: entry.node.queue_free()
	slashes.clear()
	trail_mesh.clear_surfaces()
	shake = 0
	shake_clock = 0
	kick = Vector2.ZERO
	if camera:
		camera.h_offset = 0
		camera.v_offset = 0

func consume(events: Array[Dictionary],actors: Array[Node3D],guests: Array[Node3D] = []) -> void:
	for event in events:
		match event.type:
			"shot":
				var index := 0 if event.team == "player" else int(event.shooter)+1
				var p := Vector3(event.p.x,1.15,event.p.y)
				if index >= 0 and index < actors.size():
					actors[index].fire_flash()
					p = actors[index].muzzle.global_position
				var direction := Vector3(event.direction.x,0,event.direction.y)
				var right := direction.cross(Vector3.UP)
				_add_bit(p-direction*.12,right*2.3+Vector3.UP*2.6,Color("c29a51"),Vector3(.045,.035,.11),7.0)
				var hero: bool = event.team == "player"
				var gun_kick := float(event.get("kick",.18 if hero else .035))
				shake = minf(.55,shake+gun_kick*(HERO_SHAKE if hero else 1.0))
				if hero: _push(-(event.direction as Vector2)*gun_kick*KICK_SHOT)
			"trace": _trace(event,actors)
			"slash": _slash(event)
			"impact":
				var p := Vector3(event.p.x,1.15,event.p.y)
				var normal := Vector3(event.direction.x,0,event.direction.y)
				var surface: String = event.get("surface","spark")
				var debris: Dictionary = DEBRIS.get(surface,DEBRIS.spark)
				if event.has("rect"): p.y = clampf(float(event.h)-.12,.15,1.15)
				for i in debris.count:
					var spread := Vector3(rng.randf_range(-1,1),rng.randf_range(.5,2),rng.randf_range(-1,1))
					_add_bit(p,normal*rng.randf_range(.5,1.5)*debris.speed+spread*debris.speed*.5,debris.colors[i%debris.colors.size()],debris.size*rng.randf_range(.6,1.4),debris.life*rng.randf_range(.8,1.2))
				if event.has("rect"): _hole(event)
			"glass": _crack(event)
			"unravel","wisp_gone","tear","camera_down","blackout":
				# A torn casca's tenant coming apart, a flame snuffed out, a bag ripped: dark dust.
				var p := Vector3(event.p.x,1.0,event.p.y)
				var colors: Array = DUST.get(event.type)
				for i in 10:
					_add_bit(p+Vector3(rng.randf_range(-.2,.2),rng.randf_range(-.3,.5),rng.randf_range(-.2,.2)),
						Vector3(rng.randf_range(-1.2,1.2),rng.randf_range(1.0,3.2),rng.randf_range(-1.2,1.2)),colors[i%colors.size()],Vector3.ONE*rng.randf_range(.04,.1),.9)
			"blood":
				_blood(event.p,event.direction,BLOOD.get(event.get("kind","human"),BLOOD.human))
				var victim := int(event.get("victim",-1))
				var guest := int(event.get("guest",-1))   # a party guest (Simulation.civilians)
				var body: Node3D = null
				if victim >= 0 and victim < actors.size(): body = actors[victim]
				elif guest >= 0 and guest < guests.size(): body = guests[guest]
				if event.get("gore_allowed",false) and body:
					var region: String = event.get("gore","")   # rolled by the simulation: it is a rule
					if region == "half": cut_in_half(body,event.direction)
					elif not region.is_empty(): dismember(body,region,event.direction)
					if region != "half" and not event.player and event.get("weapon","") in KNOCKBACK_WEAPONS:
						knock_back(body,event.p,event.direction)
				shake = minf(.8,shake+(.65 if event.player else .24))
				_push((event.direction as Vector2)*(KICK_DEATH if event.player else KICK_KILL))
	events.clear()

func _push(along: Vector2) -> void:
	kick = (kick+along).limit_length(KICK_MAX)

func knock_back(visual: Node3D,p: Vector2,direction: Vector2) -> void:
	## Heavy guns throw the body back along the shot (never through a wall), smearing blood on
	## the floor where it slides.
	var heading := direction.normalized()
	var reach := KNOCKBACK_REACH
	var t: float = simulation.wall_hit(p,p+heading*reach,.25,true) if simulation else INF
	if t != INF: reach *= t
	visual.knock_back(heading,reach)
	for i in 6:
		var along := reach*(i+.5)/6.0
		_stain(p+heading*along+heading.orthogonal()*rng.randf_range(-.08,.08),rng.randf_range(.07,.12),Color("842637"))

func dismember(visual: Node3D,region: String,direction: Vector2) -> void:
	var fragments: Array[MeshInstance3D] = visual.detach_part(region)
	if fragments.is_empty(): return
	var p := Vector3.ZERO
	var impulse := Vector3(direction.x,0,direction.y)
	for fragment in fragments:
		p += fragment.position
		_make_room()
		add_child(fragment)
		var velocity := impulse*gore_rng.randf_range(1.6,3.7)+Vector3(gore_rng.randf_range(-1.6,1.6),gore_rng.randf_range(2.2,4.8),gore_rng.randf_range(-1.6,1.6))
		bits.append({"node":fragment,"v":velocity,"age":0.0,"life":12.0,"landed":false,"blood":false,"size":Vector3.ONE,"gib":true,"spin":Vector3(gore_rng.randf_range(-6,6),gore_rng.randf_range(-6,6),gore_rng.randf_range(-6,6))})
	p /= fragments.size()
	for i in (12 if region == "head" else 7):
		var velocity := impulse*gore_rng.randf_range(1,3)+Vector3(gore_rng.randf_range(-2,2),gore_rng.randf_range(1,3.8),gore_rng.randf_range(-2,2))
		_add_bit(p,velocity,Color("a92e40") if i%2 else Color("651e2c"),Vector3.ONE*gore_rng.randf_range(.06,.14),1.5,true)

func cut_in_half(visual: Node3D,direction: Vector2) -> void:
	## The top half is thrown along the shot, tumbling backwards over the cut, while the legs
	## stand a beat and fold (ActorVisual). Both cut ends spurt, a few bits of gut fly out.
	var cut: Dictionary = visual.cut_in_half()
	if cut.is_empty(): return
	var upper: MeshInstance3D = cut.upper
	var impulse := Vector3(direction.x,0,direction.y)
	_make_room()
	add_child(upper)
	var velocity := impulse*gore_rng.randf_range(2.2,3.4)+Vector3(0,gore_rng.randf_range(2.6,3.6),0)
	# A half is a corpse: it stays on the floor until restart instead of fading like a gib.
	bits.append({"node":upper,"v":velocity,"age":0.0,"life":INF,"landed":false,"blood":false,"size":Vector3.ONE,"gib":true,"keep":true,"lie_axis":Vector3.UP,
		"tumble":Vector3.UP.cross(impulse).normalized()*gore_rng.randf_range(6.5,9.0),"spin":Vector3.ZERO})
	var waist: Vector3 = (cut.stump as Node3D).global_position
	for i in 26:
		var spray := impulse*gore_rng.randf_range(.5,2.6)+Vector3(gore_rng.randf_range(-2,2),gore_rng.randf_range(1.5,4.5),gore_rng.randf_range(-2,2))
		_add_bit(waist,spray,Color("a92e40") if i%2 else Color("651e2c"),Vector3.ONE*gore_rng.randf_range(.06,.15),1.5,true)
	for i in 6:
		var flung := impulse*gore_rng.randf_range(.8,2.4)+Vector3(gore_rng.randf_range(-1.4,1.4),gore_rng.randf_range(1.4,3.2),gore_rng.randf_range(-1.4,1.4))
		_add_bit(waist,flung,Color("c25a6a") if i%2 else Color("8c2f45"),Vector3(gore_rng.randf_range(.07,.12),.06,gore_rng.randf_range(.12,.24)),12.0)
	fountains.append({"node":cut.stump,"up":true,"time":1.3,"clock":0.0})
	fountains.append({"node":upper.get_node("Cut"),"up":false,"time":.9,"clock":0.0})

func _make_room() -> void:
	## Frees the oldest bit to stay under MAX_BITS, never a body half.
	if bits.size() < MAX_BITS: return
	for i in bits.size():
		if not bits[i].get("keep",false):
			bits[i].node.queue_free()
			bits.remove_at(i)
			return

func _trace(event: Dictionary,actors: Array[Node3D]) -> void:
	var origin := Vector3(event.origin.x,1.15,event.origin.y)
	var direction := Vector3(event.direction.x,0,event.direction.y)
	var a := Vector3(event.a.x,1.15,event.a.y)
	var b := Vector3(event.b.x,1.15,event.b.y)
	var index := 0 if event.team == "player" else int(event.shooter)+1
	var muzzle_distance := .50
	var muzzle_height := 1.15
	if index >= 0 and index < actors.size():
		var muzzle_position: Vector3 = actors[index].muzzle.global_position
		muzzle_distance = clampf((muzzle_position-origin).dot(direction),.3,.9)
		muzzle_height = muzzle_position.y
	# Do not draw a backwards streak while a simulated bullet is still inside the gun.
	if (b-origin).dot(direction) <= muzzle_distance: return
	if (a-origin).dot(direction) < muzzle_distance:
		a = origin+direction*muzzle_distance
		a.y = muzzle_height
	if a.distance_squared_to(b) < .00001: return
	if traces.size() >= MAX_TRACES: traces.pop_front()
	traces.append({"a":a,"b":b,"age":0.0,"life":.09,"color":Color("ffe5a5") if event.team == "player" else Color("ffb478")})

func _add_bit(p: Vector3,velocity: Vector3,color: Color,size: Vector3,life: float,blood := false) -> void:
	_make_room()
	var mesh := MeshInstance3D.new()
	mesh.mesh = unit_box
	mesh.material_override = material(color)
	mesh.position = p
	mesh.scale = size
	mesh.rotation = Vector3(rng.randf()*PI,rng.randf()*PI,rng.randf()*PI)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	bits.append({"node":mesh,"v":velocity,"age":0.0,"life":life,"landed":false,"blood":blood,"size":size})

func _stain(p: Vector2,radius: float,color: Color,grow := .0) -> void:
	for r in simulation.solids:
		if r.has_point(p): return
	var index := stain_total%STAIN_SHEETS
	var sheet := stain_sheets[index]
	var slot := sheet_used[index]%STAINS_PER_SHEET
	sheet_used[index] += 1
	sheet.visible_instance_count = mini(sheet_used[index],STAINS_PER_SHEET)
	sheet.set_instance_color(slot,color)
	var turn := Basis(Vector3.UP,rng.randf()*TAU)
	var at := Vector3(p.x,.105+float(stain_total%24)*.0005,p.y)
	stain_total += 1
	sheet.set_instance_transform(slot,Transform3D(turn.scaled(Vector3(radius,1,radius)*(.2 if grow > 0 else 1.0)),at))
	if grow > 0: growing.append({"sheet":sheet,"slot":slot,"turn":turn,"at":at,"radius":radius,"age":0.0,"grow":grow})

func _blood(p: Vector2,direction: Vector2,colors: Array = BLOOD.human) -> void:
	_stain(p,.58,colors[0],.65)
	_stain(p+direction*.2,.30,colors[1],.4)
	for i in 13:
		var sideways := Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(.3,2.1)
		var velocity := direction*rng.randf_range(1.1,3.5)+sideways
		_add_bit(Vector3(p.x,1.05,p.y),Vector3(velocity.x,rng.randf_range(1,3.3),velocity.y),colors[2] if i%3 else colors[3],Vector3.ONE*rng.randf_range(.055,.115),1.4,true)
	for i in 6:
		var offset := direction*rng.randf_range(.35,1.35)+Vector2.from_angle(rng.randf()*TAU)*.35
		# Scatter must not paint through a wall on the opposite side of a room.
		if simulation.can_see(p,p+offset): _stain(p+offset,rng.randf_range(.045,.15),colors[4])

func _slash(event: Dictionary) -> void:
	## The katana's cut drawn as a flat, stepped arc of light at chest height, sweeping the way the
	## cut goes (alternate sides on alternate swings); it lights up as the blade lands and fades.
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(1,1,1,0)
	var facing: float = (event.direction as Vector2).angle()
	var arc: float = event.arc
	var side := 1.0 if int(event.count)%2 else -1.0
	var steps := 7
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in steps:
		# Brightest at the leading end of the sweep, in flat PS1 bands.
		var shade := float(i+1)/steps
		var color := Color(.75,.95,1.0,1).lerp(Color(1,1,1,1),shade)*Color(1,1,1,shade)
		var a0 := facing+side*arc*(2.0*i/steps-1.0)
		var a1 := facing+side*arc*(2.0*(i+1)/steps-1.0)
		var inner: float = event.reach*.62
		var outer: float = event.reach
		var quad := [Vector2.from_angle(a0)*inner,Vector2.from_angle(a0)*outer,Vector2.from_angle(a1)*outer,Vector2.from_angle(a1)*inner]
		for k in [0,1,2,0,2,3]:
			mesh.surface_set_color(color)
			mesh.surface_add_vertex(Vector3(quad[k].x,1.05,quad[k].y))
	mesh.surface_end()
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position = Vector3(event.p.x,0,event.p.y)
	add_child(node)
	slashes.append({"node":node,"material":material,"age":0.0})

func update(dt: float,paused := false) -> void:
	if paused: return
	for i in range(slashes.size()-1,-1,-1):
		var entry: Dictionary = slashes[i]
		entry.age += dt
		# Unseen during the wind-up, flashes as the blade lands (Simulation.KATANA.strike), fades.
		var t: float = (entry.age-.16)/.2
		if t >= 1.0:
			entry.node.queue_free(); slashes.remove_at(i); continue
		entry.material.albedo_color.a = 0.0 if t < 0 else .45*(1.0-t)
	for i in range(bits.size()-1,-1,-1):
		var bit := bits[i]
		bit.age += dt
		if bit.age >= bit.life:
			bit.node.queue_free(); bits.remove_at(i); continue
		if bit.landed:
			bit.node.scale = bit.size*minf(1,(bit.life-bit.age)*3)
			continue
		bit.v.y -= 9.8*dt
		var before: Vector3 = bit.node.position
		var after: Vector3 = before+bit.v*dt
		var ground := .12
		if bit.has("tumble"): bit.node.rotate(bit.tumble.normalized(),dt*bit.tumble.length())
		if bit.get("gib",false):
			bit.node.rotate_x(dt*bit.spin.x)
			bit.node.rotate_y(dt*bit.spin.y)
			bit.node.rotate_z(dt*bit.spin.z)
			var box: AABB = Transform3D(bit.node.basis,Vector3.ZERO)*bit.node.get_aabb()
			ground = .11-box.position.y
		for entry in simulation.layout.solids:
			if minf(before.y,after.y) > float(entry.h): continue
			var r := LapaSimulation.rect(entry.r)
			var t := LapaSimulation.segment_box(Vector2(before.x,before.z),Vector2(after.x,after.z),r)
			if t != INF:
				after.x = before.x; after.z = before.z
				bit.v.x *= -.2; bit.v.z *= -.2
				break
		if after.y <= ground:
			after.y = ground
			if bit.blood:
				_stain(Vector2(after.x,after.z),rng.randf_range(.04,.10),Color("842637"))
				bit.node.queue_free(); bits.remove_at(i); continue
			elif absf(bit.v.y) > .8:
				bit.v.y *= -.22; bit.v.x *= .6; bit.v.z *= .6
			else:
				bit.landed = true
				if bit.get("gib",false):
					# A severed limb should settle along the floor, not balance upright.
					_lay_flat(bit.node,bit.get("lie_axis",Vector3.ZERO))
					var resting_box: AABB = Transform3D(bit.node.basis,Vector3.ZERO)*bit.node.get_aabb()
					after.y = .11-resting_box.position.y
				else: bit.node.rotation = Vector3(0,bit.node.rotation.y,0)
		bit.node.position = after
		if not bit.landed and not bit.get("gib",false): bit.node.rotate_x(dt*9); bit.node.rotate_z(dt*7)
	_spurt(dt)
	for i in range(growing.size()-1,-1,-1):
		var pool := growing[i]
		pool.age += dt
		var spread := lerpf(.2,1.0,clampf(pool.age/pool.grow,0,1))
		pool.sheet.set_instance_transform(pool.slot,Transform3D(pool.turn.scaled(Vector3(pool.radius,1,pool.radius)*spread),pool.at))
		if pool.age >= pool.grow: growing.remove_at(i)
	for i in range(traces.size()-1,-1,-1):
		traces[i].age += dt
		if traces[i].age >= traces[i].life: traces.remove_at(i)
	_draw_traces()
	shake = maxf(0,shake-dt*2.5)
	shake_clock += dt
	kick *= exp(-KICK_RETURN*dt)
	if kick.length_squared() < .00001: kick = Vector2.ZERO
	if camera:
		camera.h_offset = sin(shake_clock*113)*shake*.28+kick.x
		camera.v_offset = cos(shake_clock*139)*shake*.20-kick.y*KICK_DEPTH

func _spurt(dt: float) -> void:
	## Cut ends pump blood in short beats, weakening until they stop.
	for i in range(fountains.size()-1,-1,-1):
		var spring := fountains[i]
		spring.time -= dt
		spring.clock -= dt
		if spring.time <= 0 or not is_instance_valid(spring.node):
			fountains.remove_at(i); continue
		if spring.clock > 0: continue
		spring.clock = .045
		var source: Node3D = spring.node
		var out := Vector3.UP if spring.up else source.global_basis*Vector3.DOWN
		var strength := clampf(spring.time,.3,1.0)
		var velocity := out*gore_rng.randf_range(1.2,2.6)*strength+Vector3(gore_rng.randf_range(-.6,.6),gore_rng.randf_range(0,.8),gore_rng.randf_range(-.6,.6))
		_add_bit(source.global_position,velocity,Color("a92e40") if gore_rng.randf() < .6 else Color("651e2c"),Vector3.ONE*gore_rng.randf_range(.04,.09),1.2,true)

func _lay_flat(node: MeshInstance3D,axis := Vector3.ZERO) -> void:
	## Turns the piece's long axis (or the given local axis, a half's spine) level with the floor.
	var size := node.get_aabb().size
	if axis == Vector3.ZERO:
		axis = Vector3.RIGHT
		if size.y > size.x and size.y >= size.z: axis = Vector3.UP
		elif size.z > size.x: axis = Vector3.BACK
	var current := (node.basis*axis).normalized()
	var horizontal := Vector3(current.x,0,current.z)
	if horizontal.length_squared() < .001: horizontal = Vector3.RIGHT
	node.basis = Basis(Quaternion(current,horizontal.normalized()))*node.basis

func _draw_traces() -> void:
	trail_mesh.clear_surfaces()
	if traces.is_empty(): return
	trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,trail_material)
	for trail in traces:
		var direction: Vector3 = (trail.b-trail.a).normalized()
		var across := direction.cross(camera.global_basis.z).normalized()
		var alpha := 1.0-float(trail.age)/float(trail.life)
		for pass_index in 2:
			var width := .025 if pass_index else .08
			var color: Color = trail.color
			color.a = alpha*(1.0 if pass_index else .18)
			var side := across*width
			for vertex in [trail.a-side,trail.a+side,trail.b+side,trail.a-side,trail.b+side,trail.b-side]:
				trail_mesh.surface_set_color(color)
				trail_mesh.surface_add_vertex(vertex)
	trail_mesh.surface_end()
