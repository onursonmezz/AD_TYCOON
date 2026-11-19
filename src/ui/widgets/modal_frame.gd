class_name ModalFrame
extends RefCounted
## Modal pencere iskeleti (UiUtil.modal_frame buradan çağırır; ui_util.gd 400 satırı aşmasın diye ayrıldı, UI-4).

## Modal pencere iskeleti: root'un içine karartılmış arka plan + ortada kaydırılabilir kart kurar.
## Dönüş: içeriğin ekleneceği kutu.
static func build(root: Control, min_size: Vector2, animate: bool = true, fixed: bool = false) -> VBoxContainer:
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.08, 0.14, 0.1, 0.45)
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	# fixed: pencere tam verilen boyda (taslak ölçüsü); değilse yükseklik içerikten gelir, min_size.y üst sınırdır.
	panel.custom_minimum_size = min_size if fixed else Vector2(min_size.x, 0.0)
	center.add_child(panel)
	var parts: Array = UiUtil.window_frame(panel)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	(parts[1] as VBoxContainer).add_child(scroll)
	# K-122: içerik taşarsa önce küçülür (FitScaler, ui_layout fit_min_scale); o da yetmezse kayar.
	var scaler: FitScaler = FitScaler.new(float(DataDB.data.raw["ui_layout.json"]["fit_min_scale"]))
	scaler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scaler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(scaler)
	var content: VBoxContainer = UiUtil.vbox(10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.set_meta("frame", parts[1])  # altbilgi düğmeleri için: UiUtil.modal_outer
	scaler.add_child(content)
	# UI-3: pencere içeriği kadar yer kaplar; min_size.y en fazla yüksekliktir.
	# Kaydırma çubuğu ya hep var ya hiç yok (belirip kaybolurken metin genişliği oynamasın).
	var cap: float = min_size.y - UiUtil.MODAL_CHROME if fixed else minf(min_size.y, 600.0)
	scroll.custom_minimum_size = Vector2(min_size.x - 2.0 * CozyTheme.SPACE_XL, 0.0)
	var fit: Callable = func() -> void:
		if not is_instance_valid(content) or not is_instance_valid(scroll):
			return  # pencere bu arada kapandı
		var need: float = content.get_combined_minimum_size().y
		var shown: bool = scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		var low: float = need * scaler.min_scale
		var mode: ScrollContainer.ScrollMode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS \
			if low > cap or (shown and low > cap - MainHud.SCROLL_HYSTERESIS) else ScrollContainer.SCROLL_MODE_DISABLED
		if scroll.vertical_scroll_mode != mode:
			scroll.vertical_scroll_mode = mode
		var h: float = cap if fixed else minf(need, cap)
		if not is_equal_approx(scroll.custom_minimum_size.y, h):
			scroll.custom_minimum_size.y = h
	content.minimum_size_changed.connect(fit)
	fit.call_deferred()
	if animate:
		UiUtil.pop_in(panel)
	# Esc ile kapanan pencerelerde başlık bandında kapat düğmesi.
	if root.has_meta("esc_closes"):
		(parts[2] as HBoxContainer).add_child(UiUtil.close_button(root.queue_free))
	# Başlık içerik kurulduktan sonra banda taşınır.
	var adopt: Callable = func() -> void:
		if is_instance_valid(parts[0]) and is_instance_valid(content):  # pencere bu arada kapandıysa geç
			UiUtil.adopt_heading(parts[0], content)
	if root.is_node_ready():
		adopt.call_deferred()
	else:
		root.ready.connect(adopt, CONNECT_ONE_SHOT)
	return content
