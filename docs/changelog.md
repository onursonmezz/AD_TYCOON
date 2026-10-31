# Değişiklik günlüğü

## M0 — Kurulum & iskelet (2026-10-31)

### Eklenenler
- Godot 4.7.2 projesi (`project.godot`), GDD 24.2 klasör yapısı, M0 açılış ekranı (`src/ui/screens/boot_screen.tscn`).
- `CLAUDE.md` (GDD 25.2 şablonu, sürüm 4.7.2 sabitlendi + yerel ortam notu).
- GDD'nin bölüm bölüm markdown hâli: `docs/gdd/00-icindekiler.md` … `29-ekler.md`.
- Veri: `balance.json` (29.1), `sectors.json` (35), `objectives.json` (6, odak önemi + ideal S/K), `audiences.json` (4), `tones.json` (6), `tone_groups.json` (11), `focus_areas.json` (9), `channels.json` (45), `combo_rules.json`, `fit/sector_objective.json`, `fit/sector_audience.json`, `fit/tone_fit.json`, `fit/channel_fit.json`.
- Yerelleştirme: `localization/strings.csv` (TR + EN, 120 anahtar).
- GUT 9.7.1 test eklentisi + `tests/test_data_validator.gd` (10 test).
- Veri doğrulama: `tools/validate_data.gd` + `tools/data_validator.gd` (id tutarlılığı, GDD 8.0 tam satır dağılım kuralı).
- `docs/decisions.md` (K-001…K-015 + açık sorular), `docs/playtest-notes.md`, `docs/ideas.md`, `.gitignore`.

### Nasıl test ederim
1. Godot'yu aç: `C:\Users\osonm\Tools\Godot\Godot_v4.7.2-stable_win64.exe` → **İçe Aktar (Import)** → `AD_TYCOON\project.godot` → **İçe Aktar ve Düzenle**.
2. Sağ üstteki ▶ (veya **F5**) ile çalıştır: krem zeminde "Ajans Tycoon" yazan açılış ekranı gelmeli; alttaki Çıktı (Output) panelinde kırmızı hata olmamalı.
3. Testler (Git Bash veya PowerShell, proje klasöründe):
   `"C:/Users/osonm/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` → "All tests passed".
4. Veri doğrulama: `"C:/Users/osonm/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless --script res://tools/validate_data.gd` → "Veri doğrulama BAŞARILI".
5. Bozuk satır denemesi: `data/fit/sector_objective.json` içinde `fast_food` satırındaki altı değeri de `3` yap, 4. adımı tekrarla → "dağılım kuralını bozuyor" hatası ve çıkış kodu 1. Sonra değişikliği geri al (`git checkout data/fit/sector_objective.json`).
