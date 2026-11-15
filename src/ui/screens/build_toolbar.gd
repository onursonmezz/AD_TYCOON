class_name BuildToolbar
extends PanelContainer
## İnşa modu araç çubuğu (M6-B): mobilya paleti, oda çizme (büyütülmüş ofisten), kaldırma; ofisin altında durur.
## OfficeView'in isteklerini komutlara çevirir, sonucu/hata nedenini gösterir. Paletin solunda sabit duran "Sil / sat"
## düğmesi ve iki döndürme düğmesi (eşya seçiliyken) var; Delete tuşu imlecin altındaki eşyayı satar.

var _view: OfficeView
var _on_exit: Callable
var _status: Label
var _quality: Label
var _tool_buttons: Array[Button] = []
var _rotate_buttons: Array[Button] = []
var _cat_row: HBoxContainer
var _palette: HBoxContainer
var _category: String = "all"
var _previewing: bool = false  # durum satırında satış önizlemesi var (eşyadan çıkınca ipucuna döner)

const CARD_SIZE: Vector2 = Vector2(80.0, 78.0)
const ART_SIZE: int = 44
const CATEGORIES: Array = [["all", "UI_BUILD_CAT_ALL"], ["plants", "UI_BUILD_CAT_PLANTS"], ["other", "UI_BUILD_CAT_OTHER"]]


func _init(view: OfficeView, on_exit: Callable) -> void:
	_view = view
	_on_exit = on_exit


func _ready() -> void:
	# UI-3 (taslak 20): iki kutu yan yana, sabit boyda (data/ui_layout.json "build_bar").
	# Solda araçlar ve durum; sağda kategori sekmeleri ve eşya kartları.
	var bar: Dictionary = DataDB.data.raw["ui_layout.json"]["build_bar"]
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var split: HBoxContainer = UiUtil.hbox(int(bar["gap"]))
	add_child(split)
	split.add_child(_tools_box(float(bar["tools_width"])))
	var right: PanelContainer = PanelContainer.new()
	right.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM_LIGHT, 11, CozyTheme.BORDER, 1, true, Vector2(8.0, 5.0)))
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right)
	var col: VBoxContainer = UiUtil.vbox(3)
	right.add_child(col)
	var top: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	_cat_row = UiUtil.hbox()
	_cat_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_cat_row)
	var done: Button = UiUtil.button(tr("UI_BUILD_DONE"), _exit)
	done.theme_type_variation = "PrimaryButton"
	done.add_theme_font_size_override("font_size", 13)
	done.custom_minimum_size = Vector2(54.0, 24.0)
	done.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(done)
	col.add_child(top)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_palette = UiUtil.hbox(4)
	scroll.add_child(_palette)
	col.add_child(scroll)
	col.add_child(UiUtil.label(tr("UI_BUILD_KEYS"), 10, UiUtil.MUTED))
	_fill_palette("all")
	_view.place_requested.connect(_on_place)
	_view.room_requested.connect(_on_room)
	_view.remove_requested.connect(_on_remove)
	_view.wall_requested.connect(func(a: Vector2, b: Vector2) -> void:
		_after(GameState.execute(BuildWallCommand.new(a, b)), "UI_BUILD_WALL_DONE"))
	_view.door_requested.connect(func(p: Vector2) -> void:
		_after(GameState.execute(BuildDoorCommand.new(p)), "UI_BUILD_DOOR_DONE"))
	_view.hover_changed.connect(func(key: String) -> void:
		_show(key if not key.is_empty() else "UI_BUILD_OK", key.is_empty()))
	_view.remove_hover.connect(_on_remove_hover)
	_refresh_quality()


