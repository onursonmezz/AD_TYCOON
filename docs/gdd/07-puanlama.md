# 7 Kampanya oluşturma ve puanlama algoritması

Bu bölüm oyunun kalbidir. Game Dev Tycoon'un mantığını temel alıp müşteri ilişkisi, çoklu kanal ve KPI katmanı ekler. Tüm sayılar başlangıç değerleridir; `data/balance.json` içinde tutulur ve playtest ile ayarlanır.

> Tablo numarası notu: PDF'te 7.2/7.4/7.7'deki bazı tablo atıfları kaymış (sektör × kitle tablosu 8.1'in sağ yarısıdır; odak önemi ve ideal S/K Tablo 8.2'dedir). Satış/Dönüşüm ideal S/K = **1.7** (Tablo 8.2). Bkz. `docs/decisions.md` K-002, K-004.

## 7.1 Kampanya kurulum ekranı (oyuncunun seçtikleri)

1. Kampanya adı (serbest metin — easter egg'ler için önemli).
2. Sektör: Brief'ten gelir (kendi ajans tanıtım kampanyası hariç).
3. Kampanya hedefi (6 adet, GDT'deki "tür"): Bilinirlik, Lansman, Satış/Dönüşüm, Marka Yenileme, Etkileşim/Sadakat, Sosyal Sorumluluk/İtibar. Geç oyunda çift hedef (Multi-Genre karşılığı, ör. Lansman/Satış) açılır.
4. Hedef kitle: Genç (Y), Yetişkin (E), Olgun (O), Kurumsal/B2B (K). "Hedef Kitle Analizi" araştırılmadan önce seçilemez (GDT'deki gibi Y3'te açılır).
5. Ton: Duygusal, Esprili, Bilgilendirici, Cesur/Provokatif, Lüks/Prestijli, Nostaljik. (Marka kişiliği ve sektörle etkileşir.)
6. Kanal karışımı: 1–N kanal ve her birine medya bütçesi yüzdesi. Kanal sayısı ofis seviyesi ve medya planlama yeteneğiyle sınırlı.
7. Büyüklük ve ekip.

## 7.2 Kombinasyon Uyumu (M)

```text
f(x) : −3..+3 uyum değerini çarpana çevirir:
       −3→0.45  −2→0.62  −1→0.82  0→1.00  +1→1.06  +2→1.14  +3→1.25
       (asimetrik: kötü seçim, iyi seçimin ödülünden daha sert cezalandırılır)

uyum_SH   = f(fit[sektör][hedef])                  # Tablo 8.1
uyum_SK   = f(fit_kitle[sektör][kitle])            # Tablo 8.2 (PDF'teki atıf; tablo 8.1'in sağ yarısı)
uyum_KN   = Σ_k pay_k * f( (kanal_hedef[k][hedef] + kanal_kitle[k][kitle]) / 2 )   # Tablo 8.4, bütçe payına göre ağırlıklı
uyum_ton  = f(ton_fit[sektör][ton]) ^ 0.5          # tonun etkisi daha yumuşak
trend     = 1 + Σ aktif_trend_bonusları            # ör. "Nostalji dalgası 2014": Nostaljik ton +%8

M = (uyum_SH^0.35 * uyum_SK^0.25 * uyum_KN^0.30 * uyum_ton^0.10) * trend
```

Geometrik ortalama kullanılır: tek bir çok kötü seçim tüm kampanyayı aşağı çeker, ama tek bir mükemmel seçim her şeyi kurtarmaz. Ceza tarafının asimetrik olması bilinçli: tablolarda olumsuz hücreler artık üçte bir oranında (Bölüm 8.0) ve rastgele seçim yapan oyuncu belirgin şekilde geride kalmalı.

## 7.3 Kanal sinerjisi

Bazı kanallar birlikte kullanıldığında bonus verir (gerçek "360° kampanya" mantığı):

| Kombinasyon | Bonus | Gerekçe |
|---|---|---|
| TV + Arama reklamı (2002+) | +%6 | TV ilgi yaratır, insanlar arar. |
| Billboard + Sosyal medya | +%4 | Fiziksel görünürlük + paylaşım. |
| Etkinlik + Influencer | +%7 | Influencer'lar etkinliği yayar. |
| Gerilla + PR | +%8 | Gerilla haberleşirse etkisi katlanır. |
| Display + Retargeting | +%5 | Dönüşüm kampanyalarında. |
| 5'ten fazla kanal, düşük bütçe | −%3 / fazladan kanal | Bütçe çok parçalanır ("her yerde ama hiçbir yerde"). |

```text
sinerji = 1 + Σ çift_bonusları − parçalanma_cezası
parçalanma_cezası = max(0, kanal_sayısı − önerilen_kanal(bütçe)) * 0.03
önerilen_kanal(bütçe) = 1 + floor(log10(medya_bütçesi / 10_000) * 1.5)
```

## 7.4 Üç faz ve dokuz odak alanı (GDT'nin 3×3 slider sistemi)

| Faz | Odak 1 | Odak 2 | Odak 3 | Ana puan |
|---|---|---|---|---|
| Faz 1: Strateji | Pazar Araştırması | İçgörü (Insight) | Konumlandırma & Mesaj | Ağırlıklı S |
| Faz 2: Kreatif | Büyük Fikir / Konsept | Metin Yazarlığı (Copy) | Görsel Tasarım (Art) | Ağırlıklı K |
| Faz 3: Prodüksiyon & Yayın | Prodüksiyon (çekim, baskı, kodlama) | Medya Planlama | Ölçümleme & Optimizasyon | Ağırlıklı T (Teknik) |

Her fazda oyuncu üç slider'ı (toplam %100) ayarlar. Her kampanya hedefinin her odak için bir önem değeri vardır (PDF'te "Tablo 8.3" yazıyor; doğrusu Tablo 8.2). Doğru odaklanma "odak bonusu" verir:

```text
odak_skoru(faz) = Σ_i slider_i * önem_i      # önem: +++ = 1.0, ++ = 0.7, + = 0.45, ~ = 0.3, − = 0.15, −− = 0.05, −−− = 0
odak_ideal(faz) = en iyi slider dağılımıyla ulaşılabilecek skor (1 tanesine %100 değil; tavan %60 kuralı)
F_faz = 0.80 + 0.40 * (odak_skoru / odak_ideal)     # 0.80..1.20
F = (F_1 * F_2 * F_3)^(1/3)
```

**Kural:** bir slider'a %60'tan fazla verilirse o alanın verimi azalır (azalan getiri) → oyuncuyu dengeye iter.

## 7.5 Puan üretimi (çalışanlar)

Her gün (tick) atanmış her çalışan, o anki fazın odak alanlarına puan üretir:

```text
üretim(çalışan, alan) = taban(=1.0)
    * yetenek(çalışan, alanın_stat'ı)/50                # stat 0–100; 50 = ortalama
    * hız(çalışan)/50
    * araç_çarpanı(alan, yıl, ajansın_yazılımları)      # 0.6..1.6 (Bölüm 12.5)
    * ofis_çarpanı(odanın kalitesi, mobilya)            # 0.85..1.25
    * moral_çarpanı = 0.6 + 0.8*moral/100
    * enerji_çarpanı = enerji<20 ? 0.5 : 1.0
    * uzmanlık_bonusu (pozisyon alanla eşleşirse 1.3; uyumsuzsa 0.6)
    * slider_payı(alan)
```

Alan→stat eşlemesi:

| Alanlar | Stat |
|---|---|
| Pazar Araştırması, İçgörü, Konumlandırma, Medya Planlama, Ölçümleme | → Strateji (S) |
| Konsept, Copy, Görsel Tasarım | → Kreatif (K) |
| Prodüksiyon, Medya Planlama (yarı), Ölçümleme (yarı) | → Teknik (T) |

Ayrıca her üretim bir "hata" (revizyon) olasılığı taşır:

```text
p_hata = 0.06 * (1 − dikkat/100) * (fazla_mesai ? 1.6 : 1) * (acele ? 1.4 : 1)
```

**Görsel geri bildirim:** Çalışanın başından küçük renkli baloncuklar çıkar: mavi S, turuncu K, yeşil T, kırmızı hata (GDT'nin imza hissi). Kampanya kartında S/K/T sayaçları canlı artar.

## 7.6 (İsteğe bağlı derin mod) Ara çıktılar

Startup Company tarzı: puanlar belirli eşiklerde ara çıktıya dönüşür: İçgörü kartı, Slogan, Key Visual, Storyboard, Medya Planı, Baskı Dosyası. Kanallar belirli ara çıktılar ister (TV → Storyboard + Prodüksiyon; Billboard → Key Visual + Slogan; Arama reklamı → Copy + Ölçümleme). Eksik çıktı = o kanalda ceza. Bu mod MVP'de kapalı olabilir; `balance.json → deep_mode: false`.

## 7.7 S/K denge oranı (GDT'nin T/D oranı)

```text
oran  = S_toplam / max(1, K_toplam)
ideal = hedef.ideal_SK                     # Tablo 8.2 (PDF: "Tablo 8.3 (ör. Satış 1.6, Marka Yenileme 0.5)" — Satış için Tablo 8.2'deki 1.7 geçerli)
sapma = |ln(oran / ideal)|
B = 1 − min(0.30, sapma * 0.25)            # 0.70..1.00
```

## 7.8 Tekrar ve yenilik

```text
N = 1.0
if (sektör, hedef) son 3 kampanyanın birinde kullanıldıysa:          N *= 0.88
if (sektör, hedef, ana_kanal) son kampanyayla aynıysa:               N *= 0.75
if aynı müşteriye 12 hafta içinde aynı hedef:                        N *= 0.85   ("devam kampanyası" ancak "Seri Kampanya" Ar-Ge'si ile cezasız)
if yeni çıkmış bir kanalı ilk kullananlardansan (çıkıştan ≤ 2 yıl):  N *= 1.10   ("öncü" bonusu, ödüllere de yarar)
if kampanyada AI araçları ağırlıklı ve yıl ≥ 2026:                   N *= 0.95   ("AI yorgunluğu" — Ar-Ge ile azaltılabilir)
```

## 7.9 Toplam kalite ve 1–10 puan

```text
Ham = (S + K + T) * M * F * B * N * sinerji − hata_sayısı * hata_ağırlığı(yıl)
      # hata_ağırlığı: kampanya büyüdükçe artar; "Kalite Kontrol" (Traffic/Proof) ile hatalar teslimden önce temizlenebilir.

# GDT tarzı GÖRECELİ puan: hem ajansın kendi rekoru hem dönem beklentisi
hedef_puan = max( en_iyi_ham_bu_büyüklükte * 1.05 , dönem_tabanı(yıl, büyüklük) )
dönem_tabanı(yıl, büyüklük) = büyüklük_çarpanı * 120 * 1.085^(yıl − 1990)

r = Ham / hedef_puan
puan_10 = clamp( 10 * r^0.8 − 1.5 + gürültü(±0.4), 1, 10 )   # 1 ondalık
if puan_10 ≥ 9.5 and hata == 0 and r > 1.25: "Mükemmel Kampanya" (10/10) olasılığı açılır

en_iyi_ham güncellemesi: sadece Ham > en_iyi * 1.0 ise; ama GDT'deki gibi rekoru tam yükseltmek yerine
    en_iyi = en_iyi + 0.6*(Ham − en_iyi)   → "çıtayı çok sert yükseltme" (oyuncuyu cezalandırmaz)
```

> **Neden göreceli puan?** Mutlak puanda oyuncu bir kez iyi ekibi kurunca hep 10 alır ve oyun sıkıcılaşır. Göreceli puan sürekli "bir öncekinden daha iyisini yap" baskısı yaratır; GDT'nin bağımlılık yapan döngüsü budur. Çıtanın yumuşak güncellenmesi ise GDT'nin en çok eleştirilen "bir kere 10 aldım, sonra hep 7 alıyorum" sorununu çözer.

## 7.10 Yayın sonuçları: KPI hesapları

```text
for kanal in karışım:
    harcama_k   = medya_bütçesi * pay_k * tedarikçi_verimi_k        # medya satın alma pazarlığı (Bölüm 10)
    CPM_k       = kanal.base_CPM * enflasyon(yıl) * talep(ilgi(kanal,yıl)) * mevsim
    gösterim_k  = harcama_k / CPM_k * 1000
    erişim_k    = kitle_büyüklüğü_k * (1 − e^(−gösterim_k / kitle_büyüklüğü_k))   # doygunluk: aynı kişiye tekrar tekrar göstermek azalan getiri
    etkileşim_k = erişim_k * kanal.base_ER * (0.4 + 0.12*puan_10) * kitle_uyumu_k
    dönüşüm_k   = etkileşim_k * kanal.base_CVR * hedef_çarpanı(Satış=1.5, Bilinirlik=0.4…)

viral_şansı = (puan_10 ≥ 8.5 ? 0.02*(puan_10−8) : 0) * kanal.viral_potansiyeli * ton_bonusu(Esprili/Cesur)
if viral: organik_erişim += erişim_toplam * rand(1.5, 6)          # 2005+ sosyal kanallarda

Bilinirlik artışı (marka metriği) = Σ erişim / pazar_nüfusu * hatırlanma(puan_10)
Müşteri ROI = (dönüşüm * ortalama_sepet(sektör) − toplam_bütçe) / toplam_bütçe
```

Rapor ekranı bu sayıları sade gösterir: Erişim, Etkileşim, Dönüşüm, Bilinirlik +%, Müşteri ROI, KPI hedefi: ✓/✗.

## 7.11 Ajansın kazancı

```text
gelir = fee (sabit)
      + medya_komisyonu = medya_harcaması * komisyon_oranı (varsayılan %15; pazarlıkla %8–17)
      + prodüksiyon_marjı = (müşteriye_fatura − tedarikçi_maliyeti)   # baskı, çekim
      + performans_primi (KPI aşıldıysa fee * 0..%50)
      − kesinti (gecikme cezası, iade)
```

## 7.12 Rapor ekranındaki açıklama cümleleri (Sütun 1: okunabilirlik)

Her çarpan için eşik tabanlı açıklama üretilir. Örnek şablonlar (`data/report_lines.json`):

- `uyum_SH ≥ 1.15`: "Sektör ile kampanya hedefi mükemmel uyumlu." · `≤ 0.85`: "Bu sektörde bu hedef pek işe yaramıyor."
- `B ≤ 0.85 ve oran > ideal`: "Kampanya fazla analitik kaldı, kreatif tarafı zayıf."
- `N ≤ 0.8`: "Jüri ve tüketiciler bu fikri daha önce gördüklerini düşünüyor."
- `parçalanma > 0`: "Bütçe çok fazla kanala bölünmüş."
- `hata > 3`: "Basılı malzemelerde yazım hataları fark edildi."
