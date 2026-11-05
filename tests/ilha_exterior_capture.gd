extends SceneTree
## Night eight's exterior in the actual gameplay view and at the zoom limits.
var game
var folder := "res://../.qa/ilha_exterior/"

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
	game.load_level(7)
	game.start_or_resume()
	game.sim.state = "playing"
	for j in game.actors.size():
		for i in 20: game.actors[j].sync(game.sim.player if j == 0 else game.sim.enemies[j-1],1.0/60,false)
	for j in game.guests.size(): game.guests[j].sync(game.sim.civilians[j],1.0/60,false)
	game.aim_marker.hide()
	game.update_ui()
	game._frame(game.CAMERA_TARGET,game.CAMERA_SIZE)
	await save("after")
	game.hud.hide()
	await save("exterior")
	game._frame(Vector3(.4,2,-10.5),12.0)
	await save("tower")
	game._frame(Vector3(15.5,0,5.3),11.0)
	await save("quay")
	game._frame(Vector3(-11,0,10),11.0)
	await save("service_boat")
	game._frame(Vector3(-14,0,-10),14.0)
	await save("bridge")
	game.hud.show()
	for item in [["zoom_entrance",Vector2(-10.7,8.875)],["zoom_back",Vector2(.5,-5.5)],["zoom_exit",Vector2(14.1,5.2)]]:
		game.sim.player.p = item[1]
		game.actors[0].sync(game.sim.player,1.0/60,false)
		game.view_size = game.PLAYER_ZOOM_MIN
		game.view_current = game.PLAYER_ZOOM_MIN
		game._update_kill_zoom(1.0/60)
		await save(item[0])
	print("ILHA_EXTERIOR_CAPTURE_OK")
	quit()
