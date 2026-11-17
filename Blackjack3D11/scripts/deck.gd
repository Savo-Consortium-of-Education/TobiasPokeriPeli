class_name Deck
extends RefCounted
## 52 kortin pakka. Kortti on Vector2i: x = arvo (1-13), y = maa (0-3).

var cards: Array[Vector2i] = []


func _init() -> void:
	reset()


func reset() -> void:
	cards.clear()
	for suit in 4:
		for rank in range(1, 14):
			cards.append(Vector2i(rank, suit))
	cards.shuffle()


func draw() -> Vector2i:
	if cards.is_empty():
		reset()
	return cards.pop_back()


func remaining() -> int:
	return cards.size()
