extends Control
## M0 açılış ekranı: projenin hatasız açıldığını ve yerelleştirmenin çalıştığını gösterir.

@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _milestone: Label = %Milestone


func _ready() -> void:
	_title.text = tr("GAME_TITLE")
	_subtitle.text = tr("BOOT_SUBTITLE")
	_milestone.text = tr("BOOT_MILESTONE")
