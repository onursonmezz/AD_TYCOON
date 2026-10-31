class_name SimClock
extends RefCounted
## Oyun zamanı (GDD 5.1): 1 hafta = 7 gün, 1 ay = 4 hafta, 1 yıl = 12 ay = 48 hafta.
## Saf hesap; gerçek zamanlı hız (1x/2x/4x) M2'deki Clock autoload'unda olacak.

var start_year: int = 1990
var weeks_per_month: int = 4
var months_per_year: int = 12
var days_per_week: int = 7

## Oyun başından beri geçen hafta / gün (0'dan başlar).
var week_index: int = 0
var day_in_week: int = 0


func _init(data: GameData) -> void:
	start_year = data.bali("time.start_year")
	weeks_per_month = data.bali("time.weeks_per_month")
	months_per_year = data.bali("calendar.months_per_year")
	days_per_week = data.bali("calendar.days_per_week")


func weeks_per_year() -> int:
	return weeks_per_month * months_per_year


func year() -> int:
	return start_year + week_index / weeks_per_year()


## 1..12
func month() -> int:
	return (week_index % weeks_per_year()) / weeks_per_month + 1


## 1..4
func week_in_month() -> int:
	return week_index % weeks_per_month + 1


## Oyuncunun gördüğü yıl numarası (Y1 = başlangıç yılı).
func game_year() -> int:
	return year() - start_year + 1


## Bir gün ilerletir. Dönüş: bu günün sonunda biten periyotlar.
func advance_day() -> Dictionary:
	var ended: Dictionary = {"week": false, "month": false, "year": false}
	day_in_week += 1
	if day_in_week < days_per_week:
		return ended
	day_in_week = 0
	week_index += 1
	ended["week"] = true
	if week_index % weeks_per_month == 0:
		ended["month"] = true
	if week_index % weeks_per_year() == 0:
		ended["year"] = true
	return ended


func to_dict() -> Dictionary:
	return {"week_index": week_index, "day_in_week": day_in_week}


func load_dict(d: Dictionary) -> void:
	week_index = int(d.get("week_index", 0))
	day_in_week = int(d.get("day_in_week", 0))
