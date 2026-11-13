class_name IconPack
extends RefCounted
## Orgo'nun ikon paketi (assets/ui/icons/*.png, UI-3). Tek renkli ikonlar beyaza çevrilip tema rengiyle boyanır
## (dokta kiremit, açıkken yeşil); çok renkli olanlar (logo, para, yıldız) olduğu gibi çizilir.
## Pakette karşılığı olmayan adlar için null döner; çağıran eski SVG setine düşer.

const DIR: String = "res://assets/ui/icons"
## Koddaki ikon adı → paketteki dosya adı.
const NAMES: Dictionary = {
	"inbox": "gelen-kutusu", "users-group": "ekip", "speakerphone": "kampanya", "building": "ofis", "tool": "araclar",
	"flask": "ar-ge", "coins": "finans", "trophy": "oduller", "chart-bar": "raporlar", "settings": "ayarlar",
	"device-floppy": "kaydet", "calendar": "takvim", "clock": "tempo", "player-pause": "duraklat", "player-play": "oynat",
	"bell": "bildirim", "x": "kapat", "world": "dil", "device-desktop": "ekran", "device-gamepad-2": "oyun",
	"volume": "ses", "receipt": "belge", "user": "insan", "users": "insan", "check": "onay", "alert-triangle": "uyari",
	"trash": "sil-sat", "rotate-left": "geri-al", "rotate-right": "ileri-al", "chevron-right": "saga-ok",
	"building-bank": "banka", "folder-open": "klasor", "plant": "yaprak", "arrow-up": "yukari-gelir",
	"arrow-down": "asagi-gider", "search": "arama", "lock": "kilit", "info": "bilgi", "move": "tasi", "refresh": "dondur",
	"laurel": "itibar", "stat-strategy": "strateji", "stat-creative": "kreatif", "stat-technical": "teknik",
	"focus-research": "pazar-arastirmasi", "focus-insight": "icgoru", "focus-positioning": "konumlandirma",
}

const ALPHA_FLOOR: float = 0.2
const EDGE_SKIP: float = 0.06  # dosya kenarındaki komşu ikon kırıntıları sayılmaz

static var _cache: Dictionary = {}


## Tek renkli ikon, beyaz ve px boyunda (tema rengiyle çarpılarak boyanır). Pakette yoksa null.
static func texture(name: String, px: int) -> Texture2D:
	if not NAMES.has(name):
		return null
	return _load(str(NAMES[name]), px, true)


## Çok renkli çizim (ajans-logo, para, yildiz), px boyunda, renkleri korunur. Dosya yoksa null.
static func art(file_name: String, px: int) -> Texture2D:
	return _load(file_name, px, false)


static func _load(file_name: String, px: int, whiten: bool) -> Texture2D:
	var key: String = "%s@%d%s" % [file_name, px, "w" if whiten else ""]
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = null
	var path: String = "%s/%s.png" % [DIR, file_name]
	if ResourceLoader.exists(path):
		var img: Image = (load(path) as Texture2D).get_image()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		# Dosyadaki boş kenarı at, kareye tamamla: ikon her boyda kutusunu doldursun.
		var used: Rect2i = _solid_rect(img)
		if used.size.x > 0 and used.size.y > 0:
			var side: int = maxi(used.size.x, used.size.y)
			var square: Image = Image.create(side, side, false, Image.FORMAT_RGBA8)
			square.blit_rect(img, used, Vector2i((side - used.size.x) / 2, (side - used.size.y) / 2))
			img = square
		img.resize(px, px, Image.INTERPOLATE_LANCZOS)
		if whiten:
			for y: int in px:
				for x: int in px:
					img.set_pixel(x, y, Color(1.0, 1.0, 1.0, img.get_pixel(x, y).a))
		tex = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Belirgin (yarı saydamdan koyu) piksellerin kapladığı dikdörtgen; çok soluk kenar tozu sayılmaz.
static func _solid_rect(img: Image) -> Rect2i:
	var lo: Vector2i = img.get_size()
	var hi: Vector2i = Vector2i(-1, -1)
	var skip: int = int(img.get_width() * EDGE_SKIP)
	for y: int in range(skip, img.get_height() - skip):
		for x: int in range(skip, img.get_width() - skip):
			if img.get_pixel(x, y).a > ALPHA_FLOOR:
				lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
				hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
	return Rect2i(lo, hi - lo + Vector2i.ONE) if hi.x >= 0 else Rect2i()
