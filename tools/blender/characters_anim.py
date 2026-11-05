"""Karakter hareketleri (C1 + C2): her biri ayrı Blender eylemi, oyunda ayrı klip.

Pozlar kemik → dönüş sözlüğüdür. Dönüş (x, y, z) derece ya da Matrix; her ikisi de dinlenme anındaki
dünya eksenlerine göre ve ebeveynle birlikte döner (+X öne eğer: dik kemikte baş öne, sarkan kolda kol geriye).
Eli bir noktaya götürmek için `_reach` iki kemikli basit bir uzanma hesabı yapar (omuz → dirsek → avuç).

Oturan hareketler (sit, type, phone, present, stress, sleep, cheer) sandalyede kalça ~0.56 m'dedir;
ayaktakiler (idle, walk, coffee, cheer_stand) yerdedir. Adlar data/characters.json "animations".
"""

import math

import bpy
from mathutils import Euler, Matrix, Quaternion, Vector

from characters import BONE_NAMES, BONES, PROPS

SIT_HIPS = (0.0, -0.08, -0.3)  # sandalye minderinin ortası (sandalye oturma noktasından 0.1 m masaya yakın)
STAND = (0.0, 0.0, 0.0)
DOWN = Vector((0, 0, -1))
UPPER = 0.23          # omuz → dirsek
FORE = 0.21 + 0.045   # dirsek → avuç ortası
HIDDEN = 0.001        # eşya kemiğinin gizli ölçeği


# --- poz yardımcıları --------------------------------------------------------------

def _mat(value) -> Matrix:
    if isinstance(value, Matrix):
        return value
    if isinstance(value, Quaternion):
        return value.to_matrix()
    return Euler(tuple(math.radians(v) for v in value), "XYZ").to_matrix()


def _world(rot: dict, hips, bone: str) -> Matrix:
    """Kemiğin dünyadaki (4x4) dönüşümü; ebeveyn zinciri boyunca."""
    head, _, parent = BONES[bone]
    h = Vector(head)
    local = Matrix.Translation(h) @ _mat(rot.get(bone, (0, 0, 0))).to_4x4() @ Matrix.Translation(-h)
    if parent is None:
        return Matrix.Translation(Vector(hips)) @ local
    return _world(rot, hips, parent) @ local


def _reach(rot: dict, hips, side: str, target, pole) -> None:
    """side kolunun avucunu target'a (dünya, m) götürür; dirsek pole yönüne bükülür. rot'u değiştirir."""
    up, fo = "upper_arm_" + side, "forearm_" + side
    chest = _world(rot, hips, "chest")
    s = chest @ Vector(BONES[up][0])
    t = Vector(target)
    d_vec = t - s
    d = max(abs(UPPER - FORE) + 1e-3, min(d_vec.length, UPPER + FORE - 1e-3))
    u = d_vec.normalized()
    p = Vector(pole)
    p = (p - u * p.dot(u)).normalized()
    x = (UPPER * UPPER - FORE * FORE + d * d) / (2.0 * d)
    elbow = s + u * x + p * math.sqrt(max(UPPER * UPPER - x * x, 0.0))
    hand = s + u * d
    rp = chest.to_3x3()
    r_up = DOWN.rotation_difference(rp.inverted() @ (elbow - s).normalized()).to_matrix()
    rot[up] = r_up
    r_total = rp @ r_up
    rot[fo] = DOWN.rotation_difference(r_total.inverted() @ (hand - elbow).normalized()).to_matrix()


def _pose(arm, frame: int, rot: dict, hips, props=()) -> None:
    """Bütün kemikleri anahtarlar (anahtarsız kemik dinlenmede) ki klipler birbirine sızmasın."""
    for name in BONE_NAMES:
        pb = arm.pose.bones[name]
        m = arm.data.bones[name].matrix_local.to_3x3()
        r = _mat(rot.get(name, (0, 0, 0)))
        pb.rotation_quaternion = (m.inverted() @ r @ m).to_quaternion()
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        if name == "hips":
            pb.location = m.inverted() @ Vector(hips)
            pb.keyframe_insert("location", frame=frame)
        if name in PROPS:
            k = 1.0 if name in props else HIDDEN
            pb.scale = (k, k, k)
            pb.keyframe_insert("scale", frame=frame)


