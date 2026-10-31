# 16 Rastgele olaylar ve krizler

Olaylar veri odaklıdır (`data/events/*.json`): koşul, olasılık, metin, seçenekler ve her seçeneğin etkisi. Bu yapı sayesinde yüzlerce olay kodsuz eklenebilir ve modlanabilir.

```json
{
    "id": "logo_buyut",
    "trigger": "campaign_review",
    "conditions": { "client.ego": ">=60" },
    "chance": 0.35,
    "title": "Logoyu biraz büyütebilir miyiz?",
    "text": "{client} pazarlama müdürü son onay toplantısında: 'Çok güzel olmuş ama logo biraz daha büyük olsa?'",
    "options": [
        { "label": "Büyütelim", "effects": { "campaign.quality": -0.03, "client.satisfaction": +4 } },
        { "label": "Nazikçe ikna et", "check": { "stat": "account.communication", "dc": 60 },
          "success": { "client.trust": +3 }, "fail": { "client.satisfaction": -5 } },
        { "label": "Asla!", "effects": { "team.morale": +5, "client.satisfaction": -8 } }
    ]
}
```

> Not: Örnekteki `+4` gibi artı işaretli sayılar standart JSON'da geçersizdir; veri dosyalarında `4` yazılır. Ayrıca CLAUDE.md kuralı gereği `title`/`text`/`label` gerçek dosyalarda yerelleştirme anahtarı olacaktır (M7). Bkz. `docs/decisions.md`.

## 16.1 Olay kategorileri ve örnekler

| Kategori | Örnekler |
|---|---|
| Müşteri | "Logoyu büyüt", son dakika brief değişikliği, ödeme gecikmesi, müşteri pazarlama müdürü değişti (yeni müdür yeni ajans ister!), müşterinin CEO'su kampanyayı çok sevdi (bonus), müşteri birleşmesi. |
| Çalışan | Zam talebi, rakipten teklif, tükenmişlik, evlilik/doğum izni, iki çalışan arasında gerginlik, çalışan yan iş yapıyor, ünlü çalışan TV programına çıktı (itibar +). |
| Prodüksiyon | Baskı hatası, çekim günü yağmur, oyuncu sette sorun çıkardı, sunucu çöktü, dosya kayboldu (yedekleme Ar-Ge'si). |
| Kriz | Sosyal medya linci (yanlış anlaşılan reklam), yayın kurulu reklamı durdurdu, influencer skandalı, rakip ajans intihal suçlaması, veri ihlali (dijital çağ). |
| Fırsat | Reklamınız viral oldu, bir TV programı ajansınızı belgesele konu etmek istiyor, ünlü bir yönetmen sizinle çalışmak istiyor, "son dakika" büyük brief. |
| Makro / dönem | Ekonomik kriz, para reformu, yeni platform çıktı, Büyük Kapanma, seçim dönemi (OOH doluluk), dünya kupası (spor sponsorluk talebi). |
| Mizah | Ofiste kedi doğurdu (moral +), çaycı emekli oluyor, ajansın "ilk faks makinesi" bozuldu, stajyer yanlışlıkla taslağı müşteriye gönderdi. |
