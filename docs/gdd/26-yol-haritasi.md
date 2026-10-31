# 26 Yol haritası: kilometre taşları

Süreler, haftada ~15–20 saat ayıran tek kişi + Claude Code için tahmindir. Toplam MVP/demo: ~4–5 ay; tam sürüm: ~10–14 ay. Her taşın sonunda oyunu oyna ve not al.

| # | Kilometre taşı | Süre | Çıktı |
|---|---|---|---|
| M0 | Kurulum & iskelet | 3–5 gün | Repo, CLAUDE.md, klasörler, GDD markdown, boş Godot projesi, test altyapısı |
| M1 | Simülasyon çekirdeği (görselsiz) | 2 hafta | Zaman, ekonomi, müşteri, brief, kampanya puanlama; headless 10 yıllık bot oyunu |
| M2 | Oynanabilir 2D prototip | 2 hafta | Menülerle tam döngü: brief → kampanya → rapor → para. "Eğlenceli mi?" testi |
| M3 | Çalışanlar & departmanlar | 2 hafta | İşe alım, statlar, eğitim, moral, enerji, puan üretimi |
| M4 | Kanallar, tedarikçiler, medya | 2 hafta | Kanal karışımı, matbaa/OOH/influencer mekanikleri, KPI |
| M5 | Pitch, rakipler, itibar, ödüller | 2 hafta | Pitch mini oyunu, rakip AI, festivaller |
| M6 | 3D ofis (gri kutu) | 3 hafta | İzometrik kamera, oda inşası, karakterler masaya gidip çalışıyor, baloncuklar |
| M7 | Dönemler, Ar-Ge, olaylar | 2 hafta | 1990–2035 içerik akışı, araçlar, olay sistemi, bilgi defteri |
| M8 | Sanat geçişi (AI asset'leri) | 3–4 hafta (M6'dan itibaren paralel) | Stil incili, MVP asset listesi, karakterler, UI teması |
| M9 | Cila: ses, tutorial, kayıt, yerelleştirme | 2 hafta | Eğitici, kayıt slotları, TR/EN, ayarlar, juice |
| M10 | Denge & playtest, Steam sayfası, demo | 3–4 hafta | Denge simülasyonları, 5–10 dış oyuncu testi, Steam sayfası, demo |
| M11 | Tam içerik + geç oyun | 2–3 ay | Tüm sektör/kanal/dönemler, holding, global, başarımlar, Steamworks |
| M12 | Çıkış (Erken Erişim veya 1.0) | — | Yayın, güncelleme planı, topluluk |

## M0 — Kurulum & iskelet

