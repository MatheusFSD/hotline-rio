extends CanvasLayer
## Death and level-clear screens. The title is slammed onto the glass like a thrown street sign,
## then waves and flickers; the tally slides in and rolls every number up, each step kicking the
## screen; the night behind is tinted, split and torn (shaders/result_fx.gdshader). Everything is
## a function of `clock`, so skipping just jumps it. Presentation only: main.gd decides what
## Enter does, a click only asks through `confirmed`.
signal confirmed
signal slammed(heavy: bool)    # the title or the win's grade hits the glass
signal ticked(progress: float) # a number of the tally turns
const TITLE_FONT := preload("res://assets/fonts/Bungee-Regular.ttf")
const DIGIT_FONT := preload("res://assets/fonts/VT323-Regular.ttf")
const FX := preload("res://shaders/result_fx.gdshader")
const DEATH_QUIPS := ["DEU RUIM.","VACILOU.","FOI DE ARRASTA.","JÁ ERA, PARCEIRO.","A LAPA NÃO PERDOA.","UM TIRO. SÓ UM."]
const DEATH_COLORS := [Color("ff2a3d"),Color("f4efe1")]
const WIN_COLORS := [Color("ff4fa3"),Color("53e8ff"),Color("ffd23f")]   # the bar's neon
const CLICK_GUARD := .45   # a trigger finger still down at the moment of death must not restart
const SLAM := .22          # seconds for the title to land
const SLIDE := .15         # seconds for a tally row to slide in
const ROLL := .45          # seconds for its number to roll up
const TITLE_LANDS := .08   # when the thrown title first reaches the glass
const GRADE_LANDS := .05   # the same for the grade
const TICK_EVERY := .04    # the digits turn faster than anyone could hear them all
## Points are only shown, never fed back into the game: kills plus a bonus for every second under a minute.
const GRADES := [[13000,"S"],[11000,"A"],[9500,"B"],[8500,"C"],[0,"D"]]

var mode := ""
var clock := 0.0
var trauma := 0.0
var flash_alpha := 0.0
var palette: Array = DEATH_COLORS
var rows: Array[Dictionary] = []
var title_text := ""
var grade_at := INF
var prompt_at := 0.0
var done_at := 0.0
var points := 0
var grade_letter := ""
var title_landed := false
var grade_landed := false
var last_tick := -1.0
var rng := RandomNumberGenerator.new()

var fx: ColorRect
var fx_material: ShaderMaterial
var stage: Control
var title_box: Control
var title: RichTextLabel
var quip: Label
var grade: Label
var prompt: Label
var flash: ColorRect

func _init() -> void:
	layer = 10
	visible = false
	fx = ColorRect.new()
	fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_STOP   # clicks land here instead of the game
	fx_material = ShaderMaterial.new()
	fx_material.shader = FX
	fx.material = fx_material
	fx.gui_input.connect(_on_click)
	add_child(fx)
	stage = Control.new()
	stage.size = Vector2(1280,800)
	stage.pivot_offset = stage.size/2
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	title_box = Control.new()
	title_box.position = Vector2(0,110)
	title_box.size = Vector2(1280,150)
	title_box.pivot_offset = title_box.size/2
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(title_box)
	title = RichTextLabel.new()
	title.bbcode_enabled = true
	title.scroll_active = false
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size = title_box.size
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_override("normal_font",TITLE_FONT)
	title.add_theme_font_size_override("normal_font_size",92)
	title.add_theme_constant_override("shadow_offset_x",8)
	title.add_theme_constant_override("shadow_offset_y",8)
	title.add_theme_constant_override("outline_size",10)
	title.add_theme_color_override("font_outline_color",Color("0b0710"))
	title_box.add_child(title)
	quip = _label(DIGIT_FONT,44,Color("f4efe1"))
	quip.position = Vector2(0,262)
	quip.size = Vector2(1280,50)
	quip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage.add_child(quip)
	grade = _label(TITLE_FONT,190,Color.WHITE)
	grade.position = Vector2(950,330)
	grade.size = Vector2(260,250)
	grade.pivot_offset = grade.size/2
	grade.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade.add_theme_constant_override("outline_size",14)
	grade.add_theme_color_override("font_outline_color",Color("0b0710"))
	grade.add_theme_constant_override("shadow_offset_x",10)
	grade.add_theme_constant_override("shadow_offset_y",10)
	stage.add_child(grade)
	prompt = _label(DIGIT_FONT,38,Color("f4efe1"))
	prompt.position = Vector2(0,690)
	prompt.size = Vector2(1280,50)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage.add_child(prompt)
	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

