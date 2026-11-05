extends CanvasLayer
## In-game HUD in the same voice as the death and level-clear screens: signage and terminal fonts
## floating over the night with a heavy ink outline and a neon drop shadow, no panels. Only what
## matters mid-fight stays: kills and clock, the objective, gun and rounds, the spectre charge.
## Each change kicks: a kill pops the counter and nudges the whole HUD, a shot pops the rounds,
## the bar going quiet slams the new objective in. It steps aside for cinematics (walk-in,
## death beat). Presentation only: main.gd hands it a snapshot of the simulation every frame.
const ResultScreen = preload("res://scripts/result_screen.gd")
const TITLE_FONT := ResultScreen.TITLE_FONT
const DIGIT_FONT := ResultScreen.DIGIT_FONT
const INK := Color("0b0710")
const BONE := Color("f4efe1")
const PINK := Color("ff4fa3")
const CYAN := Color("53e8ff")
const YELLOW := Color("ffd23f")
const RED := Color("ff2a3d")
const MARGIN := 30.0
const LOW_AMMO := .25    # fraction of the magazine that turns the rounds red

## A row of blocks, PS1-style, for the magazine and the spectre charge.
class Segments extends Control:
	var count := 16
	var fill := 1.0
	const EDGE := Color("0b0710")
	var lit := Color.WHITE
	var dim := Color(1,1,1,.18)
	func _draw() -> void:
		var gap := 3.0
		var w := (size.x-gap*(count-1))/count
		var full := fill*count
		for i in count:
			var rect := Rect2(i*(w+gap),0,w,size.y)
			draw_rect(rect.grow(2),EDGE)
			var part := clampf(full-i,0,1)
			draw_rect(rect,dim)
			if part > 0: draw_rect(Rect2(rect.position,Vector2(w*part,size.y)),lit)

var root: Control          # menus (briefing, pause) hang here and never fade with the HUD
var content: Control       # everything that fades and shakes
var phase_tint: ColorRect
var kills: Label
var kills_caption: Label
var clock: Label
var objective: Label
var weapon: Label
var spare: Label           # the other weapon, one F away
var ammo: Label
var ammo_total: Label
var magazine: Segments
var spectre_caption: Label
var spectre: Segments
var god_badge: Label       # modo deus is on
var rec: Label             # night twelve on air: Jairo is broadcasting it live
var kills_box: Control
var ammo_box: Control
var objective_box: Control
var clue_box: Control      # a clue just taken: what it is and what it says
var clue_title: Label
var clue_text: Label
var flash: ColorRect       # the photo the hero takes of it
var clue_time := -1.0
const CLUE_HOLD := 4.0

var active := true
var trauma := 0.0
var time := 0.0
var kill_pop := 0.0
var ammo_pop := 0.0
var objective_pop := 0.0
var last := {}
var rng := RandomNumberGenerator.new()

