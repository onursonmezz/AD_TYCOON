class_name RivalSystem
extends RefCounted
## Rakip ajanslar (GDD 14.3): tam simülasyon yok; aylık güç skoru, büyüme/küçülme/batma, müşteri çalma.
## Kişilik parametreleri balance.json "rivals"ta, ajanslar data/rivals.json'da.

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


func _r(key: String) -> Variant:
	return data.bal("rivals." + key)


## Açılış yılı gelmiş ama durumda olmayan rakipleri ekler (yeni oyun, yeni dönem, eski kayıt).
func ensure(state: SimState) -> Array[String]:
	var added: Array[String] = []
	var year: int = state.clock.year()
	for id: String in data.rival_ids:
		var rec: Dictionary = data.rivals[id]
		if state.rivals.has(id) or int(rec["available_from"]) > year:
			continue
		state.rivals[id] = {"id": id, "reputation": float(rec["reputation"]), "staff": float(rec["staff"]), "alive": true,
			"award_points": 0.0, "closed_year": 0}
		added.append(id)
	return added


func alive_ids(state: SimState) -> Array[String]:
	var out: Array[String] = []
	for id: String in state.rivals:
		if bool(state.rivals[id]["alive"]):
			out.append(id)
	return out


func personality(rival_id: String) -> Dictionary:
	return _r("personalities")[data.rivals[rival_id]["personality"]]


## Güç skoru: ekip büyüklüğü (azalan getiri) × itibar.
func power(state: SimState, rival_id: String) -> float:
	var rv: Dictionary = state.rivals[rival_id]
	return pow(maxf(1.0, float(rv["staff"])), float(_r("power_staff_exp"))) \
		* (0.5 + float(rv["reputation"]) / float(_r("power_rep_div")))


## Yıllık gelir tahmini (sıralama için): ekip × kişi başı gelir × enflasyon × gürültü.
func revenue(state: SimState, rival_id: String) -> float:
	var noise: float = float(_r("revenue_noise"))
	return float(state.rivals[rival_id]["staff"]) * float(_r("revenue_per_staff_1990")) \
		* Economy.inflation(data, state.clock.year()) * state.rng.range_f("rivals", 1.0 - noise, 1.0 + noise)


## Güce göre ağırlıklı rastgele rakip ("" = hiç rakip yok).
func pick_by_power(state: SimState) -> String:
	var ids: Array[String] = alive_ids(state)
	if ids.is_empty():
		return ""
	var weights: Array = []
	for id: String in ids:
		weights.append(power(state, id))
	return ids[state.rng.pick_weighted_index("rivals", weights)]


## Aylık güncelleme. Dönüş: bildirimler [{key, args, kind}] ("closed"/"opened" için rakip adı anahtarı arg'dadır).
func monthly(state: SimState) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	for id: String in ensure(state):
		notes.append({"key": "NOTE_RIVAL_OPENED", "args": [data.rivals[id]["name_key"]], "kind": "info"})
	var year: int = state.clock.year()
	for id: String in alive_ids(state):
		var rv: Dictionary = state.rivals[id]
		var pers: Dictionary = personality(id)
		var growth: float = float(pers["growth"])
		if pers.has("boost_from") and year >= int(pers["boost_from"]):
			growth *= float(pers["boost"])
		var noise: float = float(_r("staff_noise"))
		var staff: float = float(rv["staff"]) * (1.0 + growth + state.rng.range_f("rivals", -noise, noise))
		rv["staff"] = clampf(staff, 0.0, float(pers["max_staff"]))
		var rep: float = float(rv["reputation"])
		rep += (float(pers["rep_target"]) - rep) * float(_r("rep_pull")) \
			+ state.rng.range_f("rivals", -float(_r("rep_noise")), float(_r("rep_noise")))
		rv["reputation"] = clampf(rep, data.balf("reputation.min"), data.balf("reputation.max"))
		if float(rv["staff"]) < float(_r("close_below_staff")) and state.rng.chance("rivals", float(_r("close_monthly_chance"))):
			rv["alive"] = false
			rv["closed_year"] = year
			notes.append({"key": "NOTE_RIVAL_CLOSED", "args": [data.rivals[id]["name_key"]], "kind": "info"})
	return notes


## Memnuniyeti risk eşiğinin altındaki müşterileri rakipler çalabilir. Dönüş: [{client_id, rival_id}]
func steal_clients(state: SimState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for client: Dictionary in state.clients.values():
		if float(client["satisfaction"]) >= data.balf("clients.risk_threshold"):
			continue
		if _busy(state, str(client["id"])):
			continue
		if not state.rng.chance("rivals", float(_r("steal_monthly_chance"))):
			continue
		var rival: String = pick_by_power(state)
		if not rival.is_empty():
			out.append({"client_id": client["id"], "rival_id": rival})
	return out


## Üretimde ya da yayında işi olan müşteri çalınmaz (ajans parasını alamazdı).
func _busy(state: SimState, client_id: String) -> bool:
	if state.active_campaign.get("setup", {}).get("client_id", "") == client_id:
		return true
	for camp: Dictionary in state.airing:
		if camp["setup"]["client_id"] == client_id:
			return true
	return false


## Rakipten transfer (GDD 11.6 "rakibi zayıflatır").
func weaken_by_transfer(state: SimState, rival_id: String) -> void:
	if not state.rivals.has(rival_id):
		return
	var rv: Dictionary = state.rivals[rival_id]
	rv["staff"] = maxf(0.0, float(rv["staff"]) - float(_r("transfer_staff_loss")))
	rv["reputation"] = maxf(0.0, float(rv["reputation"]) - float(_r("transfer_rep_loss")))


## Ödüle gönderilen rakip işlerinin puanları (GDD 15 ödül skoru ölçeğinde, zorluk hariç).
func award_entries(state: SimState, rival_id: String) -> Array[float]:
	var rv: Dictionary = state.rivals[rival_id]
	var span: Array = _r("entries_per_rival")
	var rng: RandomNumberGenerator = state.rng.stream("rivals")
	var mean: float = float(_r("entry_score_base")) + float(_r("entry_creative_weight")) * float(personality(rival_id)["creative"]) \
		+ float(_r("entry_rep_weight")) * float(rv["reputation"])
	var out: Array[float] = []
	for i: int in state.rng.range_i("rivals", int(span[0]), int(span[1])):
		out.append(rng.randfn(mean, float(_r("entry_sd"))))
	return out