func _label(font: Font,size: int,color: Color) -> Label:
	var node := Label.new()
	node.add_theme_font_override("font",font)
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",color)
	node.add_theme_color_override("font_shadow_color",Color(0,0,0,.75))
	node.add_theme_constant_override("shadow_offset_x",3)
	node.add_theme_constant_override("shadow_offset_y",3)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func show_death(stats: Dictionary) -> void:
	_open("dead",DEATH_COLORS,"FIM DA NOITE",DEATH_QUIPS[rng.randi()%DEATH_QUIPS.size()])
	fx_material.set_shader_parameter("tint",Color(.85,.08,.12))
	fx_material.set_shader_parameter("stripe",Color(1,.2,.3))
	flash.color = Color(1,.1,.15,0)
	var total: int = stats.total
	_row("ELIMINADOS",.45,stats.kills,func(v: float) -> String: return "%02d / %02d" % [int(v),total])
	_row("TEMPO",.7,stats.time,_clock_text)
	prompt.text = "R  ·  ENTER  ·  CLIQUE   TENTAR DE NOVO"
	prompt_at = 1.0
	done_at = prompt_at

func show_win(stats: Dictionary) -> void:
	var heading: String = stats.get("title","")
	_open("won",WIN_COLORS,heading if heading else "BAR LIMPO","ATÉ A PRÓXIMA.")
	fx_material.set_shader_parameter("tint",Color(.35,.18,.75))
	fx_material.set_shader_parameter("stripe",Color(1,.3,.65))
	flash.color = Color(1,1,1,0)
	points = int(stats.kills)*1000+int(maxf(0.0,60.0-float(stats.time))*100.0)
	for entry in GRADES:
		if points >= entry[0]:
			grade_letter = entry[1]
			break
	var total: int = stats.total
	_row("ELIMINADOS",.55,stats.kills,func(v: float) -> String: return "%02d / %02d" % [int(v),total])
	_row("TEMPO",1.05,stats.time,_clock_text)
	_row("TENTATIVA",1.55,stats.attempt,func(v: float) -> String: return "%02d" % int(v))
	if int(stats.get("guests",0)) > 0:   # never fails the night, but it goes in the papers
		_row("CONVIDADOS MORTOS",1.8,stats.guests_killed,func(v: float) -> String: return "%02d" % int(v))
	_row("PONTOS",2.05,points,func(v: float) -> String: return "%06d" % int(v),1.0)
	grade.text = grade_letter
	grade_at = 3.2
	prompt.text = "ENTER  ·  CLIQUE   IR PRO QUARTO"
	prompt_at = 3.6
	done_at = prompt_at

func _open(kind: String,colors: Array,heading: String,line: String) -> void:
	for row in rows: row.node.queue_free()
	rows.clear()
	mode = kind
	palette = colors
	title_text = heading
	title.text = "[center][wave amp=28.0 freq=6.0 connected=1]%s[/wave][/center]" % tr(heading)
	quip.text = line
	clock = 0.0
	trauma = 1.0
	flash_alpha = .85
	grade_at = INF
	title_landed = false
	grade_landed = false
	last_tick = -1.0
	grade.text = ""
	visible = true
	advance(0.0)

func hide_screen() -> void:
	mode = ""
	visible = false

func _clock_text(seconds: float) -> String:
	return "%02d:%04.1f" % [int(seconds)/60,fmod(seconds,60.0)]

func _row(name: String,at: float,target: float,format: Callable,roll := ROLL) -> void:
	var node := Control.new()
	node.position = Vector2(330,340+rows.size()*62)
	node.size = Vector2(620,56)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var left := _label(DIGIT_FONT,50,Color("cfc8b6"))
	left.text = name
	left.size = Vector2(330,56)
	node.add_child(left)
	var right := _label(DIGIT_FONT,58,Color.WHITE)
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.size = Vector2(300,56)
	right.position.x = 320
	right.pivot_offset = Vector2(300,28)
	node.add_child(right)
	stage.add_child(node)
	rows.append({"node":node,"value":right,"at":at,"target":target,"format":format,"roll":roll,"pop":0.0})

