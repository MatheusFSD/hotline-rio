extends SceneTree
## The campaign and the rules it changes: clues (taken by walking over them, never as a spectre;
## carried ones show up on the body; the required one holds the exit), the night's report
## (clues, favours, story unlock), Celeste's orders paid in favours, every upgrade felt by the
## simulation, the save round trip, and enemy kinds reaching the blood.
const Sim = preload("res://scripts/simulation.gd")
const Campaign = preload("res://scripts/campaign.gd")
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
func layout(index: int) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(Sim.LEVELS[index]))
func run() -> void:
	Campaign.state = Campaign.fresh()
	# Clues on the floor.
	var s = Sim.new()
	s.reset()
	var ledger: Dictionary = s.clues.filter(func(c): return c.id == "caderno_taxa")[0]
	var phone: Dictionary = s.clues.filter(func(c): return c.id == "celular_russo")[0]
	check(ledger.required and not phone.required,"The bar has a required clue and an optional one")
	s.player.p = s.nearest_free(s.clue_spot(ledger))
	s.player.phasing = true
	s._pick_clues()
	check(not ledger.taken,"A spectre touches nothing: no clue")
	s.player.phasing = false
	s._pick_clues()
	check(ledger.taken and s.events[-1].type == "clue" and s.events[-1].title == "CADERNO DA TAXA","Walking over it takes it and says so")
	check(s.clue_spot(phone) == Vector2.INF,"Russo's phone is in his pocket while he lives")
	var russo: Dictionary = s.enemies[phone.from_enemy]
	s.kill(russo,Vector2.UP)
	check(s.clue_spot(phone) == russo.p,"Once he is down it lies on his body")
	s.player.p = s.nearest_free(russo.p+Vector2(.5,0))
	s._pick_clues()
	check(phone.taken and s.taken_clues() == ["caderno_taxa","celular_russo"],"And can be taken there")
	s.reset()
	check(s.clues.all(func(c): return not c.taken),"A retry puts every clue back")
	for e in s.enemies: s.kill(e,Vector2.UP)
	check(not s.cleared(),"Everyone down is not enough while the required clue is out")
	for c in s.clues: if c.required: c.taken = true
	check(s.cleared(),"The required clue opens the exit; optional ones never hold it")
	# The night's report.
	var report := Campaign.complete(0,layout(0),["caderno_taxa","celular_russo"],1,"pistol")
	check(report.clues.size() == 2 and report.favors == 1 and report.reward.id == "shotgun","The bar: two clues, one favour (the optional one), the shotgun")
	check(Campaign.state.level == 1 and Campaign.has("shotgun") and Campaign.state.cleared == [0],"The campaign moves on to the gafieira")
	report = Campaign.complete(0,layout(0),["caderno_taxa","celular_russo"],1,"pistol")
	check(report.favors == 0 and report.reward.is_empty() and report.clues.all(func(c): return not c.new),"Replaying a night farms nothing")
	# Celeste's orders.
	check(not Campaign.available("extended_mag") and not Campaign.order("extended_mag"),"Orders open after the second night")
	Campaign.complete(1,layout(1),["recibos_casarao","espelho_banheiro"],2,"pistol")
	check(Campaign.state.favors == 2 and Campaign.has("smg"),"The gafieira: another favour and the SMG")
	check(Campaign.order("extended_mag") and Campaign.state.favors == 1 and not Campaign.order("extended_mag"),"An order costs its favours, once")
	check(not Campaign.available("suppressor"),"Act 2 orders wait for the end of act 1")
	Campaign.state.favors = 5
	Campaign.state.cleared = [0,1,2,3]
	for id in ["rubber_soles","back_sheath","suppressor","mag_pouch"]: check(Campaign.order(id),"Ordered "+id)
	Campaign.complete(2,layout(2),["livro_vendas"],3,"pistol")
	# Every upgrade felt by the rules.
	var base = Sim.new()
	var up = Sim.new()
	up.mods = Campaign.mods()
	up.reset()
	base.reset()
	check(up.stats().magazine == 18 and up.player.ammo == 18 and is_equal_approx(up.stats().reload,.6),"Extended magazine and pouch: 18 rounds, 0.6 s reload")
	up.weapon = "smg"
	check(up.stats().magazine == 45,"Extended magazine: SMG 45")
	up.weapon = "pistol"
	up.reset()
	for sim in [base,up]:
		sim.player.mana = 100.0
		steps(sim,1.0,{"phase":true})
	check(is_equal_approx(base.player.mana,100-34.0) and absf(up.player.mana-(100-29.0)) < .01,"Fôlego I: 29 mana a second instead of 34")
	for sim in [base,up]:
		sim.reset()
		sim.switch_weapon()
	check(is_equal_approx(base.player.cooldown,.22) and is_equal_approx(up.player.cooldown,.12),"Back scabbard: 0.12 s swap")
	# Rubber soles: behind an unaware man at 1.8 m he only feels the hero without them.
	for sim in [base,up]:
		sim.reset()
		if sim.melee: sim.switch_weapon()
		var e: Dictionary = sim.enemies[0]
		sim.player.p = e.p-Vector2.from_angle(e.angle)*1.8
		sim.update(1.0/60,{})
	check(base.enemies[0].alerted and not up.enemies[0].alerted,"Rubber soles: noticed at 1.4 m, not 2.1 m")
	# Suppressor: a pistol shot only reaches 4 m.
	for sim in [base,up]:
		sim.reset()
		sim.player.p = sim.nearest_free(sim.enemies[5].p+Vector2(0,6.0))
		sim.shoot(sim.player,"player",sim.stats())
	check(base.enemies[5].alerted and not up.enemies[5].alerted,"Suppressor: the shot is not heard at 6 m")
	# Story unlocks and the save.
	check(Campaign.has("folego_1") and Campaign.state.clues.has("livro_vendas"),"The mansion gives Fôlego I")
	var kept := FileAccess.get_file_as_bytes(Campaign.PATH) if Campaign.exists() else PackedByteArray()
	var snapshot: Dictionary = Campaign.state.duplicate(true)
	Campaign.save()
	Campaign.state = Campaign.fresh()
	check(Campaign.load_saved() and Campaign.state.level == 3 and Campaign.state.favors == snapshot.favors and Campaign.state.unlocks == snapshot.unlocks and Campaign.state.cleared == [0,1,2,3],"The save brings the whole campaign back")
	if kept.is_empty(): DirAccess.remove_absolute(ProjectSettings.globalize_path(Campaign.PATH))
	else: FileAccess.open(Campaign.PATH,FileAccess.WRITE).store_buffer(kept)
	# Kinds: humans by default; what lives in a casca bleeds its own colour.
	var k = Sim.new()
	check(k.enemies.all(func(e): return e.kind == "human"),"Enemies are human unless the level says otherwise")
	k.layout.enemies[0].kind = "inquilino"
	k.reset()
	k.kill(k.enemies[0],Vector2.UP)
	check(k.enemies[0].kind == "inquilino" and k.events[-1].kind == "inquilino","The kind reaches the blood event")
	# In the game: clues on stage, the photo flash and the objective.
	Campaign.state = Campaign.fresh()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_or_resume()
	check(game.clue_markers.size() == 2,"A marker for each clue of the night")
	game.sim.player.p = game.sim.nearest_free(game.sim.clue_spot(game.sim.clues[0]))
	game._physics_process(1.0/60)
	check(game.sim.clues[0].taken and game.hud.clue_box.visible and game.hud.clue_title.text == "CADERNO DA TAXA" and game.hud.flash.color.a > .3,"Taking it flashes the photo and names it")
	check(not game.clue_markers[0].visible and game.clue_markers[1].visible == false,"Its marker goes out; the phone waits in Russo's pocket")
	game.queue_free()
	# The room's board pins only what was found; MARÉ writes from the second night on.
	var after_two := Campaign.fresh()
	after_two.cleared = [0,1]
	after_two.clues = ["caderno_taxa","celular_russo","recibos_casarao"]
	var room = load("res://scripts/room.gd").new({"campaign":after_two})
	root.add_child(room)
	var cards: Array = room.viewport.find_children("Clue_*","Node3D",true,false)
	var shown: Array = cards.filter(func(n): return n.visible).map(func(n): return String(n.name).trim_prefix("Clue_"))
	shown.sort()
	check(cards.size() == 24 and shown == ["caderno_taxa","celular_russo","recibos_casarao"],"The board pins the three clues found, of twenty-four (%s)" % [shown])
	check(Campaign.messages(Campaign.fresh()).is_empty() and Campaign.messages(after_two).size() == 1,"Celeste is silent before the gafieira, then writes")
	after_two.clues.append("espelho_banheiro")
	check(Campaign.messages(after_two).size() == 2,"The mirror gets its own message")
	room.queue_free()
	Campaign.state = Campaign.fresh()
	await process_frame
	print("CAMPAIGN: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
