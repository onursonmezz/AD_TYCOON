class_name BriefGenerator
extends RefCounted
## Haftalık brief üretimi ve mevsimsellik (GDD 6.2, 6.3).

var data: GameData
var clients: ClientSystem


func _init(game_data: GameData, client_system: ClientSystem) -> void:
	data = game_data
	clients = client_system


## mevsim_çarpanı(ay, sektör): sektörü kapsayan mevsimlerin en büyük çarpanı (yoksa 1).
func season_multiplier(sector: String, year: int, month: int) -> float:
	var best: float = 1.0
	for season: Dictionary in data.calendar.get("seasons", []):
		if not (season["sectors"] as Array).has(sector) or year < int(season.get("from_year", 0)):
			continue
		if _season_months(season, year).has(month):
			best = maxf(best, float(season["multiplier"]))
	return best


## JSON sayıları float gelir; ayları int'e çeviririz ki has() doğru çalışsın.
func _season_months(season: Dictionary, year: int) -> Array[int]:
	var raw_months: Array = []
	if not season.has("moving"):
		raw_months = season.get("months", [])
	else:
		for entry: Dictionary in data.calendar.get("moving_holidays", []):
			if int(entry["year"]) == year:
				for key: Variant in season["moving"]:
					raw_months.append_array(entry[key])
	var months: Array[int] = []
	for m: Variant in raw_months:
		months.append(int(m))
	return months


## Hafta sonu: süresi dolan brief'leri sil, mevcut müşterilerden ve dışarıdan yeni brief'ler üret.
func weekly(state: SimState) -> void:
	var week: int = state.clock.week_index
	var kept: Array[Dictionary] = []
	for b: Dictionary in state.inbox:
		if int(b["expires_week"]) > week and (b["prospect"] as Dictionary).is_empty() == state.clients.has(b["client_id"]):
			kept.append(b)
	state.inbox = kept
	var year: int = state.clock.year()
	var month: int = state.clock.month()
	var chances: Array = data.bal("clients.brief_weekly_chance")
	for client: Dictionary in state.clients.values():
		if _has_pending(state, client["id"]):
			continue
		var p: float = float(chances[int(client["scale"])]) * season_multiplier(client["sector"], year, month)
		if state.rng.chance("briefs", p):
			state.inbox.append(make_brief(state, client, {}))
	# GDD 6.3: p_yeni = 0.04 + itibar/1000 + ödül_bonus (ödül bonusu her yıl yarıya iner, K-051).
	var p_new: float = data.balf("clients.new_client_base") + state.reputation / data.balf("clients.new_client_reputation_div") \
		+ state.award_buzz
	if state.rng.chance("briefs", p_new):
		var prospect: Dictionary = clients.create_prospect(state)
		state.inbox.append(make_brief(state, prospect, prospect))


func _has_pending(state: SimState, client_id: String) -> bool:
	if state.active_campaign.get("setup", {}).get("client_id", "") == client_id:
		return true
	for b: Dictionary in state.inbox:
		if b["client_id"] == client_id:
			return true
	return false


## prospect: portföy dışı yeni marka ise müşteri sözlüğü (kabul edilince portföye eklenir), değilse {}.
func make_brief(state: SimState, client: Dictionary, prospect: Dictionary) -> Dictionary:
	var b: Dictionary = data.bal("briefs")
	var allowed: Array = data.office(state.office_level)["allowed_sizes"]
	var sizes: Array = []
	for s: Variant in b["sizes_by_scale"][int(client["scale"])]:
		if allowed.has(s):
			sizes.append(s)
	if sizes.is_empty():
		sizes = [allowed[allowed.size() - 1]]
	var size: String = state.rng.pick("briefs", sizes)
	var infl: float = Economy.inflation(data, state.clock.year())
	var objective: String = ""
	if not state.rng.chance("briefs", float(b["free_objective_chance"])):
		objective = state.rng.pick("briefs", data.objective_ids)
	var fee_range: Array = b["fee"][size]
	var media_range: Array = b["media"][size]
	var deadline: Array = b["deadline_weeks"][size]
	var kpi_factor: Array = b["kpi_target_factor"]
	var media: float = state.rng.range_f("briefs", float(media_range[0]), float(media_range[1])) * infl
	return {"id": state.next_id("br"), "client_id": client["id"], "prospect": prospect, "sector": client["sector"],
		"objective": objective, "size": size,
		"fee": roundf(state.rng.range_f("briefs", float(fee_range[0]), float(fee_range[1])) * infl),
		"media_budget": roundf(media),
		"deadline_weeks": state.rng.range_i("briefs", int(deadline[0]), int(deadline[1])),
		"kpi_factor": state.rng.range_f("briefs", float(kpi_factor[0]), float(kpi_factor[1])),
		"created_week": state.clock.week_index,
		"expires_week": state.clock.week_index + int(b["expiry_weeks"])}
