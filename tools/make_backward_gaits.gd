extends SceneTree
const Gait = preload("res://scripts/backward_gait.gd")
func _initialize() -> void:
	var scene = load("res://assets/characters/hero.glb").instantiate()
	var player: AnimationPlayer
	for node in scene.find_children("*","AnimationPlayer",true,false): player = node; break
	DirAccess.make_dir_recursive_absolute("res://assets/animations")
	for entry in [["Jog_Fwd","run_backward"],["Walk","walk_backward"]]:
		var source := player.get_animation(entry[0])
		var backward := Gait.create(source)
		var result := ResourceSaver.save(backward,"res://assets/animations/"+entry[1]+".tres")
		if result != OK: scene.free(); quit(1); return
		print("BAKED ",entry[1]," ",backward.length,"s ",backward.get_track_count()," tracks")
	scene.free()
	quit()
