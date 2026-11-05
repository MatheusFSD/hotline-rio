extends SceneTree
## In-game HUD: only combat information, in the result screens' fonts, kicking on kills and shots,
## warning on low rounds, slamming the new objective in and stepping aside for cinematics.
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
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var hud = game.hud
	hud.set_process(false)
	var texts: Array[String] = []
	for node in hud.content.find_children("*","Label",true,false): texts.append(node.text)
	var joined := " ".join(texts)
	check(not joined.contains("HOTLINE") and not joined.contains("LAPA") and not joined.contains("WASD") and not joined.contains("TENT"),"No game name, location or controls in the HUD (%s)" % joined)
	var fonts_ok := true
	for node in hud.content.find_children("*","Label",true,false):
		var font: Font = node.get_theme_font("font")
		fonts_ok = fonts_ok and (font == hud.TITLE_FONT or font == hud.DIGIT_FONT)
	check(fonts_ok,"Every HUD label uses the result screens' fonts")
	check(game.overlay.visible and joined.length() > 0,"The briefing still opens the night")
	hud.advance(1.0)
	check(hud.content.modulate.a < .05,"The HUD stays out of the briefing")
	key(game,KEY_ENTER)
	game.update_ui()
	hud.advance(.5)
	check(hud.content.modulate.a > .95,"The HUD fades in once the night is playing")
	check(hud.kills.text == "00/08" and hud.weapon.text == "PISTOLA" and hud.ammo.text == "12" and hud.ammo_total.text == "/12","Kills, gun and rounds read at a glance")
	check(hud.objective.text == "ELIMINE TODOS","The objective names the job")
	game.sim.kill(game.sim.enemies[0])
	game.update_ui()
	check(hud.kills.text == "01/08" and hud.kill_pop > .9 and hud.trauma > .4,"A kill pops the counter and nudges the HUD")
	hud.advance(.05)
	check(hud.kills_box.scale.x > 1.2,"The counter visibly grows on the kill")
	game.sim.player.ammo = 2
	game.update_ui()
	check(hud.ammo_pop > .9 and hud.ammo.get_theme_color("font_color") == hud.RED and hud.magazine.lit == hud.RED,"Rounds pop on a shot and go red when the magazine runs low")
	game.sim.player.reload = .3
	game.update_ui()
	check(hud.ammo.text == "RECARREGANDO" and not hud.ammo_total.visible and absf(hud.magazine.fill-(1.0-.3/.75)) < .01,"Reloading says so and refills the magazine bar")
	game.sim.player.reload = 0.0
	game.sim.player.ammo = 12
	game.sim.player.mana = 40.0
	game.sim.player.phasing = true
	game.update_ui()
	check(hud.spectre_caption.text == "ESPECTRO ATIVO" and is_equal_approx(hud.spectre.fill,.4),"The spectre bar shows the charge and when it is on")
	game.sim.player.phasing = false
	game.sim.player.mana = 5.0
	game.update_ui()
	check(hud.spectre_caption.text == "ESPECTRO ESGOTADO" and hud.spectre.lit == hud.RED,"A drained spectre turns red")
	for e in game.sim.enemies:
		if e.alive: game.sim.kill(e)
	game.update_ui()
	check(hud.objective.text == "PEGUE A PISTA" and hud.objective_pop > .9,"With the bar quiet, the clue is the job")
	hud.advance(1.0)
	for c in game.sim.clues: c.taken = true
	game.update_ui()
	check(hud.objective.text.contains("BECO") and hud.objective_pop > .9 and hud.trauma > .9,"The clue in hand slams the way out in")
	hud.advance(.05)
	check(hud.objective_box.scale.x > 1.5,"The new objective lands big")
	game.sim.die()
	game.update_ui()
	hud.advance(.5)
	check(hud.content.modulate.a < .05,"The HUD steps aside for the death beat")
	game.queue_free()
	await process_frame
	print("HUD: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
