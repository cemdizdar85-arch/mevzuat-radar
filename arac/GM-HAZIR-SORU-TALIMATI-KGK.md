# GM HAZIR SORU YAZIM TALİMATI — KGK (Bağımsız Denetçilik) · kalıcı şablon

> 07.10.2026, Cem "eksik kuralları yapalım" (KGK oturumu, K1 + K7). Her KGK GM turunda yazar ajana BU dosya + `arac/GM-HAZIR-SORU-TALIMATI.md`
> (yeterlilik talimatı) verilir. Yeterlilik talimatının **B25, A/B kontrol listesi, E6/G1 önek alıntı, G2 çeldirici = tek yanlış, G3 atıf
> zinciri, G4 kökte olmayan bilgi, F.1 çeldirici yolu `;` zinciri, F.2 teoride tablo yok, F.3 adım kuralı genel, F.4 harf planı, DALGA DÜZENİ ve
> İKİNCİ GÖZ** bölümleri KGK'da AYNEN geçerlidir. Vergiye özgü maddeler (C listesinin KDV/GV oranları, D, E1–E5) KGK'da yalnız konu vergiye
> değiyorsa (TMS 12) uygulanır. Bu dosya KGK'ya özgü olanları ekler; çelişkide bu dosya kazanır.
> Soru metni bu dosyaya ve depoya GİRMEZ; yazar yalnız `veri/fabrika/hazir-kgk-<dalga>-<modül>-<zorluk>[-N].json` dosyasına yazar.

## Neden ayrı dosya (ölçüldü 07.10)
- Yerel KGK hazır dosyalarında (60 dosya, 814 soru; d1/d1b 27.09'da yazıldı) **808 soruda adımlar şık HARFİ anıyor** ("Cevap B şıkkıdır.",
  "A şıkkını seçmek (HATALI) → doğrusu B"). Seviye testi ve şık kaydırma şıkların yerini değiştirir → metin yanlış harfi gösterir.
- KGK'da KAPI-K sözlüğü, B25 sertliği, uzunluk tavanı ve onarım hattı KGK listesi yoktu (07.10 kuruldu, aşağıda).
- 27.09 ölçümü (79 GM Denetim sorusu, 71 yayın şartı geçti): düşen 8'in 5'i hakem2 "YZ kokusu", 3'ü simülasyon YETMEDİ (anlatım tanımı ve
  faktörün yönünü eksik veriyordu).

## Kaynak — hafızadan paragraf/madde/rakam YAZILMAZ
- Paragraf, madde, fıkra, oran, eşik yalnız AMBARDAN (`dokumanlar.kaynak_ad`); kullanılan her kayıt `kaynak_adlar`'a birebir.
  Ad biçimleri: `BDS 701 p.13 - …`, `TMS 16 p.31 - …`, `Sermaye Piyasası K. (6362 s.K.) m.35`, `Bankacılık K. (5411 s.K.) m.24 [1/2]`,
  `Sigortacılık K. (5684 s.K.) m.16 [1/3]`, `KGK Kurulus KHK (660 s.) m.9 [1/4]`. Parçalı maddede ([k/n]) atıf yapılan fıkranın geçtiği parça da listeye.
- **KAPI-AILE:** kaynak yalnız modülün resmî aileleri (`veri/kgk-ders-aile.json`). Örnek: Denetim sorusuna TTK maddesi değil BD Yönetmeliği/BDS;
  Sigorta sorusuna TTK yalnız m.14xx–15xx. Aile dışı kaynak paketten sessizce atılır → soru "kaynak yetersiz" düşer.
- **Paragraf numarası resmî metinden:** BDS 500 eski numaralama (A25→A29 … A31→A35 kaydı) kullanılmaz; KAPI-BP komşu paragrafı yakalar.
  BDS 700 p.50 bent harfleri ambarda YOK → bent harfiyle atıf yapma, paragrafla yap.
- **Yeni sürüm esas** (Cem 30.09): TMS 1 yerine TFRS 18 (KAPI-EK). TFRS 18 01.01.2027'de yürürlüğe giriyor; sunum sorusunda kök hangi standarda
  göre sorulduğunu AÇIK yazar ("TFRS 18'e göre …"). İki standarda göre farklı cevabı olan kök yazılmaz.
- **Finansal Yönetim istisnası** (Cem 27.09, karar A): resmî metin yok (SPL 1007 telifli). Formül/kavram notunu GM yazar; her soru yine kör çözüm
  + simülasyondan geçer. "Resmî metin" kuralının TEK istisnası, yalnız FY modülü.

