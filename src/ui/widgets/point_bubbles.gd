class_name PointBubbles
extends Control
## Puan baloncukları (S3B, Game Dev Tycoon gibi): her gün, kampanyada o fazda çalışan kişilerin başından o günün
## katkısı "+n" olarak çıkar ve üst şeritteki sayaca uçar; hata olunca kırmızı "!" hata sayacına uçar.
## Günün artışı çalışanlara yoğunluklarına göre bölünür (atamasız işte eşit). Çok hızlı akışta sayı sınırlı.

const MAX_ALIVE: int = 14
const RISE: float = 26.0
const RISE_SECONDS: float = 0.45
const FLY_SECONDS: float = 0.55
const STAT_ORDER: Array[String] = ["strategy", "creative", "technical"]

var _office: OfficeView
var _strip: CampaignStrip
var _camp_id: String = ""
var _last: Array[float] = [0.0, 0.0, 0.0]
var _last_errors: int = 0
var _last_day: int = -1


func _init(office: OfficeView, strip: CampaignStrip) -> void:
	_office = office
	_strip = strip
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Günlük yenilemede çağrılır (main._refresh).
func refresh(camp: Dictionary) -> void:
	if camp.is_empty():
		_camp_id = ""
		return
	var totals: Dictionary = GameState.sim.scoring.stat_totals(camp["points"])
	var now: Array[float] = [float(totals["strategy"]), float(totals["creative"]), float(totals["technical"])]
	var errors: int = int(camp["errors"])
	var day: int = int(camp["day"])
	if str(camp["id"]) != _camp_id:  # yeni kampanya: yalnızca başlangıç değerini al
		_camp_id = str(camp["id"])
		_last = now
		_last_errors = errors
		_last_day = day
		return
	if day == _last_day:
		return
	_last_day = day
	var workers: Dictionary = _workers(camp)
	var weight_sum: float = 0.0
	for w: Variant in workers.values():
		weight_sum += float(w)
	if not _strip.visible:  # şerit gizliyken (pencere açık) birikmesin: dönünce tek seferde patlamasın
		_last = now
	elif weight_sum > 0.0:
		for s: int in 3:
			var gain: float = now[s] - _last[s]
			if gain < 1.0:
				continue  # küçük artışlar birikir; tam puana ulaşınca uçar
			_last[s] = now[s]
			for id: String in workers:
				var part: int = int(roundf(gain * float(workers[id]) / weight_sum))
				if part > 0:
					_spawn(id, "+%d" % part, CampaignStrip.COUNTERS[s][1], s)
		if errors > _last_errors and not workers.is_empty():
			var ids: Array = workers.keys()
			_spawn(str(ids[day % ids.size()]), "!", CozyTheme.NEGATIVE, 3)
		elif errors < _last_errors and not workers.is_empty():  # S3C: rötuşta giderilen hata
			var fixers: Array = workers.keys()
			_spawn(str(fixers[day % fixers.size()]), "−%d" % (_last_errors - errors), CozyTheme.FOREST, 3)
	_last_errors = errors


## Bu fazda çalışanlar ve ağırlıkları: atamalı planda fazdaki yoğunluk, değilse ekipteki herkes eşit.
func _workers(camp: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var setup: Dictionary = camp["setup"]
	var phase: int = GameState.sim.production.current_phase(camp)
	var week: int = GameState.sim.state.clock.week_index
	for id: Variant in setup.get("team", []):
		var emp: Dictionary = GameState.sim.state.staff.get(str(id), {})
		if emp.is_empty() or not Employee.is_available(emp, week):
			continue
		var w: float = TaskPlan.phase_intensity(setup, phase, str(id)) if TaskPlan.has_plan(setup) else 1.0
		if w > 0.0:
			out[str(id)] = w
	return out


func _spawn(emp_id: String, text: String, color: Color, counter: int) -> void:
	if get_child_count() >= MAX_ALIVE or _strip.size.x < 10.0:  # şerit henüz yerleşmediyse hedef yanlış olur
		return
	var from: Vector2 = _office.head_screen_pos(emp_id)
	if from == Vector2.INF or not get_viewport_rect().has_point(from):
		_strip.pulse(counter)  # karakter ekranda değil: sayaç yine de kıpırdasın
		return
	var l: Label = UiUtil.label(text, 18, color)
	l.add_theme_font_override("font", CozyTheme.title_font(800))
	l.add_theme_color_override("font_outline_color", CozyTheme.CREAM_LIGHT)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	l.reset_size()
	l.global_position = from - l.size * 0.5
	var to: Vector2 = _strip.counter_pos(counter) - l.size * 0.5
	var tw: Tween = l.create_tween()
	tw.tween_property(l, "global_position:y", l.global_position.y - RISE, RISE_SECONDS).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "global_position", to, FLY_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(l, "scale", Vector2(0.6, 0.6), FLY_SECONDS)
	tw.tween_callback(func() -> void:
		_strip.pulse(counter)
		l.queue_free())
