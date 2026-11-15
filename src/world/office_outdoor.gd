class_name OfficeOutdoor
extends RefCounted
## Ofisin dışı (OfficeDressing'den ayrıldı, 400 satır kuralı): bahçe, bina önündeki çit ve çalılar, kaldırım/yol şeridi,
## girişin hangi yüzde olduğu. Yalnızca görünüş; rastgele sayı üreteci kullanmaz. Ayarlar models.json.

## Bahçe (B4): binanın çevresinde, sokak tarafı hariç, iç halkada çalılar, dış halkada ağaçlar. Konumlar ızgaradan ve
## noktanın kendi özetinden (hash) gelir: her açılışta aynı, rastgele sayı üreteci kullanmaz (yalnızca görünüş).
## Ayarlar models.json "garden".
static func garden(parent: Node3D, layout: OfficeLayout) -> void:
	var cfg: Dictionary = DataDB.data.models.get("garden", {})
	if cfg.is_empty():
		return
	var street: Dictionary = DataDB.data.models["street"]
	var sl: Dictionary = DataDB.data.models["street_layout"]
	var n: Vector2 = OfficeDressing.OUTWARD[entrance_side(layout)]
	var building: Rect2 = Rect2(Vector2.ZERO, layout.size)
	var inner: float = float(cfg["inner"])
	var outer: float = float(cfg["outer"])
	var trees_from: float = float(cfg["trees_from"])
	var step: float = float(cfg["step"])
	var jitter: float = float(cfg["jitter"])
	var street_band: float = float(sl["sidewalk_width"]) + float(sl["road_width"]) + float(cfg["street_keep"])
	var front: float = (layout.size * 0.5).dot(n.abs()) + (layout.size * 0.5).dot(n)
	var x: float = -outer
	while x <= layout.size.x + outer:
		var z: float = -outer
		while z <= layout.size.y + outer:
			var h: int = absi(hash(Vector2i(roundi(x * 10.0), roundi(z * 10.0))))
			var p: Vector2 = Vector2(x, z) + Vector2(float(h % 1000) / 1000.0 - 0.5, float((h / 1000) % 1000) / 1000.0 - 0.5) * jitter
			var dist: float = _rect_distance(building, p)
			var ahead: float = p.dot(n) - front  # binanın ön yüzünden sokağa doğru uzaklık
			if dist >= inner and dist <= outer and not (ahead > -1.0 and ahead < street_band):
				var key: String = "tree" if dist >= trees_from and h % int(cfg["tree_every"]) == 0 else "bush"
				if key == "tree" or h % int(cfg["bush_every"]) == 0:
					var def: Dictionary = street[key]
					var s: float = 0.8 + float((h / 7) % 50) / 100.0
					OfficeDressing.thing(parent, str(def["model"]), p, OfficeDressing._v2(def["size"]) * s, float(def["height"]) * s, OfficeDressing.color_of(def["color"]),
						float(h % 360))
			z += step
		x += step


## Noktanın dikdörtgene uzaklığı (içindeyse 0).
static func _rect_distance(r: Rect2, p: Vector2) -> float:
	var dx: float = maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
	var dz: float = maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
	return Vector2(dx, dz).length()


## Bina önü: kapının iki yanında duvar boyunca çit çalısı (arada top çalı); bina köşelerinin ötesinde tahta çit.
static func greenery(parent: Node3D, layout: OfficeLayout, mid: Vector2, n: Vector2, t: Vector2, edge_len: float, yaw: float) -> void:
	var cfg: Dictionary = DataDB.data.models["street_layout"]
	var street: Dictionary = DataDB.data.models["street"]
	if not street.has("hedge"):
		return
	var off: float = float(cfg["hedge_offset"])
	var step: float = float(cfg["hedge_step"])
	var door: float = (layout.entrance - mid).dot(t)
	var every: int = int(cfg["bush_every"])
	var k: int = 0
	var x: float = -edge_len * 0.5 + step * 0.5
	while x + step * 0.5 <= edge_len * 0.5 + 0.01:
		if absf(x - door) > float(cfg["door_gap"]) + step * 0.5:
			var d: Dictionary = street["bush"] if k % every == every - 1 else street["hedge"]
			OfficeDressing.thing(parent, str(d["model"]), mid + t * x + n * off, OfficeDressing._v2(d["size"]), float(d["height"]), OfficeDressing.color_of(d["color"]), yaw)
			k += 1
		x += step
	var fence: Dictionary = street["fence"]
	var fstep: float = float(cfg["fence_step"])
	for side: float in [-1.0, 1.0]:
		var fx: float = edge_len * 0.5 + fstep * 0.5
		while fx < edge_len * 0.5 + float(cfg["fence_reach"]):
			if side < 0.0 or absf(fx - (edge_len * 0.5 + OfficeDressing.BILLBOARD_GAP)) > 2.6:
				OfficeDressing.thing(parent, str(fence["model"]), mid + t * (side * fx) + n * off, OfficeDressing._v2(fence["size"]), float(fence["height"]),
					OfficeDressing.color_of(fence["color"]), yaw)
			fx += fstep


## surface: look.json "street" içindeki doku adı (sidewalk, road); dosyası yoksa düz renk.
static func strip(parent: Node3D, center: Vector2, along: Vector2, length: float, width: float, y: float, color: Color,
		surface: String = "") -> void:
	var size: Vector3 = Vector3(length, 0.04, width) if along.x > 0.5 else Vector3(width, 0.04, length)
	var strip: MeshInstance3D = OfficeDressing.box(parent, Vector3(center.x, y - 0.02, center.y), size, color)
	var entry: Dictionary = WorldLook.cfg().get("street", {}).get(surface, {})
	if WorldLook.has_surface(entry):
		strip.material_override = WorldLook.surface_material(entry)


static func entrance_side(layout: OfficeLayout) -> String:
	var e: Vector2 = layout.entrance
	var d: Dictionary = {"n": e.y, "s": layout.size.y - e.y, "w": e.x, "e": layout.size.x - e.x}
	var best: String = "s"
	for k: String in d:
		if float(d[k]) < float(d[best]):
			best = k
	return best
