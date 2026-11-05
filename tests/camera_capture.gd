extends SceneTree
## The Guardião's cameras on screen, in .qa/cameras: the whole floor with every cone watching,
## close views of the corridor sweep and the central, and a cone gone red on the hero.
## Requires a graphical session:  godot --path . --script res://tests/camera_capture.gd
var folder := "res://../.qa/cameras/"
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
	game.load_level(5)
	game.start_or_resume()
	game.sim.state = "playing"
	game.sim.god = true
	for i in 40: game._physics_process(1.0/60)
	await save("floor")
	look(game,Vector2(9.0,-.6),9.0)
	await save("corridor")
	look(game,Vector2(-4.5,-4.2),9.0)
	await save("central")
	game.sim.player.p = Vector2(-3.5,-3.2)
	for i in 4: game._physics_process(1.0/60)
	look(game,Vector2(-4.5,-4.2),9.0)
	await save("seen")
	print("CAMERA_CAPTURE_OK")
	quit()
