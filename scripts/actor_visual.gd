class_name LapaActorVisual
extends Node3D
const BodyParts = preload("res://scripts/body_parts.gd")
const ActorLook = preload("res://scripts/actor_look.gd")
const AFTERIMAGE_LIFE := .32
const AFTERIMAGE_INTERVAL := .07
const MAX_AFTERIMAGES := 8
const RING_LIFE := .3
const HALVED_HOLD := .35   # cut in half, the legs stand this long before folding
# Guns carried low at the hip instead of aimed at arm's length. The animation library
# only has pistol clips, so the arms are solved onto the gun on top of the pistol pose.
const HIP_WEAPONS := ["minigun"]
const HIP_GRIP := Vector3(-.15,.9,.04)        # right hand on the spade grip, actor space
const HIP_HANDLE := Vector3(-.04,.24,-.15)    # left wrist over the carry handle, gun space
const HIP_CAN := Vector3(-.12,-.2,-.4)        # left wrist at the ammo can while reloading
const HIP_SUPPORT_TWIST := -PI/2              # turns the pistol support hand palm-down
const HIP_LEAN := -.22                        # chest tilts back, radians
# Minigun recoil: no kick per round but a steady shove (an M134 averages ~68 kg at 3000 rounds/min)
# that the gunner leans into while the whole gun buzzes; spinning up without firing only hums.
const HIP_PUSH_LEAN := .16                    # chest leans into the gun while firing, radians
const HIP_PUSH_BACK := .035                   # the gun is shoved back at the hip, metres
const HIP_SPIN_UP := .55                      # Simulation's minigun spin-up time
# Idle, shoot and reload per gun, keyed in tools/build_weapon_anims.py except the library's pistol
# idle and reload. The minigun has no shot clip: its recoil is live in _hold_at_hip.
const PISTOL_CLIPS := ["Pistol_Idle_Loop","Pistol_Kick","Pistol_Reload"]
const GUN_CLIPS := {"smg":["SMG_Idle","SMG_Shoot","SMG_Reload"],"shotgun":["Shotgun_Idle","Shotgun_Shoot","Shotgun_Reload"],
	"rifle":["Rifle_Idle","Rifle_Shoot","Rifle_Reload"],"minigun":["Pistol_Idle_Loop","","Pistol_Reload"],
	# The katana's guard; its cuts (SLASHES) follow the simulation's swing count, not the recoil.
	"katana":["ual2/Sword_Guard","",""]}
## UAL2 cuts, each joined to its recovery (tools/extract_ual2_clips.gd), alternating per swing.
const SLASHES := ["ual2/Slash_A","ual2/Slash_B"]
static var gun_library: AnimationLibrary
## Unaware enemies (level.json "pose") carry an everyday pose on the upper body over their patrol
## walk, from Universal Animation Library 2: a beer with a sip now and then, a phone call, arms
## folded. The gun is put away when the pose needs the right hand; alerted, they snap back armed.
const POSES := {"drink":{"clip":"ual2/Drink_Loop","prop":"bottle","hand":"l","gun":true},
	"phone":{"clip":"ual2/Idle_TalkingPhone_Loop","prop":"phone","hand":"r","gun":false},
	"arms":{"clip":"ual2/Idle_FoldArms_Loop","prop":"","hand":"","gun":false},
	# The Lagoa party: guests sip champagne; an inquilino in a guest's casca holds the glass and
	# never drinks (the clip held still), with no gun in sight until alerted.
	"champagne":{"clip":"ual2/Drink_Loop","prop":"glass","hand":"l","gun":false},
	"hold":{"clip":"ual2/Drink_Loop","prop":"glass","hand":"l","gun":false,"still":true}}
