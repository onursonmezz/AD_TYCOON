class_name Juice
extends RefCounted
## Arayüz "juice"ı (M9-B, GDD 20): para uçuşu, bildirim kayması, konfeti. Sayılar data/sounds.json "juice".


static func _cfg() -> Dictionary:
	return DataDB.data.sounds["juice"]


## Üst çubuktaki nakdin yanından "+₺…" (yeşil) ya da "−₺…" (kırmızı) yukarı uçar; artışta ka-ching.
## Küçük değişimler (günlük giderler) gösterilmez.
static func cash_fly(anchor: Control, delta: float, year: int) -> void:
	var min_amount: float = float(_cfg()["cash_fly_min_1990"]) * Economy.inflation(DataDB.data, year)
	if absf(delta) < min_amount or not anchor.is_inside_tree():
		return
	var l: Label = UiUtil.label(("+" if delta > 0.0 else "−") + UiUtil.money(absf(delta)), 22, Color.WHITE)
	l.top_level = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", UiUtil.head_font())
	# Rozetlerdeki gibi beyaz yazı + renkli kontur: artış yeşil, azalış kırmızı.
	l.add_theme_color_override("font_outline_color", UiUtil.SAGE_DARK if delta > 0.0 else UiUtil.TERRACOTTA)
	l.add_theme_constant_override("outline_size", 8)
	l.z_index = 10
	anchor.add_child(l)
	# Rozetin solunda başlayıp yukarı süzülür (altındaki bildirimleri örtmesin).
	l.global_position = anchor.global_position + Vector2(-l.get_minimum_size().x - 6.0, anchor.size.y * 0.25)
	var secs: float = float(_cfg()["cash_fly_seconds"])
	var t: Tween = l.create_tween().set_parallel(true)
	t.tween_property(l, "global_position:y", l.global_position.y - 24.0, secs).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, secs).set_delay(secs * 0.4)
	t.chain().tween_callback(l.queue_free)
	if delta > 0.0:
		Audio.play("money")


## Yeni bildirim sağdan kayarak ve belirerek gelir.
static func slide_in(c: Control) -> void:
	var offset: float = float(_cfg()["notify_slide"])
	var secs: float = float(_cfg()["notify_seconds"])
	c.modulate.a = 0.0
	c.position.x += offset
	var t: Tween = c.create_tween().set_parallel(true)
	t.tween_property(c, "modulate:a", 1.0, secs)
	t.tween_property(c, "position:x", c.position.x - offset, secs).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Ekranın üstünden düşen renkli kâğıtlar (yüksek puan).
static func confetti(parent: Control) -> CPUParticles2D:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.amount = int(_cfg()["confetti_count"])
	p.one_shot = true
	p.explosiveness = 0.85
	p.lifetime = 2.2
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(maxf(200.0, parent.size.x * 0.5), 10.0)
	p.position = Vector2(parent.size.x * 0.5, -10.0)
	p.direction = Vector2(0, 1)
	p.spread = 35.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 320.0
	p.gravity = Vector2(0, 260)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.scale_amount_min = 4.0
	p.scale_amount_max = 8.0
	var g: Gradient = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	g.colors = PackedColorArray([UiUtil.SAGE, UiUtil.TERRACOTTA, UiUtil.MUSTARD, UiUtil.WOOD])
	p.color_initial_ramp = g
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p