func skip() -> bool:
	## Enter or a click during the level-clear tally lands it at once; true if it did.
	if mode != "won" or clock >= done_at: return false
	clock = done_at
	return true

func _on_click(event: InputEvent) -> void:
	if not visible or not (event is InputEventMouseButton and event.pressed): return
	if mode == "dead" and clock < CLICK_GUARD: return
	if not skip(): confirmed.emit()

func _process(dt: float) -> void:
	if visible: advance(dt)

func advance(dt: float) -> void:
	clock += dt
	trauma = maxf(0.0,trauma-dt*1.8)
	flash_alpha = maxf(0.0,flash_alpha-dt*4.0)
	# Title: thrown in big and tilted, lands with an overshoot, then never quite settles.
	var land := clampf(clock/SLAM,0,1)
	var back := 1.0+2.7*pow(land-1.0,3)+1.7*pow(land-1.0,2)   # ease-out-back
	title_box.scale = Vector2.ONE*lerpf(3.4,1.0,back)*(1.0+.03*sin(clock*6.0))
	title_box.rotation = lerpf(-.35,-.04,back)+.035*sin(clock*2.6)
	if not title_landed and clock >= TITLE_LANDS:
		title_landed = true
		slammed.emit(false)
	var hue: Color = palette[int(clock*12.0)%palette.size()]
	var under: Color = palette[(int(clock*12.0)+1)%palette.size()]
	title.add_theme_color_override("default_color",hue)
	title.add_theme_color_override("font_shadow_color",under.darkened(.35))
	quip.visible_characters = clampi(int((clock-.3)/.035),0,quip.text.length())
	quip.modulate.a = .65+.35*float(int(clock*20.0)%2)
	for row in rows:
		var t: float = clock-row.at
		row.node.visible = t >= 0
		if t < 0: continue
		var slide := 1.0-pow(1.0-clampf(t/SLIDE,0,1),3)
		row.node.position.x = lerpf(-700.0,330.0,slide)
		var p := clampf((t-SLIDE)/row.roll,0,1)
		var text: String = row.format.call(float(row.target)*(1.0-pow(1.0-p,2)))
		if text != row.value.text:
			if row.value.text != "":
				_kick(.12)
				if clock-last_tick >= TICK_EVERY:
					last_tick = clock
					ticked.emit(p)
			row.value.text = text
			row.pop = 1.0
		row.pop = maxf(0.0,row.pop-dt*6.0)
		row.value.scale = Vector2.ONE*(1.0+.35*row.pop)
		row.value.add_theme_color_override("font_color",hue if row.pop > .5 else Color.WHITE)
	# Grade: a second, heavier slam with a white-out.
	var g := clock-grade_at
	grade.visible = g >= 0
	if grade.visible:
		if g-dt < 0: _kick(1.0,.6)
		if not grade_landed and g >= GRADE_LANDS:
			grade_landed = true
			slammed.emit(true)
		var drop := clampf(g/.18,0,1)
		grade.scale = Vector2.ONE*lerpf(4.0,1.0,1.0-pow(1.0-drop,3))*(1.0+.05*sin(clock*9.0))
		grade.rotation = lerpf(-.5,.1,drop)+.05*sin(clock*3.1)
		grade.add_theme_color_override("font_color",hue)
		grade.add_theme_color_override("font_shadow_color",under.darkened(.3))
	prompt.visible = clock >= prompt_at and fmod(clock,.5) < .33
	# Shake, flash and the torn screen all follow the same trauma.
	var shake := trauma*trauma
	stage.position = Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1))*30.0*shake
	stage.rotation = rng.randf_range(-1,1)*.03*shake
	flash.color.a = flash_alpha
	fx_material.set_shader_parameter("amount",clampf(clock/.12,0,1))
	fx_material.set_shader_parameter("glitch",clampf(.1+shake*.9,0,1))

func _kick(amount: float,flash_to := 0.0) -> void:
	trauma = minf(1.0,trauma+amount)
	flash_alpha = maxf(flash_alpha,flash_to)
