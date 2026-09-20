# TETİKTE — INSTAGRAM AÇILIŞ PLANI · 30 GÜN

> Karar tarihi **21.09.2026**. Cem: *"pazarlama direktörü olarak plan yap, onu yapalım."*
> Bu dosya planın TEK nüshasıdır. Değişiklik Cem onayıyla, tarih düşülerek yapılır.
> Ölçüm rakamları hafızadan yazılmaz; her sayının kaynağı bu dosyada gösterilir.

---

## 0. DURUM (ölçülmüş, 21.09.2026)

| ne | değer | kaynak |
|---|---|---|
| Yayındaki çözümlü soru | 3.678 | tetikte.com ana sayfa |
| Vitrindeki açık soru | 70 (272 adlandırılmış tuzak) | `kaydir/vitrin/sgs.html` |
| Taranan çıkmış sınav | 35 dönem · 3.248 konu | `veri/siklik-kunyesi.json` |
| 2026 mevzuat değişikliği | 125 adet, **13'ü sınavı etkiliyor** | `arac/mevzuat-degisiklik-suzgeci.ps1` |
| Seviye testi | çalışıyor, 30 soru, e-posta kapısı | `seviye-testi.html` |
| Instagram takipçi | 0 | — |
| SGS sınavına kalan | 61 gün (21 Kasım 2026) | TÜRMOB takvimi |

**Elde hazır duran üretim:** 12 kartlık karne carousel · 3 bölümlük maskot dizisi ·
yakalanma videosu (sorusu değişecek) · kart üretim hattı (`araclar/kayit/kart-bas.js`) ·
kilitli 4 ses · SORU maskotu referansları.

---

## 1. KONUM — tek cümle

> **Rakip soruyu verir, cevabı da verir. Yanlışın ADINI kimse koymaz.**

Bütün içerik bu cümlenin kanıtıdır. Satış yapılmaz, kanıt gösterilir.

---

## 2. NEDEN BU İŞE YARAR (2026 algoritma ölçümü)

Instagram 2026 sıralaması şu sinyalleri ödüllendiriyor, sırayla:
**izlenme oranı → arkadaşa gönderme (send) → kaydetme (save) → içerikte geçen süre.**
Beğeni en zayıf sinyal. Takipçi sayısı değil, **niş derinliği ve tutarlılık** belirleyici.

Sonuç: içerik "izlensin" diye değil, **"kaydedilsin ve gönderilsin"** diye tasarlanır.

| içerik türü | ne kazandırır | format |
|---|---|---|
| Sıklık karnesi (35 sınav) | **save + send** | carousel |
| Tuzak / yakalanma | izlenme + yorum | Reels |
| Mevzuat değişikliği | send + otorite | Reels |
| Maskot dizisi | takip + marka kimliği | Reels |
| Seviye testi | **e-posta** | Reels + story |

---

## 3. GÖRSEL KURALLAR — dikkati ne çeker

1. **İlk kare hareket ya da tek büyük rakam.** Yazı kartıyla açılmak yasak.
2. **Tek vurgu rengi:** amber (`#f5a524`). Kırmızı yalnız "yanlış", yeşil yalnız "doğru".
3. **Sade zemin** (`#fbfaf8`), bol boşluk. Kalabalık kart kaydırılır.
4. **İnsan yüzü yok, KARAKTER var** (SORU maskotu). Yüz yasağı marka kuralı.
5. **Her görselin altında ölçüm tarihi + kaynak.** Rakip "güncel" der, biz tarih yazarız.
6. **Telefon güvenli alanı:** altyazı tabanı y=1440, satır 30 karakter; üst 220 / alt 420 /
   sağ 150×500 bölgeleri Instagram arayüzüne ayrılmıştır.
7. Videoda **süre söylenmez**, rakam söylenir. "30 dakika" caydırır, "30 soru" çeker.

---

## 4. 30 GÜNLÜK TAKVİM

