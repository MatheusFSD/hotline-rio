extends SceneTree
## Night seven: actual gameplay framing, shore, garden and the limits of wheel zoom.
var game
var folder := "res://../.qa/lagoa_exterior/"

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
	game.load_level(6)
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
	game._frame(Vector3(15.5,0,1.8),12.0)
	await save("shore")
	game._frame(Vector3(2,0,5.5),12.0)
	await save("garden")
	game._frame(Vector3(0,0,-10),16.0)
	await save("landscape")
	game.hud.show()
	for item in [["zoom_entrance",Vector2(-11.1,8.875)],["zoom_back",Vector2(1,-5.8)],["zoom_exit",Vector2(14.1,.1)]]:
		game.sim.player.p = item[1]
		game.actors[0].sync(game.sim.player,1.0/60,false)
		game.view_size = game.PLAYER_ZOOM_MIN
		game.view_current = game.PLAYER_ZOOM_MIN
		game._update_kill_zoom(1.0/60)
		await save(item[0])
	print("LAGOA_EXTERIOR_CAPTURE_OK")
	quit()
