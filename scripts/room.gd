class_name LapaRoom
extends CanvasLayer
## The protagonist's room between nights: one fixed 3D camera and point-and-click hotspots.
## The computer (Celeste's orders, paid in favours), the weapon rack (the guns earned so far) and
## the investigation board (each night's clues) open panels; the door or the button starts the next
## night. The night just won is reported at the top: its clues, favours and what it unlocked.
signal next_night
const RESOLUTION := Vector2i(640,400)
const CAMERA_FROM := Vector3(.9,2.15,2.6)
const CAMERA_TO := Vector3(-.7,1.25,-3.4)
## Hotspot node -> [label, hint, panel].
const HOTSPOTS := {
	"Hotspot_pc":["COMPUTADOR","Encomendas da Celeste","pc"],
	"Hotspot_board":["QUADRO DE INVESTIGAÇÃO","Missões e pistas","board"],
	"Hotspot_door":["PORTA","Sair para a próxima noite","door"],
	"Weapon_pistol":["PISTOLA","Arsenal: escolher arma","weapons"],
	"Weapon_smg":["SUBMETRALHADORA","Arsenal: escolher arma","weapons"],
	"Weapon_shotgun":["ESCOPETA","Arsenal: escolher arma","weapons"],
	"Weapon_rifle":["FUZIL","Arsenal: escolher arma","weapons"],
	"Weapon_minigun":["MINIGUN","Arsenal: escolher arma","weapons"]}
## After the Síndico (summary "finale"): only the TV, on the desk, and the window.
const FINALE_SPOTS := {
	"Hotspot_pc":["TELEVISÃO","Ligar no plantão","tv"],
	"City":["JANELA","Ir embora pela janela","window"]}
signal finale_chosen(kind: String)
var spots: Dictionary = HOTSPOTS
const Simulation = preload("res://scripts/simulation.gd")
const Campaign = preload("res://scripts/campaign.gd")
## Rack hotspot -> weapon id and a line of flavour; the numbers come from the simulation.
const WEAPONS := [["Weapon_pistol","pistol","A pistola do Russo. Achei no chão do beco."],
	["Weapon_smg","smg","Do cofre da gafieira. Rajada rápida, espalha."],
	["Weapon_shotgun","shotgun","A doze do Seu Arlindo. Sete chumbos, curto alcance."],
	["Weapon_rifle","rifle","Preciso e rápido."],
	["Weapon_minigun","minigun","Precisa girar. Você fica lento."]]
## Night lights: position, colour, energy, range.
const LIGHTS := [
	[Vector3(2.5,1.05,-3.05),"ffc27a",1.6,4.5],     # bedside lamp
	[Vector3(-2.55,1.35,-.25),"ffd29a",1.2,4.0],    # floor lamp
	[Vector3(0,2.7,-1.6),"fff0d8",.5,6.0],          # weak ceiling bulb
	[Vector3(-1.95,1.15,-3.6),"7fd6ff",1.1,2.6],    # CRT glow
	[Vector3(1.5,1.9,-4.2),"6f8cff",1.4,5.5]]       # moonlight through the window

var summary: Dictionary
var viewport: SubViewport
var camera: Camera3D
var screen: TextureRect
var hotspots: Dictionary = {}
var triangles: Dictionary = {}   # hotspot -> world-space triangle soup, the room never moves
var hovered := ""
var highlight := StandardMaterial3D.new()
var heavy := SystemFont.new()
var tooltip: Label
var panel: PanelContainer
var panel_title: Label
var panel_body: VBoxContainer
var open_panel := ""
var selected_weapon := "Weapon_pistol"
var equipped := "pistol"
var equipped_label: Label

func _init(night_summary: Dictionary = {}) -> void:
	summary = night_summary
	equipped = summary.get("weapon","pistol")
	if summary.get("finale",false): spots = FINALE_SPOTS
	layer = 15

func _ready() -> void:
	heavy.font_names = PackedStringArray(["Arial Black","Impact","Arial"])
	heavy.font_weight = 900
	highlight.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	highlight.albedo_color = Color(1,.78,.35,.28)
	_build_world()
	_build_ui()

func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

