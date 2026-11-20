extends GutTest
## S12 (Orgo): görev planında çubuk konumu görevin gerçek yüzdesi; üç görev hep %100, kalan pay eski oranlarla dağılır.


func test_raising_one_task_shares_the_rest_by_old_ratio() -> void:
	var d: TaskPlanDialog = TaskPlanDialog.new({}, {}, Callable())
	d._raw[1] = [40.0, 40.0, 20.0]
	d._rebalance(1, 0, 70.0)
	assert_almost_eq(float(d._raw[1][0]), 70.0, 0.001)
	assert_almost_eq(float(d._raw[1][1]), 20.0, 0.001, "kalan %30, eski 40:20 oranıyla")
	assert_almost_eq(float(d._raw[1][2]), 10.0, 0.001)
	var s: Array = d.sliders()
	assert_almost_eq(float(s[1][0]), 0.70, 0.001, "çubuk %70'te → pay %70")
	d.free()


func test_zero_others_split_evenly() -> void:
	var d: TaskPlanDialog = TaskPlanDialog.new({}, {}, Callable())
	d._raw[0] = [100.0, 0.0, 0.0]
	d._rebalance(0, 0, 50.0)
	assert_almost_eq(float(d._raw[0][1]), 25.0, 0.001)
	assert_almost_eq(float(d._raw[0][2]), 25.0, 0.001)
	d.free()
