class_name WorldLook
extends RefCounted
## Ofisin görünüşü (G1, docs/art-direction.md 4–7): ortam (ton eşleme, SSAO, SSIL, glow), sıcak güneş ve soğuk dolgu
## ışığı, kamera alan derinliği (tilt-shift), duvar parçaları (yuvarlak dış köşeler), zemin desenleri.
## Sayılar data/look.json'da; ince ayar için kod gerekmez.

static var _floor_textures: Dictionary = {}


static func cfg() -> Dictionary:
	return DataDB.data.raw.get("look.json", {})


static func col(a: Array, alpha: float = 1.0) -> Color:
	return Color(float(a[0]), float(a[1]), float(a[2]), alpha)


# --- ortam ve ışık -----------------------------------------------------------------

static func make_environment() -> WorldEnvironment:
	var c: Dictionary = cfg()["environment"]
	var e: Environment = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = col(c["background"])
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = col(c["ambient_color"])
	e.ambient_light_energy = float(c["ambient_energy"])
	e.tonemap_mode = Environment.TONE_MAPPER_ACES if str(c["tonemap"]) == "aces" else Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = float(c["exposure"])
	e.tonemap_white = float(c["white"])
	var ao: Dictionary = c["ssao"]
	e.ssao_enabled = bool(ao["enabled"])
	e.ssao_radius = float(ao["radius"])
	e.ssao_intensity = float(ao["intensity"])
	e.ssao_power = float(ao["power"])
	e.ssao_detail = float(ao["detail"])
	var il: Dictionary = c["ssil"]
	e.ssil_enabled = bool(il["enabled"])
	e.ssil_radius = float(il["radius"])
	e.ssil_intensity = float(il["intensity"])
	var gl: Dictionary = c["glow"]
	e.glow_enabled = bool(gl["enabled"])
	e.glow_intensity = float(gl["intensity"])
	e.glow_strength = float(gl["strength"])
	e.glow_bloom = float(gl["bloom"])
	e.glow_hdr_threshold = float(gl["hdr_threshold"])
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	var adj: Dictionary = c["adjustments"]
	e.adjustment_enabled = true
	e.adjustment_brightness = float(adj["brightness"])
	e.adjustment_contrast = float(adj["contrast"])
	e.adjustment_saturation = float(adj["saturation"])
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = e
	return we


static func make_sun() -> DirectionalLight3D:
	var s: Dictionary = cfg()["sun"]
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_color = col(s["color"])
	sun.light_energy = float(s["energy"])
	sun.rotation_degrees = Vector3(float(s["pitch"]), float(s["yaw"]), 0.0)
	sun.shadow_enabled = true
	sun.shadow_blur = float(s["shadow_blur"])
	sun.shadow_bias = float(s["shadow_bias"])
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = float(s["shadow_max_distance"])
	return sun


## Gölgesiz, soğuk dolgu ışığı: gölgeli yüzler simsiyah olmasın, hafif mavi-yeşil kalsın.
static func make_fill() -> DirectionalLight3D:
	var f: Dictionary = cfg()["fill"]
	var l: DirectionalLight3D = DirectionalLight3D.new()
	l.light_color = col(f["color"])
	l.light_energy = float(f["energy"])
	l.rotation_degrees = Vector3(float(f["pitch"]), float(f["yaw"]), 0.0)
	l.shadow_enabled = false
	return l


## Tilt-shift: odak ofisin ortası; uzaklaştıkça yumuşak bulanıklık (kamera mesafesi değişince güncellenir).
static func apply_camera(camera: Camera3D, distance: float) -> void:
	var c: Dictionary = cfg()["camera"]
	var attrs: CameraAttributesPractical = camera.attributes as CameraAttributesPractical
	if attrs == null:
		attrs = CameraAttributesPractical.new()
		camera.attributes = attrs
	var far: Dictionary = c["dof_far"]
	attrs.dof_blur_far_enabled = bool(far["enabled"])
	attrs.dof_blur_far_distance = distance * float(far["distance_factor"])
	attrs.dof_blur_far_transition = distance * float(far["transition_factor"])
	attrs.dof_blur_amount = float(far["amount"])
	var near: Dictionary = c["dof_near"]
	attrs.dof_blur_near_enabled = bool(near["enabled"])
	attrs.dof_blur_near_distance = float(near["distance"])
	attrs.dof_blur_near_transition = float(near["transition"])


## Kenar kararması (vinyet): 3D görüntünün üstüne yarı saydam radyal katman.
static func make_vignette() -> ColorRect:
	var v: Dictionary = cfg()["vignette"]
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float strength = 0.3;
uniform float radius = 0.85;
void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.0, 0.75);
	float d = length(p) * 1.6;
	float k = smoothstep(radius * 0.55, radius, d);
	COLOR = vec4(0.06, 0.1, 0.07, k * strength);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("strength", float(v["strength"]))
	mat.set_shader_parameter("radius", float(v["radius"]))
	var r: ColorRect = ColorRect.new()
	r.material = mat
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


# --- zemin ----------------------------------------------------------------------

## Oda türüne göre desenli zemin malzemesi: tahta (planks), karo (tiles), halı (carpet), beton (concrete).
## Dünya koordinatına göre desen (triplanar), böylece her oda boyunda aynı ölçek.
static func ground_material() -> StandardMaterial3D:
	var g: Dictionary = cfg()["ground"]
	return pattern_material(g["grass"], str(g.get("pattern", "concrete")), 0.08)


