extends SceneTree
## The Santa Aurora's sedated patients (docs/planejado/fase10-12.md): eight live, whole bodies in
## their beds, out of the blade's reach; an inquilino dying whole by the ward sends its flame into
## one, who gets out of bed occupied; killing that one counts as killing a person; a retry puts
## everyone back to bed. FÔLEGO II, Souza's file and Celeste. On screen: sheets, and an empty bed.
const Sim = preload("res://scripts/simulation.gd")
const Campaign = preload("res://scripts/campaign.gd")
const CLINICA := 10
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s = Sim.new(CLINICA)
	s.reset()
	check(s.patients.size() == 8 and s.patients.all(func(p): return not p.used and s._whole(p)),"Eight sedated patients, whole bodies all")
	var beds: Array = s.layout.solids.filter(func(e): return e.type == "bed").map(func(e): return Sim.rect(e.r))
	check(s.patients.all(func(p): return beds.any(func(b): return b.has_point(p.p))),"Each one lies in a bed")
	# The blade does not reach them.
	s.god = true
	s.melee = true
	s.reset()
	s.god = true
	var patient: Dictionary = s.patients[4]
	s.player.p = s.nearest_free(patient.p+Vector2(0,-1.2))
	s.player.angle = ((patient.p as Vector2)-s.player.p).angle()
	s.attack()
	for i in 20: s.update(1.0/60,{"aim":patient.p})
	check(not patient.used and s._whole(patient) and s.civilians_killed == 0,"A cut by the bed leaves the patient asleep")
	# An inquilino dying whole by the ward: its flame gets a patient out of bed.
	s = Sim.new(CLINICA)
	s.reset()
	s.god = true
	var tenant: Dictionary = s.enemies[6]   # by the beds, posing as staff
	check(tenant.kind == "inquilino" and s.patients.any(func(p): return (p.p as Vector2).distance_to(tenant.p) < Sim.WISP.reach),"Staging: an inquilino within reach of the beds")
	var count: int = s.enemies.size()
	s.kill(tenant,Vector2.ZERO)
	var rose: Dictionary = {}
	for i in 60*3:
		s.update(1.0/60,{})
		for event in s.events: if event.type == "rise" and event.patient >= 0: rose = event
		s.events.clear()
	check(not rose.is_empty() and rose.spare and s.patients[rose.patient].used,"The flame wears a patient, who gets out of bed")
	var risen: Dictionary = s.enemies[-1]
	check(s.enemies.size() == count+1 and risen.alive and risen.get("patient",false) and risen.kind == "inquilino","…a new enemy, still a patient")
	check(not s._whole(s.patients[rose.patient]),"That bed is empty now")
	# Killing the patient who got up is killing a person.
	s.events.clear()
	s.kill(risen,Vector2.RIGHT,"katana")
	check(s.civilians_killed == 1 and s.events.any(func(e): return e.type == "patient_down"),"Killing the risen patient counts as a civilian death")
	s.reset()
	check(s.patients.all(func(p): return not p.used) and s.civilians_killed == 0,"A retry puts everyone back to bed")
	# FÔLEGO II, Souza, Celeste.
	check(Campaign.mods(["folego_1","folego_2"]).mana_drain == 25.0 and Campaign.mods(["folego_1"]).mana_drain == 29.0,"Fôlego II: the spectre drains 25 a second")
	var after := Campaign.fresh()
	check(not Campaign.souza_saved(after),"Without his file, Souza is not saved")
	after.clues = ["prontuario_souza"]
	after.cleared = range(11)
	check(Campaign.souza_saved(after) and Campaign.messages(after).any(func(m): return m.begins_with("Mandei a foto")),"With his file, Souza is saved and Celeste says so")
	# On screen.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.load_level(CLINICA)
	game.start_or_resume()
	game.sim.state = "playing"
	game.sim.god = true
	game._physics_process(1.0/60)
	check(game.patient_view.bodies.size() == 8 and game.patient_view.bodies.all(func(b): return b.visible),"Eight patients under their sheets")
	var actors: int = game.actors.size()
	game.sim.kill(game.sim.enemies[6],Vector2.ZERO)
	for i in 60*3: game._physics_process(1.0/60)
	var empty: Array = game.patient_view.bodies.filter(func(b): return not b.visible)
	check(empty.size() == 1 and game.actors.size() == actors+1,"One bed empties; the patient is on stage, on his feet")
	check(game.actors[-1].model.find_children("*","MeshInstance3D",true,false).any(func(n): return n.get_surface_override_material(0) and n.get_surface_override_material(0).albedo_color == game.ActorVisual.GOWN),"…in a hospital gown")
	game.queue_free()
	await process_frame
	print("PATIENT: %d/%d checks passed" % [checks-failures,checks])
	quit(1 if failures else 0)