## Guests' evening wear: a tint over the clothes' texture, one per guest in turn.
const GUEST_TINTS := [Color("ffe2b0"),Color("ffb8c4"),Color("c8c4ff"),Color("bff0d8"),Color("f0f0f0")]
const GLASS := Color(1.0,.92,.62,.85)   # champagne in a flute
## Shotgun and rifle kills (CombatEffects) throw the body back: UAL2's knockback fall replaces
## Death01 and the body slides along the shot, facing the shooter.
const KNOCK_CLIP := "ual2/Hit_Knockback"
const RISE_KEY := "rise"   # Death01 backwards, for a corpse a shadow-flame stands up
const BARE_SKIN := Color("c9a892")   # morgue-pale skin of the bodies in the bags
## Out of a torn bag: the body slides out of its bottom and falls upright (DROP_FALL), then
## crumples on the floor (Death01 played fast, DROP_CRUMPLE) before getting up (RISE_KEY).
const DROP_KEY := "drop"
const DROP_HEIGHT := .7
const DROP_FALL := .3
const DROP_CRUMPLE := .4
const KNOCK_FROM := .06        # the clip opens on a crouch; start as the hit lands
const KNOCK_SLIDE := .35       # seconds the body travels
static var ual2_library: AnimationLibrary
## Moving at an angle to the aim. The libraries have no sidestep clips, only forward and backward
## gaits, so the hips (and the legs with them) turn toward the way the body travels, or toward the
## opposite way on the backward gait, up to LEG_TWIST_MAX. The spine turns back by the same amount
## in SPINE_SHARE parts, so the chest, arms and gun stay on the aim. Eases at LEG_TWIST_RATE.
const LEG_TWIST_MAX := 1.6
const LEG_TWIST_RATE := 14.0
const SPINE_SHARE := {"spine_01":.3,"spine_02":.35,"spine_03":.35}
var leg_twist := 0.0
var twist_applied: Dictionary = {}   # bone index -> rotation added on top of its pose, undone before the next frame
var model: Node3D
var animator: AnimationPlayer
var skeleton: Skeleton3D
var current := ""
var clips: Dictionary = {}
var gun: Node3D
var locomotion_time := 0.0
var locomotion: Animation
var leg_tracks: Array[Vector2i] = []
var locomotions: Dictionary = {}
var locomotion_tracks: Dictionary = {}
var locomotion_name := ""
var locomotion_rate := 1.0
var muzzle: Marker3D
var flash_mesh: Node3D
var flash_light: OmniLight3D
var flash_time := 0.0
var body_parts
static var weapon_manifest: Dictionary = {}
var weapon := ""
var weapon_model: Node3D
var gun_parts: Array[MeshInstance3D] = []
var hip_fire := false
var arm_bones: Dictionary = {}
var support_grip: Basis       # left hand relative to the gun in the pistol pose
var pelvis_rest: Vector3
var last_recoil := 0.0
var halved_hold := 0.0
var hip_push := 0.0    # 0..1, eases in while the minigun fires
var hip_clock := 0.0
var ghost_material: StandardMaterial3D
var xray_material: StandardMaterial3D
var ghost_gun_material: StandardMaterial3D
var ring: MeshInstance3D
var ring_material: StandardMaterial3D
var ring_time := 0.0
var phasing := false
var phase_clock := 0.0
var afterimages: Array[Dictionary] = []
var afterimage_clock := 0.0
var look   # legibility dressing (contact shadow, rim, figure light); only the level adds it
var pose := ""                 # unaware pose, see POSES
var guest := false             # a party guest: never armed, runs without a gun stance
var prop: Node3D               # bottle or phone in the posing hand
var knock_dir := Vector2.ZERO
var knock_reach := 0.0
var knock_time := -1.0         # world seconds since a knockback kill, -1 without one
var drop_time := -1.0          # world seconds since the body dropped out of its bag, -1 without one
var last_swings := 0           # katana swings already shown

func setup(path: String) -> void:
	model = (load(path) as PackedScene).instantiate()
	add_child(model)
	var skin_material: StandardMaterial3D
	for node in model.find_children("*","",true,false):
		if node is AnimationPlayer: animator = node
		if node is Skeleton3D: skeleton = node
		if node is MeshInstance3D:
			for surface in node.mesh.get_surface_count():
				var original: Material = node.get_active_material(surface)
				if original is StandardMaterial3D:
					var mat := original.duplicate() as StandardMaterial3D
					mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					mat.roughness = 1.0
					mat.metallic = 0.0
					node.set_surface_override_material(surface,mat)
					if not skin_material: skin_material = mat
	if not animator or not skeleton:
		push_error("Character is missing skeleton or animations: "+path)
		return
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip in animator.get_animation_list():
		for short in ["Pistol_Idle_Loop","Walk_Loop","Jog_Fwd_Loop","Pistol_Shoot","Pistol_Reload","Death01"]:
			if String(clip).ends_with(short) or String(clip) == short.trim_suffix("_Loop"): clips[short] = clip
	for short in ["Pistol_Idle_Loop","Walk_Loop","Jog_Fwd_Loop"]:
		if clips.has(short): animator.get_animation(clips[short]).loop_mode = Animation.LOOP_LINEAR
	var library := AnimationLibrary.new()
	animator.add_animation_library("armed",library)
	for entry in [["walk","Walk_Loop"],["run","Jog_Fwd_Loop"]]:
		_make_armed_locomotion(entry[0],entry[1],library)
	for entry in [["walk_back","walk_backward"],["run_back","run_backward"]]:
		_make_armed_locomotion(entry[0],"res://assets/animations/"+entry[1]+".tres",library)
	animator.add_animation_library("guns",_gun_library())
	for clip in gun_library.get_animation_list(): clips[String(clip)] = "guns/"+clip
	if not ual2_library: ual2_library = load("res://assets/animations/ual2_clips.res")
	animator.add_animation_library("ual2",ual2_library)
	animator.play(clips.get("Pistol_Idle_Loop","RESET"))
	animator.advance(0)
	skeleton.force_update_all_bone_transforms()
	_add_pistol()
	body_parts = BodyParts.new()
	body_parts.setup(model,skeleton)
	_setup_phase(skin_material)

