extends Node
## Äänitehosteet. Autoload "Sfx" (scenes/sfx.tscn), käyttö: Sfx.play(&"deal")
## Voitto- ja häviöäänen ajaksi taustamusiikkia hiljennetään, jotta ne kuuluvat selvästi.

# Näille annetaan pieni satunnainen sävelkorkeuden vaihtelu, jotta ääni ei toistu täysin samana.
const VARIED: Array[StringName] = [&"deal", &"flip", &"chip", &"click"]
const JINGLES: Array[StringName] = [&"win", &"blackjack", &"lose"]
const DUCK_DB := 7.0

@onready var players: Dictionary = {
	&"deal": $Deal,
	&"flip": $Flip,
	&"chip": $Chip,
	&"click": $Click,
	&"win": $Win,
	&"blackjack": $Blackjack,
	&"lose": $Lose,
}

var _music_bus := -1
var _music_db := 0.0
var _duck_tween: Tween


func _ready() -> void:
	_music_bus = AudioServer.get_bus_index(&"Music")
	if _music_bus != -1:
		_music_db = AudioServer.get_bus_volume_db(_music_bus)


func play(sound: StringName) -> void:
	var player := players.get(sound) as AudioStreamPlayer
	if player == null:
		return
	player.pitch_scale = randf_range(0.95, 1.05) if sound in VARIED else 1.0
	player.play()
	if sound in JINGLES:
		_duck_music(player.stream.get_length())


func _duck_music(duration: float) -> void:
	if _music_bus == -1:
		return
	if _duck_tween:
		_duck_tween.kill()
	var ducked := _music_db - DUCK_DB
	_duck_tween = create_tween()
	_duck_tween.tween_method(_set_music_db, AudioServer.get_bus_volume_db(_music_bus), ducked, 0.12)
	_duck_tween.tween_interval(maxf(duration - 0.4, 0.0))
	_duck_tween.tween_method(_set_music_db, ducked, _music_db, 0.8)


func _set_music_db(value: float) -> void:
	AudioServer.set_bus_volume_db(_music_bus, value)
