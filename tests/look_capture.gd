extends SceneTree
## Same frames before and after a visual pass: the gameplay framing, plus 2x nearest crops of
## the red salon, the kitchen and the left alley so small fighters can be judged at real size.
## Usage: godot --path "godot 3d" --script res://tests/look_capture.gd -- <folder name under .qa>
var game: Node3D
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var folder := "look"
	if not OS.get_cmdline_user_args().is_empty(): folder = OS.get_cmdline_user_args()[0]
	var out := ProjectSettings.globalize_path("res://../.qa/"+folder)
	DirAccess.make_dir_recursive_absolute(out)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.sim.reset()
	game.sim.state = "playing"
	game.sim.player.p = Vector2(-4.2,-1.2)
	game.sim.player.angle = -PI/3
	game.overlay.hide()
	game.update_ui()
	for i in game.actors.size(): game.actors[i].sync(game.sim.player if i==0 else game.sim.enemies[i-1],.016,false)
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	shot.save_png(out+"/game.png")
	for crop in [["salon",Rect2i(330,240,420,300)],["kitchen",Rect2i(750,240,260,260)],["bar",Rect2i(270,330,260,260)]]:
		var part := shot.get_region(crop[1])
		part.resize(part.get_width()*2,part.get_height()*2,Image.INTERPOLATE_NEAREST)
		part.save_png(out+"/"+crop[0]+".png")
	# The hero phasing: the spectral look must still win over everything else.
	game.sim.player.phasing = true
	game.actors[0].sync(game.sim.player,.016,false)
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var phase := root.get_texture().get_image().get_region(Rect2i(330,240,420,300))
	phase.resize(840,600,Image.INTERPOLATE_NEAREST)
	phase.save_png(out+"/phasing.png")
	print("LOOK_CAPTURE_OK ",out)
	quit()
