extends Control
## UI kiti vitrini (G2): bütün bileşenler tek ekranda. Tema değişikliklerini burada görsel olarak kontrol et.
## Çalıştırma: godot --path . res://tools/ui_kit_demo.tscn  ( -- --out=<klasör> verilirse PNG kaydedip kapanır)


func _ready() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color("#5B7A55")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var cols: HBoxContainer = UiUtil.hbox(24)
	margin.add_child(cols)
	cols.add_child(_left())
	cols.add_child(_middle())
	cols.add_child(_right())
	var out: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	if not out.is_empty():
		await get_tree().create_timer(1.5).timeout
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(out)
		get_viewport().get_texture().get_image().save_png(out.path_join("ui_kit_demo.png"))
		get_tree().quit()


## İkon çubuğu ve oyun düğmeleri.
func _left() -> VBoxContainer:
	var col: VBoxContainer = UiUtil.vbox(6)
	for name: String in ["inbox", "users", "speakerphone", "users-group", "building", "tool", "flask", "coins"]:
		var b: Button = UiUtil.icon_button(name, name, func() -> void: pass, 24)
		b.custom_minimum_size = Vector2(52, 52)
		if name == "users-group":
			b.theme_type_variation = "IconButtonActive"
		col.add_child(b)
	return col


## Panel: başlık, hap düğmeler, ilerleme çubukları, liste satırları, form öğeleri.
func _middle() -> PanelContainer:
	var p: PanelContainer = UiUtil.panel()
	p.custom_minimum_size = Vector2(620, 0)
	var col: VBoxContainer = UiUtil.vbox(12)
	p.add_child(col)
	var strip: PanelContainer = PanelContainer.new()
	strip.theme_type_variation = "HeaderStrip"
	var title: Label = UiUtil.label("★  UI KİTİ  ★", 22, Color.WHITE)
	title.add_theme_font_override("font", UiUtil.head_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strip.add_child(title)
	col.add_child(strip)
	col.add_child(UiUtil.heading("Başlık (Fredoka)"))
	col.add_child(UiUtil.wrapped("Gövde metni Nunito ile yazılır; Türkçe karakterler: ğüşıöç ĞÜŞİÖÇ.", 16, UiUtil.TEXT, 560))
	var buttons: HBoxContainer = UiUtil.hbox(10)
	buttons.add_child(UiUtil.button_kind("Kabul", func() -> void: pass, "accept"))
	buttons.add_child(UiUtil.button_kind("Bekle", func() -> void: pass, "wait"))
	buttons.add_child(UiUtil.button_kind("Reddet", func() -> void: pass, "decline"))
	buttons.add_child(UiUtil.button("İkincil", func() -> void: pass))
	var off: Button = UiUtil.button("Kapalı", func() -> void: pass)
	off.disabled = true
	buttons.add_child(off)
	col.add_child(buttons)
	for row: Array in [["Kampanya bitir", 9, 25], ["Müşteri memnun et", 3, 5]]:
		col.add_child(_progress(row[0], int(row[1]), int(row[2])))
	for row: Array in [["25", "Mobilya ya da dekor", "26/80"], ["35", "Nakit kazan", "463/1.100"]]:
		col.add_child(_list_row(row[0], row[1], row[2]))
	var form: HBoxContainer = UiUtil.hbox(10)
	var le: LineEdit = LineEdit.new()
	le.placeholder_text = "Kampanya adı"
	le.custom_minimum_size.x = 200
	form.add_child(le)
	var ob: OptionButton = OptionButton.new()
	for o: String in ["Bilinirlik", "Satış", "Etkileşim"]:
		ob.add_item(o)
	form.add_child(ob)
	var cb: CheckBox = CheckBox.new()
	cb.text = "Fazla mesai"
	cb.button_pressed = true
	form.add_child(cb)
	col.add_child(form)
	var slider: HSlider = HSlider.new()
	slider.value = 60
	col.add_child(slider)
	var pop: Button = UiUtil.button_kind("Pencere aç (animasyon)", func() -> void: _demo_dialog(), "accept")
	col.add_child(pop)
	return p


## Rozetler, bildirim, tarih ve hız grubu.
func _right() -> VBoxContainer:
	var col: VBoxContainer = UiUtil.vbox(16)
	var cash: CountBadge = CountBadge.new("currency-lira", CozyTheme.GOLD, func(v: float) -> String: return UiUtil.money(v).replace("₺", ""), 230)
	col.add_child(cash)
	cash.set_value(1645.0)
	var rep: CountBadge = CountBadge.new("star", CozyTheme.ACCENT, func(v: float) -> String: return "%d" % int(v), 140)
	col.add_child(rep)
	rep.set_value(54.0)
	col.add_child(UiUtil.button("Para +500 (sayma)", func() -> void: cash.set_value(cash.value() + 500.0)))
	var feed: VBoxContainer = UiUtil.vbox(8)
	feed.custom_minimum_size.x = 340
	col.add_child(feed)
	MainHud.toast(feed, "NOTE_WELCOME", [], "info")
	MainHud.toast(feed, "NOTE_SAVED", [], "good")
	var date: PanelContainer = PanelContainer.new()
	date.theme_type_variation = "HeaderStrip"
	var dl: Label = UiUtil.label("1998 · Ay 3", 22, Color.WHITE)
	dl.add_theme_font_override("font", UiUtil.head_font())
	date.add_child(dl)
	col.add_child(date)
	var pill: PanelContainer = PanelContainer.new()
	pill.theme_type_variation = "DarkPill"
	var row: HBoxContainer = UiUtil.hbox(6)
	pill.add_child(row)
	row.add_child(UiUtil.icon_button("clock", "", func() -> void: pass, 24))
	var play: Button = UiUtil.icon_button("player-play", "", func() -> void: pass, 24)
	play.theme_type_variation = "IconButtonActive"
	row.add_child(play)
	for s: String in ["1×", "2×", "4×"]:
		var b: Button = UiUtil.button(s, func() -> void: pass)
		b.theme_type_variation = "IconButton"
		row.add_child(b)
	col.add_child(pill)
	var close: Button = UiUtil.close_button(func() -> void: pass)
	close.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(close)
	return col


func _progress(text: String, value: int, total: int) -> Control:
	var bar: ProgressBar = ProgressBar.new()
	bar.max_value = total
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 38)
	var row: HBoxContainer = UiUtil.hbox()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_right = -16
	row.add_child(UiUtil.label(text, 16, UiUtil.TEXT))
	row.add_child(UiUtil.spacer())
	row.add_child(UiUtil.label("%d/%d" % [value, total], 16, UiUtil.TEXT))
	bar.add_child(row)
	return bar


func _list_row(points: String, text: String, value: String) -> PanelContainer:
	var card: PanelContainer = UiUtil.card()
	var row: HBoxContainer = UiUtil.hbox(12)
	card.add_child(row)
	var chip: PanelContainer = PanelContainer.new()
	chip.theme_type_variation = "DarkPill"
	var pl: Label = UiUtil.label(points, 16, Color.WHITE)
	pl.add_theme_font_override("font", UiUtil.head_font())
	chip.add_child(pl)
	row.add_child(chip)
	row.add_child(UiUtil.label(text, 17, UiUtil.TEXT))
	row.add_child(UiUtil.spacer())
	row.add_child(UiUtil.label(value, 17, UiUtil.TEXT))
	return card


func _demo_dialog() -> void:
	add_child(ConfirmDialog.new("UI_UNSAVED_TITLE", "UI_UNSAVED_TEXT", [["UI_CANCEL", Callable()]]))
