class_name OfficeDressing
extends RefCounted
## Ofisin "giydirilmesi" (M8): mobilya ve sabit eşyalar (masa, sandalye, dönemsel bilgisayar), ofisin önündeki sokak,
## billboard ve duvar posterlerindeki kampanya görselleri. Model varsa .glb (ModelLibrary), yoksa gri kutu.
## OfficeWorld 400 satırı aşmasın diye ayrı; yalnızca okur.

const OUTWARD: Dictionary = {"n": Vector2(0, -1), "s": Vector2(0, 1), "w": Vector2(-1, 0), "e": Vector2(1, 0)}
## Billboard binanın köşesinden bu kadar ötede durur (m).
const BILLBOARD_GAP: float = 2.8

var _visual_root: Node3D
var _visual_sig: String = ""
var _walls: Array[Dictionary] = []
var _billboard_anchor: Transform3D = Transform3D.IDENTITY
var _layout: OfficeLayout


func _m() -> Dictionary:
	return DataDB.data.models


static func color_of(a: Array) -> Color:
	return Color(float(a[0]), float(a[1]), float(a[2]))


static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var m: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	m.material_override = mat
	m.position = pos
	parent.add_child(m)
	return m


## Bir eşya: model varsa sığdırılmış model, yoksa taban × boy kutusu. base_y: eşyanın oturduğu yükseklik.
## Dönüş: eklenen düğüm ve modelden mi geldiği.
static func thing(parent: Node3D, rel: String, center: Vector2, footprint: Vector2, height: float, color: Color,
		yaw_deg: float = 0.0, base_y: float = 0.0) -> Dictionary:
	var model: Node3D = ModelLibrary.instance(rel, footprint, height, yaw_deg)
	if model != null:
		model.position = Vector3(center.x, base_y, center.y)
		parent.add_child(model)
		return {"node": model, "model": true}
	var rotated: Vector2 = footprint if absi(roundi(yaw_deg / 90.0)) % 2 == 0 else Vector2(footprint.y, footprint.x)
	var b: MeshInstance3D = box(parent, Vector3(center.x, base_y + height * 0.5, center.y),
		Vector3(rotated.x * 0.9, height, rotated.y * 0.9), color)
	return {"node": b, "model": false}


# --- kurulum ---------------------------------------------------------------------

## walls: OfficeWorld'ün duvar kayıtları; posterler bunlara "poster" anahtarıyla bağlanır (kesik duvarda gizlenir).
func build(parent: Node3D, layout: OfficeLayout, state: SimState, walls: Array[Dictionary]) -> void:
	_layout = layout
	_walls = walls
	_props(parent, layout, state)
	_street(parent, layout)
	_visual_root = Node3D.new()
	_visual_root.name = "KeyVisuals"
	parent.add_child(_visual_root)
	_visual_sig = ""
	refresh_visuals(state)


func _props(parent: Node3D, layout: OfficeLayout, state: SimState) -> void:
	var data: GameData = DataDB.data
	var props: Dictionary = _m()["props"]
	var dry: bool = GameState.sim.build.plants_dry(state)
	var equip: Dictionary = _m()["equipment"].get(state.hardware, {})
	for prop: Dictionary in layout.props:
		var pr: Rect2 = prop["rect"]
		if prop["kind"] == "furniture":
			var def: Dictionary = data.furniture[prop["id"]]
			var withered: bool = dry and def["decor"] == "plant"
			var col: Color = color_of(_m()["dry_plant_color"]) if withered else color_of(def["color"])
			var t: Dictionary = thing(parent, str(def.get("model", "")), pr.get_center(),
				Vector2(float(def["size"][0]), float(def["size"][1])), float(def["height"]), col, -90.0 * int(prop.get("rot", 0)))
			if withered and bool(t["model"]):
				ModelLibrary.tint(t["node"], Color(col, 0.55))
			continue
		var def2: Dictionary = props[prop["kind"]]
		var h: float = float(def2["height"])
		thing(parent, str(def2["model"]), pr.get_center(), pr.size, h, color_of(def2["color"]), float(def2.get("yaw", 0.0)))
		if prop["kind"] == "desk":
			var chair: Dictionary = props["chair"]
			thing(parent, str(chair["model"]), pr.get_center() + Vector2(0, OfficeLayout.SEAT_OFFSET - 0.1),
				_v2(chair["size"]), float(chair["height"]), color_of(chair["color"]), float(chair.get("yaw", 0.0)))
			if not equip.is_empty():
				thing(parent, str(equip["model"]), pr.get_center() + Vector2(0, -0.1), _v2(equip["size"]),
					float(equip["height"]), color_of(equip["color"]), 0.0, h)


