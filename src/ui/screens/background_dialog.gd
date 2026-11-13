class_name BackgroundDialog
extends Control
## Yeni oyun sayfaları (A1), tam ekran, iki adım:
##   1) "Sen kimsin?": ajans adı (M9), başlangıç yılı (GDD 5.1 hızlı başlangıç), kurucunun geçmişi (GDD 11.5).
##   2) "Karakterini oluştur": avatar ve kurucunun adı.
## on_done(background, start_year, agency_name, founder); founder = { "name", "avatar" }.

const LABEL_WIDTH: float = 150.0
const PREVIEW_SIZE: Vector2 = Vector2(210.0, 187.0)

var _on_done: Callable
var _step: int = 1
var _page: VBoxContainer
var _start_year: int = 0
var _agency_name: String = ""
var _founder_name: String = ""
var _background: String = ""
var _avatar: String = ""
var _year_buttons: Array[Button] = []
var _cards: Array[Button] = []
var _desc: Label
var _stats: HBoxContainer
var _preview: VBoxContainer


func _init(on_done: Callable) -> void:
	_on_done = on_done


func _ready() -> void:
	var data: GameData = DataDB.data
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_meta("esc_closes", true)
	add_child(MenuArt.backdrop(0.2))
	# İçerik sütunu: arka plandaki boş duvarın üstünde.
	var frame: MarginContainer = MarginContainer.new()
	frame.anchor_left = 0.275
	frame.anchor_right = 0.815
	frame.anchor_top = 0.025
	frame.anchor_bottom = 0.955
	add_child(frame)
	_page = UiUtil.vbox(CozyTheme.SPACE_S)
	frame.add_child(_page)
	_start_year = int(data.bal("tools.start_years")[0])
	_background = data.background_ids[0]
	var avatars: Array = avatar_ids()
	_avatar = str(avatars[0]) if not avatars.is_empty() else ""
	show_step(1)


static func avatar_ids() -> Array:
	return (DataDB.data.raw.get("avatars.json", []) as Array).map(func(rec: Variant) -> String: return str(rec["id"]))


func show_step(step: int) -> void:
	_step = step
	UiUtil.clear(_page)
	_cards.clear()
	_year_buttons.clear()
	var logo: Label = MenuArt.logo_label(tr("GAME_TITLE"), 26)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page.add_child(logo)
	if step == 1:
		_build_background()
	else:
		_build_character()


# --- 1. adım: geçmiş -----------------------------------------------------------------

func _build_background() -> void:
	var data: GameData = DataDB.data
	_page.add_child(MenuArt.tape(tr("UI_BACKGROUND_TITLE"), "user"))
	_page.add_child(UiUtil.wrapped(tr("UI_BACKGROUND_HINT"), 15, CozyTheme.TEXT, 400.0))
	var name_edit: LineEdit = _edit(_agency_name, tr("UI_DEFAULT_AGENCY"), func(t: String) -> void: _agency_name = t)
	_page.add_child(_row(tr("UI_AGENCY_NAME"), name_edit))
	var years: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	for y: Variant in data.bal("tools.start_years"):
		var year: int = int(y)
		var b: Button = UiUtil.button(str(year), func() -> void: _set_year(year))
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(88.0, 38.0)
		b.set_meta("year", year)
		_year_buttons.append(b)
		years.add_child(b)
	_page.add_child(_row(tr("UI_START_YEAR"), years))
	_page.add_child(UiUtil.wrapped(tr("UI_START_YEAR_HINT"), 13, CozyTheme.MUTED, 400.0))
	_set_year(_start_year)
	var cards: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page.add_child(cards)
	for id: String in data.background_ids:
		cards.add_child(_pick_card(id, MenuArt.portrait_path(id), tr(data.backgrounds[id]["name_key"]),
			Vector2(0.0, 190.0), func() -> void: _select_background(id)))
	_desc = UiUtil.wrapped("", 16, CozyTheme.TEXT, 400.0)
	_desc.add_theme_font_override("font", CozyTheme.strong_font(800))
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page.add_child(_desc)
	_stats = UiUtil.hbox(CozyTheme.SPACE_S)
	_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	_page.add_child(_stats)
	_page.add_child(_buttons(tr("UI_CANCEL"), queue_free, tr("MENU_CONTINUE"), func() -> void: show_step(2)))
	_select_background(_background)


func _select_background(id: String) -> void:
	_background = id
	var data: GameData = DataDB.data
	var bg: Dictionary = data.backgrounds[id]
	_mark(id)
	_desc.text = tr(bg["desc_key"])
	UiUtil.clear(_stats)
	# Her stat tam adıyla; üzerine gelince ne işe yaradığı yazar.
	for stat: Variant in data.bal("staff_rules.stats"):
		var key: String = "STAT_" + str(stat).to_upper()
		var chip: PanelContainer = PanelContainer.new()
		chip.theme_type_variation = "Badge"
		chip.tooltip_text = "%s: %s" % [tr(key + "_NAME"), tr(key + "_DESC")]
		var row: HBoxContainer = UiUtil.hbox(6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(UiUtil.label(tr(key + "_NAME"), 13, CozyTheme.MUTED))
		var value: Label = UiUtil.label(str(int(bg["stats"][stat])), 15, CozyTheme.TEXT)
		value.add_theme_font_override("font", CozyTheme.strong_font(800))
		row.add_child(value)
		chip.add_child(row)
		_stats.add_child(chip)


func _set_year(year: int) -> void:
	_start_year = year
	for b: Button in _year_buttons:
		var on: bool = int(b.get_meta("year")) == year
		b.set_pressed_no_signal(on)
		var style: StyleBoxFlat = CozyTheme.box(CozyTheme.FOREST if on else CozyTheme.CREAM_LIGHT, CozyTheme.RADIUS_CARD,
			CozyTheme.FOREST if on else CozyTheme.BORDER, 1, false, Vector2(CozyTheme.SPACE_L, 6))
		for st: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			b.add_theme_stylebox_override(st, style)
		for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, CozyTheme.CREAM_LIGHT if on else CozyTheme.TEXT)


