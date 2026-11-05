extends RefCounted
## Derive a backpedal from the supplied forward gait. Reverse the foot cycle,
## soften the pelvis bounce and add a small backwards lean; keep upper-body aim.
static func create(source: Animation) -> Animation:
	var result := Animation.new()
	result.length = source.length
	result.loop_mode = Animation.LOOP_LINEAR
	var samples := ceili(source.length*30)
	for track in source.get_track_count():
		var type := source.track_get_type(track)
		if type not in [Animation.TYPE_ROTATION_3D,Animation.TYPE_POSITION_3D,Animation.TYPE_SCALE_3D]: continue
		var path := source.track_get_path(track)
		var index := result.add_track(type)
		result.track_set_path(index,path)
		result.track_set_interpolation_type(index,Animation.INTERPOLATION_LINEAR)
		var bone := String(path).get_slice(":",1)
		for frame in samples+1:
			var time := source.length*frame/samples
			var original := fposmod(source.length-time,source.length)
			match type:
				Animation.TYPE_ROTATION_3D:
					var rotation := source.rotation_track_interpolate(track,original)
					if bone == "pelvis": rotation = Quaternion(Vector3.RIGHT,-.10)*rotation
					result.rotation_track_insert_key(index,time,rotation.normalized())
				Animation.TYPE_POSITION_3D:
					var position := source.position_track_interpolate(track,original)
					if bone == "pelvis":
						var rest := source.position_track_interpolate(track,0)
						position.y = rest.y+(position.y-rest.y)*.75
					result.position_track_insert_key(index,time,position)
				Animation.TYPE_SCALE_3D:
					result.scale_track_insert_key(index,time,source.scale_track_interpolate(track,original))
	return result
