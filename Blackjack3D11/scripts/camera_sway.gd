extends Camera3D
## Kevyt sivuttaiskeinuminen, jotta pöytä ei näytä still-kuvalta.

const SWAY := 0.3
const SPEED := 0.4

var _time := 0.0
@onready var _start_x := position.x


func _process(delta: float) -> void:
	_time += delta
	position.x = _start_x + sin(_time * SPEED) * SWAY
