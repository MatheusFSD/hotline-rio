extends SceneTree
## Night twelve (docs/planejado/fase10-12.md): the Síndico over three stages. The rally: his casca
## falls and his flame, which no hand can hold, runs through the walls for the elevator. The count
## room: it jumps to the nearest whole body in reach and gets up quicker each time; Souza is among
## the aides unless his file was taken; the Mão do Avesso ends it; with no body near, he flees down
## the shaft. The helipad: seen only from the spectre, walking through everything, bullets passing
## through him; his touch kills outside the spectre; the katana kills him and wins the night; the
## landing lights give breath once. Then the endings: REC on air, the ending chosen by Jairo and the
## proofs, the newscast's variants, and the last room with only the TV and the window.
const Sim = preload("res://scripts/simulation.gd")
const Campaign = preload("res://scripts/campaign.gd")
const NewsCard = preload("res://scripts/news_card.gd")
const RALLY := 11
const COUNT := 12
const HELIPAD := 13
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func types(s) -> Array: return s.events.map(func(e): return e.type)
func run_until(s,what: String,frames := 600) -> Dictionary:
	for i in frames:
		s.update(1.0/60,{})
		for event in s.events: if event.type == what: return event
		s.events.clear()
	return {}
func run() -> void:
	# 1. The rally.
	var s = Sim.new(RALLY)
	s.reset()
	s.god = true
	var sindico: Dictionary = s.enemies.filter(func(e): return e.get("sindico",false))[0]
	check(sindico.kind == "proprietario" and not sindico.ghost and s.stage() == 1,"The rally: the Síndico is a Proprietário")
	s.mods = {"hand":true}
	s.kill(sindico,Vector2.RIGHT,"katana")
	check(s.wisps.size() == 1 and s.wisps[0].sindico and not s.wisps[0].grab,"His casca falls, torn, and still his flame flies, out of any hand's reach")
	s.player.p = s.nearest_free(sindico.p)
	s.player.phasing = true
	var fled := run_until(s,"sindico_flees")
	check(not fled.is_empty() and (fled.p as Vector2).distance_to(Sim.point(s.boss().exit)) < .1 and s.wisps.is_empty(),"…through the walls to the elevator, and gone")
	# 2. The count room.
	s = Sim.new(COUNT)
	s.known_clues = []
	s.reset()
	check(s.shells.size() == 7 and s.shells.any(func(b): return b.name == "souza") and s.shells.all(func(b): return b.style == "seated"),"Seven aides at the desks, Souza among them")
	s.known_clues = ["prontuario_souza"]
	s.reset()
	check(s.shells.size() == 6 and not s.shells.any(func(b): return b.name == "souza"),"With his file taken, Souza is not there")
	s.god = true
	sindico = s.enemies.filter(func(e): return e.get("sindico",false))[0]
	var reaction: float = sindico.reaction
	s.kill(sindico,Vector2.RIGHT,"katana")
	check(s.wisps.size() == 1 and not s.wisps[0].target.is_empty() and s.wisps[0].target.has("style"),"His flame jumps to the nearest aide")
	var rose := run_until(s,"rise")
	var risen: Dictionary = s.enemies[-1]
	check(not rose.is_empty() and rose.sindico and risen.sindico and risen.kind == "proprietario" and is_equal_approx(risen.reaction,reaction-.05) and is_equal_approx(risen.rising,1.0),"…who gets up the Síndico, quicker by .05 s, in 1 s")
	# The Mão do Avesso takes his flame.
	s.mods = {"hand":true}
	for i in 90: s.update(1.0/60,{})
	s.kill(risen,Vector2.RIGHT,"katana")
	s.player.p = s.wisps[0].p
	s.player.phasing = true
	s.events.clear()
	s.update(1.0/60,{"phase":true})
	check(s.wisps.is_empty() and s.events.any(func(e): return e.type == "wisp_gone" and e.grabbed and e.sindico),"In the count room the Mão do Avesso takes his flame")
	# With no whole body in reach, down the shaft.
	s = Sim.new(COUNT)
	s.known_clues = []
	s.reset()
	s.god = true
	for shell in s.shells: s.tear(shell)
	sindico = s.enemies.filter(func(e): return e.get("sindico",false))[0]
	s.kill(sindico,Vector2.ZERO)
	fled = run_until(s,"sindico_flees")
	check(not fled.is_empty() and (fled.p as Vector2).distance_to(Sim.point(s.boss().exit)) < .1,"No whole body within 8 m: he flees down the shaft")
	# 3. The helipad.
	s = Sim.new(HELIPAD)
	s.reset()
	sindico = s.enemies[0]
	check(sindico.ghost and s.stage() == 3 and s.pads.size() == 4,"The helipad: the Síndico without a casca, four landing lights")
	var start: Vector2 = sindico.p
	for i in 60: s.update(1.0/60,{})
	check(sindico.p == start,"He waits a moment first")
	s.player.p = Vector2(0.0,3.0)
	s.player.angle = ((sindico.p as Vector2)-s.player.p).angle()
	s.god = true
	s.attack()
	for i in 60: s.update(1.0/60,{"aim":sindico.p})
	check(sindico.alive,"Bullets go through him")
	check((sindico.p as Vector2).distance_to(s.player.p) < start.distance_to(s.player.p),"He walks for the hero")
	s.god = false
	s.player.mana = 100.0
	s.player.p = s.nearest_free((sindico.p as Vector2)+Vector2(1.5,0))
	for i in 60:
		s.update(1.0/60,{"phase":true})
		if (sindico.p as Vector2).distance_to(s.player.p) < .3: break
	check(s.state == "playing" and s.player.alive,"His touch does nothing to the spectre")
	s.player.phasing = false
	s.player.locked = true
	s.update(1.0/60,{})
	check(s.state == "dead","Outside the spectre, his touch kills")
	s = Sim.new(HELIPAD)
	s.melee = true
	s.reset()
	s.god = true
	sindico = s.enemies[0]
	s.player.p = s.nearest_free((sindico.p as Vector2)+Vector2(0,1.2))
	s.player.angle = ((sindico.p as Vector2)-s.player.p).angle()
	s.attack()
	for i in 20: s.update(1.0/60,{"aim":sindico.p})
	check(not sindico.alive and s.state == "won","The katana kills him, and the night is won where it stands")
	s = Sim.new(HELIPAD)
	s.reset()
	s.player.mana = 40.0
	s.player.p = s.pads[0].p
	s.update(1.0/60,{})
	var after_one: float = s.player.mana
	s.update(1.0/60,{})
	check(after_one >= 69.0 and s.pads[0].used and s.player.mana <= after_one+1.0,"A landing light gives 30 breath, once")
	# The endings.
	var state := Campaign.fresh()
	state.clues = ["ordem_compra","catalogo_lote12","fitas_arquivo"]
	check(Campaign.ending(state) == "a","Jairo alive and three proofs: Final A")
	state.jairo_dead = true
	check(Campaign.ending(state) == "b","Jairo dead: Final B")
	state.jairo_dead = false
	state.clues = ["ordem_compra","fitas_arquivo"]
	check(Campaign.ending(state) == "b","Two proofs only: Final B")
	state.clues = ["ordem_compra","catalogo_lote12","fitas_arquivo","prontuario_souza"]
	state.civilians_killed = 4
	var bitter := NewsCard.load_news("res://assets/news/final_a.json",state)
	check(bitter.segments.size() == 4,"Final A with Souza saved and four guests dead: Souza's arrest and the bitter coda")
	state.civilians_killed = 0
	state.clues = ["ordem_compra"]
	check(NewsCard.load_news("res://assets/news/final_a.json",state).segments.size() == 2,"Final A, clean and without Souza: the two plain segments")
	# On screen: REC, the ghost seen from the spectre, the last room.
	Campaign.state = Campaign.fresh()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.load_level(HELIPAD)
	check(game.hud.rec.visible,"Jairo alive: night twelve goes out live, REC on")
	game.start_or_resume()
	game.sim.state = "playing"
	game.sim.god = true
	game._physics_process(1.0/60)
	check(not game.actors[1].visible,"On the helipad the Síndico is not there for the eye")
	game.sim.player.phasing = true
	game._show_ghost()
	check(game.actors[1].visible,"…but the spectre sees him")
	game.queue_free()
	await process_frame
	Campaign.state.jairo_dead = true
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.load_level(RALLY)
	check(not game.hud.rec.visible,"Jairo dead: no one broadcasts it")
	game.queue_free()
	await process_frame
	# The count room as it is played: he falls, an aide gets up and shoots, he falls again.
	Campaign.state = Campaign.fresh()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.load_level(COUNT)
	game.start_or_resume()
	game.sim.state = "playing"
	game.sim.god = true
	for other in game.sim.enemies: if not other.get("sindico",false): other.alive = false
	var risings := 0
	var fired := 0
	for i in 1800:
		game._physics_process(1.0/60)
		for bullet in game.sim.bullets: if bullet.team == "enemy": fired += 1
		var standing: Array = game.sim.enemies.filter(func(e): return e.alive and e.get("sindico",false) and e.get("rising",0.0) <= 0.0)
		if standing.size() == 1:
			for a in 8:
				game.sim.player.p = game.sim.nearest_free((standing[0].p as Vector2)+Vector2.from_angle(a*TAU/8)*1.6)
				if game.sim.can_see(standing[0].p,game.sim.player.p): break
			if fired > risings:
				game.sim.kill(standing[0],Vector2.RIGHT,"katana")
				risings += 1
		if game.sim.state != "playing" or risings >= 3: break
	check(risings >= 3,"The Síndico gets up in an aide's body, shoots, and falls again, three times over (%d)" % risings)
	check(game.actors.size() == game.sim.enemies.size()+1,"Every body he got up is on stage")
	game.queue_free()
	await process_frame
	Campaign.state = Campaign.fresh()
	var room = load("res://scripts/room.gd").new({"campaign":Campaign.fresh(),"finale":true})
	root.add_child(room)
	var chosen := []
	room.finale_chosen.connect(func(kind): chosen.append(kind))
	room.click("City")
	room.click("Hotspot_door")
	check(chosen == ["window"] and room.spots.size() == 2,"The last room: the window chooses, the door is not there")
	room.queue_free()
	await process_frame
	print("SINDICO: %d/%d checks passed" % [checks-failures,checks])
	quit(1 if failures else 0)
