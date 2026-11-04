class_name AwardSystem
extends RefCounted
## Ödüller ve festivaller (GDD 15): başvuru penceresi, jüri skoru, tören, itibar/moral/piyasa değeri etkisi,
## yıl sonu "Yılın Ajansı" ve sıralamalar (GDD 14.3). Ödüller data/awards.json, sayılar balance.json "awards".

var data: GameData
var rivals: RivalSystem


func _init(game_data: GameData, rival_system: RivalSystem) -> void:
	data = game_data
	rivals = rival_system


func _a(key: String) -> Variant:
	return data.bal("awards." + key)


func available(state: SimState) -> Array[String]:
	var out: Array[String] = []
	for id: String in data.award_ids:
		if int(data.awards[id]["available_from"]) <= state.clock.year():
			out.append(id)
	return out


## Başvuru penceresi törenden önceki aydır.
func entry_month(award_id: String) -> int:
	var m: int = int(data.awards[award_id]["month"]) - 1
	return m if m >= 1 else data.bali("calendar.months_per_year")


func is_open(state: SimState, award_id: String) -> bool:
	return available(state).has(award_id) and state.clock.month() == entry_month(award_id)


func open_awards(state: SimState) -> Array[String]:
	var out: Array[String] = []
	for id: String in available(state):
		if is_open(state, id):
			out.append(id)
	return out


func entry_fee(state: SimState, award_id: String) -> float:
	return float(data.awards[award_id]["entry_fee_1990"]) * Economy.inflation(data, state.clock.year())


## Kampanyanın ödül kategorisi: ana kanalın türü; 3+ kanal "integrated" (entegre).
func category_of(hist: Dictionary) -> String:
	if int(hist.get("channel_count", 1)) >= 3:
		return "integrated"
	return str(data.channels[hist["main_channel"]]["category"])


func is_eligible(award_id: String, hist: Dictionary) -> bool:
	var award: Dictionary = data.awards[award_id]
	var cats: Array = award["eligible_categories"]
	if not cats.is_empty() and not cats.has(category_of(hist)) and not cats.has(data.channels[hist["main_channel"]]["category"]):
		return false
	var objs: Array = award["eligible_objectives"]
	var secs: Array = award["eligible_sectors"]
	if objs.is_empty() and secs.is_empty():
		return true
	return objs.has(hist["objective"]) or secs.has(hist["sector"])


func _entered(state: SimState, award_id: String, campaign_id: String) -> bool:
	for e: Dictionary in state.award_entries:
		if e["award"] == award_id and e["campaign"] == campaign_id:
			return true
	for r: Dictionary in state.award_history:
		if r["award"] == award_id and r["campaign"] == campaign_id:
			return true
	return false


