extends SceneTree
const Room = preload("res://scripts/room.gd")
var failures := 0
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var room = Room.new({"kills":8,"time":42.0,"attempt":2})
	root.add_child(room)
	check(room.hotspots.size() == Room.HOTSPOTS.size(),"Every hotspot is in the room model: %s" % [room.hotspots.keys()])
	for key in ["Hotspot_pc","Hotspot_board","Weapon_pistol","Weapon_smg","Weapon_shotgun","Weapon_rifle","Weapon_minigun"]:
		if not room.hotspots.has(key): continue
		var point: Vector2 = room.camera.unproject_position(room.surface_point(key))
		var inside := Rect2(Vector2.ZERO,Vector2(Room.RESOLUTION)).has_point(point)
		check(inside and room.hotspot_at(point) == key,"%s is visible and clickable from the fixed camera (%s -> %s)" % [key,point,room.hotspot_at(point)])
	check(room.hotspot_at(Vector2(320,395)) == "","Bare floor is not a hotspot")
	room.click("Hotspot_pc")
	check(room.open_panel == "pc" and room.panel.visible,"PC opens the upgrade shop")
	room._close()
	room.click("Hotspot_board")
	check(room.open_panel == "board","Board opens the missions")
	room._close()
	room.click("Weapon_shotgun")
	check(room.open_panel == "weapons" and room.selected_weapon == "Weapon_shotgun","A gun opens the arsenal on that gun")
	room.equip("shotgun")
	check(room.equipped == "shotgun" and room.equipped_label.text.ends_with("ESCOPETA"),"Arsenal equips the chosen gun")
	room._close()
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
