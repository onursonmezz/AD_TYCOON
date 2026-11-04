extends Node
## Oyuncu ayarları (M9): user://settings.cfg. Ses seviyeleri, dil, ekran, arayüz boyutu, otomatik kayıt,
## görülen tutorial ipuçları. Değişince hemen uygulanır ve kaydedilir.

signal changed(key: String)

const PATH: String = "user://settings.cfg"
const DEFAULTS: Dictionary = {
	"volume_master": 0.8, "volume_music": 0.6, "volume_sfx": 0.8, "volume_ambient": 0.5,
	"language": "", "fullscreen": false, "resolution": "1280x720", "ui_scale": 1.0,
	"autosave": true, "tutorial": true, "tutorial_seen": [],
}
const RESOLUTIONS: Array[String] = ["1280x720", "1600x900", "1920x1080", "2560x1440"]
const UI_SCALES: Array[float] = [0.9, 1.0, 1.15, 1.3]
const BUSES: Dictionary = {"volume_master": "Master", "volume_music": "Music", "volume_sfx": "SFX", "volume_ambient": "Ambient"}

## Testler dosyaya yazmasın diye kapatılabilir.
var persist: bool = true
var _values: Dictionary = {}


func _ready() -> void:
	load_from_disk()
	apply_all()


func load_from_disk() -> void:
	_values = DEFAULTS.duplicate(true)
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for key: String in DEFAULTS:
		if cfg.has_section_key("settings", key):
			_values[key] = cfg.get_value("settings", key)


func get_value(key: String) -> Variant:
	return _values.get(key, DEFAULTS.get(key))


func set_value(key: String, value: Variant) -> void:
	_values[key] = value
	apply(key)
	save()
	changed.emit(key)


func save() -> void:
	if not persist:
		return
	var cfg: ConfigFile = ConfigFile.new()
	for key: String in _values:
		cfg.set_value("settings", key, _values[key])
	cfg.save(PATH)


func reset() -> void:
	_values = DEFAULTS.duplicate(true)
	apply_all()
	save()


func apply_all() -> void:
	for key: String in DEFAULTS:
		apply(key)


func apply(key: String) -> void:
	var v: Variant = get_value(key)
	match key:
		"language":
			if not str(v).is_empty():
				TranslationServer.set_locale(str(v))
		"fullscreen", "resolution":
			_apply_window()
		"ui_scale":
			if get_tree() != null and get_tree().root != null:
				get_tree().root.content_scale_factor = float(v)
		_:
			if BUSES.has(key):
				var bus: int = AudioServer.get_bus_index(BUSES[key])
				if bus >= 0:
					AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(0.0001, float(v))))
					AudioServer.set_bus_mute(bus, float(v) <= 0.001)


func _apply_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if bool(get_value("fullscreen")):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var parts: PackedStringArray = str(get_value("resolution")).split("x")
	if parts.size() == 2:
		var size: Vector2i = Vector2i(int(parts[0]), int(parts[1]))
		var screen: Vector2i = DisplayServer.screen_get_size()
		size = Vector2i(mini(size.x, screen.x), mini(size.y, screen.y))
		DisplayServer.window_set_size(size)
		DisplayServer.window_set_position((screen - size) / 2)


# --- tutorial (M9-C kullanır) -------------------------------------------------------

func tutorial_seen(id: String) -> bool:
	return (get_value("tutorial_seen") as Array).has(id)


func mark_tutorial_seen(id: String) -> void:
	var seen: Array = (get_value("tutorial_seen") as Array).duplicate()
	if not seen.has(id):
		seen.append(id)
		set_value("tutorial_seen", seen)
