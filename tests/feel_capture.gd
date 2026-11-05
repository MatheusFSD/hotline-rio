extends SceneTree
## Night one's floor after every enemy died where he stood, in .qa/feel: the first pools must still be
## there, in the blood's own red. Prints the frame rate with all of it on screen.
## Requires a graphical session:  godot --path . --script res://tests/feel_capture.gd
var folder := "res://../.qa/feel/"

func _initialize() -> void: call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.start_or_resume()
	game.sim.state = "playing"
	game.sim.god = true
	game.set_physics_process(false)
	var first := true
	var first_place: Vector3
	for e in game.sim.enemies:
		game.sim.kill(e,Vector2.from_angle(float(e.id)*2.4),"shotgun")
		game.effects.consume(game.sim.events,game.actors)
		if first:
			first = false
			first_place = game.effects.stain_sheets[0].get_instance_transform(0).origin
		for i in 60: game.effects.update(1.0/30)
	for j in game.actors.size():
		for i in 80: game.actors[j].sync(game.sim.player if j == 0 else game.sim.enemies[j-1],1.0/30,false)
	game._frame(game.CAMERA_TARGET,game.CAMERA_SIZE)
	game.hud.hide()
	for i in 40: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"floor.png")
	var sheet: MultiMesh = game.effects.stain_sheets[0]
	var color: Color = sheet.get_instance_color(0)
	var want: Color = game.effects.BLOOD[String(game.sim.enemies[0].get("kind","human"))][0]
	var kept: bool = Vector3(color.r-want.r,color.g-want.g,color.b-want.b).length() < .01 and sheet.get_instance_transform(0).origin.is_equal_approx(first_place)
	# Two seconds of ordinary frames, so the rate is not the loading's.
	await create_timer(2.0).timeout
	print("FEEL_CAPTURE_OK stains=%d fps=%d first_pool_kept=%s color=%s want=%s at=%s was=%s" % [game.effects.stain_total,Engine.get_frames_per_second(),kept,color,want,sheet.get_instance_transform(0).origin,first_place])
	quit()
