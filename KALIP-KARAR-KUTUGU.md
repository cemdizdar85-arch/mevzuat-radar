# KALIP KARAR KÜTÜĞÜ — Kaydır-Çöz cevap kalıbı

> ❄️ **DONDURMA 06.09–13.09.2026 (Cem "2 yap"):** kalıp bu hâliyle kilitli. Yeni kural/özellik önerisi yalnız bu kütüğe yazılır
> (Ö/R satırı), **haftada bir** (pazartesi) toplu işlenir. Bu arada üretim (117 kalıpsız ağır konu) DONMUŞ kalıpla yapılır;
> üretilen soru dondurma sonrası kural değişikliğinde yeniden basılmaz, kütükte "bekleyen kural" olarak işaretlenir.
> Dondurma dışı tek istisna: hakem/kapı düşüren gerçek HATA (yanlış hüküm, kırık ekran).

> 06.09.2026 Cem: "kayboldum". Bu dosya her öneri ve kararın TEK yeri. Durum: ✅ yapıldı · ⏳ bekliyor (kimde) · ❌ ret · 🔁 değişti.
> Şartname: [STANDART-CEVAP-KALIBI.md](STANDART-CEVAP-KALIBI.md). Yeni öneri önce buraya yazılır, sonra yapılır.

## Cem'in açık kararları

