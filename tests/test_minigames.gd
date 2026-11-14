extends GutTest
## K-120: fazlar arası mini oyunlar — oyun seçimi, sonuç kaydı, en çok %5 bonus, taslak seçimi.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _camp(channel: String) -> Dictionary:
	return {"setup": {"client_id": "cl_x", "mix": [{"channel": channel, "share": 1.0}]}}


func test_strategy_game_first_then_channel_game_then_draft() -> void:
	assert_eq(Minigames.game_for(data, _camp("radio")["setup"], 0), "audience", "strateji fazı: hedef kitle")
	assert_eq(Minigames.game_for(data, _camp("radio")["setup"], 1), "radio_wave")
	assert_eq(Minigames.game_for(data, _camp("billboard")["setup"], 0), "map", "açık havada strateji: konum")
	assert_eq(Minigames.game_for(data, _camp("billboard")["setup"], 1), "billboard")
	assert_eq(Minigames.game_for(data, _camp("magazine")["setup"], 1), "newspaper", "basılı kategori → gazete")
	assert_eq(Minigames.game_for(data, _camp("national_tv")["setup"], 1), "film")
	assert_eq(Minigames.game_for(data, _camp("instafoto")["setup"], 1), "feed")
	assert_eq(Minigames.game_for(data, _camp("guerrilla")["setup"], 1), "map")
	assert_eq(Minigames.game_for(data, _camp("guerrilla")["setup"], 0), "audience", "iki oyun aynı çıkmaz")
	assert_eq(Minigames.game_for(data, _camp("radio")["setup"], 2), Minigames.DRAFT, "kreatiften sonra taslak seçimi")


func test_bonus_is_at_most_five_percent_and_skipping_costs_nothing() -> void:
	var camp: Dictionary = _camp("radio")
	assert_almost_eq(Minigames.mult(data, camp), 1.0, 0.0001, "oynanmadıysa çarpan 1")
	Minigames.record(camp, 0, 1.0)
	assert_almost_eq(Minigames.mult(data, camp), 1.0 + data.balf("minigames.max_bonus") * 0.5, 0.0001, "iki oyundan biri")
	Minigames.record(camp, 1, 3.0)
	assert_almost_eq(Minigames.mult(data, camp), 1.0 + data.balf("minigames.max_bonus"), 0.0001, "üst sınır %5")
	Minigames.record(camp, 1, 0.0)
	assert_gte(Minigames.mult(data, camp), 1.0, "atlamak cezalandırmaz")


func test_pending_and_draft_choice() -> void:
	var camp: Dictionary = _camp("newspaper")
	assert_true(Minigames.pending(camp, 0))
	Minigames.record(camp, 0, 0.5)
	assert_false(Minigames.pending(camp, 0))
	assert_true(Minigames.pending(camp, 2))
	Minigames.choose_draft(camp, {"bg": "bg_sunny", "product": "product_fast_food_1"})
	assert_false(Minigames.pending(camp, 2))
	assert_eq(str(camp["setup"]["draft"]["bg"]), "bg_sunny")
