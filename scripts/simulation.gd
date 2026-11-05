class_name LapaSimulation
extends RefCounted
## Ground-plane simulation for fixed-height 3D combat. World units are meters.
## Rendering, skeletons and UI have no authority over hits or movement.
const RADIUS := 0.30
const SPEED := 5.2
## Player weapons: magazine, reload seconds, seconds between shots, pellets per shot,
## spread (whole cone, radians), bullet speed and lifetime, minigun spin-up, camera kick.
## Holding the button fires at the weapon's own cadence; enemies always carry pistols.
const WEAPONS := {
	"pistol":{"name":"PISTOLA","magazine":12,"reload":.75,"cooldown":.26,"pellets":1,"spread":0.0,"speed":29.0,"life":1.5,"spin":0.0,"kick":.18},
	"smg":{"name":"SUBMETRALHADORA","magazine":30,"reload":1.1,"cooldown":.075,"pellets":1,"spread":.14,"speed":27.0,"life":1.1,"spin":0.0,"kick":.07},
	"shotgun":{"name":"ESCOPETA","magazine":6,"reload":1.35,"cooldown":.7,"pellets":7,"spread":.42,"speed":25.0,"life":.42,"spin":0.0,"kick":.42},
	"rifle":{"name":"FUZIL","magazine":20,"reload":1.3,"cooldown":.13,"pellets":1,"spread":.035,"speed":38.0,"life":1.5,"spin":0.0,"kick":.12},
	"minigun":{"name":"MINIGUN","magazine":120,"reload":2.6,"cooldown":.045,"pellets":1,"spread":.16,"speed":30.0,"life":1.2,"spin":.55,"kick":.05}}
const ENEMY_GUN := {"pellets":1,"spread":0.0,"speed":29.0,"life":1.5,"kick":.035}
## Guardião guards with rifles (enemies[i].weapon = "rifle"): a faster bullet, still one shot.
const ENEMY_RIFLE := {"pellets":1,"spread":0.0,"speed":46.0,"life":1.2,"kick":.05}
## The hero's katana, always at hand next to the gun from the room: one cut every `cooldown`
## seconds that lands `strike` seconds after the click, killing every enemy in an arc of
## +-`arc` radians and `reach` metres ahead with a clear line. Silent: unlike a shot it alerts
## nobody. Swapping (F or the mouse wheel) takes `swap` seconds and drops a reload in progress.
const KATANA := {"name":"KATANA","cooldown":.45,"strike":.2,"reach":1.8,"arc":1.13,"swap":.22}
## Spinning the minigun slows its carrier by up to this fraction.
const MINIGUN_DRAG := .45
const MANA_DRAIN := 34.0
const MANA_REGEN := 18.0
const CELL := 0.4
## The nights in order. Each file holds a whole level: scenery, lamps, briefing, solids, cast and exit.
const LEVELS := ["res://assets/level.json","res://assets/level_2.json","res://assets/level_3.json","res://assets/level_4.json","res://assets/level_5.json","res://assets/level_6.json","res://assets/level_7.json","res://assets/level_8.json","res://assets/level_9.json","res://assets/level_10.json","res://assets/level_11.json","res://assets/level_12a.json","res://assets/level_12b.json","res://assets/level_12c.json"]
var level := 0
var layout: Dictionary
var solids: Array[Rect2] = []
## The solids nothing sees or shoots through: all but the glass panes ("type":"glass", docs/planejado/fase10-12.md),
## which hold a body back but let sight and bullets pass.
var opaque: Array[Rect2] = []
var bounds: Rect2
var exit_rect: Rect2
var grid := AStarGrid2D.new()
var player: Dictionary
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var events: Array[Dictionary] = []
var state := "ready"
var attempt := 0
var kills := 0
var elapsed := 0.0
var weapon := "pistol"
var melee := false   # katana in hand instead of the gun; kept across retries
var god := false     # modo deus: bullets still hit the hero but cannot kill him; kept across retries and nights
var rng := RandomNumberGenerator.new()
## Dismemberment is a rule, not decoration: a body torn apart is no use to what lives inside it
## (docs/narrativa.md, 4.3). Rolled here, per attempt, and handed to the effects in the blood event.
var gore_rng := RandomNumberGenerator.new()
## Campaign upgrades over the base numbers (Campaign.mods): mana_drain, magazine {gun: rounds},
## reload_mult, notice (metres at which an unaware enemy feels the hero), swap, pistol_alert.
var mods := {}
## This attempt's clues (layout "clues"): id, title, text, required, the rect on the floor or the
## enemy who drops it, and whether it is taken. The exit opens with every enemy down and every
## required clue taken.
var clues: Array[Dictionary] = []
## The casca rule (docs/narrativa.md, 4.3). A casca killed whole lets out a shadow-flame that
## flies, through walls, to the nearest whole body within `reach` and stands it up as a new
## inquilino; a torn casca lets out nothing. Without a body the flame goes back to the Avesso.
const WISP := {"life":2.5,"reach":6.0,"speed":{"inquilino":3.0,"proprietario":4.0},"rise":.9,"drop":.7,"reaction":.6,"grab":.55,"fade":.6}
## Shadow-flames in flight: p, kind, the casca they left (from: never theirs again), target (a
## corpse or a shell, {} when there is none), life.
var wisps: Array[Dictionary] = []
## Whole bodies hanging in bags (layout "shells": p, angle): spare cascas. A shot or a cut tears one.
var shells: Array[Dictionary] = []
## Security cameras (layout "cameras": p, angle, fov half-angle, range, sweep, period). A camera
## catches the Avesso: it sees the hero even as a spectre, and when it does every living enemy
## knows where he is. A shot or a cut breaks it; the shot is still heard.
var cameras: Array[Dictionary] = []
## Guests (layout "civilians", docs/fase7.md): people at the party, not targets. The first shot
## anywhere sends every calm one running for the nearest "flee" point; a death in plain sight
## within CIVILIAN.startle sends that one. The hero's bullets and blade kill them (counted, never
## failing the night); the guards' bullets pass through. A guest killed whole is a body the
## shadow-flames can wear.
## Proprietários (kind "proprietario", docs/fase8.md): tenants with the hero's own power. Shot at
## within PROPRIETOR.reach, or right after firing, one blinks (still, killable) and then goes
## through to the Avesso: through walls and bullets, not shooting, to a spot beside the hero away
## from his aim; out again, it waits PROPRIETOR.cooldown before it can do it again.
const PROPRIETOR := {"blink":.3,"phase":1.5,"cooldown":4.0,"flank":3.5,"speed":3.2,"reach":9.25,"first":1.0}
## The breaker (layout "breaker", docs/fase9.md): a shot or a cut trips it and the building goes
## dark until the retry. In the dark people see DARK.sight of the distance and take DARK.reaction
## times as long; what lives in a casca sees the same, and so do the cameras.
const DARK := {"sight":.5,"reaction":2.0,"hit":.25}
var breaker: Dictionary = {}
var dark := false
## Sedated patients (layout "patients", docs/planejado/fase10-12.md): live, whole bodies lying in
## their beds. Out of reach of bullets and blades, but a shadow-flame can wear one: it gets out of
## bed occupied, and killing it then is killing a person.
var patients: Array[Dictionary] = []
## The Síndico (layout "boss", docs/planejado/fase10-12.md): the enemy marked "sindico", fought over
## night twelve's three stages. 1, the rally: a Proprietário whose flame flees to the elevator.
## 2, the count room: his flame jumps to the nearest whole body within boss.reach and gets up
## faster each time, until no body is in reach (he flees down the shaft) or the Mão do Avesso
## takes it. 3, the helipad: no casca, seen only from the spectre, walking through everything
## toward the hero; his touch kills outside the spectre, only the katana kills him.
var known_clues: Array = []   # the campaign's clues, for shells that exist "unless_clue"
var pads: Array[Dictionary] = []   # stage 3's landing lights: +PAD.mana once each
const PAD := {"mana":30.0,"reach":.8}
const CIVILIAN := {"speed":2.6,"startle":5.0,"repath":.45,"arrive":.4}
var civilians: Array[Dictionary] = []
var civilians_killed := 0

