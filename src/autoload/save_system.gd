extends Node
## Kayıt/yükleme (GDD 24.3). M2: tek slot; M9'da 3 slot + otomatik kayıt.

const SLOT_PATH: String = "user://save_slot_1.sav"


func has_save() -> bool:
	return FileAccess.file_exists(SLOT_PATH)


func save_game(sim: Simulation) -> bool:
	var file: FileAccess = FileAccess.open_compressed(SLOT_PATH, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	if file == null:
		push_error("Kayıt yazılamadı: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(SaveCodec.encode(sim))
	file.close()
	return true


## Dönüş: Simulation veya null.
func load_game(data: GameData) -> Simulation:
	if not has_save():
		return null
	var file: FileAccess = FileAccess.open_compressed(SLOT_PATH, FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	if file == null:
		return null
	var text: String = file.get_as_text()
	file.close()
	var errors: Array[String] = []
	var sim: Simulation = SaveCodec.decode(data, text, errors)
	for e: String in errors:
		push_error("Kayıt okunamadı: " + e)
	return sim
