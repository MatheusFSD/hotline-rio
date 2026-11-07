extends SceneTree
## Every night: level data, a sound and playable floor plan, and main.gd swapping whole levels in
## and out (scenery, lamps, collision, cast, exit, briefing, HUD hint, win title, mission order).
const Sim = preload("res://scripts/simulation.gd")
## Per level: scenery file, enemies, materials that must be there, title, and where the exit lies.
const EXPECT := [
	{"scene":"lapa.glb","enemies":8,"materials":["Lapa_vermelhao","Lapa_arcos"],"title":"ÚLTIMO GOLE","cleared":"BAR LIMPO","exit":"right"},
	{"scene":"lavradio.glb","enemies":11,"materials":["Lapa_tacos","Lapa_velvet","Lapa_felt"],"title":"ÚLTIMA DANÇA","cleared":"SALÃO LIMPO","exit":"left"},
	{"scene":"ateliers.glb","enemies":12,"materials":["Lapa_ladrilho","Lapa_atelier_floor","Lapa_grass","Lapa_paintings","Lapa_paralelepipedo"],"title":"ÚLTIMA DEMÃO","cleared":"ATELIÊ LIMPO","exit":"back"},
	{"scene":"bondes.glb","enemies":13,"materials":["Lapa_bonde","Lapa_rail","Lapa_oil_concrete","Lapa_paralelepipedo"],"title":"ÚLTIMO BONDE","cleared":"GALPÃO LIMPO","exit":"right"},
	{"scene":"caju.glb","enemies":12,"materials":["Lapa_frost","Lapa_isopainel","Lapa_oil_concrete","Lapa_bay"],"title":"ÚLTIMA CARGA","cleared":"CÂMARA FRIA LIMPA","exit":"back"},
	{"scene":"guardiao.glb","enemies":14,"materials":["Lapa_carpete","Lapa_granilite","Lapa_tacos"],"frame_materials":["Lapa_guardiao_facade","Lapa_guardiao_roof","Lapa_guardiao_road"],"title":"ÚLTIMO TURNO","cleared":"CENTRAL DESLIGADA","exit":"left"},
	{"scene":"lagoa.glb","enemies":14,"materials":["Lapa_deck","Lapa_granilite","Lapa_grass"],"frame_materials":["Lapa_lagoa_water","Lapa_lagoa_stone","Lapa_lagoa_hill"],"title":"ÚLTIMO LANCE","cleared":"LEILÃO ENCERRADO","exit":"right"},
	{"scene":"ilha.glb","enemies":15,"materials":["Lapa_parquet","Lapa_granilite","Lapa_ilha_water"],"frame_materials":["Lapa_ilha_green","Lapa_ilha_stone","Lapa_ilha_roof"],"title":"ÚLTIMO BAILE","cleared":"BAILE ENCERRADO","exit":"right"},
	{"scene":"telerio.glb","enemies":14,"materials":["Lapa_carpete","Lapa_studio_floor","Lapa_oil_concrete"],"frame_materials":["Lapa_side_cream","Lapa_side_roof","Lapa_t9_road","Lapa_t9_blue","Lapa_t9_steel"],"title":"ÚLTIMO PLANTÃO","cleared":"SAINDO DO AR","exit":"right"},
	{"scene":"joa.glb","enemies":15,"materials":["Lapa_porcelanato","Lapa_deck","Lapa_pane"],"frame_materials":["Lapa_joa_rock","Lapa_joa_green","Lapa_joa_trail","Lapa_joa_sea"],"title":"ÚLTIMA VISTA","cleared":"CONDOMÍNIO DESPEJADO","exit":"left"},
	{"scene":"clinica.glb","enemies":14,"materials":["Lapa_vinil","Lapa_marble","Lapa_granilite"],"frame_materials":["Lapa_side_cream","Lapa_side_roof","Lapa_c11_ochre","Lapa_c11_facade","Lapa_c11_roof"],"title":"ÚLTIMA CONSULTA","cleared":"ALTA DADA","exit":"right"},
	{"scene":"marques_comicio.glb","enemies":9,"materials":["Lapa_stage_floor","Lapa_pedra"],"title":"ÚLTIMA PROMESSA","cleared":"CASCA DE 1977 NO CHÃO","exit":"back"},
	{"scene":"marques_apuracao.glb","enemies":7,"materials":["Lapa_carpete","Lapa_concrete"],"title":"ÚLTIMA APURAÇÃO","cleared":"SALA DE APURAÇÃO LIMPA","exit":"back"},
	{"scene":"marques_heliponto.glb","enemies":1,"materials":["Lapa_helipad","Lapa_yellow_paint"],"title":"ÚLTIMO AR","cleared":"ORDEM NA CASA","exit":"back"}]
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
## The Síndico's stages: kill everyone, then again whoever he gets up in, until his flame is gone.
func defeat(game) -> void:
	game.sim.god = true
	for round in 12:
		for e in game.sim.enemies: if e.alive: game.sim.kill(e,Vector2.RIGHT,"katana")
		for i in 300:
			game.sim.update(1.0/60,{})
			if game.sim.wisps.is_empty() and game.sim.enemies.all(func(e): return not e.alive or e.get("rising",0.0) <= 0): break
		if game.sim.cleared(): return

