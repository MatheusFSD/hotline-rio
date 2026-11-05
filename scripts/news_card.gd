extends CanvasLayer
## A between-acts newscast as a flat 2D sketch on the tube: the "Alerta Rio" graphics of the
## opening (bug, live tag, lower third, ticker, captions) over painted placeholder shots. It reads
## assets/news/<id>.json (clock, bug, segments [shot, who, headline, caption, seconds], ticker)
## so the 3D version can take the same data later. Enter skips; `finished` when it switches off.
signal finished
const CRT = preload("res://shaders/crt.gdshader")
const RESOLUTION := Vector2i(640,480)
const POWER_ON := .45
const POWER_OFF := .6

var data: Dictionary
var time := 0.0
var total := 0.0
var done := false
var viewport: SubViewport
var screen: TextureRect
var crt: ShaderMaterial
var picture: Control
var heavy := SystemFont.new()
var mono := SystemFont.new()
var live_dot: ColorRect
var lower: Control
var who: Label
var headline: Label
var ticker: Label
var caption: Label
var caption_box: CenterContainer
var current := -1

func _init(news: Dictionary) -> void:
	data = news
	layer = 26
	heavy.font_names = PackedStringArray(["Arial Black","Impact","Arial"])
	heavy.font_weight = 900
	mono.font_names = PackedStringArray(["Courier New","Consolas","Monospace"])
	mono.font_weight = 700
	for segment in data.segments: total += float(segment.seconds)
	total += POWER_ON
	var black := ColorRect.new()
	black.color = Color("050407")
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	viewport = SubViewport.new()
	viewport.size = RESOLUTION
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	picture = _layer(viewport)
	picture.draw.connect(_paint)
	_build_graphics()
	crt = ShaderMaterial.new()
	crt.shader = CRT
	screen = TextureRect.new()
	screen.texture = viewport.get_texture()
	screen.material = crt
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.offset_top = 40
	screen.offset_bottom = -40
	add_child(screen)
	advance(0.0)

## A segment may play only "when" the campaign so far fits: "civilians" killed or "clean", "bitter"
## (three or more killed), "souza" (his file was taken). `of` is the campaign state, or just the
## number of civilians killed.
static func load_news(path: String,of = 0) -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var state: Dictionary = of if of is Dictionary else {"civilians_killed":int(of)}
	var killed := int(state.get("civilians_killed",0))
	var told := ["civilians" if killed > 0 else "clean"]
	if killed >= 3: told.append("bitter")
	if "prontuario_souza" in state.get("clues",[]): told.append("souza")
	data.segments = data.segments.filter(func(s): return not s.has("when") or s.when in told)
	return data

func _process(dt: float) -> void:
	advance(dt)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_ESCAPE]:
		get_viewport().set_input_as_handled()
		skip()

func skip() -> void:
	## First press jumps to the switch-off, the second leaves at once.
	if time < total: time = total
	else: _finish()

func advance(dt: float) -> void:
	if done: return
	time += dt
	# The tube opens to a line, then to the picture; at the end it collapses to a dot.
	var opening := clampf(time/POWER_ON,0.0,1.0)
	var closing := clampf((time-total)/POWER_OFF,0.0,1.0)
	crt.set_shader_parameter("open_y",clampf(opening*2.0,0.02,1.0)*(1.0-clampf(closing*2.0,0.0,.98)))
	crt.set_shader_parameter("open_x",clampf(opening*2.0-.6,0.02,1.0)*(1.0-clampf(closing*2.0-1.0,0.0,.98)))
	crt.set_shader_parameter("flash",maxf(1.0-opening*2.0,0.0)*.6+closing*.4)
	crt.set_shader_parameter("static_amount",.06+maxf(1.0-opening,0.0)*.6)
	var index := segment_at(time)
	if index != current:
		current = index
		var segment: Dictionary = data.segments[index]
		who.text = tr(segment.who)
		headline.text = tr(segment.headline)
		caption.text = ""
	var local := time-POWER_ON-_start(current)
	var line: String = tr(data.segments[current].caption)
	caption.text = line.left(int(clampf((local-.6)*38.0,0.0,line.length())))
	caption_box.visible = caption.text != ""
	lower.visible = local > .35
	live_dot.visible = fmod(time*1.5,1.0) < .6
	ticker.position.x = -fposmod(time*72.0,ticker.get_minimum_size().x/2.0)
	picture.queue_redraw()
	if time >= total+POWER_OFF: _finish()

