class_name GameOverDialog
extends Control
## İflas ekranı (GDD 13.3): yeni oyun, son kayıttan devam, ana menü.

var _to_menu: Callable


func _init(to_menu: Callable) -> void:
	_to_menu = to_menu


func _ready() -> void:
	var s: SimState = GameState.sim.state
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(520.0, 320.0))
	col.add_child(UiUtil.label(tr("UI_BANKRUPT_TITLE"), 30, UiUtil.TERRACOTTA))
	col.add_child(UiUtil.wrapped(tr("UI_BANKRUPT_TEXT") % [UiUtil.date_text(s.clock), s.history.size()], 16, UiUtil.TEXT, 460.0))
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.button(tr("MENU_NEW_GAME"), func() -> void:
		GameState.new_game()
		get_tree().reload_current_scene()))
	var load_button: Button = UiUtil.button(tr("MENU_CONTINUE"), func() -> void:
		if GameState.load_game():
			get_tree().reload_current_scene())
	load_button.disabled = not SaveSystem.has_save()
	buttons.add_child(load_button)
	buttons.add_child(UiUtil.button(tr("UI_MAIN_MENU"), _to_menu))
	col.add_child(buttons)
