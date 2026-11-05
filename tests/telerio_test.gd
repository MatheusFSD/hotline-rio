extends SceneTree
## The TeleRio (docs/fase9.md): a shot or a cut trips the breaker; in the dark people see half as
## far and react twice as slow while tenants see the same; the retry lights it again. Jairo stays
## put, the guards' bullets can kill him, and the campaign remembers it. CORTE DE SAÍDA: releasing
## the spectre with the katana in hand cuts, landing in .1 s. On screen the lamps go out.
const Sim = preload("res://scripts/simulation.gd")
const Campaign = preload("res://scripts/campaign.gd")
const TELERIO := 8
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func types(s) -> Array: return s.events.map(func(e): return e.type)
## Puts the hero `distance` m straight ahead of enemy i, on open floor in its sight.
func in_front(s,i: int,distance: float) -> Dictionary:
	var e: Dictionary = s.enemies[i]
	for a in 32:
		var heading: float = e.angle+(a-16)*.03
		var spot: Vector2 = (e.p as Vector2)+Vector2.from_angle(heading)*distance
		if not s.blocked(spot) and s.can_see(e.p,spot):
			s.player.p = spot
			e.angle = heading
			return e
	return e
func seen(dark: bool,i: int,distance: float) -> bool:
	var s = Sim.new(TELERIO)
	s.reset()
	s.god = true
	s.dark = dark
	var e := in_front(s,i,distance)
	for k in 3: s.update(1.0/60,{})
	return e.alerted
func first_shot(dark: bool) -> float:
	var s = Sim.new(TELERIO)
	s.reset()
	s.god = true
	s.dark = dark
	var e := in_front(s,0,2.5)
	e.alerted = true
	for k in 240:
		s.update(1.0/60,{})
		for event in s.events: if event.type == "shot" and event.shooter == e.id: return s.elapsed
		s.events.clear()
	return INF
func run() -> void:
	var s = Sim.new(TELERIO)
	s.reset()
	check(not s.breaker.is_empty() and s.breaker.alive and not s.dark,"The building starts lit, its breaker on the corridor wall")
	# A shot trips it; it stays off until the retry.
	s.god = true
	s.player.p = s.nearest_free(s.breaker.p+Vector2(1.6,1.2))
	s.player.angle = (s.breaker.p-s.player.p).angle()
	s.attack()
	for k in 10: s.update(1.0/60,{"aim":s.breaker.p})
	check(s.dark and not s.breaker.alive and types(s).has("blackout"),"A shot on the breaker blacks out the building")
	s.reset()
	check(not s.dark and s.breaker.alive,"The retry lights it again")
	s.melee = true
	s.reset()
	s.god = true
	s.player.p = s.nearest_free(s.breaker.p+Vector2(1.0,.4))
	s.player.angle = (s.breaker.p-s.player.p).angle()
	s.attack()
	for k in 20: s.update(1.0/60,{"aim":s.breaker.p})
	check(s.dark,"A cut on the breaker does it too")
	# In the dark people see half as far and react twice as slow; tenants see the same.
	check(seen(false,0,4.0) and seen(false,0,6.0),"Lit, a guard sees the hero at 4 and at 6 m")
	check(seen(true,0,4.0) and not seen(true,0,6.0),"In the dark, at 4 m but not at 6")
	check(seen(true,9,6.0),"An inquilino in the dark still sees at 6 m")
	var lit := first_shot(false)
	var blind := first_shot(true)
	check(lit != INF and blind != INF and absf(blind/lit-2.0) < .25,"In the dark a guard takes twice as long to fire (%.2f s, %.2f s)" % [lit,blind])
	# Jairo stays put; a guard's bullet can kill him.
	s = Sim.new(TELERIO)
	s.reset()
	s.god = true
	var jairo: Dictionary = s.civilians.filter(func(c): return c.vip == "jairo")[0]
	s.panic()
	check(jairo.state == "calm" and s.civilians.filter(func(c): return c.vip == "").all(func(c): return c.state == "flee"),"In the panic Jairo stays, the staff run")
	var guard: Dictionary = s.enemies[5]
	guard.angle = ((jairo.p as Vector2)-guard.p).angle()
	s.player.p = s.nearest_free(Vector2(-4.0,6.0))
	s.events.clear()
	s.shoot(guard,"enemy")
	var down := false
	for k in 20:
		s.update(1.0/60,{})
		if types(s).has("vip_down"): down = true
	check(not jairo.alive and down and s.state == "playing" and not s.vip_alive(),"A guard's bullet kills Jairo; the night goes on")
	var staff: Dictionary = s.civilians.filter(func(c): return c.vip == "")[0]
	check(s.vip_alive("ninguém") and staff.vip == "","Only Jairo counts as the one to keep alive")
	# Celeste writes the one that fits.
	var after := Campaign.fresh()
	after.cleared = [0,1,2,3,4,5,6,7,8]
	var alive_lines: Array = Campaign.messages(after)
	after.jairo_dead = true
	var dead_lines: Array = Campaign.messages(after)
	check(alive_lines.any(func(m): return m.begins_with("O Jairo me ligou")) and not alive_lines.any(func(m): return m.begins_with("O Jairo não saiu")),"Jairo alive: he called Celeste")
	check(dead_lines.any(func(m): return m.begins_with("O Jairo não saiu")) and not dead_lines.any(func(m): return m.begins_with("O Jairo me ligou")),"Jairo dead: his pass is yours")
	# CORTE DE SAÍDA.
	check(Campaign.mods(["corte_saida"]).exit_cut,"Corte de saída in the campaign's rules")
	for cut in [true,false]:
		s = Sim.new(TELERIO)
		s.mods = {"exit_cut":true} if cut else {}
		s.melee = true
		s.reset()
		s.god = true
		var target: Dictionary = s.enemies[1]
		s.player.p = s.nearest_free((target.p as Vector2)+Vector2(1.2,0))
		s.player.angle = ((target.p as Vector2)-s.player.p).angle()
		for k in 10: s.update(1.0/60,{"phase":true,"aim":target.p})
		check(s.player.phasing,"Staging: in the spectre")
		s.update(1.0/60,{"aim":target.p})
		var swing_after: float = s.player.swing
		for k in 6: s.update(1.0/60,{"aim":target.p})
		if cut: check(swing_after >= .09 and not target.alive,"Released with the katana in hand: the cut lands at once")
		else: check(swing_after < 0 and target.alive,"Without it, releasing does nothing")
	# On screen: the lamps go out, the retry lights them.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.load_level(TELERIO)
	game.start_or_resume()
	game.sim.state = "playing"
	game.sim.god = true
	check(game.lamp_lights.size() == 7 and game.lamp_lights.all(func(l): return l.light_energy > .5),"The studio lit by its seven lamps")
	check(game.guests.size() == 3 and game.guests.all(func(g): return g.pose == "phone"),"Jairo and the staff on the phone")
	game.sim.trip()
	game._physics_process(1.0/60)
	for k in 30: await process_frame
	check(game.lamp_lights.all(func(l): return l.light_energy < .01) and game.world_environment.ambient_light_energy < .2,"The breaker trips: the lamps go out")
	game.sim.state = "dead"
	game.start_or_resume()
	check(game.lamp_lights.all(func(l): return l.light_energy > .5) and game.world_environment.ambient_light_energy > .6,"The retry lights the studio again")
	game.queue_free()
	await process_frame
	print("TELERIO: %d/%d checks passed" % [checks-failures,checks])
	quit(1 if failures else 0)
