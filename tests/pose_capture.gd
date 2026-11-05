extends SceneTree
## Close frames of the unaware poses (drink, phone, arms folded, standing and walking) and of a
## shotgun knockback death, saved to .qa/poses.
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../.qa/poses/"+name+".png"))
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../.qa/poses"))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.overlay.hide()
	game.hud.hide()
	game.sim.reset()
	game.sim.state = "playing"
	# Three posers side by side in the salon, the hero out of the way.
	game.sim.player.p = Vector2(-9.5,-5.0)
	var spots := [Vector2(-3.4,-2.9),Vector2(-2.2,-2.9),Vector2(-1.0,-2.9)]
	var who := [1,2,0]   # drink, phone, arms
	for k in 3:
		var e: Dictionary = game.sim.enemies[who[k]]
		e.p = spots[k]
		e.angle = PI/2
		e.moving = false
	for step in 50:
		for i in game.actors.size(): game.actors[i].sync(game.sim.player if i==0 else game.sim.enemies[i-1],1.0/60,false)
	game._frame(Vector3(-2.2,0,-2.9),4.0)
	await save("poses_standing")
	for k in 3:
		var e: Dictionary = game.sim.enemies[who[k]]
		e.moving = true
		e.velocity = Vector2(0,.925)
	for step in 40:
		for k in 3: game.actors[who[k]+1].sync(game.sim.enemies[who[k]],1.0/60,false)
	await save("poses_walking")
	game.sim.enemies[who[1]].alerted = true
	game.sim.enemies[who[1]].moving = false
	for step in 10: game.actors[who[1]+1].sync(game.sim.enemies[who[1]],1.0/60,false)
	await save("phone_alerted")
	# Shotgun knockback: shot from the left, thrown to the right.
	game.equip("shotgun")
	var victim: Dictionary = game.sim.enemies[who[0]]
	victim.alerted = true
	game.sim.kill(victim,Vector2.RIGHT,"shotgun")
	game.sim.gore_rng.seed = 3
	var visual = game.actors[who[0]+1]
	for i in game.actors.size(): game.actors[i].sync(game.sim.player if i==0 else game.sim.enemies[i-1],1.0/60,false)
	game.effects.consume(game.sim.events,game.actors)
	for step in 9:
		visual.sync(victim,1.0/60,false)
		game.effects.update(1.0/60,false)
	await save("knock_early")
	for step in 60:
		visual.sync(victim,1.0/60,false)
		game.effects.update(1.0/60,false)
	await save("knock_down")
	print("POSE_CAPTURE_OK knock=",visual.current," slid=",visual.position.distance_to(Vector3(victim.p.x,0,victim.p.y)))
	quit()
