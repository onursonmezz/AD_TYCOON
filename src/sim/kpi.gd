class_name Kpi
extends RefCounted
## Yayın sonuçları (GDD 7.10) ve ajans geliri (GDD 7.11).

var data: GameData
var scoring: Scoring
## Basılı işlerin görülme/kalite hesabı ve kanal seçeneklerinin etkileri (Simulation bağlar).
var prints: PrintSystem = null
var options: ChannelOptions = null


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


## Medya talebinin yoğun olduğu aylarda CPM artar (7.10 "mevsim", calendar.json → cpm_season).
func cpm_season(year: int, month: int) -> float:
	var cfg: Dictionary = data.calendar.get("cpm_season", {})
	var m: float = float(cfg.get("months", {}).get(str(month), 1.0))
	for entry: Dictionary in data.calendar.get("moving_holidays", []):
		if int(entry["year"]) != year:
			continue
		var moving: Dictionary = cfg.get("moving", {})
		for key: String in moving:
			for mm: Variant in entry.get(key, []):
				if int(mm) == month:
					m = maxf(m, float(moving[key]))
	return m


## Kampanyanın KPI'ları. score: 1–10 puan. month: yayın ayı (CPM mevsimi).
func compute(setup: Dictionary, client: Dictionary, score: float, year: int, rng: SimRng, month: int = 1) -> Dictionary:
	var media: float = float(setup["media_budget"])
	var audience: String = setup["audience"]
	var pop: float = population(year)
	var infl: float = Economy.inflation(data, year)
	# Otomatik kitle (Hedef Kitle araştırması öncesi, M7-B): geniş, yetişkin payı kadar.
	var share_of_pop: float = float((data.bal("kpi.audience_share") as Dictionary).get(audience, data.balf("kpi.audience_share_auto")))
	var conv_mult: float = float(data.bal("kpi.objective_conversion")[setup["objective"]])
	var reach: float = 0.0
	var engagements: float = 0.0
	var conversions: float = 0.0
	var per_channel: Array[Dictionary] = []
	var efficiency: float = float(setup.get("media_efficiency", 1.0))
	var season: float = cpm_season(year, month)
	var recall_reach: float = 0.0
	for entry: Dictionary in setup["mix"]:
		var ch: String = entry["channel"]
		var opts: Dictionary = entry.get("options", {})
		var production_share: float = float(options.production(ch).get("share", 0.0)) if options != null else 0.0
		var spend: float = media * float(entry["share"]) * (1.0 - production_share) * efficiency
		var interest_now: float = interest(ch, year)
		var fx: Dictionary = options.effects(ch, opts, setup, year) if options != null else {}
		var job: Dictionary = opts.get("job", {})
		var impressions: float = 0.0
		var quality: float = 1.0
		var er: float = data.channel_param(ch, "er")
		if not job.is_empty() and prints != null:
			impressions = prints.impressions(job)
			quality = prints.quality_effect(job, setup["sector"])
		elif opts.has("_influencer_kpi"):
			impressions = float(opts["_influencer_kpi"]["impressions"]) * float(opts.get("_scandal_mult", 1.0))
			er = float(opts["_influencer_kpi"]["er"])
		elif production_share >= 1.0:
			# Etkinlik: bütçenin tamamı prodüksiyon; katılım/görülme, marj sonrası kalan bütçeyle ölçülür.
			var event_spend: float = media * float(entry["share"]) * (1.0 - float(options.production(ch).get("margin", 0.0)))
			impressions = event_spend / (data.channel_param(ch, "cpm") * infl * float(fx.get("cost_mult", 1.0))) * 1000.0
		else:
			var cpm: float = data.channel_param(ch, "cpm") * infl * demand(interest_now) * season * float(fx.get("cost_mult", 1.0))
			impressions = spend / cpm * 1000.0
		impressions *= interest_now * float(fx.get("impressions_mult", 1.0)) * float(opts.get("_press", 1.0))
		er *= float((setup.get("category_er_mult", {}) as Dictionary).get(data.channels[ch]["category"], 1.0))
		var pool: float = maxf(1.0, pop * share_of_pop * data.channel_audience_size(ch, audience) * reach_cap(client))
		var r: float = pool * (1.0 - exp(-impressions / pool))
		var aud_fit: float = scoring.fit_mult(data.fit("channel_audience", ch, audience)) if not audience.is_empty() else 1.0
		var e: float = r * er * (data.balf("kpi.er_score_base") + data.balf("kpi.er_score_per_point") * score) \
			* aud_fit * quality * float(fx.get("er_mult", 1.0))
		var c: float = e * data.channel_param(ch, "cvr") * conv_mult * float(fx.get("cvr_mult", 1.0))
		reach += r
		recall_reach += r * float(fx.get("recall_mult", 1.0))
		engagements += e
		conversions += c
		per_channel.append({"channel": ch, "spend": spend, "impressions": impressions, "reach": r,
			"engagements": e, "conversions": c, "press": opts.has("_press")})
	var viral: bool = _roll_viral(setup, score, year, rng)
	if viral:
		var organic: float = rng.range_f("kpi", data.balf("kpi.viral.organic_min"), data.balf("kpi.viral.organic_max"))
		reach += reach * organic
		recall_reach += recall_reach * organic
	var awareness_lift: float = minf(1.0, recall_reach / pop * recall(score))
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


## Karışımda basılı iş kanallarının bütçe payı (bu pay medya değil prodüksiyondur: komisyon yerine marj).
func print_share(setup: Dictionary) -> float:
	var s: float = 0.0
	for entry: Dictionary in setup.get("mix", []):
		if PrintSystem.is_print_channel(data, entry["channel"]):
			s += float(entry["share"])
	return s


## Karışımda prodüksiyon payı (TV çekimi, etkinlik): komisyon yerine marj alınır.
func production_share(setup: Dictionary) -> float:
	if options == null:
		return 0.0
	var s: float = 0.0
	for entry: Dictionary in setup.get("mix", []):
		s += float(entry["share"]) * float(options.production(entry["channel"]).get("share", 0.0))
	return s


## GDD 7.11 ajans geliri: fee + medya komisyonu (yalnız medya kısmı) + prodüksiyon marjı + performans primi.
## Kesinti (gecikme cezası, iade) şimdilik yok; gecikme memnuniyete yansır.
func agency_income(setup: Dictionary, kpi_ratio: float) -> Dictionary:
	var fee: float = float(setup["fee"])
	var media_part: float = float(setup["media_budget"]) * (1.0 - print_share(setup) - production_share(setup))
	var commission: float = media_part * float(setup.get("commission_rate", data.balf("media_commission.default")))
	var bonus: float = fee * clampf(kpi_ratio - 1.0, 0.0, data.balf("agency.performance_bonus_max"))
	return {"fee": fee, "commission": commission, "bonus": bonus,
		"production_margin": float(setup.get("production_margin", 0.0))}
