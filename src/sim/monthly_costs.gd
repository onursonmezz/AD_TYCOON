class_name MonthlyCosts
extends RefCounted
## Aylık giderlerin dökümü (S8): ay sonunda ödenen her kalem tek yerde hesaplanır; simülasyon bunu öder,
## finans ekranı aynı sayıları gösterir. Eskiden ekranda "aylık sabit gider" yalnız taban gideri gösteriyordu
## (maaş, kira, abonelik ve bakım yoktu; 2015'te 10 bin yazıp gerçekte 300 bin gidiyordu).

const ORDER: Array[String] = ["payroll", "rent", "tools", "equipment", "loan", "base"]


## { kalem: tutar } — ORDER sırasındaki anahtarlar. loan: bu ayki kredi taksiti (faiz dahil).
static func breakdown(sim: Simulation) -> Dictionary:
	var s: SimState = sim.state
	var data: GameData = sim.data
	return {
		"payroll": sim.staff.monthly_payroll(s),
		"rent": sim.offices.monthly_rent(s),
		"tools": sim.tools.monthly_cost(s),
		"equipment": sim.equipment.monthly_cost(s),
		"loan": float(s.loan["monthly"]) if sim.loans.has_loan(s) else 0.0,
		"base": data.balf("cashflow.monthly_base_cost") * Economy.inflation(data, s.clock.year()),
	}


## Ay sonunda Economy.monthly'nin "extra"sı: taban gider ve kredi hariç (onları kendi sistemleri öder).
static func extra(sim: Simulation) -> float:
	var b: Dictionary = breakdown(sim)
	return float(b["payroll"]) + float(b["rent"]) + float(b["tools"]) + float(b["equipment"])


static func total(sim: Simulation) -> float:
	var sum: float = 0.0
	for v: Variant in breakdown(sim).values():
		sum += float(v)
	return sum
