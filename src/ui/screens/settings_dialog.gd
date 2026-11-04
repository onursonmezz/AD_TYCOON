class_name SettingsDialog
extends Control
## Ayarlar (M9): ses seviyeleri, dil, ekran, arayüz boyutu, otomatik kayıt, tutorial, günlük klasörü.
## Ana menüden ve oyun içinden açılır; değişiklik hemen uygulanır (Settings autoload'u kaydeder). Esc ile kapanır.
## Dil değişince açık ekran yeniden kurulsun diye on_language çağrılır.

var _on_language: Callable


func _init(on_language: Callable = Callable()) -> void:
	_on_language = on_language
	set_meta("esc_closes", true)


func _ready() -> void:
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(620.0, 560.0))
	col.add_child(UiUtil.heading(tr("UI_SETTINGS")))
	col.add_child(UiUtil.label(tr("UI_SET_AUDIO"), 17, UiUtil.SAGE_DARK))
	for key: String in ["volume_master", "volume_music", "volume_sfx", "volume_ambient"]:
		col.add_child(_slider_row(key))
	col.add_child(UiUtil.label(tr("UI_SET_GAME"), 17, UiUtil.SAGE_DARK))
	col.add_child(_option_row("language", ["tr", "en"], ["UI_LANG_TR", "UI_LANG_EN"]))
	var scales: Array = []
	var scale_names: Array = []
	for s: float in Settings.UI_SCALES:
		scales.append(s)
		scale_names.append(UiUtil.percent(roundf(s * 100.0)))
	col.add_child(_option_row("ui_scale", scales, scale_names))
	col.add_child(_check_row("autosave"))
	col.add_child(_check_row("tutorial"))
	col.add_child(UiUtil.label(tr("UI_SET_DISPLAY"), 17, UiUtil.SAGE_DARK))
	col.add_child(_check_row("fullscreen"))
	var res: Array = Array(Settings.RESOLUTIONS)
	col.add_child(_option_row("resolution", res, res))
	var tools: HBoxContainer = UiUtil.hbox()
	tools.add_child(UiUtil.button(tr("UI_SET_TUTORIAL_RESET"), func() -> void: Settings.set_value("tutorial_seen", [])))
	tools.add_child(UiUtil.button(tr("UI_SET_LOGS"), func() -> void:
		OS.shell_open(ProjectSettings.globalize_path("user://logs"))))
	col.add_child(tools)
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.button(tr("UI_SET_RESET"), func() -> void:
		Settings.reset()
		_language_changed()))
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_CLOSE"), queue_free))
	col.add_child(buttons)


func _label(key: String) -> Label:
	var l: Label = UiUtil.label(tr("UI_SET_" + key.to_upper()), 15)
	l.custom_minimum_size.x = 220.0
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
	var c: CheckBox = CheckBox.new()
	c.button_pressed = bool(Settings.get_value(key))
	UiUtil.style_toggle(c)
	c.toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
	row.add_child(c)
	return row


func _language_changed() -> void:
	queue_free()
	if _on_language.is_valid():
		_on_language.call()
