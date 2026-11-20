extends GutTest
## K-033 (Orgo, değişmez): görev planı çubukları birbirinden bağımsız; biri oynatılınca diğerleri kaymaz.
## Pay = öncelik / fazın öncelikleri toplamı.


func test_moving_one_bar_does_not_move_the_others() -> void:
	var d: TaskPlanDialog = TaskPlanDialog.new({}, {}, Callable())
	assert_false(d.has_method("_rebalance"), "kaydırıcılar birbirini itmez (K-033)")
	d._raw[1] = [50.0, 50.0, 50.0]
	d._raw[1][0] = 100.0  # çubuğun yaptığı tek şey
	assert_eq(float(d._raw[1][1]), 50.0)
	assert_eq(float(d._raw[1][2]), 50.0)
	var s: Array = d.sliders()
	assert_almost_eq(float(s[1][0]), 0.5, 0.001, "pay = 100 / (100+50+50)")
	assert_almost_eq(float(s[1][1]), 0.25, 0.001)
	d.free()
