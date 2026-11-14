class_name WorldQuality
extends RefCounted
## Grafik kalitesi (B1): Ayarlar → Ekran → "Grafik kalitesi" (low / medium / high). Her kademenin kenar yumuşatması,
## çizim ölçeği ve efektleri data/look.json "quality" altında; koda sayı yazılmaz.

const SETTING: String = "graphics"
const MSAA: Dictionary = {0: Viewport.MSAA_DISABLED, 2: Viewport.MSAA_2X, 4: Viewport.MSAA_4X, 8: Viewport.MSAA_8X}
const SCREEN_AA: Dictionary = {"none": Viewport.SCREEN_SPACE_AA_DISABLED, "fxaa": Viewport.SCREEN_SPACE_AA_FXAA,
	"smaa": Viewport.SCREEN_SPACE_AA_SMAA}

static var _mipmapped: Dictionary = {}


static func ids() -> Array:
	return (WorldLook.cfg()["quality"]["levels"] as Dictionary).keys()


## Seçili kademenin ayarları; ayar tanınmıyorsa look.json'daki varsayılan.
static func level() -> Dictionary:
	var q: Dictionary = WorldLook.cfg()["quality"]
	var levels: Dictionary = q["levels"]
	return levels.get(str(Settings.get_value(SETTING)), levels[str(q["default"])])


## 3D görüntünün çizildiği pencereye kenar yumuşatma ve çizim ölçeğini uygular.
static func apply_viewport(viewport: Viewport) -> void:
	var l: Dictionary = level()
	viewport.msaa_3d = MSAA.get(int(l["msaa"]), Viewport.MSAA_DISABLED)
	viewport.screen_space_aa = SCREEN_AA.get(str(l["screen_aa"]), Viewport.SCREEN_SPACE_AA_DISABLED)
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	viewport.scaling_3d_scale = float(l["scale"])
	viewport.use_debanding = bool(l["debanding"])


## Pahalı ortam efektleri: look.json'da açık olsa bile düşük kademede kapanır.
static func apply_environment(e: Environment) -> void:
	var c: Dictionary = WorldLook.cfg()["environment"]
	var l: Dictionary = level()
	e.ssao_enabled = bool(c["ssao"]["enabled"]) and bool(l["ssao"])
	e.ssil_enabled = bool(c["ssil"]["enabled"]) and bool(l["ssil"])
	e.glow_enabled = bool(c["glow"]["enabled"]) and bool(l["glow"])


static func dof() -> bool:
	return bool(level()["dof"])


## Dokunun uzak mesafe kopyaları (mipmap) yoksa üretir: uzaktan bakınca kumlanma / titreşme olmasın.
## (.import dosyaları depoda tutulmadığı için içe aktarma ayarına güvenmiyoruz.)
static func mipmapped(path: String) -> Texture2D:
	if _mipmapped.has(path):
		return _mipmapped[path]
	var tex: Texture2D = load(path) as Texture2D
	var img: Image = tex.get_image() if tex != null else null
	if img != null and not img.has_mipmaps():
		if img.is_compressed():
			img.decompress()
		if img.generate_mipmaps() == OK:
			tex = ImageTexture.create_from_image(img)
	_mipmapped[path] = tex
	return tex
