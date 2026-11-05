extends SceneTree
## The clinic on screen, in .qa/clinica: the whole floor, close views of the recovery ward, the
## operating theatre and Vera Lis. office; then a patient out of bed after an inquilino dies whole.
##
## Requires a graphical session:  godot --path . --script res://tests/clinica_capture.gd
var folder := "res://../.qa/clinica/"
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
	game.load_level(10)
	game.start_or_resume()
	game.sim.state = "playing"
	game.sim.god = true
	for i in 40: game._physics_process(1.0/60)
	await save("floor")
	look(game,Vector2(-8.8,-3.6),8.0)
	await save("ward")
	look(game,Vector2(-0.6,-3.6),8.0)
	await save("theatre")
	look(game,Vector2(10.0,-3.6),8.0)
	await save("office")
	game._frame(game.CAMERA_TARGET,game.CAMERA_SIZE)
	game.sim.kill(game.sim.enemies[6],Vector2.ZERO)
	for i in 150: game._physics_process(1.0/60)
	for i in 20: await process_frame
	await save("patient_up")
	print("CLINICA_CAPTURE_OK")
	quit()
