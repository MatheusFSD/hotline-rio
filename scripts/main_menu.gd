extends Control
## Main menu. The Lapa at night runs behind (MenuBackdrop); the menu keeps to a shadow at the left,
## quiet: place, the title in the HUD's signage font with its neon shadow, a pink rule, one line of
## tone and a short list of text-only options. Arrows or the mouse move, Enter chooses. New game
## plays the newscast first; load game opens the night the save points to, straight on its card.
const Hud = preload("res://scripts/hud.gd")
const Main = preload("res://scripts/main.gd")
const Lang = preload("res://scripts/lang.gd")
const Campaign = preload("res://scripts/campaign.gd")
const MenuBackdrop = preload("res://scripts/menu_backdrop.gd")
const STAGGER := .07          # seconds between options sliding in
const THEME := "res://assets/audio/menu_theme.ogg"
const THEME_DB := -6.0
## The level select (FASES), a development tool: offered only while this file exists.
const LEVEL_SELECT := "res://scripts/level_select.gd"

var backdrop
var column: VBoxContainer
var title: Label
var rule: ColorRect
var options: VBoxContainer
var hint: Label
var fade: ColorRect
var page := ""
var time := 0.0
var page_time := 0.0
var leaving := false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	Lang.setup()
	get_tree().auto_accept_quit = false   # the window close goes through quit_game
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop = MenuBackdrop.new()
	add_child(backdrop)
	var shade := TextureRect.new()
	var gradient := GradientTexture2D.new()
	gradient.gradient = Gradient.new()
	gradient.gradient.set_color(0,Color(Hud.INK,.92))
	gradient.gradient.set_color(1,Color(Hud.INK,0))
	gradient.fill_to = Vector2(1,0)
	shade.texture = gradient
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.anchor_right = .62
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	column = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.anchor_bottom = 1.0
	column.offset_left = 96
	column.offset_right = 96+560
	column.add_theme_constant_override("separation",8)
	add_child(column)
	column.add_child(_text(Hud.DIGIT_FONT,28,Hud.CYAN,"LAPA  /  RIO DE JANEIRO"))
	title = _text(Hud.TITLE_FONT,88,Hud.BONE,"HOTLINE RIO",Hud.PINK)
	title.add_theme_constant_override("shadow_offset_x",7)
	title.add_theme_constant_override("shadow_offset_y",6)
	title.add_theme_constant_override("line_spacing",-14)
	column.add_child(title)
	rule = ColorRect.new()
	rule.color = Hud.PINK
	rule.custom_minimum_size = Vector2(0,3)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(rule)
	column.add_child(_text(Hud.DIGIT_FONT,28,Color(Hud.BONE,.72),"Um tiro mata. Ninguém viu nada."))
	var gap := Control.new()
	gap.custom_minimum_size.y = 40
	column.add_child(gap)
	options = VBoxContainer.new()
	options.add_theme_constant_override("separation",2)
	column.add_child(options)
	var gap_low := Control.new()
	gap_low.custom_minimum_size.y = 34
	column.add_child(gap_low)
	hint = _text(Hud.DIGIT_FONT,20,Color(Hud.BONE,.4),"ENTER ESCOLHE  ·  SETAS MOVEM")
	column.add_child(hint)
	fade = ColorRect.new()
	fade.color = Color(0,0,0,1)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	create_tween().tween_property(fade,"color:a",0.0,.8)
	show_page("main")
	_play_theme()

## The menu theme (synthesised by tools/build_music.py, 40 s seamless loop), rising slowly.
var theme_player: AudioStreamPlayer

func _play_theme() -> void:
	var stream := load(THEME) as AudioStreamOggVorbis
	stream.loop = true
	theme_player = AudioStreamPlayer.new()
	theme_player.stream = stream
	theme_player.volume_db = -40.0
	add_child(theme_player)
	theme_player.play()
	create_tween().tween_property(theme_player,"volume_db",THEME_DB,3.0)

## Leaving the menu, the theme stops. Quitting from here (SAIR or the window's close button) stops
## it a few frames early: the audio server only lets go of a playback on its next mix, and quitting
## mid-play leaves the stream alive at exit.
func _exit_tree() -> void:
	if theme_player: theme_player.stop()
	get_tree().auto_accept_quit = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: quit_game()

func quit_game() -> void:
	leaving = true
	theme_player.stop()
	for i in 3: await get_tree().process_frame
	get_tree().quit()

func _text(font: Font,font_size: int,color: Color,value: String,shadow := Color(Hud.INK,.8)) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_override("font",font)
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	node.add_theme_color_override("font_outline_color",Hud.INK)
	node.add_theme_constant_override("outline_size",8 if font == Hud.TITLE_FONT else 6)
	node.add_theme_color_override("font_shadow_color",shadow)
	node.add_theme_constant_override("shadow_offset_x",4)
	node.add_theme_constant_override("shadow_offset_y",4)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

