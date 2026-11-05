extends SceneTree
## Close shots of the hero aiming up the screen while running sideways, diagonally and backwards,
## a few frames apart. Requires a graphical session: godot --path . --script res://tests/strafe_capture.gd -- <folder>
var game
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var folder := "res://../.qa/strafe/"+(args[0] if args.size() else "depois")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_or_resume()
	game.hud.hide()
	game.aim_marker.hide()
	for e in game.sim.enemies: e.p = Vector2(-100,-100)
	var hero = game.actors[0]
	var d: Dictionary = game.sim.player
	d.p = Vector2(-4.0,-1.4)
	d.angle = -PI/2
	d.moving = true
	game.camera.size = 3.2
	game.camera.position = Vector3(d.p.x,1.0,d.p.y)+game.CAMERA_HOME-game.CAMERA_TARGET
	for entry in [["lado",90],["diagonal",45],["diagonal_tras",135]]:
		d.velocity = Vector2.from_angle(d.angle+deg_to_rad(entry[1]))*3.2
		for i in 40: hero.sync(d,1.0/60,false)
		for shot in 3:
			for i in 6: hero.sync(d,1.0/60,false)
			for i in 3: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%s_%d.png" % [folder,entry[0],shot])
	print("STRAFE_CAPTURE_OK")
	quit()
