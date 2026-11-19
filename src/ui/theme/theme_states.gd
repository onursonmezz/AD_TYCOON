class_name ThemeStates
extends RefCounted
## S11: bir düğme türünün bütün hâlleri (normal, üstüne gelince, basılı, kapalı) aynı iç boşlukta olmalı; yoksa fare
## üstüne gelince ya da düğme kapanınca yazı kayar. Tanımlı olmayan hâl taban türden gelir; o da eşitlenir.
static func unify(t: Theme) -> void:
	for type: String in t.get_type_list():
		var root: String = type
		while not t.get_type_variation_base(root).is_empty():
			root = t.get_type_variation_base(root)
		if not ["Button", "CheckBox", "CheckButton"].has(root):
			continue
		var normal: StyleBox = _style_of(t, "normal", type)
		if normal == null:
			continue
		for st: String in ["hover", "pressed", "hover_pressed", "disabled"]:
			var sb: StyleBox = _style_of(t, st, type)
			if sb == null:
				continue
			var same: bool = true
			for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
				same = same and is_equal_approx(sb.get_content_margin(side), normal.get_content_margin(side))
			if same:
				continue
			var fixed: StyleBox = sb.duplicate()
			for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
				fixed.set_content_margin(side, normal.get_content_margin(side))
			t.set_stylebox(st, type, fixed)


## Türün hâl kutusu; kendisinde yoksa taban türünden.
static func _style_of(t: Theme, st: String, type: String) -> StyleBox:
	var cur: String = type
	while not cur.is_empty():
		if t.has_stylebox(st, cur):
			return t.get_stylebox(st, cur)
		cur = t.get_type_variation_base(cur)
	return null
