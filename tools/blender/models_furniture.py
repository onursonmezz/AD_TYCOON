"""Satın alınan mobilya ve dekor ile sokak eşyaları (G3, art/prompts/items.md).

Ölçüler oyunun beklediği taban ve boyla aynı (data/furniture.json, data/models.json). Ön yüz -Y.
"""

import math
import random

from common import Builder


def _cabinet(b: Builder, width: float = 0.48, depth: float = 0.46, height: float = 0.7, color: str = "wood") -> float:
    """İçecek makinelerinin altındaki küçük dolap; üst yüzeyin yüksekliğini döndürür."""
    b.box((width, depth, height - 0.04), (0, 0, (height - 0.04) / 2 + 0.04), color, bevel=0.015)
    b.box((width - 0.06, depth - 0.06, 0.04), (0, 0, 0.02), "wood_dark", bevel=0.008, segments=1)
    b.box((width - 0.06, 0.02, height - 0.16), (0, -depth / 2 - 0.005, height / 2 + 0.02), "wood_light", bevel=0.01)
    b.box((0.025, 0.025, 0.1), (width / 2 - 0.08, -depth / 2 - 0.02, height - 0.17), "brass", bevel=0.008, segments=1)
    b.box((width + 0.02, depth + 0.02, 0.03), (0, 0, height - 0.015), "wood_light", bevel=0.01, segments=1)
    return height


def tea_urn() -> None:
    """Semaver: pirinç gövde, üstte demlik, yanında tepside ince belli çay bardakları."""
    b = Builder("tea_urn")
    top = _cabinet(b)
    b.cylinder(0.08, 0.1, 0.05, (0, 0.04, top), "brass", segments=14)
    b.cylinder(0.12, 0.1, 0.16, (0, 0.04, top + 0.05), "brass", segments=16)
    b.cylinder(0.1, 0.06, 0.03, (0, 0.04, top + 0.21), "brass", segments=14)
    b.cylinder(0.06, 0.05, 0.07, (0, 0.04, top + 0.24), "terracotta", segments=12)
    b.blob(0.025, (0, 0.04, top + 0.32), "terracotta_dark")
    b.box((0.03, 0.05, 0.02), (0, -0.07, top + 0.1), "brass", bevel=0.006, segments=1)
    b.box((0.2, 0.12, 0.012), (0.08, -0.14, top + 0.006), "brass", bevel=0.004, segments=1)
    for i in range(3):
        b.cylinder(0.018, 0.024, 0.06, (0.02 + i * 0.06, -0.14, top + 0.012), "terracotta_dark", segments=8, bevel=0.004)
    b.finish()


def filter_coffee() -> None:
    """Filtre kahve makinesi: kömür gövde, cam sürahi, yanında kupalar."""
    b = Builder("filter_coffee")
    top = _cabinet(b)
    b.box((0.2, 0.18, 0.04), (-0.06, 0.02, top + 0.02), "charcoal", bevel=0.012)
    b.box((0.2, 0.08, 0.3), (-0.06, 0.07, top + 0.15), "charcoal", bevel=0.02)
    b.box((0.2, 0.18, 0.06), (-0.06, 0.02, top + 0.29), "charcoal", bevel=0.02)
    b.cylinder(0.06, 0.055, 0.13, (-0.06, -0.01, top + 0.04), "water_blue", segments=12, bevel=0.01)
    b.cylinder(0.062, 0.062, 0.06, (-0.06, -0.01, top + 0.1), "wood_dark", segments=12, bevel=0.008)
    for i, col in enumerate(["cream", "terracotta"]):
        b.cylinder(0.035, 0.035, 0.08, (0.13, -0.1 + i * 0.1, top), col, segments=10, bevel=0.006)
    b.finish()


def espresso() -> None:
    """Espresso makinesi: gümüş gövde, iki grup başlığı, manometre, üstte fincanlar."""
    b = Builder("espresso")
    top = _cabinet(b)
    b.box((0.36, 0.28, 0.24), (0, 0.06, top + 0.12), "steel", bevel=0.03, segments=3)
    b.box((0.37, 0.02, 0.05), (0, -0.09, top + 0.2), "red", bevel=0.012)
    for x in (-0.09, 0.09):
        b.cylinder(0.035, 0.03, 0.05, (x, -0.06, top + 0.07), "charcoal", segments=10, bevel=0.006)
        b.box((0.02, 0.08, 0.02), (x, -0.12, top + 0.09), "charcoal", bevel=0.006, segments=1)
    b.cylinder(0.03, 0.03, 0.012, (0, -0.095, top + 0.16), "cream", segments=12, bevel=0.0)
    b.box((0.3, 0.12, 0.014), (0, -0.12, top + 0.007), "charcoal", bevel=0.004, segments=1)
    for i in range(3):
        b.cylinder(0.026, 0.02, 0.04, (-0.1 + i * 0.1, 0.1, top + 0.24), "cream", segments=10, bevel=0.005)
    b.finish()


