class_name IndustryCalendar
extends RefCounted
## Sektör takvimi (M5–M7): ay başında rakipler, müşteri çalma, ödül pencereleri ve törenler; hafta sonunda pitch;
## yıl sonunda sıralamalar, araç sürümleri ve dönem değişimi.
## simulation.gd 400 satırı aşmasın diye ayrı; yalnızca Simulation'ın sistemlerini çağırır ve sinyallerini yayar.


static func monthly(sim: Simulation) -> void:
	var state: SimState = sim.state
	for note: Dictionary in sim.rivals.monthly(state):
		sim.staff_note.emit(note["key"], note["args"], note["kind"])
	var stolen: Array[String] = []
	for s: Dictionary in sim.rivals.steal_clients(state):
		sim.staff_note.emit("NOTE_CLIENT_STOLEN", [state.clients[s["client_id"]]["name"],
			sim.data.rivals[s["rival_id"]]["name_key"]], "bad")
		state.clients.erase(s["client_id"])
		stolen.append(str(s["client_id"]))
	sim.drop_clients(stolen)
	for id: String in sim.awards.open_awards(state):
		sim.staff_note.emit("NOTE_AWARD_OPEN", [sim.data.awards[id]["name_key"]], "info")
	for id: String in sim.awards.available(state):
		if int(sim.data.awards[id]["month"]) == state.clock.month():
			var result: Dictionary = sim.awards.ceremony(state, id)
			if not (result["player"] as Array).is_empty():
				sim.award_ceremony.emit(result)


## Hafta sonu: pitch davetleri, sıcak markaların teklifleri, hazırlığın bitişi. Bot/test (duraklamasız) modda
## sunum unutulursa bir süre sonra her turun ilk kartıyla kendiliğinden yapılır.
static func weekly(sim: Simulation) -> void:
	for note: Dictionary in sim.pitches.weekly(sim.state):
		sim.staff_note.emit(note["key"], note["args"], note["kind"])
		if note["key"] == "NOTE_PITCH_READY":
			sim.pitch_ready.emit()
	var pitch: Dictionary = sim.state.pitch
	if not sim.pause_on_phase and sim.pitches.is_waiting(sim.state) \
			and sim.state.clock.week_index > int(pitch["end_week"]) + sim.data.bali("pitch.auto_present_after_weeks"):
		var cards: Array = []
		for r: String in PitchSystem.ROUNDS:
			cards.append(sim.pitches.cards_of_round(r)[0])
		sim.pitches.present(sim.state, cards)


## Yıl sonu (gelir sayaçları sıfırlanmadan önce): sıralamalar, araç sürümleri ve abonelikler, dönem değişimi.
static func yearly(sim: Simulation) -> void:
	sim.rankings_published.emit(sim.awards.year_end(sim.state))
	for note: Dictionary in sim.tools.yearly(sim.state):
		sim.staff_note.emit(note["key"], note["args"], note["kind"])
	var year: int = sim.state.clock.year()
	if sim.data.era_of(year) != sim.data.era_of(year - 1):
		sim.era_started.emit(sim.data.era_of(year))
