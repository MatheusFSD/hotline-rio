extends SceneTree
## Frames of the death and level-clear screens at fixed moments, saved to .qa/results.
func _initialize() -> void: call_deferred("capture")
func shot(screen,at: float,name: String) -> void:
	screen.advance(at-screen.clock)
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../.qa/results/"+name+".png"))
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../.qa/results"))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var screen = game.results
	screen.set_process(false)
	game.sim.reset()
	game.sim.state = "playing"
	game.update_ui()
	for i in 3: game.sim.kill(game.sim.enemies[i])
	game.sim.elapsed = 12.4
	for i in game.actors.size(): game.actors[i].sync(game.sim.player if i==0 else game.sim.enemies[i-1],.016,false)
	game.sim.die()
	game.update_ui()
	await shot(screen,.06,"death_slam")
	await shot(screen,.8,"death_count")
	await shot(screen,1.6,"death_done")
	game.sim.state = "playing"
	game.update_ui()
	game.sim.kills = 8
	game.sim.elapsed = 34.5
	game.sim.state = "won"
	game.update_ui()
	await shot(screen,2.4,"win_points")
	await shot(screen,3.25,"win_grade")
	await shot(screen,4.0,"win_done")
	print("RESULT_CAPTURE_OK")
	quit()
