class_name StaffLife
extends RefCounted
## Çalışanların zamanla değişen durumu (GDD 11.2, 11.4): enerji, moral, tükenmişlik, izin/istifa, XP/seviye,
## gizli statların ortaya çıkması, rakip transfer teklifleri ve departman etkileri (account bonusu, hata yakalama).

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


func _r(key: String) -> float:
	return data.balf("staff_rules." + key)


func _team(state: SimState) -> Array:
	if state.active_campaign.is_empty():
		return []
	return state.active_campaign["setup"].get("team", [])


## Günlük enerji: ekiptekiler çalışır (fazla mesaide ×2), diğerleri dinlenir.
func daily(state: SimState) -> void:
	var team: Array = _team(state)
	var drain: float = _r("energy_work_per_day") * (data.balf("staff.overtime_energy_mult") if state.overtime else 1.0)
	for emp: Dictionary in state.staff.values():
		var delta: float = -drain if team.has(emp["id"]) \
			else _r("energy_rest_per_day") * float(state.office_effects.get("energy_rest_mult", 1.0))
		emp["energy"] = clampf(float(emp["energy"]) + delta, 0.0, 100.0)


## Haftalık: hafta sonu dinlenmesi, moral (GDD 11.4), tükenmişlik, hastalık izni/istifa, gizli statlar, teklif süreleri.
## Dönüş: bildirimler [{ "key", "args", "kind" }].
func weekly(state: SimState) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	var team: Array = _team(state)
	var comfort: float = float(data.office(state.office_level)["comfort"])
	var has_hr: bool = false
	for emp: Dictionary in state.staff.values():
		if Employee.has_effect(data, emp, "reveal_hidden"):
			has_hr = true
	var leaving: Array[String] = []
	for emp: Dictionary in state.staff.values():
		var on_team: bool = team.has(emp["id"])
		emp["energy"] = clampf(float(emp["energy"]) + _r("energy_weekend"), 0.0, 100.0)
		var target: float = _r("morale_baseline") + comfort * _r("comfort_weight") + _team_harmony(state, emp)
		var m: float = float(emp["morale"])
		m += (target - m) * _r("morale_drift")
		var market: float = Employee.market_value(data, emp, state.clock.year())
		if market > 0.0:
			m += (float(emp["salary"]) / market - 1.0) * _r("salary_gap_weight")
		if state.overtime and on_team:
			m += _r("overtime_morale")
		emp["morale"] = clampf(m, 0.0, 100.0)
		var b: float = float(emp["burnout"])
		if state.overtime and on_team:
			b += data.balf("staff.burnout_per_overtime_week") * Employee.trait_effect(data, emp, "overtime_burnout_mult")
		else:
			b -= _r("burnout_recovery_per_week") * float(state.office_effects.get("burnout_recovery_mult", 1.0))
		emp["burnout"] = clampf(b, 0.0, 100.0)
		if not bool(emp["hidden_revealed"]) and (has_hr or state.clock.week_index - int(emp["hired_week"]) >= int(_r("reveal_hidden_weeks"))):
			emp["hidden_revealed"] = true
		if float(emp["burnout"]) >= _r("burnout_limit") and Employee.is_available(emp, state.clock.week_index):
			if state.rng.chance("staff", _r("sick_leave_chance")):
				emp["busy_until"] = state.clock.week_index + int(_r("sick_leave_weeks"))
				emp["busy_reason"] = "sick"
				emp["burnout"] = maxf(0.0, float(emp["burnout"]) - _r("sick_leave_burnout_drop"))
				notes.append({"key": "NOTE_SICK_LEAVE", "args": [_display_name(emp)], "kind": "bad"})
			elif not bool(emp["is_founder"]) and state.rng.chance("staff",
					(100.0 - float(emp["hidden"]["loyalty"])) / 100.0 * _r("resign_chance_mult")):
				leaving.append(emp["id"])
				notes.append({"key": "NOTE_RESIGNED", "args": [_display_name(emp)], "kind": "bad"})
	var still: Array[Dictionary] = []
	for offer: Dictionary in state.offers:
		if int(offer["expires_week"]) <= state.clock.week_index:
			leaving.append(offer["employee_id"])
			notes.append({"key": "NOTE_POACHED", "args": [_display_name(state.staff.get(offer["employee_id"], {}))], "kind": "bad"})
		else:
			still.append(offer)
	state.offers = still
	for id: String in leaving:
		remove_employee(state, id)
	return notes


## Ego özelliği taşıyan diğer çalışanlar ekip moralini düşürür (GDD 11.2 "ekip morali −5").
func _team_harmony(state: SimState, emp: Dictionary) -> float:
	var v: float = 0.0
	for other: Dictionary in state.staff.values():
		if other["id"] != emp["id"]:
			v += Employee.trait_effect(data, other, "team_morale", true)
	return v


func _display_name(emp: Dictionary) -> String:
	return str(emp.get("name", ""))


func remove_employee(state: SimState, emp_id: String) -> void:
	state.staff.erase(emp_id)
	if not state.active_campaign.is_empty():
		(state.active_campaign["setup"]["team"] as Array).erase(emp_id)
	var kept: Array[Dictionary] = []
	for o: Dictionary in state.offers:
		if o["employee_id"] != emp_id:
			kept.append(o)
	state.offers = kept


