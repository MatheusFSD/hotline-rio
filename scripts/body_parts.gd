extends RefCounted
## Partition the original skinned triangles. Hiding a region never changes the
## skeleton, animation tracks, their timing, or the surviving body's death pose.
const REGIONS := ["torso","hips","head","arm_l","arm_r","leg_l","leg_r"]
# Everything above the waist cut: the hips (pelvis, spine_01) stay on the legs.
const UPPER := ["torso","head","arm_l","arm_r"]
static var mesh_cache: Dictionary = {}
var source: MeshInstance3D
var skeleton: Skeleton3D
var parts: Dictionary = {}
var triangles: Array[Dictionary] = []
var bone_map: Array[int] = []
var removed: Dictionary = {}
var wounds: Array[Node3D] = []

func setup(model: Node3D,rig: Skeleton3D) -> void:
	skeleton = rig
	for node in model.find_children("*","MeshInstance3D",true,false):
		if node.skin != null:
			source = node
			break
	if not source: return
	for slot in source.skin.get_bind_count():
		var bone := skeleton.find_bone(source.skin.get_bind_name(slot))
		if bone < 0: bone = source.skin.get_bind_bone(slot)
		bone_map.append(bone)
	var cache_key := source.mesh.get_instance_id()
	if not mesh_cache.has(cache_key): mesh_cache[cache_key] = _partition()
	var cached: Dictionary = mesh_cache[cache_key]
	triangles.assign(cached.triangles)
	for name in REGIONS:
		if not cached.meshes.has(name): continue
		var node := MeshInstance3D.new()
		node.name = "Body_"+name
		node.mesh = cached.meshes[name]
		node.skin = source.skin
		node.skeleton = source.skeleton
		node.transform = source.transform
		node.cast_shadow = source.cast_shadow
		source.get_parent().add_child(node)
		for surface in node.mesh.get_surface_count(): node.set_surface_override_material(surface,source.get_active_material(surface))
		parts[name] = node
	source.hide()

func set_material_override(material: Material) -> void:
	# null restores each part's own textured surface materials.
	for node in parts.values(): node.material_override = material

func _region(bone: String) -> String:
	bone = bone.to_lower()
	if bone == "head": return "head"
	if bone == "pelvis" or bone == "spine_01": return "hips"
	var side := "l" if bone.ends_with("_l") else "r"
	for prefix in ["upperarm","lowerarm","hand","index","middle","pinky","ring","thumb"]:
		if bone.begins_with(prefix): return "arm_"+side
	for prefix in ["thigh","calf","foot","ball"]:
		if bone.begins_with(prefix): return "leg_"+side
	return "torso"

func _partition() -> Dictionary:
	var meshes: Dictionary = {}
	var groups: Array[Dictionary] = []
	for name in REGIONS: meshes[name] = ArrayMesh.new()
	for surface in source.mesh.get_surface_count():
		var arrays := source.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for i in vertices.size(): indices.append(i)
		var influences := bones.size()/vertices.size()
		var grouped: Dictionary = {}
		for name in REGIONS: grouped[name] = PackedInt32Array()
		for i in range(0,indices.size(),3):
			var scores := {"torso":0.0,"hips":0.0,"head":0.0,"arm_l":0.0,"arm_r":0.0,"leg_l":0.0,"leg_r":0.0}
			for corner in 3:
				var vertex := indices[i+corner]
				for influence in influences:
					var offset := vertex*influences+influence
					if weights[offset] <= .001: continue
					var region := _region(skeleton.get_bone_name(bone_map[bones[offset]]))
					scores[region] += weights[offset]
			var region := "torso"
			for name in REGIONS:
				if scores[name] > scores[region]: region = name
			for corner in 3: grouped[region].append(indices[i+corner])
		groups.append({"arrays":arrays,"groups":grouped})
		for name in REGIONS:
			# Keep one surface per original surface so material slots stay identical.
			var data: Array = arrays.duplicate()
			data[Mesh.ARRAY_INDEX] = grouped[name]
			if not grouped[name].is_empty():
				meshes[name].add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,data)
	var nonempty := {}
	for name in REGIONS:
		if meshes[name].get_surface_count() > 0: nonempty[name] = meshes[name]
	return {"meshes":nonempty,"triangles":groups}

func reset() -> void:
	removed.clear()
	for node in parts.values(): node.show()
	for node in wounds: node.queue_free()
	wounds.clear()

