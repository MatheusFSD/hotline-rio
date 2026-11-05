extends SceneTree
## Mouse wheel zoom: from the full view (the farthest) in to PLAYER_ZOOM_MIN and no closer, the
## closer view following the hero without ever showing past the full view; kill zooms still
## work on top of it; the wheel no longer swaps weapons.
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")

func wheel(game,up: bool,times := 1) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN
	event.pressed = true
	for i in times: game._unhandled_input(event)

func settle(game,frames := 120) -> void:
	for i in frames: game._update_kill_zoom(1.0/60)

func focus(game) -> Vector3:
	return game.camera.position-(game.CAMERA_HOME-game.CAMERA_TARGET)

func inside_full_view(game) -> bool:
	## Every corner of the screen lands on ground the full view also shows.
	var view: Vector2 = game.get_viewport().get_visible_rect().size
	var pitch: float = (game.CAMERA_TARGET-game.CAMERA_HOME).angle_to(Vector3(0,0,-1))
	var spare_x: float = (game.CAMERA_SIZE-game.camera.size)*view.x/view.y/2.0
	var spare_z: float = (game.CAMERA_SIZE-game.camera.size)/2.0/sin(pitch)
	var f := focus(game)
	return absf(f.x-game.CAMERA_TARGET.x) <= spare_x+.01 and absf(f.z-game.CAMERA_TARGET.z) <= spare_z+.01

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_or_resume()
	for e in game.sim.enemies: e.reaction = 999.0
	settle(game)
	check(is_equal_approx(game.camera.size,game.CAMERA_SIZE) and focus(game).is_equal_approx(game.CAMERA_TARGET),"It opens at the full view")
	wheel(game,false,3)
	settle(game)
	check(is_equal_approx(game.camera.size,game.CAMERA_SIZE),"The full view is the farthest: wheeling out does nothing more")
	var melee: bool = game.sim.melee
	wheel(game,true)
	check(game.sim.melee == melee,"The wheel no longer swaps weapons")
	wheel(game,true,20)
	settle(game)
	check(absf(game.camera.size-game.PLAYER_ZOOM_MIN) < .05,"Wheeling in stops at %.1f (%.2f)" % [game.PLAYER_ZOOM_MIN,game.camera.size])
	check(game.PLAYER_ZOOM_MIN >= game.CAMERA_SIZE*.5,"Never closer than half the full view, so model and texture details stay out of reach")
	# The close view follows the hero across the level and never shows past the full view.
	for p in [Vector2(-2.0,-1.0),Vector2(-11.5,-6.8),Vector2(11.0,6.5),Vector2(-9.0,8.9),Vector2(10.5,-6.5)]:
		game.sim.player.p = p
		settle(game,2)
		check(inside_full_view(game),"At %s the close view stays inside the full view" % p)
	game.sim.player.p = Vector2(-2.0,-1.0)
	settle(game,2)
	check(Vector2(focus(game).x,focus(game).z).distance_to(game.sim.player.p) < .01,"Away from the edges the close view is centred on the hero")
	# A kill still zooms in a little more, from the close view, and comes back to it.
	game.sim.events.append({"type":"blood","player":false})
	settle(game,1)
	game.sim.events.clear()
	settle(game,9)
	check(game.camera.size < game.PLAYER_ZOOM_MIN-.3,"A kill zooms in from the close view (%.2f)" % game.camera.size)
	settle(game,120)
	check(absf(game.camera.size-game.PLAYER_ZOOM_MIN) < .05,"…and settles back on it")
	# Halfway, then back out.
	wheel(game,false,2)
	settle(game)
	check(game.camera.size > game.PLAYER_ZOOM_MIN+3 and game.camera.size < game.CAMERA_SIZE-3 and inside_full_view(game),"Each step eases to an in-between view")
	game.load_level(1)
	game.start_or_resume()
	settle(game)
	check(is_equal_approx(game.view_size,game.camera.size) and game.view_size < game.CAMERA_SIZE,"The chosen zoom carries over to the next night")
	wheel(game,false,20)
	settle(game)
	check(is_equal_approx(game.camera.size,game.CAMERA_SIZE) and focus(game).is_equal_approx(game.CAMERA_TARGET),"Wheeling out returns exactly to the full view")
	game.queue_free()
	await process_frame
	print("ZOOM: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
