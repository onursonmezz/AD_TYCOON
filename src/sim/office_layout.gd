class_name OfficeLayout
extends RefCounted
## Bir ofisin yerleşimi (GDD 12.1–12.3), saf veri: hazır odalar + oyuncunun çizdiği odalar, duvar parçaları, masalar,
## mobilyalar, mutfak/toplantı/dinlenme noktaları ve yürüme ızgarası (AStarGrid2D, K-060).
## Hem simülasyon (yerleştirme kuralları, oda kalitesi) hem 3D sahne kullanır. Koordinatlar metre, Vector2(x, z).

const CELL: float = 0.5
const WALL_CLEARANCE: float = 0.3
const DOOR_WIDTH: float = 1.6
const ENTRANCE_WIDTH: float = 2.0
const DESK_SIZE: Vector2 = Vector2(1.4, 0.7)
const DESK_STEP: Vector2 = Vector2(2.0, 2.5)
const DESK_MARGIN: float = 1.0
const SEAT_OFFSET: float = 0.8
const SPOT_STEP: float = 1.0
const MAX_SPOTS: int = 8
const SIDES: Array[String] = ["n", "w", "e", "s"]

var size: Vector2 = Vector2.ZERO
## { "type", "rect": Rect2, "open", "door", "custom": bool }
var rooms: Array[Dictionary] = []
## { "a": Vector2, "b": Vector2, "outer": bool, "side": "n"|"s"|"e"|"w" }
var walls: Array[Dictionary] = []
## { "pos": Vector2, "seat": Vector2 }
var desks: Array[Dictionary] = []
## Engel kutuları: { "kind": "desk"|"counter"|"table"|"sofa"|"furniture", "rect": Rect2, "id" (mobilya), "index" }
var props: Array[Dictionary] = []
## oda tipi → yürünebilir bekleme noktaları
var spots: Dictionary = {}
var entrance: Vector2 = Vector2.ZERO
## Kapalı odaların kapı ortaları: masalar bunların önüne dizilmez (yol kapanmasın).
var _doors: Array[Vector2] = []
const DOOR_KEEP_CLEAR: float = 1.4
var _grid: AStarGrid2D = AStarGrid2D.new()


## custom: { "rooms": [{type, rect: [x, z, w, d]}], "furniture": [{id, pos: [x, z], rot}] }; furniture_defs: id → kayıt.
static func build(rec: Dictionary, custom: Dictionary = {}, furniture_defs: Dictionary = {}) -> OfficeLayout:
	var l: OfficeLayout = OfficeLayout.new()
	l.size = Vector2(float(rec["size"][0]), float(rec["size"][1]))
	for r: Dictionary in rec["rooms"]:
		l.rooms.append({"type": r["type"], "rect": _rect(r["rect"]), "open": bool(r.get("open", false)),
			"door": str(r.get("door", "")), "custom": false})
	for r: Dictionary in custom.get("rooms", []):
		var rect: Rect2 = _rect(r["rect"])
		l.rooms.append({"type": r["type"], "rect": rect, "open": false, "door": l._auto_door(rect), "custom": true})
	l._outer_walls(str(rec.get("entrance", "s")))
	for room: Dictionary in l.rooms:
		if not bool(room["open"]) and not str(room["door"]).is_empty():
			var seg: Array[Vector2] = l._edge(room["rect"], room["door"])
			l._doors.append((seg[0] + seg[1]) * 0.5)
	for room: Dictionary in l.rooms:
		if not bool(room["open"]):
			l._room_walls(room)
		if not (bool(room["type"] == "empty") or l._covered(room)):
			l._furnish(room)
	var i: int = 0
	for f: Dictionary in custom.get("furniture", []):
		if furniture_defs.has(f["id"]):
			l.props.append({"kind": "furniture", "id": f["id"], "index": i, "rot": int(f.get("rot", 0)),
				"rect": furniture_rect(furniture_defs[f["id"]], Vector2(float(f["pos"][0]), float(f["pos"][1])), int(f.get("rot", 0)))})
		i += 1
	l._build_grid()
	# Küçük odalarda duvara çok yakın düşen bekleme noktaları atılır.
	for kind: Variant in l.spots.keys():
		l.spots[kind] = (l.spots[kind] as Array).filter(func(p: Vector2) -> bool: return l.is_walkable(p))
	return l


