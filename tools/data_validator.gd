class_name DataValidator
extends RefCounted
## data/ altındaki JSON'ları yükler ve doğrular (GDD 8.0 satır dağılım kuralı + id tutarlılığı).
## Hem tools/validate_data.gd (komut satırı) hem testler bu sınıfı kullanır.

const DEFAULT_DATA_DIR: String = "res://data"
const DataChecksM5: GDScript = preload("res://tools/data_checks_m5.gd")

## Kimlik listesi olan dosyalar: dosya → bu listeye atıf yapan "tip" adı.
const ID_LISTS: Dictionary = {
	"sectors.json": "sector",
	"objectives.json": "objective",
	"audiences.json": "audience",
	"tones.json": "tone",
	"tone_groups.json": "tone_group",
	"focus_areas.json": "focus",
	"channels.json": "channel",
	"combo_rules.json": "combo_rule",
	"positions.json": "position",
	"traits.json": "trait",
	"hiring_channels.json": "hiring_channel",
	"offices.json": "office",
	"backgrounds.json": "background",
	"suppliers.json": "supplier",
	"rivals.json": "rival",
	"awards.json": "award",
	"pitch_cards.json": "pitch_card",
	"office_layouts.json": "office_layout",
	"furniture.json": "furniture",
	"room_types.json": "room_type",
	"tools.json": "tool",
	"hardware.json": "hardware",
	"eras.json": "era",
}
const FIT_FILES: Array[String] = [
	"fit/sector_objective.json",
	"fit/sector_audience.json",
	"fit/tone_fit.json",
	"fit/channel_fit.json",
]
const FIT_MIN: int = -3
const FIT_MAX: int = 3
const VIRAL_MAX: int = 3
const ID_PATTERN: String = "^[a-z0-9_]+$"

var _errors: PackedStringArray = PackedStringArray()


## Klasördeki tüm .json dosyalarını (alt klasörler dahil) yükler.
## Dönüş: { "fit/tone_fit.json": <ayrıştırılmış veri>, ... }. Ayrıştırma hataları errors'a eklenir.
func load_dir(root: String) -> Dictionary:
	var data: Dictionary = {}
	_load_dir_recursive(root, "", data)
	return data


## Yüklenmiş veriyi doğrular; bulunan hataları döndürür (boş = geçerli).
func validate(data: Dictionary) -> PackedStringArray:
	var ids: Dictionary = {}
	for file_name: String in ID_LISTS:
		ids[ID_LISTS[file_name]] = _check_id_list(data, file_name)
	_check_balance(data)
	_check_sectors(data, ids)
	_check_objectives(data, ids)
	_check_channels(data)
	_check_combo_rules(data, ids)
	_check_calendar(data, ids)
	_check_brands(data, ids)
	_check_staff_data(data, ids)
	_check_print_data(data)
	for e: String in DataChecksM5.check(data, ids):
		_err(e)
	var rules: Dictionary = _parse_row_rules(data)
	for file_name: String in FIT_FILES:
		_check_fit_file(data, file_name, ids, rules)
	return _errors


## Yükle + doğrula. Tek çağrıda tüm hatalar.
func validate_dir(root: String = DEFAULT_DATA_DIR) -> PackedStringArray:
	_errors = PackedStringArray()
	var data: Dictionary = load_dir(root)
	return validate(data)


## "1x+3, 1x(+1|+2), ..." → [{ "count": 1, "values": [3] }, { "count": 1, "values": [1, 2] }, ...]
static func parse_row_rule(rule_text: String) -> Array[Dictionary]:
	var parts: Array[Dictionary] = []
	for raw: String in rule_text.split(","):
		var part: String = raw.strip_edges()
		var x_pos: int = part.find("x")
		if x_pos <= 0:
			return []
		var count_text: String = part.substr(0, x_pos)
		var values_text: String = part.substr(x_pos + 1).trim_prefix("(").trim_suffix(")")
		if not count_text.is_valid_int():
			return []
		var values: Array[int] = []
		for value_text: String in values_text.split("|"):
			var clean: String = value_text.strip_edges().trim_prefix("+")
			if not clean.is_valid_int():
				return []
			values.append(clean.to_int())
		parts.append({"count": count_text.to_int(), "values": values})
	return parts