def _action(arm, name: str, keys, props=()) -> None:
    """keys: [(kare, rot, hips)]; eylemi NLA'ya iter ki dışa aktarıcı ayrı klip olarak yazsın."""
    act = bpy.data.actions.new(name)
    arm.animation_data_create()
    arm.animation_data.action = act
    for frame, rot, hips in keys:
        _pose(arm, frame, rot, hips, props)
    for fc in _fcurves(act):
        for kp in fc.keyframe_points:
            kp.interpolation = "BEZIER"
    track = arm.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, int(keys[0][0]), act)
    track.mute = True  # sahnede dinlenme pozu kalsın
    arm.animation_data.action = None


def _fcurves(act):
    if hasattr(act, "fcurves") and len(getattr(act, "fcurves", [])) > 0:
        return act.fcurves
    out = []
    for layer in getattr(act, "layers", []):
        for strip in layer.strips:
            for bag in strip.channelbags:
                out.extend(bag.fcurves)
    return out


def _with(base: dict, **extra) -> dict:
    out = dict(base)
    out.update(extra)
    return out


ARMS_DOWN = {"upper_arm_l": (0, -4, 0), "upper_arm_r": (0, 4, 0)}


def _sit(**extra) -> dict:
    """Oturuş: uyluklar yatay, baldırlar dik, eller kucakta."""
    base = {"thigh_l": (-88, 0, -3), "thigh_r": (-88, 0, 3), "shin_l": (86, 0, 0), "shin_r": (86, 0, 0),
            "upper_arm_l": (-10, -6, 0), "upper_arm_r": (-10, 6, 0), "forearm_l": (-55, 0, 0),
            "forearm_r": (-55, 0, 0)}
    base.update(extra)
    return base


def _hands(rot: dict, hips, left=None, right=None, pole_l=(1, 0.3, -1), pole_r=(-1, 0.3, -1)) -> dict:
    out = dict(rot)
    if left is not None:
        _reach(out, hips, "l", left, pole_l)
    if right is not None:
        _reach(out, hips, "r", right, pole_r)
    return out


def _loop(name: str, arm, poses, hips, props=(), step: int = 12) -> None:
    """poses'ı eşit aralıklarla anahtarlar ve ilk poza döner (döngü)."""
    keys = [(1 + i * step, p, hips) for i, p in enumerate(poses)]
    keys.append((1 + len(poses) * step, poses[0], hips))
    _action(arm, name, keys, props)


# --- hareketler ------------------------------------------------------------------

def anim_idle(arm) -> None:
    """Bekle: hafif nefes, baş yavaşça döner (2 sn)."""
    a = _with(ARMS_DOWN, chest=(-1.5, 0, 0), head=(2, 0, -4))
    b = _with(ARMS_DOWN, chest=(1.5, 0, 0), head=(-1, 0, 4), upper_arm_l=(2, -5, 0), upper_arm_r=(2, 5, 0))
    _action(arm, "idle", [(1, a, STAND), (25, b, (0, 0, -0.008)), (49, a, STAND)])


