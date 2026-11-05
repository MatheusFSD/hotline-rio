extends SceneTree
## Death and level-clear screens: they open on the right state, roll their numbers to the exact
## values, kick the screen as they count, and Enter/clicks behave (instant retry, skippable tally).
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func key(game,code) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._unhandled_input(event)
func click(screen) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	screen._on_click(event)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var screen = game.results
	check(not screen.visible,"No result screen before the night starts")
	key(game,KEY_ENTER)
	game.sim.kill(game.sim.enemies[0])
	game.sim.kill(game.sim.enemies[1])
	game.sim.kill(game.sim.enemies[2])
	game.sim.elapsed = 12.4
	game.sim.die()
	game.update_ui()
	# Death beat: a hard zoom onto the hero and two seconds of slow motion before the screen.
	var hero := Vector3(game.sim.player.p.x,1.0,game.sim.player.p.y)
	var sizes: Array[float] = []
	var scales: Array[float] = []
	var steps := 0
	while not screen.visible and steps < 300:
		game._update_death_beat(1.0/60)
		sizes.append(game.camera.size)
		scales.append(game.time_scale())
		steps += 1
	check(absf(steps/60.0-game.DEATH_SLOWMO) < .03,"The death screen opens after the 2 s death beat (%.2f s)" % (steps/60.0))
	check(sizes[20] < game.CAMERA_SIZE*.45 and sizes[-2] < sizes[20],"The camera snaps in hard on the hero and keeps creeping in")
	var view: Vector2 = game.get_viewport().get_visible_rect().size
	check(Rect2(view*.2,view*.6).has_point(game.camera.unproject_position(hero)),"The hero is centred in the death zoom")
	check(scales[10] <= game.DEATH_SCALE+.001 and scales[-2] <= game.DEATH_SCALE+.001,"The world crawls in slow motion for the whole beat")
	check(game.camera.basis != game.camera_basis,"The camera rolls a little during the beat")
	check(screen.visible and screen.mode == "dead" and not game.overlay.visible,"Death opens the death screen, not the old panel")
	check(screen.trauma > .9 and screen.flash_alpha > .5,"Death lands with a full shake and a red flash")
	var kicks := 0
	var last: float = screen.trauma
	var texts := {}
	for i in 90:
		screen.advance(1.0/60)
		if screen.trauma > last+.05: kicks += 1
		last = screen.trauma
		texts[screen.rows[0].value.text] = true
	check(screen.rows[0].value.text == "03 / 08" and screen.rows[1].value.text == "00:12.4","The tally rolls to the exact kills and time (%s, %s)" % [screen.rows[0].value.text,screen.rows[1].value.text])
	check(texts.size() >= 3 and kicks >= 3,"Numbers count up and every step kicks the screen (%d steps, %d kicks)" % [texts.size(),kicks])
	check(screen.title_box.scale.distance_to(Vector2.ONE) < .1,"The title has landed")
	check(screen.prompt.text.contains("TENTAR"),"Death prompts a retry")
	game.sim.state = "playing"; game.update_ui(); game.sim.die(); game.update_ui()
	game._update_death_beat(1.0)
	key(game,KEY_ENTER)
	check(game.sim.state == "playing" and game.death_time < 0 and game.camera.basis.is_equal_approx(game.camera_basis) and is_equal_approx(game.camera.size,game.CAMERA_SIZE),"Enter during the death beat retries at once, camera back to the gameplay framing")
	game.sim.die(); game.update_ui()
	game._update_death_beat(2.05)
	click(screen)
	check(game.sim.state == "dead","A click in the first instants of the death screen (finger still on the trigger) does not restart")
	key(game,KEY_ENTER)
	check(game.sim.state == "playing" and not screen.visible,"Enter retries at once, even mid-animation")
	# Level clear.
	game.sim.kills = 8
	game.sim.elapsed = 34.5
	game.sim.state = "won"
	game.update_ui()
	check(screen.visible and screen.mode == "won" and screen.title.text.contains("BAR LIMPO"),"Leaving the bar opens the level-clear screen")
	check(screen.points == 8000+2550 and screen.grade_letter == "B","Points and grade come from kills and time only (%d, %s)" % [screen.points,screen.grade_letter])
	screen.advance(.8)
	key(game,KEY_ENTER)
	check(game.sim.state == "won" and screen.visible and screen.clock >= screen.done_at,"The first Enter lands the tally instead of leaving")
	screen.advance(1.0/60)
	check(screen.rows[3].value.text == "010550" and screen.grade.visible and screen.grade.text == "B","Skipping shows the final points and the grade")
	check(game.sim.layout != null and game.sim.kills == 8 and is_equal_approx(game.sim.elapsed,34.5),"The screens never touch the simulation")
	click(screen)
	check(game.room != null and not screen.visible,"A click after the tally goes to the room")
	game.queue_free()
	await process_frame
	print("RESULTS: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
