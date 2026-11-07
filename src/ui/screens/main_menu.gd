extends Control
## Ana menü: Yeni oyun, Devam et (en son kayıt), Yükle (3 slot + otomatik), Ayarlar, çıkış (M9).

const GAME_SCENE: String = "res://src/ui/screens/main.tscn"

var _continue_button: Button
var _error_label: Label


func _ready() -> void:
	if str(Settings.get_value("language")).is_empty() and not TranslationServer.get_locale().begins_with("en"):
		TranslationServer.set_locale("tr")
	_build()


func _build() -> void:
	UiUtil.clear(self)
	theme = CozyTheme.get_theme()  # UI-1: Cozy Refined (önce yalnızca ana menü ve finans)
	var bg: ColorRect = ColorRect.new()
	bg.color = CozyTheme.FOREST
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size.x = 420.0
	center.add_child(card)
	var col: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_M)
	card.add_child(col)
	var title: Label = _label(tr("GAME_TITLE"), "TitleLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub: Label = _label(tr("BOOT_SUBTITLE"), "MutedLabel")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	col.add_child(HSeparator.new())
	# Tek birincil (turuncu) eylem: kayıt varsa "Devam et", yoksa "Yeni oyun".
	var has_save: bool = SaveSystem.has_save()
	_continue_button = _menu_button(tr("MENU_CONTINUE"), _on_continue, "PrimaryButton" if has_save else "")
	_continue_button.disabled = not has_save
	var new_button: Button = _menu_button(tr("MENU_NEW_GAME"), _on_new_game, "" if has_save else "PrimaryButton")
	col.add_child(_continue_button if has_save else new_button)
	col.add_child(new_button if has_save else _continue_button)
	var load_button: Button = _menu_button(tr("MENU_LOAD"), func() -> void:
		add_child(SaveLoadDialog.new(false, func() -> void: get_tree().change_scene_to_file(GAME_SCENE))))
	load_button.disabled = not has_save
	col.add_child(load_button)
	col.add_child(_menu_button(tr("MENU_SETTINGS"), func() -> void: add_child(SettingsDialog.new(_build))))
	col.add_child(_menu_button(tr("MENU_QUIT"), func() -> void: get_tree().quit(), "QuietButton"))
	_error_label = _label("", "NegativeLabel")
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.custom_minimum_size.x = 372.0
	_error_label.visible = false
	col.add_child(_error_label)
	if not DataDB.is_ok():
		_show_error(tr("ERR_DATA") + "\n" + "\n".join(DataDB.data.errors))


func _label(text: String, variation: String) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.theme_type_variation = variation
	return l


func _menu_button(text: String, on_press: Callable, variation: String = "") -> Button:
	var b: Button = UiUtil.button(text, on_press)
	b.theme_type_variation = variation
	b.custom_minimum_size.y = 46.0
	return b


func _show_error(text: String) -> void:
	_error_label.text = text
	_error_label.visible = not text.is_empty()


func _on_new_game() -> void:
	if not DataDB.is_ok():
		return
	add_child(BackgroundDialog.new(func(background: String, start_year: int, agency_name: String) -> void:
		GameState.new_game(-1, background, start_year, agency_name)
		get_tree().change_scene_to_file(GAME_SCENE)))


func _on_continue() -> void:
	if GameState.load_game():
		get_tree().change_scene_to_file(GAME_SCENE)
	else:
		_show_error(tr("ERR_SAVE_CORRUPT"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		for i: int in range(get_child_count() - 1, -1, -1):
			if get_child(i).has_meta("esc_closes"):
				get_child(i).queue_free()
				get_viewport().set_input_as_handled()
				return