## Sol kutu: yeşil başlık, oda kalitesi, büyük araç düğmeleri (döndür, sat), altında geri / ileri döndürme ve durum.
func _tools_box(width: float) -> PanelContainer:
	var box: PanelContainer = PanelContainer.new()
	box.custom_minimum_size.x = width
	box.theme_type_variation = "WindowPanel"
	var col: VBoxContainer = UiUtil.vbox(0)
	box.add_child(col)
	var band: PanelContainer = PanelContainer.new()
	var band_style: StyleBoxFlat = CozyTheme.box(CozyTheme.FOREST, 11, Color.TRANSPARENT, 0, false, Vector2(10.0, 3.0))
	band_style.corner_radius_bottom_left = 0
	band_style.corner_radius_bottom_right = 0
	band.add_theme_stylebox_override("panel", band_style)
	var head: HBoxContainer = UiUtil.hbox(6)
	band.add_child(head)
	head.add_child(UiUtil.icon("tool", 14, CozyTheme.CREAM_LIGHT))
	var title: Label = UiUtil.label(tr("UI_BUILD_TITLE"), 13, CozyTheme.CREAM_LIGHT)
	title.add_theme_font_override("font", CozyTheme.title_font(700))
	head.add_child(title)
	col.add_child(band)
	var pad: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 8 if side != "top" else 4)
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(pad)
	var body: VBoxContainer = UiUtil.vbox(4)
	pad.add_child(body)
	_quality = UiUtil.label("", 11, CozyTheme.TEXT)
	_quality.clip_text = true
	body.add_child(_quality)
	var tiles: HBoxContainer = UiUtil.hbox(4)
	tiles.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(tiles)
	var rotate: Button = _tile("refresh", tr("UI_BUILD_ROTATE"), func() -> void: _view.rotate_tool(1))
	rotate.disabled = true
	_rotate_buttons.append(rotate)
	tiles.add_child(rotate)
	var remove: Button = _tile("trash", tr("UI_BUILD_SELL"), func() -> void: _select({"kind": "remove"}))
	remove.toggle_mode = true
	remove.set_meta("tool", "remove")
	_tool_buttons.append(remove)
	tiles.add_child(remove)
	var foot: HBoxContainer = UiUtil.hbox(4)
	for d: int in [-1, 1]:
		var rb: Button = UiUtil.button("", func() -> void: _view.rotate_tool(d))
		rb.icon = UiUtil.icon_texture("rotate-left" if d < 0 else "rotate-right", 12)
		rb.tooltip_text = tr("UI_BUILD_ROTATE_LEFT" if d < 0 else "UI_BUILD_ROTATE_RIGHT")
		rb.custom_minimum_size = Vector2(26.0, 22.0)
		for state: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			rb.add_theme_color_override(state, CozyTheme.FOREST)
		rb.add_theme_color_override("icon_disabled_color", Color(UiUtil.MUTED, 0.45))
		rb.add_theme_stylebox_override("normal", CozyTheme.box(CozyTheme.CREAM_LIGHT, 6, CozyTheme.BORDER, 1, false, Vector2(4.0, 2.0)))
		rb.disabled = true
		_rotate_buttons.append(rb)
		foot.add_child(rb)
	_status = UiUtil.label(tr("UI_BUILD_PICK"), 10, UiUtil.TEXT)
	_status.clip_text = true
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_status)
	body.add_child(foot)
	return box


## Büyük araç düğmesi: üstte kiremit ikon, altında adı.
func _tile(icon_name: String, caption: String, on_press: Callable) -> Button:
	var b: Button = UiUtil.button("", on_press)
	b.theme_type_variation = "PickCard"
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = 44.0
	var inner: VBoxContainer = UiUtil.vbox(0)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 3)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(inner)
	var ic: TextureRect = UiUtil.icon(icon_name, 20, CozyTheme.TERRA)
	ic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(ic)
	var l: Label = UiUtil.label(caption, 10, CozyTheme.TERRA)
	l.add_theme_font_override("font", CozyTheme.strong_font())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(l)
	return b


