extends CanvasLayer
## The end of an act, after its last night and the room: the mission card's voice on black (the
## level file's "act_end": place, title, body, tip with what comes next, button). Enter or the
## button closes it; main.gd decides where that leads.
signal confirmed
const MissionScreen = preload("res://scripts/mission_screen.gd")
var screen

func _init(hud,act_end: Dictionary) -> void:
	layer = 25
	var black := ColorRect.new()
	black.color = Color("07050a")
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	screen = MissionScreen.new(hud)
	add_child(screen)
	screen.controls.hide()
	screen.confirmed.connect(func(): confirmed.emit())
	screen.show_briefing(act_end)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ENTER,KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		confirmed.emit()
