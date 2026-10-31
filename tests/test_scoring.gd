extends GutTest
## Puanlama testleri (GDD 7.2–7.9, M1 kabul).

var data: GameData
var scoring: Scoring


func before_all() -> void:
	data = GameData.load_from()
	scoring = Scoring.new(data)


func _setup(sector: String, objective: String, audience: String, tone: String, channel: String) -> Dictionary:
	return {"client_id": "cl_test", "sector": sector, "objective": objective, "audience": audience, "tone": tone,
		"mix": [{"channel": channel, "share": 1.0}], "sliders": [[0.6, 0.4, 0.0], [0.6, 0.4, 0.0], [0.6, 0.4, 0.0]],
		"size": "small", "fee": 10000.0, "media_budget": 30000.0, "deadline_weeks": 6}


func _campaign(setup: Dictionary, per_area: float = 10.0) -> Dictionary:
	var points: Dictionary = {}
	for id: String in data.focus_ids:
		points[id] = per_area
	return {"id": "cp_test", "setup": setup, "points": points, "errors": 0}


const NEUTRAL_CLIENT: Dictionary = {"personality": {"risk": 50}}


func test_data_loads() -> void:
	assert_eq(data.errors.size(), 0, "\n".join(data.errors))


func test_fit_mult_table_values() -> void:
	assert_almost_eq(scoring.fit_mult(-3), 0.45, 0.0001)
	assert_almost_eq(scoring.fit_mult(0), 1.0, 0.0001)
	assert_almost_eq(scoring.fit_mult(3), 1.25, 0.0001)


func test_fit_mult_interpolates_half_values() -> void:
	assert_almost_eq(scoring.fit_mult(0.5), 1.03, 0.0001)
	assert_almost_eq(scoring.fit_mult(-2.5), 0.535, 0.0001)


func test_triple_plus_combination_beats_triple_minus() -> void:
	# Fast Food: Satış +++ / Genç +++  vs  SSR −− / B2B −−− ; kanal ve ton aynı
	var good: Dictionary = _setup("fast_food", "sales", "young", "humorous", "radio")
	var bad: Dictionary = _setup("fast_food", "csr", "b2b", "humorous", "radio")
	var m_good: float = scoring.combination(good, NEUTRAL_CLIENT)["m"]
	var m_bad: float = scoring.combination(bad, NEUTRAL_CLIENT)["m"]
	assert_gt(m_good, m_bad)
	var rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_a.seed = 7
	var rng_b: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_b.seed = 7
	var r_good: Dictionary = scoring.evaluate(_campaign(good), NEUTRAL_CLIENT, [], 10, 1990, 0.0, rng_a)
	var r_bad: Dictionary = scoring.evaluate(_campaign(bad), NEUTRAL_CLIENT, [], 10, 1990, 0.0, rng_b)
	assert_gt(float(r_good["raw"]), float(r_bad["raw"]))
	assert_gt(float(r_good["score"]), float(r_bad["score"]) + 1.0, "+++ kombinasyon belirgin şekilde yüksek puan almalı")


func test_bold_brand_gets_bold_tone_bonus() -> void:
	var bold_client: Dictionary = {"personality": {"risk": 90}}
	var shy_client: Dictionary = {"personality": {"risk": 10}}
	var base: int = data.fit("tone", "food_beverage", "bold")
	assert_eq(scoring.tone_value("fast_food", "bold", NEUTRAL_CLIENT), base)
	assert_eq(scoring.tone_value("fast_food", "bold", bold_client), mini(3, base + 1))
	assert_eq(scoring.tone_value("fast_food", "bold", shy_client), maxi(-3, base - 1))


func test_focus_ideal_sliders_give_max_f() -> void:
	# Bilinirlik, faz 1: Araştırma ~, İçgörü ++, Konum. ++ → ideal %60/%40 iki ++ alana
	var pf: Dictionary = scoring.phase_focus("awareness", 0, [0.0, 0.6, 0.4])
	assert_almost_eq(float(pf["f"]), 1.2, 0.0001)
	var worse: Dictionary = scoring.phase_focus("awareness", 0, [1.0, 0.0, 0.0])
	assert_lt(float(worse["f"]), 1.0)


func test_overcap_slider_has_diminishing_returns() -> void:
	assert_almost_eq(scoring.effective_share(0.6), 0.6, 0.0001)
	assert_almost_eq(scoring.effective_share(1.0), 0.8, 0.0001)
	var all_in: Dictionary = scoring.phase_focus("awareness", 0, [0.0, 1.0, 0.0])
	assert_lt(float(all_in["f"]), 1.2, "tek alana %100 ideal değil")


func test_balance_near_ideal_ratio_is_one() -> void:
	var ideal: float = float(data.objectives["sales"]["ideal_sk"])
	assert_almost_eq(float(scoring.balance_sk(ideal * 100.0, 100.0, "sales")["b"]), 1.0, 0.0001)
	assert_almost_eq(float(scoring.balance_sk(100.0, 100.0 * 1.05 / ideal, "sales")["b"]), 1.0, 0.02)
	assert_almost_eq(float(scoring.balance_sk(1000.0, 10.0, "rebrand")["b"]), 0.7, 0.0001, "en fazla %30 ceza")


