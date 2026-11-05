extends SceneTree
## Clues and the campaign on screen, in .qa/clues: the clue marker up close, the HUD asking for the
## clue, the photo flash, and the room after two nights (report, orders, board, arsenal), then the board after six.
## Requires a graphical session:  godot --path . --script res://tests/clue_capture.gd
const Campaign = preload("res://scripts/campaign.gd")
const Main = preload("res://scripts/main.gd")
var folder := "res://../.qa/clues/"
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+name+".png")
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	Campaign.state = Campaign.fresh()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.start_or_resume()
	game.sim.state = "playing"
	game.set_physics_process(false)
	for i in 30: game._physics_process(1.0/60)
	var spot: Vector2 = game.sim.clue_spot(game.sim.clues[0])
	game.camera.size = 9.0
	game.camera.position = Vector3(spot.x,0,spot.y)+game.CAMERA_HOME-game.CAMERA_TARGET
	await save("marker")
	game._frame(game.CAMERA_TARGET,game.CAMERA_SIZE)
	for e in game.sim.enemies: game.sim.kill(e,Vector2.ZERO)
	game.effects.clear()
	game.sim.events.clear()
	for i in 40: game._physics_process(1.0/60)
	await save("hunting")
	game.sim.player.p = game.sim.nearest_free(spot)
	game._physics_process(1.0/60)
	await save("photo")
	for i in 60:
		game._physics_process(1.0/60)
		game.hud.advance(1.0/60)
	await save("clue_card")
	game.queue_free()
	# The room after the bar and the gafieira, both optional clues found.
	for night in 2:
		var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Main.Simulation.LEVELS[night]))
		var report := Campaign.complete(night,layout,layout.clues.map(func(c): return c.id),night+1,"pistol")
		if night == 1:
			var room = Main.Room.new({"kills":11,"time":41.2,"attempt":2,"weapon":"pistol","level":1,"report":report,"campaign":Campaign.state})
			root.add_child(room)
			await save("room")
			room.click("Hotspot_pc")
			await save("room_orders")
			room._close()
			room.click("Hotspot_board")
			await save("room_board")
			room._close()
			room.click("Weapon_rifle")
			await save("room_arsenal")
			room.queue_free()
	# Every night made so far won: every clue on the board, then the last night's card.
	var last: Dictionary
	var report: Dictionary
	for night in range(2,Main.Simulation.LEVELS.size()):
		last = JSON.parse_string(FileAccess.get_file_as_string(Main.Simulation.LEVELS[night]))
		report = Campaign.complete(night,last,last.get("clues",[]).map(func(c): return c.id),(night+1)%Main.Simulation.LEVELS.size(),"pistol")
	var full = Main.Room.new({"kills":14,"time":61.0,"attempt":1,"weapon":"pistol","level":Main.Simulation.LEVELS.size()-1,"report":report,"campaign":Campaign.state})
	root.add_child(full)
	await save("room_full")
	full.click("Hotspot_board")
	await save("room_full_board")
	full.queue_free()
	var hud = Main.Hud.new()
	root.add_child(hud)
	var card = Main.ActCard.new(hud,last.act_end)
	root.add_child(card)
	for i in 240: card.screen.advance(1.0/60)
	await save("act_end")
	Campaign.state = Campaign.fresh()
	print("CLUE_CAPTURE_OK")
	quit()
