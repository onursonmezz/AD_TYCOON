"""Karakterler (C1, art/pipeline.md "Karakterler"): ortak iskelet, 3 gövde, saç ve hareketler.

Üç gövde aynı iskeleti ve aynı kol/bacak ölçülerini kullanır; yalnızca gövde, omuz ve kalça şekli değişir.
Böylece her kıyafet ve saç üç gövdeye de oturur, bir animasyon seti hepsinde çalışır.

Renk: ten "skin", kıyafet "outfit", saç "hair" adlı beyaz malzemelere boyanır; oyun bu malzemelerin rengini
çalışana göre değiştirir (CharacterRig). Gözler, pantolon ve ayakkabı ortak paletten sabit renk alır.

Her parça tek bir kemiğe bağlıdır (sert bağ); eklem yerlerindeki toplar bükülürken boşluğu kapatır.
Gövde (bel-göğüs) yüksekliğe göre iki kemik arasında yumuşak dağıtılır.
Ön yüz -Y, boy 1.7 m (saç hariç).
"""

import math

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

from common import Builder

FPS = 24
HEIGHT = 1.7
ARM_X = 0.22   # omuz eklemi (her gövdede aynı)
LEG_X = 0.09

# kemik: (baş, kuyruk, ebeveyn)
BONES = {
    "hips": ((0, 0, 0.86), (0, 0, 0.98), None),
    "spine": ((0, 0, 0.98), (0, 0, 1.12), "hips"),
    "chest": ((0, 0, 1.12), (0, 0, 1.30), "spine"),
    "neck": ((0, 0, 1.30), (0, 0, 1.37), "chest"),
    "head": ((0, 0, 1.37), (0, 0, 1.70), "neck"),
}
for _s, _x in (("l", 1.0), ("r", -1.0)):
    BONES.update({
        "upper_arm_" + _s: ((_x * ARM_X, 0, 1.27), (_x * ARM_X, 0, 1.04), "chest"),
        "forearm_" + _s: ((_x * ARM_X, 0, 1.04), (_x * ARM_X, 0, 0.83), "upper_arm_" + _s),
        "hand_" + _s: ((_x * ARM_X, 0, 0.83), (_x * ARM_X, 0, 0.74), "forearm_" + _s),
        "thigh_" + _s: ((_x * LEG_X, 0, 0.86), (_x * LEG_X, 0, 0.47), "hips"),
        "shin_" + _s: ((_x * LEG_X, 0, 0.47), (_x * LEG_X, 0, 0.09), "thigh_" + _s),
        "foot_" + _s: ((_x * LEG_X, 0, 0.09), (_x * LEG_X, -0.12, 0.03), "shin_" + _s),
    })
BONE_NAMES = list(BONES.keys())

# Gövde şekilleri: omuz genişliği, bel, kalça (m) ve göğüs derinliği.
BODIES = {
    "female": {"shoulders": 0.33, "waist": 0.27, "hips": 0.34, "depth": 0.2},
    "male": {"shoulders": 0.39, "waist": 0.31, "hips": 0.31, "depth": 0.22},
    "neutral": {"shoulders": 0.36, "waist": 0.29, "hips": 0.32, "depth": 0.21},
}

def _flat_material(name: str):
    """Oyunun boyayacağı beyaz malzeme (adı önemli: skin / outfit / hair)."""
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.85
    mat.diffuse_color = (1.0, 1.0, 1.0, 1.0)
    if name == "hair":
        mat.use_backface_culling = False
    return mat


