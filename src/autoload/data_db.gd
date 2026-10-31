extends Node
## Açılışta tüm JSON'ları yükler ve doğrular (GDD 24.3). Hata varsa ana menü bunu gösterir.

var data: GameData


func _ready() -> void:
	data = GameData.load_from()
	for message: String in data.errors:
		push_error("Veri hatası: " + message)


func is_ok() -> bool:
	return data != null and data.errors.is_empty()
