class_name MediaPlanning
extends RefCounted
## Kanal karışımı kuralları (GDD 7.1), medya satın alma verimi (GDD 10.4), kanal seçenekleri ve influencer seçimi
## (GDD 9), teslimdeki baskı/prodüksiyon/medya maliyetleri ve riskler.

var data: GameData
var prints: PrintSystem
var options: ChannelOptions
var influencers: InfluencerSystem


func _init(game_data: GameData, print_system: PrintSystem, channel_options: ChannelOptions, influencer_system: InfluencerSystem) -> void:
	data = game_data
	prints = print_system
	options = channel_options
	influencers = influencer_system


## 7.1: kanal sayısı ofis seviyesi ve medya planlama yeteneğiyle sınırlı; çoklu kanal Y3'te açılır (17).
func channel_limit(state: SimState, team: Array) -> int:
	if state.clock.game_year() < data.bali("mix.multi_from_game_year"):
		return 1
	var by_office: Array = data.bal("mix.limit_by_office")
	var limit: int = int(by_office[clampi(state.office_level - 1, 0, by_office.size() - 1)])
	if _best_media_skill(state, team) >= 0.0:
		limit += data.bali("mix.media_planner_bonus")
	return limit


## Ekipteki en iyi medya planlamacının satın alma yeteneği ((strateji + iletişim) / 2); yoksa −1.
func _best_media_skill(state: SimState, team: Array) -> float:
	var best: float = -1.0
	for id: Variant in team:
		var emp: Dictionary = state.staff.get(str(id), {})
		if not emp.is_empty() and Employee.has_effect(data, emp, "media_buying"):
			best = maxf(best, (float(emp["stats"]["strategy"]) + float(emp["stats"]["communication"])) / 2.0)
	return best


## 10.4: tedarikçi_verimi = 1 + medya_satın_alma_yeteneği/400 + hacim_indirimi(yıllık medya).
func efficiency(state: SimState, team: Array) -> float:
	var m: Dictionary = data.bal("media_buying")
	var skill: float = maxf(0.0, _best_media_skill(state, team))
	var unit: float = float(m["volume_unit_1990"]) * Economy.inflation(data, state.clock.year())
	var volume: float = minf(float(m["volume_max"]), state.year_media / unit * float(m["volume_rate"]))
	return 1.0 + skill / float(m["skill_div"]) + volume


## Karışımı hazırlar: eksik seçenekleri "Otomatik" doldurur (baskı işi, kategori seçenekleri, influencer) ve doğrular.
## Dönüş: "" veya hata anahtarı.
func prepare_mix(setup: Dictionary, state: SimState) -> String:
	if (setup["mix"] as Array).size() > channel_limit(state, setup.get("team", [])):
		return "ERR_TOO_MANY_CHANNELS"
	var year: int = state.clock.year()
	for entry: Dictionary in setup["mix"]:
		var ch: String = str(entry.get("channel", ""))
		var opts: Dictionary = entry.get("options", {})
		var budget: float = float(setup["media_budget"]) * float(entry.get("share", 0.0))
		var err: String = ""
		if PrintSystem.is_print_channel(data, ch):
			if not opts.has("job"):
				opts["job"] = prints.auto_job(ch, budget, setup["sector"], state, int(setup["deadline_weeks"]))
			err = prints.validate(ch, opts["job"])
		elif InfluencerSystem.is_influencer_channel(data, ch):
			if not opts.has("influencer"):
				opts["influencer"] = influencers.auto_pick(state, ch, budget, setup)
			var inf: Dictionary = influencers.find(state, str(opts["influencer"]))
			if inf.is_empty():
				err = "ERR_NO_INFLUENCER"
			elif influencers.fee(state, inf) > budget:
				err = "ERR_INFLUENCER_FEE"
		else:
			var defaults: Dictionary = options.defaults(ch)
			for key: String in defaults:
				if not opts.has(key):
					opts[key] = defaults[key]
			err = options.validate(ch, opts, year)
		entry["options"] = opts
		if not err.is_empty():
			return err
	return ""


## Teslimde: basılı işler basılır; prodüksiyon payı (TV çekimi, etkinlik) marj bırakır; riskler zarlanır; influencer
## anlaşması yapılır (skandal olabilir); medya kısmı tedarikçiye borç yazılır.
## Dönüş: { payable, production_margin, late_weeks, print_results, fines, option_satisfaction, notes, scandal_candidates }
func settle_delivery(setup: Dictionary, state: SimState) -> Dictionary:
	var media_budget: float = float(setup["media_budget"])
	var media_part: float = 0.0
	var margin: float = 0.0
	var payable: float = 0.0
	var max_weeks: int = 0
	var fines: float = 0.0
	var satisfaction: float = 0.0
	var results: Array[Dictionary] = []
	var notes: Array[Dictionary] = []
	var scandal_candidates: Array[Dictionary] = []
	for entry: Dictionary in setup["mix"]:
		var ch: String = entry["channel"]
		var billed: float = media_budget * float(entry["share"])
		var opts: Dictionary = entry.get("options", {})
		if opts.has("job"):
			var r: Dictionary = prints.run(opts["job"], state)
			r["channel"] = ch
			r["billed"] = billed
			results.append(r)
			payable += float(r["cost"])
			margin += billed - float(r["cost"])
			max_weeks = maxi(max_weeks, int(r["weeks"]))
			continue
		var prod: Dictionary = options.production(ch)
		var prod_billed: float = billed * float(prod.get("share", 0.0))
		margin += prod_billed * float(prod.get("margin", 0.0))
		payable += prod_billed * (1.0 - float(prod.get("margin", 0.0)))
		media_part += billed - prod_billed
		if opts.has("influencer"):
			var inf: Dictionary = influencers.find(state, str(opts["influencer"]))
			if not inf.is_empty():
				opts["_influencer_kpi"] = influencers.kpi_inputs(state, inf, billed, setup)
				opts["_influencer_name"] = inf["name"]
				influencers.record_collab(state, inf["id"])
				scandal_candidates.append(inf)
		var outcomes: Array[Dictionary] = options.roll_risks(ch, opts, setup, billed, state)
		opts["_outcomes"] = outcomes
		for o: Dictionary in outcomes:
			fines += float(o["fine"])
			satisfaction += float(o["satisfaction"])
			if not str(o["note"]).is_empty():
				notes.append({"key": o["note"], "args": [setup.get("client_name", "")], "kind": "bad"})
	payable += media_part
	state.year_media += media_part
	var window: int = PrintSystem.print_window_weeks(int(setup["deadline_weeks"]))
	return {"payable": payable, "production_margin": margin, "late_weeks": maxi(0, max_weeks - window),
		"print_results": results, "fines": fines, "option_satisfaction": satisfaction, "notes": notes,
		"scandal_candidates": scandal_candidates}


## Yayın sonunda: gerilla basına çıktı mı (puan bilinir), skandal etkisi. KPI hesabından önce çağrılır.
func before_kpi(camp: Dictionary, score: float, state: SimState) -> void:
	var setup: Dictionary = camp["setup"]
	for entry: Dictionary in setup["mix"]:
		var opts: Dictionary = entry.get("options", {})
		if options.guerrilla_press(entry["channel"], score, setup.get("team", []), state):
			opts["_press"] = options.press_mult(entry["channel"])
		if opts.has("influencer") and camp.has("scandal"):
			opts["_scandal_mult"] = float(camp["scandal"]["impressions_mult"])
		entry["options"] = opts
