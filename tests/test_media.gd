extends GutTest
## M4-A: kanal karışımı, matbaa fiyat modeli, tedarikçiler, pazarlık, kanal bazında KPI (GDD 7.1, 7.3, 7.10, 9.1, 10).

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _job(qty: int, extra: Dictionary = {}) -> Dictionary:
	var job: Dictionary = {"product": "flyer_a5", "quality": "standard", "quantity": qty, "distribution": "door_to_door",
		"proof": false, "supplier": "renkli_baski", "negotiated_discount": 0.0}
	job.merge(extra, true)
	return job


func test_print_unit_price_drops_with_volume() -> void:
	# 25.3 örnek kabul kriteri: 10x adette birim fiyat %30–38 düşmeli.
	var sim: Simulation = Simulation.new(data, 1)
	var p1: float = sim.prints.unit_price(_job(1000), 1990, 0.0)
	var p10: float = sim.prints.unit_price(_job(10000), 1990, 0.0)
	var drop: float = 1.0 - p10 / p1
	assert_between(drop, 0.30, 0.38, "10x adet → birim fiyat ~%34 düşer")
	assert_almost_eq(p1, 0.15, 0.0001, "1990, standart, 1.000 adet = taban fiyat")


func test_print_quality_and_supplier_multipliers() -> void:
	var sim: Simulation = Simulation.new(data, 1)
	var base: float = sim.prints.unit_price(_job(1000), 1990, 0.0)
	assert_almost_eq(sim.prints.unit_price(_job(1000, {"quality": "premium"}), 1990, 0.0) / base, 1.6, 0.0001)
	assert_almost_eq(sim.prints.unit_price(_job(1000, {"supplier": "altin_varak"}), 1990, 0.0) / base, 1.3, 0.0001)


func test_digital_printer_has_flat_unit_price() -> void:
	var sim: Simulation = Simulation.new(data, 1)
	var small: float = sim.prints.unit_price(_job(1000, {"supplier": "hizli_dijital"}), 1990, 0.0)
	var big: float = sim.prints.unit_price(_job(100000, {"supplier": "hizli_dijital"}), 1990, 0.0)
	assert_gt(big / small, 0.85, "dijital baskıda ölçek ekonomisi yok denecek kadar az")
	var offset_small: float = sim.prints.unit_price(_job(1000), 1990, 0.0)
	assert_lt(small, offset_small, "küçük adette dijital ucuz")


func test_proof_reduces_errors_by_70_percent() -> void:
	var sim: Simulation = Simulation.new(data, 2)
	var no_proof: int = 0
	var with_proof: int = 0
	for i: int in 2000:
		if bool(sim.prints.run(_job(1000, {"supplier": "ucuzcu_ofset"}), sim.state)["error"]):
			no_proof += 1
		if bool(sim.prints.run(_job(1000, {"supplier": "ucuzcu_ofset", "proof": true}), sim.state)["error"]):
			with_proof += 1
	assert_between(no_proof, 120, 200, "%8 hata")
	assert_between(float(with_proof) / no_proof, 0.15, 0.45, "prova hatayı ~%70 azaltır")


func test_delivery_weeks_follow_capacity_and_proof() -> void:
	var sim: Simulation = Simulation.new(data, 1)
	assert_eq(sim.prints.delivery_weeks(_job(80000), sim.state), 3, "80k / 40k haftalık + 1 sıra")
	assert_eq(sim.prints.delivery_weeks(_job(80000, {"proof": true}), sim.state), 4)


func test_auto_job_fits_budget_with_margin() -> void:
	var sim: Simulation = Simulation.new(data, 1)
	var job: Dictionary = sim.prints.auto_job("flyer_brochure", 20000.0, "fast_food", sim.state)
	var total: float = float(sim.prints.cost(job, sim.state)["total"])
	assert_lte(total, 20000.0 * 0.8 + 0.01)
	assert_gt(total, 20000.0 * 0.6, "bütçenin çoğu kullanılır")
	assert_eq(job["quality"], "standard")
	assert_eq(sim.prints.auto_job("flyer_brochure", 20000.0, "luxury", sim.state)["quality"], "premium", "lüks sektör")