func _init(index := 0) -> void:
	grid.region = Rect2i(-40, -30, 80, 60)
	grid.cell_size = Vector2.ONE * CELL
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	load_level(index)

func load_level(index: int) -> void:
	## A new night: another level, its attempts counted from zero. Weapon and katana carry over.
	level = index
	layout = JSON.parse_string(FileAccess.get_file_as_string(LEVELS[index]))
	bounds = rect(layout.bounds)
	exit_rect = rect(layout.exit)
	solids.clear()
	opaque.clear()
	for entry in layout.solids:
		solids.append(rect(entry.r))
		if entry.type != "glass": opaque.append(rect(entry.r))
	for x in range(-40, 40):
		for z in range(-30, 30):
			grid.set_point_solid(Vector2i(x, z), blocked(Vector2(x,z)*CELL, RADIUS + 0.09))
	attempt = 0
	reset(false)

static func point(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))

static func rect(a: Array) -> Rect2:
	return Rect2(float(a[0]),float(a[1]),float(a[2]),float(a[3]))

func reset(play := true) -> void:
	if play: attempt += 1
	state = "playing" if play else "ready"
	kills = 0
	civilians_killed = 0
	dark = false
	elapsed = 0.0
	bullets.clear()
	events.clear()
	rng.seed = 1979+attempt   # spread stays reproducible per attempt
	gore_rng.seed = 5011+attempt
	player = actor(point(layout.start), -PI/2)
	player.merge({"ammo":stats().magazine,"reload":0.0,"mana":100.0,"phasing":false,"locked":false,"regen_delay":0.0,"spin":0.0,
		"melee":melee,"swing":-1.0,"swings":0,"struck":true,"god":god})
	enemies.clear()
	for i in layout.enemies.size():
		var entry: Dictionary = layout.enemies[i]
		var e := actor(nearest_free(point(entry.p)), float(entry.angle))
		e.merge({"id":i,"patrol":entry.patrol,"patrol_index":0,"reaction":float(entry.reaction),"alerted":false,"memory":0.0,"last_seen":e.p,"windup":0.0,"route":PackedVector2Array(),"repath":0.0,
			"kind":String(entry.get("kind","human")),"gore":"","weapon":String(entry.get("weapon","pistol")),
			"phase_state":"","phase_t":0.0,"phase_cd":PROPRIETOR.first,"phase_goal":Vector2.ZERO,"phasing":false,
			"sindico":bool(entry.get("sindico",false))})
		e.ghost = e.sindico and stage() == 3   # on the helipad: no casca, bullets go through him
		enemies.append(e)
	wisps.clear()
	shells.clear()
	cameras.clear()
	for entry in layout.get("cameras",[]):
		cameras.append({"p":point(entry.p),"base":float(entry.angle),"angle":float(entry.angle),"fov":float(entry.get("fov",.5)),
			"range":float(entry.get("range",7.0)),"sweep":float(entry.get("sweep",0.0)),"period":float(entry.get("period",6.0)),
			"alive":true,"seeing":false})
	civilians.clear()
	for i in layout.get("civilians",[]).size():
		var entry: Dictionary = layout.civilians[i]
		var c := actor(nearest_free(point(entry.p)),float(entry.get("angle",0.0)))
		c.merge({"id":i,"civilian":true,"pose":String(entry.get("pose","drink")),"state":"calm","alerted":false,
			"route":PackedVector2Array(),"repath":0.0,"gore":"","used":false,"kind":"human","vip":String(entry.get("vip",""))})
		civilians.append(c)
	breaker = {}
	if layout.has("breaker"): breaker = {"breaker":true,"p":point(layout.breaker.p),"alive":true}
	patients.clear()
	for entry in layout.get("patients",[]):
		patients.append({"bed":true,"id":patients.size(),"p":point(entry.p),"angle":float(entry.get("angle",0.0)),"used":false})
	for entry in layout.get("shells",[]):
		if entry.get("unless_clue","") in known_clues: continue   # Souza, saved by his file, is not among them
		shells.append({"p":point(entry.p),"angle":float(entry.get("angle",0.0)),"torn":false,"used":false,
			"style":String(entry.get("style","")),"name":String(entry.get("name",""))})
	pads.clear()
	for entry in layout.get("pads",[]): pads.append({"p":point(entry),"used":false})
	clues.clear()
	for entry in layout.get("clues",[]):
		clues.append({"id":entry.id,"title":entry.title,"text":entry.get("text",""),"required":bool(entry.get("required",false)),
			"rect":rect(entry.r) if entry.has("r") else Rect2(),"from_enemy":int(entry.get("from_enemy",-1)),"taken":false})