func fall_from_bag() -> void:
	drop_time = 0.0
	current = ""

func strip() -> void:
	## A body out of a morgue bag: no clothes and no detail, one pale skin over the whole figure,
	## smooth as a mannequin. Changed in place, so the parts a shot or a cut takes off match.
	for node in model.find_children("*","MeshInstance3D",true,false):
		for surface in node.get_surface_override_material_count():
			var mat := node.get_surface_override_material(surface) as StandardMaterial3D
			if not mat: continue
			mat.albedo_texture = null
			mat.albedo_color = BARE_SKIN

func add_look(hero: bool) -> void:
	look = ActorLook.new()
	add_child(look)
	look.setup(self,hero)

func set_pose(name: String) -> void:
	## The everyday pose this enemy holds while unaware; "" for none.
	pose = name if POSES.has(name) else ""
	if prop: prop.get_parent().queue_free()
	prop = null
	if pose.is_empty() or POSES[pose].prop.is_empty(): return
	var side: String = POSES[pose].hand
	var socket := BoneAttachment3D.new()
	socket.bone_name = "hand_"+side
	skeleton.add_child(socket)
	socket.on_skeleton_update()
	var material := StandardMaterial3D.new()
	material.roughness = 1.0
	var mesh: Mesh
	if POSES[pose].prop == "glass":
		var flute := CylinderMesh.new()
		flute.top_radius = .028
		flute.bottom_radius = .008
		flute.height = .17
		flute.radial_segments = 6
		flute.rings = 1
		mesh = flute
		material.albedo_color = GLASS
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	elif POSES[pose].prop == "bottle":
		var bottle := CylinderMesh.new()
		bottle.top_radius = .026
		bottle.bottom_radius = .034
		bottle.height = .24
		bottle.radial_segments = 6
		bottle.rings = 1
		mesh = bottle
		material.albedo_color = Color("5a3412")   # brown long-neck
	else:
		var phone := BoxMesh.new()
		phone.size = Vector3(.012,.12,.06)
		mesh = phone
		material.albedo_color = Color("16181d")
	prop = MeshInstance3D.new()
	prop.name = "Prop_"+POSES[pose].prop
	prop.mesh = mesh
	prop.material_override = material
	prop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Held through the fist like the guns: the long axis runs across the knuckles.
	var hand_pose := skeleton.get_bone_global_pose(skeleton.find_bone("hand_"+side))
	prop.transform = hand_pose.affine_inverse()*fist_frame(side)
	prop.visible = false
	socket.add_child(prop)
	if look: look.refresh()

func knock_back(direction: Vector2,reach: float) -> void:
	## Thrown back by a heavy shot: the knockback fall instead of Death01, sliding `reach` metres.
	knock_dir = direction.normalized()
	knock_reach = reach
	knock_time = 0.0

static func _gun_library() -> AnimationLibrary:
	## Shared by every actor: all characters use the same RioRig skeleton, so the tracks fit as is.
	if not gun_library:
		gun_library = AnimationLibrary.new()
		var source: Node = (load("res://assets/animations/weapon_clips.glb") as PackedScene).instantiate()
		var player: AnimationPlayer = source.find_children("*","AnimationPlayer",true,false)[0]
		for clip in player.get_animation_list(): gun_library.add_animation(clip,player.get_animation(clip))
		source.free()
	return gun_library

func _setup_phase(skin: StandardMaterial3D) -> void:
	# Intangible look: a translucent cyan body that keeps its texture, plus a faint
	# x-ray pass without depth test so the silhouette stays visible inside walls.
	ghost_material = skin.duplicate() if skin else StandardMaterial3D.new()
	ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	ghost_material.albedo_color = Color(.55,.95,1.0,.42)
	ghost_material.emission_enabled = true
	ghost_material.emission = Color("2fc8ff")
	ghost_material.emission_energy_multiplier = .8
	xray_material = StandardMaterial3D.new()
	xray_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	xray_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	xray_material.no_depth_test = true
	xray_material.albedo_color = Color(.4,.9,1.0,.2)
	xray_material.render_priority = 1
	ghost_material.next_pass = xray_material
	ghost_gun_material = StandardMaterial3D.new()
	ghost_gun_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost_gun_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_gun_material.albedo_color = Color(.45,.9,1.0,.35)
	# Ring that bursts from the feet when the spectre starts or ends.
	var torus := TorusMesh.new()
	torus.inner_radius = .32
	torus.outer_radius = .4
	torus.rings = 12
	torus.ring_segments = 3
	ring_material = StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ring_material.albedo_color = Color(.35,.9,1.0,0)
	ring = MeshInstance3D.new()
	ring.mesh = torus
	ring.material_override = ring_material
	ring.position.y = .12
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.hide()
	add_child(ring)

