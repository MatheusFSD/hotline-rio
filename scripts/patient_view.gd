extends Node3D
## The Santa Aurora's sedated patients (Simulation.patients): each one a body under a white sheet
## on its bed, the head on the pillow, the chest rising slowly. When a shadow-flame gets one out of
## bed (an ActorVisual drops from it), the bed is left empty with the sheet thrown back.
## Presentation only: the rules live in the simulation.
const BED_TOP := .92      # the mattress, a little under the bed solid's 0.9 m cut plus the sheet
const LENGTH := 1.55
const SHEET := Color("e8ece8")
const SKIN := Color("c9a892")
const BREATH := 1.6       # seconds per breath

var sim
var bodies: Array[Node3D] = []
var time := 0.0

func setup(simulation) -> void:
	sim = simulation
	for patient in sim.patients:
		var body := Node3D.new()
		body.position = Vector3(patient.p.x,BED_TOP,patient.p.y)
		body.rotation.y = -patient.angle+PI/2
		add_child(body)
		var sheet := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(.5,.16,LENGTH)
		sheet.mesh = shape
		sheet.material_override = _flat(SHEET)
		sheet.position = Vector3(0,.08,.08)
		sheet.name = "Sheet"
		body.add_child(sheet)
		var head := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = .11
		ball.height = .2
		ball.radial_segments = 6
		ball.rings = 3
		head.mesh = ball
		head.material_override = _flat(SKIN)
		head.position = Vector3(0,.12,-LENGTH/2-.02)   # the head at the far end from where the body faces
		body.add_child(head)
		bodies.append(body)

func _flat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material

func update() -> void:
	time += 1.0/60
	for i in bodies.size():
		var used: bool = sim.patients[i].used
		bodies[i].visible = not used
		if not used:   # the sheet rises and falls with a slow breath
			bodies[i].get_node("Sheet").scale.y = 1.0+.08*sin(TAU*(time+i*.37)/BREATH)
