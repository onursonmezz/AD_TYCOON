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


## Ekibin geçerliliği: en az bir kişi, herkes var ve müsait (eğitimde/izinde değil).
func validate_team(team: Array, state: SimState) -> String:
	if team.is_empty():
		return "ERR_TEAM_EMPTY"
	for id: Variant in team:
		var emp: Dictionary = state.staff.get(str(id), {})
		if emp.is_empty() or not Employee.is_available(emp, state.clock.week_index):
			return "ERR_BUSY_EMPLOYEE"
	return ""


## Bir günlük üretim (GDD 7.5): ekipteki her müsait çalışan, fazın üç odak alanına slider payıyla puan üretir;
## her çalışan için günde bir hata zarı atılır (K-021).
func produce_day(campaign: Dictionary, state: SimState) -> void:
	var phase: int = current_phase(campaign)
	var ids: Array[String] = data.focus_ids_of_phase(phase)
	var setup: Dictionary = campaign["setup"]
	var sliders: Array = setup["sliders"][phase]
	var ref: float = data.balf("production.stat_reference")
	var year: int = state.clock.year()
	var overtime_out: float = data.balf("staff.overtime_output") if state.overtime else 1.0
	var rush: bool = int(setup["deadline_weeks"]) < data.bali("production.rush_below_weeks")
	var points: Dictionary = campaign["points"]
	# Oda etkisi (12.2): ör. beyin fırtınası odası konsepte +%10.
	var focus_mult: Dictionary = state.office_effects.get("focus_mult", {})
	for id: Variant in setup.get("team", []):
		var emp: Dictionary = state.staff.get(str(id), {})
		if emp.is_empty() or not Employee.is_available(emp, state.clock.week_index):
			continue
		var base: float = data.balf("production.base_per_day") * Employee.person_mult(data, emp, state.room_quality) \
			* Employee.campaign_mult(data, emp, setup, year) * overtime_out
		for i: int in ids.size():
			var share: float = scoring.effective_share(float(sliders[i]))
			points[ids[i]] = float(points[ids[i]]) + base * Employee.area_stat(data, emp, ids[i]) / ref \
				* Employee.specialty_mult(data, emp, ids[i]) * share * float(focus_mult.get(ids[i], 1.0))
		var p_error: float = data.balf("staff.base_error_rate") * (1.0 - float(emp["stats"]["attention"]) / 100.0) \
			* Employee.trait_effect(data, emp, "error_mult")
		if rush:
			p_error *= data.balf("production.rush_error_mult")
		if state.overtime:
			p_error *= data.balf("production.overtime_error_mult")
		if state.rng.chance("production", p_error):
			campaign["errors"] = int(campaign["errors"]) + 1
	campaign["day"] = int(campaign["day"]) + 1
