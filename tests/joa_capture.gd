extends SceneTree
## The Joá on screen, in .qa/joa: the whole house, close views of the glass rooms, of the deck
## with the pool that reflects nothing, and of the gourmet terrace; then a shot through the glass.
##
## Requires a graphical session:  godot --path . --script res://tests/joa_capture.gd
var folder := "res://../.qa/joa/"
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
	game.load_level(9)
	game.start_or_resume()
	game.sim.state = "playing"
	game.sim.god = true
	for i in 40: game._physics_process(1.0/60)
	await save("floor")
	look(game,Vector2(1.0,-3.0),9.0)
	await save("glass_rooms")
	look(game,Vector2(-9.0,-3.0),8.0)
	await save("deck")
	look(game,Vector2(10.0,-1.5),8.0)
	await save("gourmet")
	game._frame(game.CAMERA_TARGET,game.CAMERA_SIZE)
	game.sim.player.p = Vector2(-1.0,0.8); game.sim.player.angle = 0.0; game.sim.attack()
	for i in 30: game._physics_process(1.0/60)
	for i in 20: await process_frame
	await save("shot_through_glass")
	print("JOA_CAPTURE_OK")
	quit()
