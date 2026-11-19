class_name MainHud
extends RefCounted
## Ana ekranın yüzen arayüz parçaları (UI-3 kabuğu). Ölçüler Orgo'nun "Ayarlar" taslağından alındı
## (docs/reference/ui_mockups/19_ayarlar.webp; 1672×941 görüntü → 1280×720 mantıksal piksel, ×0,7655):
##   Sol üst: ajans kartı (logo, ad, alt yazı), altında iki küçük düğme (kaydet, ayarlar).
##   Üst orta: zaman kutusu (tarih | duraklat | hızlar; seçili hız kiremit kutuda, önünde oynat işareti).
##   Sağ üst: para ve itibar kutusu; altında bildirim kartları.
##   Alt orta: krem dok (menü ikonları). Pencereler ekranın ortasında açılır (main.gd).

const EDGE: float = 15.0  # kenardan uzaklık (taslakta 20 px)
const SCROLL_HYSTERESIS: float = 24.0  # kaydırma çubuğu ancak bu kadar boşluk açılınca kalkar (K-122)
const TOP: float = 14.0
const BOX_HEIGHT: float = 38.0  # üstteki kutuların yüksekliği (taslakta 50 px)
const CARD_SIZE: Vector2 = Vector2(223.0, 56.0)
const CARD_RADIUS: int = 11
const LOGO_SIZE: int = 46
const MINI_SIZE: Vector2 = Vector2(36.0, 27.0)
const MINI_GAP: int = 8
const TIME_WIDTH: float = 427.0
const PAUSE_SIZE: float = 26.0
const SPEED_SIZE: Vector2 = Vector2(52.0, 26.0)
const WALLET_WIDTH: float = 260.0
const CASH_ART: float = 30.0
const STAR_ART: float = 26.0
const WALLET_FONT: int = 20
const TOAST_TOP: float = 108.0  # ilk bildirimin üst kenarı (taslakta 141 px)
const TOAST_WIDTH: float = 176.0
const TOAST_HEIGHT: float = 38.0
const TOAST_RADIUS: int = 9
const TOAST_GAP: int = 9
const DOCK_HEIGHT: float = 58.0
const DOCK_BOTTOM: float = 26.0
const DOCK_RADIUS: int = 17
const DOCK_SLOT: Vector2 = Vector2(46.0, 42.0)
const MENU_ICON: int = 28
const TIME_ICON: int = 12
const TOASTS_KEPT: int = 3  # UI-4: dört uzun kart sağ kenarı dolduruyordu
const TOAST_SECONDS: float = 7.0


static func _box(radius: int, margin: Vector2) -> StyleBoxFlat:
	return CozyTheme.box(CozyTheme.CREAM_LIGHT, radius, CozyTheme.BORDER, 1, true, margin)


static func _divider(height: float = 18.0) -> ColorRect:
	var line: ColorRect = ColorRect.new()
	line.color = CozyTheme.BORDER
	line.custom_minimum_size = Vector2(1.0, height)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return line


static func _strong(text: String, size: int) -> Label:
	var l: Label = UiUtil.label(text, size, CozyTheme.FOREST)
	l.add_theme_font_override("font", CozyTheme.strong_font())
	return l


## Sol üst: ajans kartı + iki küçük düğme (kaydet, ayarlar). Yükle ve ana menüye dönüş Ayarlar'ın içinde.
## Dönüş: kaydet düğmesi (ipucu balonu onu gösterir).
static func agency_card(main: Control) -> Button:
	var col: VBoxContainer = UiUtil.vbox(5)
	main.add_child(col)
	col.position = Vector2(EDGE, TOP)
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _box(CARD_RADIUS, Vector2(10.0, 4.0)))
	card.custom_minimum_size = CARD_SIZE
	col.add_child(card)
	var row: HBoxContainer = UiUtil.hbox(10)
	card.add_child(row)
	var logo: TextureRect = UiUtil.icon("speakerphone", LOGO_SIZE, CozyTheme.TERRA)
	var logo_art: Texture2D = IconPack.art("ajans-logo", LOGO_SIZE)
	if logo_art != null:
		logo.texture = logo_art
		logo.modulate = Color.WHITE
	row.add_child(logo)
	var names: VBoxContainer = UiUtil.vbox(-5)
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(names)
	var agency: Label = UiUtil.label(GameState.agency_display(), 21, CozyTheme.FOREST)
	agency.add_theme_font_override("font", CozyTheme.title_font(700))
	names.add_child(agency)
	var tagline: Label = UiUtil.label(main.tr("UI_AGENCY_TAGLINE"), 12, CozyTheme.TEXT)
	tagline.add_theme_font_override("font", MenuArt.italic(CozyTheme.body_font()))
	names.add_child(tagline)
	var buttons: HBoxContainer = UiUtil.hbox(MINI_GAP)
	col.add_child(buttons)
	var reload: Callable = func() -> void: main.get_tree().reload_current_scene()
	var save: Button = _mini("device-floppy", main.tr("UI_SAVE") + " (F5)", func() -> void:
		main.call("open_modal", SaveLoadDialog.new(true)))
	buttons.add_child(save)
	buttons.add_child(_mini("settings", main.tr("UI_SETTINGS"), func() -> void:
		var dialog: SettingsDialog = SettingsDialog.new(reload)
		dialog.game = main
		main.call("open_modal", dialog)))
	return save