func violet_phase() -> void:
	## A Proprietário goes through in violet where the hero goes in cyan.
	ghost_material.albedo_color = Color(.72,.5,1.0,.42)
	ghost_material.emission = Color("7a3cff")
	xray_material.albedo_color = Color(.65,.42,1.0,.2)
	ghost_gun_material.albedo_color = Color(.7,.45,1.0,.35)
	ring_material.albedo_color = Color(.65,.4,1.0,0)

func reset_damage() -> void:
	halved_hold = 0.0
	knock_time = -1.0
	if body_parts: body_parts.reset()

func detach_part(region: String) -> Array[MeshInstance3D]:
	return body_parts.detach(region)

func cut_in_half() -> Dictionary:
	## {upper, stump}; the legs then stand a beat before the original death clip folds them.
	var result: Dictionary = body_parts.cut_in_half()
	if not result.is_empty(): halved_hold = HALVED_HOLD
	return result

func _make_armed_locomotion(label: String,source: String,library: AnimationLibrary) -> void:
	if not clips.has("Pistol_Idle_Loop"): return
	var source_animation: Animation = load(source) if source.begins_with("res://") else animator.get_animation(clips[source])
	locomotions[label] = source_animation
	var tracks: Array[Vector2i] = []
	for i in source_animation.get_track_count():
		var bone_name := String(source_animation.track_get_path(i)).get_slice(":",1)
		if _is_lower_body(bone_name):
			var index := skeleton.find_bone(bone_name)
			if index >= 0: tracks.append(Vector2i(i,index))
	locomotion_tracks[label] = tracks
	var run := source_animation.duplicate(true) as Animation
	var idle := animator.get_animation(clips.Pistol_Idle_Loop)
	for i in range(run.get_track_count()-1,-1,-1):
		var p := String(run.track_get_path(i)).to_lower()
		if not ("thigh" in p or "calf" in p or "foot" in p or "ball" in p or "pelvis" in p or p.ends_with(":root")):
			run.remove_track(i)
	for i in idle.get_track_count():
		var p := String(idle.track_get_path(i)).to_lower()
		if "thigh" in p or "calf" in p or "foot" in p or "ball" in p or "pelvis" in p or p.ends_with(":root"): continue
		idle.copy_track(i,run)
	run.loop_mode = Animation.LOOP_LINEAR
	library.add_animation(label,run)
	clips["armed_"+label] = "armed/"+label

func _is_lower_body(bone: String) -> bool:
	return bone.begins_with("thigh") or bone.begins_with("calf") or bone.begins_with("foot") or bone.begins_with("ball") or bone == "pelvis"

func _select_locomotion(data: Dictionary) -> void:
	var speed := (data.get("velocity",Vector2.ZERO) as Vector2).length()
	var selected := "walk" if speed < 1.6 else "run"
	if speed > .05:
		var facing := Vector2.from_angle(data.angle)
		var alignment := (data.velocity as Vector2).normalized().dot(facing)
		var threshold := -.15 if locomotion_name.ends_with("_back") else -.35
		if alignment < threshold: selected += "_back"
	if selected != locomotion_name:
		var progress := locomotion_time/locomotion.length if locomotion else 0.0
		locomotion_name = selected
		locomotion = locomotions.get(selected)
		leg_tracks = locomotion_tracks.get(selected,[])
		locomotion_time = progress*locomotion.length if locomotion else 0.0
	locomotion_rate = clampf(speed/(1.25 if selected.begins_with("walk") else 3.2),.35,1.8)

func _twist_legs(data: Dictionary,dt: float) -> void:
	## See LEG_TWIST_MAX. The node faces the aim; only the skeleton below the chest turns.
	var target := 0.0
	var velocity: Vector2 = data.get("velocity",Vector2.ZERO)
	if data.alive and data.moving and velocity.length_squared() > .0025:
		var travel := velocity.angle()+(PI if locomotion_name.ends_with("_back") else 0.0)
		target = clampf(-angle_difference(data.angle,travel),-LEG_TWIST_MAX,LEG_TWIST_MAX)
	leg_twist = lerpf(leg_twist,target,1.0-exp(-LEG_TWIST_RATE*dt)) if data.alive else 0.0
	if absf(leg_twist) < .001: return
	var up := (skeleton.global_basis.inverse()*Vector3.UP).normalized()
	_turn_bone("pelvis",up,leg_twist)
	for bone in SPINE_SHARE: _turn_bone(bone,up,-leg_twist*SPINE_SHARE[bone])

