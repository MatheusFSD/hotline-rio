extends RefCounted
## Level select, a development tool: a FASES page on the main menu that opens any night, with the
## campaign as if every night before it had been won (its clues, rewards and unlocks). The save on
## disk is left alone while playing from here.
## To take it out of the game, delete this file: the menu only offers the page while it exists.
const Main = preload("res://scripts/main.gd")
const Campaign = preload("res://scripts/campaign.gd")

## Fills the menu's FASES page: one option per night ("05  ÚLTIMA CARGA"), then back.
static func fill(menu) -> void:
	for i in Main.Simulation.LEVELS.size():
		var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Main.Simulation.LEVELS[i]))
		var button: Button = menu._option("%02d  %s" % [i+1,menu.tr(layout.briefing.title)],play.bind(menu,i))
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # the title is translated above
	menu._option("VOLTAR",menu.show_page.bind("main"))

## Opens night `index` on its card, past the newscast, with the nights before it won.
static func play(menu,index: int) -> void:
	Campaign.state = state_before(index)
	Campaign.saving = false
	menu._launch({"level":index,"weapon":"pistol","news":false})

## The campaign at the start of night `index`: every earlier night cleared with all its clues found.
static func state_before(index: int) -> Dictionary:
	var saved: Dictionary = Campaign.state
	Campaign.state = Campaign.fresh()
	for i in index:
		var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Main.Simulation.LEVELS[i]))
		Campaign.complete(i,layout,layout.get("clues",[]).map(func(c): return c.id),i+1,"pistol")
	var result: Dictionary = Campaign.state
	Campaign.state = saved
	return result
