class_name OfficeLights
extends RefCounted
## Oda içi ışıklar (B5): her masada küçük bir masa lambası (kodla çizilir: taban, kol, şapka, parlayan ampul) ve
## sıcak, gölgesiz nokta ışığı; odaların ortasında yumuşak tavan ışığı. Yalnızca görünüş. Ayarlar look.json
## "interior_lights"; "enabled": false ya da düşük grafik kalitesinde kapanır.

const LAMP_NAME: String = "DeskLamp"


static func _cfg() -> Dictionary:
	return WorldLook.cfg().get("interior_lights", {})


static func enabled() -> bool:
	var c: Dictionary = _cfg()
	return not c.is_empty() and bool(c["enabled"]) and bool(WorldQuality.level().get("interior_lights", true))


static func _mat(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.6
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


static func _cyl(parent: Node3D, top: float, bottom: float, height: float, y: float, mat: Material) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position.y = y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Yer düzleminde (x, z) bir yönü dikey eksende derece kadar döndürür (Godot y dönüşüyle aynı yön).
static func turned(v: Vector2, degrees: float) -> Vector2:
	var t: float = deg_to_rad(degrees)
	return Vector2(v.x * cos(t) + v.y * sin(t), -v.x * sin(t) + v.y * cos(t))


## Masanın arka sağ köşesine lamba ve ışığı. desk: masanın taban dikdörtgeni (metre, dönmüş hâli); top: masa üstü
## yüksekliği; turn: masanın dönüşü (derece; 0 = oturan güneyde, 180 = ada kuzey sırası, 90 = kurucu masası).
static func desk_lamp(parent: Node3D, desk: Rect2, top: float, turn: float = 0.0) -> void:
	if not enabled():
		return
	var c: Dictionary = _cfg()["desk_lamp"]
	var inset: Vector2 = WorldLook.v2(c["inset"])
	var size: Vector2 = desk.size if int(turn) % 180 == 0 else Vector2(desk.size.y, desk.size.x)
	var local: Vector2 = Vector2(size.x * 0.5 - inset.x, -size.y * 0.5 + inset.y)  # dönmemiş masada arka sağ köşe
	var at: Vector2 = desk.get_center() + turned(local, turn)
	var root: Node3D = Node3D.new()
	root.name = LAMP_NAME
	root.position = Vector3(at.x, top, at.y)
	parent.add_child(root)
	var body: StandardMaterial3D = _mat(WorldLook.col(c["body_color"]))
	var shade: StandardMaterial3D = _mat(WorldLook.col(c["shade_color"]))
	var pole: float = float(c["pole_height"])
	_cyl(root, 0.06, 0.07, 0.02, 0.01, body)
	_cyl(root, 0.012, 0.012, pole, pole * 0.5, body)
	_cyl(root, 0.035, 0.09, 0.1, pole + 0.02, shade)
	var bulb: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.03
	sphere.height = 0.06
	bulb.mesh = sphere
	bulb.material_override = _mat(WorldLook.col(c["light_color"]), float(c["bulb_glow"]))
	bulb.position.y = pole - 0.03
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(bulb)
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = WorldLook.col(c["light_color"])
	light.light_energy = float(c["energy"])
	light.omni_range = float(c["range"])
	light.omni_attenuation = float(c["attenuation"])
	light.position.y = pole - 0.06
	light.shadow_enabled = false
	root.add_child(light)


## Odaların ortasında, tavana yakın yumuşak ışık (oda türü listede olanlarda).
static func rooms(parent: Node3D, layout: OfficeLayout) -> void:
	if not enabled():
		return
	var c: Dictionary = _cfg()["room_light"]
	for room: Dictionary in layout.rooms:
		if not (c["rooms"] as Array).has(str(room["type"])):
			continue
		var r: Rect2 = room["rect"]
		var light: OmniLight3D = OmniLight3D.new()
		light.light_color = WorldLook.col(c["color"])
		light.light_energy = float(c["energy"])
		light.omni_range = clampf(r.size.length() * float(c["range_factor"]), float(c["min_range"]), float(c["max_range"]))
		light.omni_attenuation = float(c["attenuation"])
		light.position = Vector3(r.get_center().x, float(c["height"]), r.get_center().y)
		light.shadow_enabled = false
		parent.add_child(light)
