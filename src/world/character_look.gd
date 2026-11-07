class_name CharacterLook
extends RefCounted
## Çalışanın görünüşü (M8-B, GDD 21.3 modüler karakter): gövde, saç, kıyafet ve renkler çalışanın kimliğinden
## türetilir; aynı çalışan her açılışta aynı görünür. Kıyafet ve bazı saçlar döneme bağlıdır (90'lar vatkalı ceket…).
## Saf veri (Node'suz); testler doğrudan çağırır.


## hire_year: çalışanın işe alındığı yıl (kadro karakteri seçimi, K-090); -1 ise kadro kullanılmaz.
static func make(data: GameData, emp: Dictionary, year: int, hire_year: int = -1) -> Dictionary:
	var ch: Dictionary = data.characters
	var seed: int = absi(str(emp.get("id", "")).hash())
	var body: Dictionary = ch["bodies"][ch["bodies"].size() - 1]
	for b: Dictionary in ch["bodies"]:
		if (b["genders"] as Array).has(str(emp.get("gender", ""))):
			body = b
			break
	var hair: Dictionary = _pick(_fitting(ch["hair"], body["id"], year), _mix(seed, 1))
	var outfit: Dictionary = _pick(_fitting(ch["outfits"], body["id"], year), _mix(seed, 2))
	var outfit_color: Array = ch["outfit_colors"][_mix(seed, 3) % (ch["outfit_colors"] as Array).size()]
	if bool(emp.get("is_founder", false)):
		outfit_color = ch["founder_outfit_color"]
	var cast: Dictionary = _cast(ch, str(emp.get("gender", "")), hire_year, seed) if hire_year >= 0 else {}
	return {
		"cast": str(cast.get("id", "")), "cast_model": str(cast.get("model", "")),
		"body": body["id"], "body_model": str(body["model"]),
		"hair": str(hair.get("id", "")), "hair_model": str(hair.get("model", "")),
		"outfit": str(outfit.get("id", "")), "outfit_model": str(outfit.get("model", "")),
		"skin": _color(ch["skin_tones"][_mix(seed, 4) % (ch["skin_tones"] as Array).size()]),
		"hair_color": _color(ch["hair_colors"][_mix(seed, 5) % (ch["hair_colors"] as Array).size()]),
		"outfit_color": _color(outfit_color),
		"bald": str(hair.get("model", "x")).is_empty(),
	}


## Kadro karakteri (Tripo): aynı cinsiyetten ve işe alındığı yıla uyanlar. Nötr ya da cinsiyetsiz (kurucu) çalışan için
## nötr yoksa o dönemin herhangi biri. Uygun yoksa boş: parçalı karakter.
static func _cast(ch: Dictionary, gender: String, hire_year: int, seed: int) -> Dictionary:
	var same: Array = []
	var era: Array = []
	for c: Dictionary in ch.get("cast", []):
		if int(c["from"]) <= hire_year and hire_year <= int(c["to"]):
			era.append(c)
			if str(c["gender"]) == gender:
				same.append(c)
	var pool: Array = same if not same.is_empty() or gender in ["female", "male"] else era
	return _pick(pool, _mix(seed, 6))


## Çalışanın işe alındığı yıl.
static func hire_year(clock: SimClock, emp: Dictionary) -> int:
	return clock.start_year + int(emp.get("hired_week", 0)) / clock.weeks_per_year()


## Ardışık kimlikler (em_0001, em_0002…) neredeyse ardışık özet verir; her seçim için sayıyı karıştır (C1).
static func _mix(seed: int, salt: int) -> int:
	var x: int = (seed + salt * 0x9E3779B9) & 0xFFFFFFFF
	x = ((x ^ (x >> 16)) * 0x45D9F3B) & 0xFFFFFFFF
	x = ((x ^ (x >> 16)) * 0x45D9F3B) & 0xFFFFFFFF
	return x ^ (x >> 16)


## Gövdeye uyan ve o yıl giyilen parçalar.
static func _fitting(parts: Array, body_id: String, year: int) -> Array:
	var out: Array = []
	for p: Dictionary in parts:
		if (p["bodies"] as Array).has(body_id) and int(p.get("from", 0)) <= year and year <= int(p.get("to", 9999)):
			out.append(p)
	return out


static func _pick(list: Array, n: int) -> Dictionary:
	return list[n % list.size()] if not list.is_empty() else {}


static func _color(a: Array) -> Color:
	return Color(float(a[0]), float(a[1]), float(a[2]))


## Görünüşün değiştiğini anlamak için kısa imza (dönem değişince kıyafet değişir).
static func signature(look: Dictionary) -> String:
	return "%s|%s|%s|%s" % [look.get("cast", ""), look["body"], look["hair"], look["outfit"]]