func _turn_bone(name: String,up: Vector3,angle: float) -> void:
	## Turns a bone about the skeleton's vertical through its own origin, remembering the turn.
	var bone := skeleton.find_bone(name)
	if bone < 0: return
	var parent := skeleton.get_bone_parent(bone)
	var axis := up if parent < 0 else (skeleton.get_bone_global_pose(parent).basis.inverse()*up).normalized()
	var turn := Quaternion(axis,angle)
	skeleton.set_bone_pose_rotation(bone,turn*skeleton.get_bone_pose_rotation(bone))
	twist_applied[bone] = turn

func _add_pistol() -> void:
	var socket := BoneAttachment3D.new()
	socket.bone_name = "hand_r"
	skeleton.add_child(socket)
	socket.on_skeleton_update()
	gun = Node3D.new()
	socket.add_child(gun)
	# The grip goes inside the fist of the pistol idle, measured on the finger bones.
	# tools/build_weapon_anims.py uses the same frame, so the long-gun clips land the hands on the grips.
	gun.transform = skeleton.get_bone_global_pose(skeleton.find_bone("hand_r")).affine_inverse()*fist_frame("r")
	muzzle = Marker3D.new()
	gun.add_child(muzzle)
	flash_mesh = Node3D.new()
	muzzle.add_child(flash_mesh)
	# Two crossed, spiky polygons: a deliberately faceted PS1 muzzle flash.
	for pass_index in 2:
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.albedo_color = Color("fff0a3") if pass_index else Color("ff9e32")
		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,material)
		var points := [Vector3(-.12,0,0),Vector3(.12,0,0),Vector3(.065,0,-.18),Vector3(.17,0,-.28),Vector3(.035,0,-.22),Vector3(0,0,-.55),Vector3(-.045,0,-.23),Vector3(-.15,0,-.31),Vector3(-.06,0,-.15)]
		for i in points.size():
			mesh.surface_add_vertex(Vector3(0,0,-.13))
			mesh.surface_add_vertex(points[i])
			mesh.surface_add_vertex(points[(i+1)%points.size()])
		mesh.surface_end()
		for angle in [0.0,PI/2]:
			var plane := MeshInstance3D.new()
			plane.mesh = mesh
			plane.rotation.z = angle
			if pass_index: plane.scale = Vector3.ONE*.55
			flash_mesh.add_child(plane)
	flash_light = OmniLight3D.new()
	flash_light.light_color = Color("ffc274")
	flash_light.light_energy = 1.6
	flash_light.omni_range = 2.2
	flash_light.shadow_enabled = false
	muzzle.add_child(flash_light)
	for bone in ["pelvis","spine_02","upperarm_r","lowerarm_r","hand_r","upperarm_l","lowerarm_l","hand_l"]:
		arm_bones[bone] = skeleton.find_bone(bone)
	pelvis_rest = skeleton.get_bone_global_pose(arm_bones.pelvis).origin
	support_grip = (gun.global_transform.affine_inverse()*skeleton.global_transform*skeleton.get_bone_global_pose(arm_bones.hand_l)).basis
	set_weapon("pistol")
	clear_effects()

func fist_frame(side: String) -> Transform3D:
	## Skeleton space. Origin in the hole of the fist (between the middle finger's knuckle and its
	## curled tip), -Z along the knuckles (barrel), +Y along the hole from pinky to index (grip).
	var at := func(bone: String) -> Vector3: return skeleton.get_bone_global_pose(skeleton.find_bone(bone+"_"+side)).origin
	var axis: Vector3 = (at.call("index_01")-at.call("pinky_01")).normalized()
	var knuckles: Vector3 = at.call("middle_01")-at.call("hand")
	knuckles = (knuckles-axis*knuckles.dot(axis)).normalized()
	return Transform3D(Basis(knuckles.cross(axis),axis,-knuckles),(at.call("middle_01")+at.call("middle_03"))/2)

## A patient's hospital gown: pale blue over the clothes.
const GOWN := Color("bcd4e4")

func dress(index: int,tint := Color(0,0,0,0)) -> void:
	## Evening wear for the Lagoa party (guests and the inquilinos posing as them): the clothes
	## tinted, one tint per guest in turn. Changed in place, so cut-off parts keep it.
	if tint.a == 0: tint = GUEST_TINTS[index%GUEST_TINTS.size()]
	for node in model.find_children("*","MeshInstance3D",true,false):
		for surface in node.get_surface_override_material_count():
			var mat := node.get_surface_override_material(surface) as StandardMaterial3D
			if mat: mat.albedo_color = tint

