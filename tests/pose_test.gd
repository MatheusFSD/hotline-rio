extends SceneTree
## Unaware poses and the heavy-gun knockback death, both from Universal Animation Library 2.
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func step(visual,data: Dictionary,frames: int) -> void:
	for i in frames: visual.sync(data,1.0/60,false)
func run() -> void:
	var library: AnimationLibrary = load("res://assets/animations/ual2_clips.res")
	check(library.has_animation("Drink_Loop") and library.has_animation("Hit_Knockback") and library.has_animation("Idle_TalkingPhone_Loop") and library.has_animation("Idle_FoldArms_Loop"),"The UAL2 clips are in the library")
	check(absf(library.get_animation("Drink_Loop").length-library.get_animation("Consume").length-3.0) < .01,"Drinking is a sip and a pause, not nonstop")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.sim.reset()
	game.sim.state = "playing"
	var poses := {}
	for i in game.sim.enemies.size(): poses[game.actors[i+1].pose] = true
	check(poses.has("drink") and poses.has("phone") and poses.has("arms") and game.actors[0].pose == "","Enemies take their poses from level.json; the hero never poses")
	# Find one enemy of each pose.
	var by_pose := {}
	for i in game.sim.enemies.size(): by_pose[game.actors[i+1].pose] = i
	for name in ["drink","phone","arms"]:
		var index: int = by_pose[name]
		var visual = game.actors[index+1]
		var data: Dictionary = game.sim.enemies[index]
		data.moving = false
		step(visual,data,3)
		var spec: Dictionary = visual.POSES[name]
		check(visual.current == spec.clip,"%s: an unaware enemy holds the pose (%s)" % [name,visual.current])
		check(visual.gun.visible == spec.gun,"%s: the gun is %s" % [name,"kept in hand" if spec.gun else "put away"])
		check((visual.prop != null and visual.prop.visible) == not String(spec.prop).is_empty(),"%s: the prop shows in the posing hand" % name)
		var leg: int = visual.skeleton.find_bone("calf_l")
		var still: Quaternion = visual.skeleton.get_bone_pose_rotation(leg)
		data.moving = true
		data.velocity = Vector2(.925,0)
		step(visual,data,12)
		check(visual.current == spec.clip and not still.is_equal_approx(visual.skeleton.get_bone_pose_rotation(leg)),"%s: the pose rides on the patrol walk" % name)
		data.alerted = true
		data.moving = false
		step(visual,data,3)
		check(visual.current == "Pistol_Idle_Loop" and visual.gun.visible and (visual.prop == null or not visual.prop.visible),"%s: alerted, the enemy is armed again" % name)
		data.alerted = false
	# Heavy guns throw the body back; a pistol does not.
	var shot: int = by_pose["drink"]
	var victim: Dictionary = game.sim.enemies[shot]
	var body = game.actors[shot+1]
	victim.p = Vector2(-3.0,-2.5)
	# A quarter of shotgun kills cut the body in half instead; pick a gore roll that does not.
	var seed := 1
	while true:
		game.sim.gore_rng.seed = seed
		if game.sim.gore_rng.randf() >= .25: break
		seed += 1
	game.sim.gore_rng.seed = seed
	game.sim.kill(victim,Vector2.RIGHT,"shotgun")
	game.effects.consume(game.sim.events,game.actors)
	step(body,victim,90)
	var landed: Vector3 = body.position
	check(body.current == body.KNOCK_CLIP,"A shotgun kill plays the knockback fall")
	check(absf(landed.x-(-3.0+game.effects.KNOCKBACK_REACH)) < .02 and absf(landed.z+2.5) < .02,"The body slides back along the shot (%.2f m)" % (landed.x+3.0))
	check((body.global_basis*Vector3.BACK).dot(Vector3.LEFT) > .99,"The body faces the shooter as it falls")
	var pelvis: Vector3 = body.skeleton.global_transform*body.skeleton.get_bone_global_pose(body.skeleton.find_bone("pelvis")).origin
	check(pelvis.y < .3,"It ends on the floor (pelvis %.2f m)" % pelvis.y)
	body.reset_damage()
	victim.alive = true
	step(body,victim,2)
	check(body.knock_time < 0 and Vector2(body.position.x,body.position.z).distance_to(victim.p) < .01,"A restart puts the body back where the simulation has it")
	var near_wall: Dictionary = game.sim.enemies[by_pose["phone"]]
	var wall_body = game.actors[by_pose["phone"]+1]
	near_wall.p = Vector2(3.1,-4.0)   # the kitchen partition starts at x 3.6 (z -7.3 to -2.6)
	game.sim.gore_rng.seed = seed
	game.sim.kill(near_wall,Vector2.RIGHT,"rifle")
	game.effects.consume(game.sim.events,game.actors)
	check(wall_body.knock_time >= 0 and wall_body.knock_reach < .3,"A wall stops the slide (%.2f m)" % wall_body.knock_reach)
	var calm: Dictionary = game.sim.enemies[by_pose["arms"]]
	var calm_body = game.actors[by_pose["arms"]+1]
	game.sim.kill(calm,Vector2.RIGHT,"pistol")
	game.effects.consume(game.sim.events,game.actors)
	step(calm_body,calm,3)
	check(calm_body.current == "Death01" and calm_body.knock_time < 0,"A pistol kill keeps the original Death01")
	game.queue_free()
	await process_frame
	print("POSES: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