func stats() -> Dictionary:
	## The gun in hand, with the campaign's magazine and reload upgrades.
	var gun: Dictionary = WEAPONS[weapon]
	if not (mods.has("magazine") or mods.has("reload_mult")): return gun
	gun = gun.duplicate()
	gun.magazine = int(mods.get("magazine",{}).get(weapon,gun.magazine))
	gun.reload *= float(mods.get("reload_mult",1.0))
	return gun

## Where a clue lies now: its rect's centre, or the body of the enemy who carries it once he is
## down. Vector2.INF while it cannot be picked up.
func clue_spot(c: Dictionary) -> Vector2:
	if c.from_enemy < 0: return (c.rect as Rect2).get_center()
	if c.from_enemy >= enemies.size(): return Vector2.INF
	var carrier: Dictionary = enemies[c.from_enemy]
	return carrier.p if not carrier.alive else Vector2.INF

func clues_done() -> bool:
	return clues.all(func(c): return c.taken or not c.required)

## Every enemy down, no shadow-flame still looking for a body and every required clue taken:
## the exit counts.
func cleared() -> bool:
	return kills == enemies.size() and wisps.is_empty() and clues_done()

func taken_clues() -> Array:
	return clues.filter(func(c): return c.taken).map(func(c): return c.id)

func _pick_clues() -> void:
	## Walking over a clue takes it, never as a spectre: the spectre touches nothing.
	if player.phasing: return
	for c in clues:
		if c.taken: continue
		var spot := clue_spot(c)
		if spot == Vector2.INF: continue
		var reached: bool = (c.rect as Rect2).grow(.35).has_point(player.p) if c.from_enemy < 0 else (player.p as Vector2).distance_to(spot) < .9
		if reached:
			c.taken = true
			events.append({"type":"clue","id":c.id,"title":c.title,"text":c.text,"required":c.required})

static func gore_variant(weapon: String,roll_rng: RandomNumberGenerator) -> String:
	## Pistol and SMG keep most bodies whole; shotgun and rifle always take something off,
	## a quarter of the time cutting the body in half; the minigun always cuts in half.
	if weapon == "minigun": return "half"
	var roll := roll_rng.randf()
	if weapon == "katana":
		# A clean blade always takes something: mostly heads and arms, sometimes the whole body in two.
		if roll < .3: return "head"
		if roll < .6: return "arm_"+("l" if roll_rng.randf() < .5 else "r")
		if roll < .75: return "leg_"+("l" if roll_rng.randf() < .5 else "r")
		return "half"
	if weapon in ["shotgun","rifle"]:
		if roll < .25: return "half"
		roll = .55+(roll-.25)/.75*.45   # the rest splits evenly between head, arms and legs
	elif roll < .55: return ""
	if roll < .70: return "head"
	var side := "l" if roll_rng.randf() < .5 else "r"
	return ("arm_" if roll < .85 else "leg_")+side

static func actor(p: Vector2, angle: float) -> Dictionary:
	return {"p":p,"angle":angle,"alive":true,"moving":false,"velocity":Vector2.ZERO,"cooldown":0.0,"recoil":0.0,"death_age":0.0}

func blocked(p: Vector2, radius := RADIUS) -> bool:
	if not bounds.grow(-radius).has_point(p): return true
	for r in solids:
		var q := Vector2(clampf(p.x,r.position.x,r.end.x),clampf(p.y,r.position.y,r.end.y))
		if p.distance_squared_to(q) < radius*radius: return true
	return false

func nearest_free(p: Vector2) -> Vector2:
	if not blocked(p): return p
	for ring in range(1,100):
		for i in range(32):
			var q := p + Vector2.from_angle(TAU*i/32.0)*ring*0.15
			if not blocked(q): return q
	return point(layout.start)

func move(a: Dictionary, offset: Vector2) -> void:
	# Small substeps prevent tunneling even for external calls with a long offset.
	var count := maxi(1,ceili(offset.length()/0.12))
	var delta := offset / count
	for i in count:
		var p: Vector2 = a.p
		if not blocked(p+Vector2(delta.x,0)): p.x += delta.x
		if not blocked(p+Vector2(0,delta.y)): p.y += delta.y
		a.p = p

static func segment_box(a: Vector2,b: Vector2,r: Rect2) -> float:
	var delta := b-a
	var low := 0.0
	var high := 1.0
	for axis in 2:
		if absf(delta[axis]) < 0.000001:
			if a[axis] < r.position[axis] or a[axis] > r.end[axis]: return INF
		else:
			var t1 := (r.position[axis]-a[axis])/delta[axis]
			var t2 := (r.end[axis]-a[axis])/delta[axis]
			low = maxf(low,minf(t1,t2))
			high = minf(high,maxf(t1,t2))
			if low > high: return INF
	return low

static func segment_circle(a: Vector2,b: Vector2,p: Vector2,radius := RADIUS) -> float:
	var d := b-a
	var f := a-p
	var aa := d.dot(d)
	if f.length_squared() <= radius*radius: return 0.0
	if aa < 0.000001: return INF
	var bb := 2*f.dot(d)
	var disc := bb*bb-4*aa*(f.dot(f)-radius*radius)
	if disc < 0: return INF
	var t := (-bb-sqrt(disc))/(2*aa)
	return t if t >= 0 and t <= 1 else INF

## Where a line first meets a solid (0..1, INF for a clear line). Sight and bullets go through
## glass; a body moving along the line passes `glass` true and is stopped by it.
func wall_hit(a: Vector2,b: Vector2,margin := 0.0,glass := false) -> float:
	var t := INF
	for r in (solids if glass else opaque): t = minf(t,segment_box(a,b,r.grow(margin)))
	return t

func can_see(a: Vector2,b: Vector2) -> bool:
	return wall_hit(a,b) == INF

func path(a: Vector2,b: Vector2) -> PackedVector2Array:
	var from := Vector2i((a/CELL).round())
	var to := Vector2i((b/CELL).round())
	if not grid.is_in_boundsv(from) or not grid.is_in_boundsv(to): return PackedVector2Array()
	# A character can stand between grid centers. Find a nearby clear center.
	for is_start in [true,false]:
		var current: Vector2i = from if is_start else to
		if grid.is_point_solid(current):
			var best := current
			var best_d := INF
			for x in range(-3,4):
				for y in range(-3,4):
					var q := current+Vector2i(x,y)
					var origin: Vector2 = a if is_start else b
					if grid.is_in_boundsv(q) and not grid.is_point_solid(q) and wall_hit(origin,Vector2(q)*CELL,RADIUS,true) == INF:
						var d := origin.distance_squared_to(Vector2(q)*CELL)
						if d < best_d: best = q; best_d = d
			if is_start: from = best
			else: to = best
	if grid.is_point_solid(from) or grid.is_point_solid(to): return PackedVector2Array()
	return grid.get_point_path(from,to)

