extends SceneTree
## The katana in the hero's hand, close: guard, both cuts mid-swing, the hand on the grip from the
## side, and a cut landing on an enemy. Saved to .qa/katana.
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../.qa/katana/"+name+".png"))
func sync_all(game,dt: float) -> void:
	for i in game.actors.size(): game.actors[i].sync(game.sim.player if i==0 else game.sim.enemies[i-1],dt,false)
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../.qa/katana"))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.overlay.hide()
	game.sim.reset()
	game.sim.state = "playing"
	for e in game.sim.enemies: e.reaction = 999.0   # nobody shoots while the frames are taken
	game.update_ui()
	game.hud.advance(1.0)
	game.sim.player.p = Vector2(-2.6,-2.6)
	game.sim.player.angle = PI/2   # facing the camera
	game.switch_weapon()
	for i in 20: sync_all(game,1.0/60)
	game.update_ui()
	game.hud.advance(.2)
	await save("hud")
	game.hud.hide()
	game._frame(Vector3(-2.6,0,-2.6),3.2)
	await save("guard")
	var hero = game.actors[0]
	# A side look at the grip with its own camera.
	var side := Camera3D.new()
	game.add_child(side)
	side.position = Vector3(-1.2,1.3,-2.25)
	side.look_at(Vector3(-2.6,1.0,-2.45))
	side.fov = 40
	side.current = true
	await save("grip_side")
	side.position = Vector3(-2.2,1.5,-1.0)
	side.look_at(Vector3(-2.6,1.0,-2.4))
	await save("grip_front")
	game.camera.current = true
	for swing in 2:
		game.sim.player.cooldown = 0.0
		game.sim.slash()
		for i in 14:   # ~0.23 s, the fastest moment of the cut
			game.sim.update(1.0/60,{"aim":game.sim.player.p+Vector2.from_angle(game.sim.player.angle)})
			sync_all(game,1.0/60)
		await save("cut_"+["a","b"][swing])
		for i in 60:
			game.sim.update(1.0/60,{"aim":game.sim.player.p+Vector2.from_angle(game.sim.player.angle)})
			sync_all(game,1.0/60)
	# A cut that lands: an enemy right in front.
	var e: Dictionary = game.sim.enemies[1]
	e.p = game.sim.player.p+Vector2(0,1.1)
	e.alerted = true
	game.sim.player.cooldown = 0.0
	game.sim.slash()
	for i in 16:
		game.sim.update(1.0/60,{"aim":game.sim.player.p+Vector2(0,1)})
		sync_all(game,1.0/60)
		game.effects.consume(game.sim.events,game.actors)
		game.effects.update(1.0/60,false)
	game._frame(Vector3(-2.6,0,-2.0),4.5)
	await save("cut_kill")
	print("KATANA_CAPTURE_OK alive=",e.alive," swings=",game.sim.player.swings," held=",hero.weapon)
	quit()
