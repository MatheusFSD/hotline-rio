extends SceneTree
## Renders any night: briefing, gameplay view, the four quarters of the level up close, the hill
## behind it and the exit lit after the clear. Requires a graphical session:
##   godot --path . --script res://tests/level_capture.gd -- 3      (images in .qa/level3)
var game
var folder := ""
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+name+".png")
func close(at: Vector3,size: float,name: String) -> void:
	game.camera.size = size
	game.camera.position = at+game.CAMERA_HOME-game.CAMERA_TARGET
	await save(name)
func settle(frames: int) -> void:
	for i in frames:
		for j in game.actors.size(): game.actors[j].sync(game.sim.player if j == 0 else game.sim.enemies[j-1],1.0/60,false)
func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var level := int(args[0]) if args.size() else 2
	folder = "res://../.qa/level%d/" % level
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.load_level(level-1)
	await save("briefing")
	game.start_or_resume()
	game.update_ui()
	settle(20)
	await save("game")
	game.hud.hide()
	await close(Vector3(-7.0,0,-3.5),10.0,"back_left")
	await close(Vector3(7.0,0,-3.5),10.0,"back_right")
	await close(Vector3(-7.0,0,4.5),10.0,"front_left")
	await close(Vector3(7.0,0,4.5),10.0,"front_right")
	await close(Vector3(0,0,-12.0),16.0,"hill")
	game.hud.show()
	game._frame(game.CAMERA_TARGET,game.CAMERA_SIZE)
	for e in game.sim.enemies: game.sim.kill(e,Vector2.RIGHT)
	game.effects.consume(game.sim.events,game.actors)
	for i in 90:
		settle(1)
		game.exit_marker.update(true,1.0/60,false)
	game.update_ui()
	await save("cleared")
	print("LEVEL_CAPTURE_OK ",level)
	quit()