## Bir satırın kurala uyup uymadığını kontrol eder. Dönüş: boş = uyuyor, aksi halde açıklama.
static func check_row_against_rule(row_values: Array[int], rule: Array[Dictionary]) -> String:
	var expected_total: int = 0
	for part: Dictionary in rule:
		expected_total += int(part["count"])
	if row_values.size() != expected_total:
		return "%d değer var, kural %d istiyor" % [row_values.size(), expected_total]
	var problems: PackedStringArray = PackedStringArray()
	for part: Dictionary in rule:
		var allowed: Array = part["values"]
		var found: int = 0
		for v: int in row_values:
			if allowed.has(v):
				found += 1
		if found != int(part["count"]):
			problems.append("%s kümesinden %d adet olmalı, %d var" % [_symbols(allowed), int(part["count"]), found])
	return "; ".join(problems)


static func value_to_symbol(v: int) -> String:
	match v:
		3: return "+++"
		2: return "++"
		1: return "+"
		0: return "~"
		-1: return "−"
		-2: return "−−"
		-3: return "−−−"
	return str(v)


static func _symbols(values: Array) -> String:
	var out: PackedStringArray = PackedStringArray()
	for v: int in values:
		out.append(value_to_symbol(v))
	return "{" + "|".join(out) + "}"


# --- yükleme -----------------------------------------------------------------

func _load_dir_recursive(root: String, rel: String, out: Dictionary) -> void:
	var dir_path: String = root if rel.is_empty() else root.path_join(rel)
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		_err("Klasör açılamadı: %s" % dir_path)
		return
	for sub: String in dir.get_directories():
		_load_dir_recursive(root, sub if rel.is_empty() else rel.path_join(sub), out)
	for file_name: String in dir.get_files():
		if file_name.get_extension() != "json":
			continue
		var key: String = file_name if rel.is_empty() else rel.path_join(file_name)
		var text: String = FileAccess.get_file_as_string(dir_path.path_join(file_name))
		var json: JSON = JSON.new()
		if json.parse(text) != OK:
			_err("%s: JSON hatası, satır %d: %s" % [key, json.get_error_line(), json.get_error_message()])
			continue
		out[key] = json.data


# --- kontroller --------------------------------------------------------------

func _check_id_list(data: Dictionary, file_name: String) -> Array[String]:
	var ids: Array[String] = []
	if not data.has(file_name):
		_err("%s eksik" % file_name)
		return ids
	var list: Variant = data[file_name]
	if typeof(list) != TYPE_ARRAY:
		_err("%s: kayıt listesi (dizi) olmalı" % file_name)
		return ids
	var id_regex: RegEx = RegEx.create_from_string(ID_PATTERN)
	for i: int in (list as Array).size():
		var rec: Variant = list[i]
		if typeof(rec) != TYPE_DICTIONARY or typeof(rec.get("id")) != TYPE_STRING:
			_err("%s[%d]: 'id' alanı olan bir nesne olmalı" % [file_name, i])
			continue
		var id: String = rec["id"]
		if id_regex.search(id) == null:
			_err("%s: geçersiz id '%s' (küçük harf, rakam, alt çizgi)" % [file_name, id])
		if ids.has(id):
			_err("%s: tekrar eden id '%s'" % [file_name, id])
		ids.append(id)
		if typeof(rec.get("name_key")) != TYPE_STRING:
			_err("%s: '%s' için name_key eksik" % [file_name, id])
	return ids


func _check_balance(data: Dictionary) -> void:
	if not data.has("balance.json") or typeof(data["balance.json"]) != TYPE_DICTIONARY:
		_err("balance.json eksik veya nesne değil")


func _check_sectors(data: Dictionary, ids: Dictionary) -> void:
	for rec: Dictionary in _records(data, "sectors.json"):
		var id: String = str(rec.get("id"))
		if not _is_int(rec.get("available_from")):
			_err("sectors.json: '%s' available_from tam sayı olmalı" % id)
		if not (ids["tone_group"] as Array).has(rec.get("tone_group")):
			_err("sectors.json: '%s' bilinmeyen tone_group '%s'" % [id, str(rec.get("tone_group"))])
		var basket: Variant = rec.get("avg_basket")
		if not (typeof(basket) == TYPE_FLOAT or typeof(basket) == TYPE_INT) or float(basket) <= 0.0:
			_err("sectors.json: '%s' avg_basket pozitif sayı olmalı" % id)


