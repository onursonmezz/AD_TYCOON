extends RefCounted
## M8 veri kontrolleri: model yolları (data/furniture.json "model", data/models.json). Dosyanın var olması
## gerekmez (model yoksa oyun gri kutu çizer); yalnızca yolun biçimi ve kayıtların eksiksizliği denetlenir.

const PROP_KINDS: Array[String] = ["desk", "chair", "counter", "table", "sofa"]
const STREET: Array[String] = ["tree", "lamp", "bench", "billboard"]


static func check(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	for rec: Variant in data.get("furniture.json", []):
		if typeof(rec) == TYPE_DICTIONARY:
			_path(errors, "furniture.json: '%s'" % str(rec.get("id", "?")), rec.get("model"))
	var m: Variant = data.get("models.json")
	if typeof(m) != TYPE_DICTIONARY:
		errors.append("models.json: yok ya da sözlük değil")
		return errors
	if not str(m.get("root", "")).begins_with("res://") or not str(m.get("root", "")).ends_with("/"):
		errors.append("models.json: root 'res://…/' biçiminde olmalı")
	var hardware: Array = []
	for hw: Variant in data.get("hardware.json", []):
		if typeof(hw) == TYPE_DICTIONARY:
			hardware.append(hw.get("id"))
	var groups: Dictionary = {"props": PROP_KINDS, "equipment": hardware, "street": STREET}
	for group: String in groups:
		var g: Dictionary = m.get(group, {})
		for id: Variant in groups[group]:
			if not g.has(id):
				errors.append("models.json: %s.%s eksik" % [group, str(id)])
				continue
			var rec: Dictionary = g[id]
			var where: String = "models.json: %s.%s" % [group, str(id)]
			_path(errors, where, rec.get("model"))
			if not (rec.get("size") is Array and (rec["size"] as Array).size() == 2):
				errors.append("%s size [genişlik, derinlik] olmalı" % where)
			if not (rec.get("color") is Array and (rec["color"] as Array).size() == 3):
				errors.append("%s color [r, g, b] olmalı" % where)
			if float(rec.get("height", 0.0)) <= 0.0:
				errors.append("%s height > 0 olmalı" % where)
	for key: String in ["street_layout", "posters", "limits", "key_visual", "dry_plant_color"]:
		if not m.has(key):
			errors.append("models.json: '%s' eksik" % key)
	var kv: Dictionary = m.get("key_visual", {})
	if (kv.get("palette", []) as Array).size() < 2 or int(kv.get("slogans", 0)) < 1 or int(kv.get("layouts", 0)) < 1:
		errors.append("models.json: key_visual palette ≥ 2, slogans ≥ 1, layouts ≥ 1 olmalı")
	return errors


## Göreli yol: "klasör/ad.glb", küçük harf, Türkçe karakter yok (GDD 21.3, art/pipeline.md).
static func _path(errors: PackedStringArray, where: String, p: Variant) -> void:
	var s: String = str(p) if p != null else ""
	var re: RegEx = RegEx.create_from_string("^[a-z0-9_]+/[a-z0-9_]+\\.(glb|tscn)$")
	if re.search(s) == null:
		errors.append("%s model yolu 'klasör/ad.glb' biçiminde olmalı ('%s')" % [where, s])


## Karakterler (M8-B): her cinsiyetin gövdesi, her gövdeye her yıl en az bir saç ve kıyafet, adlar ve renkler.
static func check_characters(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var ch: Variant = data.get("characters.json")
	if typeof(ch) != TYPE_DICTIONARY:
		errors.append("characters.json: yok ya da sözlük değil")
		return errors
	var bodies: Array = []
	var genders: Array = []
	for b: Dictionary in ch.get("bodies", []):
		bodies.append(b["id"])
		genders.append_array(b.get("genders", []))
		_path(errors, "characters.json: gövde '%s'" % str(b["id"]), b.get("model"))
	for g: String in ["female", "male", "neutral", ""]:
		if not genders.has(g):
			errors.append("characters.json: '%s' cinsiyetine gövde yok" % g)
	for group: String in ["hair", "outfits"]:
		for p: Dictionary in ch.get(group, []):
			var where: String = "characters.json: %s '%s'" % [group, str(p.get("id", "?"))]
			if not (group == "hair" and str(p.get("model", "")).is_empty()):
				_path(errors, where, p.get("model"))
			for b: Variant in p.get("bodies", []):
				if not bodies.has(b):
					errors.append("%s bilinmeyen gövde '%s'" % [where, str(b)])
		for b: Variant in bodies:
			for year: int in range(1990, 2036):
				var found: bool = false
				for p: Dictionary in ch.get(group, []):
					if (p["bodies"] as Array).has(b) and int(p.get("from", 0)) <= year and year <= int(p.get("to", 9999)):
						found = true
						break
				if not found:
					errors.append("characters.json: %s gövdesine %d yılında %s yok" % [str(b), year, group])
					break
	for key: String in ["skin_tones", "hair_colors", "outfit_colors"]:
		if (ch.get(key, []) as Array).is_empty():
			errors.append("characters.json: '%s' boş" % key)
	for a: String in ["idle", "walk"]:
		if not (ch.get("animations", []) as Array).has(a):
			errors.append("characters.json: animations '%s' içermeli" % a)
	return errors