## Son 12 ayda biten, bu ödüle henüz gönderilmemiş, koşulları tutan kampanyalar (history kayıtları).
func eligible_campaigns(state: SimState, award_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var since: int = state.clock.week_index - int(_a("eligible_weeks"))
	for h: Dictionary in state.history:
		if int(h["week"]) >= since and is_eligible(award_id, h) and not _entered(state, award_id, h["campaign"]):
			out.append(h)
	return out


## Dönüş: "" veya hata anahtarı.
func enter(state: SimState, economy: Economy, award_id: String, campaign_id: String) -> String:
	if not data.awards.has(award_id) or not is_open(state, award_id):
		return "ERR_AWARD_CLOSED"
	# Sektör tanınmayan ajansı ciddiye almaz (M10 önerisi, K-076): en az bu itibar; 0 = sınır yok.
	if state.reputation < float(data.bal("awards").get("min_reputation", 0.0)):
		return "ERR_AWARD_REPUTATION"
	for h: Dictionary in eligible_campaigns(state, award_id):
		if h["campaign"] == campaign_id:
			economy.pay(state, entry_fee(state, award_id))
			state.award_entries.append({"award": award_id, "campaign": campaign_id, "year": state.clock.year()})
			return ""
	return "ERR_AWARD_NOT_ELIGIBLE"


## GDD 15: puan×0.5 + N×2 + viral + kategori uyumu + jüri(±1) [+ KPI aşımı×3] + ödülün zorluğu.
func jury_score(award_id: String, hist: Dictionary, rng: RandomNumberGenerator) -> float:
	return expected_score(award_id, hist) + rng.randf_range(-float(_a("jury_noise")), float(_a("jury_noise")))


## Jüri rastgeleliği olmadan beklenen skor (arayüz ipucu ve botlar için).
func expected_score(award_id: String, hist: Dictionary) -> float:
	var award: Dictionary = data.awards[award_id]
	var s: float = float(hist["score"]) * float(_a("score_weight")) + float(hist["factors"]["n"]) * float(_a("novelty_weight"))
	if bool(hist.get("viral", false)):
		s += float(_a("viral_bonus"))
	if (award["categories"] as Array).has(category_of(hist)):
		s += float(_a("category_match"))
	s += float(award["kpi_weight"]) * clampf(float(hist.get("kpi_ratio", 1.0)) - 1.0, 0.0, 1.0)
	return s + float(award["difficulty"])


## "" (ödülsüz), shortlist, bronze, silver, gold. Grand Prix törende ayrıca seçilir.
func level_for(award_id: String, score: float) -> String:
	var th: Dictionary = data.awards[award_id]["thresholds"]
	var level: String = ""
	for l: String in ["shortlist", "bronze", "silver", "gold"]:
		if score >= float(th[l]):
			level = l
	return level


## Tören ayının başında çağrılır. Dönüş: { award, year, player: [{campaign, client_name, name, score, level}],
## rivals: [{rival, level}], grand_prix: {who: "player"|rival_id|"", campaign} } — sonuç yoksa {}.
func ceremony(state: SimState, award_id: String) -> Dictionary:
	var rng: RandomNumberGenerator = state.rng.stream("awards")
	var year: int = state.clock.year()
	var entries: Array[Dictionary] = []
	var kept: Array[Dictionary] = []
	for e: Dictionary in state.award_entries:
		if e["award"] == award_id:
			entries.append(e)
		else:
			kept.append(e)
	state.award_entries = kept
	var result: Dictionary = {"award": award_id, "year": year, "player": [], "rivals": [], "grand_prix": {"who": "", "campaign": ""}}
	var best: float = -INF
	var award: Dictionary = data.awards[award_id]
	for e: Dictionary in entries:
		var hist: Dictionary = _history_of(state, e["campaign"])
		if hist.is_empty():
			continue
		var score: float = jury_score(award_id, hist, rng)
		var row: Dictionary = {"award": award_id, "year": year, "campaign": e["campaign"], "client_name": hist.get("client_name", ""),
			"name": hist.get("name", ""), "score": score, "level": level_for(award_id, score), "team": hist.get("team", [])}
		(result["player"] as Array).append(row)
		if score > best:
			best = score
			result["grand_prix"] = {"who": "player", "campaign": e["campaign"]}
	for rid: String in rivals.alive_ids(state):
		for raw: float in rivals.award_entries(state, rid):
			var score: float = raw + float(award["difficulty"])
			var level: String = level_for(award_id, score)
			if not level.is_empty():
				(result["rivals"] as Array).append({"rival": rid, "level": level})
				state.rivals[rid]["award_points"] = float(state.rivals[rid]["award_points"]) + float(_a("points")[level])
			if score > best:
				best = score
				result["grand_prix"] = {"who": rid, "campaign": ""}
	if best < float(award["thresholds"]["grand_prix"]):
		result["grand_prix"] = {"who": "", "campaign": ""}
	_apply_player_results(state, result)
	return result


func _history_of(state: SimState, campaign_id: String) -> Dictionary:
	for i: int in range(state.history.size() - 1, -1, -1):
		if state.history[i]["campaign"] == campaign_id:
			return state.history[i]
	return {}


## İtibar, ödül puanı (sıralama + yeni müşteri), ekibin morali ve piyasa değeri.
func _apply_player_results(state: SimState, result: Dictionary) -> void:
	var gp: Dictionary = result["grand_prix"]
	for row: Dictionary in result["player"]:
		var level: String = row["level"]
		if gp["who"] == "player" and gp["campaign"] == row["campaign"]:
			level = "grand_prix"
			row["level"] = level
		state.award_history.append(row)
		if level.is_empty():
			continue
		var pts: float = float(_a("points")[level])
		state.reputation = clampf(state.reputation + float(_a("reputation")[level]), data.balf("reputation.min"),
			data.balf("reputation.max"))
		state.award_points_year += pts
		state.award_buzz += pts * float(_a("buzz_per_point"))
		for id: Variant in row["team"]:
			var emp: Dictionary = state.staff.get(str(id), {})
			if emp.is_empty():
				continue
			emp["morale"] = clampf(float(emp["morale"]) + float(_a("morale")[level]), 0.0, 100.0)
			emp["award_points"] = float(emp.get("award_points", 0.0)) + pts
	if gp["who"] != "" and gp["who"] != "player":
		state.rivals[gp["who"]]["award_points"] = float(state.rivals[gp["who"]]["award_points"]) + float(_a("points")["grand_prix"])


## Yıl sonu (gelir sayaçları sıfırlanmadan önce): sıralamalar, Yılın Ajansı, rakip puanlarının sıfırlanması.
## Dönüş: { year, creative: [{who, points}], biggest: [{who, revenue}], creative_rank, biggest_rank, agency_of_year }
func year_end(state: SimState) -> Dictionary:
	var year: int = state.clock.year()
	var creative: Array[Dictionary] = [{"who": "player", "points": state.award_points_year}]
	var biggest: Array[Dictionary] = [{"who": "player", "revenue": state.year_income}]
	var growth: Dictionary = {"player": state.year_income / maxf(1.0, state.last_year_income) - 1.0}
	for rid: String in rivals.alive_ids(state):
		creative.append({"who": rid, "points": float(state.rivals[rid]["award_points"])})
		biggest.append({"who": rid, "revenue": rivals.revenue(state, rid)})
		growth[rid] = float(data.bal("rivals.personalities")[data.rivals[rid]["personality"]]["growth"]) * 12.0
	creative.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["points"]) > float(b["points"]))
	biggest.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["revenue"]) > float(b["revenue"]))
	var best_who: String = ""
	var best_value: float = 0.0
	for row: Dictionary in creative:
		var v: float = float(row["points"]) + float(_a("agency_of_year_growth_weight")) * float(growth[row["who"]])
		if float(row["points"]) > 0.0 and v > best_value:
			best_value = v
			best_who = row["who"]
	if best_who == "player":
		state.reputation = clampf(state.reputation + float(_a("agency_of_year_reputation")), data.balf("reputation.min"),
			data.balf("reputation.max"))
	var out: Dictionary = {"year": year, "creative": creative, "biggest": biggest, "agency_of_year": best_who,
		"creative_rank": _rank_of(creative), "biggest_rank": _rank_of(biggest)}
	state.rankings = out
	state.ranking_history.append({"year": year, "creative_rank": out["creative_rank"], "biggest_rank": out["biggest_rank"],
		"agency_of_year": best_who == "player"})
	state.last_year_income = state.year_income
	state.award_points_year = 0.0
	state.award_buzz *= 1.0 - float(_a("buzz_yearly_decay"))
	for rid: String in state.rivals:
		state.rivals[rid]["award_points"] = 0.0
	return out


func _rank_of(rows: Array[Dictionary]) -> int:
	for i: int in rows.size():
		if rows[i]["who"] == "player":
			return i + 1
	return 0
