class_name SupplierSystem
extends RefCounted
## Tedarikçi ilişkileri, gelen teklifler ve çerçeve anlaşmalar (GDD 10.3), 3 turluk pazarlık mini oyunu.
## Durum SimState'te: supplier_rel { id: puan }, supplier_offers [], supplier_deals [], print_volume_year { id: adet },
## negotiation {} (açık pazarlık).

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


func relationship(state: SimState, supplier_id: String) -> float:
	return float(state.supplier_rel.get(supplier_id, data.balf("suppliers.start_relationship")))


func _set_relationship(state: SimState, supplier_id: String, value: float) -> void:
	state.supplier_rel[supplier_id] = clampf(value, 0.0, 100.0)


## İlişki indirimi (50 üstü puan → en fazla %5) + geçerli anlaşmaların en iyisi.
func discount(state: SimState, supplier_id: String, quantity: int) -> float:
	var start: float = data.balf("suppliers.start_relationship")
	var rel: float = clampf((relationship(state, supplier_id) - start) / (100.0 - start), 0.0, 1.0)
	var d: float = rel * data.balf("print_job.relationship_discount_max")
	var best: float = 0.0
	for deal: Dictionary in state.supplier_deals:
		if deal["supplier"] != supplier_id or int(deal["end_week"]) < state.clock.week_index:
			continue
		if deal["type"] == "volume" and quantity < int(deal["min_quantity"]):
			continue
		best = maxf(best, float(deal["discount"]))
	return d + best


## Zamanında ödenen düzenli iş ilişkiyi güçlendirir; yıllık hacim kaydedilir (taahhüt kontrolü için).
func record_job(state: SimState, supplier_id: String, quantity: int) -> void:
	_set_relationship(state, supplier_id, relationship(state, supplier_id) + data.balf("print_job.relationship_gain_per_job"))
	state.print_volume_year[supplier_id] = int(state.print_volume_year.get(supplier_id, 0)) + quantity


## Haftalık: rastgele teklif gelir (GDD 10.3), süresi dolan teklifler düşer. Dönüş: yeni teklif (yoksa {}).
func weekly(state: SimState) -> Dictionary:
	var still: Array[Dictionary] = []
	for o: Dictionary in state.supplier_offers:
		if int(o["expires_week"]) > state.clock.week_index:
			still.append(o)
	state.supplier_offers = still
	if not state.rng.chance("suppliers", data.balf("suppliers.offer_weekly_chance")):
		return {}
	var s: Dictionary = data.bal("suppliers")
	var sup: String = state.rng.pick("suppliers", data.supplier_ids)
	var weeks: int = int(s["offer_valid_weeks"])
	var offer: Dictionary = {"id": state.next_id("so"), "supplier": sup,
		"expires_week": state.clock.week_index + int(s["offer_response_weeks"])}
	if state.rng.chance("suppliers", float(s["volume_offer_chance"])):
		var md: Array = s["volume_min_qty"]
		var dr: Array = s["volume_discount"]
		offer.merge({"type": "volume", "discount": snappedf(state.rng.range_f("suppliers", float(dr[0]), float(dr[1])), 0.01),
			"min_quantity": int(snappedf(state.rng.range_f("suppliers", float(md[0]), float(md[1])), 1000.0)), "duration_weeks": weeks})
	else:
		var cq: Array = s["annual_commit_qty"]
		var dr: Array = s["annual_discount"]
		offer.merge({"type": "annual", "discount": snappedf(state.rng.range_f("suppliers", float(dr[0]), float(dr[1])), 0.01),
			"commit_quantity": int(snappedf(state.rng.range_f("suppliers", float(cq[0]), float(cq[1])), 1000.0)),
			"duration_weeks": state.clock.weeks_per_year() - state.clock.week_index % state.clock.weeks_per_year()})
	state.supplier_offers.append(offer)
	return offer


func accept_offer(state: SimState, offer_id: String) -> String:
	for o: Dictionary in state.supplier_offers:
		if o["id"] != offer_id:
			continue
		state.supplier_offers.erase(o)
		var deal: Dictionary = o.duplicate()
		deal["start_week"] = state.clock.week_index
		deal["end_week"] = state.clock.week_index + int(o["duration_weeks"])
		deal["volume_at_start"] = int(state.print_volume_year.get(o["supplier"], 0))
		state.supplier_deals.append(deal)
		return ""
	return "ERR_NO_OFFER"


