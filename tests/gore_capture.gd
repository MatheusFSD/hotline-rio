extends SceneTree
var game
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.qa/"+name+".png")
func capture() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.hud.hide()
	game.aim_marker.hide()
	for region in ["head","arm_l","leg_r"]:
		game.start_or_resume()
		game.sim.player.p = Vector2(-8.9,6.5)
		game.sim.player.angle = -PI/2
		var victim: Dictionary = game.sim.enemies[0]
		game.sim.kill(victim,Vector2.UP)
		game.sim.events[-1].gore_allowed = false
		for i in game.actors.size(): game.actors[i].sync(game.sim.player if i==0 else game.sim.enemies[i-1],.016,false)
		game.effects.consume(game.sim.events,game.actors)
		game.effects.dismember(game.actors[1],region,Vector2.UP)
		game.camera.position = Vector3(-4,6,11)
		game.camera.look_at(Vector3(-8.9,.65,5.2))
		game.camera.size = 5.8
		for i in 10:
			game.effects.update(1.0/60)
			game.actors[1].sync(victim,1.0/60,false)
		await save("lapa3d-gore-"+region)
		for i in 125:
			game.effects.update(1.0/60)
			game.actors[1].sync(victim,1.0/60,false)
		await save("lapa3d-gore-"+region+"-ground")
	game.start_or_resume()
	var hero: Dictionary = game.sim.player
	hero.p = Vector2(-8.9,4.6)
	hero.angle = -PI/2
	hero.moving = true
	hero.velocity = Vector2(0,5.2)
	for i in range(1,game.actors.size()): game.actors[i].hide()
	for i in 12:
		hero.p += hero.velocity/60
		game.actors[0].sync(hero,1.0/60,false)
	await save("lapa3d-run-backward")
	print("GORE_CAPTURE_OK")
	quit()