# ---------------------------------------------------------------- 3D
func _build_world() -> void:
	viewport = SubViewport.new()
	viewport.size = RESOLUTION
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("06080c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8f9ab8")
	env.ambient_light_energy = .38
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = env
	viewport.add_child(world)
	var room := (load("res://assets/room/room.glb") as PackedScene).instantiate()
	viewport.add_child(room)
	for node in room.find_children("*","MeshInstance3D",true,false):
		for surface in node.mesh.get_surface_count():
			var mat := node.mesh.surface_get_material(surface) as BaseMaterial3D
			if mat:
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				mat.roughness = 1.0
				mat.metallic = 0.0
				mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		for key in spots:
			if String(node.name).begins_with(key) or String(node.get_parent().name).begins_with(key): hotspots[key] = node
	# The board shows the clues found so far, each pinned with its yarn (tools/build_room.py).
	for node in room.find_children("Clue_*","Node3D",true,false):
		node.visible = String(node.name).trim_prefix("Clue_") in campaign().clues
	for light in LIGHTS:
		var omni := OmniLight3D.new()
		omni.position = light[0]
		omni.light_color = Color(light[1])
		omni.light_energy = light[2]
		omni.omni_range = light[3]
		omni.omni_attenuation = .9
		viewport.add_child(omni)
	camera = Camera3D.new()
	camera.fov = 48
	camera.near = .1
	camera.far = 30
	viewport.add_child(camera)
	camera.look_at_from_position(CAMERA_FROM,CAMERA_TO)
	camera.current = true
	for key in hotspots:
		var node: MeshInstance3D = hotspots[key]
		triangles[key] = node.global_transform*node.mesh.get_faces()

func hotspot_at(point: Vector2) -> String:
	## Hotspot under a point of the 640x400 picture: the nearest triangle hit by the camera ray.
	var origin := camera.project_ray_origin(point)
	var direction := camera.project_ray_normal(point)
	var best := ""
	var best_distance := INF
	for key in hotspots:
		var node: MeshInstance3D = hotspots[key]
		if (node.global_transform*node.get_aabb()).grow(.02).intersects_ray(origin,direction) == null: continue
		var faces: PackedVector3Array = triangles[key]
		for i in range(0,faces.size(),3):
			var hit: Variant = Geometry3D.ray_intersects_triangle(origin,direction,faces[i],faces[i+1],faces[i+2])
			if hit != null and origin.distance_to(hit) < best_distance:
				best = key
				best_distance = origin.distance_to(hit)
	return best

func surface_point(key: String) -> Vector3:
	## A point on the hotspot itself, near the middle of its bounds (for tests and captures).
	var node: MeshInstance3D = hotspots[key]
	var centre: Vector3 = (node.global_transform*node.get_aabb()).get_center()
	var faces: PackedVector3Array = triangles[key]
	var best := faces[0]
	for i in range(0,faces.size(),3):
		var middle := (faces[i]+faces[i+1]+faces[i+2])/3
		if middle.distance_to(centre) < best.distance_to(centre): best = middle
	return best

func _picture_point(screen_point: Vector2) -> Vector2:
	return (screen_point-screen.position)/screen.size*Vector2(RESOLUTION)

func _set_hovered(key: String) -> void:
	if key == hovered: return
	if hovered != "" and hotspots.has(hovered): hotspots[hovered].material_overlay = null
	hovered = key
	if hovered != "": hotspots[hovered].material_overlay = highlight
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hovered != "" else Input.CURSOR_ARROW)
	tooltip.visible = hovered != ""
	if hovered != "":
		var rack := WEAPONS.filter(func(w): return w[0] == hovered)
		var locked: bool = not rack.is_empty() and not rack[0][1] in campaign().unlocks   # not his gun yet
		tooltip.text = "%s\n%s" % ["???" if locked else tr(spots[hovered][0]),tr(spots[hovered][1])]

func click(key: String) -> void:
	if key == "" or not spots.has(key): return
	var kind: String = spots[key][2]
	if kind in ["tv","window"]:
		finale_chosen.emit(kind)
		return
	if kind == "door":
		next_night.emit()
		return
	if kind == "weapons": selected_weapon = key
	_open(kind)

func _input(event: InputEvent) -> void:
	# The room owns all input while it is up; nothing reaches the paused game below.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE and open_panel != "": _close()
		elif event.physical_keycode in [KEY_ENTER,KEY_KP_ENTER] and open_panel == "": next_night.emit()
		get_viewport().set_input_as_handled()

func _on_screen_input(event: InputEvent) -> void:
	if open_panel != "": return
	if event is InputEventMouseMotion:
		_set_hovered(hotspot_at(_picture_point(event.position+screen.position)))
		tooltip.position = event.position+screen.position+Vector2(18,14)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(hotspot_at(_picture_point(event.position+screen.position)))

# ---------------------------------------------------------------- 2D
func _label(value: String,size: int,color := Color("ede4cb")) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font",heavy)
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	return label

