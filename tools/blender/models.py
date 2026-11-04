"""Parametrik eşya modelleri (G3). Her fonksiyon boş sahneye bir model kurar.

Ölçüler oyunun beklediği taban ve boyla aynı (data/furniture.json, data/models.json);
oyun yine de modeli kendisi sığdırır (ModelLibrary). Ön yüz -Y.
"""

import math
import random

from common import Builder


def desk(width: float = 1.4, depth: float = 0.7, height: float = 0.75) -> None:
    """Çalışma masası: tombul ahşap tabla, dört ayak, sağda çekmeceli dolap (çekmeceler oturana, -Y'ye bakar)."""
    b = Builder("desk")
    top = 0.06
    b.box((width, depth, top), (0, 0, height - top / 2), "wood", bevel=0.025, segments=3)
    leg = 0.07
    leg_h = height - top
    inset = 0.08
    xs = [-width / 2 + inset, width / 2 - inset]
    ys = [-depth / 2 + inset, depth / 2 - inset]
    for x in xs[:1]:
        for y in ys:
            b.box((leg, leg, leg_h), (x, y, leg_h / 2), "wood_dark", bevel=0.015)
    # Sağ tarafta dolap (ayakların yerini alır)
    cab_w = 0.42
    cab_x = width / 2 - inset - cab_w / 2 + leg / 2
    b.box((cab_w, depth - 0.1, leg_h - 0.02), (cab_x, 0, (leg_h - 0.02) / 2 + 0.02), "wood_light", bevel=0.02)
    drawer_h = (leg_h - 0.12) / 3
    for i in range(3):
        z = 0.08 + drawer_h * (i + 0.5)
        b.box((cab_w - 0.06, 0.03, drawer_h - 0.03), (cab_x, -(depth - 0.1) / 2 - 0.01, z), "wood", bevel=0.01)
        b.box((0.08, 0.025, 0.025), (cab_x, -(depth - 0.1) / 2 - 0.035, z + drawer_h * 0.15), "brass",
              bevel=0.008, segments=1)
    # Sol ayakları bağlayan çubuk (sağlamlık hissi)
    b.box((0.04, depth - 2 * inset, 0.05), (xs[0], 0, 0.18), "wood_dark", bevel=0.01, segments=1)
    b.finish()


def bookshelf(width: float = 1.5, depth: float = 0.45, height: float = 1.9, seed: int = 7) -> None:
    """Kitaplık: ahşap gövde, 4 raf, renkli kitaplar, küçük saksı ve vazo."""
    b = Builder("bookshelf")
    rng = random.Random(seed)
    side = 0.05
    b.box((side, depth, height), (-width / 2 + side / 2, 0, height / 2), "wood", bevel=0.018)
    b.box((side, depth, height), (width / 2 - side / 2, 0, height / 2), "wood", bevel=0.018)
    b.box((width, depth, 0.05), (0, 0, height - 0.025), "wood", bevel=0.02)
    b.box((width - 2 * side, 0.02, height - 0.1), (0, depth / 2 - 0.02, height / 2), "wood_dark", bevel=0.004, segments=1)
    b.box((width - 2 * side, depth - 0.02, 0.08), (0, -0.01, 0.04), "wood_dark", bevel=0.012)
    shelf_zs = [0.08 + i * (height - 0.13) / 4 for i in range(4)]
    inner = width - 2 * side
    for z in shelf_zs[1:]:
        b.box((inner, depth - 0.04, 0.035), (0, 0, z), "wood", bevel=0.01)
    book_colors = ["terracotta", "sage", "mustard", "pastel_blue", "cream", "wall_deep", "pastel_pink"]
    gap = (height - 0.13) / 4
    for row, z in enumerate(shelf_zs):
        base = z + (0.04 if row == 0 else 0.0175)
        x = -inner / 2 + 0.04
        end = inner / 2 - 0.04
        decor_at = rng.choice([0, 1]) if row in (1, 3) else -1
        while x < end - 0.05:
            if decor_at >= 0 and x > (-inner / 4 if decor_at == 0 else inner / 6):
                if row == 1:
                    # küçük saksı + bitki
                    b.cylinder(0.07, 0.085, 0.13, (x + 0.09, -0.02, base), "terracotta", segments=12)
                    b.blob(0.11, (x + 0.09, -0.02, base + 0.2), "leaf", rng=rng, squash=(1, 1, 0.9))
                else:
                    b.cylinder(0.06, 0.04, 0.22, (x + 0.08, -0.02, base), "pastel_mint", segments=12)
                x += 0.22
                decor_at = -1
                continue
            w = rng.uniform(0.035, 0.07)
            h = rng.uniform(0.62, 0.86) * (gap - 0.04)
            tilt = rng.random() < 0.08
            if x + w > end:
                break
            if tilt:
                b.box((w, depth * 0.72, h), (x + h * 0.25, -0.02, base + h * 0.47), rng.choice(book_colors),
                      bevel=0.006, segments=1, rot_y=0.22)
                x += h * 0.55
            else:
                b.box((w, depth * 0.72, h), (x + w / 2, -0.02, base + h / 2), rng.choice(book_colors),
                      bevel=0.006, segments=1)
                x += w + 0.004
            if rng.random() < 0.06:
                x += rng.uniform(0.08, 0.16)
    b.finish()


POT_SIZES = {
    # boy (m), saksı yarıçapı, saksı boyu, yaprak kümesi sayısı
    "small": {"height": 0.7, "radius": 0.17, "pot_h": 0.26, "clusters": 5, "color": "terracotta"},
    "medium": {"height": 1.1, "radius": 0.24, "pot_h": 0.36, "clusters": 7, "color": "pot_sage"},
    "big": {"height": 1.6, "radius": 0.36, "pot_h": 0.5, "clusters": 10, "color": "terracotta"},
}


