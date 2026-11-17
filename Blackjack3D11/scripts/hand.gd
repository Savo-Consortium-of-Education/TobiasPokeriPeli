class_name Hand
extends RefCounted
## Yhden pelaajan (tai jakajan) käsi ja sen arvon laskenta.

var cards: Array[Vector2i] = []


static func card_value(c: Vector2i) -> int:
	if c.x == 1:
		return 11
	return mini(c.x, 10)


func add(c: Vector2i) -> void:
	cards.append(c)


func clear() -> void:
	cards.clear()


func size() -> int:
	return cards.size()


func value() -> int:
	var total := 0
	var aces := 0
	for c in cards:
		total += card_value(c)
		if c.x == 1:
			aces += 1
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total


func first_card_value() -> int:
	return card_value(cards[0]) if not cards.is_empty() else 0


func is_bust() -> bool:
	return value() > 21


func is_blackjack() -> bool:
	return cards.size() == 2 and value() == 21
