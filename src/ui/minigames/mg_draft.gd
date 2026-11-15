class_name MgDraft
extends MinigameGame
## Ekibin 3 taslağı (K-120): kreatif faz bitince ekip üç ilan taslağı sunar; birini seç. Seçilen taslak ofis
## duvarındaki posterde, sokaktaki billboard'da ve törende görünür. Puana etkisi yok, süre sınırı yok.

const CARD: Vector2 = Vector2(192, 222)  # üç kart oyun alanını doldurur (eskiden üstte küçük kalıyordu)

signal chosen(draft: Dictionary)

var _drafts: Array[Dictionary] = []


func begin() -> void:
	_drafts = DraftArt.options(DataDB.data, ctx["setup"], int(ctx["year"]), int(ctx["seed"]))
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	var row_w: float = 3.0 * (CARD.x + 8.0) + 2.0 * CozyTheme.SPACE_S
	row.position = Vector2(maxf(0.0, (CANVAS.x - row_w) * 0.5), 40)
	add_child(row)
	for i: int in _drafts.size():
		var b: Button = Button.new()
		b.custom_minimum_size = CARD + Vector2(8, 8)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = tr("MG_DRAFT_PICK")
		var art: Control = Control.new()
		art.position = Vector2(4, 4)
		art.size = CARD
		art.clip_contents = true
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		DraftArt.compose(art, _drafts[i], CARD, str(ctx["brand"]), ctx["accent"])
		b.add_child(art)
		b.pressed.connect(func() -> void: _pick(i))
		row.add_child(b)
	var label: Label = UiUtil.label(tr("MG_DRAFT_TEAM"), 13, UiUtil.MUTED)
	label.position = Vector2(8, 8)
	add_child(label)


func _pick(i: int) -> void:
	if _done:
		return
	chosen.emit(_drafts[i])
	finish(1.0)


## Atla: ekibin ilk taslağı kullanılır.
func time_up() -> void:
	_pick(0)
