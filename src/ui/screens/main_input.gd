class_name MainInput
extends RefCounted
## Ana ekranın çıkış uyarısı ve kısayolları (M9); main.gd 400 satırı aşmasın diye ayrı.


## Kaydedilmemiş ilerleme varsa sorar: kaydet ve çık / kaydetmeden çık / vazgeç.
static func confirm_leave(main: Control, leave: Callable) -> void:
	if not GameState.dirty or GameState.is_bankrupt():
		leave.call()
		return
	main.call("open_modal", ConfirmDialog.new("UI_UNSAVED_TITLE", "UI_UNSAVED_TEXT", [
		["UI_SAVE_AND_EXIT", func() -> void:
			if GameState.current_slot.is_empty():
				main.call("open_modal", SaveLoadDialog.new(true))
			elif GameState.save_game():
				leave.call()],
		["UI_EXIT_NO_SAVE", leave],
		["UI_CANCEL", Callable()]]))


## F5 hızlı kayıt (slot yoksa slot seçtirir); Esc en üstteki kapatılabilir pencereyi, yoksa yan pencereyi kapatır.
## Dönüş: tuş işlendi mi.
static func handle(main: Control, event: InputEvent, modal_layer: Control, panel_id: String) -> bool:
	if event.is_action_pressed("game_quick_save"):
		if GameState.current_slot.is_empty():
			main.call("open_modal", SaveLoadDialog.new(true))
		else:
			GameState.save_game()
		return true
	if event.is_action_pressed("ui_cancel"):
		var modals: Array[Node] = modal_layer.get_children()
		for i: int in range(modals.size() - 1, -1, -1):
			if modals[i].has_meta("esc_closes") and not modals[i].is_queued_for_deletion():
				modals[i].queue_free()
				return true
		if modals.is_empty() and not panel_id.is_empty():
			main.call("close_panel")
			return true
	return false
