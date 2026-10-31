class_name StaffSystem
extends RefCounted
## Çalışanlar (GDD 11): kurucu, aday üretimi, işe alım, eğitim, uzmanlaşma, kovma, maaş, haftalık moral/enerji/
## tükenmişlik, XP/seviye, rakip transfer teklifleri.

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


func _r(key: String) -> float:
	return data.balf("staff_rules." + key)


# --- oluşturma ---------------------------------------------------------------

func create_founder(state: SimState, background_id: String) -> Dictionary:
	var bg: Dictionary = data.backgrounds.get(background_id, data.backgrounds[data.bal("founder.default_background")])
	var emp: Dictionary = _blank(state, "founder", 1)
	emp["name"] = ""
	emp["is_founder"] = true
	emp["background"] = bg["id"]
	emp["stats"] = (bg["stats"] as Dictionary).duplicate()
	emp["hidden"] = {"potential": _r("stat_max"), "loyalty": _r("stat_max"), "ego": 50, "stress_tolerance": 60}
	emp["hidden_revealed"] = true
	emp["traits"] = []
	state.staff[emp["id"]] = emp
	return emp


func _blank(state: SimState, role: String, level: int) -> Dictionary:
	return {"id": state.next_id("em"), "role": role, "level": level, "xp": 0.0, "stats": {}, "hidden": {},
		"hidden_revealed": false, "energy": _r("start_energy"), "morale": _r("start_morale"), "burnout": 0.0,
		"salary": 0.0, "traits": [], "specialization": "", "hired_week": state.clock.week_index,
		"busy_until": -1, "busy_reason": "", "is_founder": false, "gender": "", "name": ""}


## İşe alım kanalından aday listesi üretir (GDD 11.3). Ücret ödenir. Dönüş: adaylar ([] = yetersiz nakit/geçersiz).
func search(state: SimState, economy: Economy, role: String, channel_id: String, lang: String) -> Array[Dictionary]:
	var ch: Dictionary = data.hiring_channels.get(channel_id, {})
	var pos: Dictionary = data.positions.get(role, {})
	var year: int = state.clock.year()
	if ch.is_empty() or pos.is_empty() or not bool(pos.get("hireable", false)) \
			or int(ch["available_from"]) > year or int(pos["available_from"]) > year:
		return []
	var cost: float = float(ch["cost_1990"]) * Economy.inflation(data, year)
	economy.pay(state, cost)
	var out: Array[Dictionary] = []
	for i: int in int(ch["candidates"]):
		out.append(_candidate(state, role, ch, lang))
	state.candidates = out
	return out


func _candidate(state: SimState, role: String, ch: Dictionary, lang: String) -> Dictionary:
	var rng: RandomNumberGenerator = state.rng.stream("staff")
	var levels: Array = ch["level_range"]
	var emp: Dictionary = _blank(state, role, rng.randi_range(int(levels[0]), int(levels[1])))
	var pos: Dictionary = data.positions[role]
	var mean: float = float(ch["primary_stat_mean"]) + (int(emp["level"]) - 1) * _r("stat_points_per_level")
	var spread: float = float(ch["stat_spread"])
	for stat: Variant in data.bal("staff_rules.stats"):
		var m: float = mean if (pos["primary_stats"] as Array).has(stat) else mean + _r("secondary_stat_offset")
		if stat == "speed":
			m = _r("speed_mean")
		emp["stats"][stat] = roundf(clampf(m + rng.randf_range(-spread, spread), _r("stat_min"), _r("stat_max")))
	var pot: Array = ch["potential_range"]
	emp["hidden"] = {"potential": float(rng.randi_range(int(pot[0]), int(pot[1]))),
		"loyalty": float(rng.randi_range(int(_r("hidden_min")), int(_r("hidden_max")))),
		"ego": float(rng.randi_range(int(_r("hidden_min")), int(_r("hidden_max")))),
		"stress_tolerance": float(rng.randi_range(int(_r("hidden_min")), int(_r("hidden_max"))))}
	var trait_count: int = 1 + state.rng.pick_weighted_index("staff", data.bal("staff_rules.trait_count_weights"))
	var pool: Array[String] = data.trait_ids.duplicate()
	for i: int in trait_count:
		var t: String = pool[rng.randi_range(0, pool.size() - 1)]
		pool.erase(t)
		(emp["traits"] as Array).append(t)
	_assign_name(state, emp, lang)
	emp["salary"] = roundf(Employee.market_value(data, emp, state.clock.year()) * float(ch["salary_factor"]))
	return emp


func _assign_name(state: SimState, emp: Dictionary, lang: String) -> void:
	var names: Dictionary = data.names(lang)
	var gender: String = state.rng.pick("staff", ["female", "male", "neutral"])
	emp["gender"] = gender
	emp["name"] = "%s %s" % [state.rng.pick("staff", names[gender]), state.rng.pick("staff", names["surnames"])]


# --- kapasite ve işe alım ----------------------------------------------------

func headcount(state: SimState) -> int:
	return state.staff.size()


func capacity(state: SimState) -> int:
	return int(data.office(state.office_level)["capacity"])


