extends SceneTree
const Entrance = preload("res://scripts/level_entrance.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.cinematics = true
	var start: Vector2 = game.sim.point(game.sim.layout.start)
	var path: Array = game.sim.layout.entrance.path
	var first := Vector2(path[0][0],path[0][1])
	check(not game.sim.blocked(first) and game.sim.can_see(first,start),"Entrance path is clear of walls")
	game.start_or_resume()
	check(game.sim.state == "entering" and game.entrance != null and not game.overlay.visible,"A night opens with the walk-in, briefing hidden")
	check(game.sim.player.p.distance_to(first) < .01 and game.sim.player.moving,"The hero starts at the first point of the entrance, walking")
	check(game.camera.size < game.CAMERA_SIZE*.5,"The camera starts close on the hero")
	var hero_screen: Vector2 = game.camera.unproject_position(Vector3(game.sim.player.p.x,1.0,game.sim.player.p.y))
	var view: Vector2 = game.get_viewport().get_visible_rect().size
	check(Rect2(Vector2.ZERO,view).has_point(hero_screen),"The hero is in frame from the first moment")
	var walk_anim := ""
	var elapsed_before: float = game.sim.elapsed
	var enemy_before: Vector2 = game.sim.enemies[0].p
	var inside := true
	var arrived_close := false
	var t := 0.0
	while game.sim.state == "entering" and t < 20.0:
		game._update_entrance(1.0/60)
		if game.sim.state != "entering":
			t += 1.0/60
			break
		game.sim.update(1.0/60,{})
		game.actors[0].sync(game.sim.player,1.0/60,false)
		if t > .5 and walk_anim.is_empty(): walk_anim = game.actors[0].current
		inside = inside and game.camera.position.x-game.camera.size*view.x/view.y/2 >= game.scenery_bounds.position.x-.01
		if game.sim.player.p.distance_to(start) < .01 and game.entrance and game.entrance.arrived_for < .1: arrived_close = game.camera.size < game.CAMERA_SIZE*.5
		t += 1.0/60
	var expected: float = Entrance.from_layout(game.sim.layout,start,-PI/2).duration()
	check(walk_anim.begins_with("armed_walk"),"The hero walks in with the walk cycle (%s)" % walk_anim)
	check(arrived_close,"The camera stays close until he reaches the start point")
	check(inside,"The close framing never shows past the scenery")
	check(game.sim.state == "playing" and absf(t-expected) < .1,"Control is handed over when the pull-back ends (%.2f s of %.2f s)" % [t,expected])
	check(game.sim.player.p == start and is_equal_approx(game.sim.player.angle,-PI/2) and not game.sim.player.moving,"He ends at the start point, facing the level")
	check(game.camera.position.is_equal_approx(game.CAMERA_HOME) and is_equal_approx(game.camera.size,game.CAMERA_SIZE),"The camera ends exactly at the gameplay framing")
	check(game.sim.elapsed == elapsed_before and game.sim.enemies[0].p == enemy_before,"The level waits during the walk-in")
	# Retrying after a death starts at once; the next night opens with the walk-in again, skippable.
	game.sim.die()
	game.start_or_resume()
	check(game.sim.state == "playing" and game.entrance == null,"Retrying after a death skips the walk-in")
	game.sim.state = "ready"
	game.start_or_resume()
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ENTER
	event.pressed = true
	game._unhandled_input(event)
	check(game.sim.state == "playing" and game.sim.player.p == start and game.camera.position.is_equal_approx(game.CAMERA_HOME),"Enter skips the walk-in")
	check(Entrance.from_layout({},start,0.0) == null,"A level without an entrance starts directly")
	game.queue_free()
	await process_frame
	print("ENTRANCE: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
