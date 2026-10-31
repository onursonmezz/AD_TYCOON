# 25 Claude Code çalışma düzeni

## 25.1 Kurulum (bir kerelik, M0'da)

1. Godot 4 (godotengine.org → standart sürüm, .NET olmayan). Kurulum gerektirmez, klasöre çıkarıp çalıştır.
2. Git + bir GitHub hesabı (özel/private depo). İstersen GitHub Desktop ile görsel kullanım.
3. Claude Code (terminal veya masaüstü uygulaması) — proje klasöründe açılır.
4. Blender (ücretsiz) — AI modellerini temizlemek için.
5. (Önerilir) VS Code — dosyalara göz atmak için; Godot eklentisiyle GDScript renklendirme.
6. (İsteğe bağlı) Godot MCP sunucusu — Claude'un Godot editörünü/projeyi çalıştırıp hata çıktısını görmesini sağlar (ör. açık kaynak "godot-mcp" projeleri). Kurulumu Claude'a yaptırabilirsin: "Godot için bir MCP sunucusu kur ve yapılandır, hangi seçenekleri önerdiğini önce bana açıkla."

## 25.2 CLAUDE.md şablonu (proje köküne)

> Proje kökündeki `CLAUDE.md` bu şablondan oluşturuldu (sürüm 4.7.2 olarak sabitlendi).

```markdown
# Ajans Tycoon — Claude Code Talimatları

## Proje
Reklam ajansı yönetim simülasyonu (Game Dev Tycoon benzeri). Tasarım: docs/GDD.pdf ve docs/gdd/*.md.
Motor: Godot 4.X.Y (sürümü sabitle) · Dil: GDScript (statik tipli) · Hedef: Windows/Steam.
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
```

## 25.3 İyi prompt alışkanlıkları

- **Tek sistem, net kabul kriteri:** "Matbaa fiyat modelini Bölüm 10.2'ye göre yaz; 1.000 ve 10.000 adet için birim fiyat testleri ekle; 10x adette birim fiyat %30–38 düşmeli."
- **Önce plan:** Büyük işlerde "önce plan yap, dosya listesi ve adımları göster, kod yazma" de (Claude Code'un plan modu).
- **Hata görünce:** Godot'nun Output/Debugger panelindeki hatayı kopyalayıp yapıştır; ekran görüntüsü de verebilirsin.
- **Hissi tarif et:** "Kampanya raporu açılınca puan sayılarak yükselsin, 8 üstüyse konfeti" gibi duygu/an tarifleri iyi sonuç verir.
- **Bağlamı taze tut:** Uzun oturumlarda Claude'a ilgili GDD bölümünü yeniden okumasını söyle: "docs/gdd/07-puanlama.md'yi oku, sonra…".
- **Geri al:** Bir şey kötü gittiyse "son commit'e geri dön" demek her zaman mümkün.
