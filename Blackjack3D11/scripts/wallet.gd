extends Node
## Pelaajan rahat ja velka. Autoload "Wallet", säilyy scenejen välillä.

signal changed

const START_BALANCE := 1000

var balance := START_BALANCE
var debt := 0


func borrow(amount: int) -> void:
	balance += amount
	debt += amount
	changed.emit()


## Maksaa velkaa enintään sen verran kuin velkaa ja rahaa on. Palauttaa maksetun summan.
func repay(amount: int) -> int:
	var paid := mini(amount, mini(balance, debt))
	balance -= paid
	debt -= paid
	changed.emit()
	return paid


func reset() -> void:
	balance = START_BALANCE
	debt = 0
	changed.emit()


## Muotoilee summan luettavaksi: 1234567 -> "1 234 567"
func format(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += " "
		out += digits[i]
	return ("-" if amount < 0 else "") + out
