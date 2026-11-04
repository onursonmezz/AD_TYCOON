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