def pot(size: str = "small", seed: int = 3) -> None:
    """Saksıda bitki (küçük / orta / büyük): konik saksı, kalın ağız, toprak, tombul yaprak kümeleri."""
    p = POT_SIZES[size]
    b = Builder("plant_" + size)
    rng = random.Random(seed + len(size))
    r = p["radius"]
    ph = p["pot_h"]
    b.cylinder(r * 0.75, r, ph, (0, 0, 0), p["color"], segments=20, bevel=0.015)
    b.cylinder(r * 1.08, r * 1.08, ph * 0.18, (0, 0, ph * 0.86), p["color"], segments=20, bevel=0.02)
    b.cylinder(r * 0.98, r * 0.98, 0.02, (0, 0, ph * 0.93), "soil", segments=20, bevel=0.0)
    foliage_h = p["height"] - ph
    trunk_h = foliage_h * (0.45 if size == "big" else 0.25)
    b.cylinder(r * 0.12, r * 0.08, trunk_h + 0.05, (0, 0, ph * 0.9), "wood_dark", segments=8, bevel=0.0)
    top = p["height"]
    shades = ["leaf", "leaf_light", "leaf_dark"]
    n = p["clusters"]
    for i in range(n):
        a = i / n * math.tau + rng.uniform(-0.3, 0.3)
        ring = 0.0 if i == 0 else rng.uniform(0.35, 0.75)
        rad = (foliage_h * 0.32 if i == 0 else foliage_h * rng.uniform(0.2, 0.27))
        spread = r * 1.5 if size != "small" else r * 1.25
        z_lo = ph + trunk_h * 0.8 + rad * 0.6
        z = top - rad if i == 0 else rng.uniform(z_lo, top - rad * 1.1)
        b.blob(rad, (math.cos(a) * spread * ring, math.sin(a) * spread * ring, z), shades[i % 3],
               subdiv=2, squash=(1.0, 1.0, 0.85), rng=rng)
    b.finish()


def hex_shelf(cell: float = 0.32, depth: float = 0.16, seed: int = 11) -> None:
    """Altıgen (bal peteği) duvar rafı: üç sivri tepeli altıgen çerçeve, içlerinde küçük eşyalar. Arka yüz +Y (duvara)."""
    b = Builder("hex_shelf")
    rng = random.Random(seed)
    t = 0.035  # çerçeve kalınlığı
    w = cell * math.sqrt(3) / 2  # merkezden düz kenara uzaklık; kenar boyu = cell
    lift = cell  # en alttaki köşe Z = 0'a otursun
    # petek düzeni: altta iki, üstte ortada bir
    centers = [(-w, lift), (w, lift), (0.0, lift + cell * 1.5)]
    for cx, cz in centers:
        for k in range(6):
            a = math.radians(60 * k)  # kenar ortasının açısı (0 = sağ düz kenar)
            mx = cx + math.cos(a) * (w - t / 2)
            mz = cz + math.sin(a) * (w - t / 2)
            b.box((t, depth, cell + t * 0.6), (mx, 0, mz), "wood", bevel=0.008, rot_y=-a)
        b.prism(6, cell - t, 0.012, (cx, depth / 2 - 0.006, cz), "wood_dark", rot_x=math.pi / 2,
                bevel=0.0, start_angle=math.radians(30))
    # İçlerine küçük eşyalar (her altıgenin alt kısmında düz bir taban yok; eşyalar alt köşelere yaslanır)
    floor = lambda c: c[1] - w + t * 1.2
    b.cylinder(0.05, 0.06, 0.08, (centers[0][0], -0.01, floor(centers[0])), "terracotta", segments=10)
    b.blob(0.075, (centers[0][0], -0.01, floor(centers[0]) + 0.14), "leaf_light", rng=rng)
    for i, col in enumerate(["mustard", "sage", "pastel_pink"]):
        hb = 0.17 - i * 0.02
        b.box((0.035, depth * 0.7, hb), (centers[1][0] - 0.05 + i * 0.04, -0.005, floor(centers[1]) + hb / 2), col,
              bevel=0.005, segments=1)
    b.cylinder(0.035, 0.05, 0.12, (centers[2][0], -0.01, floor(centers[2])), "brass", segments=10)
    b.blob(0.05, (centers[2][0], -0.01, floor(centers[2]) + 0.16), "mustard", rng=rng, squash=(0.8, 0.8, 1.0))
    b.finish()


def wall_panel(width: float = 1.2, height: float = 1.0, depth: float = 0.05, slats: int = 9) -> None:
    """Dikey çıtalı ahşap duvar paneli (akustik panel): koyu zemin üstünde yuvarlak uçlu çıtalar. Arka yüz +Y."""
    b = Builder("wall_panel")
    b.box((width, 0.02, height), (0, depth / 2 - 0.01, height / 2), "wall_deep", bevel=0.008)
    gap = width / slats
    sw = gap * 0.62
    for i in range(slats):
        x = -width / 2 + gap * (i + 0.5)
        b.box((sw, depth - 0.02, height - 0.04), (x, -0.01, height / 2), "wood", bevel=min(0.02, sw * 0.4), segments=3)
    b.box((width + 0.04, depth + 0.01, 0.04), (0, -0.005, 0.02), "wood_dark", bevel=0.012)
    b.box((width + 0.04, depth + 0.01, 0.04), (0, -0.005, height - 0.02), "wood_dark", bevel=0.012)
    b.finish()