static func _mini(icon_name: String, tip: String, on_press: Callable) -> Button:
	var b: Button = UiUtil.icon_button(icon_name, tip, on_press, 16)
	b.theme_type_variation = "MiniButton"
	b.custom_minimum_size = MINI_SIZE
	return b


## Üst orta: zaman kutusu. Dönüş: { date, pause, speeds }.
## S3B: saat kutusunun altında kampanya şeridi ve puan baloncukları katmanı.
static func campaign_strip(main: Control, office: OfficeView, on_open: Callable) -> Dictionary:
	var strip: CampaignStrip = CampaignStrip.new(on_open)
	main.add_child(strip)
	strip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	strip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	strip.offset_top = TOP + BOX_HEIGHT + 6.0
	strip.visible = false
	var bubbles: PointBubbles = PointBubbles.new(office, strip)
	main.add_child(bubbles)
	return {"strip": strip, "bubbles": bubbles}


static func time_bar(main: Control) -> Dictionary:
	var pill: PanelContainer = PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _box(999, Vector2(18.0, 4.0)))
	pill.custom_minimum_size = Vector2(TIME_WIDTH, BOX_HEIGHT)
	main.add_child(pill)
	pill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	pill.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pill.offset_top = TOP
	var row: HBoxContainer = UiUtil.hbox(10)
	pill.add_child(row)
	row.add_child(UiUtil.icon("calendar", 18, CozyTheme.FOREST))
	var date: Label = _strong("", 14)
	date.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(date)
	row.add_child(_divider())
	var pause: Button = UiUtil.icon_button("player-pause", main.tr("TIP_PAUSE"), func() -> void: Clock.toggle_pause(), TIME_ICON)
	pause.theme_type_variation = "PauseButton"
	pause.custom_minimum_size = Vector2(PAUSE_SIZE, PAUSE_SIZE)
	pause.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pause)
	var speeds: Array[Button] = []
	var values: Array = DataDB.data.bal("time.speeds")
	for i: int in values.size():
		var b: Button = UiUtil.button("%d×" % int(values[i]), func() -> void: Clock.set_speed(i))
		b.theme_type_variation = "PillButton"
		b.custom_minimum_size = SPEED_SIZE
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", 14)
		b.add_theme_constant_override("h_separation", 5)
		b.tooltip_text = main.tr("TIP_SPEED") % (i + 1)
		speeds.append(b)
		row.add_child(b)
	return {"date": date, "pause": pause, "speeds": speeds}


## Hız düğmelerinin görünüşü: seçili hız kiremit kutuda ve önünde oynat işareti; duraklatılınca duraklat düğmesi dolar.
static func show_speed(pause: Button, speeds: Array[Button], paused: bool, index: int) -> void:
	pause.theme_type_variation = "PauseButtonOn" if paused else "PauseButton"
	for i: int in speeds.size():
		var on: bool = not paused and index == i
		speeds[i].theme_type_variation = "SpeedActive" if on else "PillButton"
		speeds[i].icon = UiUtil.icon_texture("player-play", TIME_ICON) if on else null


