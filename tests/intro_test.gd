extends SceneTree
const Intro = preload("res://scripts/intro.gd")
const Main = preload("res://scripts/main.gd")
var failures := 0
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var intro = Intro.new(Main.level_lamps(Main.Simulation.new().layout))
	root.add_child(intro)
	var ended := [false]
	intro.finished.connect(func(): ended[0] = true)
	check(intro.viewport.size == Vector2i(640,480) and intro.crt.shader != null,"Newscast renders at 640x480 through the CRT shader")
	for person in [intro.anchor,intro.witness,intro.cop]:
		check(person.player.get_animation_list().size() >= 2 and person.skeleton.get_bone_count() >= 60,"Cast member is rigged and animated")
	var clips: Array = ["Idle_Talking_Loop","Walk_Formal_Loop","Spell_Simple_Shoot","Idle_Loop"].map(func(clip): return Intro.clip_name(intro.anchor,clip))
	check(not clips.has(&"") and intro.anchor.player.get_animation(clips[0]).loop_mode == Animation.LOOP_LINEAR,"Anchor talks, walks and points: %s" % [intro.anchor.player.get_animation_list()])
	check(intro.anchor.skeleton.find_children("*","BoneAttachment3D",true,false).size() == 1,"Anchor wears a tie on the chest bone")
	var seen := {}
	var captions := {}
	var ghost_start: Vector2 = intro.ghost_data.p
	var ghost_moved := false
	var anchor_clips := {}
	var mosaic_on_screen := false
	var siren_flashes := 0
	var last_siren := -1.0
	while intro.time < Intro.POWER_OFF-.05:
		intro.advance(1.0/30)
		seen[intro.current_shot] = true
		if intro.caption.text != "": captions[intro.caption.text] = true
		if intro.anchor.player.is_playing(): anchor_clips[intro.anchor.player.current_animation] = true
		if intro.current_shot == "cctv" and (intro.ghost_data.p as Vector2).distance_to(ghost_start) > 2.5: ghost_moved = true
		if intro.mosaic.visible and Rect2(Vector2.ZERO,Vector2(640,480)).has_point(intro.mosaic.position+intro.mosaic.size/2): mosaic_on_screen = true
		if intro.sirens[0].light_energy != last_siren: siren_flashes += 1; last_siren = intro.sirens[0].light_energy
	check(seen.size() == Intro.SHOTS.size(),"Every shot plays: %s" % [seen.keys()])
	check(captions.size() == Intro.CAPTIONS.size(),"Every caption line appears")
	check(anchor_clips.size() >= 3,"Anchor walks, talks and points during the bulletin: %s" % [anchor_clips.keys()])
	check(ghost_moved and intro.ghost.phasing,"Security camera shows the spectre crossing the bar")
	check(mosaic_on_screen,"Witness face is pixelated on screen")
	check(siren_flashes > 20,"Police lights flash")
	check(not ended[0],"Newscast still running before power-off")
	intro.skip()
	var dated := false
	for i in 150:
		if ended[0]: break
		intro.advance(1.0/30)
		if intro.epilogue.visible and intro.epilogue_line.visible_ratio >= 1.0: dated = true
	check(dated,"The set goes dark on the date: fourteen days after the alley")
	check(ended[0],"Set switches off and finishes")
	var second = Intro.new(Main.level_lamps(Main.Simulation.new().layout))
	root.add_child(second)
	var skipped := [false]
	second.finished.connect(func(): skipped[0] = true)
	second.advance(2.0)
	second.skip()
	check(is_equal_approx(second.time,Intro.POWER_OFF),"First skip jumps to the power-off")
	second.skip()
	check(skipped[0],"Second skip leaves at once")
	# A real launch (main as the current scene) opens with the newscast over the briefing.
	change_scene_to_file("res://scenes/main.tscn")
	for i in 3: await process_frame
	var opening: Array = current_scene.find_children("*","LapaIntro",false,false) if current_scene else []
	check(opening.size() == 1 and current_scene.overlay.visible and current_scene.sim.state == "ready","Game launch plays the newscast before the briefing")
	await process_frame
	print("INTRO: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