func _style(color: Color,border := Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_content_margin_all(18)
	if border.a > 0:
		style.set_border_width_all(2)
		style.border_color = border
	return style

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	screen = TextureRect.new()
	screen.texture = viewport.get_texture()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_SCALE
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.gui_input.connect(_on_screen_input)
	root.add_child(screen)
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.add_theme_stylebox_override("panel",_style(Color(.06,.08,.1,.82)))
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var row := HBoxContainer.new()
	top.add_child(row)
	var place := VBoxContainer.new()
	row.add_child(place)
	place.add_child(_label("QUARTO",24,Color("e2b86a")))
	place.add_child(_label("RUA DO LAVRADIO, LAPA  •  4:12 DA MANHÃ",12,Color("a6c3b0")))
	equipped_label = _label("",13,Color("ffe2a0"))
	place.add_child(equipped_label)
	_show_equipped()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var night := _label(tr("NOITE CONCLUÍDA\n%d ELIMINAÇÕES  •  %.1f s  •  TENTATIVA %d") % [summary.get("kills",0),summary.get("time",0.0),summary.get("attempt",1)],13)
	night.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var right := VBoxContainer.new()
	right.add_child(night)
	row.add_child(right)
	# What the night brought: the clues photographed, Celeste's favours, the story unlock.
	var report: Dictionary = summary.get("report",{})
	for clue in report.get("clues",[]):
		var line := _label("%s  %s" % [tr("PISTA:"),tr(clue.title)]+("" if clue.new else "  "+tr("(JÁ NO QUADRO)")),13,Color("ffd27a"))
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_child(line)
	if report.get("favors",0) > 0:
		var favour := _label(tr("+%d FAVOR DA CELESTE") % report.favors,13,Color("9fe0c8"))
		favour.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_child(favour)
	if not report.get("reward",{}).is_empty():
		var reward := _label("%s  %s" % [tr("NOVO:"),tr(report.reward.title)],13,Color("9fe0c8"))
		reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_child(reward)
	var hint := _label("A TV ou a janela." if summary.get("finale",false) else "Clique no computador, no arsenal ou no quadro",13,Color("cfc6ae"))
	hint.position = Vector2(24,748)
	root.add_child(hint)
	var go := Button.new()
	go.text = "PRÓXIMA NOITE  →"
	go.add_theme_font_override("font",heavy)
	go.add_theme_font_size_override("font_size",16)
	go.add_theme_stylebox_override("normal",_style(Color("35574d")))
	go.add_theme_stylebox_override("hover",_style(Color("467366")))
	go.position = Vector2(1036,730)
	go.size = Vector2(220,48)
	go.pressed.connect(func(): next_night.emit())
	go.visible = not summary.get("finale",false)   # after the Síndico there is no next night
	root.add_child(go)
	tooltip = _label("",15,Color("ffe2a0"))
	tooltip.add_theme_stylebox_override("normal",_style(Color(0,0,0,.78)))
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.hide()
	root.add_child(tooltip)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel",_style(Color(.07,.09,.11,.96),Color("e2b86a")))
	panel.position = Vector2(340,170)
	panel.custom_minimum_size = Vector2(600,0)
	panel.hide()
	root.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",10)
	panel.add_child(content)
	panel_title = _label("",26,Color("e2b86a"))
	content.add_child(panel_title)
	panel_body = VBoxContainer.new()
	panel_body.add_theme_constant_override("separation",6)
	content.add_child(panel_body)
	var close := Button.new()
	close.text = "FECHAR  (ESC)"
	close.add_theme_font_override("font",heavy)
	close.add_theme_stylebox_override("normal",_style(Color("324143")))
	close.pressed.connect(_close)
	content.add_child(close)

func _line(text: String,color := Color("ede4cb"),size := 15) -> void:
	var label := _label(text,size,color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_body.add_child(label)

func _open(kind: String) -> void:
	_set_hovered("")
	open_panel = kind
	for child in panel_body.get_children(): child.queue_free()
	match kind:
		"pc":
			# Celeste's orders: no money in this game, the payment is investigation.
			panel_title.text = "LAPANET  —  ENCOMENDAS"
			_line("Conectando... 14.4 kbps",Color("4cff6a"),13)
			# MARÉ writes from the second night on; the latest two messages stay on screen.
			var letters := Campaign.messages(campaign())
			if letters.is_empty(): _line("MARÉ está offline.",Color("6d756f"),13)
			for letter in letters.slice(-2): _line("MARÉ:  "+tr(letter),Color("ffe2a0"),13)
			_line(tr("FAVORES DA CELESTE: %d") % campaign().favors,Color("9fe0c8"))
			for id in Campaign.ORDERS: _order_row(id)
			_line("Cada pista opcional que você encontra vale um favor.",Color("a6c3b0"),13)
		"board":
			panel_title.text = "MISSÕES"
			# One block per level file: its state, then its clues, found or still a question mark.
			var cleared: Array = campaign().cleared
			var found: Array = campaign().clues
			for i in Simulation.LEVELS.size():
				var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Simulation.LEVELS[i]))
				if data.get("chain",false): continue   # the Síndico's stages count as one night, the last
				var mission: String = data.get("mission","")
				if i in cleared: _line(tr(mission)+"        "+tr("✔ CONCLUÍDA"),Color("94c4b0"))
				else: _line(tr(mission)+"        "+tr("PRÓXIMA NOITE"),Color("ffe2a0"))
				for clue in data.get("clues",[]):
					if clue.id in found: _line("    •  %s  —  %s" % [tr(clue.title),tr(clue.get("text",""))],Color("ede4cb"),12)
					else: _line("    •  ???",Color("6d756f"),12)
			# The next destination: the lead of the latest clue that points somewhere, or the red strings.
			var lead := "siga os fios vermelhos"
			for i in Simulation.LEVELS.size():
				var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Simulation.LEVELS[i]))
				for clue in data.get("clues",[]):
					if clue.id in found and clue.has("lead"): lead = clue.lead
			if not Simulation.LEVELS.size()-1 in cleared: _line(tr("%02d  ???  —  %s        EM BREVE") % [Simulation.LEVELS.size()+1,tr(lead)],Color("8d958f"))
		"weapons":
			panel_title.text = "ARSENAL"
			for weapon in WEAPONS:
				_weapon_row(weapon)
			_line("A arma equipada vai na mão para a próxima noite.",Color("a6c3b0"),13)
	panel.show()

