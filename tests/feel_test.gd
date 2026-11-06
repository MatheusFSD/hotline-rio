extends SceneTree
## The weight of a blow: blood that stays for the whole night, the hit stop, the camera's push with a
## direction, and the retry on R.
const Campaign = preload("res://scripts/campaign.gd")
var checks := 0
var failures := 0

func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void: call_deferred("run")

func fresh_game():
	Campaign.state = Campaign.fresh()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_or_resume()
	game.sim.state = "playing"
	game.sim.god = true
	return game

func press(game,keycode: int) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = keycode
	game._unhandled_input(event)

func held_frames(game) -> int:
	## Frames the simulation stands still, from the frame that hears the kill.
	game._physics_process(1.0/60)
	var clock: float = game.sim.elapsed
	var frames := 0
	while frames < 30:
		game._physics_process(1.0/60)
		if game.sim.elapsed != clock: break
		frames += 1
	return frames

func run() -> void:
	var game = fresh_game()
	var effects = game.effects
	# Blood stays: a whole night of kills, none overwritten. (Headless rendering keeps no instance data:
	# the colour and the place are checked on screen, by tests/feel_capture.gd.)
	var spot: Vector2 = game.sim.player.p
	var burst: Array[Dictionary] = []
	burst.append({"type":"blood","p":spot,"direction":Vector2.RIGHT,"player":false})
	effects.consume(burst,game.actors)
	check(not effects.growing.is_empty(),"A pool spreads")
	for kill in 40:
		burst.append({"type":"blood","p":spot,"direction":Vector2.RIGHT,"player":false})
		effects.consume(burst,game.actors)
		for i in 20: effects.update(1.0/30)
	check(effects.growing.is_empty(),"Pools stop spreading")
	check(effects.stain_total > 128,"A night's kills leave more than the old limit of stains (%d)" % effects.stain_total)
	var shown := 0
	for sheet in effects.stain_sheets: shown += sheet.visible_instance_count
	check(shown == effects.stain_total,"All of them are still drawn (%d of %d)" % [shown,effects.stain_total])
	check(effects.sheet_used.max() <= effects.STAINS_PER_SHEET,"…none written over another")
	# Past the limit the oldest goes, nothing breaks.
	effects.stain_total = effects.MAX_STAINS+1
	effects.sheet_used.fill(effects.STAINS_PER_SHEET+1)
	effects._stain(spot,.1,Color.WHITE)
	check(effects.stain_sheets[1].visible_instance_count == effects.STAINS_PER_SHEET,"Over the limit: still inside the sheet")
	effects.clear()
	shown = 0
	for sheet in effects.stain_sheets: shown += sheet.visible_instance_count
	check(shown == 0 and effects.stain_total == 0 and effects.growing.is_empty(),"The retry washes the floor")
	# The push: against the hero's shot, by his gun's kick; along the kill; an enemy's shot does not push.
	burst.append({"type":"shot","p":spot,"direction":Vector2.RIGHT,"team":"player","shooter":-1,"kick":game.sim.WEAPONS.pistol.kick,"weapon":"pistol"})
	effects.consume(burst,game.actors)
	check(effects.kick.x < -.1 and is_zero_approx(effects.kick.y),"A shot east leans the camera west")
	var pistol_push: float = -effects.kick.x
	effects.clear()
	burst.append({"type":"shot","p":spot,"direction":Vector2.RIGHT,"team":"player","shooter":-1,"kick":game.sim.WEAPONS.shotgun.kick,"weapon":"shotgun"})
	effects.consume(burst,game.actors)
	check(-effects.kick.x > pistol_push*2,"A shotgun leans it much further than a pistol")
	effects.clear()
	burst.append({"type":"shot","p":spot,"direction":Vector2.RIGHT,"team":"enemy","shooter":0,"kick":.035,"weapon":"pistol"})
	effects.consume(burst,game.actors)
	check(effects.kick == Vector2.ZERO,"An enemy's shot does not lean it")
	effects.clear()
	burst.append({"type":"blood","p":spot,"direction":Vector2.UP,"player":false})
	effects.consume(burst,game.actors)
	check(effects.kick.y < 0,"A kill leans it along the shot")
	for i in 4: effects.update(1.0/60)
	check(game.camera.v_offset > 0 or absf(game.camera.v_offset) < .3,"…up the screen for a shot up the screen")
	var leaned: float = effects.kick.length()
	var aim: Vector2 = game.aim_position()
	effects.kick = Vector2(.4,.4)
	effects.update(0.0)
	check(game.aim_position().is_equal_approx(aim),"The lean does not move the aim")
	effects.kick = Vector2.ZERO
	for i in 4: effects.update(1.0/60)
	check(leaned > 0 and effects.kick == Vector2.ZERO,"…and settles back")
	effects.clear()
	game.sim.events.clear()
	# The hit stop: the world holds, on real time; the sound does not.
	var living: Array = game.sim.enemies.filter(func(e): return e.alive)
	game.sim.kill(living[0],Vector2.RIGHT,"pistol")
	check(held_frames(game) in [2,3],"A bullet's kill holds about three frames")
	check(game.sound.world == 1.0,"The sound is not held")
	game.hit_stop_rest = 0.0
	game.sim.kill(living[1],Vector2.RIGHT,"katana")
	check(held_frames(game) in [4,5],"The blade holds longer")
	game.hit_stop_rest = 0.0
	game.sim.kill(living[2],Vector2.RIGHT,"pistol")
	game._physics_process(1.0/60)
	check(game.hit_stop > 0.0,"Held")
	game.sim.kill(living[3],Vector2.RIGHT,"pistol")
	game.hit_stop = 0.0
	game._physics_process(1.0/60)
	check(game.hit_stop == 0.0,"A kill right after is not held again: a minigun must not stutter")
	game.hit_stop_rest = 0.0
	game.sim.events.clear()
	game.sim.events.append({"type":"blood","p":spot,"direction":Vector2.RIGHT,"player":true,"gore_allowed":true,"weapon":"pistol"})
	game._physics_process(1.0/60)
	check(game.hit_stop == 0.0,"The hero's own death has its own beat")
	game.sim.events.append({"type":"blood","p":spot,"direction":Vector2.RIGHT,"player":false,"gore_allowed":false,"weapon":""})
	game._physics_process(1.0/60)
	check(game.hit_stop == 0.0,"A kill by no blow holds nothing")
	game.sim.kill(game.sim.enemies.filter(func(e): return e.alive)[0],Vector2.RIGHT,"pistol")
	game._physics_process(1.0/60)
	check(game.hit_stop > 0.0,"Held once more")
	game.start_or_resume()
	game.sim.state = "playing"
	check(game.hit_stop == 0.0 and game.hit_stop_rest == 0.0,"A retry starts unheld")
	game.queue_free()
	await process_frame
	# R: only after dying, and not by a reload's tap as he dies.
	game = fresh_game()
	game._physics_process(1.0/60)
	var attempt: int = game.sim.attempt
	press(game,KEY_R)
	check(game.sim.attempt == attempt and game.sim.state == "playing","While he lives, R is only the reload")
	game.sim.god = false
	game.sim.die(Vector2.RIGHT,"pistol")
	game._physics_process(1.0/60)
	check(game.sim.state == "dead" and game.death_time >= 0.0 and game.death_time < game.RETRY_GUARD,"He is down")
	press(game,KEY_R)
	check(game.sim.state == "dead","A tap as he dies does not skip his death")
	while game.death_time < game.RETRY_GUARD: game._physics_process(1.0/60)
	check(not game.results.visible,"Still in the death's slow motion")
	press(game,KEY_R)
	check(game.sim.state == "playing" and game.sim.player.alive and game.sim.attempt == attempt+1,"R retries, without waiting for the screen")
	check(game.music.pitch_scale == 1.0 and game.death_time < 0.0,"…with the night's music back up")
	game.sim.god = false
	game.sim.die(Vector2.RIGHT,"pistol")
	game._physics_process(1.0/60)
	game._update_death_beat(2.05)
	check(game.results.visible and game.results.mode == "dead","The death screen")
	check("R" in game.results.prompt.text,"…says so")
	press(game,KEY_R)
	check(game.sim.state == "playing" and not game.results.visible,"R retries from the screen too")
	game.queue_free()
	await process_frame
	# What a bullet stops in: a hole and the right debris; a sofa takes it without a mark.
	game = fresh_game()
	effects = game.effects
	var sim = game.sim
	sim.player.p = Vector2(-6.8,5)
	sim.player.angle = 0
	sim.events.clear()
	sim.attack()
	var impact := {}
	for i in 6:
		sim.update(1.0/60)
		for event in sim.events: if event.type == "impact": impact = event
	check(impact.get("surface","") == "stone" and impact.has("rect"),"A bullet into a wall knows it is stone")
	sim.events.clear()
	var solids: Array = sim.layout.solids
	var desk: Dictionary = solids.filter(func(s): return s.type in ["desk","counter","table","crate"])[0]
	var desk_rect := Rect2(desk.r[0],desk.r[1],desk.r[2],desk.r[3])
	check(sim.surface_at(Vector2(desk_rect.position.x,desk_rect.get_center().y)).surface == "wood","…and furniture that it is wood")
	var hits: Array[Dictionary] = [{"type":"impact","p":impact.p,"direction":impact.direction,"surface":"stone","rect":impact.rect,"h":impact.h}]
	effects.consume(hits,game.actors)
	check(effects.hole_total == 1,"It leaves a hole")
	check(effects.face_normal(Rect2(0,0,2,1),Vector2(1,1)) == Vector2.DOWN,"…on the face it hit (the one toward the camera here)")
	hits = [{"type":"impact","p":impact.p,"direction":impact.direction,"surface":"soft","rect":impact.rect,"h":1.0}]
	effects.consume(hits,game.actors)
	check(effects.hole_total == 1,"A sofa takes it without a mark")
	effects.clear()
	check(effects.hole_total == 0 and effects.holes.visible_instance_count == 0,"The retry fills the holes")
	game.queue_free()
	await process_frame
	# Glass: the bullet goes on, the pane cracks where it crossed.
	game = fresh_game()
	game.load_level(9)
	game.start_or_resume()
	game.sim.state = "playing"
	game.sim.god = true
	sim = game.sim
	var pane: Dictionary = sim.panes.filter(func(p): return (p.r as Rect2).size.y < (p.r as Rect2).size.x)[0]
	var across: Rect2 = pane.r
	var start := Vector2(across.get_center().x,across.end.y+.6)
	sim.events.clear()
	sim.bullets.append({"p":start,"origin":start,"v":Vector2(0,-29),"team":"player","shooter":-1,"life":1.0,"weapon":"pistol"})
	var crossed := {}
	for i in 4:
		sim.update(1.0/60)
		for event in sim.events: if event.type == "glass": crossed = event
		game.effects.consume(sim.events,game.actors)
	check(not crossed.is_empty() and absf(crossed.p.y-across.end.y) < .05,"A bullet through a pane: it cracks where it crossed")
	check(game.effects.crack_total == 1,"…one crack")
	game.queue_free()
	await process_frame
	# An enemy turning on him: a "!" over the head, a sting.
	game = fresh_game()
	game._physics_process(1.0/60)
	var watcher: Dictionary = game.sim.enemies[0]
	watcher.alerted = false
	game._physics_process(0.0)
	game.sound.silence()
	watcher.alerted = true
	game._physics_process(0.0)
	check(game.actors[1].alert_time >= 0.0 and game.actors[1].alert_mark.visible,"An enemy who sees him: a mark over his head")
	check(game.sound.voices.any(func(v): return v.playing and v.stream == game.sound.ALERT),"…and a sting")
	for i in 60: game.actors[1].sync(watcher,1.0/60,false)
	check(not game.actors[1].alert_mark.visible,"…for a moment only")
	# The aim: it opens on a shot, turns through a reload, an X on each kill.
	game.sim.events.append({"type":"shot","team":"player","weapon":"pistol","p":game.sim.player.p,"direction":Vector2.RIGHT,"shooter":-1,"kick":.18})
	game._physics_process(0.0)
	check(game.aim_marker.scale.x > 1.5,"A shot opens the aim")
	for i in 30: game._update_aim(1.0/60,1.0/60)
	check(game.aim_marker.scale.x < 1.05,"…and it closes back")
	game.sim.player.reload = 1.0
	game._update_aim(1.0/60,.1)
	check(absf(game.aim_marker.rotation.y) > .5,"It turns through a reload")
	game.sim.player.reload = 0.0
	for i in 60: game._update_aim(1.0/60,1.0/60)
	var rest := fmod(absf(game.aim_marker.rotation.y),PI/2)
	check(rest < .01 or PI/2-rest < .01,"…and settles square")
	game.sim.events.clear()
	game.sim.kill(game.sim.enemies[1],Vector2.RIGHT,"pistol")
	game._physics_process(1.0/60)
	check(game.kill_marks.size() == 1,"A kill leaves an X on the body")
	for i in 40: game._update_aim(1.0/60,1.0/60)
	check(game.kill_marks.is_empty(),"…that goes")
	# Slow motion muffles the night's music.
	game.kill_time = game.ZOOM_IN_TIME+.05
	game._update_music_bus(0.0)
	var muffle := AudioServer.get_bus_effect(game.music_bus,0) as AudioEffectLowPassFilter
	check(AudioServer.is_bus_effect_enabled(game.music_bus,0) and muffle.cutoff_hz < 1500,"Slow motion muffles the music")
	game.kill_time = -1.0
	game._update_music_bus(0.0)
	check(not AudioServer.is_bus_effect_enabled(game.music_bus,0),"…and lets it open")
	# The last enemy: a longer hold, the music drops and opens back.
	game.hit_stop_rest = 0.0
	game.hit_stop = 0.0
	for e in game.sim.enemies:
		if e.alive: game.sim.kill(e,Vector2.RIGHT,"pistol")
	game._physics_process(1.0/60)
	check(game.hit_stop >= game.LAST_STOP-1.0/60,"The last one down holds longer than any kill")
	check(game.music_drop >= 0.0,"…and the music drops")
	for i in 20: game._update_music_bus(1.0/60)
	check(AudioServer.get_bus_volume_db(game.music_bus) < -15.0,"…out")
	for i in 90: game._update_music_bus(1.0/60)
	check(game.music_drop < 0.0 and is_zero_approx(AudioServer.get_bus_volume_db(game.music_bus)) and not AudioServer.is_bus_effect_enabled(game.music_bus,0),"…and comes back whole")
	game.start_or_resume()
	check(game.kill_marks.is_empty() and game.music_drop < 0.0 and not game.all_down,"A retry starts clean")
	game.queue_free()
	await process_frame
	print("FEEL: %d/%d checks passed" % [checks-failures,checks])
	quit(1 if failures else 0)
