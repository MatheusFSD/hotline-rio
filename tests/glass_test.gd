extends SceneTree
## The Joá's glass (docs/planejado/fase10-12.md): a pane holds a body back, hero and guards alike,
## and the routes go round it; but sight goes through it, both sides' bullets go through it, and
## cameras would see through it; the spectre passes it like any wall. The night hands over the
## minigun, and Celeste writes after it.
const Sim = preload("res://scripts/simulation.gd")
const Campaign = preload("res://scripts/campaign.gd")
const JOA := 9
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s = Sim.new(JOA)
	s.reset()
	var panes: Array = s.layout.solids.filter(func(e): return e.type == "glass")
	check(panes.size() == 13 and s.opaque.size() == s.solids.size()-13,"Thirteen glass panes, kept out of the opaque solids")
	# The office's west pane, between the meeting room and the office.
	var pane := Sim.rect(panes.filter(func(e): return e.r[0] == 0.6 and e.r[1] == -7.3)[0].r)
	var west := Vector2(pane.position.x-.6,pane.get_center().y)
	var east := Vector2(pane.end.x+.6,pane.get_center().y)
	check(not s.blocked(west) and not s.blocked(east) and s.blocked(pane.get_center()),"Staging: open floor on both sides of a pane")
	check(s.can_see(west,east),"Sight goes through glass")
	check(s.wall_hit(west,east) == INF and s.wall_hit(west,east,0.0,true) != INF,"A line meets the pane only when a body travels it")
	# A body is held back.
	s.god = true
	s.player.p = west
	for i in 60: s.update(1.0/60,{"move":Vector2.RIGHT})
	check(s.player.p.x < pane.position.x,"The hero walks into the glass and stops")
	var route: PackedVector2Array = s.path(west,east)
	check(route.size() > 1 and route.size()*Sim.CELL > west.distance_to(east)+1.0,"The route goes round the pane, through a door")
	# The spectre passes it.
	s.player.p = west
	s.player.mana = 100.0
	for i in 40: s.update(1.0/60,{"move":Vector2.RIGHT,"phase":true})
	check(s.player.p.x > pane.end.x,"The spectre passes the glass")
	# The hero's bullet goes through and kills the guard behind it.
	s = Sim.new(JOA)
	s.reset()
	s.god = true
	var guard: Dictionary = s.enemies[10]   # the Proprietária in the office
	guard.kind = "human"                     # a plain target for this check
	guard.p = east
	s.player.p = west
	s.player.angle = (east-west).angle()
	s.attack()
	for i in 20: s.update(1.0/60,{"aim":east})
	check(not guard.alive,"The hero's bullet goes through glass")
	# A guard's bullet goes through too.
	s = Sim.new(JOA)
	s.reset()
	guard = s.enemies[10]
	guard.p = east
	guard.angle = (west-east).angle()
	s.player.p = west
	s.shoot(guard,"enemy")
	for i in 20: s.update(1.0/60,{})
	check(s.state == "dead","A guard's bullet goes through glass")
	# A guard behind glass sees the hero.
	s = Sim.new(JOA)
	s.reset()
	s.god = true
	guard = s.enemies[10]
	guard.p = east
	guard.angle = (west-east).angle()
	guard.alerted = false
	s.player.p = west
	for i in 3: s.update(1.0/60,{})
	check(guard.alerted,"A guard sees the hero through the glass")
	# The reward and Celeste.
	var after := Campaign.fresh()
	Campaign.state = after
	Campaign.complete(JOA,s.layout,["escritura_casca","ata_conselho"],JOA+1,"pistol")
	check("minigun" in Campaign.state.unlocks,"The night hands over the minigun")
	var ten := Campaign.fresh()
	ten.cleared = range(10)
	ten.clues = ["ata_conselho"]
	check(Campaign.messages(ten).any(func(m): return m.begins_with("Sete assinaturas")),"With the minutes, Celeste names the council")
	Campaign.state = Campaign.fresh()
	print("GLASS: %d/%d checks passed" % [checks-failures,checks])
	quit(1 if failures else 0)