Günde **1 gönderi**, haftada **1 dinlenme günü**. Her gönderiden sonra 3 story.

### HAFTA 1 — OTORİTE ("biz ölçüyoruz")
| gün | gönderi | format | bedel |
|---|---|---|---|
| 1 | **35 Sınavın Karnesi — Muhasebe ilk 10** | carousel (HAZIR) | 0 |
| 2 | Aynı veri, Reels: "35 sınav, ilk 3 konu" | Reels | 0 |
| 3 | 35 Sınavın Karnesi — **Hukuk ilk 10** | carousel | 0 |
| 4 | Tuzak kartı: en sık çıkan konunun tuzağı | carousel | 0 |
| 5 | **Yakalanma videosu** (soru değişmiş hâli) | Reels | ≈3,7 USD |
| 6 | 35 Sınavın Karnesi — **Ekonomi + Maliye** | carousel | 0 |
| 7 | dinlenme / story | — | 0 |

### HAFTA 2 — YAKALANMA ("sen bunu yanlış yapıyorsun")
Vitrindeki 70 sorudan seçilir; her biri **pazarlama soru kapısından** geçer
(`arac/pazarlama-soru-kapisi.ps1` — VUK/TMS çatallı soru kullanılmaz).
| gün | gönderi | format |
|---|---|---|
| 8 | Tuzak Reels 1 (maskot sorar, izleyen düşer) | Reels ≈3,7 USD |
| 9 | "Bu tuzağa düşenler" carousel | 0 |
| 10 | Maskot dizi **Bölüm 1** (hazır) | Reels 0 |
| 11 | Tuzak Reels 2 | Reels ≈3,7 USD |
| 12 | Sıklık karnesi — **Yeterlilik sınavı** | carousel 0 |
| 13 | Maskot dizi **Bölüm 2** (hazır) | Reels 0 |
| 14 | dinlenme | — |

### HAFTA 3 — NÖBET ("kitabın eski")
13 sınav-etkili 2026 değişikliğinden seçilir.
| gün | gönderi | format |
|---|---|---|
| 15 | **Kanuni faiz artık sabit değil** (7589) | Reels ≈3,7 USD |
| 16 | "16 Temmuz'da bir kanun çıktı, üç kanunu değiştirdi" | carousel 0 |
| 17 | **Üretimde kurumlar vergisi %12,5** (7582) | Reels ≈3,7 USD |
| 18 | Maskot dizi **Bölüm 3** (hazır) | Reels 0 |
| 19 | Sıklık karnesi — **KGK sınavı** | carousel 0 |
| 20 | Tuzak Reels 3 | Reels ≈3,7 USD |
| 21 | dinlenme | — |

### HAFTA 4 — KAPI ("ölç kendini")
| gün | gönderi | format |
|---|---|---|
| 22 | **Seviye testi Reels**: "Sınava bugün girsen ne olurdu? 30 soru." | Reels ≈3,7 USD |
| 23 | "30 soruda ne ölçülüyor" carousel | 0 |
| 24 | Tuzak Reels 4 | Reels ≈3,7 USD |
| 25 | Kullanıcı sonuçlarından karne (veri birikmişse) | carousel 0 |
| 26 | Mevzuat değişikliği 3 | Reels ≈3,7 USD |
| 27 | **Paket duyurusu** — ilk 500 kuruluş fiyatı | carousel 0 |
| 28-30 | ölçüm + en iyi 3 gönderinin tekrar kurgusu | 0 |

**Toplam üretim bedeli: ≈33 USD** (9 yeni klip × 3,7). Geri kalan her şey 0.

---

## 5. ÖLÇÜM VE KARAR NOKTALARI

Her hafta sonu şu dört sayı yazılır (tahmin değil, panelden):

| ölçüt | neden |
|---|---|
| Erişim (reach) | içerik yeni insana ulaşıyor mu |
| **Gönderme (send)** | en güçlü ikinci sinyal |
| **Kaydetme (save)** | değer taşıyor mu |
| Profil ziyareti → link tıklaması | kapıya kaç kişi geliyor |