static func _v2(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


## Girişin önünde kaldırım ve yol; kaldırımda ağaçlar, lambalar, bank; köşede billboard (GDD 21.1, 21.4).
func _street(parent: Node3D, layout: OfficeLayout) -> void:
	var cfg: Dictionary = _m()["street_layout"]
	var street: Dictionary = _m()["street"]
	var side: String = _entrance_side(layout)
	var n: Vector2 = OUTWARD[side]
	var t: Vector2 = Vector2(-n.y, n.x).abs()
	var edge_len: float = layout.size.x if t.x > 0.5 else layout.size.y
	var mid: Vector2 = layout.size * 0.5 + n * (layout.size * 0.5).dot(n.abs())
	var sw: float = float(cfg["sidewalk_width"])
	var road: float = float(cfg["road_width"])
	var length: float = edge_len + 12.0
	var yaw: float = rad_to_deg(atan2(n.x, n.y))
	_strip(parent, mid + n * (sw * 0.5), t, length, sw, 0.03, color_of(cfg["sidewalk_color"]))
	_strip(parent, mid + n * (sw + road * 0.5), t, length, road, 0.01, color_of(cfg["road_color"]))
	var step: float = float(cfg["tree_step"])
	var k: int = 0
	var x: float = -length * 0.5 + step * 0.5
	while x < length * 0.5:
		if absf(x) > 3.5 and absf(x - (edge_len * 0.5 + BILLBOARD_GAP)) > 2.5:
			var p: Vector2 = mid + t * x + n * (sw - 0.6)
			var key: String = "lamp" if k % int(cfg["lamp_every"]) == 1 else "tree"
			var d: Dictionary = street[key]
			thing(parent, str(d["model"]), p, _v2(d["size"]), float(d["height"]), color_of(d["color"]), yaw)
			k += 1
		x += step
	var bench: Dictionary = street["bench"]
	thing(parent, str(bench["model"]), mid - t * 2.5 + n * (sw * 0.5), _v2(bench["size"]), float(bench["height"]),
		color_of(bench["color"]), yaw)
	# Billboard: binanın köşesinin ötesinde, kaldırımda, yola bakar.
	var bb: Dictionary = street["billboard"]
	var bb_pos: Vector2 = mid + t * (edge_len * 0.5 + BILLBOARD_GAP) + n * (sw * 0.5)
	var panel: Array = cfg["billboard_panel"]
	var bottom: float = float(cfg["billboard_panel_bottom"])
	var t_bb: Dictionary = thing(parent, str(bb["model"]), bb_pos, _v2(bb["size"]), float(bb["height"]), color_of(bb["color"]), yaw)
	if not bool(t_bb["model"]):
		# Yedek: kutu yerine iki direk ve çerçeve (panel önde görünsün).
		(t_bb["node"] as Node).queue_free()
		var frame: Node3D = Node3D.new()
		frame.position = Vector3(bb_pos.x, 0.0, bb_pos.y)
		frame.rotation.y = deg_to_rad(yaw)
		parent.add_child(frame)
		var c: Color = color_of(bb["color"])
		for sx: float in [-1.0, 1.0]:
			box(frame, Vector3(sx * float(panel[0]) * 0.35, bottom * 0.5, -0.05), Vector3(0.15, bottom, 0.15), c)
		box(frame, Vector3(0.0, bottom + float(panel[1]) * 0.5, -0.08), Vector3(float(panel[0]) + 0.2, float(panel[1]) + 0.2, 0.12), c)
	_billboard_anchor = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)),
		Vector3(bb_pos.x, bottom + float(panel[1]) * 0.5, bb_pos.y) + Vector3(n.x, 0.0, n.y) * 0.05)


