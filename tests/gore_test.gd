extends SceneTree
const Visual = preload("res://scripts/actor_visual.gd")
const Sim = preload("res://scripts/simulation.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func fingerprint(animation: Animation) -> int:
	var signature: Array = [animation.length,animation.loop_mode]
	for i in animation.get_track_count():
		signature.append(animation.track_get_path(i))
		signature.append(animation.track_get_type(i))
		for key in animation.track_get_key_count(i):
			signature.append(animation.track_get_key_time(i,key))
			signature.append(animation.track_get_key_value(i,key))
	return hash(signature)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for name in ["hero","enemy_a","enemy_b"]:
		var visual := Visual.new()
		root.add_child(visual)
		visual.setup("res://assets/characters/"+name+".glb")
		check(visual.body_parts.parts.size() == 7,name+" has all seven body regions")
		var original_triangles: int = visual.body_parts.source.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()
		var split_triangles := 0
		for node in visual.body_parts.parts.values(): split_triangles += node.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()
		check(original_triangles == split_triangles,name+" triangle partition preserves complete original mesh")
		var death := visual.animator.get_animation(visual.clips.Death01)
		var stamp := fingerprint(death)
		var d := Sim.actor(Vector2(2,3),-.7)
		d.alive = false
		visual.sync(d,.05,false)
		for region in ["head","arm_l","arm_r","leg_l","leg_r"]:
			visual.reset_damage()
			var before := visual.animator.current_animation_position
			var pelvis := visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("pelvis"))
			var fragments := visual.detach_part(region)
			check(not fragments.is_empty() and (region != "head" or fragments.size() >= 2),name+" detaches textured "+region)
			check(not visual.body_parts.parts[region].visible and visual.body_parts.parts.torso.visible,name+" removes only selected "+region)
			check(visual.animator.current_animation_position == before and visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("pelvis")).is_equal_approx(pelvis),name+" severing "+region+" leaves death clock and skeleton untouched")
			for fragment in fragments:
				check(fragment.skin == null and fragment.mesh.surface_get_material(0) != null,name+" detached geometry is rigid and textured")
				fragment.free()
			check(visual.detach_part(region).is_empty(),name+" cannot detach the same region twice")
			visual.sync(d,.02,false)
		visual.reset_damage()
		var clock := visual.animator.current_animation_position
		var cut: Dictionary = visual.cut_in_half()
		var upper: MeshInstance3D = cut.get("upper")
		var parts: Dictionary = visual.body_parts.parts
		check(upper != null and upper.skin == null and upper.has_node("Cut"),name+" cut in half: the top becomes one rigid piece with a cap over the cut")
		check(not parts.torso.visible and not parts.head.visible and not parts.arm_l.visible and parts.hips.visible and parts.leg_l.visible and parts.leg_r.visible,name+" cut in half keeps hips and legs on the skeleton")
		check(visual.cut_in_half().is_empty(),name+" cannot be cut in half twice")
		visual.sync(d,.2,false)
		check(visual.animator.current_animation_position == clock,name+" cut legs stand a beat before folding")
		visual.sync(d,.3,false)
		check(visual.animator.current_animation_position > clock,name+" cut legs then fold with the original death clip")
		upper.free()
		check(fingerprint(death) == stamp and visual.current == "Death01",name+" original death animation tracks and timing are unchanged")
		visual.reset_damage()
		check(visual.body_parts.removed.is_empty() and visual.body_parts.parts.head.visible and visual.body_parts.parts.leg_l.visible,name+" restart restores missing body parts")
		visual.queue_free()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_or_resume()
	var roll := RandomNumberGenerator.new()
	roll.seed = 76489
	var counts := {"":0,"head":0,"arm_l":0,"arm_r":0,"leg_l":0,"leg_r":0}
	for i in 1000: counts[game.sim.gore_variant("pistol",roll)] += 1
	check(counts[""] > 450 and counts[""] < 650,"Most pistol kills keep a normal corpse")
	check(not counts.has("half"),"Pistol never cuts a body in half")
	for weapon in ["shotgun","rifle"]:
		var heavy := {}
		for i in 1000:
			var region: String = game.sim.gore_variant(weapon,roll)
			heavy[region] = heavy.get(region,0)+1
		check(not heavy.has("") and heavy.get("half",0) > 180 and heavy.get("head",0) > 180,weapon+" always dismembers and sometimes cuts in half: %s" % [heavy])
	var smg := 0
	for i in 400: smg += int(game.sim.gore_variant("smg",roll) == "")
	check(smg > 160,"SMG keeps the pistol odds")
	check(range(50).all(func(i): return game.sim.gore_variant("minigun",roll) == "half"),"Minigun always cuts in half")
	for region in ["head","arm_l","arm_r","leg_l","leg_r"]: check(counts[region] > 25,"Random fatal hits include "+region)
	var victim: Dictionary = game.sim.enemies[0]
	game.sim.kill(victim,Vector2.UP)
	check(game.sim.events[-1].victim == 1 and game.sim.events[-1].gore_allowed and game.sim.events[-1].weapon == "pistol","Real projectile kill identifies its victim and gun for gore")
	check(game.sim.events[-1].gore == victim.gore and game.sim.events[-1].kind == "human","The simulation rolls the gore and keeps it on the body; effects only draw it")
	# A rule, so a retry rolls the same bodies the same way.
	var rolls := []
	for attempt in 2:
		var s = load("res://scripts/simulation.gd").new()
		s.attempt = 4
		s.reset(false)
		rolls.append(range(6).map(func(i): s.kill(s.enemies[i],Vector2.UP,"smg"); return s.enemies[i].gore))
	check(rolls[0] == rolls[1],"The same attempt dismembers the same way (%s)" % [rolls[0]])
	game.actors[1].sync(victim,.016,false)
	game.effects.dismember(game.actors[1],"leg_l",Vector2.UP)
	var gibs := 0
	for bit in game.effects.bits:
		if bit.get("gib",false): gibs += 1
	check(gibs == 1,"Severed leg becomes a physical textured fragment")
	for i in 180: game.effects.update(1.0/60)
	var settled := true
	for bit in game.effects.bits:
		if bit.get("gib",false):
			var box: AABB = bit.node.transform*bit.node.get_aabb()
			settled = settled and box.position.y >= .10 and bit.landed
	check(settled,"Detached limb settles above the floor")
	# Minigun kill: the top half flies off and settles, the stump spurts, both halves stay.
	var second: Dictionary = game.sim.enemies[1]
	second.alive = false
	game.actors[2].sync(second,.016,false)
	game.effects.consume([{"type":"blood","p":second.p,"direction":Vector2.RIGHT,"player":false,"victim":2,"gore_allowed":true,"gore":"half","weapon":"minigun"}] as Array[Dictionary],game.actors)
	var halves: Array = game.effects.bits.filter(func(bit): return bit.get("keep",false))
	check(halves.size() == 1 and not game.actors[2].body_parts.parts.torso.visible,"Minigun kill cuts the body in half")
	var start: Vector3 = halves[0].node.position
	check(not game.effects.fountains.is_empty(),"Both cut ends spurt blood")
	for i in 240: game.effects.update(1.0/60)
	var half: Dictionary = halves[0]
	var rest: AABB = half.node.transform*half.node.get_aabb()
	check(half.landed and rest.position.y >= .1 and Vector2(half.node.position.x-start.x,half.node.position.z-start.z).dot(Vector2.RIGHT) > .5,"Top half is thrown along the shot and settles on the floor")
	for i in 300: game.effects._add_bit(Vector3.ZERO,Vector3.UP,Color.RED,Vector3.ONE*.05,30.0)
	check(game.effects.bits.has(half) and game.effects.fountains.is_empty(),"Body halves outlast the bit limit; spurts stop")
	game.start_or_resume()
	check(game.effects.bits.is_empty() and game.actors[1].body_parts.removed.is_empty() and game.actors[2].body_parts.parts.torso.visible,"Restart clears fragments and restores corpse geometry")
	game.queue_free()
	await process_frame
	print("GORE: ",checks-failures,"/",checks," checks passed; distribution ",counts)
	quit(1 if failures else 0)