static func _rect(a: Array) -> Rect2:
	return Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))


## Mobilyanın kapladığı alan; pos = sol üst köşe (ızgaraya oturur), rot 1 = 90°.
static func furniture_rect(def: Dictionary, pos: Vector2, rot: int) -> Rect2:
	var s: Vector2 = Vector2(float(def["size"][0]), float(def["size"][1]))
	if rot % 2 == 1:
		s = Vector2(s.y, s.x)
	return Rect2(pos, s)


## Hazır bir odanın üstüne oyuncu oda çizdiyse (boş alan), alttaki oda döşenmez.
func _covered(room: Dictionary) -> bool:
	if bool(room["custom"]):
		return false
	for other: Dictionary in rooms:
		if bool(other["custom"]) and (other["rect"] as Rect2).encloses(room["rect"]):
			return true
	return false


# --- duvarlar --------------------------------------------------------------------

func _outer_walls(entrance_side: String) -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	for side: String in SIDES:
		var seg: Array[Vector2] = _edge(r, side)
		if side == entrance_side:
			var mid: Vector2 = (seg[0] + seg[1]) * 0.5
			entrance = mid + _inward(side) * 0.6
			_add_with_gap(seg[0], seg[1], mid, ENTRANCE_WIDTH, true, side)
		else:
			walls.append({"a": seg[0], "b": seg[1], "outer": true, "side": side})


## Kapalı odanın bina kenarında olmayan kenarlarına bölme duvarı; kapı tarafında ortada boşluk.
func _room_walls(room: Dictionary) -> void:
	var r: Rect2 = room["rect"]
	for side: String in SIDES:
		var seg: Array[Vector2] = _edge(r, side)
		if _on_perimeter(seg[0], seg[1]):
			continue
		if side == room["door"]:
			_add_with_gap(seg[0], seg[1], (seg[0] + seg[1]) * 0.5, DOOR_WIDTH, false, side)
		else:
			walls.append({"a": seg[0], "b": seg[1], "outer": false, "side": side})


## Çizilen odanın kapısı: dışarısı bina içinde ve başka kapalı odada olmayan ilk kenar (önce kuzey).
func _auto_door(r: Rect2) -> String:
	for side: String in SIDES:
		var seg: Array[Vector2] = _edge(r, side)
		var outside: Vector2 = (seg[0] + seg[1]) * 0.5 - _inward(side) * 0.6
		if Rect2(Vector2.ZERO, size).has_point(outside) and not _in_closed_room(outside):
			return side
	return "n"


func _in_closed_room(p: Vector2) -> bool:
	for room: Dictionary in rooms:
		if not bool(room["open"]) and (room["rect"] as Rect2).has_point(p):
			return true
	return false


func _edge(r: Rect2, side: String) -> Array[Vector2]:
	match side:
		"n":
			return [r.position, Vector2(r.end.x, r.position.y)]
		"s":
			return [Vector2(r.position.x, r.end.y), r.end]
		"w":
			return [r.position, Vector2(r.position.x, r.end.y)]
	return [Vector2(r.end.x, r.position.y), r.end]


func _inward(side: String) -> Vector2:
	return {"n": Vector2(0, 1), "s": Vector2(0, -1), "w": Vector2(1, 0), "e": Vector2(-1, 0)}[side]


func _on_perimeter(a: Vector2, b: Vector2) -> bool:
	return (is_zero_approx(a.x) and is_zero_approx(b.x)) or (is_zero_approx(a.y) and is_zero_approx(b.y)) \
		or (is_equal_approx(a.x, size.x) and is_equal_approx(b.x, size.x)) \
		or (is_equal_approx(a.y, size.y) and is_equal_approx(b.y, size.y))


