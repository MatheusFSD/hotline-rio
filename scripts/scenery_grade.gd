extends RefCounted
## Selective grading of the Lapa scenery textures, applied when the level loads (presentation only).
## From the far top-down camera the fighters are small, so the big floor and roof surfaces are
## calmed per material: less saturation, softer grout joints and less mottle, while each texture
## keeps its pattern, its 32 px PS1 resolution and nearest-neighbour sampling. The source PNGs and
## lapa.glb are untouched; removing a material from GRADES restores its original texture.
##   saturation  colour kept (1 = original)
##   joints      contrast kept between grout lines and the tiles they separate (1 = original)
##   mottle      contrast kept in the surface noise between the joints (1 = original)
##   value       brightness multiplier
##   tint        colour pulled toward by `tint_amount` after the rest (cools browns and oranges)
## Flat-coloured materials take saturation, value and tint on their albedo colour.
## The four sobrados flanking the bar wear their own Lapa_side_* materials (tools/build_environment.py)
## so they can be pushed back into a frame here without touching the same colours inside the bar.
const FRAME_TINT := Color(.36,.4,.5)   # dusk blue-grey the side buildings lean toward
const GRADES := {
	# Salon floor: still unmistakably vermelhão, no longer louder than the people standing on it.
	"Lapa_vermelhao": {"saturation":.77,"joints":.65,"mottle":.7,"value":.97},
	# Gafieira dance floor and office (level 2): the taco blocks stay readable, their seams quiet.
	"Lapa_tacos": {"saturation":.8,"joints":.55,"mottle":.75,"value":.95},
	# Santa Teresa (levels 3 and 4): patterned tiles, paint-flecked cement, lawn, gravel and the
	# cobbled street, all pushed under the fighters the same way.
	"Lapa_ladrilho": {"saturation":.65,"joints":.6,"mottle":.7,"value":.9},
	"Lapa_atelier_floor": {"saturation":.7,"joints":.6,"mottle":.7},
	"Lapa_grass": {"saturation":.75,"mottle":.7,"value":.92},
	"Lapa_saibro": {"saturation":.75,"mottle":.7,"value":.9},
	"Lapa_oil_concrete": {"joints":.6,"mottle":.7},
	"Lapa_paralelepipedo": {"saturation":.8,"joints":.65,"mottle":.75,"value":.95},
	"Lapa_cimento": {"saturation":.85,"joints":.62,"mottle":.75},          # kitchen floor
	"Lapa_concrete": {"joints":.6,"mottle":.65},                          # alleys and storage
	"Lapa_granilite": {"joints":.7,"mottle":.85},                         # vestibule
	"Lapa_pedra": {"mottle":.8,"value":.95},                              # pavement under the street lamps
	"Lapa_white_tile": {"joints":.7},                                     # kitchen wall tiles
	"Lapa_azulejo": {"saturation":.9},                                    # the blue pattern stays
	# Roofs of the neighbouring sobrados frame the level; out of play, they step back.
	"Lapa_roof": {"saturation":.72,"joints":.5,"mottle":.55,"value":.88},
	# The back muro is a long whitewashed band right behind the bar: a step down so it stays backdrop.
	"Lapa_whitewash": {"mottle":.8,"value":.58},
	# Side sobrados as a frame: each keeps its paint colour but quieter, flatter and a step darker,
	# read as a mass with openings rather than plaster stains and brick rows.
	"Lapa_side_facade_blue": {"saturation":.62,"mottle":.4,"value":.84,"tint":FRAME_TINT,"tint_amount":.12},
	"Lapa_side_facade_yellow": {"saturation":.6,"mottle":.4,"value":.8,"tint":FRAME_TINT,"tint_amount":.14},
	"Lapa_side_facade_pink": {"saturation":.6,"mottle":.4,"value":.82,"tint":FRAME_TINT,"tint_amount":.14},
	"Lapa_side_facade_green": {"saturation":.62,"mottle":.4,"value":.84,"tint":FRAME_TINT,"tint_amount":.12},
	"Lapa_side_roof": {"saturation":.58,"joints":.4,"mottle":.4,"value":.7,"tint":FRAME_TINT,"tint_amount":.1},
	# Their trims, shutters and balconies close in on the facade tone: less light/dark contrast.
	"Lapa_side_cream": {"saturation":.6,"value":.7,"tint":FRAME_TINT,"tint_amount":.15},
	"Lapa_side_teal": {"saturation":.6,"value":.9,"tint":FRAME_TINT,"tint_amount":.1},
	"Lapa_side_red_paint": {"saturation":.6,"value":.9,"tint":FRAME_TINT,"tint_amount":.1},
	"Lapa_side_iron": {"saturation":.6,"value":.95,"tint":FRAME_TINT,"tint_amount":.18}}
