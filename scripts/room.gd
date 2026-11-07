class_name LapaRoom
extends CanvasLayer
## The protagonist's room between nights: one fixed 3D camera and point-and-click hotspots.
## The computer walks the camera up to its screen, where Celeste's shop opens on the dark web (her
## orders, paid in favours); on the weapon rack only the guns earned so far hang, each telling its
## numbers under the mouse and taken in hand with a click; the investigation board (each night's
## clues) opens a panel; the door or the button starts the next
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
	"Weapon_pistol":["PISTOLA","","weapons"],
	"Weapon_smg":["SUBMETRALHADORA","","weapons"],
	"Weapon_shotgun":["ESCOPETA","","weapons"],
	"Weapon_rifle":["FUZIL","","weapons"],
	"Weapon_minigun":["MINIGUN","","weapons"]}
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
var in_hand := StandardMaterial3D.new()   # a faint glow on the gun he will carry
var heavy := SystemFont.new()
var tooltip: Label
var panel: PanelContainer
var panel_title: Label
var panel_body: VBoxContainer
var open_panel := ""
var selected_weapon := "Weapon_pistol"
var equipped := "pistol"
var equipped_label: Label
## The computer: a click walks the camera up to the CRT over ZOOM_TIME, then the screen comes on with
## MARÉ's shop, a .onion page in the LOKI browser. The page is a 2D scene drawn into the tube's own
## glass (the room model's pc_screen surface); clicks on the glass are carried into it, a click off
## the monitor or Esc walks back. Each order stands on a turntable, a PSX model of its own
## (tools/build_shop.py).
const ZOOM_TIME := 1.5
const LEAVE_TIME := .8
const SITE_SIZE := Vector2i(480,360)
const SCREEN_FILL := .72         # the glass's height, as a share of the picture: the monitor round it
## At the screen the room is drawn at twice its resolution, so the page on the glass stays legible;
## it switches as the tube comes on, and back as the camera leaves.
const SCREEN_DETAIL := 2
const SITE_FONT := preload("res://assets/fonts/VT323-Regular.ttf")
const ITEM_VIEW := 56
const ITEM_SPIN := .9            # radians per second
const ITEM_TILT := {"back_sheath":-.75,"suppressor":1.2}
const ONION := "loki://mare7xq3vkd2pjw.onion/encomendas"
const PHOSPHOR := Color("46ff6e")
const SCANLINES := "shader_type canvas_item;\nvoid fragment() { COLOR = vec4(0.0,0.0,0.0,mod(floor(FRAGCOORD.y),2.0)*0.16); }"
var site: SubViewport
var site_root: Control
var site_status: Label
var site_material: StandardMaterial3D
var spinners: Array[Node3D] = []
var pc_state := ""               # "", "zooming", "open" or "leaving"
var camera_home: Transform3D
var camera_tween: Tween
var screen_node: MeshInstance3D
var screen_surface := -1
var screen_triangles := PackedVector3Array()
var screen_uvs := PackedVector2Array()
var screen_corners: Array[Vector3] = []   # the glass's top-left, top-right and bottom-left, world
var room_chrome: Array[Control] = []      # what the room shows over the picture, hidden at the screen

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
	in_hand.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	in_hand.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	in_hand.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	in_hand.albedo_color = Color(.45,1,.6,.16)
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
	# The window's casements: shut, but open on the last night, when he can leave by it.
	var leaving: bool = summary.get("finale",false)
	for node in room.find_children("Sashes_closed*","",true,false): node.visible = not leaving
	for node in room.find_children("Sashes_open*","",true,false): node.visible = leaving
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
	camera_home = camera.global_transform
	if hotspots.has("Hotspot_pc"): _find_screen(hotspots["Hotspot_pc"])
	# A gun not earned yet is not on the wall at all.
	for weapon in WEAPONS:
		if hotspots.has(weapon[0]): hotspots[weapon[0]].visible = weapon[1] in campaign().unlocks
	_mark_in_hand()

func _mark_in_hand() -> void:
	for weapon in WEAPONS:
		if hotspots.has(weapon[0]) and weapon[0] != hovered:
			hotspots[weapon[0]].material_overlay = in_hand if weapon[1] == equipped else null

