"""Saçlar ve kıyafetler (C3, data/characters.json "hair" ve "outfits").

Saç: başa oturan sert parça (iskelet yok); oyun `head` kemiğine bağlar. Hepsi "hair" malzemesinde, rengini oyun verir.

Kıyafet: gövdenin tişörtünü tamamen örten, gövdeyle aynı ağırlıklarla bükülen kabuk. Her gövde (kadın/erkek/nötr)
için ayrı kabuk aynı dosyada durur (nesne adı `outfit_<ad>_<gövde>`); oyun çalışanın gövdesine uyanı seçer.
"outfit" malzemesi çalışanın kıyafet rengini alır; yaka, düğme, kravat gibi ayrıntılar paletten sabit renk.
"""

import json
import math
import os
import random

import bmesh
import bpy
from mathutils import Vector

from characters import ARM_X, BELT, FPS, LEG_X, RigBuilder, _smooth, _torso_weights, armature, bind, torso_rings
from common import ROOT

HEAD = Vector((0.0, 0.0, 1.525))
O = ("outfit", "white_soft")  # oyunun boyadığı kumaş


# --- saç -------------------------------------------------------------------------

def _cap(b: RigBuilder, keep, radius: float = 0.192, scale=(1.04, 1.02, 1.0), center=(0.0, 0.006, 1.54),
         subdiv: int = 3) -> None:
    """Başı saran küreden keep(co) dışında kalanları siler."""
    bm = b.bm
    old = set(bm.faces)
    verts = bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=radius)["verts"]
    for v in verts:
        v.co = Vector((v.co.x * scale[0] + center[0], v.co.y * scale[1] + center[1], v.co.z * scale[2] + center[2]))
    bmesh.ops.delete(bm, geom=[v for v in verts if not keep(v.co)], context="VERTS")
    b._assign([f for f in bm.faces if f not in old], "hair", lambda v: {"head": 1.0})


def _short_keep(c) -> bool:
    return not (c.z < 1.43 or (c.y < -0.07 and c.z < 1.6) or (abs(c.x) > 0.12 and c.y < 0.02 and c.z < 1.52))


def _hair_blob(b: RigBuilder, r: float, center, squash=(1.0, 1.0, 1.0), subdiv: int = 2) -> None:
    b.part(b.blob, "head", "hair", r, center, subdiv=subdiv, squash=squash, wobble=0.0)


def _hair(name: str, fn):
    def build() -> None:
        b = RigBuilder("hair_" + name)
        fn(b)
        obj = b.finish()
        obj.vertex_groups.clear()  # sert parça: iskelet yok
    return build


def hair_short(b) -> None:
    _cap(b, _short_keep)
    _hair_blob(b, 0.06, (0.04, -0.13, 1.64), (1.6, 0.8, 0.6))


def hair_buzz(b) -> None:
    _cap(b, lambda c: not (c.z < 1.46 or (c.y < -0.06 and c.z < 1.62) or (abs(c.x) > 0.1 and c.y < 0.03
                                                                          and c.z < 1.55)),
         radius=0.184, scale=(1.02, 1.0, 1.0), center=(0.0, 0.004, 1.535))


def hair_side_part(b) -> None:
    _cap(b, _short_keep)
    _hair_blob(b, 0.09, (0.06, -0.07, 1.68), (1.5, 1.1, 0.5))
    _hair_blob(b, 0.05, (0.13, -0.1, 1.62), (0.8, 1.0, 1.0))


def _bob_keep(bottom: float):
    return lambda c: not (c.z < bottom or (c.y < -0.085 and c.z < 1.6 and abs(c.x) < 0.145))


def hair_bob(b) -> None:
    _cap(b, _bob_keep(1.4), radius=0.2, scale=(1.08, 1.05, 1.12), center=(0.0, 0.01, 1.53))
    _hair_blob(b, 0.07, (0.0, -0.15, 1.63), (2.1, 0.7, 0.5))


