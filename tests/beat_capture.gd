extends SceneTree
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 2: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../.qa/beat/"+name+".png"))
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../.qa/beat"))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.results.set_process(false)
	game.sim.reset()
	game.sim.state = "playing"
	game.sim.player.p = Vector2(-4.2,-1.2)
	game.update_ui()
	# Exit lit: all enemies down, light coming up out of the alley floor.
	game.sim.kills = game.sim.enemies.size()
	for i in 6: game.exit_marker.update(true,1.0/60,false)
	await save("exit_rising")
	for i in 60: game.exit_marker.update(true,1.0/60,false)
	await save("exit_full")
	game._frame(Vector3(13.5,0,5.9),7.0)
	await save("exit_close")
	game.sim.kills = 0
	game.exit_marker.update(false,.1,false)
	game._apply_kill_zoom()
	# Death beat.
	game.sim.die(Vector2.RIGHT)
	game.effects.consume(game.sim.events,game.actors)
	game.update_ui()
	var marks := {12:"death_zoom",60:"death_slowmo",115:"death_late"}
	for i in 126:
		var dt := 1.0/60
		game._update_death_beat(dt)
		var world: float = dt*game.time_scale()
		for a in game.actors.size(): game.actors[a].sync(game.sim.player if a==0 else game.sim.enemies[a-1],world,false)
		game.effects.update(world,false)
		if marks.has(i): await save(marks[i])
	game.results.advance(1.4)
	await save("death_screen")
	print("BEAT_CAPTURE_OK")
	quit()
