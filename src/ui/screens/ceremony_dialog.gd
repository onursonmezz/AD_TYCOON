class_name CeremonyDialog
extends Control
## Ödül töreni (GDD 15 "duygusal bir an"): sonuçlar teker teker açılır, Grand Prix en sonda.

const REVEAL_SECONDS: float = 0.8

var _result: Dictionary
var _lines: VBoxContainer


func _init(result: Dictionary) -> void:
	_result = result


func _ready() -> void:
	var data: GameData = DataDB.data
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(620.0, 420.0))
	col.add_child(UiUtil.heading(tr("UI_CEREMONY_TITLE") % [UiUtil.name_of(data.awards, _result["award"]), int(_result["year"])],
		"trophy"))
	_lines = UiUtil.vbox(6)
	col.add_child(_lines)
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_CLOSE"), queue_free))
	col.add_child(buttons)
	var rows: Array[Array] = []
	for r: Dictionary in _result["player"]:
		var level: String = str(r["level"])
		var title: String = str(r.get("name", "")) if not str(r.get("name", "")).is_empty() else tr("UI_UNTITLED")
		var text: String = tr("UI_CEREMONY_ROW") % [title, r.get("client_name", ""),
			tr("LEVEL_" + level.to_upper()) if not level.is_empty() else tr("LEVEL_NONE")]
		rows.append([text, UiUtil.MUSTARD if not level.is_empty() else UiUtil.MUTED])
	rows.append([tr("UI_CEREMONY_RIVALS") % (_result["rivals"] as Array).size(), UiUtil.WOOD])
	var gp: Dictionary = _result["grand_prix"]
	if gp["who"] == "player":
		rows.append([tr("UI_CEREMONY_GP_US"), UiUtil.SAGE_DARK])
	elif not str(gp["who"]).is_empty():
		rows.append([tr("UI_CEREMONY_GP_RIVAL") % UiUtil.name_of(data.rivals, gp["who"]), UiUtil.TERRACOTTA])
	else:
		rows.append([tr("UI_CEREMONY_GP_NONE"), UiUtil.MUTED])
	_reveal(rows)


func _reveal(rows: Array[Array]) -> void:
	for row: Array in rows:
		await get_tree().create_timer(REVEAL_SECONDS).timeout
		if not is_inside_tree():
			return
		_lines.add_child(UiUtil.wrapped(str(row[0]), 17, row[1], 560.0))