class RigBuilder(Builder):
    """Builder + her parçanın malzemesi ve kemiği. Malzeme sırası: 0 palet, 1 skin, 2 outfit, 3 hair."""

    SLOTS = ["palette", "skin", "outfit", "hair"]

    def __init__(self, name: str):
        super().__init__(name)
        self.deform = self.bm.verts.layers.deform.verify()

    def part(self, fn, bone: str, mat: str = "palette", *a, **kw):
        """fn = self.box / cylinder / blob…; yeni yüzlere malzeme, yeni köşelere kemik verir."""
        if mat != "palette" and "color" not in kw:
            kw["color"] = "white_soft"  # UV önemsiz: renk oyundan gelir
        old = set(self.bm.faces)
        fn(*a, **kw)
        new = [f for f in self.bm.faces if f not in old]
        self._assign(new, mat, lambda v: {bone: 1.0})
        return new

    def loft(self, rings, weights, segments: int = 24, power: float = 3.0) -> None:
        """Halkalardan tek parça yumuşak gövde; weights(v) → {kemik: ağırlık}.
        rings: [(z, yarı genişlik, yarı derinlik, malzeme, renk)]; iki halka arasındaki yüzler alttaki halkanın
        malzemesini alır. Kesit yuvarlatılmış dikdörtgen (süperelips; power büyüdükçe köşeli). Alt ve üst kapalı."""
        bm = self.bm
        loops = []
        for z, w, d, _, _ in rings:
            ring = []
            for i in range(segments):
                a = math.tau * i / segments
                c, s = math.cos(a), math.sin(a)
                ring.append(bm.verts.new((w * math.copysign(abs(c) ** (2.0 / power), c),
                                          d * math.copysign(abs(s) ** (2.0 / power), s), z)))
            loops.append(ring)
        groups = {}
        for k in range(len(rings) - 1):
            key = (rings[k][3], rings[k][4])
            for i in range(segments):
                j = (i + 1) % segments
                f = bm.faces.new((loops[k][i], loops[k][j], loops[k + 1][j], loops[k + 1][i]))
                groups.setdefault(key, []).append(f)
        for ring, key in ((loops[0], (rings[0][3], rings[0][4])), (loops[-1], (rings[-2][3], rings[-2][4]))):
            groups.setdefault(key, []).append(bm.faces.new(ring))
        for (mat, color), faces in groups.items():
            self._paint(faces, color)
            self._assign(faces, mat, weights)

    def _assign(self, faces, mat: str, weights) -> None:
        idx = self.SLOTS.index(mat)
        verts = set()
        for f in faces:
            f.material_index = idx
            verts.update(f.verts)
        for v in verts:
            d = v[self.deform]
            d.clear()
            for b, w in weights(v).items():
                if w > 0.0:
                    d[BONE_NAMES.index(b)] = w

    def finish(self):
        obj = super().finish()
        mesh = obj.data
        for s in self.SLOTS[1:]:  # palet (0) Builder.finish'te eklendi
            mesh.materials.append(_flat_material(s))
        for b in BONE_NAMES:
            obj.vertex_groups.new(name=b)
        return obj


# --- iskelet --------------------------------------------------------------------

