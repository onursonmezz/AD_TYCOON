class_name Economy
extends RefCounted
## Nakit, enflasyon, aylık gider, faturalar/tahsilat, yıllık vergi ve iflas (GDD 13).

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


## enflasyon(yıl): base_year'a göre fiyat çarpanı. "historical" mod M7'de (şimdilik "simple" kullanılır).
static func inflation(game_data: GameData, year: int) -> float:
	var rate: float = game_data.balf("economy.simple_rate")
	return pow(1.0 + rate, year - game_data.bali("time.base_year"))


## Gider öder (vergi matrahından düşülür).
func pay(state: SimState, amount: float) -> void:
	state.cash -= amount
	state.year_expense += amount


## Müşteri adına medya ödemesi (vergiye girmez): tedarikçiye vadeli ödenir (GDD 13.3 "peşin veya 30 gün").
func add_payable(state: SimState, amount: float) -> void:
	state.payables.append({"amount": amount, "due_week": state.clock.week_index + data.bali("cashflow.media_payment_weeks")})


## Müşteriye fatura keser. amount: toplam tutar; income_part: bunun ajans geliri olan kısmı (fee, komisyon, prim).
func invoice(state: SimState, client: Dictionary, amount: float, income_part: float) -> void:
	var pay_score: float = float(client["personality"]["pay"])
	var weeks: int = 0
	for term: Dictionary in data.bal("cashflow.payment_terms"):
		if pay_score >= float(term["min_pay"]):
			weeks = int(term["weeks"])
			break
	var late_p: float = (100.0 - pay_score) / 100.0 * data.balf("cashflow.late_chance_mult")
	if state.rng.chance("economy", late_p):
		var extra: Array = data.bal("cashflow.late_extra_weeks")
		weeks += state.rng.range_i("economy", int(extra[0]), int(extra[1]))
	state.receivables.append({"client_id": client["id"], "amount": amount, "income": income_part,
		"due_week": state.clock.week_index + weeks})


## Her hafta sonu: vadesi gelen faturaları tahsil et, kırmızı süreyi say, iflası kontrol et.
func weekly(state: SimState) -> void:
	var remaining: Array[Dictionary] = []
	for r: Dictionary in state.receivables:
		if int(r["due_week"]) <= state.clock.week_index:
			state.cash += float(r["amount"])
			state.year_income += float(r["income"])
		else:
			remaining.append(r)
	state.receivables = remaining
	var unpaid: Array[Dictionary] = []
	for p: Dictionary in state.payables:
		if int(p["due_week"]) <= state.clock.week_index:
			state.cash -= float(p["amount"])
		else:
			unpaid.append(p)
	state.payables = unpaid
	if state.cash < 0.0:
		state.red_weeks += 1
		if state.red_weeks >= data.bali("cashflow.red_weeks_to_bankrupt"):
			state.bankrupt = true
	else:
		state.red_weeks = 0


## Her ay sonu: sabit gider + extra (kira ve maaşlar+SGK; M7'de yazılım abonelikleri eklenecek).
func monthly(state: SimState, extra: float = 0.0) -> void:
	pay(state, data.balf("cashflow.monthly_base_cost") * inflation(data, state.clock.year()) + extra)


## Yıl sonu: kurumlar vergisi (kâr varsa) ve yıllık sayaçların sıfırlanması.
func yearly(state: SimState) -> float:
	var profit: float = state.year_income - state.year_expense
	var tax: float = maxf(0.0, profit) * data.balf("economy.corporate_tax")
	state.cash -= tax
	state.year_income = 0.0
	state.year_expense = 0.0
	return tax
