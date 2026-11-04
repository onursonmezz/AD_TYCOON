# Eşya listesi, ölçüler ve prompt'lar

Her satırdaki **[NESNE]** metnini `art/style_bible.md`'deki şablonun başına koy. Ölçüler metre cinsindendir: **taban** = genişlik × derinlik, **boy** = yükseklik. Oyun modeli bu kutuya sığdırır; ölçüye yakın üretirsen oranlar korunur.

Önerilen ilk deneme sırası: `desk` → `chair` → `plant_big` → `pc386`.

## Sabit eşyalar (`assets/models/props/`)

| Dosya | Taban | Boy | [NESNE] |
|---|---|---|---|
| `desk.glb` | 1.4 × 0.7 | 0.75 | a simple wooden office desk with a drawer, warm wood |
| `chair.glb` | 0.5 × 0.5 | 0.9 | a cushioned office chair on wheels, sage green fabric |
| `counter.glb` | 3.0 × 0.6 | 0.95 | a small office kitchen counter with cabinets, cream doors, wooden top |
| `meeting_table.glb` | 2.4 × 1.2 | 0.75 | a rectangular wooden meeting table |
| `sofa.glb` | 3.0 × 0.8 | 0.55 | a long low three-seat sofa, sage green fabric, wooden legs |

## Bilgisayarlar (`assets/models/equipment/`)

Masanın üstünde durur. Klavye dahil olabilir; ekranın önü (+Z, Blender'da −Y) oturan kişiye bakar.

| Dosya | Dönem | Taban | Boy | [NESNE] |
|---|---|---|---|---|
| `pc386.glb` | 1990–1999 | 0.45 × 0.45 | 0.40 | a beige 1990s CRT computer monitor with a chunky keyboard |
| `g4.glb` | 2000–2009 | 0.45 × 0.45 | 0.42 | a colorful translucent teal all-in-one CRT computer, early 2000s |
| `imak.glb` | 2010–2019 | 0.55 × 0.18 | 0.45 | a thin white all-in-one desktop computer on a stand, no logo |
| `mchip.glb` | 2020+ | 0.60 × 0.30 | 0.32 | an open silver laptop next to a small second monitor |

## Mobilya ve dekor (`assets/models/furniture/`)

| Dosya | Taban | Boy | [NESNE] |
|---|---|---|---|
| `plant_small.glb` | 0.5 × 0.5 | 0.7 | a small leafy potted plant in a terracotta pot |
| `plant_big.glb` | 1.0 × 1.0 | 1.6 | a tall monstera plant in a large terracotta pot |
| `tea_urn.glb` | 0.5 × 0.5 | 1.0 | a Turkish samovar tea urn on a small cabinet with tea glasses |
| `filter_coffee.glb` | 0.5 × 0.5 | 1.0 | a filter coffee machine on a small cabinet |
| `espresso.glb` | 0.5 × 0.5 | 1.0 | a shiny espresso machine on a small cabinet |
| `water_cooler.glb` | 0.5 × 0.5 | 1.3 | an office water cooler with a blue bottle |
| `whiteboard.glb` | 1.5 × 0.5 | 1.6 | a rolling office whiteboard with colorful doodles, no readable text |
| `mood_board.glb` | 1.5 × 0.5 | 1.6 | a standing cork mood board with pinned photos and color swatches |
| `bookshelf.glb` | 1.5 × 0.5 | 1.9 | a wooden bookshelf with books and small plants |
| `record_player.glb` | 1.0 × 0.5 | 0.9 | a vintage record player on a wooden cabinet with vinyl records |
| `award_case.glb` | 1.0 × 0.5 | 1.8 | a glass display cabinet with golden trophies |
| `neon_sign.glb` | 1.0 × 0.5 | 1.2 | a pink neon sign shaped like a lightbulb on a small stand |
| `office_cat.glb` | 1.0 × 1.0 | 0.5 | a fluffy orange cat sleeping on a round cushion |

## Sokak (`assets/models/street/`)

| Dosya | Taban | Boy | [NESNE] |
|---|---|---|---|
| `tree.glb` | 1.2 × 1.2 | 3.2 | a round stylized street tree |
| `lamp.glb` | 0.3 × 0.3 | 3.0 | a classic dark green street lamp |
| `bench.glb` | 1.5 × 0.5 | 0.8 | a wooden park bench with metal legs |
| `billboard.glb` | 4.0 × 0.4 | 3.6 | an empty billboard frame on two posts, **blank white panel** |

> **Billboard'un paneli boş olmalı.** Oyun, kampanyalarının görselini panelin önüne kendisi yerleştirir: 3.6 m × 2.0 m, alt kenarı yerden 1.4 m yukarıda. Panelini bu ölçüye yakın yap.

## Karakterler (`assets/models/characters/`)

Adım adım: `art/pipeline.md` → "Karakterler". Boy 1.7 m. Saç ve kıyafeti açık gri ya da beyaz boya; renklerini oyun verir.

| Dosya | [NESNE] |
|---|---|
| `body_female.glb` | a stylized female office worker, slightly big head, plain light gray t-shirt and trousers, T-pose |
| `body_male.glb` | a stylized male office worker, slightly big head, plain light gray t-shirt and trousers, T-pose |
| `body_neutral.glb` | a stylized androgynous office worker, slightly big head, plain light gray clothes, T-pose |
| `hair_short.glb` … `hair_man_bun.glb` | [saç tipi] hairstyle only, no head, light gray, game asset |
| `outfit_shoulder_pad_blazer.glb` | a 1990s blazer with big shoulder pads, light gray, clothing only |
| `outfit_hipster_flannel.glb` | a 2010s flannel shirt with rolled sleeves, light gray, clothing only |
| `outfit_hoodie.glb` | a casual hoodie, light gray, clothing only |
| (diğer kıyafetler) | `data/characters.json`'daki ada göre: "[kıyafet], light gray, clothing only" |
