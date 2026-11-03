class_name Scoring
extends RefCounted
## Kampanya puanlaması — GDD 7.2–7.9 (M, F, B, N, sinerji, göreceli 1–10 puan, yumuşak rekor).
## Her fonksiyon çarpanın yanında açıklama için ara değerleri de döndürür (GDD 7.12, Sütun 1).

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


# --- 7.2 Kombinasyon uyumu (M) ----------------------------------------------

## −3..+3 uyum değerini çarpana çevirir. Buçuklu değerlerde komşu iki değer arasında doğrusal ara değer (K-016).
func fit_mult(x: float) -> float:
	var table: Dictionary = data.bal("fit_multiplier")
	var v: float = clampf(x, -3.0, 3.0)
	var lo: int = floori(v)
	var hi: int = ceili(v)
	var a: float = float(table[str(lo)])
	if lo == hi:
		return a
	return lerpf(a, float(table[str(hi)]), v - float(lo))


## Ton değeri: sektör grubunun ton uyumu + marka kişiliği (8.3 notu: cesur marka Cesur/Esprili +1, muhafazakâr marka Cesur −1).
func tone_value(sector_id: String, tone_id: String, client: Dictionary) -> int:
	var group: String = data.sectors[sector_id]["tone_group"]
	var v: int = data.fit("tone", group, tone_id)
	var risk: float = float(client.get("personality", {}).get("risk", 50))
	if risk >= data.balf("clients.bold_risk_min") and (tone_id == "bold" or tone_id == "humorous"):
		v += 1
	elif risk <= data.balf("clients.conservative_risk_max") and tone_id == "bold":
		v -= 1
	return clampi(v, -3, 3)


func combination(setup: Dictionary, client: Dictionary) -> Dictionary:
	var sector: String = setup["sector"]
	var objective: String = setup["objective"]
	var audience: String = setup["audience"]
	var sh: float = fit_mult(data.fit("sector_objective", sector, objective))
	var sk: float = fit_mult(data.fit("sector_audience", sector, audience))
	var kn: float = 0.0
	for entry: Dictionary in setup["mix"]:
		var ch: String = entry["channel"]
		var avg: float = (data.fit("channel_objective", ch, objective) + data.fit("channel_audience", ch, audience)) / 2.0
		kn += float(entry["share"]) * fit_mult(avg)
	var tone: float = pow(fit_mult(tone_value(sector, setup["tone"], client)), data.balf("scoring.tone_exponent"))
	var trend: float = 1.0  # M7: aktif trend bonusları
	var w: Dictionary = data.bal("combo_weights")
	var m: float = pow(sh, float(w["sector_objective"])) * pow(sk, float(w["sector_audience"])) \
		* pow(kn, float(w["channel"])) * pow(tone, float(w["tone"])) * trend
	return {"sh": sh, "sk": sk, "kn": kn, "tone": tone, "trend": trend, "m": m}


# --- 7.4 Faz odakları (F) ----------------------------------------------------

## %60 tavanını aşan slider payı azalan getiriyle sayılır (7.4 kuralı).
func effective_share(share: float) -> float:
	var cap: float = data.balf("focus.slider_soft_cap")
	if share <= cap:
		return share
	return cap + (share - cap) * data.balf("production.overcap_efficiency")


func importance_value(level: int) -> float:
	return float(data.bal("importance_values")[str(level)])


func phase_focus(objective_id: String, phase: int, sliders: Array) -> Dictionary:
	var ids: Array[String] = data.focus_ids_of_phase(phase)
	var score: float = 0.0
	var values: Array[float] = []
	for i: int in ids.size():
		var imp: float = importance_value(data.focus_importance(objective_id, ids[i]))
		values.append(imp)
		score += effective_share(float(sliders[i])) * imp
	values.sort()
	values.reverse()
	var cap: float = data.balf("focus.slider_soft_cap")
	var ideal: float = 0.0
	var remaining: float = 1.0
	for v: float in values:
		var take: float = minf(cap, remaining)
		ideal += take * v
		remaining -= take
	var ratio: float = 0.0 if ideal <= 0.0 else minf(1.0, score / ideal)
	var lo: float = data.balf("focus.min_mult")
	var hi: float = data.balf("focus.max_mult")
	return {"score": score, "ideal": ideal, "f": lo + (hi - lo) * ratio}


func focus(objective_id: String, sliders_by_phase: Array) -> Dictionary:
	var phases: Array[Dictionary] = []
	var product: float = 1.0
	for phase: int in 3:
		var pf: Dictionary = phase_focus(objective_id, phase, sliders_by_phase[phase])
		phases.append(pf)
		product *= float(pf["f"])
	return {"f": pow(product, 1.0 / 3.0), "phases": phases}


