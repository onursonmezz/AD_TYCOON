class_name DeskLayout
extends RefCounted
## Çalışma odasında masa adaları (OF-2): iki sıra masa sırt sırta, sandalyeler dışta; adalar arasında yürüme yolu.
## Eskiden tüm masalar tek yöne bakan sıralardı (sınıf gibi). Masa adedi eski dizilişle aynı tutulur: oda konforu ve
## masa kademesi maliyeti masa sayısına bağlı, denge değişmesin. Yalnızca konum hesabı; Node kullanmaz.
## Dönüş: [{ "pos", "seat", "face", "flip" }] — face: oturanın baktığı yön, flip: masa 180° dönük (kuzey sırası).

const AISLE: float = 1.3
## Sandalyenin arkasında duvara kadar bırakılan yol (eski dizilişteki boşlukla aynı; kapasite korunur).
const WALL_WALK: float = 0.7


## r: oda dikdörtgeni; blocked(rect) true dönerse o konuma masa konmaz (kapı önü).
static func work_desks(r: Rect2, blocked: Callable) -> Array[Dictionary]:
	var size: Vector2 = OfficeLayout.DESK_SIZE
	var seat: float = OfficeLayout.SEAT_OFFSET
	var margin: float = OfficeLayout.DESK_MARGIN
	var step_x: float = OfficeLayout.DESK_STEP.x
	var limit: int = _old_count(r, blocked)
	var out: Array[Dictionary] = []
	var pod: float = size.y * 2.0 + seat * 2.0 + AISLE
	# Adalar odada dikeyde ortalanır (hepsi kuzey duvarına yığılıp güney yarısı boş kalmasın).
	var cols: int = 0
	var cx: float = r.position.x + margin
	while cx <= r.end.x - margin + 0.001:
		cols += 1
		cx += step_x
	var pods: int = ceili(float(limit) / float(maxi(1, cols * 2)))
	var span: float = pods * pod - AISLE  # ilk kuzey sandalyesinden son güney sandalyesine
	var room: float = r.size.y - 2.0 * WALL_WALK
	var z: float = r.position.y + WALL_WALK + seat + maxf(0.0, (room - span) * 0.5)
	while out.size() < limit and z + size.y + seat <= r.end.y - WALL_WALK + 0.001:
		# Sütun sütun, önce kuzey sonra güney masası: çalışanlar karşılıklı çiftler halinde dolar (sıra sıra değil).
		var x: float = r.position.x + margin
		while x <= r.end.x - margin + 0.001 and out.size() < limit:
			for row: int in 2:
				var pos: Vector2 = Vector2(x, z + row * size.y)
				if out.size() < limit and not blocked.call(Rect2(pos - size * 0.5, size)):
					var north: bool = row == 0
					out.append({"pos": pos, "seat": pos + Vector2(0, -seat if north else seat),
						"face": Vector2(0, 1) if north else Vector2(0, -1), "flip": north})
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
