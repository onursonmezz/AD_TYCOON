# Ses ve müzik: dosya rehberi

Oyunda şu an duyduğun bütün sesler kodla üretilmiş **yer tutuculardır**: bip, tık, ka-ching. Gerçek bir ses dosyasını doğru adla doğru klasöre koyduğunda oyun o dosyayı kullanır; kod gerekmez. Müzik dosyası yoksa müzik çalmaz.

Godot editörünü bir kez açıp kapatman (ya da `godot --headless --import`) yeni dosyaları içe aktarır.

## Biçimler

- **Müzik ve uzun ortam sesleri:** `.ogg` (Ogg Vorbis; küçük ve döngüye uygun).
- **Kısa efektler:** `.ogg` ya da `.wav`.
- `.mp3` da çalışır, ama `.ogg` önerilir.
- Ses seviyesini dosyada normalize et: tepe yaklaşık −1 dB, efektler arasında büyük ses farkı olmasın.

## Efektler (`assets/audio/sfx/`)

Dosya adı = sesin adı. Örneğin `money.ogg`, kodla üretilen "money" sesinin yerine geçer.

| Ad | Ne zaman çalar | Öneri |
|---|---|---|
| `click` | Her düğmeye basınca | Çok kısa, yumuşak tık |
| `notify_pager` | Bildirim, 1990–1997 | Çağrı cihazı bip-bip-bip |
| `notify_sms` | Bildirim, 1998–2007 | Eski cep telefonu SMS sesi |
| `notify_ding` | Bildirim, 2008–2019 | Tek "ding" |
| `notify_soft` | Bildirim, 2020+ | Yumuşak iki notalı uyarı |
| `bad` | Kötü haber (müşteri kaybı vb.) | Alçalan, kısa |
| `fax` | Yeni brief, 1990–1999 | Faks cızırtısı |
| `mail` | Yeni brief, 2000+ | E-posta "ding-dong" |
| `money` | Nakit girişi (fatura tahsil) | Yazar kasa "ka-ching" |
| `report` | Kampanya raporu | Kısa olumlu iki nota |
| `cheer` | Yüksek puan, seviye atlama, araştırma bitti | Küçük fanfar |
| `applause` | Ödül töreni | 1–2 sn alkış |
| `event` | Olay penceresi açılınca | Dikkat çeken üç nota |
| `pop` | (yedek) | Kısa "pop" |
| `save` | Oyun kaydedildi | Kısa onay |
| `ambient_typing` | Ofis ortamı (döngü) | 10–30 sn klavye ve ofis uğultusu, **döngüye uygun** (başı ve sonu birleşince tık sesi olmasın) |

Hangi sesin ne zaman çaldığı ve dönemsel varyantlar `data/sounds.json`'da yazar.

## Müzik (`assets/audio/music/<dönem>/`)

Her dönemin kendi klasörü var. O dönemde klasördeki parçalar karışık sırayla çalar; parça değişirken ses yavaşça geçer. Bir dönemin klasörü boşsa `assets/audio/music/` kökündeki parçalar çalar.

| Klasör | Yıllar | Hava (GDD 22) |
|---|---|---|
| `classic/` | 1990–1996 | Synth-pop esintili, rahat |
| `web_dawn/` | 1997–2004 | Hafif elektronik |
| `social_birth/` | 2005–2010 | Elektronik / indie geçişi |
| `mobile/` | 2011–2016 | Indie |
| `creator/` | 2017–2022 | Lo-fi / jazz-hop |
| `ai/` | 2023–2029 | Lo-fi, sıcak |
| `future/` | 2030+ | Yumuşak synth |

Her dönem için 2–4 parça, 2–3 dakika uzunluğunda olsun; parçalar sözsüz olsun.

## Kaynaklar ve lisans (GDD 22, 28)

- **freesound.org:** Her sesin lisansını tek tek kontrol et. CC0 en rahatı; CC-BY ad vermeyi gerektirir; "NonCommercial" olanları **kullanma**.
- **Satın alınan paketler** (ör. itch.io, Humble): ticari oyunda kullanıma izin verdiklerinden emin ol.
- **AI müzik araçları:** Yalnızca ticari lisans veren ücretli planlar. Şartları kaydet.
- Her dosyayı `art/audio_log.csv`'ye yaz: dosya, kaynak, lisans, ad verme gerekli mi, tarih. Steam ve oyunun "Katkıda bulunanlar" ekranı için gerekli.

## Kontrol

1. Dosyayı koy, Godot'yu bir kez aç-kapat.
2. Oyunu aç ve sesi tetikle (ör. bir düğmeye bas, bir fatura tahsil et).
3. Ses seviyeleri: **Ayarlar** → Ses. Müzik, efektler ve ofis ortamı ayrı ayrı ayarlanır.