func _strip(parent: Node3D, center: Vector2, along: Vector2, length: float, width: float, y: float, color: Color) -> void:
	var size: Vector3 = Vector3(length, 0.04, width) if along.x > 0.5 else Vector3(width, 0.04, length)
	box(parent, Vector3(center.x, y - 0.02, center.y), size, color)


static func _entrance_side(layout: OfficeLayout) -> String:
	var e: Vector2 = layout.entrance
	var d: Dictionary = {"n": e.y, "s": layout.size.y - e.y, "w": e.x, "e": layout.size.x - e.x}
	var best: String = "s"
	for k: String in d:
		if float(d[k]) < float(d[best]):
			best = k
	return best


# --- kampanya görselleri ----------------------------------------------------------

## Biten/yayındaki kampanyalar ya da ödüller değiştiyse billboard ve posterleri yeniden çizer.
func refresh_visuals(state: SimState) -> void:
	if _visual_root == null or not is_instance_valid(_visual_root):
		return
	var bb_camp: Dictionary = KeyVisual.billboard_campaign(state)
	var sig: String = "%s|%d|%d|%s" % [str(bb_camp.get("id", "")), state.finished.size(), state.award_history.size(),
		TranslationServer.get_locale()]
	if sig == _visual_sig:
		return
	_visual_sig = sig
	for child: Node in _visual_root.get_children():
		child.queue_free()
	for w: Dictionary in _walls:
		w.erase("poster")
	var kv: Dictionary = _m()["key_visual"]
	var awarded: Dictionary = KeyVisual.awarded_campaigns(state)
	var cfg: Dictionary = _m()["street_layout"]
	var panel: Vector2 = _v2(cfg["billboard_panel"])
	var bb: MeshInstance3D = _panel(KeyVisual.spec(DataDB.data, bb_camp, awarded), Vector2i(_v2(kv["pixels"])), panel)
	bb.transform = _billboard_anchor
	_poster_walls(state, awarded, kv)
	_visual_root.add_child(bb)


func _poster_walls(state: SimState, awarded: Dictionary, kv: Dictionary) -> void:
	var cfg: Dictionary = _m()["posters"]
	var candidates: Array[Dictionary] = []
	for w: Dictionary in _walls:
		if bool(w["outer"]) and float(w["length"]) >= float(cfg["min_wall_length"]):
			candidates.append(w)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["length"]) > float(b["length"]))
	var camps: Array[Dictionary] = KeyVisual.poster_campaigns(state, mini(int(cfg["max"]), candidates.size()))
	var size: Vector2 = _v2(cfg["size"])
	for i: int in camps.size():
		var w: Dictionary = candidates[i]
		var inward: Vector2 = -(OUTWARD[w["side"]] as Vector2)
		var spec: Dictionary = KeyVisual.spec(DataDB.data, camps[i], awarded)
		var holder: Node3D = Node3D.new()
		var mid: Vector2 = w["mid"]
		var pos: Vector2 = mid + inward * (OfficeWorld.WALL_THICKNESS * 0.5 + 0.02)
		holder.position = Vector3(pos.x, float(cfg["center_height"]), pos.y)
		holder.rotation.y = atan2(inward.x, inward.y)
		var frame_color: Color = color_of(cfg["award_frame"] if not str(spec["award"]).is_empty() else cfg["frame"])
		box(holder, Vector3(0, 0, -0.005), Vector3(size.x + 0.1, size.y + 0.1, 0.02), frame_color)
		var quad: MeshInstance3D = _panel(spec, Vector2i(_v2(kv["poster_pixels"])), size)
		quad.position.z = 0.01
		holder.add_child(quad)
		_visual_root.add_child(holder)
		w["poster"] = holder


## Görseli çizen SubViewport'u ve onu gösteren düz yüzeyi kurar.
func _panel(spec: Dictionary, px: Vector2i, size: Vector2) -> MeshInstance3D:
	var vp: SubViewport = KeyVisual.make_viewport(spec, px)
	_visual_root.add_child(vp)
	var quad: MeshInstance3D = MeshInstance3D.new()
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = size
	quad.mesh = mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = vp.get_texture()
	quad.material_override = mat
	return quad
