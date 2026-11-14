class_name EquipmentSystem
extends RefCounted
## Prodüksiyon ekipmanı ve kiralama (K-119, GDD 12.4'e ek): kamera, fotoğraf, ışık, ses, set, drone; kampanya başına
## kiralanan stüdyo, film ekibi, drone ekibi, helikopter çekimi. Veriler data/equipment.json, sayılar balance.json
## "equipment". Etki: prodüksiyon alanına çarpan; kampanyanın medya karışımında ekipmanın işine yarayan kanalların
## payı kadar. Her gruptan yalnızca en iyisi sayılır (yeni kuşak eskisini geçersiz kılar).

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


func _e(key: String) -> Variant:
	return data.bal("equipment." + key)


func available(state: SimState, kind: String) -> Array[String]:
	var year: int = state.clock.year()
	var out: Array[String] = []
	for id: String in data.equipment_ids:
		var e: Dictionary = data.equipment[id]
		if e["kind"] == kind and int(e["from"]) <= year and year <= int(e.get("until", 9999)):
			out.append(id)
	return out


func owns(state: SimState, id: String) -> bool:
	return state.equipment.has(id)


func price(state: SimState, id: String) -> float:
	return float(data.equipment[id]["cost_1990"]) * Economy.inflation(data, state.clock.year())


func monthly_cost(state: SimState) -> float:
	var total: float = 0.0
	for id: String in state.equipment:
		total += float(data.equipment[id].get("upkeep_1990", 0.0))
	return total * Economy.inflation(data, state.clock.year())


func buy(state: SimState, economy: Economy, id: String) -> String:
	if not available(state, "owned").has(id):
		return "ERR_EQUIPMENT_NA"
	if owns(state, id):
		return "ERR_EQUIPMENT_OWNED"
	if state.cash < price(state, id):
		return "ERR_NO_CASH"
	economy.pay(state, price(state, id))
	state.equipment.append(id)
	return ""


## Satış: alış fiyatının (bugünkü değeriyle) sell_refund oranı.
func sell(state: SimState, id: String) -> bool:
	if not owns(state, id):
		return false
	state.cash += price(state, id) * float(_e("sell_refund"))
	state.equipment.erase(id)
	return true


## Kiralıkların toplam bedeli (bu kampanya için).
func rental_cost(state: SimState, rentals: Array) -> float:
	var total: float = 0.0
	for id: Variant in rentals:
		total += price(state, str(id))
	return total


func validate_rentals(state: SimState, rentals: Array) -> String:
	var ok: Array[String] = available(state, "rental")
	for id: Variant in rentals:
		if not ok.has(str(id)):
			return "ERR_EQUIPMENT_NA"
	if state.cash < rental_cost(state, rentals):
		return "ERR_NO_CASH"
	return ""


## Medya karışımında bu ihtiyaca (video, photo, audio, visual) yarayan kanalların payı (0..1).
func relevance(mix: Array, needs: String) -> float:
	var channels: Array = (_e("needs") as Dictionary).get(needs, [])
	var share: float = 0.0
	for entry: Dictionary in mix:
		if channels.has(entry["channel"]):
			share += float(entry["share"])
	return minf(1.0, share)


## Grup başına en iyi (sahip olunan + bu kampanyanın kiralıkları) ekipman. Dönüş: { group: id }.
func best_by_group(state: SimState, setup: Dictionary) -> Dictionary:
	var pool: Array = state.equipment.duplicate()
	pool.append_array(setup.get("rentals", []))
	var best: Dictionary = {}
	for id: Variant in pool:
		var e: Dictionary = data.equipment.get(str(id), {})
		if e.is_empty():
			continue
		var g: String = e["group"]
		if not best.has(g) or float(e["bonus"]) > float(data.equipment[best[g]]["bonus"]):
			best[g] = str(id)
	return best


## Prodüksiyon alanı çarpanı: 1 + Σ grup en iyisinin bonusu × kanal uygunluğu (üst sınır max_bonus).
func production_mult(state: SimState, setup: Dictionary) -> float:
	var bonus: float = 0.0
	var best: Dictionary = best_by_group(state, setup)
	for g: String in best:
		var e: Dictionary = data.equipment[best[g]]
		bonus += float(e["bonus"]) * relevance(setup.get("mix", []), str(e["needs"]))
	return 1.0 + minf(bonus, float(_e("max_bonus")))