func test_auto_job_is_delivered_on_time() -> void:
	var sim: Simulation = Simulation.new(data, 1)
	for deadline: int in [4, 7, 12]:
		var job: Dictionary = sim.prints.auto_job("flyer_brochure", 60000.0, "fast_food", sim.state, deadline)
		assert_lte(sim.prints.delivery_weeks(job, sim.state), PrintSystem.print_window_weeks(deadline),
			"otomatik baskı son faza sığar (teslim %d hafta)" % deadline)


func test_channel_limit_by_year_office_and_media_planner() -> void:
	var sim: Simulation = Simulation.new(data, 1)
	var team: Array = [sim.state.founder()["id"]]
	assert_eq(sim.media.channel_limit(sim.state, team), 1, "Y1–Y2 tek kanal (17: Medya Planlama Y3)")
	sim.state.clock.week_index = 2 * 48
	assert_eq(sim.media.channel_limit(sim.state, team), 2, "ev odası: 2")
	var mp: Dictionary = sim.staff._blank(sim.state, "media_planner", 1)
	mp["stats"] = {"strategy": 60.0, "creative": 40.0, "technical": 50.0, "communication": 60.0, "speed": 50.0, "attention": 50.0}
	sim.state.staff[mp["id"]] = mp
	team.append(mp["id"])
	assert_eq(sim.media.channel_limit(sim.state, team), 3, "medya planlamacı +1")
	assert_almost_eq(sim.media.efficiency(sim.state, team), 1.15, 0.0001, "1 + 60/400")


func test_multi_channel_campaign_with_print_runs_end_to_end() -> void:
	var sim: Simulation = Simulation.new(data, 4)
	sim.state.clock.week_index = 2 * 48
	sim.state.cash = 500000.0
	while sim.state.inbox.is_empty():
		sim.step_week()
	var brief: Dictionary = sim.state.inbox[0]
	var r: Dictionary = sim.start_campaign(brief["id"], {"objective": "sales", "audience": "adult", "tone": "humorous",
		"mix": [{"channel": "radio", "share": 0.6}, {"channel": "flyer_brochure", "share": 0.4}]})
	assert_true(r["ok"], str(r))
	var job: Dictionary = sim.state.active_campaign["setup"]["mix"][1]["options"]["job"]
	assert_false(job.is_empty(), "basılı kanala otomatik baskı işi konur")
	for i: int in 40:
		sim.step_week()
	assert_eq(sim.state.finished.size(), 1)
	var camp: Dictionary = sim.state.finished[0]
	assert_eq((camp["kpi"]["per_channel"] as Array).size(), 2, "kanal bazında KPI")
	assert_eq((camp["print_results"] as Array).size(), 1)
	assert_gt(float(camp["income"]["production_margin"]), 0.0, "baskı marjı gelire girer")
	assert_almost_eq(float(camp["income"]["commission"]), float(brief["media_budget"]) * 0.6 * 0.15, 0.5,
		"komisyon yalnız medya kısmından")


func test_too_many_channels_rejected() -> void:
	var sim: Simulation = Simulation.new(data, 4)
	while sim.state.inbox.is_empty():
		sim.step_week()
	var r: Dictionary = sim.start_campaign(sim.state.inbox[0]["id"], {"objective": "sales", "audience": "adult",
		"tone": "humorous", "mix": [{"channel": "radio", "share": 0.5}, {"channel": "newspaper", "share": 0.5}]})
	assert_eq(r["error"], "ERR_TOO_MANY_CHANNELS", "Y1'de çoklu kanal yok")


func test_negotiation_accepts_at_or_above_floor() -> void:
	var sim: Simulation = Simulation.new(data, 7)
	var n: Dictionary = NegotiateCommand.new("renkli_baski", 10000.0).execute(sim)
	var floor_price: float = float(n["min_price"])
	assert_between(floor_price, 7400.0, 9500.0, "taban liste fiyatının %5–25 altında (ilişki etkisiyle)")
	n = NegotiateCommand.new("renkli_baski", 0.0, floor_price - 100.0).execute(sim)
	assert_true(n["status"] == "open" or n["status"] == "failed")
	n = NegotiateCommand.new("renkli_baski", 0.0, floor_price + 1.0).execute(sim)
	if n["status"] == "accepted":
		assert_almost_eq(sim.suppliers.negotiated_discount(sim.state), 1.0 - (floor_price + 1.0) / 10000.0, 0.0001)


