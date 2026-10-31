class_name NegotiationDialog
extends Control
## Matbaa pazarlığı mini oyunu (GDD 10.3): 3 tura kadar karşı teklif. Her reddin ilişkiyi zedeleme riski var.
## Satın alma uzmanı varsa gizli taban bir aralık olarak görünür.

var _supplier: String
var _list_price: float
var _on_done: Callable
var _price: SpinBox
var _status: Label
var _offer_button: Button
var _discount: float = 0.0


func _init(supplier_id: String, list_price: float, on_done: Callable) -> void:
	_supplier = supplier_id
	_list_price = list_price
	_on_done = on_done


func _ready() -> void:
	var data: GameData = DataDB.data
	GameState.execute(NegotiateCommand.new(_supplier, _list_price))
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(520.0, 340.0))
	col.add_child(UiUtil.heading(tr("UI_NEGOTIATION_TITLE") % tr(data.suppliers[_supplier]["name_key"])))
	col.add_child(UiUtil.label(tr("UI_LIST_PRICE") % UiUtil.money(_list_price), 16))
	var h: Array = GameState.sim.suppliers.hint(GameState.sim.state)
	if not h.is_empty():
		col.add_child(UiUtil.label(tr("UI_NEGOTIATION_HINT") % [UiUtil.money(h[0]), UiUtil.money(h[1])], 15, UiUtil.SAGE_DARK))
	else:
		col.add_child(UiUtil.wrapped(tr("UI_NEGOTIATION_NO_HINT"), 14, UiUtil.MUTED, 460.0))
	var row: HBoxContainer = UiUtil.hbox()
	_price = SpinBox.new()
	_price.min_value = 0.0
	_price.max_value = _list_price
	_price.step = 100.0
	_price.value = roundf(_list_price * 0.85 / 100.0) * 100.0
	_price.prefix = "₺"
	_price.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_price)
	_offer_button = UiUtil.button(tr("UI_MAKE_OFFER"), _on_offer)
	row.add_child(_offer_button)
	col.add_child(row)
	_status = UiUtil.wrapped("", 15, UiUtil.TEXT, 460.0)
	col.add_child(_status)
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_CLOSE"), _close))
	col.add_child(buttons)


func _on_offer() -> void:
	var n: Dictionary = GameState.execute(NegotiateCommand.new(_supplier, 0.0, _price.value))
	var rounds: int = DataDB.data.bali("negotiation.rounds")
	match str(n["status"]):
		"accepted":
			_discount = GameState.sim.suppliers.negotiated_discount(GameState.sim.state)
			_status.text = tr("UI_NEGOTIATION_ACCEPTED") % [UiUtil.money(n["price"]), int(roundf(_discount * 100.0))]
			_status.add_theme_color_override("font_color", UiUtil.SAGE_DARK)
			_offer_button.disabled = true
		"failed":
			_status.text = tr("UI_NEGOTIATION_FAILED")
			_status.add_theme_color_override("font_color", UiUtil.TERRACOTTA)
			_offer_button.disabled = true
		_:
			_status.text = tr("UI_NEGOTIATION_REJECTED") % [int(n["round"]), rounds] \
				+ ("\n" + tr("UI_NEGOTIATION_STRAINED") if bool(n.get("last_broken", false)) else "")
			_status.add_theme_color_override("font_color", UiUtil.WOOD)


func _close() -> void:
	_on_done.call(_discount)
	queue_free()
