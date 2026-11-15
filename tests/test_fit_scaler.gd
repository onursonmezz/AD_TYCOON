extends GutTest
## K-122: pencere içeriği kaydırma yerine küçülerek sığar; en küçük ölçekten sonra kaydırmaya bırakır.


func _box(h: float) -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = Vector2(100.0, h)
	return c


func _fit(content_h: float, room_h: float, smallest: float) -> FitScaler:
	var fit: FitScaler = FitScaler.new(smallest)
	fit.add_child(_box(content_h))
	add_child_autofree(fit)
	fit.size = Vector2(400.0, room_h)
	fit.notification(Container.NOTIFICATION_SORT_CHILDREN)
	return fit


func test_fits_without_scaling() -> void:
	var fit: FitScaler = _fit(200.0, 300.0, 0.7)
	assert_almost_eq(fit.current_scale(), 1.0, 0.001)
	assert_almost_eq((fit.get_child(0) as Control).size.y, 300.0, 0.5, "içerik pencereyi doldurur")


func test_shrinks_to_fit() -> void:
	var fit: FitScaler = _fit(400.0, 300.0, 0.7)
	assert_almost_eq(fit.current_scale(), 0.75, 0.001)
	var c: Control = fit.get_child(0)
	assert_almost_eq(c.size.y * c.scale.y, 300.0, 0.5, "küçülen içerik tam sığar")
	assert_almost_eq(c.size.x * c.scale.x, 400.0, 0.5, "genişlik de pencereyi doldurur")


func test_stops_at_min_scale() -> void:
	var fit: FitScaler = _fit(1000.0, 300.0, 0.7)
	assert_almost_eq(fit.current_scale(), 0.7, 0.001)
	await get_tree().process_frame  # en küçük boy ertelenmiş bildirilir
	assert_gt(fit.get_combined_minimum_size().y, 300.0, "sığmazsa dıştaki kaydırma devreye girsin")
