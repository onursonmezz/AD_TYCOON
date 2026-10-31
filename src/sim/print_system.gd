class_name PrintSystem
extends RefCounted
## Basılı işler (GDD 9.1) ve matbaa fiyat modeli (GDD 10.2).
## Baskı işi (job) bir kanal karışımı girdisinin "options.job" alanında durur:
## { "product", "quality", "quantity", "distribution", "proof", "supplier", "negotiated_discount" }

var data: GameData
var suppliers: SupplierSystem


func _init(game_data: GameData, supplier_system: SupplierSystem) -> void:
	data = game_data
	suppliers = supplier_system


func _p(key: String) -> Variant:
	return data.bal("print_job." + key)


static func is_print_channel(game_data: GameData, channel_id: String) -> bool:
	return game_data.channels.get(channel_id, {}).has("print_products")


## GDD 10.2: birim_fiyat = taban × enflasyon × kalite × matbaa × (adet/1000)^(−0.18) × (1 − indirim).
## Dijital baskı makinesinde ölçek ekonomisi neredeyse yoktur (küçük adet ucuz, büyük adet pahalı).
func unit_price(job: Dictionary, year: int, discount: float) -> float:
	var product: Dictionary = data.print_products[job["product"]]
	var sup: Dictionary = data.suppliers[job["supplier"]]
	var exponent: float = float(_p("digital_scale_exponent")) if bool(sup["digital"]) else data.balf("print.scale_exponent")
	return float(product["base_unit_price"]) * Economy.inflation(data, year) \
		* float(data.bal("print.quality_mult")[job["quality"]]) * float(sup["price_mult"]) \
		* pow(float(job["quantity"]) / 1000.0, exponent) * (1.0 - discount)


## Toplam maliyet = sabit kurulum + birim × adet + dağıtım + (prova). İndirim: pazarlık + ilişki + anlaşmalar.
func cost(job: Dictionary, state: SimState) -> Dictionary:
	var year: int = state.clock.year()
	var infl: float = Economy.inflation(data, year)
	var product: Dictionary = data.print_products[job["product"]]
	var sup: Dictionary = data.suppliers[job["supplier"]]
	var qty: float = float(job["quantity"])
	var discount: float = clampf(float(job.get("negotiated_discount", 0.0))
		+ suppliers.discount(state, job["supplier"], int(qty)), 0.0, 0.9)
	var printing: float = float(product["setup_cost"]) * infl * float(sup["price_mult"]) * (1.0 - discount) \
		+ unit_price(job, year, discount) * qty
	var dist: float = float(data.distributions[job["distribution"]]["cost_per_piece"]) * infl * qty
	var proof: float = float(_p("proof_cost_1990")) * infl if bool(job["proof"]) else 0.0
	return {"printing": printing, "distribution": dist, "proof": proof, "total": printing + dist + proof, "discount": discount}


func delivery_weeks(job: Dictionary, state: SimState) -> int:
	var sup: Dictionary = data.suppliers[job["supplier"]]
	var weeks: int = ceili(float(job["quantity"]) / float(sup["capacity_weekly"])) + int(sup["queue_weeks"])
	if suppliers.relationship(state, job["supplier"]) >= data.balf("suppliers.priority_relationship"):
		weeks = maxi(0, weeks - 1)
	if bool(job["proof"]):
		weeks += int(_p("proof_weeks"))
	return weeks


## Görülme = adet × parça başı görülme × (1 − çöpe giden oran) (GDD 9.1 "verim").
func impressions(job: Dictionary) -> float:
	var product: Dictionary = data.print_products[job["product"]]
	var waste: float = float(data.distributions[job["distribution"]]["waste"])
	return float(job["quantity"]) * float(product["views_per_piece"]) * (1.0 - waste)


## Kâğıt/baskı kalitesi algıyı ve Lüks sektör uyumunu etkiler (GDD 9.1).
func quality_effect(job: Dictionary, sector: String) -> float:
	var luxury: bool = str(data.sectors[sector]["tone_group"]) == str(_p("luxury_tone_group"))
	var table: Dictionary = _p("luxury_quality_effect") if luxury else _p("quality_effect")
	return float(table[job["quality"]])


