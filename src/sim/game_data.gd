class_name GameData
extends RefCounted
## Simülasyonun salt-okunur veri kaynağı: data/*.json'ları yükler, doğrular, hızlı erişim sözlükleri kurar.
## Node'a bağımlı değildir; M2'de DataDB autoload'u bunu saracak.

const DataValidatorScript: GDScript = preload("res://tools/data_validator.gd")

var errors: PackedStringArray = PackedStringArray()
var raw: Dictionary = {}
var balance: Dictionary = {}

var sectors: Dictionary = {}
var objectives: Dictionary = {}
var audiences: Dictionary = {}
var tones: Dictionary = {}
var channels: Dictionary = {}
var focus_areas: Dictionary = {}

var sector_ids: Array[String] = []
var objective_ids: Array[String] = []
var audience_ids: Array[String] = []
var tone_ids: Array[String] = []
var channel_ids: Array[String] = []
var focus_ids: Array[String] = []

var positions: Dictionary = {}
var traits: Dictionary = {}
var hiring_channels: Dictionary = {}
var offices: Dictionary = {}
var backgrounds: Dictionary = {}
var position_ids: Array[String] = []
var trait_ids: Array[String] = []
var hiring_channel_ids: Array[String] = []
var background_ids: Array[String] = []

var calendar: Dictionary = {}
var name_parts: Dictionary = {}
var handcrafted_brands: Array = []

var _fit: Dictionary = {}


## Veriyi yükler. Hata varsa errors doludur; simülasyon başlatılmamalıdır.
static func load_from(root: String = DataValidatorScript.DEFAULT_DATA_DIR) -> GameData:
	var data: GameData = GameData.new()
	var validator: DataValidator = DataValidatorScript.new()
	data.raw = validator.load_dir(root)
	data.errors = validator.validate(data.raw)
	if data.errors.is_empty():
		data._index()
	return data


## balance.json içinden noktalı yol ile değer okur: bal("score.era_base"). Eksikse hata basar.
func bal(path: String) -> Variant:
	var node: Variant = balance
	for key: String in path.split("."):
		if typeof(node) != TYPE_DICTIONARY or not (node as Dictionary).has(key):
			push_error("balance.json: '%s' bulunamadı" % path)
			return null
		node = node[key]
	return node


func balf(path: String) -> float:
	return float(bal(path))


func bali(path: String) -> int:
	return int(bal(path))


## Uyum değeri (−3..+3). table: "sector_objective", "sector_audience", "tone", "channel_objective", "channel_audience".
func fit(table: String, row_id: String, column_id: String) -> int:
	return int(_fit[table][row_id][column_id])


func focus_importance(objective_id: String, focus_id: String) -> int:
	return int(objectives[objective_id]["focus_importance"][focus_id])


func focus_ids_of_phase(phase: int) -> Array[String]:
	var phase_name: String = ["strategy", "creative", "production"][phase]
	var out: Array[String] = []
	for id: String in focus_ids:
		if focus_areas[id]["phase"] == phase_name:
			out.append(id)
	return out


## Kanalın KPI parametresi: kanalda varsa onu, yoksa kanal türünün varsayılanını kullanır (K-020).
func channel_param(channel_id: String, key: String) -> float:
	var ch: Dictionary = channels[channel_id]
	var own_key: String = "base_" + key
	if ch.has(own_key):
		return float(ch[own_key])
	return float(bal("kpi.category_defaults")[ch["category"]][key])


func channel_audience_size(channel_id: String, audience_id: String) -> float:
	var ch: Dictionary = channels[channel_id]
	if ch.has("audience_size"):
		return float(ch["audience_size"].get(audience_id, 1.0))
	return 1.0


## Ofis seviyesi (1..5) → offices.json kaydı.
func office(level: int) -> Dictionary:
	return offices.get("office_%d" % level, {})


func max_office_level() -> int:
	return offices.size()


## Dil başına isim listesi (GDD 24.5): names_tr.json / names_en.json.
func names(lang: String) -> Dictionary:
	return raw.get("names_%s.json" % lang, raw.get("names_tr.json", {}))


func channels_available(year: int) -> Array[String]:
	var out: Array[String] = []
	for id: String in channel_ids:
		if int(channels[id]["available_from"]) <= year:
			out.append(id)
	return out


func sectors_available(year: int) -> Array[String]:
	var out: Array[String] = []
	for id: String in sector_ids:
		if int(sectors[id]["available_from"]) <= year:
			out.append(id)
	return out


# --- iç ---------------------------------------------------------------------

func _index() -> void:
	balance = raw["balance.json"]
	_index_list("sectors.json", sectors, sector_ids)
	_index_list("objectives.json", objectives, objective_ids)
	_index_list("audiences.json", audiences, audience_ids)
	_index_list("tones.json", tones, tone_ids)
	_index_list("channels.json", channels, channel_ids)
	_index_list("focus_areas.json", focus_areas, focus_ids)
	_fit["sector_objective"] = raw["fit/sector_objective.json"]["tables"]["objective"]["values"]
	_fit["sector_audience"] = raw["fit/sector_audience.json"]["tables"]["audience"]["values"]
	_fit["tone"] = raw["fit/tone_fit.json"]["tables"]["tone"]["values"]
	_fit["channel_objective"] = raw["fit/channel_fit.json"]["tables"]["objective"]["values"]
	_fit["channel_audience"] = raw["fit/channel_fit.json"]["tables"]["audience"]["values"]
	_index_list("positions.json", positions, position_ids)
	_index_list("traits.json", traits, trait_ids)
	_index_list("hiring_channels.json", hiring_channels, hiring_channel_ids)
	_index_list("backgrounds.json", backgrounds, background_ids)
	var office_ids: Array[String] = []
	_index_list("offices.json", offices, office_ids)
	calendar = raw.get("calendar.json", {})
	name_parts = raw.get("brands/name_parts.json", {})
	handcrafted_brands = raw.get("brands/handcrafted_brands.json", [])


func _index_list(file_name: String, out: Dictionary, ids: Array[String]) -> void:
	for rec: Dictionary in raw[file_name]:
		out[rec["id"]] = rec
		ids.append(str(rec["id"]))