func _weapon_row(weapon: Array) -> void:
	var id: String = weapon[1]
	var stats: Dictionary = Simulation.WEAPONS[id]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",14)
	panel_body.add_child(row)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var chosen: bool = weapon[0] == selected_weapon
	# A gun not earned yet in the story stays on the rack as a question mark.
	var owned: bool = id in campaign().unlocks
	text.add_child(_label(("▶ " if chosen else "")+(tr(stats.name) if owned else "???"),17,Color("ffe2a0") if chosen else Color("ede4cb")))
	if owned:
		var pellets := tr("  •  %d chumbos") % stats.pellets if stats.pellets > 1 else ""
		text.add_child(_label(tr("%d tiros/min  •  pente %d  •  recarga %.2f s%s") % [roundi(60.0/stats.cooldown),int(Campaign.mods(campaign().unlocks).get("magazine",{}).get(id,stats.magazine)),stats.reload*float(Campaign.mods(campaign().unlocks).get("reload_mult",1.0)),pellets],12,Color("a6c3b0")))
	text.add_child(_label(weapon[2] if owned else "Ainda não é sua.",12,Color("8d958f")))
	var button := Button.new()
	button.add_theme_font_override("font",heavy)
	button.custom_minimum_size = Vector2(130,0)
	button.text = ("NA MÃO" if id == equipped else "EQUIPAR") if owned else "BLOQUEADA"
	button.disabled = id == equipped or not owned
	button.add_theme_stylebox_override("normal",_style(Color("35574d")))
	button.add_theme_stylebox_override("disabled",_style(Color("4a3d22")))
	button.pressed.connect(equip.bind(id))
	row.add_child(button)

## The campaign the room shows: the game's own, or the starting one when the room stands alone.
func campaign() -> Dictionary:
	return summary.get("campaign",Campaign.state)

func _order_row(id: String) -> void:
	var item: Dictionary = Campaign.ORDERS[id]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",14)
	panel_body.add_child(row)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(_label(item.title,16,Color("ede4cb")))
	text.add_child(_label(item.text,12,Color("a6c3b0")))
	var button := Button.new()
	button.add_theme_font_override("font",heavy)
	button.custom_minimum_size = Vector2(150,0)
	var owned: bool = id in campaign().unlocks
	var offered: bool = campaign().cleared.size() >= int(item.after)
	button.text = "CHEGOU" if owned else (tr("PEDIR  (%d)") % item.cost if offered else "EM BREVE")
	button.disabled = owned or not offered or campaign().favors < int(item.cost)
	button.add_theme_stylebox_override("normal",_style(Color("35574d")))
	button.add_theme_stylebox_override("disabled",_style(Color("2c3434")))
	button.pressed.connect(func():
		if Campaign.order(id,summary.get("persist",false)): _open("pc"))
	row.add_child(button)

func equip(id: String) -> void:
	equipped = id
	selected_weapon = WEAPONS.filter(func(w): return w[1] == id)[0][0]
	_show_equipped()
	if open_panel == "weapons": _open("weapons")

func _show_equipped() -> void:
	equipped_label.text = tr("NA MÃO: %s") % tr(Simulation.WEAPONS[equipped].name)

func _close() -> void:
	open_panel = ""
	panel.hide()