## The options of one page: main (new, load, levels, languages, quit), levels or languages.
func show_page(name: String) -> void:
	page = name
	page_time = 0.0
	for child in options.get_children():
		options.remove_child(child)
		child.queue_free()
	match name:
		"main":
			_option("NOVO JOGO",new_game)
			var load_option := _option("CARREGAR JOGO",load_game)
			load_option.disabled = not Campaign.exists()
			var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(Campaign.PATH)) if Campaign.exists() else null
			if saved is Dictionary:   # the night it opens on
				load_option.text = "%s  ·  %02d" % [tr("CARREGAR JOGO"),int(saved.get("level",0))+1]
			if ResourceLoader.exists(LEVEL_SELECT): _option("FASES",show_page.bind("levels"))
			_option("IDIOMAS",show_page.bind("languages"))
			_option("SAIR",quit_game)
		"levels":
			load(LEVEL_SELECT).fill(self)
		"languages":
			for entry in Lang.LANGUAGES:
				var chosen: bool = Lang.current() == entry[0]
				var button := _option(entry[1],_choose_language.bind(entry[0]))
				button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
				if chosen: button.add_theme_color_override("font_color",Hud.CYAN)   # the one in use
			_option("VOLTAR",show_page.bind("main"))
	for child in options.get_children():
		if not (child as Button).disabled:
			child.grab_focus()
			break

func _choose_language(code: String) -> void:
	Lang.choose(code)
	show_page("languages")
	options.get_child(Lang.LANGUAGES.map(func(e): return e[0]).find(code)).grab_focus()

## A text-only option: terminal font, a pink marker and bar when it has the focus.
func _option(label: String,action: Callable) -> Button:
	var node := Button.new()
	node.text = label
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	node.add_theme_font_override("font",Hud.DIGIT_FONT)
	node.add_theme_font_size_override("font_size",40)
	node.add_theme_color_override("font_color",Color(Hud.BONE,.78))
	for key in ["font_hover_color","font_focus_color","font_pressed_color","font_hover_pressed_color"]:
		node.add_theme_color_override(key,Color.WHITE)
	node.add_theme_color_override("font_disabled_color",Color(Hud.BONE,.25))
	node.add_theme_color_override("font_outline_color",Hud.INK)
	node.add_theme_constant_override("outline_size",6)
	node.add_theme_stylebox_override("normal",_bar(Color(0,0,0,0),Color(0,0,0,0)))
	node.add_theme_stylebox_override("disabled",_bar(Color(0,0,0,0),Color(0,0,0,0)))
	node.add_theme_stylebox_override("hover",_bar(Color(Hud.PINK,.14),Hud.PINK))
	node.add_theme_stylebox_override("focus",_bar(Color(Hud.PINK,.14),Hud.PINK))
	node.add_theme_stylebox_override("pressed",_bar(Color(Hud.YELLOW,.2),Hud.YELLOW))
	node.add_theme_stylebox_override("hover_pressed",_bar(Color(Hud.YELLOW,.2),Hud.YELLOW))
	node.mouse_entered.connect(func(): if not node.disabled: node.grab_focus())
	node.pressed.connect(func(): if not leaving: action.call())
	node.modulate.a = 0.0
	options.add_child(node)
	return node

func _bar(fill: Color,edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.border_width_left = 4
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 0
	style.content_margin_bottom = 2
	return style

func _process(delta: float) -> void:
	time += delta
	page_time += delta
	rule.custom_minimum_size.x = 520.0*smoothstep(.3,.9,time)
	# Options slide in one after another; the focused one breathes.
	for i in options.get_child_count():
		var button := options.get_child(i) as Button
		var k := smoothstep(.15+i*STAGGER,.4+i*STAGGER,page_time+(0.0 if page != "main" else -.4*(1.0-smoothstep(0,1.2,time))))
		button.modulate.a = k
		button.position.x = lerpf(-24.0,0.0,k)
	# The title's neon shadow jitters now and then, like a worn tape.
	var jitter := fmod(time,4.3) > 4.18
	title.add_theme_constant_override("shadow_offset_x",7+(rng.randi_range(-5,5) if jitter else 0))
	title.modulate.a = .94+.06*sin(time*1.7) if not jitter else rng.randf_range(.75,1.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and page != "main": show_page("main")

func new_game() -> void:
	Campaign.new_game()
	_launch({"level":0,"weapon":"pistol","news":true})

func load_game() -> void:
	if not Campaign.load_saved(): return
	_launch({"level":Campaign.state.level,"weapon":Campaign.state.weapon,"news":false})

func _launch(opening: Dictionary) -> void:
	leaving = true
	Main.opening = opening
	var out := create_tween()
	out.tween_property(fade,"color:a",1.0,.5)
	out.parallel().tween_property(theme_player,"volume_db",-40.0,.5)   # the theme leaves with the light
	out.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
