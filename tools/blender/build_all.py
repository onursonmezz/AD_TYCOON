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

# ad → (göreli .glb yolu, kurucu)
TARGETS = {
    "desk": ("props/desk.glb", lambda: models.desk()),
    "bookshelf": ("furniture/bookshelf.glb", lambda: models.bookshelf()),
    "plant_small": ("furniture/plant_small.glb", lambda: models.pot("small")),
    "plant_medium": ("decor/plant_medium.glb", lambda: models.pot("medium")),
    "plant_big": ("furniture/plant_big.glb", lambda: models.pot("big")),
    "hex_shelf": ("decor/hex_shelf.glb", lambda: models.hex_shelf()),
    "wall_panel": ("decor/wall_panel.glb", lambda: models.wall_panel()),
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
