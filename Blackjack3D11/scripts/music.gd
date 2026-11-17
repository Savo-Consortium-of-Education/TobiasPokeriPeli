extends Node
## Taustamusiikki. Autoload "Music" (scenes/music.tscn).
## Soi taukoamatta, myös kun scene vaihtuu valikosta peliin.

@onready var player: AudioStreamPlayer = $Player


func _ready() -> void:
	var stream := player.stream as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	# Varmuuden vuoksi: jos silmukka ei jostain syystä toimi, kappale alkaa alusta
	player.finished.connect(player.play)

	# Musiikki nousee esiin pehmeästi
	player.volume_db = -40.0
	player.play()
	create_tween().tween_property(player, "volume_db", 0.0, 2.5)
