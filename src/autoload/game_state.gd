extends Node
## Oyunun tek doğruluk kaynağı (GDD 24.3): Simulation'ı tutar, komutları uygular, sinyalleri EventBus'a aktarır.

var sim: Simulation = null


func has_game() -> bool:
	return sim != null


## background: oyuncunun geçmişi (data/backgrounds.json, GDD 11.5).
func new_game(seed_value: int = -1, background: String = "") -> void:
	if seed_value < 0:
		seed_value = int(Time.get_unix_time_from_system()) % 1000000
	_attach(Simulation.new(DataDB.data, seed_value, background))
	EventBus.game_started.emit()
	EventBus.notification.emit("NOTE_WELCOME", [], "info")
	EventBus.state_changed.emit()


func load_game() -> bool:
	var loaded: Simulation = SaveSystem.load_game(DataDB.data)
	if loaded == null:
		return false
	_attach(loaded)
	EventBus.game_started.emit()
	EventBus.notification.emit("NOTE_LOADED", [], "info")
	EventBus.state_changed.emit()
	return true


func save_game() -> bool:
	if sim == null:
		return false
	var ok: bool = SaveSystem.save_game(sim)
	EventBus.notification.emit("NOTE_SAVED" if ok else "NOTE_SAVE_FAILED", [], "info" if ok else "bad")
	return ok


func end_game() -> void:
	sim = null


## Saat (Clock) her oyun günü bunu çağırır.
func step_day() -> void:
	if sim == null:
		return
	sim.step_day()
	EventBus.state_changed.emit()


## Komut nesnesini (src/commands) uygular; sonucu döndürür.
func execute(command: RefCounted) -> Variant:
	var result: Variant = command.call("execute", sim)
	EventBus.state_changed.emit()
	return result


func set_phase_sliders(sliders: Array) -> bool:
	var ok: bool = sim.set_phase_sliders(sliders)
	EventBus.state_changed.emit()
	return ok


func is_waiting() -> bool:
	return sim != null and sim.state.waiting_for_input


func is_bankrupt() -> bool:
	return sim != null and sim.state.bankrupt


func _attach(new_sim: Simulation) -> void:
	sim = new_sim
	sim.pause_on_phase = true
	sim.phase_started.connect(func(phase: int) -> void: EventBus.phase_started.emit(phase))
	sim.campaign_delivered.connect(_on_delivered)
	sim.campaign_finished.connect(_on_finished)
	sim.briefs_received.connect(func(count: int) -> void:
		EventBus.notification.emit("NOTE_NEW_BRIEFS", [count], "info"))
	sim.clients_lost.connect(func(names: Array[String]) -> void:
		for n: String in names:
			EventBus.notification.emit("NOTE_CLIENT_LOST", [n], "bad"))
	sim.went_bankrupt.connect(func() -> void: EventBus.bankrupt.emit())
	sim.staff_note.connect(func(key: String, args: Array, kind: String) -> void:
		EventBus.notification.emit(key, args, kind))
	sim.offer_received.connect(func(offer: Dictionary) -> void: EventBus.offer_received.emit(offer))


## Arayüz dili (isim listeleri için): "tr" ya da "en".
func lang() -> String:
	return "en" if TranslationServer.get_locale().begins_with("en") else "tr"


## Çalışanın görünen adı: kurucu için "Sen (unvan)".
func employee_name(emp: Dictionary) -> String:
	if bool(emp.get("is_founder", false)):
		return tr("UI_YOU")
	return str(emp.get("name", ""))


func _on_delivered(camp: Dictionary) -> void:
	EventBus.notification.emit("NOTE_DELIVERED", [camp["setup"].get("client_name", "")], "info")
	EventBus.campaign_delivered.emit(camp)


func _on_finished(camp: Dictionary) -> void:
	var score: float = float(camp["report"]["score"])
	var kind: String = "info"
	if score >= DataDB.data.balf("reputation.good_score"):
		kind = "good"
	elif score <= DataDB.data.balf("reputation.bad_score"):
		kind = "bad"
	EventBus.notification.emit("NOTE_REPORT_READY", [camp["setup"].get("client_name", ""), score], kind)
	EventBus.campaign_finished.emit(camp)
