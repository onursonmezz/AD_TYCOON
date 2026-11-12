class_name BuildGhost
extends Node3D
## İnşa modu önizlemesi: yerleşim kutusu (yeşil uygun, kırmızı değil) ve içinde eşyanın kendisi, yarı saydam ve
## renk katmanlı. Renk ve saydamlıklar data/look.json "build_ghost".

var _box: MeshInstance3D
var _box_mat: StandardMaterial3D
var _tint: StandardMaterial3D
var _model: Node3D
var _model_key: String = ""


func _init() -> void:
	_box = MeshInstance3D.new()
	_box.mesh = BoxMesh.new()
	_box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_box_mat = _unshaded()
	_box.material_override = _box_mat
	add_child(_box)
	_tint = _unshaded()


static func _unshaded() -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


static func _cfg() -> Dictionary:
	return WorldLook.cfg().get("build_ghost", {})


## rect: zemindeki kutu; item (isteğe bağlı): { model, size (dönmemiş taban), yaw (derece), base_y }.
## mode: "ok" | "bad" | "remove".
func show_at(rect: Rect2, height: float, mode: String, item: Dictionary = {}) -> void:
	var cfg: Dictionary = _cfg()
	visible = true
	var base_y: float = float(item.get("base_y", 0.0))
	_set_model(item)
	var color: Array = cfg.get(mode, [0.5, 0.5, 0.5])
	var alpha_key: String = "box_alpha" if _model != null else "box_alpha_no_model"
	_box_mat.albedo_color = WorldLook.col(color, float(cfg.get(alpha_key, 0.45)))
	(_box.mesh as BoxMesh).size = Vector3(rect.size.x, height, rect.size.y)
	_box.position = Vector3(rect.get_center().x, base_y + height * 0.5, rect.get_center().y)
	if _model != null:
		_tint.albedo_color = WorldLook.col(color, float(cfg.get("tint_alpha", 0.3)))
		_model.position = Vector3(rect.get_center().x, base_y, rect.get_center().y)


func hide_all() -> void:
	visible = false


func has_model() -> bool:
	return _model != null


## Aynı eşya ve yön için model yeniden yüklenmez; değişince eskisi silinir.
func _set_model(item: Dictionary) -> void:
	var rel: String = str(item.get("model", ""))
	var key: String = "%s|%s|%s" % [rel, item.get("yaw", 0.0), item.get("size", Vector2.ZERO)]
	if key == _model_key:
		return
	_model_key = key
	if _model != null:
		_model.queue_free()
		_model = null
	if rel.is_empty():
		return
	var size: Vector2 = item.get("size", Vector2.ONE)
	_model = ModelLibrary.instance(rel, size, float(item.get("height", 1.0)), float(item.get("yaw", 0.0)))
	if _model == null:
		return
	var see_through: float = float(_cfg().get("model_transparency", 0.3))
	for node: Node in _model.find_children("*", "GeometryInstance3D", true, false):
		var g: GeometryInstance3D = node as GeometryInstance3D
		g.transparency = see_through
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.material_overlay = _tint
	add_child(_model)
