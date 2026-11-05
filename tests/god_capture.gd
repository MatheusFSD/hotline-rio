extends SceneTree
## Renders modo deus: the hero outlined in gold, shot at by a gunman, sparks where the bullets
## glance off, and the HUD badge. Requires a graphical session; images go to .qa/god.
var game
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.qa/god/"+name+".png")
func step(frames: int) -> void:
	for f in frames:
		game.sim.update(1.0/60,{"aim":game.sim.enemies[1].p})
		for i in game.actors.size(): game.actors[i].sync(game.sim.player if i == 0 else game.sim.enemies[i-1],1.0/60,false)
		game.effects.update(1.0/60,false)
		game.effects.consume(game.sim.events,game.actors)
		game.update_ui()
		game.hud.advance(1.0/60)
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../.qa/god"))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_or_resume()
	game.sim.toggle_god()
	game.aim_marker.hide()
	var s = game.sim
	s.player.p = s.nearest_free(Vector2(-2.6,-1.8))
	var shooter: Dictionary = s.enemies[1]
	for e in s.enemies: if e != shooter: e.p = Vector2(-100,-100); e.alive = false
	shooter.p = s.player.p+Vector2(3,0)
	shooter.alerted = true
	shooter.memory = 5.0
	step(150)
	await save("game")
	game.camera.size = 6.0
	game.camera.position = Vector3(s.player.p.x+1.5,1.0,s.player.p.y)+game.CAMERA_HOME-game.CAMERA_TARGET
	step(20)
	await save("close")
	print("GOD_CAPTURE_OK ",s.state)
	quit()
