extends GutTest
## K-120: fazlar arası mini oyunlar — oyun seçimi, sonuç kaydı, en çok %5 bonus, taslak seçimi.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _camp(channel: String) -> Dictionary:
	return {"setup": {"client_id": "cl_x", "mix": [{"channel": channel, "share": 1.0}]}}


func test_game_follows_main_channel_and_changes_next_phase() -> void:
	assert_eq(Minigames.game_for(data, _camp("radio")["setup"], 0), "radio_wave")
	assert_eq(Minigames.game_for(data, _camp("billboard")["setup"], 0), "billboard")
	assert_eq(Minigames.game_for(data, _camp("magazine")["setup"], 0), "newspaper", "basılı kategori → gazete")
	assert_ne(Minigames.game_for(data, _camp("radio")["setup"], 1), "radio_wave", "ikinci fazda başka oyun")
	assert_eq(Minigames.game_for(data, _camp("radio")["setup"], 2), Minigames.DRAFT, "kreatiften sonra taslak seçimi")
	var unknown: String = Minigames.game_for(data, _camp("tiktak")["setup"], 0)
	assert_true((data.bal("minigames.pool") as Array).has(unknown), "eşlemesi olmayan kanal havuzdan bir oyun alır")


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
