class_name WallSystem
extends RefCounted
## İnşa modunda iç duvar çekme, silme ve kapı açma (K-116). Bina dış duvarları hariç tüm iç duvarlar düzenlenir.
## İşlemler state.build["wall_ops"] listesine sırayla yazılır, OfficeLayout bunları hazır duvarlara uygular.
## Ücretler balance.json "build": duvar metre başı, kapı sabit; oyuncunun çektiği duvar silinince yarısı geri gelir,
## hazır duvarı yıkmak bedava ama iade yok. Kapıyı kapatmak (silmek) bedava.

var data: GameData
var build: BuildSystem


func _init(game_data: GameData, build_system: BuildSystem) -> void:
	data = game_data
	build = build_system


func _b(key: String) -> float:
	return float(data.bal("build." + key))


func _ops(state: SimState) -> Array:
	return state.build.get_or_add("wall_ops", [])


func wall_cost_per_m(state: SimState) -> float:
	return _b("wall_cost_per_m_1990") * Economy.inflation(data, state.clock.year())


func door_cost(state: SimState) -> float:
	return _b("door_cost_1990") * Economy.inflation(data, state.clock.year())


## Çekilecek duvarın yeni (henüz duvar olmayan) uzunluğu; bedel buna göre.
func new_length(state: SimState, a: Vector2, b: Vector2) -> float:
	return a.distance_to(b) - OfficeWalls.covered(build.layout(state).wall_lines, a, b)


func wall_cost(state: SimState, a: Vector2, b: Vector2) -> float:
	return maxf(0.0, new_length(state, a, b)) * wall_cost_per_m(state)


func _trial_reachable(state: SimState, op: Dictionary) -> bool:
	var trial: Dictionary = state.build.duplicate(true)
	(trial.get_or_add("wall_ops", []) as Array).append(op)
	return OfficeLayout.build(data.office_layouts["office_%d" % state.office_level], trial, data.furniture).all_reachable()


## "" = çekilebilir; değilse hata anahtarı (para hariç). full = false: yol kontrolü atlanır (fare gezinirken).
func wall_error(state: SimState, a: Vector2, b: Vector2, full: bool = true) -> String:
	if OfficeWalls.seg(a, b).is_empty():
		return "ERR_WALL_STRAIGHT"
	if a.distance_to(b) < _b("min_wall_length") - OfficeWalls.EPS:
		return "ERR_WALL_SHORT"
	var l: OfficeLayout = build.layout(state)
	var inside: Rect2 = Rect2(Vector2.ZERO, l.size).grow(OfficeWalls.EPS)
	if not inside.has_point(a) or not inside.has_point(b) or l.is_on_perimeter(a, b):
		return "ERR_WALL_OUTSIDE"
	if new_length(state, a, b) < OfficeWalls.EPS:
		return "ERR_WALL_EXISTS"
	var line: Rect2 = Rect2(a, Vector2.ZERO).expand(b).grow(0.05)
	for prop: Dictionary in l.props:
		if (prop["rect"] as Rect2).intersects(line):
			return "ERR_PLACE_BLOCKED"
	if full and not _trial_reachable(state, _op("add", a, b)):
		return "ERR_PLACE_PATH"
	return ""


func _op(kind: String, a: Vector2, b: Vector2) -> Dictionary:
	return {"op": kind, "a": [a.x, a.y], "b": [b.x, b.y]}


func build_wall(state: SimState, economy: Economy, a: Vector2, b: Vector2) -> String:
	var err: String = wall_error(state, a, b)
	var cost: float = wall_cost(state, a, b)
	if err.is_empty() and state.cash < cost:
		err = "ERR_NO_CASH"
	if not err.is_empty():
		return err
	economy.pay(state, cost)
	_ops(state).append(_op("add", a, b))
	build.mark_changed(state)
	return ""


# --- silme ---------------------------------------------------------------------------

## Noktadaki duvar parçası (silme / kapı araçları için); yoksa {}.
func wall_at(state: SimState, p: Vector2) -> Dictionary:
	return OfficeWalls.segment_at(build.layout(state).wall_lines, p, _b("wall_pick_distance"))