func reload() -> void:
	if state == "playing" and not player.melee and not player.phasing and player.reload <= 0 and player.ammo < stats().magazine:
		player.reload = stats().reload

func switch_weapon() -> void:
	## Katana <-> gun. The gun keeps its rounds; a reload in progress is dropped.
	if state != "playing": return
	melee = not melee
	player.melee = melee
	player.reload = 0.0
	player.spin = 0.0
	player.swing = -1.0
	player.struck = true
	player.cooldown = maxf(player.cooldown,float(mods.get("swap",KATANA.swap)))
	events.append({"type":"switch","melee":melee})

func toggle_god() -> void:
	## Modo deus (G): invulnerable to bullets. Everything else plays as usual, kills and exit included.
	god = not god
	player.god = god
	events.append({"type":"god","on":god})

func slash() -> void:
	if state != "playing" or player.phasing or player.cooldown > 0: return
	player.cooldown = KATANA.cooldown
	player.swing = 0.0
	player.struck = false
	player.swings += 1
	events.append({"type":"slash","p":player.p,"direction":Vector2.from_angle(player.angle),"count":player.swings,"reach":KATANA.reach,"arc":KATANA.arc})

func _strike() -> void:
	## The blade lands: everyone alive in the arc ahead, within reach, with no wall in between.
	if player.phasing: return
	var facing := Vector2.from_angle(player.angle)
	var before := kills+civilians_killed
	var hit_bag := false
	for e in enemies:
		if not e.alive or e.get("phasing",false): continue
		var to: Vector2 = e.p-player.p
		var distance := to.length()
		if distance > KATANA.reach+RADIUS: continue
		if distance > RADIUS*1.5 and absf(angle_difference(player.angle,to.angle())) > KATANA.arc: continue
		if not can_see(player.p,e.p): continue
		kill(e,to.normalized() if distance > .01 else facing,"katana")
	for c in civilians:
		if not c.alive: continue
		var to: Vector2 = c.p-player.p
		var distance := to.length()
		if distance > KATANA.reach+RADIUS: continue
		if distance > RADIUS*1.5 and absf(angle_difference(player.angle,to.angle())) > KATANA.arc: continue
		if not can_see(player.p,c.p): continue
		kill_civilian(c,to.normalized() if distance > .01 else facing,"katana")
	for camera in cameras:
		var to: Vector2 = camera.p-player.p
		if camera.alive and to.length() <= KATANA.reach+RADIUS and absf(angle_difference(player.angle,to.angle())) <= KATANA.arc and can_see(player.p,camera.p):
			break_camera(camera)
	if not breaker.is_empty() and breaker.alive:
		var to: Vector2 = breaker.p-player.p
		if to.length() <= KATANA.reach+RADIUS and absf(angle_difference(player.angle,to.angle())) <= KATANA.arc and can_see(player.p,breaker.p): trip()
	for shell in shells:
		var to: Vector2 = shell.p-player.p
		if not shell.torn and to.length() <= KATANA.reach+RADIUS and absf(angle_difference(player.angle,to.angle())) <= KATANA.arc and can_see(player.p,shell.p):
			tear(shell)
			hit_bag = true
	events.append({"type":"strike","hit":hit_bag or kills+civilians_killed != before})

func shoot(a: Dictionary,team: String,gun: Dictionary = ENEMY_GUN) -> void:
	var direction := Vector2.from_angle(a.angle)
	# Start inside the body's collision radius: a muzzle beyond a wall must not bypass it.
	var shooter := int(a.get("id",-1))
	var pellets: int = gun.pellets
	for i in pellets:
		var offset := 0.0
		if gun.spread > 0:
			# A shotgun fans its pellets evenly; single bullets wander inside the cone.
			offset = (float(i)+.5)/pellets-.5 if pellets > 1 else 0.0
			offset = offset*gun.spread+rng.randf_range(-.5,.5)*gun.spread/pellets
		var heading := Vector2.from_angle(a.angle+offset)
		bullets.append({"p":a.p,"origin":a.p,"v":heading*gun.speed,"team":team,"shooter":shooter,"life":gun.life,"weapon":weapon if team == "player" else String(a.get("weapon","pistol"))})
	events.append({"type":"shot","p":a.p,"direction":direction,"team":team,"shooter":shooter,"kick":gun.kick,"pellets":pellets,"weapon":weapon if team == "player" else String(a.get("weapon","pistol"))})
	panic()
	a.recoil = .24
	var heard := float(mods.get("pistol_alert",9.25)) if team == "player" and weapon == "pistol" else 9.25
	for e in enemies:
		if e.alive and e != a and (e.p as Vector2).distance_to(a.p) < heard:
			e.alerted = true; e.memory = 3.0; e.last_seen = a.p
	if team == "player":
		for e in enemies:
			if e.alerted and (e.p as Vector2).distance_to(a.p) <= PROPRIETOR.reach: blink(e)

func attack() -> void:
	if player.melee:
		slash()
		return
	if state != "playing" or player.phasing or player.reload > 0 or player.cooldown > 0: return
	if player.ammo <= 0:
		reload()
		return
	var gun := stats()
	if player.spin < gun.spin: return   # the minigun must spin up first
	shoot(player,"player",gun)
	player.ammo -= 1
	player.cooldown = gun.cooldown

func kill(e: Dictionary,direction := Vector2.ZERO,gun := "pistol") -> void:
	if not e.alive: return
	e.alive = false
	e.moving = false
	e.velocity = Vector2.ZERO
	e.death_age = 0.0
	e.phase_state = ""
	e.phasing = false
	kills += 1
	e.gore = gore_variant(gun,gore_rng) if direction != Vector2.ZERO else ""
	events.append({"type":"blood","p":e.p,"direction":direction if direction != Vector2.ZERO else Vector2.from_angle(player.angle),"player":false,"victim":int(e.id)+1,
		"gore_allowed":direction != Vector2.ZERO,"gore":e.gore,"weapon":gun,"kind":e.get("kind","human")})
	if e.get("patient",false):   # a patient out of bed is still a person
		civilians_killed += 1
		events.append({"type":"patient_down","p":e.p,"victim":int(e.id)+1})
	if e.get("kind","human") != "human": _evict(e)
	_startle(e.p)

