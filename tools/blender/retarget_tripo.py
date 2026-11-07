"""Tripo (Mixamo adlı iskelet) karakterine bizim hareketlerimizi aktarır (art/ai_rehberi.md 5.4).

Yöntem: kendi iskeletimizde (characters.py) hareketleri oynatır, her karede eşlenen kemiklerin dünyadaki
dönüşünü okur ve Tripo kemiklerine aynı dönüşü verir. İki iskeletin dinlenme duruşu farklı (bizimki kollar aşağıda,
Tripo A-pozu): her kemik için dinlenme yönünü bizimkine çeviren sabit bir hizalama (C) araya girer:
    Tripo kemiğinin dünya dönüşü = bizim kemiğin dünya dönüşü @ C
Eşlenmeyen kemikler (Spine1, omuzlar, parmaklar, ayak ucu) ebeveynleriyle birlikte döner. Kalça yer değiştirmesi
boy oranıyla ölçeklenir.

Çalıştırma:
    blender --background --python tools/blender/retarget_tripo.py -- --src=art/incoming/x.glb --dst=characters/x.glb
"""

import os
import sys

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import characters  # noqa: E402
import characters_anim  # noqa: E402
from common import MODELS_DIR, ROOT, args  # noqa: E402

# bizim kemik → Tripo (Mixamo) kemiği. Bizim "l" = karakterin solu (+X).
MAP = {
    "hips": "Hips", "spine": "Spine", "chest": "Spine2", "neck": "Neck", "head": "Head",
    "upper_arm_l": "LeftArm", "forearm_l": "LeftForeArm", "hand_l": "LeftHand",
    "upper_arm_r": "RightArm", "forearm_r": "RightForeArm", "hand_r": "RightHand",
    "thigh_l": "LeftUpLeg", "shin_l": "LeftLeg", "foot_l": "LeftFoot",
    "thigh_r": "RightUpLeg", "shin_r": "RightLeg", "foot_r": "RightFoot",
}
SAMPLE_STEP = 1  # her kare


def _prefix(arm) -> str:
    for b in arm.data.bones:
        if b.name.endswith("Hips"):
            return b.name[:-4]
    raise RuntimeError("Hips kemiği yok: Mixamo adlı iskelet bekleniyor")


def _ordered(bones):
    out = []
    def walk(b):
        out.append(b)
        for c in b.children:
            walk(c)
    for b in bones:
        if b.parent is None:
            walk(b)
    return out


ARM_PARTS = ["Shoulder", "Arm", "ForeArm"]
BODY_MARGIN = 0.98  # omuz ekleminin x'inin bu oranından içerideki noktalar gövde/saç sayılır


def _release_hair(mesh, tarm, pre: str) -> None:
    """Tripo'nun otomatik ağırlıkları uzun saçın omuz hizasındaki kısmını kol kemiklerine bağlıyor; kol kalkınca saç
    sivri çıkıntılar yapıyor. Gövde genişliğinin içinde kalan (|x| < omuz eklemi) noktalardaki kol ağırlıklarını
    göğse (Spine2) aktarır. Kolun kendisi A-pozunda gövdenin dışında olduğu için etkilenmez."""
    arm_x = abs((tarm.matrix_world @ tarm.data.bones[pre + "LeftArm"].head_local).x) * BODY_MARGIN
    chest = mesh.vertex_groups.get(pre + "Spine2")
    groups = {mesh.vertex_groups[pre + side + part].index for side in ("Left", "Right") for part in ARM_PARTS
              if pre + side + part in mesh.vertex_groups}
    if chest is None or not groups:
        return
    moved = 0
    for v in mesh.data.vertices:
        if abs((mesh.matrix_world @ v.co).x) >= arm_x:
            continue
        take = 0.0
        for g in v.groups:
            if g.group in groups and g.weight > 0.0:
                take += g.weight
                mesh.vertex_groups[g.group].remove([v.index])
        if take > 0.0:
            chest.add([v.index], take, "ADD")
            moved += 1
    print("saç/gövde: %d noktanın kol ağırlığı göğse aktarıldı" % moved)


