# Ajans Tycoon — Oyun Tasarım Dokümanı (GDD) + Geliştirme Yol Haritası

> Kaynak: `docs/GDD.pdf` · Doküman sürümü 1.1 · 31 Ekim 2026 (uyum tabloları yeniden dengelendi).
> Bu klasördeki dosyalar PDF'in bölüm bölüm markdown karşılığıdır. Çelişki/belirsizlik kararları: `docs/decisions.md`.

Garajdan reklam holdingine: bir reklam ajansı yönetim simülasyonu.
Claude Code ile geliştirilmek üzere hazırlanmış eksiksiz proje rehberi.

- **Çalışma adı:** Ajans Tycoon (alternatifler: Brief & Pitch, Mad Ads Tycoon, Billboard Baron, Kampanya!)
- **Tür:** Tycoon / Yönetim simülasyonu · Tek oyunculu · PC (Steam)
- **Motor:** Godot 4 (GDScript) · **Görsel stil:** sıcak, izometrik, stilize "cozy" 3D

## Bir cümlede oyun

Oyuncu 1990'da evinin bir odasında tek kişilik bir reklam ajansı kurar; markalardan gelen brief'leri doğru sektör × kampanya hedefi × hedef kitle × kanal kombinasyonuyla, doğru ekip ve doğru bütçe dağılımıyla kampanyaya dönüştürür; matbaalarla pazarlık eder, pitch'lerde rakip ajansları yener, ödüller toplar, her dönemin yeni mecralarına (internet, sosyal medya, influencer, yapay zekâ…) uyum sağlar ve 2030'larda küresel bir reklam holdingi olmaya çalışır.

## İçindekiler

| # | Bölüm | Dosya |
|---|---|---|
| 1 | Bu doküman nasıl kullanılır (Claude Code için) | [01-kullanim.md](01-kullanim.md) |
| 2 | Oyun vizyonu ve tasarım sütunları | [02-vizyon.md](02-vizyon.md) |
| 3 | Referans oyun analizi (Game Dev Tycoon, Mad Games Tycoon 2, Startup Company) | [03-referans-oyunlar.md](03-referans-oyunlar.md) |
| 4 | Çekirdek oyun döngüsü | [04-cekirdek-dongu.md](04-cekirdek-dongu.md) |
| 5 | Zaman, dönemler ve teknoloji ağacı | [05-zaman-donemler.md](05-zaman-donemler.md) |
| 6 | Müşteriler (markalar) ve brief sistemi | [06-musteriler-brief.md](06-musteriler-brief.md) |
| 7 | Kampanya oluşturma ve puanlama algoritması | [07-puanlama.md](07-puanlama.md) |
| 8 | Uyum tabloları (Sektör × Hedef × Kitle × Kanal) | [08-uyum-tablolari.md](08-uyum-tablolari.md) |
| 9 | Kanallar: baskı, OOH, gerilla, dijital, influencer, etkinlik… | [09-kanallar.md](09-kanallar.md) |
| 10 | Tedarikçiler, matbaalar, medya satın alma | [10-tedarikciler.md](10-tedarikciler.md) |
| 11 | Departmanlar, pozisyonlar ve çalışanlar | [11-calisanlar.md](11-calisanlar.md) |
| 12 | Ofisler, odalar, mobilya, donanım ve yazılım abonelikleri | [12-ofis-mobilya-yazilim.md](12-ofis-mobilya-yazilim.md) |
| 13 | Ekonomi ve finans | [13-ekonomi.md](13-ekonomi.md) |
| 14 | Yeni iş: pitch, rakip ajanslar, itibar | [14-pitch-rakipler-itibar.md](14-pitch-rakipler-itibar.md) |
| 15 | Ödüller, festivaller ve PR | [15-oduller.md](15-oduller.md) |
| 16 | Rastgele olaylar ve krizler | [16-olaylar.md](16-olaylar.md) |
| 17 | Araştırma (Ar-Ge) ve kilit açma sistemi | [17-arge.md](17-arge.md) |
| 18 | Geç oyun (late game) içerikleri | [18-gec-oyun.md](18-gec-oyun.md) |
| 19 | Başarımlar (achievements) ve easter egg'ler | [19-basarimlar.md](19-basarimlar.md) |
| 20 | Arayüz (UI/UX) ekranları | [20-arayuz.md](20-arayuz.md) |
| 21 | Sanat yönü ve yapay zekâ ile asset üretim hattı | [21-sanat.md](21-sanat.md) |
| 22 | Ses ve müzik | [22-ses-muzik.md](22-ses-muzik.md) |
| 23 | Oyun motoru seçimi: neden Godot? | [23-motor-secimi.md](23-motor-secimi.md) |
| 24 | Teknik mimari, klasör yapısı, veri şemaları | [24-teknik-mimari.md](24-teknik-mimari.md) |
| 25 | Claude Code çalışma düzeni + CLAUDE.md şablonu | [25-claude-code.md](25-claude-code.md) |
| 26 | Yol haritası: kilometre taşları ve hazır promptlar | [26-yol-haritasi.md](26-yol-haritasi.md) |
| 27 | Denge (balance), test ve simülasyon | [27-denge-test.md](27-denge-test.md) |
| 28 | Senin aklına gelmeyen ama gereken her şey | [28-ek-konular.md](28-ek-konular.md) |
| 29 | Ekler: sabitler, sözlük, kontrol listeleri | [29-ekler.md](29-ekler.md) |
