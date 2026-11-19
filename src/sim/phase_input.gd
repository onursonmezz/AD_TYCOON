class_name PhaseInput
extends RefCounted
## Faz başında oyuncunun girdisi: kaydırıcılar (GDD 7.4, eski yol) ya da görev panosu planı ve kiralıklar (K-118, K-119).
## Simulation.set_phase_sliders / set_phase_plan buraya yönlendirir.


## Oyuncu fazın slider'larını onaylar (GDD 7.4: üç slider, toplam %100).
static func apply_sliders(sim: Simulation, sliders: Array) -> bool:
	if sim.state.active_campaign.is_empty() or sliders.size() != 3:
		return false
	var sum: float = 0.0
	for v: Variant in sliders:
		if float(v) < 0.0:
			return false
		sum += float(v)
	if not is_equal_approx(sum, 1.0):
		return false
	var camp: Dictionary = sim.state.active_campaign  # öne çıkan = faz başında bekleyen (S3D)
	var phase: int = sim.production.current_phase(camp)
	camp["setup"]["sliders"][phase] = sliders.duplicate()
	var confirmed: Array = camp.get("confirmed_phases", [])
	confirmed.append(phase)
	camp["confirmed_phases"] = confirmed
	sim.state.waiting_for_input = false
	sim.state.waiting_campaign = ""
	return true


## S11: planlı kampanyada faz başında o fazın görev planı (Orgo: fazlar sırayla). weights: fazın üç görev ağırlığı
## (toplam 1), assign_row: üç görevin kişisi ("" boş; atama gerekmeyen işte yok sayılır), rentals: yalnız prodüksiyon fazında.
static func apply_task_phase(sim: Simulation, campaign_id: String, weights: Array, assign_row: Array, rentals: Array = []) -> String:
	var camp: Dictionary = sim.state.find_campaign(campaign_id)
	if camp.is_empty() or not sim.state.waiting_for_input or str(sim.state.waiting_campaign) != campaign_id:
		return "ERR_PLAN"
	var phase: int = sim.production.current_phase(camp)
	if (camp.get("confirmed_phases", []) as Array).has(phase) or weights.size() != 3:
		return "ERR_PLAN"
	var sum: float = 0.0
	for v: Variant in weights:
		if float(v) < 0.0:
			return "ERR_PLAN"
		sum += float(v)
	if not is_equal_approx(sum, 1.0):
		return "ERR_PLAN"
	var setup: Dictionary = camp["setup"]
	var team: Array = setup.get("team", [])
	if TaskPlan.has_plan(setup):
		if assign_row.size() != 3:
			return "ERR_PLAN"
		var any: bool = false
		for id: Variant in assign_row:
			if not str(id).is_empty() and not team.has(str(id)):
				return "ERR_PLAN_MEMBER"
			any = any or not str(id).is_empty()
		if not any:
			return "ERR_PLAN_EMPTY"
	if not rentals.is_empty():
		if phase != 2:
			return "ERR_PLAN"
		var err: String = sim.equipment.validate_rentals(sim.state, rentals)
		if not err.is_empty():
			return err
		sim.economy.pay(sim.state, sim.equipment.rental_cost(sim.state, rentals))
		var have: Array = setup.get("rentals", [])
		for id: Variant in rentals:
			if not have.has(id):
				have.append(id)
		setup["rentals"] = have
	setup["sliders"][phase] = weights.duplicate()
	if TaskPlan.has_plan(setup):
		setup["assign"][phase] = assign_row.duplicate()
	var confirmed: Array = camp.get("confirmed_phases", [])
	confirmed.append(phase)
	camp["confirmed_phases"] = confirmed
	sim.state.waiting_for_input = false
	sim.state.waiting_campaign = ""
	return ""


## Oyuncu fazın görev planını onaylar (K-118): { emp_id: [a0, a1, a2] }. Kaydırıcılar plandan hesaplanır.
## rentals (K-119): bu kampanya için kiralanan ekipman; bedeli hemen ödenir.
static func apply_plan(sim: Simulation, plan: Dictionary, rentals: Array = []) -> String:
	if sim.state.active_campaign.is_empty() or not sim.state.waiting_for_input:
		return "ERR_PLAN"
	var camp: Dictionary = sim.state.active_campaign
	var err: String = WorkPlan.validate(sim.data, plan, camp["setup"].get("team", []))
	if err.is_empty() and not rentals.is_empty():
		err = sim.equipment.validate_rentals(sim.state, rentals)
	if not err.is_empty():
		return err
	if not rentals.is_empty():
		sim.economy.pay(sim.state, sim.equipment.rental_cost(sim.state, rentals))
		var have: Array = camp["setup"].get("rentals", [])
		for id: Variant in rentals:
			if not have.has(id):
				have.append(id)
		camp["setup"]["rentals"] = have
	var phase: int = sim.production.current_phase(camp)
	var plans: Array = camp["setup"].get("plan", [{}, {}, {}])
	plans[phase] = plan.duplicate(true)
	camp["setup"]["plan"] = plans
	return "" if apply_sliders(sim, WorkPlan.shares_of(plan)) else "ERR_PLAN"
