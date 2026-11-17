extends Node3D
## Alkuruutu: pöytä taustalla, rahat ja pankki oikeassa yläkulmassa.

const GAME_SCENE := "res://scenes/main.tscn"
const CardScene := preload("res://scenes/card.tscn")

@onready var money_label: Label = %MoneyLabel
@onready var debt_label: Label = %DebtLabel
@onready var bank_button: Button = %BankButton
@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton
@onready var bank_dialog: BankDialog = %BankDialog


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	bank_button.pressed.connect(_on_bank_pressed)
	quit_button.pressed.connect(func(): get_tree().quit())
	bank_dialog.closed.connect(_on_bank_closed)
	Wallet.changed.connect(_refresh_money)

	_place_cards()
	_refresh_money()
	play_button.grab_focus()


## Pöydälle jää blackjack-käsi: ässä ja kuningas.
func _place_cards() -> void:
	var hand := [Vector2i(1, 0), Vector2i(13, 1)]
	for i in hand.size():
		var card := CardScene.instantiate() as Card
		add_child(card)
		card.setup(hand[i].x, hand[i].y)
		card.scale = Vector3.ONE * 2.0
		card.position = Vector3(1.4 + i * 1.7, 0.04, 0.5)
		card.rotation = Vector3(0, deg_to_rad(14 - i * 26), 0)


func _on_play_pressed() -> void:
	Sfx.play(&"click")
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_bank_pressed() -> void:
	Sfx.play(&"click")
	bank_dialog.open()


func _on_bank_closed() -> void:
	Sfx.play(&"click")
	play_button.grab_focus()


func _refresh_money() -> void:
	money_label.text = "Rahat: %s €" % Wallet.format(Wallet.balance)
	debt_label.text = "Velka: %s €" % Wallet.format(Wallet.debt)
