class_name ResearchSystem
extends RefCounted
## Ar-Ge (GDD 17): araştırma puanı (AP) kampanyalardan ve Ar-Ge lab'dan gelir; araştırma AP + para + zaman ister.
## Tamamlanan araştırmalar kilit açar (ton, kitle, çoklu kanal, dijital departman…) ya da etki verir.
## Bilgi Defteri (M7-B): raporlarla keşfedilen uyum hücreleri; Pazar Araştırması parayla hücre açar.
## Araştırmalar data/research.json, sayılar balance.json "research".

const KNOWLEDGE_TABLES: Array[String] = ["sector_objective", "sector_audience", "tone", "channel_objective", "channel_audience"]

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


func _r(key: String) -> Variant:
	return data.bal("research." + key)


static func empty_research() -> Dictionary:
	return {"points": 0.0, "done": [], "active": {}}


## Hızlı başlangıç: başlangıç yılına kadar dünyanın bildiği (mutlak yıla bağlı) araştırmalar tamam sayılır (K-065).
func start(state: SimState) -> void:
	state.research = empty_research()
	if state.clock.start_year <= data.bali("time.base_year"):
		return
	for id: String in data.research_ids:
		var req: Dictionary = data.research[id]["requires"]
		if req.has("year") and int(req["year"]) <= state.clock.start_year:
			(state.research["done"] as Array).append(id)


## Eski kayıt (M7-B öncesi): o güne kadar koşulu tutan bütün araştırmalar tamam sayılır; eski oyun aynı devam eder.
func grant_reachable(state: SimState) -> void:
	state.research = empty_research()
	for id: String in data.research_ids:
		var req: Dictionary = data.research[id]["requires"]
		if state.clock.game_year() >= int(req.get("game_year", 0)) and state.clock.year() >= int(req.get("year", 0)):
			(state.research["done"] as Array).append(id)


func has(state: SimState, id: String) -> bool:
	return (state.research["done"] as Array).has(id)


func cost(state: SimState, id: String) -> float:
	return float(data.research[id]["cost_1990"]) * Economy.inflation(data, state.clock.year())


## Koşul listesi: [{key, need, have, ok}] (arayüz ✓/✗ gösterir).
func requirements(state: SimState, id: String) -> Array[Dictionary]:
	var req: Dictionary = data.research[id]["requires"]
	var out: Array[Dictionary] = []
	if req.has("game_year"):
		out.append({"key": "REQ_YEAR", "need": int(req["game_year"]), "have": state.clock.game_year(),
			"ok": state.clock.game_year() >= int(req["game_year"])})
	if req.has("year"):
		out.append({"key": "REQ_CAL_YEAR", "need": int(req["year"]), "have": state.clock.year(), "ok": state.clock.year() >= int(req["year"])})
	for r: Variant in req.get("research", []):
		out.append({"key": "REQ_RESEARCH", "need": data.research[str(r)]["name_key"], "have": "", "ok": has(state, str(r))})
	out.append({"key": "REQ_AP", "need": int(data.research[id]["ap"]), "have": int(float(state.research["points"])),
		"ok": float(state.research["points"]) >= float(data.research[id]["ap"])})
	return out


func can_start(state: SimState, id: String) -> bool:
	if not data.research.has(id) or has(state, id) or not (state.research["active"] as Dictionary).is_empty():
		return false
	for r: Dictionary in requirements(state, id):
		if not bool(r["ok"]):
			return false
	return true


## Dönüş: "" veya hata anahtarı. AP ve para hemen düşer; süre bitince tamamlanır.
func begin(state: SimState, economy: Economy, id: String) -> String:
	if not can_start(state, id):
		return "ERR_RESEARCH"
	if state.cash < cost(state, id):
		return "ERR_NO_CASH"
	economy.pay(state, cost(state, id))
	state.research["points"] = float(state.research["points"]) - float(data.research[id]["ap"])
	state.research["active"] = {"id": id, "weeks_left": int(data.research[id]["weeks"])}
	return ""


## Kampanya bitince AP: puan × büyüklük katsayısı (GDT'deki araştırma puanı).
func on_campaign(state: SimState, score: float, size: String) -> float:
	var ap: float = score * float(_r("ap_per_score")) * float(_r("size_mult")[size])
	state.research["points"] = float(state.research["points"]) + ap
	return ap


