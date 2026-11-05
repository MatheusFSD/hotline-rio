extends SceneTree
## The casca rule on screen, in .qa/wisp, staged in the bar: the shadow-flame leaving a whole
## casca for a corpse, the corpse getting up, a bag hanging and a bag torn, and the Olho do
## Avesso outlining the inquilinos from the spectre.
## Requires a graphical session:  godot --path . --script res://tests/wisp_capture.gd
var folder := "res://../.qa/wisp/"
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+name+".png")
func frames(game,count: int) -> void:
	for i in count: game._physics_process(1.0/60)
	look(game)
var focus := Vector2.ZERO
func look(game) -> void:
	game.camera.size = 7.0
	game.camera.position = Vector3(focus.x,0,focus.y)+game.CAMERA_HOME-game.CAMERA_TARGET
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	for i in [0,2,4]: game.sim.layout.enemies[i].kind = "inquilino"
	game.sim.layout.shells = [{"p":[0,0],"angle":0},{"p":[0,0],"angle":0}]
	game.start_or_resume()
	game.sim.state = "playing"
	var host: Dictionary = game.sim.enemies[0]
	var corpse: Dictionary = game.sim.enemies[1]
	corpse.p = game.sim.nearest_free(host.p+Vector2(2.6,.4))
	game.sim.player.p = game.sim.nearest_free(host.p+Vector2(-1.5,3.5))
	focus = host.p+Vector2(1.3,-1.0)
	game.sim.shells[0].p = game.sim.nearest_free(host.p+Vector2(2.4,-2.6))
	game.sim.shells[1].p = game.sim.nearest_free(host.p+Vector2(3.4,-2.6))
	game.sim.tear(game.sim.shells[1])
	game.avesso.rebuild()
	game.sim.kill(corpse,Vector2.ZERO)
	frames(game,20)
	game.sim.kill(host,Vector2.ZERO)
	frames(game,34)
	await save("flame")
	frames(game,90)
	await save("rising")
	# The Olho do Avesso from the spectre.
	game.sim.mods = {"eye":true}
	game.sim.player.mana = 100.0
	for i in 12:
		game.sim.update(1.0/60,{"phase":true})
		for k in game.actors.size(): game.actors[k].sync(game.sim.player if k == 0 else game.sim.enemies[k-1],1.0/60,false)
		game.avesso.update(1.0/60,false)
	focus = game.sim.enemies[1].p
	look(game)
	await save("eye")
	print("WISP_CAPTURE_OK")
	quit()
