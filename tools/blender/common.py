"""Blender betiklerinin ortak yardımcıları (G3, docs/art-direction.md 7).

Her model yuvarlatılmış kutu ve silindirlerden kurulur. Her parça ortak palet dokusundaki
(assets/textures/palette.png, 256x256, 16x16 renk karesi) bir kareye eşlenir; bütün modeller
tek malzeme kullanır.

Kurallar (art/style_bible.md 3): 1 birim = 1 m, taban Z = 0, X/Y'de ortalı, ön yüz -Y.
Blender 4.x / 5.x ile çalışır; yalnızca bpy ve bmesh kullanır.
"""

import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

# Proje kökü: bu dosya tools/blender/ altında.
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
PALETTE_PATH = os.path.join(ROOT, "assets", "textures", "palette.png")
MODELS_DIR = os.path.join(ROOT, "assets", "models")

PALETTE_SIZE = 256
CELLS = 16  # 16x16 kare, her biri 16 px

# Dünya paleti (art-direction.md 3.2) ve modellerin ihtiyaç duyduğu ara tonlar.
# Sıra = karenin numarası (soldan sağa, yukarıdan aşağı). Yeni renk yalnızca sona eklenir;
# araya eklemek mevcut modellerin renklerini kaydırır.
PALETTE = [
    ("wood", "#C9A266"),
    ("wood_light", "#E0C38A"),
    ("wood_dark", "#8A6440"),
    ("wall_sage", "#4F7A5C"),
    ("wall_deep", "#2F5A40"),
    ("wall_cream", "#EFE6D2"),
    ("terracotta", "#C8664A"),
    ("terracotta_dark", "#9E4B35"),
    ("mustard", "#D9A441"),
    ("charcoal", "#3B3C40"),
    ("leaf", "#6FA04A"),
    ("leaf_light", "#8CBF5A"),
    ("leaf_dark", "#4C7A37"),
    ("soil", "#5A4030"),
    ("cream", "#F5EEDC"),
    ("sage", "#5B7F67"),
    ("pastel_blue", "#8FB8C9"),
    ("pastel_pink", "#E3A3A0"),
    ("pastel_yellow", "#EED48A"),
    ("pastel_mint", "#A9D6B9"),
    ("ink", "#3B3530"),
    ("brass", "#C9A13A"),
    ("pot_sage", "#9FBFA4"),
    ("pot_cream", "#E8DCC4"),
]
_INDEX = {name: i for i, (name, _) in enumerate(PALETTE)}

_MATERIAL = None


# --- komut satırı -------------------------------------------------------------

def args() -> dict:
    """`blender --background --python x.py -- --out=a --size=b` → {"out": "a", "size": "b"}."""
    out = {}
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    for a in argv:
        if a.startswith("--") and "=" in a:
            k, v = a[2:].split("=", 1)
            out[k] = v
    return out


# --- palet --------------------------------------------------------------------

def _hex(h: str) -> tuple:
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def write_palette() -> str:
    """Palet dokusunu yazar (her çalıştırmada yeniden; boş kareler krem)."""
    os.makedirs(os.path.dirname(PALETTE_PATH), exist_ok=True)
    img = bpy.data.images.new("palette_tmp", PALETTE_SIZE, PALETTE_SIZE, alpha=False)
    px = [0.0] * (PALETTE_SIZE * PALETTE_SIZE * 4)
    cell = PALETTE_SIZE // CELLS
    fill = _hex("#F5EEDC")
    for y in range(PALETTE_SIZE):
        for x in range(PALETTE_SIZE):
            # Blender pikselleri alttan başlar; kare 0 sol üstte olsun.
            idx = ((PALETTE_SIZE - 1 - y) // cell) * CELLS + x // cell
            c = _hex(PALETTE[idx][1]) if idx < len(PALETTE) else fill
            o = (y * PALETTE_SIZE + x) * 4
            px[o:o + 4] = [c[0], c[1], c[2], 1.0]
    img.pixels = px
    img.filepath_raw = PALETTE_PATH
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)
    return PALETTE_PATH


