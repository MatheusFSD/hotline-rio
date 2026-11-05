extends Control
## The night's mission card and the pause screen, over the level itself: a dark veil from the left,
## then the place types itself out, the title slams in with a jittering neon shadow, a pink rule
## draws under it, the objective types out and the way in lights up. The HUD's fonts and colors,
## no box. Enter or a click on the action goes in; main.gd owns that decision.
signal confirmed
signal menu_requested
const Hud = preload("res://scripts/hud.gd")
const PLACE_AT := .1
const TITLE_AT := .35
const RULE_AT := .55
const BODY_AT := .8
const TYPE_RATE := 55.0     # characters per second
const RULE_WIDTH := 560.0

var hud
var content: VBoxContainer   # first child: tests look for the controls line in it
var place: Label
var title: Label
var rule: ColorRect
var body: Label
var tip: Label
var actions: HBoxContainer
var caret: Label
var button: Button
var menu_button: Button
var controls: Label
var time := 0.0
var veil := 0.0
var rng := RandomNumberGenerator.new()

func _init(owner_hud) -> void:
	hud = owner_hud
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	content = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.anchor_bottom = 1.0
	content.offset_left = 96
	content.offset_right = 96+700
	content.add_theme_constant_override("separation",10)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	place = hud._text(Hud.DIGIT_FONT,28,Hud.CYAN,"")
	content.add_child(place)
	title = hud._text(Hud.TITLE_FONT,64,Hud.BONE,"",Hud.PINK)
	title.add_theme_constant_override("shadow_offset_x",6)
	title.add_theme_constant_override("shadow_offset_y",5)
	content.add_child(title)
	rule = ColorRect.new()
	rule.color = Hud.PINK
	rule.custom_minimum_size = Vector2(0,3)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	content.add_child(rule)
	body = hud._text(Hud.DIGIT_FONT,32,Hud.BONE,"")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(body)
	tip = hud._text(Hud.DIGIT_FONT,24,Color(Hud.BONE,.6),"")
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(tip)
	var gap := Control.new()
	gap.custom_minimum_size.y = 18
	content.add_child(gap)
	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation",6)
	content.add_child(actions)
	caret = hud._text(Hud.TITLE_FONT,24,Hud.PINK,"▸")
	actions.add_child(caret)
	button = _action(true)
	button.pressed.connect(func(): confirmed.emit())
	actions.add_child(button)
	menu_button = _action(false)
	menu_button.text = "MENU PRINCIPAL"
	menu_button.pressed.connect(func(): menu_requested.emit())
	actions.add_child(menu_button)
	var gap_low := Control.new()
	gap_low.custom_minimum_size.y = 26
	content.add_child(gap_low)
	controls = hud._text(Hud.DIGIT_FONT,21,Color(Hud.BONE,.42),"WASD MOVE  ·  MOUSE MIRA E ATIRA  ·  R RECARREGA  ·  G MODO DEUS\nF KATANA / ARMA  ·  RODA ZOOM  ·  SHIFT / Q ESPECTRO  ·  ESC PAUSA")
	content.add_child(controls)
	rng.seed = 7

## A text-only action: signage font, a pink bar at the left when it is the one Enter takes.
func _action(primary: bool) -> Button:
	var node := Button.new()
	node.add_theme_font_override("font",Hud.TITLE_FONT)
	node.add_theme_font_size_override("font_size",26 if primary else 18)
	node.add_theme_color_override("font_color",Hud.BONE if primary else Color(Hud.BONE,.55))
	for key in ["font_hover_color","font_focus_color","font_pressed_color","font_hover_pressed_color"]:
		node.add_theme_color_override(key,Color.WHITE)
	node.add_theme_color_override("font_outline_color",Hud.INK)
	node.add_theme_constant_override("outline_size",6)
	var bar := Hud.PINK if primary else Color(0,0,0,0)
	node.add_theme_stylebox_override("normal",_bar(Color(Hud.PINK,.08 if primary else 0.0),bar))
	node.add_theme_stylebox_override("hover",_bar(Color(Hud.PINK,.2),Hud.PINK))
	node.add_theme_stylebox_override("pressed",_bar(Color(Hud.YELLOW,.2),Hud.YELLOW))
	node.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	node.focus_mode = Control.FOCUS_NONE   # Enter belongs to main.gd
	return node

func _bar(fill: Color,edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.border_width_left = 4
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func show_briefing(briefing: Dictionary) -> void:
	place.text = briefing.place
	title.text = briefing.title
	body.text = briefing.body
	tip.text = briefing.get("tip","")
	button.text = briefing.button
	menu_button.hide()
	_restart()

func show_pause() -> void:
	place.text = ""
	title.text = "PAUSADO"
	body.text = "Respira. A próxima esquina pode esperar."
	tip.text = ""
	button.text = "CONTINUAR  →"
	menu_button.show()
	_restart()

func _restart() -> void:
	time = 0.0
	tip.visible = tip.text != ""
	advance(0.0)

func _process(delta: float) -> void:
	if visible: advance(delta)

## Plays the card's entrance up to `time`; settles into a slow idle once everything is in.
func advance(delta: float) -> void:
	time += delta
	veil = smoothstep(0.0,.35,time)
	queue_redraw()
	place.visible_ratio = _typed(place,time-PLACE_AT)
	var landing := smoothstep(TITLE_AT,TITLE_AT+.18,time)
	title.modulate.a = landing
	title.position.x = lerpf(-40.0,0.0,landing) if landing < 1.0 else 0.0
	# A neon shadow that jitters as the title lands, then now and again like a worn tape.
	var jitter := (time > TITLE_AT and time < TITLE_AT+.3) or fmod(time,4.3) > 4.18
	title.add_theme_constant_override("shadow_offset_x",6+(rng.randi_range(-5,5) if jitter else 0))
	rule.custom_minimum_size.x = RULE_WIDTH*smoothstep(RULE_AT,RULE_AT+.35,time)
	body.visible_ratio = _typed(body,time-BODY_AT)
	var typed_end := BODY_AT+body.get_total_character_count()/TYPE_RATE
	var settle := smoothstep(typed_end,typed_end+.3,time)
	tip.modulate.a = settle
	actions.modulate.a = settle
	controls.modulate.a = settle
	caret.modulate.a = 1.0 if fmod(time,.9) < .6 else .15

func _typed(label: Label,elapsed: float) -> float:
	var total := label.get_total_character_count()
	return 1.0 if total == 0 else clampf(elapsed*TYPE_RATE/total,0.0,1.0)

## Is the card still writing itself out?
func animating() -> bool:
	return actions.modulate.a < 1.0

func _draw() -> void:
	# The veil: dark at the left where the words stand, clear over the right of the level.
	var w := size.x
	var h := size.y
	var ink := Hud.INK
	draw_rect(Rect2(Vector2.ZERO,size),Color(ink,.3*veil))
	draw_polygon(PackedVector2Array([Vector2(0,0),Vector2(w*.72,0),Vector2(w*.72,h),Vector2(0,h)]),
		PackedColorArray([Color(ink,.9*veil),Color(ink,0),Color(ink,0),Color(ink,.9*veil)]))
