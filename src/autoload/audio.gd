extends Node
## Ses yöneticisi (M9-B, GDD 22): Music / SFX / Ambient kanalları (Master'a bağlı), adla çalınan efektler,
## dönemsel müzik listesi ve ofis ortam sesi.
## Efekt: assets/audio/sfx/<ad>.(ogg|wav|mp3) varsa o, yoksa data/sounds.json tarifinden üretilen yer tutucu.
## Müzik: assets/audio/music/<dönem_id>/ altındaki parçalar karışık çalar; klasör boşsa genel klasör, o da boşsa sessiz.

const BUSES: Array[String] = ["Music", "SFX", "Ambient"]
const SFX_VOICES: int = 6

var _cache: Dictionary = {}
var _sfx: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music: Array[AudioStreamPlayer] = []
var _music_on: int = 0
var _music_era: String = ""
var _playlist: Array[String] = []
var _wait: float = 0.0
var _ambient: AudioStreamPlayer
var _ambient_timer: float = 0.0
## Son çalınan efektler (testler ve ekran turu için).
var history: Array[String] = []


func _cfg() -> Dictionary:
	return DataDB.data.sounds


func _ready() -> void:
	for bus: String in BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var idx: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus)
			AudioServer.set_bus_send(idx, "Master")
	for i: int in SFX_VOICES:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx.append(p)
	for i: int in 2:
		var m: AudioStreamPlayer = AudioStreamPlayer.new()
		m.bus = "Music"
		m.volume_db = -80.0
		m.finished.connect(_on_music_finished.bind(i))
		add_child(m)
		_music.append(m)
	_ambient = AudioStreamPlayer.new()
	_ambient.bus = "Ambient"
	_ambient.volume_db = -80.0
	add_child(_ambient)
	Settings.apply_all()
	if DataDB.is_ok():
		_connect_events()


func _connect_events() -> void:
	EventBus.notification.connect(_on_notification)
	EventBus.campaign_finished.connect(func(camp: Dictionary) -> void:
		play("cheer" if float(camp["report"]["score"]) >= float(_cfg()["juice"]["confetti_score"]) else "report"))
	EventBus.award_ceremony.connect(func(_r: Dictionary) -> void: play("applause"))
	EventBus.event_started.connect(func(_e: Dictionary) -> void: play("event"))


func _on_notification(key: String, _args: Array, kind: String) -> void:
	var map: Dictionary = _cfg()["notification_sounds"]
	play(str(map["keys"].get(key, map.get(kind, "notify"))))


# --- efektler ----------------------------------------------------------------------

func _year() -> int:
	return GameState.sim.state.clock.year() if GameState.has_game() else DataDB.data.bali("time.start_year")


## Dönemsel ad (notify, brief) → o yılın sesi; değilse adın kendisi.
func resolve(name: String, year: int = -1) -> String:
	var variants: Dictionary = _cfg()["variants"]
	if not variants.has(name):
		return name
	if year < 0:
		year = _year()
	var best: String = ""
	var best_year: int = -1
	for y: String in variants[name]:
		if int(y) <= year and int(y) > best_year:
			best_year = int(y)
			best = str(variants[name][y])
	return best if not best.is_empty() else name