func _init() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	phase_tint = ColorRect.new()
	phase_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	phase_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phase_tint.color = Color(.25,.8,1.0,0)
	root.add_child(phase_tint)
	content = Control.new()
	content.size = Vector2(1280,800)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.modulate.a = 0.0   # the night opens on the briefing; the HUD fades in with play
	root.add_child(content)
	# Top left: how many are down, and the clock.
	kills_box = _box(Vector2(MARGIN,16),Vector2(260,110),Vector2(0,40))
	kills_caption = _text(DIGIT_FONT,26,PINK,"ELIMINADOS")
	kills_box.add_child(kills_caption)
	kills = _text(TITLE_FONT,50,BONE,"00/08",PINK)
	kills.position.y = 18
	kills_box.add_child(kills)
	clock = _text(DIGIT_FONT,34,BONE,"00:00.0")
	clock.position = Vector2(MARGIN,98)
	content.add_child(clock)
	god_badge = _text(TITLE_FONT,22,YELLOW,"MODO DEUS",Color("7a5a00"))
	god_badge.position = Vector2(MARGIN,142)
	god_badge.visible = false
	content.add_child(god_badge)
	rec = _text(DIGIT_FONT,28,RED,"●  REC")
	rec.size = Vector2(200,34)
	rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rec.position = Vector2(1280-MARGIN-200,86)
	rec.visible = false
	content.add_child(rec)
	# Top right: what to do now.
	objective_box = _box(Vector2(1280-MARGIN-560,22),Vector2(560,60),Vector2(560,30))
	objective = _text(DIGIT_FONT,34,BONE,"")
	objective.size = Vector2(560,60)
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective_box.add_child(objective)
	# Bottom left: what F swaps to, the weapon in hand, its rounds and the magazine.
	spare = _text(DIGIT_FONT,24,Color(BONE,.55),"F  KATANA")
	spare.position = Vector2(MARGIN,800-178)
	content.add_child(spare)
	weapon = _text(TITLE_FONT,24,YELLOW,"PISTOLA",INK)
	weapon.position = Vector2(MARGIN,800-150)
	content.add_child(weapon)
	ammo_box = _box(Vector2(MARGIN,800-128),Vector2(300,80),Vector2(0,60))
	ammo = _text(DIGIT_FONT,84,BONE,"12")
	ammo_box.add_child(ammo)
	ammo_total = _text(DIGIT_FONT,40,Color(BONE,.6),"/12")
	ammo_box.add_child(ammo_total)
	magazine = Segments.new()
	magazine.position = Vector2(MARGIN,800-46)
	magazine.size = Vector2(240,12)
	magazine.lit = YELLOW
	content.add_child(magazine)
	# Bottom right: the spectre charge.
	spectre_caption = _text(DIGIT_FONT,30,CYAN,"ESPECTRO")
	spectre_caption.size = Vector2(320,34)
	spectre_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	spectre_caption.position = Vector2(1280-MARGIN-320,800-84)
	content.add_child(spectre_caption)
	spectre = Segments.new()
	spectre.position = Vector2(1280-MARGIN-240,800-46)
	spectre.size = Vector2(240,14)
	spectre.lit = CYAN
	content.add_child(spectre)
	# Top middle: a clue just taken, under a camera flash.
	clue_box = _box(Vector2(640-380,150),Vector2(760,150),Vector2(380,40))
	var clue_caption := _text(DIGIT_FONT,26,YELLOW,"PISTA")
	clue_caption.size.x = 760
	clue_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clue_box.add_child(clue_caption)
	clue_title = _text(TITLE_FONT,36,BONE,"",Color("7a5a00"))
	clue_title.position.y = 26
	clue_title.size.x = 760
	clue_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clue_box.add_child(clue_title)
	clue_text = _text(DIGIT_FONT,26,Color(BONE,.85),"")
	clue_text.position.y = 76
	clue_text.size.x = 760
	clue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	clue_box.add_child(clue_text)
	clue_box.visible = false
	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(1,1,1,0)
	root.add_child(flash)

## A clue taken: a camera flash, then its name and words for a few seconds.
func show_clue(title: String,text: String) -> void:
	clue_title.text = title
	clue_text.text = text
	clue_time = 0.0
	clue_box.visible = true
	flash.color.a = .55
	trauma = minf(1.0,trauma+.3)

func _box(at: Vector2,box_size: Vector2,pivot: Vector2) -> Control:
	var box := Control.new()
	box.position = at
	box.size = box_size
	box.pivot_offset = pivot
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(box)
	return box