## ⭐ K7 — YILA BAĞLI TUTAR VE EŞİK
- Yıla bağlı eşik (bağımsız denetime tabi olma ölçütleri, sermaye/özkaynak alt sınırları, idari para cezası tutarları, BDDK/SEDDK oranları)
  **o yılın düzenlemesinden** alınır (Cumhurbaşkanı kararı, kurul kararı, yeniden değerleme ilanı) ve dayanağı o düzenlemedir, kanun maddesi değil
  (yeterlilik talimatı E1'in KGK karşılığı). Ambarda o yılın düzenlemesi yoksa senaryo o eşiğe ÇARPMAZ (sözleşme B11) — ayrıca kaynak borcu yazılır.
- Kökteki EN YENİ yıl = bugünün yılı (KAPI-Y, ön denetimde KUSUR). Geçmiş yıl soruluyorsa bugünün yılı bağlamı verilir
  ("2025 yılı finansal tabloları için 2026 yılında yapılan bağımsız denetimde …"). Kanun numarası ("6362 sayılı") sayılmaz.
- "Bu madde … tarihine kadar uygulanır" diyen geçici maddeye uzatması ambarda yoksa dayanılmaz.

## ⭐ KGK'YA ÖZGÜ YAZIM KURALLARI
1. **K4 — Şık harfi ANILMAZ** (kök dışında hiçbir alanda: açıklama, teşhis, sade, adımlar, çeldirici yolu, hap, sınav taktiği).
   "Cevap B şıkkıdır." / "C şıkkı bu yüzden düşer" / "doğrusu A" / açıklama sonunda "Doğrusu: B." / çıplak harf ("A ve D düşer",
   "B söyler →", "yalnız E'de → E") YASAK — 07.10 onarımında 770 KGK sorusunun 486'sında bu kalıplar vardı, site "Doğrusu:" sonrasını
   olduğu gibi gösteriyor. Şık İÇERİĞİYLE anılır: "Doğru cevap: görüş vermekten kaçınma."
   "Bildirimi kaldıran seçenek p.14'e aykırıdır." Teori adımının son adımı: "Doğru şık: <şık metni>". Kişi adı "(A) Bey" serbest.
2. **K5 — "(soruda verilen)"** yalnız kökte harfiyen geçen sayıya. Hesaplanan değer "(N. adımda bulduk)" ile anılır (S1).
3. **K6 — Fıkra atfı** (`m.X/Y`) ambar metnindeki "(Y)" fıkrasından okunur; maddenin parçalı kaydında fıkra hangi parçadaysa o parça `kaynak_adlar`'da.
   Numarasız fıkralı eski kanunda fıkra numarası verme ("birinci fıkra" diye sayma da yapma) — maddeyle atıf yap.
4. **Olumlu kök tercih edilir** (15.09 ölçümü: hakem olumsuz kökte "işaretli şık yanlış" deyip HAYIR verdi). Olumsuz kök gerçek sınav kalıbındaki
   payı aşmaz (`veri/sinav-anatomisi-kgk.json`; ölçülmeden sabit oran yazılmaz).
5. **Doğru şık TEK bir maddeye/paragrafa dayanır** (KAPI-KP konu dışı sayıp ilke kararını paketten düşürebiliyor).
6. **Tutar resmî yazımla:** "750.000.000 TL" ("750 milyon TL" KAPI-H'de THP 750 hesabı sanılır). Üç haneli sayıyı birimsiz yazma (KAPI-HG).
7. **Çözüm anlatımı tanımı ve her faktörün YÖNÜNÜ eksiksiz verir** (27.09: simülasyon "yetmedi" 3/8). Risk/önemlilik sorusunda "artırır/azaltır"
   her faktör için ayrı yazılır; simüle öğrenci ikiz soruyu (aynı kural, başka faktör) bu anlatımla çözebilmeli.
8. **YZ kokusu yok** (27.09: hakem2 düşüşlerinin 5/8'i): "bu bağlamda", "önem arz etmektedir", aynı cümle kalıbının tekrarı, em-dash, placeholder
   unvan (ABC A.Ş.) yok. Denetçi/işletme adı kısa ve doğal ("Ege Denetim", "(K) A.Ş.").
9. **KAPI-K (KGK sözlüğü):** kökte KGK kitapçıklarında hiç geçmeyen (≥6 harfli) kelime en çok 1. Ön denetim tüm KGK kitapçıklarından kurulan
   sözlükle ölçer (`KGK KAPI-K` satırı); bulut KGK'da KAPI-K koşmaz — bu yalnız sınav dili kalitesidir, düşen kelimeyi sınav diliyle değiştir.
11. **T kodlu paragraf (Türkiye uygulaması) esastır** (07.10 ikinci göz, kgk-o2-tds-zor/kp-10 ÇIKAR): BDS 700/705/720'de "2T, 21T, 22T" gibi
    Türkiye'ye özgü paragraf varsa soru onlara göre kurulur ve kök bunu yazar. Örn. Türkiye'de faaliyet raporu (diğer bilgiler) DENETLENİR
    (BDS 720 p.2T) — uluslararası p.21-22'ye göre "denetlenmez" diye anlatılan soru iki doğru şıklı olur.
12. **Tanım tek bende indirgenmez** (07.10, 27 DÜZELT'in en sık sınıfı): tanımın birden çok bendi/şartı varsa (BDS 505 p.6 "yanıt" tanımı,
    BDS 250 kapsam kısıtı p.27-28, BDS 510 p.10-11 görüş seçenekleri) "yalnız / her / … olur" ile tek bende daraltılmaz.
13. **"Kural:" kısmına kaynakta olmayan sonuç cümlesi eklenmez** ("böylece yeni risk doğar") ve "gerekebilir" → "gerekir" sertleştirilmez.
14. **Kavram tanımının kaynağı** (`sade.kavramlar[].kaynak`) tanımın GERÇEKTEN geçtiği paragraftır ve `kaynak_adlar`'a da eklenir
    (07.10: GDS 3400 p.9 yerine p.4, BDS 500 p.A64 yerine BDS 315 p.12 — hiçbir kapı bu alanı okumuyor).
15. **Örnek olayda iki ilkeye birden uyan senaryo kurulmaz** (07.10, kp-30: yönetim müşteriyle birlikte → hem muvazaa hem kontrol ihlali).
10. **Bir dosyada bir konudan BİR soru** (27.09: 85 sorunun 19'u aynı konu adıyla iz bırakmadan kayboldu).

## Modül sırası ve önkoşul (07.10)
- Denetim Standartları → Muhasebe Standartları → Finansal Yönetim → Kurumsal Yönetim → Sürdürülebilirlik.
- **Başlık sızması (madde sonuna sonraki başlık):** yutucu düzeltildi (122d1279). 07.10 altyapı: Bankacılık (255 kayıt) + Sigortacılık
  (106) TAZELENDİ (928af587) → yazılabilir. **SPK (6362) henüz tazelenmedi** (m.35'e 35/A başlığı sızmıştı → iki doğru şık); bulut boşalınca
  yazılacak — o zamana dek SPK'ya yazım YOK.
- **Standartlarda da sızma var** (07.10 altyapı ölçümü: 4.240 paragrafta 610 başlık kuyruğu adayı, örneklem 39/40 gerçek; Etik 317, TFRS 124,
  TMS 94, BDS 29). 122d1279 standart yutucusunu KAPSAMIYOR. Yazarken: paragraf metninin sonundaki noktalamasız başlık parçası hükmün parçası
  DEĞİLDİR — ona dayanan şık/açıklama yazılmaz (ör. BDS 701 p.13 sonu "…Denetçi Raporunda Bildirilmediği").

## Teslimden önce (zorunlu)
```
powershell -NoProfile -ExecutionPolicy Bypass -File arac/hazir-soru-denetle.ps1 -Dosya veri/fabrika/hazir-kgk-<…>.json
```
Dosya adı `hazir-kgk-…` ise (ya da `-IkizEtiket kgk-…`) KGK sıkı modu kendiliğinden açılır: ADIM YOK / SADE YOK / SIM KUSUR · KGK HARF ANMA ·
KGK SORUDA VERİLEN · KGK FIKRA ATFI · KGK uzunluk tavanı (Denetim 784, Muhasebe Standartları 661 — etikette tms/tfrs yoksa `-Tavan 661`;
KGK'da `-Ders` VERME, SGS sözlüğü kurulur) · KGK KAPI-K. Çıktıda KUSUR kalmaz. Sonra İKİNCİ GÖZ (yeterlilik talimatı) → yükle → plan → bulut sırası.
Onarım: `node arac/onarim-hatti.js teslim <klasör>` kgk- etiketini artık `veri/sinav/kgk-elle-ret.json`'a yazar (07.10, K8).