func stream_of(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var stream: AudioStream = null
	for ext: Variant in _cfg()["extensions"]:
		var path: String = str(_cfg()["sfx_dir"]) + name + "." + str(ext)
		if ResourceLoader.exists(path):
			stream = load(path) as AudioStream
			break
	if stream == null and (_cfg()["sfx"] as Dictionary).has(name):
		var def: Dictionary = _cfg()["sfx"][name]
		stream = SfxSynth.build(def["synth"], int(_cfg()["sample_rate"]), name.hash(), bool(def.get("loop", false)))
	_cache[name] = stream
	return stream


func has_file(name: String) -> bool:
	for ext: Variant in _cfg()["extensions"]:
		if ResourceLoader.exists(str(_cfg()["sfx_dir"]) + name + "." + str(ext)):
			return true
	return false


func play(name: String) -> void:
	if not DataDB.is_ok():
		return
	var real: String = resolve(name)
	var stream: AudioStream = stream_of(real)
	history.append(real)
	if history.size() > 20:
		history.pop_front()
	if stream == null:
		return
	var p: AudioStreamPlayer = _sfx[_next_voice]
	_next_voice = (_next_voice + 1) % _sfx.size()
	p.stream = stream
	p.play()


# --- müzik ve ortam ----------------------------------------------------------------

## Dönemin parçaları: önce assets/audio/music/<dönem>/, boşsa assets/audio/music/ kökü.
func tracks_for(era: String) -> Array[String]:
	var root: String = str(_cfg()["music_dir"])
	var out: Array[String] = _list_audio(root + era + "/")
	if out.is_empty():
		out = _list_audio(root)
	return out


func _list_audio(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	if not DirAccess.dir_exists_absolute(dir_path):
		return out
	var exts: Array = _cfg()["extensions"]
	for f: String in DirAccess.get_files_at(dir_path):
		var name: String = f.trim_suffix(".import").trim_suffix(".remap")
		if exts.has(name.get_extension()) and not out.has(dir_path + name):
			out.append(dir_path + name)
	return out


func _process(delta: float) -> void:
	if not DataDB.is_ok():
		return
	_update_music(delta)
	_ambient_timer -= delta
	if _ambient_timer <= 0.0:
		_ambient_timer = float(_cfg()["ambient"]["update_seconds"])
		_update_ambient()


func _update_music(delta: float) -> void:
	var era: String = DataDB.data.era_of(_year())
	if era != _music_era:
		_music_era = era
		_playlist = tracks_for(era)
		_playlist.shuffle()
		if _music[_music_on].playing or _playlist.is_empty():
			_fade_out(_music[_music_on])
		_wait = 0.0
		if not _playlist.is_empty():
			_next_track()
		return
	if _playlist.is_empty() or _music[_music_on].playing:
		return
	_wait -= delta
	if _wait <= 0.0:
		_next_track()


func _next_track() -> void:
	if _playlist.is_empty():
		return
	var path: String = _playlist.pop_front()
	_playlist.append(path)
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	var old: AudioStreamPlayer = _music[_music_on]
	_music_on = 1 - _music_on
	var p: AudioStreamPlayer = _music[_music_on]
	p.stream = stream
	p.volume_db = -40.0
	p.play()
	var cf: float = float(_cfg()["music"]["crossfade_seconds"])
	create_tween().tween_property(p, "volume_db", 0.0, cf)
	if old.playing:
		_fade_out(old)


func _fade_out(p: AudioStreamPlayer) -> void:
	var t: Tween = create_tween()
	t.tween_property(p, "volume_db", -40.0, float(_cfg()["music"]["crossfade_seconds"]))
	t.tween_callback(p.stop)


func _on_music_finished(index: int) -> void:
	if index == _music_on:
		_wait = float(_cfg()["music"]["gap_seconds"])


## Klavye uğultusu: çalışan sayısıyla artar; oyun durunca kısılır; oyun yokken susar.
func ambient_level() -> float:
	if not GameState.has_game():
		return 0.0
	var cfg: Dictionary = _cfg()["ambient"]
	var level: float = minf(1.0, float(GameState.sim.state.staff.size()) / float(cfg["staff_full"]))
	return level if Clock.is_running() else level * float(cfg["paused_factor"])


func _update_ambient() -> void:
	var level: float = ambient_level()
	if level <= 0.001:
		if _ambient.playing and _ambient.volume_db > -39.0:
			_fade_out(_ambient)
		return
	if not _ambient.playing:
		_ambient.stream = stream_of("ambient_typing")
		_ambient.volume_db = -40.0
		_ambient.play()
	create_tween().tween_property(_ambient, "volume_db", linear_to_db(level), float(_cfg()["ambient"]["fade_seconds"]))