func decline_offer(state: SimState, offer_id: String) -> String:
	for o: Dictionary in state.supplier_offers:
		if o["id"] == offer_id:
			state.supplier_offers.erase(o)
			return ""
	return "ERR_NO_OFFER"


## Yıl sonu: tutmayan yıllık taahhüdün cezası (eksik adet × ortalama birim fiyat × oran). Dönüş: toplam ceza.
func year_end(state: SimState) -> float:
	var penalty: float = 0.0
	var kept: Array[Dictionary] = []
	for deal: Dictionary in state.supplier_deals:
		if deal["type"] == "annual" and int(deal["end_week"]) <= state.clock.week_index:
			var done: int = int(state.print_volume_year.get(deal["supplier"], 0)) - int(deal["volume_at_start"])
			var shortfall: int = maxi(0, int(deal["commit_quantity"]) - done)
			penalty += shortfall * _avg_unit_price(state) * data.balf("suppliers.annual_penalty_rate")
		elif int(deal["end_week"]) > state.clock.week_index:
			kept.append(deal)
	state.supplier_deals = kept
	state.print_volume_year = {}
	return penalty


func _avg_unit_price(state: SimState) -> float:
	var sum: float = 0.0
	for p: Dictionary in data.print_products.values():
		sum += float(p["base_unit_price"])
	return sum / maxf(1.0, data.print_products.size()) * Economy.inflation(data, state.clock.year())


# --- pazarlık mini oyunu (GDD 10.3) ------------------------------------------

## Pazarlık açar: tedarikçinin gizli "minimum kabul fiyatı" var; iyi ilişki tabanı düşürür.
func start_negotiation(state: SimState, supplier_id: String, list_price: float) -> Dictionary:
	var n: Dictionary = data.bal("negotiation")
	var range_d: Array = n["min_discount"]
	var rel_bonus: float = (relationship(state, supplier_id) - data.balf("suppliers.start_relationship")) / 100.0 \
		* float(n["relationship_effect"])
	var d: float = clampf(state.rng.range_f("suppliers", float(range_d[0]), float(range_d[1])) + rel_bonus, 0.0, 0.5)
	state.negotiation = {"supplier": supplier_id, "list_price": list_price, "min_price": list_price * (1.0 - d),
		"round": 0, "status": "open", "price": list_price}
	return state.negotiation


## Satın alma uzmanı (iletişim) gizli tabanı bir aralık olarak gösterir; yoksa [].
func hint(state: SimState) -> Array:
	var best: float = -1.0
	for emp: Dictionary in state.staff.values():
		if Employee.has_effect(data, emp, "negotiation_hint"):
			best = maxf(best, float(emp["stats"]["communication"]))
	if best < 0.0 or state.negotiation.is_empty():
		return []
	var spread: float = float(state.negotiation["list_price"]) * data.balf("negotiation.hint_spread") * (1.0 - best / 100.0)
	return [float(state.negotiation["min_price"]) - spread, float(state.negotiation["min_price"]) + spread]


## Karşı teklif. Dönüş: güncel pazarlık durumu ("accepted" / "open" / "failed"; "broken" ilişki bozuldu).
func counter(state: SimState, price: float) -> Dictionary:
	var n: Dictionary = state.negotiation
	if n.is_empty() or n["status"] != "open":
		return n
	n["round"] = int(n["round"]) + 1
	if price >= float(n["min_price"]):
		n["status"] = "accepted"
		n["price"] = price
		return n
	n["last_broken"] = false
	if state.rng.chance("suppliers", data.balf("negotiation.break_chance")):
		_set_relationship(state, n["supplier"], relationship(state, n["supplier"]) + data.balf("negotiation.break_relationship"))
		n["last_broken"] = true
	if int(n["round"]) >= data.bali("negotiation.rounds"):
		n["status"] = "failed"
		n["price"] = float(n["list_price"])
	return n


## Pazarlığın sonucu: liste fiyatına göre indirim oranı (0 = indirim yok).
func negotiated_discount(state: SimState) -> float:
	var n: Dictionary = state.negotiation
	if n.is_empty() or n["status"] != "accepted":
		return 0.0
	return clampf(1.0 - float(n["price"]) / float(n["list_price"]), 0.0, 0.9)
