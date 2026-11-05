extends SceneTree
## The act 1 → 2 newscast sketch on screen, in .qa/news: each segment midway through its caption.
## Requires a graphical session:  godot --path . --script res://tests/news_capture.gd
const NewsCard = preload("res://scripts/news_card.gd")
var folder := "res://../.qa/news/"
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+name+".png")
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var news = NewsCard.new(NewsCard.load_news("res://assets/news/virada_1.json"))
	news.set_process(false)
	root.add_child(news)
	for at in [4.0,10.6]:
		news.advance(at-news.time)
		await save("segment_%d" % news.current)
	print("NEWS_CAPTURE_OK")
	quit()
