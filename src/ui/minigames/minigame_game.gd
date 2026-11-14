class_name MinigameGame
extends Control
## Mini oyunların ortak tabanı (K-120). Oyun bittiğinde finished(başarı 0..1) yayar; süre dolunca host time_up() çağırır.
## ctx: { camp, setup, brand, accent, year, seed }.

signal finished(quality: float)

const CANVAS: Vector2 = Vector2(620, 320)

var ctx: Dictionary = {}
var _done: bool = false


func _init() -> void:
	custom_minimum_size = CANVAS
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


## Oyunu kurar (ctx atandıktan sonra, ağaca eklenince host çağırır).
func begin() -> void:
	pass


## Süre doldu: o anki duruma göre kısmi başarı.
func time_up() -> void:
	finish(0.0)


func finish(quality: float) -> void:
	if _done:
		return
	_done = true
	finished.emit(clampf(quality, 0.0, 1.0))


## Taslak dizgicisiyle küçük bir ilan (billboard, gazete): kampanyanın ilk taslak seçeneği.
func ad_preview(size_px: Vector2) -> Control:
	var box: Control = Control.new()
	box.size = size_px
	box.custom_minimum_size = size_px
	box.clip_contents = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var draft: Dictionary = (ctx["setup"] as Dictionary).get("draft", {})
	if draft.is_empty():
		draft = DraftArt.options(DataDB.data, ctx["setup"], int(ctx["year"]), int(ctx["seed"]))[0]
	DraftArt.compose(box, draft, size_px, str(ctx["brand"]), ctx["accent"])
	return box