func segment_at(at: float) -> int:
	var clock := POWER_ON
	for i in data.segments.size():
		clock += float(data.segments[i].seconds)
		if at < clock: return i
	return data.segments.size()-1

func _start(index: int) -> float:
	var clock := 0.0
	for i in index: clock += float(data.segments[i].seconds)
	return clock

func _finish() -> void:
	if done: return
	done = true
	finished.emit()

# ---------------------------------------------------------------- the shots, painted
func _paint() -> void:
	var shot: String = data.segments[current].shot
	if shot == "press": _paint_press()
	else: _paint_studio()

func _paint_studio() -> void:
	## The anchor at the desk, the city at night on the screen behind him.
	var p := picture
	p.draw_rect(Rect2(0,0,640,480),Color("0c1630"))
	p.draw_rect(Rect2(0,0,640,300),Color("13254d"))
	for i in 14:
		var w := 26.0+fmod(i*37.0,30.0)
		var h := 50.0+fmod(i*53.0,110.0)
		var x := i*48.0-10.0
		p.draw_rect(Rect2(x,300-h,w,h),Color("0a1226"))
		for k in int(h/18.0):
			if fmod(i*7.0+k*3.0,5.0) < 2.0: p.draw_rect(Rect2(x+6,300-h+8+k*18,5,6),Color("e8c56a",.7))
	p.draw_rect(Rect2(0,296,640,6),Color("c4161c"))
	_figure(Vector2(320,300),Color("1d2230"),Color("c4161c"),1.0)
	p.draw_rect(Rect2(60,318,520,162),Color("2a2f3c"))
	p.draw_rect(Rect2(60,318,520,8),Color("3d4456"))
	p.draw_string(heavy,Vector2(250,370),"ALERTA RIO",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("ffd21a",.8))

func _paint_press() -> void:
	## A press conference: the slogan wall, the podium bristling with microphones, flashes. He is
	## framed from the waist up, as he always is.
	var p := picture
	p.draw_rect(Rect2(0,0,640,480),Color("0e1a3a"))
	for row in 6:
		for col in 4:
			var x := col*190.0-40.0+(95.0 if row%2 else 0.0)
			p.draw_string(heavy,Vector2(x,52+row*52),"ORDEM NA CASA",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("f2efe6",.18))
	_figure(Vector2(320,262),Color("d9cfb4"),Color("f4f1ea"),1.12)
	p.draw_rect(Rect2(220,212,200,268),Color("1b2a52"))
	p.draw_rect(Rect2(220,212,200,10),Color("2b3f74"))
	p.draw_string(heavy,Vector2(244,262),"CASTELAR",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("f2efe6"))
	var flags := [Color("c4161c"),Color("1f6fd6"),Color("ffd21a"),Color("2a9d55"),Color("ffffff")]
	for i in flags.size():
		var x := 262.0+i*24.0
		p.draw_line(Vector2(x,216),Vector2(318+i*2.0,186),Color("222222"),3.0)
		p.draw_rect(Rect2(x-7,208,14,12),flags[i])
	# Camera flashes from the press pit.
	for i in 3:
		var beat := fmod(time*1.7+i*.37,1.0)
		if beat < .08:
			var at := Vector2(80+fmod(i*211.0+floor(time*1.7)*97.0,480.0),400+i*18.0)
			p.draw_circle(at,26.0,Color(1,1,1,.85))
			p.draw_rect(Rect2(0,0,640,480),Color(1,1,1,.12))