func _find_screen(node: MeshInstance3D) -> void:
	## The CRT's glass: its triangles and UVs in the world, and its corners.
	for surface in node.mesh.get_surface_count():
		var material := node.mesh.surface_get_material(surface)
		if not material or not String(material.resource_name).ends_with("pc_screen"): continue
		screen_node = node
		screen_surface = surface
		var arrays := node.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var order: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] else PackedInt32Array(range(vertices.size()))
		for i in order:
			screen_triangles.append(node.global_transform*vertices[i])
			screen_uvs.append(uvs[i])
		for corner in [Vector2(0,0),Vector2(1,0),Vector2(0,1)]:
			var best := 0
			for i in uvs.size(): if uvs[i].distance_to(corner) < uvs[best].distance_to(corner): best = i
			screen_corners.append(node.global_transform*vertices[best])
		return

func screen_pose() -> Transform3D:
	## In front of the glass, square to it, the glass filling SCREEN_FILL of the picture's height.
	var right := screen_corners[1]-screen_corners[0]
	var down := screen_corners[2]-screen_corners[0]
	var centre := screen_corners[0]+(right+down)/2
	var normal := right.cross(down).normalized()
	if normal.dot(camera_home.origin-centre) < 0: normal = -normal
	var distance := down.length()/SCREEN_FILL/(2.0*tan(deg_to_rad(camera.fov)/2.0))
	return Transform3D(Basis.looking_at(-normal,-down.normalized()),centre+normal*distance)

## A point of the room's picture, on the glass: where it falls on the page, or null off the screen.
func site_point(picture_point: Vector2) -> Variant:
	var origin := camera.project_ray_origin(picture_point)
	var direction := camera.project_ray_normal(picture_point)
	for i in range(0,screen_triangles.size(),3):
		var a := screen_triangles[i]
		var b := screen_triangles[i+1]
		var c := screen_triangles[i+2]
		var hit: Variant = Geometry3D.ray_intersects_triangle(origin,direction,a,b,c)
		if hit == null: continue
		var w := Geometry3D.get_triangle_barycentric_coords(hit,a,b,c)
		return (screen_uvs[i]*w.x+screen_uvs[i+1]*w.y+screen_uvs[i+2]*w.z)*Vector2(SITE_SIZE)
	return null

## Where a point of the page shows in the room's picture (for tests and captures).
func picture_of(page_point: Vector2) -> Vector2:
	var uv := page_point/Vector2(SITE_SIZE)
	var world := screen_corners[0]+(screen_corners[1]-screen_corners[0])*uv.x+(screen_corners[2]-screen_corners[0])*uv.y
	return camera.unproject_position(world)

func _enter_pc() -> void:
	_set_hovered("")
	open_panel = "pc"
	pc_state = "zooming"
	for node in room_chrome:
		node.set_meta("shown",node.visible)
		node.hide()
	_fly(screen_pose(),ZOOM_TIME,_site_on)

func _fly(to: Transform3D,seconds: float,done: Callable) -> void:
	if camera_tween: camera_tween.kill()
	var from := camera.global_transform
	var turn_from := from.basis.get_rotation_quaternion()
	var turn_to := to.basis.get_rotation_quaternion()
	camera_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_method(func(t: float): camera.global_transform = Transform3D(Basis(turn_from.slerp(turn_to,t)),from.origin.lerp(to.origin,t)),0.0,1.0,seconds)
	camera_tween.tween_callback(done)

func _site_on() -> void:
	pc_state = "open"
	_fill_site()
	site.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = RESOLUTION*SCREEN_DETAIL
	screen_node.set_surface_override_material(screen_surface,site_material)
	# The tube comes on: a bright line opens into the page.
	var flash := ColorRect.new()
	flash.color = Color(.85,1,.88)
	flash.size = Vector2(SITE_SIZE)
	flash.pivot_offset = Vector2(SITE_SIZE)/2
	flash.scale = Vector2(1,.02)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	site_root.add_child(flash)
	var on := create_tween()
	on.tween_property(flash,"scale:y",1.0,.12)
	on.tween_property(flash,"modulate:a",0.0,.22)
	on.tween_callback(flash.queue_free)

func _leave_pc() -> void:
	if pc_state == "leaving": return
	pc_state = "leaving"
	screen_node.set_surface_override_material(screen_surface,null)
	site.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.size = RESOLUTION
	for child in site_root.get_children(): child.queue_free()
	spinners.clear()
	_fly(camera_home,LEAVE_TIME,func():
		pc_state = ""
		open_panel = ""
		for node in room_chrome: node.visible = node.get_meta("shown",true))

func hotspot_at(point: Vector2) -> String:
	## Hotspot under a point of the 640x400 picture: the nearest triangle hit by the camera ray.
	var origin := camera.project_ray_origin(point)
	var direction := camera.project_ray_normal(point)
	var best := ""
	var best_distance := INF
	for key in hotspots:
		var node: MeshInstance3D = hotspots[key]
		if not node.is_visible_in_tree(): continue
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
	return (screen_point-screen.position)/screen.size*Vector2(viewport.size)