## Her Creative Director en fazla 6 kreatif yönetir; CD yoksa da ilk 6 kreatife izin verilir (GDD 11.1).
func creative_limit(state: SimState) -> int:
	var cds: int = 0
	for emp: Dictionary in state.staff.values():
		if Employee.is_creative_director(data, emp):
			cds += 1
	return int(_r("creatives_per_cd")) * maxi(1, cds)


func creative_count(state: SimState) -> int:
	var n: int = 0
	for emp: Dictionary in state.staff.values():
		if Employee.is_creative(data, emp):
			n += 1
	return n


## Dönüş: "" veya hata anahtarı.
func hire(state: SimState, candidate_id: String) -> String:
	var cand: Dictionary = {}
	for c: Dictionary in state.candidates:
		if c["id"] == candidate_id:
			cand = c
	if cand.is_empty():
		return "ERR_NO_CANDIDATE"
	if headcount(state) >= capacity(state):
		return "ERR_OFFICE_FULL"
	if Employee.is_creative(data, cand) and creative_count(state) >= creative_limit(state):
		return "ERR_NEED_CD"
	cand["hired_week"] = state.clock.week_index
	state.staff[cand["id"]] = cand
	state.candidates.erase(cand)
	return ""


## Kovma: kıdem yılı başına bir aylık maaş tazminat (en az bir ay), diğerlerinin moraline kısa etki (GDD 11.3).
func fire(state: SimState, economy: Economy, emp_id: String) -> String:
	var emp: Dictionary = state.staff.get(emp_id, {})
	if emp.is_empty() or bool(emp["is_founder"]):
		return "ERR_CANNOT_FIRE"
	if _on_active_team(state, emp_id):
		return "ERR_ON_CAMPAIGN"
	economy.pay(state, severance(state, emp))
	state.staff.erase(emp_id)
	for other: Dictionary in state.staff.values():
		other["morale"] = clampf(float(other["morale"]) + _r("fire_team_morale"), 0.0, 100.0)
	return ""


func severance(state: SimState, emp: Dictionary) -> float:
	var years: float = float(state.clock.week_index - int(emp["hired_week"])) / state.clock.weeks_per_year()
	return float(emp["salary"]) * maxf(1.0, floorf(years)) * _r("severance_months_per_year")


func _on_active_team(state: SimState, emp_id: String) -> bool:
	if state.active_campaign.is_empty():
		return false
	return (state.active_campaign["setup"].get("team", []) as Array).has(emp_id)


## Stat eğitimi: para + zaman + enerji; kazanç potansiyelle sınırlı (GDD 11.3).
func train(state: SimState, economy: Economy, emp_id: String, stat: String) -> String:
	var emp: Dictionary = state.staff.get(emp_id, {})
	if emp.is_empty() or not (emp["stats"] as Dictionary).has(stat):
		return "ERR_NO_EMPLOYEE"
	if not Employee.is_available(emp, state.clock.week_index) or _on_active_team(state, emp_id):
		return "ERR_BUSY_EMPLOYEE"
	economy.pay(state, training_cost(state))
	var gain: float = state.rng.range_f("staff", _r("training_gain_min"), _r("training_gain_max"))
	emp["stats"][stat] = minf(float(emp["hidden"]["potential"]), float(emp["stats"][stat]) + gain)
	emp["energy"] = maxf(0.0, float(emp["energy"]) - _r("training_energy"))
	emp["busy_until"] = state.clock.week_index + int(_r("training_weeks"))
	emp["busy_reason"] = "training"
	return ""


func training_cost(state: SimState) -> float:
	return _r("training_cost_1990") * Economy.inflation(data, state.clock.year())


## Uzmanlaşma eğitimi: belli seviyeden sonra bir sektörde +%15 (GDD 11.2).
func specialize(state: SimState, economy: Economy, emp_id: String, sector: String) -> String:
	var emp: Dictionary = state.staff.get(emp_id, {})
	if emp.is_empty() or not data.sectors.has(sector):
		return "ERR_NO_EMPLOYEE"
	if int(emp["level"]) < int(_r("specialization_min_level")):
		return "ERR_LEVEL_TOO_LOW"
	if not Employee.is_available(emp, state.clock.week_index) or _on_active_team(state, emp_id):
		return "ERR_BUSY_EMPLOYEE"
	economy.pay(state, _r("specialization_cost_1990") * Economy.inflation(data, state.clock.year()))
	emp["specialization"] = sector
	emp["busy_until"] = state.clock.week_index + int(_r("specialization_weeks"))
	emp["busy_reason"] = "training"
	return ""


func raise_to_market(state: SimState, emp_id: String, over_market: float = 0.0) -> String:
	var emp: Dictionary = state.staff.get(emp_id, {})
	if emp.is_empty() or bool(emp["is_founder"]):
		return "ERR_NO_EMPLOYEE"
	emp["salary"] = roundf(Employee.market_value(data, emp, state.clock.year()) * (1.0 + over_market))
	return ""


func monthly_payroll(state: SimState) -> float:
	var total: float = 0.0
	for emp: Dictionary in state.staff.values():
		total += float(emp["salary"])
	return total * (1.0 + data.balf("economy.payroll_tax"))
