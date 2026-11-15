class_name FitScaler
extends Container
## Pencere içeriğini kaydırmak yerine küçülterek sığdırır (K-122): içerik yer kaplamazsa ölçek 1,
## taşarsa orantılı küçülür; en küçük ölçek data/ui_layout.json "fit_min_scale". Ondan da büyükse
## en küçük ölçekte kalır ve dıştaki kaydırma devreye girer (son çare).

var min_scale: float = 1.0
var _scale: float = 1.0
var _busy: bool = false  # yerleşim sırasında kendi kendini yeniden çağırmasın (İngilizce kampanyada çökme)
var _min_h: float = 0.0  # en son bildirilen en küçük yükseklik; yalnızca belirgin değişince güncellenir
## Denenip hemen geri alınan büyütme: [kutu boyu, içerik yüksekliği]. Aynı durumda bir daha denenmez; yoksa metin
## iki ölçek arasında gidip gelir (küçülünce satır kırılması azalır, içerik kısalır, büyüyünce yine taşar) ve oyun çöker.
var _rejected: Array = []
const MAX_STREAK: int = 8
var _streak: int = 0
var _changed_frame: int = -100
var _last_grow: Array = []  # [kutu boyu, içerik yüksekliği, büyütmeden önceki ölçek]


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
	return Vector2(0.0, _min_h)


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN or _busy:
		return
	var c: Control = _content()
	if c == null or size.x <= 0.0 or size.y <= 0.0:
		return
	_busy = true
	_layout_child(c)
	_busy = false


func _layout_child(c: Control) -> void:
	var need: Vector2 = c.get_combined_minimum_size()
	var s: float = 1.0
	if need.y > size.y:
		s = size.y / need.y
	if need.x > size.x:
		s = minf(s, size.x / need.x)
	s = clampf(s, min_scale, 1.0)
	# Son çare: ölçek ardışık karelerde durmadan değişiyorsa artık yalnızca küçülür (küçülme her zaman durulur).
	var frame: int = Engine.get_process_frames()
	if not is_equal_approx(s, _scale):
		_streak = _streak + 1 if frame - _changed_frame <= 2 else 0
		_changed_frame = frame
	if _streak > MAX_STREAK:
		s = minf(s, _scale)
	if s > _scale + 0.001:
		if _rejected == [size, need.y]:
			s = _scale  # bu büyütme az önce denendi, hemen geri küçülmek gerekti
		else:
			_last_grow = [size, need.y, _scale]
	elif s < _scale - 0.001:
		# Büyüttükten hemen sonra eski ölçeğe geri dönüyorsak o büyütme işe yaramıyor: hatırla.
		if not _last_grow.is_empty() and _last_grow[0] == size and absf(s - float(_last_grow[2])) < 0.002:
			_rejected = [size, _last_grow[1]]
		_last_grow = []
	c.position = Vector2.ZERO
	c.scale = Vector2(s, s)
	c.size = Vector2(size.x / s, maxf(need.y, size.y / s))
	_scale = s
	# En küçük boy yalnızca 1 pikselden fazla değişince bildirilir (kaydırma çubuğu belirip kaybolurken
	# genişlik → satır kırma → yükseklik zinciri durmadan dönmesin).
	var want: float = need.y * min_scale
	if absf(want - _min_h) > 1.0:
		_min_h = want
		update_minimum_size.call_deferred()