func validate(channel_id: String, job: Dictionary) -> String:
	var products: Array = data.channels[channel_id].get("print_products", [])
	if not products.has(job.get("product", "")):
		return "ERR_PRINT_PRODUCT"
	var product: Dictionary = data.print_products[job["product"]]
	if not (product["distributions"] as Array).has(job.get("distribution", "")):
		return "ERR_PRINT_DISTRIBUTION"
	if not (data.bal("print.quality_mult") as Dictionary).has(job.get("quality", "")) or not data.suppliers.has(job.get("supplier", "")):
		return "ERR_PRINT_OPTIONS"
	var qty: int = int(job.get("quantity", 0))
	if qty < int(product["min_quantity"]) or qty > int(product["max_quantity"]):
		return "ERR_PRINT_QUANTITY"
	return ""


## Üretimin son fazı (baskı burada yapılır) kaç hafta sürer; daha uzun baskı teslimi gecikmedir.
static func print_window_weeks(deadline_weeks: int) -> int:
	return ceili(float(deadline_weeks) / 3.0)


## "Otomatik" seçenekler (GDD 9): ilk ürün, standart kalite (lüks sektörde premium), varsayılan matbaa, prova açık,
## adet = bütçenin hedef marjı bırakacak kadarı, ama baskı zamanında yetişecek kadarla sınırlı.
func auto_job(channel_id: String, budget: float, sector: String, state: SimState, deadline_weeks: int = 0) -> Dictionary:
	var product_id: String = str(data.channels[channel_id]["print_products"][0])
	var product: Dictionary = data.print_products[product_id]
	var luxury: bool = str(data.sectors[sector]["tone_group"]) == str(_p("luxury_tone_group"))
	var job: Dictionary = {"product": product_id, "quality": "premium" if luxury else str(_p("default_quality")),
		"distribution": str(product["distributions"][0]), "proof": true, "supplier": str(_p("default_supplier")),
		"negotiated_discount": 0.0, "quantity": int(product["min_quantity"])}
	job["quantity"] = max_quantity(job, budget * (1.0 - float(_p("target_margin"))), state)
	if deadline_weeks > 0:
		var window: int = print_window_weeks(deadline_weeks)
		var sup: Dictionary = data.suppliers[job["supplier"]]
		var weeks_for_print: int = window - int(sup["queue_weeks"]) - int(_p("proof_weeks"))
		if weeks_for_print < 1:
			job["proof"] = false
			weeks_for_print = window - int(sup["queue_weeks"])
		var by_time: int = maxi(int(product["min_quantity"]), weeks_for_print * int(sup["capacity_weekly"]))
		job["quantity"] = mini(int(job["quantity"]), by_time)
	return job


## Bu bütçeye sığan en büyük adet (ikili arama; maliyet adetle artar).
func max_quantity(job: Dictionary, budget: float, state: SimState) -> int:
	var product: Dictionary = data.print_products[job["product"]]
	var lo: int = int(product["min_quantity"])
	var hi: int = int(product["max_quantity"])
	var probe: Dictionary = job.duplicate()
	while lo < hi:
		var mid: int = (lo + hi + 1) / 2
		probe["quantity"] = mid
		if float(cost(probe, state)["total"]) <= budget:
			lo = mid
		else:
			hi = mid - 1
	return lo


## Teslimde baskı: maliyet, baskı hatası (provayla %70 az) → yeniden baskı ve gecikme (GDD 9.1, 10.2).
func run(job: Dictionary, state: SimState) -> Dictionary:
	var c: Dictionary = cost(job, state)
	var sup: Dictionary = data.suppliers[job["supplier"]]
	var p_error: float = float(sup["error_rate"]) * (data.balf("print.proof_error_mult") if bool(job["proof"]) else 1.0)
	var error: bool = state.rng.chance("print", p_error)
	var total: float = float(c["total"])
	var weeks: int = delivery_weeks(job, state)
	if error:
		total += float(c["printing"])
		weeks += int(_p("reprint_delay_weeks"))
	suppliers.record_job(state, job["supplier"], int(job["quantity"]))
	return {"cost": total, "error": error, "weeks": weeks, "discount": c["discount"]}