# --- 2. adım: karakter ---------------------------------------------------------------

func _build_character() -> void:
	_page.add_child(MenuArt.tape(tr("UI_FOUNDER_TITLE"), "user"))
	_page.add_child(UiUtil.wrapped(tr("UI_FOUNDER_HINT"), 15, CozyTheme.TEXT, 400.0))
	var name_edit: LineEdit = _edit(_founder_name, tr("UI_DEFAULT_FOUNDER"), func(t: String) -> void:
		_founder_name = t
		_refresh_preview())
	_page.add_child(_row(tr("UI_FOUNDER_NAME"), name_edit))
	var split: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_L)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page.add_child(split)
	# Solda seçilen avatarın büyük hâli ve yazılan ad.
	_preview = UiUtil.vbox(CozyTheme.SPACE_S)
	_preview.custom_minimum_size.x = PREVIEW_SIZE.x
	split.add_child(_preview)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", CozyTheme.SPACE_S)
	grid.add_theme_constant_override("v_separation", CozyTheme.SPACE_S)
	split.add_child(grid)
	for id: Variant in avatar_ids():
		var avatar: String = str(id)
		var card: Button = _pick_card(avatar, MenuArt.avatar_path(avatar), "", Vector2(0.0, 92.0),
			func() -> void: _select_avatar(avatar))
		card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		grid.add_child(card)
	_page.add_child(_buttons(tr("UI_BACK"), func() -> void: show_step(1), tr("UI_START_GAME"), func() -> void:
		_on_done.call(_background, _start_year, _agency_name, {"name": _founder_name, "avatar": _avatar})))
	_select_avatar(_avatar)
	name_edit.grab_focus.call_deferred()


func _select_avatar(id: String) -> void:
	_avatar = id
	_mark(id)
	_refresh_preview()


func _refresh_preview() -> void:
	UiUtil.clear(_preview)
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = "Card"
	_preview.add_child(card)
	var col: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	card.add_child(col)
	col.add_child(MenuArt.picture(MenuArt.avatar_path(_avatar), PREVIEW_SIZE))
	var shown: String = _founder_name.strip_edges()
	var name: Label = UiUtil.label(shown if not shown.is_empty() else tr("UI_DEFAULT_FOUNDER"), 20, CozyTheme.FOREST)
	name.add_theme_font_override("font", CozyTheme.title_font(800))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.clip_text = true
	col.add_child(name)
	var role: Label = UiUtil.label(tr(DataDB.data.backgrounds[_background]["name_key"]), 14, CozyTheme.WOOD)
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(role)


# --- ortak ---------------------------------------------------------------------------

func _mark(id: String) -> void:
	for c: Button in _cards:
		var on: bool = str(c.get_meta("pick")) == id
		c.set_pressed_no_signal(on)
		c.theme_type_variation = "PickCardActive" if on else "PickCard"


## Seçim kartı: çerçeveli resim, altında (varsa) ad.
func _pick_card(id: String, image: String, caption: String, picture_size: Vector2, on_press: Callable) -> Button:
	var card: Button = Button.new()
	card.toggle_mode = true
	card.theme_type_variation = "PickCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.pressed.connect(on_press)
	card.set_meta("pick", id)
	UiUtil.add_hover(card)
	var inner: VBoxContainer = UiUtil.vbox(6)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(inner)
	var pic: PanelContainer = MenuArt.picture(image, picture_size)
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(pic)
	var extra: float = 20.0
	if not caption.is_empty():
		var name: Label = UiUtil.label(caption, 15, CozyTheme.TEXT)
		name.add_theme_font_override("font", CozyTheme.strong_font(800))
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name.custom_minimum_size.y = 40.0
		name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(name)
		extra += 46.0
	card.custom_minimum_size = Vector2(96.0, picture_size.y + extra)
	_cards.append(card)
	return card


func _edit(text: String, placeholder: String, on_change: Callable) -> LineEdit:
	var e: LineEdit = LineEdit.new()
	e.text = text
	e.placeholder_text = placeholder
	e.max_length = 32
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e.text_changed.connect(on_change)
	return e


func _row(caption: String, control: Control) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var l: Label = UiUtil.label(caption, 16, CozyTheme.TEXT)
	l.add_theme_font_override("font", CozyTheme.strong_font(800))
	l.custom_minimum_size.x = LABEL_WIDTH
	row.add_child(l)
	row.add_child(control)
	return row


func _buttons(back_text: String, on_back: Callable, next_text: String, on_next: Callable) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	row.add_child(UiUtil.spacer())
	var back: Button = UiUtil.button(back_text, on_back)
	back.custom_minimum_size = Vector2(120.0, 46.0)
	row.add_child(back)
	var next: Button = UiUtil.button(next_text, on_next)
	next.theme_type_variation = "PrimaryButton"
	next.icon = UiUtil.icon_texture("player-play", 20)
	next.custom_minimum_size = Vector2(180.0, 46.0)
	row.add_child(next)
	return row
