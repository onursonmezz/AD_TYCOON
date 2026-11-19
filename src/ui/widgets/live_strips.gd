class_name LiveStrips
extends RefCounted
## Üretimdeki her kampanya için saat kutusunun altında bir şerit ve kendi puan baloncukları (S3B, S3D).
## En çok MAX şerit alt alta; pencere açıkken gizli.

const MAX: int = 3
const GAP: float = 4.0

var _main: Control
var _office: OfficeView
var _on_open: Callable
var _strips: Array[CampaignStrip] = []
var _bubbles: Array[PointBubbles] = []


func _init(main: Control, office: OfficeView, on_open: Callable) -> void:
	_main = main
	_office = office
	_on_open = on_open


func _ensure(n: int) -> void:
	var h: float = float(DataDB.data.raw["ui_layout.json"]["campaign_strip"]["height"])
	while _strips.size() < n:
		var i: int = _strips.size()
		var strip: CampaignStrip = CampaignStrip.new(_on_open)
		_main.add_child(strip)
		strip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		strip.grow_horizontal = Control.GROW_DIRECTION_BOTH
		strip.offset_top = MainHud.TOP + MainHud.BOX_HEIGHT + 6.0 + i * (h + GAP)
		strip.visible = false
		var layer: PointBubbles = PointBubbles.new(_office, strip)
		_main.add_child(layer)
		# S11: şerit ve baloncuklar sonradan eklendiği için pencerelerin üstüne çıkıyordu; pencere katmanının altına alınır.
		var modal: Variant = _main.get("_modal_layer")
		if modal is Node and is_instance_valid(modal):
			_main.move_child(layer, (modal as Node).get_index())
			_main.move_child(strip, (modal as Node).get_index())
		_strips.append(strip)
		_bubbles.append(layer)


## Günlük yenileme. show: pencere kapalı mı (açıkken şeritler gizli, baloncuk birikmez).
func refresh(s: SimState, show: bool) -> void:
	var n: int = mini(MAX, s.campaigns.size())
	_ensure(n)
	for i: int in _strips.size():
		var camp: Dictionary = s.campaigns[i] if i < n else {}
		_strips[i].refresh(camp)
		_strips[i].visible = _strips[i].visible and show
		_bubbles[i].refresh(camp)


func hide_all() -> void:
	for strip: CampaignStrip in _strips:
		strip.visible = false