static func floor_material(room_type: String) -> StandardMaterial3D:
	var f: Dictionary = cfg()["floors"].get(room_type, {"color": [0.8, 0.8, 0.8], "pattern": "concrete"})
	return pattern_material(f["color"], str(f["pattern"]), 0.5 if str(f["pattern"]) == "planks" else 0.6)


static func pattern_material(color: Array, pattern: String, scale: float) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = col(color)
	mat.albedo_texture = _pattern(pattern)
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * scale
	mat.roughness = 0.85
	return mat


static func _pattern(kind: String) -> ImageTexture:
	if _floor_textures.has(kind):
		return _floor_textures[kind]
	if kind == "grass":
		# Dikişsiz gürültü: tekrar eden kare izi olmasın.
		var noise: FastNoiseLite = FastNoiseLite.new()
		noise.seed = 7
		noise.frequency = 0.035
		noise.fractal_octaves = 4
		var nimg: Image = noise.get_seamless_image(256, 256)
		nimg.convert(Image.FORMAT_RGB8)
		for y: int in 256:
			for x: int in 256:
				var g: float = 0.72 + 0.45 * nimg.get_pixel(x, y).r
				nimg.set_pixel(x, y, Color(g, g, g))
		var gtex: ImageTexture = ImageTexture.create_from_image(nimg)
		_floor_textures[kind] = gtex
		return gtex
	var n: int = 128
	var img: Image = Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = kind.hash()
	for y: int in n:
		for x: int in n:
			var v: float = 1.0
			match kind:
				"planks":
					# 4 tahta sırası; her tahta biraz farklı ton, aralarında koyu derz, kaydırmalı uç birleşimleri.
					var row: int = y * 4 / n
					var offset: int = (row * 37) % n
					var plank: int = ((x + offset) % n) * 2 / n
					var seed_v: float = float((row * 7 + plank * 13) % 5) / 5.0
					v = 0.9 + 0.12 * seed_v + 0.03 * sin(float(x) * 0.35 + row)
					if y % (n / 4) < 2 or (x + offset) % (n / 2) < 2:
						v = 0.62
				"tiles":
					v = 1.0 if (x % (n / 4) > 2 and y % (n / 4) > 2) else 0.78
				"carpet":
					v = 0.93 + 0.07 * rng.randf()
				_:
					v = 0.9 + 0.08 * rng.randf()
			img.set_pixel(x, y, Color(v, v, v))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_floor_textures[kind] = tex
	return tex


# --- duvarlar ---------------------------------------------------------------------

## Duvar parçaları: dış duvarlar bina köşelerinde corner_radius kadar kısalır, köşeler çeyrek yaylarla birleşir.
## Dönüş: [{ a, b, side, outer, height }]. Yay parçaları en yakın kenarın "side"ını alır (kesik duvar için).
static func wall_segments(layout: OfficeLayout) -> Array[Dictionary]:
	var w: Dictionary = cfg()["walls"]
	var r: float = float(w["corner_radius"])
	var out: Array[Dictionary] = []
	var size: Vector2 = layout.size
	var corners: Array[Vector2] = [Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]
	for wall: Dictionary in layout.walls:
		var a: Vector2 = wall["a"]
		var b: Vector2 = wall["b"]
		if bool(wall["outer"]):
			for c: Vector2 in corners:
				if a.distance_to(c) < 0.01:
					a = a.move_toward(b, r)
				if b.distance_to(c) < 0.01:
					b = b.move_toward(a, r)
		if a.distance_to(b) > 0.02:
			out.append({"a": a, "b": b, "side": wall["side"], "outer": wall["outer"],
				"height": float(w["outer_height"]) if bool(wall["outer"]) else float(w["partition_height"])})
	# Dört bina köşesi: merkez köşeden içeri (r, r); çeyrek yay 6 parça.
	var sides: Array = [["n", "w"], ["n", "e"], ["s", "e"], ["s", "w"]]
	var starts: Array[float] = [PI, 1.5 * PI, 0.0, 0.5 * PI]
	for i: int in 4:
		var c: Vector2 = corners[i]
		var center: Vector2 = c + Vector2(r if c.x < 0.01 else -r, r if c.y < 0.01 else -r)
		var steps: int = 6
		for k: int in steps:
			var t0: float = starts[i] + 0.5 * PI * k / steps
			var t1: float = starts[i] + 0.5 * PI * (k + 1) / steps
			var p0: Vector2 = center + Vector2(cos(t0), sin(t0)) * r
			var p1: Vector2 = center + Vector2(cos(t1), sin(t1)) * r
			var horizontal_side: String = sides[i][0]
			var vertical_side: String = sides[i][1]
			# Yayın yatay kenara yakın yarısı o kenarın, dikey kenara yakın yarısı diğerinin.
			var near_h: bool = absf(p0.y - c.y) + absf(p1.y - c.y) < absf(p0.x - c.x) + absf(p1.x - c.x)
			out.append({"a": p0, "b": p1, "side": horizontal_side if near_h else vertical_side, "outer": true,
				"height": float(w["outer_height"])})
	return out


## Duvarın iç yüzünün rengi: duvarın yanındaki odanın türüne göre (dış duvar); bölme duvarı krem.
static func wall_color(layout: OfficeLayout, seg: Dictionary) -> Color:
	var w: Dictionary = cfg()["walls"]
	if not bool(seg["outer"]):
		return col(w["color"])
	var mid: Vector2 = ((seg["a"] as Vector2) + (seg["b"] as Vector2)) * 0.5
	var inward: Vector2 = (layout.size * 0.5 - mid).normalized()
	var room: Dictionary = layout.room_at(mid + inward * 0.6)
	if room.is_empty():
		return col(w["color"])
	return col(cfg()["walls_by_room"].get(room["type"], w["color"]))
