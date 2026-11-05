extends SceneTree
## Night six's exterior in the real gameplay camera, including the zoom limits.
## godot --path . --script res://tests/guardiao_exterior_capture.gd
var game
var folder := "res://../.qa/guardiao_exterior/"

func _initialize() -> void: call_deferred("capture")

func save(name: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+name+".png")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.load_level(5)
	game.start_or_resume()
	game.sim.state = "playing"
	for j in game.actors.size():
		for i in 20: game.actors[j].sync(game.sim.player if j == 0 else game.sim.enemies[j-1],1.0/60,false)
	game.aim_marker.hide()
	game.update_ui()
	game._frame(game.CAMERA_TARGET,game.CAMERA_SIZE)
	await save("after")
	game.hud.hide()
	await save("exterior")
	game._frame(Vector3(0,-15,-29),26.5)
	await save("avenue")
	game._frame(Vector3(11,-1,9),10.0)
	await save("fire_escape")
	game.hud.show()
	for item in [["zoom_entrance",Vector2(10.5,8.875)],["zoom_back",Vector2(0,-5.8)],["zoom_exit",Vector2(-14.1,-.4)]]:
		game.sim.player.p = item[1]
		game.view_size = game.PLAYER_ZOOM_MIN
		game.view_current = game.PLAYER_ZOOM_MIN
		game._update_kill_zoom(1.0/60)
		await save(item[0])
	print("GUARDIAO_EXTERIOR_CAPTURE_OK")
	quit()
