class_name MediaPlanning
extends RefCounted
## Kanal karışımı kuralları (GDD 7.1), medya satın alma verimi (GDD 10.4) ve teslimdeki baskı/medya maliyetleri.

var data: GameData
var prints: PrintSystem


func _init(game_data: GameData, print_system: PrintSystem) -> void:
	data = game_data
	prints = print_system


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


## Karışımı hazırlar: basılı kanallara eksikse "Otomatik" baskı işi koyar ve doğrular. Dönüş: "" veya hata anahtarı.
func prepare_mix(setup: Dictionary, state: SimState) -> String:
	if (setup["mix"] as Array).size() > channel_limit(state, setup.get("team", [])):
		return "ERR_TOO_MANY_CHANNELS"
	for entry: Dictionary in setup["mix"]:
		var ch: String = str(entry.get("channel", ""))
		if not PrintSystem.is_print_channel(data, ch):
			continue
		var options: Dictionary = entry.get("options", {})
		var budget: float = float(setup["media_budget"]) * float(entry.get("share", 0.0))
		if not options.has("job"):
			options["job"] = prints.auto_job(ch, budget, setup["sector"], state, int(setup["deadline_weeks"]))
		entry["options"] = options
		var err: String = prints.validate(ch, options["job"])
		if not err.is_empty():
			return err
	return ""


## Teslimde: basılı işler basılır (maliyet, hata, gecikme); medya kısmı tedarikçiye borç yazılır.
## Dönüş: { "payable", "production_margin", "late_weeks", "print_results": [...] }
func settle_delivery(setup: Dictionary, state: SimState) -> Dictionary:
	var media_budget: float = float(setup["media_budget"])
	var media_part: float = 0.0
	var margin: float = 0.0
	var print_cost: float = 0.0
	var max_weeks: int = 0
	var results: Array[Dictionary] = []
	for entry: Dictionary in setup["mix"]:
		var billed: float = media_budget * float(entry["share"])
		var job: Dictionary = entry.get("options", {}).get("job", {})
		if job.is_empty():
			media_part += billed
			continue
		var r: Dictionary = prints.run(job, state)
		r["channel"] = entry["channel"]
		r["billed"] = billed
		results.append(r)
		print_cost += float(r["cost"])
		margin += billed - float(r["cost"])
		max_weeks = maxi(max_weeks, int(r["weeks"]))
	state.year_media += media_part
	var phase3_weeks: int = PrintSystem.print_window_weeks(int(setup["deadline_weeks"]))
	return {"payable": media_part + print_cost, "production_margin": margin,
		"late_weeks": maxi(0, max_weeks - phase3_weeks), "print_results": results}
