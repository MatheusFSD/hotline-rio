extends SceneTree
const Sim = preload("res://scripts/simulation.gd")
var failures := 0
var checks := 0
var game
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func tick(input: Dictionary = {}) -> void:
	game.sim.update(1.0/60,input)
	for i in game.actors.size(): game.actors[i].sync(game.sim.player if i==0 else game.sim.enemies[i-1],1.0/60,false)
	game.effects.update(1.0/60)
	game.effects.consume(game.sim.events,game.actors)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_or_resume()
	game.sim.player.p = Vector2(-8.9,6.5)
	var target: Dictionary = game.sim.enemies[0]
	tick({"aim":target.p,"attack":true})
	check(game.actors[0].flash_mesh.visible and game.actors[0].flash_light.visible,"Shot flashes at weapon")
	check(game.effects.bits.size() >= 1 and game.effects.shake > 0,"Shot ejects a shell and shakes camera")
	for i in 2: tick()
	check(not game.effects.traces.is_empty(),"Moving projectile draws a tracer")
	for i in 8: tick()
	check(not target.alive and game.effects.stain_total > 0,"Lethal hit paints blood on the floor")
	check(not game.actors[0].flash_mesh.visible,"Muzzle flash expires")
	var count: int = game.effects.bits.size()
	var age: float = game.effects.bits[0].age
	var h: float = game.camera.h_offset
	game.effects.update(.5,true)
	check(game.effects.bits.size() == count and game.effects.bits[0].age == age and game.camera.h_offset == h,"Pause freezes particles and shake")
	var aim: Vector2 = game.aim_position()
	game.camera.h_offset = .3; game.camera.v_offset = -.2
	check(game.aim_position().is_equal_approx(aim),"Camera shake does not move logical aim")
	for i in 90: game.effects.update(1.0/60)
	check(game.effects.traces.is_empty() and game.effects.shake == 0 and game.camera.h_offset == 0,"Tracers and camera shake expire")
	game.start_or_resume()
	check(game.effects.bits.is_empty() and game.effects.traces.is_empty() and game.effects.stain_total == 0,"Restart removes all combat effects")
	var sim = Sim.new()
	sim.reset()
	sim.player.p = Vector2(-6.8,5)
	sim.player.angle = 0
	sim.attack()
	for i in 4: sim.update(1.0/60)
	var impact := false
	var clipped := true
	for event in sim.events:
		if event.type == "impact": impact = true
		if event.type == "trace":
			clipped = clipped and event.b.x <= -6.15+.0001
	check(impact and clipped,"Impact and tracer stop exactly at wall")
	game.effects.consume(sim.events,game.actors)
	check(game.effects.bits.size() >= 6,"Wall hit emits fragments")
	game.effects.clear()
	var burst: Array[Dictionary] = []
	for i in 24: burst.append({"type":"blood","p":Vector2(-2,3),"direction":Vector2.UP,"player":false})
	game.effects.consume(burst,game.actors)
	check(game.effects.bits.size() <= game.effects.MAX_BITS and game.effects.stain_total <= game.effects.MAX_STAINS,"Heavy combat keeps particles and stains within their caps")
	game.effects.clear()
	var velocity_sim = Sim.new()
	velocity_sim.reset()
	velocity_sim.player.p = Vector2(-6.45,5)
	velocity_sim.update(1.0/60,{"move":Vector2.RIGHT})
	check(not velocity_sim.player.moving and velocity_sim.player.velocity == Vector2.ZERO,"Pressing into a wall does not animate running in place")
	velocity_sim.reset()
	velocity_sim.player.p = Vector2(13,9)
	for i in 4: velocity_sim.update(1.0/60)
	check(absf((velocity_sim.enemies[0].velocity as Vector2).length()-.925) < .0001,"Patrol reports the actual walking speed")
	velocity_sim.enemies[0].alerted = true
	velocity_sim.enemies[0].memory = 3.0
	velocity_sim.enemies[0].last_seen = Vector2(-8.9,7)
	velocity_sim.update(1.0/60)
	check(absf((velocity_sim.enemies[0].velocity as Vector2).length()-2.15) < .0001,"Pursuit reports the actual running speed")
	var snapshot: Dictionary = game.sim.player.duplicate(true)
	game.effects.update(.1)
	check(snapshot == game.sim.player,"Presentation does not change simulation")
	game.queue_free()
	await process_frame
	print("EFFECTS: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