## A Proprietário about to go through: it blinks first, still and killable.
func blink(e: Dictionary) -> void:
	if e.get("kind","") != "proprietario" or not e.alive or e.get("rising",0.0) > 0 or e.get("ghost",false): return
	if e.get("phase_state","") != "" or e.get("phase_cd",0.0) > 0: return
	e.phase_state = "blink"
	e.phase_t = PROPRIETOR.blink
	e.windup = 0.0
	events.append({"type":"blink","p":e.p,"victim":int(e.id)+1})

## Beside the hero, PROPRIETOR.flank across the line between them, on the side away from his aim;
## the other side if that one is walled or outside; else two metres back, away from him.
func flank_goal(e: Dictionary) -> Vector2:
	var hero: Vector2 = player.p
	var line: Vector2 = (e.p as Vector2)-hero
	if line.length_squared() < .0001: line = Vector2.RIGHT
	var side := line.normalized().orthogonal()
	if side.dot(Vector2.from_angle(player.angle)) > 0: side = -side
	var area := bounds.grow(-RADIUS)
	for s in [side,-side]:
		var goal: Vector2 = hero+s*PROPRIETOR.flank
		if area.has_point(goal) and not blocked(goal): return goal
	var back: Vector2 = (e.p as Vector2)+line.normalized()*2.0
	return back.clamp(area.position,area.end)

func _update_proprietor(e: Dictionary,dt: float) -> void:
	e.phase_t -= dt
	if e.phase_state == "blink":
		if e.phase_t > 0: return
		e.phase_state = "phasing"
		e.phasing = true
		e.phase_t = PROPRIETOR.phase
		e.phase_goal = flank_goal(e)
		events.append({"type":"proprietor_phase","p":e.p,"victim":int(e.id)+1})
		return
	# Through the Avesso: straight for the goal, walls or not; it still sees and remembers.
	var area := bounds.grow(-RADIUS)
	var step: Vector2 = (e.phase_goal as Vector2)-e.p
	var old: Vector2 = e.p
	e.p = ((e.p as Vector2)+step.limit_length(PROPRIETOR.speed*dt)).clamp(area.position,area.end)
	e.velocity = (e.p-old)/maxf(dt,.000001)
	e.moving = old.distance_squared_to(e.p) > .000001
	if can_see(e.p,player.p):
		e.alerted = true; e.memory = 3.5; e.last_seen = player.p
	e.angle = ((player.p as Vector2)-e.p).angle()
	if e.phase_t > 0: return
	e.p = nearest_free(e.p)
	e.phasing = false
	e.phase_state = ""
	e.phase_cd = PROPRIETOR.cooldown
	e.windup = 0.0
	events.append({"type":"proprietor_out","p":e.p,"victim":int(e.id)+1})

## Every calm guest runs (a shot anywhere in the house).
func panic() -> void:
	var any := false
	for c in civilians:
		if c.alive and c.state == "calm":
			_flee(c)
			any = true
	if any: events.append({"type":"panic"})

## A death in plain sight: the calm guests within CIVILIAN.startle who see it run.
func _startle(p: Vector2) -> void:
	for c in civilians:
		if c.alive and c.state == "calm" and (c.p as Vector2).distance_to(p) <= CIVILIAN.startle and can_see(c.p,p): _flee(c)

func _flee(c: Dictionary) -> void:
	if c.vip != "": return   # Jairo stays where he is, on the phone
	c.state = "flee"
	c.alerted = true   # out of the party pose
	c.repath = 0.0

func kill_civilian(c: Dictionary,direction := Vector2.ZERO,gun := "pistol") -> void:
	if not c.alive: return
	c.alive = false
	c.state = "dead"
	c.moving = false
	c.velocity = Vector2.ZERO
	c.death_age = 0.0
	civilians_killed += 1
	c.gore = gore_variant(gun,gore_rng) if direction != Vector2.ZERO else ""
	events.append({"type":"blood","p":c.p,"direction":direction if direction != Vector2.ZERO else Vector2.from_angle(player.angle),"player":false,"victim":-1,
		"guest":int(c.id),"civilian":true,"gore_allowed":direction != Vector2.ZERO,"gore":c.gore,"weapon":gun,"kind":"human"})
	if c.vip != "": events.append({"type":"vip_down","p":c.p,"vip":c.vip})
	_startle(c.p)

## The breaker trips: the lamps go out until the retry.
func trip() -> void:
	if breaker.is_empty() or not breaker.alive: return
	breaker.alive = false
	dark = true
	events.append({"type":"blackout","p":breaker.p})

## Jairo, alive? (true where there is no Jairo)
func vip_alive(name := "jairo") -> bool:
	return civilians.all(func(c): return c.vip != name or c.alive)

func _update_civilians(dt: float) -> void:
	for c in civilians:
		c.moving = false
		c.velocity = Vector2.ZERO
		if not c.alive:
			if c.state == "dead": c.death_age += dt
			continue
		if c.state != "flee": continue
		var goal := point(layout.flee[0])
		for spot in layout.get("flee",[]):
			if (c.p as Vector2).distance_to(point(spot)) < (c.p as Vector2).distance_to(goal): goal = point(spot)
		if (c.p as Vector2).distance_to(goal) < CIVILIAN.arrive:
			c.alive = false
			c.state = "gone"
			events.append({"type":"civilian_escaped","p":c.p,"guest":int(c.id)})
			continue
		c.repath -= dt
		var waypoint := goal
		if wall_hit(c.p,goal,RADIUS+.04,true) != INF:
			if c.repath <= 0:
				c.route = path(c.p,goal); c.repath = CIVILIAN.repath
			while c.route.size() > 0 and (c.p as Vector2).distance_to(c.route[0]) < .15: c.route.remove_at(0)
			if c.route.is_empty(): continue
			waypoint = c.route[0]
		var step: Vector2 = waypoint-c.p
		var old: Vector2 = c.p
		move(c,step.limit_length(CIVILIAN.speed*dt))
		c.velocity = (c.p-old)/maxf(dt,.000001)
		c.moving = old.distance_squared_to(c.p) > .000001
		if c.moving: c.angle = step.angle()