func _check_objectives(data: Dictionary, ids: Dictionary) -> void:
	var focus_ids: Array = ids["focus"]
	for rec: Dictionary in _records(data, "objectives.json"):
		var id: String = str(rec.get("id"))
		var sk: Variant = rec.get("ideal_sk")
		if not (typeof(sk) == TYPE_FLOAT or typeof(sk) == TYPE_INT) or float(sk) <= 0.0:
			_err("objectives.json: '%s' ideal_sk pozitif sayı olmalı" % id)
		var imp: Variant = rec.get("focus_importance")
		if typeof(imp) != TYPE_DICTIONARY:
			_err("objectives.json: '%s' focus_importance eksik" % id)
			continue
		_check_keys_match("objectives.json '%s' focus_importance" % id, (imp as Dictionary).keys(), focus_ids)
		for k: Variant in imp:
			if not _is_fit_value(imp[k]):
				_err("objectives.json: '%s'.%s değeri −3..+3 tam sayı olmalı" % [id, str(k)])


func _check_channels(data: Dictionary) -> void:
	for rec: Dictionary in _records(data, "channels.json"):
		var id: String = str(rec.get("id"))
		if not _is_int(rec.get("available_from")):
			_err("channels.json: '%s' available_from tam sayı olmalı" % id)
		if not _is_int(rec.get("min_budget")) or int(rec.get("min_budget")) < 0:
			_err("channels.json: '%s' min_budget ≥ 0 tam sayı olmalı" % id)
		var viral: Variant = rec.get("viral")
		if not _is_int(viral) or int(viral) < 0 or int(viral) > VIRAL_MAX:
			_err("channels.json: '%s' viral 0..%d olmalı" % [id, VIRAL_MAX])
		if typeof(rec.get("category")) != TYPE_STRING:
			_err("channels.json: '%s' category eksik" % id)
		if rec.has("interest_curve"):
			_check_curve(id, rec["interest_curve"])


func _check_curve(id: String, curve: Variant) -> void:
	if typeof(curve) != TYPE_ARRAY or (curve as Array).is_empty():
		_err("channels.json: '%s' interest_curve boş olmayan dizi olmalı" % id)
		return
	var last_year: int = -1
	for point: Variant in curve:
		if typeof(point) != TYPE_ARRAY or (point as Array).size() != 2 or not _is_int(point[0]):
			_err("channels.json: '%s' interest_curve noktaları [yıl, değer] olmalı" % id)
			return
		var year: int = int(point[0])
		var value: float = float(point[1])
		if year <= last_year:
			_err("channels.json: '%s' interest_curve yılları artan sırada olmalı" % id)
		if value < 0.0 or value > 1.0:
			_err("channels.json: '%s' interest_curve değeri 0..1 olmalı (%s)" % [id, str(value)])
		last_year = year


func _check_combo_rules(data: Dictionary, ids: Dictionary) -> void:
	for rec: Dictionary in _records(data, "combo_rules.json"):
		var objectives: Variant = rec.get("objectives")
		if typeof(objectives) != TYPE_ARRAY:
			_err("combo_rules.json: '%s' objectives dizisi eksik" % str(rec.get("id")))
			continue
		for obj: Variant in objectives:
			if not (ids["objective"] as Array).has(obj):
				_err("combo_rules.json: '%s' bilinmeyen hedef '%s'" % [str(rec.get("id")), str(obj)])


func _check_calendar(data: Dictionary, ids: Dictionary) -> void:
	var cal: Variant = data.get("calendar.json")
	if typeof(cal) != TYPE_DICTIONARY:
		_err("calendar.json eksik veya nesne değil")
		return
	for season: Variant in cal.get("seasons", []):
		var sid: String = str(season.get("id"))
		for sector: Variant in season.get("sectors", []):
			if not (ids["sector"] as Array).has(sector):
				_err("calendar.json: '%s' bilinmeyen sektör '%s'" % [sid, str(sector)])
		for m: Variant in season.get("months", []):
			if not _is_int(m) or int(m) < 1 or int(m) > 12:
				_err("calendar.json: '%s' ay 1..12 olmalı" % sid)


