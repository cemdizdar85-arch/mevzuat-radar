# VERİ HARİTASI — her verinin TEK evi

> **20.08.2026, geçmiş temizliği sonrası kuruldu (Cem onayı, Faz 2).**
> KURAL: Her verinin **tek otoriter evi** vardır. İkinci kopya ancak "ara ürün" veya
> "önbellek" olarak, burada kayıtlıysa yaşayabilir. Bu haritada evi olmayan yeni bir
> veri üretmeden önce buraya satır eklenir. "Hangi kopya doğru?" sorusunun cevabı
> her zaman bu dosyadır.

## Karar ağacı (yeni veri nereye konur?)

1. **Kişisel/ticari sır taşıyor mu** (VKN, TCKN, borçlu adı, üye verisi, paralı içerik,
   cevap anahtarı)? → **Supabase** (RLS/policy YOK + dışarı yalnız tavanlı RPC) veya
   **private bucket**. Depoya ASLA — depo herkese açıktır.
2. **Site bunu tarayıcıda mı okuyor?** → depoda yaşar (Pages'ten servis edilir),
   ama 1 MB'ı aşıyorsa önce "bunu RPC'ye taşısak?" diye sorulur.
3. **Robot ara-belleği / durum dosyası mı?** → `motor/hafiza/` veya `veri/` altında,
   bot yazar. **Uzak (origin) otoriterdir; bayt değil KAYIT SAYılır.**
4. **Büyük ham kaynak mı** (PDF, kitapçık, indirilen arşiv)? → yalnız disk,
   `.gitignore`'a kural + bu haritaya satır.

## 1. Supabase (otoriter — gizli ve canlı veriler)

| Veri | Ev | Dışa açılan yüz | Not |
|---|---|---|---|
| Mevzuat ambarı (60 kaynak, madde-belge) | `mevzuat`/madde-ara tabloları | `madde-ara` RPC (v6) | repo `veri/mevzuat/*.json` yalnız YÜKLEME ara ürünü |
| Soru kasası (31 bin+ soru, cevap+açıklama) | soru havuzu tabloları | sayfalara kimlikli servis | soru METNİ depoya ASLA (gitignore korumalı) |
| Alacak arşivi (5.728 ilan, VKN/TCKN) | `alacak_ilan` (RLS açık, policy YOK) | tavanlı RPC: vitrin/ara/toplu | fiyat kapısı SUNUCUDA; 19.08 kasaya alındı |
| İhale arşivi (2.410 ihale) | ihale tabloları (service_role) | RPC'ler | 20.08 kasaya alındı (c408c23f) |
| Üye/kimlik | Supabase Auth | giriş/üyelik akışı | başkasının verisini görmek RLS ile kapalı |
| Evrak Radarı fişleri | `fisler` bucket (**private**, KVKK) | imzalı URL | 17.07 kararı |
| Soru bildirimleri | `soru_bildirim` | anon INSERT (bilinçli açık) | okuma kapalı |
| Onarım taslakları | `onarim-taslak` bucket (ÖZEL) | — | kasa-örnek raporları vb. |

Şemalar: `radar-app/sql/*.sql` (tarih damgalı; en yenisi geçerli).

## 2. Depo — site içeriği (herkese açık, Pages servis eder)

| Veri | Yol | Yazan |
|---|---|---|
| Sayfalar + araçlar | kök `*.html`, `gtip-ara.js`, `menu.js` | GM/Claude |
| Hap kartları (yayımlanmış içerik) | `motor/kartlar/<tarih>/` + `arsiv/kartlar-*.html` | kart robotu |
| Değişim sayfaları | `arsiv/degisim/` | kart robotu |
| GTİP/gözetim/oran katmanları | `veri/gtip-*.json`, `veri/gozetim-*.json` | gözetim robotu + nöbetçi |
| Yerel kütüphane | `kutuphane/supabase-2.112.3.js` | elle, sürüm sabit |

## 3. Depo — robot ara-belleği ve üretim ara ürünleri

| Veri | Yol | Not |
|---|---|---|
| Mevzuat JSON'ları (yükleme kaynağı) | `veri/mevzuat/*.json` | otoriter DEĞİL — ambar Supabase'de; yeniden üretilebilir |
| Ham metinler | `veri/mevzuat-hazir/*.txt` | ara ürün |
| Damga diff tabanı | `veri/mevzuat/_madde-damga.json` + `_madde-damga-onceki.json` | `-onceki` SİLİNMEZ: soru-dayanak-nöbetçisinin karşılaştırma tabanı |
| Robot durum/nabız | `motor/hafiza/*` (50 dosya), `veri/*-log.txt`, karne/rapor JSON'ları | bot yazar → **uzak otoriter, kayıt say** |
| Eski tebliğ önbelleği | `motor/arsiv-eski/` | kart-toplu.ps1 bir kez indirir, CI commit'ler — SİLİNMEZ |
| İhale özetleri (kişisel veri YOK) | `veri/ihale-*-ozet.json`, `ihale-bulten-ilan.json` | ham `ihale-sonuc.json` artık YALNIZ Supabase |

## 4. Yalnız disk (depoya girmez — .gitignore'da)

| Veri | Yol | Neden |
|---|---|---|
| RG PDF arşivi | `motor/arsiv/` | 130 MB; geçmişi şişirdi, 20.08 geçmişten silindi |
| Sınav kitapçık arşivleri | `veri/kgk-arsiv/`, `veri/smmm-arsiv/`, `_txt/` | telif + boyut |
| Paralı soru içeriği | `veri/fabrika/`, `veri/fabrika-yedek-denetim-oncesi/`, `sql-yerel/` | ticari sır |
| Cevap anahtarları | `veri/profesor-rapor*.json` | 20.08 geçmişten de silindi |
| Alacak ham dosyaları | `veri/alacak-arsiv.json`, `alacak-ilan-canli.json` | kasa Supabase'de |
| İç pazarlama | `video/` | public depoda işi yok (20.08 kalıcı kural) |
| Acil yedek kasası | `../_yerel-veri-kasasi/` | geçmiş temizliği öncesi kopyalar (PDF arşivi) |

## 5. Yasaklar (tekrar yaşanmasın diye)

- 🔴 Depo herkese açıktır: **gizli veri depoya girmez, geçmişe de girmez** — bir kez
  girdi mi silmek 2 saatlik geçmiş ameliyatı demek (20.08'de yaşandı: 1 GB → 80 MB).
- 🔴 `*.yedek-*` dosyası depoya commit'lenmez (gitignore'da); onarım yedeği yerelde kalır.
- 🔴 Aynı verinin iki "otoriter" kopyası olamaz. Kopya gerekiyorsa bu haritada
  "ara ürün/önbellek" olarak kaydı ve tek yönü (kim → kime) yazılır.
- 🔴 Bot'un yazdığı dosyada yerel ile uzak çatışırsa **uzak kazanır** (kayıt sayarak teyit).
