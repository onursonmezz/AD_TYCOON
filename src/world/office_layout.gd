class_name OfficeLayout
extends RefCounted
## Bir ofis seviyesinin yerleşimi (GDD 12.1–12.2), saf veri: odalar, duvar parçaları, masalar, mutfak/toplantı/dinlenme
## noktaları ve yürüme ızgarası (AStarGrid2D). 3D sahne bunu okur; testler sahnesiz kullanır.
## Koordinatlar metre, Vector2(x, z); 1 birim = 1 metre (GDD 21.2).

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

var size: Vector2 = Vector2.ZERO
var rooms: Array[Dictionary] = []
## { "a": Vector2, "b": Vector2, "outer": bool, "side": "n"|"s"|"e"|"w" }
var walls: Array[Dictionary] = []
## { "pos": Vector2, "seat": Vector2 }
var desks: Array[Dictionary] = []
## Mobilya kutuları (görsel + engel): { "kind", "rect": Rect2 }
var props: Array[Dictionary] = []
## oda tipi → yürünebilir bekleme noktaları
var spots: Dictionary = {}
var entrance: Vector2 = Vector2.ZERO
var _grid: AStarGrid2D = AStarGrid2D.new()


static func build(rec: Dictionary) -> OfficeLayout:
	var l: OfficeLayout = OfficeLayout.new()
	l.size = Vector2(float(rec["size"][0]), float(rec["size"][1]))
	for r: Dictionary in rec["rooms"]:
		var rr: Array = r["rect"]
		l.rooms.append({"type": r["type"], "rect": Rect2(float(rr[0]), float(rr[1]), float(rr[2]), float(rr[3])),
			"open": bool(r.get("open", false)), "door": str(r.get("door", ""))})
	l._outer_walls(str(rec.get("entrance", "s")))
	for room: Dictionary in l.rooms:
		if not bool(room["open"]):
			l._room_walls(room)
		l._furnish(room)
	l._build_grid()
	return l


# --- duvarlar --------------------------------------------------------------------

func _outer_walls(entrance_side: String) -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	for side: String in ["n", "s", "e", "w"]:
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
	for side: String in ["n", "s", "e", "w"]:
		var seg: Array[Vector2] = _edge(r, side)
		if _on_perimeter(seg[0], seg[1]):
			continue
		if side == room["door"]:
			_add_with_gap(seg[0], seg[1], (seg[0] + seg[1]) * 0.5, DOOR_WIDTH, false, side)
		else:
			walls.append({"a": seg[0], "b": seg[1], "outer": false, "side": side})


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
	var g1: Vector2 = mid - dir * width * 0.5
	var g2: Vector2 = mid + dir * width * 0.5
	walls.append({"a": a, "b": g1, "outer": outer, "side": side})
	walls.append({"a": g2, "b": b, "outer": outer, "side": side})


# --- mobilya ve noktalar -----------------------------------------------------------

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
					desks.append({"pos": pos, "seat": pos + Vector2(0, SEAT_OFFSET)})
					props.append({"kind": "desk", "rect": Rect2(pos - DESK_SIZE * 0.5, DESK_SIZE)})
					x += DESK_STEP.x
				z += DESK_STEP.y
		"kitchen":
			props.append({"kind": "counter", "rect": Rect2(r.position + Vector2(0.3, 0.2), Vector2(r.size.x - 0.6, 0.6))})
			list = _row(r.position.x + 0.8, r.end.x - 0.8, r.position.y + 1.4)
		"meeting":
			var table: Rect2 = Rect2(r.get_center() - r.size * Vector2(0.25, 0.15), r.size * Vector2(0.5, 0.3))
			props.append({"kind": "table", "rect": table})
			list = _row(table.position.x + 0.4, table.end.x - 0.4, table.position.y - 0.6)
			list.append_array(_row(table.position.x + 0.4, table.end.x - 0.4, table.end.y + 0.6))
		"lounge":
			props.append({"kind": "sofa", "rect": Rect2(r.position + Vector2(0.4, 0.3), Vector2(minf(r.size.x - 0.8, 3.0), 0.8))})
			list = _row(r.position.x + 0.8, r.end.x - 0.8, r.position.y + 1.7)
	if not list.is_empty():
		(spots.get_or_add(room["type"], []) as Array).append_array(list.slice(0, MAX_SPOTS))


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
		if room["type"] == kind:
			return room["rect"]
	return Rect2()


# --- yürüme ---------------------------------------------------------------------

func _build_grid() -> void:
	_grid.region = Rect2i(0, 0, int(ceilf(size.x / CELL)), int(ceilf(size.y / CELL)))
	_grid.cell_size = Vector2(CELL, CELL)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	for cx: int in _grid.region.size.x:
		for cz: int in _grid.region.size.y:
			var c: Vector2 = Vector2((cx + 0.5) * CELL, (cz + 0.5) * CELL)
			if _blocked(c):
				_grid.set_point_solid(Vector2i(cx, cz))


func _blocked(p: Vector2) -> bool:
	for w: Dictionary in walls:
		if Geometry2D.get_closest_point_to_segment(p, w["a"], w["b"]).distance_to(p) < WALL_CLEARANCE:
			return true
	for prop: Dictionary in props:
		if (prop["rect"] as Rect2).has_point(p):
			return true
	return false


func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(clampi(int(p.x / CELL), 0, _grid.region.size.x - 1), clampi(int(p.y / CELL), 0, _grid.region.size.y - 1))


func is_walkable(p: Vector2) -> bool:
	return not _grid.is_point_solid(cell_of(p))


## İki nokta arası yol (metre). Ulaşılamazsa boş.
func path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var cells: Array[Vector2i] = _grid.get_id_path(cell_of(from), cell_of(to), true)
	var out: PackedVector2Array = PackedVector2Array()
	for c: Vector2i in cells:
		out.append(Vector2((c.x + 0.5) * CELL, (c.y + 0.5) * CELL))
	if not out.is_empty():
		out[out.size() - 1] = to
	return out