func _check_brands(data: Dictionary, ids: Dictionary) -> void:
	var parts: Variant = data.get("brands/name_parts.json")
	if typeof(parts) != TYPE_DICTIONARY or typeof(parts.get("suffixes")) != TYPE_DICTIONARY:
		_err("brands/name_parts.json eksik veya 'suffixes' yok")
	else:
		_check_keys_match("brands/name_parts.json suffixes", (parts["suffixes"] as Dictionary).keys(), ids["sector"])
	var hand: Variant = data.get("brands/handcrafted_brands.json")
	if typeof(hand) != TYPE_ARRAY:
		_err("brands/handcrafted_brands.json eksik")
		return
	for rec: Variant in hand:
		if not (ids["sector"] as Array).has(rec.get("sector")):
			_err("handcrafted_brands.json: '%s' bilinmeyen sektör" % str(rec.get("id")))


## Pozisyon uzman alanları ve statlar geçerli mi; geçmişlerin statları tam mı; isim listeleri var mı (M3).
func _check_staff_data(data: Dictionary, ids: Dictionary) -> void:
	var balance: Variant = data.get("balance.json")
	var stats: Array = balance.get("staff_rules", {}).get("stats", []) if typeof(balance) == TYPE_DICTIONARY else []
	for rec: Dictionary in _records(data, "positions.json"):
		for f: Variant in rec.get("specialty_focus", []):
			if not (ids["focus"] as Array).has(f):
				_err("positions.json: '%s' bilinmeyen odak alanı '%s'" % [str(rec["id"]), str(f)])
		for s: Variant in rec.get("primary_stats", []):
			if not stats.has(s):
				_err("positions.json: '%s' bilinmeyen stat '%s'" % [str(rec["id"]), str(s)])
		if (rec.get("title_keys", []) as Array).is_empty():
			_err("positions.json: '%s' unvan listesi boş" % str(rec["id"]))
	for rec: Dictionary in _records(data, "backgrounds.json"):
		_check_keys_match("backgrounds.json '%s' stats" % str(rec["id"]), (rec.get("stats", {}) as Dictionary).keys(), stats)
	for file_name: String in ["names_tr.json", "names_en.json"]:
		var n: Variant = data.get(file_name)
		if typeof(n) != TYPE_DICTIONARY or (n.get("surnames", []) as Array).is_empty():
			_err("%s eksik veya soyad listesi boş" % file_name)


## Basılı iş verisi: kanalların ürünleri var mı, ürünlerin dağıtımları tanımlı mı (M4).
func _check_print_data(data: Dictionary) -> void:
	var opts: Variant = data.get("print_options.json")
	if typeof(opts) != TYPE_DICTIONARY:
		_err("print_options.json eksik")
		return
	var products: Array = []
	var dists: Array = []
	for d: Dictionary in opts.get("distributions", []):
		dists.append(d["id"])
	for p: Dictionary in opts.get("products", []):
		products.append(p["id"])
		for d: Variant in p.get("distributions", []):
			if not dists.has(d):
				_err("print_options.json: '%s' bilinmeyen dağıtım '%s'" % [str(p["id"]), str(d)])
		if float(p.get("min_quantity", 0)) > float(p.get("max_quantity", 0)):
			_err("print_options.json: '%s' min adet max adetten büyük" % str(p["id"]))
	for ch: Dictionary in _records(data, "channels.json"):
		for p: Variant in ch.get("print_products", []):
			if not products.has(p):
				_err("channels.json: '%s' bilinmeyen basılı ürün '%s'" % [str(ch["id"]), str(p)])


