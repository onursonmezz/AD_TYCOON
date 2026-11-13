extends Control
## Ana menü (A1): oda illüstrasyonu üstünde logo, kâğıt etiket ve ikonlu düğmeler.
## Yeni oyun, Devam et (en son kayıt), Yükle (3 slot + otomatik), Ayarlar, çıkış (M9).

const GAME_SCENE: String = "res://src/ui/screens/main.tscn"
const BUTTON_SIZE: Vector2 = Vector2(340.0, 54.0)

var _continue_button: Button
var _error_label: Label


func _ready() -> void:
	if str(Settings.get_value("language")).is_empty() and not TranslationServer.get_locale().begins_with("en"):
		TranslationServer.set_locale("tr")
	_build()


func _build() -> void:
	UiUtil.clear(self)
	add_child(MenuArt.backdrop())
	# Menü sütunu: illüstrasyondaki boş duvarın ortasında (resim yoksa ekranın ortasında).
	var has_art: bool = MenuArt.texture() != null
	var side: CenterContainer = CenterContainer.new()
	side.anchor_left = 0.4 if has_art else 0.0
	side.anchor_right = 0.82 if has_art else 1.0
	side.anchor_bottom = 1.0
	add_child(side)
	var col: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_M)
	col.custom_minimum_size.x = BUTTON_SIZE.x
	side.add_child(col)
	col.add_child(_logo())
	# Alt başlık: hafif eğik krem kâğıt etiket.
	var tag: Control = MenuArt.tape(tr("BOOT_SUBTITLE"), "", 17, -3.0)
	(tag as HBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(tag)
	var gap: Control = Control.new()
	gap.custom_minimum_size.y = CozyTheme.SPACE_S
	col.add_child(gap)
	# Tek birincil (turuncu) eylem: kayıt varsa "Devam et", yoksa "Yeni oyun".
	var has_save: bool = SaveSystem.has_save()
	_continue_button = _menu_button(tr("MENU_CONTINUE"), "player-track-next", _on_continue,
		"PrimaryButton" if has_save else "")
	_continue_button.disabled = not has_save
	var new_button: Button = _menu_button(tr("MENU_NEW_GAME"), "player-play", _on_new_game,
		"" if has_save else "PrimaryButton")
	col.add_child(_continue_button if has_save else new_button)
	col.add_child(new_button if has_save else _continue_button)
	var load_button: Button = _menu_button(tr("MENU_LOAD"), "folder-open", func() -> void:
		add_child(SaveLoadDialog.new(false, func() -> void: get_tree().change_scene_to_file(GAME_SCENE))))
	load_button.disabled = not has_save
	col.add_child(load_button)
	col.add_child(_menu_button(tr("MENU_SETTINGS"), "settings", func() -> void: add_child(SettingsDialog.new(_build))))
	col.add_child(_menu_button(tr("MENU_QUIT"), "logout", func() -> void: get_tree().quit()))
	_error_label = _label("", "NegativeLabel")
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.custom_minimum_size.x = BUTTON_SIZE.x
	_error_label.visible = false
	col.add_child(_error_label)
	if not DataDB.is_ok():
		_show_error(tr("ERR_DATA") + "\n" + "\n".join(DataDB.data.errors))


## Logo: iki satır eğik serif yazı, yanında turuncu megafon.
func _logo() -> Control:
	var words: PackedStringArray = tr("GAME_TITLE").split(" ", false, 1)
	var box: VBoxContainer = UiUtil.vbox(-22)
	var top: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(MenuArt.logo_label(words[0], 84))
	top.add_child(UiUtil.icon("speakerphone", 64, CozyTheme.ACCENT))
	box.add_child(top)
	if words.size() > 1:
		var second: Label = MenuArt.logo_label(words[1], 84)
		second.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(second)
	var center: CenterContainer = CenterContainer.new()
	center.add_child(MenuArt.tilted(box, -4.0))
	return center


func _label(text: String, variation: String) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.theme_type_variation = variation
	return l


func _menu_button(text: String, icon_name: String, on_press: Callable, variation: String = "") -> Button:
	var b: Button = UiUtil.button(text, on_press)
	b.theme_type_variation = variation
	b.custom_minimum_size = BUTTON_SIZE
	b.add_theme_font_size_override("font_size", 20)
	b.icon = UiUtil.icon_texture(icon_name, 26)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("h_separation", CozyTheme.SPACE_L)
	return b


func _show_error(text: String) -> void:
	_error_label.text = text
	_error_label.visible = not text.is_empty()


func _on_new_game() -> void:
	if not DataDB.is_ok():
		return
	add_child(BackgroundDialog.new(func(background: String, start_year: int, agency_name: String, founder: Dictionary) -> void:
		GameState.new_game(-1, background, start_year, agency_name, founder)
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