def anim_walk(arm) -> None:
    """Yürü: 1.6 m/sn'de iki adım ~0.67 sn (16 kare). Kollar bacakların tersine sallanır."""
    def step(sign: float) -> dict:
        return {
            "thigh_l": (-26 * sign, 0, 0), "thigh_r": (26 * sign, 0, 0),
            "shin_l": (8 if sign > 0 else 30, 0, 0), "shin_r": (30 if sign > 0 else 8, 0, 0),
            "foot_l": (8 * sign, 0, 0), "foot_r": (-8 * sign, 0, 0),
            "upper_arm_l": (22 * sign, -4, 0), "upper_arm_r": (-22 * sign, 4, 0),
            "forearm_l": (-12, 0, 0), "forearm_r": (-12, 0, 0),
            "chest": (-3, 0, 5 * sign), "head": (2, 0, -3 * sign), "hips": (0, 0, -4 * sign),
        }

    def mid(sign: float) -> dict:
        return {
            "thigh_l": (-4 * sign, 0, 0), "thigh_r": (4 * sign, 0, 0),
            "shin_l": (6 if sign > 0 else 38, 0, 0), "shin_r": (38 if sign > 0 else 6, 0, 0),
            "upper_arm_l": (4 * sign, -4, 0), "upper_arm_r": (-4 * sign, 4, 0),
            "forearm_l": (-14, 0, 0), "forearm_r": (-14, 0, 0), "chest": (-3, 0, 0),
        }

    _action(arm, "walk", [(1, step(1), (0, 0, -0.025)), (5, mid(1), (0, 0, 0.012)),
                          (9, step(-1), (0, 0, -0.025)), (13, mid(-1), (0, 0, 0.012)),
                          (17, step(1), (0, 0, -0.025))])


def anim_sit(arm) -> None:
    """Otur: kalça sandalye minderine iner (~0.56 m), eller kucakta, hafif nefes (2 sn)."""
    a = _sit(chest=(-1, 0, 0), head=(3, 0, 0))
    b = _sit(chest=(1.5, 0, 0), head=(1, 0, 3))
    _action(arm, "sit", [(1, a, SIT_HIPS), (25, b, SIT_HIPS), (49, a, SIT_HIPS)])


def anim_type(arm) -> None:
    """Yaz: öne eğik, eller masadaki klavyede sırayla iner kalkar (0.5 sn)."""
    base = _sit(spine=(4, 0, 0), chest=(6, 0, 0), head=(8, 0, 0))
    y, z = -0.5, 0.8
    poses = [
        _hands(base, SIT_HIPS, (0.11, y, z + 0.025), (-0.11, y - 0.01, z)),
        _hands(_with(base, head=(9, 0, 1)), SIT_HIPS, (0.12, y - 0.01, z), (-0.1, y, z + 0.025)),
        _hands(base, SIT_HIPS, (0.1, y, z + 0.02), (-0.12, y + 0.01, z)),
        _hands(_with(base, head=(7, 0, -1)), SIT_HIPS, (0.11, y + 0.01, z), (-0.11, y, z + 0.02)),
    ]
    _loop("type", arm, poses, SIT_HIPS, step=3)


def anim_phone(arm) -> None:
    """Telefon: sağ el kulakta, baş telefona eğik; sol el arada konuşurken sallanır (3 sn)."""
    base = _sit(chest=(2, 0, 0))
    ear = (-0.215, -0.095, 1.235)
    a = _hands(_with(base, head=(4, -8, 0)), SIT_HIPS, right=ear, pole_r=(-1, -0.2, -1))
    b = _hands(_with(base, head=(1, -10, 8)), SIT_HIPS, left=(0.22, -0.41, 0.86), right=ear, pole_r=(-1, -0.2, -1))
    c = _hands(_with(base, head=(5, -7, -6)), SIT_HIPS, right=ear, pole_r=(-1, -0.2, -1))
    _loop("phone", arm, [a, b, c], SIT_HIPS, props=("prop_phone",), step=24)


def anim_coffee(arm) -> None:
    """Kahve (ayakta, mutfakta): kupa göğüs hizasında, ara ara yudum; baş geriye (4 sn)."""
    base = _with(ARMS_DOWN, chest=(-1, 0, 0))
    hold = _hands(base, STAND, right=(-0.13, -0.24, 1.02), pole_r=(-1, 0.6, -1))
    hold2 = _hands(_with(base, head=(-1, 0, 5), chest=(1, 0, 0)), STAND, right=(-0.13, -0.25, 1.0),
                   pole_r=(-1, 0.6, -1))
    sip = _hands(_with(base, head=(-12, 0, 0), chest=(-3, 0, 0)), STAND, right=(-0.08, -0.21, 1.42),
                 pole_r=(-1, 0.4, -1))
    keys = [(1, hold, STAND), (30, hold2, STAND), (42, sip, STAND), (58, sip, STAND), (70, hold, STAND),
            (97, hold, STAND)]
    _action(arm, "coffee", keys, ("prop_cup",))


