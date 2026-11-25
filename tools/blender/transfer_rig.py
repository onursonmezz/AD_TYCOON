"""İskeletsiz Tripo karakterine, benzer yapıdaki iskeletli bir karakterin iskeletini ve ağırlıklarını aktarır (S13).

Orgo'nun önerisi: "iskeletlerini diğerlerinden kopyalayabilirsin, hepsi benzer". Tripo karakterleri aynı A-pozda ve
benzer oranlarda geldiği için:
  1. Örnek (iskeletli) karakterin iskeleti ve gövdesi, yeni karakterin kutusuna (en, derinlik, boy) uydurulur;
     eklemler orantılı olarak yeni gövdeye taşınır.
  2. Kemik ağırlıkları örnek gövdeden yeni gövdeye en yakın yüzeyden aktarılır (Data Transfer).
  3. Yeni gövde iskelete bağlanır; örnek gövde silinir; iskeletli GLB yazılır.
Çıktı, kadro aracının (build_cast.py) beklediği adla art/incoming/cast/ altına konur; oradan hareketler aktarılır.

Çalıştırma:
    blender --background --python tools/blender/transfer_rig.py -- --src=<iskeletsiz.fbx|glb> --ref=<iskeletli.fbx>
        --dst=art/incoming/cast/char_2010_f02.glb
"""

import json
import os
import sys

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from common import ROOT, args  # noqa: E402
import retarget_tripo  # noqa: E402


def _import(path: str) -> list:
    before = set(bpy.data.objects)
    if path.lower().endswith(".fbx"):
        bpy.ops.import_scene.fbx(filepath=path)
    else:
        bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in bpy.data.objects if o not in before]


def _select(objs: list, active=None) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = active or objs[0]


def _bake_world(obj) -> None:
    """Nesneyi ebeveyninden ayırır ve dönüşümünü verisine işler (dünya koordinatları = yerel)."""
    _select([obj])
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def _bbox(meshes: list) -> tuple:
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for m in meshes:
        for v in m.data.vertices:
            p = m.matrix_world @ v.co
            lo = Vector((min(lo.x, p.x), min(lo.y, p.y), min(lo.z, p.z)))
            hi = Vector((max(hi.x, p.x), max(hi.y, p.y), max(hi.z, p.z)))
    return lo, hi


def _upright(arm, mesh) -> None:
    """Örnek yatık gelebilir (Mixamo FBX): kalça→baş yönünü +Z'ye, karakterin solunu +X'e çevirir (retarget_tripo ile
    aynı kural); dönüş iskeletin ve gövdenin verisine işlenir."""
    bones = arm.data.bones
    pre = next(b.name[:-4] for b in bones if b.name.endswith("Hips"))
    up = (bones[pre + "Head"].head_local - bones[pre + "Hips"].head_local).normalized()
    left = bones[pre + "LeftArm"].head_local - bones[pre + "RightArm"].head_local
    left = (left - up * left.dot(up)).normalized()
    fwd = left.cross(up)
    have = Matrix((left, fwd, up)).transposed()
    want = Matrix(((1, 0, 0), (0, -1, 0), (0, 0, 1))).transposed()
    fix = want @ have.inverted()
    fix = Matrix([[float(round(fix[i][j])) for j in range(3)] for i in range(3)])
    if fix == Matrix.Identity(3) or abs(fix.determinant() - 1.0) > 1e-6:
        return
    arm.data.transform(fix.to_4x4())
    mesh.data.transform(fix.to_4x4())
    bpy.context.view_layer.update()
    print("örnek dik konuma getirildi")