## Kategori sekmeleri ve kartlar. Eşya kategorisi "decor" alanından (bitkiler / diğer); "Odalar" oda çizme türleri.
func _fill_palette(category: String) -> void:
	_category = category
	UiUtil.clear(_cat_row)
	var sim: Simulation = GameState.sim
	var tabs: Array = CATEGORIES.duplicate()
	tabs.append(["walls", "UI_BUILD_CAT_WALLS"])
	if sim.build.can_build_rooms(sim.state):
		tabs.append(["rooms", "UI_BUILD_CAT_ROOMS"])
	var seg: PanelContainer = UiUtil.segmented(tabs, _category, _fill_palette)
	for b: Node in seg.get_child(0).get_children():
		(b as Button).add_theme_font_size_override("font_size", 12)
		(b as Button).add_theme_constant_override("h_separation", 4)
	_cat_row.add_child(seg)
	for b: Button in _tool_buttons.duplicate():
		if b.get_parent() == _palette:
			_tool_buttons.erase(b)
	UiUtil.clear(_palette)
	var current: String = str(_view.build_tool.get("id", ""))
	if category == "walls":
		# K-116: iç duvar çek (metre başı) ve duvara kapı aç; silmek için "Sat" aracı.
		_palette.add_child(_card("wall", "", tr("UI_BUILD_WALL"), tr("UI_BUILD_PER_M") % UiUtil.money(sim.walls.wall_cost_per_m(sim.state)),
			current, {"kind": "wall", "id": "wall"}, "wall"))
		_palette.add_child(_card("door", "", tr("UI_BUILD_DOOR"), UiUtil.money(sim.walls.door_cost(sim.state)), current,
			{"kind": "door", "id": "door"}, "door"))
		return
	if category == "rooms":
		for type: String in DataDB.data.room_type_ids:
			if bool(DataDB.data.room_types[type]["buildable"]):
				_palette.add_child(_card("room:" + type, "", UiUtil.name_of(DataDB.data.room_types, type),
					"%s/m²" % UiUtil.money(sim.build.room_cost(sim.state, type, Rect2(0, 0, 1, 1))), current,
					{"kind": "room", "type": type, "id": "room:" + type}))
		return
	var art: Dictionary = DataDB.data.raw["ui_layout.json"]["furniture_art"]
	for id: String in sim.build.available_furniture(sim.state):
		var plant: bool = str(DataDB.data.furniture[id].get("decor", "")) == "plant"
		if (category == "plants" and not plant) or (category == "other" and plant):
			continue
		_palette.add_child(_card(id, str(art.get(id, "")), UiUtil.name_of(DataDB.data.furniture, id),
			UiUtil.money(sim.build.furniture_cost(sim.state, id)), current, {"kind": "furniture", "id": id, "rot": 0},
			"plant" if plant else "building"))


## Palet kartı: resim (yoksa ikon), ad, fiyat. Seçilen kart yeşil çerçeveli.
const THUMBS: String = "res://assets/ui/thumbs"


func _card(id: String, art_file: String, caption: String, price_text: String, current: String, tool: Dictionary,
		fallback_icon: String = "building") -> Button:
	var b: Button = Button.new()
	b.toggle_mode = true
	b.theme_type_variation = "PickCardActive" if id == current else "PickCard"
	b.custom_minimum_size = CARD_SIZE
	b.set_meta("tool", id)
	b.button_pressed = id == current
	b.pressed.connect(func() -> void: _select(tool))
	b.tooltip_text = caption
	var inner: VBoxContainer = UiUtil.vbox(0)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(inner)
	var picture: Texture2D = IconPack.art(art_file, ART_SIZE) if not art_file.is_empty() else null
	# UI-4: çizimi olmayan eşyada modelden üretilmiş küçük resim (tools/furniture_thumbs.gd).
	var thumb: String = THUMBS.path_join(id + ".png")
	if picture == null and ResourceLoader.exists(thumb):
		picture = load(thumb)
	var ic: TextureRect = UiUtil.icon(fallback_icon, 26, CozyTheme.TERRA)
	if picture != null:
		ic.texture = picture
		ic.modulate = Color.WHITE
	ic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(ic)
	var name: Label = UiUtil.label(caption, 10, CozyTheme.TEXT)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # uzun ad iki satıra iner (kesilmez)
	name.max_lines_visible = 2
	name.add_theme_constant_override("line_spacing", -3)
	inner.add_child(name)
	var price: Label = UiUtil.label(price_text, 10, CozyTheme.FOREST)
	price.add_theme_font_override("font", CozyTheme.strong_font())
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(price)
	_tool_buttons.append(b)
	return b


func _select(tool: Dictionary) -> void:
	_view.set_tool(tool)
	for rb: Button in _rotate_buttons:
		rb.disabled = tool.get("kind", "") != "furniture"
	var key: String = str(tool.get("id", tool.get("kind", "")))
	for b: Button in _tool_buttons:
		b.set_pressed_no_signal(str(b.get_meta("tool")) == key)
		if b.get_parent() == _palette:
			b.theme_type_variation = "PickCardActive" if str(b.get_meta("tool")) == key else "PickCard"
	_show("UI_BUILD_PICK_" + str(tool["kind"]).to_upper(), true)


func _show(key: String, ok: bool) -> void:
	_previewing = false
	_status.text = tr(key)
	_status.add_theme_color_override("font_color", UiUtil.SAGE_DARK if ok else UiUtil.TERRACOTTA)


func _refresh_quality() -> void:
	var s: SimState = GameState.sim.state
	_quality.text = tr("UI_BUILD_QUALITY_SHORT") % [s.room_quality, UiUtil.num(Employee.office_mult(DataDB.data, s.room_quality), 2)]


