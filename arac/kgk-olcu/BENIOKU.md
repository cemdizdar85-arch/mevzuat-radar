# arac/kgk-olcu — KGK ölçü araçları (ANLIK KOPYA, 03.11.2026)

Çalışan kopya `C:\TETIKTE-CALISMA\kgk-is` (yollar `__dirname`'e göre: `konu-profil.js`, `olcu-satiri.js`, `plan-kur.js` kökte; kalıp araçları `kalip\`).
Bu klasör o araçların depodaki yedeğidir — **buradan doğrudan koşmaz** (girdi dosyaları — çıkmış metin önbelleği, okuma çıktıları —
depoya bilerek girmez: soru metni depoya girmez). Ne ölçtükleri ve geçme şartları: kökteki `KGK-OLCU-TABLOSU.md`.

| Dosya | İş |
|---|---|
| bagla.js · yeniden-bagla.js | kitapçık metni ↔ etiket (modül+no+konu) içerikle bağlama (eski sıra kuralı %18–35 kayıyordu) |
| konu-profil.js | gerçek konu profili kur · hedef tablosu · `denetle` = plan kapı 3 (karışım + gizli iz + B30 kalıp) · `--sinav` öz-sınav |
| olcu-satiri.js | soru başı ölçü satırı (B31) = plan kapı 4 |
| plan-kur.js | KGK plan kurucu (kapı 1–4) + modül tavanları |
| kgk-kalip-ayirici.js | KGK soru cümlesi kalıbı ayırıcısı (`--sinav`: elle etikete uyum, 03.11 %87,6) |
| konu-kalip-tablo.js | `veri/sinav/kgk-duzeltme/konu-konu-kalip.md` |
| girdi-kur*.js · eksik-girdi.js · elle-oku.js · elle-birlestir.js · BRIF-KALIP.md | elle kalıp etiketi düzeni → `veri/sinav/kgk-kalip-elle-3905.json` |
| tavan-olc.js · iz-kalibre.js · bag-denetim.js | tavan / gizli iz eşik kalibrasyonu / bağ denetimi |
| BRIF-BITIS.md | KGK yazar brifi (§1b konu profil, §1c gizli izler, §1d kalıp) |
