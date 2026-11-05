extends SceneTree
## Renders the spectre crossing the bar counter. Requires a graphical session.
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
	game.start_or_resume()
	game.aim_marker.hide()
	var player: Dictionary = game.sim.player
	# Walk west through the long bar counter while intangible.
	player.p = Vector2(-8.6,-2.6)
	player.angle = PI
	for i in 30:
		game.sim.update(1.0/60,{"move":Vector2.LEFT,"phase":true,"aim":player.p+Vector2.LEFT})
		for j in game.actors.size(): game.actors[j].sync(player if j == 0 else game.sim.enemies[j-1],1.0/60,false)
		game._update_phase_view(1.0/60)
	await save("lapa3d-phase-game")
	game.hud.hide()
	game.camera.position = Vector3(-6,7,4)
	game.camera.look_at(Vector3(-10,.7,-2.6))
	game.camera.size = 5.5
	await save("lapa3d-phase-close")
	print("PHASE_CAPTURE_OK")
	quit()
