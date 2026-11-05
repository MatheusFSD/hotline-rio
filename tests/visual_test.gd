extends SceneTree
const Visual = preload("res://scripts/actor_visual.gd")
const Sim = preload("res://scripts/simulation.gd")
var failures := 0
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for name in ["hero","enemy_a","enemy_b"]:
		var visual := Visual.new()
		root.add_child(visual)
		visual.setup("res://assets/characters/"+name+".glb")
		check(visual.skeleton != null and visual.skeleton.get_bone_count() >= 60,name+" skeleton")
		check(visual.clips.size() == 20,name+" six imported clips, forward/backwards armed gaits and ten keyed gun clips")
		var mesh: MeshInstance3D
		for node in visual.model.find_children("*","MeshInstance3D",true,false): mesh = node; break
		var arrays := mesh.mesh.surface_get_arrays(0)
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var distinct := {}
		for i in bones.size():
			if weights[i] > .001: distinct[bones[i]] = true
		check(distinct.size() > 20,name+" skinned to actual body bones, not a neutral fallback bone")
		var d: Dictionary = Sim.actor(Vector2.ZERO,-PI/2)
		d.merge({"reload":0.0})
		visual.sync(d,.1,false)
		var direction := Vector3(cos(d.angle),0,sin(d.angle))
		check((visual.global_basis*Vector3.BACK).dot(direction) > .99,name+" body faces aim")
		var barrel := -visual.gun.global_basis.z
		check(barrel.normalized().dot(direction) > .9,name+" gun barrel faces aim")
		var socket: BoneAttachment3D = visual.gun.get_parent()
		var to_skeleton: Transform3D = visual.skeleton.global_transform.affine_inverse()
		socket.on_skeleton_update()
		check((to_skeleton*visual.gun.global_position).distance_to(visual.fist_frame("r").origin) < .01,name+" pistol grip sits inside the fist")
		for gun in ["smg","shotgun","rifle"]:
			visual.set_weapon(gun)
			visual.sync(d,.2,false)
			visual.sync(d,1.0/60,false)   # the new clip's pose shows from the frame after the switch
			socket.on_skeleton_update()
			var tip: Array = visual.weapon_manifest[gun].support
			var support: Vector3 = to_skeleton*visual.gun.global_transform*Vector3(tip[0],tip[1],tip[2])
			var aim := (visual.global_basis.inverse()*-visual.gun.global_basis.z).normalized()
			check(visual.animator.current_animation == "guns/"+visual.GUN_CLIPS[gun][0] and aim.z > .95,name+" "+gun+" idle clip aims forward")
			d.recoil = .24
			for step in [.001,.035,.0001]: visual.sync(d,step,false)   # the kick peaks ~35 ms in
			socket.on_skeleton_update()
			var kicked := (visual.global_basis.inverse()*-visual.gun.global_basis.z).normalized()
			check(rad_to_deg(asin(kicked.y)-asin(aim.y)) > 2.0,name+" "+gun+" shot kicks the muzzle up")
			d.recoil = 0
			visual.sync(d,.4,false)
			visual.sync(d,1.0/60,false)
			socket.on_skeleton_update()
			check(visual.fist_frame("l").origin.distance_to(support) < .09,name+" "+gun+" left hand on its support grip (%.3f m off)" % visual.fist_frame("l").origin.distance_to(support))
		visual.set_weapon("pistol")
		visual.sync(d,.2,false)
		var hand := visual.skeleton.find_bone("hand_r")
		var leg := visual.skeleton.find_bone("calf_l")
		var idle_hand := visual.skeleton.get_bone_global_pose(hand)
		var idle_leg := visual.skeleton.get_bone_global_pose(leg)
		d.moving = true
		d.velocity = Vector2(.925,0)
		visual.sync(d,.2,false)
		check(visual.current == "armed_walk" and visual.locomotion == visual.animator.get_animation(visual.clips.Walk_Loop),name+" patrol uses actual walk clip")
		check(not visual.skeleton.get_bone_global_pose(leg).is_equal_approx(idle_leg),name+" walking moves leg bones")
		var slow_rate := visual.locomotion_rate
		d.velocity = Vector2(1.25,0)
		visual.sync(d,.1,false)
		check(visual.locomotion_rate > slow_rate and visual.current == "armed_walk",name+" walk cadence follows real speed")
		d.velocity = Vector2(2.15,0)
		visual.sync(d,.2,false)
		check(visual.current == "armed_run" and visual.locomotion == visual.animator.get_animation(visual.clips.Jog_Fwd_Loop),name+" pursuit switches to actual jog clip")
		d.velocity = Vector2(0,2.15)
		visual.sync(d,.15,false)
		check(visual.current == "armed_run_back" and visual.locomotion.resource_path.ends_with("run_backward.tres"),name+" retreat selects authored backwards run")
		check((visual.global_basis*Vector3.BACK).dot(direction) > .99,name+" backwards run preserves aiming direction")
		var forward := visual.animator.get_animation(visual.clips.Jog_Fwd_Loop)
		var reverse := visual.locomotion
		var original_track := forward.find_track(NodePath("RioRig/Skeleton3D:calf_l"),Animation.TYPE_ROTATION_3D)
		var reversed_track := reverse.find_track(NodePath("RioRig/Skeleton3D:calf_l"),Animation.TYPE_ROTATION_3D)
		check(original_track >= 0 and reversed_track >= 0 and reverse.rotation_track_interpolate(reversed_track,.2).angle_to(forward.rotation_track_interpolate(original_track,forward.length-.2)) < .02,name+" backwards leg cycle derives from reversed forward poses")
		d.recoil = .24
		visual.sync(d,.1,false)
		check(visual.current == "Pistol_Kick" and visual.locomotion_name == "run_back",name+" firing keeps backwards locomotion under upper body")
		d.recoil = 0
		d.velocity = Vector2(0,.925)
		visual.sync(d,.15,false)
		check(visual.current == "armed_walk_back",name+" slow retreat selects backwards walk")
		d.velocity = Vector2(2.15,0)
		visual.sync(d,.1,false)
		check(visual.current == "armed_run",name+" lateral movement exits backwards gait without flipping aim")
		d.moving = false; d.recoil = .24
		visual.sync(d,.12,false)
		check(visual.current == "Pistol_Kick" and not visual.skeleton.get_bone_global_pose(hand).is_equal_approx(idle_hand),name+" shooting moves hand bones")
		d.recoil = 0; d.reload = .75
		d.moving = true
		visual.sync(d,.3,false)
		check(visual.current == "Pistol_Reload",name+" reload animation")
		var reloading_leg := visual.skeleton.get_bone_pose_rotation(leg)
		visual.sync(d,.15,false)
		check(not reloading_leg.is_equal_approx(visual.skeleton.get_bone_pose_rotation(leg)),name+" gait continues while reloading")
		var position := visual.animator.current_animation_position
		var gait_time := visual.locomotion_time
		visual.fire_flash()
		visual.sync(d,.2,true)
		check(is_equal_approx(position,visual.animator.current_animation_position),name+" pause freezes animation")
		check(is_equal_approx(gait_time,visual.locomotion_time) and visual.flash_time > 0,name+" pause freezes gait and muzzle flash")
		visual.clear_effects()
		check(not visual.flash_mesh.visible and not visual.flash_light.visible,name+" restart clears weapon flash")
		d.alive = false
		visual.sync(d,2.5,false)
		check(visual.current == "Death01" and not visual.gun.visible,name+" death pose and hidden weapon")
		visual.sync(d,.1,false)
		check(visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("pelvis")).origin.y < .65,name+" death settles on the floor")
		visual.queue_free()
	await process_frame
	print("VISUALS: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
