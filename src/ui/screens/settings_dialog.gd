class_name SettingsDialog
extends Control
## Ayarlar (M9, UI-2d): ses seviyeleri, dil, ekran, arayüz boyutu, otomatik kayıt, tutorial, günlük klasörü.
## Ana menüden ve oyun içinden açılır; değişiklik hemen uygulanır (Settings autoload'u kaydeder). Esc ile kapanır.
## Dil değişince açık ekran yeniden kurulsun diye on_language çağrılır.

var _on_language: Callable
var _tab: String = "audio"
var _built: bool = false
const FOOTER: float = 62.0  # kaydırmanın dışındaki alt satır
## Oyun içinden açıldıysa ana ekran: "Oyun" sekmesine yükle ve ana menüye dön düğmeleri eklenir (üstte yalnızca
## kaydet ve ayarlar düğmesi var; taslak 19).
var game: Control = null

const TABS: Array = [["audio", "UI_SET_AUDIO", "volume"], ["game", "UI_SET_GAME", "device-gamepad-2"],
	["display", "UI_SET_DISPLAY", "device-desktop"], ["language", "UI_SET_LANGUAGE", "world"], ["tempo", "UI_SET_TEMPO", "clock"]]


func _init(on_language: Callable = Callable()) -> void:
	_on_language = on_language
	set_meta("esc_closes", true)


func _ready() -> void:
	_build()


## UI-2d: solda ikonlu sekmeler (Ses, Oynanış, Ekran, Dil), sağda seçili sekmenin ayarları; altta sıfırla / kapat.
func _build() -> void:
	UiUtil.clear(self)
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("settings") - Vector2(0.0, FOOTER), not _built, true)
	_built = true
	col.add_child(UiUtil.heading(tr("UI_SETTINGS"), "settings"))
	var split: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_L)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(split)
	var nav: VBoxContainer = UiUtil.vbox(4)
	nav.custom_minimum_size.x = 190.0
	split.add_child(nav)
	for tab: Array in TABS:
		var b: Button = UiUtil.button(tr(tab[1]), func() -> void:
			_tab = tab[0]
			_build())
		b.icon = UiUtil.icon_texture(tab[2], 22)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.theme_type_variation = "NavButtonActive" if _tab == tab[0] else "NavButton"
		if _tab == tab[0]:
			# Taslak 19: seçili sekmenin solunda koyu yeşil şerit.
			var active: StyleBoxFlat = CozyTheme.box(CozyTheme.SAGE_SOFT, CozyTheme.RADIUS_CONTROL, Color.TRANSPARENT, 0, false,
				Vector2(CozyTheme.SPACE_M, 10))
			active.border_width_left = 3
			active.border_color = CozyTheme.FOREST
			for st: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
				b.add_theme_stylebox_override(st, active)
		nav.add_child(b)
	split.add_child(VSeparator.new())  # taslak 19: sol menü ile ayarlar arasında ince dikey çizgi
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())  # taslak 19: sağ taraf kutusuz
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 250.0
	split.add_child(panel)
	var body: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_M)
	panel.add_child(body)
	# Taslak 19: "Ses ayarları" başlığı, sağında aynı satırda ince çizgi.
	var title_row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var tab_title: Label = UiUtil.label(tr("UI_SET_" + _tab.to_upper() + "_TITLE"), 18, CozyTheme.FOREST)
	tab_title.add_theme_font_override("font", CozyTheme.title_font(700))
	title_row.add_child(tab_title)
	var line: HSeparator = HSeparator.new()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(line)
	body.add_child(title_row)
	match _tab:
		"audio":
			for key: String in ["volume_master", "volume_music", "volume_sfx", "volume_ambient"]:
				body.add_child(_slider_row(key))
		"game":
			var scales: Array = []
			var scale_names: Array = []
			for s: float in Settings.UI_SCALES:
				scales.append(s)
				scale_names.append(UiUtil.percent(roundf(s * 100.0)))
			body.add_child(_option_row("ui_scale", scales, scale_names))
			body.add_child(_check_row("autosave"))
			body.add_child(_check_row("tutorial"))
			body.add_child(_check_row("minigames"))
			body.add_child(_check_row("era_lock"))
			var tools: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
			tools.add_child(UiUtil.button(tr("UI_SET_TUTORIAL_RESET"), func() -> void: Settings.set_value("tutorial_seen", [])))
			tools.add_child(UiUtil.button(tr("UI_SET_LOGS"), func() -> void:
				OS.shell_open(ProjectSettings.globalize_path("user://logs"))))
			body.add_child(tools)
			if game != null:
				var session: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
				var main: Control = game
				session.add_child(UiUtil.button(tr("MENU_LOAD"), func() -> void:
					main.call("open_modal", SaveLoadDialog.new(false, func() -> void: main.get_tree().reload_current_scene()))
					queue_free()))
				session.add_child(UiUtil.button(tr("UI_MAIN_MENU"), func() -> void:
					main.call("_confirm_leave", Callable(main, "_to_menu"))
					queue_free()))
				body.add_child(session)
		"display":
			body.add_child(_check_row("fullscreen"))
			var res: Array = Array(Settings.RESOLUTIONS)
			body.add_child(_option_row("resolution", res, res))
			var levels: Array = WorldQuality.ids()
			body.add_child(_option_row("graphics", levels,
				levels.map(func(id: Variant) -> String: return "UI_SET_GRAPHICS_" + str(id).to_upper())))
			body.add_child(UiUtil.wrapped(tr("UI_SET_GRAPHICS_HINT"), 13, UiUtil.MUTED, 480.0))
		"language":
			body.add_child(_option_row("language", ["tr", "en"], ["UI_LANG_TR", "UI_LANG_EN"]))
		"tempo":
			_tempo(body)
	var buttons: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	var note: Label = UiUtil.label(tr("UI_SET_AUTOSAVED"), 13, UiUtil.MUTED)
	note.add_theme_font_override("font", MenuArt.italic(CozyTheme.body_font()))
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(note)
	buttons.add_child(UiUtil.button(tr("UI_SET_RESET"), func() -> void:
		Settings.reset()
		_language_changed()))
	buttons.add_child(UiUtil.button_kind(tr("UI_CLOSE"), queue_free, "accept"))
	# Alt satır kaydırmanın dışında, pencerenin en altında (taslak 19).
	var frame: VBoxContainer = UiUtil.modal_outer(col)
	frame.add_child(HSeparator.new())
	frame.add_child(buttons)