func _add_with_gap(a: Vector2, b: Vector2, mid: Vector2, width: float, outer: bool, side: String) -> void:
	var dir: Vector2 = (b - a).normalized()
	walls.append({"a": a, "b": mid - dir * width * 0.5, "outer": outer, "side": side})
	walls.append({"a": mid + dir * width * 0.5, "b": b, "outer": outer, "side": side})


# --- hazır mobilya ve noktalar -------------------------------------------------------

func _furnish(room: Dictionary) -> void:
	var r: Rect2 = room["rect"]
	var list: Array[Vector2] = []
	match str(room["type"]):
		"work":
			var z: float = r.position.y + DESK_MARGIN
			while z <= r.end.y - DESK_MARGIN - SEAT_OFFSET + 0.001:
				var x: float = r.position.x + DESK_MARGIN
				while x <= r.end.x - DESK_MARGIN + 0.001:
					var pos: Vector2 = Vector2(x, z)
					if _near_door(Rect2(pos - DESK_SIZE * 0.5, DESK_SIZE)):
						x += DESK_STEP.x
						continue
					desks.append({"pos": pos, "seat": pos + Vector2(0, SEAT_OFFSET)})
					props.append({"kind": "desk", "rect": Rect2(pos - DESK_SIZE * 0.5, DESK_SIZE)})
					x += DESK_STEP.x
				z += DESK_STEP.y
		"kitchen":
			props.append({"kind": "counter", "rect": Rect2(r.position + Vector2(0.3, 0.2), Vector2(r.size.x - 0.6, 0.6))})
			list = _row(r.position.x + 0.8, r.end.x - 0.8, minf(r.position.y + 1.4, r.end.y - 0.6))
		"meeting", "brainstorm", "rd_lab", "studio":
			var table: Rect2 = Rect2(r.get_center() - r.size * Vector2(0.25, 0.15), r.size * Vector2(0.5, 0.3))
			props.append({"kind": "table", "rect": table})
			list = _row(table.position.x + 0.4, table.end.x - 0.4, table.position.y - 0.6)
			list.append_array(_row(table.position.x + 0.4, table.end.x - 0.4, table.end.y + 0.6))
		"lounge", "award_lobby":
			props.append({"kind": "sofa", "rect": Rect2(r.position + Vector2(0.4, 0.3), Vector2(minf(r.size.x - 0.8, 3.0), 0.8))})
			list = _row(r.position.x + 0.8, r.end.x - 0.8, minf(r.position.y + 1.7, r.end.y - 0.6))
	if not list.is_empty():
		(spots.get_or_add(room["type"], []) as Array).append_array(list.slice(0, MAX_SPOTS))


func _near_door(r: Rect2) -> bool:
	for d: Vector2 in _doors:
		if r.grow(DOOR_KEEP_CLEAR).has_point(d):
			return true
	return false