def armature():
    data = bpy.data.armatures.new("rig")
    arm = bpy.data.objects.new("rig", data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (head, tail, parent) in BONES.items():
        eb = data.edit_bones.new(name)
        eb.head = Vector(head)
        eb.tail = Vector(tail)
        eb.roll = 0.0
        if parent:
            eb.parent = data.edit_bones[parent]
            eb.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
    return arm


def bind(obj, arm) -> None:
    obj.parent = arm
    mod = obj.modifiers.new("rig", "ARMATURE")
    mod.object = arm


# --- gövde ----------------------------------------------------------------------

def _smooth(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


def _torso_weights(v) -> dict:
    """Bel → göğüs geçişi yumuşak; kalça bölgesi hips."""
    z = v.co.z
    if z < 0.98:
        k = _smooth((z - 0.9) / 0.12)
        return {"hips": 1.0 - k, "spine": k}
    k = _smooth((z - 1.06) / 0.14)
    return {"spine": 1.0 - k, "chest": k}


def body(kind: str):
    """Tek gövde: ten (baş, boyun, el), tişört (outfit), pantolon ve ayakkabı (palet)."""
    p = BODIES[kind]
    b = RigBuilder("body_" + kind)
    sh, wa, hi, dp = p["shoulders"], p["waist"], p["hips"], p["depth"]
    # baş: büyükçe, hafif yumurta; gözler, burun, kulaklar
    b.part(b.blob, "head", "skin", 0.178, (0, 0, 1.525), subdiv=3, squash=(1.0, 0.96, 1.0), wobble=0.0)
    for x in (-1.0, 1.0):
        b.part(b.blob, "head", "palette", 0.022, (x * 0.062, -0.158, 1.535), "ink", subdiv=1,
               squash=(0.85, 0.5, 1.15), wobble=0.0)
        b.part(b.blob, "head", "skin", 0.036, (x * 0.176, 0.005, 1.515), subdiv=1, squash=(0.5, 0.8, 1.0),
               wobble=0.0)
    b.part(b.blob, "head", "skin", 0.026, (0, -0.172, 1.49), subdiv=1, squash=(1.0, 0.9, 0.85), wobble=0.0)
    b.part(b.box, "head", "palette", (0.045, 0.01, 0.008), (0, -0.165, 1.445), "terracotta_dark", bevel=0.003,
           segments=1)
    b.part(b.cylinder, "neck", "skin", 0.05, 0.048, 0.12, (0, 0.005, 1.27), segments=12, bevel=0.0)
    # gövde: kasıktan boyna tek parça; bel çizgisinin altı pantolon, üstü tişört
    sh2, wa2, hi2, d2 = sh / 2, wa / 2, hi / 2, dp / 2
    b.loft([(0.80, 0.13, d2 * 0.75, "palette", "denim"), (0.86, hi2 * 0.97, d2 * 0.95, "palette", "denim"),
            (0.94, hi2, d2, "palette", "denim"), (0.985, (hi2 + wa2) / 2, d2 * 0.97, "outfit", "white_soft"),
            (1.06, wa2, d2 * 0.94, "outfit", "white_soft"), (1.17, sh2 * 0.94, d2, "outfit", "white_soft"),
            (1.25, sh2, d2 * 0.95, "outfit", "white_soft"), (1.3, sh2 * 0.82, d2 * 0.78, "outfit", "white_soft"),
            (1.325, sh2 * 0.45, d2 * 0.5, "outfit", "white_soft"), (1.33, 0.07, 0.06, "outfit", "white_soft")],
           _torso_weights)
    for s, x in (("l", 1.0), ("r", -1.0)):
        ax = x * ARM_X
        # omuz topu ve kol (kısa kollu): üst kol tişört, ön kol ve el ten
        b.part(b.blob, "upper_arm_" + s, "outfit", 0.06, (ax - x * 0.01, 0, 1.245), subdiv=2, wobble=0.0)
        b.part(b.cylinder, "upper_arm_" + s, "outfit", 0.058, 0.052, 0.17, (ax, 0, 1.06), segments=12,
               bevel=0.012)
        b.part(b.cylinder, "upper_arm_" + s, "skin", 0.043, 0.045, 0.06, (ax, 0, 1.02), segments=10, bevel=0.0)
        b.part(b.blob, "forearm_" + s, "skin", 0.044, (ax, 0, 1.04), subdiv=1, wobble=0.0)
        b.part(b.cylinder, "forearm_" + s, "skin", 0.036, 0.042, 0.2, (ax, 0, 0.84), segments=10, bevel=0.0)
        b.part(b.blob, "hand_" + s, "skin", 0.046, (ax, -0.005, 0.79), subdiv=2, squash=(0.65, 0.95, 1.15),
               wobble=0.0)
        b.part(b.blob, "hand_" + s, "skin", 0.018, (ax - x * 0.022, -0.035, 0.81), subdiv=1, wobble=0.0)
        # bacak: kalça topu, uyluk, diz topu, baldır, ayakkabı
        lx = x * LEG_X
        b.part(b.cylinder, "thigh_" + s, "palette", 0.078, 0.07, 0.4, (lx, 0, 0.47), "denim", segments=14,
               bevel=0.0)
        b.part(b.blob, "shin_" + s, "palette", 0.07, (lx, 0, 0.47), "denim", subdiv=2, wobble=0.0)
        b.part(b.cylinder, "shin_" + s, "palette", 0.066, 0.062, 0.38, (lx, 0, 0.09), "denim", segments=14,
               bevel=0.0)
        b.part(b.box, "foot_" + s, "palette", (0.11, 0.22, 0.09), (lx, -0.045, 0.045), "charcoal", bevel=0.035,
               segments=2)
        b.part(b.box, "foot_" + s, "palette", (0.115, 0.225, 0.02), (lx, -0.045, 0.01), "cream", bevel=0.008,
               segments=1)
    return b.finish()


def hair_short():
    """Kısa saç: başın üstünü ve arkasını saran kep, önde hafif perçem. Sert parça (baş kemiğine bağlanır)."""
    b = RigBuilder("hair_short")
    bm = b.bm
    old = set(bm.faces)
    res = bmesh.ops.create_icosphere(bm, subdivisions=3, radius=0.192)
    verts = res["verts"]
    for v in verts:
        v.co = Vector((v.co.x * 1.04, v.co.y * 1.02 + 0.006, v.co.z * 1.0 + 1.54))
    kill = [v for v in verts if v.co.z < 1.43 or (v.co.y < -0.07 and v.co.z < 1.6)
            or (abs(v.co.x) > 0.12 and v.co.y < 0.02 and v.co.z < 1.52)]
    bmesh.ops.delete(bm, geom=kill, context="VERTS")
    b._assign([f for f in bm.faces if f not in old], "hair", lambda v: {"head": 1.0})
    b.part(b.blob, "head", "hair", 0.06, (0.04, -0.13, 1.64), subdiv=2, squash=(1.6, 0.8, 0.6), wobble=0.0)
    obj = b.finish()
    # sert parça: iskelet yok, ağırlık grupları gereksiz
    obj.vertex_groups.clear()
    return obj


# --- hareketler -------------------------------------------------------------------

def _rest3(arm, name: str) -> Matrix:
    return arm.data.bones[name].matrix_local.to_3x3()


def _pose(arm, frame: int, rot: dict, hips=(0.0, 0.0, 0.0)) -> None:
    """rot: kemik → (x, y, z) derece, dinlenme anındaki dünya eksenlerine göre (ebeveynle birlikte döner).
    Anahtarlanmayan kemik dinlenme hâlinde anahtarlanır ki klipler birbirine sızmasın."""
    for name in BONE_NAMES:
        pb = arm.pose.bones[name]
        m = _rest3(arm, name)
        e = rot.get(name, (0.0, 0.0, 0.0))
        r = Euler((math.radians(e[0]), math.radians(e[1]), math.radians(e[2])), "XYZ").to_matrix()
        pb.rotation_quaternion = (m.inverted() @ r @ m).to_quaternion()
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        if name == "hips":
            pb.location = m.inverted() @ Vector(hips)
            pb.keyframe_insert("location", frame=frame)


def _action(arm, name: str, keys) -> None:
    """keys: [(kare, rot, hips)]; eylemi NLA'ya iter ki dışa aktarıcı ayrı klip olarak yazsın."""
    act = bpy.data.actions.new(name)
    arm.animation_data_create()
    arm.animation_data.action = act
    for frame, rot, hips in keys:
        _pose(arm, frame, rot, hips)
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


ARMS_DOWN = {"upper_arm_l": (0, -4, 0), "upper_arm_r": (0, 4, 0)}


def _with(base: dict, **extra) -> dict:
    out = dict(base)
    out.update(extra)
    return out


def anim_idle(arm) -> None:
    """Bekle: hafif nefes, baş yavaşça döner (2 sn)."""
    a = _with(ARMS_DOWN, chest=(-1.5, 0, 0), head=(2, 0, -4))
    b = _with(ARMS_DOWN, chest=(1.5, 0, 0), head=(-1, 0, 4), upper_arm_l=(2, -5, 0), upper_arm_r=(2, 5, 0))
    _action(arm, "idle", [(1, a, (0, 0, 0)), (25, b, (0, 0, -0.008)), (49, a, (0, 0, 0))])


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


SIT_HIPS = (0.0, 0.03, -0.3)


def _sit_base(**extra) -> dict:
    base = {"thigh_l": (-88, 0, -3), "thigh_r": (-88, 0, 3), "shin_l": (86, 0, 0), "shin_r": (86, 0, 0),
            "upper_arm_l": (-10, -6, 0), "upper_arm_r": (-10, 6, 0), "forearm_l": (-55, 0, 0),
            "forearm_r": (-55, 0, 0)}
    base.update(extra)
    return base


def anim_sit(arm) -> None:
    """Otur: kalça sandalye minderine iner (~0.56 m), eller kucakta, hafif nefes (2 sn)."""
    a = _sit_base(chest=(-1, 0, 0), head=(3, 0, 0))
    b = _sit_base(chest=(1.5, 0, 0), head=(1, 0, 3))
    _action(arm, "sit", [(1, a, SIT_HIPS), (25, b, SIT_HIPS), (49, a, SIT_HIPS)])


def character(kind: str) -> None:
    """Gövde + iskelet + C1 hareketleri."""
    bpy.context.scene.render.fps = FPS
    arm = armature()
    obj = body(kind)
    bind(obj, arm)
    for fn in (anim_idle, anim_walk, anim_sit):
        fn(arm)
    # dinlenme pozuna dön (dışa aktarılan bağlama pozu)
    for pb in arm.pose.bones:
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
