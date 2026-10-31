class_name SaveCodec
extends RefCounted
## Kayıt biçimi (GDD 24.3, 24.5): sürüm numaralı JSON, sürüm göçü (migration) fonksiyonları.
## Dosya işlemleri SaveSystem autoload'undadır; bu sınıf saf dönüşüm yapar (test edilebilir).

const SAVE_VERSION: int = 1


static func encode(sim: Simulation) -> String:
	var doc: Dictionary = {"save_version": SAVE_VERSION, "state": sim.state.to_dict()}
	return JSON.stringify(doc, "", true, true)


## Dönüş: yüklenmiş Simulation; hata varsa null (error_out'a açıklama yazılır).
static func decode(data: GameData, text: String, error_out: Array[String] = []) -> Simulation:
	var json: JSON = JSON.new()
	var parsed: Variant = json.data if json.parse(text) == OK else null
	if typeof(parsed) != TYPE_DICTIONARY:
		error_out.append("ERR_SAVE_CORRUPT")
		return null
	var doc: Dictionary = migrate(parsed)
	if int(doc.get("save_version", 0)) != SAVE_VERSION:
		error_out.append("ERR_SAVE_VERSION")
		return null
	var sim: Simulation = Simulation.new(data, 0)
	sim.load_state(doc["state"])
	return sim


## Eski sürümleri sırayla yükseltir: migrate_v1_to_v2(), migrate_v2_to_v3() … (ilk sürüm, henüz göç yok).
static func migrate(doc: Dictionary) -> Dictionary:
	return doc
