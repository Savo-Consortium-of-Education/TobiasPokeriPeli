class_name BankDialog
extends Control
## Työttömien pankki: lainan nosto ja velan maksu. Avataan alkuruudusta (scenes/bank_dialog.tscn).

signal closed

@onready var stats_label: Label = %StatsLabel
@onready var amount_spin: SpinBox = %AmountSpin
@onready var message_label: Label = %MessageLabel
@onready var borrow_button: Button = %BorrowButton
@onready var repay_button: Button = %RepayButton
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	borrow_button.pressed.connect(_on_borrow)
	repay_button.pressed.connect(_on_repay)
	close_button.pressed.connect(close)
	Wallet.changed.connect(_refresh)


func open() -> void:
	message_label.text = ""
	_refresh()
	visible = true
	borrow_button.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_borrow() -> void:
	amount_spin.apply()
	var amount := int(amount_spin.value)
	if amount <= 0:
		return
	Wallet.borrow(amount)
	Sfx.play(&"chip")
	message_label.text = "Laina myönnetty: +%s €." % Wallet.format(amount)


func _on_repay() -> void:
	if Wallet.debt == 0:
		message_label.text = "Ei velkaa maksettavana."
		return
	amount_spin.apply()
	var paid := Wallet.repay(int(amount_spin.value))
	if paid == 0:
		message_label.text = "Rahat eivät riitä velan maksuun."
		return
	Sfx.play(&"chip")
	message_label.text = "Maksoit velkaa %s €." % Wallet.format(paid)


func _refresh() -> void:
	stats_label.text = "Rahat: %s €\nVelka: %s €" % [Wallet.format(Wallet.balance), Wallet.format(Wallet.debt)]
