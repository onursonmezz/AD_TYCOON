class_name EventSystem
extends RefCounted
## Rastgele olaylar ve krizler (GDD 16, K-067). Olaylar veri odaklıdır: data/events/*.json.
## Tetikler:
## - "weekly": her hafta sonu genel kapıdan (events.gate.weekly) geçilirse uygun olaylardan biri;
## - "production": üretimdeki kampanya üzerine (ekip, müşteri);
## - "airing": yayındaki bir kampanya üzerine;
## - "fixed": ay başında, koşulu tutan sabit tarihli olaylar (dönem krizleri) kapısız gelir.
## "chance" aynı tetikteki olaylar arasında ağırlıktır. Aynı anda tek olay kararı bekler; kuyruğa girer.
## Metinler anahtardan türetilir: EV_<ID>_T (başlık), EV_<ID>_X (metin), EV_<ID>_O<n> (seçenek n, 1'den).

const OPS: Array[String] = [">=", "<=", "!=", "==", ">", "<"]

var data: GameData
var events: Dictionary = {}
var event_ids: Array[String] = []
## Simulation bağlar (oda ve bitki koşulları için).
var build: BuildSystem


func _init(game_data: GameData) -> void:
	data = game_data
	for file_name: String in data.raw:
		if file_name.begins_with("events/"):
			for rec: Dictionary in data.raw[file_name]:
				events[rec["id"]] = rec
				event_ids.append(str(rec["id"]))


static func empty_events() -> Dictionary:
	return {"queue": [], "last": {}, "last_week": -999, "macro": [], "log": []}


func _cfg() -> Dictionary:
	return data.bal("events")


static func pending(state: SimState) -> Dictionary:
	var q: Array = state.events["queue"]
	return q[0] if not q.is_empty() else {}


static func text_key(id: String, part: String) -> String:
	return "EV_%s_%s" % [id.to_upper(), part]


# --- tetikleme ---------------------------------------------------------------------

## Hafta sonu: süresi biten piyasa koşullarını siler, sonra sırayla üretim, yayın ve genel olay dener.
## Dönüş: kuyruğa yeni giren olaylar.
func weekly(state: SimState) -> Array[Dictionary]:
	var week: int = state.clock.week_index
	var kept: Array = []
	for m: Dictionary in state.events["macro"]:
		if int(m["until_week"]) > week:
			kept.append(m)
	state.events["macro"] = kept
	var out: Array[Dictionary] = []
	if not (state.events["queue"] as Array).is_empty() or week - int(state.events["last_week"]) < int(_cfg()["min_gap_weeks"]):
		return out
	var triggers: Array[String] = []
	if not state.active_campaign.is_empty():
		triggers.append("production")
	if not state.airing.is_empty():
		triggers.append("airing")
	triggers.append("weekly")
	for trigger: String in triggers:
		if not state.rng.chance("events", float(_cfg()["gate"][trigger])):
			continue
		var inst: Dictionary = _pick(state, trigger)
		if not inst.is_empty():
			out.append(inst)
			break
	return out


