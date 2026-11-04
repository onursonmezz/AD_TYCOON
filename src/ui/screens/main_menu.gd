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
	var bg: ColorRect = ColorRect.new()
	bg.color = UiUtil.CREAM
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col: VBoxContainer = UiUtil.vbox(14)
	col.custom_minimum_size.x = 360.0
	center.add_child(col)
	var title: Label = UiUtil.label(tr("GAME_TITLE"), 60, UiUtil.SAGE_DARK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub: Label = UiUtil.label(tr("BOOT_SUBTITLE"), 22, UiUtil.WOOD)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	col.add_child(UiUtil.label(" ", 10))
	col.add_child(UiUtil.button(tr("MENU_NEW_GAME"), _on_new_game))
	_continue_button = UiUtil.button(tr("MENU_CONTINUE"), _on_continue)
	_continue_button.disabled = not SaveSystem.has_save()
	col.add_child(_continue_button)
	var load_button: Button = UiUtil.button(tr("MENU_LOAD"), func() -> void:
		add_child(SaveLoadDialog.new(false, func() -> void: get_tree().change_scene_to_file(GAME_SCENE))))
	load_button.disabled = not SaveSystem.has_save()
	col.add_child(load_button)
	col.add_child(UiUtil.button(tr("MENU_SETTINGS"), func() -> void: add_child(SettingsDialog.new(_build))))
	col.add_child(UiUtil.button(tr("MENU_QUIT"), func() -> void: get_tree().quit()))
	_error_label = UiUtil.wrapped("", 14, UiUtil.TERRACOTTA, 360.0)
	col.add_child(_error_label)
	if not DataDB.is_ok():
		_error_label.text = tr("ERR_DATA") + "\n" + "\n".join(DataDB.data.errors)


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
		_error_label.text = tr("ERR_SAVE_CORRUPT")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		for i: int in range(get_child_count() - 1, -1, -1):
			if get_child(i).has_meta("esc_closes"):
				get_child(i).queue_free()
				get_viewport().set_input_as_handled()
				return
