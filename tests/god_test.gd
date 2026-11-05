extends SceneTree
## Modo deus (G): bullets still hit the hero but glance off; it survives retries and level
## changes; the rest of the game (kills, exit, win) is untouched; the HUD and a gold rim show it.
const Sim = preload("res://scripts/simulation.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")

func duel(god: bool) -> Dictionary:
	## One alerted gunman three metres away with a clear line, everyone else down; two seconds.
	var s = Sim.new()
	s.reset()
	if god: s.toggle_god()
	s.player.p = s.nearest_free(Vector2(-2.6,-1.8))
	var shooter: Dictionary = s.enemies[1]
	for e in s.enemies: if e != shooter: e.alive = false
	shooter.p = s.player.p+Vector2(3,0)
	shooter.alerted = true
	shooter.memory = 5.0
	var impacts := 0
	var seen: bool = s.can_see(shooter.p,s.player.p)
	for i in 120:
		s.update(1.0/60,{"aim":shooter.p})
		for event in s.events:
			if event.type == "impact" and (event.p as Vector2).distance_to(s.player.p) < .5: impacts += 1
		s.events.clear()
	return {"sim":s,"impacts":impacts,"seen":seen}

func run() -> void:
	var mortal := duel(false)
	check(mortal.seen and mortal.sim.state == "dead","Without it, the gunman kills the hero")
	var blessed := duel(true)
	check(blessed.sim.state == "playing" and blessed.sim.player.alive,"With it, the hero survives the same gunman")
	check(blessed.impacts >= 1,"The bullets still hit him and glance off in sparks (%d)" % blessed.impacts)
	var s = blessed.sim
	s.die(Vector2.RIGHT)
	check(s.state == "playing","Nothing else kills him either")
	s.reset()
	check(s.god and s.player.god,"A retry keeps it on")
	s.load_level(2)
	check(s.god and s.player.god,"The next night keeps it on")
	s.reset()
	for e in s.enemies: s.kill(e,Vector2.RIGHT)
	for c in s.clues: c.taken = true
	s.player.p = s.exit_rect.get_center()
	s.update(1.0/60,{})
	check(s.kills == s.enemies.size() and s.state == "won","Kills and the exit work as always")
	s.toggle_god()
	check(not s.god and not s.player.god,"G again turns it off")
	# In the game: the key, the HUD badge and the hero's gold outline.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_or_resume()
	var press := InputEventKey.new()
	press.physical_keycode = KEY_G
	press.pressed = true
	game._unhandled_input(press)
	var hero = game.actors[0]
	hero.sync(game.sim.player,1.0/60,false)
	check(game.sim.god and game.hud.god_badge.visible,"G turns it on and the HUD says MODO DEUS")
	check(hero.look.golden and hero.look.rim.get_shader_parameter("rim_color") == hero.look.GOD_RIM,"The hero is outlined in gold")
	check(not game.actors[1].look.golden,"Enemies keep their own rim")
	game._unhandled_input(press)
	hero.sync(game.sim.player,1.0/60,false)
	check(not game.sim.god and not game.hud.god_badge.visible and hero.look.rim.get_shader_parameter("rim_color") == hero.look.HERO_RIM,"G again: badge gone, cyan rim back")
	check(game.overlay.get_child(0).get_children().any(func(n): return n is Label and "G MODO DEUS" in n.text),"The briefing lists the key")
	game.queue_free()
	await process_frame
	print("GOD: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
