extends SceneTree
var game: Node3D
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.qa/lapa3d-menu.png")
	game.sim.reset()
	game.sim.player.p = Vector2(-8.9,1.8)
	game.sim.player.angle = -PI/2
	game.overlay.hide()
	game.update_ui()
	for i in game.actors.size(): game.actors[i].sync(game.sim.player if i==0 else game.sim.enemies[i-1],.016,false)
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.qa/lapa3d-game.png")
	# Close view to inspect skinning, gun orientation and floor contact.
	game.camera.position = Vector3(-5,5,8)
	game.camera.look_at(Vector3(-8.9,.8,1.8))
	game.camera.size = 5.5
	game.hud.hide()
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.qa/lapa3d-character.png")
	for pose in ["walk","run","shoot","reload","death"]:
		game.sim.player.moving = pose in ["walk","run"]
		game.sim.player.velocity = Vector2(5.2 if pose == "run" else .925,0) if game.sim.player.moving else Vector2.ZERO
		game.sim.player.recoil = .24 if pose == "shoot" else 0
		game.sim.player.reload = .75 if pose == "reload" else 0
		game.sim.player.alive = pose != "death"
		game.actors[0].sync(game.sim.player,.016,false)
		game.actors[0].sync(game.sim.player,1.8 if pose == "death" else .18,false)
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.qa/lapa3d-"+pose+".png")
	print("CAPTURE_OK")
	quit()
