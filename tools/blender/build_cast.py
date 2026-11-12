"""Kadro karakterlerini toplu hazırlar (K2, art/ai_rehberi.md 5).

1. art/incoming/cast/ içindeki adlandırma kuralına uyan dosyaları bulur:
       char_<dönem>_<f|m|n><sıra>.glb (Tripo Rig) ya da .fbx (Mixamo)   ör. char_1990_f01.glb, char_2010_m02.fbx
   dönem: 1990, 2000, 2010, 2020 (2020 = 2020 ve sonrası); f kadın, m erkek, n nötr.
2. Her karaktere hareketleri aktarır (retarget_tripo.py) → assets/models/characters/cast/<id>.glb.
3. Başarıyla hazırlanan yeni karakterleri data/characters.json "cast" listesine ekler (dosyanın düzenini bozmadan).
   İskeleti olmayan dosya hazırlanamaz ve listeye girmez; Tripo'da Rig yapılıp yeniden indirilmeli.

Çalıştırma (proje klasöründe):
    blender --background --python tools/blender/build_cast.py [-- --only=char_2020_f01,char_1990_m01]
"""

import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from common import ROOT, args  # noqa: E402
import retarget_tripo  # noqa: E402

INCOMING = os.path.join(ROOT, "art", "incoming", "cast")
DATA = os.path.join(ROOT, "data", "characters.json")
NAME = re.compile(r"^char_(1990|2000|2010|2020)_([fmn])(\d{2})\.(glb|fbx)$")  # Tripo GLB ya da Mixamo FBX
GENDERS = {"f": "female", "m": "male", "n": "neutral"}
ERA_END = {"1990": 1999, "2000": 2009, "2010": 2019, "2020": 9999}


def _entry(fname: str) -> dict:
    era, g, _, ext = NAME.match(fname).groups()
    cid = fname.rsplit(".", 1)[0]
    return {"id": cid, "model": "characters/cast/%s.glb" % cid, "gender": GENDERS[g], "from": int(era),
            "to": ERA_END[era], "src": "art/incoming/cast/%s.%s" % (cid, ext)}


def _entry_text(e: dict) -> str:
    return ('\t\t{ "id": "%s", "model": "%s", "gender": "%s", "from": %d, "to": %d,\n\t\t\t"src": "%s" }'
            % (e["id"], e["model"], e["gender"], e["from"], e["to"], e["src"]))


def _register(entries: list) -> None:
    """Yeni girdileri "cast" listesinin sonuna ekler; dosyanın geri kalanına dokunmaz."""
    if not entries:
        return
    with open(DATA, encoding="utf-8") as f:
        text = f.read()
    start = text.index('"cast": [')
    end = text.index("\n\t]", start)
    body = text[start:end].rstrip()
    sep = "" if body.endswith("[") else ","
    text = text[:start] + body + sep + "\n" + ",\n".join(_entry_text(e) for e in entries) + text[end:]
    json.loads(text)  # bozuk yazmadığımızdan emin ol
    with open(DATA, "w", encoding="utf-8") as f:
        f.write(text)
    print("Kadroya eklendi:", ", ".join(e["id"] for e in entries))


def _build(e: dict) -> bool:
    src = os.path.join(ROOT, e.get("src", ""))
    if not e.get("src") or not os.path.exists(src):
        print("ATLA %s: ham dosya yok (%s)" % (e["id"], e.get("src", "")))
        return False
    try:
        retarget_tripo.retarget(src, e["model"])
        return True
    except (StopIteration, RuntimeError, KeyError) as err:
        print("HATA %s: iskelet bulunamadı ya da Mixamo adlı değil (%s). Tripo'da Rig (humanoid) yapıp GLB indir."
              % (e["id"], err))
        return False


def main() -> None:
    only = [s for s in args().get("only", "").split(",") if s]
    with open(DATA, encoding="utf-8") as f:
        cast = json.load(f).get("cast", [])
    known = {c["id"] for c in cast}
    files = sorted(os.listdir(INCOMING)) if os.path.isdir(INCOMING) else []
    for n in files:
        if n.lower().endswith((".glb", ".fbx")) and not NAME.match(n):
            print("UYARI: %s adlandırma kuralına uymuyor (char_<dönem>_<f|m|n><sıra>.glb ya da .fbx), atlandı" % n)
    new = [_entry(n) for n in files if NAME.match(n) and n.rsplit(".", 1)[0] not in known]
    done = 0
    for e in cast:
        if (not only or e["id"] in only) and _build(e):
            done += 1
    added = []
    for e in new:
        if (not only or e["id"] in only) and _build(e):
            added.append(e)
            done += 1
    _register(added)
    print("Kadro: %d karakter hazırlandı, listede %d karakter" % (done, len(cast) + len(added)))


main()
