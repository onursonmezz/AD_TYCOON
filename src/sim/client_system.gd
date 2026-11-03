class_name ClientSystem
extends RefCounted
## Markalar (müşteriler): üretim, beklenti, memnuniyet (GDD 6.1, 6.4), yıllık bütçe değişimi, müşteri kaybı.

const PERSONALITY_KEYS: Array[String] = ["risk", "detail", "pay", "ego", "loyalty"]

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


func create_client(state: SimState, sector: String, scale: int, brand_name: String = "") -> Dictionary:
	var personality: Dictionary = {}
	var lo: int = data.bali("clients.personality_min")
	var hi: int = data.bali("clients.personality_max")
	for key: String in PERSONALITY_KEYS:
		personality[key] = state.rng.range_i("clients", lo, hi)
	if brand_name.is_empty():
		brand_name = _brand_name(state, sector)
	var budget: float = float(data.bal("clients.annual_budget_1990")[scale]) \
		* Economy.inflation(data, state.clock.year()) * state.rng.range_f("clients", 0.8, 1.2)
	return {"id": state.next_id("cl"), "name": brand_name, "sector": sector, "scale": scale,
		"annual_budget": budget, "personality": personality,
		"satisfaction": data.balf("clients.start_satisfaction"), "trust": data.balf("clients.start_trust"),
		"contract": "project", "history": []}


## Başlangıç müşterileri: el yapımı "starter" markalardan (GDD 6.1 örnekleri).
## extra: oyuncu geçmişinin getirdiği ek müşteri (GDD 11.5 "müşteri ağı"); el yapımı liste bitince rastgele mahalle markası.
func create_starting(state: SimState, extra: int = 0) -> void:
	var count: int = data.bali("clients.start_count")
	for i: int in extra:
		var sector: String = state.rng.pick("clients", data.sectors_available(state.clock.year()))
		var c: Dictionary = create_client(state, sector, 0)
		state.clients[c["id"]] = c
	for rec: Dictionary in data.handcrafted_brands:
		if count <= 0:
			break
		if bool(rec.get("starter", false)):
			var client: Dictionary = create_client(state, rec["sector"], int(rec["scale"]), rec["name"])
			state.clients[client["id"]] = client
			count -= 1


## Ajans dışından gelen potansiyel müşteri (henüz portföyde değil). Büyük ofis büyük markaları çeker (K-049).
func create_prospect(state: SimState) -> Dictionary:
	var weights: Array = data.bal("clients.scale_weights_by_office")[state.office_level - 1]
	var scale: int = state.rng.pick_weighted_index("clients", weights)
	var sector: String = state.rng.pick("clients", data.sectors_available(state.clock.year()))
	return create_client(state, sector, scale)


func _brand_name(state: SimState, sector: String) -> String:
	var prefix: String = state.rng.pick("clients", name_parts_list("prefixes"))
	var suffix: String = state.rng.pick("clients", data.name_parts["suffixes"][sector])
	return prefix + " " + suffix


func name_parts_list(key: String) -> Array:
	return data.name_parts.get(key, [])


func expectation(client: Dictionary, year: int) -> float:
	var hist: Array = client["history"]
	var avg: float = data.balf("satisfaction.history_default")
	if not hist.is_empty():
		var sum: float = 0.0
		for h: Dictionary in hist:
			sum += float(h["score"])
		avg = sum / hist.size()
	return data.balf("satisfaction.expectation_base") + float(client["scale"]) * data.balf("satisfaction.expectation_per_scale") \
		+ avg * data.balf("satisfaction.expectation_history") \
		+ (year - data.bali("time.base_year")) * data.balf("satisfaction.expectation_per_year")


## GDD 6.4 Δmemnuniyet. Revizyon, gecikme ve bütçe aşımı henüz 0 (K-023); account_bonus ekipten gelir (0..+6).
func satisfaction_delta(client: Dictionary, score: float, kpi_ratio: float, tone: String, year: int,
		account_bonus: float = 0.0, late_weeks: int = 0, over_budget: bool = false, revisions: int = 0) -> float:
	var total: float = 0.0
	for v: Variant in satisfaction_parts(client, score, kpi_ratio, tone, year, account_bonus, late_weeks, over_budget,
			revisions).values():
		total += float(v)
	return total


## 6.4 formülünün kalemleri ayrı ayrı (raporda "memnuniyet neden değişti" dökümü için). Sıfır olanlar da döner.
func satisfaction_parts(client: Dictionary, score: float, kpi_ratio: float, tone: String, year: int,
		account_bonus: float = 0.0, late_weeks: int = 0, over_budget: bool = false, revisions: int = 0) -> Dictionary:
	var sat: Dictionary = data.bal("satisfaction")
	var parts: Dictionary = {}
	parts["quality"] = float(sat["quality_coef"]) * (score - expectation(client, year)) / float(sat["quality_div"])
	parts["kpi"] = float(sat["kpi_coef"]) * clampf(kpi_ratio - 1.0, -1.0, 1.0)
	parts["timing"] = float(sat["on_time"]) if late_weeks <= 0 else float(sat["late_per_week"]) * late_weeks
	parts["budget"] = float(sat["over_budget"]) if over_budget else 0.0
	parts["revisions"] = -revisions * float(client["personality"]["detail"]) / 100.0 * float(sat["revision_coef"])
	parts["account"] = account_bonus
	var bold: bool = float(client["personality"]["risk"]) >= data.balf("clients.bold_risk_min") and tone == "bold"
	parts["bold_match"] = float(sat["bold_match_bonus"]) if bold else 0.0
	return parts


func apply_result(client: Dictionary, campaign_id: String, score: float, objective: String, year: int, delta: float) -> void:
	client["satisfaction"] = clampf(float(client["satisfaction"]) + delta, 0.0, 100.0)
	(client["history"] as Array).append({"campaign": campaign_id, "score": score, "objective": objective, "year": year})


## Yıl sonu: memnun müşterinin bütçesi artar (GDD 6.4).
func yearly(state: SimState) -> void:
	for client: Dictionary in state.clients.values():
		if float(client["satisfaction"]) >= data.balf("clients.budget_growth_min_satisfaction"):
			client["annual_budget"] = float(client["annual_budget"]) * (1.0 + state.rng.range_f("clients",
				data.balf("clients.budget_growth_min"), data.balf("clients.budget_growth_max")))


## Memnuniyeti eşiğin altına düşen müşteriler ajansı bırakır (M5'te önce ihaleye çıkacak). Dönüş: ayrılanların id'leri.
## removed_names: verilirse ayrılan markaların adları buna eklenir (bildirim için).
func remove_unhappy(state: SimState, removed_names: Array[String] = []) -> Array[String]:
	var gone: Array[String] = []
	for id: String in state.clients.keys():
		if float(state.clients[id]["satisfaction"]) < data.balf("clients.leave_threshold"):
			gone.append(id)
	for id: String in gone:
		removed_names.append(str(state.clients[id]["name"]))
		state.clients.erase(id)
	return gone