## Hafta sonu: Ar-Ge lab AP'si, yürüyen araştırmanın ilerlemesi. Dönüş: tamamlanan araştırma id'si ya da "".
func weekly(state: SimState) -> String:
	state.research["points"] = float(state.research["points"]) + float(state.office_effects.get("research_weekly", 0.0))
	var active: Dictionary = state.research["active"]
	if active.is_empty():
		return ""
	active["weeks_left"] = int(active["weeks_left"]) - 1
	if int(active["weeks_left"]) > 0:
		return ""
	var id: String = str(active["id"])
	(state.research["done"] as Array).append(id)
	state.research["active"] = {}
	return id


## AI Atölyesi (17): AI araçlarının özgünlük bedeli yarıya iner.
func ai_penalty_mult(state: SimState) -> float:
	return float(_r("ai_workshop_mult")) if has(state, "ai_workshop") else 1.0


## Bu kanal için gereken araştırma ("" = gerekmez): dijital ve sosyal kanallar Dijital Departman ister (17).
func channel_requirement(channel_id: String) -> String:
	return "digital_department" if (_r("digital_categories") as Array).has(data.channels[channel_id]["category"]) else ""


func channel_unlocked(state: SimState, channel_id: String) -> bool:
	var need: String = channel_requirement(channel_id)
	return need.is_empty() or has(state, need)


func position_unlocked(state: SimState, role: String) -> bool:
	return str(data.positions[role]["department"]) != "digital" or has(state, "digital_department")


# --- Bilgi Defteri ----------------------------------------------------------------

static func cell_key(row: String, column: String) -> String:
	return row + "|" + column


func is_known(state: SimState, table: String, row: String, column: String) -> bool:
	return (state.knowledge.get(table, {}) as Dictionary).has(cell_key(row, column))


func reveal(state: SimState, table: String, row: String, column: String) -> bool:
	if row.is_empty() or column.is_empty() or is_known(state, table, row, column):
		return false
	(state.knowledge.get_or_add(table, {}) as Dictionary)[cell_key(row, column)] = true
	return true


## Biten kampanyanın kullandığı hücreler deftere yazılır (GDD 20 "Bilgi Defteri", GDT'deki rapor keşfi).
func learn_from(state: SimState, setup: Dictionary) -> int:
	var n: int = 0
	var sector: String = setup["sector"]
	n += int(reveal(state, "sector_objective", sector, setup["objective"]))
	n += int(reveal(state, "sector_audience", sector, setup["audience"]))
	n += int(reveal(state, "tone", str(data.sectors[sector]["tone_group"]), setup["tone"]))
	for entry: Dictionary in setup["mix"]:
		n += int(reveal(state, "channel_objective", entry["channel"], setup["objective"]))
		n += int(reveal(state, "channel_audience", entry["channel"], setup["audience"]))
	return n


func market_research_cost(state: SimState) -> float:
	return float(_r("market_research_cost_1990")) * Economy.inflation(data, state.clock.year())


## Pazar Araştırması hizmeti (17): bir sektörün bilinmeyen hedef/kitle hücrelerinden birini parayla açar.
## Dönüş: { "error", "table", "column" }
func buy_insight(state: SimState, economy: Economy, sector: String) -> Dictionary:
	if not has(state, "market_research"):
		return {"error": "ERR_RESEARCH"}
	if state.cash < market_research_cost(state):
		return {"error": "ERR_NO_CASH"}
	var unknown: Array[Array] = []
	for obj: String in data.objective_ids:
		if not is_known(state, "sector_objective", sector, obj):
			unknown.append(["sector_objective", obj])
	for aud: String in data.audience_ids:
		if not is_known(state, "sector_audience", sector, aud):
			unknown.append(["sector_audience", aud])
	if unknown.is_empty():
		return {"error": "ERR_ALL_KNOWN"}
	economy.pay(state, market_research_cost(state))
	var pick: Array = unknown[state.rng.range_i("research", 0, unknown.size() - 1)]
	reveal(state, str(pick[0]), sector, str(pick[1]))
	return {"error": "", "table": pick[0], "column": pick[1]}