## Tempo ölçümü (K-096): son yılların gerçek süresi; hız kararını bu sayılarla veriyoruz.
func _tempo(body: VBoxContainer) -> void:
	body.add_child(UiUtil.wrapped(tr("UI_SET_TEMPO_HINT"), 14, UiUtil.MUTED, 480.0))
	var rows: Array = []
	for e: Dictionary in Clock.playtime.latest(DataDB.data.bali("telemetry.keep_entries")):
		if float(e["total"]) >= DataDB.data.balf("telemetry.show_min_seconds") and rows.size() < DataDB.data.bali("telemetry.show_years"):
			rows.append(e)
	if rows.is_empty():
		body.add_child(UiUtil.label(tr("UI_SET_TEMPO_EMPTY"), 15))
		return
	for e: Dictionary in rows:
		var running: float = maxf(0.001, float(e["running"]))
		var share: float = float((e["by_speed"] as Dictionary).get("1", 0.0)) / running * 100.0
		body.add_child(UiUtil.label(tr("UI_SET_TEMPO_ROW") % [int(e["year"]), UiUtil.num(float(e["total"]) / 60.0, 1),
			UiUtil.num(float(e["running"]) / 60.0, 1), share, int(e["campaigns"])], 15))


func _label(key: String) -> Label:
	var l: Label = UiUtil.label(tr("UI_SET_" + key.to_upper()), 15)
	l.custom_minimum_size.x = 200.0
	return l



func _slider_row(key: String) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox()
	row.add_child(_label(key))
	var s: HSlider = HSlider.new()
	s.min_value = 0.0
	s.max_value = 100.0
	s.step = 5.0
	s.value = float(Settings.get_value(key)) * 100.0
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value: Label = UiUtil.label(UiUtil.percent(s.value), 14, UiUtil.WOOD)
	value.custom_minimum_size.x = 50.0
	s.value_changed.connect(func(v: float) -> void:
		value.text = UiUtil.percent(v)
		Settings.set_value(key, v / 100.0))
	row.add_child(s)
	row.add_child(value)
	return row


func _option_row(key: String, values: Array, names: Array) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox()
	row.add_child(_label(key))
	var o: OptionButton = OptionButton.new()
	var current: Variant = Settings.get_value(key)
	if key == "language" and str(current).is_empty():
		current = TranslationServer.get_locale().substr(0, 2)
	for i: int in values.size():
		o.add_item(tr(str(names[i])) if str(names[i]).begins_with("UI_") else str(names[i]))
		if str(values[i]) == str(current) or (values[i] is float and is_equal_approx(float(values[i]), float(current))):
			o.select(i)
	o.item_selected.connect(func(i: int) -> void:
		Settings.set_value(key, values[i])
		if key == "language":
			_language_changed())
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(o)
	return row


func _check_row(key: String) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox()
	row.add_child(_label(key))
	var c: CheckButton = CheckButton.new()
	c.button_pressed = bool(Settings.get_value(key))
	row.add_child(UiUtil.spacer())
	c.toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
	row.add_child(c)
	return row


func _language_changed() -> void:
	queue_free()
	if _on_language.is_valid():
		_on_language.call()
