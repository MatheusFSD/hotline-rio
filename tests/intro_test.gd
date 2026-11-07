extends SceneTree
const Intro = preload("res://scripts/intro.gd")
const Main = preload("res://scripts/main.gd")
const Lang = preload("res://scripts/lang.gd")
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
	# Caio's own room: the TV on his desk wears the newscast on its glass, through the tube's shader.
	var through: TextureRect = intro.tube.get_child(0)
	check(through.texture == intro.viewport.get_texture() and through.material == intro.crt,"The tube runs the newscast through the CRT shader")
	var glass: Array = intro.room.find_children("*","MeshInstance3D",true,false).filter(func(node):
		for surface in node.mesh.get_surface_count():
			if node.get_surface_override_material(surface) == intro.screen_material: return true
		return false)
	check(glass.size() == 1 and glass[0].name.begins_with("Hotspot_pc") and intro.screen_material.get_shader_parameter("picture") == intro.tube.get_texture(),"The picture is on the glass of the TV on Caio's desk")
	check(intro.room_camera.current and intro.room_camera.global_position.distance_to(Intro.ROOM_VIEW[0]) < .05,"It starts from the room's own view")
	var visible_guns: Array = intro.room.find_children("Weapon_*","Node3D",true,false).filter(func(n): return n.is_visible_in_tree()).map(func(n): return String(n.name))
	check(visible_guns.size() == 1 and visible_guns[0].begins_with("Weapon_pistol"),"On 26 October only the pistol from the alley is on the rack: %s" % [visible_guns])
	check(String(intro.caio.player.current_animation).begins_with("Sitting") and Vector2(intro.caio.node.position.x,intro.caio.node.position.z).distance_to(Vector2(intro.screen_centre.x,intro.screen_centre.z)) < 1.0,"Caio sits at the desk in front of the TV")
	var sofa: Vector3 = intro.room_camera.global_position
	check(intro.viewport.find_child("Lapa_bar_ceiling",true,false) != null,"The bar has its ceiling and its walls back for the news cameras")
	# Sound: the set's track from the click on, the room around it.
	check(intro.set_sound.stream.resource_path.ends_with("plantao.ogg") and intro.set_sound.playing,"The set's sound starts with the picture")
	check(absf(intro.set_sound.stream.get_length()-Intro.POWER_OFF) < .5,"…and runs until the set goes off (%.1f s)" % intro.set_sound.stream.get_length())
	check(intro.room_sound.playing and intro.room_sound.stream.loop,"The room hums around it, looping")
	# Every word on the set can be translated: lines, who says them, headlines, ticker.
	var english: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/lang/en.json"))
	var words: Array = Intro.CAPTIONS.map(func(l): return l[3])+Intro.SPEAKERS.values()+Intro.SHOTS.map(func(s): return s[2]).filter(func(h): return h != "")+[Intro.TICKER]
	var missing: Array = words.filter(func(w): return not english.has(w))
	check(missing.is_empty(),"Every line, speaker, headline and the ticker has its English: missing %s" % [missing])
	check(Intro.CAPTIONS.all(func(l): return Intro.SPEAKERS.has(l[2])),"Every line has a speaker")
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
	var subtitle_lies := false
	while intro.time < Intro.POWER_OFF-.05:
		intro.advance(1.0/30)
		seen[intro.current_shot] = true
		if intro.caption.text != "": captions[intro.caption.text] = intro.speaker.text
		if intro.subtitle.visible != (intro.caption.text != ""): subtitle_lies = true
		if intro.anchor.player.is_playing(): anchor_clips[intro.anchor.player.current_animation] = true
		if intro.current_shot == "cctv" and (intro.ghost_data.p as Vector2).distance_to(ghost_start) > 2.5: ghost_moved = true
		if intro.mosaic.visible and Rect2(Vector2.ZERO,Vector2(640,480)).has_point(intro.mosaic.position+intro.mosaic.size/2): mosaic_on_screen = true
		if intro.sirens[0].light_energy != last_siren: siren_flashes += 1; last_siren = intro.sirens[0].light_energy
	check(seen.size() == Intro.SHOTS.size(),"Every shot plays: %s" % [seen.keys()])
	check(captions.size() == Intro.CAPTIONS.size(),"Every caption line appears")
	check(captions.get("ELE PASSOU PELA PAREDE, MOÇO! TAVA TODO AZUL!") == "TESTEMUNHA" and captions.get("ÁREA ISOLADA. SÃO OITO CORPOS LÁ DENTRO. NINGUÉM VIU O ATIRADOR.") == "TEN. ELIAS SOUZA","Subtitles name who speaks: %s" % [captions])
	check(not subtitle_lies,"The subtitle shows only while someone talks")
	var to_glass: float = (intro.room_camera.global_position-intro.screen_centre).dot(intro.screen_normal)
	check(intro.room_camera.global_position.distance_to(sofa) > 3.0 and to_glass < .8 and intro.room_camera.global_position.distance_to(intro.caio.node.position) > .25,"The camera goes past him up to the glass (%.2f m from it)" % to_glass)
	check(intro.screen_material.get_shader_parameter("reflection") == 0.0 and intro.hand_glow_at(intro.time) == 0.0,"No reflection, no glow while the set is on")
	check(intro.set_sound.playing and not intro.off_sound.playing,"Still on the air before the power-off")
	check(anchor_clips.size() >= 3,"Anchor walks, talks and points during the bulletin: %s" % [anchor_clips.keys()])
	check(ghost_moved and intro.ghost.phasing,"Security camera shows the spectre crossing the bar")
	check(mosaic_on_screen,"Witness face is pixelated on screen")
	check(siren_flashes > 20,"Police lights flash")
	check(not ended[0],"Newscast still running before power-off")
	intro.skip()
	var dated := false
	var reflected := 0.0
	var glowed := 0.0
	var glow_after_calm := 0.0
	var off_checked := false
	for i in 400:
		if ended[0]: break
		intro.advance(1.0/30)
		if not off_checked and intro.time > Intro.POWER_OFF+.2:
			off_checked = true
			check(not intro.set_sound.playing and intro.off_sound.playing and intro.after_sound.playing,"Off: the set's sound stops, the tube zaps, he breathes")
		reflected = maxf(reflected,intro.screen_material.get_shader_parameter("reflection"))
		glowed = maxf(glowed,intro.hand_glow_at(intro.time))
		if intro.time > Intro.POWER_OFF+float(Intro.AFTER.calm): glow_after_calm = maxf(glow_after_calm,intro.hand_glow_at(intro.time))
		if intro.epilogue.visible and intro.epilogue_line.visible_ratio >= 1.0: dated = true
	check(reflected > .99 and intro.mirror_camera.projection == Camera3D.PROJECTION_FRUSTUM,"The dark glass reflects him, through a camera mirrored in it")
	check(glowed > .99 and glow_after_calm == 0.0,"His hand glows from the Avesso, then calms")
	check(dated and intro.epilogue_line.text == Intro.EPILOGUE and "DUAS HORAS ANTES" in Intro.EPILOGUE,"Then the card: two hours earlier, back to the bar")
	check(ended[0],"Set switches off and finishes")
	var second = Intro.new(Main.level_lamps(Main.Simulation.new().layout))
	root.add_child(second)
	var skipped := [false]
	second.finished.connect(func(): skipped[0] = true)
	second.advance(2.0)
	second.skip()
	check(is_equal_approx(second.time,Intro.POWER_OFF),"First skip jumps to the power-off")
	second.advance(.01)
	check(not second.set_sound.playing and second.off_sound.playing,"…and the set's sound goes with it")
	check(second.time < Intro.EPILOGUE_AT,"…still showing the reflection before the card")
	second.skip()
	check(skipped[0],"Second skip leaves at once")
	# In English the subtitles are English, with the speaker's name too.
	Lang.setup()
	TranslationServer.set_locale("en")
	var abroad = Intro.new(Main.level_lamps(Main.Simulation.new().layout))
	root.add_child(abroad)
	abroad.advance(18.0)
	check(abroad.caption.text == "HE WENT THROUGH THE WALL, MISTER! ALL BLUE!" and abroad.speaker.text == "WITNESS","Subtitles follow the language: %s / %s" % [abroad.speaker.text,abroad.caption.text])
	abroad.queue_free()
	TranslationServer.set_locale("pt")
	# A real launch (main as the current scene) opens with the newscast over the briefing.
	change_scene_to_file("res://scenes/main.tscn")
	for i in 3: await process_frame
	var opening: Array = current_scene.find_children("*","LapaIntro",false,false) if current_scene else []
	check(opening.size() == 1 and current_scene.overlay.visible and current_scene.sim.state == "ready","Game launch plays the newscast before the briefing")
	await process_frame
	print("INTRO: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