## Noktadaki kapatılabilir kapı (oyuncunun açtığı, hâlâ boşluk olan); yoksa {} — { "a", "b" }.
func door_at(state: SimState, p: Vector2) -> Dictionary:
	var lines: Dictionary = build.layout(state).wall_lines
	var pick: float = _b("wall_pick_distance")
	for op: Dictionary in _ops(state):
		if str(op["op"]) != "door":
			continue
		var a: Vector2 = Vector2(float(op["a"][0]), float(op["a"][1]))
		var b: Vector2 = Vector2(float(op["b"][0]), float(op["b"][1]))
		if Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) <= pick \
				and OfficeWalls.covered(lines, a, b) < a.distance_to(b) - OfficeWalls.EPS:
			return {"a": a, "b": b}
	return {}


## Silinirse geri gelecek para: parçanın oyuncunun çektiği kısmı × güncel metre fiyatı × iade oranı.
func wall_refund(state: SimState, seg: Dictionary) -> float:
	var owned: Dictionary = OfficeWalls.owned(_ops(state).filter(func(op: Dictionary) -> bool:
		return not bool(op.get("free", false))))
	return OfficeWalls.covered(owned, seg["a"], seg["b"]) * wall_cost_per_m(state) * _b("sell_refund")


## Noktadaki kapıyı kapatır ya da duvarı yıkar. Dönüş: "" ya da ERR_WALL_NONE.
func remove_at(state: SimState, p: Vector2) -> String:
	var door: Dictionary = door_at(state, p)
	if not door.is_empty():
		var op: Dictionary = _op("add", door["a"], door["b"])
		op["free"] = true
		_ops(state).append(op)
		build.mark_changed(state)
		return ""
	var seg: Dictionary = wall_at(state, p)
	if seg.is_empty():
		return "ERR_WALL_NONE"
	state.cash += wall_refund(state, seg)
	_ops(state).append(_op("remove", seg["a"], seg["b"]))
	build.mark_changed(state)
	return ""


# --- kapı ----------------------------------------------------------------------------

## Noktaya açılacak kapı boşluğu: { "a", "b" } ya da { "error" }.
func door_gap(state: SimState, p: Vector2) -> Dictionary:
	var seg: Dictionary = wall_at(state, p)
	if seg.is_empty():
		return {"error": "ERR_WALL_NONE"}
	var width: float = _b("door_width")
	var s: Dictionary = OfficeWalls.seg(seg["a"], seg["b"])
	if float(s["t1"]) - float(s["t0"]) < width - OfficeWalls.EPS:
		return {"error": "ERR_DOOR_SHORT"}
	var snap: float = _b("wall_snap")
	var t: float = clampf(roundf(float(seg["t"]) / snap) * snap, float(s["t0"]) + width * 0.5, float(s["t1"]) - width * 0.5)
	var e: Array[Vector2] = OfficeWalls.ends(str(s["key"]), t - width * 0.5, t + width * 0.5)
	# Kapının iki yanı eşyayla tıkalı olmasın (ör. mutfak tezgâhının arkasına kapı açılmaz).
	var mid: Vector2 = (e[0] + e[1]) * 0.5
	var normal: Vector2 = (e[1] - e[0]).normalized().orthogonal()
	for d: float in [-_b("door_clearance"), _b("door_clearance")]:
		for prop: Dictionary in build.layout(state).props:
			if not bool(prop.get("flat", false)) and (prop["rect"] as Rect2).has_point(mid + normal * d):
				return {"error": "ERR_DOOR_BLOCKED"}
	return {"a": e[0], "b": e[1]}


func build_door(state: SimState, economy: Economy, p: Vector2) -> String:
	var gap: Dictionary = door_gap(state, p)
	if gap.has("error"):
		return str(gap["error"])
	if state.cash < door_cost(state):
		return "ERR_NO_CASH"
	economy.pay(state, door_cost(state))
	_ops(state).append(_op("door", gap["a"], gap["b"]))
	build.mark_changed(state)
	return ""


## Taşınırken: oyuncunun çektiği duvarların taşınma iadesi (bina değişince duvarlar gelmez).
func move_refund(state: SimState) -> float:
	var owned: Dictionary = OfficeWalls.owned(_ops(state).filter(func(op: Dictionary) -> bool:
		return not bool(op.get("free", false))))
	return OfficeWalls.length(owned) * wall_cost_per_m(state) * _b("move_refund")