def hair_long(b) -> None:
    _cap(b, _bob_keep(1.38), radius=0.2, scale=(1.08, 1.05, 1.12), center=(0.0, 0.01, 1.53))
    _hair_blob(b, 0.07, (0.03, -0.15, 1.63), (2.1, 0.7, 0.5))
    _hair_blob(b, 0.16, (0.0, 0.1, 1.3), (1.05, 0.45, 1.35))


def hair_bun(b) -> None:
    _cap(b, lambda c: not (c.z < 1.45 or (c.y < -0.08 and c.z < 1.62) or (abs(c.x) > 0.125 and c.y < 0.0
                                                                          and c.z < 1.5)))
    _hair_blob(b, 0.07, (0.0, 0.1, 1.7))
    b.part(b.cylinder, "head", "palette", 0.045, 0.045, 0.02, (0.0, 0.085, 1.645), "terracotta", segments=12,
           bevel=0.0)


def hair_curly(b) -> None:
    _cap(b, _short_keep, radius=0.188)
    rng = random.Random(7)
    n = 70
    for i in range(n):
        # Fibonacci küresi: eşit dağılmış noktalar; yüz ve ense altına konmaz
        z = 1.0 - 2.0 * (i + 0.5) / n
        a = math.pi * (3.0 - math.sqrt(5.0)) * i
        p = HEAD + Vector((math.cos(a) * math.sqrt(1 - z * z), math.sin(a) * math.sqrt(1 - z * z), z)) * 0.2
        p.z += 0.02
        if _short_keep(p) and p.z > 1.44:
            _hair_blob(b, rng.uniform(0.042, 0.055), tuple(p), subdiv=1)


def hair_mullet(b) -> None:
    _cap(b, _short_keep)
    _hair_blob(b, 0.06, (0.0, -0.13, 1.64), (1.8, 0.8, 0.55))
    _hair_blob(b, 0.12, (0.0, 0.11, 1.39), (1.1, 0.5, 1.05))


def hair_man_bun(b) -> None:
    _cap(b, lambda c: not (c.z < 1.45 or (c.y < -0.09 and c.z < 1.63) or (abs(c.x) > 0.12 and c.y < 0.01
                                                                          and c.z < 1.5)),
         radius=0.186, scale=(1.03, 1.01, 1.0))
    _hair_blob(b, 0.052, (0.0, 0.13, 1.66))


HAIRS = {"short": hair_short, "buzz": hair_buzz, "side_part": hair_side_part, "bob": hair_bob, "long": hair_long,
         "bun": hair_bun, "curly": hair_curly, "mullet": hair_mullet, "man_bun": hair_man_bun}


# --- kıyafet yardımcıları ---------------------------------------------------------------

def _ring_at(rings, z: float):
    for (z0, w0, d0), (z1, w1, d1) in zip(rings, rings[1:]):
        if z0 <= z <= z1:
            t = (z - z0) / (z1 - z0)
            return (z, w0 + (w1 - w0) * t, d0 + (d1 - d0) * t)
    return rings[0] if z < rings[0][0] else rings[-1]


def _shell(b, kind: str, bottom: float, inflate: float = 0.014, mat=O, top: float = 1.34, bulge=None) -> None:
    """Gövde kabuğu: bottom'dan boyna. bulge(z) → ek şişkinlik (kapitone yelek gibi)."""
    rings = torso_rings(kind, inflate)
    zs = [bottom] + [z for z, _, _ in rings if bottom < z < top]
    out = []
    for z in zs:
        _, w, d = _ring_at(rings, z)
        k = bulge(z) if bulge else 0.0
        out.append((z, w + k, d + k, mat[0], mat[1]))
    b.loft(out, _torso_weights)


def _front(kind: str, z: float, inflate: float) -> float:
    """Kabuğun o yükseklikteki ön yüzü (y, eksi)."""
    return -_ring_at(torso_rings(kind, inflate), z)[2]


