class_name BuildSystem
extends RefCounted
## İnşa modu (GDD 12.2–12.3): mobilya yerleştirme/satma, masa kalitesi, büyütülmüş ofisten itibaren oda çizme,
## oda kalitesi (ofis çarpanı) ve oda etkileri. Düzen SimState.build'de saf veri; OfficeLayout ile doğrulanır.
## Mobilyalar data/furniture.json, oda tipleri data/room_types.json, sayılar balance.json "build".

var data: GameData
var _cache: OfficeLayout
var _cache_key: String = ""


func _init(game_data: GameData) -> void:
	data = game_data


func _b(key: String) -> Variant:
	return data.bal("build." + key)


static func empty_build() -> Dictionary:
	return {"rooms": [], "furniture": [], "desk_tier": "basic", "version": 0}


func layout(state: SimState) -> OfficeLayout:
	var key: String = "%d:%d" % [state.office_level, int(state.build.get("version", 0))]
	if key != _cache_key:
		_cache = OfficeLayout.build(data.office_layouts["office_%d" % state.office_level], state.build, data.furniture)
		_cache_key = key
	return _cache


func _changed(state: SimState) -> void:
	state.build["version"] = int(state.build.get("version", 0)) + 1
	refresh(state)


# --- mobilya --------------------------------------------------------------------

func available_furniture(state: SimState) -> Array[String]:
	var out: Array[String] = []
	var year: int = state.clock.year()
	for id: String in data.furniture_ids:
		var f: Dictionary = data.furniture[id]
		if int(f["available_from"]) <= year and year <= int(f["available_until"]):
			out.append(id)
	return out


func furniture_cost(state: SimState, id: String) -> float:
	return float(data.furniture[id]["cost_1990"]) * Economy.inflation(data, state.clock.year())


func count_of(state: SimState, id: String) -> int:
	var n: int = 0
	for f: Dictionary in state.build["furniture"]:
		if f["id"] == id:
			n += 1
	return n


## "" = yerleştirilebilir; değilse hata anahtarı (para hariç tüm kurallar). full = false: yol kontrolü atlanır
## (inşa modunda fare gezinirken hızlı önizleme için; yerleştirirken her zaman tam kontrol yapılır).
func place_error(state: SimState, id: String, pos: Vector2, rot: int, full: bool = true) -> String:
	if not available_furniture(state).has(id):
		return "ERR_FURNITURE"
	if count_of(state, id) >= int(data.furniture[id]["max_count"]):
		return "ERR_FURNITURE_LIMIT"
	if not layout(state).is_free(OfficeLayout.furniture_rect(data.furniture[id], pos, rot)):
		return "ERR_PLACE_BLOCKED"
	if not full:
		return ""
	var trial: Dictionary = state.build.duplicate(true)
	(trial["furniture"] as Array).append({"id": id, "pos": [pos.x, pos.y], "rot": rot})
	if not OfficeLayout.build(data.office_layouts["office_%d" % state.office_level], trial, data.furniture).all_reachable():
		return "ERR_PLACE_PATH"
	return ""


func place(state: SimState, economy: Economy, id: String, pos: Vector2, rot: int) -> String:
	var err: String = place_error(state, id, pos, rot)
	if err.is_empty() and state.cash < furniture_cost(state, id):
		err = "ERR_NO_CASH"
	if not err.is_empty():
		return err
	economy.pay(state, furniture_cost(state, id))
	(state.build["furniture"] as Array).append({"id": id, "pos": [pos.x, pos.y], "rot": rot,
		"paid": furniture_cost(state, id)})
	_changed(state)
	return ""


## Satış: ödenen bedelin yarısı geri gelir.
func sell(state: SimState, index: int) -> bool:
	var list: Array = state.build["furniture"]
	if index < 0 or index >= list.size():
		return false
	state.cash += float(list[index].get("paid", 0.0)) * float(_b("sell_refund"))
	list.remove_at(index)
	_changed(state)
	return true


# --- masalar ---------------------------------------------------------------------

func desk_tier_cost(state: SimState, tier: String) -> float:
	return float(_b("desk_tiers")[tier]["cost_per_desk_1990"]) * Economy.inflation(data, state.clock.year()) \
		* layout(state).desks.size()


func set_desk_tier(state: SimState, economy: Economy, tier: String) -> String:
	var tiers: Dictionary = _b("desk_tiers")
	if not tiers.has(tier) or int(tiers[tier]["available_from"]) > state.clock.year() or tier == state.build["desk_tier"]:
		return "ERR_DESK_TIER"
	if state.cash < desk_tier_cost(state, tier):
		return "ERR_NO_CASH"
	economy.pay(state, desk_tier_cost(state, tier))
	state.build["desk_tier"] = tier
	_changed(state)
	return ""


# --- odalar -----------------------------------------------------------------------

func can_build_rooms(state: SimState) -> bool:
	return state.office_level >= int(_b("from_level"))


func room_cost(state: SimState, type: String, rect: Rect2) -> float:
	return float(data.room_types[type]["cost_per_m2_1990"]) * rect.get_area() * Economy.inflation(data, state.clock.year())