## The night's boss rules ({} away from night twelve) and its stage.
func boss() -> Dictionary:
	return layout.get("boss",{})

func stage() -> int:
	return int(boss().get("stage",0))

func _evict(e: Dictionary) -> void:
	## What lived in the casca leaves it: from a torn one it comes apart at once; from a whole one
	## it flies off as a shadow-flame after another body, or fades if there is none in reach.
	if e.get("sindico",false) and stage() > 0:
		_sindico_leaves(e)
		return
	if e.gore != "":
		events.append({"type":"unravel","p":e.p,"victim":int(e.id)+1,"kind":e.kind})
		return
	var body := _nearest_body(e.p,e)
	wisps.append({"p":e.p,"kind":e.kind,"from":e,"target":body,"life":WISP.life if not body.is_empty() else WISP.fade,
		"speed":float(WISP.speed.get(e.kind,3.0))})
	events.append({"type":"wisp","p":e.p,"kind":e.kind,"victim":int(e.id)+1,"bound":not body.is_empty()})

## The Síndico's casca falls, torn or not. On the helipad that is the end of him; on the rally his
## flame runs for the elevator; in the count room it jumps to the nearest whole body in reach,
## or runs for the shaft when there is none.
func _sindico_leaves(e: Dictionary) -> void:
	if stage() == 3:
		events.append({"type":"sindico_down","p":e.p,"victim":int(e.id)+1})
		return
	var body: Dictionary = _nearest_body(e.p,e,float(boss().get("reach",0.0))) if stage() == 2 else {}
	wisps.append({"p":e.p,"kind":"proprietario","from":e,"target":body,"life":60.0,"sindico":true,"grab":stage() == 2,
		"reaction":float(e.reaction),"goal":point(boss().exit),"speed":float(boss().get("speed",4.0)) if stage() == 2 else 4.0})
	events.append({"type":"wisp","p":e.p,"kind":"proprietario","victim":int(e.id)+1,"bound":not body.is_empty(),"sindico":true})

func _whole(body: Dictionary) -> bool:
	## A body a shadow-flame can wear: a whole corpse, or a shell still in its bag.
	if body.has("torn"): return not body.torn and not body.used
	if body.has("civilian"): return body.state == "dead" and body.gore == "" and not body.used
	if body.has("bed"): return not body.used   # alive, asleep and whole
	return not body.alive and body.gore == ""

func _nearest_body(p: Vector2,skip: Dictionary = {},reach: float = WISP.reach) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = reach
	for body in enemies+shells+civilians+patients:
		if is_same(body,skip) or not _whole(body) or wisps.any(func(w): return is_same(w.target,body)): continue
		var distance := p.distance_to(body.p)
		if distance < best_distance: best = body; best_distance = distance
	return best

func break_camera(camera: Dictionary) -> void:
	if not camera.alive: return
	camera.alive = false
	camera.seeing = false
	events.append({"type":"camera_down","p":camera.p,"camera":cameras.find(camera)})

## Where a camera points now: its heading panned back and forth by `sweep` over `period`.
func camera_angle(camera: Dictionary) -> float:
	if camera.sweep <= 0: return camera.base
	return camera.base+camera.sweep*sin(TAU*elapsed/maxf(camera.period,.1))

func camera_sees(camera: Dictionary,p: Vector2) -> bool:
	## Range, cone and a clear line, like a man's eyes; but the spectre is no hiding from it.
	var to: Vector2 = p-camera.p
	return camera.alive and to.length() <= camera.range and absf(angle_difference(camera.angle,to.angle())) <= camera.fov and can_see(camera.p,p)

func _update_cameras() -> void:
	for camera in cameras:
		if not camera.alive: continue
		camera.angle = camera_angle(camera)
		var seeing := camera_sees(camera,player.p)
		if seeing and not camera.seeing: events.append({"type":"alarm","p":camera.p,"camera":cameras.find(camera)})
		camera.seeing = seeing
		if not seeing: continue
		for e in enemies:
			if e.alive: e.alerted = true; e.memory = 3.5; e.last_seen = player.p

func tear(shell: Dictionary) -> void:
	if shell.torn: return
	shell.torn = true
	events.append({"type":"tear","p":shell.p,"shell":shells.find(shell)})

func _update_wisps(dt: float) -> void:
	for i in range(wisps.size()-1,-1,-1):
		var w := wisps[i]
		# Mão do Avesso: as a spectre the hero can take hold of what lives there.
		if w.get("grab",true) and mods.get("hand",false) and player.phasing and (player.p as Vector2).distance_to(w.p) < WISP.grab:
			events.append({"type":"wisp_gone","p":w.p,"kind":w.kind,"grabbed":true,"sindico":w.get("sindico",false)})
			wisps.remove_at(i)
			continue
		w.life -= dt
		if not w.target.is_empty() and not _whole(w.target): w.target = _nearest_body(w.p,w.from,float(boss().get("reach",WISP.reach)) if w.get("sindico",false) else WISP.reach)   # torn on the way
		if w.target.is_empty() and w.has("goal"):
			# The Síndico with nowhere to go: straight through the walls to the way out, and gone.
			var out: Vector2 = (w.goal as Vector2)-w.p
			if out.length() <= w.speed*dt+.05:
				events.append({"type":"sindico_flees","p":w.goal})
				wisps.remove_at(i)
				continue
			w.p += out.normalized()*w.speed*dt
			continue
		if not w.target.is_empty():
			var to: Vector2 = w.target.p-w.p
			if to.length() <= w.speed*dt+.05:
				_rise(w)
				wisps.remove_at(i)
				continue
			w.p += to.normalized()*w.speed*dt
		if w.life <= 0:
			events.append({"type":"wisp_gone","p":w.p,"kind":w.kind,"grabbed":false})
			wisps.remove_at(i)

