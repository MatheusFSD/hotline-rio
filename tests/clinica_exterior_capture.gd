extends SceneTree
## Night eleven: actual gameplay framing, ambulance, neighborhood and emergency exit.
var game
var folder := "res://../.qa/clinica_exterior/"

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
	game.load_level(10)
	game.start_or_resume()
	game.sim.state = "playing"
	for j in game.actors.size():
		for i in 20: game.actors[j].sync(game.sim.player if j == 0 else game.sim.enemies[j-1],1.0/60,false)
	game.patient_view.update()
	game.aim_marker.hide()
	game.update_ui()
	game._frame(game.CAMERA_TARGET,game.CAMERA_SIZE)
	await save("after")
	game.hud.hide()
	await save("exterior")
	game._frame(Vector3(-9,0,9.5),11)
	await save("ambulance")
	game._frame(Vector3(7,0,-11),14)
	await save("rear_street")
	game._frame(Vector3(17,0,3),15)
	await save("emergency_exit")
	game.hud.show()
	for item in [["zoom_entrance",Vector2(-10,8.875)],["zoom_back",Vector2(-2,-4.5)],["zoom_exit",Vector2(14.1,1.7)]]:
		game.sim.player.p = item[1]
		game.actors[0].sync(game.sim.player,1.0/60,false)
		game.view_size = game.PLAYER_ZOOM_MIN
		game.view_current = game.PLAYER_ZOOM_MIN
		game._update_kill_zoom(1.0/60)
		await save(item[0])
	print("CLINICA_EXTERIOR_CAPTURE_OK")
	quit()
