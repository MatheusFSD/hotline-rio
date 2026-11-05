extends SceneTree
## Night twelve on screen, in .qa/marques: the rally hall, the count room with the aides slumped at
## their desks, the helipad (the Síndico unseen, then seen from the spectre), and the last room.
## Requires a graphical session:  godot --path . --script res://tests/marques_capture.gd
const Campaign = preload("res://scripts/campaign.gd")
var folder := "res://../.qa/marques/"
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+name+".png")
func look(game,at: Vector2,size: float) -> void:
	game.camera.size = size
	game.camera.position = Vector3(at.x,0,at.y)+game.CAMERA_HOME-game.CAMERA_TARGET
func stage(game,index: int) -> void:
	game.load_level(index)
	game.start_or_resume()
	game.sim.state = "playing"
	game.sim.god = true
	for i in 40: game._physics_process(1.0/60)
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	Campaign.state = Campaign.fresh()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await stage(game,11)
	await save("rally")
	await stage(game,12)
	await save("count_room")
	look(game,Vector2(0.0,-4.0),8.0)
	await save("aides")
	await stage(game,13)
	await save("helipad")
	game.sim.player.phasing = true
	game._show_ghost()
	await save("helipad_spectre")
	game.queue_free()
	var room = load("res://scripts/room.gd").new({"campaign":Campaign.fresh(),"finale":true,"report":{}})
	root.add_child(room)
	await save("last_room")
	print("MARQUES_CAPTURE_OK")
	quit()