## Oda yalnızca boş alana (hazır "empty" odalar) çizilir, en az 3×3 m, başka çizilmiş odayla çakışmaz,
## içinde mobilya olmaz ve kimsenin yolunu kesmez.
func room_error(state: SimState, type: String, rect: Rect2) -> String:
	if not can_build_rooms(state):
		return "ERR_ROOM_LEVEL"
	if not data.room_types.has(type) or not bool(data.room_types[type]["buildable"]):
		return "ERR_ROOM_TYPE"
	var min_size: float = float(_b("min_room_size"))
	if rect.size.x < min_size or rect.size.y < min_size:
		return "ERR_ROOM_SMALL"
	var l: OfficeLayout = layout(state)
	var inside_empty: bool = false
	for room: Dictionary in l.rooms:
		var r: Rect2 = room["rect"]
		if bool(room["custom"]) and r.intersects(rect):
			return "ERR_ROOM_OVERLAP"
		if room["type"] == "empty" and not bool(room["custom"]) and r.encloses(rect):
			inside_empty = true
	if not inside_empty:
		return "ERR_ROOM_NOT_EMPTY"
	for prop: Dictionary in l.props:
		if prop["kind"] == "furniture" and (prop["rect"] as Rect2).intersects(rect):
			return "ERR_ROOM_OVERLAP"
	var trial: Dictionary = state.build.duplicate(true)
	(trial["rooms"] as Array).append({"type": type, "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
	if not OfficeLayout.build(data.office_layouts["office_%d" % state.office_level], trial, data.furniture).all_reachable():
		return "ERR_PLACE_PATH"
	return ""


func build_room(state: SimState, economy: Economy, type: String, rect: Rect2) -> String:
	var err: String = room_error(state, type, rect)
	if err.is_empty() and state.cash < room_cost(state, type, rect):
		err = "ERR_NO_CASH"
	if not err.is_empty():
		return err
	economy.pay(state, room_cost(state, type, rect))
	(state.build["rooms"] as Array).append({"type": type, "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
	_changed(state)
	return ""


## Odayı yıkar (bedel geri gelmez); içine yerleştirilmiş mobilya yerinde kalır.
func demolish_room(state: SimState, index: int) -> bool:
	var list: Array = state.build["rooms"]
	if index < 0 or index >= list.size():
		return false
	list.remove_at(index)
	_changed(state)
	return true


## Taşınırken mobilyalar ve çizilen odalar yeni binaya gelmez: mobilya bedelinin yarısı iade (masa kalitesi kalır).
func on_move(state: SimState) -> float:
	var refund: float = 0.0
	for f: Dictionary in state.build["furniture"]:
		refund += float(f.get("paid", 0.0)) * float(_b("move_refund"))
	state.cash += refund
	var tier: String = str(state.build.get("desk_tier", "basic"))
	state.build = empty_build()
	state.build["desk_tier"] = tier
	refresh(state)
	return refund


# --- kalite ve etkiler -------------------------------------------------------------

## GDD 12.3: oda_kalitesi = taban + konfor/alan + dekor çeşitliliği − kalabalık (0..100).
## Dönüş: { base, comfort, variety, crowding, total }.
func quality_parts(state: SimState) -> Dictionary:
	var l: OfficeLayout = layout(state)
	var area: float = maxf(1.0, l.work_area())
	var comfort: float = float(_b("desk_tiers")[state.build["desk_tier"]]["comfort"]) * l.desks.size()
	var kinds: Dictionary = {}
	for prop: Dictionary in l.props:
		if prop["kind"] != "furniture":
			continue
		var def: Dictionary = data.furniture[prop["id"]]
		var room: Dictionary = l.room_at((prop["rect"] as Rect2).get_center())
		var factor: float = 1.0 if not room.is_empty() and room["type"] == "work" else float(_b("outside_comfort_factor"))
		comfort += float(def["comfort"]) * factor
		kinds[def["decor"]] = true
	var base: float = float(data.office(state.office_level)["room_quality"])
	var comfort_part: float = comfort / area * float(_b("comfort_weight"))
	var variety: float = float(_b("variety_per_kind")) * mini(kinds.size(), int(_b("variety_cap")))
	var crowd: float = maxf(0.0, float(state.staff.size()) / area - float(_b("crowd_density"))) * float(_b("crowd_penalty"))
	return {"base": base, "comfort": comfort_part, "variety": variety, "crowding": -crowd,
		"total": clampf(base + comfort_part + variety - crowd, 0.0, 100.0)}


## Oda kalitesini ve oda etkilerini SimState'e yazar (üretim, enerji, memnuniyet bunları okur).
func refresh(state: SimState) -> void:
	state.room_quality = float(quality_parts(state)["total"])
	var effects: Dictionary = {}
	var l: OfficeLayout = layout(state)
	for type: String in data.room_type_ids:
		if l.has_closed_room(type):
			for k: String in data.room_types[type]["effects"]:
				effects[k] = data.room_types[type]["effects"][k]
	state.office_effects = effects
