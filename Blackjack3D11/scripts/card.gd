class_name Card
extends Node3D
## Yksittäinen 3D-pelikortti (scenes/card.tscn).

const SUIT_SYMBOLS := ["♠", "♥", "♦", "♣"]
const RANK_NAMES := ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
const BLACK := Color("111111")
const RED := Color("c0151f")

var _rest_y := 0.0

@onready var front_label: Label3D = $FrontLabel


func setup(rank: int, suit: int) -> void:
	front_label.text = "%s\n%s" % [RANK_NAMES[rank], SUIT_SYMBOLS[suit]]
	front_label.modulate = RED if suit == 1 or suit == 2 else BLACK


## Kortti lentää korttikengästä pöydälle. Alussa kuvapuoli on alaspäin.
func fly(from: Vector3, to: Vector3, show_face: bool) -> void:
	_rest_y = to.y
	position = from
	rotation = Vector3(0, 0.6, PI)
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "position", to, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "rotation:y", randf_range(-0.06, 0.06), 0.45)
	if show_face:
		t.tween_property(self, "rotation:z", 0.0, 0.45).set_trans(Tween.TRANS_SINE)
	await t.finished


## Siirtyy sivusuunnassa, kun riviin tulee uusi kortti.
func slide_x(x: float) -> void:
	create_tween().tween_property(self, "position:x", x, 0.3)


## Kortti nousee ilmaan ja kääntyy kuvapuoli ylöspäin.
func reveal() -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "rotation:z", 0.0, 0.45).set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "position:y", 1.1, 0.22).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position:y", _rest_y, 0.22).set_delay(0.22).set_ease(Tween.EASE_IN)
	await t.finished
