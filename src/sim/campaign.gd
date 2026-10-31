class_name CampaignProduction
extends RefCounted
## Kampanya kurulumu doğrulama ve günlük puan üretimi (GDD 7.1, 7.4, 7.5).
## M1'de tek üretici oyuncu karakteridir; M3'te ekip ataması gelecek.

var data: GameData
var scoring: Scoring


func _init(game_data: GameData, scoring_ref: Scoring) -> void:
	data = game_data
	scoring = scoring_ref


## Oyuncu seçimlerini kontrol eder. Dönüş: boş = geçerli, aksi halde hata anahtarı.
func validate_setup(setup: Dictionary, year: int) -> String:
	if not data.objectives.has(setup.get("objective", "")):
		return "ERR_OBJECTIVE"
	if not data.audiences.has(setup.get("audience", "")):
		return "ERR_AUDIENCE"
	if not data.tones.has(setup.get("tone", "")):
		return "ERR_TONE"
	var mix: Array = setup.get("mix", [])
	if mix.is_empty():
		return "ERR_MIX_EMPTY"
	var total: float = 0.0
	var seen: Array[String] = []
	var infl: float = Economy.inflation(data, year)
	for entry: Dictionary in mix:
		var ch: String = str(entry.get("channel", ""))
		if not data.channels.has(ch) or int(data.channels[ch]["available_from"]) > year or seen.has(ch):
			return "ERR_CHANNEL"
		seen.append(ch)
		var share: float = float(entry.get("share", 0.0))
		if share <= 0.0:
			return "ERR_SHARE"
		if float(setup["media_budget"]) * share < float(data.channels[ch]["min_budget"]) * infl:
			return "ERR_MIN_BUDGET"
		total += share
	if not is_equal_approx(total, 1.0):
		return "ERR_SHARE"
	var sliders: Array = setup.get("sliders", [])
	if sliders.size() != 3:
		return "ERR_SLIDERS"
	for phase: Variant in sliders:
		if typeof(phase) != TYPE_ARRAY or (phase as Array).size() != 3:
			return "ERR_SLIDERS"
		var sum: float = 0.0
		for v: Variant in phase:
			if float(v) < 0.0:
				return "ERR_SLIDERS"
			sum += float(v)
		if not is_equal_approx(sum, 1.0):
			return "ERR_SLIDERS"
	return ""


func create(setup: Dictionary, campaign_id: String, week_index: int) -> Dictionary:
	var points: Dictionary = {}
	for id: String in data.focus_ids:
		points[id] = 0.0
	return {"id": campaign_id, "setup": setup, "points": points, "errors": 0, "day": 0,
		"days_total": int(setup["deadline_weeks"]) * data.bali("calendar.days_per_week"), "start_week": week_index}


func current_phase(campaign: Dictionary) -> int:
	return mini(2, int(campaign["day"]) * 3 / int(campaign["days_total"]))


func is_finished(campaign: Dictionary) -> bool:
	return int(campaign["day"]) >= int(campaign["days_total"])


## GDD 7.5'teki çalışan bazlı çarpanların alana bağlı olmayan kısmı.
func person_multiplier(person: Dictionary) -> float:
	var ref: float = data.balf("production.stat_reference")
	var speed: float = float(person["speed"]) / ref
	var quality: float = clampf(data.balf("office.home_room_quality") / 100.0, 0.0, 1.0)
	var office: float = data.balf("office.quality_base") + data.balf("office.quality_range") * quality
	var morale: float = data.balf("morale.mult_base") + data.balf("morale.mult_range") * float(person["morale"]) / 100.0
	var energy: float = data.balf("energy.low_mult") if float(person["energy"]) < data.balf("energy.low_threshold") else 1.0
	return speed * float(person["tool_mult"]) * office * morale * energy * float(person["specialty_mult"])


## Alanın stat değeri: birden çok stata bölünen alanlarda ağırlıklı ortalama.
func area_stat(person: Dictionary, area: String) -> float:
	var split: Dictionary = data.focus_areas[area]["stats"]
	var v: float = 0.0
	for stat: String in split:
		v += float(person[stat]) * float(split[stat])
	return v


## Bir günlük üretim: fazın üç odak alanına slider payıyla puan; günde bir hata zarı (K-021).
func produce_day(campaign: Dictionary, person: Dictionary, rng: SimRng) -> void:
	var phase: int = current_phase(campaign)
	var ids: Array[String] = data.focus_ids_of_phase(phase)
	var sliders: Array = campaign["setup"]["sliders"][phase]
	var base: float = data.balf("production.base_per_day") * person_multiplier(person)
	var ref: float = data.balf("production.stat_reference")
	var points: Dictionary = campaign["points"]
	for i: int in ids.size():
		var share: float = scoring.effective_share(float(sliders[i]))
		points[ids[i]] = float(points[ids[i]]) + base * area_stat(person, ids[i]) / ref * share
	var p_error: float = data.balf("staff.base_error_rate") * (1.0 - float(person["attention"]) / 100.0)
	if int(campaign["setup"]["deadline_weeks"]) < data.bali("production.rush_below_weeks"):
		p_error *= data.balf("production.rush_error_mult")
	if rng.chance("production", p_error):
		campaign["errors"] = int(campaign["errors"]) + 1
	campaign["day"] = int(campaign["day"]) + 1