## Ay başı: sabit tarihli olaylar (koşulu tutan hepsi, kapısız).
func monthly(state: SimState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in event_ids:
		if events[id]["trigger"] != "fixed":
			continue
		var ctx: Dictionary = _context(state, "fixed")
		if _eligible(state, events[id], ctx):
			out.append(_enqueue(state, events[id], ctx))
	return out


func _pick(state: SimState, trigger: String) -> Dictionary:
	var ctx: Dictionary = _context(state, trigger)
	var pool: Array[Dictionary] = []
	var weights: Array = []
	for id: String in event_ids:
		var ev: Dictionary = events[id]
		if ev["trigger"] == trigger and _eligible(state, ev, ctx):
			pool.append(ev)
			weights.append(float(ev.get("chance", 1.0)))
	if pool.is_empty():
		return {}
	return _enqueue(state, pool[state.rng.pick_weighted_index("events", weights)], ctx)


## Bağlam: olayın kime/neye dokunduğu. Kurucu "çalışan" bağlamına girmez (istifa edemez).
func _context(state: SimState, trigger: String) -> Dictionary:
	var ctx: Dictionary = {}
	var camp: Dictionary = {}
	if trigger == "production":
		camp = state.active_campaign
	elif trigger == "airing":
		camp = state.rng.pick("events", state.airing)
	var pool: Array = []
	if not camp.is_empty():
		ctx["campaign_id"] = camp["id"]
		if state.clients.has(camp["setup"]["client_id"]):
			ctx["client_id"] = camp["setup"]["client_id"]
		for id: Variant in camp["setup"].get("team", []):
			pool.append(str(id))
	elif not state.clients.is_empty():
		ctx["client_id"] = state.rng.pick("events", state.clients.keys())
	if pool.is_empty():
		pool = state.staff.keys()
	var staff: Array = []
	for id: Variant in pool:
		if state.staff.has(id) and not bool(state.staff[id].get("is_founder", false)):
			staff.append(str(id))
	if not staff.is_empty():
		ctx["employee_id"] = state.rng.pick("events", staff)
		var others: Array = []
		for id: Variant in state.staff.keys():
			if id != ctx["employee_id"] and not bool(state.staff[id].get("is_founder", false)):
				others.append(str(id))
		if not others.is_empty():
			ctx["employee2_id"] = state.rng.pick("events", others)
	var alive: Array = []
	for id: Variant in state.rivals:
		if bool(state.rivals[id].get("alive", true)):
			alive.append(str(id))
	if not alive.is_empty():
		ctx["rival_id"] = state.rng.pick("events", alive)
	return ctx


func _enqueue(state: SimState, ev: Dictionary, ctx: Dictionary) -> Dictionary:
	var args: Dictionary = {}
	if ctx.has("client_id"):
		args["client"] = state.clients[ctx["client_id"]]["name"]
	var camp: Dictionary = _campaign(state, ctx)
	if not camp.is_empty():
		args["campaign"] = str(camp["setup"].get("name", ""))
		if not args.has("client"):
			args["client"] = str(camp["setup"].get("client_name", ""))
	if ctx.has("rival_id"):
		args["rival"] = data.rivals[ctx["rival_id"]]["name_key"]
	var inst: Dictionary = {"uid": state.next_id("ev"), "id": ev["id"], "category": ev.get("category", ""),
		"week": state.clock.week_index, "ctx": ctx, "args": args, "options": available_options(state, ev)}
	(state.events["queue"] as Array).append(inst)
	state.events["last"][ev["id"]] = state.clock.week_index
	state.events["last_week"] = state.clock.week_index
	return inst


## Oyuncuya gösterilen seçenekler (ör. Kriz İletişimi araştırması ek seçenek açar).
func available_options(state: SimState, ev: Dictionary) -> Array:
	var out: Array = []
	var opts: Array = ev["options"]
	for i: int in opts.size():
		var req: String = str(opts[i].get("requires_research", ""))
		if req.is_empty() or (state.research["done"] as Array).has(req):
			out.append(i)
	return out


# --- koşullar -----------------------------------------------------------------------

func _eligible(state: SimState, ev: Dictionary, ctx: Dictionary) -> bool:
	var last: Variant = state.events["last"].get(ev["id"])
	if last != null:
		if bool(ev.get("once", false)):
			return false
		if state.clock.week_index - int(last) < int(ev.get("cooldown_weeks", _cfg()["cooldown_weeks"])):
			return false
	for key: String in _needed_targets(ev):
		if not ctx.has(key):
			return false
	var conditions: Dictionary = ev.get("conditions", {})
	for key: String in conditions:
		if not condition_ok(state, key, conditions[key], ctx):
			return false
	return true


## Koşul ya da etki anahtarlarının öneki olayın neye ihtiyaç duyduğunu söyler (client., employee., campaign.…).
func _needed_targets(ev: Dictionary) -> Array[String]:
	var keys: Array = (ev.get("conditions", {}) as Dictionary).keys()
	for opt: Dictionary in ev["options"]:
		for part: String in ["effects", "success", "fail"]:
			keys.append_array((opt.get(part, {}) as Dictionary).keys())
	var out: Array[String] = []
	for k: Variant in keys:
		var prefix: String = str(k).get_slice(".", 0)
		var target: String = {"client": "client_id", "employee": "employee_id", "employee2": "employee2_id",
			"campaign": "campaign_id", "rival": "rival_id"}.get(prefix, "")
		if not target.is_empty() and not out.has(target):
			out.append(target)
	return out


func condition_ok(state: SimState, key: String, spec: Variant, ctx: Dictionary) -> bool:
	match key:
		"research":
			return (state.research["done"] as Array).has(spec)
		"no_research":
			return not (state.research["done"] as Array).has(spec)
		"years":
			return (spec as Array).has(float(state.clock.year())) or (spec as Array).has(state.clock.year())
		"room":
			return build.layout(state).has_closed_room(str(spec))
		"position":
			for emp: Dictionary in state.staff.values():
				if emp["role"] == spec:
					return true
			return false
		"campaign.category":
			var camp: Dictionary = _campaign(state, ctx)
			for entry: Dictionary in camp["setup"]["mix"]:
				if data.channels[entry["channel"]]["category"] == spec:
					return true
			return false
		"employee.trait":
			return Employee.has_trait(state.staff[ctx["employee_id"]], str(spec))
	var value: Variant = _value(state, key, ctx)
	if value == null:
		return false
	return compare(value, spec)


static func compare(value: Variant, spec: Variant) -> bool:
	if spec is bool:
		return bool(value) == spec
	if spec is float or spec is int:
		return is_equal_approx(float(value), float(spec))
	var s: String = str(spec)
	for op: String in OPS:
		if s.begins_with(op):
			var rhs: String = s.substr(op.length()).strip_edges()
			if not rhs.is_valid_float():
				return (str(value) == rhs) == (op == "==")
			var a: float = float(value)
			var b: float = float(rhs)
			match op:
				">=": return a >= b
				"<=": return a <= b
				"!=": return not is_equal_approx(a, b)
				"==": return is_equal_approx(a, b)
				">": return a > b
				"<": return a < b
	return str(value) == s


func _value(state: SimState, key: String, ctx: Dictionary) -> Variant:
	var parts: PackedStringArray = key.split(".")
	match parts[0]:
		"year": return state.clock.year()
		"month": return state.clock.month()
		"reputation": return state.reputation
		"staff": return state.staff.size()
		"clients": return state.clients.size()
		"office_level": return state.office_level
		"era": return data.era_of(state.clock.year())
		"cash_1990": return state.cash / Economy.inflation(data, state.clock.year())
		"plants": return build.plant_count(state)
		"client":
			var c: Dictionary = state.clients.get(ctx.get("client_id", ""), {})
			if c.is_empty():
				return null
			return c["personality"].get(parts[1], c.get(parts[1]))
		"employee", "employee2":
			var emp: Dictionary = state.staff.get(ctx.get(parts[0] + "_id", ""), {})
			if emp.is_empty():
				return null
			if parts[1] == "stat":
				return emp["stats"].get(parts[2])
			if parts[1] == "salary_ratio":
				return float(emp["salary"]) / maxf(1.0, Employee.market_value(data, emp, state.clock.year()))
			return emp.get(parts[1])
		"campaign":
			var camp: Dictionary = _campaign(state, ctx)
			if camp.is_empty():
				return null
			match parts[1]:
				"phase": return CampaignProduction.phase_of(camp)
				"size": return camp["setup"]["size"]
				"score": return camp.get("report", {}).get("score")
				"errors": return camp.get("errors")
				"channels": return (camp["setup"]["mix"] as Array).size()
	return null


## Bağlamdaki kampanya: üretimdeki ya da yayındaki.
static func _campaign(state: SimState, ctx: Dictionary) -> Dictionary:
	var id: String = str(ctx.get("campaign_id", ""))
	if id.is_empty():
		return {}
	if not state.active_campaign.is_empty() and state.active_campaign["id"] == id:
		return state.active_campaign
	for camp: Dictionary in state.airing:
		if camp["id"] == id:
			return camp
	return {}


# --- karar ------------------------------------------------------------------------

## Stat kontrolünün başarı olasılığı (GDD 16): zar(0..100) + en iyi stat / 2 (+ kriz iletişimi) ≥ zorluk.
func check_chance(state: SimState, inst: Dictionary, check: Dictionary) -> float:
	var need: float = float(check["dc"]) - check_stat(state, inst, check) / 2.0 - _crisis_bonus(state, inst)
	return clampf((100.0 - need) / 100.0, 0.0, 1.0)


func check_stat(state: SimState, inst: Dictionary, check: Dictionary) -> float:
	var stat: String = check["stat"]
	if str(check.get("who", "best")) == "employee":
		var emp: Dictionary = state.staff.get(inst["ctx"].get("employee_id", ""), {})
		return float(emp["stats"][stat]) if not emp.is_empty() else 0.0
	var best: float = 0.0
	for emp: Dictionary in state.staff.values():
		if Employee.is_available(emp, state.clock.week_index):
			best = maxf(best, float(emp["stats"][stat]))
	return best


func _crisis_bonus(state: SimState, inst: Dictionary) -> float:
	if inst["category"] != "crisis" or not (state.research["done"] as Array).has("crisis_comms"):
		return 0.0
	return 100.0 * data.balf("research.crisis_statement_bonus")


## Oyuncunun seçimi. Dönüş: { ok, option, checked, success, effects: { anahtar: uygulanan değer } }.
func resolve(sim: Simulation, uid: String, option: int) -> Dictionary:
	var state: SimState = sim.state
	var queue: Array = state.events["queue"]
	var inst: Dictionary = {}
	for e: Dictionary in queue:
		if e["uid"] == uid:
			inst = e
	if inst.is_empty() or not (inst["options"] as Array).has(option):
		return {"ok": false}
	queue.erase(inst)
	var opt: Dictionary = events[inst["id"]]["options"][option]
	var effects: Dictionary = opt.get("effects", {})
	var result: Dictionary = {"ok": true, "option": option, "checked": opt.has("check"), "success": true}
	if opt.has("check"):
		result["success"] = state.rng.range_f("events", 0.0, 100.0) + check_stat(state, inst, opt["check"]) / 2.0 \
			+ _crisis_bonus(state, inst) >= float(opt["check"]["dc"])
		effects = opt.get("success" if result["success"] else "fail", {})
	result["effects"] = EventEffects.apply(sim, inst, effects)
	var log: Array = state.events["log"]
	log.append({"id": inst["id"], "week": inst["week"], "option": option, "success": result["success"],
		"args": inst["args"]})
	while log.size() > int(_cfg()["log_kept"]):
		log.pop_front()
	return result


## Bot/test (duraklamasız) modu: bir hafta cevapsız kalan olay ilk seçenekle (ya da "default") kapanır.
func auto_resolve(sim: Simulation) -> void:
	var inst: Dictionary = pending(sim.state)
	if inst.is_empty() or sim.state.clock.week_index - int(inst["week"]) < int(_cfg()["auto_resolve_weeks"]):
		return
	var ev: Dictionary = events[inst["id"]]
	var choice: int = int(ev.get("default", 0))
	if not (inst["options"] as Array).has(choice):
		choice = int(inst["options"][0])
	resolve(sim, inst["uid"], choice)


# --- piyasa koşulları (makro olaylar) ---------------------------------------------

## Yeni brief'lerin bütçe çarpanı (kriz yılları, GDD 13: "bütçeler düşer").
static func budget_mult(state: SimState) -> float:
	var m: float = 1.0
	for macro: Dictionary in state.events["macro"]:
		m *= float(macro.get("budget_mult", 1.0))
	return m


## KPI'ya giden kategori çarpanları (ör. Büyük Kapanma'da açık hava ve etkinlik çöker).
static func prepare_kpi(state: SimState, setup: Dictionary) -> void:
	var imp: Dictionary = {}
	var cost: Dictionary = {}
	for macro: Dictionary in state.events["macro"]:
		for cat: String in macro.get("impressions", {}):
			imp[cat] = float(imp.get(cat, 1.0)) * float(macro["impressions"][cat])
		for cat: String in macro.get("cost", {}):
			cost[cat] = float(cost.get(cat, 1.0)) * float(macro["cost"][cat])
	setup["macro_impressions"] = imp
	setup["macro_cost"] = cost
