# KGK KONU KARTI DOLDURMA TALİMATI (05.11.2026 · kol kgkbasim · BITIRME-SORU-STANDARDI K1'in KGK eşi)

Bitirmenin `C:\TETIKTE-CALISMA\kalip-olcum\KART-DOLDURMA-TALIMAT.md` talimatının KGK uyarlaması. Kart = bir KGK konusunun yazım şartnamesi;
"kartsız soru YAZILMAZ" (K1). Yazar kartın kalıp DAĞILIMI, kök hedefi ve şık türü dışına çıkamaz.

## Dosyan
`C:\TETIKTE-CALISMA\kgk-is\kart\parca\<PARÇA>.json` — her öğe bir kart. ÖLÇÜLMÜŞ alanlar dolu ve DOKUNULMAZ
(modul, konu, diger_adlar, donem_sayisi, son_donem, soru_sayisi, son10, sitede, hedef, eksik, ornek, kalip, kalip_dagilim, tahmini_hedef,
beceri, beceri_kaynak, kok_hedef_kr, sik_medyan_kr, sik_turu, olumsuz_pay, oncullu_pay, hesap_pay). SEN her kart için şu 4 alanı doldurursun:

- **`ne_sorar`**: bu konuda sınavın ölçtüğü 2–5 nokta, " · " ile. Önce konunun GERÇEK çıkmış sorularını oku:
  `node "C:\TETIKTE-CALISMA\kgk-is\kart\kart-ornek.js" "<konu>"` (kök + şık + cevap + kalıp). Gerçekte sorulan noktaları yaz; kalıp
  dağılımındaki her kalıbın hangi noktayla sorulduğunu göster (ör. "U: hangi metrik sektörler arası sayılır · C: hangisi zorunlu açıklama değildir").
  Çıkmış soru METNİNİ kopyalama (A1/B29) — noktayı kendi cümlenle yaz.
- **`dayanak`**: standart/paragraf ya da kanun/madde; HER BİRİNİ AMBARDAN DOĞRULA (depo kökü `C:\TETIKTE-CALISMA\kgk-basim`):
  `node arac/bitirme-temizlik/ambar-ara.js ad "%<parça>%"` · `metin "<tam kaynak_ad>"` · `icinde "%<ad>%" "<kelime>"`
  ya da `node "C:\TETIKTE-CALISMA\kgk-is\ambar-oku.js" "<desen>" [adet]` (baştan eşleşir). Kaynak adını ambardaki gibi yaz
  ("TSRS 2 p.36", "Sigortacılık K. (5684 s.K.) m.30"…). Ambarda yoksa: **"AMBARDA YOK: <ne>"** (o karta soru yazılmaz, K1b).
  Modül desenleri: `C:\TETIKTE-CALISMA\kgk-is\BRIF-T8.md` "Modül notları" + "t8 — EK ALANLAR" bölümleri.
  Bilinen kaynak boşlukları (`BRIF-BITIS.md` §3) ve bozuk paragraflar (TSRS 2 B24 değişikliği ters · Eşik Kararı "MADDE 2 – UYARI (ambar notu)" ·
  `TASLAK … SGDS 5000` · BOBİ 10.21 · TMS 32 UR8 · Kavramsal Çerçeve 4.66 · TMS 36 p.117) dayanak OLAMAZ → "AMBARDA YOK" ya da "BOZUK KAYNAK: <ne>".
- **`celdirici`**: bu konuya ÖZGÜ 3–5 gerçek öğrenci hatası, " · " ile; her biri bir yanlış şık üretir (ör. "net hedefi açıklayınca brüt
  hedefi atlamak", "komşu paragraf p.29'un metriğini sektörler arası saymak"). Gerçek soruların yanlış şıklarından esinlen.
- **`yazim_notu`**: tek satır — yazarın bu konuda düşeceği tuzak (kök şartı, yıl, makam adı, kip, mevzuat sürümü). Yıla bağlı kural varsa
  hangi Kurul kararından/yürürlükten okunacağını yaz. Makam: sigortada bugün SEDDK (Kurum/Kurul).

## KESİN
- ÖLÇÜLMÜŞ alanları değiştirme; JSON yapısını ve sırasını bozma. Hafızadan oran/tutar/paragraf yazma — dayanaktaki her ad ambarda bulunmuş olmalı.
- Gerçek sınav sorusunu kopyalama. Depo/commit/para harcayan iş yok. Yalnız kendi parça dosyana yaz; yardımcı dosyalar `C:\TETIKTE-CALISMA\kgk-is\kart\tmp-<PARÇA>\`.
- Ambar çağrılarını sırayla yap (eş zamanlı değil). BAĞLANTI HATASI alırsan "AMBARDA YOK" deme; tekrar dene, olmuyorsa `dayanak`'a "OKUNAMADI" yaz.
- Bitince: `node -e "require('C:/TETIKTE-CALISMA/kgk-is/kart/parca/<PARÇA>.json')"` ile geçerli JSON mu kontrol et.

## Son mesajın (en çok 6 satır)
parça · doldurulan kart sayısı · "AMBARDA YOK"/"BOZUK KAYNAK" kartlar (konu adıyla) · okunamayan · emin olmadığın dayanak.
