class_name GameOverDialog
extends Control
## İflas ekranı (GDD 13.3): yeni oyun, son kayıttan devam, ana menü.
## UI-3 dili: kiremit uyarı kartı, kapanış tarihi / kampanya / itibar şeridi; düğmeler ayrı alt satırda.

var _to_menu: Callable


func _init(to_menu: Callable) -> void:
	_to_menu = to_menu


func _ready() -> void:
	var s: SimState = GameState.sim.state
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("game_over"))
	col.add_child(UiUtil.heading(tr("UI_BANKRUPT_TITLE"), "alert-triangle"))
	var warn: PanelContainer = PanelContainer.new()
	warn.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.TERRA_SOFT, CozyTheme.RADIUS_CARD, Color.TRANSPARENT, 0,
		false, Vector2(CozyTheme.SPACE_M, CozyTheme.SPACE_M)))
	var head: HBoxContainer = Cards.header(Cards.tile("alert-triangle", 48.0, CozyTheme.CREAM_LIGHT), tr("UI_BANKRUPT_SUB"),
		tr("UI_BANKRUPT_TEXT") % [UiUtil.date_text(s.clock), s.history.size()])
	var sub: Label = (head.get_child(1) as VBoxContainer).get_child(1) as Label
	sub.clip_text = false
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_color_override("font_color", CozyTheme.TEXT)
	warn.add_child(head)
	col.add_child(warn)
	col.add_child(Cards.facts([
		Cards.fact("calendar", tr("UI_BANKRUPT_DATE"), UiUtil.date_text(s.clock)),
		Cards.fact("speakerphone", tr("UI_BANKRUPT_CAMPAIGNS"), str(s.history.size())),
		Cards.fact("laurel", tr("UI_BANKRUPT_REP"), str(int(s.reputation)))]))
	var frame: VBoxContainer = UiUtil.modal_outer(col)
	frame.add_child(HSeparator.new())
	var foot: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	foot.add_child(UiUtil.button(tr("UI_MAIN_MENU"), _to_menu))
	foot.add_child(UiUtil.spacer())
	var load_button: Button = UiUtil.button(tr("MENU_CONTINUE"), func() -> void:
		if GameState.load_game():
			get_tree().reload_current_scene())
	load_button.disabled = not SaveSystem.has_save()
	foot.add_child(load_button)
	var fresh: Button = UiUtil.button(tr("MENU_NEW_GAME"), func() -> void:
		GameState.new_game()
		get_tree().reload_current_scene())
	fresh.theme_type_variation = "PrimaryButton"
	fresh.custom_minimum_size.x = 140.0
	foot.add_child(fresh)
	frame.add_child(foot)