const SHADE := preload("res://shaders/scenery_shade.gdshader")
const ContactShadows = preload("res://scripts/contact_shadows.gd")
## Materials that keep more of their light at night. The Arcos are floodlit from below like the
## real monument: warm and dimmed, not swallowed with the houses around them.
const NIGHT_EXCEPTIONS := {
	"Lapa_arcos": {"night":Color(.8,.68,.55),"roof_night":.3},
	# Night six: city surfaces are already muted, and must keep enough separation to
	# read as buildings and an avenue below the tower. Only its own materials change.
	"Lapa_guardiao_facade": {"night":Color(.51,.56,.65)},
	"Lapa_guardiao_roof": {"night":Color(.46,.52,.61)},
	"Lapa_guardiao_trim": {"night":Color(.47,.53,.62)},
	"Lapa_guardiao_steel": {"night":Color(.57,.64,.73)},
	"Lapa_guardiao_window": {"night":Color(.66,.73,.84)},
	"Lapa_guardiao_window_blue": {"night":Color(.61,.68,.78)},
	"Lapa_guardiao_road": {"night":Color(.65,.7,.78)},
	"Lapa_guardiao_marking": {"night":Color(.52,.58,.66)},
	"Lapa_guardiao_car": {"night":Color(.57,.63,.72)},
	"Lapa_guardiao_car_red": {"night":Color(.6,.63,.7)},
	"Lapa_guardiao_tree": {"night":Color(.6,.66,.73)},
	# Night seven's shore and compressed distant relief remain readable as a single
	# landscape. The original Lapa palette and the other nights retain their grades.
	"Lapa_lagoa_water": {"night":Color(.66,.76,.83)},
	"Lapa_lagoa_reflection": {"night":Color(.57,.69,.76)},
	"Lapa_lagoa_hill": {"night":Color(.66,.72,.74),"roof_from":8.0},
	"Lapa_lagoa_hill_light": {"night":Color(.62,.7,.73),"roof_from":8.0},
	"Lapa_lagoa_hill_dark": {"night":Color(.65,.73,.77),"roof_from":8.0},
	"Lapa_lagoa_stone": {"night":Color(.56,.63,.69)},
	"Lapa_lagoa_roof": {"night":Color(.5,.57,.63),"roof_from":8.0},
	"Lapa_lagoa_facade": {"night":Color(.51,.58,.64)},
	"Lapa_lagoa_deck": {"night":Color(.67,.67,.66)},
	"Lapa_lagoa_bank": {"night":Color(.59,.67,.69)},
	"Lapa_lagoa_swan": {"night":Color(.62,.7,.76)},
	# The Fiscal island's tower and masonry need a quiet but complete silhouette.
	"Lapa_ilha_green": {"night":Color(.63,.71,.68),"roof_from":8.0},
	"Lapa_ilha_stone": {"night":Color(.59,.66,.7),"roof_from":8.0},
	"Lapa_ilha_trim": {"night":Color(.6,.67,.71),"roof_from":8.0},
	"Lapa_ilha_roof": {"night":Color(.66,.73,.8),"roof_from":8.0},
	"Lapa_ilha_paving": {"night":Color(.53,.61,.67)},
	"Lapa_ilha_water": {"night":Color(.68,.77,.85)},
	"Lapa_ilha_reflection": {"night":Color(.57,.68,.77)},
	"Lapa_ilha_warehouse": {"night":Color(.53,.6,.65)},
	"Lapa_ilha_boat": {"night":Color(.61,.67,.72)},
	"Lapa_ilha_clock": {"night":Color(.72,.72,.64),"roof_from":8.0},
	# TeleRio's own city materials: legible architecture in the lit view, still
	# subject to the real ambient/moon change when the studio breaker is tripped.
	"Lapa_t9_concrete": {"night":Color(.53,.6,.67),"roof_from":8.0},
	"Lapa_t9_roof": {"night":Color(.5,.58,.65),"roof_from":8.0},
	"Lapa_t9_steel": {"night":Color(.6,.67,.74),"roof_from":8.0},
	"Lapa_t9_white": {"night":Color(.6,.67,.73),"roof_from":8.0},
	"Lapa_t9_red": {"night":Color(.73,.59,.61),"roof_from":8.0},
	"Lapa_t9_trim": {"night":Color(.55,.62,.68)},
	"Lapa_t9_glass": {"night":Color(.64,.71,.79),"roof_from":8.0},
	"Lapa_t9_glass_blue": {"night":Color(.55,.63,.72),"roof_from":8.0},
	"Lapa_t9_road": {"night":Color(.56,.63,.71)},
	"Lapa_t9_yard": {"night":Color(.49,.56,.64)},
	"Lapa_t9_seat": {"night":Color(.53,.6,.66)},
	# Joá: the continuous coastal terrain and granite silhouette stay readable
	# while the small lit house leads the scene. These materials belong to night ten.
	"Lapa_joa_rock": {"night":Color(.61,.68,.71),"roof_from":8.0},
	"Lapa_joa_rock_dark": {"night":Color(.61,.67,.7),"roof_from":8.0},
	"Lapa_joa_green": {"night":Color(.58,.66,.66),"roof_from":8.0},
	"Lapa_joa_green_dark": {"night":Color(.61,.68,.69),"roof_from":8.0},
	"Lapa_joa_leaf": {"night":Color(.6,.67,.67),"roof_from":8.0},
	"Lapa_joa_leaf_dark": {"night":Color(.62,.69,.7),"roof_from":8.0},
	"Lapa_joa_sea": {"night":Color(.68,.76,.83)},
	"Lapa_joa_stone": {"night":Color(.56,.63,.68)},
	"Lapa_joa_concrete": {"night":Color(.55,.62,.68)},
	"Lapa_joa_trail": {"night":Color(.72,.72,.65)},
	"Lapa_joa_road": {"night":Color(.61,.67,.73)},
	"Lapa_joa_glass": {"night":Color(.63,.7,.77)},
	"Lapa_joa_trim": {"night":Color(.58,.65,.7)},
	# Santa Aurora: calm urban surroundings and a distant granite dome, lit under
	# the same night rig as the clinic, with no new lamps over the patient ward.
	"Lapa_c11_facade": {"night":Color(.56,.65,.66),"roof_from":8.0},
	"Lapa_c11_roof": {"night":Color(.5,.59,.64),"roof_from":8.0},
	"Lapa_c11_ochre": {"night":Color(.55,.62,.65),"roof_from":8.0},
	"Lapa_c11_stone": {"night":Color(.55,.62,.67)},
	"Lapa_c11_glass": {"night":Color(.61,.69,.76),"roof_from":8.0},
	"Lapa_c11_white": {"night":Color(.6,.67,.72)},
	"Lapa_c11_trim": {"night":Color(.57,.65,.7)},
	"Lapa_c11_road": {"night":Color(.53,.61,.68)}}

