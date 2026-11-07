extends SceneTree
## Renders the room, a hovered gun, the gun taken in hand and the walk up to the computer's shop. Requires a graphical session.
const Room = preload("res://scripts/room.gd")
const Campaign = preload("res://scripts/campaign.gd")
var room
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.qa/%s.png" % name)
func capture() -> void:
	Campaign.state = Campaign.fresh()
	Campaign.state.unlocks.append_array(["smg","shotgun","rifle","minigun"])
	room = Room.new({"kills":8,"time":42.0,"attempt":2})
	root.add_child(room)
	await save("room")
	var point: Vector2 = room.camera.unproject_position(room.surface_point("Weapon_minigun"))
	room._set_hovered(room.hotspot_at(point))
	room.tooltip.position = point/Vector2(Room.RESOLUTION)*room.screen.size+Vector2(18,14)
	await save("room-hover")
	room.click("Weapon_minigun")
	await save("room-arsenal")
	room._set_hovered("")
	room.click("Hotspot_pc")
	await create_timer(room.ZOOM_TIME*.5).timeout
	await save("room-pc-zoom")
	await create_timer(room.ZOOM_TIME*.5+.3).timeout
	await save("room-pc-shop")
	print("ROOM_CAPTURE_OK")
	quit()
