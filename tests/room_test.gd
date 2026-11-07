extends SceneTree
const Room = preload("res://scripts/room.gd")
const Campaign = preload("res://scripts/campaign.gd")
var failures := 0
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	# Three guns earned: the rifle and the minigun are not on the wall yet.
	Campaign.state = Campaign.fresh()
	Campaign.state.unlocks.append_array(["smg","shotgun"])
	var room = Room.new({"kills":8,"time":42.0,"attempt":2})
	root.add_child(room)
	check(room.hotspots.size() == Room.HOTSPOTS.size(),"Every hotspot is in the room model: %s" % [room.hotspots.keys()])
	for key in ["Weapon_rifle","Weapon_minigun"]:
		var point: Vector2 = room.camera.unproject_position(room.surface_point(key))
		check(not room.hotspots[key].visible and room.hotspot_at(point) != key,"%s, not earned yet, is not on the wall" % key)
	for key in ["Hotspot_pc","Hotspot_board","Weapon_pistol","Weapon_smg","Weapon_shotgun"]:
		if not room.hotspots.has(key): continue
		var point: Vector2 = room.camera.unproject_position(room.surface_point(key))
		var inside := Rect2(Vector2.ZERO,Vector2(Room.RESOLUTION)).has_point(point)
		check(inside and room.hotspot_at(point) == key,"%s is visible and clickable from the fixed camera (%s -> %s)" % [key,point,room.hotspot_at(point)])
	check(room.hotspot_at(Vector2(320,395)) == "","Bare floor is not a hotspot")
	var shut: Array = room.viewport.find_children("Sashes_closed*","",true,false)
	var swung: Array = room.viewport.find_children("Sashes_open*","",true,false)
	check(not shut.is_empty() and not swung.is_empty() and shut.all(func(n): return n.is_visible_in_tree()) and swung.all(func(n): return not n.is_visible_in_tree()),"Between nights the window is shut")
	var last_night = Room.new({"finale":true})
	root.add_child(last_night)
	check(last_night.viewport.find_children("Sashes_open*","",true,false).all(func(n): return n.is_visible_in_tree()) and last_night.viewport.find_children("Sashes_closed*","",true,false).all(func(n): return not n.is_visible_in_tree()),"On the last night it stands open")
	var view: Vector2 = last_night.camera.unproject_position(last_night.surface_point("City"))
	check(last_night.hotspot_at(view) == "City","…and the night through it is still the way out")
	last_night.queue_free()
	# The computer: the camera walks up to the screen, then MARÉ's shop comes on the glass.
	Campaign.state = Campaign.fresh()
	Campaign.state.cleared = [0,1]
	Campaign.state.favors = 1
	var home: Vector3 = room.camera.global_position
	room.click("Hotspot_pc")
	check(room.open_panel == "pc" and room.pc_state == "zooming" and not room.panel.visible,"The computer walks the camera up to it")
	check(not room.room_chrome.any(func(n): return n.visible),"…the room's bar out of the way")
	await create_timer(room.ZOOM_TIME*.5).timeout
	check(room.pc_state == "zooming" and room.camera.global_position.distance_to(home) > .5,"…on its way after half the time")
	await create_timer(room.ZOOM_TIME*.5+.2).timeout
	check(room.pc_state == "open" and room.camera.global_position.distance_to(room.screen_pose().origin) < .01,"…there in %.1f s" % room.ZOOM_TIME)
	check(room.screen_node.get_surface_override_material(room.screen_surface) == room.site_material,"The page is on the monitor's own glass")
	check(room.spinners.size() == Campaign.ORDERS.size(),"Every order turns on its own stage (%d)" % room.spinners.size())
	var turned: float = room.spinners[0].rotation.y
	await process_frame
	await process_frame
	check(room.spinners[0].rotation.y != turned,"…and turns")
	var labels: Array = room.site_root.find_children("*","Label",true,false).map(func(l): return l.text)
	check(labels.has("LOKI") and labels.has(room.ONION),"The browser is LOKI, on MARÉ's .onion")
	check(not labels.any(func(t): return "LAPANET" in t.to_upper()),"No LapaNet left")
	# A click on the glass reaches the page: order the extended magazine with the favour she owes.
	var order: Button = room.site_root.find_children("*","Button",true,false).filter(func(b): return not b.disabled and b.text.begins_with("PEDIR"))[0]
	var press := func(page_point: Vector2):
		var picture: Vector2 = room.picture_of(page_point)
		for down in [true,false]:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = down
			click.position = picture/Vector2(room.viewport.size)*room.screen.size
			room._on_screen_input(click)
	press.call(order.get_global_rect().get_center())
	await process_frame
	check("extended_mag" in Campaign.state.unlocks and Campaign.state.favors == 0,"A click on the glass orders it")
	var hover := InputEventMouseMotion.new()
	var card: Control = room.site_root.find_children("*","SubViewportContainer",true,false)[1]
	hover.position = room.picture_of(card.get_global_rect().get_center())/Vector2(room.viewport.size)*room.screen.size
	room._on_screen_input(hover)
	await process_frame
	check(room.site_status.text == Campaign.ORDERS.rubber_soles.text,"Hovering an order, the status line says what it does")
	# Esc walks back; a click off the monitor too.
	room._close()
	check(room.pc_state == "leaving","Esc walks back")
	await create_timer(room.LEAVE_TIME+.2).timeout
	check(room.pc_state == "" and room.open_panel == "" and room.camera.global_position.distance_to(home) < .01,"…to where the room is seen from")
	check(room.screen_node.get_surface_override_material(room.screen_surface) == null and room.viewport.size == Room.RESOLUTION,"…the screen back to itself, the room to its own resolution")
	check(room.room_chrome[0].visible,"…and the room's bar back")
	room.click("Hotspot_pc")
	await create_timer(room.ZOOM_TIME+.2).timeout
	var off := InputEventMouseButton.new()
	off.button_index = MOUSE_BUTTON_LEFT
	off.pressed = true
	off.position = Vector2(4,4)
	room._on_screen_input(off)
	check(room.pc_state == "leaving","A click off the monitor walks back")
	await create_timer(room.LEAVE_TIME+.2).timeout
	Campaign.state = Campaign.fresh()
	room.click("Hotspot_board")
	check(room.open_panel == "board","Board opens the missions")
	room._close()
	# A gun on the wall: its numbers under the mouse, in hand with a click.
	Campaign.state = Campaign.fresh()
	Campaign.state.unlocks.append_array(["smg","shotgun"])
	room._set_hovered("Weapon_shotgun")
	var gun_card: String = room.tooltip.text
	check(room.tooltip.visible and gun_card.begins_with("ESCOPETA") and "tiros/min" in gun_card and "pente 6" in gun_card and "7 chumbos" in gun_card,"Hovering a gun tells its numbers (%s)" % gun_card.replace("\n"," | "))
	check(gun_card.ends_with("Clique para levar"),"…and that a click takes it")
	room.click("Weapon_shotgun")
	check(room.open_panel == "" and room.equipped == "shotgun" and room.equipped_label.text.ends_with("ESCOPETA"),"A click takes it in hand, no panel")
	check(room.tooltip.text.ends_with("NA MÃO"),"…and it says so")
	check(room.hotspots.Weapon_shotgun.material_overlay == room.highlight,"…still lit under the mouse")
	room._set_hovered("")
	check(room.hotspots.Weapon_shotgun.material_overlay == room.in_hand and room.hotspots.Weapon_pistol.material_overlay == null,"The gun in hand keeps a faint glow, the others none")
	room.click("Weapon_rifle")
	check(room.equipped == "shotgun","A gun not earned cannot be taken")
	var left := [false]
	room.next_night.connect(func(): left[0] = true)
	room.click("Hotspot_door")
	check(left[0],"The door starts the next night")
	room.queue_free()
	# Winning a night leads to the room, and the room leads into the next night.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_or_resume()
	game.sim.state = "won"
	game.start_or_resume()
	check(game.room != null and game.room.is_inside_tree(),"Winning opens the room")
	var pistol_muzzle: float = game.actors[0].muzzle.position.z
	game.room.equip("minigun")
	game.room.next_night.emit()
	check(game.room == null and game.sim.level == 1 and game.sim.state == "ready" and game.overlay.visible and game.overlay_title.text == "ÚLTIMA DANÇA","The next night is the next level, opening on its briefing")
	game.start_or_resume()
	check(game.sim.state == "playing" and game.sim.attempt == 1 and game.sim.kills == 0 and game.actors.size() == game.sim.enemies.size()+1,"Its first attempt starts with its own cast")
	check(game.sim.weapon == "minigun" and game.sim.player.ammo == 120 and game.actors[0].weapon == "minigun","The night starts with the gun chosen in the room")
	check(game.actors[0].muzzle.position.z < pistol_muzzle-.5 and game.actors[0].gun_parts.size() > 0,"The hero holds the minigun, muzzle at its barrels")
	var hero = game.actors[0]
	for i in 10: hero.sync(game.sim.player,1.0/60,false)
	var grip: Vector3 = hero.global_transform.affine_inverse()*hero.gun.global_position
	var barrel: Vector3 = hero.global_basis.inverse()*-hero.gun.global_basis.z
	var palm: Vector3 = hero.global_transform.affine_inverse()*(hero.skeleton.global_transform*hero.skeleton.get_bone_global_pose(hero.arm_bones.hand_l)).origin
	check(grip.y < 1.0 and grip.x < -.1 and barrel.z > .97,"Minigun rides level at the right hip (%s, %s)" % [grip,barrel])
	check(palm.y > grip.y+.15 and palm.distance_to(grip) < .45,"Left hand rides the minigun's carry handle")
	game.update_ui()
	check(game.hud.weapon.text == "MINIGUN" and game.hud.ammo_total.text == "/120","HUD shows the gun and its magazine")
	await process_frame
	print("ROOM: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
