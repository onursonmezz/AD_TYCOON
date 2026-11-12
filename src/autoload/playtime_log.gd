class_name PlaytimeLog
extends RefCounted
## Tempo ölçümü (GDD 27.3, K-096): her oyun yılı için gerçek süre. Yalnızca oyuncunun bilgisayarında,
## user://playtime.json'da durur; hiçbir yere gönderilmez.
## total: oyun açıkken geçen süre (duraklama ve pencereler dahil; uzun süre dokunulmazsa sayılmaz).
## running: zamanın aktığı süre. by_speed: hız çarpanına göre akan süre ("1", "2", "4").

const PATH: String = "user://playtime.json"

var path: String = PATH
## Testler dosyaya yazmasın diye kapatılabilir.
var persist: bool = true
## [{ game, year, total, running, by_speed: {"1": s, ...}, campaigns }] — en yeni sonda.
var entries: Array = []
var _dirty_seconds: float = 0.0


func _cfg(data: GameData) -> Dictionary:
	return data.bal("telemetry")


func load_from_disk() -> void:
	entries = []
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary and (parsed as Dictionary).get("entries") is Array:
		entries = (parsed as Dictionary)["entries"]


func save() -> void:
	_dirty_seconds = 0.0
	if not persist:
		return
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"entries": entries}, "\t"))


## Bir kare: delta gerçek saniye; running zaman akıyor mu; speed çarpan (1, 2, 4); idle oyuncu uzun süredir
## dokunmadı mı (duraklatılmışken sayılmaz, zaman akarken sayılır).
func record(data: GameData, game: String, year: int, delta: float, running: bool, speed: int, idle: bool) -> void:
	if not running and idle:
		return
	var e: Dictionary = _entry(data, game, year)
	e["total"] = float(e["total"]) + delta
	if running:
		e["running"] = float(e["running"]) + delta
		var by: Dictionary = e["by_speed"]
		by[str(speed)] = float(by.get(str(speed), 0.0)) + delta
	_dirty_seconds += delta
	if _dirty_seconds >= float(_cfg(data)["save_every_seconds"]):
		save()


func count_campaign(data: GameData, game: String, year: int) -> void:
	var e: Dictionary = _entry(data, game, year)
	e["campaigns"] = int(e["campaigns"]) + 1


## Son n kayıt, en yeni önce.
func latest(n: int) -> Array:
	var out: Array = []
	for i: int in range(entries.size() - 1, maxi(-1, entries.size() - 1 - n), -1):
		out.append(entries[i])
	return out


func _entry(data: GameData, game: String, year: int) -> Dictionary:
	for i: int in range(entries.size() - 1, -1, -1):
		var e: Dictionary = entries[i]
		if str(e["game"]) == game and int(e["year"]) == year:
			return e
	var fresh: Dictionary = {"game": game, "year": year, "total": 0.0, "running": 0.0, "by_speed": {}, "campaigns": 0}
	entries.append(fresh)
	var keep: int = int(_cfg(data)["keep_entries"])
	while entries.size() > keep:
		entries.pop_front()
	return fresh
