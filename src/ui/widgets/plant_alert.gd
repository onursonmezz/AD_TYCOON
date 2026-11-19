class_name PlantAlert
extends RefCounted
## Bitki uyarısı (S11, Orgo): bitkiler susayınca sağdaki bildirim sütununun en üstünde, kaybolmayan, "Sula" düğmeli bir
## kart durur; sulanınca kalkar. Susadı/kurudu bildirimleri bu kartla gösterildiği için ayrı kart olarak çıkmaz.

const META: String = "plant_alert"


## Her yenilemede çağrılır: gerekiyorsa kartı kurar, metnini günceller ya da kaldırır.
static func update(feed: VBoxContainer) -> void:
	var sim: Simulation = GameState.sim
	var state: int = sim.build.plants_need_water(sim.state)  # 0 yok, 1 susadı, 2 kurudu
	var card: PanelContainer = null
	for c: Node in feed.get_children():
		if c.has_meta(META):
			card = c
	if state == 0:
		if card != null:
			card.queue_free()
		return
	if card == null:
		card = _build(feed)
	var label: Label = card.get_meta("label")
	label.text = TranslationServer.translate("UI_PLANT_ALERT_DRY" if state == 2 else "UI_PLANT_ALERT_THIRSTY")
	label.add_theme_color_override("font_color", CozyTheme.NEGATIVE if state == 2 else CozyTheme.TEXT)
	if card.get_index() != 0:
		feed.move_child(card, 0)


static func _build(feed: VBoxContainer) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.set_meta(META, true)
	card.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM_LIGHT, MainHud.TOAST_RADIUS, CozyTheme.SAGE, 2,
		true, Vector2(10.0, 6.0)))
	card.custom_minimum_size = Vector2(MainHud.TOAST_WIDTH, MainHud.TOAST_HEIGHT)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var row: HBoxContainer = UiUtil.hbox(8)
	card.add_child(row)
	row.add_child(UiUtil.icon("plant", 18, CozyTheme.FOREST))
	var label: Label = UiUtil.label("", 12, CozyTheme.TEXT)  # kısa yazı: tek satır
	label.add_theme_font_override("font", CozyTheme.strong_font())
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	card.set_meta("label", label)
	var water: Button = UiUtil.button(TranslationServer.translate("UI_PLANT_ALERT_WATER"), func() -> void:
		GameState.execute(WaterPlantsCommand.new())
		update(feed))
	Cards.compact(water, true)
	row.add_child(water)
	feed.add_child(card)
	feed.move_child(card, 0)
	Juice.slide_in(card)
	return card
