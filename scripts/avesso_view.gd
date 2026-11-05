extends Node3D
## Presentation only: what the casca rule puts on stage. Shadow-flames (sim.wisps) as stepped
## violet flames that lick upward over a glow on the floor, always plain to see so the player
## follows each one to the body it takes; and the shells (sim.shells), body bags hanging from the
## rail, head, shoulders and feet under the plastic, a zip down the front, swaying on the hook.
## Torn or emptied, a flap stays on the hook and the open bag lies on the floor. No lights: every
## flame is unlit geometry.
const FLAME_COLORS := [Color("1a0a33"),Color("6a32d0"),Color("9b5cff")]
const TONGUES := 5
const HOOK := 2.7   # the rail height: each bag swings from here

var sim
var flames: Array[Node3D] = []
var bags: Array[Node3D] = []
var clock := 0.0
var flame_materials: Array[StandardMaterial3D] = []
var bag_material := StandardMaterial3D.new()
var rail_material := StandardMaterial3D.new()
var spill_material := StandardMaterial3D.new()
var tag_material := StandardMaterial3D.new()
var zip_material := StandardMaterial3D.new()
## The count room's aides (shells with "style":"seated"): slumped over their desks in grey suits,
## Souza in his police blue. Whole, they are bodies the Síndico can take; used, the chair is empty.
var suit_material := StandardMaterial3D.new()
var uniform_material := StandardMaterial3D.new()
var skin_material := StandardMaterial3D.new()
var glow_material := StandardMaterial3D.new()
var cube := BoxMesh.new()
var disc := CylinderMesh.new()

func setup(simulation) -> void:
	sim = simulation
	cube.size = Vector3.ONE
	disc.top_radius = .5
	disc.bottom_radius = .5
	disc.height = 1.0
	disc.radial_segments = 8   # stepped, PS1
	disc.rings = 1
	for color in FLAME_COLORS:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = color
		mat.no_depth_test = true   # from the Avesso: seen through the walls it crosses
		mat.render_priority = 2
		flame_materials.append(mat)
	# Blue-black plastic with a sheen, lighter than the black wall caps so a bag never reads as a
	# slit in a wall; the zip and the tag make it a body bag from above.
	bag_material.albedo_color = Color("343f52")
	bag_material.roughness = .22
	bag_material.metallic_specular = 1.0
	zip_material.albedo_color = Color("c3cad4")
	glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_material.albedo_color = Color(.55,.3,1.0,.5)
	glow_material.no_depth_test = true
	glow_material.render_priority = 1
	rail_material.albedo_color = Color("6d7178")
	rail_material.metallic = .6
	spill_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spill_material.albedo_color = Color("0e0e1a")
	tag_material.albedo_color = Color("e8e6de")
	suit_material.albedo_color = Color("3a3f4a")
	uniform_material.albedo_color = Color("2a3f6e")
	skin_material.albedo_color = Color("b88a6a")
	rebuild()

func rebuild() -> void:
	## A new night or a retry: the level's shells, whole again.
	for bag in bags: bag.queue_free()
	bags.clear()
	for shell in sim.shells:
		if shell.get("style","") == "seated":
			bags.append(_seated(shell))
			continue
		var bag := Node3D.new()
		bag.position = Vector3(shell.p.x,0,shell.p.y)   # broad side and zip always to the camera
		add_child(bag)
		var swing := Node3D.new()   # pivots on the hook
		swing.name = "swing"
		swing.position.y = HOOK
		bag.add_child(swing)
		_part(swing,rail_material,Vector3(0,-.15,0),Vector3(.04,.3,.04))
		var whole := Node3D.new()
		whole.name = "whole"
		swing.add_child(whole)
		# Hanging head down from the knot: head, shoulders, hips, feet, from 2.2 m to 0.8 m.
		_part(whole,bag_material,Vector3(0,-.4,0),Vector3(.14,.14,.14))      # knot
		_part(whole,bag_material,Vector3(0,-.62,0),Vector3(.3,.3,.26))       # head
		_part(whole,bag_material,Vector3(0,-1.1,0),Vector3(.52,.7,.32))      # shoulders and chest
		_part(whole,bag_material,Vector3(0,-1.6,0),Vector3(.42,.4,.28))      # hips and legs
		_part(whole,bag_material,Vector3(0,-1.85,0),Vector3(.3,.16,.22))     # feet
		_part(whole,zip_material,Vector3(0,-1.2,.165),Vector3(.03,1.1,.01))   # the zip, on the camera side
		_part(whole,zip_material,Vector3(0,-.68,.17),Vector3(.07,.05,.01))    # its pull
		_part(whole,tag_material,Vector3(.14,-.5,.14),Vector3(.12,.08,.01))   # the name tag
		var open := Node3D.new()
		open.name = "open"
		bag.add_child(open)
		_part(open,bag_material,Vector3(0,HOOK-.55,0),Vector3(.3,.32,.08))    # a flap left on the hook
		_part(open,bag_material,Vector3(0,.04,.3),Vector3(.55,.06,1.2))       # the empty bag on the floor
		_part(open,zip_material,Vector3(0,.075,.3),Vector3(.03,.01,1.0))
		_part(open,spill_material,Vector3(0,.012,0),Vector3(.9,.01,.7))
		bags.append(bag)