func test_repeating_combination_gets_novelty_penalty() -> void:
	var setup: Dictionary = _setup("fast_food", "sales", "young", "humorous", "radio")
	var fresh: Dictionary = scoring.novelty(setup, [], 50, 1990)
	assert_almost_eq(float(fresh["n"]), 1.0, 0.0001)
	var history: Array[Dictionary] = [{"client_id": "cl_other", "sector": "fast_food", "objective": "sales",
		"main_channel": "radio", "week": 10}]
	var repeat: Dictionary = scoring.novelty(setup, history, 50, 1990)
	assert_almost_eq(float(repeat["n"]), 0.88 * 0.75, 0.0001)


func test_same_client_same_objective_within_12_weeks() -> void:
	var setup: Dictionary = _setup("fast_food", "sales", "young", "humorous", "radio")
	var history: Array[Dictionary] = [{"client_id": "cl_test", "sector": "automotive", "objective": "sales",
		"main_channel": "billboard", "week": 40}]
	assert_almost_eq(float(scoring.novelty(setup, history, 50, 1990)["n"]), 0.85, 0.0001)
	assert_almost_eq(float(scoring.novelty(setup, history, 60, 1990)["n"]), 1.0, 0.0001, "12 hafta sonra cezasız")


func test_pioneer_bonus_for_new_channel() -> void:
	var setup: Dictionary = _setup("ecommerce", "sales", "young", "humorous", "search_ads")  # 2002
	assert_almost_eq(float(scoring.novelty(setup, [], 0, 2003)["n"]), 1.10, 0.0001)
	assert_almost_eq(float(scoring.novelty(setup, [], 0, 2006)["n"]), 1.0, 0.0001)


func test_synergy_pair_and_fragmentation() -> void:
	var mix: Array = [{"channel": "national_tv", "share": 0.7}, {"channel": "search_ads", "share": 0.3}]
	var syn: Dictionary = scoring.synergy(mix, 1000000.0, 1990)
	assert_almost_eq(float(syn["synergy"]), 1.06, 0.0001)
	var many: Array = []
	for ch: String in ["newspaper", "magazine", "radio", "billboard", "cinema"]:
		many.append({"channel": ch, "share": 0.2})
	var frag: Dictionary = scoring.synergy(many, 10000.0, 1990)
	assert_almost_eq(float(frag["fragmentation"]), 0.12, 0.0001, "önerilen 1 kanal, 4 fazla × %3")


func test_recommended_channels_formula() -> void:
	assert_eq(scoring.recommended_channels(10000.0, 1990), 1)
	assert_eq(scoring.recommended_channels(100000.0, 1990), 2)
	assert_eq(scoring.recommended_channels(1000000.0, 1990), 4)


func test_relative_score_uses_era_base_and_soft_record() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var base: float = scoring.era_base(1990, "small")
	assert_almost_eq(base, 120.0, 0.0001)
	assert_almost_eq(scoring.era_base(1991, "medium"), 120.0 * 2.6 * 1.085, 0.001)
	var fin: Dictionary = scoring.final_score(200.0, 0, 1990, "small", 100.0, rng)
	assert_almost_eq(float(fin["target"]), 120.0, 0.0001, "rekor×1.05 < dönem tabanı → taban")
	assert_almost_eq(float(fin["new_best"]), 160.0, 0.0001, "en_iyi + 0.6*(ham − en_iyi)")
	var high: Dictionary = scoring.final_score(150.0, 0, 1990, "small", 200.0, rng)
	assert_almost_eq(float(high["target"]), 210.0, 0.0001)
	assert_almost_eq(float(high["new_best"]), 200.0, 0.0001, "rekor geçilmezse değişmez")


func test_score_is_clamped_1_to_10() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	assert_eq(float(scoring.final_score(0.0, 3, 1990, "small", 0.0, rng)["score"]), 1.0)
	assert_lte(float(scoring.final_score(10000.0, 0, 1990, "small", 0.0, rng)["score"]), 10.0)


func test_errors_reduce_raw_score() -> void:
	var setup: Dictionary = _setup("fast_food", "sales", "young", "humorous", "radio")
	var clean: Dictionary = _campaign(setup)
	var buggy: Dictionary = _campaign(setup)
	buggy["errors"] = 3
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var a: float = scoring.evaluate(clean, NEUTRAL_CLIENT, [], 0, 1990, 0.0, rng)["raw"]
	var b: float = scoring.evaluate(buggy, NEUTRAL_CLIENT, [], 0, 1990, 0.0, rng)["raw"]
	assert_almost_eq(a - b, 3.0 * scoring.error_weight(1990, "small"), 0.001)
