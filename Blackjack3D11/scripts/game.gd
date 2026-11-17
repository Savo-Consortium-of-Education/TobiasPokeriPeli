extends Node3D
## Pelin ohjaus: vuorot, panokset ja tulokset.
## Pöytä (table.tscn), kortit (card.tscn), käyttöliittymä (ui.tscn), pelimerkit ja game over -ruutu
## ovat omia noodejaan. Rahat ja velka ovat autoloadissa Wallet.
## Pikanäppäimet: H = HIT, S = STAND, D = DOUBLE, Space/Enter = JAKO, Esc = valikko

const CardScene := preload("res://scenes/card.tscn")
const MENU_SCENE := "res://scenes/menu.tscn"

const DEFAULT_BET := 50
const MIN_BET := 10
const BET_STEP := 10
const CARD_SPACING := 1.25
const CHIP_SOUND_PAUSE := 0.25   # jetonin ääni kuuluu ennen korttien jakoa
const GAME_OVER_DELAY := 1.8     # tulos ehtii näkyä ennen game over -ruutua

enum State { BETTING, DEALING, PLAYER_TURN, DEALER_TURN, GAME_OVER }

@onready var dealer_spot: Marker3D = $DealerSpot
@onready var player_spot: Marker3D = $PlayerSpot
@onready var shoe_spot: Marker3D = $ShoeSpot
@onready var cards_root: Node3D = $Cards
@onready var chips: ChipStack = $Chips
@onready var ui: GameUI = $UI
@onready var game_over: GameOver = $GameOver

var state: State = State.BETTING
var bet := DEFAULT_BET
var pot := 0

var deck := Deck.new()
var player := Hand.new()
var dealer := Hand.new()
var player_cards: Array[Card] = []
var dealer_cards: Array[Card] = []
var hole_card: Card = null
var dealer_hidden := false


func _ready() -> void:
	ui.deal_pressed.connect(_on_deal)
	ui.hit_pressed.connect(_on_hit)
	ui.stand_pressed.connect(_on_stand)
	ui.double_pressed.connect(_on_double)
	ui.all_in_pressed.connect(_on_all_in)
	ui.bet_changed.connect(_on_bet_changed)
	ui.bet_set.connect(_on_bet_set)
	ui.menu_pressed.connect(_on_menu)
	game_over.restart_pressed.connect(_on_restart)

	if Wallet.balance < MIN_BET:
		# Rahat on jo loppu (esim. velka maksettu pankissa tyhjäksi): ei lainaa, peli alkaa alusta
		state = State.GAME_OVER
		_refresh()
		game_over.open()
		return
	bet = clampi(DEFAULT_BET, MIN_BET, Wallet.balance)
	ui.set_message("Aseta panos ja paina JAKO")
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H: _on_hit()
			KEY_S: _on_stand()
			KEY_D: _on_double()
			KEY_SPACE, KEY_ENTER: _on_deal()
			KEY_ESCAPE: _on_menu()


# ---------------------------------------------------------------------------
# Korttien jako
# ---------------------------------------------------------------------------
func _row_x(index: int, count: int) -> float:
	return (index - (count - 1) / 2.0) * CARD_SPACING


func _deal_card(hand: Hand, cards: Array[Card], spot: Marker3D, face_up: bool) -> Card:
	var data := deck.draw()
	hand.add(data)

	var card := CardScene.instantiate() as Card
	cards_root.add_child(card)
	card.setup(data.x, data.y)
	cards.append(card)

	var n := cards.size()
	for i in n - 1:
		cards[i].slide_x(_row_x(i, n))
	var target := Vector3(_row_x(n - 1, n), spot.position.y, spot.position.z)
	Sfx.play(&"deal")
	await card.fly(shoe_spot.position, target, face_up)
	return card


func _clear_table() -> void:
	for c in player_cards + dealer_cards:
		c.queue_free()
	player_cards.clear()
	dealer_cards.clear()
	player.clear()
	dealer.clear()
	hole_card = null
	dealer_hidden = false


# ---------------------------------------------------------------------------
# Panos
# ---------------------------------------------------------------------------
## Panoksen askel kasvaa rahamäärän mukana, jotta suurellakin summalla panosta on helppo säätää.
func _bet_step() -> int:
	var magnitude := int(floor(log(maxf(Wallet.balance, 1.0)) / log(10.0)))
	return maxi(BET_STEP, int(pow(10.0, magnitude - 2)))


func _set_bet(amount: int) -> void:
	bet = clampi(amount, MIN_BET, maxi(MIN_BET, Wallet.balance))
	_refresh()


func _on_bet_changed(direction: int) -> void:
	if state != State.BETTING:
		return
	Sfx.play(&"chip")
	_set_bet(bet + direction * _bet_step())


func _on_bet_set(amount: int) -> void:
	if state != State.BETTING:
		return
	_set_bet(amount)


func _on_all_in() -> void:
	if state != State.BETTING:
		return
	Sfx.play(&"chip")
	_set_bet(Wallet.balance)


