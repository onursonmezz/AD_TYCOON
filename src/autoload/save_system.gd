extends Node
## Kayıt/yükleme (GDD 24.3, 24.5; M9): 3 elle kayıt slotu + 1 otomatik kayıt slotu.
## Her slot: sıkıştırılmış kayıt (SaveCodec JSON) + yanında küçük bir .meta (yükleme ekranı dosyayı açmadan okusun).
## M2'deki tek slot (user://save_slot_1.sav) zaten 1. slotun dosyasıdır; ayrıca taşımaya gerek yok.

const SLOTS: Array[String] = ["slot_1", "slot_2", "slot_3"]
const AUTO: String = "auto"

## Test ve araçlar başka klasör kullanabilsin.
var dir: String = "user://"


func path_of(slot: String) -> String:
	return dir.path_join("save_%s.sav" % slot)


## Bir önceki kayıt (K-150): asıl dosya okunamazsa buradan yüklenir.
func backup_path_of(slot: String) -> String:
	return path_of(slot) + ".bak"


func meta_path_of(slot: String) -> String:
	return dir.path_join("save_%s.meta" % slot)


func all_slots() -> Array[String]:
	var out: Array[String] = SLOTS.duplicate()
	out.append(AUTO)
	return out


func has_save(slot: String = "") -> bool:
	if slot.is_empty():
		return not latest_slot().is_empty()
	return FileAccess.file_exists(path_of(slot))


## En son kaydedilen slot (otomatik dahil); yoksa "".
func latest_slot() -> String:
	var best: String = ""
	var best_t: float = -1.0
	for slot: String in all_slots():
		if not has_save(slot):
			continue
		var t: float = float(slot_meta(slot).get("saved_at", 0.0))
		if t > best_t:
			best_t = t
			best = slot
	return best


## Slotun özeti; yoksa {}. .meta yoksa (eski kayıt) kaydın kendisinden çıkarılır.
func slot_meta(slot: String) -> Dictionary:
	if not has_save(slot):
		return {}
	if FileAccess.file_exists(meta_path_of(slot)):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path_of(slot)))
		if parsed is Dictionary:
			return parsed
	var text: String = _read(slot)
	var doc: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if not doc is Dictionary or not (doc as Dictionary).has("state"):
		return {"corrupt": true}
	var meta: Dictionary = SaveCodec.meta_of(doc["state"], FileAccess.get_modified_time(path_of(slot)))
	return meta


func save_game(sim: Simulation, slot: String) -> bool:
	var text: String = SaveCodec.encode(sim)
	var tmp: String = path_of(slot) + ".tmp"
	var file: FileAccess = FileAccess.open_compressed(tmp, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	if file == null:
		push_error("Kayıt yazılamadı: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(text)
	file.close()
	# Önce geçici dosyaya yazılır, sonra eskisinin yerine konur: yazarken çökerse eski kayıt bozulmaz.
	# K-150: eski kayıt silinmez, .bak olarak bir kuşak saklanır; yenisi yerine konamazsa geri alınır.
	var bak: String = backup_path_of(slot)
	if FileAccess.file_exists(path_of(slot)):
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(bak)
		DirAccess.rename_absolute(path_of(slot), bak)
	if DirAccess.rename_absolute(tmp, path_of(slot)) != OK:
		push_error("Kayıt yerine konamadı: %s" % path_of(slot))
		if FileAccess.file_exists(bak) and not FileAccess.file_exists(path_of(slot)):
			DirAccess.rename_absolute(bak, path_of(slot))
		return false
	var meta: Dictionary = SaveCodec.meta_of(sim.state.to_dict(), Time.get_unix_time_from_system())
	var mf: FileAccess = FileAccess.open(meta_path_of(slot), FileAccess.WRITE)
	if mf != null:
		mf.store_string(JSON.stringify(meta))
		mf.close()
	return true


## Dönüş: Simulation veya null; hata anahtarları error_out'a.
func load_game(data: GameData, slot: String, error_out: Array[String] = []) -> Simulation:
	if not has_save(slot):
		error_out.append("ERR_SAVE_CORRUPT")
		return null
	var text: String = _read(slot)
	var errors: Array[String] = []
	var sim: Simulation = SaveCodec.decode(data, text, errors) if not text.is_empty() else null
	if sim == null and errors.is_empty():
		errors.append("ERR_SAVE_CORRUPT")
	if sim == null and FileAccess.file_exists(backup_path_of(slot)):
		# K-150: asıl dosya bozuksa bir önceki kayıt denenir.
		var backup_errors: Array[String] = []
		var old: Simulation = SaveCodec.decode(data, _read_file(backup_path_of(slot)), backup_errors)
		if old != null:
			push_warning("Kayıt bozuktu (%s), bir önceki kayıt yüklendi." % slot)
			return old
	error_out.append_array(errors)
	for e: String in errors:
		push_error("Kayıt okunamadı (%s): %s" % [slot, e])
	return sim


func _read(slot: String) -> String:
	return _read_file(path_of(slot))


func _read_file(path: String) -> String:
	var file: FileAccess = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text