**Karar kapıları:**
- **7. gün:** en çok send alan format hangisi? Sonraki hafta ona ağırlık verilir.
- **14. gün:** takipçi 300'ü geçmediyse kreatif değil **kanca** değiştirilir.
- **21. gün:** organik tavan ölçülmüş olur → reklam kararı bu rakamla verilir.
- **28. gün:** test reklamı (5.000 TL) en iyi kreatife basılır → **gerçek CPL** ölçülür.

---

## 6. 5.000 ÜYE HEDEFİ — dürüst tablo

Piyasa verisi (2026 TR): CPM ₺40–85 · CPC ₺4–10,50 · **lead başına ₺65–180**.

| yol | bir haftada | 5.000 üye ne zaman / ne kadar |
|---|---|---|
| Organik (bu plan) | 20–150 üye | ~10–15 ay |
| Organik + viral | 300–800 üye | ~6-8 ay |
| **Reklam** | bütçeye bağlı | **325.000 – 900.000 TL** |

**Bir haftada 5.000 üye yalnız ödemeli reklamla olur.** Bu planın işi, reklamı
ucuzlatan şeyi üretmek: **çalıştığı ölçülmüş kreatif.** Kötü kreatife basılan
reklam CPL'i ikiye katlar; 28 günlük organik test bu yüzden reklamdan önce gelir.

---

## 7. CEM'İN YAPACAKLARI (bende değil, sende)

| iş | neden | ne zaman |
|---|---|---|
| Instagram profili: ad, bio, amblem | gönderiden önce | **1. gün** |
| Bio linki → `seviye-testi.html` | tıklayan iki tık atmasın | 1. gün |
| Yorumlara cevap verecek kişi | sahipsiz hesap ölür | 1. gün |
| **Meta reklam hesabı + piksel** | 28. gün testinin ön şartı | 3. hafta |
| **İYS kaydı** (6563) | toplanan e-postaya ileti göndermek için | 3. hafta |
| Sunucu kapasitesi kararı | dalga gelirse ambar yükü | reklamdan önce |
| Test bütçesi 5.000 TL | gerçek CPL ölçümü | 28. gün |

---

## 8. KURALLAR (çiğnenmez)

1. **Çıkmış sınav sorusu paylaşılmaz.** Sorularımız özgün, savunmamız bu.
2. **Pazarlamada "SMMM / mali müşavir" unvanı kullanılmaz.** Cem = "Tetikte'nin kurucusu".
   "Hoca / öğretmen / uzman" yok → **Nöbetçi**.
3. **Uydurma rakam yok.** Geçme oranı, kullanıcı sayısı, "adayların %90'ı" gibi ölçülmemiş
   iddia yazılmaz. Her sayının altında kaynak ve tarih durur.
4. **"Yakında geliyoruz" denmez.** Sınav tarafı açık; kapıyı kapalı gösteren kitle kaybettirir.
5. **Videoya girecek her soru `arac/pazarlama-soru-kapisi.ps1`'den geçer** (VUK/TMS çatalı).
6. **Video metni iki kişilik konuşma, satır satır Cem onayı.** Monolog ve anlatıcı etiketi yasak.
7. **Para harcayan her adım önce bedeliyle sorulur.** Ucuz prova varsa önce o koşar.

---

## 9. İLK 72 SAAT

| ne zaman | ne |
|---|---|
| Bugün | Cem: profil + bio + link · GM: sıklık verisini tazele |
| Bugün akşam 20:00–22:00 | **1. gönderi: Muhasebe karnesi carousel** (hazır) |
| Yarın | GM: karne Reels'i çıkarır (0 USD) · Cem: yorum yanıtları |
| 3. gün | **Hukuk karnesi carousel** + ilk hafta ölçümü başlar |
