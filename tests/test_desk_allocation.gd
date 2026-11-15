extends GutTest
## 3D ofis: her çalışana ayrı masa (OfficeWorld.allocate_desks).


func _values_unique(d: Dictionary) -> bool:
	var seen: Dictionary = {}
	for v: Variant in d.values():
		if seen.has(v):
			return false
		seen[v] = true
	return true


func test_each_gets_own_desk() -> void:
	var out: Dictionary = OfficeWorld.allocate_desks({}, ["a", "b", "c"], 5)
	assert_eq(out.size(), 3)
	assert_true(_values_unique(out))


func test_more_staff_than_desks_leaves_rest_without() -> void:
	var out: Dictionary = OfficeWorld.allocate_desks({}, ["a", "b", "c", "d"], 2)
	assert_eq(out.size(), 2, "masası olmayan iki kişi atanmaz (dinlenme alanına gider)")
	assert_true(_values_unique(out))


func test_keeps_valid_and_fixes_removed_desk() -> void:
	# b'nin masası silindi (indeks 3, artık 3 masa var), c ile d aynı masadaydı.
	var out: Dictionary = OfficeWorld.allocate_desks({"a": 2, "b": 3, "c": 0, "d": 0}, ["a", "b", "c", "d"], 3)
	assert_eq(int(out["a"]), 2, "geçerli masa korunur")
	assert_eq(int(out["c"]), 0)
	assert_true(_values_unique(out))
	assert_eq(out.size(), 3)


func test_new_desk_goes_to_waiting_person() -> void:
	var out: Dictionary = OfficeWorld.allocate_desks({"a": 0}, ["a", "b"], 2)
	assert_eq(int(out["b"]), 1)