func _rise(w: Dictionary) -> void:
	## The body stands up occupied, a fresh enemy that already knows where the hero is.
	var body: Dictionary = w.target
	var e: Dictionary = body
	var spare: bool = body.has("torn")
	var guest: bool = body.has("civilian")
	var patient: bool = body.has("bed")
	if spare or guest or patient:
		# A bag's body, or a guest's: a new enemy where it lay, the old corpse leaves the stage.
		body.used = true
		e = actor(nearest_free(body.p),body.angle)
		e.merge({"id":enemies.size(),"patrol":[[body.p.x,body.p.y]],"patrol_index":0,"route":PackedVector2Array(),"repath":0.0,"gore":"","weapon":"pistol"})
		if patient: e.patient = true
		enemies.append(e)
	else:
		e.alive = true
		e.death_age = 0.0
		kills -= 1
	e.kind = w.kind
	e.merge({"phase_state":"","phase_t":0.0,"phase_cd":PROPRIETOR.first,"phase_goal":Vector2.ZERO,"phasing":false},true)
	e.reaction = WISP.reaction
	e.alerted = true
	e.memory = 3.5
	e.last_seen = player.p
	e.windup = 0.0
	# A body out of a bag first drops from it and crumples, then gets up like any corpse.
	e.rising = WISP.rise+(WISP.drop if spare or patient else 0.0)
	if w.get("sindico",false):
		# The Síndico again, a little quicker every time he gets up.
		e.sindico = true
		e.reaction = maxf(float(boss().floor),float(w.reaction)-float(boss().step))
		e.rising = float(boss().rise)
	e.cooldown = e.rising
	e.angle = (player.p-e.p).angle()
	events.append({"type":"rise","p":e.p,"kind":e.kind,"victim":int(e.id)+1,"spare":spare or patient,"guest":int(body.id) if guest else -1,"patient":int(body.id) if patient else -1,
		"style":String(body.get("style","")) if spare else "","name":String(body.get("name","")) if spare else "","sindico":e.get("sindico",false)})

## Stage 3: the Síndico without a casca walks straight for the hero, through anything; his touch
## outside the spectre is the end of him.
func _update_ghost(e: Dictionary,dt: float) -> void:
	if elapsed < float(boss().get("delay",0.0)): return
	var to: Vector2 = player.p-e.p
	var area := bounds.grow(-RADIUS)
	var old: Vector2 = e.p
	e.p = ((e.p as Vector2)+to.limit_length(float(boss().speed)*dt)).clamp(area.position,area.end)
	e.velocity = (e.p-old)/maxf(dt,.000001)
	e.moving = old.distance_squared_to(e.p) > .000001
	e.angle = to.angle()
	e.alerted = true
	if not player.phasing and to.length() < float(boss().touch): die(Vector2.ZERO,"sindico")

## The helipad's landing lights: each gives the spectre's breath back once.
func _update_pads() -> void:
	for i in pads.size():
		if pads[i].used or (player.p as Vector2).distance_to(pads[i].p) > PAD.reach: continue
		pads[i].used = true
		player.mana = minf(100.0,player.mana+PAD.mana)
		events.append({"type":"pad_used","p":pads[i].p,"pad":i})

func die(direction := Vector2.ZERO,gun := "pistol") -> void:
	if state != "playing" or player.phasing or god: return
	player.alive = false
	player.moving = false
	player.velocity = Vector2.ZERO
	state = "dead"
	var gore := gore_variant(gun,gore_rng) if direction != Vector2.ZERO else ""
	events.append({"type":"blood","p":player.p,"direction":direction,"player":true,"victim":0,"gore_allowed":direction != Vector2.ZERO,"gore":gore,"weapon":gun,"kind":"human"})

func phase(dt: float,wants: bool) -> void:
	if not wants: player.locked = false
	if player.phasing:
		if wants and player.mana > 0:
			player.mana = maxf(0,player.mana-float(mods.get("mana_drain",MANA_DRAIN))*dt)
			player.regen_delay = float(mods.get("regen_delay",.8))
			if player.mana > 0: return
			player.locked = true
		player.phasing = false
		player.p = nearest_free(player.p)
		# Corte de saída: back from the Avesso with the katana already cutting, landing in .1 s.
		if mods.get("exit_cut",false) and player.melee and player.cooldown <= 0:
			slash()
			player.swing = KATANA.strike-.1
	elif wants and not player.locked and player.mana >= 12:
		player.phasing = true
		player.mana = maxf(0,player.mana-float(mods.get("mana_drain",MANA_DRAIN))*dt)
		player.regen_delay = float(mods.get("regen_delay",.8))
		return
	player.regen_delay = maxf(0,player.regen_delay-dt)
	if player.regen_delay <= 0: player.mana = minf(100,player.mana+float(mods.get("mana_regen",MANA_REGEN))*dt)

