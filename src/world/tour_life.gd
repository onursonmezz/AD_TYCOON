class_name TourLife
extends Node
## Gezinti modunda zaman dururken ofisin canlı görünmesi (K-148): arada biri masasından kalkıp mutfağa ya da
## dinlenme alanına gider, biraz durur, geri döner; masadakiler yazma ile telefon arasında geçer.
## Yalnızca görüntü: simülasyona, kayda ve oyunun tohumlu rastgeleliğine dokunmaz (kendi zarı var).
## Ayarlar data/look.json "tour.life".

var _world: OfficeWorld
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _stroll_in: float = 0.0
var _switch_in: float = 0.0
## Masasından kalkmış olanlar: id → { "place", "slot", "stay" (varınca kalacağı süre), "activity" (dönünce) }
var _away: Dictionary = {}


func _init(world: OfficeWorld) -> void:
	_world = world
	_rng.randomize()
	_stroll_in = _roll("stroll_every") * 0.4  # ilk kalkış çabuk gelsin
	_switch_in = _roll("switch_every")


static func cfg() -> Dictionary:
	return WorldLook.cfg()["tour"]["life"]


func away_count() -> int:
	return _away.size()


func _roll(key: String) -> float:
	var r: Array = cfg()[key]
	return _rng.randf_range(float(r[0]), float(r[1]))


func _process(delta: float) -> void:
	_stroll_in -= delta
	_switch_in -= delta
	if _stroll_in <= 0.0:
		_stroll_in = _roll("stroll_every")
		_send_someone()
	if _switch_in <= 0.0:
		_switch_in = _roll("switch_every")
		_switch_someone()
	for id: String in _away.keys():
		var c: OfficeCharacter = _world.character(id)
		if c == null:
			_away.erase(id)
			continue
		if c.is_moving():
			continue
		_away[id]["stay"] = float(_away[id]["stay"]) - delta
		if float(_away[id]["stay"]) <= 0.0:
			var back: String = str(_away[id]["activity"])
			_away.erase(id)
			_world.go_home(id)
			c.set_activity(back)


## Masasında oturan, uyumayan biri (en fazla max_away kişi aynı anda) boş bir mutfak / dinlenme yerine gider.
func _send_someone() -> void:
	if _away.size() >= int(cfg()["max_away"]):
		return
	var pool: Array[String] = _at_desk()
	if pool.is_empty():
		return
	var id: String = pool[_rng.randi() % pool.size()]
	var places: Array[String] = []
	for place: String in ["kitchen", "lounge"]:
		if _free_slot(place) >= 0:
			places.append(place)
	if places.is_empty():
		return
	var place: String = places[_rng.randi() % places.size()]
	var c: OfficeCharacter = _world.character(id)
	_away[id] = {"place": place, "slot": _free_slot(place), "stay": _roll("stay"), "activity": c.wanted_activity()}
	_world.send(id, place, int(_away[id]["slot"]))
	c.set_activity("coffee" if place == "kitchen" else "sit")


## Masada yazan biri telefona geçer, telefondaki yazmaya döner.
func _switch_someone() -> void:
	var pool: Array[String] = []
	for id: String in _at_desk():
		if ["type", "phone"].has(_world.character(id).wanted_activity()):
			pool.append(id)
	if pool.is_empty():
		return
	var c: OfficeCharacter = _world.character(pool[_rng.randi() % pool.size()])
	c.set_activity("phone" if c.wanted_activity() == "type" else "type")


## Masasına varmış, kalkmamış, uyumayan / stres yapmayanlar.
func _at_desk() -> Array[String]:
	var out: Array[String] = []
	for id: String in _world.character_ids():
		var c: OfficeCharacter = _world.character(id)
		if _away.has(id) or not c.visible or c.is_moving() or not _world.home_place(id).begins_with("desk"):
			continue
		if ["sleep", "stress"].has(c.wanted_activity()):
			continue
		out.append(id)
	return out


## place'in kimsenin (gerçekte orada olan ya da gezintide giden) kullanmadığı ilk yeri; yoksa −1.
func _free_slot(place: String) -> int:
	var spots: int = _world.layout.spot_list(place).size()
	var used: Dictionary = {}
	for id: String in _world.character_ids():
		var home: String = _world.home_place(id)
		if home.get_slice(":", 0) == place:
			used[int(home.get_slice(":", 1))] = true
	for a: Dictionary in _away.values():
		if a["place"] == place:
			used[int(a["slot"])] = true
	for i: int in spots:
		if not used.has(i):
			return i
	return -1
