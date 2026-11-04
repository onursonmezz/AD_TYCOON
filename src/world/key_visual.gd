class_name KeyVisual
extends RefCounted
## Kampanya "key visual"ı (GDD 21.4): şablon + marka rengi + slogan. Ofisin önündeki billboard'da ve duvar
## posterlerinde görünür. spec() saf veridir (test edilir); make_viewport() onu bir SubViewport'a bir kez çizer.


## Billboard: yayındaki en yeni kampanya, yoksa en son biten; hiç yoksa "kiralık alan".
static func billboard_campaign(state: SimState) -> Dictionary:
	if not state.airing.is_empty():
		return state.airing[state.airing.size() - 1]
	if not state.finished.is_empty():
		return state.finished[state.finished.size() - 1]
	return {}


## Posterler: biten kampanyalardan ödül alanlar önce, sonra puanı yüksek olanlar.
static func poster_campaigns(state: SimState, count: int) -> Array[Dictionary]:
	var list: Array[Dictionary] = state.finished.duplicate()
	var awarded: Dictionary = awarded_campaigns(state)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var aa: bool = awarded.has(a["id"])
		var bb: bool = awarded.has(b["id"])
		if aa != bb:
			return aa
		return float(a["report"]["score"]) > float(b["report"]["score"]))
	return list.slice(0, count)


static func awarded_campaigns(state: SimState) -> Dictionary:
	var out: Dictionary = {}
	for row: Dictionary in state.award_history:
		var level: String = str(row.get("level", ""))
		if not level.is_empty() and level != "shortlist":
			out[row["campaign"]] = level
	return out


## Görselin içeriği: marka, başlık, slogan anahtarı, renkler, şablon. Aynı kampanya hep aynı görseli verir.
static func spec(data: GameData, camp: Dictionary, awarded: Dictionary = {}) -> Dictionary:
	var kv: Dictionary = data.models["key_visual"]
	if camp.is_empty():
		return {"empty": true, "bg": UiUtil.CREAM, "accent": UiUtil.SAGE_DARK, "layout": 0, "award": ""}
	var setup: Dictionary = camp["setup"]
	var brand: String = str(setup.get("client_name", ""))
	var h: int = absi(str(camp["id"]).hash())
	var palette: Array = kv["palette"]
	var bg_idx: int = absi(brand.hash()) % palette.size()
	var acc_idx: int = (bg_idx + 1 + h % (palette.size() - 1)) % palette.size()
	var c: Array = palette[bg_idx]
	var a: Array = palette[acc_idx]
	var title: String = str(setup.get("name", ""))
	return {"empty": false, "brand": brand, "title": title if not title.is_empty() else brand,
		"slogan_key": "KV_SLOGAN_%d" % (h % int(kv["slogans"]) + 1), "sector": data.sectors[setup["sector"]]["name_key"],
		"bg": Color(float(c[0]), float(c[1]), float(c[2])), "accent": Color(float(a[0]), float(a[1]), float(a[2])),
		"layout": (h / 7) % int(kv["layouts"]), "award": str(awarded.get(camp["id"], ""))}


## Görseli bir kez çizen SubViewport (ağaca eklenmeli). Doku: viewport.get_texture().
static func make_viewport(s: Dictionary, px: Vector2i) -> SubViewport:
	var vp: SubViewport = SubViewport.new()
	vp.size = px
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var bg: ColorRect = ColorRect.new()
	bg.color = s["bg"]
	bg.size = Vector2(px)
	vp.add_child(bg)
	var unit: float = float(mini(px.x, px.y))
	if bool(s["empty"]):
		_text(vp, TranslationServer.translate("KV_EMPTY"), unit * 0.11, s["accent"], Rect2(Vector2.ZERO, Vector2(px)), true)
		return vp
	var light: bool = (s["bg"] as Color).get_luminance() < 0.5
	var ink: Color = UiUtil.CREAM if light else UiUtil.TEXT
	var slogan: String = TranslationServer.translate(s["slogan_key"]).format({"brand": s["brand"]})
	var w: float = float(px.x)
	var hgt: float = float(px.y)
	match int(s["layout"]):
		0:
			# Ortada büyük başlık, altta slogan, köşede marka.
			_text(vp, s["title"], unit * 0.16, ink, Rect2(0, hgt * 0.15, w, hgt * 0.4), true)
			_text(vp, slogan, unit * 0.07, s["accent"] if not light else UiUtil.MUSTARD, Rect2(0, hgt * 0.58, w, hgt * 0.2), true)
			_text(vp, str(s["brand"]).to_upper(), unit * 0.06, ink, Rect2(w * 0.05, hgt * 0.82, w * 0.9, hgt * 0.14), false)
		1:
			# Solda renk bloğu ve marka, sağda başlık ve slogan.
			var block: ColorRect = ColorRect.new()
			block.color = s["accent"]
			block.size = Vector2(w * 0.38, hgt)
			vp.add_child(block)
			_text(vp, str(s["brand"]).to_upper(), unit * 0.09, UiUtil.CREAM, Rect2(0, 0, w * 0.38, hgt), true)
			_text(vp, s["title"], unit * 0.12, ink, Rect2(w * 0.4, hgt * 0.15, w * 0.58, hgt * 0.45), true)
			_text(vp, slogan, unit * 0.06, ink, Rect2(w * 0.4, hgt * 0.6, w * 0.58, hgt * 0.3), true)
		_:
			# Alt bant: üstte slogan büyük, bantta marka ve başlık.
			_text(vp, slogan, unit * 0.11, ink, Rect2(w * 0.05, hgt * 0.08, w * 0.9, hgt * 0.6), true)
			var band: ColorRect = ColorRect.new()
			band.color = s["accent"]
			band.position = Vector2(0, hgt * 0.72)
			band.size = Vector2(w, hgt * 0.28)
			vp.add_child(band)
			_text(vp, "%s · %s" % [str(s["brand"]).to_upper(), s["title"]], unit * 0.065, UiUtil.CREAM,
				Rect2(0, hgt * 0.72, w, hgt * 0.28), true)
	if not str(s["award"]).is_empty():
		var badge: ColorRect = ColorRect.new()
		badge.color = UiUtil.MUSTARD
		badge.size = Vector2(unit * 0.22, unit * 0.22)
		badge.position = Vector2(w - unit * 0.27, unit * 0.05)
		vp.add_child(badge)
		_text(vp, "★", unit * 0.15, UiUtil.TEXT, Rect2(badge.position, badge.size), true)
	return vp


static func _text(parent: Node, text: String, font_size: float, color: Color, rect: Rect2, center: bool) -> void:
	var l: Label = Label.new()
	l.text = text
	l.position = rect.position
	l.size = rect.size
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", int(font_size))
	l.add_theme_color_override("font_color", color)
	l.clip_text = true
	parent.add_child(l)
