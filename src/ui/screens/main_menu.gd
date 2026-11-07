extends Control
## Ana menü: Yeni oyun, Devam et (en son kayıt), Yükle (3 slot + otomatik), Ayarlar, çıkış (M9).

const GAME_SCENE: String = "res://src/ui/screens/main.tscn"
const BACKGROUND: String = "res://assets/ui/menu_background"  # .png, .jpg ya da .webp

var _continue_button: Button
var _error_label: Label


func _ready() -> void:
	if str(Settings.get_value("language")).is_empty() and not TranslationServer.get_locale().begins_with("en"):
		TranslationServer.set_locale("tr")
	_build()


func _build() -> void:
	UiUtil.clear(self)
	# Arka plan: illüstrasyon varsa (art/ai_rehberi.md "Ana menü illüstrasyonu"), yoksa koyu yeşil.
	var bg: ColorRect = ColorRect.new()
	bg.color = CozyTheme.FOREST
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var tex: Texture2D = _background()
	if tex != null:
		var art: TextureRect = TextureRect.new()
		art.texture = tex
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(art)
	# Sağda menü sütunu (referans: logo, kâğıt etiket, ikonlu düğmeler).
	var side: CenterContainer = CenterContainer.new()
	side.anchor_left = 0.56 if tex != null else 0.0  # illüstrasyon yoksa ortada
	side.anchor_right = 0.96 if tex != null else 1.0
	side.anchor_bottom = 1.0
	add_child(side)
	var col: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_M)
	col.custom_minimum_size.x = 340.0
	side.add_child(col)
	var title: Label = _label(tr("GAME_TITLE"), "TitleLabel")
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", CozyTheme.CREAM_LIGHT)
	title.add_theme_color_override("font_outline_color", CozyTheme.FOREST)
	title.add_theme_constant_override("outline_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	# Alt başlık: hafif eğik krem kâğıt etiket.
	var tag_holder: CenterContainer = CenterContainer.new()
	col.add_child(tag_holder)
	var tag: PanelContainer = PanelContainer.new()
	tag.theme_type_variation = "Card"
	tag.rotation_degrees = -3.0
	tag_holder.add_child(tag)
	tag.resized.connect(func() -> void: tag.pivot_offset = tag.size * 0.5)
	var sub: Label = _label(tr("BOOT_SUBTITLE"), "CardHeading")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_child(sub)
	col.add_child(UiUtil.spacer())
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
	_error_label.custom_minimum_size.x = 340.0
	_error_label.visible = false
	col.add_child(_error_label)
	if not DataDB.is_ok():
		_show_error(tr("ERR_DATA") + "\n" + "\n".join(DataDB.data.errors))


## Ana menü illüstrasyonu (Orgo'nun görsel AI ile ürettiği); yoksa null.
func _background() -> Texture2D:
	for ext: String in ["png", "jpg", "webp"]:
		var path: String = "%s.%s" % [BACKGROUND, ext]
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


func _label(text: String, variation: String) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.theme_type_variation = variation
	return l


func _menu_button(text: String, icon_name: String, on_press: Callable, variation: String = "") -> Button:
	var b: Button = UiUtil.button(text, on_press)
	b.theme_type_variation = variation
	b.custom_minimum_size.y = 50.0
	b.icon = UiUtil.icon_texture(icon_name, 22)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("h_separation", CozyTheme.SPACE_L)
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
