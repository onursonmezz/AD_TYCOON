class_name OfficeWalls
extends RefCounted
## Düzenlenebilir iç duvarlar (K-116). Her iç duvar düz bir çizginin üstünde bir aralıktır: yatay çizgi "h:<z>",
## dikey çizgi "v:<x>"; değer [[t0, t1], ...] (sıralı, birleşik). Oyuncunun duvar işlemleri (state.build "wall_ops")
## hazır duvarların üstüne sırayla uygulanır: "add" ekler, "remove" siler, "door" kapı boşluğu açar.
## Dış duvarlar buraya girmez; onlara dokunulamaz. Saf veri, düğüm yok.

const EPS: float = 0.01


## a–b ekseni hizalı mı? Değilse {}; ise { "key", "t0", "t1" } (t0 < t1).
static func seg(a: Vector2, b: Vector2) -> Dictionary:
	if absf(a.y - b.y) < EPS:
		return {"key": "h:%.2f" % a.y, "t0": minf(a.x, b.x), "t1": maxf(a.x, b.x)}
	if absf(a.x - b.x) < EPS:
		return {"key": "v:%.2f" % a.x, "t0": minf(a.y, b.y), "t1": maxf(a.y, b.y)}
	return {}


## Çizgi anahtarı + aralık → uç noktalar.
static func ends(key: String, t0: float, t1: float) -> Array[Vector2]:
	var c: float = float(key.substr(2))
	if key.begins_with("h"):
		return [Vector2(t0, c), Vector2(t1, c)]
	return [Vector2(c, t0), Vector2(c, t1)]


## Duvar listesinden (yalnız iç duvarlar) çizgi tablosu.
static func lines_from(walls: Array) -> Dictionary:
	var lines: Dictionary = {}
	for w: Dictionary in walls:
		var s: Dictionary = seg(w["a"], w["b"])
		if not s.is_empty():
			add(lines, s["key"], s["t0"], s["t1"])
	return lines


static func add(lines: Dictionary, key: String, t0: float, t1: float) -> void:
	var list: Array = lines.get(key, [])
	list.append([t0, t1])
	list.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
	var merged: Array = []
	for iv: Array in list:
		if not merged.is_empty() and float(iv[0]) <= float(merged[-1][1]) + EPS:
			merged[-1][1] = maxf(float(merged[-1][1]), float(iv[1]))
		else:
			merged.append([float(iv[0]), float(iv[1])])
	lines[key] = merged


static func subtract(lines: Dictionary, key: String, t0: float, t1: float) -> void:
	if not lines.has(key):
		return
	var out: Array = []
	for iv: Array in lines[key]:
		var a: float = float(iv[0])
		var b: float = float(iv[1])
		if b <= t0 + EPS or a >= t1 - EPS:
			out.append([a, b])
			continue
		if a < t0 - EPS:
			out.append([a, t0])
		if b > t1 + EPS:
			out.append([t1, b])
	if out.is_empty():
		lines.erase(key)
	else:
		lines[key] = out


## İşlem: { "op": "add"|"remove"|"door", "a": [x, z], "b": [x, z] } (kapıda a–b kapı boşluğunun iki ucu).
static func apply(lines: Dictionary, ops: Array) -> void:
	for op: Dictionary in ops:
		var s: Dictionary = seg(_v(op["a"]), _v(op["b"]))
		if s.is_empty():
			continue
		if str(op["op"]) == "add":
			add(lines, s["key"], s["t0"], s["t1"])
		else:
			subtract(lines, s["key"], s["t0"], s["t1"])


static func _v(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


## Çizgi tablosu → duvar sözlükleri (OfficeLayout.walls biçiminde, iç duvar).
static func to_walls(lines: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for key: String in lines:
		for iv: Array in lines[key]:
			if float(iv[1]) - float(iv[0]) < EPS:
				continue
			var e: Array[Vector2] = ends(key, float(iv[0]), float(iv[1]))
			out.append({"a": e[0], "b": e[1], "outer": false, "side": "n" if key.begins_with("h") else "w"})
	return out


## a–b boyunca duvarla kaplı uzunluk.
static func covered(lines: Dictionary, a: Vector2, b: Vector2) -> float:
	var s: Dictionary = seg(a, b)
	if s.is_empty() or not lines.has(s["key"]):
		return 0.0
	var total: float = 0.0
	for iv: Array in lines[s["key"]]:
		total += maxf(0.0, minf(float(iv[1]), s["t1"]) - maxf(float(iv[0]), s["t0"]))
	return total


## Noktaya en yakın duvar parçası (tol metre içinde): { "a", "b", "key", "t" (noktanın çizgideki yeri) }; yoksa {}.
static func segment_at(lines: Dictionary, p: Vector2, tol: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = tol
	for key: String in lines:
		var c: float = float(key.substr(2))
		var horizontal: bool = key.begins_with("h")
		var t: float = p.x if horizontal else p.y
		var d: float = absf((p.y if horizontal else p.x) - c)
		if d > best_d:
			continue
		for iv: Array in lines[key]:
			if t >= float(iv[0]) - EPS and t <= float(iv[1]) + EPS:
				var e: Array[Vector2] = ends(key, float(iv[0]), float(iv[1]))
				best = {"a": e[0], "b": e[1], "key": key, "t": t}
				best_d = d
	return best


## Oyuncunun kendi çektiği (parası ödenmiş) duvar uzunlukları: eklenenler, sonra silinen / kapı açılan yerler düşülür.
static func owned(ops: Array) -> Dictionary:
	var lines: Dictionary = {}
	apply(lines, ops)
	return lines


## Toplam uzunluk.
static func length(lines: Dictionary) -> float:
	var total: float = 0.0
	for key: String in lines:
		for iv: Array in lines[key]:
			total += float(iv[1]) - float(iv[0])
	return total
