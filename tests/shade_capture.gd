extends SceneTree
## Same frames before and after a shading pass: the gameplay framing and close views of the salon
## tables, the bar, the booth, the kitchen and the storage, saved to .qa/<folder>.
## Usage: godot --path "godot 3d" --script res://tests/shade_capture.gd -- <folder>
func _initialize() -> void: call_deferred("capture")
func save(folder: String,name: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+name+".png")
func capture() -> void:
	var folder := ProjectSettings.globalize_path("res://../.qa/"+(OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "shade"))
	DirAccess.make_dir_recursive_absolute(folder)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.overlay.hide()
	game.sim.reset()
	game.sim.state = "playing"
	game.update_ui()
	game.hud.content.modulate.a = 1.0
	for i in game.actors.size(): game.actors[i].sync(game.sim.player if i==0 else game.sim.enemies[i-1],.016,false)
	await save(folder,"game")
	game.hud.hide()
	for shot in [["tables",Vector3(-2.5,0,-2.5),8.0],["bar",Vector3(-9.0,0,-2.0),7.0],["booth",Vector3(-1.5,0,5.5),6.0],["kitchen",Vector3(7.8,0,-3.5),7.0],["storage",Vector3(7.5,0,4.8),5.5]]:
		game._frame(shot[1],shot[2])
		await save(folder,shot[0])
	print("SHADE_CAPTURE_OK ",folder)
	quit()