def water_cooler() -> None:
    """Su sebili: beyaz gövde, kırmızı ve mavi musluk, üstte mavi damacana."""
    b = Builder("water_cooler")
    b.box((0.32, 0.32, 0.88), (0, 0, 0.44), "white_soft", bevel=0.04, segments=3)
    b.box((0.24, 0.02, 0.2), (0, -0.165, 0.62), "steel", bevel=0.01)
    b.box((0.04, 0.05, 0.05), (-0.05, -0.18, 0.64), "red", bevel=0.01, segments=1)
    b.box((0.04, 0.05, 0.05), (0.05, -0.18, 0.64), "water_blue", bevel=0.01, segments=1)
    b.box((0.2, 0.08, 0.02), (0, -0.17, 0.53), "charcoal", bevel=0.006, segments=1)
    b.cylinder(0.05, 0.05, 0.05, (0, 0, 0.88), "white_soft", segments=12, bevel=0.0)
    b.cylinder(0.04, 0.14, 0.08, (0, 0, 0.93), "water_blue", segments=16, bevel=0.0)
    b.cylinder(0.14, 0.14, 0.24, (0, 0, 1.01), "water_blue", segments=16, bevel=0.03)
    b.cylinder(0.12, 0.1, 0.05, (0, 0, 1.25), "water_blue", segments=16, bevel=0.02)
    b.finish()


def _board_stand(b: Builder, width: float, board_color: str, frame_color: str) -> tuple:
    """Tekerlekli pano ayağı ve panosu; panonun ön yüzü (y) ve dikey sınırlarını döndürür."""
    for x in (-width / 2 + 0.05, width / 2 - 0.05):
        b.box((0.06, 0.46, 0.05), (x, 0, 0.07), "charcoal", bevel=0.015)
        for y in (-0.19, 0.19):
            b.cylinder(0.03, 0.03, 0.045, (x, y, 0), "charcoal", segments=8, bevel=0.008, bevel_segments=1)
        b.box((0.045, 0.045, 1.5), (x, 0, 0.07 + 0.75), "steel", bevel=0.012)
    z0, z1 = 0.62, 1.52
    b.box((width - 0.14, 0.05, z1 - z0 + 0.08), (0, 0, (z0 + z1) / 2), frame_color, bevel=0.015)
    b.box((width - 0.2, 0.054, z1 - z0), (0, 0, (z0 + z1) / 2), board_color, bevel=0.005, segments=1)
    return -0.027, z0, z1