func _seated(shell: Dictionary) -> Node3D:
	## An aide slumped forward over the desk, arms out, face down; the same node layout as a bag.
	var aide := Node3D.new()
	aide.position = Vector3(shell.p.x,0,shell.p.y)
	aide.rotation.y = -shell.angle+PI/2
	add_child(aide)
	var swing := Node3D.new()
	swing.name = "swing"
	aide.add_child(swing)
	var whole := Node3D.new()
	whole.name = "whole"
	swing.add_child(whole)
	var cloth: Material = uniform_material if shell.get("name","") == "souza" else suit_material
	_part(whole,cloth,Vector3(0,.5,0),Vector3(.4,.18,.36))                                  # hips on the chair
	var torso := _part(whole,cloth,Vector3(0,.82,.18),Vector3(.42,.52,.24))
	torso.rotation.x = .9                                                                    # leaning onto the desk
	_part(whole,skin_material,Vector3(0,.88,.48),Vector3(.2,.18,.22))                        # face down on the desk
	for side in [-1,1]: _part(whole,cloth,Vector3(side*.24,.8,.42),Vector3(.1,.1,.42))     # arms out over the papers
	for side in [-1,1]: _part(whole,cloth,Vector3(side*.1,.22,-.05),Vector3(.12,.44,.12))  # legs down to the floor
	var open := Node3D.new()
	open.name = "open"
	aide.add_child(open)
	_part(open,spill_material,Vector3(0,.012,.2),Vector3(.6,.01,.5))
	return aide

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
	if bags.size() != sim.shells.size(): rebuild()
	for i in bags.size():
		var open: bool = sim.shells[i].torn or sim.shells[i].used
		bags[i].get_node("swing/whole").visible = not open
		bags[i].get_node("open").visible = open
		# A slow sway on the hook, each bag out of step: the eye catches it among the still walls.
		var swing: Node3D = bags[i].get_node("swing")
		var hanging: bool = sim.shells[i].get("style","") != "seated"
		swing.rotation = Vector3(cos(clock*1.1+i*.9)*.03,0,sin(clock*1.4+i*1.7)*.05) if hanging and not open else Vector3.ZERO
	while flames.size() < sim.wisps.size(): flames.append(_flame())
	for i in flames.size():
		var shown: bool = i < sim.wisps.size()
		flames[i].visible = shown
		if not shown: continue
		var w: Dictionary = sim.wisps[i]
		flames[i].position = Vector3(w.p.x,0,w.p.y)
		var fading := clampf(float(w.life)/.4,0.0,1.0) if w.target.is_empty() else 1.0
		for k in TONGUES:
			# Each tongue rises, thins and starts over, out of step with the others.
			var tongue: MeshInstance3D = flames[i].get_child(k)
			var t := fposmod(clock*2.2+k*.37,1.0)
			var lean := Vector2(sin(k*2.1+clock*5.0),cos(k*1.7+clock*4.0))*.12
			tongue.position = Vector3(lean.x,.35+t*1.5,lean.y)
			tongue.scale = Vector3.ONE*(.34-.26*t)*fading
		flames[i].get_child(TONGUES).scale = Vector3(.32,.9,.32)*fading*(1.0+.08*sin(clock*17.0))
		flames[i].get_child(TONGUES+1).scale = Vector3(1.3,.01,1.3)*fading*(1.0+.12*sin(clock*9.0))

func _flame() -> Node3D:
	var flame := Node3D.new()
	add_child(flame)
	for k in TONGUES: _part(flame,flame_materials[1+k%2],Vector3.ZERO,Vector3.ONE*.2)
	_part(flame,flame_materials[0],Vector3(0,.75,0),Vector3(.32,.9,.32))   # the dark core
	_part(flame,glow_material,Vector3(0,.06,0),Vector3(1.3,.01,1.3)).mesh = disc   # a violet glow on the floor under it
	return flame
