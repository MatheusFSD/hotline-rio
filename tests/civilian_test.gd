extends SceneTree
## The Lagoa party (docs/fase7.md): guests stay calm until a shot, then run for the nearest way out
## and leave; a death in plain sight startles only who sees it; the hero's bullets and blade kill
## them (counted, never failing), the guards' bullets pass through; a guest killed whole is a body
## a shadow-flame can wear. On screen: guests in evening wear with a flute and no gun, the
## inquilinos posing as guests holding theirs still; RECUPERAÇÃO brings the breath back sooner.
const Sim = preload("res://scripts/simulation.gd")
const Campaign = preload("res://scripts/campaign.gd")
const LAGOA := 6
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func types(s) -> Array: return s.events.map(func(e): return e.type)
func run() -> void:
	var s = Sim.new(LAGOA)
	s.reset()
	check(s.civilians.size() == 10 and s.enemies.size() == 14,"Ten guests and fourteen enemies at the auction")
	check(s.civilians.all(func(c): return c.alive and c.state == "calm" and not c.alerted),"The guests start calm, at the party")
	check(s.enemies[13].kind == "inquilino" and s.layout.enemies[13].pose == "phone" and s.layout.clues[0].from_enemy == 13,"Prates is an inquilino, on the phone, carrying the invitation")
	# Calm guests do not move; a shot anywhere sends them all running.
	var before: Vector2 = s.civilians[0].p
	for i in 30: s.update(1.0/60,{})
	check(s.civilians[0].p == before and s.civilians.all(func(c): return c.state == "calm"),"Calm guests keep their places")
	s.events.clear()
	s.shoot(s.enemies[0],"enemy")
	check(s.civilians.all(func(c): return c.state == "flee" and c.alerted) and types(s).has("panic"),"A shot anywhere: every guest runs")
	for i in 60*20: s.update(1.0/60,{})
	check(s.civilians.all(func(c): return c.state == "gone" and not c.alive),"Every guest makes it out (%s)" % [s.civilians.map(func(c): return c.state)])
	check(s.civilians_killed == 0 and s.state == "playing","Guests leaving is no harm done")
	# A death in plain sight startles only the guests who see it.
	s = Sim.new(LAGOA)
	s.reset()
	s.god = true
	var guest: Dictionary = s.civilians[6]   # by the bar
	var near: Dictionary = s.enemies[4]      # the inquilino posing by the bar door
	check((guest.p as Vector2).distance_to(near.p) < 5.0 and s.can_see(guest.p,near.p),"Staging: a guest sees the bar inquilino")
	s.kill(near,Vector2.ZERO)
	check(guest.state == "flee","A death in plain sight within 5 m startles the guest")
	check(s.civilians.filter(func(c): return c.state == "flee").size() < s.civilians.size(),"…but not the whole party")
	# The hero's bullet kills a guest; the night goes on.
	s = Sim.new(LAGOA)
	s.reset()
	s.god = true
	guest = s.civilians[4]
	s.player.p = s.nearest_free(guest.p+Vector2(0,1.4))
	s.player.angle = ((guest.p as Vector2)-s.player.p).angle()
	s.events.clear()
	s.attack()
	for i in 20: s.update(1.0/60,{})
	check(not guest.alive and guest.state == "dead" and s.civilians_killed == 1,"The hero's bullet kills a guest, counted")
	check(s.state == "playing" and s.kills == 0,"…which neither fails the night nor counts as a kill")
	# The guards' bullets pass through guests.
	s = Sim.new(LAGOA)
	s.reset()
	guest = s.civilians[4]
	var shooter: Dictionary = s.enemies[3]
	shooter.p = s.nearest_free(guest.p+Vector2(-1.2,0))
	shooter.angle = ((guest.p as Vector2)-shooter.p).angle()
	s.player.p = s.nearest_free(guest.p+Vector2(1.6,0))
	s.god = true
	s.shoot(shooter,"enemy")
	for i in 10: s.update(1.0/60,{})
	check(guest.alive and s.civilians_killed == 0,"A guard's bullet passes through a guest")
	# The katana kills them too.
	s = Sim.new(LAGOA)
	s.reset()
	s.god = true
	s.melee = true
	s.reset()
	guest = s.civilians[8]
	s.player.p = s.nearest_free(guest.p+Vector2(-1.0,0))
	s.player.angle = ((guest.p as Vector2)-s.player.p).angle()
	s.attack()
	for i in 20: s.update(1.0/60,{"aim":guest.p})
	check(not guest.alive and s.civilians_killed == 1,"The katana kills a guest")
	# A guest killed whole is a body a shadow-flame can wear.
	s = Sim.new(LAGOA)
	s.reset()
	s.god = true
	for shell in s.shells: s.tear(shell)   # no bags to go to
	guest = s.civilians[0]   # in the garden, by the pool
	s.kill_civilian(guest,Vector2.ZERO)
	check(s._whole(guest),"A guest killed with no wound is a whole body")
	var tenant: Dictionary = s.enemies[1]   # the inquilino by the garden pool
	check((tenant.p as Vector2).distance_to(guest.p) < Sim.WISP.reach,"Staging: the guest lies within a flame's reach")
	var count: int = s.enemies.size()
	s.events.clear()
	s.kill(tenant,Vector2.ZERO)
	var rose := false
	for i in 60*4:
		s.update(1.0/60,{})
		for event in s.events:
			if event.type == "rise" and event.guest == guest.id: rose = true
		s.events.clear()
	check(rose and guest.used and s.enemies.size() == count+1 and s.enemies[-1].alive and s.enemies[-1].kind == "inquilino","The flame wears the guest's body: a new enemy where it lay")
	check(not s._whole(guest),"…and that body is spent")
	# RECUPERAÇÃO: the breath comes back sooner and faster.
	var mods := Campaign.mods(["pistol","katana","recuperacao"])
	check(mods.regen_delay == .5 and mods.mana_regen == 22.0,"Recuperação: .5 s delay, 22 per second")
	s = Sim.new(LAGOA)
	s.mods = mods
	s.reset()
	s.player.mana = 50.0
	s.phase(1.0/60,true)
	s.phase(1.0/60,false)
	check(is_equal_approx(s.player.regen_delay,.5-1.0/60),"The breath starts coming back after .5 s")
	s.player.regen_delay = 0.0
	var mana: float = s.player.mana
	s.phase(1.0,false)
	check(is_equal_approx(s.player.mana-mana,22.0),"…at 22 a second")
	# On screen.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.load_level(LAGOA)
	await process_frame
	check(game.guests.size() == 10 and game.guests.all(func(g): return g.guest and g.pose == "champagne" and g.prop.name == "Prop_glass"),"The guests are on stage with champagne flutes")
	var held: Array = game.actors.slice(1).filter(func(a): return a.pose == "hold")
	check(held.size() == 5 and held.all(func(a): return a.prop.name == "Prop_glass"),"Five inquilinos pose as guests, glass in hand")
	game.start_or_resume()
	game.sim.state = "playing"
	for i in 10: game._physics_process(1.0/60)
	check(game.guests.all(func(g): return not g.gun.visible and g.prop.visible),"Guests show a flute and never a gun")
	check(held.all(func(a): return not a.gun.visible and a.animator.speed_scale == 0.0),"The posing inquilinos hold their glass still, no gun in sight")
	game.sim.civilians[2].state = "gone"
	game.sim.civilians[2].alive = false
	game._physics_process(1.0/60)
	check(not game.guests[2].visible,"A guest out of the door leaves the stage")
	game.sim.kill_civilian(game.sim.civilians[3],Vector2.RIGHT,"pistol")
	game._physics_process(1.0/60)
	check(game.guests[3].visible and game._tally().guests_killed == 1 and game._tally().guests == 10,"A guest killed stays on the floor, counted for the results")
	game.queue_free()
	await process_frame
	print("CIVILIAN: %d/%d checks passed" % [checks-failures,checks])
	quit(1 if failures else 0)
