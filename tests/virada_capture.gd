extends SceneTree
## Renders the special report closing Act 1 (assets/news/virada_1_tv.json) as seen in Caio's room,
## and the newscast's own picture, one frame per shot, into .qa/virada. Requires a graphical session.
const Intro = preload("res://scripts/intro.gd")
const Campaign = preload("res://scripts/campaign.gd")
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../.qa/virada"))
	# The room as it stands after the fourth night: the guns and clues of Act 1.
	Campaign.state = Campaign.fresh()
	Campaign.state.unlocks.append_array(["smg","shotgun"])
	Campaign.state.clues.append_array(["caderno_taxa","celular_gravata"])
	var report = Intro.new([],"res://assets/news/virada_1_tv.json")
	root.add_child(report)
	report.set_process(false)
	for moment in [[1.0,"room"],[2.0,"plantao"],[6.0,"studio"],[12.5,"oficina"],[16.5,"close"],[20.0,"press"],[23.6,"ordem"],[27.0,"outro"],[29.2,"boot"],[33.0,"iml"],[40.0,"iml_late"]]:
		while report.time < moment[0]: report.advance(1.0/30)
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.qa/virada/%s.png" % moment[1])
		report.viewport.get_texture().get_image().save_png("res://../.qa/virada/%s_raw.png" % moment[1])
	print("VIRADA_CAPTURE_OK")
	quit()
