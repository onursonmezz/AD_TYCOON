extends GutTest
## M9-C: çeviri bütünlüğü. Her satırın Türkçe ve İngilizcesi dolu; koddaki her tr("ANAHTAR") CSV'de var;
## % biçim işaretleri iki dilde aynı sayıda.

var rows: Dictionary = {}


func before_all() -> void:
	var f: FileAccess = FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	f.get_csv_line()
	while not f.eof_reached():
		var r: PackedStringArray = f.get_csv_line()
		if r.size() >= 1 and not r[0].is_empty():
			rows[r[0]] = r


func test_every_row_has_both_languages() -> void:
	var bad: Array[String] = []
	for key: String in rows:
		var r: PackedStringArray = rows[key]
		if r.size() < 3 or r[1].strip_edges().is_empty() or r[2].strip_edges().is_empty():
			bad.append(key)
	assert_eq(bad, [] as Array[String], "iki dili de dolu olmayan satırlar")


func test_format_markers_match() -> void:
	var re: RegEx = RegEx.create_from_string("%[-+0-9.]*[sdf]")
	var bad: Array[String] = []
	for key: String in rows:
		var r: PackedStringArray = rows[key]
		if r.size() >= 3 and re.search_all(r[1]).size() != re.search_all(r[2]).size():
			bad.append(key)
	assert_eq(bad, [] as Array[String], "% işaret sayısı farklı satırlar")


func test_every_literal_key_in_code_exists() -> void:
	var re: RegEx = RegEx.create_from_string("tr\\(\"([A-Z][A-Z0-9_]+)\"\\)")
	var missing: Array[String] = []
	for path: String in _scripts("res://src"):
		var text: String = FileAccess.get_file_as_string(path)
		for m: RegExMatch in re.search_all(text):
			var key: String = m.get_string(1)
			if not rows.has(key) and not missing.has(key):
				missing.append("%s (%s)" % [key, path.get_file()])
	assert_eq(missing, [] as Array[String], "kodda olup CSV'de olmayan anahtarlar")


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for sub: String in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir.path_join(sub)))
	for f: String in DirAccess.get_files_at(dir):
		if f.get_extension() == "gd":
			out.append(dir.path_join(f))
	return out
