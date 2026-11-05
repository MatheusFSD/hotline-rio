extends SceneTree
## The Ilha Fiscal's Proprietários (docs/fase8.md): shot at, or right after firing, one blinks
## (still, killable), then goes through to the Avesso beside the hero, away from his aim, through
## walls and bullets and without shooting, and comes out on a cooldown; its flame is fast and the
## body it raises is a Proprietário too. VÉU hides the spectre from people only. The act 2 newscast
## picks its middle segment by the guests killed so far.
const Sim = preload("res://scripts/simulation.gd")
const Campaign = preload("res://scripts/campaign.gd")
const NewsCard = preload("res://scripts/news_card.gd")
const ILHA := 7
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func types(s) -> Array: return s.events.map(func(e): return e.type)
## Hero `distance` m in front of enemy i, both on open floor, facing each other.
func face_off(s,i: int,distance: float) -> Dictionary:
	var e: Dictionary = s.enemies[i]
	for a in 16:
		var spot: Vector2 = (e.p as Vector2)+Vector2.from_angle(a*TAU/16)*distance
		if not s.blocked(spot) and s.can_see(spot,e.p):
			s.player.p = spot
			break
	s.player.angle = ((e.p as Vector2)-s.player.p).angle()
	e.angle = (s.player.p-(e.p as Vector2)).angle()
	e.alerted = true
	e.memory = 3.5
	e.last_seen = s.player.p
	e.phase_cd = 0.0
	return e
