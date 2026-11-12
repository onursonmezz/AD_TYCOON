extends GutTest
## K-096: tempo ölçümü — yıl yıl gerçek süre, duraklama/akan ayrımı, boşta kalma, dosya.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _log() -> PlaytimeLog:
	var log: PlaytimeLog = PlaytimeLog.new()
	log.persist = false
	return log


func test_counts_total_running_and_speed_per_year() -> void:
	var log: PlaytimeLog = _log()
	log.record(data, "a|1990", 1990, 2.0, true, 1, false)
	log.record(data, "a|1990", 1990, 3.0, false, 1, false)
	log.record(data, "a|1990", 1990, 1.0, true, 4, false)
	log.record(data, "a|1990", 1991, 5.0, true, 2, false)
	var y90: Dictionary = log.entries[0]
	assert_almost_eq(float(y90["total"]), 6.0, 0.001, "duraklama dahil toplam")
	assert_almost_eq(float(y90["running"]), 3.0, 0.001, "yalnızca akan süre")
	assert_almost_eq(float(y90["by_speed"]["4"]), 1.0, 0.001)
	assert_eq(int(log.latest(1)[0]["year"]), 1991, "en yeni önce")


func test_idle_pause_is_not_counted_but_idle_running_is() -> void:
	var log: PlaytimeLog = _log()
	log.record(data, "a|1990", 1990, 10.0, false, 1, true)
	assert_true(log.entries.is_empty(), "duraklatıp bırakılan oyun sayılmaz")
	log.record(data, "a|1990", 1990, 4.0, true, 1, true)
	assert_almost_eq(float(log.entries[0]["running"]), 4.0, 0.001, "zaman akarken izlemek de oyundur")


func test_separate_games_and_campaigns_and_entry_limit() -> void:
	var log: PlaytimeLog = _log()
	log.record(data, "a|1990", 1990, 1.0, true, 1, false)
	log.record(data, "b|1990", 1990, 1.0, true, 1, false)
	log.count_campaign(data, "b|1990", 1990)
	assert_eq(log.entries.size(), 2, "iki oyun ayrı tutulur")
	assert_eq(int(log.entries[1]["campaigns"]), 1)
	for y: int in range(2000, 2000 + int(data.bal("telemetry.keep_entries")) + 5):
		log.record(data, "a|1990", y, 1.0, true, 1, false)
	assert_eq(log.entries.size(), int(data.bal("telemetry.keep_entries")), "eski kayıtlar atılır")


func test_saves_and_loads_file() -> void:
	var log: PlaytimeLog = _log()
	log.persist = true
	log.path = "user://test_playtime.json"
	log.record(data, "a|1990", 1990, 2.5, true, 1, false)
	log.save()
	var other: PlaytimeLog = _log()
	other.path = log.path
	other.load_from_disk()
	assert_almost_eq(float(other.entries[0]["total"]), 2.5, 0.001)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(log.path))