# --- 7.7 S/K dengesi (B) -----------------------------------------------------

func balance_sk(s_total: float, k_total: float, objective_id: String) -> Dictionary:
	var ratio: float = maxf(s_total, 0.001) / maxf(1.0, k_total)
	var ideal: float = float(data.objectives[objective_id]["ideal_sk"])
	var deviation: float = absf(log(ratio / ideal))
	var b: float = 1.0 - minf(data.balf("balance_sk.max_penalty"), deviation * data.balf("balance_sk.penalty_per_log"))
	return {"b": b, "ratio": ratio, "ideal": ideal}


# --- 7.8 Tekrar ve yenilik (N) -----------------------------------------------

static func main_channel(mix: Array) -> String:
	var best: String = ""
	var best_share: float = -1.0
	for entry: Dictionary in mix:
		if float(entry["share"]) > best_share:
			best_share = float(entry["share"])
			best = entry["channel"]
	return best


const AI_FATIGUE_YEAR: int = 2026


func novelty(setup: Dictionary, history: Array[Dictionary], week_index: int, year: int) -> Dictionary:
	var n: float = 1.0
	var flags: Array[String] = []
	var nv: Dictionary = data.bal("novelty")
	var window: int = data.bali("novelty_rules.recent_pair_window")
	for i: int in range(maxi(0, history.size() - window), history.size()):
		var h: Dictionary = history[i]
		if h["sector"] == setup["sector"] and h["objective"] == setup["objective"]:
			n *= float(nv["same_pair_recent3"])
			flags.append("same_pair_recent")
			break
	if not history.is_empty():
		var last: Dictionary = history[history.size() - 1]
		if last["sector"] == setup["sector"] and last["objective"] == setup["objective"] \
				and last["main_channel"] == main_channel(setup["mix"]):
			n *= float(nv["same_triplet_last"])
			flags.append("same_triplet_last")
	var client_weeks: int = data.bali("novelty_rules.same_client_weeks")
	for i: int in range(history.size() - 1, -1, -1):
		var h: Dictionary = history[i]
		if week_index - int(h["week"]) > client_weeks:
			break
		if h["client_id"] == setup["client_id"] and h["objective"] == setup["objective"]:
			n *= float(nv["same_client_12w"])  # M7: "Seri Kampanya" Ar-Ge'si bu cezayı kaldırır
			flags.append("same_client")
			break
	var start_year: int = data.bali("time.base_year")
	for entry: Dictionary in setup["mix"]:
		var from: int = int(data.channels[entry["channel"]]["available_from"])
		if from > start_year and year - from <= data.bali("novelty_rules.pioneer_years"):
			n *= float(nv["pioneer_bonus"])
			flags.append("pioneer")
			break
	# AI araçları (12.5): araç başına özgünlük bedeli; 2026'dan sonra "AI'dan bıktık" (5.2) ek ceza.
	var ai: float = float(setup.get("ai_penalty", 0.0))
	if ai > 0.0:
		n *= 1.0 - ai
		if year >= AI_FATIGUE_YEAR:
			n *= float(nv["ai_fatigue_from_2026"])
		flags.append("ai")
	return {"n": n, "flags": flags}


# --- 7.3 Kanal sinerjisi -----------------------------------------------------

func recommended_channels(media_budget: float, year: int) -> int:
	var unit: float = data.balf("synergy.recommended_budget_unit") * Economy.inflation(data, year)
	var x: float = log(maxf(media_budget, 1.0) / unit) / log(10.0)
	return maxi(1, 1 + floori(x * data.balf("synergy.recommended_log_mult")))


func synergy(mix: Array, media_budget: float, year: int) -> Dictionary:
	var ids: Array[String] = []
	var cats: Array[String] = []
	for entry: Dictionary in mix:
		ids.append(str(entry["channel"]))
		cats.append(str(data.channels[entry["channel"]]["category"]))
	var bonus: float = 0.0
	var pairs: Array[String] = []
	for pair: Dictionary in data.bal("synergy.pairs"):
		if _side_matches(pair["a"], ids, cats) and _side_matches(pair["b"], ids, cats):
			bonus += float(pair["bonus"])
			pairs.append(str(pair["id"]))
	var extra: int = maxi(0, ids.size() - recommended_channels(media_budget, year))
	var fragmentation: float = float(extra) * data.balf("synergy.fragmentation_per_channel")
	return {"synergy": 1.0 + bonus - fragmentation, "pairs": pairs, "fragmentation": fragmentation}


