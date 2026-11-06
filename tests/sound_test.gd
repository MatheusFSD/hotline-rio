extends SceneTree
## The combat sounds on the game's own clock. Every shot sounds with its own gun, an enemy's under the
## hero's; a bullet into anyone sounds, and the blade makes one sound as it lands, its cut or the air; a reload pulls, then pushes right after; slow motion drags down what rings and what starts in it. The hero's death: the night's
## music sinks across the slow motion, then is held; the death music comes in exactly as the slow
## motion ends, what still rang is cut; a retry brings the night's music back at its full level.
const Campaign = preload("res://scripts/campaign.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func ringing(game) -> Array:
	return game.sound.voices.filter(func(v): return v.playing).map(func(v): return v.stream.resource_path.get_file().get_basename())
func voice_of(game,name: String) -> AudioStreamPlayer:
	return game.sound.voices.filter(func(v): return v.playing and v.stream.resource_path.get_file().get_basename() == name)[0]
func ringing_screen(game) -> Array:
	return game.sound.screen_voices.filter(func(v): return v.playing).map(func(v): return v.stream.resource_path.get_file().get_basename())
func blade_sounds(game) -> void:
	for event in game.sim.events: if event.type in ["slash","strike","blood"]: game.sound.hear(event)
	game.sim.events.clear()   # as the effects do with each frame's events
func swing_out(game,aim) -> void:
	for i in 20:
		game.sim.update(1.0/60,{"aim":aim})
		blade_sounds(game)
func fresh_game():
	Campaign.state = Campaign.fresh()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_or_resume()
	game.sim.state = "playing"
	game.sim.god = true
	game.sim.player.p = game.sim.nearest_free(game.sim.player.p)
	return game
func step(game,frames := 1) -> void:
	for i in frames: game._physics_process(1.0/60)
func run() -> void:
	var game = fresh_game()
	game._physics_process(1.0/60)
	# Every gun has its own shot.
	for gun in ["pistol","smg","shotgun","rifle","minigun"]:
		game.sound.silence()
		game.sound.hear({"type":"shot","team":"player","weapon":gun})
		check(ringing(game) == [gun],"The %s sounds as itself" % gun)
	game.sound.silence()
	game.sim.weapon = "pistol"
	game.sim.player.cooldown = 0.0
	game.sim.player.ammo = 12
	game.sim.attack()
	game._physics_process(0.0)
	check(ringing(game).filter(func(n): return n != "alert") == ["pistol"],"Firing in the game: the shot sounds on that frame (and the room may turn on him)")
	game.sound.silence()
	game.sim.events.clear()
	game.sim.enemies[0].weapon = "rifle"
	game.sim.shoot(game.sim.enemies[0],"enemy",game.sim.ENEMY_RIFLE)
	for event in game.sim.events: game.sound.hear(event)
	check(ringing(game) == ["rifle"],"A guard's rifle sounds as a rifle")
	var guard: AudioStreamPlayer = voice_of(game,"rifle")
	check(is_equal_approx(guard.volume_db,game.sound.VOLUME_DB+game.sound.ENEMY_DB),"…under the hero's level")
	game.sound.silence()
	game.sim.events.clear()
	game.sim.enemies[1].weapon = "pistol"
	game.sim.shoot(game.sim.enemies[1],"enemy",game.sim.ENEMY_GUN)
	for event in game.sim.events: game.sound.hear(event)
	check(ringing(game) == ["pistol"],"Anyone else's pistol as a pistol")
	game.sound.silence()
	game.sound.hear({"type":"shot","team":"player","weapon":"pistol"})
	check(is_equal_approx(voice_of(game,"pistol").volume_db,game.sound.VOLUME_DB),"The hero's next shot back at full level, in whatever voice")
	game.sound.silence()
	# Flesh, from the real kills.
	var enemy: Dictionary = game.sim.enemies[0]
	var other: Dictionary = game.sim.enemies[1]
	game.sim.events.clear()
	game.sim.kill(other,Vector2.RIGHT,"pistol")
	for event in game.sim.events: game.sound.hear(event)
	check(ringing(game) == ["flesh"],"A bullet in an enemy")
	game.sound.silence()
	game.sound.hear({"type":"blood","gore_allowed":true,"weapon":"pistol","player":true})
	check(ringing(game) == ["flesh"],"A bullet in the hero")
	game.sound.silence()
	game.sound.hear({"type":"blood","gore_allowed":false,"weapon":"sindico","player":true})
	check(ringing(game).is_empty(),"The Síndico's touch is no bullet")
	game.sound.silence()
	# The blade: silent in the air, then one sound as it lands, the cut or the whoosh.
	var victim: Dictionary = enemy if enemy.alive else game.sim.enemies[2]
	for a in 8:
		game.sim.player.p = game.sim.nearest_free((victim.p as Vector2)+Vector2.from_angle(a*TAU/8))
		if game.sim.can_see(game.sim.player.p,victim.p): break
	game.sim.player.angle = ((victim.p as Vector2)-game.sim.player.p).angle()
	game.sim.player.melee = true
	game.sim.player.cooldown = 0.0
	game.sim.events.clear()
	game.sim.attack()
	blade_sounds(game)
	check(ringing(game).is_empty() and game.sim.player.swing == 0.0,"The blade in the air: nothing yet")
	swing_out(game,victim.p)
	check(ringing(game) == ["sword_cut"] and not victim.alive,"It goes in: its own cut, and only that")
	game.sound.silence()
	for e in game.sim.enemies: e.alive = false
	game.sim.player.cooldown = 0.0
	game.sim.attack()
	swing_out(game,victim.p)
	check(ringing(game) == ["whoosh"],"It finds nobody: only the air")
	game.sound.silence()
	game.sim.shells.append({"p":game.sim.player.p+Vector2.from_angle(game.sim.player.angle),"angle":0.0,"torn":false,"used":false,"style":"","name":""})
	game.sim.player.cooldown = 0.0
	game.sim.attack()
	swing_out(game,game.sim.shells[-1].p)
	check(ringing(game) == ["sword_cut"],"A hanging bag is a body too")
	game.sim.player.melee = false
	game.sim.player.swing = -1.0
	game.sim.shells.clear()
	game.sound.silence()
	# The reload: pull, then the push just before the gun is ready.
	game.sim.player.ammo = 1
	game.sim.reload()
	var total: float = game.sim.player.reload
	game.sound.follow_reload(game.sim.player,"pistol")
	check(ringing(game) == ["reload_out"] and game.sound.reload_stage == 1,"The reload pulls as it starts")
	game.sim.player.reload = total*.5
	game.sound.follow_reload(game.sim.player,"pistol")
	check(game.sound.reload_stage == 2,"…and by half of it has already pushed")
	game.sound.silence()
	game.sim.player.ammo = 1
	game.sim.player.reload = 0.0
	game.sim.reload()
	total = game.sim.player.reload
	game.sound.follow_reload(game.sim.player,"pistol")
	game.sim.player.reload = total-game.sound.RELOAD_GAP*.5
	game.sound.follow_reload(game.sim.player,"pistol")
	check(game.sound.reload_stage == 1,"The two beats are one short gap apart")
	game.sim.player.reload = total-game.sound.RELOAD_GAP
	game.sound.follow_reload(game.sim.player,"pistol")
	check(ringing(game).has("reload_in") and game.sound.reload_stage == 2,"…and the push comes right after, not at the end of the reload")
	game.sim.player.reload = 0.0
	game.sound.follow_reload(game.sim.player,"pistol")
	check(game.sound.reload_stage == 0,"Ready for the next one")
	game.sound.silence()
	game.sim.player.reload = 1.0
	game.sound.follow_reload(game.sim.player,"shotgun")
	check(ringing(game) == ["shotgun_out"],"The shotgun has its own pump")
	game.sim.player.reload = 0.0
	game.sound.silence()
	# The world answers: a bullet in a wall, once for a shotgun's seven pellets; the enemy's quieter.
	for i in 7: game.sound.hear({"type":"impact","team":"player"})
	check(ringing(game) == ["wall_hit"],"A shotgun blast in a wall is one sound")
	game.sound.advance(game.sound.WALL_GAP+.01,game.sim.player,false)
	game.sound.hear({"type":"impact","team":"enemy"})
	check(ringing(game).size() == 2,"…and the next one sounds after its gap")
	game.sound.silence()
	game.sound.hear({"type":"impact","team":"enemy"})
	check(is_equal_approx(voice_of(game,"wall_hit").volume_db,game.sound.VOLUME_DB+game.sound.WALL_ENEMY_DB),"An enemy's stray is under the hero's")
	game.sound.silence()
	# Brass lands after it flew, the hero's only, and a fast gun's is a patter.
	game.sound.hear({"type":"shot","team":"enemy","weapon":"pistol"})
	check(game.sound.casings.is_empty(),"An enemy's brass is not heard")
	game.sound.silence()
	game.sound.hear({"type":"shot","team":"player","weapon":"pistol"})
	check(not ringing(game).has("casing"),"The brass is still in the air as the shot rings")
	game.sound.advance(game.sound.CASING_FALL*1.2,game.sim.player,false)
	check(ringing(game).has("casing"),"…and then it lands")
	game.sound.silence()
	for i in 40: game.sound.hear({"type":"shot","team":"player","weapon":"minigun"})
	check(game.sound.casings.size() == 1,"Rounds fired together are one landing")
	game.sound.silence()
	# His feet: alternating, by distance, and a ghost makes none.
	var runner: Dictionary = game.sim.player.duplicate()
	runner.velocity = Vector2(game.sim.SPEED,0)
	var heard := 0
	for i in 120:
		game.sound.advance(1.0/60,runner,true)
		heard = ringing(game).filter(func(n): return n.begins_with("step_")).size()
	check(heard >= 1 and game.sound.foot in [0,1],"He runs: footfalls")
	game.sound.silence()
	var steps := 0
	game.sound.stride = 0.0
	for i in 60:
		var before: int = game.sound.foot
		game.sound.advance(1.0/60,runner,true)
		if game.sound.foot != before: steps += 1
	check(steps >= 3 and steps <= 4,"…about one every 1.45 m at a run (%d in a second)" % steps)
	game.sound.silence()
	runner.phasing = true
	for i in 60: game.sound.advance(1.0/60,runner,true)
	check(ringing(game).is_empty(),"A ghost makes no footfall")
	runner.phasing = false
	runner.velocity = Vector2.ZERO
	for i in 60: game.sound.advance(1.0/60,runner,true)
	check(ringing(game).is_empty(),"Standing still neither")
	# Changing hands, the breaker, a camera: from the real events.
	game.sim.events.clear()
	game.sim.player.melee = false
	game.sim.melee = false
	game.sim.switch_weapon()
	for event in game.sim.events: game.sound.hear(event)
	check(ringing(game) == ["katana_draw"],"To the blade: steel leaving the scabbard")
	game.sound.silence()
	game.sim.events.clear()
	game.sim.switch_weapon()
	for event in game.sim.events: game.sound.hear(event)
	check(ringing(game) == ["gun_draw"],"Back to the gun")
	game.sim.events.clear()
	game.sound.silence()
	game.sound.hear({"type":"blackout"})
	check(ringing(game) == ["breaker"],"The breaker goes")
	game.sound.silence()
	game.sound.hear({"type":"camera_down"})
	check(ringing(game) == ["camera_break"],"A camera breaks")
	game.sound.silence()
	# What the bullet stopped in, glass on the way, a room turning on him.
	for surface in ["stone","wood","metal","soft"]:
		game.sound.silence()
		game.sound.hear({"type":"impact","team":"player","surface":surface})
		check(ringing(game) == [game.sound.SURFACE_HITS[surface].resource_path.get_file().get_basename()],"A bullet into %s sounds as it" % surface)
	game.sound.silence()
	for i in 4: game.sound.hear({"type":"glass"})
	check(ringing(game) == ["glass_hit"],"A shotgun through a pane: one crack")
	game.sound.silence()
	for i in 5: game.sound.alert()
	check(ringing(game) == ["alert"],"A whole room seeing him: one sting")
	game.sound.silence()
	# Slow motion, with the real clock of a kill.
	game.sound.play(game.sound.SHOTS.pistol,1.0,0.0)
	var voice: AudioStreamPlayer = game.sound.voices.filter(func(v): return v.playing)[0]
	check(is_equal_approx(voice.pitch_scale,1.0),"At full speed, at full pitch")
	game.kill_time = game.ZOOM_IN_TIME
	game.sound.set_time(game.time_scale())
	check(is_equal_approx(voice.pitch_scale,game.SLOWMO_SCALE),"A kill's slow motion drags down what rings")
	game.sound.play(game.sound.FLESH,1.0,0.0)
	var later: AudioStreamPlayer = voice_of(game,"flesh")
	check(is_equal_approx(later.pitch_scale,game.SLOWMO_SCALE),"…and what starts in it")
	game.kill_time = -1.0
	game.sound.set_time(game.time_scale())
	check(is_equal_approx(voice.pitch_scale,1.0),"…and lets it back up")
	game.sound.silence()
	# The hero's death, in steps of the real beat.
	game.sim.god = false
	game.sim.die(Vector2.RIGHT,"pistol")
	step(game)
	check(ringing(game).has("flesh") and game.death_time >= 0.0,"The bullet goes in")
	var position: float = game.music.get_playback_position()
	check(not game.death_music.playing and game.music.playing,"In the slow motion, no death music yet")
	step(game,30)
	check(game.music.pitch_scale < 1.0 and game.music.volume_db < game.MUSIC_DB,"The night's music sinks with it")
	check(game.sound.world < .25 and voice_of(game,"flesh").pitch_scale < .3,"The bullet's sound crawls")
	while game.death_time < game.DEATH_SLOWMO-2.0/60: step(game)
	check(not game.death_music.playing and not game.results.visible,"A moment before the end of it, still nothing")
	step(game,3)
	check(game.death_music.playing and game.death_music.stream.loop and game.results.visible,"The slow motion over, the screen and the death music, together")
	check(game.music.stream_paused,"The night's music is held, not dropped")
	check(game.sound.cutting != null and game.sound.world < .25,"What still rang goes, without rising back to pitch")
	var path: String = game.music_path
	step(game,60)
	check(game.death_music.playing,"The death music stays on")
	game.start_or_resume()
	check(not game.death_music.playing and game.music_path == path and not game.music.stream_paused,"A retry: the death music gone, the night's back")
	check(game.music.pitch_scale == 1.0 and game.music.volume_db == game.MUSIC_DB,"…at its pitch and its level")
	check(ringing(game).is_empty() and game.sound.cutting == null and game.sound.world == 1.0,"…and nothing left ringing")
	game.queue_free()
	await process_frame
	# The walk-in's music: over the walk, ending on its hit as he stops; the night's after it.
	Campaign.state = Campaign.fresh()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.cinematics = true
	game.start_or_resume()
	check(game.sim.state == "entering" and game.entrance_music.playing and game.entrance_music.stream.loop and game.music_path == "","He walks in: the walk-in's music, not the night's yet")
	var guard_steps := 0
	while not game.entrance.pulling_back() and guard_steps < 3000:
		game._update_entrance(1.0/60)
		guard_steps += 1
		if not game.entrance.pulling_back() and not game.entrance_music.playing: check(false,"The walk-in's music stopped while he was still walking")
	check(not game.entrance_music.playing and game.cue.playing and game.cue.stream.resource_path.ends_with("entrance_hit.ogg"),"He stops, the camera pulls back: it ends on its hit")
	check(game.sim.state == "entering" and game.music_path == "","The hit rings over the pull-back")
	while game.sim.state == "entering" and guard_steps < 6000:
		game._update_entrance(1.0/60)
		guard_steps += 1
	check(game.sim.state == "playing" and game.music_path == game.sim.layout.music,"Control in the hero's hands: the night's music")
	game.queue_free()
	await process_frame
	# Skipped mid-walk: still its hit, then the night.
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.cinematics = true
	game.start_or_resume()
	game.skip_entrance()
	check(not game.entrance_music.playing and game.cue.playing and game.music_path == game.sim.layout.music,"A skipped walk-in: its hit, and the night's music at once")
	# The night clear: the music cut, the short cue, the title and grade slams, the digits.
	var slams := []
	var ticks := []
	game.results.slammed.connect(func(heavy): slams.append(heavy))
	game.results.ticked.connect(func(p): ticks.append(p))
	for e in game.sim.enemies: e.alive = false
	game.sim.kills = game.sim.enemies.size()
	game.sim.state = "won"
	game.update_ui()
	check(game.cue.stream.resource_path.ends_with("night_clear.ogg") and game.cue.playing and game.music_path == "","Night clear: its short cue, the night's music going")
	check((game.cue.stream as AudioStream).get_length() < 3.5,"…and it is brief")
	check(slams.is_empty(),"The title is still in the air")
	game.results.set_process(false)
	for i in 12: game.results.advance(1.0/60)
	check(slams == [false],"It hits the glass")
	check(ringing_screen(game).has("slam"),"…and it sounds")
	for i in 170: game.results.advance(1.0/60)
	check(ticks.size() > 5,"The numbers climb, ticking (%d)" % ticks.size())
	check(ticks.slice(0,3).all(func(p): return p < 1.0) and ringing_screen(game).has("tally_tick"),"…rising as they go")
	for i in 40: game.results.advance(1.0/60)
	check(slams == [false,true],"The grade comes down heavier")
	game.queue_free()
	await process_frame
	# Night twelve: the first stage walks in to the walk-in's music; the next keeps the song going.
	Campaign.state = Campaign.fresh()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.cinematics = true
	game.load_level(11)
	game.start_or_resume()
	check(game.entrance_music.playing and game.music_path == "","The rally opens with the walk-in's music")
	game.skip_entrance()
	check(game.music_path == game.sim.layout.music,"…then the song")
	game._next_stage()
	game.start_or_resume()
	check(game.sim.state == "entering" and not game.entrance_music.playing and game.music_path == game.sim.layout.music and game.music.playing,"The count room's walk-in keeps the song, in its own mix")
	game.queue_free()
	await process_frame
	# The death screen has them too, on top of its music: the title lands, the numbers climb.
	var ending = load("res://scripts/result_screen.gd").new()
	root.add_child(ending)
	var hits := []
	var turns := []
	ending.slammed.connect(func(heavy): hits.append(heavy))
	ending.ticked.connect(func(p): turns.append(p))
	ending.show_death({"kills":3,"total":8,"time":30.0})
	check(hits.is_empty(),"The death's title is still in the air")
	for i in 90: ending.advance(1.0/60)
	check(hits == [false],"The death's title hits the glass, and there is no grade to follow it")
	check(turns.size() > 3,"The death's numbers tick up (%d)" % turns.size())
	ending.queue_free()
	await process_frame
	print("SOUND: %d/%d checks passed" % [checks-failures,checks])
	quit(1 if failures else 0)
