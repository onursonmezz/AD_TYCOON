class_name FocusHint
extends RefCounted
## Odak alanı önemi ipuçları (K-098): öğrenilmişse +++ … −−− işareti, öğrenilmemişse "?".
## Faz ekranı, rapor ve Bilgi Defteri aynı işaretleri ve cümleleri kullanır.

const SYMBOLS: Dictionary = {3: "+++", 2: "++", 1: "+", 0: "~", -1: "−", -2: "−−", -3: "−−−"}


static func known(objective: String, focus_id: String) -> bool:
	return GameState.sim.research.focus_known(GameState.sim.state, objective, focus_id)


static func value(objective: String, focus_id: String) -> int:
	return DataDB.data.focus_importance(objective, focus_id)


static func color_of(v: int) -> Color:
	return UiUtil.SAGE_DARK if v >= 2 else (UiUtil.TEXT if v >= 0 else UiUtil.TERRACOTTA)


## Kaydırıcının yanındaki küçük işaret; üstüne gelince açıklama.
static func badge(objective: String, focus_id: String, size: int = 16) -> Label:
	var is_known: bool = known(objective, focus_id)
	var v: int = value(objective, focus_id)
	var l: Label = UiUtil.label(SYMBOLS[v] if is_known else "?", size, color_of(v) if is_known else UiUtil.MUTED)
	l.custom_minimum_size.x = 44.0
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	l.tooltip_text = sentence(objective, focus_id) if is_known else TranslationServer.translate("UI_FOCUS_UNKNOWN")
	return l


## Rapordaki öğrenme cümlesi: "Satış kampanyasında Metin Yazarlığı çok önemli (+++)."
static func sentence(objective: String, focus_id: String) -> String:
	var v: int = value(objective, focus_id)
	var key: String = "UI_FOCUS_LEARN_%s" % ("HIGH" if v >= 2 else ("MID" if v >= 0 else "LOW"))
	return TranslationServer.translate(key) % [UiUtil.name_of(DataDB.data.objectives, objective),
		UiUtil.name_of(DataDB.data.focus_areas, focus_id), SYMBOLS[v]]
