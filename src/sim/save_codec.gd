class_name SaveCodec
extends RefCounted
## Kayıt biçimi (GDD 24.3, 24.5): sürüm numaralı JSON, sürüm göçü (migration) fonksiyonları.
## Dosya işlemleri SaveSystem autoload'undadır; bu sınıf saf dönüşüm yapar (test edilebilir).

const SAVE_VERSION: int = 2


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


## Eski sürümleri sırayla yükseltir: migrate_v1_to_v2(), migrate_v2_to_v3() …
static func migrate(doc: Dictionary) -> Dictionary:
	if int(doc.get("save_version", 0)) == 1:
		doc = migrate_v1_to_v2(doc)
	return doc


## v1 (M2): tek "player" sözlüğü → v2 (M3): kurucu bir çalışan; kampanyaların ekibi kurucu.
static func migrate_v1_to_v2(doc: Dictionary) -> Dictionary:
	var state: Dictionary = doc["state"]
	var player: Dictionary = state.get("player", {})
	var ids: Dictionary = state.get("_next_id", {})
	ids["em"] = int(ids.get("em", 0)) + 1
	state["_next_id"] = ids
	var founder_id: String = "em_%04d" % int(ids["em"])
	var stats: Dictionary = {}
	for stat: String in ["strategy", "creative", "technical", "communication", "speed", "attention"]:
		stats[stat] = float(player.get(stat, 50))
	state["staff"] = {founder_id: {"id": founder_id, "role": "founder", "level": int(player.get("level", 1)),
		"xp": float(player.get("xp", 0)), "stats": stats,
		"hidden": {"potential": 100.0, "loyalty": 100.0, "ego": 50.0, "stress_tolerance": 60.0}, "hidden_revealed": true,
		"energy": float(player.get("energy", 100)), "morale": float(player.get("morale", 70)), "burnout": 0.0,
		"salary": 0.0, "traits": [], "specialization": "", "hired_week": 0, "busy_until": -1, "busy_reason": "",
		"is_founder": true, "gender": "", "name": "", "background": "copywriter"}}
	state.erase("player")
	state["candidates"] = []
	state["offers"] = []
	state["overtime"] = false
	var camps: Array = []
	if not (state.get("active_campaign", {}) as Dictionary).is_empty():
		camps.append(state["active_campaign"])
	camps.append_array(state.get("airing", []))
	camps.append_array(state.get("finished", []))
	for camp: Variant in camps:
		camp["setup"]["team"] = [founder_id]
	doc["save_version"] = 2
	return doc
