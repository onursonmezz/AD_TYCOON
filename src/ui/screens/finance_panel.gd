class_name FinancePanel
extends VBoxContainer
## Finans özeti (GDD 13.6, M2 sade sürüm): nakit, bekleyen tahsilat/ödemeler, bu yılın gelir-gideri;
## banka kredisi (GDD 13.5, M10). UI-1: Cozy Refined düzeni (CozyTheme; pencereyi main.gd bu temaya geçirir):
## üstte üç büyük sayı kartı, altında "Bu yıl", "Nakit akışı", kredi ve matbaa kartları.

var _stats: HBoxContainer
var _year: VBoxContainer
var _flow: VBoxContainer
var _suppliers: VBoxContainer
var _loan: VBoxContainer
var _sig: String = ""


func _init() -> void:
	add_theme_constant_override("separation", CozyTheme.SPACE_M)
	add_child(_label(tr("MENU_FINANCE"), "SectionHeading"))
	add_child(_wrapped(tr("UI_FINANCE_HINT"), "MutedLabel"))
	_stats = UiUtil.hbox(CozyTheme.SPACE_M)
	add_child(_stats)
	_year = _card(tr("UI_FIN_SECTION_YEAR"))
	_flow = _card(tr("UI_FIN_SECTION_FLOW"))
	_loan = _card(tr("UI_LOAN_TITLE"))
	_suppliers = _card(tr("UI_SUPPLIERS"))


static func _label(text: String, variation: String = "") -> Label:
	var l: Label = Label.new()
	l.text = text
	l.theme_type_variation = variation
	return l


static func _wrapped(text: String, variation: String = "") -> Label:
	var l: Label = _label(text, variation)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 200.0
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


## Başlıklı kart; içerik kutusunu döndürür (başlığın altında).
func _card(title: String) -> VBoxContainer:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = "Card"
	add_child(card)
	var col: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	card.add_child(col)
	col.add_child(_label(title, "CardHeading"))
	var body: VBoxContainer = UiUtil.vbox(6)
	col.add_child(body)
	return body


## Sol: soluk ad, sağ: değer (varyasyon artı/eksi rengi verir).
static func _row(parent: Control, name: String, value: String, variation: String = "") -> void:
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var n: Label = _label(name, "MutedLabel")
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(n)
	var v: Label = _label(value, variation)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(v)
	parent.add_child(row)


static func _signed(value: float) -> String:
	return "NegativeLabel" if value < 0.0 else ""


func _stat(name: String, value: String, note: String, variation: String = "") -> void:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = "StatCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col: VBoxContainer = UiUtil.vbox(2)
	card.add_child(col)
	col.add_child(_label(name, "StatLabel"))
	var v: Label = _label(value, "StatValue")
	if not variation.is_empty():
		v.add_theme_color_override("font_color", CozyTheme.NEGATIVE)
	col.add_child(v)
	col.add_child(_label(note, "StatLabel"))
	_stats.add_child(card)


## Matbaalarla ilişki puanı ve aktif anlaşmalar (GDD 10.3).
func _refresh_suppliers(s: SimState) -> void:
	UiUtil.clear(_suppliers)
	var data: GameData = DataDB.data
	for id: String in data.supplier_ids:
		_suppliers.add_child(_label(tr("UI_SUPPLIER_LINE") % [tr(data.suppliers[id]["name_key"]),
			int(GameState.sim.suppliers.relationship(s, id))]))
	for deal: Dictionary in s.supplier_deals:
		_suppliers.add_child(_label("✓ %s: %s" % [tr(data.suppliers[deal["supplier"]]["name_key"]),
			UiUtil.supplier_offer_text(deal)], "PositiveLabel"))


