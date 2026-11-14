class_name MgFeed
extends MinigameGame
## Akış provası (K-120; sosyal medya, dijital, influencer): telefon akışı yukarı kayarken kendi kampanya gönderine
## tıkla. Başka gönderiye tıklamak başarıdan götürür.

const PHONE: Vector2 = Vector2(600, 1200)        # telefon çerçevesi görseli (piksel)
const SCREEN: Rect2 = Rect2(70, 110, 460, 980)    # çerçevenin içindeki ekran (yaklaşık, piksel)
const POST_H: float = 72.0
const POSTS: int = 7

var _feed: Control
var _posts: Array[Control] = []
var _ours: int = 0
var _mistakes: int = 0
var _screen: Rect2


func begin() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = CozyTheme.SAGE_SOFT.lightened(0.45)
	bg.size = CANVAS
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# Solda aranan gönderi.
	var wanted: Label = UiUtil.label(tr("MG_FEED_WANTED"), 14, CozyTheme.FOREST)
	wanted.add_theme_font_override("font", CozyTheme.title_font(700))
	wanted.position = Vector2(60, 70)
	add_child(wanted)
	var card: Control = ad_preview(Vector2(170, 120))
	card.position = Vector2(50, 100)
	add_child(card)
	# Sağda telefon ve kayan akış.
	var s: float = (CANVAS.y - 20.0) / PHONE.y
	var phone_pos: Vector2 = Vector2(CANVAS.x - PHONE.x * s - 70.0, 10.0)
	_screen = Rect2(phone_pos + SCREEN.position * s, SCREEN.size * s)
	var clip: Control = Control.new()
	clip.position = _screen.position
	clip.size = _screen.size
	clip.clip_contents = true
	add_child(clip)
	_feed = Control.new()
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(_feed)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(ctx["seed"])
	_ours = rng.randi_range(2, 4)  # 5 saniyede ekrana gelsin
	var others: Array[String] = DraftArt.names("products")
	for i: int in POSTS:
		var post: Control
		if i == _ours:
			post = ad_preview(Vector2(_screen.size.x - 8.0, POST_H - 8.0))
		else:
			post = _other_post(others[rng.randi_range(0, others.size() - 1)], rng)
		post.position = Vector2(4, i * POST_H + 4)
		post.mouse_filter = Control.MOUSE_FILTER_STOP
		post.gui_input.connect(_on_post.bind(i))
		_feed.add_child(post)
		_posts.append(post)
	var frame: Texture2D = DraftArt.tex("props", "prop_phone_frame")
	if frame != null:
		var r: TextureRect = DraftArt._image(frame, Rect2(phone_pos, PHONE * s), TextureRect.STRETCH_SCALE)
		add_child(r)


func _other_post(product: String, rng: RandomNumberGenerator) -> Control:
	var c: Control = Control.new()
	c.size = Vector2(_screen.size.x - 8.0, POST_H - 8.0)
	c.clip_contents = true
	var fill: ColorRect = ColorRect.new()
	fill.color = [CozyTheme.CREAM_LIGHT, CozyTheme.SAGE_SOFT, CozyTheme.TERRA_SOFT, CozyTheme.ACCENT_SOFT][rng.randi_range(0, 3)]
	fill.size = c.size
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(fill)
	var t: Texture2D = DraftArt.tex("products", product)
	if t != null:
		c.add_child(DraftArt._image(t, Rect2(Vector2(6, 6), c.size - Vector2(12, 12)), TextureRect.STRETCH_KEEP_ASPECT_CENTERED))
	return c


func _process(delta: float) -> void:
	if _done or _feed == null:
		return
	_feed.position.y -= DataDB.data.balf("minigames.feed_speed") * delta
	# Ekrandan çıkan gönderi alta döner (sonsuz akış).
	for post: Control in _posts:
		if _feed.position.y + post.position.y + POST_H < 0.0:
			post.position.y += POSTS * POST_H


func _on_post(event: InputEvent, i: int) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if _done or mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if i == _ours:
		Audio.play("click")
		finish(1.0 - 0.34 * _mistakes)
	else:
		_mistakes += 1
		var tw: Tween = create_tween()
		tw.tween_property(_posts[i], "modulate", Color(1, 0.6, 0.6), 0.08)
		tw.tween_property(_posts[i], "modulate", Color.WHITE, 0.2)
