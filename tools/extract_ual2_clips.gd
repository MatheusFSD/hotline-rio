extends SceneTree
## Pulls the clips the game uses out of Quaternius' Universal Animation Libraries (CC0, both on the
## same 65-bone rig) and saves them as one AnimationLibrary aimed at the characters' rig: unaware
## enemy poses, the shotgun/rifle knockback death and the hero's katana (UAL2's two regular cuts,
## each joined to its own recovery, and the guard they start and end in).
## Run: godot --headless --path . --script res://tools/extract_ual2_clips.gd
const SOURCES := {"ual2":"res://tools/source/UAL2_Standard.glb"}   # tools/source is not imported by Godot
const TARGET := "res://assets/animations/ual2_clips.res"
const CLIPS := [["ual2","Consume"],["ual2","Idle_TalkingPhone_Loop"],["ual2","Idle_FoldArms_Loop"],["ual2","Hit_Knockback"]]
## Cut + recovery, so a single swing comes back to guard on its own.
const SLASHES := {"Slash_A":["Sword_Regular_A","Sword_Regular_A_Rec"],"Slash_B":["Sword_Regular_B","Sword_Regular_B_Rec"]}
const RIG := "RioRig/Skeleton3D"   # skeleton path inside every character scene
const SIP_PAUSE := 3.0             # Drink_Loop: one sip, then the bottle held low this long

func _initialize() -> void:
	var players := {}
	var scenes: Array[Node] = []
	for key in SOURCES:
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var error := document.append_from_file(ProjectSettings.globalize_path(SOURCES[key]),state)
		if error != OK:
			push_error("Cannot read %s (%d)" % [SOURCES[key],error]); quit(1); return
		var scene := document.generate_scene(state)
		scenes.append(scene)
		players[key] = scene.find_children("*","AnimationPlayer",true,false)[0]
	var library := AnimationLibrary.new()
	for entry in CLIPS:
		var animation := _clip(players[entry[0]],entry[1])
		if not animation: quit(1); return
		animation.loop_mode = Animation.LOOP_LINEAR if entry[1].ends_with("_Loop") else Animation.LOOP_NONE
		library.add_animation(entry[1],animation)
		if entry[1] == "Consume": library.add_animation("Drink_Loop",_with_pause(animation,SIP_PAUSE))
	for name in SLASHES:
		var cut := _clip(players.ual2,SLASHES[name][0])
		var back := _clip(players.ual2,SLASHES[name][1])
		if not cut or not back: quit(1); return
		library.add_animation(name,_joined(cut,back))
		# Both cuts start and end in the same kamae: blade forward, edge down, hand at the right hip.
		if name == "Slash_A": library.add_animation("Sword_Guard",_held(cut,0.0))
	var error := ResourceSaver.save(library,TARGET)
	print("UAL2_CLIPS_SAVED ",TARGET," ",error," ",library.get_animation_list())
	for scene in scenes: scene.free()
	quit(0 if error == OK else 1)

func _clip(player: AnimationPlayer,name: String) -> Animation:
	var source := player.get_animation(name)
	if not source:
		push_error("Missing clip "+name)
		return null
	var animation := source.duplicate(true) as Animation
	for i in animation.get_track_count():
		var bone := String(animation.track_get_path(i)).get_slice(":",1)
		animation.track_set_path(i,NodePath(RIG+":"+bone))
	return animation

func _joined(first: Animation,second: Animation) -> Animation:
	## `second` appended after `first`, track by track.
	var animation := first.duplicate(true) as Animation
	for i in second.get_track_count():
		var track := animation.find_track(second.track_get_path(i),second.track_get_type(i))
		if track < 0: continue
		for k in second.track_get_key_count(i):
			animation.track_insert_key(track,first.length+second.track_get_key_time(i,k),second.track_get_key_value(i,k))
	animation.length = first.length+second.length
	animation.loop_mode = Animation.LOOP_NONE
	return animation

func _held(source: Animation,at: float) -> Animation:
	## One frame of source, held as a still loop.
	var animation := Animation.new()
	animation.length = 1.0
	animation.loop_mode = Animation.LOOP_LINEAR
	for i in source.get_track_count():
		var type := source.track_get_type(i)
		var value: Variant
		match type:
			Animation.TYPE_ROTATION_3D: value = source.rotation_track_interpolate(i,at)
			Animation.TYPE_POSITION_3D: value = source.position_track_interpolate(i,at)
			Animation.TYPE_SCALE_3D: value = source.scale_track_interpolate(i,at)
			_: continue
		var track := animation.add_track(type)
		animation.track_set_path(track,source.track_get_path(i))
		animation.track_insert_key(track,0.0,value)
	return animation

func _with_pause(source: Animation,pause: float) -> Animation:
	## The clip, then its first frame held for `pause` seconds, looping: a sip now and then.
	var animation := source.duplicate(true) as Animation
	var end := source.length+pause
	for i in animation.get_track_count():
		if animation.track_get_key_count(i) > 0:
			animation.track_insert_key(i,end,animation.track_get_key_value(i,0))
	animation.length = end
	animation.loop_mode = Animation.LOOP_LINEAR
	return animation
