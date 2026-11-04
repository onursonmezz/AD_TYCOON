"""Odalarla gelen sabit eşyalar ve dönemsel bilgisayarlar (G3, art/prompts/items.md).

Ölçüler oyunun beklediği taban ve boyla aynı (data/models.json). Ön yüz -Y.
"""

import math

from common import Builder


# --- sabit eşyalar (props/) ----------------------------------------------------

def chair() -> None:
    """Tekerlekli ofis sandalyesi: beş kollu ayak, amortisör, minderli oturak ve sırt. Oturan -Y'ye bakar."""
    b = Builder("chair")
    for k in range(5):
        a = math.tau * k / 5 + math.pi / 2
        b.box((0.24, 0.045, 0.035), (math.cos(a) * 0.12, math.sin(a) * 0.12, 0.06), "charcoal", bevel=0.01,
              segments=1, rot_z=a)
        b.cylinder(0.025, 0.025, 0.04, (math.cos(a) * 0.22, math.sin(a) * 0.22, 0.0), "charcoal", segments=8,
                   bevel=0.008, bevel_segments=1)
    b.cylinder(0.03, 0.03, 0.34, (0, 0, 0.06), "steel", segments=10, bevel=0.0)
    b.box((0.48, 0.46, 0.1), (0, -0.01, 0.45), "sage", bevel=0.04, segments=3)
    b.box((0.05, 0.06, 0.3), (0, 0.2, 0.52), "charcoal", bevel=0.01, segments=1)
    b.box((0.44, 0.09, 0.36), (0, 0.22, 0.71), "sage", bevel=0.04, segments=3, rot_x=-0.12)
    b.finish()


def counter(width: float = 3.0, depth: float = 0.6, height: float = 0.95) -> None:
    """Mutfak tezgâhı: krem dolaplar, ahşap üst, evye ve musluk, üstünde kettle ve kupalar."""
    b = Builder("counter")
    body_h = height - 0.05
    b.box((width - 0.02, depth - 0.04, body_h - 0.08), (0, 0.01, (body_h + 0.08) / 2), "cream", bevel=0.015)
    b.box((width - 0.08, depth - 0.1, 0.08), (0, 0.04, 0.04), "wood_dark", bevel=0.01, segments=1)
    doors = 6
    dw = (width - 0.06) / doors
    for i in range(doors):
        x = -width / 2 + 0.03 + dw * (i + 0.5)
        b.box((dw - 0.03, 0.025, body_h - 0.14), (x, -depth / 2 + 0.015, (body_h + 0.1) / 2), "wall_cream", bevel=0.01)
        hx = x + (dw * 0.32 if i % 2 == 0 else -dw * 0.32)
        b.box((0.025, 0.03, 0.12), (hx, -depth / 2 - 0.01, body_h - 0.16), "brass", bevel=0.008, segments=1)
    b.box((width, depth, 0.05), (0, 0, height - 0.025), "wood_light", bevel=0.015)
    # evye ve musluk
    b.box((0.55, 0.38, 0.012), (0.6, 0.02, height + 0.001), "steel", bevel=0.004, segments=1)
    b.cylinder(0.02, 0.02, 0.24, (0.6, 0.2, height), "steel", segments=8, bevel=0.0)
    b.box((0.03, 0.16, 0.03), (0.6, 0.13, height + 0.24), "steel", bevel=0.01, segments=1)
    # kettle ve kupalar
    b.cylinder(0.08, 0.07, 0.18, (-0.9, 0.05, height), "red", segments=12)
    b.box((0.03, 0.08, 0.1), (-0.9, 0.13, height + 0.08), "charcoal", bevel=0.01, segments=1)
    for i, col in enumerate(["mustard", "pastel_blue", "cream"]):
        b.cylinder(0.04, 0.04, 0.09, (-0.4 + i * 0.12, -0.08, height), col, segments=10, bevel=0.008)
    b.finish()


def meeting_table(width: float = 2.4, depth: float = 1.2, height: float = 0.75) -> None:
    """Toplantı masası: kalın yuvarlak kenarlı ahşap tabla, iki ayaklı sehpa, üstünde defterler ve küçük bitki."""
    b = Builder("meeting_table")
    top = 0.07
    b.box((width, depth, top), (0, 0, height - top / 2), "wood", bevel=0.03, segments=3)
    leg_h = height - top
    for x in (-width / 2 + 0.35, width / 2 - 0.35):
        b.box((0.1, depth - 0.3, 0.08), (x, 0, 0.04), "wood_dark", bevel=0.02)
        b.box((0.1, 0.12, leg_h), (x, 0, leg_h / 2), "wood_dark", bevel=0.02)
    b.box((width - 0.8, 0.06, 0.06), (0, 0, 0.2), "wood_dark", bevel=0.015, segments=1)
    for i, (x, y, col) in enumerate([(-0.7, -0.3, "pastel_blue"), (0.5, -0.32, "cream"), (-0.2, 0.33, "mustard"),
                                     (0.8, 0.3, "pastel_pink")]):
        b.box((0.24, 0.3, 0.02), (x, y, height + 0.01), col, bevel=0.005, segments=1, rot_z=0.15 * (i - 1.5))
    b.finish()