func refresh() -> void:
	var s: SimState = GameState.sim.state
	var data: GameData = DataDB.data
	var receivable: float = 0.0
	var next_due: int = -1
	for r: Dictionary in s.receivables:
		receivable += float(r["amount"])
		if next_due < 0 or int(r["due_week"]) < next_due:
			next_due = int(r["due_week"])
	var payable: float = 0.0
	for p: Dictionary in s.payables:
		payable += float(p["amount"])
	var monthly: float = data.balf("cashflow.monthly_base_cost") * Economy.inflation(data, s.clock.year())
	var projected: float = s.cash + receivable - payable
	UiUtil.clear(_stats)
	_stat(tr("UI_FIN_CASH"), UiUtil.money(s.cash), " ", _signed(s.cash))
	var due: String = tr("UI_WEEKS") % (next_due - s.clock.week_index) if next_due >= 0 else "—"
	_stat(tr("UI_FIN_RECEIVABLE"), UiUtil.money(receivable), "%s: %s" % [tr("UI_FIN_NEXT_DUE"), due])
	_stat(tr("UI_FIN_PROJECTED"), UiUtil.money(projected), " ", _signed(projected))
	UiUtil.clear(_year)
	var profit: float = s.year_income - s.year_expense
	_row(_year, tr("UI_FIN_YEAR_INCOME"), UiUtil.money(s.year_income))
	_row(_year, tr("UI_FIN_YEAR_EXPENSE"), UiUtil.money(s.year_expense))
	_row(_year, tr("UI_FIN_YEAR_PROFIT"), UiUtil.money(profit), "NegativeLabel" if profit < 0.0 else ("PositiveLabel" if profit > 0.0 else ""))
	UiUtil.clear(_flow)
	_row(_flow, tr("UI_FIN_PAYABLE"), "%s (%d)" % [UiUtil.money(payable), s.payables.size()])
	_row(_flow, tr("UI_FIN_MONTHLY"), UiUtil.money(monthly))
	_row(_flow, tr("UI_FIN_RED_WEEKS"), "%d / %d" % [s.red_weeks, data.bali("cashflow.red_weeks_to_bankrupt")],
		"NegativeLabel" if s.red_weeks > 0 else "")
	_refresh_suppliers(s)
	_refresh_loan(s)


## Kredi: varsa kalan borç, taksit ve erken kapatma; yoksa tutar ve vade seçip çekme (taksit önizlemesiyle).
func _refresh_loan(s: SimState) -> void:
	var loans: LoanSystem = GameState.sim.loans
	var sig: String = "%s|%d" % [str(s.loan), int(loans.max_amount(s) / 1000.0)]
	if sig == _sig:
		return
	_sig = sig
	UiUtil.clear(_loan)
	if loans.has_loan(s):
		_loan.add_child(_wrapped(tr("UI_LOAN_ACTIVE") % [UiUtil.money(float(s.loan["balance"])),
			UiUtil.money(float(s.loan["monthly"])), int(s.loan["months_left"])]))
		var b: Button = UiUtil.button(tr("UI_LOAN_REPAY") % UiUtil.money(loans.repay_cost(s)), func() -> void: _run(LoanActionCommand.new("repay")))
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_loan.add_child(b)
		return
	var max_amount: float = loans.max_amount(s)
	_loan.add_child(_wrapped(tr("UI_LOAN_HINT") % [UiUtil.money(max_amount),
		UiUtil.percent(100.0 * DataDB.data.balf("loans.annual_interest"))], "MutedLabel"))
	var steps: Array = DataDB.data.bal("loans.amount_steps")
	var terms: Array = DataDB.data.bal("loans.terms_months")
	var amount_pick: OptionButton = OptionButton.new()
	for st: Variant in steps:
		amount_pick.add_item(UiUtil.money(max_amount * float(st)))
	amount_pick.select(steps.size() - 1)
	var term_pick: OptionButton = OptionButton.new()
	for t: Variant in terms:
		term_pick.add_item(tr("UI_LOAN_TERM") % int(t))
	term_pick.select(1)
	var preview: Label = _label("", "MutedLabel")
	var update: Callable = func(_i: int = 0) -> void:
		preview.text = tr("UI_LOAN_PREVIEW") % UiUtil.money(GameState.sim.loans.monthly_payment(
			max_amount * float(steps[amount_pick.selected]), int(terms[term_pick.selected])))
	amount_pick.item_selected.connect(update)
	term_pick.item_selected.connect(update)
	update.call()
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.add_child(amount_pick)
	row.add_child(term_pick)
	var take: Button = UiUtil.button(tr("UI_LOAN_TAKE"), func() -> void:
		_run(LoanActionCommand.new("take", max_amount * float(steps[amount_pick.selected]), int(terms[term_pick.selected]))))
	take.theme_type_variation = "PrimaryButton"
	row.add_child(take)
	_loan.add_child(row)
	_loan.add_child(preview)


func _run(cmd: RefCounted) -> void:
	var err: String = GameState.execute(cmd)
	if not err.is_empty():
		EventBus.notification.emit(err, [], "bad")
	_sig = ""
	refresh()