> **CLAUDE CODE PROMPT**
>
> docs/GDD.pdf'i oku. (1) Bölüm 24.2'deki klasör yapısıyla bir Godot 4 projesi oluştur (en güncel kararlı 4.x; sürümü CLAUDE.md'ye yaz). (2) Bölüm 25.2'deki CLAUDE.md'yi oluştur. (3) GDD'yi bölüm bölüm docs/gdd/*.md dosyalarına dönüştür; uyum tablolarını (Bölüm 8) data/fit/*.json olarak, sektör/hedef/kitle/ton/kanal listelerini ilgili data/*.json dosyalarına aktar. (4) GUT test eklentisini kur, örnek bir test yaz ve headless çalıştır. (5) tools/validate_data.gd yaz: tüm JSON'ları yükleyip id tutarlılığını ve Bölüm 8.0'daki satır dağılım kuralını (her satırda tek +++, en az bir −−/−−−) kontrol etsin. (6) .gitignore ekle, git init, ilk commit. Bitince bana Godot'yu nasıl açıp projeyi nasıl çalıştıracağımı adım adım anlat.

**Kabul:** Proje Godot'da hatasız açılıyor · test ve veri doğrulama komutları başarılı · tablolar JSON'da birebir · bilerek bozulmuş bir satır (ör. tamamen yeşil) doğrulamada hata veriyor.

## M1 — Simülasyon çekirdeği

> **CLAUDE CODE PROMPT**
>
> GDD Bölüm 5, 6, 7 ve 13'ü oku. src/sim altında Node'a bağımlı olmayan simülasyon çekirdeğini yaz: Clock (hafta/ay/yıl tick), Economy (nakit, aylık giderler, enflasyon), ClientSystem + BriefGenerator (mevsimsellik dahil), Campaign + Scoring (7.2–7.9 formülleri: M, F, B, N, sinerji, göreceli 1–10 puan, yumuşak rekor güncelleme), KPI (7.10) ve gelir (7.11). Şimdilik çalışanları "oyuncu karakteri" tek kişi olarak basitleştir. Tüm sabitler data/balance.json'da. Scoring için kapsamlı birim testleri yaz (ör. +++ kombinasyon −−−'den yüksek puan almalı; aynı kombinasyon tekrarı N cezası almalı; S/K ideal orana yakınsa B≈1). tools/balance_sim.gd: basit bir bot 1990'dan 10 yıl oynasın (rastgele bot ve "tabloyu bilen" açgözlü bot), sonuçları (nakit eğrisi, ortalama puan, iflas oranı) konsola tablo olarak yazsın.

**Kabul:** Akıllı bot rastgele bottan belirgin şekilde iyi (ortalama puan farkı ≥ 2) · rastgele bot ilk 3 yılda %20–40 oranında iflas ediyor · testler geçiyor.

## M2 — Oynanabilir 2D prototip

> **CLAUDE CODE PROMPT**
>
> GDD Bölüm 20'yi oku. Sade bir UI ile oynanabilir prototip yap (3D yok): üst bar (nakit, tarih, hız), gelen kutusu (brief'ler), müşteri listesi, kampanya sihirbazı (hedef/kitle/ton/tek kanal/büyüklük), 3 fazlı slider ekranı (canlı S/K/T sayaçları), kampanya raporu (animasyonlu puan, 4 yorum cümlesi, KPI kartları, Bölüm 7.12 açıklama cümleleri), finans özeti. Basit bir Theme oluştur (krem zemin, adaçayı yeşili başlıklar, yuvarlak köşe). Tüm metinler strings.csv'de. Oyun 1990'da ev odasında başlasın; iflas ekranı ve "yeni oyun" olsun. Kayıt/yükleme (tek slot) ekle.

**Kabul:** 30 dakika oynadığında "bir kampanya daha" hissi var mı? Yoksa M3'e geçmeden önce Bölüm 7 formüllerini ve tabloları birlikte ayarlayın. Bu, projenin en önemli kontrol noktasıdır.

## M3 — Çalışanlar & departmanlar

> **CLAUDE CODE PROMPT**
>
> GDD Bölüm 11'i oku. Çalışan modelini (statlar, gizli statlar, enerji, moral, tükenmişlik, XP/seviye, özellikler, uzmanlaşma), işe alım ekranı (kanallara göre aday havuzu), eğitim, kovma, maaş/piyasa değeri ve rakip teklif olayını uygula. Puan üretimini Bölüm 7.5'e göre çalışan bazlı yap; kampanyaya ekip atama ekranı ekle. Pozisyonlar data/positions.json, özellikler data/traits.json. Testler: uzman çalışan kendi alanında daha çok puan üretmeli; fazla mesai tükenmişliği artırmalı.

## M4 — Kanallar, tedarikçiler, medya

> **CLAUDE CODE PROMPT**
>
> GDD Bölüm 8.4, 9 ve 10'u oku. Çoklu kanal karışımını (bütçe yüzdesi slider'ları, sinerji ve parçalanma), kanal yaşam eğrilerini, matbaa fiyat modelini (ölçek ekonomisi, prova, hata), gelen tedarikçi teklifleri ve 3 turluk pazarlık mini oyununu, OOH lokasyon paketlerini, influencer havuzunu (sahte takipçi, skandal) ve etkinlik kararlarını uygula. Her kanal kategorisinin ek seçenekleri "Otomatik" varsayılanla gelsin. KPI'ları kanal bazında rapora ekle.

## M5 — Pitch, rakipler, itibar, ödüller

> **CLAUDE CODE PROMPT**
>
> GDD Bölüm 14 ve 15'i oku. İtibar sistemini, pitch davetlerini, pitch hazırlığını ve kart tabanlı sunum mini oyununu (müşteri tepki baloncuklarıyla), rakip ajans AI'ını (aylık güç skoru, büyüme/batma, transfer/müşteri çalma olayları), yıllık sıralamaları ve ödül başvuru + tören akışını uygula. Rakipler data/rivals.json, ödüller data/awards.json.

## M6 — 3D ofis (gri kutu)

> **CLAUDE CODE PROMPT**
>
> GDD Bölüm 12 ve 21.1'i oku. src/world altında 3D ofis sahnesi kur: izometrik kamera (90° döndürme, zoom, kaydırma), ızgara tabanlı oda çizme ve mobilya yerleştirme (inşa modu), kutu/kapsül placeholder modeller. Karakterler (kapsül) masalarına yürüsün (NavigationAgent3D), çalışırken başlarından S/K/T/hata baloncukları çıksın, yorgunken mutfağa gitsin. Simülasyon ile bağlantı sadece EventBus ve GameState okuma ile olsun. Ofis seviyeleri arası geçişte yeni bina sahnesi yüklensin. Sahneleri metin dosyası olarak oluştur; editörde yapmam gereken bir şey varsa adım adım anlat.

## M7 — Dönemler, Ar-Ge, olaylar

> **CLAUDE CODE PROMPT**
>
> GDD Bölüm 5, 16, 17'yi oku. eras.json, research.json, tools.json, hardware.json ve events/*.json'u doldur (her kategoride en az 10 olay). Dönem geçişlerinde bildirim + kısa "yeni dönem" ekranı, kanal/araç kilit açmaları, yazılım sürüm güncellemeleri ve abonelik geçişi, Bilgi Defteri ekranı (keşfedilen uyum hücreleri), mevsimsel takvim. Olay sistemi veri odaklı olsun (Bölüm 16'daki JSON formatı, stat kontrolü olan seçenekler dahil).

## M8 — Sanat geçişi

Bu taş büyük ölçüde senin işin (AI araçları + Blender). Claude'un rolü:

> **CLAUDE CODE PROMPT**
>
> art/ klasöründe Bölüm 21'e göre style_bible.md ve asset_log.csv şablonunu oluştur. assets/models altına koyduğum .glb dosyalarını sahnedeki placeholder'larla değiştirecek bir sistem kur: data/furniture.json'da her mobilyanın model yolu olsun. Karakterler için modüler sistem: temel gövde + saç + kıyafet + renk shader'ı. Animasyonları AnimationTree ile bağla (yürü, otur, yaz, telefon, kahve, sevin, stres). Ofis önündeki billboard'a ve duvar posterlerine oyuncunun kampanyalarından prosedürel key visual (şablon + marka rengi + slogan) basan bir SubViewport sistemi yaz.

## M9 — Cila

> **CLAUDE CODE PROMPT**
>
> Bölüm 20, 22 ve 24.5'i oku. Etkileşimli tutorial (ilk 3 kampanya boyunca ipuçları, atlanabilir), 3 kayıt slotu + otomatik kayıt + sürüm göçü, ayarlar menüsü (ses kanalları, dil, çözünürlük, metin boyutu), müzik/SFX yöneticisi ve dönemsel playlist, "juice" (puan sayma animasyonu, konfeti, para sesi, bildirim kayması), tüm metinlerin İngilizce çevirisi. Performans profili çıkar: 60 çalışanla 60 FPS hedefi.

## M10 — Denge, playtest, Steam, demo

> **CLAUDE CODE PROMPT**
>
> Bölüm 27'yi oku. balance_sim.gd'yi genişlet: 4 bot stratejisi, 1000 koşu, hedef metriklerle karşılaştırma tablosu ve docs/balance-report.md çıktısı. Hedef dışı metrikler için balance.json'da önerilen değişiklikleri gerekçeleriyle listele (otomatik uygulama, ben onaylayayım). Ayrıca demo yapısı: 1990–1998 arası oynanabilir, sonra "tam oyunu istek listene ekle" ekranı. Windows dışa aktarma ayarlarını yap.

## M11–M12 — Tam içerik, Steamworks, çıkış

Tüm sektör/kanal/dönem içeriği, holding & satın almalar, global ağ, kendi markan modülü, başarımlar (GodotSteam), bulut kayıt, çökme raporu, mod klasörü desteği. Erken Erişim mi 1.0 mı kararını M10 playtest sonuçlarına göre ver.