def whiteboard() -> None:
    """Tekerlekli beyaz tahta: renkli karalamalar ve yapışkan notlar (okunur yazı yok)."""
    b = Builder("whiteboard")
    y, z0, z1 = _board_stand(b, 1.5, "white_soft", "steel")
    rng = random.Random(5)
    for i in range(6):
        b.box((rng.uniform(0.2, 0.45), 0.006, 0.018), (rng.uniform(-0.45, 0.2), y, z1 - 0.12 - i * 0.12),
              rng.choice(["red", "water_blue", "sage"]), bevel=0.003, segments=1, rot_y=rng.uniform(-0.08, 0.08))
    for i, col in enumerate(["pastel_yellow", "pastel_pink", "pastel_mint", "pastel_yellow"]):
        b.box((0.1, 0.008, 0.1), (0.38 + (i % 2) * 0.13, y, z1 - 0.15 - (i // 2) * 0.14), col, bevel=0.003, segments=1)
    b.box((1.0, 0.06, 0.025), (0, -0.04, z0 - 0.02), "steel", bevel=0.008, segments=1)
    for i, col in enumerate(["red", "water_blue", "charcoal"]):
        b.box((0.1, 0.018, 0.018), (-0.2 + i * 0.13, -0.05, z0 - 0.0), col, bevel=0.006, segments=1)
    b.finish()


def mood_board() -> None:
    """Mantar ilham panosu: iğnelenmiş fotoğraflar, renk örnekleri, ip."""
    b = Builder("mood_board")
    y, z0, z1 = _board_stand(b, 1.5, "cork", "wood")
    rng = random.Random(9)
    cols = ["cream", "pastel_blue", "pastel_pink", "pastel_mint", "white_soft", "pastel_yellow"]
    for i in range(7):
        x = -0.5 + (i % 4) * 0.32 + rng.uniform(-0.04, 0.04)
        z = z1 - 0.2 - (i // 4) * 0.36 + rng.uniform(-0.04, 0.04)
        w, h = rng.uniform(0.16, 0.24), rng.uniform(0.14, 0.22)
        b.box((w, 0.008, h), (x, y, z), rng.choice(cols), bevel=0.003, segments=1, rot_y=rng.uniform(-0.15, 0.15))
        b.blob(0.012, (x, y - 0.008, z + h / 2 - 0.02), "red", subdiv=1)
    for i, col in enumerate(["terracotta", "mustard", "sage", "wall_deep", "pastel_pink"]):
        b.box((0.08, 0.008, 0.08), (0.18 + i * 0.09, y, z0 + 0.12), col, bevel=0.003, segments=1)
    b.finish()


def record_player() -> None:
    """Pikap: bacaklı ahşap dolap, altta plaklar, üstte dönen tabla ve kol."""
    b = Builder("record_player")
    w, d, h = 1.0, 0.46, 0.68
    for x in (-w / 2 + 0.08, w / 2 - 0.08):
        for y in (-d / 2 + 0.08, d / 2 - 0.08):
            b.cylinder(0.03, 0.02, 0.18, (x, y, 0), "wood_dark", segments=8, bevel=0.0)
    b.box((w, d, h - 0.18), (0, 0, 0.18 + (h - 0.18) / 2), "wood", bevel=0.02)
    b.box((w - 0.08, 0.02, h - 0.3), (0, -d / 2 - 0.005, 0.18 + (h - 0.18) / 2), "wood_dark", bevel=0.006, segments=1)
    rng = random.Random(4)
    for i in range(12):
        col = rng.choice(["charcoal", "terracotta", "mustard", "sage", "pastel_blue", "cream"])
        b.box((0.015, 0.36, 0.34), (-0.4 + i * 0.03, -0.05, 0.22 + 0.17), col, bevel=0.003, segments=1)
    b.box((0.36, 0.08, 0.3), (0.26, -0.18, 0.39), "charcoal", bevel=0.02)
    b.box((0.5, 0.38, 0.08), (0, 0, h + 0.04), "wood_dark", bevel=0.02)
    b.cylinder(0.15, 0.15, 0.02, (-0.06, 0.0, h + 0.08), "charcoal", segments=24, bevel=0.005)
    b.cylinder(0.05, 0.05, 0.004, (-0.06, 0.0, h + 0.1), "mustard", segments=14, bevel=0.0)
    b.cylinder(0.025, 0.025, 0.05, (0.18, 0.12, h + 0.08), "steel", segments=8, bevel=0.0)
    b.box((0.2, 0.015, 0.015), (0.1, 0.07, h + 0.13), "steel", bevel=0.005, segments=1, rot_z=0.5)
    b.finish()


def award_case() -> None:
    """Ödül dolabı: koyu çerçeve, üç raf, altın kupalar ve plaketler (öne açık vitrin)."""
    b = Builder("award_case")
    w, d, h = 1.0, 0.45, 1.8
    b.box((w, d, 0.12), (0, 0, 0.06), "wood_dark", bevel=0.02)
    b.box((w, d, 0.06), (0, 0, h - 0.03), "wood_dark", bevel=0.02)
    for x in (-w / 2 + 0.03, w / 2 - 0.03):
        b.box((0.06, d, h - 0.16), (x, 0, h / 2), "wood_dark", bevel=0.012)
    b.box((w - 0.08, 0.02, h - 0.16), (0, d / 2 - 0.02, h / 2), "wall_deep", bevel=0.004, segments=1)
    shelves = [0.12, 0.62, 1.12]
    for z in shelves[1:]:
        b.box((w - 0.1, d - 0.06, 0.025), (0, 0, z), "wood", bevel=0.008, segments=1)
    for row, z in enumerate(shelves):
        for i, x in enumerate((-0.28, 0.0, 0.28)):
            if (row + i) % 3 == 2:
                b.box((0.16, 0.03, 0.2), (x, 0.1, z + 0.12), "wood", bevel=0.01, segments=1, rot_x=-0.15)
                b.box((0.1, 0.006, 0.08), (x, 0.08, z + 0.14), "mustard", bevel=0.002, segments=1, rot_x=-0.15)
                continue
            s = 0.8 + 0.2 * ((row + i) % 2)
            b.box((0.1 * s, 0.1 * s, 0.05), (x, 0, z + 0.04), "wood_dark", bevel=0.01, segments=1)
            b.cylinder(0.015, 0.015, 0.1 * s, (x, 0, z + 0.065), "mustard", segments=8, bevel=0.0)
            b.cylinder(0.035 * s, 0.075 * s, 0.13 * s, (x, 0, z + 0.065 + 0.1 * s), "mustard", segments=14, bevel=0.01)
            for side in (-1, 1):
                b.box((0.03, 0.012, 0.06 * s), (x + side * 0.085 * s, 0, z + 0.065 + 0.17 * s), "mustard",
                      bevel=0.005, segments=1)
    b.finish()


def neon_sign() -> None:
    """Pembe neon ampul tabelası: ayaklı koyu pano, üstünde ampul şekilli neon tüp (yazı yok)."""
    b = Builder("neon_sign")
    b.box((0.9, 0.4, 0.06), (0, 0, 0.03), "wood_light", bevel=0.02)
    for x in (-0.3, 0.3):
        b.box((0.04, 0.04, 0.4), (x, 0.06, 0.26), "charcoal", bevel=0.01, segments=1)
    b.box((0.95, 0.04, 0.72), (0, 0.06, 0.46 + 0.36), "lamp_green", bevel=0.02)
    tube, y = 0.03, 0.02
    cx, cz, r = 0.0, 0.92, 0.2
    n = 14
    for k in range(n):
        a0 = math.radians(-50) + (math.radians(280) / n) * (k + 0.5)
        seg = 2 * r * math.sin(math.radians(280) / n / 2) + 0.012
        b.box((seg, tube, tube), (cx + math.cos(a0) * r, y, cz + math.sin(a0) * r), "neon_pink", bevel=0.012,
              segments=2, rot_y=-(a0 + math.pi / 2))
    for x in (-0.1, 0.1):
        b.box((tube, tube, 0.16), (x, y, cz - r * 0.8 - 0.06), "neon_pink", bevel=0.012, segments=2)
    for i in range(3):
        b.box((0.22 - i * 0.03, tube, tube), (0, y, 0.6 - i * 0.05), "neon_pink", bevel=0.012, segments=2)
    b.box((tube, tube, 0.14), (0, y, cz - 0.02), "neon_pink", bevel=0.012, segments=2, rot_y=0.4)
    b.finish()


def office_cat() -> None:
    """Ofis kedisi: yuvarlak minderde kıvrılıp uyuyan turuncu kedi."""
    b = Builder("office_cat")
    rng = random.Random(2)
    b.cylinder(0.48, 0.46, 0.14, (0, 0, 0), "pastel_pink", segments=24, bevel=0.05, bevel_segments=3)
    b.cylinder(0.5, 0.5, 0.06, (0, 0, 0.1), "terracotta", segments=24, bevel=0.03, bevel_segments=2)
    b.blob(0.2, (0.03, 0.04, 0.27), "cat_orange", subdiv=2, squash=(1.35, 1.0, 0.75), rng=rng, wobble=0.04)
    b.blob(0.12, (-0.2, -0.08, 0.3), "cat_orange", subdiv=2, squash=(1.0, 1.0, 0.9), rng=rng, wobble=0.03)
    for x in (-0.26, -0.15):
        b.cylinder(0.04, 0.0, 0.08, (x, -0.06, 0.38), "cat_orange", segments=6, bevel=0.0)
    b.blob(0.05, (0.18, -0.16, 0.2), "cat_orange", squash=(3.0, 1.0, 0.8), rng=rng, wobble=0.02)
    b.blob(0.04, (-0.24, -0.18, 0.28), "cream", squash=(1.2, 0.8, 0.8), rng=rng, wobble=0.02)
    b.finish()


# --- sokak (street/) -----------------------------------------------------------

def tree(seed: int = 21) -> None:
    """Yuvarlak sokak ağacı: konik gövde, tombul yaprak kümeleri."""
    b = Builder("tree")
    rng = random.Random(seed)
    b.cylinder(0.14, 0.08, 1.7, (0, 0, 0), "wood_dark", segments=10, bevel=0.0)
    b.blob(0.5, (0, 0, 2.55), "leaf", subdiv=2, rng=rng, squash=(1.0, 1.0, 0.95))
    for k in range(6):
        a = math.tau * k / 6 + rng.uniform(-0.2, 0.2)
        b.blob(rng.uniform(0.28, 0.36), (math.cos(a) * 0.3, math.sin(a) * 0.3, rng.uniform(2.05, 2.6)),
               ["leaf_light", "leaf_dark", "leaf"][k % 3], subdiv=2, rng=rng)
    b.finish()


def lamp() -> None:
    """Klasik koyu yeşil sokak lambası: kaide, direk, fener."""
    b = Builder("lamp")
    b.cylinder(0.15, 0.12, 0.3, (0, 0, 0), "lamp_green", segments=12, bevel=0.02)
    b.cylinder(0.05, 0.04, 2.3, (0, 0, 0.3), "lamp_green", segments=10, bevel=0.0)
    b.cylinder(0.07, 0.07, 0.05, (0, 0, 2.58), "lamp_green", segments=10, bevel=0.01)
    b.box((0.18, 0.18, 0.24), (0, 0, 2.63 + 0.12), "pastel_yellow", bevel=0.02)
    for x in (-0.09, 0.09):
        for y in (-0.09, 0.09):
            b.box((0.025, 0.025, 0.26), (x, y, 2.63 + 0.12), "lamp_green", bevel=0.006, segments=1)
    b.cylinder(0.15, 0.02, 0.12, (0, 0, 2.87), "lamp_green", segments=4, bevel=0.0)
    b.finish()


def bench() -> None:
    """Park bankı: kömür metal yan ayaklar, ahşap oturak ve sırt çıtaları."""
    b = Builder("bench")
    for x in (-0.6, 0.6):
        b.box((0.05, 0.42, 0.05), (x, 0.0, 0.025), "charcoal", bevel=0.012, segments=1)
        b.box((0.05, 0.05, 0.4), (x, -0.16, 0.22), "charcoal", bevel=0.012, segments=1)
        b.box((0.05, 0.05, 0.78), (x, 0.17, 0.39), "charcoal", bevel=0.012, segments=1, rot_x=-0.12)
        b.box((0.05, 0.4, 0.04), (x, 0.0, 0.4), "charcoal", bevel=0.012, segments=1)
    for i in range(3):
        b.box((1.5, 0.1, 0.035), (0, -0.14 + i * 0.12, 0.44), "wood", bevel=0.012)
    for i in range(2):
        b.box((1.5, 0.035, 0.09), (0, 0.19 + i * 0.015, 0.57 + i * 0.14), "wood", bevel=0.012, rot_x=-0.12)
    b.finish()


def billboard() -> None:
    """Billboard: iki direk, kalın çerçeve, boş açık panel (görseli oyun önüne çizer), önde iskele ve ışıklar.

    Panel 3.6 x 2.0 m, alt kenarı 1.4 m (data/models.json street_layout); oyun görseli modelin ortasından
    5 cm öne koyar, bu yüzden panel yüzü y = -0.03'ün gerisinde kalır.
    """
    b = Builder("billboard")
    for x in (-1.3, 1.3):
        b.box((0.16, 0.16, 3.4), (x, 0.12, 1.7), "charcoal", bevel=0.02)
    b.box((4.0, 0.06, 0.2), (0, 0.0, 3.5), "lamp_green", bevel=0.02)
    b.box((4.0, 0.06, 0.2), (0, 0.0, 1.3), "lamp_green", bevel=0.02)
    for x in (-1.9, 1.9):
        b.box((0.2, 0.06, 2.4), (x, 0.0, 2.4), "lamp_green", bevel=0.02)
    b.box((3.6, 0.04, 2.0), (0, 0.0, 2.4), "white_soft", bevel=0.0, segments=1)
    b.box((3.8, 0.2, 0.05), (0, -0.1, 1.15), "steel", bevel=0.01, segments=1)
    for x in (-1.2, 0.0, 1.2):
        b.box((0.03, 0.03, 0.12), (x, -0.16, 1.21), "steel", bevel=0.008, segments=1)
        b.box((0.14, 0.08, 0.06), (x, -0.16, 1.28), "pastel_yellow", bevel=0.015, segments=1, rot_x=0.4)
    b.finish()
