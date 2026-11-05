extends SceneTree
## Walking and running in every direction while aiming one way: the feet must stride along the
## direction of travel (no sliding sideways), and the chest and gun must stay on the aim.
const Visual = preload("res://scripts/actor_visual.gd")
const Sim = preload("res://scripts/simulation.gd")
var failures := 0
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")

func flat(v: Vector3) -> Vector2: return Vector2(v.x,v.z)

func stride_axis(visual,d: Dictionary) -> Vector2:
	## Principal horizontal axis along which the feet separate over one gait cycle.
	var samples: Array[Vector2] = []
	var left: int = visual.skeleton.find_bone("foot_l")
	var right: int = visual.skeleton.find_bone("foot_r")
	var frames := int(ceil(visual.locomotion.length/visual.locomotion_rate*60))+2
	for i in frames:
		visual.sync(d,1.0/60,false)
		var to_world: Transform3D = visual.skeleton.global_transform
		samples.append(flat(to_world*visual.skeleton.get_bone_global_pose(left).origin-to_world*visual.skeleton.get_bone_global_pose(right).origin))
	var mean := Vector2.ZERO
	for s in samples: mean += s
	mean /= samples.size()
	var xx := 0.0; var xy := 0.0; var yy := 0.0
	for s in samples:
		var v := s-mean
		xx += v.x*v.x; xy += v.x*v.y; yy += v.y*v.y
	return Vector2.from_angle(.5*atan2(2*xy,xx-yy))

func chest(visual) -> Vector2:
	## Where the chest points, in the actor's own frame (independent of the aim angle).
	var bone: int = visual.skeleton.find_bone("spine_03")
	var basis: Basis = visual.global_basis.inverse()*visual.skeleton.global_basis*visual.skeleton.get_bone_global_pose(bone).basis
	return flat(basis*Vector3.FORWARD).normalized()

func run() -> void:
	for name in ["hero","enemy_a"]:
		var visual := Visual.new()
		root.add_child(visual)
		visual.setup("res://assets/characters/"+name+".glb")
		var d: Dictionary = Sim.actor(Vector2.ZERO,-PI/2)
		d.merge({"reload":0.0})
		d.moving = true
		d.velocity = Vector2(0,-3.2)
		for i in 40: visual.sync(d,1.0/60,false)
		var reference := chest(visual)
		var gun_reference := flat(visual.global_basis.inverse()*-visual.gun.global_basis.z).normalized()
		for speed in [.925,3.2]:
			for degrees in [0,45,90,135,180,-45,-90,-135]:
				var travel: float = d.angle+deg_to_rad(degrees)
				d.velocity = Vector2.from_angle(travel)*speed
				for i in 40: visual.sync(d,1.0/60,false)
				var axis := stride_axis(visual,d)
				var off := rad_to_deg(absf(asin(clampf(axis.cross(Vector2.from_angle(travel)),-1,1))))
				var label := "%s %s %+d°" % [name,"walk" if speed < 1 else "run",degrees]
				check(off < 20,"%s: feet stride along the direction of travel (%.0f° off, %s)" % [label,off,visual.locomotion_name])
				check(rad_to_deg(chest(visual).angle_to(reference)) < 6,"%s: chest stays on the aim (%.1f°)" % [label,rad_to_deg(absf(chest(visual).angle_to(reference)))])
				var gun := flat(visual.global_basis.inverse()*-visual.gun.global_basis.z).normalized()
				check(rad_to_deg(absf(gun.angle_to(gun_reference))) < 6,"%s: gun stays on the aim (%.1f°)" % [label,rad_to_deg(absf(gun.angle_to(gun_reference)))])
		# A long sideways run must not pile the twist up frame after frame.
		d.velocity = Vector2.from_angle(d.angle+PI/2)*3.2
		for i in 600: visual.sync(d,1.0/60,false)
		check(rad_to_deg(absf(chest(visual).angle_to(reference))) < 6,"%s: ten seconds sideways, the chest is still on the aim" % name)
		var held: Quaternion = visual.skeleton.get_bone_pose_rotation(visual.skeleton.find_bone("pelvis"))
		for i in 30: visual.sync(d,1.0/60,true)
		check(held.is_equal_approx(visual.skeleton.get_bone_pose_rotation(visual.skeleton.find_bone("pelvis"))),"%s: pause holds the twisted hips as they are" % name)
		d.moving = false
		d.velocity = Vector2.ZERO
		for i in 30: visual.sync(d,1.0/60,false)
		check(absf(visual.leg_twist) < .02,"%s: standing still, the hips turn back under the chest (%.3f)" % [name,visual.leg_twist])
		visual.queue_free()
	await process_frame
	print("STRAFE: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