func _parse_row_rules(data: Dictionary) -> Dictionary:
	var rules: Dictionary = {}
	var balance: Variant = data.get("balance.json")
	if typeof(balance) != TYPE_DICTIONARY or typeof(balance.get("fit_row_rules")) != TYPE_DICTIONARY:
		_err("balance.json: fit_row_rules eksik")
		return rules
	var raw: Dictionary = balance["fit_row_rules"]
	for rule_name: Variant in raw:
		var parsed: Array[Dictionary] = parse_row_rule(str(raw[rule_name]))
		if parsed.is_empty():
			_err("balance.json: fit_row_rules.%s okunamadı: '%s'" % [str(rule_name), str(raw[rule_name])])
			continue
		rules[rule_name] = parsed
	return rules


func _check_fit_file(data: Dictionary, file_name: String, ids: Dictionary, rules: Dictionary) -> void:
	if not data.has(file_name):
		_err("%s eksik" % file_name)
		return
	var fit: Variant = data[file_name]
	if typeof(fit) != TYPE_DICTIONARY or typeof(fit.get("tables")) != TYPE_DICTIONARY:
		_err("%s: 'row_type' ve 'tables' alanları olmalı" % file_name)
		return
	var row_type: String = str(fit.get("row_type"))
	if not ids.has(row_type):
		_err("%s: bilinmeyen row_type '%s'" % [file_name, row_type])
		return
	var row_ids: Array = ids[row_type]
	var tables: Dictionary = fit["tables"]
	for table_name: Variant in tables:
		var where: String = "%s/%s" % [file_name, str(table_name)]
		var table: Variant = tables[table_name]
		if typeof(table) != TYPE_DICTIONARY or typeof(table.get("values")) != TYPE_DICTIONARY:
			_err("%s: 'column_type', 'rule', 'values' alanları olmalı" % where)
			continue
		var column_type: String = str(table.get("column_type"))
		if not ids.has(column_type):
			_err("%s: bilinmeyen column_type '%s'" % [where, column_type])
			continue
		var rule_name: String = str(table.get("rule"))
		if not rules.has(rule_name):
			_err("%s: bilinmeyen kural '%s'" % [where, rule_name])
			continue
		var column_ids: Array = ids[column_type]
		var values: Dictionary = table["values"]
		_check_keys_match(where + " satırları", values.keys(), row_ids)
		for row_id: Variant in values:
			_check_fit_row(where, str(row_id), values[row_id], column_ids, rules[rule_name])


func _check_fit_row(where: String, row_id: String, row: Variant, column_ids: Array, rule: Array[Dictionary]) -> void:
	if typeof(row) != TYPE_DICTIONARY:
		_err("%s: '%s' satırı nesne olmalı" % [where, row_id])
		return
	_check_keys_match("%s '%s' sütunları" % [where, row_id], (row as Dictionary).keys(), column_ids)
	var row_values: Array[int] = []
	for col: Variant in row:
		if not _is_fit_value(row[col]):
			_err("%s: '%s'.%s değeri −3..+3 tam sayı olmalı" % [where, row_id, str(col)])
			return
		row_values.append(int(row[col]))
	var problem: String = check_row_against_rule(row_values, rule)
	if not problem.is_empty():
		_err("%s: '%s' satırı dağılım kuralını bozuyor (GDD 8.0): %s" % [where, row_id, problem])


# --- yardımcılar -------------------------------------------------------------

func _records(data: Dictionary, file_name: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var list: Variant = data.get(file_name)
	if typeof(list) != TYPE_ARRAY:
		return out
	for rec: Variant in list:
		if typeof(rec) == TYPE_DICTIONARY:
			out.append(rec)
	return out


func _check_keys_match(where: String, actual: Array, expected: Array) -> void:
	for k: Variant in expected:
		if not actual.has(k):
			_err("%s: '%s' eksik" % [where, str(k)])
	for k: Variant in actual:
		if not expected.has(k):
			_err("%s: bilinmeyen '%s'" % [where, str(k)])


## JSON sayıları Godot'da float gelir; tam sayı olup olmadığını değerden anlarız.
func _is_int(v: Variant) -> bool:
	if typeof(v) == TYPE_INT:
		return true
	return typeof(v) == TYPE_FLOAT and is_equal_approx(float(v), roundf(float(v)))


func _is_fit_value(v: Variant) -> bool:
	return _is_int(v) and int(v) >= FIT_MIN and int(v) <= FIT_MAX


func _err(message: String) -> void:
	_errors.append(message)
