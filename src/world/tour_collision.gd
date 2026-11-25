class_name TourCollision
extends RefCounted
## Gezinti modunda (K-148) yürüyenin duvar ve eşyalardan geçmemesi: OfficeLayout'un duvar parçaları (kapılar boşluk)
## ve eşya alanları. Yere serilen (halı) ve asılı eşyalar engel değildir; çalışanların içinden geçilir.
## Saf hesap: sahneye bağlı değil, test edilebilir.

## Duvar gövdesinin yarı kalınlığı (OfficeWorld.WALL_THICKNESS / 2).
const WALL_HALF: float = 0.09


## p noktasında radius yarıçaplı daire bir duvara ya da eşyaya değiyor mu, ya da yürünebilir alanın dışında mı.
static func blocked(layout: OfficeLayout, p: Vector2, radius: float, margin: float) -> bool:
	if not Rect2(Vector2.ZERO, layout.size).grow(margin).has_point(p):
		return true
	for w: Dictionary in layout.walls:
		if Geometry2D.get_closest_point_to_segment(p, w["a"], w["b"]).distance_to(p) < WALL_HALF + radius:
			return true
	for prop: Dictionary in layout.props:
		if bool(prop.get("flat", false)) or bool(prop.get("hanging", false)):
			continue
		var r: Rect2 = prop["rect"]
		var nearest: Vector2 = p.clamp(r.position, r.end)
		if nearest.distance_to(p) < radius:
			return true
	return false


## from'dan to'ya gidiş; engel varsa duvar boyunca kayar (önce yalnız x, sonra yalnız z). Gidilemiyorsa from.
static func slide(layout: OfficeLayout, from: Vector2, to: Vector2, radius: float, margin: float) -> Vector2:
	if not blocked(layout, to, radius, margin):
		return to
	if blocked(layout, from, radius, margin):
		return to  # bir engelin içinde başlandıysa (dar giriş) sıkışıp kalmasın
	var only_x: Vector2 = Vector2(to.x, from.y)
	if not blocked(layout, only_x, radius, margin):
		return only_x
	var only_z: Vector2 = Vector2(from.x, to.y)
	if not blocked(layout, only_z, radius, margin):
		return only_z
	return from


## Başlangıç noktası: giriş kapısından içeri doğru back metre; orası doluysa kapının kendisi.
static func start_point(layout: OfficeLayout, back: float, radius: float) -> Vector2:
	var inward: Vector2 = (layout.entrance - layout.doorway).normalized()
	if inward.is_zero_approx():
		inward = (layout.size * 0.5 - layout.entrance).normalized()
	var p: Vector2 = layout.entrance + inward * back
	return p if not blocked(layout, p, radius, 0.0) else layout.entrance