func _set_hovered(key: String) -> void:
	if key == hovered: return
	var left := hovered
	hovered = key
	if left != "" and hotspots.has(left): hotspots[left].material_overlay = null
	_mark_in_hand()
	if hovered != "": hotspots[hovered].material_overlay = highlight
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hovered != "" else Input.CURSOR_ARROW)
	tooltip.visible = hovered != ""
	if hovered != "":
		var rack := WEAPONS.filter(func(w): return w[0] == hovered)
		tooltip.text = weapon_card(rack[0]) if not rack.is_empty() else "%s\n%s" % [tr(spots[hovered][0]),tr(spots[hovered][1])]

## What a gun on the wall says under the mouse: its name, its numbers, a line about it, and whether
## it is the one in hand.
func weapon_card(weapon: Array) -> String:
	var id: String = weapon[1]
	var stats: Dictionary = Simulation.WEAPONS[id]
	var mods := Campaign.mods(campaign().unlocks)
	var pellets := tr("  •  %d chumbos") % stats.pellets if stats.pellets > 1 else ""
	var numbers := tr("%d tiros/min  •  pente %d  •  recarga %.2f s%s") % [roundi(60.0/stats.cooldown),int(mods.get("magazine",{}).get(id,stats.magazine)),stats.reload*float(mods.get("reload_mult",1.0)),pellets]
	var state := tr("NA MÃO") if id == equipped else tr("Clique para levar")
	return "%s\n%s\n%s\n%s" % [tr(stats.name),numbers,tr(weapon[2]),state]

func click(key: String) -> void:
	if key == "" or not spots.has(key): return
	var kind: String = spots[key][2]
	if kind in ["tv","window"]:
		finale_chosen.emit(kind)
		return
	if kind == "door":
		next_night.emit()
		return
	if kind == "pc":
		if screen_surface >= 0 and pc_state == "": _enter_pc()
		return
	if kind == "weapons":
		# A click takes the gun in hand; only the earned ones hang on the wall.
		var id: String = WEAPONS.filter(func(w): return w[0] == key)[0][1]
		if id in campaign().unlocks: equip(id)
		return
	_open(kind)

func _input(event: InputEvent) -> void:
	# The room owns all input while it is up; nothing reaches the paused game below.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE and open_panel != "": _close()
		elif event.physical_keycode in [KEY_ENTER,KEY_KP_ENTER] and open_panel == "": next_night.emit()
		get_viewport().set_input_as_handled()

func _on_screen_input(event: InputEvent) -> void:
	if open_panel == "pc":
		# At the computer the mouse works the page on the glass; a click off the monitor walks back.
		if pc_state != "open" or not event is InputEventMouse: return
		var at: Variant = site_point(_picture_point(event.position+screen.position))
		if at == null:
			if event is InputEventMouseButton and event.pressed: _leave_pc()
			return
		var copy: InputEventMouse = event.duplicate()
		copy.position = at
		copy.global_position = at
		site.push_input(copy,true)
		return
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
	room_chrome.append(top)
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
	var hint := _label("A TV ou a janela." if summary.get("finale",false) else "Clique numa arma para levá-la, no computador ou no quadro",13,Color("cfc6ae"))
	hint.position = Vector2(24,748)
	root.add_child(hint)
	room_chrome.append(hint)
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
	room_chrome.append(go)
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
	_build_site()

# ---------------------------------------------------------------- the computer's screen
func _build_site() -> void:
	site = SubViewport.new()
	site.size = SITE_SIZE
	site.disable_3d = true
	site.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(site)
	site_root = Control.new()
	site_root.size = Vector2(SITE_SIZE)
	var theme := Theme.new()
	theme.default_font = SITE_FONT
	theme.default_font_size = 16
	site_root.theme = theme
	site.add_child(site_root)
	site_material = StandardMaterial3D.new()
	site_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	site_material.albedo_texture = site.get_texture()
	site_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR

func _flat(color: Color,border := Color.TRANSPARENT,margin := 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_content_margin_all(margin)
	if border.a > 0:
		style.set_border_width_all(1)
		style.border_color = border
	return style

func _text(value: String,color: Color,size := 16) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_color_override("font_color",color)
	label.add_theme_font_size_override("font_size",size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _status(value := "") -> void:
	site_status.text = value if value != "" else tr("LOKI  ·  conexão anônima  ·  14.4 kbps")

func _fill_site() -> void:
	## The LOKI window and MARÉ's page in it: her orders on turntables, her favours, her messages.
	for child in site_root.get_children(): child.queue_free()
	spinners.clear()
	var window := PanelContainer.new()
	window.size = Vector2(SITE_SIZE)
	window.add_theme_stylebox_override("panel",_flat(Color("bdbdb5"),Color("f2f2ea"),2))
	site_root.add_child(window)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",2)
	window.add_child(column)
	# The browser: its title bar, with the close box, and the address of the page.
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel",_flat(Color("1a2a6c"),Color.TRANSPARENT,2))
	column.add_child(bar)
	var title := HBoxContainer.new()
	bar.add_child(title)
	title.add_child(_text("LOKI",Color("ffd23f")))
	title.add_child(_text(" — MARÉ :: encomendas",Color.WHITE))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_child(gap)
	var shut := Button.new()
	shut.text = "X"
	shut.custom_minimum_size = Vector2(18,0)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		shut.add_theme_color_override(state,Color.BLACK)
	shut.add_theme_stylebox_override("normal",_flat(Color("bdbdb5"),Color("f2f2ea"),0))
	shut.add_theme_stylebox_override("hover",_flat(Color("e0e0d8"),Color("f2f2ea"),0))
	shut.add_theme_stylebox_override("pressed",_flat(Color("8f8f88"),Color("f2f2ea"),0))
	shut.pressed.connect(_close)
	title.add_child(shut)
	var address := HBoxContainer.new()
	column.add_child(address)
	address.add_child(_text("Endereço",Color("202020"),14))
	var field := PanelContainer.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_theme_stylebox_override("panel",_flat(Color.WHITE,Color("5a5a55"),1))
	field.add_child(_text(ONION,Color("101010"),14))
	address.add_child(field)
	# The page.
	var page := PanelContainer.new()
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_stylebox_override("panel",_flat(Color("040805"),Color.TRANSPARENT,6))
	column.add_child(page)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",5)
	page.add_child(body)
	var head := HBoxContainer.new()
	body.add_child(head)
	head.add_child(_text("░▒▓ M A R É ▓▒░",PHOSPHOR,18))
	var spring := Control.new()
	spring.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spring)
	head.add_child(_text("encomendas · pague em favores",Color("2f9e47"),14))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",5)
	grid.add_theme_constant_override("v_separation",5)
	body.add_child(grid)
	for id in Campaign.ORDERS: grid.add_child(_order_card(id))
	# The sixth cell: the favours she owes, the only currency here.
	var purse := PanelContainer.new()
	purse.custom_minimum_size = Vector2(150,0)
	purse.add_theme_stylebox_override("panel",_flat(Color("0d1a10"),Color("2f9e47")))
	var coins := VBoxContainer.new()
	purse.add_child(coins)
	coins.add_child(_text("FAVORES",Color("2f9e47"),14))
	coins.add_child(_text("%d" % campaign().favors,Color("ffd23f"),34))
	var rule := _text("Cada pista opcional que você encontra vale um favor.",Color("7fbf8a"),13)
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule.custom_minimum_size = Vector2(138,0)
	coins.add_child(rule)
	grid.add_child(purse)
	# What MARÉ writes, the latest two.
	var inbox := PanelContainer.new()
	inbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inbox.add_theme_stylebox_override("panel",_flat(Color("060c07"),Color("1f5a2b")))
	body.add_child(inbox)
	var letters := VBoxContainer.new()
	letters.add_theme_constant_override("separation",0)
	inbox.add_child(letters)
	var messages := Campaign.messages(campaign())
	if messages.is_empty(): letters.add_child(_text("MARÉ está offline.",Color("4a5a4d"),15))
	else: letters.add_child(_text("MARÉ escreve:",Color("2f9e47"),14))
	for letter in messages.slice(-2):
		var line := _text("> "+tr(letter),Color("ffe2a0"),15)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(450,0)
		letters.add_child(line)
	site_status = _text("",Color("202020"),14)
	column.add_child(site_status)
	_status()
	# The tube: a scanline over everything.
	var lines := ColorRect.new()
	lines.size = Vector2(SITE_SIZE)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = SCANLINES
	lines.material = ShaderMaterial.new()
	(lines.material as ShaderMaterial).shader = shader
	site_root.add_child(lines)

func _order_card(id: String) -> PanelContainer:
	var item: Dictionary = Campaign.ORDERS[id]
	var owned: bool = id in campaign().unlocks
	var offered: bool = campaign().cleared.size() >= int(item.after)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(150,0)
	card.add_theme_stylebox_override("panel",_flat(Color("0a140c"),Color("2f9e47") if offered and not owned else Color("1f3a24")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",4)
	card.add_child(row)
	row.add_child(_turntable(id))
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation",0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var name := _text(item.title,Color("e8ffe8") if offered else Color("6d8a72"),15)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.custom_minimum_size = Vector2(80,0)
	text.add_child(name)
	text.add_child(_text(tr("%d FAVOR") % item.cost if int(item.cost) == 1 else tr("%d FAVORES") % item.cost,Color("ffd23f"),14))
	var button := Button.new()
	button.add_theme_font_size_override("font_size",15)
	button.text = "CHEGOU" if owned else (tr("PEDIR  (%d)") % item.cost if offered else "EM BREVE")
	button.disabled = owned or not offered or campaign().favors < int(item.cost)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
		button.add_theme_color_override(state,Color.BLACK)
	button.add_theme_color_override("font_disabled_color",Color("4a5a4d"))
	button.add_theme_stylebox_override("normal",_flat(PHOSPHOR,Color.TRANSPARENT,1))
	button.add_theme_stylebox_override("hover",_flat(Color("b6ffc4"),Color.TRANSPARENT,1))
	button.add_theme_stylebox_override("pressed",_flat(Color("2f9e47"),Color.TRANSPARENT,1))
	button.add_theme_stylebox_override("disabled",_flat(Color("142618"),Color.TRANSPARENT,1))
	button.pressed.connect(func():
		if Campaign.order(id,summary.get("persist",false)): _fill_site())
	text.add_child(button)
	# The browser's status line says what the order does, as it says where a link goes.
	for node in [card,button]:
		node.mouse_entered.connect(func(): _status(tr(item.text)))
		node.mouse_exited.connect(func(): _status())
	return card

func _turntable(id: String) -> SubViewportContainer:
	## The order's PSX model turning on its own little stage, lit from the side.
	var holder := SubViewportContainer.new()
	holder.stretch = true
	holder.custom_minimum_size = Vector2(ITEM_VIEW,ITEM_VIEW)
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	var view := SubViewport.new()
	view.own_world_3d = true
	view.transparent_bg = true
	view.size = Vector2i(ITEM_VIEW,ITEM_VIEW)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	holder.add_child(view)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_CLEAR_COLOR
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("9fb8a4")
	world.environment.ambient_light_energy = .7
	world.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	view.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-.7,.6,0)
	sun.light_energy = 1.3
	view.add_child(sun)
	var spinner := Node3D.new()
	view.add_child(spinner)
	var tilt := Node3D.new()
	tilt.rotation.z = ITEM_TILT.get(id,0.0)
	spinner.add_child(tilt)
	var model := (load("res://assets/shop/%s.glb" % id) as PackedScene).instantiate() as Node3D
	tilt.add_child(model)
	var bounds := AABB()
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		bounds = mesh.get_aabb() if bounds.size == Vector3.ZERO else bounds.merge(mesh.get_aabb())
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.mesh.surface_get_material(surface) as BaseMaterial3D
			if material: material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	model.position = -bounds.get_center()
	var reach := bounds.size.length()
	var eye := Camera3D.new()
	eye.projection = Camera3D.PROJECTION_ORTHOGONAL
	eye.size = reach*.95
	eye.near = .01
	eye.far = reach*6
	view.add_child(eye)
	eye.look_at_from_position(Vector3(0,reach*.55,reach*2),Vector3.ZERO)
	spinners.append(spinner)
	return holder

func _process(dt: float) -> void:
	for spinner in spinners:
		if is_instance_valid(spinner): spinner.rotate_y(dt*ITEM_SPIN)

func _line(text: String,color := Color("ede4cb"),size := 15) -> void:
	var label := _label(text,size,color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_body.add_child(label)

func _open(kind: String) -> void:
	_set_hovered("")
	open_panel = kind
	for child in panel_body.get_children(): child.queue_free()
	match kind:
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

	panel.show()

## The campaign the room shows: the game's own, or the starting one when the room stands alone.
func campaign() -> Dictionary:
	return summary.get("campaign",Campaign.state)

func equip(id: String) -> void:
	equipped = id
	selected_weapon = WEAPONS.filter(func(w): return w[1] == id)[0][0]
	_show_equipped()
	_mark_in_hand()
	if hovered != "": _set_hovered_text()

func _set_hovered_text() -> void:
	var key := hovered
	hovered = ""
	_set_hovered(key)

func _show_equipped() -> void:
	equipped_label.text = tr("NA MÃO: %s") % tr(Simulation.WEAPONS[equipped].name)

func _close() -> void:
	if open_panel == "pc":
		_leave_pc()
		return
	open_panel = ""
	panel.hide()
