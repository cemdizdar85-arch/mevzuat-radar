# AMBAR YUTMA İŞ EMRİ — 30.09.2026 (SGS soru onarımında ölçüldü)

> Elle yazılmış iş emridir (robot çıktısı değil). Yazan: SGS oturumu (`sgs` kolu), Cem 30.09 "1.2.3 üçünü de yap".
> Kapanınca her satıra `KAPANDI <tarih> <commit>` yazılır; hepsi kapanınca dosya silinir.
> Bu eksikler `veri/kesik-metin-adaylari.json` ve `veri/kesik-madde-onarim-onerisi.json`'da **yok** (30.09 grep ile ölçüldü) — mevcut
> kesik metin taraması bunları görmüyor.

## Neden önemli

Kapılar (KAPI-HK `arac/hesap-kodu-kapisi.js`, KAPI-BP `arac/bds-atif-kapisi.js`) ve onarım ajanları doğruluğu **ambardan** okuyor.
Aşağıdaki eksikler iki yoldan zarar veriyor:
1. **Yanlış alarm:** doğru atıf "yok"/"konu uyuşmuyor" sayılıyor (kapılar şimdilik bu vakaları bilerek atlıyor — atlama geçici yamadır).
2. **Kaynaksız onarım:** THP 17 grubu ambarda olmadığı için yıllara yaygın inşaat sorularında hesap kodu resmî kaynaktan doğrulanamıyor.

## Eksikler

| # | Kaynak | Eksik | Nasıl bulundu (30.09) | Geçici yama |
|---|---|---|---|---|
| 1 | **THP 170–179** (Yıllara Yaygın İnşaat ve Onarım Maliyetleri grubu) | Ambarda `THP 17%` sorgusu **0 kayıt**. 350/358 var, 170/178/179 yok. | SMMM oturumu: `smmm-w3-maliyet-zor/kp-22` HK-YOK 170/178/179 verdi; soru MSUGT'ye atıf yapıyor | KAPI-HK: listede grubu olmayan koda hüküm verilmez (3f1ad304) |
| 2 | **BDS 500 p.11** | Ayrı kayıt değil; `BDS 500 p.10` kaydının gövdesinin içinde ("…Güvenilirliğine İlişkin 11. Bir kaynaktan…") | KAPI-BP isabet yargısı (60 bulgu) | KAPI-BP: gövdeye gömülü paragraf var sayılır (`gomulu`) |
| 3 | **BDS 250 p.5** | İlk cümlede kesiliyor; devamı "BDS 250 p.1 - Denetçinin Sorumluluğu" etiketli ayrı bir kayıtta | KAPI-BP yargısı + bp-1 onarımı (2 soru) | yok — yanlış alarm veriyor |
| 4 | **BDS 330 p.17** | (b) bendi eksik | KAPI-BP yargısı | yok |
| 5 | **BDS 580 p.11** ("İşlemlerin Tamlığı") | (b) bendi ("tüm işlemlerin kaydedildiği" beyanı) düşmüş | bp-2 onarımı (`sgs-t1-denetim-zor/kp-23`) | yok |

Ek not (ölçülmedi, doğrulanmalı): onarım ajanları TTK m.189 ve m.473'ü ambarda bu adla bulamadı; TTK m.189 metni kesik geldi.

## Yapılacak

1. Resmî kaynaktan (KGK BDS metinleri; MSUGT / THP hesap açıklamaları) ilgili parçaları **yeniden yut**; paragraf başına ayrı kayıt, etiket = gerçek paragraf numarası.
2. Yutma sonrası: `node arac/bds-atif-kapisi.js --tazele` ve `node arac/hesap-kodu-kapisi.js --tazele` (listeler tazelenir), ardından iki kapının
   `--banka sgs` ölçümü — yanlış alarm sayısı düşmeli. Düşmüyorsa yutma eksik.
3. KAPI-HK "grubu olmayan kod" ve KAPI-BP "gömülü paragraf" atlamaları ambar düzelince gözden geçirilir (gerekirse kaldırılır, öz-sınav vakasıyla).
4. **Kesik metin taraması kör:** bu beşini görmeyen `kesik-metin-adaylari` üreticisine "paragraf ilk cümlede bitiyor / numaralı bent eksik /
   sonraki paragraf numarası gövdede" desenleri eklenmeli (kapı kuralı: öz-sınav + mutasyon).

Kol: kaynak yutma KGK/altyapı işidir; SGS oturumu yutma yapmaz.
