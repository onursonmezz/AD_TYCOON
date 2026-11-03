extends RefCounted
## M5 veri kontrolleri (rakipler, ödüller); data_validator.gd 400 satırı aşmasın diye ayrı dosyada.

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
	return errors