func run() -> void:
	check(Sim.LEVELS.size() == EXPECT.size(),"Twelve nights, the last in three stages")
	for index in Sim.LEVELS.size():
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Sim.LEVELS[index]))
		var name := "Level %d" % (index+1)
		var keys := ["scene","briefing","cleared","exit_hint","mission","lamps","bounds","start","entrance","exit","solids","enemies"]
		check(keys.all(func(k): return data.has(k)),"%s describes a whole level" % name)
		check(ResourceLoader.exists(data.scene) and data.scene.ends_with(EXPECT[index].scene),"%s points at its scenery" % name)
		check(data.lamps.size() <= 7,"%s keeps to 7 lamps: with the exit light, 8 per object in Compatibility" % name)
		var night := int(data.get("night",index+1))   # the Síndico's three stages are all night twelve
		check(data.briefing.place.begins_with("%02d" % night) and data.mission.begins_with("%02d" % night),"%s is numbered in its briefing and mission" % name)
		# A sound floor plan: nobody starts in a wall, every patrol stop is free, all of it is reachable.
		var s = Sim.new(index)
		check(s.enemies.size() == EXPECT[index].enemies,"%s has %d enemies" % [name,EXPECT[index].enemies])
		var start: Vector2 = s.player.p
		for e in s.enemies:
			check(not s.blocked(Sim.point(s.layout.enemies[e.id].p)),"%s: enemy %d starts on open floor" % [name,e.id])
			for stop in e.patrol: check(not s.blocked(Sim.point(stop)),"%s: enemy %d patrols open floor (%s)" % [name,e.id,stop])
			check(s.path(start,e.p).size() > 1,"%s: the hero can walk to enemy %d" % [name,e.id])
			check(e.has("id") and ["arms","drink","phone","hold"].has(String(s.layout.enemies[e.id].get("pose",""))),"%s: enemy %d has an everyday pose" % [name,e.id])
		# Guests (the Lagoa party) stand on open floor and can reach a way out.
		for c in s.civilians:
			check(not s.blocked(c.p) and s.layout.flee.any(func(f): return s.path(c.p,Sim.point(f)).size() > 1),"%s: guest %d stands free and can run out" % [name,c.id])
		var exit: Rect2 = s.exit_rect
		check(s.path(start,exit.get_center()).size() > 1 and s.bounds.encloses(exit),"%s: the exit is inside the level and reachable" % name)
		var side: String = "left" if exit.get_center().x < -12 else "right" if exit.get_center().x > 12 else "back" if exit.get_center().y < -7.75 else "?"
		check(side == EXPECT[index].exit,"%s: the exit is out the %s" % [name,EXPECT[index].exit])
		var arrow: String = data.exit_hint
		check((side == "left" and arrow.begins_with("←")) or (side == "right" and arrow.ends_with("→")) or (side == "back" and arrow.begins_with("↑")),"%s: the HUD hint points to the exit (%s)" % [name,arrow])
		var walls: Array = s.layout.solids.filter(func(w): return w.type == "wall")
		var tall: Array = walls.filter(func(w): return w.h > 1.4)
		check(tall.size() == 1 and tall[0].r[1] == -7.75 and walls.all(func(w): return w.h in [1.4,2.5]),"%s: same cut as the bar, one full back wall and every other wall at 1.4 m" % name)
	# Swapping levels in the running game.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var previous: Node = game.level_nodes[0]
	for index in range(1,EXPECT.size()):
		var name := "Level %d" % (index+1)
		game.load_level(index)
		await process_frame
		check(not is_instance_valid(previous),"%s: the previous scenery leaves the stage" % name)
		var scenery: Node = game.level_nodes[0]
		previous = scenery
		check(scenery.scene_file_path.ends_with(EXPECT[index].scene),"%s: its scenery is on stage" % name)
		var names := {}
		for mesh in scenery.find_children("*","MeshInstance3D",true,false):
			for i in mesh.mesh.get_surface_count():
				var mat: Material = mesh.mesh.surface_get_material(i)
				if mat: names[mat.resource_name] = mat
		check(not names.has("Lapa_arcos"),"%s: no Arcos away from the bar" % name)
		check(EXPECT[index].materials.all(func(m): return names.has(m)),"%s: its own floors and props are there (%s)" % [name,EXPECT[index].materials])
		var frame_materials: Array = EXPECT[index].get("frame_materials",["Lapa_side_cream","Lapa_side_roof"])
		check(frame_materials.all(func(m): return names.has(m)),"%s: the exterior has its own frame materials" % name)
		var floor_name: String = EXPECT[index].materials[0]
		check(names.has(floor_name) and names[floor_name].next_pass != null,"%s: the PS1 shading pass reaches the new scenery" % name)
		check(game.level_nodes.filter(func(n): return n is OmniLight3D).size() == game.sim.layout.lamps.size(),"%s: its own lamps" % name)
		check(game.level_nodes.filter(func(n): return n is StaticBody3D).size() == game.sim.layout.solids.size(),"%s: its own collision" % name)
		check(game.actors.size() == EXPECT[index].enemies+1 and game.actors.slice(1).all(func(a): return a.pose != ""),"%s: its cast, each in an everyday pose" % name)
		check(Vector2(game.exit_marker.position.x,game.exit_marker.position.z).distance_to(game.sim.exit_rect.get_center()) < .01,"%s: the exit light marks its exit" % name)
		check(game.overlay.visible and game.overlay_title.text == EXPECT[index].title and game.overlay_place.text.begins_with("%02d" % int(game.sim.layout.get("night",index+1))),"%s: the briefing is its own" % name)
		check(game.scenery_bounds.size.x > 30 and game.scenery_bounds.position.z < -12,"%s: scenery bounds come from the new scenery" % name)
		# Play it: clear, the HUD points at the exit, reaching it wins, the win screen names the place.
		game.start_or_resume()
		# The katana tears every casca: no shadow-flame left holding the exit.
		if game.sim.layout.has("boss"): await defeat(game)
		else: for e in game.sim.enemies: game.sim.kill(e,Vector2.RIGHT,"katana")
		game.update_ui()
		if not game.sim.clues.is_empty():
			check(game.hud.objective.text == "PEGUE A PISTA","%s: everyone down, the night still holds its clue" % name)
			game.sim.player.p = game.sim.exit_rect.get_center()
			game.sim.update(1.0/60,{})
			check(game.sim.state == "playing","%s: the exit waits for the clue" % name)
			for c in game.sim.clues: c.taken = true
			game.update_ui()
		if game.sim.state == "playing":
			check(game.hud.objective.text == game.sim.layout.exit_hint,"%s: cleared, the HUD shows the way out" % name)
			game.sim.player.p = game.sim.exit_rect.get_center()
		game.sim.update(1.0/60,{})
		check(game.sim.state == "won","%s: %s" % [name,"cleared, the helipad is won" if game.sim.layout.get("win_on_clear",false) else "reaching the exit wins"])
		game.update_ui()
		if game.sim.layout.get("chain",false):
			# A stage of the Síndico goes straight on to the next, with no screen or room between.
			await process_frame
			check(not game.results.visible and game.sim.level == index+1 and game.overlay_title.text == EXPECT[index+1].title,"%s: the next stage follows at once" % name)
			check(game.hud.rec.visible,"%s: on air, the REC light on" % name)
			previous = game.level_nodes[0]
			continue
		check(game.results.visible and game.results.title_text == EXPECT[index].cleared,"%s: the win screen says %s" % [name,EXPECT[index].cleared])
		game.results.hide_screen()
		if game.sim.layout.get("act_end",{}).get("finale",false):
			# The end: the Síndico's card, the room with only the TV and the window, then the ending.
			game.start_or_resume()
			check(game.act_card != null and game.act_card.screen.title.text == "SEM SOMBRA" and game.room == null,"The Síndico down: his card before the room")
			game.act_card.confirmed.emit()
			await process_frame
			check(game.room != null and game.room.summary.get("finale",false) and game.room.spots.keys() == ["Hotspot_pc","City"],"The last room: only the TV and the window")
			game.room.click("Hotspot_pc")
			await process_frame
			check(game.news != null and game.news.data.segments[0].headline.begins_with("OLHA O CHÃO") and game.news.data.segments.size() == 3,"Jairo alive and every proof found: Final A on the TV, with Souza")
			while game.news and not game.news.done: game.news.advance(1.0/30)
			await process_frame
			previous = game.level_nodes[0]
			continue
		# The room leads to the next night, and after the last one back to the first.
		game.start_or_resume()
		check(game.room != null and game.room.summary.level == index,"%s: winning opens the room" % name)
		game.room.next_night.emit()
		await process_frame
		# The station closes act 1 before anything else comes; the last night made so far says the story goes on.
		var closes: bool = index in [3,7]
		check((game.act_card != null) == closes,"%s: %s" % [name,"a card closes the night" if closes else "the act goes on"])
		if game.act_card and index == 7:
			# The ball closes act 2: Castelar's goodnight, then its newscast, one segment chosen by the guests killed.
			check(game.act_card.screen.title.text == "BOA NOITE, INQUILINO" and not game.sim.layout.act_end.get("menu",false) and game.act_card.screen.tip.text.contains("ATO 3"),"The end of act 2 says goodnight and goes on to act 3")
			game.act_card.confirmed.emit()
			await process_frame
			check(game.news != null and game.news.data.segments.size() == 3,"Act 2's newscast: three segments")
			var told := {}
			while game.news and not game.news.done:
				told[game.news.headline.text] = true
				game.news.advance(1.0/30)
			check(told.has("GARÇONS ESCAPAM ILESOS, DIZ A GUARDIÃO") and not told.has("FANTASMA MATA CONVIDADOS E GARÇONS"),"No guest killed: the waiters got out unharmed")
			await process_frame
		if game.act_card:
			check(game.act_card.screen.title.text == "O SÍNDICO AGRADECE" and game.act_card.screen.tip.text.contains("ATO 2"),"The end of act 1 thanks him in the Síndico's name and names act 2")
			game.act_card.confirmed.emit()
			await process_frame
			# Then the act's special report, in 3D on the TV in his room, until it switches off.
			check(game.news != null and game.news.get("plan") != null and game.news.plan.get("bug","") == "PLANTÃO ESPECIAL","The act's special report comes on after the card, on the TV in his room")
			var shown := {}
			while game.news and not game.news.done:
				shown[game.news.headline.text] = true
				game.news.advance(1.0/30)
			check(shown.has("AGIOTA DA LAPA ENCONTRADO MORTO EM OFICINA DE BONDES") and shown.has("CASTELAR PROMETE CAÇAR O \"FANTASMA DA LAPA\""),"It plays through: the loan shark found dead, Castelar's promise")
			await process_frame
		var next := (index+1)%EXPECT.size()
		check(game.sim.level == next and game.actors.size() == EXPECT[next].enemies+1 and game.overlay_title.text == EXPECT[next].title,"%s: the next night is level %d" % [name,next+1])
		previous = game.level_nodes[0]
	check(game.sim.level == 0 and game.overlay_title.text == "ÚLTIMO GOLE","After the last night the first comes round again")
	game.queue_free()
	await process_frame
	print("LEVELS: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
