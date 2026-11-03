class_name PitchSystem
extends RefCounted
## Pitch / ihale (GDD 14.2): davet → hazırlık (ekip S/K biriktirir) → 3 turluk kartlı sunum → rakiplerle yarış.
## Kartlar data/pitch_cards.json, sayılar balance.json "pitch". Hazırlıktaki çalışanlar kampanyada çalışmaz.

const PREF_KEYS: Array[String] = ["risk", "budget", "digital", "humor"]
const ROUNDS: Array[String] = ["opening", "idea", "closing"]

var data: GameData
var clients: ClientSystem
var briefs: BriefGenerator
var scoring: Scoring
var rivals: RivalSystem


func _init(game_data: GameData, client_system: ClientSystem, brief_generator: BriefGenerator, scoring_ref: Scoring,
		rival_system: RivalSystem) -> void:
	data = game_data
	clients = client_system
	briefs = brief_generator
	scoring = scoring_ref
	rivals = rival_system


func _p(key: String) -> Variant:
	return data.bal("pitch." + key)


func cards_of_round(round_name: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in data.pitch_card_ids:
		if data.pitch_cards[id]["round"] == round_name:
			out.append(id)
	return out


func is_waiting(state: SimState) -> bool:
	return state.pitch.get("phase", "") == "present"


func find_invite(state: SimState, invite_id: String) -> Dictionary:
	for inv: Dictionary in state.pitch_invites:
		if inv["id"] == invite_id:
			return inv
	return {}


# --- hafta ---------------------------------------------------------------------

## Dönüş: bildirimler [{key, args, kind}]; "ready" anahtarı sunum zamanının geldiğini söyler.
func weekly(state: SimState) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	var week: int = state.clock.week_index
	var kept: Array[Dictionary] = []
	for inv: Dictionary in state.pitch_invites:
		if int(inv["expires_week"]) > week:
			kept.append(inv)
	state.pitch_invites = kept
	if state.pitch.get("phase", "") == "prep" and int(state.pitch["end_week"]) <= week:
		state.pitch["phase"] = "present"
		notes.append({"key": "NOTE_PITCH_READY", "args": [state.pitch["client"]["name"]], "kind": "info"})
	for id: String in state.warm_clients.keys():
		if state.rng.chance("pitch", float(_p("warm_weekly_offer_chance"))):
			var client: Dictionary = state.warm_clients[id]
			state.warm_clients.erase(id)
			state.inbox.append(briefs.make_brief(state, client, client))
			notes.append({"key": "NOTE_WARM_OFFER", "args": [client["name"]], "kind": "good"})
	if _invite_chance(state) > 0.0 and state.rng.chance("pitch", _invite_chance(state)):
		var inv: Dictionary = make_invite(state)
		state.pitch_invites.append(inv)
		notes.append({"key": "NOTE_PITCH_INVITE", "args": [inv["client"]["name"]], "kind": "info"})
	return notes


func _invite_chance(state: SimState) -> float:
	if state.office_level < int(_p("min_office_level")) or not state.pitch.is_empty() or not state.pitch_invites.is_empty():
		return 0.0
	return float(_p("invite_weekly_base")) + state.reputation / float(_p("invite_reputation_div"))


## Büyük bir markanın ihale daveti: gizli tercihler, davetli rakipler, hazırlık süresi, katılım ücreti.
func make_invite(state: SimState) -> Dictionary:
	var scale: int = state.rng.pick_weighted_index("pitch", _p("client_scale_weights"))
	var sector: String = state.rng.pick("pitch", data.sectors_available(state.clock.year()))
	var client: Dictionary = clients.create_client(state, sector, scale)
	var invited: Array[String] = []
	var span: Array = _p("rivals_invited")
	for i: int in state.rng.range_i("pitch", int(span[0]), int(span[1])):
		var rid: String = rivals.pick_by_power(state)
		if not rid.is_empty() and not invited.has(rid):
			invited.append(rid)
	var weeks: Array = _p("prep_weeks")
	var fee: float = 0.0
	if state.rng.chance("pitch", float(_p("participation_fee_chance"))):
		fee = roundf(float(_p("participation_fee_1990")) * Economy.inflation(data, state.clock.year()))
	var order: Array = PREF_KEYS.duplicate()
	for i: int in range(order.size() - 1, 0, -1):
		var j: int = state.rng.range_i("pitch", 0, i)
		var tmp: Variant = order[i]
		order[i] = order[j]
		order[j] = tmp
	return {"id": state.next_id("pi"), "client": client, "rivals": invited, "prefs": _prefs(state, client),
		"hint_order": order, "prep_weeks": state.rng.range_i("pitch", int(weeks[0]), int(weeks[1])),
		"participation_fee": fee, "expires_week": state.clock.week_index + int(_p("invite_expiry_weeks"))}


## Müşterinin gizli tercihleri, her biri −1..+1 (risk iştahı, fiyat hassasiyeti, dijital yakınlık, mizah).
func _prefs(state: SimState, client: Dictionary) -> Dictionary:
	var year: int = state.clock.year()
	var digital: float = float(year - int(_p("digital_year_zero"))) / float(_p("digital_year_span"))
	if (_p("digital_sectors") as Array).has(client["sector"]):
		digital += float(_p("digital_sector_bonus"))
	return {"risk": (float(client["personality"]["risk"]) - 50.0) / 50.0,
		"budget": state.rng.range_f("pitch", -1.0, 1.0),
		"digital": clampf(digital, -1.0, 1.0),
		"humor": float(scoring.tone_value(client["sector"], "humorous", client)) / 3.0}


# --- oyuncu eylemleri ---------------------------------------------------------------

## Dönüş: "" veya hata anahtarı. Ekip hazırlık bitene kadar kampanyada çalışmaz.
func accept(state: SimState, invite_id: String, team: Array, fee_ratio: float) -> String:
	var inv: Dictionary = find_invite(state, invite_id)
	if inv.is_empty():
		return "ERR_NO_PITCH"
	if not state.pitch.is_empty():
		return "ERR_PITCH_BUSY"
	if team.is_empty():
		return "ERR_TEAM_EMPTY"
	if not (_p("fee_options") as Array).has(fee_ratio):
		return "ERR_PITCH_FEE"
	var end_week: int = state.clock.week_index + int(inv["prep_weeks"])
	for id: Variant in team:
		var emp: Dictionary = state.staff.get(str(id), {})
		if emp.is_empty() or not Employee.is_available(emp, state.clock.week_index):
			return "ERR_BUSY_EMPLOYEE"
	for id: Variant in team:
		state.staff[str(id)]["pitch_until"] = end_week
	state.pitch_invites.erase(inv)
	state.cash += float(inv["participation_fee"])
	inv.merge({"team": team.duplicate(), "fee_ratio": fee_ratio, "end_week": end_week, "s": 0.0, "k": 0.0, "phase": "prep"})
	state.pitch = inv
	return ""


func decline(state: SimState, invite_id: String) -> bool:
	var inv: Dictionary = find_invite(state, invite_id)
	if inv.is_empty():
		return false
	state.pitch_invites.erase(inv)
	return true


## Hazırlık günü: ekipteki her çalışan Strateji ve Kreatif puan biriktirir (prodüksiyon yok).
func produce_day(state: SimState) -> void:
	if state.pitch.get("phase", "") != "prep":
		return
	var ref: float = data.balf("production.stat_reference")
	for id: Variant in state.pitch["team"]:
		var emp: Dictionary = state.staff.get(str(id), {})
		if emp.is_empty() or int(emp.get("busy_until", -1)) > state.clock.week_index:
			continue
		var base: float = data.balf("production.base_per_day") * float(_p("prep_rate")) \
			* Employee.person_mult(data, emp, state.room_quality)
		state.pitch["s"] = float(state.pitch["s"]) + base * float(emp["stats"]["strategy"]) / ref
		state.pitch["k"] = float(state.pitch["k"]) + base * float(emp["stats"]["creative"]) / ref


# --- sunum --------------------------------------------------------------------

## Görünen tercih ipuçları: temel 2, hazırlıkta yeterli Strateji birikmişse 1 fazla.
func hints(pitch: Dictionary) -> Array[String]:
	var n: int = int(_p("hints_base"))
	if float(pitch.get("s", 0.0)) >= float(_p("hint_bonus_strategy")):
		n += 1
	var out: Array[String] = []
	for i: int in mini(n, (pitch["hint_order"] as Array).size()):
		out.append(str(pitch["hint_order"][i]))
	return out


## Sunumu yapan: ekipteki en yüksek İletişim statlı çalışan.
func presenter(state: SimState, pitch: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	for id: Variant in pitch["team"]:
		var emp: Dictionary = state.staff.get(str(id), {})
		if not emp.is_empty() and (best.is_empty() or float(emp["stats"]["communication"]) > float(best["stats"]["communication"])):
			best = emp
	return best


## Kartın müşteriye uyumu −1..+1 (müşteri tepkisi bundan).
func card_fit(pitch: Dictionary, card_id: String) -> float:
	var fit: float = 0.0
	for key: String in PREF_KEYS:
		fit += float(data.pitch_cards[card_id]["prefs"][key]) * float(pitch["prefs"][key])
	return clampf(fit, -1.0, 1.0)


func reaction(fit: float) -> String:
	var th: float = float(_p("reaction_threshold"))
	return "good" if fit >= th else ("bad" if fit <= -th else "neutral")


## GDD 14.2 kart_uyumu: her kartın gücü uyuma, sunucunun İletişim'ine ve kartın statındaki hazırlık payına bağlı.
func card_mult(state: SimState, pitch: Dictionary, card_id: String) -> float:
	var comm: float = float(presenter(state, pitch).get("stats", {}).get("communication", 50.0))
	var power: float = float(_p("presenter_base")) + comm / float(_p("presenter_div"))
	var total: float = maxf(0.001, float(pitch["s"]) + float(pitch["k"]))
	var share: float = (float(pitch["s"]) if data.pitch_cards[card_id]["stat"] == "strategy" else float(pitch["k"])) / total
	return maxf(0.1, 1.0 + float(_p("card_effect")) * card_fit(pitch, card_id) * power + float(_p("stat_bonus")) * (share - 0.5))


func price_mult(pitch: Dictionary, fee_ratio: float) -> float:
	var elasticity: float = float(_p("price_elasticity")) * (1.0 + float(pitch["prefs"]["budget"]) * float(_p("price_budget_weight")))
	return pow(fee_ratio, -elasticity)


func player_score(state: SimState, pitch: Dictionary, cards: Array) -> float:
	var fit: float = 1.0
	for c: Variant in cards:
		fit *= card_mult(state, pitch, str(c))
	var warm: float = float(_p("warm_bonus")) if state.warm_clients.has(pitch["client"]["id"]) else 0.0
	# Ödül lobisi (12.2): müşteri ziyaretinde itibar etkisi.
	fit *= float(state.office_effects.get("pitch_mult", 1.0))
	return (float(pitch["s"]) * float(_p("s_weight")) + float(pitch["k"]) * float(_p("k_weight"))) * fit \
		* (1.0 + state.reputation / float(_p("reputation_div"))) * (1.0 + warm) * price_mult(pitch, float(pitch["fee_ratio"]))


func rival_score(state: SimState, pitch: Dictionary, rival_id: String) -> float:
	var rng: RandomNumberGenerator = state.rng.stream("pitch")
	var span: Array = _p("rival_card_range")
	var cards: float = 1.0
	for i: int in ROUNDS.size():
		cards *= rng.randf_range(float(span[0]), float(span[1]))
	var specialist: float = float(_p("rival_specialist_bonus")) \
		if (data.rivals[rival_id]["sectors"] as Array).has(pitch["client"]["sector"]) else 1.0
	var fee: float = float(_p("rival_fee")[data.rivals[rival_id]["personality"]])
	return rivals.power(state, rival_id) * float(_p("rival_points_per_power_week")) * float(pitch["prep_weeks"]) * cards \
		* (1.0 + float(state.rivals[rival_id]["reputation"]) / float(_p("reputation_div"))) * specialist * price_mult(pitch, fee)


## Sunum: cards = her turdan bir kart. Kazanan softmax ile seçilir (GDD 14.2). Dönüş: { ok, won, rank,
## reactions: [..], scores: [{who, score}], p_win, client_name } ve etkiler uygulanır (müşteri, itibar, sıcak ilişki).
func present(state: SimState, cards: Array) -> Dictionary:
	var pitch: Dictionary = state.pitch
	if pitch.get("phase", "") != "present" or cards.size() != ROUNDS.size():
		return {"ok": false}
	for i: int in ROUNDS.size():
		if not data.pitch_cards.has(str(cards[i])) or data.pitch_cards[str(cards[i])]["round"] != ROUNDS[i]:
			return {"ok": false}
	var reactions: Array[String] = []
	for c: Variant in cards:
		reactions.append(reaction(card_fit(pitch, str(c))))
	var scores: Array[Dictionary] = [{"who": "player", "score": player_score(state, pitch, cards)}]
	for rid: Variant in pitch["rivals"]:
		if state.rivals.has(str(rid)) and bool(state.rivals[str(rid)]["alive"]):
			scores.append({"who": str(rid), "score": rival_score(state, pitch, str(rid))})
	var top: float = 0.0001
	for s: Dictionary in scores:
		top = maxf(top, float(s["score"]))
	var weights: Array = []
	for s: Dictionary in scores:
		weights.append(exp((float(s["score"]) / top - 1.0) / float(_p("softmax_temperature"))))
	var total: float = 0.0
	for w: Variant in weights:
		total += float(w)
	var winner_who: String = str(scores[state.rng.pick_weighted_index("pitch", weights)]["who"])
	var p_win: float = float(weights[0]) / total
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
	var rank: int = 1
	for i: int in scores.size():
		if scores[i]["who"] == "player":
			rank = i + 1
	var won: bool = winner_who == "player"
	var result: Dictionary = {"ok": true, "won": won, "rank": rank, "reactions": reactions, "scores": scores,
		"p_win": p_win, "client_name": pitch["client"]["name"], "cards": cards.duplicate(),
		"winner": winner_who}
	_apply(state, pitch, result)
	return result


## Kazanırsak marka portföye girer ve ilk brief'i gelir; kısa listede kalırsak itibar +0.5 ve "sıcak" ilişki.
func _apply(state: SimState, pitch: Dictionary, result: Dictionary) -> void:
	var client: Dictionary = pitch["client"]
	if bool(result["won"]):
		client["satisfaction"] = float(client["satisfaction"]) + float(_p("win_satisfaction_bonus"))
		state.clients[client["id"]] = client
		state.warm_clients.erase(client["id"])
		var brief: Dictionary = briefs.make_brief(state, client, {})
		brief["fee"] = roundf(float(brief["fee"]) * float(pitch["fee_ratio"]))
		state.inbox.append(brief)
		state.reputation += float(_p("win_reputation"))
	elif int(result["rank"]) <= 2:
		state.reputation += float(_p("shortlist_reputation"))
		state.warm_clients[client["id"]] = client
	state.reputation = clampf(state.reputation, data.balf("reputation.min"), data.balf("reputation.max"))
	for id: Variant in pitch["team"]:
		if state.staff.has(str(id)):
			state.staff[str(id)]["pitch_until"] = -1
	state.pitch_history.append({"year": state.clock.year(), "client_name": client["name"], "won": result["won"],
		"rank": result["rank"], "winner": result["winner"]})
	state.pitch = {}
