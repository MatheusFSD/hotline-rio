extends SceneTree
## Main menu and the night's mission card, in Portuguese and English: images in .qa/menu.
## Requires a graphical session:  godot --path . --script res://tests/menu_capture.gd
const Lang = preload("res://scripts/lang.gd")
var folder := "res://../.qa/menu/"
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+name+".png")
func run(node: Node,seconds: float) -> void:
	for i in int(seconds*60):
		node._process(1.0/60)
	node.set_process(false)
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	Lang.setup()
	var before := TranslationServer.get_locale()
	for code in ["pt","en"]:
		TranslationServer.set_locale(code)
		var menu = load("res://scenes/menu.tscn").instantiate()
		root.add_child(menu)
		await process_frame
		TranslationServer.set_locale(code)   # the menu applies the saved or system language on open
		for i in 60: await process_frame   # the fade-in tween runs on real frames
		for i in 150:
			menu._process(1.0/60)
			menu.backdrop.advance(1.0/60)
		await save("menu_"+code)
		menu.show_page("languages")
		for i in 60: menu._process(1.0/60)
		await save("languages_"+code)
		menu.queue_free()
		var game = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		game.set_physics_process(false)
		game.overlay.set_process(false)
		game.overlay.advance(.7)
		await save("mission_typing_"+code)
		game.overlay.advance(4.0)
		await save("mission_"+code)
		game.start_or_resume()
		game.sim.state = "paused"
		game.update_ui()
		game.overlay.advance(3.0)
		await save("pause_"+code)
		game.queue_free()
		await process_frame
	TranslationServer.set_locale(before)
	print("MENU_CAPTURE_OK")
	quit()
