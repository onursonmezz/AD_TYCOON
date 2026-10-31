extends GutTest
## Veri doğrulayıcı testleri: gerçek veri geçerli olmalı, bilerek bozulan satırlar yakalanmalı (GDD 8.0, M0 kabul).

const DataValidatorScript: GDScript = preload("res://tools/data_validator.gd")

var _data: Dictionary


func before_each() -> void:
	_data = DataValidatorScript.new().load_dir(DataValidatorScript.DEFAULT_DATA_DIR)


func _validate(data: Dictionary) -> PackedStringArray:
	return DataValidatorScript.new().validate(data)


func _sector_objective_row(sector_id: String) -> Dictionary:
	return _data["fit/sector_objective.json"]["tables"]["objective"]["values"][sector_id]


func _has_error_containing(errors: PackedStringArray, needle: String) -> bool:
	for message: String in errors:
		if message.contains(needle):
			return true
	return false


func test_real_data_is_valid() -> void:
	var errors: PackedStringArray = _validate(_data)
	assert_eq(errors.size(), 0, "Gerçek veri hatasız olmalı: %s" % "\n".join(errors))


func test_all_green_row_fails() -> void:
	var row: Dictionary = _sector_objective_row("fast_food")
	for col: String in row:
		row[col] = 3
	var errors: PackedStringArray = _validate(_data)
	assert_true(_has_error_containing(errors, "'fast_food' satırı dağılım kuralını bozuyor"), "Tamamen yeşil satır hata vermeli")


func test_row_without_strong_negative_fails() -> void:
	# Fast Food: ++ ~ +++ − + −−  →  −− yerine − koy
	_sector_objective_row("fast_food")["csr"] = -1
	var errors: PackedStringArray = _validate(_data)
	assert_true(_has_error_containing(errors, "'fast_food' satırı dağılım kuralını bozuyor"))


func test_two_triple_plus_fails() -> void:
	_sector_objective_row("fast_food")["awareness"] = 3
	assert_true(_has_error_containing(_validate(_data), "'fast_food'"))


func test_missing_row_fails() -> void:
	(_data["fit/sector_objective.json"]["tables"]["objective"]["values"] as Dictionary).erase("airline")
	assert_true(_has_error_containing(_validate(_data), "'airline' eksik"))


func test_unknown_tone_group_fails() -> void:
	(_data["sectors.json"][0] as Dictionary)["tone_group"] = "yok_boyle_grup"
	assert_true(_has_error_containing(_validate(_data), "bilinmeyen tone_group"))


func test_duplicate_id_fails() -> void:
	(_data["channels.json"] as Array).append((_data["channels.json"][0] as Dictionary).duplicate(true))
	assert_true(_has_error_containing(_validate(_data), "tekrar eden id 'newspaper'"))


func test_out_of_range_value_fails() -> void:
	_data["fit/channel_fit.json"]["tables"]["audience"]["values"]["billboard"]["b2b"] = -4
	assert_true(_has_error_containing(_validate(_data), "'billboard'.b2b"))


func test_parse_row_rule() -> void:
	var rule: Array[Dictionary] = DataValidatorScript.parse_row_rule("1x+3, 1x(+1|+2), 1x(0|-1), 1x(-2|-3)")
	assert_eq(rule.size(), 4)
	assert_eq(rule[1]["values"], [1, 2])
	assert_eq(rule[3]["values"], [-2, -3])


func test_rule_accepts_valid_and_rejects_invalid_rows() -> void:
	var six: Array[Dictionary] = DataValidatorScript.parse_row_rule("1x+3, 1x+2, 1x+1, 1x0, 1x-1, 1x(-2|-3)")
	var ok_row: Array[int] = [2, 0, 3, -1, 1, -2]
	var bad_row: Array[int] = [3, 3, 3, 3, 3, 3]
	assert_eq(DataValidatorScript.check_row_against_rule(ok_row, six), "")
	assert_ne(DataValidatorScript.check_row_against_rule(bad_row, six), "")