def _sleeves(b, length: str, mat=O, r: float = 0.066, cuff=None) -> None:
    """length: short (dirseğe kadar), long (bileğe), rolled (kıvrık, ön kolun yarısı)."""
    for s, x in (("l", 1.0), ("r", -1.0)):
        ax = x * ARM_X
        up, fo = "upper_arm_" + s, "forearm_" + s
        b.part(b.blob, up, mat[0], r, (ax - x * 0.01, 0, 1.245), mat[1], subdiv=2, wobble=0.0)
        if length == "short":
            b.part(b.cylinder, up, mat[0], r * 1.05, r * 0.95, 0.2, (ax, 0, 1.05), mat[1], segments=14, bevel=0.01)
            continue
        b.part(b.cylinder, up, mat[0], r * 0.92, r * 0.95, 0.22, (ax, 0, 1.04), mat[1], segments=14, bevel=0.0)
        b.part(b.blob, fo, mat[0], r * 0.88, (ax, 0, 1.04), mat[1], subdiv=2, wobble=0.0)
        low = 0.83 if length == "long" else 0.93
        b.part(b.cylinder, fo, mat[0], r * 0.8, r * 0.86, 1.04 - low, (ax, 0, low), mat[1], segments=14, bevel=0.0)
        if length == "rolled":
            b.part(b.cylinder, fo, mat[0], r * 0.92, r * 0.92, 0.035, (ax, 0, low - 0.01), mat[1], segments=14,
                   bevel=0.01)
        elif cuff:
            b.part(b.cylinder, fo, "palette", r * 0.84, r * 0.84, 0.025, (ax, 0, low), cuff, segments=14, bevel=0.0)


def _collar(b, color=None, height: float = 0.05, r: float = 0.083) -> None:
    mat = ("palette", color) if color else O
    b.loft([(1.305, r, r * 0.9, *mat), (1.305 + height, r * 0.88, r * 0.8, *mat)], lambda v: {"chest": 1.0},
           segments=16, power=2.0)


def _buttons(b, kind: str, zs, inflate: float, color: str = "white_soft", x: float = 0.0) -> None:
    for z in zs:
        b.part(b.blob, "chest" if z > 1.1 else "spine", "palette", 0.011, (x, _front(kind, z, inflate) - 0.003, z),
               color, subdiv=1, squash=(1.0, 0.5, 1.0), wobble=0.0)


def _strip(b, kind: str, z0: float, z1: float, width: float, inflate: float, color: str, bone="chest") -> None:
    """Önde dik şerit (açık önden görünen iç gömlek, fermuar…)."""
    zm = (z0 + z1) / 2
    y = min(_front(kind, z0, inflate), _front(kind, z1, inflate), _front(kind, zm, inflate)) - 0.002
    b.part(b.box, bone, "palette", (width, 0.006, z1 - z0), (0, y, zm), color, bevel=0.002, segments=1)


def _tie(b, kind: str, inflate: float, color: str = "red") -> None:
    y = _front(kind, 1.2, inflate) - 0.008
    b.part(b.box, "chest", "palette", (0.04, 0.01, 0.2), (0, y, 1.16), color, bevel=0.004, segments=1)
    b.part(b.box, "chest", "palette", (0.035, 0.014, 0.03), (0, y - 0.004, 1.275), color, bevel=0.006, segments=1)


def _pants(b, mat=O, r: float = 0.088) -> None:
    for s, x in (("l", 1.0), ("r", -1.0)):
        lx = x * LEG_X
        b.part(b.cylinder, "thigh_" + s, mat[0], r, r * 0.9, 0.4, (lx, 0, 0.47), mat[1], segments=14, bevel=0.0)
        b.part(b.blob, "shin_" + s, mat[0], r * 0.9, (lx, 0, 0.47), mat[1], subdiv=2, wobble=0.0)
        b.part(b.cylinder, "shin_" + s, mat[0], r * 0.86, r * 0.84, 0.36, (lx, 0, 0.11), mat[1], segments=14,
               bevel=0.0)


