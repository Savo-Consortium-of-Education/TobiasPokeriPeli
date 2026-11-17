class_name GameOver
extends CanvasLayer
## Rahat loppu: pankki ei lainaa, peli alkaa alusta (scenes/game_over.tscn).

signal restart_pressed

const MESSAGES: Array[String] = [
	"Rahat loppu. Pankki ei lainaa konkurssiin menneelle. Haista paska ja painu kotiin!",
	"Työttömien pankki ei lainaa työttömälle pelurille, jolta on pelit pelattu. Haista paska!",
	"Luottotiedot paskana, taskut tyhjänä. Pankki haistattaa sinulle paskat.",
]

@onready var message_label: Label = %MessageLabel
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	restart_button.pressed.connect(func(): restart_pressed.emit())


func open() -> void:
	message_label.text = "%s\n\nPeli alkaa alusta: rahat %s €, velat nollattu." % [MESSAGES.pick_random(), Wallet.format(Wallet.START_BALANCE)]
	visible = true
	restart_button.grab_focus()