func _side_matches(side: Dictionary, ids: Array[String], cats: Array[String]) -> bool:
	for ch: Variant in side.get("channels", []):
		if ids.has(ch):
			return true
	for cat: Variant in side.get("categories", []):
		if cats.has(cat):
			return true
	return false


# --- 7.9 Toplam kalite ve 1–10 puan ------------------------------------------

## Hızlı başlangıçta (GDD 5.1) dönem tabanı oyunun başladığı yıldan büyümeye başlar (K-064): başlangıç yılı − 1990.
var era_offset: int = 0

func era_base(year: int, size: String) -> float:
	return float(data.bal("size_multiplier")[size]) * data.balf("score.era_base") \
		* pow(data.balf("score.era_growth"), year - data.bali("time.base_year") - era_offset)


## Hataların toplam payı (K-047): hata başına işin kendi kalitesinin bir yüzdesi, toplamda üst sınırlı.
## GDD 7.9 "hata_ağırlığı kampanya büyüdükçe artar": ceza işin kendi emeğiyle ölçeklenir, dönemle değil.
func error_penalty(errors: int) -> float:
	return minf(errors * data.balf("scoring.error_penalty_per_error"), data.balf("scoring.error_penalty_max"))


## Ham puandan 1–10 puan. best: bu büyüklükteki rekor ham puan (yoksa 0).
func final_score(raw: float, errors: int, year: int, size: String, best: float, rng: RandomNumberGenerator) -> Dictionary:
	var target: float = maxf(best * data.balf("score.beat_best_factor"), era_base(year, size))
	var r: float = raw / target
	var noise: float = data.balf("score.noise")
	var score: float = 10.0 * pow(r, data.balf("score.exponent")) + data.balf("score.offset") + rng.randf_range(-noise, noise)
	score = snappedf(clampf(score, data.balf("scoring.min_score"), data.balf("scoring.max_score")), 0.1)
	var perfect: bool = false
	if score >= data.balf("scoring.perfect_min_score") and errors == 0 and r > data.balf("scoring.perfect_min_r") \
			and rng.randf() < data.balf("scoring.perfect_chance"):
		score = data.balf("scoring.max_score")
		perfect = true
	var new_best: float = best
	if raw > best:
		new_best = best + data.balf("score.best_update_lerp") * (raw - best)
	return {"score": score, "r": r, "target": target, "perfect": perfect, "new_best": new_best}


## S/K/T toplamları (GDD 7.5 alan→stat eşlemesi, focus_areas.json "stats").
func stat_totals(points: Dictionary) -> Dictionary:
	var totals: Dictionary = {"strategy": 0.0, "creative": 0.0, "technical": 0.0}
	for area: String in points:
		var split: Dictionary = data.focus_areas[area]["stats"]
		for stat: String in split:
			totals[stat] = float(totals[stat]) + float(points[area]) * float(split[stat])
	return totals


## Bir kampanyanın tüm puanlaması. Dönüş: rapor için bütün çarpanlar.
func evaluate(campaign: Dictionary, client: Dictionary, history: Array[Dictionary], week_index: int,
		year: int, best: float, rng: RandomNumberGenerator) -> Dictionary:
	var setup: Dictionary = campaign["setup"]
	var totals: Dictionary = stat_totals(campaign["points"])
	var s: float = totals["strategy"]
	var k: float = totals["creative"]
	var t: float = totals["technical"]
	var comb: Dictionary = combination(setup, client)
	var foc: Dictionary = focus(setup["objective"], setup["sliders"])
	var bal_sk: Dictionary = balance_sk(s, k, setup["objective"])
	var nov: Dictionary = novelty(setup, history, week_index, year)
	var syn: Dictionary = synergy(setup["mix"], float(setup["media_budget"]), year)
	var errors: int = int(campaign["errors"])
	var raw: float = (s + k + t) * float(comb["m"]) * float(foc["f"]) * float(bal_sk["b"]) * float(nov["n"]) \
		* float(syn["synergy"]) * (1.0 - error_penalty(errors))
	var fin: Dictionary = final_score(raw, errors, year, setup["size"], best, rng)
	return {"s": s, "k": k, "t": t, "errors": errors, "combination": comb, "focus": foc, "balance": bal_sk,
		"novelty": nov, "synergy": syn, "raw": raw, "score": fin["score"], "r": fin["r"], "target": fin["target"],
		"perfect": fin["perfect"], "new_best": fin["new_best"]}