func _row(x0: float, x1: float, z: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var x: float = x0
	while x <= x1 + 0.001:
		out.append(Vector2(x, z))
		x += SPOT_STEP
	return out


func spot_list(kind: String) -> Array:
	return spots.get(kind, [])


func room_rect(kind: String) -> Rect2:
	for room: Dictionary in rooms:
		if room["type"] == kind and not _covered(room):
			return room["rect"]
	return Rect2()


## Noktanın bulunduğu oda (önce oyuncunun çizdikleri); yoksa {}.
func room_at(p: Vector2) -> Dictionary:
	for pass_custom: bool in [true, false]:
		for room: Dictionary in rooms:
			if bool(room["custom"]) == pass_custom and (room["rect"] as Rect2).has_point(p):
				return room
	return {}


func has_room(kind: String) -> bool:
	return room_rect(kind).has_area()


## Oda etkileri yalnızca kapalı (kapılı) odalardan gelir; ev odasındaki açık köşeler süstür (K-062).
func has_closed_room(kind: String) -> bool:
	for room: Dictionary in rooms:
		if room["type"] == kind and not bool(room["open"]) and not _covered(room):
			return true
	return false


## Kalabalık ve mobilya konforu için çalışma alanı (m²).
func work_area() -> float:
	var a: float = 0.0
	for room: Dictionary in rooms:
		if room["type"] == "work" and not _covered(room):
			a += (room["rect"] as Rect2).get_area()
	return a


# --- yürüme ---------------------------------------------------------------------

## Duvarlar ve kutular hücre hücre işaretlenir (her hücrede tüm engelleri dolaşmak yerine; inşa modunda hızlı olsun).
func _build_grid() -> void:
	_grid.region = Rect2i(0, 0, int(ceilf(size.x / CELL)), int(ceilf(size.y / CELL)))
	_grid.cell_size = Vector2(CELL, CELL)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	for w: Dictionary in walls:
		var a: Vector2 = w["a"]
		var b: Vector2 = w["b"]
		var box: Rect2 = Rect2(a, Vector2.ZERO).expand(b).grow(WALL_CLEARANCE)
		_mark(box, func(c: Vector2) -> bool:
			return Geometry2D.get_closest_point_to_segment(c, a, b).distance_to(c) < WALL_CLEARANCE)
	for prop: Dictionary in props:
		_mark(prop["rect"], func(c: Vector2) -> bool: return (prop["rect"] as Rect2).has_point(c))


func _mark(box: Rect2, test: Callable) -> void:
	var c0: Vector2i = cell_of(box.position)
	var c1: Vector2i = cell_of(box.end)
	for cx: int in range(c0.x, c1.x + 1):
		for cz: int in range(c0.y, c1.y + 1):
			if test.call(Vector2((cx + 0.5) * CELL, (cz + 0.5) * CELL)):
				_grid.set_point_solid(Vector2i(cx, cz))


func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(clampi(int(p.x / CELL), 0, _grid.region.size.x - 1), clampi(int(p.y / CELL), 0, _grid.region.size.y - 1))


func is_walkable(p: Vector2) -> bool:
	return not _grid.is_point_solid(cell_of(p))


## Alanın tamamı boş mu (duvar ve kutu yok, bina içinde)?
func is_free(r: Rect2) -> bool:
	if not Rect2(Vector2.ZERO, size).encloses(r):
		return false
	var c0: Vector2i = cell_of(r.position + Vector2(0.01, 0.01))
	var c1: Vector2i = cell_of(r.end - Vector2(0.01, 0.01))
	for cx: int in range(c0.x, c1.x + 1):
		for cz: int in range(c0.y, c1.y + 1):
			if _grid.is_point_solid(Vector2i(cx, cz)):
				return false
	return true


## Girişten ulaşılabilen hücreler (taşkın doldurma). Tüm masa koltukları ve noktalar ulaşılabilir olmalı.
func all_reachable() -> bool:
	var seen: Dictionary = {}
	var queue: Array[Vector2i] = [cell_of(entrance)]
	seen[queue[0]] = true
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if _grid.is_in_boundsv(n) and not seen.has(n) and not _grid.is_point_solid(n):
				seen[n] = true
				queue.append(n)
	for d: Dictionary in desks:
		if not seen.has(cell_of(d["seat"])):
			return false
	for list: Variant in spots.values():
		for p: Variant in list:
			if not seen.has(cell_of(p)):
				return false
	return true


## İki nokta arası yol (metre). Ulaşılamazsa boş.
func path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var cells: Array[Vector2i] = _grid.get_id_path(cell_of(from), cell_of(to), true)
	var out: PackedVector2Array = PackedVector2Array()
	for c: Vector2i in cells:
		out.append(Vector2((c.x + 0.5) * CELL, (c.y + 0.5) * CELL))
	if not out.is_empty():
		out[out.size() - 1] = to
	return out
