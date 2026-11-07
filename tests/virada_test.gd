extends SceneTree
## The special report closing Act 1 (assets/news/virada_1_tv.json), watched on the TV in Caio's room.
const Intro = preload("res://scripts/intro.gd")
const Campaign = preload("res://scripts/campaign.gd")
const PROGRAM := "res://assets/news/virada_1_tv.json"
var failures := 0
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	Campaign.state = Campaign.fresh()
	Campaign.state.unlocks.append_array(["smg","shotgun"])
	Campaign.state.clues.append("caderno_taxa")
	var report = Intro.new([],PROGRAM)
	root.add_child(report)
	var ended := [false]
	report.finished.connect(func(): ended[0] = true)
	# Its sets and people, nothing of the opening's.
	check(report.viewport.find_child("Lapa_bar_ceiling",true,false) == null and report.witness.is_empty(),"None of the opening's sets: no bar, no witness")
	for person in [report.castelar,report.cadaver,report.perito,report.souza,report.anchor]:
		check(not person.is_empty() and person.skeleton.get_bone_count() >= 60,"Cast member is rigged")
	check(report.set_sound.stream.resource_path.ends_with("virada_1.ogg") and absf(report.set_sound.stream.get_length()-report.power_off) < .5,"Its own soundtrack, as long as the programme")
	# The room as the campaign stands: the guns earned, the clue found, Caio in the chair.
	var guns: Array = report.room.find_children("Weapon_*","Node3D",true,false).filter(func(n): return n.is_visible_in_tree()).map(func(n): return String(n.name).trim_prefix("Weapon_"))
	check(guns.size() == 3 and "shotgun" in guns,"The rack shows what Caio has by now: %s" % [guns])
	check(report.room.find_child("Clue_caderno_taxa",true,false).is_visible_in_tree(),"The board shows the clues found")
	check(String(report.caio.player.current_animation).begins_with("Sitting"),"Caio watches from the desk chair")
	# Every word translatable.
	var english: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/lang/en.json"))
	var words: Array = report.lines.map(func(l): return l[3])+report.speakers.values()+report.shots.map(func(s): return s[2]).filter(func(h): return h != "")+[report.plan.ticker,report.plan.bug]
	var missing: Array = words.filter(func(w): return not english.has(w))
	check(missing.is_empty(),"Every line, speaker, headline and the ticker has its English: missing %s" % [missing])
	var seen := {}
	var said := {}
	var floor_seen := false
	var loki_outside := false
	var typed := ""
	var cadaver_start: Vector3 = report.cadaver.node.position
	var walked := false
	while report.time < report.power_off-.05:
		report.advance(1.0/30)
		seen[report.current_shot] = true
		if report.caption.text != "": said[report.caption.text] = report.speaker.text
		# Castelar from the waist up only: the floor at his feet is never in the picture.
		if report.current_shot in ["press","press_close"]:
			for at in [Vector3(0,0,0),Vector3(.3,0,.25),Vector3(-.3,0,.25)]:
				if report.camera.is_position_in_frustum(Intro.PRESS+Intro.CASTELAR_MARK+at): floor_seen = true
		if report.loki.visible != (report.current_shot == "loki"): loki_outside = true
		if report.current_shot == "loki":
			typed = report.loki_message.text
			if (report.cadaver.node.position-cadaver_start).length() > 2.0: walked = true
	check(seen.size() == report.shots.size(),"Every shot plays: %s" % [seen.keys()])
	check(said.size() == report.lines.size(),"Every line is subtitled")
	check(said.get("ORDEM NA CASA.") == "ÁLVARO CASTELAR" and said.get("OLHA O CHÃO DEBAIXO DELE. NÃO TEM SOMBRA.  — C.") == "MARÉ","Subtitles name who speaks: %s" % [said])
	check(not floor_seen,"Castelar is only ever framed from the waist up")
	check(not loki_outside,"LOKI is on the screen only once the computer comes on")
	check(typed == "OLHA O CHÃO DEBAIXO DELE. NÃO TEM SOMBRA.  — C.","MARÉ's message is typed out on her page")
	# The IML: the tubes cast shadows, the body that walks out of the drawer does not.
	var shadow_lights: Array = report.viewport.find_children("*","SpotLight3D",true,false).filter(func(l): return l.shadow_enabled)
	var casts: Array = report.cadaver.node.find_children("*","MeshInstance3D",true,false).map(func(m): return m.cast_shadow)
	check(shadow_lights.size() >= 4 and casts.all(func(c): return c == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF),"In the corridor everything casts a shadow but him")
	check(walked and report.cadaver.player.current_animation.begins_with("Zombie"),"He walks out of the drawer toward the camera, and stops")
	# His path, shoulders and swinging arms included, crosses nothing: not the tray, not the gurney.
	var lane := AABB(Intro.IML+Vector3(Intro.CADAVER_START.x-.32,.05,Intro.CADAVER_START.z-.3),Vector3(.64,1.8,Intro.CADAVER_STOP-Intro.CADAVER_START.z+.6))
	var blocking := []
	for mesh in report.viewport.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh == null or report.cadaver.node.is_ancestor_of(mesh) or not lane.intersects(mesh.global_transform*mesh.get_aabb()): continue
		var faces: PackedVector3Array = mesh.mesh.get_faces()
		for f in range(0,faces.size(),3):
			var a: Vector3 = mesh.global_transform*faces[f]
			var b: Vector3 = mesh.global_transform*faces[f+1]
			var c: Vector3 = mesh.global_transform*faces[f+2]
			var hit := false
			for u in 11:
				for v in 11-u:
					if lane.has_point(a+(b-a)*(u/10.0)+(c-a)*(v/10.0)): hit = true
			if hit: blocking.append(String(mesh.name)); break
	check(blocking.is_empty(),"Nothing stands in his way down the corridor: %s" % [blocking])
	check(report.hand_glow_at(report.time) == 0.0 and not report.reflects and report.epilogue_at == INF,"No reflection, no card: that is the opening's")
	report.skip()
	for i in 120:
		if ended[0]: break
		report.advance(1.0/30)
	check(ended[0],"The set goes off and the story goes on")
	# The act's end plays it: past the card, the broadcast instead of the flat newscast.
	var level: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/level_4.json"))
	check(level.act_end.get("broadcast","") == PROGRAM,"Act 1's last night ends on this broadcast")
	var game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game.load_level(3)
	game.act_card = Node.new()
	game.add_child(game.act_card)
	game._close_act()
	check(game.news is Intro and game.news.plan.get("bug","") == "PLANTÃO ESPECIAL","After the act's card, the special report comes on in 3D")
	game.queue_free()
	await process_frame
	print("VIRADA: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