def sofa(width: float = 3.0, depth: float = 0.8, height: float = 0.55) -> None:
    """Üç kişilik alçak kanepe: adaçayı kumaş, tombul minderler, kolçaklar, ahşap ayaklar. Oturan -Y'ye bakar."""
    b = Builder("sofa")
    leg = 0.08
    for x in (-width / 2 + 0.12, width / 2 - 0.12):
        for y in (-depth / 2 + 0.1, depth / 2 - 0.1):
            b.cylinder(0.03, 0.022, leg, (x, y, 0), "wood_dark", segments=8, bevel=0.0)
    b.box((width - 0.04, depth - 0.04, 0.16), (0, 0, leg + 0.08), "sage", bevel=0.04)
    arm = 0.16
    for x in (-width / 2 + arm / 2, width / 2 - arm / 2):
        b.box((arm, depth, 0.3), (x, 0, leg + 0.15), "sage", bevel=0.06, segments=3)
    inner = width - 2 * arm
    for i in range(3):
        x = -inner / 2 + inner / 6 * (2 * i + 1)
        b.box((inner / 3 - 0.02, depth - 0.24, 0.12), (x, -0.08, leg + 0.22), "pot_sage", bevel=0.05, segments=3)
        b.box((inner / 3 - 0.02, 0.2, height - leg - 0.16), (x, depth / 2 - 0.12, leg + 0.16 + (height - leg - 0.16) / 2),
              "pot_sage", bevel=0.06, segments=3, rot_x=-0.1)
    b.box((0.3, 0.12, 0.26), (-inner / 3, -0.02, leg + 0.38), "mustard", bevel=0.05, segments=3, rot_x=-0.3, rot_z=0.2)
    b.finish()


# --- bilgisayarlar (equipment/) ------------------------------------------------

def _keyboard(b: Builder, y: float, width: float, color: str, keys: str) -> None:
    b.box((width, 0.13, 0.025), (0, y, 0.0125), color, bevel=0.008, segments=1)
    b.box((width - 0.04, 0.09, 0.008), (0, y + 0.005, 0.028), keys, bevel=0.002, segments=1)


def pc386() -> None:
    """1990'lar: bej tüplü monitör ve kalın klavye."""
    b = Builder("pc386")
    b.box((0.3, 0.26, 0.05), (0, 0.08, 0.025), "beige_pc", bevel=0.012)
    b.box((0.36, 0.2, 0.32), (0, 0.03, 0.05 + 0.16), "beige_pc", bevel=0.025, segments=3)
    b.box((0.28, 0.12, 0.24), (0, 0.15, 0.05 + 0.14), "beige_pc", bevel=0.03, segments=2)
    b.box((0.29, 0.02, 0.22), (0, -0.07, 0.22), "screen", bevel=0.012)
    b.box((0.04, 0.01, 0.01), (0.12, -0.075, 0.075), "leaf_light", bevel=0.003, segments=1)
    _keyboard(b, -0.155, 0.42, "beige_pc", "wall_cream")
    b.finish()


def g4() -> None:
    """2000'ler: renkli yarı saydam görünümlü, tombul hepsi-bir-arada bilgisayar."""
    b = Builder("g4")
    b.box((0.36, 0.3, 0.32), (0, 0.06, 0.07 + 0.16), "teal_glass", bevel=0.08, segments=4)
    b.box((0.3, 0.04, 0.26), (0, -0.09, 0.24), "white_soft", bevel=0.03, segments=3)
    b.box((0.24, 0.02, 0.18), (0, -0.11, 0.25), "screen", bevel=0.01)
    b.box((0.16, 0.16, 0.07), (0, 0.06, 0.035), "white_soft", bevel=0.02)
    _keyboard(b, -0.155, 0.36, "white_soft", "teal_glass")
    b.finish()


def imak() -> None:
    """2010'lar: ince beyaz hepsi-bir-arada ekran, gümüş ayak."""
    b = Builder("imak")
    b.box((0.2, 0.16, 0.012), (0, 0.0, 0.006), "steel", bevel=0.004, segments=1)
    b.box((0.08, 0.02, 0.16), (0, 0.04, 0.09), "steel", bevel=0.006, rot_x=0.15)
    b.box((0.55, 0.03, 0.33), (0, 0.0, 0.12 + 0.165), "white_soft", bevel=0.012)
    b.box((0.51, 0.006, 0.25), (0, -0.016, 0.31), "screen_glow", bevel=0.002, segments=1)
    b.box((0.55, 0.031, 0.06), (0, 0.0, 0.15), "white_soft", bevel=0.01)
    b.finish()


def mchip() -> None:
    """2020'ler: açık gümüş dizüstü ve yanında küçük ikinci ekran."""
    b = Builder("mchip")
    lx = -0.15
    b.box((0.3, 0.21, 0.014), (lx, -0.03, 0.007), "steel", bevel=0.005, segments=1)
    b.box((0.26, 0.12, 0.004), (lx, -0.01, 0.016), "charcoal", bevel=0.001, segments=1)
    b.box((0.3, 0.012, 0.2), (lx, 0.085, 0.1), "steel", bevel=0.005, segments=1, rot_x=-0.25)
    b.box((0.27, 0.003, 0.17), (lx, 0.077, 0.1), "screen_glow", bevel=0.001, segments=1, rot_x=-0.25)
    mx = 0.17
    b.box((0.14, 0.12, 0.01), (mx, 0.06, 0.005), "charcoal", bevel=0.004, segments=1)
    b.box((0.03, 0.02, 0.14), (mx, 0.08, 0.08), "charcoal", bevel=0.005, segments=1)
    b.box((0.26, 0.02, 0.17), (mx, 0.06, 0.32 - 0.085), "charcoal", bevel=0.008)
    b.box((0.24, 0.004, 0.15), (mx, 0.048, 0.32 - 0.085), "screen_glow", bevel=0.001, segments=1)
    b.cylinder(0.035, 0.03, 0.08, (0.05, -0.1, 0), "mustard", segments=10, bevel=0.006)
    b.finish()