func set_weapon(name: String) -> void:
	## Puts one of the room's guns in the right hand; the grip is the model's origin.
	if weapon_model: weapon_model.free()
	gun_parts.clear()
	weapon_model = (load("res://assets/weapons/%s.glb" % name) as PackedScene).instantiate()
	gun.add_child(weapon_model)
	for node in weapon_model.find_children("*","MeshInstance3D",true,false):
		for surface in node.mesh.get_surface_count():
			var mat := node.mesh.surface_get_material(surface) as BaseMaterial3D
			if mat:
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				mat.roughness = 1.0
		node.material_override = ghost_gun_material if phasing else null
		gun_parts.append(node)
	if weapon_manifest.is_empty():
		weapon_manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/weapons/weapons.json"))
	var tip: Array = weapon_manifest[name].muzzle
	muzzle.position = Vector3(tip[0],tip[1],tip[2])
	weapon = name
	hip_fire = name in HIP_WEAPONS
	if look: look.refresh()

func _hold_at_hip(data: Dictionary,dt: float) -> void:
	## Right hand brings the gun to the hip, left hand rides the carry handle.
	var to_skeleton := skeleton.global_transform.affine_inverse()*global_transform
	var reloading: bool = data.get("reload",0.0) > 0
	var firing: bool = data.recoil > 0 and not reloading
	hip_push = move_toward(hip_push,1.0 if firing else 0.0,dt*(12.0 if firing else 5.0))
	var hum := maxf(hip_push,.3*float(data.get("spin",0.0))/HIP_SPIN_UP)
	hip_clock += dt
	var buzz := Vector3(sin(hip_clock*97.0)*.005,sin(hip_clock*131.0)*.007,sin(hip_clock*83.0)*.009)*hum
	# Lean back against the weight instead of the pistol stance's forward hunch, into the gun when firing.
	var spine := skeleton.get_bone_global_pose(arm_bones.spine_02)
	spine.basis = Basis(to_skeleton.basis*Vector3.RIGHT,HIP_LEAN+HIP_PUSH_LEAN*hip_push)*spine.basis
	skeleton.set_bone_global_pose(arm_bones.spine_02,spine)
	var grip :=HIP_GRIP+skeleton.get_bone_global_pose(arm_bones.pelvis).origin-pelvis_rest
	if reloading: grip.y -= .06
	grip += buzz+Vector3(0,0,-HIP_PUSH_BACK*hip_push)
	var wobble := Basis(Vector3.RIGHT,sin(hip_clock*71.0)*.012*hum)
	var hold := to_skeleton*Transform3D(Basis(Vector3.UP,PI)*wobble,grip)
	var hand := hold*gun.transform.affine_inverse()
	_reach(arm_bones.upperarm_r,arm_bones.lowerarm_r,arm_bones.hand_r,hand,to_skeleton.basis*Vector3(-.5,-.3,-.8))
	var support := Transform3D(hold.basis*Basis(Vector3.BACK,HIP_SUPPORT_TWIST)*support_grip,hold*(HIP_CAN if reloading else HIP_HANDLE))
	_reach(arm_bones.upperarm_l,arm_bones.lowerarm_l,arm_bones.hand_l,support,to_skeleton.basis*Vector3(.9,-.3,-.2))
	(gun.get_parent() as BoneAttachment3D).on_skeleton_update()

func _reach(upper: int,lower: int,hand: int,target: Transform3D,pole: Vector3) -> void:
	## Two-bone IK in skeleton space: the elbow bends toward the pole, the hand takes the target's rotation.
	var shoulder := skeleton.get_bone_global_pose(upper)
	var elbow := skeleton.get_bone_global_pose(lower).origin
	var wrist := skeleton.get_bone_global_pose(hand).origin
	var a := shoulder.origin.distance_to(elbow)
	var b := elbow.distance_to(wrist)
	var reach := target.origin-shoulder.origin
	var d := clampf(reach.length(),absf(a-b)+.001,a+b-.001)
	var dir := reach.normalized()
	var bend := (pole-dir*pole.dot(dir)).normalized()
	var cos_a := (a*a+d*d-b*b)/(2*a*d)
	var new_elbow := shoulder.origin+dir*a*cos_a+bend*a*sqrt(maxf(0,1-cos_a*cos_a))
	# Orthonormalized every time: these bones have no scale tracks, so float error would accumulate.
	shoulder.basis = (Basis(Quaternion((elbow-shoulder.origin).normalized(),(new_elbow-shoulder.origin).normalized()))*shoulder.basis).orthonormalized()
	skeleton.set_bone_global_pose(upper,shoulder)
	var forearm := skeleton.get_bone_global_pose(lower)
	wrist = skeleton.get_bone_global_pose(hand).origin
	forearm.basis = (Basis(Quaternion((wrist-forearm.origin).normalized(),(shoulder.origin+dir*d-forearm.origin).normalized()))*forearm.basis).orthonormalized()
	skeleton.set_bone_global_pose(lower,forearm)
	var palm := skeleton.get_bone_global_pose(hand)
	palm.basis = target.basis.orthonormalized()
	skeleton.set_bone_global_pose(hand,palm)

