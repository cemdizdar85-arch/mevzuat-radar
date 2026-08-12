# KS-12 — Araç Ayrım Denetimi Defteri

> Cem 12.08: "bunu her yere yap, bu çok önemli."
> Yöntem: sayfadaki her mevzuat iddiasının dayanak maddesi ambardan okunur;
> maddede oran/şart FARKLILAŞMASI varsa (imalatçı/ihracatçı, büyükşehir/diğer,
> işçili/işçisiz, yıl geçişi, ülke/tür/kanal ayrımı...) aracın bu ayrımı
> kullanıcıya sorduğu/gösterdiği doğrulanır. Üç sonuç: GEÇTİ / KUSUR(+düzeltme) / ÖLÇÜLEMEDİ.

## 12.08.2026 turu

| Sayfa | İddia yoğunluğu | Sonuç | Not |
|---|---|---|---|
| kurulus.html | 75 | **2 KUSUR → DÜZELTİLDİ+YAYINDA** | (1) "çalışan olacak mı" basit usulü kapatıyordu — m.47/1 çırak istisnası metinden teyit, soru ikiye bölündü; (2) üretim al-satla aynı şıktaydı — 2027 %12,5 ayrımı (7582) şıkka ve gerekçeye işlendi. Ayrıca 11 madde elle okundu (KVK m.10/ğ, TBK 620/638, GVK 51/65/mük.20/9, 4691 geç.2, TTK 211/304, KoopK 1); m.51 örnekleri ve m.9 %4-%2 stopaj notu sayfaya eklendi. |
| ceza-asistani.html | 99 | **GEÇTİ** | Örnek tasarım: gecikme zammı `gecikme-zammi.json`+robot (hard-code yok); m.344 kat ayrımları (3 kat kaçakçılık, kendiliğinden bildirim) var; uzlaşmada kaçakçılık istisnası + gümrük m.244 kapalılığı + 15/30 gün kanal ayrımı; 7524 tek-oran m.376 işlenmiş; uzlaşma eşiği bilinçli rakamsız ("tutara bağlı"+YMM). |
| asgari-kv.html | 41 | **GEÇTİ** | m.32/C bent bent izleniyor (C-1 %10, C-2 düşülecek istisna listesi, C-3 mahsuplar, C-5 ilk-kuruluş 3 dönem muafiyeti, C-6 taban tanımı); 7524+7582/9 güncel; "beyandan önce mali müşavir" yönlendirmesi var. |

| hizmet.html | 42 | **1 KUSUR → DÜZELTİLDİ+YAYINDA** | 9 tür × ÇVÖA/mukimlik/183-gün matrisi sağlam; brüt/net gross-up notla çözülmüş; faizde stopaj %0-10 banka ayrımı vardı AMA **KDV-2 her türde %20 sabitti** — yurt dışı BANKA kredisi faizi KDV'den istisna (KDVK m.17/4-e ambardan birebir teyit). Sonuç tablosu + hesap makinesi faize duyarlı yapıldı ("banka: yok · diğer: %20"). |
| kurulus.html (ek tur) | — | **1 KUSUR → DÜZELTİLDİ+YAYINDA** | Ortaklı senaryoda vergi kıyası tek kişilik şahıs matematiği basıyordu; adi ortaklıkta kâr bölüşümü + ortak başına genç istisnası (mük. m.20/3) hesaba işlendi, ortak sayısı seçici eklendi (2 genç ortak 600.000 kârda vergi ~0 gerçeği artık görünür). Cem'in akış önerisi (sorular sıralı/aşamalı açılsın) ayrı iş: aşağıda. |

## SIRADA (öncelik = iddia yoğunluğu × para riski)

- [x] **[Cem 12.08] kurulus.html akış yeniden tasarımı — YAPILDI+YAYINDA:** sorular
      aşamalı açılıyor (cevaplandıkça sıradaki belirir + kayar; 9/9 bitince öneri
      düğmesi çıkar). Motor değişmedi, görünürlük katmanı; tıklama-akışı testiyle doğrulandı.
| hatirlatici.html | 35 | **GEÇTİ + AMBAR BOŞLUĞU** | Ayrım tasarımı doğru (her belge türü ayrı kart; AŞ m.409 / LTD m.617 ikisi de var; m.409 "üç ay" ambardan birebir teyit; DİİB ek süre m.20 anılmış). BOŞLUK: DİİB kartlarının dayanağı Dahilde İşleme mevzuatı (2005/8391 Karar + İhracat 2006/12 Tebliği) AMBARDA YOK — sayfa konsolideden elle okunmuş (dipnotlu) ama robot nöbetinde değil; yutma adayı. |
| karne.html | 34 | **GEÇTİ — örnek disiplin** | Eşikler kaynaklı config objesinde (bağımsız denetim: 11066 s. Karar 17.03.2026 RG, 2026 dönemi, "3 ölçütten 2'si + 2 yıl üst üste" mekanizmasıyla; avukat bulundurma 1.250.000 = güncel AŞ asgarisinin 5 katı türetimi); belirsiz kalemlerde `teyitEksik` bayrağı deseni var. |
- [ ] fiyatfarki.html (27) — credit/debit note; KDV-gümrük kıymeti-tamamlayıcı beyan üç kanal ayrımı
- [ ] destekler.html (27) — destek şartlarında ölçek/bölge ayrımları
- [ ] gtip.html (25) — ülke-oran (MFN/STA/ek vergi) ayrımı; KDV I/II listeleri
- [ ] kdv-iade-rehberi.html (23) · ihale-radari.html (23) · marka-radari.html (22)
- [ ] songun.html (19) · kontrol-listesi.html (19) · risk-taramasi.html (17) · genc.html (17)
- [ ] marka-itiraz.html (16) · index.html (16) · bilgi.html kartları (61 — kart kart)
- [ ] sayfalar/* (e-fatura-zorunlulugu.html dahil)

## Kalıcı kural 2 (12.08, Cem: "onu seçtiğinde soracaksın")

Bir kutu ŞART sayıyorsa ya şartı SORAR (koşullu mini-sorgu) ya da hangi şartın
kritik olduğunu ADIYLA söyler; "muhasebecine sor"la yarım bırakmaz. İlk uygulama:
basit usul kutusu 3 buton-soruya çevrildi (büyükşehir → kira eşiği dinamik 99.000/60.000 ·
kiralık/mülk → mülkte emsal kira m.47/2 yarı-hükmü · m.48 haddi) ve cevaba göre
✓ tutuyor / ✕ takılan şart adıyla / ◐ emsal kira hesabı hükmü veriyor.

## Kalıcı kural

`vergi-sabitleri.json`'a (ya da herhangi bir veri dosyasına) ORANI KOŞULA GÖRE
DEĞİŞEN yeni alan giren herkes, o ayrımın ilgili araçta bir soruya/koşullu
kutuya dönüştüğünü bu deftere işleyerek doğrular. Robot oranı yakalar,
tasarım ayrımı taşımazsa kullanıcı yanlış yönlenir — 12.08 kurulus dersi.
