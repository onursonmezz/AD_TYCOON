class_name ConfirmDialog
extends Control
## Basit soru penceresi (M9): başlık, metin ve düğmeler [[metin anahtarı, Callable], …]. Her düğme pencereyi kapatır.
## Esc "vazgeç" sayılır. UI-3 dili: düğmeler ayrı alt satırda, ilki birincil (yeşil).

var _title_key: String
var _text_key: String
var _choices: Array


func _init(title_key: String, text_key: String, choices: Array) -> void:
	_title_key = title_key
	_text_key = text_key
	_choices = choices
	set_meta("esc_closes", true)


func _ready() -> void:
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("confirm"))
	col.add_child(UiUtil.heading(tr(_title_key), "alert-triangle"))
	col.add_child(UiUtil.wrapped(tr(_text_key), 15, CozyTheme.TEXT))
	var frame: VBoxContainer = UiUtil.modal_outer(col)
	frame.add_child(HSeparator.new())
	var foot: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	foot.add_child(UiUtil.spacer())
	for i: int in _choices.size():
		var c: Array = _choices[i]
		var cb: Callable = c[1]
		var b: Button = UiUtil.button(tr(str(c[0])), func() -> void:
			queue_free()
			if cb.is_valid():
				cb.call())
		if i == 0:
			b.theme_type_variation = "PrimaryButton"
		foot.add_child(b)
	frame.add_child(foot)
