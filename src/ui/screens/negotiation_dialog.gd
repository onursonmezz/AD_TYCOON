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
var _stage: NegotiationStage


func _init(supplier_id: String, list_price: float, on_done: Callable) -> void:
	_supplier = supplier_id
	_list_price = list_price
	_on_done = on_done


func _ready() -> void:
	var data: GameData = DataDB.data
	GameState.execute(NegotiateCommand.new(_supplier, _list_price))
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("negotiation"), true, true)  # S11: sabit boy
	col.add_child(UiUtil.heading(tr("UI_NEGOTIATION_TITLE") % tr(data.suppliers[_supplier]["name_key"]), "receipt"))
	col.add_child(Cards.header(Cards.art("supplier_art", _supplier, 52.0, "receipt"), tr(data.suppliers[_supplier]["name_key"]),
		tr("UI_LIST_PRICE") % UiUtil.money(_list_price)))
	# S2: iki karakterli pazarlık sahnesi (kurucu ve matbaanın temsilcisi).
	var reps: Dictionary = data.raw["ui_layout.json"]["negotiation_stage"]["reps"]
	_stage = NegotiationStage.new(str(GameState.sim.state.founder().get("avatar", "kadin_02")), str(reps.get(_supplier, "erkek_02")))
	col.add_child(_stage)
	var h: Array = GameState.sim.suppliers.hint(GameState.sim.state)
	var hint: Label
	if not h.is_empty():
		hint = UiUtil.label(tr("UI_NEGOTIATION_HINT") % [UiUtil.money(h[0]), UiUtil.money(h[1])], 14, CozyTheme.FOREST)
	else:
		hint = UiUtil.label(tr("UI_NEGOTIATION_NO_HINT"), 13, CozyTheme.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(hint)
	col.add_child(Cards.section(tr("UI_NEGOTIATION_YOUR_OFFER"), "", "coins"))
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	_price = SpinBox.new()
	_price.min_value = 0.0
	_price.max_value = _list_price
	_price.step = 100.0
	_price.value = roundf(_list_price * 0.85 / 100.0) * 100.0
	_price.prefix = "₺"
	_price.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_price)
	_offer_button = UiUtil.button(tr("UI_MAKE_OFFER"), _on_offer)
	_offer_button.theme_type_variation = "PrimaryButton"
	_offer_button.custom_minimum_size.x = 120.0
	row.add_child(_offer_button)
	col.add_child(row)
	_status = UiUtil.label("", 14, CozyTheme.TEXT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_status)
	var frame: VBoxContainer = UiUtil.modal_outer(col)
	frame.add_child(HSeparator.new())
	var foot: HBoxContainer = UiUtil.hbox()
	foot.add_child(UiUtil.spacer())
	var close: Button = UiUtil.button(tr("UI_CLOSE"), _close)
	close.custom_minimum_size.x = 120.0
	foot.add_child(close)
	frame.add_child(foot)


func _on_offer() -> void:
	var n: Dictionary = GameState.execute(NegotiateCommand.new(_supplier, 0.0, _price.value))
	var rounds: int = DataDB.data.bali("negotiation.rounds")
	var r: int = int(n.get("round", 1))
	_stage.offer(tr("UI_NEGO_SAY_OFFER") % UiUtil.money(_price.value))
	match str(n["status"]):
		"accepted":
			_discount = GameState.sim.suppliers.negotiated_discount(GameState.sim.state)
			_status.text = tr("UI_NEGOTIATION_ACCEPTED") % [UiUtil.money(n["price"]), int(roundf(_discount * 100.0))]
			_status.add_theme_color_override("font_color", CozyTheme.FOREST)
			_offer_button.disabled = true
			_stage.accept.call_deferred(tr("UI_NEGO_SAY_YES_%d" % (r % 3)))
		"failed":
			_status.text = tr("UI_NEGOTIATION_FAILED")
			_status.add_theme_color_override("font_color", CozyTheme.NEGATIVE)
			_offer_button.disabled = true
			_stage.fail.call_deferred(tr("UI_NEGO_SAY_FAIL"))
		_:
			_status.text = tr("UI_NEGOTIATION_REJECTED") % [int(n["round"]), rounds] \
				+ ("\n" + tr("UI_NEGOTIATION_STRAINED") if bool(n.get("last_broken", false)) else "")
			_status.add_theme_color_override("font_color", CozyTheme.WOOD)
			var strained: bool = bool(n.get("last_broken", false))
			_stage.reject.call_deferred(tr("UI_NEGO_SAY_ANGRY") if strained else tr("UI_NEGO_SAY_NO_%d" % (r % 3)), strained)


func _close() -> void:
	_on_done.call(_discount)
	queue_free()