def _decimate(mesh) -> None:
    """Gövde karakter üçgen sınırını (data/models.json limits.triangles_character) aşıyorsa %95'ine indirilir.
    Ağırlıklar sonra aktarıldığı için sadeleştirme iskeleti bozmaz."""
    with open(os.path.join(ROOT, "data", "models.json"), encoding="utf-8") as f:
        limit = int(json.load(f)["limits"]["triangles_character"])
    tris = sum(len(p.vertices) - 2 for p in mesh.data.polygons)
    if tris <= limit:
        return
    mod = mesh.modifiers.new("sadelestir", "DECIMATE")
    mod.ratio = limit * 0.95 / tris
    _select([mesh])
    bpy.ops.object.modifier_apply(modifier=mod.name)
    print("sadeleştirildi: %d → %d üçgen" % (tris, sum(len(p.vertices) - 2 for p in mesh.data.polygons)))


def _own_textures(src: str, meshes: list) -> None:
    """Tripo FBX'leri dokuyu yalnız dosya adıyla ("Color.png") anar; Blender aynı adı başka karakterin klasöründe
    bulabiliyor. Kaynağın yanındaki <ad>.fbm klasörü varsa dokular oradan yeniden yüklenir."""
    fbm = os.path.splitext(src)[0] + ".fbm"
    if not os.path.isdir(fbm):
        return
    for m in meshes:
        for mat in m.data.materials:
            for n in (mat.node_tree.nodes if mat and mat.use_nodes else []):
                if n.type != "TEX_IMAGE" or not n.image:
                    continue
                own = os.path.join(fbm, os.path.basename(bpy.path.abspath(n.image.filepath)))
                if os.path.isfile(own):
                    n.image = _clean_image(own)
                    print("doku:", own)


def _clean_image(path: str):
    """Dokuyu renk profilsiz (ICC) kopya olarak yükler: Tripo PNG'lerindeki profil JPEG'e taşınınca Godot dokuyu
    okuyamıyor. Pikseller yeni bir resme kopyalanır, geçici JPEG olarak yazılıp paketlenir."""
    src = bpy.data.images.load(path, check_existing=False)
    w, h = src.size
    px = [0.0] * (w * h * 4)
    src.pixels.foreach_get(px)
    img = bpy.data.images.new(os.path.splitext(os.path.basename(path))[0], w, h)
    img.pixels.foreach_set(px)
    bpy.data.images.remove(src)
    tmp = os.path.join(bpy.app.tempdir or os.environ.get("TEMP", "."), "rig_%s.png" % img.name)
    img.filepath_raw = tmp
    img.file_format = "PNG"
    img.save()
    img.pack()
    return img


def _keep_base_color(mesh) -> None:
    """Malzemede yalnız Base Color'a bağlı doku kalır. Tripo'nun normal/pürüzlülük dokuları retarget'te aynı adı
    alıp rengin yerine geçiyordu (karakter beyaz görünüyordu)."""
    for mat in mesh.data.materials:
        if not mat or not mat.use_nodes:
            continue
        tree = mat.node_tree
        keep = set()
        for n in tree.nodes:
            if n.type == "BSDF_PRINCIPLED":
                for link in n.inputs["Base Color"].links:
                    keep.add(link.from_node)
        for n in list(tree.nodes):
            if n.type in ("TEX_IMAGE", "NORMAL_MAP") and n not in keep:
                tree.nodes.remove(n)


def _join(meshes: list):
    if len(meshes) == 1:
        return meshes[0]
    _select(meshes)
    bpy.ops.object.join()
    return bpy.context.view_layer.objects.active


