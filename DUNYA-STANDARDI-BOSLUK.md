# DÜNYA STANDARDI BOŞLUK ANALİZİ — "biz bu işin en iyisi olmalıyız"
> 13.08.2026 · Cem: *"başka atladığımız bir şey var mı? ABD İngiltere rakiplere bak."*
> Ölçüt: NBME Item-Writing Guide (ABD sınav bankalarının altın standardı; CPA/AICPA
> bankaları da aynı ilkelerle çalışır) + UWorld/Becker/Kaplan ürün özellikleri.
> Kural: her boşluk ya KAPATILDI ya da AÇIK olarak tarihlendi — "sözde iş" bırakılmaz.

## ✅ 13.08'de KAPATILANLAR (bugün kuruldu, ölçüldü)
| Kapı | Ne ölçer | İlk sonuç (3.540 yayın adayı) |
|---|---|---|
| **K15 sınav tekniği** | cevap anahtarı dağılımı · doğru şık en uzun mu · küme içi kopya | **A %47,5 → KIRMIZI** · uzunluk %32,4 yeşil · **5 kopya çifti** |
| **K16 tablo/yevmiye** | görsel var mı · yapı sağlam mı · borç=alacak · uydurma rakam | **598 hesaplı soruda tablo YOK** · 55 yapı bozuk · **denge temiz (0)** · 15 uydurma rakam |
| **K17 madde yazım tekniği** (NBME) | mutlak terim · hepsi/hiçbiri · uzunluk ipucu · sayı sırası · kelime tekrarı · vurgusuz olumsuz kök | 65 · 1 · 233 · **354** · 302 · **438** |
| Yetki devri denetçisi | kanun doğru ama ikincil düzenleme değişmiş mi (site) | 19 aday, 2 gerçek açık kapatıldı |
| Vana kuralı | yayın = kapı-temiz **VE** okuyucu-uygun | 3.540 → 37 (okunan kadarı) |
| Hata-bildir askısı | tek geçerli bildirim → otomatik yayından indir | oturum tavanı 5 ile kötüye kullanım frenli |
| Soru etki zinciri | kanun değişince o kanuna dayanan yayındaki sorular askıya | motorda, mail'li |

## 🔴 AÇIK — EN BÜYÜK EKSİK: PSİKOMETRİ (item analysis)
Rakiplerin (UWorld, Becker, Kaplan) ve resmî sınav kurullarının asıl kalite silahı bu; bizde **hiç yok**:
- **p-değeri (güçlük):** soruyu kaç aday doğru yaptı. Bizim "zorluk" etiketimiz makine tahmini, ölçüm değil.
- **Ayırt edicilik (point-biserial):** soruyu, sınavın tamamında başarılı olanlar mı doğru yapıyor? **Negatif ayırt edicilik = soru bozuktur** — içerik denetiminden geçse bile. Literatürde bozuk madde tespitinin ana yöntemi budur.
- **Çeldirici verimliliği:** hiç seçilmeyen şık ölü şıktır, soruyu 5'ten 4'e düşürür.
**Ön koşul:** yayın açılıp cevap verisi birikmesi (soru-cevap logu). **Plan:** açılışta her cevap `soru_id, dogru_mu, sure, oturum` olarak kaydedilir; 30 cevaba ulaşan soruda istatistik hesaplanır; negatif ayırt edici sorular **otomatik askıya** (mevcut askı hattına bağlanır). Bunu kurduğumuzda Türkiye'de başka kimsede olmayan bir şey oluruz.

## 🟡 AÇIK — orta öncelik (açılış sonrası ilk ay)
1. **Aralıklı tekrar (spaced repetition):** yanlış yapılan soru 1-3-7-21 gün sonra tekrar çıkar. UWorld/Anki modeli; bizde "işaretle" var, otomatik dönüş yok.
2. **Mevzuat tarih damgası (as-of date):** her soruya "bu soru X tarihli mevzuata göre yazıldı". Etki zinciri kanun no'suna bakıyor; tarih damgası olursa "eski mevzuatla yazılmış soru" kendiliğinden görünür.
3. **Erişilebilirlik (WCAG 2.2 AA):** klavye ile tam gezinme, ekran okuyucu etiketleri, kontrast. İngiltere'de (Equality Act) ve ABD'de (ADA) yasal zorunluluk; bizde hiç ölçülmedi.
4. **Errata/şeffaflık sayfası:** "bu hafta şu soruları düzelttik" kamuya açık kayıt. Rakiplerin çoğu yapmaz; bizim en güçlü güven silahımız olur (hata-bildir hattımız zaten var).
5. **Konu kapsama karnesi (blueprint coverage):** resmî sınav konu dağılımıyla bankanın dağılımı yan yana — "hangi konuda kaç soru var, sınavda kaç çıkıyor" açık grafik.

## ⚪ Bilinçli DIŞARIDA (karar verildi)
- Chatbot/"soru sor" asistanı — yanlış cevap riski, [[feedback-zararli-itiraz]] ilkesi.
- Video ders — kurs değiliz (5580 riski, [[acilis-kontrol-listesi]]).
- Adaptif motor (IRT tabanlı) — psikometri verisi birikmeden anlamsız; Faz 2.

## SIRA (öneri)
1. **Şık karıştırıcı** (A yığılmasını çöz — mekanik, güvenli, bugün yazılabilir)
2. **Sayı sırası düzeltici** (F4: 354 soru — tamamen mekanik, riski sıfır)
3. **Olumsuz kök vurgulayıcı** (F6: 438 soru — biçim işi)
4. Tablo kuyruğu (598) + F3/F5 (uzunluk-kelime ipucu) — bunlar **yeniden yazım** ister, okuyucu hattıyla birlikte
5. Açılışta cevap logu → 30 cevapta psikometri → otomatik askı
