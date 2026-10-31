class_name Kpi
extends RefCounted
## Yayın sonuçları (GDD 7.10) ve ajans geliri (GDD 7.11).

var data: GameData
var scoring: Scoring


func _init(game_data: GameData, scoring_ref: Scoring) -> void:
	data = game_data
	scoring = scoring_ref


func population(year: int) -> float:
	return data.balf("kpi.market_population_1990") \
		* pow(1.0 + data.balf("kpi.population_growth"), year - data.bali("time.base_year"))


## ilgi(kanal, yıl) = piecewise_linear(kanal.curve, yıl); eğrisi olmayan kanal için 1.0 (M4'te eğriler eklenecek).
func interest(channel_id: String, year: int) -> float:
	var ch: Dictionary = data.channels[channel_id]
	if not ch.has("interest_curve"):
		return 1.0
	var curve: Array = ch["interest_curve"]
	if year <= int(curve[0][0]):
		return float(curve[0][1])
	for i: int in range(1, curve.size()):
		var y1: int = int(curve[i][0])
		if year <= y1:
			var y0: int = int(curve[i - 1][0])
			return lerpf(float(curve[i - 1][1]), float(curve[i][1]), float(year - y0) / float(y1 - y0))
	return float(curve[curve.size() - 1][1])


func demand(interest_value: float) -> float:
	return data.balf("kpi.demand_base") + data.balf("kpi.demand_range") * interest_value


func recall(score: float) -> float:
	return data.balf("kpi.recall_base") + data.balf("kpi.recall_per_point") * score


func reach_cap(client: Dictionary) -> float:
	return float(data.bal("kpi.scale_reach_cap")[int(client["scale"])])


## Kampanyanın KPI'ları. score: 1–10 puan.
func compute(setup: Dictionary, client: Dictionary, score: float, year: int, rng: SimRng) -> Dictionary:
	var media: float = float(setup["media_budget"])
	var audience: String = setup["audience"]
	var pop: float = population(year)
	var infl: float = Economy.inflation(data, year)
	var share_of_pop: float = float(data.bal("kpi.audience_share")[audience])
	var conv_mult: float = float(data.bal("kpi.objective_conversion")[setup["objective"]])
	var reach: float = 0.0
	var engagements: float = 0.0
	var conversions: float = 0.0
	var per_channel: Array[Dictionary] = []
	for entry: Dictionary in setup["mix"]:
		var ch: String = entry["channel"]
		var spend: float = media * float(entry["share"])  # M4: tedarikçi_verimi_k
		var cpm: float = data.channel_param(ch, "cpm") * infl * demand(interest(ch, year))  # M4: mevsim
		var impressions: float = spend / cpm * 1000.0
		var pool: float = maxf(1.0, pop * share_of_pop * data.channel_audience_size(ch, audience) * reach_cap(client))
		var r: float = pool * (1.0 - exp(-impressions / pool))
		var aud_fit: float = scoring.fit_mult(data.fit("channel_audience", ch, audience))
		var e: float = r * data.channel_param(ch, "er") * (data.balf("kpi.er_score_base") \
			+ data.balf("kpi.er_score_per_point") * score) * aud_fit
		var c: float = e * data.channel_param(ch, "cvr") * conv_mult
		reach += r
		engagements += e
		conversions += c
		per_channel.append({"channel": ch, "spend": spend, "impressions": impressions, "reach": r,
			"engagements": e, "conversions": c})
	var viral: bool = _roll_viral(setup, score, year, rng)
	if viral:
		reach += reach * rng.range_f("kpi", data.balf("kpi.viral.organic_min"), data.balf("kpi.viral.organic_max"))
	var awareness_lift: float = minf(1.0, reach / pop * recall(score))
	var total_budget: float = media + float(setup["fee"])
	var basket: float = float(data.sectors[setup["sector"]]["avg_basket"]) * infl
	var roi: float = (conversions * basket - total_budget) / total_budget
	return {"reach": reach, "engagements": engagements, "conversions": conversions,
		"awareness_lift": awareness_lift, "roi": roi, "viral": viral, "per_channel": per_channel}


func _roll_viral(setup: Dictionary, score: float, year: int, rng: SimRng) -> bool:
	if year < data.bali("kpi.viral.from_year") or score < data.balf("kpi.viral.min_score"):
		return false
	var base: float = data.balf("kpi.viral.per_point") * (score - data.balf("kpi.viral.score_offset"))
	var tone_bonus: float = float(data.bal("kpi.viral.tone_bonus").get(setup["tone"], 1.0))
	for entry: Dictionary in setup["mix"]:
		var potential: float = float(data.channels[entry["channel"]]["viral"])
		if potential > 0.0 and rng.chance("kpi", base * potential * tone_bonus):
			return true
	return false


## Brief'teki KPI türü (hedefe göre) ve sonuçtaki değeri.
func kpi_type(objective_id: String) -> String:
	return str(data.bal("kpi.objective_kpi")[objective_id])


static func value_of(result: Dictionary, type: String) -> float:
	return float(result[type])


## Brief'in KPI hedefi için referans: ortalama bir kanal, ortalama kitle, referans puan.
func reference_value(objective_id: String, media_budget: float, client: Dictionary, year: int) -> float:
	var ref: Dictionary = data.bal("kpi.reference_channel")
	var infl: float = Economy.inflation(data, year)
	var pop: float = population(year)
	var shares: Dictionary = data.bal("kpi.audience_share")
	var pool: float = maxf(1.0, pop * reach_cap(client) / float(shares.size()))
	var impressions: float = media_budget / (float(ref["cpm"]) * infl) * 1000.0
	var reach: float = pool * (1.0 - exp(-impressions / pool))
	var score: float = data.balf("kpi.reference_score")
	var eng: float = reach * float(ref["er"]) * (data.balf("kpi.er_score_base") + data.balf("kpi.er_score_per_point") * score)
	var conv: float = eng * float(ref["cvr"]) * float(data.bal("kpi.objective_conversion")[objective_id])
	var values: Dictionary = {"reach": reach, "engagements": eng, "conversions": conv,
		"awareness_lift": minf(1.0, reach / pop * recall(score))}
	return float(values[kpi_type(objective_id)])


## GDD 7.11 ajans geliri: fee + medya komisyonu + performans primi (prodüksiyon marjı M4'te, kesinti şimdilik yok).
func agency_income(setup: Dictionary, kpi_ratio: float) -> Dictionary:
	var fee: float = float(setup["fee"])
	var commission: float = float(setup["media_budget"]) * float(setup.get("commission_rate", data.balf("media_commission.default")))
	var bonus: float = fee * clampf(kpi_ratio - 1.0, 0.0, data.balf("agency.performance_bonus_max"))
	return {"fee": fee, "commission": commission, "bonus": bonus}
