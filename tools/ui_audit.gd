class_name UiAudit
extends RefCounted
## Arayüz denetimi (S11): ekran turu her karede çağırır, sorunları metin olarak toplar.
## Aranan: (1) kesilen tek satırlık yazı, (2) pencereden ya da ekrandan taşan öğe, (3) hâlleri arasında iç boşluğu
## farklı düğme (üstüne gelince yazı kayar), (4) küçültülmüş içerik (FitScaler < 1), (5) aynı pencerenin sekmeleri
## arasında boy değişimi. Rapor: <out>/audit.txt.

var lines: PackedStringArray = PackedStringArray()
var _window_sizes: Dictionary = {}  # pencere başlığı → {boy: [kare adları]}
const STATES: Array[String] = ["normal", "hover", "pressed", "hover_pressed", "disabled"]


func check(root: Node, shot: String) -> void:
	var viewport: Rect2 = Rect2(Vector2.ZERO, root.get_viewport().get_visible_rect().size)
	for n: Node in root.find_children("*", "", true, false):
		if not (n is Control) or not (n as Control).is_visible_in_tree():
			continue
		var c: Control = n
		if c is FitScaler:
			for ch: Node in c.get_children():
				if ch is Control and (ch as Control).visible:
					var need: float = (ch as Control).get_combined_minimum_size().x
					if need > c.size.x + 1.5:
						_add(shot, "içerik pencereden geniş, sağı kesik (%d/%d px)" % [int(need), int(c.size.x)], c)
					var sc: Node = c.get_parent()
					if sc is ScrollContainer:
						var tall: float = (ch as Control).get_combined_minimum_size().y
						if tall > (sc as ScrollContainer).size.y + 1.5:
							_add(shot, "içerik pencereden uzun, aşağısı kayıyor (%d/%d px)" % [int(tall), int((sc as ScrollContainer).size.y)], c)
		if c is FitScaler and (c as FitScaler).current_scale() < 0.999:
			_add(shot, "küçültülmüş içerik ×%.2f" % (c as FitScaler).current_scale(), c)
		if c is ScrollContainer and (c as ScrollContainer).horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
			_scroll_width(shot, c as ScrollContainer)
		if c is Label:
			_label(shot, c as Label)
		if c is Button:
			_button(shot, c as Button)
		var r: Rect2 = c.get_global_rect()
		var backdrop: bool = r.size.x >= viewport.size.x * 0.95 and r.size.y >= viewport.size.y * 0.95  # tam ekran zemin
		if r.size.x > 2.0 and r.size.y > 2.0 and not backdrop and not viewport.grow(1.0).encloses(r) and not _inside_scroll(c):
			_add(shot, "ekrandan taşıyor %s" % str(r), c)
	_windows(root, shot)


## Yatay kaydırması kapalı kutuda içerik kutudan genişse sağ taraf kesilir.
func _scroll_width(shot: String, sc: ScrollContainer) -> void:
	for ch: Node in sc.get_children():
		if ch is Control and not (ch is ScrollBar):
			var need: float = (ch as Control).get_combined_minimum_size().x * (ch as Control).scale.x
			var room: float = sc.size.x - (sc.get_v_scroll_bar().size.x if sc.get_v_scroll_bar().visible else 0.0)
			if need > room + 1.5:
				_add(shot, "içerik kutudan geniş, sağı kesik (%d/%d px)" % [int(need), int(room)], sc)


func _inside_scroll(c: Control) -> bool:
	var p: Node = c.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


func _label(shot: String, l: Label) -> void:
	if l.autowrap_mode != TextServer.AUTOWRAP_OFF or l.text.is_empty() or l.text.contains("\n"):
		return
	if not l.clip_text and l.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING:
		return
	var font: Font = l.get_theme_font("font")
	var px: int = l.get_theme_font_size("font_size")
	var w: float = font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	if w > l.size.x + 1.5:
		_add(shot, "yazı kesik (%d/%d px) \"%s\"" % [int(w), int(l.size.x), l.text.left(40)], l)


func _button(shot: String, b: Button) -> void:
	var base: StyleBox = b.get_theme_stylebox("normal")
	if base == null:
		return
	for st: String in STATES:
		var sb: StyleBox = b.get_theme_stylebox(st)
		if sb == null:
			continue
		for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			if absf(sb.get_content_margin(side) - base.get_content_margin(side)) > 0.5:
				_add(shot, "düğmede '%s' hâlinin iç boşluğu farklı (yazı kayar) \"%s\"" % [st, b.text.left(30)], b)
				return
	if not b.text.is_empty() and b.clip_text:
		var font: Font = b.get_theme_font("font")
		var w: float = font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x
		var room: float = b.size.x - base.get_content_margin(SIDE_LEFT) - base.get_content_margin(SIDE_RIGHT)
		if b.icon != null:
			room -= b.icon.get_width() + b.get_theme_constant("h_separation")
		if w > room + 1.5:
			_add(shot, "düğme yazısı kesik \"%s\"" % b.text.left(40), b)


## Pencere boyu: başlığı aynı olan pencere her karede aynı boyda olmalı.
func _windows(root: Node, shot: String) -> void:
	for n: Node in root.find_children("*", "PanelContainer", true, false):
		var p: PanelContainer = n
		if not p.is_visible_in_tree() or p.theme_type_variation != "WindowPanel":
			continue
		var title: String = ""
		for l: Node in p.find_children("*", "Label", true, false):
			if (l as Label).is_visible_in_tree():
				title = (l as Label).text
				break
		var key: String = "%dx%d" % [int(p.size.x), int(p.size.y)]
		var by: Dictionary = _window_sizes.get_or_add(title, {})
		(by.get_or_add(key, []) as Array).append(shot)


func _add(shot: String, text: String, c: Control) -> void:
	lines.append("%s | %s | %s" % [shot, text, str(c.get_path()).get_slice("/", c.get_path().get_name_count() - 1)])


func save(path: String) -> void:
	var out: PackedStringArray = lines.duplicate()
	for title: String in _window_sizes:
		var by: Dictionary = _window_sizes[title]
		if by.size() > 1:
			out.append("BOY DEĞİŞİYOR | %s | %s" % [title, JSON.stringify(by)])
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(out) + "\n")
	print("UiAudit: %d sorun → %s" % [out.size(), path])