def _skirt_weights(v) -> dict:
    k = _smooth((0.88 - v.co.z) / 0.3)
    if abs(v.co.x) < 0.02:
        return {"hips": 1.0 - k, "thigh_l": k / 2, "thigh_r": k / 2}
    return {"hips": 1.0 - k, ("thigh_l" if v.co.x > 0 else "thigh_r"): k}


# --- kıyafetler ---------------------------------------------------------------------

def outfit_shoulder_pad_blazer(b, kind: str) -> None:
    e = 0.018
    _shell(b, kind, 0.84, e)
    _sleeves(b, "long", r=0.07)
    for x in (1.0, -1.0):  # vatka
        b.part(b.box, "chest", "outfit", (0.13, 0.15, 0.045), (x * 0.19, 0, 1.3), color="white_soft", bevel=0.02,
               segments=2)
    _strip(b, kind, 1.12, 1.31, 0.07, e, "white_soft")
    _buttons(b, kind, (1.05, 0.96), e, "brass", x=0.03)


def outfit_pleated_suit(b, kind: str) -> None:
    e = 0.016
    _shell(b, kind, 0.8, e)
    _sleeves(b, "long", cuff="white_soft")
    _pants(b)
    _strip(b, kind, 1.08, 1.31, 0.08, e, "white_soft")
    _tie(b, kind, e, "terracotta_dark")
    _buttons(b, kind, (1.02, 0.94), e, "ink", x=0.03)


def outfit_sweater_vest(b, kind: str) -> None:
    _shell(b, kind, 0.95, 0.008, ("palette", "white_soft"))
    _sleeves(b, "long", ("palette", "white_soft"), r=0.064)
    _collar(b, "white_soft")
    _shell(b, kind, 0.92, 0.02, top=1.27)
    _strip(b, kind, 1.17, 1.27, 0.05, 0.02, "white_soft")
    _tie(b, kind, 0.02, "ink")


def outfit_denim_jacket(b, kind: str) -> None:
    e = 0.02
    _shell(b, kind, 0.9, e)
    _sleeves(b, "long", r=0.07, cuff="ink")
    _collar(b, None, 0.045, 0.092)
    _strip(b, kind, 0.92, 1.3, 0.06, e, "white_soft")
    for x in (1.0, -1.0):
        b.part(b.box, "chest", "outfit", (0.075, 0.012, 0.07), (x * 0.09, _front(kind, 1.2, e) - 0.004, 1.2),
               color="white_soft", bevel=0.004, segments=1)
        b.part(b.blob, "chest", "palette", 0.008, (x * 0.09, _front(kind, 1.22, e) - 0.012, 1.22), "brass",
               subdiv=1, wobble=0.0)


def outfit_polo(b, kind: str) -> None:
    e = 0.012
    _shell(b, kind, 0.93, e)
    _sleeves(b, "short", cuff=None)
    _collar(b, None, 0.035, 0.088)
    _buttons(b, kind, (1.27, 1.23), e)


def outfit_office_shirt(b, kind: str) -> None:
    e = 0.012
    _shell(b, kind, 0.93, e)
    _sleeves(b, "rolled", r=0.063)
    _collar(b, None, 0.05)
    _buttons(b, kind, (1.26, 1.19, 1.12, 1.05, 0.98), e)


def outfit_cardigan(b, kind: str) -> None:
    e = 0.018
    _shell(b, kind, 0.88, e)
    _sleeves(b, "long", r=0.068)
    _strip(b, kind, 0.89, 1.31, 0.075, e, "cream")
    _buttons(b, kind, (1.15, 1.05, 0.95), e, "wood_dark", x=0.045)


def outfit_hipster_flannel(b, kind: str) -> None:
    e = 0.014
    _shell(b, kind, 0.9, e)
    _sleeves(b, "rolled", r=0.065)
    _collar(b, None, 0.045)
    for z in (0.95, 1.05, 1.15, 1.24):  # ekose hissi: koyu yatay şeritler
        _, w, d = _ring_at(torso_rings(kind, e + 0.003), z)
        b.loft([(z, w, d, "palette", "ink"), (z + 0.018, w, d, "palette", "ink")], _torso_weights)
    for x in (1.0, -1.0):
        b.part(b.cylinder, "upper_arm_" + ("l" if x > 0 else "r"), "palette", 0.064, 0.064, 0.018,
               (x * ARM_X, 0, 1.12), "ink", segments=14, bevel=0.0)
    _buttons(b, kind, (1.2, 1.1, 1.0), e, "ink")