def uv_of(color: str) -> tuple:
    """Renk karesinin merkezi (UV, alttan yukarı)."""
    i = _INDEX[color]
    u = (i % CELLS + 0.5) / CELLS
    v = 1.0 - (i // CELLS + 0.5) / CELLS
    return (u, v)


def material():
    """Tek ortak malzeme: palet dokusu, en yakın piksel, mat yüzey."""
    global _MATERIAL
    if _MATERIAL is not None:
        return _MATERIAL
    if not os.path.exists(PALETTE_PATH):
        write_palette()
    mat = bpy.data.materials.new("palette")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.9
    bsdf.inputs["Metallic"].default_value = 0.0
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(PALETTE_PATH, check_existing=True)
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    _MATERIAL = mat
    return mat


# --- sahne --------------------------------------------------------------------

def reset() -> None:
    """Boş sahne (varsayılan küp, kamera, ışık gider)."""
    global _MATERIAL
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _MATERIAL = None


class Builder:
    """Parçaları tek bir bmesh'te toplar; her parça kendi renk karesine eşlenir."""

    def __init__(self, name: str):
        self.name = name
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")

    def _paint(self, faces, color: str) -> None:
        uv = uv_of(color)
        for f in faces:
            for loop in f.loops:
                loop[self.uv].uv = uv

    def _bevel(self, geom_verts, width: float, segments: int, min_angle_deg: float = 40.0) -> list:
        """Yalnızca keskin kenarları (yüzler arası açı > min_angle) yuvarlar; yeni yüzleri döndürür."""
        vs = set(geom_verts)
        edges = [e for e in self.bm.edges if e.verts[0] in vs and e.verts[1] in vs
                 and len(e.link_faces) == 2 and e.calc_face_angle(0.0) > math.radians(min_angle_deg)]
        if width <= 0.0 or not edges:
            return []
        res = bmesh.ops.bevel(self.bm, geom=edges, offset=width, offset_type="OFFSET", segments=segments,
                              profile=0.5, affect="EDGES", clamp_overlap=True)
        return list(res["faces"])

    def box(self, size, center, color: str, bevel: float = 0.015, segments: int = 2, rot_z: float = 0.0,
            rot_y: float = 0.0):
        """Yuvarlatılmış kutu. size (x, y, z) m, center kutunun merkezi."""
        res = bmesh.ops.create_cube(self.bm, size=1.0)
        verts = res["verts"]
        m = (Matrix.Translation(Vector(center)) @ Matrix.Rotation(rot_z, 4, "Z") @ Matrix.Rotation(rot_y, 4, "Y")
             @ Matrix.Diagonal(Vector((*size, 1.0))))
        bmesh.ops.transform(self.bm, matrix=m, verts=verts)
        faces = {f for v in verts for f in v.link_faces}
        bevel = min(bevel, min(size) * 0.45)
        self._paint(faces, color)  # bevel yeni yüzlere aynı UV'yi aktarır
        self._bevel(verts, bevel, segments)
        return verts

    def cylinder(self, radius_bottom: float, radius_top: float, height: float, center_bottom, color: str,
                 segments: int = 16, bevel: float = 0.012, bevel_segments: int = 2):
        """Konik/düz silindir; tabanı center_bottom'da. Yalnız ağız ve taban kenarı yuvarlanır."""
        res = bmesh.ops.create_cone(self.bm, cap_ends=True, cap_tris=False, segments=segments,
                                    radius1=radius_bottom, radius2=radius_top, depth=height)
        verts = res["verts"]
        bmesh.ops.translate(self.bm, vec=Vector(center_bottom) + Vector((0, 0, height * 0.5)), verts=verts)
        faces = {f for v in verts for f in v.link_faces}
        self._paint(faces, color)  # bevel yeni yüzlere aynı UV'yi aktarır
        self._bevel(verts, min(bevel, height * 0.3), bevel_segments)
        return verts

    def blob(self, radius, center, color: str, subdiv: int = 1, squash=(1.0, 1.0, 1.0), rng=None, wobble: float = 0.12):
        """Yaprak kümesi için tombul, hafif düzensiz küre (ikosfer)."""
        res = bmesh.ops.create_icosphere(self.bm, subdivisions=subdiv, radius=radius)
        verts = res["verts"]
        r = rng or random.Random(0)
        for v in verts:
            k = 1.0 + r.uniform(-wobble, wobble)
            v.co = Vector((v.co.x * squash[0] * k, v.co.y * squash[1] * k, v.co.z * squash[2] * k))
        bmesh.ops.translate(self.bm, vec=Vector(center), verts=verts)
        faces = {f for v in verts for f in v.link_faces}
        self._paint(faces, color)
        return verts

    def prism(self, sides: int, radius: float, depth: float, center, color: str, rot_x: float = 0.0,
              bevel: float = 0.01, segments: int = 2, start_angle: float = 0.0):
        """Düzgün çokgen prizma (ör. altıgen). Ekseni Z; rot_x ile duvara dik çevrilir."""
        res = bmesh.ops.create_cone(self.bm, cap_ends=True, cap_tris=False, segments=sides,
                                    radius1=radius, radius2=radius, depth=depth)
        verts = res["verts"]
        m = Matrix.Translation(Vector(center)) @ Matrix.Rotation(rot_x, 4, "X") @ Matrix.Rotation(start_angle, 4, "Z")
        bmesh.ops.transform(self.bm, matrix=m, verts=verts)
        faces = {f for v in verts for f in v.link_faces}
        self._paint(faces, color)  # bevel yeni yüzlere aynı UV'yi aktarır
        self._bevel(verts, bevel, segments)
        return verts

    def finish(self):
        """Mesh nesnesini oluşturur, yumuşak gölgelendirir (keskin kenarlar korunur)."""
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        for p in mesh.polygons:
            p.use_smooth = True
        if hasattr(mesh, "set_sharp_from_angle"):
            mesh.set_sharp_from_angle(angle=math.radians(50.0))
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        mesh.materials.append(material())
        return obj


# --- dışa aktarma -------------------------------------------------------------

def export(rel_path: str) -> str:
    """Sahneyi assets/models/<rel_path> olarak .glb yazar (+Y yukarı, değiştiriciler uygulanmış)."""
    path = os.path.join(MODELS_DIR, rel_path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, export_apply=True,
                              export_animations=False, export_cameras=False, export_lights=False)
    tris = sum(len(p.vertices) - 2 for o in bpy.context.scene.objects if o.type == "MESH" for p in o.data.polygons)
    dims = [o.dimensions for o in bpy.context.scene.objects if o.type == "MESH"]
    d = dims[0] if dims else Vector()
    print("GLB %s  %.2f x %.2f x %.2f m  ~%d üçgen" % (rel_path, d.x, d.y, d.z, tris))
    return path