func test_negotiation_fails_after_three_rounds() -> void:
	var sim: Simulation = Simulation.new(data, 8)
	NegotiateCommand.new("ucuzcu_ofset", 10000.0).execute(sim)
	var n: Dictionary = {}
	for i: int in 3:
		n = NegotiateCommand.new("ucuzcu_ofset", 0.0, 1.0).execute(sim)
	assert_eq(n["status"], "failed")
	assert_almost_eq(sim.suppliers.negotiated_discount(sim.state), 0.0, 0.0001, "liste fiyatı geçerli")


func test_purchasing_specialist_shows_hint() -> void:
	var sim: Simulation = Simulation.new(data, 9)
	NegotiateCommand.new("renkli_baski", 10000.0).execute(sim)
	assert_eq(sim.suppliers.hint(sim.state), [], "satın alma uzmanı yoksa ipucu yok")
	var emp: Dictionary = sim.staff._blank(sim.state, "purchasing", 1)
	emp["stats"] = {"communication": 80.0}
	sim.state.staff[emp["id"]] = emp
	var h: Array = sim.suppliers.hint(sim.state)
	assert_eq(h.size(), 2)
	assert_between(float(sim.state.negotiation["min_price"]), float(h[0]), float(h[1]))


func test_supplier_offers_and_annual_penalty() -> void:
	var sim: Simulation = Simulation.new(data, 10)
	var s: Dictionary = data.bal("suppliers")
	var old: float = float(s["offer_weekly_chance"])
	s["offer_weekly_chance"] = 1.0
	var offer: Dictionary = {}
	while offer.is_empty() or offer["type"] != "annual":
		sim.state.supplier_offers.clear()
		offer = sim.suppliers.weekly(sim.state)
	s["offer_weekly_chance"] = old
	assert_eq(RespondSupplierOfferCommand.new(offer["id"], true).execute(sim), "")
	assert_gt(sim.suppliers.discount(sim.state, offer["supplier"], 1000), float(offer["discount"]) - 0.0001)
	sim.state.clock.week_index = 48
	var penalty: float = sim.suppliers.year_end(sim.state)
	assert_gt(penalty, 0.0, "taahhüt tutmazsa ceza")
	assert_eq(sim.state.supplier_deals.size(), 0)


func test_relationship_grows_with_work() -> void:
	var sim: Simulation = Simulation.new(data, 11)
	var r0: float = sim.suppliers.relationship(sim.state, "renkli_baski")
	sim.prints.run(_job(1000), sim.state)
	assert_almost_eq(sim.suppliers.relationship(sim.state, "renkli_baski"), r0 + 2.0, 0.0001)


func test_interest_curve_scales_channel_effect() -> void:
	var sim: Simulation = Simulation.new(data, 12)
	var setup: Dictionary = {"sector": "fast_food", "objective": "awareness", "audience": "adult", "tone": "emotional",
		"mix": [{"channel": "newspaper", "share": 1.0}], "fee": 1000.0, "media_budget": 20000.0}
	var client: Dictionary = {"scale": 3}
	var early: Dictionary = sim.kpi.compute(setup, client, 6.0, 1990, sim.state.rng)
	var late: Dictionary = sim.kpi.compute(setup, client, 6.0, 2030, sim.state.rng)
	assert_gt(float(early["per_channel"][0]["impressions"]), float(late["per_channel"][0]["impressions"]) * 3.0,
		"gazete 2030'da çok daha etkisiz (enflasyon dahil)")


func test_cpm_season() -> void:
	var sim: Simulation = Simulation.new(data, 1)
	assert_almost_eq(sim.kpi.cpm_season(1995, 12), 1.2, 0.0001, "yılbaşı")
	assert_almost_eq(sim.kpi.cpm_season(1995, 6), 1.0, 0.0001)