def anim_present(arm) -> None:
    """Sunum (toplantıda oturarak): eller açık anlatır, baş masadakilere döner (3 sn)."""
    base = _sit(chest=(3, 0, 0))
    poses = [
        _hands(_with(base, head=(0, 0, 14)), SIT_HIPS, (0.2, -0.47, 0.98), (-0.24, -0.41, 1.1)),
        _hands(_with(base, head=(2, 0, 0), chest=(3, 0, -4)), SIT_HIPS, (0.27, -0.41, 1.1), (-0.2, -0.49, 0.97)),
        _hands(_with(base, head=(0, 0, -14)), SIT_HIPS, (0.22, -0.51, 1.02), (-0.22, -0.51, 1.02)),
    ]
    _loop("present", arm, poses, SIT_HIPS, step=24)


def _cheer(arm, name: str, hips_low, hips_high, legs: dict, top: float) -> None:
    """Sevin: kollar havada iki kez yumruk sallar (2.5 sn, döngüsüz)."""
    up = _hands(_with(legs, chest=(-5, 0, 0), head=(-10, 0, 0)), hips_high, (0.3, -0.06, top), (-0.3, -0.06, top),
                (1, 0.2, 0), (-1, 0.2, 0))
    pump = _hands(_with(legs, chest=(-2, 0, 0), head=(-6, 0, 0)), hips_low, (0.27, -0.1, top - 0.13),
                  (-0.27, -0.1, top - 0.13), (1, 0.2, -0.3), (-1, 0.2, -0.3))
    keys = [(1, pump, hips_low), (7, up, hips_high), (16, pump, hips_low), (24, up, hips_high),
            (34, pump, hips_low), (46, up, hips_high), (60, up, hips_high)]
    _action(arm, name, keys)


def anim_cheer(arm) -> None:
    _cheer(arm, "cheer", SIT_HIPS, (0.0, -0.08, -0.27), _sit(), 1.25)


def anim_cheer_stand(arm) -> None:
    knees = {"thigh_l": (-14, 0, 0), "thigh_r": (-14, 0, 0), "shin_l": (24, 0, 0), "shin_r": (24, 0, 0)}
    _cheer(arm, "cheer_stand", (0.0, 0.0, -0.03), (0.0, 0.0, 0.07), knees, 1.85)


def anim_stress(arm) -> None:
    """Stres: eller başın iki yanında, baş öne düşük ve iki yana sallanır (1.5 sn)."""
    base = _sit(spine=(5, 0, 0), chest=(9, 0, 0))
    l, r = (0.17, -0.23, 1.2), (-0.17, -0.23, 1.2)
    a = _hands(_with(base, head=(14, 0, 9)), SIT_HIPS, l, r, (1, -1, -0.4), (-1, -1, -0.4))
    b = _hands(_with(base, head=(16, 0, -9)), SIT_HIPS, l, r, (1, -1, -0.4), (-1, -1, -0.4))
    _loop("stress", arm, [a, b], SIT_HIPS, step=18)


def anim_sleep(arm) -> None:
    """Uyukla: baş göğse düşmüş, kollar gevşek, yavaş derin nefes (4 sn)."""
    a = _sit(spine=(4, 0, 0), chest=(10, 0, 0), head=(32, 8, 0), forearm_l=(-40, 0, 0), forearm_r=(-40, 0, 0))
    b = _sit(spine=(5, 0, 0), chest=(14, 0, 0), head=(36, 8, 0), forearm_l=(-40, 0, 0), forearm_r=(-40, 0, 0))
    _loop("sleep", arm, [a, b], SIT_HIPS, step=48)


ALL = [anim_idle, anim_walk, anim_sit, anim_type, anim_phone, anim_coffee, anim_present, anim_cheer,
       anim_cheer_stand, anim_stress, anim_sleep]


def add_all(arm) -> None:
    for fn in ALL:
        fn(arm)
