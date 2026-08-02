# TETİKTE — DEĞİŞMEZ KURALLAR

Bu dosya, üzerinde **anlaşıp karara bağladığımız** ilkelerin tek kaydıdır.
Kural burada yazılıysa tartışılmaz, uygulanır. "Şu an pratik olan" bir kuralı
geçersiz kılmaz. Yeni kural ancak Cem'in açık onayıyla eklenir.

---

## 0. SIFIR YANLIŞ KURALI (02.08.2026 — Cem: "1 adet bile yanlış soru ve cevap istemiyorum; ne gerekirse yap")

**Sitede yanlış cevap olmayacak. Yanlışı öğrenciden önce BİZ göreceğiz.**

- Bir soru, **insan okumasından geçmeden** yayına açılamaz. Robot kapıları
  (üretim elekleri + hakem 3/3 + alıntı doğrulaması) *ön eleme*dir, yeterlilik
  belgesi değildir.
- **Neden:** ölçüldü — hakem 12.996 hükmün 630'unda (%5) kendi alıntısını
  uydurdu; teori eşleştirmesi örneklemde %40 yanlış nota bağladı. Bu tabloda
  "hepsi doğru" demek yalan olur.
- **02.08'de uygulandı:** yayındaki 9.905 sorunun tamamı yayından çekildi
  (silinmedi, `yayin=false`). Yayın artık **okunan partilerle** açılır.
- **Dayanağı ambardan çözülemeyen soru yayına giremez** — istisnasız.
- Şüphe varsa soru **bekler**. Az ve doğru, çok ve şüpheliye yeğdir.

## 1. YUTMA KURALI (02.08.2026 — Cem: "üstünkörü değil, en küçük maddesine kadar")

**Bir metin yutulurken tek satırı bile atlanmaz.**

- Kısa madde/paragraf **atılmaz** — bir önceki kayda eklenir.
- Uzun madde **kesilmez** — cümle sınırından dilimlenir, `[1/3]` etiketiyle saklanır.
- İlk başlıktan önceki ön-bölüm (künye, amaç, kapsam) de ambara girer.
- Madde deseni tutmayan metin (tebliğ, standart, bölüm yapılı) **atlanmaz** —
  bölüm parçalayıcısıyla yutulur.
- **KAPSAMA ÖLÇÜMÜ ZORUNLUDUR:** her yutmadan sonra
  `kaynak karakter → ambar karakter` oranı hesaplanır ve rapora yazılır.
  **%98'in altı KIRMIZIDIR** ve düzeltilmeden geçilmez.

*Neden:* Ambar yalnız soru fabrikasının değil, **soru-cevap aracının** da
kaynağıdır. Kullanıcı tebliğin ortasındaki bir fıkrayı sorduğunda o fıkra
ambarda yoksa araç ya susar ya uydurur. İkisi de kabul edilemez.

*Bedeli görülen vakalar:* SMK m.5/3 muvafakatname fıkrası 1800-karakter
kesiğinde kaybolmuştu (27.07, marka başvurusunda eksik bilgi). KYS 1'in
%27,6'sı parçalayıcı kestirmesiyle kaybolmuştu (02.08, ölçümle yakalandı).

---

## 2. KAYNAKSIZ İÇERİK YASAĞI

- Birincil metin yutulmadan o konuda **içerik yayınlanmaz, soru üretilmez.**
- Resmî metni olmayan alanlarda (finansal yönetim, mikroekonomi, maliye
  teorisi) yol: **Cem+GM onaylı kürasyon teori notu** ambara girer, sorular
  ona bağlanır. Kaynaksız üretim yine yasaktır.
- İkincil kaynak (blog, sirküler, sunum) yalnız keşif içindir; iddia asla
  ikincilden yayınlanmaz.

---

## 3. YAYIN KAPISI

- Üretilen her soru kasaya `yayin=false` girer.
- Yayına ancak **hakemden 3/3 geçen** (cevabı madde destekliyor + tam olarak
  tek şık doğru + açıklama maddeyle çelişmiyor) **ve alıntısı makineyle
  doğrulanmış** sorular açılır.
- Yayın kararı **robotun değil GM'nin**; otomatik cron yoktur.

---

## 4. PARA KURALI

- Ücretli koşu öncesi **ölçüm modu** (0 USD) çalıştırılır, maliyet Cem'e
  rakamla bildirilir.
- Ödenmiş iş ikinci kez satın alınmaz: batch kimliği saklanır, `-kurtar` ile
  bedava hasat edilir; yargılanmış sorular `-haric` listesiyle atlanır.
- Önce bedava yol denenir; ücretli yol ancak bedava yol yoksa açılır.
- Tavan aşılacaksa **önce haber verilir**, sessizce aşılmaz.

---

## 5. KÖR KALMA YASAĞI

- Para harcayan her kanal hatasını **dosyaya** yazar (Actions logları
  admin-kilitli). Hata gövdesi her koşulda okunur.
- "Yeşil koşu ≠ tam veri": yazma sonrası **geri okuyup sayım** yapılır.
- Sessiz çöp, açık hatadan tehlikelidir: sınır aşılırsa iş DURUR.

---

## 6. RAKAM DİSİPLİNİ

- Hiçbir sayı uydurulmaz. Kaynağı yoksa yazılmaz; teyitsiz iddia yumuşatılır.
- Site rakamları robotun ölçtüğü dosyadan gelir; boş/sıfır asla basılmaz.

**6a. BİRİNCİL KAYNAK KİLİDİ** *(02.08.2026 — Cem: "1. kaynak dışı okuma YOK";
VUK 323 vakası: eşik önce müşavirlik sirkülerinden 'teyit' edilip deftere yazıldı — İHLAL):*
- Mevzuat rakamı/olgusu doğrulaması **yalnız birincilden**: Resmî Gazete,
  mevzuat.gov.tr, GİB, KGK, kurumun kendi sitesi. Web araması bu alanlara
  **kilitli** yapılır (allowed_domains); serbest arama yalnız "hangi tebliğ,
  hangi RG sayısı" işaretini bulmak içindir ve tek başına hiçbir karar üretmez.
- Bulgu defterine / rapora / kasaya bir rakam, ancak birincil METİN gözle
  okunduktan **sonra** girer. "Şimdilik yazayım, sonra birincile bakarım" yasak.
- Okunan birincil belge depoya kaydedilir (`veri/kaynak-*.pdf`) — kanıt iz bırakır.
- Sirküler/özet/blog/yapay zekâ özeti = İŞARET'tir, TEYİT değildir. İstisnasız.

---

## 7. KARAR SIRASI

1. GM kendi görüşünü **sorulmadan** söyler (gerekçesiyle).
2. Cem karar verir.
3. Karar uygulanır — ve bu dosyaya yazılır.

Karara bağlanmış bir işi GM kendi kestirmesiyle değiştiremez. Değişiklik
gerekiyorsa önce söyler, onay alır.
