extends SceneTree
## Presentation pass: scenery grading stays selective and PS1-sized, and only the living get the
## legibility dressing (figure light layer, rim, contact shadow), with the hero told apart.
const Grade = preload("res://scripts/scenery_grade.gd")
const Look = preload("res://scripts/actor_look.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")

func saturation(c: Color) -> float:
	# Chroma (distance from grey), what the grade's saturation scales; HSV's S also moves with value.
	return maxf(c.r,maxf(c.g,c.b))-minf(c.r,minf(c.g,c.b))

func run() -> void:
	# Real salon floor, straight from the source PNG (headless runs have no GPU pixels).
	var source := Image.load_from_file(ProjectSettings.globalize_path("res://assets/environment/lapa_Lapa_vermelhao.png"))
	source.convert(Image.FORMAT_RGB8)
	var graded := Grade.grade(source,Grade.GRADES.Lapa_vermelhao)
	check(graded.get_size() == source.get_size() and graded.get_size() == Vector2i(32,32),"Grading keeps the 32 px PS1 texture size")
	var rows := Grade._lines(source,true)
	var columns := Grade._lines(source,false)
	check(rows.keys().size() == 2 and columns.keys().size() == 2 and rows.has(0) and rows.has(16),"Grout joints found every 16 px, nothing else (%s / %s)" % [rows.keys(),columns.keys()])
	var tile_before := 0.0; var joint_before := 0.0; var tile_after := 0.0; var joint_after := 0.0
	var sat_before := 0.0; var sat_after := 0.0
	for x in range(1,16):
		joint_before += Grade.luma(source.get_pixel(x,16)); tile_before += Grade.luma(source.get_pixel(x,17))
		joint_after += Grade.luma(graded.get_pixel(x,16)); tile_after += Grade.luma(graded.get_pixel(x,17))
	for y in 32:
		for x in 32:
			sat_before += saturation(source.get_pixel(x,y)); sat_after += saturation(graded.get_pixel(x,y))
	var contrast_cut := 1.0-((tile_after-joint_after)/tile_after)/((tile_before-joint_before)/tile_before)
	check(contrast_cut > .25 and contrast_cut < .41,"Joint contrast softened by %d%% (target 25-40)" % roundi(contrast_cut*100))
	var sat_cut := 1.0-sat_after/sat_before
	check(sat_cut > .2 and sat_cut < .35,"Vermelhão chroma cut by %d%% (target 20-35)" % roundi(sat_cut*100))
	print("vermelhão: chroma -%d%%, joint contrast -%d%%" % [roundi(sat_cut*100),roundi(contrast_cut*100)])
	var mean := Color(0,0,0)
	for y in 32: for x in 32: mean += graded.get_pixel(x,y)/1024.0
	check(mean.r > mean.g*1.6 and mean.r > mean.b*1.6,"The salon floor still reads red")
	check(not Grade.GRADES.has("Lapa_gingham") and not Grade.GRADES.has("Lapa_leather") and not Grade.GRADES.has("Lapa_mosaic"),"Signature colours (tablecloths, booths, Selarón tiles) are left alone")
	check(Grade.GRADES.Lapa_azulejo.keys() == ["saturation"],"Azulejos keep their pattern and grout")
	var azulejo := Image.load_from_file(ProjectSettings.globalize_path("res://assets/environment/lapa_Lapa_azulejo.png"))
	azulejo.convert(Image.FORMAT_RGB8)
	var calmer := Grade.grade(azulejo,Grade.GRADES.Lapa_azulejo)
	var blue := 0
	for y in 32: for x in 32: if calmer.get_pixel(x,y).b > calmer.get_pixel(x,y).r+.15: blue += 1
	check(blue > 200,"Azulejos stay blue and white (%d blue px)" % blue)

	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	# Cutaway: one cut height for every wall; only the back wall, with the bar's name, stands full.
	var heights := {}
	var tallest: Dictionary
	for s in game.sim.layout.solids:
		if s.type != "wall": continue
		heights[s.h] = true
		if not tallest or s.h > tallest.h: tallest = s
	check(heights.size() == 2 and tallest.r[1] == -7.75 and tallest.r[2] > 24 and game.sim.layout.solids.filter(func(s): return s.type == "wall" and s.h == tallest.h).size() == 1,"All walls share one cut height; only the back wall stands full")
	var figure_bit := 1 << (Look.FIGURE_LAYER-1)
	var figure_lights: Array = game.get_children().filter(func(n): return n is DirectionalLight3D and n.light_cull_mask == figure_bit)
	check(figure_lights.size() == 1,"One figure light, culled to the figure layer")
	var scenery_on_layer := false
	for node in game.get_children():
		if node is LapaActorVisual: continue
		for mesh in node.find_children("*","MeshInstance3D",true,false): scenery_on_layer = scenery_on_layer or (mesh.layers & figure_bit) != 0
	check(not scenery_on_layer,"The figure light never reaches the scenery")
	for i in game.actors.size(): game.actors[i].sync(game.sim.player if i==0 else game.sim.enemies[i-1],.1,false)
	var hero = game.actors[0]
	var enemy = game.actors[1]
	check(hero.look != null and enemy.look != null,"Every fighter in the level is dressed for legibility")
	var body: MeshInstance3D = hero.body_parts.parts.torso
	check((body.layers & figure_bit) != 0 and (hero.gun_parts[0].layers & figure_bit) != 0,"Living body and gun sit on the figure layer")
	check(body.get_surface_override_material(0).next_pass == hero.look.rim,"The rim rides on the skin as a next pass")
	check(hero.look.rim.get_shader_parameter("rim_color") != enemy.look.rim.get_shader_parameter("rim_color") and hero.look.rim_strength > enemy.look.rim_strength,"The hero's rim is cooler and a touch stronger")
	check(enemy.body_parts.parts.torso.get_surface_override_material(0).next_pass == enemy.look.rim,"Rims are per actor, never shared")
	var hips: Vector3 = hero.skeleton.global_transform*hero.skeleton.get_bone_global_pose(hero.skeleton.find_bone("pelvis")).origin
	check(hero.look.shadow.visible and Vector2(hero.look.shadow.global_position.x-hips.x,hero.look.shadow.global_position.z-hips.z).length() < .01,"Contact shadow sits under the hips")
	check(hero.look.shadow.global_position.y > .07 and hero.look.shadow.global_position.y < .1,"Contact shadow clears every floor slab without floating")
	hero.set_weapon("shotgun")
	check((hero.gun_parts[0].layers & figure_bit) != 0,"A new weapon joins the figure layer")
	# Phasing thins the shadow; the ghost material replaces the rim on its own.
	game.sim.player.phasing = true
	for i in 30: hero.sync(game.sim.player,1.0/60,false)
	check(absf(hero.look.presence-Look.SHADOW_PHASING) < .01,"An intangible hero barely darkens the floor")
	check(hero.body_parts.parts.torso.material_override == hero.ghost_material,"The spectre look still takes over the whole body")
	game.sim.player.phasing = false
	# The dead drop the dressing and settle into the scene.
	var data: Dictionary = game.sim.enemies[0]
	data.alive = false
	for i in 30: enemy.sync(data,1.0/60,false)
	check((enemy.body_parts.parts.torso.layers & figure_bit) == 0 and enemy.look.rim.get_shader_parameter("strength") == 0.0,"A corpse leaves the figure light and loses its rim")
	check(not enemy.look.shadow.visible,"A corpse's contact shadow fades out")
	data.alive = true
	for i in 30: enemy.sync(data,1.0/60,false)
	check((enemy.body_parts.parts.torso.layers & figure_bit) != 0 and enemy.look.shadow.visible,"A restart brings the dressing back")
	# Side sobrados: their own materials, pushed back as a frame; the same colours in the bar stay.
	var by_name := {}
	for mesh in game.find_children("Lapa_*","MeshInstance3D",true,false):
		var m := mesh.mesh.surface_get_material(0) as BaseMaterial3D
		if m: by_name[m.resource_name] = m
	var sides: Array = by_name.keys().filter(func(n): return String(n).begins_with("Lapa_side_"))
	check(sides.size() == 9,"The four side sobrados wear their own materials (%d)" % sides.size())
	var cream: Color = by_name.Lapa_cream.albedo_color
	var side_cream: Color = by_name.Lapa_side_cream.albedo_color
	check(not by_name.Lapa_cream.has_meta("graded") and by_name.Lapa_side_cream.has_meta("graded") and side_cream.v < cream.v*.85 and side_cream.s < cream.s,"Side trims step back; the bar's cream is untouched (%s / %s)" % [cream.to_html(false),side_cream.to_html(false)])
	var facade := Image.load_from_file(ProjectSettings.globalize_path("res://assets/environment/lapa_Lapa_facade_yellow.png"))
	facade.convert(Image.FORMAT_RGB8)
	var framed := Grade.grade(facade,Grade.GRADES.Lapa_side_facade_yellow)
	var stats := func(img: Image) -> Vector3:
		var sum := 0.0; var sq := 0.0; var chroma := 0.0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x,y)
				var l := Grade.luma(c)
				sum += l; sq += l*l; chroma += saturation(c)
		var n := float(img.get_width()*img.get_height())
		return Vector3(sum/n,sqrt(maxf(sq/n-(sum/n)*(sum/n),0.0)),chroma/n)
	var raw: Vector3 = stats.call(facade)
	var calm: Vector3 = stats.call(framed)
	print("side facade: brightness %d%%, contrast %d%%, chroma %d%%" % [roundi((calm.x/raw.x-1)*100),roundi((calm.y/raw.y-1)*100),roundi((calm.z/raw.z-1)*100)])
	check(calm.z < raw.z*.75 and calm.y < raw.y*.8 and calm.x < raw.x*.92,"Side facades: less saturated, less contrasted, a step darker")
	var mean_side := framed.get_pixel(16,16)
	check(mean_side.r > mean_side.b,"...and still yellow, not grey")
	# PS1 shading: contact shadows baked from the solids, no extra geometry.
	var Contact = load("res://scripts/contact_shadows.gd")
	var contact: Dictionary = Contact.build(game.sim.layout.solids,game.sim.layout.bounds)
	var map: Image = contact.texture.get_image()
	var texel := func(x: float,z: float) -> float:
		var p: Vector2 = (Vector2(x,z)-contact.origin)*Contact.TEXELS
		return map.get_pixel(clampi(int(p.x),0,map.get_width()-1),clampi(int(p.y),0,map.get_height()-1)).r
	var table: Array = game.sim.layout.solids.filter(func(s): return s.type == "table")[0].r
	var under: float = texel.call(table[0]+table[2]/2,table[1]+table[3]/2)
	var open: float = texel.call(-2.6,2.0)
	check(under < .6 and open > .99,"The floor under a table is in shade, open floor is not (%.2f / %.2f)" % [under,open])
	var near: float = texel.call(table[0]-.15,table[1]+table[3]/2)
	check(near < open and near > under,"The shade falls off around the furniture (%.2f)" % near)
	var levels := {}
	for y in map.get_height():
		for x in map.get_width(): levels[snappedf(map.get_pixel(x,y).r,.01)] = true
	check(levels.size() <= Contact.BANDS+1,"Contact shadows come in a few flat bands (%d levels)" % levels.size())
	var shaded := 0
	var meshes := 0
	for mesh in game.find_children("Lapa_*","MeshInstance3D",true,false):
		meshes += 1
		var mat := mesh.mesh.surface_get_material(0) as BaseMaterial3D
		if mat and mat.next_pass is ShaderMaterial and mat.next_pass.get_shader_parameter("contact") != null: shaded += 1
	check(shaded > meshes/2,"The PS1 shading pass rides on the scenery materials (%d of %d)" % [shaded,meshes])
	# Exit: nothing painted on the ground; light rises out of it only once the bar is clear.
	var painted := false
	for mesh in game.find_children("Lapa_*","MeshInstance3D",true,false):
		painted = painted or String(mesh.name).contains("exit_paint")
	var marker = game.exit_marker
	check(not painted,"The exit is not painted into the scenery")
	marker.update(false,.1,false)
	check(not marker.visible,"The exit stays hidden while enemies are left")
	marker.update(true,.05,false)
	var early: float = marker.curtain.scale.y
	for i in 60: marker.update(true,1.0/60,false)
	check(marker.visible and early < .5 and marker.curtain.scale.y > .99 and marker.lamp.light_energy > .5,"When the bar is clear the light rises out of the ground (%.2f -> %.2f)" % [early,marker.curtain.scale.y])
	var exit: Array = game.sim.layout.exit
	check(Vector2(marker.position.x,marker.position.z).distance_to(Rect2(exit[0],exit[1],exit[2],exit[3]).get_center()) < .01,"The light marks the exit rectangle from level.json")
	marker.update(false,.1,false)
	check(not marker.visible,"A restart hides the exit again")
	game.queue_free()
	await process_frame
	print("LOOK: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