def outfit_hoodie(b, kind: str) -> None:
    e = 0.02
    _shell(b, kind, 0.86, e)
    _sleeves(b, "long", r=0.07)
    b.part(b.blob, "chest", "outfit", 0.14, (0, 0.11, 1.34), color="white_soft", subdiv=2, squash=(1.2, 0.6, 0.55),
           wobble=0.0)
    b.part(b.box, "spine", "outfit", (0.22, 0.02, 0.1), (0, _front(kind, 0.98, e) - 0.006, 0.98), color="white_soft",
           bevel=0.01, segments=2)
    for x in (0.04, -0.04):
        b.part(b.box, "chest", "palette", (0.008, 0.008, 0.1), (x, _front(kind, 1.22, e) - 0.008, 1.22),
               "white_soft", bevel=0.003, segments=1)


def outfit_oversize_tee(b, kind: str) -> None:
    e = 0.03
    _shell(b, kind, 0.83, e)
    _sleeves(b, "short", r=0.08)


def outfit_dress(b, kind: str) -> None:
    e = 0.014
    _shell(b, kind, BELT, e)
    _sleeves(b, "short", r=0.066)
    rings = torso_rings(kind, e)
    _, w, d = _ring_at(rings, BELT + 0.01)
    _, hw, hd = _ring_at(rings, 0.94)
    b.loft([(0.52, hw + 0.1, hd + 0.08, *O), (0.7, hw + 0.06, hd + 0.05, *O), (0.86, hw + 0.025, hd + 0.02, *O),
            (BELT + 0.01, w, d, *O)], _skirt_weights)
    _pants(b, ("skin", "white_soft"), r=0.084)  # çorapsız bacak: kotu örter
    b.part(b.box, "spine", "palette", (0.2, 0.01, 0.025), (0, _front(kind, 1.0, e) - 0.004, 1.0), "cream",
           bevel=0.006, segments=1)


def outfit_tech_vest(b, kind: str) -> None:
    _shell(b, kind, 0.93, 0.008, ("palette", "pastel_blue"))
    _sleeves(b, "long", ("palette", "pastel_blue"), r=0.064)
    _collar(b, "pastel_blue", 0.04)
    _shell(b, kind, 0.9, 0.024, top=1.3, bulge=lambda z: 0.008 * (0.5 + 0.5 * math.cos((z - 0.9) / 0.075 * math.tau)))
    _strip(b, kind, 0.91, 1.28, 0.012, 0.034, "charcoal")


OUTFITS = {name[len("outfit_"):]: fn for name, fn in globals().items() if name.startswith("outfit_") and callable(fn)}


def _bodies_of(outfit_id: str) -> list:
    with open(os.path.join(ROOT, "data", "characters.json"), encoding="utf-8") as f:
        data = json.load(f)
    for o in data["outfits"]:
        if o["id"] == outfit_id:
            return list(o["bodies"])
    return ["female", "male", "neutral"]


def _outfit(name: str, fn):
    def build() -> None:
        bpy.context.scene.render.fps = FPS
        arm = armature()
        for kind in _bodies_of(name):
            b = RigBuilder("outfit_%s_%s" % (name, kind))
            fn(b, kind)
            bind(b.finish(), arm)
    return build


TARGETS = {}
for _n, _f in HAIRS.items():
    TARGETS["hair_" + _n] = ("characters/hair_%s.glb" % _n, _hair(_n, _f))
for _n, _f in OUTFITS.items():
    TARGETS["outfit_" + _n] = ("characters/outfit_%s.glb" % _n, _outfit(_n, _f))
