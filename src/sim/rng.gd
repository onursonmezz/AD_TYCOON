class_name SimRng
extends RefCounted
## Tohumlu rastgelelik (GDD 24.5): her sistem kendi akışını kullanır, aynı tohum = aynı oyun.
## Bir sisteme yeni rastgele çağrı eklemek diğer sistemlerin sonuçlarını kaydırmaz.

var seed_value: int = 0
var _streams: Dictionary = {}


func _init(seed_in: int = 0) -> void:
	seed_value = seed_in


func stream(stream_name: String) -> RandomNumberGenerator:
	if not _streams.has(stream_name):
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = hash(str(seed_value) + ":" + stream_name)
		_streams[stream_name] = rng
	return _streams[stream_name]


func chance(stream_name: String, p: float) -> bool:
	return stream(stream_name).randf() < p


func range_f(stream_name: String, lo: float, hi: float) -> float:
	return stream(stream_name).randf_range(lo, hi)


func range_i(stream_name: String, lo: int, hi: int) -> int:
	return stream(stream_name).randi_range(lo, hi)


func pick(stream_name: String, items: Array) -> Variant:
	if items.is_empty():
		return null
	return items[stream(stream_name).randi_range(0, items.size() - 1)]


## Ağırlıklı seçim; ağırlıkların indeksini döndürür.
func pick_weighted_index(stream_name: String, weights: Array) -> int:
	var total: float = 0.0
	for w: Variant in weights:
		total += float(w)
	var roll: float = stream(stream_name).randf() * total
	for i: int in weights.size():
		roll -= float(weights[i])
		if roll < 0.0:
			return i
	return weights.size() - 1
