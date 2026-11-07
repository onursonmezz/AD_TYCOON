class_name BackgroundDialog
extends Control
## Yeni oyun: ajans adı (M9), başlangıç yılı (GDD 5.1 hızlı başlangıç) ve oyuncunun geçmişi (GDD 11.5).
## on_pick(background, start_year, agency_name).

var _on_pick: Callable
var _start_year: int = 0
var _year_buttons: Array[Button] = []
var _name_edit: LineEdit
var _cards: Array[Button] = []
var _selected: String = ""
var _desc: Label
var _stats: HBoxContainer


func _init(on_pick: Callable) -> void:
	_on_pick = on_pick


func _ready() -> void:
	var data: GameData = DataDB.data
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(720.0, 470.0))
	col.add_child(UiUtil.heading(tr("UI_BACKGROUND_TITLE"), "user"))
	col.add_child(UiUtil.wrapped(tr("UI_BACKGROUND_HINT"), 15, UiUtil.MUTED, 560.0))
	var name_row: HBoxContainer = UiUtil.hbox()
	name_row.add_child(UiUtil.label(tr("UI_AGENCY_NAME"), 15))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = tr("UI_DEFAULT_AGENCY")
	_name_edit.max_length = 32
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_name_edit)
	col.add_child(name_row)
	var years: HBoxContainer = UiUtil.hbox()
	years.add_child(UiUtil.label(tr("UI_START_YEAR"), 15))
	for y: Variant in data.bal("tools.start_years"):
		var year: int = int(y)
		var b: Button = UiUtil.button(str(year), func() -> void: _set_year(year))
		b.toggle_mode = true
		b.set_meta("year", year)
		_year_buttons.append(b)
		years.add_child(b)
	col.add_child(years)
	col.add_child(UiUtil.wrapped(tr("UI_START_YEAR_HINT"), 13, UiUtil.MUTED, 560.0))
	_set_year(int(data.bal("tools.start_years")[0]))
	# UI-2d: geçmişler yan yana portre kartları; seçilenin açıklaması, statları ve "Bu geçmişi seç" altta.
	var cards: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(cards)
	for id: String in data.background_ids:
		var card: Button = Button.new()
		card.toggle_mode = true
		card.custom_minimum_size = Vector2(150.0, 178.0)
		card.theme_type_variation = "PickCard"
		card.pressed.connect(func() -> void: _select(id))
		card.set_meta("bg", id)
		var inner: VBoxContainer = UiUtil.vbox(6)
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(inner)
		inner.add_child(_portrait(id))
		var name: Label = UiUtil.label(tr(data.backgrounds[id]["name_key"]), 15, CozyTheme.TEXT)
		name.add_theme_font_override("font", CozyTheme.strong_font(800))
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(name)
		_cards.append(card)
		cards.add_child(card)
	_desc = UiUtil.wrapped("", 15, CozyTheme.TEXT, 560.0)
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_desc)
	_stats = UiUtil.hbox(CozyTheme.SPACE_S)
	_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(_stats)
	var buttons: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_CANCEL"), queue_free))
	var pick: Button = UiUtil.button(tr("UI_PICK_BACKGROUND"), func() -> void: _on_pick.call(_selected, _start_year, _name_edit.text))
	pick.theme_type_variation = "PrimaryButton"
	pick.icon = UiUtil.icon_texture("check", 20)
	buttons.add_child(pick)
	col.add_child(buttons)
	_select(data.background_ids[0])


## Portre: assets/ui/portraits/<id>.png varsa o, yoksa krem daire içinde kişi ikonu.
func _portrait(id: String) -> Control:
	var path: String = "res://assets/ui/portraits/%s.png" % id
	var box: PanelContainer = PanelContainer.new()
	box.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM, 10, CozyTheme.BORDER, 1, false, Vector2(4, 4)))
	box.custom_minimum_size = Vector2(0.0, 104.0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: TextureRect = TextureRect.new()
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if ResourceLoader.exists(path):
		tex.texture = load(path) as Texture2D
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:
		tex.texture = UiUtil.icon_texture("user", 56)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		tex.modulate = CozyTheme.SAGE
	box.add_child(tex)
	return box


func _select(id: String) -> void:
	_selected = id
	var data: GameData = DataDB.data
	var bg: Dictionary = data.backgrounds[id]
	for c: Button in _cards:
		c.set_pressed_no_signal(str(c.get_meta("bg")) == id)
		c.theme_type_variation = "PickCardActive" if str(c.get_meta("bg")) == id else "PickCard"
	_desc.text = tr(bg["desc_key"])
	UiUtil.clear(_stats)
	for stat: Variant in data.bal("staff_rules.stats"):
		var chip: PanelContainer = PanelContainer.new()
		chip.theme_type_variation = "Badge"
		chip.add_child(UiUtil.label("%s %d" % [tr("STAT_" + str(stat).to_upper()), int(bg["stats"][stat])], 14))
		_stats.add_child(chip)


func _set_year(year: int) -> void:
	_start_year = year
	for b: Button in _year_buttons:
		b.set_pressed_no_signal(int(b.get_meta("year")) == year)
