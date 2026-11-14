extends GutTest
## K-120: mini oyunların başarı ölçümü (arayüz düğümleri, oyun durumu olmadan).

func _ctx() -> Dictionary:
	var camp: Dictionary = {"id": "cmp_test", "setup": {"sector": "fast_food", "client_name": "Test", "client_id": "cl_t",
		"mix": [{"channel": "radio", "share": 1.0}], "objective": "awareness"}}
	return {"camp": camp, "setup": camp["setup"], "brand": "Test", "accent": Color.SEA_GREEN, "year": 1995, "seed": 3}


func _start(game: MinigameGame) -> MinigameGame:
	game.ctx = _ctx()
	add_child_autofree(game)
	game.begin()
	watch_signals(game)
	return game


func _click(game: Control, p: Vector2) -> void:
	var ev: InputEventMouseButton = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = p
	game._gui_input(ev)


func test_radio_in_order_is_perfect_and_mistakes_cost() -> void:
	var g: MgRadio = _start(MgRadio.new())
	var order: Array[int] = g.get("_order")
	_click(g, g.call("_piece_rect", order.find(1)).get_center())  # yanlış: önce 1
	for piece: int in 3:
		_click(g, g.call("_piece_rect", order.find(piece)).get_center())
	assert_signal_emitted(g, "finished")
	var q: float = get_signal_parameters(g, "finished")[0]
	assert_almost_eq(q, 0.66, 0.01, "bir yanlış tık")


func test_billboard_center_catch_scores_high_and_miss_scores_zero() -> void:
	var g: MgBillboard = _start(MgBillboard.new())
	var car: TextureRect = g.get("_car")
	car.position.x = float(g.get("_target_x")) - MgBillboard.CAR_WIDTH * 0.5
	g.call("_catch")
	assert_almost_eq(float(get_signal_parameters(g, "finished")[0]), 1.0, 0.01)
	var late: MgBillboard = _start(MgBillboard.new())
	(late.get("_car") as TextureRect).position.x = MinigameGame.CANVAS.x
	late.call("_catch")
	assert_almost_eq(float(get_signal_parameters(late, "finished")[0]), 0.0, 0.01)


func test_newspaper_drop_inside_box_finishes() -> void:
	var g: MgNewspaper = _start(MgNewspaper.new())
	var ad: Control = g.get("_ad")
	var slot: Rect2 = g.get("_slot")
	ad.position = Vector2(5, 5)
	g.call("_drop")
	assert_signal_not_emitted(g, "finished", "kutunun dışı: tekrar dene")
	ad.position = slot.position
	g.call("_drop")
	assert_almost_eq(float(get_signal_parameters(g, "finished")[0]), 1.0, 0.01)


func test_draft_offers_three_and_skip_picks_first() -> void:
	var g: MgDraft = _start(MgDraft.new())
	assert_eq((g.get("_drafts") as Array).size(), 3)
	watch_signals(g)
	g.time_up()
	assert_signal_emitted(g, "chosen")
	assert_eq(get_signal_parameters(g, "chosen")[0], (g.get("_drafts") as Array)[0])
