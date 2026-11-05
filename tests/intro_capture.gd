extends SceneTree
## Renders one frame of every newscast shot. Requires a graphical session.
const Intro = preload("res://scripts/intro.gd")
const Main = preload("res://scripts/main.gd")
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var intro = Intro.new(Main.level_lamps(Main.Simulation.new().layout))
	root.add_child(intro)
	intro.set_process(false)
	for moment in [[.5,"on"],[2.4,"plantao"],[6.5,"medium"],[10.5,"close"],[15.0,"cctv"],[18.5,"witness"],[22.0,"cop"],[27.3,"point"],[30.2,"outro"],[31.35,"off"]]:
		while intro.time < moment[0]: intro.advance(1.0/30)
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.qa/intro-%s.png" % moment[1])
	print("INTRO_CAPTURE_OK")
	quit()
