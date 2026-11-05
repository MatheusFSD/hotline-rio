extends SceneTree
## The Lagoa on screen, in .qa/lagoa: the whole house at the party, close views of the auction hall
## and of the bar, cellar and office, the guests running after a shot, and the night's results.
## Requires a graphical session:  godot --path . --script res://tests/lagoa_capture.gd
var folder := "res://../.qa/lagoa/"
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+name+".png")
func look(game,at: Vector2,size: float) -> void:
	game.camera.size = size
	game.camera.position = Vector3(at.x,0,at.y)+game.CAMERA_HOME-game.CAMERA_TARGET
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.load_level(6)
	game.start_or_resume()
	game.sim.state = "playing"
	game.sim.god = true
	for i in 40: game._physics_process(1.0/60)
	await save("house")
	look(game,Vector2(2.0,-3.0),9.0)
	await save("hall")
	look(game,Vector2(-8.5,-2.5),8.0)
	await save("bar_cellar")
	look(game,Vector2(2.0,5.5),9.0)
	await save("garden")
	game._frame(game.CAMERA_TARGET,game.CAMERA_SIZE)
	game.sim.shoot(game.sim.enemies[3],"enemy")
	for i in 50: game._physics_process(1.0/60)
	await save("panic")
	print("LAGOA_CAPTURE_OK")
	quit()