def transfer(src: str, ref: str, dst: str) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    ref_objs = _import(ref)
    arm = next(o for o in ref_objs if o.type == "ARMATURE")
    ref_meshes = [o for o in ref_objs if o.type == "MESH" and o.vertex_groups]
    for o in ref_objs:
        if o.type == "MESH" and not o.vertex_groups:
            bpy.data.objects.remove(o, do_unlink=True)
    for a in list(bpy.data.actions):  # örnekteki hazır hareket atılır
        bpy.data.actions.remove(a)
    if arm.animation_data:
        arm.animation_data_clear()
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    for m in ref_meshes:
        _bake_world(m)
    ref_mesh = _join(ref_meshes)
    _select([arm])
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    _upright(arm, ref_mesh)

    src_objs = _import(src)
    _own_textures(src, [o for o in src_objs if o.type == "MESH"])
    src_meshes = [o for o in src_objs if o.type == "MESH"]
    for o in src_objs:
        if o.type not in ("MESH",):
            continue
    for m in src_meshes:
        _bake_world(m)
    for o in src_objs:  # boş ebeveynler (Tripo kök düğümü) atılır
        if o.type != "MESH" and o.name in bpy.data.objects:
            bpy.data.objects.remove(o, do_unlink=True)
    mesh = _join(src_meshes)
    _decimate(mesh)

    # 1. Örneği yeni gövdenin kutusuna uydur (eksen başına ölçek, taban ve merkez hizası).
    rlo, rhi = _bbox([ref_mesh])
    slo, shi = _bbox([mesh])
    rs = rhi - rlo
    print("örnek kutu", tuple(round(x, 3) for x in rlo), tuple(round(x, 3) for x in rhi))
    print("yeni kutu", tuple(round(x, 3) for x in slo), tuple(round(x, 3) for x in shi))
    ss = shi - slo
    scale = Vector((ss.x / rs.x, ss.y / rs.y, ss.z / rs.z))
    rc = Vector(((rlo.x + rhi.x) * 0.5, (rlo.y + rhi.y) * 0.5, rlo.z))
    sc = Vector(((slo.x + shi.x) * 0.5, (slo.y + shi.y) * 0.5, slo.z))
    fit = Matrix.Translation(sc) @ Matrix.Diagonal((scale.x, scale.y, scale.z, 1.0)) @ Matrix.Translation(-rc)
    ref_mesh.data.transform(fit)
    arm.data.transform(fit)
    bpy.context.view_layer.update()
    print("uydurma ölçeği: %.3f %.3f %.3f" % (scale.x, scale.y, scale.z))

    # 2. Ağırlıkları en yakın yüzeyden aktar. Örnek gövde dinlenme hâlinde okunmalı: iskelet değiştiricisi kaldırılır
    #    (FBX'ten kalan poz gövdeyi kaydırıyordu).
    for md in list(ref_mesh.modifiers):
        ref_mesh.modifiers.remove(md)
    for vg in ref_mesh.vertex_groups:
        if vg.name not in mesh.vertex_groups:
            mesh.vertex_groups.new(name=vg.name)
    mod = mesh.modifiers.new("agirlik", "DATA_TRANSFER")
    mod.object = ref_mesh
    mod.use_vert_data = True
    mod.data_types_verts = {"VGROUP_WEIGHTS"}
    mod.vert_mapping = "POLYINTERP_NEAREST"
    mod.layers_vgroup_select_src = "ALL"
    mod.layers_vgroup_select_dst = "NAME"
    _select([mesh])
    bpy.ops.object.modifier_apply(modifier=mod.name)

    _keep_base_color(mesh)

    # 3. Yeni gövdeyi iskelete bağla, örneği sil, yaz.
    bpy.data.objects.remove(ref_mesh, do_unlink=True)
    mesh.parent = arm
    arm_mod = mesh.modifiers.new("iskelet", "ARMATURE")
    arm_mod.object = arm
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    _select([arm, mesh], arm)
    bpy.ops.export_scene.gltf(filepath=dst, use_selection=True, export_format="GLB", export_animations=False,
                              export_cameras=False, export_lights=False, export_image_format="JPEG",
                              export_jpeg_quality=95)  # PNG kalırsa retarget onu "JPEG" etiketiyle yazıyor
    retarget_tripo._strip_icc(dst)  # ham dosya da Godot'da hatasız açılsın
    print("iskelet aktarıldı → %s (%d kemik)" % (dst, len(arm.data.bones)))


def main() -> None:
    a = args()
    path = lambda p: p if os.path.isabs(p) else os.path.join(ROOT, p)  # noqa: E731
    transfer(path(a["src"]), path(a["ref"]), path(a["dst"]))


if __name__ == "__main__":
    main()
