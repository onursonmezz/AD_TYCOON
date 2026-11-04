"""Bütün G3 modellerini üretir ve assets/models/ altına .glb olarak yazar.

Çalıştırma (proje klasöründe):
    blender --background --python tools/blender/build_all.py
Yalnızca bazılarını üretmek için:
    blender --background --python tools/blender/build_all.py -- --only=desk,plant_big
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import common  # noqa: E402
import models  # noqa: E402
import models_furniture as mf  # noqa: E402
import models_props as mp  # noqa: E402

# ad → (göreli .glb yolu, kurucu)
TARGETS = {
    "desk": ("props/desk.glb", lambda: models.desk()),
    "bookshelf": ("furniture/bookshelf.glb", lambda: models.bookshelf()),
    "plant_small": ("furniture/plant_small.glb", lambda: models.pot("small")),
    "plant_medium": ("decor/plant_medium.glb", lambda: models.pot("medium")),
    "plant_big": ("furniture/plant_big.glb", lambda: models.pot("big")),
    "hex_shelf": ("decor/hex_shelf.glb", lambda: models.hex_shelf()),
    "wall_panel": ("decor/wall_panel.glb", lambda: models.wall_panel()),
    "chair": ("props/chair.glb", mp.chair),
    "counter": ("props/counter.glb", mp.counter),
    "meeting_table": ("props/meeting_table.glb", mp.meeting_table),
    "sofa": ("props/sofa.glb", mp.sofa),
    "pc386": ("equipment/pc386.glb", mp.pc386),
    "g4": ("equipment/g4.glb", mp.g4),
    "imak": ("equipment/imak.glb", mp.imak),
    "mchip": ("equipment/mchip.glb", mp.mchip),
    "tea_urn": ("furniture/tea_urn.glb", mf.tea_urn),
    "filter_coffee": ("furniture/filter_coffee.glb", mf.filter_coffee),
    "espresso": ("furniture/espresso.glb", mf.espresso),
    "water_cooler": ("furniture/water_cooler.glb", mf.water_cooler),
    "whiteboard": ("furniture/whiteboard.glb", mf.whiteboard),
    "mood_board": ("furniture/mood_board.glb", mf.mood_board),
    "record_player": ("furniture/record_player.glb", mf.record_player),
    "award_case": ("furniture/award_case.glb", mf.award_case),
    "neon_sign": ("furniture/neon_sign.glb", mf.neon_sign),
    "office_cat": ("furniture/office_cat.glb", mf.office_cat),
    "tree": ("street/tree.glb", mf.tree),
    "lamp": ("street/lamp.glb", mf.lamp),
    "bench": ("street/bench.glb", mf.bench),
    "billboard": ("street/billboard.glb", mf.billboard),
}


def main() -> None:
    only = [s for s in common.args().get("only", "").split(",") if s]
    common.reset()
    print("Palet:", common.write_palette())
    for name, (rel, build) in TARGETS.items():
        if only and name not in only:
            continue
        common.reset()
        build()
        common.export(rel)


main()
