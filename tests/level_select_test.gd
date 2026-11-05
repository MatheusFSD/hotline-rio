extends SceneTree
## Level select (scripts/level_select.gd): the menu's FASES page lists every night and back; the
## campaign for a night is every earlier one won; playing from here leaves the save on disk alone.
## Delete this test together with the level select.
const LevelSelect = preload("res://scripts/level_select.gd")
const Main = preload("res://scripts/main.gd")
const Campaign = preload("res://scripts/campaign.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var menu = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var main_page: Array = menu.options.get_children().map(func(n): return n.text)
	check(main_page.has("FASES"),"The main menu offers FASES while the level select exists")
	menu.show_page("levels")
	var names: Array = menu.options.get_children().map(func(n): return n.text)
	var count: int = Main.Simulation.LEVELS.size()
	check(names.size() == count+1 and names[-1] == "VOLTAR","One option per night, then back (%s)" % ", ".join(names))
	check(names[0].begins_with("01  ") and names[count-1].begins_with("%02d  " % count),"Nights numbered in order")
	menu.queue_free()
	# The campaign at a night's start.
	var before: Dictionary = Campaign.state.duplicate(true)
	check(LevelSelect.state_before(0) == Campaign.fresh(),"The first night starts from a fresh campaign")
	var sixth: Dictionary = LevelSelect.state_before(5)
	check(sixth.cleared == [0,1,2,3,4],"Night 6 starts with nights 1 to 5 cleared")
	check("olho_avesso" in sixth.unlocks and not "mao_avesso" in sixth.unlocks,"…with their rewards, not its own")
	check("guia_remessa" in sixth.clues and "livro_iml" in sixth.clues,"…and their clues on the board")
	check(Campaign.state == before,"Building it leaves the campaign in memory as it was")
	# Playing from here never writes the save; a new game or a load turns saving back on.
	var stamp := FileAccess.get_modified_time(Campaign.PATH) if Campaign.exists() else -1
	var text := FileAccess.get_file_as_string(Campaign.PATH) if Campaign.exists() else ""
	Campaign.state = sixth
	Campaign.saving = false
	Campaign.complete(5,{},[],0,"pistol",true)
	check((FileAccess.get_file_as_string(Campaign.PATH) if Campaign.exists() else "") == text and (FileAccess.get_modified_time(Campaign.PATH) if Campaign.exists() else -1) == stamp,"A night won from the level select leaves the save alone")
	Campaign.new_game(false)
	check(Campaign.saving,"A new game saves again")
	Campaign.state = before
	print("LEVEL_SELECT: %d/%d checks passed" % [checks-failures,checks])
	quit(1 if failures else 0)