func _figure(base: Vector2,suit: Color,tie: Color,scale: float) -> void:
	## A head-and-shoulders silhouette: suit, collar, tie, head.
	var p := picture
	var s := scale
	var shoulders := PackedVector2Array([base+Vector2(-120,0)*s,base+Vector2(-104,-88)*s,base+Vector2(-40,-112)*s,
		base+Vector2(40,-112)*s,base+Vector2(104,-88)*s,base+Vector2(120,0)*s])
	p.draw_colored_polygon(shoulders,suit)
	p.draw_colored_polygon(PackedVector2Array([base+Vector2(-26,-112)*s,base+Vector2(26,-112)*s,base+Vector2(0,-70)*s]),Color("ece6dc"))
	p.draw_colored_polygon(PackedVector2Array([base+Vector2(-8,-104)*s,base+Vector2(8,-104)*s,base+Vector2(12,-30)*s,
		base+Vector2(0,-14)*s,base+Vector2(-12,-30)*s]),tie)
	p.draw_rect(Rect2(base+Vector2(-18,-140)*s,Vector2(36,32)*s),Color("b98a6a"))
	p.draw_circle(base+Vector2(0,-170)*s,44.0*s,Color("c99878"))
	p.draw_rect(Rect2(base+Vector2(-44,-216)*s,Vector2(88,30)*s),Color("2b2420") if suit.v < .5 else Color("bcbcbc"))

# ---------------------------------------------------------------- the station's graphics
func _build_graphics() -> void:
	var canvas := CanvasLayer.new()
	viewport.add_child(canvas)
	var root := _layer(canvas)
	var bug := _layer(root)
	_box(Color("c4161c"),Rect2(16,14,156,32),bug)
	bug.add_child(_text("ALERTA RIO",20,Color("ffd21a"),heavy,Vector2(24,15)))
	_box(Color("111111"),Rect2(16,46,156,15),bug)
	bug.add_child(_text(tr(data.get("bug","PLANTÃO")),10,Color.WHITE,heavy,Vector2(24,46)))
	_box(Color("c4161c"),Rect2(526,16,98,22),bug)
	live_dot = _box(Color.WHITE,Rect2(533,23,8,8),bug)
	bug.add_child(_text(tr("AO VIVO"),13,Color.WHITE,heavy,Vector2(546,18)))
	bug.add_child(_text(data.get("clock",""),14,Color.WHITE,heavy,Vector2(540,40)))
	lower = _layer(root)
	_box(Color("c4161c"),Rect2(22,342,300,24),lower)
	who = _text("",14,Color.WHITE,heavy,Vector2(32,344))
	lower.add_child(who)
	_box(Color("ffd21a"),Rect2(22,366,596,58),lower)
	headline = _text("",19,Color("111111"),heavy,Vector2(32,370))
	headline.size = Vector2(576,52)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lower.add_child(headline)
	var strip := _layer(root)
	_box(Color("0d1d3f"),Rect2(0,436,640,26),strip)
	var clip := Control.new()
	clip.position = Vector2(104,436)
	clip.size = Vector2(536,26)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(clip)
	ticker = _text(tr(data.ticker)+tr(data.ticker),14,Color.WHITE,heavy,Vector2(0,4))
	clip.add_child(ticker)
	_box(Color("c4161c"),Rect2(0,436,104,26),strip)
	strip.add_child(_text(tr("PLANTÃO"),13,Color("ffd21a"),heavy,Vector2(14,441)))
	caption_box = CenterContainer.new()
	caption_box.position = Vector2(20,284)
	caption_box.size = Vector2(600,50)
	caption_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(caption_box)
	caption = _text("",15,Color.WHITE,mono)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.custom_minimum_size = Vector2(560,0)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var black := StyleBoxFlat.new()
	black.bg_color = Color(0,0,0,.88)
	black.content_margin_left = 8
	black.content_margin_right = 8
	black.content_margin_top = 3
	black.content_margin_bottom = 3
	caption.add_theme_stylebox_override("normal",black)
	caption_box.add_child(caption)

func _text(value: String,size: int,color: Color,font: Font,position := Vector2.ZERO) -> Label:
	var label := Label.new()
	label.text = value
	label.position = position
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.add_theme_font_override("font",font)
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	return label

func _box(color: Color,rect: Rect2,parent: Node) -> ColorRect:
	var box := ColorRect.new()
	box.color = color
	box.position = rect.position
	box.size = rect.size
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	return box

func _layer(parent: Node) -> Control:
	var control := Control.new()
	control.size = Vector2(RESOLUTION)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(control)
	return control
