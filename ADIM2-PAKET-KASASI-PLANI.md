# Adım 2 — Paket soruları kilitli kasaya: plan, sıra, bedel (15.09.2026)

> Cem 14.09: "Adım 2 kart ödemesi onayıyla aynı haftaya." Bu belge o gün **bekleme olmadan** başlamak için yazıldı.
> Rakamlar 14–15.09 ölçümünden; ölçülmeyen "ölçülmedi" yazar.

## 0. Bugünkü durum (ölçüldü)
- **Açıkta paket içeriği:** 33 dosya / 5.208 soru (içerik nöbetçisi, 14.09).
  17 Kaydır-Çöz sayfası `kaydir/sgs/*.html` (toplam **53,4 MB**, soru başına ortalama ~14 KB) + 10 deneme seti + arşiv/örnek dosyaları.
- **Adım 1 kapısı** (`paket-kapisi.js`) yalnız **görüntüde** kilit: dosyayı doğrudan indiren her şeyi alır.
- **Soruların asıl kaynağı zaten kilitli:** Supabase `kalip_parti` (yalnız sunucu anahtarı okur).
- **Ücretsiz katman da cevap dağıtıyor:** seviye testi havuzu 450 soru, cevaplarıyla `veri/seviye/sgs-havuz.json`'da açık.
- **Paket kuralı eksik:** `soru_havuzu` politikası paketin **süresine** bakıyor, **hangi dersleri** aldığına (`paket_uyeler.dersler`) bakmıyor.
- **Yayındaki soruların kalitesi:** 3.809 sorudan 4'ünün ret kaydı var, dördü de Matematik, sınıf "kaynak eksik".
  Cevaplar bağımsız hesapla doğrulandı: 210 · 348 · 18 · 15, dördü doğru. Seçim adımı ret kütüğüne bakmıyor (bkz. 6).

## 1. Hedef mimari
```
Soru robotu ──(sunucu anahtarı)──► Supabase  paket_soru  (RLS)
                                         │
     giriş yapmış + aktif paketli üye ◄──┘  (ders ders, sayfalı çekim)
     anonim ziyaretçi ◄── yalnız ucretsiz=true satırlar (vitrin + seviye testi soruları, CEVAPSIZ)
Depo / GitHub Pages: yalnız sayfa KABUĞU (soru yok) + kimlik dosyaları (sıra, id)
```

## 2. İş sırası

| # | İş | Ayrıntı | Süre (tahmin) |
|---|---|---|---|
| 1 | **Tablo + kurallar** | `paket_soru(id pk "etiket/kp-NN", sinav, ders, konu, sira, veri jsonb, ucretsiz bool, guncelleme)`. RLS: okuma = aktif paket + (paket tam **ya da** ders `paket_uyeler.dersler` içinde); `ucretsiz` satırlar anonim okunur ama `veri`'den doğru şık ve açıklama çıkarılmış görünümle. DDL düşük trafik saatinde, eşzamanlı sağlık izlemesiyle (14.09 PostgREST 503 dersi). `UYGULANDI.md`'ye satır. | 1–2 saat |
| 2 | **Yükleyici** | `motor/kasa-soru-yukle.js`: Kaydır-Çöz basımındaki soru nesnelerini `paket_soru`'ya upsert eder. `yayin-bas.yml` içinde sayfa basımından hemen sonra koşar (secret zaten var). Kuru koşu + sayım kapısı: yüklenen = basılan. | yarım gün |
| 3 | **Sayfa kabuğu** | `kaydir-coz.ps1` şablonuna kasa modu: `SORULAR` gömülmez; sayfa oturumla kasadan ders sorularını 50'şerli çeker. **EŞDEĞERLİK PROVASI:** kasadan gelen 3.809 sorunun tamamı, bugünkü gömülü nesneyle alan alan aynı olmalı; fark = 0 değilse yayın yok. | 1 gün |
| 4 | **Deneme ve "sınav gibi"** | Set dosyaları yalnız kimlik ve sıra taşır; sorular kasadan kimlikle çekilir. | yarım gün |
| 5 | **Seviye testi** | Soru istemcide cevapsız gelir; doğru mu kontrolü sunucuda: `seviye_kontrol(id, secim)` fonksiyonu, IP başına hız sınırıyla. Böylece ücretsiz test cevap dağıtmaz. | yarım gün |
| 6 | **Kalite kapısı** | Seçim adımı (`sgs-650-bas.ps1`) ret kütüğündeki kimliği seçmez. Ya da seçerse gerekçesi yazılı "kurtarma" işareti ister. İçerik nöbetçisine "yayında ret kaydı olan soru" satırı eklenir. | 2 saat |
| 7 | **Depodan çıkarma** | 17 sayfa kabukla değişir; deneme setleri kimlik dosyası olur; arşiv ve örnek soru dosyaları git dışındaki kasaya taşınır. İçerik nöbetçisinin tabanı **boşaltılır** → YEŞİL. | 1–2 saat |
| 8 | **Geçmiş temizliği** | [[gecmis-temizligi]] reçetesi: izole çıplak klon, soru dosyalarının geçmişten silinmesi, robot commit'lerinin taşınması, `--force-with-lease` ile gönderim. 20.08'de 4.095 commit ~105 dk sürdü. **Canlı klasörde yapılmaz.** GitHub önbelleği için Support'tan temizlik istenebilir. | 3–4 saat |

**Toplam:** yaklaşık 3–4 iş günü. 1–7 site kesintisiz yapılır. 8 tek pencerede, robotlar açıkken güvenli reçeteyle yapılır.

## 3. Bedel
- **Ek para: 0 TL (öngörü).** Supabase Pro zaten ödeniyor; plan 250 GB çıkış trafiği içeriyor.
  Kaba üst sınır: 1.000 aktif öğrencinin her biri bankanın tamamını bir kez indirse 1.000 × 3.809 × ~14 KB ≈ 53 GB.
  Gerçek kullanım ölçülmedi.
- **Performans riski:** veritabanı işlemcisi en küçük boyda (NANO). Sınav haftası yükü ölçülmedi.
  3. adımdan sonra 50 eşzamanlı çekimle yük provası yapılır; gerekirse o hafta işlemci yükseltilir, bedeli o gün sorulur.

## 4. Riskler ve frenler
- **Sayfa açılmazsa satış durur.** Kasa modu önce tek derste (Türkçe, 77 soru) açılır, bir gün izlenir, sonra hepsine yayılır.
  Geri dönüş: eski gömülü sayfalar git geçmişinde; tek commit'le geri alınır. Geçmiş temizliği (8) bu yüzden **en son**.
- **Oturum süresi dolan öğrenci** boş sayfa görmesin: kapı zaten "giriş yap" ekranına düşüyor (Adım 1).
- **Önceden indirilmiş kopyalar geri alınamaz.** Adım 2 bundan sonrasını kapatır.

## 5. Cem'in kararı gereken 3 şey
1. **Ders bazlı erişim:** ders paketi alan yalnız aldığı dersleri mi görsün? (Önerim: evet; satış sayfası zaten ders seçtiriyor.)
2. **Seviye testi cevap kontrolü sunucuya taşınsın mı?** (Önerim: evet; yoksa ücretsiz katman 450 soruyu cevabıyla dağıtmaya devam eder.)
3. **Geçmiş temizliği için zorla gönderim onayı** (8. adım; 20.08'deki gibi).