func fire_flash() -> void:
	flash_time = .065
	flash_mesh.visible = true
	flash_light.visible = true

func clear_effects() -> void:
	flash_time = 0
	if flash_mesh: flash_mesh.hide()
	if flash_light: flash_light.hide()
	if phasing: _set_phasing(false)
	for entry in afterimages: entry.node.queue_free()
	afterimages.clear()
	ring_time = 0
	if ring: ring.hide()

func _set_phasing(active: bool) -> void:
	phasing = active
	if body_parts: body_parts.set_material_override(ghost_material if active else null)
	for part in gun_parts: part.material_override = ghost_gun_material if active else null
	afterimage_clock = 0.0

func _update_phase(active: bool,mana: float,moving: bool,dt: float,paused: bool) -> void:
	if not ghost_material: return
	if active != phasing:
		_set_phasing(active)
		ring_time = RING_LIFE
	if paused: return
	phase_clock += dt
	if phasing:
		# Stepped PS1-style flicker that stutters harder as the charge runs out.
		var step := floori(phase_clock*18)
		var alpha := .42+.08*sin(step*2.3)
		if mana < 25 and step%3 == 0: alpha = .12
		ghost_material.albedo_color.a = alpha
		xray_material.albedo_color.a = alpha*.5
		afterimage_clock -= dt
		if moving and afterimage_clock <= 0:
			afterimage_clock = AFTERIMAGE_INTERVAL
			_spawn_afterimage()
	for i in range(afterimages.size()-1,-1,-1):
		var entry := afterimages[i]
		entry.age += dt
		var t: float = entry.age/AFTERIMAGE_LIFE
		if t >= 1:
			entry.node.queue_free()
			afterimages.remove_at(i)
			continue
		entry.material.albedo_color.a = .3*(1-t)
	ring_time = maxf(0,ring_time-dt)
	ring.visible = ring_time > 0
	if ring.visible:
		var t := 1.0-ring_time/RING_LIFE
		var size := lerpf(.6,2.8,t)
		ring.scale = Vector3(size,1,size)
		ring_material.albedo_color.a = .8*(1-t)

func _spawn_afterimage() -> void:
	# A frozen, additive copy of the current pose left behind in world space.
	var mesh: ArrayMesh = body_parts.pose_snapshot()
	if mesh.get_surface_count() == 0: return
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = Color(.3,.85,1.0,.3)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.top_level = true
	add_child(node)
	node.global_transform = Transform3D.IDENTITY
	afterimages.append({"node":node,"material":material,"age":0.0})
	if afterimages.size() > MAX_AFTERIMAGES: afterimages.pop_front().node.queue_free()

