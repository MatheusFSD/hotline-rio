extends SceneTree
const Sim = preload("res://scripts/simulation.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func steps(sim,seconds: float,input: Dictionary = {}) -> void:
	for i in ceili(seconds*60): sim.update(1.0/60,input)
func empty_arena():
	var sim = Sim.new()
	sim.reset()
	sim.solids.clear()
	sim.opaque.clear()   # what sight and bullets meet (all but glass)
	sim.enemies.clear()
	sim.player.p = Vector2.ZERO
	return sim
func enemy(sim,p: Vector2):
	var e: Dictionary = Sim.actor(p,PI)
	e.merge({"id":0,"patrol":[[p.x,p.y]],"patrol_index":0,"reaction":1.0,"alerted":false,"memory":0.0,"last_seen":p,"windup":0.0,"route":PackedVector2Array(),"repath":0.0})
	sim.enemies.append(e)
	return e
func _initialize() -> void:
	var s = Sim.new()
	check(s.state == "ready" and s.enemies.size() == 8,"Initial state / 8 enemies")
	s.reset()
	check(s.player.ammo == 12 and s.player.mana == 100 and s.attempt == 1,"Reset resources")
	for e in s.enemies:
		check(not s.blocked(e.p),"Enemy spawns clear of solids")
		check(not s.path(s.player.p,e.p).is_empty(),"Enemy reachable from entrance")
	var start: Vector2 = s.player.p
	s.move(s.player,Vector2(-20,0))
	check(not s.blocked(s.player.p) and s.player.p.x > s.bounds.position.x,"World boundary / long movement")
	s.player.p = Vector2(-6.8,5)
	s.move(s.player,Vector2(4,0))
	check(s.player.p.x < -6.4 and not s.blocked(s.player.p),"Wall blocks movement without tunneling")
	var old: Vector2 = s.player.p
	s.state = "paused"
	steps(s,1,{"move":Vector2.ONE,"attack":true,"phase":true})
	check(s.player.p == old and s.elapsed == 0 and s.player.ammo == 12,"Pause freezes all gameplay")
	s.reset()
	s.player.p = Vector2(-6.8,5)
	steps(s,.3,{"phase":true,"move":Vector2.RIGHT})
	check(s.player.phasing and s.player.p.x > -5.75,"Phase passes through wall")
	s.player.p = Vector2(-5.95,5)
	steps(s,.02,{})
	check(not s.player.phasing and not s.blocked(s.player.p),"Solidify inside obstacle finds safe space")
	s = empty_arena()
	steps(s,2.8,{"phase":true,"attack":true})
	check(s.player.phasing and s.player.ammo == 12,"Phase blocks fire")
	steps(s,.5,{"phase":true})
	check(not s.player.phasing and s.player.locked,"Energy exhausts and locks")
	steps(s,1,{"phase":true})
	check(not s.player.phasing,"Holding depleted phase cannot reactivate")
	steps(s,2,{})
	steps(s,.02,{"phase":true})
	check(s.player.phasing,"Release and recharge enables phase again")
	s = empty_arena()
	var e = enemy(s,Vector2(4,0))
	s.player.angle = 0
	s.attack()
	steps(s,.3)
	check(not e.alive and s.kills == 1 and s.player.ammo == 11,"One pistol hit kills enemy")
	s = empty_arena()
	e = enemy(s,Vector2(4,0))
	s.solids.append(Rect2(2,-2,.2,4))
	s.opaque.append(Rect2(2,-2,.2,4))
	s.player.angle = 0
	s.attack()
	steps(s,.3)
	check(e.alive,"Wall blocks projectile before target")
	s = empty_arena()
	e = enemy(s,Vector2(4,0))
	s.shoot(e,"enemy")
	steps(s,.3)
	check(s.state == "dead" and not s.player.alive,"One enemy hit kills player")
	s = empty_arena()
	e = enemy(s,Vector2(4,0))
	s.phase(.016,true)
	s.shoot(e,"enemy")
	steps(s,.3,{"phase":true})
	check(s.state == "playing" and s.player.alive,"Phase ignores enemy bullets")
	s = empty_arena()
	s.player.ammo = 0
	s.attack()
	check(s.player.reload > 0,"Empty pistol automatically starts reload")
	steps(s,.8)
	check(s.player.ammo == 12 and s.player.reload == 0,"Reload completes in 0.75 seconds")
	s = Sim.new()
	s.reset()
	s.player.p = s.exit_rect.get_center()
	steps(s,.02)
	check(s.state == "playing","Exit stays locked while enemies live")
	for target in s.enemies: s.kill(target)
	steps(s,.02)
	check(s.state == "playing","All 8 down, the exit still waits for the clue")
	var clue: Dictionary = s.clues.filter(func(c): return c.required)[0]
	s.player.p = s.nearest_free(s.clue_spot(clue))
	steps(s,.02)
	check(clue.taken and s.events.any(func(e): return e.type == "clue" and e.id == clue.id),"Walking over the clue takes it")
	s.player.p = s.exit_rect.get_center()
	steps(s,.02)
	check(s.state == "won","All 8 kills, the clue and the exit win")
	s.reset()
	check(s.state == "playing" and s.kills == 0 and s.bullets.is_empty() and s.player.alive and s.player.p == start,"Restart fully restores level")
	# Each weapon has its own magazine, cadence, pellets and spread.
	var shots := {}
	for weapon in Sim.WEAPONS:
		s = empty_arena()
		s.weapon = weapon
		s.reset()
		s.solids.clear(); s.enemies.clear(); s.player.p = Vector2.ZERO
		var gun: Dictionary = Sim.WEAPONS[weapon]
		check(s.player.ammo == gun.magazine,"%s starts with a full %d-round magazine" % [weapon,gun.magazine])
		var fired := 0
		var bullets := 0
		for i in 60:
			s.update(1.0/60,{"attack":true,"aim":Vector2(10,0)})
			for event in s.events:
				if event.type == "shot": fired += 1; bullets += event.pellets
			s.events.clear()
		shots[weapon] = fired
		check(bullets == fired*gun.pellets,"%s fires %d pellet(s) per shot" % [weapon,gun.pellets])
	check(shots.smg > shots.rifle and shots.rifle > shots.pistol and shots.pistol > shots.shotgun,"Cadence differs per weapon: %s" % [shots])
	check(shots.minigun < 60/0.045 and shots.minigun > shots.smg-14,"Minigun spins up before firing: %d shots" % shots.minigun)
	s = empty_arena()
	s.weapon = "shotgun"
	s.reset(); s.solids.clear(); s.enemies.clear(); s.player.p = Vector2.ZERO
	s.update(1.0/60,{"attack":true,"aim":Vector2(10,0)})
	var spread := 0.0
	for bullet in s.bullets: spread = maxf(spread,absf((bullet.v as Vector2).angle()))
	check(s.bullets.size() == 7 and spread > .12,"Shotgun fans seven pellets")
	s = empty_arena()
	s.weapon = "minigun"
	s.reset(); s.solids.clear(); s.enemies.clear(); s.player.p = Vector2.ZERO
	steps(s,.3,{"attack":true,"move":Vector2.RIGHT,"aim":Vector2(10,0)})
	check(s.events.filter(func(e): return e.type == "shot").is_empty() and s.player.velocity.x < Sim.SPEED*.8,"Spinning minigun holds fire and slows its carrier")
	print("SIMULATION: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