static func apply(root: Node) -> void:
	for node in root.find_children("*","MeshInstance3D",true,false):
		for surface in node.mesh.get_surface_count():
			var mat := node.mesh.surface_get_material(surface) as BaseMaterial3D
			# Imported materials are shared by every instance of lapa.glb: grade each once.
			if not mat or not GRADES.has(mat.resource_name) or mat.has_meta("graded"): continue
			if not mat.albedo_texture:
				mat.albedo_color = grade_color(mat.albedo_color,GRADES[mat.resource_name])
				mat.set_meta("graded",true)
				continue
			var source := mat.albedo_texture.get_image()
			if not source or source.is_empty(): continue   # headless runs have no pixels to read
			mat.albedo_texture = ImageTexture.create_from_image(grade(source,GRADES[mat.resource_name]))
			mat.set_meta("graded",true)

static func shade(root: Node,layout: Dictionary) -> void:
	## PS1 shading pass on the scenery (shaders/scenery_shade.gdshader): face shading, baked
	## contact shadows from the level's solids, grounding steps and the night beyond the playable
	## rectangle (level.json "bounds"). Light sources, glass and the black wall cut keep their look.
	var bounds: Array = layout.bounds
	var contact := ContactShadows.build(layout.solids,bounds)
	var veil := ShaderMaterial.new()
	veil.shader = SHADE
	veil.set_shader_parameter("stage",Vector4(bounds[0],bounds[1],bounds[0]+bounds[2],bounds[1]+bounds[3]))
	veil.set_shader_parameter("contact",contact.texture)
	veil.set_shader_parameter("contact_origin",contact.origin)
	veil.set_shader_parameter("contact_size",contact.size)
	for node in root.find_children("*","MeshInstance3D",true,false):
		for surface in node.mesh.get_surface_count():
			var mat := node.mesh.surface_get_material(surface) as BaseMaterial3D
			if not mat or mat.emission_enabled or mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: continue
			if mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED: continue   # the black wall cut
			mat.next_pass = veil
			if NIGHT_EXCEPTIONS.has(mat.resource_name):
				var lit := veil.duplicate() as ShaderMaterial
				for key in NIGHT_EXCEPTIONS[mat.resource_name]: lit.set_shader_parameter(key,NIGHT_EXCEPTIONS[mat.resource_name][key])
				mat.next_pass = lit

