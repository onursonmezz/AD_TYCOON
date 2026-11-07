class_name ConfirmDialog
extends Control
## Basit soru penceresi (M9): başlık, metin ve düğmeler [[metin anahtarı, Callable], …]. Her düğme pencereyi kapatır.
## Esc "vazgeç" sayılır.

var _title_key: String
var _text_key: String
var _choices: Array


func _init(title_key: String, text_key: String, choices: Array) -> void:
	_title_key = title_key
	_text_key = text_key
	_choices = choices
	set_meta("esc_closes", true)


func _ready() -> void:
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(520.0, 200.0))
	col.add_child(UiUtil.heading(tr(_title_key), "alert-triangle"))
	col.add_child(UiUtil.wrapped(tr(_text_key), 16, UiUtil.TEXT, 460.0))
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	for c: Array in _choices:
		var cb: Callable = c[1]
		buttons.add_child(UiUtil.button(tr(str(c[0])), func() -> void:
			queue_free()
			if cb.is_valid():
				cb.call()))
	col.add_child(buttons)
