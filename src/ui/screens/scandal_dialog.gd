class_name ScandalDialog
extends Control
## Influencer skandalı (GDD 9.6): sözleşmeyi feshet / sessiz kal / açıklama yap. Cevapsız kalırsa sessiz kalınmış sayılır.

var _scandal: Dictionary
var _result: Label
var _buttons: HBoxContainer


func _init(scandal: Dictionary) -> void:
	_scandal = scandal


func _ready() -> void:
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(560.0, 320.0))
	col.add_child(UiUtil.heading(tr("UI_SCANDAL_TITLE"), "alert-triangle"))
	col.add_child(UiUtil.wrapped(tr("UI_SCANDAL_TEXT") % str(_scandal["influencer"]), 16, UiUtil.TEXT, 500.0))
	for key: String in ["terminate", "silent", "statement"]:
		col.add_child(UiUtil.wrapped("• " + tr("UI_SCANDAL_" + key.to_upper() + "_DESC"), 14, UiUtil.MUTED, 500.0))
	_result = UiUtil.wrapped("", 15, UiUtil.TEXT, 500.0)
	col.add_child(_result)
	_buttons = UiUtil.hbox()
	_buttons.add_child(UiUtil.spacer())
	for key: String in ["terminate", "silent", "statement"]:
		_buttons.add_child(UiUtil.button(tr("UI_SCANDAL_" + key.to_upper()), func() -> void: _resolve(key)))
	col.add_child(_buttons)


func _resolve(choice: String) -> void:
	var r: Dictionary = GameState.execute(ResolveScandalCommand.new(_scandal["id"], choice))
	if r.is_empty():
		queue_free()
		return
	UiUtil.clear(_buttons)
	_result.text = tr("UI_SCANDAL_RESULT") % ("%+d" % int(r["satisfaction"]))
	if choice == "statement":
		_result.text = tr("UI_SCANDAL_STATEMENT_OK" if bool(r["success"]) else "UI_SCANDAL_STATEMENT_FAIL") + " " + _result.text
	_buttons.add_child(UiUtil.spacer())
	_buttons.add_child(UiUtil.button(tr("UI_CLOSE"), queue_free))
