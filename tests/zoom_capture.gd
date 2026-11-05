extends SceneTree
## Renders the wheel zoom: the full view, halfway and the closest view, in the bar and in the
## Casarão das Artes. Requires a graphical session; images go to .qa/zoom.
var game
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.qa/zoom/"+name+".png")
func shoot(level: int,at: Vector2,name: String) -> void:
	game.load_level(level)
	game.start_or_resume()
	for e in game.sim.enemies: e.reaction = 999.0
	game.sim.player.p = game.sim.nearest_free(at)
	game.aim_marker.hide()
	for steps in [0,3,6]:
		game.sim.state = "playing"   # a capture window losing focus pauses the game
		game.update_ui()
		game.view_size = game.CAMERA_SIZE
		game.zoom_view(-steps)
		for i in 180: game._update_kill_zoom(1.0/60)
		for j in game.actors.size(): game.actors[j].sync(game.sim.player if j == 0 else game.sim.enemies[j-1],1.0/60,false)
		game.update_ui()
		await save("%s_%s" % [name,["longe","meio","perto"][steps/3]])
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../.qa/zoom"))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await shoot(0,Vector2(-3.0,-2.6),"bar")
	await shoot(2,Vector2(-6.0,-3.0),"casarao")
	print("ZOOM_CAPTURE_OK")
	quit()
