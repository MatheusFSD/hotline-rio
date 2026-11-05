extends SceneTree
## The Caju dock up close, in .qa/bags: the first inquilino by his two bags, then shot whole with
## the pistol, his flame on its way to a bag, the man inside dropping out of it (drop_00..09)
## and getting up.
## Requires a graphical session:  godot --path . --script res://tests/bag_capture.gd
var folder := "res://../.qa/bags/"
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+name+".png")
func look(game,at: Vector2) -> void:
	game.camera.size = 8.0
	game.camera.position = Vector3(at.x,0,at.y)+game.CAMERA_HOME-game.CAMERA_TARGET
func frames(game,count: int,at: Vector2) -> void:
	for i in count: game._physics_process(1.0/60)
	look(game,at)
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.load_level(4)
	game.start_or_resume()
	game.sim.state = "playing"
	var host: Dictionary = game.sim.enemies[2]
	var focus: Vector2 = host.p+Vector2(1.2,.6)
	frames(game,30,focus)
	await save("bags")
	game.sim.kill(host,Vector2.ZERO)   # whole, as the pistol often leaves it
	frames(game,24,focus)
	await save("flame")
	# The drop out of the bag, frame by frame from the moment it splits.
	var start: int = game.actors.size()
	var shot := 0
	for i in 160:
		game._physics_process(1.0/60)
		if game.actors.size() > start and i%6 == 0 and shot < 10:
			look(game,focus)
			await save("drop_%02d" % shot)
			shot += 1
	look(game,focus)
	await save("rising")
	print("BAG_CAPTURE_OK")
	quit()