| # | Karar | Durum | Not |
|---|---|---|---|
| K1 | Kalıp bu hâliyle okey mi? | ⏳ Cem | Pilotlar: KALIP3 (ortak maliyet), KALIP4 (evre/FIFO) + 06.09 iki yeni örnek |
| K2 | ₺ mi TL mi? | ⏳ Cem | Ölçüm: sınav 2018'den beri ₺ (13 dönemde 12). Değişirse 200 soru birlikte |
| K3 | Harf kuralı (A/B/C mamul) | ⏳ Cem | Sınav harfle anıyor; öneri: gövdede serbest, adımlarda "A mamulü" tam ad |
| K4 | Hesap kâğıdı kalıcı mı? | ⏳ Cem | 06.09 yapıldı, eşleme + kasa hazır |
| K5 | `kagit_kayit` SQL'ini basmak | ⏳ Cem | `radar-app/sql/2026-09-06-kagit-kayit.sql`; basılana dek 404 sessiz |
| K6 | Maliyet tekniği kaynağı (MSUGT Sıra No 2) | ⏳ Cem | ≈0,5 USD; hakem teoriyi VUK 275'e yaslıyor |
| K7 | 117 kalıpsız ağır konu üretimi | ✅ **Parti-1 bitti 06.09 13:20** | 14 konu → 13 soru (EOQ kaynak borcu) · hakem EVET 9 / HAYIR 4 (muhasebe bilgi sistemi, ihraç primi, işletmenin sürekliliği, standart maliyet farkları — dördü de KAYNAK PAKETİ eksiği) · Sonnet sim 6/9 doğru; EVET olup sim ✗: gelecek yıllara ait giderler, kâr dağıtımı → adım onarımı gerek · dil kapısı 2 kez çalıştı, uzun adım 1/98 · bozuk 1 (2. turda kurtarıldı) · sayfa `KAYDIR-COZ-PARTI1.html` **6 soru** (Ö29 kapanışıyla kp-08/kp-10 düştü) · bedel ≈3,9 USD (Ö29 dahil) · yedek `C:\TETIKTE-YEDEK\parti1-20260906` |
| K9 | **Parti-2 bitti 06.09 16:10** (Denetim 8 + MTA 8 konu) | ✅ | **Denetim:** 8 soru · hakem EVET 6 / HAYIR 2 (kasa denetimi: banka mutabakatı formülü BDS metninde yok · yapısal risk faktörleri: KONU DIŞI + BDS 700 A54 kaynakta yok) · sim 0/8 (teori, ikiz yok → Ö24) · 8k kesik 5/8 (Ö31 öncesi ayar). **MTA:** 7 soru (asit-test oranı KAYNAK BORCU, basılmadı) · hakem EVET 6 / HAYIR 1 (aktif devir hızı: hakem TTK 64'e yaslanmış, oran formülü kaynakta yok) · Sonnet sim 5 doğru / 2 yanlış (dikey yüzde 50.000≠35.000 gerçek yanlış · yatay analiz "-37,5" = "%37,5 azalış" **karşılaştırıcı yanlış negatifi**, cevap doğru) · aritmetik uyarı 9 (ölçülmedi, ayrı bakılacak). Sayfa `KAYDIR-COZ-PARTI2.html` **11 soru** (Denetim 6 + MTA 5; dikey yüzde sim ✗ diye Ö29 kuralıyla dışarıda) · bedel ölçülmedi (token satırları kütükte) |
| K10 | **Kalıp penceresi = YENİ sınavlar** (Cem 06.09: "o kadar geriye gitmeye gerek yok, yeni sınav kalıplarını almak lazım") | ⏳ Cem: pencere kaç dönem? (GM önerisi 7 = 2024/2–2026/2) | Ölçüm 06.09: ders uzunluk kalıbı (`arac/cikmis-ders-kalibi.ps1`) ZATEN en yeni 10 kitapçıktan (2023/2–2026/2); eski dönemden beslenen üç girdi: (1) konu seçimi "dönem sayısı" = 2015'ten beri toplam, (2) biçim çapası elle seçilmiş `kalipN-ornek.txt`, (3) çeldirici kalıbı 400 kitapçık tavanı. SGS'de Maliyet = S57–64 (8 soru/dönem); son 7 dönemde biçimler: safha/eşdeğer (FIFO/ortalama), sipariş+GÜG yükleme, ortak maliyet (katsayı/satış değeri), standart maliyet sapmaları, normal/tam/değişken maliyet-kapasite, satılan mamul maliyeti tablosu, GÜG II. dağıtım, stok değerleme, 7/A kayıt. **Kusurlu/bozuk/anormal düzeltme: 7 dönemde 0** (2013/3 safha kaybı, 2015/3 kusurlu karar sorusu — pencere dışı). Uygulama 0 bedel: üreticiye `-DonemPencere N` (konu adayı `veri/sgs-analiz.json` son N dönemden, çapa otomatik son N dönem S-aralığından = Ö18) |
| K11 | **"Bu beşi geç" (Cem 06.09 akşam)** — dört gözle kalıp denetimi paketi | ✅ kod `fc56f3b0` | (1) **Soru karnesi + istisna kuyruğu** `motor/soru-karnesi.ps1` → `veri/fabrika/soru-karnesi.json` + `sql-yerel/KARNE.html`: 8 hücre (hakem, sim, aritmetik, hesap kodu–ad, Türkçe, şık dengesi, pencere, kaynak); kırmızı/sarı + yeşillerden %10 örneklem Cem'e; Okey/Yanlış tıkı `soru_bildirim`'e `oturum='karne-cem'` (nöbetçi bu satırları atlar). İlk koşu 28 soru: kırmızı 12 · sarı 8 · yeşil 8 · kuyruk 21. Karne 4 sahte alarm türünü yakaladı ve düzeltti (yüzde, işlem önceliği, tarih farkı, standart numarası). (2) **İki kapı** üreticide: ARİTMETİK kapısı FAZ B'de (tutmayan zincir → adım yeniden, 3 tur) + **KAPI-H** hesap kodu–resmî ad (THP sözlüğü ambardan, 269 belge). (3) **Teori simülasyonu (Ö24)**: teori ikizi + Sonnet öğrenci; Denetim parti-2'de koşuyor (≈0,3 USD). (4) **Öğrenci katmanı** builder: seviye etiketi ölçümden (🟢 Isınma teori · 🟡 Nöbet kayıt/hesap · 🔴 Alarm Maliyet-MTA hesabı ya da sim ✗), ilerleme çubuğu; hedef süre **ölçülmedi** (ambarda SGS süresi yok, TESMER kılavuzu gerek). (5) **K10 penceresi**: üreticiye `-DonemPencere 7` (konu adayları son 7 dönem etiketinden kök-önekiyle, çapa otomatik pencerenin gerçek kitapçığından, Maliyet 57–64); Maliyet kp-01 bununla yeniden basılıyor (≈0,3 USD) |
| Ö37 | Karne bulgusu: TMS 40 sorusu (fmuh parti-1 kp-02) "250 Yatırım Amaçlı Gayrimenkuller" yazıyor; Tekdüzen Hesap Planı'nda 250 = ARAZİ VE ARSALAR. Sınav hangi planı kullanıyor (MSUGT mü TFRS eki mi)? Cem kararı | 06.09 | ⏳ Cem | 0 |
| Ö38 | Akran yüzdesi 5+ cevapta seviye etiketini ezsin (şimdi ders/tip varsayılanı) — `cevap_kayit` SQL'ine bağlı | 06.09 | ⏳ SQL | 0 |
| Ö35 | Sim karşılaştırıcısı işaret/yön eşlemesi: "-37,5" ile "%37,5 azalış" aynı cevap sayılmalı (MTA kp-02 yanlış negatif) | 06.09 | ⏳ GM (dondurma sonrası, 0) | 0 |
| Ö36 | MTA'da hakem oran formülünü TTK 64'te arıyor → MTA kaynak paketi (oran tanımları) Ö30/K6 listesine eklendi; Denetim'de banka mutabakatı + BDS 700 A54 da aynı listeye | 06.09 | ⏳ Cem (kaynak kararı) | ölçülmedi |
| Ö29 | Sim ✗ olan EVET sorular kasaya girmez; adımı `-AdimYenile` ile yeniden yazılıp sim tekrarlanır (kp-08, kp-10 parti-1) | 06.09 | ❌ **KAPANDI (Cem "1 yap" 06.09 15:00)**: adım yeniden yazıldı, Sonnet sim ikisinde de yine yanlış (kp-08 24.000≠6.000, kp-10 65.000≠115.000; kp-08 adımı 12k'da kesildi). İkisi HAYIR sayıldı, Parti-1 seçimi **6 soru** (`parti1-secim.json`). Sebep adım değil KAYNAK (VUK 283 / kâr dağıtımı metni) → K6/Ö30 ile birlikte | 0,2 USD harcandı |
| Ö33 | **Hedefsiz hesap hücresi kapısı** (Cem "2 yap"): hiçbir adımın doldur listesinde olmayan hesap hücresi, değerini (önce formül satırı, sonra anlatım) ya da satır adını anan ilk adıma bağlanır; çok sayılı hücre son sayısının adımında açılır. PS tarafı (üretici adımları) + JS tarafı (kayıt/teori sentetik adımları). TMS 40 ölçümü: Birikmiş maliyet 8. adımda, değer farkı 9. adımda açılıyor; geri gidince kapanıyor | 06.09 | ✅ | 0 |
| Ö34 | Panel kaydırması kart içinde kalır + "▲ Cevaba dön" · derste geri gidince sonraki adımın hücre/satırı kapanır (Cem'in iki ekran gözlemi) | 06.09 | ✅ (dondurma istisnası: kırık ekran) | 0 |
| Ö30 | Hakem HAYIR'ların 4/4'ü kaynak paketi (VUK 227 kontrol toplamı yok, TTK 482 ihraç primi yok, BDS 570 çelişki, VUK 275 sapma değil) → kaynak deseni işi (K6 ile birlikte) | 06.09 | ⏳ Cem | ölçülmedi |
| Ö32 | Kayıt oyunu: tutarlar havuzda karışık + çeldirici, serbest sürükleme, Kontrol et, kutu altı neden (Cem "hepsini yapsın, yanlış yapsın") | 06.09 | ✅ (dondurma istisnası: gerçek eksik) | 0 |
| Ö31 | Zor ayarında ilk tavan 20k (her soru 8k'da kesiliyordu, soru başına 3 dk boş çağrı) | 06.09 | ✅ | 0 |

## Öneriler ve uygulama

| # | Öneri | Tarih | Durum | Bedel |
|---|---|---|---|---|
| Ö1 | Kişisel son adım (öğrencinin kendi hatası) | 05.09 | ✅ | 0 |
| Ö2 | İkiz sızıntı kesişimi (verilen ∩ metin) | 05.09 | ✅ | 0 |
| Ö3 | Maliyet'te Kaynağı göster gizli | 05.09 | ✅ | 0 |
| Ö4 | Sınavda boş alıntı vaadi kaldırıldı · skor 5 cevaptan önce "—" · Kontrol et doğru/yanlış/boş | 05.09 | ✅ | 0 |
| Ö5 | İkiz istemi Türkçe + A/B/C yasağı | 05.09 | ✅ | 0 |
| Ö6 | Adım içinde soru ("önce sen dene", tahmin kapısı) | 05.09 → 06.09 | ✅ 06.09 | 0 |
| Ö7 | Öğrenci simülasyonu kapısı (FAZ Ö, Haiku ikizi çözer) | 05.09 → 06.09 | ✅ 06.09 | ≈0,01/soru |
| Ö8 | Kalıp uyum kapıları: ders p75 tavanı · doğru en uzun 1,3× · şık sıralama | 05.09 → 06.09 | ✅ 06.09 | 0 |
| Ö9 | Zor ayarı (`-Zorluk zor`), gövde sınav gibi (g,h), çapa gerçek çıkmış soru (`-OrnekDosya`) | 05.09 | ✅ | 0 |
| Ö10 | Hesap kâğıdı (yaz + çiz, telefon, kalıcı) | 06.09 | ✅ | 0 |
| Ö11 | Kâğıt ↔ tablo eşlemesi · oturum betiği depo kapısı · kagit_kayit tablosu | 06.09 | ✅ (SQL Cem'de) | 0 |
| Ö12 | Kâğıt → katman raporu betiği · telefon işleç tuş şeridi | 06.09 | ✅ | 0 |
| Ö13 | VERİLENLER bloğu + Adım 1 verilenleri tanı (FAZ V) | 06.09 | ✅ | ≈0,005/soru |
| Ö14 | Konu girişi kartı (FAZ G, 0. adım) | 26.08 → 06.09 | ✅ 06.09 | ≈0,005/soru |
| Ö15 | Tek hata adımı (kişisel varken genel gizli) | 06.09 | ✅ 06.09 | 0 |
| Ö16 | Adım anlatımı ≤2 cümle, dolgu yasak, kapı | 06.09 | ✅ 06.09 | 0 |
| Ö17 | Verilen satırı hesap bloğunda tekrarlanmaz | 06.09 | ✅ istem | 0 |
| Ö18 | Çıkmış çapayı otomatik seç (iki sütun karışmasını önce ölç) | 06.09 | ⏳ GM | 0 |
| Ö19 | Ters soru tipi kotası (pay verilir, miktar istenir) | 06.09 | ⏳ GM | 0 |
| Ö20 | Kâğıt çizim sekmesi el yazısı tanıma | 06.09 | ❌ şimdilik | — |
| Ö21 | Elle dersler (Türkçe/Mat/YD/Atatürk) için kalıp | 05.09 | ⏳ Cem günü | — |
| Ö22 | Kalıbı bir hafta dondur, kural değişikliği haftalık | 06.09 | ⏳ Cem | 0 |
| Ö23 | Simülasyon öğrenci-modeli: Haiku 0/2, Sonnet 2/2 (Maliyet pilotları) → ölçünün modeli Sonnet (≈0,05/soru) | 06.09 | ⏳ Cem | ≈0,05/soru |
| Ö24 | Teori sorularında simülasyon yok (ikiz yok) → teori ikizi: "aynı kuralın başka olayı" 5 şıklı mini soru | 06.09 | ⏳ GM | ≈0,03/soru |
| Ö25 | Denetim'de Kaynağı göster gizli çıktı (BDS metni listeye girmedi) → kaynak paketi ölçülmeli | 06.09 | ⏳ GM | 0 |
| Ö26 | Teori kalıbı ayrıldı: "Ne soruluyor" = soru kökü (cevap sızmaz) · kural KARTI (formül tahtası yok) · "kuralı sen söyle" (sayı tahmini yok) — Cem'in 4 gözlemi | 06.09 | ✅ | 0 |
| Ö27 | Konu girişine somut örnek (hesapsız; Haiku aritmetiği güvenilmez, kapı: "=" / eksi / artı yasak). Maliyet'te örnek hâlâ sorunun rakamlarını tekrarlıyor → Sonnet'e geçiş kararı | 06.09 | ✅ / ⚠ Cem | ≈0,005 → 0,02 |
| Ö28 | Şık eleme ✕ (Becker/Gleim sınav arayüzü) + soru süresi ⏱ (tutor/timed farkı için ilk adım) | 06.09 rakip | ✅ | 0 |
| R1 | **Akran yüzdesi** ("bu şıkkı seçenlerin %N'i"): `cevap_kayit` tablosu + `sik_yuzdesi` fonksiyonu + ekranda şık altı yüzde, 5 cevaptan az ise gizli, yanlış şıkta %40+ kırmızı | 06.09 | ✅ kod · ⏳ **Cem SQL basacak** (`2026-09-06-cevap-kayit.sql`) | 0 |
| R2-R7 | Kartıma ekle · vurgulama · "anlamadım" (Net Cevap) · timed mode · konu bazlı performans · illüstrasyon → `RAKIP-KALIP-KARSILASTIRMA.md` | 06.09 | ⏳ dondurma sonrası | dosyada |
| K8 | **Dondurma 06.09–13.09**: kural değişikliği haftalık; üretim donmuş kalıpla | 06.09 | ✅ Cem "2 yap" | 0 |

## Kalıcı kurallar (şartnamede)
Kilit 05.09 · zor ayarı · verilenler bloğu · kâğıt · tahmin kapısı · konu girişi · tek hata adımı · sınav dili (kısaltma yok, şıkta birim yok) · şık sıralama · ders p75 tavanı.
