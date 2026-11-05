extends SceneTree
## Renders the room, a hovered gun and the arsenal panel. Requires a graphical session.
const Room = preload("res://scripts/room.gd")
var room
func _initialize() -> void: call_deferred("capture")
func save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.qa/%s.png" % name)
func capture() -> void:
	room = Room.new({"kills":8,"time":42.0,"attempt":2})
	root.add_child(room)
	await save("room")
	var point: Vector2 = room.camera.unproject_position(room.surface_point("Weapon_minigun"))
	room._set_hovered(room.hotspot_at(point))
	room.tooltip.position = point/Vector2(Room.RESOLUTION)*room.screen.size+Vector2(18,14)
	await save("room-hover")
	room.click("Weapon_minigun")
	await save("room-arsenal")
	print("ROOM_CAPTURE_OK")
	quit()
