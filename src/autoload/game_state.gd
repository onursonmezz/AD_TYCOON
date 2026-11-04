extends Node
## Oyunun tek doğruluk kaynağı (GDD 24.3): Simulation'ı tutar, komutları uygular, sinyalleri EventBus'a aktarır.

var sim: Simulation = null
## Elle kaydın gideceği slot (M9): yüklenen ya da son kaydedilen; yeni oyunda "" (ilk kayıtta seçilir).
var current_slot: String = ""
## Son kayıttan beri geçen oyun günleri yoksa false: çıkarken "kaydetmeden çık?" sorulmaz.
var dirty: bool = false
var _last_month: int = -1
## Otomatik kayıt yalnızca oyun saati (Clock) çalışırken; testler GameState.step_day çağırınca gerçek kaydın
## üstüne yazılmasın. Kayıt testi bunu kapatır.
var autosave_needs_clock: bool = true


func has_game() -> bool:
	return sim != null


## background: oyuncunun geçmişi (data/backgrounds.json, GDD 11.5).
## start_year: hızlı başlangıç yılı (GDD 5.1), 0 = 1990.
## agency_name: oyuncunun verdiği ad (M9); boşsa arayüz varsayılanı gösterir.
func new_game(seed_value: int = -1, background: String = "", start_year: int = 0, agency_name: String = "") -> void:
	if seed_value < 0:
		seed_value = int(Time.get_unix_time_from_system()) % 1000000
	_attach(Simulation.new(DataDB.data, seed_value, background, start_year))
	sim.state.agency_name = agency_name.strip_edges()
	current_slot = ""
	dirty = true
	EventBus.game_started.emit()
	EventBus.notification.emit("NOTE_WELCOME", [], "info")
	EventBus.state_changed.emit()


## slot: "" = en son kaydedilen. Otomatik kayıttan yüklenince elle kayıt slotu boş kalır (üstüne yazılmasın).
func load_game(slot: String = "") -> bool:
	if slot.is_empty():
		slot = SaveSystem.latest_slot()
	var loaded: Simulation = SaveSystem.load_game(DataDB.data, slot)
	if loaded == null:
		return false
	_attach(loaded)
	current_slot = slot if slot != SaveSystem.AUTO else ""
	dirty = false
	EventBus.game_started.emit()
	EventBus.notification.emit("NOTE_LOADED", [], "info")
	EventBus.state_changed.emit()
	return true


## slot: "" = şu anki slot; o da yoksa ilk boş slot (hepsi doluysa 1. slot; arayüz önce slot seçtirir).
func save_game(slot: String = "") -> bool:
	if sim == null:
		return false
	if slot.is_empty():
		slot = current_slot if not current_slot.is_empty() else first_free_slot()
	var ok: bool = SaveSystem.save_game(sim, slot)
	if ok:
		current_slot = slot
		dirty = false
	EventBus.notification.emit("NOTE_SAVED" if ok else "NOTE_SAVE_FAILED", [], "info" if ok else "bad")
	return ok


func end_game() -> void:
	sim = null
	current_slot = ""
	dirty = false


## Ajansın görünen adı: verilmemişse varsayılan ("Ajansım").
func agency_display(agency_name: String = "") -> String:
	var n: String = agency_name if not agency_name.is_empty() else (sim.state.agency_name if sim != null else "")
	return n if not n.is_empty() else tr("UI_DEFAULT_AGENCY")


func first_free_slot() -> String:
	for slot: String in SaveSystem.SLOTS:
		if not SaveSystem.has_save(slot):
			return slot
	return SaveSystem.SLOTS[0]


## Ay başında otomatik kayıt (ayarlardan kapatılabilir). Elle kayıt slotunu ve "kaydedilmedi" bilgisini değiştirmez.
func _maybe_autosave() -> void:
	var month: int = sim.state.clock.week_index / sim.state.clock.weeks_per_month
	if _last_month < 0:
		_last_month = month
	if month == _last_month:
		return
	_last_month = month
	if autosave_needs_clock and not Clock.is_running():
		return
	if bool(Settings.get_value("autosave")) and not sim.state.bankrupt:
		SaveSystem.save_game(sim, SaveSystem.AUTO)


## Saat (Clock) her oyun günü bunu çağırır.
func step_day() -> void:
	if sim == null:
		return
	sim.step_day()
	dirty = true
	_maybe_autosave()
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


## Pitch hazırlığı bitti, sunum bekleniyor (zaman durur).
func is_pitch_waiting() -> bool:
	return sim != null and sim.pitches.is_waiting(sim.state)


## Karar bekleyen olay (M7-C); yoksa {}.
func pending_event() -> Dictionary:
	return EventSystem.pending(sim.state) if sim != null else {}


func is_bankrupt() -> bool:
	return sim != null and sim.state.bankrupt


func _attach(new_sim: Simulation) -> void:
	sim = new_sim
	_last_month = -1
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
	sim.scandal_started.connect(func(scandal: Dictionary) -> void: EventBus.scandal_started.emit(scandal))
	sim.award_ceremony.connect(func(result: Dictionary) -> void: EventBus.award_ceremony.emit(result))
	sim.rankings_published.connect(_on_rankings)
	sim.pitch_ready.connect(func() -> void: EventBus.pitch_ready.emit())
	sim.era_started.connect(func(era: String) -> void: EventBus.era_started.emit(era))
	sim.event_started.connect(func(ev: Dictionary) -> void: EventBus.event_started.emit(ev))
	sim.supplier_offer_received.connect(func(offer: Dictionary) -> void:
		EventBus.notification.emit("NOTE_SUPPLIER_OFFER", [tr(DataDB.data.suppliers[offer["supplier"]]["name_key"])], "info"))


## Arayüz dili (isim listeleri için): "tr" ya da "en".
func lang() -> String:
	return "en" if TranslationServer.get_locale().begins_with("en") else "tr"


## Çalışanın görünen adı: kurucu için "Sen (unvan)".
func employee_name(emp: Dictionary) -> String:
	if bool(emp.get("is_founder", false)):
		return tr("UI_YOU")
	return str(emp.get("name", ""))


func _on_rankings(result: Dictionary) -> void:
	EventBus.notification.emit("NOTE_RANKINGS", [int(result["creative_rank"]), int(result["biggest_rank"])], "info")
	if result["agency_of_year"] == "player":
		EventBus.notification.emit("NOTE_AGENCY_OF_YEAR", [], "good")


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
