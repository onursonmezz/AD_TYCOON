class_name ScandalDialog
extends Control
## Influencer skandalı (GDD 9.6): sözleşmeyi feshet / sessiz kal / açıklama yap. Cevapsız kalırsa sessiz kalınmış sayılır.
## UI-3 dili: uyarı kartı, üç seçenek kartı yan yana; seçince kartların yerine sonuç kartı gelir.

const CHOICES: Dictionary = {"terminate": "x", "silent": "lock", "statement": "speakerphone"}

var _scandal: Dictionary
var _choices: HBoxContainer
var _close: Button


func _init(scandal: Dictionary) -> void:
	_scandal = scandal


func _ready() -> void:
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("scandal"))
	col.add_child(UiUtil.heading(tr("UI_SCANDAL_TITLE"), "alert-triangle"))
	var warn: PanelContainer = UiUtil.card()
	warn.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.TERRA_SOFT, CozyTheme.RADIUS_CARD, Color.TRANSPARENT, 0,
		false, Vector2(CozyTheme.SPACE_M, CozyTheme.SPACE_S)))
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	warn.add_child(row)
	var ic: TextureRect = UiUtil.icon("alert-triangle", 28, CozyTheme.TERRA)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	var text: Label = UiUtil.label(tr("UI_SCANDAL_TEXT") % str(_scandal["influencer"]), 15, CozyTheme.TEXT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	col.add_child(warn)
	_choices = UiUtil.hbox(CozyTheme.SPACE_S)
	for key: String in CHOICES:
		_choices.add_child(Cards.choice(str(CHOICES[key]), tr("UI_SCANDAL_" + key.to_upper()),
			tr("UI_SCANDAL_" + key.to_upper() + "_DESC"), tr("UI_CHOOSE"), func() -> void: _resolve(key)))
	col.add_child(_choices)
	var frame: VBoxContainer = UiUtil.modal_outer(col)
	frame.add_child(HSeparator.new())
	var foot: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	foot.add_child(UiUtil.label(tr("UI_SCANDAL_HINT"), 13, CozyTheme.MUTED))
	foot.add_child(UiUtil.spacer())
	_close = UiUtil.button(tr("UI_CLOSE"), queue_free)
	_close.theme_type_variation = "PrimaryButton"
	_close.custom_minimum_size.x = 120.0
	_close.visible = false
	foot.add_child(_close)
	frame.add_child(foot)


func _resolve(choice: String) -> void:
	var r: Dictionary = GameState.execute(ResolveScandalCommand.new(_scandal["id"], choice))
	if r.is_empty():
		queue_free()
		return
	var parent: Node = _choices.get_parent()
	var at: int = _choices.get_index()
	_choices.queue_free()
	var good: bool = choice != "statement" or bool(r["success"])
	var lines: String = tr("UI_SCANDAL_RESULT") % ("%+d" % int(r["satisfaction"]))
	if choice == "statement":
		lines = tr("UI_SCANDAL_STATEMENT_OK" if bool(r["success"]) else "UI_SCANDAL_STATEMENT_FAIL") + " " + lines
	var card: PanelContainer = UiUtil.card()
	var head: HBoxContainer = Cards.header(Cards.tile(str(CHOICES[choice]), 44.0, CozyTheme.SAGE_SOFT if good else CozyTheme.TERRA_SOFT),
		tr("UI_SCANDAL_" + choice.to_upper()), lines, [], true)
	var sub: Label = (head.get_child(1) as VBoxContainer).get_child(1) as Label
	sub.clip_text = false
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(head)
	parent.add_child(card)
	parent.move_child(card, at)
	UiUtil.pop_in(card)
	_close.visible = true
