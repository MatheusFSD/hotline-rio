extends SceneTree
const Sim = preload("res://scripts/simulation.gd")
## Plays a level with the real inputs only. Level 1 by default; another with `-- --level=2`.
func _initialize() -> void:
	var level := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="): level = int(arg.get_slice("=",1))-1
	var s = Sim.new(level)
	s.reset()
	var route := PackedVector2Array()
	var goal := Vector2.INF
	var previous := Vector2.ZERO
	var stuck := 0
	for frame in 24000:
		if s.state in ["won","dead"]: break
		var target: Dictionary = {}
		var best := INF
		for e in s.enemies:
			if not e.alive: continue
			var d: float = (e.p as Vector2).distance_to(s.player.p)
			var score: float = d if s.can_see(s.player.p,e.p) else d+50
			if score < best: best = score; target = e
		# A camera in sight comes first: it would bring the whole floor down on him, spectre or not.
		for camera in s.cameras:
			var d: float = (camera.p as Vector2).distance_to(s.player.p)
			if camera.alive and d < 9.0 and s.can_see(s.player.p,camera.p) and d-1.0 < best: best = d-1.0; target = camera
		var aim: Vector2 = target.p if not target.is_empty() else s.exit_rect.get_center()
		# With everyone down, the required clue first: the exit stays dark until it is taken.
		if target.is_empty():
			for c in s.clues:
				if c.required and not c.taken and s.clue_spot(c) != Vector2.INF: aim = s.nearest_free(s.clue_spot(c))
		var visible: bool = not target.is_empty() and s.can_see(s.player.p,target.p)
		var next_goal: Vector2 = aim
		var movement := Vector2.ZERO
		if not visible or s.kills == s.enemies.size():
			if frame%20 == 0 or goal.distance_to(next_goal) > .8:
				route = s.path(s.player.p,next_goal)
				goal = next_goal
			while not route.is_empty() and (s.player.p as Vector2).distance_to(route[0]) < .16: route.remove_at(0)
			if not route.is_empty(): movement = (route[0]-s.player.p).normalized()
			elif s.can_see(s.player.p,next_goal): movement = (next_goal-s.player.p).normalized()
		# Never step into a camera's cone while it watches: wait for a sweeping one to pan away.
		var ahead: Vector2 = s.player.p+movement*.45
		if movement != Vector2.ZERO and s.cameras.any(func(c): return s.camera_sees(c,ahead) and not c.seeing): movement = Vector2.ZERO
		var danger := false
		for e in s.enemies:
			if e.alive and e.windup > e.reaction*.8: danger = true
		# Only use the actual game inputs. No teleports, forced kills or invulnerability.
		s.update(1.0/60,{"move":movement,"aim":aim,"attack":visible,"phase":danger and s.player.cooldown > .04})
		if previous.distance_to(s.player.p) < .001 and movement.length() > .1: stuck += 1
		else: stuck = 0
		previous = s.player.p
		if stuck > 300:
			print("BOT_STUCK ",s.player.p," goal=",goal," kills=",s.kills)
			break
	print("PLAYTHROUGH ",s.state," kills=",s.kills," time=",s.elapsed," position=",s.player.p)
	quit(0 if s.state == "won" else 1)
