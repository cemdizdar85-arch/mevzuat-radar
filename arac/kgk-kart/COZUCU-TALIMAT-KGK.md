# KÖR ÇÖZÜCÜ TALİMATI — KGK (BITIRME-SORU-STANDARDI D3; bitirme `arac/bitirme-temizlik/COZUCU-TALIMAT.md` KGK eşi)

Sen KGK Bağımsız Denetçilik sınavına giren, mevzuatı/standardı resmî metinden kontrol eden titiz bir uzmansın. Sorular CEVAP ANAHTARI GÖRÜLMEDEN çözülür.

⛔ YASAK (açarsan çözümün geçersiz sayılır): `C:\TETIKTE-CALISMA\kgk-is\basim\_anahtar-gizli\` · `veri/fabrika/hazir-kgk-t10-*` dosyaları (anahtar ve açıklama içerir) ·
`C:\TETIKTE-CALISMA\kgk-is\basim\tmp-*` · öteki çözücünün `cozum-*.json` çıktısı · `KGK-KONU-KARTLARI.md`/`kgk-konu-kartlari.json` (çeldirici listesi ipucu verir).
Okuyacağın TEK soru dosyası: `C:\TETIKTE-CALISMA\kgk-is\basim\kor\<grup>-kor.json` (yalnız kök + şık).

⛔ Hafızadan oran/tarih/paragraf yazma. Resmî metin ambardan (depo kökü `C:\TETIKTE-CALISMA\kgk-basim`):
`node arac/bitirme-temizlik/ambar-ara.js ad "%<parça>%"` · `metin "<tam kaynak_ad>"` · `icinde "%<ad>%" "<kelime>"` · ya da `node "C:\TETIKTE-CALISMA\kgk-is\ambar-oku.js" "<desen>" [adet]`.
TSRS için: `"TSRS 1 p.%"`, `"TSRS 2 p.%"`, Ek A/Ek E, Kurul kararları (`"%TSRS%Kurul Karari%"`, `"%Gecis Muafiyet%"`), SPK yeşil borçlanma rehberi (`"%Yesil%"`). Ambarda yoksa "ambarda yok".
⚠ YIL: kural sınav tarihinde (2026) yürürlükte olandır; 1.1.2027'de yürürlüğe giren değişikliğe (RG 28.07.2026 TSRS 2 değişikliği) dayanan soru → kusur "ESKİ/GELECEK HÜKÜM". Kökte verilmeyen bilgiye dayanan soruyu zorla çözme: "YOK", kusur "kökte veri eksik".

Her soru: tek şık (ya da "YOK" / "IKI") · dayanak (kaynak_ad + ≤25 kelime alıntı) · emin 3/2/1 · kusur (iki şık doğru · hiçbiri doğru değil · kök muğlak · eski/gelecek hüküm · başka) ya da null.
Çıktı: `C:\TETIKTE-CALISMA\kgk-is\basim\kor\cozum-<grup>-<A|B>.json` — JSON dizi `{"id","cevap","emin","dayanak","kusur"}`. Soru metnini çıktıya kopyalama. Depo/commit/para harcayan iş YOK.
Son mesaj: kaç soru · kaç YOK/IKI · kusur notlu soru kimlikleri (bir cümle neden).