func _bake(regions: Array) -> Dictionary:
	# World-space triangles of the given regions in the skeleton's current pose.
	skeleton.force_update_all_bone_transforms()
	var matrices: Array[Transform3D] = []
	for slot in bone_map.size():
		matrices.append(skeleton.global_transform*skeleton.get_bone_global_pose(bone_map[slot])*source.skin.get_bind_pose(slot))
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for group in triangles:
		var arrays: Array = group.arrays
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var original_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var original_uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var influences := bones.size()/vertices.size()
		for region in regions:
			var ids: PackedInt32Array = group.groups[region]
			for id in ids:
				var position := Vector3.ZERO
				var normal := Vector3.ZERO
				for influence in influences:
					var offset := id*influences+influence
					if weights[offset] <= 0: continue
					var matrix := matrices[bones[offset]]
					position += (matrix*vertices[id])*weights[offset]
					normal += (matrix.basis*original_normals[id])*weights[offset]
				positions.append(position)
				normals.append(normal.normalized())
				uvs.append(original_uvs[id])
	return {"positions":positions,"normals":normals,"uvs":uvs}

func pose_snapshot() -> ArrayMesh:
	## Frozen world-space copy of the visible body, used for spectral afterimages.
	var mesh := ArrayMesh.new()
	if not source: return mesh
	var regions := REGIONS.filter(func(name): return parts.has(name) and not removed.has(name))
	var baked := _bake(regions)
	if baked.positions.is_empty(): return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = baked.positions
	arrays[Mesh.ARRAY_NORMAL] = baked.normals
	arrays[Mesh.ARRAY_TEX_UV] = baked.uvs
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func detach(region: String) -> Array[MeshInstance3D]:
	var fragments: Array[MeshInstance3D] = []
	if not parts.has(region) or removed.has(region): return fragments
	var baked := _bake([region])
	var positions: PackedVector3Array = baked.positions
	var center := Vector3.ZERO
	for p in positions: center += p
	center /= maxi(1,positions.size())
	var chunks: Array[Array] = []
	for i in (4 if region == "head" else 1): chunks.append([])
	for triangle in range(0,positions.size(),3):
		var midpoint := (positions[triangle]+positions[triangle+1]+positions[triangle+2])/3
		var group := int(midpoint.x >= center.x)*2+int(midpoint.z >= center.z) if region == "head" else 0
		for corner in 3: chunks[group].append(triangle+corner)
	for chunk in chunks:
		if not chunk.is_empty(): fragments.append(_rigid(baked,chunk,"Detached_"+region))
	parts[region].hide()
	removed[region] = true
	_wound(region)
	return fragments

func cut_in_half() -> Dictionary:
	## Waist cut: what is left above the hips becomes one rigid, textured piece (with a cap over
	## the cut), the hips and legs stay skinned and keep animating. Returns {upper, stump}: the
	## piece and the wound socket that follows the legs.
	var regions := UPPER.filter(func(name): return parts.has(name) and not removed.has(name))
	if regions.is_empty() or removed.has("half"): return {}
	var baked := _bake(regions)
	var all := range(baked.positions.size())
	var upper := _rigid(baked,all,"Detached_upper")
	var waist := skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("spine_02")).origin
	var cap := _cap(.16)
	cap.position = waist-upper.position
	cap.name = "Cut"
	upper.add_child(cap)
	for name in regions:
		parts[name].hide()
		removed[name] = true
	removed["half"] = true
	_wound("half")
	return {"upper":upper,"stump":wounds[-1]}

func _rigid(baked: Dictionary,ids: Array,name: String) -> MeshInstance3D:
	## A frozen copy of some baked triangles, centred on its own pivot so it can tumble.
	var positions: PackedVector3Array = baked.positions
	var pivot := Vector3.ZERO
	for id in ids: pivot += positions[id]
	pivot /= maxi(1,ids.size())
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	for id in ids:
		v.append(positions[id]-pivot); n.append(baked.normals[id]); uv.append(baked.uvs[id])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = n
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(0,source.get_active_material(0))
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pivot
	node.name = name
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

func _wound(region: String) -> void:
	var bone := {"head":"Head","arm_l":"upperarm_l","arm_r":"upperarm_r","leg_l":"thigh_l","leg_r":"thigh_r","half":"spine_02"}.get(region,"") as String
	if bone.is_empty(): return
	var socket := BoneAttachment3D.new()
	socket.bone_name = bone
	skeleton.add_child(socket)
	socket.add_child(_cap(.16 if region == "half" else (.085 if region.begins_with("arm") else .11)))
	wounds.append(socket)

func _cap(radius: float) -> MeshInstance3D:
	## Low-poly red cap over a cut; the waist one is a flattened disc.
	var mesh := SphereMesh.new()
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.radius = radius
	mesh.height = radius*(.7 if radius > .15 else 1.3)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("7b2031")
	var cap := MeshInstance3D.new()
	cap.mesh = mesh
	cap.material_override = material
	cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return cap