func run() -> void:
	var s = Sim.new(ILHA)
	s.reset()
	var owners: Array = s.enemies.filter(func(e): return e.kind == "proprietario").map(func(e): return e.id)
	check(owners == [6,8,10] and s.enemies.all(func(e): return e.kind != "human"),"Three Proprietários among tenants only")
	check(s.enemies.all(func(e): return e.phase_state == "" and not e.phasing and e.phase_cd == Sim.PROPRIETOR.first),"They start out of the Avesso, a second before they can go")
	# Shot at: it blinks, still and killable; a bullet that lands in the blink kills it.
	s.god = true
	var p: Dictionary = face_off(s,6,2.5)
	s.events.clear()
	s.attack()
	check(p.phase_state == "blink" and types(s).has("blink"),"Shot at, the Proprietário blinks")
	for i in 12: s.update(1.0/60,{"aim":p.p})
	check(not p.alive,"A bullet landing in the blink kills it")
	# Through the Avesso: bullets pass, it holds fire, goes beside the hero away from his aim.
	s = Sim.new(ILHA)
	s.reset()
	s.god = true
	p = face_off(s,6,6.0)
	s.blink(p)
	for i in 20: s.update(1.0/60,{})
	check(p.phasing and p.phase_state == "phasing","After .3 s it is in the Avesso")
	var goal: Vector2 = p.phase_goal
	check(absf(goal.distance_to(s.player.p)-Sim.PROPRIETOR.flank) < .01 or s.blocked(s.player.p+(goal-s.player.p)),"It heads 3.5 m beside the hero")
	check((goal-s.player.p).dot(Vector2.from_angle(s.player.angle)) <= .01,"…on the side away from his aim")
	s.events.clear()
	s.player.angle = ((p.p as Vector2)-s.player.p).angle()
	s.player.cooldown = 0.0
	s.attack()
	var fired := false
	for i in 30:
		s.update(1.0/60,{"aim":p.p})
		for event in s.events: if event.type == "shot" and event.team == "enemy" and event.shooter == p.id: fired = true
		s.events.clear()
	check(p.alive and not fired,"In the Avesso bullets pass through it and it holds fire")
	for i in 60: s.update(1.0/60,{})
	check(not p.phasing and p.phase_state == "" and p.phase_cd > 3.0 and not s.blocked(p.p),"Out again on open floor, with a 4 s cooldown")
	# Walls are nothing to it: the goal can lie behind one.
	s = Sim.new(ILHA)
	s.reset()
	p = s.enemies[8]   # the ceremonial room, walled from the ballroom
	p.phase_goal = Vector2(-6.0,-1.5)
	p.phase_state = "phasing"; p.phasing = true; p.phase_t = 2.0
	check(s.wall_hit(p.p,p.phase_goal) != INF,"Staging: a wall between it and its goal")
	for i in 125: s.update(1.0/60,{})
	check((p.p as Vector2).distance_to(Vector2(-6.0,-1.5)) < .5,"It goes straight through the wall")
	# Right after firing, it blinks.
	s = Sim.new(ILHA)
	s.reset()
	s.god = true
	p = face_off(s,10,4.0)
	p.cooldown = 0.0
	var blinked := false
	for i in 90:
		s.update(1.0/60,{})
		if p.phase_state != "": blinked = true
	check(blinked,"Having fired, it goes through")
	# Its flame is fast; the body it raises is a Proprietário.
	s = Sim.new(ILHA)
	s.reset()
	s.kill(s.enemies[3],Vector2.ZERO)   # a whole corpse by the ballroom host
	for i in 60: s.update(1.0/60,{})
	s.events.clear()
	s.kill(s.enemies[6],Vector2.ZERO)
	check(s.wisps.size() == 1 and s.wisps[0].speed == 4.0 and s.wisps[0].kind == "proprietario","A Proprietário's flame flies at 4 m/s")
	var raised := false
	for i in 60*3:
		s.update(1.0/60,{})
		for event in s.events: if event.type == "rise" and event.kind == "proprietario": raised = true
		s.events.clear()
	var risen: Array = s.enemies.filter(func(e): return e.alive and e.kind == "proprietario" and e.has("phase_state") and e.id != 8 and e.id != 10)
	check(raised and risen.size() == 1,"The body it wears gets up a Proprietário")
	# VÉU: people lose sight of the spectre; what lives in a casca does not.
	check(Campaign.mods(["veu"]).veil,"Véu in the campaign's rules")
	for veil in [false,true]:
		var lapa = Sim.new(0)
		lapa.mods = {"veil":true} if veil else {}
		lapa.reset()
		lapa.god = true
		var guard: Dictionary = lapa.enemies[0]
		guard.alerted = false
		lapa.player.p = lapa.nearest_free((guard.p as Vector2)+Vector2.from_angle(guard.angle)*1.6)
		lapa.player.mana = 100.0
		for i in 6: lapa.update(1.0/60,{"phase":true})
		check(guard.alerted != veil,"A spectre in front of a man %s" % ("goes unseen with Véu" if veil else "is seen without it"))
	s = Sim.new(ILHA)
	s.mods = {"veil":true}
	s.reset()
	s.god = true
	var tenant: Dictionary = s.enemies[12]
	tenant.alerted = false
	s.player.p = s.nearest_free((tenant.p as Vector2)+Vector2.from_angle(tenant.angle)*1.6)
	s.player.mana = 100.0
	for i in 6: s.update(1.0/60,{"phase":true})
	check(tenant.alerted,"An inquilino still sees the spectre through the Véu")
	# The newscast's middle segment.
	var clean := NewsCard.load_news("res://assets/news/virada_2.json",0)
	var bloody := NewsCard.load_news("res://assets/news/virada_2.json",3)
	check(clean.segments.size() == 3 and clean.segments[1].headline.begins_with("GARÇONS"),"No guest killed: the waiters escaped")
	check(bloody.segments.size() == 3 and bloody.segments[1].headline.begins_with("FANTASMA MATA"),"Guests killed: the ghost kills guests")
	check(NewsCard.load_news("res://assets/news/virada_1.json",3).segments.size() == 2,"Act 1's newscast has no conditions")
	# On screen: violet in the Avesso.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.load_level(ILHA)
	await process_frame
	var visual = game.actors[7]
	check(visual.ghost_material.emission == Color("7a3cff") and game.actors[1].ghost_material.emission != Color("7a3cff"),"Proprietários go through in violet")
	game.queue_free()
	await process_frame
	print("PROPRIETOR: %d/%d checks passed" % [checks-failures,checks])
	quit(1 if failures else 0)
