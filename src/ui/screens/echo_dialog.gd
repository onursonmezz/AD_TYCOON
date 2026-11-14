class_name EchoDialog
extends Control
## "Kampanyanın yankıları" (GDD 7.12; UI-3 taslağı 01): kampanya bitince önce dört yayının puanı ve yorumu,
## altında genel değerlendirme görünür. "Raporu incele" ayrıntılı raporu (ReportDialog) açar.

const CHROME: float = 62.0  # kaydırmanın dışındaki alt satır

var _camp: Dictionary
var _on_report: Callable


func _init(camp: Dictionary, on_report: Callable) -> void:
	_camp = camp
	_on_report = on_report


func _ready() -> void:
	var data: GameData = DataDB.data
	var setup: Dictionary = _camp["setup"]
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("echo") - Vector2(0.0, CHROME), true, true)
	col.add_child(UiUtil.heading(tr("UI_ECHO_TITLE"), "receipt"))
	var title: String = str(setup.get("name", "")) if not str(setup.get("name", "")).is_empty() else tr("UI_UNTITLED")
	col.add_child(Cards.header(Cards.art("brand_art", str(setup.get("client_name", "")), 44.0, "speakerphone"),
		str(setup.get("client_name", "")), "%s · %s" % [title, UiUtil.name_of(data.channels, Scoring.main_channel(setup["mix"]))]))
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for r: Dictionary in _camp.get("reviews", []):
		row.add_child(_review_card(r))
	col.add_child(row)
	# Alt satır kaydırmanın dışında: genel puan ve düğmeler hep görünür.
	var frame: VBoxContainer = col.get_parent().get_parent() as VBoxContainer
	frame.add_child(HSeparator.new())
	var foot: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var close: Button = UiUtil.button(tr("UI_CLOSE"), queue_free)
	close.custom_minimum_size.x = 100.0
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(close)
	var total: VBoxContainer = UiUtil.vbox(-4)
	total.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var caption: Label = UiUtil.label(tr("UI_ECHO_OVERALL"), 13, CozyTheme.TEXT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total.add_child(caption)
	var score: Label = UiUtil.label("%.1f / 10" % float(_camp["report"]["score"]), 26, CozyTheme.TERRA)
	score.add_theme_font_override("font", CozyTheme.title_font(700))
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total.add_child(score)
	foot.add_child(total)
	var report: Button = UiUtil.button(tr("UI_ECHO_REPORT"), func() -> void:
		queue_free()
		_on_report.call())
	report.theme_type_variation = "PrimaryButton"
	report.icon = UiUtil.icon_texture("chevron-right", 14)
	report.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	report.custom_minimum_size.x = 170.0
	report.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(report)
	frame.add_child(foot)


## Bir yayının kartı: amblem ve ad, büyük puan, altında tırnak içinde yorum.
func _review_card(r: Dictionary) -> PanelContainer:
	var card: PanelContainer = UiUtil.card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v: VBoxContainer = UiUtil.vbox(4)
	card.add_child(v)
	var head: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(Cards.art("reviewer_art", str(r["reviewer_key"]), 30.0, "user", Color.TRANSPARENT))
	var who: Label = UiUtil.wrapped(tr(r["reviewer_key"]), 13, CozyTheme.TEXT, 70.0)
	who.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	head.add_child(who)
	v.add_child(head)
	v.add_child(HSeparator.new())
	var score: Label = UiUtil.label("%.1f" % float(r["score"]), 34, CozyTheme.TERRA)
	score.add_theme_font_override("font", CozyTheme.title_font(700))
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(score)
	var of: Label = UiUtil.label("/ 10", 12, CozyTheme.MUTED)
	of.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(of)
	var quote: Label = UiUtil.wrapped("“%s”" % tr(r["text_key"]), 14, CozyTheme.TEXT, 110.0)
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.add_theme_font_override("font", MenuArt.italic(CozyTheme.body_font()))
	v.add_child(quote)
	return card