## Aylık: piyasa değerinin altında maaş alanlara rakip teklif gelebilir (GDD 11.2). Dönüş: yeni teklifler.
func monthly_offers(state: SimState) -> Array[Dictionary]:
	var created: Array[Dictionary] = []
	for emp: Dictionary in state.staff.values():
		if bool(emp["is_founder"]) or _has_offer(state, emp["id"]):
			continue
		var market: float = Employee.market_value(data, emp, state.clock.year())
		if float(emp["salary"]) < market * _r("offer_check_ratio") and state.rng.chance("staff", _r("offer_monthly_chance")):
			var offer: Dictionary = {"id": state.next_id("of"), "employee_id": emp["id"],
				"offer_salary": roundf(market * (1.0 + _r("offer_premium"))),
				"expires_week": state.clock.week_index + int(_r("offer_expiry_weeks"))}
			state.offers.append(offer)
			created.append(offer)
	return created


func _has_offer(state: SimState, emp_id: String) -> bool:
	for o: Dictionary in state.offers:
		if o["employee_id"] == emp_id:
			return true
	return false


## Oyuncu kararı: "match" (piyasa +%10 zam) ya da "release" (bırak gitsin).
func resolve_offer(state: SimState, offer_id: String, choice: String) -> String:
	for o: Dictionary in state.offers:
		if o["id"] != offer_id:
			continue
		state.offers.erase(o)
		if choice == "match":
			var emp: Dictionary = state.staff.get(o["employee_id"], {})
			if not emp.is_empty():
				emp["salary"] = roundf(Employee.market_value(data, emp, state.clock.year()) * (1.0 + _r("offer_raise_over_market")))
		else:
			remove_employee(state, o["employee_id"])
		return ""
	return "ERR_NO_OFFER"


# --- kampanya etkileri -------------------------------------------------------

## GDD 6.4 account_ekibi_bonusu (0..+6): ekipteki en iyi account'un iletişimi + "müşteri dostu" özelliği.
func account_bonus(state: SimState, team: Array) -> float:
	var best: float = 0.0
	for id: Variant in team:
		var emp: Dictionary = state.staff.get(str(id), {})
		if emp.is_empty() or not Employee.has_effect(data, emp, "account_bonus"):
			continue
		var b: float = _r("account_bonus_max") * float(emp["stats"]["communication"]) / 100.0 \
			+ Employee.trait_effect(data, emp, "account_satisfaction", true)
		best = maxf(best, b)
	return best


## Trafik / Prova okuyucu: teslim öncesi hataları temizler (GDD 11.1). Dönüş: temizlenen hata sayısı.
func catch_errors(state: SimState, errors: int) -> int:
	var caught: int = 0
	for emp: Dictionary in state.staff.values():
		if not Employee.has_effect(data, emp, "error_catch") or not Employee.is_available(emp, state.clock.week_index):
			continue
		var p: float = float(emp["stats"]["attention"]) / 100.0 * _r("error_catch_per_attention")
		for i: int in errors - caught:
			if state.rng.chance("staff", p):
				caught += 1
	return caught


## Kampanya bitince: ekip XP ve moral kazanır; seviye atlayınca statlar artar (GDD 11.2).
## Dönüş: seviye atlayanların adları.
func campaign_finished(state: SimState, team: Array, report: Dictionary) -> Array[String]:
	var leveled: Array[String] = []
	var score: float = float(report["score"])
	var has_mentor: bool = false
	for id: Variant in team:
		var emp: Dictionary = state.staff.get(str(id), {})
		if not emp.is_empty() and Employee.trait_effect(data, emp, "junior_xp_mult") > 1.0:
			has_mentor = true
	for id: Variant in team:
		var emp: Dictionary = state.staff.get(str(id), {})
		if emp.is_empty():
			continue
		emp["morale"] = clampf(float(emp["morale"]) + (score - _r("campaign_morale_pivot")) * _r("campaign_morale_per_point"), 0.0, 100.0)
		var xp: float = score * _r("xp_per_score_point")
		if has_mentor and int(emp["level"]) <= int(_r("junior_max_level")):
			xp *= _mentor_mult(state, team)
		emp["xp"] = float(emp["xp"]) + xp
		var leveled_up: bool = false
		while float(emp["xp"]) >= _r("xp_per_level"):
			emp["xp"] = float(emp["xp"]) - _r("xp_per_level")
			emp["level"] = int(emp["level"]) + 1
			_level_up(emp, report)
			leveled_up = true
		if leveled_up:
			leveled.append(str(emp["name"]))
	return leveled


func _mentor_mult(state: SimState, team: Array) -> float:
	var m: float = 1.0
	for id: Variant in team:
		m = maxf(m, Employee.trait_effect(data, state.staff.get(str(id), {"traits": []}), "junior_xp_mult"))
	return m


## Stat puanları ana statlara (kurucuda kampanyanın S/K/T payına) dağıtılır; potansiyelle sınırlı.
func _level_up(emp: Dictionary, report: Dictionary) -> void:
	var cap: float = minf(_r("stat_max"), float(emp["hidden"]["potential"]))
	var points: float = _r("stat_points_per_level")
	var shares: Dictionary = {}
	var prim: Array = Employee.position(data, emp)["primary_stats"]
	if prim.is_empty():
		var total: float = maxf(1.0, float(report["s"]) + float(report["k"]) + float(report["t"]))
		shares = {"strategy": float(report["s"]) / total, "creative": float(report["k"]) / total,
			"technical": float(report["t"]) / total}
	else:
		for s: Variant in prim:
			shares[s] = 1.0 / prim.size()
	for stat: Variant in shares:
		emp["stats"][stat] = minf(cap, float(emp["stats"][stat]) + points * float(shares[stat]))
	emp["stats"]["speed"] = minf(cap, float(emp["stats"]["speed"]) + _r("speed_per_level"))
