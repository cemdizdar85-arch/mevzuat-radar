# Yeterlilik banka açıkları — ölçüm 05.10.2026

> Oturum "sinav · yeterlilik banka açıkları". Girdi: `veri/sinav/smmm-konu-okuma.json` (31 dönem okunarak) + sitedeki 3.820 sorunun okunmuş eşlemesi (site oturumu, ders başına tek okuyucu) + `arac/smmm-kapsama-tablosu.ps1 -SoruKutugu` (f5291110). Soru metni bu dosyada YOK; yalnız kimlik ve sayı.
> ⚠ Okunmuş eşleme ve Denetim okuması TEK okuyucu kararıdır (30.09 ölçümü: tek okuyucunun TEMİZ dediği 10 örnekten 6'sı kusurluydu). Liste öneridir; çekme/taşıma kararı Cem'in.

## 1. Vergi — yıllık beyan ve ücret

| Okunmuş konu | Çıkmışta dönem | Okunmuş hedef | Sitede (çok konulu soru 1/n) | Okunmuş açık | Tablonun açığı (bu konunun sorularının etiketlerinde) |
|---|---:|---:|---:|---:|---:|
| GVK › Yıllık beyan ve gelir vergisi hesabı | 25/31 | 53 | 2.5 | 51 | 15 |
| GVK › Gayrimenkul sermaye iradı | 18/31 | 38 | 10.8 | 27 | 16 |
| GVK › Ücret gelirleri | 13/31 | 28 | 2 | 26 | 3 |
| GVK › Beyannamede indirimler (GVK 89) | 10/31 | 21 | 1 | 20 | 0 |
| GVK › Menkul sermaye iradı | 14/31 | 30 | 16.2 | 14 | 17 |
| GVK › Telif kazançları istisnası (GVK 18) | 7/31 | 15 | 2.5 | 13 | 0 |
| KDV › Matrah ve özel matrah | 10/31 | 21 | 9.5 | 12 | 0 |
| VUK › Vergilendirme süreci (tarh, tebliğ, tahakkuk, tahsil) | 8/31 | 17 | 7.5 | 10 | 2 |

**Tabloda neden açık görünmüyor (ölçüldü):**
- Çıkmış sayımı parçalı: tablo ağırlığı `veri/smmm-analiz.json` etiketlerinden gelir; "yıllık beyan + GV hesabı" onlarca yazıma bölünmüş (ör. "gelir vergisi matrahi hesaplama" çıkmış 7 ama son10 **0** → hedef 0). Tek dolu satır "gelir vergisi hesabi": son10 17 (okunmuş 25 dönem), hedef 24, açık 14.
- "Yayınlanabilir" sayımı yanlış konuyu sayıyor: "gelir vergisi hesabi" anahtarındaki sitedeki 10 sorunun okunmuş konusu: Mükellefiyet türleri 9 · Menkul sermaye iradı 3 · **Yıllık beyan/GV hesabı 3** · GMSİ 1 (çok konulu). "ucret ve kira geliri beyani" etiketli 7 sorunun 7'si okumada GMSİ.
- Ücret: tabloda "Ücret gelirleri"ne denk ağırlıklı satır yok; ücretli varyantların son10'u 0.
- Plan kurucu `-KonuBasiTavan 3` ile konu başına en çok 3 soru basar → tablo yoluyla bu konuya bir dalgada ≤3 soru gider.

**Kaynak (ambar, 05.10 okundu):** GVK m.103 kaydı 2019 metni + güncel tutarlar parantez içinde iç içe, sonu m.104 başlığına taşmış ("TL) fazlası % % % % 40"). Ambardaki en güncel tarife tebliği **GVGT Seri 329** (2025 gelirleri: 158.000 / 330.000 / 800.000 (ücret 1.200.000) / 4.300.000). **Seri 332 (2026 tarifesi) ambarda YOK** — yalnız yerel `veri/mevzuat-hazir/gvkgt332.txt` (190.000 / 400.000 / 1.000.000 (ücret 1.500.000) …). m.23/18 (asgari ücret istisnası, 7349) ve m.86/1-b (dördüncü dilim) ambarda güncel. Asgari ücretin 2026 tutarı ambarda **ölçülmedi** → kökte verilmeli. **⚠ DÜZELTME 05.10 (aynı oturum): "Seri 332 ambarda YOK" YANLIŞ — ambarda 11 kayıt var, adı boşluksuz ("SERİ NO:332"); ilk arama boşluklu yazıldı. 2026 tarifesi ambarda. Ölçüm koşusunun "2025 gelirleri" kurgusu bu yanlış bulguya dayanıyordu.**

## 2. Plan bağı — kasa etiketli tablo ↔ okunmuş eşleme

Aynı kural (toplam 4.000, ders tabanı 350, en büyük kalan), ağırlık = okunmuş dönem sayısı. Okunmuş açık toplamı **1238**, hedef üstü (fazla) **948**; sözlük dışı sitedeki soru 96.

| Ders | Okunmuş hedef | Sitede | Okunmuş açık | Okunmuş fazla |
|---|---:|---:|---:|---:|
| Finansal Muhasebe | 1276 | 1099 | 399 | 220 |
| Finansal Tablolar ve Analizi | 350 | 399 | 53 | 102 |
| Hukuk | 353 | 435 | 70 | 153 |
| Maliyet Muhasebesi | 350 | 475 | 50 | 177 |
| Meslek Hukuku | 350 | 348 | 61 | 57 |
| Muhasebe Denetimi | 350 | 371 | 136 | 152 |
| Sermaye Piyasası Mevzuatı | 359 | 244 | 141 | 22 |
| Vergi Mevzuatı ve Uygulaması | 612 | 353 | 328 | 65 |

**Tablonun 983 engelsiz açığı okunmuşa göre:** dolu konuya düşen **229** · gerçekten açık konuya 322 · dengede 22 · ölçülemez (etiketin sitede sorusu yok) 410. Engelli 101.

Dolu konuya para yazan ilk 10 tablo satırı:

| Tablo açığı | Tablo konusu | Okunmuş konu | Okunmuş fazla |
|---:|---|---|---:|
| 8 | pazarlama gideri odeme | Maliyet hesapları ve yansıtma (7/A–7/B) | 24 |
| 6 | uygulamali mesleki egitim | Kalite yönetimi ve kalite kontrol | 64 |
| 5 | ticari mal alisi | Çek ve senet işlemleri | 27 |
| 5 | gug yukleme katsayisi | Genel üretim giderlerinin mamullere yüklenmesi | 29 |
| 4 | donem net kari hesaplama | Kapanış kayıtları | 8 |
| 4 | gelecek aylara ait gelir | Gelecek dönemlere ait gelir-giderler ve tahakkuklar | 22 |
| 4 | alacak tahsilati | Şüpheli ve değersiz alacaklar | 48 |
| 4 | gelir gider hesaplari kapanisi | Kapanış kayıtları | 8 |
| 3 | tahvil faiz tahsilat duzeltme | Menkul kıymet işlemleri ve değerlemesi | 8 |
| 3 | pazarlama gideri tahakkuk | Gelecek dönemlere ait gelir-giderler ve tahakkuklar | 22 |

Eşdeğerlik: `-SoruKutugu` eklenince tablo çıktısı 1.111 parti / 6.649 soru / 8.295 satırda 0 fark.

## 3. Muhasebe Denetimi — tekrar ve ders dışı

Ölçü: yayın ikiz cetveli (soru ≥0,60 VE doğru şık ≥0,60) 385 soruda **0 çift**; soru ≥0,45: 296 çift, 34 küme. Okuma (385/385): **70 kalıp grubu** (10 SINIRDA), gruplarda 260 soru, "tekrar" önerisi **180** (SINIRDA hariç 169). Ders dışı 37.

Ölçülmüş kaçış örneği: smmm-4k-a-ydenetim-kolay-r7/kp-01 · zor-r3/kp-01 · zor-r5/kp-01 aynı rakam ve aynı cevap (108.000), soru benzerliği 0,42–0,45 → ikiz kapısı görmüyor.

### Kalıp grupları

| Grup | SINIRDA | Kalsın | Tekrar (çekme/yeniden yazma adayı) |
|---|---|---|---|
| SÜ-1 BDS 570: belirsizlik yeterince açıklanmış → olumlu + ayrı bölüm |  | smmm-4k-a-ydenetim-cokzor-r5/kp-02<br>smmm-4k-a-ydenetim-zor-r5/kp-04 | smmm-4k-a-ydenetim-kolay-r1/kp-29<br>smmm-4k-a-ydenetim-kolay-r3/kp-03<br>smmm-4k-a-ydenetim-kolay-r3/kp-24<br>smmm-4k-a-ydenetim-kolay-r3/kp-30<br>smmm-4k-a-ydenetim-kolay-r6/kp-04<br>smmm-4k-a-ydenetim-kolay-r7/kp-26<br>smmm-4k-a-ydenetim-kolay-r9/kp-14<br>smmm-4k-a-ydenetim-kolay-r9/kp-17<br>smmm-4k-a-ydenetim-zor-r10/kp-10<br>smmm-4k-a-ydenetim-zor-r5/kp-17<br>smmm-w1-ydenetim-kolay/kp-04<br>smmm-w1-ydenetim-kolay/kp-05<br>smmm-w3-ydenetim-kolay/kp-05<br>smmm-w3-ydenetim-zor/kp-29 |
| KY-B BDS 220: politika dışı ek iş kararı ekibe aittir |  | smmm-4k-a-ydenetim-kolay-r7/kp-12<br>smmm-w3-ydenetim-cokzor/kp-15 | smmm-4k-a-ydenetim-kolay-r3-2/kp-03<br>smmm-4k-a-ydenetim-kolay-r3/kp-20<br>smmm-4k-a-ydenetim-kolay-r6-2/kp-01<br>smmm-4k-a-ydenetim-kolay-r7/kp-10<br>smmm-4k-a-ydenetim-kolay-r7/kp-21<br>smmm-4k-a-ydenetim-kolay-r8/kp-15<br>smmm-4k-a-ydenetim-zor-r7/kp-12<br>smmm-w14-10-ydenetim-cokzor/kp-02<br>smmm-w3-ydenetim-cokzor/kp-08<br>smmm-4k-a-ydenetim-kolay-r10/kp-05 |
| KY-A2 BDS 220: personel işe alım/eğitim şirket düzeyidir |  | smmm-4k-a-ydenetim-zor-r2/kp-18<br>smmm-w3-ydenetim-kolay/kp-02 | smmm-4k-a-ydenetim-kolay-r10/kp-18<br>smmm-4k-a-ydenetim-kolay-r6/kp-19<br>smmm-4k-a-ydenetim-kolay-r9/kp-13<br>smmm-4k-a-ydenetim-zor-r10/kp-07<br>smmm-4k-a-ydenetim-zor-r4/kp-14<br>smmm-4k-a-ydenetim-zor-r4/kp-17<br>smmm-4k-a-ydenetim-zor-r8/kp-09<br>smmm-w2-ydenetim-kolay/kp-01 |
| DT-1 Dış teyit hesap bakiyeleriyle sınırlı değildir |  | smmm-4k-a-ydenetim-kolay-r7/kp-18<br>smmm-4k-a-ydenetim-zor-r6/kp-14 | smmm-4k-a-ydenetim-kolay-r1/kp-28<br>smmm-4k-a-ydenetim-kolay-r10/kp-14<br>smmm-4k-a-ydenetim-kolay-r4/kp-28<br>smmm-4k-a-ydenetim-kolay-r8/kp-16<br>smmm-4k-a-ydenetim-kolay-r9/kp-19<br>smmm-4k-a-ydenetim-zor-r5/kp-14<br>smmm-w1-ydenetim-zor/kp-11 |
| KS-1 BDS 210: kabul edilebilir çerçeve yoksa uygun kıstas da yoktur |  | smmm-4k-a-ydenetim-kolay-r3/kp-29<br>smmm-w2-ydenetim-cokzor/kp-03 | smmm-4k-a-ydenetim-kolay-r2/kp-05<br>smmm-4k-a-ydenetim-kolay-r4/kp-29<br>smmm-4k-a-ydenetim-kolay-r6/kp-29<br>smmm-4k-a-ydenetim-kolay-r7/kp-25<br>smmm-4k-a-ydenetim-kolay-r9/kp-20<br>smmm-4k-a-ydenetim-zor-r10/kp-01<br>smmm-4k-a-ydenetim-zor-r10/kp-11 |
| KY-F KYS 1: makul güvence mutlak değildir |  | smmm-4k-a-ydenetim-zor-r9/kp-05 | smmm-4k-a-ydenetim-kolay-r2/kp-09<br>smmm-4k-a-ydenetim-kolay-r4/kp-06<br>smmm-4k-a-ydenetim-kolay-r6/kp-05<br>smmm-4k-a-ydenetim-zor-r8/kp-03<br>smmm-w3-ydenetim-zor/kp-08 |
| KY-G KYS 1: şeffaflık raporu |  | smmm-4k-a-ydenetim-kolay-r7/kp-13 | smmm-4k-a-ydenetim-kolay-r10/kp-10<br>smmm-4k-a-ydenetim-kolay-r4/kp-13<br>smmm-4k-a-ydenetim-kolay-r8/kp-12<br>smmm-4k-a-ydenetim-kolay-r9/kp-09<br>smmm-d1-ydenetim-cokzor-r1/kp-03 |
| DR-1 Denetim riski: YR ve KR işletmenin, TER denetçinin riski |  | smmm-w2-ydenetim-cokzor/kp-01<br>smmm-w4-ydenetim-zor/kp-02 | smmm-4k-a-ydenetim-kolay-r1/kp-02<br>smmm-4k-a-ydenetim-kolay-r8/kp-02<br>smmm-4k-a-ydenetim-zor-r5/kp-02<br>smmm-w1-ydenetim-cokzor/kp-01<br>smmm-w14-5-ydenetim-cokzor/kp-01 |
| DR-4 Amortisman tahmini → subjektiflik yapısal risk faktörü |  | smmm-4k-a-ydenetim-cokzor-r3/kp-02 | smmm-4k-a-ydenetim-kolay-r1-2/kp-05<br>smmm-4k-a-ydenetim-kolay-r2-2/kp-04<br>smmm-4k-a-ydenetim-zor-r2/kp-16<br>smmm-4k-a-ydenetim-zor-r4/kp-15<br>smmm-w3-ydenetim-kolay/kp-16 |
| HL-1 Hileli finansal raporlama ile varlıkların kötüye kullanılması ayrımı |  | smmm-4k-a-ydenetim-zor-r6/kp-13 | smmm-4k-a-ydenetim-kolay-r1-2/kp-02<br>smmm-4k-a-ydenetim-kolay-r1/kp-09<br>smmm-4k-a-ydenetim-kolay-r2/kp-11<br>smmm-4k-a-ydenetim-kolay-r4-2/kp-03<br>smmm-4k-a-ydenetim-kolay-r5-2/kp-02 |
| MU-3 (ders dışı) VUK 323 şüpheli alacak karşılığı hesabı |  | smmm-4k-a-ydenetim-cokzor-r8/kp-01<br>smmm-4k-a-ydenetim-zor-r1/kp-02 | smmm-4k-a-ydenetim-kolay-r10/kp-01<br>smmm-4k-a-ydenetim-kolay-r7/kp-01<br>smmm-4k-a-ydenetim-zor-r3/kp-01<br>smmm-4k-a-ydenetim-zor-r5/kp-01<br>smmm-4k-a-ydenetim-zor-r9/kp-01 |
| KY-A1 BDS 220: KYS tasarlamak ekibin değil şirketin işi |  | smmm-4k-a-ydenetim-kolay-r3/kp-18 | smmm-4k-a-ydenetim-kolay-r4/kp-15<br>smmm-4k-a-ydenetim-kolay-r6/kp-10<br>smmm-4k-a-ydenetim-kolay-r6/kp-16<br>smmm-4k-a-ydenetim-zor-r1/kp-08 |
| DR-2 Kontrol riski tanımı/teşhisi |  | smmm-4k-a-ydenetim-kolay-r7/kp-15 | smmm-4k-a-ydenetim-kolay-r1/kp-12<br>smmm-4k-a-ydenetim-kolay-r6/kp-15<br>smmm-4k-a-ydenetim-kolay-r8/kp-14<br>smmm-4k-a-ydenetim-kolay-r3/kp-11 |
| DR-3 Risk modeli hesabı (TER = DR / (YR×KR)) |  | smmm-4k-a-ydenetim-cokzor-r2/kp-02<br>smmm-4k-a-ydenetim-kolay-r3/kp-01 | smmm-4k-a-ydenetim-zor-r10/kp-06<br>smmm-4k-a-ydenetim-zor-r4/kp-09<br>smmm-4k-a-ydenetim-zor-r5/kp-11<br>smmm-4k-a-ydenetim-zor-r7/kp-08 |
| KN-1 Temsil mektubu tek başına yeterli kanıt değildir |  | smmm-4k-a-ydenetim-zor-r7/kp-05 | smmm-4k-a-ydenetim-kolay-r5/kp-20<br>smmm-4k-a-ydenetim-zor-r1/kp-05<br>smmm-4k-a-ydenetim-zor-r2/kp-02<br>smmm-4k-a-ydenetim-zor-r5/kp-03 |
| IK-1 İç kontrol eksikliği tanımı (BDS 265) |  | smmm-4k-a-ydenetim-kolay-r3/kp-07 | smmm-4k-a-ydenetim-kolay-r1/kp-10<br>smmm-4k-a-ydenetim-kolay-r5/kp-11<br>smmm-4k-a-ydenetim-kolay-r9/kp-06<br>smmm-4k-a-ydenetim-zor-r4/kp-05 |
| KY-A3 BDS 220: ekip KYS dışında serbest değildir |  | smmm-w14-12-ydenetim-cokzor/kp-01 | smmm-4k-a-ydenetim-kolay-r1/kp-19<br>smmm-4k-a-ydenetim-kolay-r5/kp-19<br>smmm-4k-a-ydenetim-kolay-r5/kp-24 |
| KY-D BDS 220 ön kabulü |  | smmm-w3-ydenetim-zor/kp-24 | smmm-4k-a-ydenetim-kolay-r2-2/kp-03<br>smmm-4k-a-ydenetim-zor-r4/kp-08<br>smmm-w14-10-ydenetim-kolay/kp-02 |
| KY-H KYS 2: diğer mevzuatla aykırılıkta mevzuata uyulur |  | smmm-4k-a-ydenetim-zor-r3/kp-10 | smmm-4k-a-ydenetim-kolay-r2/kp-12<br>smmm-4k-a-ydenetim-zor-r10/kp-03<br>smmm-4k-a-ydenetim-zor-r9/kp-10 |
| DT-2 Negatif teyit: itiraz varsa yanıt; düşük risk, çok sayıda küçük bakiye |  | smmm-denetim-30/kp-21 | smmm-4k-a-ydenetim-kolay-r10/kp-06<br>smmm-w3-ydenetim-kolay/kp-08<br>smmm-w3-ydenetim-zor/kp-12 |
| IK-3 Maddi doğrulamada yanlışlık çıkmaması kontrol etkinliği kanıtı değildir |  | smmm-w3-ydenetim-cokzor/kp-03 | smmm-4k-a-ydenetim-kolay-r10/kp-16<br>smmm-4k-a-ydenetim-kolay-r8/kp-10<br>smmm-4k-a-ydenetim-zor-r2/kp-07 |
| KY-C BDS 220 p.A6: şirket düzeyi işlere örnek olmayan |  | smmm-w6-ydenetim-kolay/kp-01 | smmm-w14-11-ydenetim-cokzor/kp-01<br>smmm-w14-6-ydenetim-cokzor/kp-01 |
| KY-E Kuruma yazılı bildirimi sorumlu denetçi gözden geçirir |  | smmm-4k-a-ydenetim-kolay-r3/kp-17 | smmm-4k-a-ydenetim-kolay-r4/kp-18<br>smmm-4k-a-ydenetim-kolay-r7/kp-16 |
| KY-I1 KYS 2: KGG değerlendirmesi denetimin tamamını kapsamaz |  | smmm-4k-a-ydenetim-cokzor-r6/kp-02 | smmm-4k-a-ydenetim-zor-r6/kp-04<br>smmm-w14-13-ydenetim-cokzor/kp-01 |
| KY-I2 KYS 2: KGG denetimi yeniden yürütmez, kanıt toplamaz |  | smmm-w1-ydenetim-zor/kp-04 | smmm-w1-ydenetim-kolay/kp-01<br>smmm-w1-ydenetim-zor/kp-02 |
| MŞ BDS 220: mesleki şüphecilik–muhakeme ilişkisi |  | smmm-4k-a-ydenetim-zor-r9/kp-07 | smmm-4k-a-ydenetim-kolay-r1/kp-03<br>smmm-4k-a-ydenetim-zor-r9/kp-03 |
| SÜ-2 BDS 570: belirsizlik açıklanmamış + yaygın → olumsuz |  | smmm-4k-a-ydenetim-zor-r8/kp-14 | smmm-4k-a-ydenetim-kolay-r10/kp-15<br>smmm-4k-a-ydenetim-kolay-r6/kp-20 |
| KN-2 Miktar artışı düşük kaliteyi telafi etmez |  | smmm-4k-a-ydenetim-cokzor-r9/kp-02 | smmm-4k-a-ydenetim-kolay-r5/kp-21<br>smmm-4k-a-ydenetim-zor-r6/kp-03 |
| KN-5 Tracing belgeden kayda, tamlık |  | smmm-w7-1-ydenetim-zor/kp-01 | smmm-4k-a-ydenetim-kolay-r5/kp-05<br>smmm-4k-a-ydenetim-kolay-r8/kp-08 |
| DT-3 Pozitif teyite yanıt yoksa alternatif prosedür |  | smmm-4k-a-ydenetim-kolay-r6/kp-21 | smmm-4k-a-ydenetim-zor-r10/kp-09<br>smmm-4k-a-ydenetim-zor-r6/kp-06 |
| IK-2 Önemli iç kontrol eksikliği ölçütü = mesleki muhakeme |  | smmm-4k-a-ydenetim-kolay-r2/kp-13 | smmm-4k-a-ydenetim-kolay-r1/kp-11<br>smmm-4k-a-ydenetim-kolay-r6/kp-11 |
| AN-1 BDS 520 A12: bağımsız dış kaynak daha güvenilir |  | smmm-4k-a-ydenetim-kolay-r3-2/kp-04 | smmm-4k-a-ydenetim-kolay-r7/kp-14<br>smmm-4k-a-ydenetim-zor-r8/kp-11 |
| AN-3 BDS 520: veri hazırlama kontrollerinin testi | evet | smmm-4k-a-ydenetim-cokzor-r1/kp-02 | smmm-4k-a-ydenetim-kolay-r4/kp-08<br>smmm-w14-8-ydenetim-cokzor/kp-01 |
| KS-2 BDS 210: uygun kıstas mesleki muhakemeyi dışlamaz |  | smmm-4k-a-ydenetim-zor-r8/kp-01 | smmm-4k-a-ydenetim-kolay-r5/kp-04<br>smmm-4k-a-ydenetim-zor-r1/kp-04 |
| ÖN Önemlilik düzeyi denetim boyunca revize edilebilir |  | smmm-4k-a-ydenetim-kolay-r10/kp-13 | smmm-4k-a-ydenetim-kolay-r1/kp-25<br>smmm-4k-a-ydenetim-kolay-r6/kp-25 |
| RT TTK 400 / BDY: 10 yılda 7 yıl → 3 yıl seçilemez |  | smmm-4k-a-ydenetim-kolay-r1/kp-06<br>smmm-4k-a-ydenetim-kolay-r6/kp-30 | smmm-4k-a-ydenetim-kolay-r2/kp-08<br>smmm-4k-a-ydenetim-kolay-r5/kp-06 |
| TR-2 Denetim türleri (vergi müfettişi KDV / iç denetim satın alma) |  | smmm-w3-ydenetim-zor/kp-15 | smmm-w1-ydenetim-zor/kp-10<br>smmm-w3-ydenetim-zor/kp-22 |
| İB Açılış bakiyesinin kapsamı (BDS 510/710) |  | smmm-4k-a-ydenetim-zor-r2/kp-06 | smmm-4k-a-ydenetim-kolay-r5/kp-09<br>smmm-4k-a-ydenetim-zor-r6/kp-08 |
| ÖD Önceki denetçiyle iletişim hem kabul hem planlama girdisi |  | smmm-4k-a-ydenetim-zor-r7/kp-04 | smmm-4k-a-ydenetim-zor-r4/kp-04<br>smmm-w12b-2-ydenetim-zor/kp-05 |
| ET-3 Tarafsızlık: üçüncü kişi baskısı |  | smmm-4k-a-ydenetim-cokzor-r3/kp-01 | smmm-4k-a-ydenetim-kolay-r8/kp-01<br>smmm-4k-a-ydenetim-zor-r4/kp-01 |
| MU-1 (ders dışı) Kavramsal Çerçeve temel niteliksel özellikler |  | smmm-4k-a-ydenetim-zor-r9/kp-09<br>smmm-4k-a-ydenetim-kolay-r6/kp-26 | smmm-4k-a-ydenetim-kolay-r5/kp-26<br>smmm-4k-a-ydenetim-zor-r8/kp-08 |
| KY-A4 BDS 220: şirket politikalarını uygulamak ekibin sorumluluğu |  | smmm-4k-a-ydenetim-kolay-r4/kp-16 | smmm-4k-a-ydenetim-kolay-r3/kp-14 |
| KY-I3 KYS 2: KGG atanma şartı (ekip üyesi olmamalı) | evet | smmm-w12b-2-ydenetim-kolay/kp-04 | smmm-w12b-2-ydenetim-cokzor/kp-04 |
| KY-I4 KYS 2: KGG denetçi raporunu (KDK dahil) gözden geçirir |  | smmm-w3-ydenetim-zor/kp-11 | smmm-w1-ydenetim-zor/kp-09 |
| KY-J KYS 1: kök neden prosedürlerinin sıkılığı |  | smmm-w3-ydenetim-zor/kp-25 | smmm-4k-a-ydenetim-zor-r2/kp-05 |
| KY-K KYS 1: rotasyonun şirket politikası olarak belirlenmesi |  | smmm-4k-a-ydenetim-zor-r5/kp-16 | smmm-4k-a-ydenetim-kolay-r7/kp-20 |
| KY-L BDS 220 p.A92: önemli muhakeme alanı sayılmayan | evet | smmm-w14-6-ydenetim-zor/kp-02 | smmm-w14-6-ydenetim-cokzor/kp-02 |
| RP Açılış bakiyesi yanlışlığı → şartlı/olumsuz (BDS 510) |  | smmm-w3-ydenetim-zor/kp-19 | smmm-w3-ydenetim-zor/kp-17 |
| HL-2 Teslim alınmayan mal için ödeme = varlıkların kötüye kullanılması |  | smmm-d1-ydenetim-cokzor-r1/kp-02 | smmm-4k-a-ydenetim-kolay-r3/kp-10 |
| HL-3 Varlıkların kötüye kullanılması yalnız çalışanlarca yapılmaz |  | smmm-4k-a-ydenetim-zor-r5/kp-13 | smmm-4k-a-ydenetim-kolay-r4/kp-10 |
| HL-4 Yönetimin kontrolleri ihlali öngörülemez → ciddi risk | evet | smmm-4k-a-ydenetim-kolay-r6/kp-27 | smmm-4k-a-ydenetim-kolay-r2/kp-27 |
| KN-3 Doğrudan dış teyit en güvenilir alacak kanıtı |  | smmm-4k-a-ydenetim-zor-r3/kp-03 | smmm-4k-a-ydenetim-kolay-r1/kp-04 |
| KN-4 Gözlem yalnız gözlem anı için kanıt sağlar |  | smmm-w3-ydenetim-kolay/kp-09 | smmm-4k-a-ydenetim-kolay-r4/kp-21 |
| KN-6 Fiziki inceleme mülkiyet/değerlemeyi tek başına kanıtlamaz | evet | smmm-4k-a-ydenetim-cokzor-r4/kp-03 | smmm-d1-ydenetim-cokzor-r1/kp-01 |
| KN-7 Sorgulama tek başına yeterli kanıt değildir | evet | smmm-w3-ydenetim-zor/kp-01 | smmm-4k-a-ydenetim-zor-r1/kp-16 |
| AN-2 BDS 520 A12: listede sayılmayan unsur | evet | smmm-4k-a-ydenetim-kolay-r2/kp-15 | smmm-4k-a-ydenetim-kolay-r4-2/kp-04 |
| BG-1 TTK 400: vergi danışmanlığı dışında hizmet verilemez |  | smmm-4k-a-ydenetim-zor-r9/kp-06 | smmm-4k-a-ydenetim-kolay-r4/kp-07 |
| BG-2 Şekilde bağımsızlık tanımı | evet | smmm-4k-a-ydenetim-zor-r7/kp-11 | smmm-4k-a-ydenetim-kolay-r9/kp-18 |
| MV-1 BDY: KAYİK sorumlu denetçi 15 yıl tecrübe |  | smmm-4k-a-ydenetim-kolay-r2/kp-18 | smmm-4k-a-ydenetim-kolay-r1/kp-17 |
| MV-2 BDY: denetim kuruluşu ortaklarının çoğunluğu | evet | smmm-4k-a-ydenetim-zor-r8/kp-10 | smmm-4k-a-ydenetim-kolay-r10/kp-11 |
| MV-3 BDY: sorumlu denetçi tanımı |  | smmm-4k-a-ydenetim-kolay-r5-2/kp-03 | smmm-w3-ydenetim-kolay/kp-11 |
| MV-4 KGK: belge ibraz edilmezse sulh ceza kararıyla arama |  | smmm-4k-a-ydenetim-kolay-r3-2/kp-05 | smmm-4k-a-ydenetim-kolay-r4-2/kp-05 |
| TR-1 GKGDS: bağımsızlık genel standarttır |  | smmm-w3-ydenetim-zor/kp-03 | smmm-w3-ydenetim-zor/kp-34 |
| ET-1 Gizlilik istisnası: kanuni hak/görev |  | smmm-4k-a-ydenetim-zor-r6/kp-01 | smmm-4k-a-ydenetim-kolay-r10/kp-02 |
| ET-2 Gizlilik ihlali |  | smmm-4k-a-ydenetim-kolay-r5/kp-01 | smmm-4k-a-ydenetim-kolay-r2/kp-02 |
| ET-4 Çok düşük ücret → yeterlik ve özene kişisel çıkar tehdidi |  | smmm-4k-a-ydenetim-kolay-r1/kp-30 | smmm-4k-a-ydenetim-kolay-r4/kp-25 |
| MU-2 (ders dışı) MSUGT: süreklilik ortakların ömrüyle sınırlı değil |  | smmm-4k-a-ydenetim-zor-r9/kp-04 | smmm-w3-ydenetim-cokzor/kp-18 |
| MU-4 (ders dışı) Amortisman kaydı 730/257 |  | smmm-4k-a-ydenetim-kolay-r3-2/kp-01 | smmm-4k-a-ydenetim-kolay-r4-2/kp-01 |
| MU-5 (ders dışı) Peşin kira → 280 tutarı |  | smmm-w3-ydenetim-kolay/kp-06 | smmm-w1-ydenetim-kolay/kp-06 |
| MU-6 (ders dışı) 245 Bağlı Ortaklıklar sınıflaması | evet | smmm-4k-a-ydenetim-zor-r4/kp-19 | smmm-4k-a-ydenetim-kolay-r1/kp-18 |

### Ders dışı

| Soru | Öneri | Gerçek ders |
|---|---|---|
| smmm-4k-a-ydenetim-kolay-r5/kp-26 | CEK | Finansal Muhasebe |
| smmm-4k-a-ydenetim-zor-r8/kp-08 | CEK | Finansal Muhasebe |
| smmm-w3-ydenetim-cokzor/kp-18 | CEK | Finansal Muhasebe |
| smmm-4k-a-ydenetim-kolay-r4-2/kp-01 | CEK | Finansal Muhasebe |
| smmm-w1-ydenetim-kolay/kp-06 | CEK | Finansal Muhasebe |
| smmm-4k-a-ydenetim-kolay-r10/kp-01 | CEK | Finansal Muhasebe |
| smmm-4k-a-ydenetim-kolay-r7/kp-01 | CEK | Finansal Muhasebe |
| smmm-4k-a-ydenetim-zor-r3/kp-01 | CEK | Finansal Muhasebe |
| smmm-4k-a-ydenetim-zor-r5/kp-01 | CEK | Finansal Muhasebe |
| smmm-4k-a-ydenetim-zor-r9/kp-01 | CEK | Finansal Muhasebe |
| smmm-4k-a-ydenetim-zor-r4/kp-21 | SINIRDA | Finansal Muhasebe |
| smmm-w3-ydenetim-zor/kp-02 | SINIRDA | Finansal Tablolar ve Analizi |
| smmm-4k-a-ydenetim-zor-r2/kp-20 | SINIRDA | Muhasebe Denetimi |
| smmm-w3-ydenetim-cokzor/kp-17 | SINIRDA | Muhasebe Denetimi |
| smmm-4k-a-ydenetim-kolay-r10/kp-02 | SINIRDA | Meslek Hukuku |
| smmm-4k-a-ydenetim-kolay-r2/kp-02 | SINIRDA | Meslek Hukuku |
| smmm-4k-a-ydenetim-kolay-r5/kp-01 | SINIRDA | Meslek Hukuku |
| smmm-4k-a-ydenetim-kolay-r8/kp-01 | SINIRDA | Meslek Hukuku |
| smmm-4k-a-ydenetim-zor-r4/kp-01 | SINIRDA | Meslek Hukuku |
| smmm-4k-a-ydenetim-zor-r6/kp-01 | SINIRDA | Meslek Hukuku |
| smmm-4k-a-ydenetim-zor-r9/kp-02 | SINIRDA | Meslek Hukuku |
| smmm-w3-ydenetim-kolay/kp-03 | SINIRDA | Meslek Hukuku |
| smmm-4k-a-ydenetim-kolay-r1/kp-18 | TASI | Finansal Muhasebe |
| smmm-4k-a-ydenetim-zor-r4/kp-19 | TASI | Finansal Muhasebe |
| smmm-4k-a-ydenetim-kolay-r6/kp-26 | TASI | Finansal Muhasebe |
| smmm-4k-a-ydenetim-zor-r9/kp-09 | TASI | Finansal Muhasebe |
| smmm-4k-a-ydenetim-kolay-r7/kp-23 | TASI | Finansal Tablolar ve Analizi |
| smmm-4k-a-ydenetim-zor-r10/kp-02 | TASI | Finansal Muhasebe |
| smmm-4k-a-ydenetim-zor-r4/kp-03 | TASI | Finansal Muhasebe |
| smmm-4k-a-ydenetim-zor-r9/kp-04 | TASI | Finansal Muhasebe |
| smmm-w3-ydenetim-cokzor/kp-10 | TASI | Finansal Muhasebe |
| smmm-4k-a-ydenetim-kolay-r3-2/kp-01 | TASI | Finansal Muhasebe |
| smmm-w3-ydenetim-kolay/kp-06 | TASI | Finansal Muhasebe |
| smmm-4k-a-ydenetim-cokzor-r8/kp-01 | TASI | Finansal Muhasebe |
| smmm-4k-a-ydenetim-zor-r1/kp-02 | TASI | Finansal Muhasebe |
| smmm-4k-a-ydenetim-zor-r2/kp-09 | TASI | Meslek Hukuku |
| smmm-4k-a-ydenetim-zor-r5/kp-10 | TASI | Meslek Hukuku |

### Ağır kusur adayı (okuyucu notu, DOĞRULANMADI)

- smmm-4k-a-ydenetim-zor-r6/kp-15
- smmm-4k-a-ydenetim-zor-r4/kp-21
- smmm-4k-a-ydenetim-kolay-r7/kp-01

## 4. Vergi ölçüm koşusu (GM yolu, okunmuş plandan) — SONUÇ 05.10

| | gm6 | gm7 (gm6'nın düzeltilmişi) | toplam |
|---|---:|---:|---:|
| yazılan hazır soru | 15 | 13 | 28 |
| ücretsiz kod kapısından geçip partiye giren | 2 | 10 | 12 |
| **yayın şartını geçen** | 0 | **1** | **1** |
| bedel (bulut günlüğü, ≈USD) | 0,14 | 1,05 | **≈1,19** |

**Yayına giren soru başı ≈1,2 USD** (kıyas: gm2 0,065 · w11–w13 0,29). Büyük basım ÖNERİLMEZ.

Düşme nedenleri (12 parti sorusu): simülasyon yanlış 3 · açıklama hakemi KUSURLU 3 · hakem HAYIR 2 · adım yok → simülasyon koşamadı 2 ·
simülasyon koşmadı 1 · KAPI-YY 1. gm6'nın 13'ü girişte KAPI-Y (talimat "2025 yılı" dedi; üretici kuralı en yeni yıl = bugün) ve KAPI-K
(SMMM test sözlüğü) ile düştü → ön denetime eklendi (73e179f9; gm6'nın 13/13'ünü yakalıyor).

Kök nedenler:
1. **Kaynak paketi yıl karışıklığı:** iki hakem HAYIR'ın ikisi de ambardan — GVK m.21 kaydı 58.000 (2026) taşıyor, yıl yazmıyor; hakem 2025
   haddini (47.000, Seri 329) yanlış saydı. Seri 329 m.3/2 ve geçici m.67 pakete girmedi. → `veri/AMBAR-YUTMA-IS-EMRI-20260930.md` satır 15–18.
2. **Adım/sade katmanını bulut modeli yazıyor:** hazır soruda `adimlar` yok; KAPI-ADIM/YY ve simülasyon düşüşleri, AH'nin "6. adımda bulduk"
   ve sade toplam hataları bu katmanda. Teori sorusunda adım hiç yazılmıyor → "simülasyon koşamadı" (gm3'te de aynı).
3. İçerik kusuru 1: m.75 bent atfı (AH, kolay MSİ).

## 5. Düzeltmeler ve GM 1.2.3 (05.10, ikinci tur)

- **Seri 332 ambarda VAR** (11 kayıt, `GELİR VERGİSİ GENEL TEBLİĞİ (SERİ NO:332) m.N`) — bölüm 1 ve iş emri satır 15 düzeltildi. Hakem HAYIR'ın (bölüm 4) kökü buna göre: yazar 2025 haddini kullandı, paket 2026 kaydını gösterdi → 2026 tarifesiyle yazılsaydı çelişki olmazdı (ölçülmedi).
- **GVK m.22 ambara eklendi** (`arac/ambar-gvk22-ekle-20261005.js`, 2 kayıt, dipnotsuz, geri okundu birebir).
- Var olan kaydı değiştiren iş emri satırları (16 m.103, 18 yılsız tutarlar, 19 m.88 başlığı) YAPILMADI: dayanak nöbetçisi etkisi ölçülmeden kayıt metni değişmez; kaynak_ad değişirse soru bağı kopar.
- **B25**: GM yazarı adım + sade yazar; ön denetim ADIM YOK / SADE YOK + KAPI-KALITE (c73c1064). Kalıcı talimat `arac/GM-HAZIR-SORU-TALIMATI.md`.
- **DÜZELTME (geç. m.67):** gm8 ikinci gözünde "geç. m.67 31.12.2025'te bitti, 2026 uzatması ambarda yok" denmişti — YANLIŞ: 10680 sayılı CBK (RG 11/12/2025) ile 31/12/2030'a uzatma ambarda var ama dipnot `gec. m.68 [2/2]` kaydına kaymış (iş emri satır 20). gm8 MSİ sorularının geç. m.67'den arındırılması zararsız, gereksizdi. Yayındaki 2 repo sorusu (gm4-12 zor/çok zor kp-01) Cem "onar" ile gelir yılı 2025'e taşınarak onarıldı (yanlış yerdeki dipnota dayanmasın diye).
