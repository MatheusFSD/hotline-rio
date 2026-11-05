extends SceneTree
var game
func _initialize() -> void: call_deferred("capture")
func tick(input: Dictionary = {}) -> void:
	game.sim.update(1.0/60,input)
	for i in game.actors.size(): game.actors[i].sync(game.sim.player if i==0 else game.sim.enemies[i-1],1.0/60,false)
	game.effects.update(1.0/60)
	game.effects.consume(game.sim.events,game.actors)
func shot(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.qa/"+name+".png")
func capture() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_or_resume()
	game.sim.player.p = Vector2(-8.9,6.5)
	game.hud.hide()
	game.aim_marker.hide()
	game.camera.position = Vector3(-4,6,11)
	game.camera.look_at(Vector3(-8.9,.65,5.2))
	game.camera.size = 5.8
	tick({"aim":game.sim.enemies[0].p,"attack":true})
	for i in 2: tick()
	await shot("lapa3d-effects-shot")
	for i in 44: tick()
	await shot("lapa3d-effects-blood")
	game.camera.position = Vector3(0,33,23.7)
	game.camera.look_at(Vector3(0,0,-1.8))
	game.camera.size = 26.5
	game.hud.show()
	game.update_ui()
	await shot("lapa3d-effects-game")
	print("EFFECTS_CAPTURE_OK")
	quit()
