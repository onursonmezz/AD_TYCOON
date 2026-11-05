"""Yapay zekâ (Tripo) modellerini oyuna hazırlar (art/ai_rehberi.md 7).

Her model `tools/blender/ai_imports.json` içinde bir satırdır:
    "desk": {"src": "art/incoming/desk.glb", "dst": "props/desk.glb", "size": [1.4, 0.7, 0.75],
             "fit": "stretch", "rot": 0, "tris": 3000, "tex": 1024}
- size: oyunun beklediği taban (genişlik, derinlik) ve boy, metre.
- fit: "uniform" oranı korur ve kutuya sığdırır; "stretch" üç ekseni ayrı ölçekler. Boyu oyun için önemli olan
  eşyalarda kullanılır: masa yüksekliği klavyeye, oturak yüksekliği oturana uymalı.
- rot: Z ekseninde döndürme (derece); önü -Y'ye (Blender "Front") bakmalı.
- tris: üçgen sınırı (aşılırsa azaltılır); tex: en büyük doku kenarı (px).
- grade (isteğe bağlı): {"sat": doygunluk çarpanı, "val": parlaklık çarpanı}; yoksa DEFAULT_GRADE.

Çalıştırma (proje klasöründe):
    blender --background --python tools/blender/import_ai.py [-- --only=desk,chair]
Çıktı assets/models/<dst>. build_all.py bu listedeki adları atlar; Blender betiği onların üstüne yazmaz.
"""

import json
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from common import MODELS_DIR, ROOT, args  # noqa: E402

LIST_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ai_imports.json")
MAX_STRETCH = 1.35  # eksenler arası en büyük ölçek oranı; fazlası modeli bozar, uyarı verilir
DEFAULT_GRADE = {"sat": 0.8, "val": 0.94}  # bütün AI dokularına; eşyaya özel "grade" ile değişir


def load_list() -> dict:
    with open(LIST_PATH, encoding="utf-8") as f:
        return json.load(f)


def _bounds(obj):
    vs = [obj.matrix_world @ v.co for v in obj.data.vertices]
    lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
    hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
    return lo, hi


def _tris(obj) -> int:
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def _grade(img, grade: dict) -> None:
    """Renk dokusunu ofis paletine yaklaştırır: doygunluğu ve parlaklığı kısar (ai_imports.json "grade").
    Görsel AI dokuları ofisin sıcak ışığında fazla doygun duruyor (masa: doygunluk 0.61, palet ahşabı 0.49)."""
    sat = float(grade.get("sat", DEFAULT_GRADE["sat"]))
    val = float(grade.get("val", DEFAULT_GRADE["val"]))
    if sat == 1.0 and val == 1.0:
        return
    px = np.empty(len(img.pixels), dtype=np.float32)
    img.pixels.foreach_get(px)
    rgba = px.reshape(-1, 4)
    lum = (rgba[:, :3] @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32))[:, None]
    rgba[:, :3] = np.clip((lum + (rgba[:, :3] - lum) * sat) * val, 0.0, 1.0)
    img.pixels.foreach_set(rgba.ravel())
    img.update()


def process(name: str, cfg: dict) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    src = os.path.join(ROOT, cfg["src"])
    if not os.path.exists(src):
        print("ATLA %s: kaynak yok (%s)" % (name, cfg["src"]))
        return
    bpy.ops.import_scene.gltf(filepath=src)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    # Tek nesne: birleştir, ebeveynleri ve dönüşümleri uygula
    for o in bpy.context.scene.objects:
        o.select_set(o.type == "MESH")
    bpy.context.view_layer.objects.active = meshes[0]
    for o in meshes:
        if o.parent:
            mw = o.matrix_world.copy()
            o.parent = None
            o.matrix_world = mw
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    for o in list(bpy.context.scene.objects):
        if o != obj:
            bpy.data.objects.remove(o, do_unlink=True)
    obj.name = name
    obj.rotation_euler.z += math.radians(float(cfg.get("rot", 0)))
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # Ölçü: kutuya sığdır (oranlı ya da eksen eksen)
    lo, hi = _bounds(obj)
    dim = hi - lo
    w, d, h = cfg["size"]
    want = Vector((w, d, h))
    k = [want[i] / max(dim[i], 1e-6) for i in range(3)]
    if cfg.get("fit", "uniform") == "stretch":
        if max(k) / min(k) > MAX_STRETCH:
            print("UYARI %s: oranlar çok farklı (%.2f); model belirgin biçimde esner" % (name, max(k) / min(k)))
        scale = Vector(k)
    else:
        s = min(k)
        scale = Vector((s, s, s))
    obj.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    lo, hi = _bounds(obj)
    obj.location = Vector((-(lo.x + hi.x) / 2, -(lo.y + hi.y) / 2, -lo.z))
    bpy.ops.object.transform_apply(location=True)

    # Üçgen sınırı
    before = _tris(obj)
    limit = int(cfg.get("tris", 3000))
    if before > limit:
        mod = obj.modifiers.new("decimate", "DECIMATE")
        mod.ratio = limit / before * 0.98
        mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=mod.name)

    # Doku boyutu ve mat yüzey (style_bible 1: parlama yok)
    tex = int(cfg.get("tex", 1024))
    for mat in obj.data.materials:
        if not mat or not mat.use_nodes:
            continue
        for n in mat.node_tree.nodes:
            if n.type == "TEX_IMAGE" and n.image:
                n.image.name = "tex"  # Godot dokuyu <model>_tex.jpg olarak çıkarır
                if max(n.image.size) > tex:
                    n.image.scale(tex, tex)
                if n.outputs[0].links and n.outputs[0].links[0].to_socket.name == "Base Color":
                    _grade(n.image, cfg.get("grade", {}))
            if n.type == "BSDF_PRINCIPLED":
                if not n.inputs["Metallic"].is_linked:
                    n.inputs["Metallic"].default_value = 0.0
                if not n.inputs["Roughness"].is_linked:
                    n.inputs["Roughness"].default_value = max(0.8, n.inputs["Roughness"].default_value)

    dst = os.path.join(MODELS_DIR, cfg["dst"])
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_yup=True, export_apply=True,
                              export_animations=False, export_cameras=False, export_lights=False,
                              export_image_format="JPEG", export_jpeg_quality=92)
    lo, hi = _bounds(obj)
    d3 = hi - lo
    print("AI %s → %s  %.2f x %.2f x %.2f m  %d → %d üçgen  doku ≤%d px" % (
        name, cfg["dst"], d3.x, d3.y, d3.z, before, _tris(obj), tex))


def main() -> None:
    only = [s for s in args().get("only", "").split(",") if s]
    for name, cfg in load_list().items():
        if only and name not in only:
            continue
        process(name, cfg)


if __name__ == "__main__":
    main()
