extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func key(game,code) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._unhandled_input(event)
func check(ok: bool,message: String) -> void:
	if not ok: failed = true; push_error(message)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	check(game.actors.size() == 9 and game.sim.state == "ready","Runtime loads hero + 8 enemies")
	key(game,KEY_ENTER)
	check(game.sim.state == "playing" and not game.overlay.visible,"Enter starts and hides briefing")
	key(game,KEY_ESCAPE)
	check(game.sim.state == "paused" and game.overlay.visible,"Escape pauses and opens overlay")
	game.start_or_resume()
	check(game.sim.state == "playing" and game.sim.attempt == 1,"Continue keeps current attempt")
	game.sim.player.ammo = 1
	game.sim.kill(game.sim.enemies[0])
	var press := InputEventKey.new()
	press.physical_keycode = KEY_R
	press.pressed = true
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	key(game,KEY_R)
	game._physics_process(1.0/60)
	check(game.sim.player.reload > 0 and game.sim.kills == 1 and game.sim.attempt == 1,"R reloads and never restarts the night")
	var release := press.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	game.sim.reset()
	game.sim.die()
	game.update_ui()
	check(game.death_time == 0.0 and not game.results.visible and not game.overlay.visible,"Death starts the death beat, not the screen")
	game._update_death_beat(2.05)
	check(game.results.visible and game.results.mode == "dead","Death screen after the beat")
	key(game,KEY_ENTER)
	check(game.sim.state == "playing" and game.sim.player.alive,"Enter restarts after death")
	var hero := Vector3(game.sim.player.p.x,1.0,game.sim.player.p.y)
	var hero_screen: Vector2 = game.camera.unproject_position(hero)
	game.sim.kill(game.sim.enemies[1],Vector2.UP)
	game._update_kill_zoom(1.0/60)
	game.sim.events.clear()
	check(game.kill_zoom > 0 and game.kill_zoom < 1 and game.time_scale() == 1.0,"Kill zoom starts before slow motion")
	# Expected order: zoom in, slow motion begins, slow motion ends, zoom out ends.
	var zoomed_size := INF
	var drift := 0.0
	var first_slow := -1
	var last_slow := -1
	var zoomed_during_slow := true
	var zoom_out_start := -1
	for i in 90:
		game._update_kill_zoom(1.0/60)
		zoomed_size = minf(zoomed_size,game.camera.size)
		drift = maxf(drift,game.camera.unproject_position(hero).distance_to(hero_screen))
		if game.time_scale() < 1.0:
			if first_slow < 0: first_slow = i
			last_slow = i
			if game.kill_zoom < 1.0: zoomed_during_slow = false
		elif last_slow >= 0 and zoom_out_start < 0 and game.kill_zoom < 1.0: zoom_out_start = i
	check(zoomed_size < game.CAMERA_SIZE*.93,"A kill zooms the camera in")
	check(drift < 2.0,"Kill zoom keeps the hero in place on screen")
	check(first_slow >= 0 and last_slow-first_slow+1 >= 20 and last_slow-first_slow+1 <= 26,"Slow motion lasts about 0.4 seconds")
	check(zoomed_during_slow,"Camera stays fully zoomed for the whole slow motion")
	check(zoom_out_start > last_slow,"Zoom releases only after slow motion ends")
	check(is_equal_approx(game.camera.size,game.CAMERA_SIZE) and game.camera.position.is_equal_approx(game.CAMERA_HOME),"Kill zoom eases back out")
	var crisp := true
	for node in game.find_children("Lapa_*","MeshInstance3D",true,false):
		for surface in node.mesh.get_surface_count():
			var mat := node.mesh.surface_get_material(surface) as BaseMaterial3D
			if mat and mat.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST: crisp = false
	check(crisp,"Scenery textures use nearest filtering")
	var hero_visual = game.actors[0]
	var player: Dictionary = game.sim.player
	player.phasing = true
	player.moving = true
	player.velocity = Vector2(5.2,0)
	for i in 10:
		player.p += Vector2(5.2/60,0)
		hero_visual.sync(player,1.0/60,false)
		game._update_phase_view(1.0/60)
	var torso: MeshInstance3D = hero_visual.body_parts.parts.torso
	check(torso.material_override == hero_visual.ghost_material and hero_visual.ghost_material.next_pass.no_depth_test,"Spectre turns the body translucent and visible through walls")
	check(hero_visual.afterimages.size() >= 2 and hero_visual.afterimages[0].node.mesh.get_surface_count() == 1,"Moving as a spectre leaves frozen afterimages")
	check(game.world_environment.adjustment_saturation < .7 and game.phase_tint.color.a > .05,"Spectre desaturates and tints the view")
	player.phasing = false
	for i in 30:
		hero_visual.sync(player,1.0/60,false)
		game._update_phase_view(1.0/60)
	check(torso.material_override == null and hero_visual.afterimages.is_empty() and game.world_environment.adjustment_saturation > .98,"Leaving the spectre restores body, afterimages and colour")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.sim.state == "paused","Losing focus pauses")
	game.queue_free()
	await process_frame
	print("RUNTIME: ","FAILED" if failed else "21/21 checks passed")
	quit(1 if failed else 0)
