extends Node
## Performans ölçümü (M9-C, GDD 24.5: 60 çalışanla 60 FPS hedefi). Pencere açar: ana ekranı en büyük ofiste
## N çalışanla kurar, oyunu en yüksek hızda çalıştırır ve kare sürelerini ölçer.
## Çalıştırma: godot --path . res://tools/perf_check.tscn -- [--staff=60] [--seconds=20] [--samples]
## --samples: deneme karakter ve eşya modelleriyle (gerçek modelli durumu taklit eder).

var _staff: int = 60
var _seconds: float = 20.0
var _samples: bool = false
var _frames: PackedFloat32Array = PackedFloat32Array()
var _proc: PackedFloat32Array = PackedFloat32Array()
var _draws: PackedFloat32Array = PackedFloat32Array()
var _measuring: bool = false


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--staff="):
			_staff = int(arg.trim_prefix("--staff="))
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
		elif arg == "--samples":
			_samples = true
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_run.call_deferred()


func _run() -> void:
	if _samples:
		var s: GDScript = preload("res://tools/sample_models.gd")
		ModelLibrary.overrides = s.make_all("user://perf_samples")
		ModelLibrary.overrides.merge(s.make_characters("user://perf_samples", DataDB.data))
	Settings.persist = false
	Settings.set_value("tutorial", false)
	Settings.set_value("autosave", false)
	GameState.new_game(77, "", 2010)
	var sim: Simulation = GameState.sim
	sim.state.office_level = DataDB.data.max_office_level()
	sim.state.cash = 1.0e9
	var roles: Array[String] = ["copywriter", "art_director", "account", "planner", "producer", "graphic_designer"]
	for i: int in _staff - 1:
		var p: Dictionary = sim.staff._blank(sim.state, roles[i % roles.size()], 3)
		p["stats"] = {"strategy": 60.0, "creative": 60.0, "technical": 60.0, "communication": 60.0, "speed": 60.0,
			"attention": 60.0}
		p["hidden"] = {"potential": 90.0}
		p["salary"] = 1000.0
		p["gender"] = ["female", "male", "neutral"][i % 3]
		p["name"] = "P%d" % i
		sim.state.staff[p["id"]] = p
	sim.build.refresh(sim.state)
	sim.pause_on_phase = false
	var screen: Control = load("res://src/ui/screens/main.tscn").instantiate()
	add_child(screen)
	Clock.set_speed(DataDB.data.bal("time.speeds").size() - 1)
	# Isınma: karakterler masalarına yürüsün.
	await get_tree().create_timer(4.0).timeout
	_measuring = true
	await get_tree().create_timer(_seconds).timeout
	_measuring = false
	_report()
	get_tree().quit()


func _process(delta: float) -> void:
	if not _measuring:
		return
	_frames.append(delta * 1000.0)
	_proc.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	_draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	# Ölçüm sırasında olaylar oyunu durdurmasın.
	if not GameState.pending_event().is_empty():
		var inst: Dictionary = GameState.pending_event()
		GameState.sim.events.resolve(GameState.sim, inst["uid"], int(inst["options"][0]))


func _report() -> void:
	var f: PackedFloat32Array = _frames.duplicate()
	f.sort()
	var avg: float = _avg(_frames)
	var p95: float = f[int(f.size() * 0.95)] if not f.is_empty() else 0.0
	var p99: float = f[int(f.size() * 0.99)] if not f.is_empty() else 0.0
	print("=== Performans: %d çalışan, ofis seviye %d, %s, %.0f sn ===" % [GameState.sim.state.staff.size(),
		GameState.sim.state.office_level, "deneme modelleri" if _samples else "gri kutu", _seconds])
	print("Kare: ort. %.2f ms (%.0f FPS) · %%95 %.2f ms · %%99 %.2f ms · en kötü %.2f ms" % [avg, 1000.0 / maxf(avg, 0.001), p95,
		p99, f[f.size() - 1] if not f.is_empty() else 0.0])
	print("İşlem (process) ort. %.2f ms · çizim çağrısı ort. %.0f" % [_avg(_proc), _avg(_draws)])
	print("Bellek (statik) %.1f MB · nesne %d · düğüm %d" % [Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	print("Oyun ilerledi: %s" % UiUtil.date_text(GameState.sim.state.clock))
	print("Hedef (60 FPS = 16.7 ms): %s" % ("✓" if p95 <= 16.7 else "✗"))


func _avg(a: PackedFloat32Array) -> float:
	var s: float = 0.0
	for v: float in a:
		s += v
	return s / maxf(1.0, a.size())