## Sağ üst: para ve itibar tek kutuda; altında bildirim kartları. Dönüş: { cash, rep, feed }.
static func wallet(main: Control) -> Dictionary:
	var pill: PanelContainer = PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _box(999, Vector2(14.0, 2.0)))
	pill.custom_minimum_size = Vector2(WALLET_WIDTH, BOX_HEIGHT)
	main.add_child(pill)
	pill.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pill.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	pill.offset_right = -EDGE
	pill.offset_top = TOP
	var row: HBoxContainer = UiUtil.hbox(10)
	pill.add_child(row)
	var cash: CountBadge = CountBadge.new("currency-lira", CozyTheme.GOLD,
		func(v: float) -> String: return UiUtil.money(v), 150.0, CASH_ART, WALLET_FONT)
	cash.tooltip_text = main.tr("TIP_CASH")
	cash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cash)
	row.add_child(_divider(22.0))
	var rep: CountBadge = CountBadge.new("star", CozyTheme.ACCENT,
		func(v: float) -> String: return "%d" % int(roundf(v)), 62.0, STAR_ART, WALLET_FONT)
	rep.tooltip_text = main.tr("TIP_REPUTATION")
	row.add_child(rep)
	cash.set_art(IconPack.art("para", int(CASH_ART)))
	rep.set_art(IconPack.art("yildiz", int(STAR_ART)))
	for badge: CountBadge in [cash, rep]:
		badge.add_theme_stylebox_override("panel", StyleBoxEmpty.new())  # ikisi tek kutunun içinde
		badge.label_node().add_theme_font_override("font", CozyTheme.strong_font())
	var feed: VBoxContainer = UiUtil.vbox(TOAST_GAP)
	feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.add_child(feed)
	feed.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	feed.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	feed.offset_right = -EDGE
	feed.offset_top = TOAST_TOP
	return {"cash": cash, "rep": rep, "feed": feed}


## Alt orta: krem dok. Dönüş: { dock, menu (ikonların ekleneceği sıra) }.
static func dock(main: Control) -> Dictionary:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(DOCK_RADIUS, Vector2(26.0, 4.0)))
	panel.custom_minimum_size.y = DOCK_HEIGHT
	main.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_bottom = -DOCK_BOTTOM
	var menu: HBoxContainer = UiUtil.hbox(6)
	panel.add_child(menu)
	return {"dock": panel, "menu": menu}


## Dok ikonları arasındaki ince kiremit çizgi.
static func dock_divider() -> ColorRect:
	var line: ColorRect = _divider(20.0)
	line.color = Color(CozyTheme.TERRA, 0.55)
	return line


## Pencerenin kaydırması: içerik sığmıyorsa çubuk hep görünür, sığıyorsa hiç yok (belirip kaybolurken metin oynamasın).
## Çubuk bir kez çıktıysa ancak belirgin boşluk açılınca (SCROLL_HYSTERESIS) kalkar: çubuk metni daraltıp satır kırılmasını
## değiştirdiği için yoksa durmadan belirip kaybolur (İngilizce Ofis penceresinde oyunu çökertiyordu).
static func fit_scroll(scroll: ScrollContainer, content: Control, room: float) -> void:
	var need: float = content.get_combined_minimum_size().y
	var shown: bool = scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	var mode: ScrollContainer.ScrollMode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS \
		if need > room or (shown and need > room - SCROLL_HYSTERESIS) else ScrollContainer.SCROLL_MODE_DISABLED
	if scroll.vertical_scroll_mode != mode:
		scroll.vertical_scroll_mode = mode


## Bildirim kartı (toast): kayarak gelir, birkaç saniye sonra solup kaybolur; en fazla TOASTS_KEPT tane.
static func toast(feed: VBoxContainer, key: String, args: Array, kind: String) -> void:
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _box(TOAST_RADIUS, Vector2(12.0, 6.0)))
	card.custom_minimum_size = Vector2(TOAST_WIDTH, TOAST_HEIGHT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: HBoxContainer = UiUtil.hbox(9)
	card.add_child(row)
	var icon_name: String = {"good": "check", "bad": "alert-triangle"}.get(kind, "bell")
	var icon_color: Color = {"good": CozyTheme.POSITIVE, "bad": CozyTheme.NEGATIVE}.get(kind, CozyTheme.FOREST)
	row.add_child(UiUtil.icon(icon_name, 18, icon_color))
	var text: Label = UiUtil.wrapped(UiUtil.tr_fmt(key, args), 12, UiUtil.TEXT, TOAST_WIDTH - 54.0)
	text.add_theme_font_override("font", CozyTheme.strong_font())  # taslakta bildirimler düz (sans), yarı kalın
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	feed.add_child(card)
	Juice.slide_in(card)
	var fade: Tween = card.create_tween()
	fade.tween_interval(TOAST_SECONDS)
	fade.tween_property(card, "modulate:a", 0.0, 0.5)
	fade.tween_callback(card.queue_free)
	while feed.get_child_count() > TOASTS_KEPT:
		var first: Node = feed.get_child(0)
		feed.remove_child(first)
		first.queue_free()
