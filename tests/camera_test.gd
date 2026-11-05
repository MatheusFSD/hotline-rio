extends SceneTree
## Security cameras and rifle guards (docs/narrativa.md, Fase 6), on the bar's floor plan with a
## camera added: it sees the hero inside its range and cone with a clear line, even as a spectre,
## and then every living enemy knows where he is; walls hide him; a sweeping camera pans; a shot
## or a cut breaks it, the shot still heard; a broken camera sees nothing; a retry mends it. Rifle
## guards fire a faster bullet. Then main.gd: the housing and its cone on stage, the rifle in hand.
const Sim = preload("res://scripts/simulation.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func of_type(s,type: String) -> Array:
	return s.events.filter(func(e): return e.type == type)
## The bar with one camera in the open room, watching east; everyone far away and unaware.
func staged(camera := {}) -> Object:
	var s = Sim.new()
	var spec := {"p":[-2.0,0.0],"angle":0.0,"fov":.5,"range":7.0}
	spec.merge(camera,true)
	s.layout.cameras = [spec]
	s.reset()
	s.god = true   # nobody kills him while the camera is under test
	s.player.p = Sim.point(s.layout.start)   # outside, where no one sees him
	return s
func run() -> void:
	var s = staged()
	var cam: Dictionary = s.cameras[0]
	var ahead: Vector2 = cam.p+Vector2(4.0,0)
	check(s.nearest_free(ahead) == ahead and s.can_see(cam.p,ahead),"Test setup: open floor four metres ahead of the camera")
	s.update(1.0/60,{})
	check(not cam.seeing and s.enemies.all(func(e): return not e.alerted),"Out of its cone it sees nothing")
	s.player.p = ahead
	s.player.mana = 100.0
	s.update(1.0/60,{"phase":true})
	s.update(1.0/60,{"phase":true})
	check(s.player.phasing and cam.seeing and of_type(s,"alarm").size() == 1,"It catches the Avesso: it sees the hero even as a spectre")
	check(s.enemies.all(func(e): return not e.alive or (e.alerted and e.last_seen == s.player.p)),"And then every living enemy knows where he is")
	s = staged()
	cam = s.cameras[0]
	s.player.p = cam.p+Vector2(0,4.0)
	s.update(1.0/60,{})
	check(not cam.seeing,"Outside the half-angle, beside it, unseen")
	s = staged({"range":4.0})
	s.player.p = s.cameras[0].p+Vector2(5.0,0)
	s.update(1.0/60,{})
	check(not s.cameras[0].seeing,"Beyond its range, unseen")
	# A wall in the way hides him; the camera looks through nothing.
	s = staged()
	cam = s.cameras[0]
	var hidden := Vector2.INF
	for x in range(-12,12):
		for z in range(-7,8):
			var p := Vector2(x,z)
			var to: Vector2 = p-cam.p
			if to.length() < 6.5 and absf(angle_difference(cam.angle,to.angle())) < .4 and not s.can_see(cam.p,p) and s.nearest_free(p) == p:
				hidden = p
	if hidden != Vector2.INF:
		s.player.p = hidden
		s.update(1.0/60,{})
		check(not cam.seeing,"Behind a solid inside its cone, unseen")
	# A sweeping camera pans back and forth.
	s = staged({"sweep":.8,"period":4.0})
	cam = s.cameras[0]
	var angles := []
	for i in 240:
		s.update(1.0/60,{})
		angles.append(cam.angle)
	check(angles.max()-angles.min() > 1.4 and absf(angles.max()-.8) < .05,"A sweeping camera pans ±0.8 rad over its period")
	# A shot breaks it, and the shot is heard; a broken camera is blind.
	s = staged()
	cam = s.cameras[0]
	# From a spot a few metres off with nothing between the gun and the camera.
	for k in 24:
		var spot: Vector2 = cam.p+Vector2.from_angle(TAU*k/24)*4.0
		if s.nearest_free(spot) == spot and s.can_see(spot,cam.p):
			s.player.p = spot
			break
	s.player.angle = (cam.p-s.player.p).angle()
	s.attack()
	for i in 20: s.update(1.0/60,{})
	check(s.can_see(s.player.p,cam.p) and not cam.alive,"A shot breaks the camera")
	s.player.p = cam.p+Vector2(3.0,0)
	s.update(1.0/60,{})
	check(not cam.seeing,"Broken, it sees nothing")
	s = staged()
	cam = s.cameras[0]
	s.player.p = s.nearest_free(cam.p+Vector2(-1.2,.4))
	s.player.angle = (cam.p-s.player.p).angle()
	if s.melee == false: s.switch_weapon()
	for i in 20: s.update(1.0/60,{})
	s.player.angle = (cam.p-s.player.p).angle()
	s.attack()
	for i in 20: s.update(1.0/60,{})
	check(not cam.alive,"A cut from below breaks it too, without a sound")
	s.reset()
	check(s.cameras[0].alive,"A retry mends every camera")
	# Rifle guards: a faster bullet.
	s = Sim.new()
	s.layout.enemies[0].weapon = "rifle"
	s.reset()
	var guard: Dictionary = s.enemies[0]
	var gun = Sim.ENEMY_RIFLE if guard.weapon == "rifle" else Sim.ENEMY_GUN
	s.shoot(guard,"enemy",gun)
	check(guard.weapon == "rifle" and is_equal_approx((s.bullets[-1].v as Vector2).length(),46.0) and s.bullets[-1].weapon == "rifle","A rifle guard's bullet flies at 46 m/s and is a rifle round")
	check(s.enemies[1].weapon == "pistol","The others keep the pistol")
	# In the game: the housing, its cone, the rifle in hand.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_or_resume()
	game.sim.layout.cameras = [{"p":[-2.0,0.0],"angle":0.0,"fov":.5,"range":7.0}]
	game.sim.layout.enemies[0].weapon = "rifle"
	game.sim.reset()
	game.actors.pop_at(1).queue_free()
	game.actors.insert(1,game._add_actor(1))
	game.actors.pop_back()
	game.sim.state = "playing"
	for i in 3: game._physics_process(1.0/60)
	check(game.camera_view.units.size() == 1 and game.camera_view.cones[0].mesh.get_surface_count() == 1,"The camera hangs on stage with its cone on the floor")
	check(game.actors[1].weapon == "rifle","The rifle guard holds a rifle")
	game.sim.break_camera(game.sim.cameras[0])
	game._physics_process(1.0/60)
	check(game.camera_view.cones[0].mesh.get_surface_count() == 0,"Broken, its cone goes out")
	game.queue_free()
	await process_frame
	print("CAMERA: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
