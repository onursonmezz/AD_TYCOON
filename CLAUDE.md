# Ajans Tycoon — Claude Code Talimatları

## Proje
Reklam ajansı yönetim simülasyonu (Game Dev Tycoon benzeri). Tasarım: docs/GDD.pdf ve docs/gdd/*.md.
Motor: Godot 4.7.2-stable (sürümü sabitle) · Dil: GDScript (statik tipli) · Hedef: Windows/Steam.
Geliştirici (Orgo) oyun motoru bilmiyor: açıklamaları sade Türkçe yap, editörde yapması
gereken bir şey varsa adım adım tarif et.

## Mimari kuralları
- Simülasyon (src/sim) Node'lara/sahnelere bağımlı OLMAZ; saf sınıflar (RefCounted). UI sadece okur.
- Oyuncu eylemleri src/commands altında Command nesneleri olarak simülasyona gider.
- Tüm sayılar data/balance.json'da; tüm içerik data/*.json'da. Koda sihirli sayı yazma.
- Tüm UI metinleri localization/strings.csv'de (tr, en). Koda Türkçe metin gömme.
- Her rastgelelik GameState.rng üzerinden (tohumlu).
- Formüller GDD Bölüm 7'deki gibi; değiştirirsen docs/decisions.md'ye gerekçeyle yaz.

## Kod stili
- snake_case dosya/değişken, PascalCase class_name. Her fonksiyonda tip belirt.
- Bir dosya ~400 satırı geçerse böl. Kısa yorumlar Türkçe olabilir.

## Test ve doğrulama (her görevde ZORUNLU)
- Birim testleri: GUT ile tests/ altında. Çalıştırma:
    godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
- Veri doğrulama: godot --headless --script res://tools/validate_data.gd
- Denge simülasyonu: godot --headless --script res://tools/balance_sim.gd -- --runs=200
- Görev bitmeden önce testler geçmeli ve proje hatasız açılmalı.

## Çalışma şekli
- Büyük görevlerde önce plan yaz, onayımı bekle.
- Küçük adımlarla ilerle; her çalışan adımdan sonra anlamlı mesajla git commit.
- .import dosyalarını ve .godot/ klasörünü elle düzenleme; .gitignore'da tut.
- Belirsizlikte tahmin etme, sor. Kararları docs/decisions.md'ye kaydet.
- Her kilometre taşı sonunda docs/changelog.md'yi güncelle ve bana "nasıl test ederim" listesi ver.

## Yerel ortam (M0'da eklendi)
- Bu makinede `godot` PATH'te değil. Komutlarda şu dosyayı kullan:
  `C:/Users/osonm/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe` (editör için `..._win64.exe`).
- Temiz bir kopyada ya da yeni dosyalar eklendikten sonra testlerden önce bir kez içe aktar:
  `godot --headless --import` (GUT sınıfları ve strings.csv çevirileri bu adımda üretilir).
- GUT 9.7.1 `addons/gut` altında. Veri doğrulayıcının çekirdeği `tools/data_validator.gd`.
- Denge aracında dosyayı değiştirmeden değer denemek: `... balance_sim.gd -- --runs=50 --set=yol.alt=değer`.
- Simülasyonun giriş noktası `src/sim/simulation.gd` (`Simulation`); veri erişimi `GameData.bal("yol")`.
- Arayüz kodla kurulur (`src/ui/screens/*.gd`, yardımcılar `UiUtil`). Ekranları görsel kontrol için:
  `godot --path . res://tools/ui_tour.tscn -- --out=<klasör>` (pencere açar, PNG kaydeder).
- Modeller (M8): yollar `data/furniture.json` `model` ve `data/models.json`; yükleyici `ModelLibrary` (yoksa gri kutu).
  Denetim: `godot --headless --script res://tools/model_check.gd`; önizleme: `godot --path . res://tools/model_preview.tscn -- --out=<klasör> [--samples]`.
- Ses (M9-B): `Audio` autoload, tarifler `data/sounds.json`, dosya rehberi `assets/audio/README.md`. Dosya yoksa kodla üretilen yer tutucu çalar.
- Performans ölçümü (M9-C): `godot --path . res://tools/perf_check.tscn -- --staff=60 [--samples]`; ekran turu İngilizce: `--lang=en`.
- Görsel karşılaştırma (G1): `godot --path . res://tools/screenshot.tscn -- --tag=<ad>` → `docs/screenshots/`; görünüş ayarları `data/look.json`.
- Blender modelleri (G3): `"C:/Program Files (x86)/Steam/steamapps/common/Blender/blender.exe" --background --python tools/blender/build_all.py [-- --only=desk]` → `assets/models/`, palet `assets/textures/palette.png`.
  Karakterler (C1): `tools/blender/characters.py` (iskelet, gövdeler, hareketler); renk `skin`/`outfit`/`hair` adlı malzemelerle `CharacterRig._paint`.
  Hareket sayfası (C2): `godot --path . res://tools/pose_sheet.tscn --resolution 640x480 -- --out=<klasör>` (her klip önden/yandan + `sheet.png`).
  Gardırop (C3): `godot --path . res://tools/wardrobe.tscn --resolution 1920x1080 -- --out=<dosya.png> [--act=type]` (her kıyafet + saç tek karede).
- AI modelleri (Tripo): ham dosya `art/incoming/`, ayarlar `tools/blender/ai_imports.json`, içe alma `blender --background --python tools/blender/import_ai.py [-- --only=desk]`. Rehber: `art/ai_rehberi.md`.
- UI teması (UI-2): `src/ui/theme/cozy_theme.gd` (`CozyTheme`, proje teması; değişince `godot --headless --script res://tools/build_theme.gd`), ikon çizimleri `cozy_icons.gd`. Pencere başlığı `UiUtil.window_frame` + `heading(metin, ikon)`. Ekran turunu tek bakışta görmek: `godot --headless --script res://tools/contact_sheet.gd -- <klasör>`.