func update(dt: float,input: Dictionary = {}) -> void:
	if state == "dead":
		player.death_age += dt
		for e in enemies:
			if not e.alive: e.death_age += dt
		return
	if state != "playing": return
	if dt > 1.0/60.0+.00001:
		var count := ceili(dt*60)
		for i in count: update(dt/count,input)
		return
	elapsed += dt
	player.cooldown = maxf(0,player.cooldown-dt)
	player.recoil = maxf(0,player.recoil-dt)
	if player.reload > 0:
		player.reload = maxf(0,player.reload-dt)
		if player.reload <= 0: player.ammo = stats().magazine
	var gun := stats()
	var spinning: bool = gun.spin > 0 and not player.melee and input.get("attack",false) and not player.phasing and player.reload <= 0
	player.spin = minf(gun.spin,player.spin+dt) if spinning else maxf(0,player.spin-dt*2)
	if input.has("aim"):
		var direction: Vector2 = input.aim-player.p
		if direction.length_squared() > .001: player.angle = direction.angle()
	phase(dt,bool(input.get("phase",false)))
	var previous_player_position: Vector2 = player.p
	var movement: Vector2 = input.get("move",Vector2.ZERO)
	movement = movement.limit_length()
	if gun.spin > 0 and not player.melee: movement *= 1.0-MINIGUN_DRAG*player.spin/gun.spin
	if player.phasing:
		var p: Vector2 = player.p+movement*SPEED*dt
		player.p = p.clamp(bounds.position+Vector2.ONE*RADIUS,bounds.end-Vector2.ONE*RADIUS)
	else: move(player,movement*SPEED*dt)
	player.velocity = (player.p-previous_player_position)/maxf(dt,.000001)
	player.moving = (player.velocity as Vector2).length_squared() > .0025
	if input.get("switch",false): switch_weapon()
	if input.get("reload",false): reload()
	if input.get("attack",false): attack()
	if player.swing >= 0:
		player.swing += dt
		if not player.struck and player.swing >= KATANA.strike:
			player.struck = true
			_strike()
		if player.swing > 2.0: player.swing = -1.0   # long after the recovery: back to guard
	for e in enemies:
		e.moving = false
		e.velocity = Vector2.ZERO
		e.recoil = maxf(0,e.recoil-dt)
		# Olho do Avesso: as a spectre the hero sees what lives in each casca.
		e.revealed = e.alive and player.phasing and mods.get("eye",false) and e.get("kind","human") != "human"
		if e.get("phase_state","") == "blink": e.revealed = fmod(elapsed,.1) < .05   # the violet flicker before it goes
		if not e.alive:
			e.death_age += dt
			continue
		if state != "playing": break
		if e.get("rising",0.0) > 0:   # a body getting up, occupied: it neither moves nor shoots yet
			e.rising = maxf(0,e.rising-dt)
			e.cooldown = maxf(0,e.cooldown-dt)
			continue
		if e.get("ghost",false):
			_update_ghost(e,dt)
			continue
		e.cooldown = maxf(0,e.cooldown-dt)
		if e.get("phase_state","") != "":
			_update_proprietor(e,dt)
			continue
		if e.has("phase_cd"): e.phase_cd = maxf(0,e.phase_cd-dt)
		e.repath -= dt
		var toward: Vector2 = player.p-e.p
		var distance := toward.length()
		var human: bool = e.get("kind","human") == "human"
		var sight: float = 9.75*(DARK.sight if dark and human else 1.0)
		var sees: bool = distance < sight and (e.alerted or distance < float(mods.get("notice",2.1)) or absf(wrapf(toward.angle()-e.angle,-PI,PI)) < 1.1) and can_see(e.p,player.p)
		# Véu: as a spectre the hero is out of sight of people; what lives in a casca still sees him.
		if sees and mods.get("veil",false) and player.phasing and e.get("kind","human") == "human": sees = false
		if sees:
			e.alerted = true; e.memory = 3.5; e.last_seen = player.p
		else:
			e.memory -= dt
			e.windup = maxf(0,e.windup-dt*2)
			if e.memory <= 0: e.alerted = false
		var goal: Vector2 = e.last_seen if e.alerted else point(e.patrol[e.patrol_index])
		if not e.alerted and (e.p as Vector2).distance_to(goal) < .2:
			e.patrol_index = (e.patrol_index+1)%e.patrol.size()
		if sees:
			e.angle = toward.angle()
			if e.cooldown <= 0: e.windup += dt
			if e.windup >= e.reaction*(DARK.reaction if dark and human else 1.0) and e.cooldown <= 0:
				shoot(e,"enemy",ENEMY_RIFLE if e.weapon == "rifle" else ENEMY_GUN); e.cooldown = 1.1; e.windup = 0.0
				blink(e)   # a Proprietário goes through right after it fires
		if not (sees and distance < 7.1) and (e.p as Vector2).distance_to(goal) > .16:
			var waypoint := goal
			if wall_hit(e.p,goal,RADIUS+.04,true) != INF:
				if e.repath <= 0:
					e.route = path(e.p,goal); e.repath = .45
				while e.route.size() > 0 and (e.p as Vector2).distance_to(e.route[0]) < .15: e.route.remove_at(0)
				if e.route.is_empty(): continue
				waypoint = e.route[0]
			var step: Vector2 = waypoint-e.p
			var old: Vector2 = e.p
			move(e,step.limit_length((2.15 if e.alerted else .925)*dt))
			e.velocity = (e.p-old)/maxf(dt,.000001)
			e.moving = old.distance_squared_to(e.p) > .000001
			if not sees and e.moving: e.angle = step.angle()
	for i in range(bullets.size()-1,-1,-1):
		var bullet := bullets[i]
		var a: Vector2 = bullet.p
		var b: Vector2 = a+bullet.v*dt
		var first := wall_hit(a,b)
		var target: Dictionary = {}
		var candidates: Array = enemies if bullet.team == "player" else [player]+civilians.filter(func(c): return c.vip != "")
		for candidate in candidates:
			if not candidate.alive or (candidate == player and player.phasing) or candidate.get("phasing",false) and candidate != player or candidate.get("ghost",false): continue
			var hit := segment_circle(a,b,candidate.p)
			if hit < first: first = hit; target = candidate
		if bullet.team == "player":
			# A hanging bag stops the hero's bullet and is torn by it.
			for shell in shells:
				if shell.torn: continue
				var hit := segment_circle(a,b,shell.p,.25)
				if hit < first: first = hit; target = shell
			for c in civilians:
				if not c.alive: continue
				var hit := segment_circle(a,b,c.p)
				if hit < first: first = hit; target = c
			for camera in cameras:
				if not camera.alive: continue
				var hit := segment_circle(a,b,camera.p,.25)
				if hit < first: first = hit; target = camera
			if not breaker.is_empty() and breaker.alive:
				var hit := segment_circle(a,b,breaker.p,DARK.hit)
				if hit < first: first = hit; target = breaker
		bullet.life -= dt
		var endpoint := a.lerp(b,first) if first != INF else b
		events.append({"type":"trace","a":a,"b":endpoint,"origin":bullet.origin,"direction":(bullet.v as Vector2).normalized(),"team":bullet.team,"shooter":bullet.shooter})
		if first != INF:
			if not target.is_empty():
				# The gun that fired travels with the bullet: the gore depends on it.
				if target.has("torn"): tear(target)
				elif target.has("sweep"): break_camera(target)
				elif target.has("breaker"): trip()
				elif target.has("civilian"): kill_civilian(target,(bullet.v as Vector2).normalized(),bullet.weapon)
				elif bullet.team == "player": kill(target,(bullet.v as Vector2).normalized(),bullet.weapon)
				elif god: events.append({"type":"impact","p":endpoint,"direction":-(bullet.v as Vector2).normalized(),"team":bullet.team})   # it glances off
				else: die((bullet.v as Vector2).normalized(),bullet.weapon)
			else: events.append({"type":"impact","p":endpoint,"direction":-(bullet.v as Vector2).normalized(),"team":bullet.team})
			bullets.remove_at(i)
		elif bullet.life <= 0: bullets.remove_at(i)
		else: bullet.p = b
	_update_civilians(dt)
	_update_wisps(dt)
	_update_cameras()
	_update_pads()
	_pick_clues()
	# The helipad is won the moment it is clear; every other night at its exit.
	if state == "playing" and cleared() and (exit_rect.has_point(player.p) or layout.get("win_on_clear",false)): state = "won"