def retarget(src: str, dst: str) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)
    tarm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
    for o in list(bpy.context.scene.objects):
        # iskelete bağlı olmayan yardımcı nesneler (Tripo'nun kürecik gibi) atılır
        if o.type == "MESH" and not o.vertex_groups:
            bpy.data.objects.remove(o, do_unlink=True)
    mesh = next(o for o in bpy.context.scene.objects if o.type == "MESH")
    pre = _prefix(tarm)
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)
    if tarm.animation_data:
        tarm.animation_data_clear()

    # Gerçek boya (1.7 m) ölçekle: model denetimi ve el eşyaları gerçek ölçüyle çalışır.
    k = characters.HEIGHT / max(mesh.dimensions.z, 0.01)
    tarm.scale = tarm.scale * k
    for o in bpy.context.scene.objects:
        o.select_set(o in (tarm, mesh))
    bpy.context.view_layer.objects.active = tarm
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.context.view_layer.update()
    _release_hair(mesh, tarm, pre)
    # Bizim iskelet ve hareketler (aynı sahnede, sonra silinir).
    bpy.context.scene.render.fps = characters.FPS
    marm = characters.armature()
    characters_anim.add_all(marm)
    ours = [a for a in bpy.data.actions]
    top = max(mesh.dimensions.z, 0.01)
    scale_k = top / characters.HEIGHT

    tbones = _ordered([b for b in tarm.data.bones])
    rest = {b.name: b.matrix_local.to_3x3() for b in tbones}
    inv_map = {pre + t: m for m, t in MAP.items()}
    # Hizalama: Tripo kemiğinin dinlenme yönünü bizim kemiğin dinlenme yönüne çevirir.
    align = {}
    for tname, mname in inv_map.items():
        tdir = rest[tname].col[1].normalized()
        mdir = marm.data.bones[mname].matrix_local.to_3x3().col[1].normalized()
        align[tname] = tdir.rotation_difference(mdir).to_matrix()
    mrest = {b.name: b.matrix_local.to_3x3() for b in marm.data.bones}

    for pb in tarm.pose.bones:
        pb.rotation_mode = "QUATERNION"
    tarm.animation_data_create()
    made = []
    for act in ours:
        marm.animation_data.action = act
        f0, f1 = int(act.frame_range[0]), int(act.frame_range[1])
        new = bpy.data.actions.new("tripo_" + act.name)
        made.append((new, act.name))
        tarm.animation_data.action = new
        for f in range(f0, f1 + 1, SAMPLE_STEP):
            bpy.context.scene.frame_set(f)
            final = {}
            for b in tbones:
                pb = tarm.pose.bones[b.name]
                if b.parent is None:
                    parent_rest_rel = rest[b.name]
                    parent_final = Matrix.Identity(3)
                else:
                    parent_rest_rel = rest[b.parent.name].inverted() @ rest[b.name]
                    parent_final = final[b.parent.name]
                inherited = parent_final @ parent_rest_rel
                if b.name in inv_map:
                    mp = marm.pose.bones[inv_map[b.name]]
                    w_my = mp.matrix.to_3x3() @ mrest[mp.name].inverted()
                    want = w_my @ align[b.name] @ rest[b.name]
                    basis = inherited.inverted() @ want
                else:
                    want = inherited
                    basis = Matrix.Identity(3)
                final[b.name] = want
                pb.rotation_quaternion = basis.to_quaternion()
                pb.keyframe_insert("rotation_quaternion", frame=f)
                if b.parent is None:
                    mh = marm.pose.bones["hips"]
                    offset = (mh.head - marm.data.bones["hips"].head_local) * scale_k
                    pb.location = rest[b.name].inverted() @ offset
                    pb.keyframe_insert("location", frame=f)
        track = tarm.animation_data.nla_tracks.new()
        track.name = act.name
        track.strips.new(act.name, f0, new)
        track.mute = True
        tarm.animation_data.action = None

    # Bizim iskeleti ve eylemlerini sil; Tripo iskeletini dinlenme pozuna döndür.
    bpy.data.objects.remove(marm, do_unlink=True)
    for a in ours:
        bpy.data.actions.remove(a)
    for new, name in made:  # bizimkiler silindi; adlar artık çakışmaz (oyun "idle", "walk"… arar)
        new.name = name
    for pb in tarm.pose.bones:
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
    for mat in mesh.data.materials:
        for n in (mat.node_tree.nodes if mat and mat.use_nodes else []):
            if n.type == "TEX_IMAGE" and n.image:
                n.image.name = "tex"
                if max(n.image.size) > 1024:
                    n.image.scale(1024, 1024)
    out = os.path.join(MODELS_DIR, dst)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_yup=True, export_animations=True,
                              export_animation_mode="ACTIONS", export_skins=True, export_cameras=False,
                              export_lights=False, export_image_format="JPEG", export_jpeg_quality=92)
    print("RETARGET %s → %s  %d hareket, boy %.2f" % (os.path.basename(src), dst, len(ours), top))


def main() -> None:
    a = args()
    retarget(os.path.join(ROOT, a["src"]), a["dst"])


if __name__ == "__main__":
    main()