# ---------------------------------------------------------------------------
# Pelaajan toiminnot
# ---------------------------------------------------------------------------
func _on_deal() -> void:
	if state != State.BETTING:
		return
	bet = clampi(bet, MIN_BET, Wallet.balance)
	state = State.DEALING

	Wallet.balance -= bet
	pot = bet
	Sfx.play(&"chip")
	_clear_table()
	if deck.remaining() < 15:
		deck.reset()
	ui.set_message("")
	dealer_hidden = true
	_refresh()

	await get_tree().create_timer(CHIP_SOUND_PAUSE).timeout
	await _deal_card(player, player_cards, player_spot, true)
	_refresh()
	await _deal_card(dealer, dealer_cards, dealer_spot, true)
	_refresh()
	await _deal_card(player, player_cards, player_spot, true)
	_refresh()
	hole_card = await _deal_card(dealer, dealer_cards, dealer_spot, false)
	_refresh()

	if player.is_blackjack() or dealer.is_blackjack():
		await _dealer_turn()
		return

	state = State.PLAYER_TURN
	_refresh()


func _on_hit() -> void:
	if state != State.PLAYER_TURN:
		return
	state = State.DEALING
	_refresh()
	await _deal_card(player, player_cards, player_spot, true)
	if player.value() >= 21:
		await _dealer_turn()
	else:
		state = State.PLAYER_TURN
		_refresh()


func _on_stand() -> void:
	if state != State.PLAYER_TURN:
		return
	await _dealer_turn()


func _on_double() -> void:
	if not _can_double():
		return
	state = State.DEALING
	Wallet.balance -= pot
	pot *= 2
	Sfx.play(&"chip")
	_refresh()
	await get_tree().create_timer(CHIP_SOUND_PAUSE).timeout
	await _deal_card(player, player_cards, player_spot, true)
	await _dealer_turn()


func _can_double() -> bool:
	return state == State.PLAYER_TURN and player.size() == 2 and Wallet.balance >= pot


func _on_menu() -> void:
	# Ei poistuta kesken animaation eikä game over -ruudusta
	if state != State.BETTING and state != State.PLAYER_TURN:
		return
	Sfx.play(&"click")
	get_tree().change_scene_to_file(MENU_SCENE)


func _on_restart() -> void:
	Wallet.reset()
	get_tree().reload_current_scene()


# ---------------------------------------------------------------------------
# Jakajan vuoro ja tuloksen selvitys
# ---------------------------------------------------------------------------
func _dealer_turn() -> void:
	state = State.DEALER_TURN
	_refresh()
	if hole_card != null:
		Sfx.play(&"flip")
		await hole_card.reveal()
	dealer_hidden = false
	_refresh()

	if not player.is_bust() and not player.is_blackjack():
		# Jakaja nostaa kunnes käsi on vähintään 17
		while dealer.value() < 17:
			await get_tree().create_timer(0.45).timeout
			await _deal_card(dealer, dealer_cards, dealer_spot, true)
			_refresh()
	await _settle()


func _settle() -> void:
	var p := player.value()
	var d := dealer.value()
	var payout := 0
	var msg := ""
	var sound: StringName = &"lose"

	if player.is_bust():
		msg = "Meni yli! Hävisit %s €" % Wallet.format(pot)
	elif player.is_blackjack() and not dealer.is_blackjack():
		payout = int(pot * 2.5)  # blackjack maksaa 3:2
		msg = "BLACKJACK! Voitit %s €" % Wallet.format(payout - pot)
		sound = &"blackjack"
	elif dealer.is_blackjack() and not player.is_blackjack():
		msg = "Jakajalla blackjack. Hävisit %s €" % Wallet.format(pot)
	elif d > 21 or p > d:
		payout = pot * 2
		msg = "Voitit %s €!" % Wallet.format(payout - pot)
		sound = &"win"
	elif p == d:
		payout = pot
		msg = "Tasapeli, panos palautetaan"
		sound = &"chip"
	else:
		msg = "Jakaja voitti. Hävisit %s €" % Wallet.format(pot)

	Wallet.balance += payout
	pot = 0
	ui.set_message(msg)
	Sfx.play(sound)

	if Wallet.balance < MIN_BET:
		# Rahat loppu kesken pelin: lainaa ei saa, pankki haistattaa ja peli alkaa alusta
		state = State.GAME_OVER
		_refresh()
		await get_tree().create_timer(GAME_OVER_DELAY).timeout
		game_over.open()
		return

	state = State.BETTING
	bet = clampi(bet, MIN_BET, maxi(MIN_BET, Wallet.balance))
	_refresh()


# ---------------------------------------------------------------------------
# Näytön päivitys
# ---------------------------------------------------------------------------
func _refresh() -> void:
	var shown_bet := pot if pot > 0 else bet
	ui.set_balance(Wallet.balance, Wallet.debt)
	ui.set_bet(shown_bet, Wallet.balance, state == State.BETTING)
	chips.show_amount(shown_bet)

	if dealer.size() == 0:
		ui.set_dealer_text("Jakaja")
	elif dealer_hidden:
		ui.set_dealer_text("Jakaja: %d + ?" % dealer.first_card_value())
	else:
		ui.set_dealer_text("Jakaja: %d" % dealer.value())

	if player.size() == 0:
		ui.set_player_text("Sinä")
	else:
		ui.set_player_text("Sinä: %d" % player.value())

	ui.set_buttons(state == State.BETTING, state == State.PLAYER_TURN, _can_double())