func _text(font: Font,font_size: int,color: Color,value: String,shadow := Color(INK,.8)) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_override("font",font)
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	node.add_theme_color_override("font_outline_color",INK)
	node.add_theme_constant_override("outline_size",8 if font == TITLE_FONT else 6)
	node.add_theme_color_override("font_shadow_color",shadow)
	node.add_theme_constant_override("shadow_offset_x",4)
	node.add_theme_constant_override("shadow_offset_y",4)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func refresh(data: Dictionary) -> void:
	## data: kills, total, elapsed, weapon, melee, ammo, magazine, reload, reload_time, mana, phasing, locked, god, active
	# Three steps: kill them all, then (if the night has one) take the clue, then the way out.
	var cleared: bool = data.get("cleared",data.kills >= data.total)
	var hunting: bool = data.kills >= data.total and not cleared
	if last.has("kills"):
		if data.kills > last.kills:
			kill_pop = 1.0
			trauma = minf(1.0,trauma+.55)
		if data.ammo < last.ammo and data.weapon == last.weapon: ammo_pop = 1.0
		if (cleared and not last.cleared) or (hunting and not last.hunting):
			objective_pop = 1.0
			trauma = 1.0
	last = data.duplicate()
	last.cleared = cleared
	last.hunting = hunting
	kills.text = "%02d/%02d" % [data.kills,data.total]
	kills.add_theme_color_override("font_color",CYAN if cleared else BONE)
	kills.add_theme_color_override("font_shadow_color",CYAN.darkened(.5) if cleared else PINK)
	clock.text = "%02d:%04.1f" % [int(data.elapsed)/60,fmod(data.elapsed,60.0)]
	objective.text = String(data.get("exit_hint","SAIA PELO BECO  →")) if cleared else ("PEGUE A PISTA" if hunting else "ELIMINE TODOS")
	var loud := cleared or hunting
	objective.add_theme_font_override("font",TITLE_FONT if loud else DIGIT_FONT)
	objective.add_theme_font_size_override("font_size",30 if loud else 34)
	objective.add_theme_color_override("font_color",CYAN if cleared else (YELLOW if hunting else Color(BONE,.8)))
	objective.add_theme_color_override("font_shadow_color",Color("0d5f6e") if cleared else (Color("7a5a00") if hunting else INK))
	# Katana in hand: no rounds to count; the gun waits one F away with its magazine as it was.
	var melee: bool = data.get("melee",false)
	weapon.text = "KATANA" if melee else data.weapon
	weapon.add_theme_color_override("font_color",CYAN if melee else YELLOW)
	spare.text = ("F  %s  %02d/%d" % [tr(data.weapon),data.ammo,data.magazine]) if melee else "F  KATANA"
	ammo_box.visible = not melee
	magazine.visible = not melee
	var reloading: bool = data.reload > 0
	var low: bool = float(data.ammo) <= data.magazine*LOW_AMMO
	ammo.text = "RECARREGANDO" if reloading else "%02d" % data.ammo
	ammo.add_theme_font_size_override("font_size",44 if reloading else 84)
	ammo.add_theme_color_override("font_color",YELLOW if reloading else (RED if low else BONE))
	ammo_total.visible = not reloading
	ammo_total.text = "/%d" % data.magazine
	ammo_total.position = Vector2(ammo.get_minimum_size().x+6,30)
	magazine.count = clampi(data.magazine,1,24)
	magazine.fill = 1.0-data.reload/maxf(data.reload_time,.01) if reloading else float(data.ammo)/data.magazine
	magazine.lit = CYAN if reloading else (RED if low else YELLOW)
	magazine.queue_redraw()
	spectre.fill = data.mana/100.0
	var drained: bool = data.locked or data.mana < 12
	spectre.lit = RED if drained and not data.phasing else CYAN
	spectre.queue_redraw()
	spectre_caption.text = "ESPECTRO ATIVO" if data.phasing else ("ESPECTRO ESGOTADO" if drained else "ESPECTRO")
	spectre_caption.add_theme_color_override("font_color",RED if drained and not data.phasing else CYAN)
	god_badge.visible = data.get("god",false)
	active = data.active   # the fade itself runs in advance()

func _process(dt: float) -> void:
	advance(dt)

## "● REC" in the corner while the night is on air.
func set_rec(on: bool) -> void:
	rec.visible = on

func advance(dt: float) -> void:
	time += dt
	if rec.visible: rec.modulate.a = 1.0 if fmod(time,1.2) < .8 else .25   # the recording light blinks
	content.modulate.a = move_toward(content.modulate.a,1.0 if active else 0.0,dt*6.0)
	trauma = maxf(0.0,trauma-dt*2.2)
	kill_pop = maxf(0.0,kill_pop-dt*4.0)
	flash.color.a = maxf(0.0,flash.color.a-dt*2.5)
	if clue_time >= 0:
		clue_time += dt
		clue_box.visible = clue_time < CLUE_HOLD
		clue_box.modulate.a = clampf((CLUE_HOLD-clue_time)/.4,0,1)
		clue_box.scale = Vector2.ONE*(1.0+.25*maxf(0,1.0-clue_time*5.0))
		if clue_time >= CLUE_HOLD: clue_time = -1.0
	ammo_pop = maxf(0.0,ammo_pop-dt*9.0)
	objective_pop = maxf(0.0,objective_pop-dt*2.5)
	var shake := trauma*trauma
	content.position = Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1))*10.0*shake
	kills_box.scale = Vector2.ONE*(1.0+.45*kill_pop)
	kills_box.rotation = -.12*kill_pop
	ammo_box.scale = Vector2.ONE*(1.0+.18*ammo_pop)
	objective_box.scale = Vector2.ONE*(1.0+1.2*objective_pop*objective_pop)
	objective_box.rotation = -.05*objective_pop+(.02*sin(time*3.0) if last.get("cleared",false) else 0.0)
	# Things that need the eye blink: the way out, an empty-ish gun, a reload, the spectre on.
	var blink := fmod(time,.5) < .32
	if last.get("cleared",false): objective.visible = blink or objective_pop > 0
	else: objective.visible = true
	var low: bool = last.has("ammo") and float(last.ammo) <= last.magazine*LOW_AMMO
	ammo.visible = blink or not (low or last.get("reload",0.0) > 0)
	spectre_caption.visible = blink or not last.get("phasing",false)
