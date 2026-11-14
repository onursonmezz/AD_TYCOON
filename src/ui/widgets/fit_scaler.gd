class_name FitScaler
extends Container
## Pencere içeriğini kaydırmak yerine küçülterek sığdırır (K-122): içerik yer kaplamazsa ölçek 1,
## taşarsa orantılı küçülür; en küçük ölçek data/ui_layout.json "fit_min_scale". Ondan da büyükse
## en küçük ölçekte kalır ve dıştaki kaydırma devreye girer (son çare).

var min_scale: float = 1.0
var _scale: float = 1.0


func _init(smallest: float) -> void:
	min_scale = smallest
	clip_contents = true


## Şu anki ölçek (testler ve çekim aracı için).
func current_scale() -> float:
	return _scale


func _content() -> Control:
	for c: Node in get_children():
		if c is Control and (c as Control).visible:
			return c
	return null


func _get_minimum_size() -> Vector2:
	var c: Control = _content()
	if c == null:
		return Vector2.ZERO
	return Vector2(0.0, c.get_combined_minimum_size().y * min_scale)


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	var c: Control = _content()
	if c == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var need: Vector2 = c.get_combined_minimum_size()
	var s: float = 1.0
	if need.y > size.y:
		s = size.y / need.y
	if need.x > size.x:
		s = minf(s, size.x / need.x)
	s = clampf(s, min_scale, 1.0)
	# Daralan genişlik metni bir satır daha kaydırabilir; yeni genişlikte bir kez daha ölç.
	c.position = Vector2.ZERO
	c.scale = Vector2(s, s)
	c.size = Vector2(size.x / s, maxf(need.y, size.y / s))
	var again: float = c.get_combined_minimum_size().y
	if again > need.y and again * s > size.y and s > min_scale:
		s = clampf(size.y / again, min_scale, 1.0)
		c.scale = Vector2(s, s)
		c.size = Vector2(size.x / s, maxf(again, size.y / s))
	if not is_equal_approx(s, _scale):
		_scale = s
		update_minimum_size()
