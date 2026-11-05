extends SceneTree
## HUD frames saved to .qa/hud: mid-fight, low rounds while reloading, the bar cleared, the briefing.
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../.qa/hud/"+name+".png"))
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../.qa/hud"))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.hud.set_process(false)
	await save("briefing")
	game.sim.reset()
	game.sim.state = "playing"
	game.update_ui()
	game.hud.advance(1.0)
	for i in game.actors.size(): game.actors[i].sync(game.sim.player if i==0 else game.sim.enemies[i-1],.016,false)
	game.sim.kill(game.sim.enemies[0]); game.sim.kill(game.sim.enemies[1])
	game.sim.elapsed = 23.7
	game.sim.player.ammo = 7
	game.sim.player.mana = 72.0
	game.update_ui()
	game.hud.advance(.6)
	await save("playing")
	game.sim.player.ammo = 2
	game.update_ui()
	game.hud.advance(.6)
	game.hud.time = .1
	game.hud.advance(0)
	await save("low_ammo")
	for e in game.sim.enemies:
		if e.alive: game.sim.kill(e)
	game.sim.player.ammo = 12
	game.update_ui()
	game.hud.advance(.12)
	await save("cleared_slam")
	game.hud.advance(.9)
	game.hud.time = .1
	game.hud.advance(0)
	await save("cleared")
	print("HUD_CAPTURE_OK")
	quit()
