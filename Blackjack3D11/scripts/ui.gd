class_name GameUI
extends CanvasLayer
## Pelin käyttöliittymä (scenes/ui.tscn). Lähettää signaaleja, pelilogiikka ei ole täällä.

signal deal_pressed
signal hit_pressed
signal stand_pressed
signal double_pressed
signal menu_pressed
signal all_in_pressed
signal bet_changed(direction: int)   # BET -/+ (-1 tai 1)
signal bet_set(amount: int)          # panos kirjoitettu kenttään

@onready var balance_label: Label = %BalanceLabel
@onready var dealer_label: Label = %DealerLabel
@onready var player_label: Label = %PlayerLabel
@onready var message_label: Label = %MessageLabel
@onready var to_menu_button: Button = %ToMenuButton
@onready var all_in_button: Button = %AllInButton
@onready var bet_minus_button: Button = %BetMinusButton
@onready var bet_spin: SpinBox = %BetSpin
@onready var bet_plus_button: Button = %BetPlusButton
@onready var deal_button: Button = %DealButton
@onready var hit_button: Button = %HitButton
@onready var stand_button: Button = %StandButton
@onready var double_button: Button = %DoubleButton


func _ready() -> void:
	deal_button.pressed.connect(_on_deal_button_pressed)
	hit_button.pressed.connect(func(): hit_pressed.emit())
	stand_button.pressed.connect(func(): stand_pressed.emit())
	double_button.pressed.connect(func(): double_pressed.emit())
	to_menu_button.pressed.connect(func(): menu_pressed.emit())
	all_in_button.pressed.connect(func(): all_in_pressed.emit())
	bet_minus_button.pressed.connect(func(): bet_changed.emit(-1))
	bet_plus_button.pressed.connect(func(): bet_changed.emit(1))
	bet_spin.value_changed.connect(func(value: float): bet_set.emit(int(value)))


func _on_deal_button_pressed() -> void:
	bet_spin.apply()  # hyväksyy kenttään kirjoitetun summan ennen jakoa
	deal_pressed.emit()


func set_balance(value: int, debt: int) -> void:
	var text := "Rahat: %s €" % Wallet.format(value)
	if debt > 0:
		text += "     Velka: %s €" % Wallet.format(debt)
	balance_label.text = text


## Päivittää panoskentän ilman, että se lähettää bet_set-signaalin.
func set_bet(value: int, max_bet: int, editable: bool) -> void:
	bet_spin.set_block_signals(true)
	bet_spin.max_value = maxi(max_bet, int(bet_spin.min_value))
	bet_spin.value = value
	bet_spin.set_block_signals(false)
	bet_spin.editable = editable


func set_dealer_text(text: String) -> void:
	dealer_label.text = text


func set_player_text(text: String) -> void:
	player_label.text = text


func set_message(text: String) -> void:
	message_label.text = text


func set_buttons(betting: bool, playing: bool, can_double: bool) -> void:
	all_in_button.disabled = not betting
	bet_minus_button.disabled = not betting
	bet_plus_button.disabled = not betting
	deal_button.disabled = not betting
	hit_button.disabled = not playing
	stand_button.disabled = not playing
	double_button.disabled = not can_double
