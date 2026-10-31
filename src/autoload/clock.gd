extends Node
## Gerçek zamanlı akış (GDD 5.1): Duraklat / 1x / 2x / 4x; 1x'te 1 hafta = time.seconds_per_week_1x saniye.
## Simülasyon saati SimClock'tadır; bu düğüm sadece "ne zaman bir gün ilerlesin"e karar verir.

## speeds dizisindeki indeks (0 = 1x).
var speed_index: int = 0
var paused: bool = true
## Modal pencere açıkken (sihirbaz, rapor) saat durur; kapanınca oyuncunun seçimi geri gelir.
var _hold_count: int = 0
var _accum: float = 0.0


func speeds() -> Array:
	return DataDB.data.bal("time.speeds")


func set_paused(value: bool) -> void:
	paused = value
	_accum = 0.0
	EventBus.speed_changed.emit(speed_index, paused)


func set_speed(index: int) -> void:
	speed_index = clampi(index, 0, speeds().size() - 1)
	paused = false
	EventBus.speed_changed.emit(speed_index, paused)


func toggle_pause() -> void:
	set_paused(not paused)


## Modal açılınca hold(), kapanınca release().
func hold() -> void:
	_hold_count += 1


func release() -> void:
	_hold_count = maxi(0, _hold_count - 1)


func is_running() -> bool:
	return not paused and _hold_count == 0 and GameState.has_game() \
		and not GameState.is_waiting() and not GameState.is_bankrupt()


func _process(delta: float) -> void:
	if not is_running():
		return
	var seconds_per_day: float = DataDB.data.balf("time.seconds_per_week_1x") / DataDB.data.balf("calendar.days_per_week")
	_accum += delta * float(speeds()[speed_index])
	while _accum >= seconds_per_day:
		_accum -= seconds_per_day
		GameState.step_day()
		if not is_running():
			_accum = 0.0
			break


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.has_game():
		return
	if event.is_action_pressed("game_pause"):
		toggle_pause()
	elif event.is_action_pressed("game_speed_1"):
		set_speed(0)
	elif event.is_action_pressed("game_speed_2"):
		set_speed(1)
	elif event.is_action_pressed("game_speed_3"):
		set_speed(2)
