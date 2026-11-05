extends SceneTree
## Renders the five guns in hand and a shotgun blast. Requires a graphical session.
const Sim = preload("res://scripts/simulation.gd")
var game
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.qa/%s.png" % name)
func capture() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_or_resume()
	game.hud.hide()
	game.aim_marker.hide()
	# Five actors in a row on the sidewalk, one gun each, all aiming at the camera side.
	var weapons: Array = Sim.WEAPONS.keys()
	for i in game.actors.size():
		var visual = game.actors[i]
		if i >= weapons.size():
			visual.hide()
			continue
		visual.set_weapon(weapons[i])
		var data: Dictionary = Sim.actor(Vector2(-11.0+i*1.3,9.4),PI/2-.5)
		data.merge({"reload":0.0})
		visual.sync(data,.3,false)
	game.camera.position = Vector3(-8.4,2.6,13.4)
	game.camera.look_at(Vector3(-8.4,1.0,9.4))
	game.camera.size = 6.0
	await save("weapons-in-hand")
	# Shotgun blast in the bar: seven pellets fan out from the barrel.
	for visual in game.actors: visual.hide()
	game.actors[0].show()
	game.equip("shotgun")
	game.start_or_resume()
	game.sim.player.p = Vector2(-2.0,-3.0)
	for i in 4:
		game.sim.update(1.0/60,{"attack":true,"aim":Vector2(3.0,-3.0)})
		game.actors[0].sync(game.sim.player,1.0/60,false)
		game.effects.update(1.0/60)
		game.effects.consume(game.sim.events,game.actors)
	game.camera.position = Vector3(1.0,9.0,4.0)
	game.camera.look_at(Vector3(.5,.5,-3.0))
	game.camera.size = 9.0
	await save("weapons-shotgun-blast")
	print("WEAPONS_CAPTURE_OK")
	quit()