static func luma(c: Color) -> float:
	return c.r*.2126+c.g*.7152+c.b*.0722

static func grade(source: Image,spec: Dictionary) -> Image:
	var image := source.duplicate() as Image
	if image.is_compressed(): image.decompress()
	image.clear_mipmaps()
	image.convert(Image.FORMAT_RGB8)
	var w := image.get_width()
	var h := image.get_height()
	var joints: float = spec.get("joints",1.0)
	var mottle: float = spec.get("mottle",1.0)
	var saturation: float = spec.get("saturation",1.0)
	var value: float = spec.get("value",1.0)
	var rows := _lines(image,true) if joints < 1 or mottle < 1 else {}
	var columns := _lines(image,false) if joints < 1 or mottle < 1 else {}
	# Mean colour of the tiles themselves, the reference the joints and mottle are pulled toward.
	var mean := Color(0,0,0)
	var count := 0
	for y in h:
		for x in w:
			if rows.has(y) or columns.has(x): continue
			mean += image.get_pixel(x,y)
			count += 1
	mean = mean/maxf(count,1) if count else image.get_pixel(0,0)
	var tile := luma(mean)
	for y in h:
		for x in w:
			var c := image.get_pixel(x,y)
			if rows.has(y) or columns.has(x):
				# Keep the joint's own colour, shrink its darkness relative to the tiles.
				var ratio := tile/maxf(luma(c),.001)
				c = c*(1.0+(ratio-1.0)*(1.0-joints))
			else:
				c = mean+(c-mean)*mottle
			image.set_pixel(x,y,grade_color(c,{"saturation":saturation,"value":value,"tint":spec.get("tint",Color.WHITE),"tint_amount":spec.get("tint_amount",0.0)}))
	return image

static func grade_color(c: Color,spec: Dictionary) -> Color:
	## Saturation, brightness and tint of one colour; alpha is kept.
	var l := luma(c)
	var graded := Color(l,l,l)+(c-Color(l,l,l))*float(spec.get("saturation",1.0))
	graded = graded*float(spec.get("value",1.0))
	graded = graded.lerp(spec.get("tint",Color.WHITE),float(spec.get("tint_amount",0.0)))
	return Color(clampf(graded.r,0,1),clampf(graded.g,0,1),clampf(graded.b,0,1),c.a)

static func _lines(image: Image,horizontal: bool) -> Dictionary:
	## Grout lines: whole rows (or columns) darker than both neighbours along most of their length.
	## Large damp patches or mottling are not thin lines, so they never qualify.
	var found := {}
	var length := image.get_width() if horizontal else image.get_height()
	var span := image.get_height() if horizontal else image.get_width()
	for i in span:
		var darker := 0
		for j in length:
			var here := luma(image.get_pixel(j,i) if horizontal else image.get_pixel(i,j))
			var before := luma(image.get_pixel(j,posmod(i-1,span)) if horizontal else image.get_pixel(posmod(i-1,span),j))
			var after := luma(image.get_pixel(j,(i+1)%span) if horizontal else image.get_pixel((i+1)%span,j))
			if here < .92*(before+after)/2.0: darker += 1
		if darker >= length*.75: found[i] = true
	return found
