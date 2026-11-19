class_name DeskLayout
extends RefCounted
## Çalışma odasında masa adaları (OF-2): iki sıra masa sırt sırta, sandalyeler dışta; adalar arasında yürüme yolu.
## Eskiden tüm masalar tek yöne bakan sıralardı (sınıf gibi). Masa adedi eski dizilişle aynı tutulur: oda konforu ve
## masa kademesi maliyeti masa sayısına bağlı, denge değişmesin. Yalnızca konum hesabı; Node kullanmaz.
## S5: kurucunun ekipten ayrı masası (GDT gibi): ilk adanın en sondaki sütununda, ekibe dönük (90° dönmüş); o sütunun
## karşı masası boş kalır. Listede her zaman ilk masa kurucunun masasıdır ("founder": true).
## Dönüş: [{ "pos", "seat", "face", "flip", "turn", "founder" }] — face: oturanın baktığı yön, turn: masanın dönüşü (derece).

const AISLE: float = 1.3
## Sandalyenin arkasında duvara kadar bırakılan yol (eski dizilişteki boşlukla aynı; kapasite korunur).
const WALL_WALK: float = 0.7


## r: oda dikdörtgeni; blocked(rect) true dönerse o konuma masa konmaz (kapı önü).
static func work_desks(r: Rect2, blocked: Callable) -> Array[Dictionary]:
	var size: Vector2 = OfficeLayout.DESK_SIZE
	var seat: float = OfficeLayout.SEAT_OFFSET
	var limit: int = _old_count(r, blocked)
	if limit <= 0:
		return []
	var slots: Array[Dictionary] = _slots(r, blocked, limit + 2)
	if slots.is_empty():
		return []
	# Kurucu: ilk adanın (en küçük z) en doğudaki sütununun kuzey yeri; masası batıya, ekibe dönük.
	var first_z: float = (slots[0]["pos"] as Vector2).y
	var boss: Dictionary = slots[0]
	for s: Dictionary in slots:
		var p: Vector2 = s["pos"]
		if is_equal_approx(p.y, first_z) and p.x > (boss["pos"] as Vector2).x:
			boss = s
	var bx: float = (boss["pos"] as Vector2).x
	var founder_pos: Vector2 = Vector2(bx, first_z + size.y * 0.5)  # iki sıranın ortasında
	var out: Array[Dictionary] = [{"pos": founder_pos, "seat": founder_pos + Vector2(seat, 0.0), "face": Vector2(-1, 0),
		"flip": false, "turn": 90.0, "founder": true}]
	for s: Dictionary in slots:
		if out.size() >= limit:
			break
		if is_equal_approx((s["pos"] as Vector2).x, bx) and absf((s["pos"] as Vector2).y - first_z) <= size.y + 0.01:
			continue  # kurucunun sütunu: ayrı kalsın
		out.append(s)
	return out


## Ada yerleri doluş sırasıyla (sütun sütun, önce kuzey sonra güney): en çok want kadar.
static func _slots(r: Rect2, blocked: Callable, want: int) -> Array[Dictionary]:
	var size: Vector2 = OfficeLayout.DESK_SIZE
	var seat: float = OfficeLayout.SEAT_OFFSET
	var margin: float = OfficeLayout.DESK_MARGIN
	var step_x: float = OfficeLayout.DESK_STEP.x
	var out: Array[Dictionary] = []
	var pod: float = size.y * 2.0 + seat * 2.0 + AISLE
	# Adalar odada dikeyde ortalanır (hepsi kuzey duvarına yığılıp güney yarısı boş kalmasın).
	var cols: int = 0
	var cx: float = r.position.x + margin
	while cx <= r.end.x - margin + 0.001:
		cols += 1
		cx += step_x
	var pods: int = ceili(float(want) / float(maxi(1, cols * 2)))
	var span: float = pods * pod - AISLE  # ilk kuzey sandalyesinden son güney sandalyesine
	var room: float = r.size.y - 2.0 * WALL_WALK
	var z: float = r.position.y + WALL_WALK + seat + maxf(0.0, (room - span) * 0.5)
	while out.size() < want and z + size.y + seat <= r.end.y - WALL_WALK + 0.001:
		var x: float = r.position.x + margin
		while x <= r.end.x - margin + 0.001 and out.size() < want:
			for row: int in 2:
				var pos: Vector2 = Vector2(x, z + row * size.y)
				if out.size() < want and not blocked.call(Rect2(pos - size * 0.5, size)):
					var north: bool = row == 0
					out.append({"pos": pos, "seat": pos + Vector2(0, -seat if north else seat),
						"face": Vector2(0, 1) if north else Vector2(0, -1), "flip": north, "turn": 180.0 if north else 0.0,
						"founder": false})
			x += step_x
		z += pod
	return out


## Eski tek yönlü dizilişin masa sayısı (denge için üst sınır).
static func _old_count(r: Rect2, blocked: Callable) -> int:
	var size: Vector2 = OfficeLayout.DESK_SIZE
	var n: int = 0
	var z: float = r.position.y + OfficeLayout.DESK_MARGIN
	while z <= r.end.y - OfficeLayout.DESK_MARGIN - OfficeLayout.SEAT_OFFSET + 0.001:
		var x: float = r.position.x + OfficeLayout.DESK_MARGIN
		while x <= r.end.x - OfficeLayout.DESK_MARGIN + 0.001:
			if not blocked.call(Rect2(Vector2(x, z) - size * 0.5, size)):
				n += 1
			x += OfficeLayout.DESK_STEP.x
		z += OfficeLayout.DESK_STEP.y
	return n
