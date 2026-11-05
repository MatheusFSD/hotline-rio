extends SceneTree
## Main menu, languages, the night's mission card and the save: the menu offers new game, load,
## languages and quit; every level line the player reads has an English entry with the same
## placeholders; the card writes itself out and settles; the menu's choice opens the right night.
const Main = preload("res://scripts/main.gd")
const Lang = preload("res://scripts/lang.gd")
const Campaign = preload("res://scripts/campaign.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func texts(menu) -> Array: return menu.options.get_children().map(func(n): return n.text)
func run() -> void:
	var before := TranslationServer.get_locale()
	var menu = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var main_page: Array = texts(menu)
	if main_page.has("FASES"): main_page.erase("FASES")   # the level select, while scripts/level_select.gd exists
	check(main_page[0] == "NOVO JOGO" and main_page[1].begins_with("CARREGAR JOGO") and main_page[2] == "IDIOMAS" and main_page[3] == "SAIR","The menu offers new game, load, languages and quit")
	check(menu.options.get_child(1).disabled == (not Campaign.exists()),"Load game is there only with a save")
	var theme: AudioStreamOggVorbis = menu.theme_player.stream
	check(menu.theme_player.playing and theme.loop and absf(theme.get_length()-40.0) < .05,"The menu theme plays, looping its 40 s")
	menu.show_page("languages")
	check(texts(menu) == ["PORTUGUÊS","ENGLISH","VOLTAR"],"Languages: Portuguese, English, back")
	menu.queue_free()
	# Translations: every line the player reads in a level has its English, placeholders kept.
	TranslationServer.set_locale("en")
	check(TranslationServer.translate("NOVO JOGO") == "NEW GAME" and TranslationServer.translate("ELIMINE TODOS") == "KILL THEM ALL","English menu and HUD")
	var missing := []
	for path in Main.Simulation.LEVELS:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var lines := [data.briefing.title,data.briefing.body,data.briefing.button,data.cleared,data.exit_hint]
		if data.briefing.has("tip"): lines.append(data.briefing.tip)
		for clue in data.get("clues",[]): lines.append_array([clue.title,clue.text])
		if data.has("reward"): lines.append_array([data.reward.title,data.reward.text])
		if data.has("act_end"): lines.append_array([data.act_end.place,data.act_end.title,data.act_end.body,data.act_end.tip,data.act_end.button])
		if data.has("act_end") and data.act_end.has("news"):
			# The newscast's own lines (names on the lower third may stay as they are).
			var news: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(data.act_end.news))
			lines.append_array([news.bug,news.ticker])
			for segment in news.segments: lines.append_array([segment.headline,segment.caption])
		for clue in data.get("clues",[]): if clue.has("lead"): lines.append(clue.lead)
		for line in lines:
			if TranslationServer.translate(line) == line: missing.append(line)
	for letter in Campaign.CELESTE: if TranslationServer.translate(letter.text) == letter.text: missing.append(letter.text)
	check(missing.is_empty(),"Every level line has its English (%s)" % ", ".join(missing))
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Lang.TABLES.en))
	var broken := table.keys().filter(func(k): return k.count("%") != table[k].count("%"))
	check(broken.is_empty(),"English keeps every placeholder (%s)" % ", ".join(broken))
	TranslationServer.set_locale("pt")
	check(TranslationServer.translate("NOVO JOGO") == "NOVO JOGO","Portuguese stays the source text")
	# The mission card over the level.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.overlay.set_process(false)
	check(game.overlay.visible and game.overlay.animating() and game.overlay.body.visible_ratio == 0.0,"The card opens empty and starts writing")
	game.overlay.advance(1.2)
	check(game.overlay.body.visible_ratio > 0.0 and game.overlay.body.visible_ratio < 1.0,"The objective types itself out")
	game.overlay.advance(5.0)
	check(not game.overlay.animating() and game.overlay.body.visible_ratio == 1.0 and game.overlay.title.modulate.a == 1.0,"Then everything settles")
	check(game.overlay.tip.visible and not game.overlay.menu_button.visible,"The first night teaches the rules; no way out to the menu from the card")
	game.load_level(1)
	check(not game.overlay.tip.visible and game.overlay_title.text == "ÚLTIMA DANÇA","Later nights skip the rules")
	game.start_or_resume()
	game.sim.state = "paused"
	game.update_ui()
	check(game.overlay.visible and game.overlay_title.text == "PAUSADO" and game.overlay.menu_button.visible,"Pause can go back to the main menu")
	game.queue_free()
	# The menu's choice opens the night it names, with its gun and without the newscast.
	Main.opening = {"level":2,"weapon":"shotgun","news":false}
	var loaded = load("res://scenes/main.tscn").instantiate()
	root.add_child(loaded)
	check(loaded.sim.level == 2 and loaded.sim.weapon == "shotgun","Load game opens the saved night with its gun")
	loaded.queue_free()
	Main.opening = {"level":0,"weapon":"pistol","news":true}
	TranslationServer.set_locale(before)
	await process_frame
	print("MENU: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