func _on_place(id: String, pos: Vector2, rot: int) -> void:
	var err: String = GameState.execute(PlaceFurnitureCommand.new(id, pos, rot))
	_show(err if not err.is_empty() else "UI_BUILD_PLACED", err.is_empty())
	_refresh_quality()


func _on_room(type: String, rect: Rect2) -> void:
	var err: String = GameState.execute(BuildRoomCommand.new(type, rect))
	_show(err if not err.is_empty() else "UI_BUILD_ROOM_DONE", err.is_empty())
	_refresh_quality()


## Noktadaki oyuncu eşyasını satar (halının üstündeki eşya önce). Satıldıysa true.
func _sell_at(p: Vector2) -> bool:
	var sim: Simulation = GameState.sim
	var prop: Dictionary = sim.build.layout(sim.state).furniture_at(p)
	if prop.is_empty():
		return false
	GameState.execute(SellFurnitureCommand.new(int(prop["index"])))
	_show("UI_BUILD_SOLD", true)
	_refresh_quality()
	return true


## Duvar / kapı işleminden sonra durum satırı (hata ya da başarı) ve kalite.
func _after(err: String, done_key: String) -> void:
	_show(err if not err.is_empty() else done_key, err.is_empty())
	_refresh_quality()


## Önce mobilya, sonra kapı ya da iç duvar, yoksa çizilmiş oda kaldırılır.
func _on_remove(p: Vector2) -> void:
	var sim: Simulation = GameState.sim
	if _sell_at(p):
		return
	var was_door: bool = not sim.walls.door_at(sim.state, p).is_empty()
	if GameState.execute(RemoveWallCommand.new(p)).is_empty():
		_after("", "UI_BUILD_DOOR_CLOSED" if was_door else "UI_BUILD_WALL_REMOVED")
		return
	var rooms: Array = sim.state.build["rooms"]
	for i: int in rooms.size():
		var r: Array = rooms[i]["rect"]
		if Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])).has_point(p):
			GameState.execute(DemolishRoomCommand.new(i))
			_show("UI_BUILD_DEMOLISHED", true)
			_refresh_quality()
			return
	_show("UI_BUILD_NOTHING", false)


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or not is_visible_in_tree():
		return
	if key.keycode == KEY_DELETE:
		var p: Vector2 = _view.hover_point()
		if p == Vector2.INF:
			_show("UI_BUILD_NOTHING", false)
		elif not _sell_at(p):
			var was_door: bool = not GameState.sim.walls.door_at(GameState.sim.state, p).is_empty()
			if GameState.execute(RemoveWallCommand.new(p)).is_empty():
				_after("", "UI_BUILD_DOOR_CLOSED" if was_door else "UI_BUILD_WALL_REMOVED")
			else:
				_show("UI_BUILD_NOTHING", false)
		_view.refresh_hover()
		get_viewport().set_input_as_handled()


## Sil aracında imlecin altındaki eşyanın adı ve geri gelecek para.
func _on_remove_hover(prop: Dictionary) -> void:
	var kind: String = str(prop.get("kind", ""))
	if kind == "wall_cost":
		_status.text = tr("UI_BUILD_WALL_PREVIEW") % [UiUtil.num(float(prop["length"]), 1), UiUtil.money(float(prop["cost"]))]
		_status.add_theme_color_override("font_color", UiUtil.SAGE_DARK)
		return
	if str(_view.build_tool.get("kind", "")) != "remove":
		return
	if prop.is_empty():
		if _previewing:
			_show("UI_BUILD_PICK_REMOVE", true)
		return
	_previewing = true
	if kind == "door":
		_status.text = tr("UI_BUILD_DOOR_CLOSE_PREVIEW")
		_status.add_theme_color_override("font_color", UiUtil.TERRACOTTA)
		return
	if kind == "wall":
		_status.text = tr("UI_BUILD_WALL_REMOVE_PREVIEW") % UiUtil.money(float(prop["refund"]))
		_status.add_theme_color_override("font_color", UiUtil.TERRACOTTA)
		return
	var sim: Simulation = GameState.sim
	_status.text = tr("UI_BUILD_SELL_PREVIEW") % [UiUtil.name_of(DataDB.data.furniture, prop["id"]),
		UiUtil.money(sim.build.refund(sim.state, int(prop["index"])))]
	_status.add_theme_color_override("font_color", UiUtil.TERRACOTTA)
	_previewing = true


func _exit() -> void:
	_view.set_tool({})
	_on_exit.call()