func sync(data: Dictionary,dt: float,paused: bool) -> void:
	position = Vector3(data.p.x,0,data.p.y)
	rotation.y = -data.angle+PI/2
	if knock_time >= 0:
		# Thrown along the shot, facing whoever fired it; the corpse stays where it lands.
		if not paused: knock_time += dt
		var travel := 1.0-pow(1.0-minf(knock_time/KNOCK_SLIDE,1.0),2)
		position += Vector3(knock_dir.x,0,knock_dir.y)*knock_reach*travel
		rotation.y = -(-knock_dir).angle()+PI/2
	if drop_time >= 0:
		if not paused: drop_time += dt
		var fall := minf(drop_time/DROP_FALL,1.0)
		position.y = DROP_HEIGHT*(1.0-fall*fall)   # falling, faster and faster
		if drop_time >= DROP_FALL+DROP_CRUMPLE or not data.alive: drop_time = -1.0
	if not animator: return
	_select_locomotion(data)
	var stance: Array = GUN_CLIPS.get(weapon,PISTOL_CLIPS)
	var key: String = stance[0]
	# Only enemies carry "alerted"; the hero and the newscast actors never pose.
	var posing: bool = not pose.is_empty() and data.alive and not bool(data.get("alerted",true)) and data.recoil <= 0
	if not data.alive: key = KNOCK_CLIP if knock_time >= 0 else "Death01"
	elif drop_time >= 0: key = DROP_KEY
	elif float(data.get("rising",0.0)) > 0: key = RISE_KEY   # occupied, the corpse gets up
	elif data.get("reload",0.0) > 0: key = stance[2]
	elif data.recoil > 0 and stance[1] != "": key = stance[1]
	elif weapon == "katana" and float(data.get("swing",-1.0)) >= 0:
		var cut: String = SLASHES[(int(data.swings)+1)%2]   # first cut A, then B, then A...
		if data.swing < animator.get_animation(cut).length: key = cut
	elif posing: key = POSES[pose].clip
	elif guest and data.moving: key = "Jog_Fwd_Loop"   # running for the door, nothing in hand
	# Long guns keep their own upper body while walking; the legs come from the gait below.
	elif data.moving and stance == PISTOL_CLIPS: key = "armed_"+locomotion_name
	if int(data.get("swings",0)) != last_swings:
		last_swings = int(data.get("swings",0))
		if key in SLASHES: current = ""   # every click starts its cut from the top, even a repeat
	var clip: String = key if key.begins_with("ual2/") else clips.get("Death01" if key in [RISE_KEY,DROP_KEY] else key,clips.get("Pistol_Idle_Loop","RESET"))
	var fired: bool = data.recoil > last_recoil   # every shot resets the recoil timer
	last_recoil = data.recoil
	if current != key:
		current = key
		# A kick lands within a frame or two: no blend into the shot, or it would swallow the peak.
		animator.play(clip,0.0 if key == stance[1] or key in SLASHES or key == DROP_KEY else (.07 if data.alive else .02))
		var length := animator.get_animation(clip).length
		if key == stance[2]: animator.speed_scale = length/maxf(data.reload,.05)   # reload fills the gun's reload time
		elif key == DROP_KEY:
			animator.seek(0.0,true)
			animator.speed_scale = 0.0   # upright while it falls; the crumple starts on landing
		elif key == RISE_KEY:
			# The fall played backwards over the rise time: off the floor and back on its feet.
			animator.play_backwards(clip,0.0)
			animator.speed_scale = length/maxf(float(data.rising),.05)
		else: animator.speed_scale = 1.0
		if key == KNOCK_CLIP: animator.seek(KNOCK_FROM,true)
		# Each poser starts somewhere else in the loop, so the bar does not sip in unison.
		elif posing: animator.seek(fposmod(get_instance_id()*.618,1.0)*length,true)
		if posing and POSES[pose].get("still",false):
			animator.seek(.2*length,true)   # the glass at the chest, and it stays there
			animator.speed_scale = 0.0
	elif fired and key == stance[1]:
		animator.seek(0.0)   # automatic fire restarts the kick on every round
	if key.begins_with("armed_"): animator.speed_scale = locomotion_rate
	if key == DROP_KEY and drop_time >= DROP_FALL: animator.speed_scale = animator.get_animation(clip).length/DROP_CRUMPLE
	if not paused:
		# A bone no clip keys would keep last frame's twist: take it off before the animation runs.
		for bone in twist_applied: skeleton.set_bone_pose_rotation(bone,twist_applied[bone].inverse()*skeleton.get_bone_pose_rotation(bone))
		twist_applied.clear()
		var step := dt
		if halved_hold > 0:   # cut in half: the legs stand still, then fold with what is left of the frame
			step = maxf(0,dt-halved_hold)
			halved_hold = maxf(0,halved_hold-dt)
		animator.advance(step)
		flash_time = maxf(0,flash_time-dt)
		flash_mesh.visible = flash_time > 0 and data.alive
		flash_light.visible = flash_mesh.visible
		# Keep the supplied leg animation running under upper-body shooting/reload.
		# Holding fire while moving must not freeze the gait every 0.26 seconds.
		if data.alive and data.moving and locomotion:
			locomotion_time = fposmod(locomotion_time+dt*locomotion_rate,locomotion.length)
			for pair in leg_tracks:
				match locomotion.track_get_type(pair.x):
					Animation.TYPE_ROTATION_3D:
						skeleton.set_bone_pose_rotation(pair.y,locomotion.rotation_track_interpolate(pair.x,locomotion_time))
					Animation.TYPE_POSITION_3D:
						skeleton.set_bone_pose_position(pair.y,locomotion.position_track_interpolate(pair.x,locomotion_time))
					Animation.TYPE_SCALE_3D:
						skeleton.set_bone_pose_scale(pair.y,locomotion.scale_track_interpolate(pair.x,locomotion_time))
		_twist_legs(data,dt)
		if hip_fire and data.alive: _hold_at_hip(data,dt)
	# No gun in hand until a risen body is on its feet.
	if gun: gun.visible = data.alive and not guest and not (posing and not POSES[pose].gun) and key not in [DROP_KEY,RISE_KEY]
	if prop: prop.visible = posing
	_update_phase(bool(data.get("phasing",false)) and data.alive,float(data.get("mana",100.0)),data.moving,dt,paused)
	if look: look.update(data,dt,paused)
