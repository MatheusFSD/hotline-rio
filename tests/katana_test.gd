extends SceneTree
## The hero's katana: swapping with the gun, a cut that lands after its wind-up in an arc ahead,
## walls and range, silence, the model in the fist, the cuts alternating, gore and HUD.
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func key(game,code) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._unhandled_input(event)
func step(sim,frames: int,aim: Vector2) -> void:
	for i in frames: sim.update(1.0/60,{"aim":aim})
func run() -> void:
	var Sim = load("res://scripts/simulation.gd")
	var s = Sim.new()
	s.reset()
	for e in s.enemies: e.reaction = 999.0   # nobody fires back during the checks
	var hero: Dictionary = s.player
	hero.p = Vector2(-2.6,-2.6)
	hero.ammo = 7
	hero.reload = .4
	s.switch_weapon()
	check(hero.melee and s.melee and hero.reload == 0.0 and hero.ammo == 7,"F swaps to the katana, keeps the rounds, drops the reload")
	check(hero.cooldown >= Sim.KATANA.swap-.001,"Swapping takes a moment")
	s.attack()
	check(hero.swings == 0,"No cut while the katana is still being drawn")
	var target: Dictionary = s.enemies[1]
	target.p = hero.p+Vector2(0,1.2)
	var aside: Dictionary = s.enemies[2]
	aside.p = hero.p+Vector2(-1.2,-.4)   # behind the arc
	var far: Dictionary = s.enemies[4]
	far.p = hero.p+Vector2(.3,2.6)        # ahead but out of reach
	var bystander: Dictionary = s.enemies[3]
	bystander.p = hero.p+Vector2(4.0,0)
	bystander.patrol = [[bystander.p.x,bystander.p.y]]   # standing still,
	bystander.angle = 0.0                                # back turned to the hero
	bystander.alerted = false
	step(s,15,hero.p+Vector2(0,1))
	s.attack()
	check(hero.swings == 1 and hero.ammo == 7,"A click cuts; no round is spent")
	step(s,int(Sim.KATANA.strike*60)-2,hero.p+Vector2(0,1))
	check(target.alive,"The cut has a wind-up before it lands")
	step(s,4,hero.p+Vector2(0,1))
	check(not target.alive and s.kills == 1,"The cut kills what is in front, within reach")
	check(aside.alive and far.alive,"Nothing behind the arc or past its reach")
	check(not bystander.alerted,"The katana is silent: it alerts nobody")
	s.shoot(hero,"player",Sim.WEAPONS.pistol)
	check(bystander.alerted,"(where a gunshot would have)")
	s.bullets.clear()
	var blood: Array = s.events.filter(func(e): return e.type == "blood")
	check(not blood.is_empty() and blood[0].weapon == "katana","Katana kills are tagged for the gore")
	check(s.events.any(func(e): return e.type == "slash"),"Each cut is an event for the arc of light")
	# Walls stop the blade.
	var walled: Dictionary = s.enemies[5]
	hero.p = Vector2(3.0,-4.0)
	walled.p = Vector2(4.5,-4.0)   # behind the kitchen partition (x 3.6 - 4.05, z -7.3 - -2.6)
	hero.cooldown = 0.0
	step(s,1,walled.p)
	s.attack()
	step(s,20,walled.p)
	check(walled.alive,"The blade does not cut through a wall")
	hero.cooldown = 0.0
	hero.phasing = true
	s.slash()
	check(hero.swings == 2,"No cut as a spectre")
	hero.phasing = false
	s.reload()
	check(hero.reload == 0.0,"R does nothing with the katana in hand")
	s.reset()
	check(s.player.melee,"The choice of the katana survives a retry")
	s.switch_weapon()
	check(not s.player.melee,"F swaps back to the gun")
	# Gore: a clean blade always takes something.
	var roll := RandomNumberGenerator.new()
	var whole := 0
	for i in 200: if s.gore_variant("katana",roll).is_empty(): whole += 1
	check(whole == 0,"Katana kills always cut something off")
	# In the game: input, model, animation and HUD.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	key(game,KEY_ENTER)
	for e in game.sim.enemies: e.reaction = 999.0
	var visual = game.actors[0]
	key(game,KEY_F)
	check(game.sim.melee and visual.weapon == "katana","F in game puts the katana in hand")
	key(game,KEY_F)
	check(not game.sim.melee and visual.weapon == game.sim.weapon,"F again swaps back to the gun")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	game._unhandled_input(wheel)
	check(not game.sim.melee,"The mouse wheel zooms now; it no longer swaps weapons")
	key(game,KEY_F)
	var player: Dictionary = game.sim.player
	for i in 3: visual.sync(player,1.0/60,false)
	check(visual.current == "ual2/Sword_Guard","With the katana the hero stands in guard")
	var socket: BoneAttachment3D = visual.gun.get_parent()
	socket.on_skeleton_update()
	var to_skeleton: Transform3D = visual.skeleton.global_transform.affine_inverse()
	var grip: Vector3 = to_skeleton*visual.gun.global_position
	check(grip.distance_to(visual.fist_frame("r").origin) < .01,"The handle sits inside the right fist")
	var blade: Vector3 = (visual.global_basis.inverse()*visual.gun.global_basis.y).normalized()
	check(blade.z > .8,"In guard the blade points ahead (%.2f)" % blade.z)
	var tip: Array = visual.weapon_manifest.katana.muzzle
	check(tip[1] > .75 and tip[1] < .9,"The blade reaches %.2f m past the fist" % tip[1])
	player.cooldown = 0.0
	game.sim.slash()
	visual.sync(player,1.0/60,false)
	check(visual.current == "ual2/Slash_A","The first cut plays Slash_A")
	player.cooldown = 0.0
	game.sim.slash()
	visual.sync(player,1.0/60,false)
	check(visual.current == "ual2/Slash_B","The next cut plays Slash_B")
	player.cooldown = 0.0
	game.sim.slash()
	visual.sync(player,1.0/60,false)
	check(visual.current == "ual2/Slash_A" and visual.animator.current_animation_position < .05,"Every click starts its cut from the top")
	player.swing = 1.9
	visual.sync(player,1.0/60,false)
	check(visual.current == "ual2/Sword_Guard","After the recovery the hero is back in guard")
	game.update_ui()
	check(game.hud.weapon.text == "KATANA" and not game.hud.ammo_box.visible and game.hud.spare.text.begins_with("F  PISTOLA"),"The HUD shows the katana and the gun one F away")
	game.queue_free()
	await process_frame
	print("KATANA: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
