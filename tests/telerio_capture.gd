extends SceneTree
## The TeleRio on screen, in .qa/telerio: the whole floor lit, close views of the studio, of the
## corridor with the breaker and Jairo's dressing room, and of the garage; then the same floor
## after the breaker trips.
## Requires a graphical session:  godot --path . --script res://tests/telerio_capture.gd
var folder := "res://../.qa/telerio/"
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
	game.load_level(8)
	game.start_or_resume()
	game.sim.state = "playing"
	game.sim.god = true
	for i in 40: game._physics_process(1.0/60)
	await save("floor")
	look(game,Vector2(-.4,-3.0),9.0)
	await save("studio")
	look(game,Vector2(-9.5,-1.5),8.0)
	await save("corridor")
	look(game,Vector2(8.8,1.0),9.0)
	await save("garage")
	game._frame(game.CAMERA_TARGET,game.CAMERA_SIZE)
	game.sim.trip()
	for i in 30: game._physics_process(1.0/60)
	for i in 20: await process_frame
	await save("blackout")
	print("TELERIO_CAPTURE_OK")
	quit()
