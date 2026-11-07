class_name LoanSystem
extends RefCounted
## Banka kredisi (GDD 13.5; M10, K-075): üst sınır ofis seviyesine ve itibara bağlı; eşit aylık taksit (anüite),
## aynı anda tek kredi, erken kapatma küçük bir bedelle. Faiz gider sayılır (vergiden düşer), anapara sayılmaz.

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


func _l(key: String) -> Variant:
	return data.bal("loans." + key)


static func empty_loan() -> Dictionary:
	return {}


func has_loan(state: SimState) -> bool:
	return not state.loan.is_empty()


## Çekilebilecek en yüksek tutar: ofis tabanı × enflasyon × (0.5 + itibar/100).
func max_amount(state: SimState) -> float:
	var base: Array = _l("max_1990_by_office")
	var level: int = clampi(state.office_level, 1, base.size())
	return float(base[level - 1]) * Economy.inflation(data, state.clock.year()) \
		* (float(_l("reputation_base")) + state.reputation / float(_l("reputation_div")))


## Eşit taksit: P · r / (1 − (1 + r)^−n), r aylık faiz.
func monthly_payment(amount: float, months: int) -> float:
	var r: float = float(_l("annual_interest")) / 12.0
	if r <= 0.0:
		return amount / months
	return amount * r / (1.0 - pow(1.0 + r, -months))


## "" = tamam; değilse hata anahtarı.
func take(state: SimState, amount: float, months: int) -> String:
	if has_loan(state):
		return "ERR_LOAN_EXISTS"
	if not (_l("terms_months") as Array).has(float(months)) and not (_l("terms_months") as Array).has(months):
		return "ERR_LOAN_TERM"
	if amount <= 0.0 or amount > max_amount(state) + 0.01:
		return "ERR_LOAN_AMOUNT"
	state.cash += amount
	state.loan = {"principal": amount, "balance": amount, "monthly": monthly_payment(amount, months),
		"months_left": months, "taken_week": state.clock.week_index}
	return ""


## Ay sonu taksiti. Dönüş: ödenen faiz (gider).
func monthly(state: SimState) -> float:
	if not has_loan(state):
		return 0.0
	var loan: Dictionary = state.loan
	var interest: float = float(loan["balance"]) * float(_l("annual_interest")) / 12.0
	var pay: float = minf(float(loan["monthly"]), float(loan["balance"]) + interest)
	state.cash -= pay
	state.book(0.0, interest)
	loan["balance"] = maxf(0.0, float(loan["balance"]) + interest - pay)
	loan["months_left"] = int(loan["months_left"]) - 1
	if int(loan["months_left"]) <= 0 or float(loan["balance"]) < 1.0:
		state.loan = {}
	return interest


func repay_cost(state: SimState) -> float:
	return float(state.loan.get("balance", 0.0)) * (1.0 + float(_l("early_repay_fee")))


func repay(state: SimState) -> String:
	if not has_loan(state):
		return "ERR_LOAN_NONE"
	var cost: float = repay_cost(state)
	if state.cash < cost:
		return "ERR_NO_CASH"
	state.cash -= cost
	state.book(0.0, cost - float(state.loan["balance"]))
	state.loan = {}
	return ""
