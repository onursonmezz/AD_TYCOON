class_name EventEffects
extends RefCounted
## Olay seçeneklerinin etkileri (GDD 16). Anahtar önekleri bağlamdaki hedefi seçer:
## client.*, clients.* (hepsi), employee.* / employee2.*, team.* (herkes), campaign.* (üretimdeki ya da yayındaki),
## rival.*, macro (piyasa koşulu), plants.*; öneksizler ajansın kendisi (cash, reputation…).
## Para 1990 ₺'si cinsindendir, enflasyonla ölçeklenir. Dönüş: { anahtar: uygulanan değer } (rapor satırları için).


static func apply(sim: Simulation, inst: Dictionary, effects: Dictionary) -> Dictionary:
	var state: SimState = sim.state
	var data: GameData = sim.data
	var ctx: Dictionary = inst["ctx"]
	var out: Dictionary = {}
	var lost: Array[String] = []
	for key: String in effects:
		var v: Variant = effects[key]
		var parts: PackedStringArray = key.split(".")
		match parts[0]:
			"cash":
				var amount: float = float(v) * Economy.inflation(data, state.clock.year())
				if amount < 0.0:
					sim.economy.pay(state, -amount)
				else:
					state.cash += amount
					state.book(amount, 0.0)
				out[key] = amount
			"reputation":
				state.reputation = clampf(state.reputation + float(v), data.balf("reputation.min"), data.balf("reputation.max"))
				out[key] = v
			"award_buzz":
				state.award_buzz += float(v)
				out[key] = v
			"prospect_brief":
				var p: Dictionary = sim.clients.create_prospect(state)
				state.inbox.append(sim.briefs.make_brief(state, p, p))
				out[key] = v
			"research_points":
				state.research["points"] = float(state.research["points"]) + float(v)
				out[key] = v
			"client":
				var c: Dictionary = state.clients.get(ctx.get("client_id", ""), {})
				if c.is_empty():
					continue
				if _client(sim, c, parts[1], v, lost):
					out[key] = v
			"clients":
				for c: Dictionary in state.clients.values():
					_client(sim, c, parts[1], v, lost)
				out[key] = v
			"employee", "employee2":
				var emp: Dictionary = state.staff.get(ctx.get(parts[0] + "_id", ""), {})
				if not emp.is_empty() and _employee(sim, emp, parts, v):
					out[key] = v
			"team":
				for emp: Dictionary in state.staff.values():
					_employee(sim, emp, parts, v)
				out[key] = v
			"campaign":
				var camp: Dictionary = EventSystem._campaign(state, ctx)
				if not camp.is_empty() and _campaign(sim, camp, parts[1], v):
					out[key] = v
			"rival":
				var r: Dictionary = state.rivals.get(ctx.get("rival_id", ""), {})
				if not r.is_empty():
					r["reputation"] = clampf(float(r["reputation"]) + float(v), 0.0, 100.0)
					out[key] = v
			"macro":
				var m: Dictionary = (v as Dictionary).duplicate(true)
				m["id"] = inst["id"]
				m["until_week"] = state.clock.week_index + int(m.get("months", 12)) * data.bali("time.weeks_per_month")
				(state.events["macro"] as Array).append(m)
				out[key] = int(m.get("months", 12))
			"plants":
				if parts[1] == "water":
					sim.build.water(state)
				elif parts[1] == "dry":
					state.build["watered_week"] = state.clock.week_index - data.bali("plants.dry_weeks")
				sim.build.refresh(state)
				out[key] = v
	if not lost.is_empty():
		sim.drop_clients(lost)
	return out


static func _client(sim: Simulation, c: Dictionary, field: String, v: Variant, lost: Array[String]) -> bool:
	match field:
		"satisfaction", "trust":
			c[field] = clampf(float(c[field]) + float(v), 0.0, 100.0)
		"budget":
			c["annual_budget"] = float(c["annual_budget"]) * (1.0 + float(v))
		"leave":
			if bool(v):
				sim.state.clients.erase(c["id"])
				lost.append(str(c["id"]))
		"brief":
			sim.state.inbox.append(sim.briefs.make_brief(sim.state, c, {}))
		_:
			return false
	return true


static func _employee(sim: Simulation, emp: Dictionary, parts: PackedStringArray, v: Variant) -> bool:
	var state: SimState = sim.state
	match parts[1]:
		"morale", "energy", "burnout":
			emp[parts[1]] = clampf(float(emp[parts[1]]) + float(v), 0.0, 100.0)
		"salary":
			emp["salary"] = roundf(float(emp["salary"]) * (1.0 + float(v)))
		"xp":
			emp["xp"] = float(emp["xp"]) + float(v)
		"stat":
			var cap: float = minf(float(emp["hidden"].get("potential", 100.0)), 100.0)
			emp["stats"][parts[2]] = clampf(float(emp["stats"][parts[2]]) + float(v), 0.0, maxf(cap, float(emp["stats"][parts[2]])))
		"leave_weeks":
			if bool(emp.get("is_founder", false)):
				return false
			emp["busy_until"] = maxi(int(emp["busy_until"]), state.clock.week_index) + int(v)
			emp["busy_reason"] = "leave"
		"quit":
			if not bool(v) or bool(emp.get("is_founder", false)):
				return false
			sim.staff_life.remove_employee(state, emp["id"])
		"award_points":
			emp["award_points"] = float(emp.get("award_points", 0.0)) + float(v)
		_:
			return false
	return true


## Üretimdeki kampanyada: days (gecikme), errors, quality (tüm puanlar ×(1+v)).
## Yayındaki kampanyada: kpi (görülme ×(1+v)), satisfaction (memnuniyet kalemi), fee_bonus (fee'nin payı kadar ödeme).
static func _campaign(sim: Simulation, camp: Dictionary, field: String, v: Variant) -> bool:
	var producing: bool = not sim.state.active_campaign.is_empty() and sim.state.active_campaign["id"] == camp["id"]
	match field:
		"days":
			if not producing:
				return false
			camp["days_total"] = maxi(int(camp["day"]) + 1, int(camp["days_total"]) + int(v))
		"errors":
			if not producing:
				return false
			camp["errors"] = maxi(0, int(camp["errors"]) + int(v))
		"quality":
			if not producing:
				return false
			for id: String in camp["points"]:
				camp["points"][id] = float(camp["points"][id]) * (1.0 + float(v))
		"kpi":
			camp["setup"]["event_kpi_mult"] = float(camp["setup"].get("event_kpi_mult", 1.0)) * (1.0 + float(v))
		"satisfaction":
			camp["event_satisfaction"] = float(camp.get("event_satisfaction", 0.0)) + float(v)
		"fee_bonus":
			var amount: float = float(camp["setup"]["fee"]) * float(v)
			sim.state.cash += amount
			sim.state.book(amount, 0.0)
		_:
			return false
	return true
