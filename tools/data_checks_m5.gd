extends RefCounted
## M5+ veri kontrolleri (rakipler, ödüller, pitch kartları, ofis yerleşimleri); data_validator.gd 400 satırı aşmasın diye ayrı dosyada.

const LEVELS: Array[String] = ["shortlist", "bronze", "silver", "gold", "grand_prix"]
const CATEGORIES_EXTRA: Array[String] = ["integrated"]


static func check(data: Dictionary, ids: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var balance: Dictionary = data.get("balance.json", {}) if typeof(data.get("balance.json")) == TYPE_DICTIONARY else {}
	var personalities: Dictionary = balance.get("rivals", {}).get("personalities", {})
	for rec: Variant in data.get("rivals.json", []):
		if typeof(rec) != TYPE_DICTIONARY:
			continue
		var id: String = str(rec.get("id", "?"))
		if not personalities.has(str(rec.get("personality", ""))):
			errors.append("rivals.json: '%s' bilinmeyen kişilik '%s'" % [id, str(rec.get("personality", ""))])
		for s: Variant in rec.get("sectors", []):
			if not (ids["sector"] as Array).has(s):
				errors.append("rivals.json: '%s' bilinmeyen sektör '%s'" % [id, str(s)])
	var categories: Array = []
	for ch: Variant in data.get("channels.json", []):
		if typeof(ch) == TYPE_DICTIONARY and not categories.has(ch.get("category")):
			categories.append(ch.get("category"))
	categories.append_array(CATEGORIES_EXTRA)
	for rec: Variant in data.get("awards.json", []):
		if typeof(rec) != TYPE_DICTIONARY:
			continue
		var id: String = str(rec.get("id", "?"))
		var month: int = int(rec.get("month", 0))
		if month < 2 or month > 12:
			errors.append("awards.json: '%s' tören ayı 2..12 olmalı (başvuru bir önceki ay)" % id)
		for field: String in ["categories", "eligible_categories"]:
			for c: Variant in rec.get(field, []):
				if not categories.has(c):
					errors.append("awards.json: '%s' bilinmeyen kategori '%s'" % [id, str(c)])
		for o: Variant in rec.get("eligible_objectives", []):
			if not (ids["objective"] as Array).has(o):
				errors.append("awards.json: '%s' bilinmeyen hedef '%s'" % [id, str(o)])
		for s: Variant in rec.get("eligible_sectors", []):
			if not (ids["sector"] as Array).has(s):
				errors.append("awards.json: '%s' bilinmeyen sektör '%s'" % [id, str(s)])
		var th: Dictionary = rec.get("thresholds", {})
		var last: float = -INF
		for l: String in LEVELS:
			if not th.has(l):
				errors.append("awards.json: '%s' eşik eksik: %s" % [id, l])
				continue
			if float(th[l]) <= last:
				errors.append("awards.json: '%s' eşikler artan sırada olmalı (%s)" % [id, l])
			last = float(th[l])
	for rec: Variant in data.get("pitch_cards.json", []):
		if typeof(rec) != TYPE_DICTIONARY:
			continue
		if not ["opening", "idea", "closing"].has(rec.get("round")):
			errors.append("pitch_cards.json: '%s' tur opening/idea/closing olmalı" % str(rec.get("id", "?")))
		if not ["strategy", "creative"].has(rec.get("stat")):
			errors.append("pitch_cards.json: '%s' stat strategy/creative olmalı" % str(rec.get("id", "?")))
		var keys: Array = (rec.get("prefs", {}) as Dictionary).keys()
		keys.sort()
		if keys != ["budget", "digital", "humor", "risk"]:
			errors.append("pitch_cards.json: '%s' prefs risk/budget/digital/humor olmalı" % str(rec.get("id", "?")))
	var room_types: Array = []
	var effect_keys: Array[String] = ["satisfaction", "focus_mult", "energy_rest_mult", "burnout_recovery_mult", "pitch_mult"]
	for rt: Variant in data.get("room_types.json", []):
		room_types.append(rt.get("id"))
		for k: Variant in (rt.get("effects", {}) as Dictionary).keys():
			if not effect_keys.has(k):
				errors.append("room_types.json: '%s' bilinmeyen etki '%s'" % [str(rt.get("id")), str(k)])
	for f: Variant in data.get("furniture.json", []):
		var sz: Array = f.get("size", [])
		if sz.size() != 2 or fmod(float(sz[0]), 0.5) != 0.0 or fmod(float(sz[1]), 0.5) != 0.0 or float(sz[0]) <= 0.0 or float(sz[1]) <= 0.0:
			errors.append("furniture.json: '%s' boyutu 0.5 m'nin katı olmalı" % str(f.get("id")))
	var layout_ids: Array = []
	for rec: Variant in data.get("office_layouts.json", []):
		if typeof(rec) != TYPE_DICTIONARY:
			continue
		layout_ids.append(rec.get("id"))
		var sz: Array = rec.get("size", [0, 0])
		for room: Variant in rec.get("rooms", []):
			var r: Array = room.get("rect", [])
			if not room_types.has(room.get("type")):
				errors.append("office_layouts.json: '%s' bilinmeyen oda tipi '%s'" % [str(rec.get("id")), str(room.get("type"))])
			if r.size() != 4 or float(r[0]) < 0 or float(r[1]) < 0 or float(r[0]) + float(r[2]) > float(sz[0]) or float(r[1]) + float(r[3]) > float(sz[1]):
				errors.append("office_layouts.json: '%s' oda bina dışına taşıyor" % str(rec.get("id")))
	for off: Variant in data.get("offices.json", []):
		if typeof(off) == TYPE_DICTIONARY and not layout_ids.has(off.get("id")):
			errors.append("office_layouts.json: '%s' için yerleşim yok" % str(off.get("id")))
	var areas: Array = balance.get("tools", {}).get("areas", [])
	for t: Variant in data.get("tools.json", []):
		if typeof(t) != TYPE_DICTIONARY:
			continue
		if not areas.has(t.get("area")):
			errors.append("tools.json: '%s' bilinmeyen alan '%s'" % [str(t.get("id")), str(t.get("area"))])
		var last: int = 0
		for v: Variant in t.get("versions", []):
			if int(v[0]) < last:
				errors.append("tools.json: '%s' sürümler yıla göre sıralı olmalı" % str(t.get("id")))
			last = int(v[0])
		if (t.get("versions", []) as Array).is_empty():
			errors.append("tools.json: '%s' sürüm yok" % str(t.get("id")))
	var focus_map: Dictionary = balance.get("tools", {}).get("focus_area", {})
	for f: Variant in data.get("focus_areas.json", []):
		if typeof(f) == TYPE_DICTIONARY and not areas.has(focus_map.get(f.get("id"))):
			errors.append("balance.json tools.focus_area: '%s' odağının araç alanı yok" % str(f.get("id")))
	return errors
