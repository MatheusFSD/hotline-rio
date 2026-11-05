extends SceneTree
## The casca rule (docs/narrativa.md, 4.3), on the bar's floor plan with a few of its men made
## inquilinos: a whole casca lets out a shadow-flame that stands up the nearest whole body; a torn
## one lets out nothing; with no body in reach the flame fades; hanging shells are spare bodies a
## shot or a cut tears; a flame goes through walls; the Mão do Avesso snuffs a flame
## from the spectre; the Olho do Avesso shows who is not human; the exit waits for every flame;
## a retry puts it all back. Then main.gd: a shell that stands up joins the cast, and leaves it
## on a retry.
const Sim = preload("res://scripts/simulation.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func steps(s,seconds: float,input := {}) -> void:
	for i in int(seconds*60): s.update(1.0/60,input)
func of_type(s,type: String) -> Array:
	return s.events.filter(func(e): return e.type == type)
## A quiet stage: everyone but the two (or three) under test already dead and torn, far away.
func stage(s,kinds: Dictionary) -> void:
	for i in kinds: s.layout.enemies[i].kind = kinds[i]
	s.reset()
	s.player.p = s.nearest_free(Vector2(10.5,6.0))
	for e in s.enemies:
		if not kinds.has(e.id):
			e.alive = false; e.gore = "half"; s.kills += 1
func run() -> void:
	# A whole casca: the flame flies to the nearest whole corpse and stands it up, occupied.
	var s = Sim.new()
	stage(s,{0:"inquilino",1:"human"})
	var host: Dictionary = s.enemies[0]
	var body: Dictionary = s.enemies[1]
	body.p = s.nearest_free(host.p+Vector2(2.5,0))
	s.kill(body,Vector2.ZERO)
	s.events.clear()
	s.kill(host,Vector2.ZERO)
	check(s.wisps.size() == 1 and of_type(s,"wisp").size() == 1 and s.wisps[0].target == body,"A whole casca lets out a shadow-flame bound for the nearest whole body")
	check(not s.cleared(),"Everyone down, but the flame keeps the exit shut")
	steps(s,.4)
	check(not body.alive and s.wisps.size() == 1,"It takes its time crossing (3 m/s)")
	steps(s,.6)
	check(body.alive and body.kind == "inquilino" and is_equal_approx(body.reaction,.6) and body.alerted and s.wisps.is_empty() and s.kills == s.enemies.size()-1,"The corpse stands up occupied: an inquilino, quick to shoot, already hunting")
	check(body.rising > 0 and of_type(s,"rise").size() == 1,"It is still getting up")
	var start: Vector2 = body.p
	steps(s,.5)
	check(body.p == start and body.cooldown > 0,"Getting up, it neither walks nor shoots")
	# A torn casca: nothing comes out to look for a body.
	s = Sim.new()
	stage(s,{0:"inquilino",1:"human"})
	s.kill(s.enemies[1],Vector2.ZERO)
	s.events.clear()
	s.kill(s.enemies[0],Vector2.RIGHT,"katana")
	check(s.enemies[0].gore != "" and s.wisps.is_empty() and of_type(s,"unravel").size() == 1,"The katana always tears the casca: it comes apart on the spot")
	check(s.cleared() or not s.clues_done(),"No flame, nothing holds the exit but the clues")
	# Walls are nothing to a flame: a bag behind one is as good as one in sight.
	s = Sim.new(4)
	s.reset()
	s.player.p = s.nearest_free(Vector2(-2.6,8.875))
	var guard: Dictionary = s.enemies[11]   # the compressor room, a bag of chamber 3 just past the wall
	check(guard.p.distance_to(s.shells[10].p) < 6.0 and s.wall_hit(guard.p,s.shells[10].p) != INF,"Caju: the pier guard has a bag within 6 m, behind the chamber wall")
	s.kill(guard,Vector2.ZERO)
	check(s.wisps.size() == 1 and s.wisps[0].target == s.shells[10],"His flame goes through the wall for it")
	s = Sim.new(4)
	s.reset()
	s.kill(s.enemies[2],Vector2.ZERO)
	check(s.wisps[0].target == s.shells[1],"On the dock, the bags in plain sight are taken")
	# Humans never let anything out.
	s = Sim.new()
	stage(s,{0:"human",1:"human"})
	s.kill(s.enemies[1],Vector2.ZERO)
	s.kill(s.enemies[0],Vector2.ZERO)
	check(s.wisps.is_empty(),"A human dies and stays dead")
	# No body in reach: the flame goes back to the Avesso.
	s = Sim.new()
	stage(s,{0:"inquilino"})
	s.kill(s.enemies[0],Vector2.ZERO)
	check(s.wisps.size() == 1 and s.wisps[0].target.is_empty(),"With no whole body within 6 m the flame has nowhere to go")
	steps(s,.7)
	check(s.wisps.is_empty() and of_type(s,"wisp_gone").size() >= 1 and not s.enemies[0].alive,"It fades back to the Avesso; the casca stays down")
	# Shells: a whole body in a bag is a spare casca; the flame stands it up as a new enemy.
	s = Sim.new()
	s.layout.shells = [{"p":[0,0],"angle":0}]
	stage(s,{0:"inquilino"})
	s.shells[0].p = s.nearest_free(s.enemies[0].p+Vector2(0,2.0))
	var count: int = s.enemies.size()
	s.kill(s.enemies[0],Vector2.ZERO)
	check(s.wisps[0].target == s.shells[0],"A shell in its bag is a body the flame can wear")
	steps(s,1.0)
	check(s.enemies.size() == count+1 and s.enemies[-1].alive and s.enemies[-1].kind == "inquilino" and s.shells[0].used and not s.cleared(),"The bag splits and a new enemy stands up: one more to kill")
	check(s.kills == count and s.enemies[-1].id == count,"It joins the count at the end")
	s.kill(s.enemies[-1],Vector2.ZERO)
	check(s.wisps.size() == 1 and s.wisps[0].target == s.enemies[0],"Killed whole, its flame takes the first casca, left whole on the floor")
	# A shot tears a bag before anything can use it; so does the katana.
	s = Sim.new()
	s.layout.shells = [{"p":[0,0],"angle":0},{"p":[0,0],"angle":0}]
	stage(s,{0:"inquilino"})
	s.shells[0].p = s.nearest_free(s.player.p+Vector2(-3.0,0))
	s.shells[1].p = s.nearest_free(s.player.p+Vector2(0,1.2))
	s.player.angle = PI
	s.attack()
	steps(s,.3)
	check(s.shells[0].torn and of_type(s,"tear").size() >= 1,"A shot tears the bag it hits")
	if s.melee == false: s.switch_weapon()
	steps(s,.4)
	s.player.angle = PI/2
	s.attack()
	steps(s,.3)
	check(s.shells[1].torn,"A cut tears it too")
	s.enemies[0].p = s.nearest_free(s.shells[1].p+Vector2(1.0,0))
	s.kill(s.enemies[0],Vector2.ZERO)
	check(s.wisps[0].target.is_empty(),"Torn bags are no use to the flame")
	# A body torn while the flame is on its way: it looks again, and finds nothing.
	s = Sim.new()
	s.layout.shells = [{"p":[0,0],"angle":0}]
	stage(s,{0:"inquilino"})
	s.shells[0].p = s.nearest_free(s.enemies[0].p+Vector2(0,3.0))
	s.kill(s.enemies[0],Vector2.ZERO)
	steps(s,.3)
	s.tear(s.shells[0])
	steps(s,.1)
	check(s.wisps.is_empty() or s.wisps[0].target.is_empty(),"Torn on the way: the flame loses its body")
	# Mão do Avesso: only with the upgrade, only as a spectre.
	for hand in [false,true]:
		s = Sim.new()
		s.mods = {"hand":true} if hand else {}
		stage(s,{0:"inquilino",1:"human"})
		s.kill(s.enemies[1],Vector2.ZERO)
		s.kill(s.enemies[0],Vector2.ZERO)
		s.player.p = s.wisps[0].p
		s.player.mana = 100.0
		s.events.clear()
		s.update(1.0/60,{"phase":true})
		s.update(1.0/60,{"phase":true})
		var grabbed: Array = of_type(s,"wisp_gone").filter(func(e): return e.grabbed)
		if hand: check(s.wisps.is_empty() and grabbed.size() == 1 and not s.enemies[1].alive,"Mão do Avesso: the spectre takes hold of the flame and the corpse stays down")
		else: check(s.wisps.size() == 1 and grabbed.is_empty(),"Without it the spectre passes right through the flame")
	# Olho do Avesso: as a spectre, who is not human shows.
	s = Sim.new()
	s.mods = {"eye":true}
	stage(s,{0:"inquilino",1:"human"})
	s.player.mana = 100.0
	s.update(1.0/60,{})
	check(not s.enemies[0].revealed,"Out of the spectre nothing shows")
	s.update(1.0/60,{"phase":true})
	s.update(1.0/60,{"phase":true})
	check(s.enemies[0].revealed and not s.enemies[1].revealed,"In the spectre the inquilino shows, the man does not")
	s.mods = {}
	s.update(1.0/60,{"phase":true})
	check(not s.enemies[0].revealed,"Without the eye, nobody shows")
	# A retry puts every bag back and every man in his place.
	s = Sim.new()
	s.layout.shells = [{"p":[0,0],"angle":0}]
	stage(s,{0:"inquilino"})
	var plan: int = s.layout.enemies.size()
	s.shells[0].p = s.nearest_free(s.enemies[0].p+Vector2(0,2.0))
	s.kill(s.enemies[0],Vector2.ZERO)
	steps(s,1.0)
	s.reset()
	check(s.enemies.size() == plan and s.wisps.is_empty() and not s.shells[0].torn and not s.shells[0].used and s.enemies.all(func(e): return not e.has("rising") or e.rising == 0),"A retry: the bags whole, no flames, the cast as written")
	# Whatever body it was (a bag's, a guest's, a patient's), once on its feet it shoots like anyone.
	for level in {4:"shells",6:"civilians",10:"patients"}:
		var kind: String = {4:"shells",6:"civilians",10:"patients"}[level]
		s = Sim.new(level)
		s.reset()
		s.god = true
		for e in s.enemies: e.alive = false
		var lying: Dictionary = s.get(kind)[0]
		s._rise({"target":lying,"kind":"inquilino"})
		var risen: Dictionary = s.enemies[-1]
		for a in 8:
			s.player.p = s.nearest_free((risen.p as Vector2)+Vector2.from_angle(a*TAU/8)*2.0)
			if s.can_see(risen.p,s.player.p): break
		var shot := false
		for i in 300:
			s.update(1.0/60,{})
			if s.bullets.any(func(b): return b.team == "enemy"): shot = true
		check(shot,"A body out of the %s, on its feet, shoots" % kind)
	# In the game: the shell joins the cast as a new actor getting up, and a retry takes it away.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.sim.layout.enemies[0].kind = "inquilino"
	game.sim.layout.shells = [{"p":[0,0],"angle":0}]
	game.start_or_resume()
	game.sim.state = "playing"
	game.avesso.rebuild()
	check(game.avesso.bags.size() == 1,"The bag hangs on stage")
	var actors: int = game.actors.size()
	game.sim.shells[0].p = game.sim.nearest_free(game.sim.enemies[0].p+Vector2(0,2.0))
	game.sim.player.p = game.sim.nearest_free(game.sim.enemies[0].p+Vector2(0,-6.0))
	game.sim.kill(game.sim.enemies[0],Vector2.ZERO)
	for i in 30: game._physics_process(1.0/60)
	check(game.avesso.flames[0].visible,"The flame is on stage while it flies")
	# Out of the bag: he drops from it, upright and in the air, crumples, then gets up; armed last.
	var seen := []
	var airborne := false
	var armed_early := false
	for i in 140:
		game._physics_process(1.0/60)
		if game.actors.size() != actors+1: continue
		var spare: Node3D = game.actors[-1]
		if spare.current != "" and (seen.is_empty() or seen[-1] != spare.current): seen.append(spare.current)
		if spare.current == "drop" and spare.position.y > .2: airborne = true
		if spare.current in ["drop","rise"] and spare.gun.visible: armed_early = true
	check(seen.slice(0,2) == ["drop","rise"] and airborne,"The bag splits: he drops out of it, crumples, then gets up (%s)" % [seen])
	check(not armed_early and game.actors[-1].gun.visible,"No gun in hand until he is on his feet")
	check(game.avesso.bags[0].get_node("open").visible,"The bag hangs torn open")
	var skins: Array = []
	for mesh in game.actors[-1].model.find_children("*","MeshInstance3D",true,false):
		for k in mesh.get_surface_override_material_count():
			if mesh.get_surface_override_material(k): skins.append(mesh.get_surface_override_material(k))
	check(skins.size() > 0 and skins.all(func(m): return m.albedo_texture == null and m.albedo_color == game.actors[-1].BARE_SKIN),"Out of the bag he wears nothing: one pale skin, no clothes, no detail")
	game.sim.die()
	game.start_or_resume()
	game._physics_process(1.0/60)
	await process_frame
	check(game.actors.size() == actors and not game.avesso.bags[0].get_node("open").visible,"A retry: the bag whole again, the extra man gone")
	game.queue_free()
	await process_frame
	print("WISP: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
