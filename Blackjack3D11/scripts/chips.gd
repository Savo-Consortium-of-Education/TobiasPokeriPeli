class_name ChipStack
extends Node3D
## Pelimerkkipino, jonka korkeus kasvaa panoksen mukana.

const COLORS := [Color("c62828"), Color("f5f5f0")]

var _count := 0


func show_amount(amount: int) -> void:
	var count := clampi(int(amount / 10.0), 1, 30)
	if count == _count:
		return
	_count = count
	for c in get_children():
		remove_child(c)
		c.queue_free()
	for i in count:
		var chip := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.38
		mesh.bottom_radius = 0.38
		mesh.height = 0.08
		chip.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = COLORS[i % 2]
		mat.roughness = 0.4
		chip.material_override = mat
		chip.position = Vector3(-floorf(i / 10.0) * 0.9, 0.04 + (i % 10) * 0.085, 0)
		add_child(chip)
