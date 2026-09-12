# KUSUR ONARIM PROTOKOLÜ — "düzeltirken başka şeyi bozmayalım"

> Cem, 12.09.2026: *"hatalarımıza ne yapacağız düzeltirken başka şeyleri bozmayalım aman
> bu çok önemli kontrol etmeden bir şey değiştirmeyelim."*
>
> Bu dosya o talimatın mekanik karşılığıdır. Elle düzenlenir (robot çıktısı değildir).

---

## 0 · NİYE BU DOSYA VAR — bugünün kanıtı

Bugün üç kez, **düzeltmenin kendisi yeni bir kusur üretti**. Üçü de ölçümle yakalandı,
hiçbiri siteye çıkmadı:

| Düzeltme | Ne yanlıştı | Nasıl yakalandı |
|---|---|---|
| `2>&1` → `2>$null` | `2>$null` de koşuyu öldürüyordu | Klon üzerinde stderr'e yazan gerçek komutla ölçüm |
| `PaketKirp` konu süzgeci | Alakasız "Ödemeler dengesi" kaldı, doğru "THP 570" düştü | Gerçek örneklerle prova → **geri alındı, basılmadı** |
| `doldur` [int] onarımı | `TryParse` boş hücrede `0` yerine `""` veriyordu → 17.835 ögenin **7.384'ünde sapma** | Eski/yeni ifadeyi bütün ambarda karşılaştırma |

**Çıkarılan ders:** "kod mantıklı görünüyor" bir kanıt değildir. Kanıt, *eski davranış ile yeni
davranışın gerçek veri üzerinde karşılaştırılmasıdır.* Üçünde de doğru düzeltmeyi bulan şey
tartışma değil ölçüm oldu.

---

## 1 · EŞDEĞERLİK PROVASI — protokolün kalbi

Her kod onarımı, basmadan önce şu testten geçer:

> **Eski mantık ile yeni mantık, ambardaki BÜTÜN gerçek veri üzerinde çalıştırılır.
> Fark sayısı, KASITLI olarak değiştirmek istediğimiz kayıt sayısına EŞİT olmalıdır.
> Bir tane fazla fark = düzeltme yanlış.**

Bugünkü `doldur` onarımının provası tam olarak buydu:

```
ESKI ile YENI AYNI sonuc : 17.830
FARKLI sonuc             : 0        <-- hedef buydu
eskinin coktugu, kurtarilan : 5     <-- kasitli degisiklik
```

İlk denemede aynı prova `FARKLI: 7.384` dedi ve düzeltme **basılmadan** çöpe gitti.

### Prova nasıl yazılır (kalıp)

```powershell
# Her gerçek kayıt için: eski ifade try/catch, yeni ifade try/catch, sonuçları kıyasla
$ayni=0; $farkli=0; $kurtarilan=0
foreach($kayit in <BÜTÜN AMBAR>){
  $eskiOk=$true; try{ $eski = <ESKI IFADE> }catch{ $eskiOk=$false }
  $yeniOk=$true; try{ $yeni = <YENI IFADE> }catch{ $yeniOk=$false }
  if(-not $eskiOk){ if($yeniOk){ $kurtarilan++ }; continue }
  if(($eski|ConvertTo-Json -Compress) -eq ($yeni|ConvertTo-Json -Compress)){ $ayni++ } else { $farkli++ }
}
```

⛔ **Örneklemle yapılmaz.** 7.384 sapmanın hepsi boş hücrelerdeydi; 20 kayıtlık bir örneklem
onların hiçbirine denk gelmeyebilirdi. Ambarın tamamı taranır — bedeli 0, süresi dakikalar.

---

## 2 · ONARIM SIRASI — beş adım, atlanmaz

1. **ÖLÇ — kusuru yerelde tekrar et.** Hata mesajını birebir üretemiyorsan kök nedeni
   bulmamışsındır. (Bugün: `Cannot convert value "Verilen"` yerelde birebir üretildi,
   sonra tek soruya — `kp-19` — indirildi.)
2. **YARIÇAPI ÖLÇ — kaç kaydı etkiliyor.** "8 / 17.835" cümlesini kuramıyorsan dokunma.
3. **EŞDEĞERLİK PROVASI** (bölüm 1). Fark ≠ hedef ise düzeltme yanlıştır, tartışılmaz.
4. **MEKANİK KAPI + KÖR KALMAMA.** Onarım, aynı kusurun sessizce dönmesini engelleyen bir
   kapı ya da en azından bir SAYAÇ bırakır. Bugün bırakılan: `DOLDUR SAYISIZ HÜCRE …`
   satırı — temizse yeşil, kirliyse soru kimliğiyle sayı basar.
5. **COMMIT = ÖLÇÜMÜN KENDİSİ.** Mesajda kök neden, yarıçap rakamı, prova sonucu ve
   kapanmayan kısım (`TAZELEME BEKLİYOR`) yazılır. Rakamsız commit kabul edilmez.

---

## 3 · KUSURU YARIÇAPINA GÖRE SINIFLA — hangisine nasıl dokunulur

| Sınıf | Örnek | Kural |
|---|---|---|
| **A · Tek kayıt bozuk** | `kp-19`'un `doldur` hücresi | Veriye dokunma; **KODU dayanıklı yap**. Tek kayıt yüzünden 5.600 soru yayınsız kalmaz. |
| **B · Kod mantığı yanlış** | `PaketKirp` konu süzgeci | Eşdeğerlik provası ZORUNLU. Prova kırmızıysa geri al — bugün öyle yapıldı. |
| **C · Üretim girdisi yanlış** | ders ataması (Denetim konusu FM'e atanmış) | Girdi dosyası düzeltilir (`veri/ders-elle-atama.json`), **basılmış soru yeniden üretilmez**. |
| **D · Kapı eksik** | üreticide `doldur` koordinat kapısı yok | Ayrı iş emri. Kapı eklenince CLAUDE.md kuralı gereği **etkilenen veri aynı commit'te tazelenir**. |

### ⛔ Dokunulmayacak olan: BASILMIŞ SORULAR

Cem, 12.09: *"eski yaptığımız soruları değiştirmeyelim bundan sonrası."*
Havuzdaki sorular yeniden üretilmez, yeniden dengelenmez, toplu düzeltmeden geçirilmez.
Onarım **bundan sonra üretilecek** soruya uygulanır. İstisna yalnız şudur: soru YANLIŞ
(cevap anahtarı hatalı) ise tek tek düzeltilir — ortalama/dağılım için toplu dokunma yasak.

---

## 4 · ŞU ANKİ KUSUR DEFTERİ — ölçülmüş, sıraya konmuş

Kaynak: `veri/RET-KUTUGU.md` (12.09 23:01) · taranan 5.627 · düşen **1.852 (%32,9)**

| # | Kusur | Büyüklük | Yarıçap sınıfı | Bedel | Niye bu sırada |
|---|---|---:|---|---|---|
| 1 | **Yayın çökmesi** | 1 soru → ~500 soru bloke | A | 0 | ✅ **12.09 kapandı.** Tek kayıt bütün yayını öldürüyordu. |
| 2 | **Ders ataması yanlış** | (sınıflanmamış) 275'in içinde + KAYNAK-EKSİK'i besliyor | C | 0 | Cem kararı: *"kaynak sorununun en ucuz çaresi."* Yanlış ders → yanlış kaynak paketi → KAYNAK-EKSİK reti. Tek girdi düzeltmesi iki kusur ailesini birden küçültüyor. |
| 3 | **(sınıflanmamış) 275** | %14,8 | — | 0 | Desen çıkarılmadan büyüklüğü bilinmiyor. Örneklerin yarısı "soru bu derse ait değil" → 2 ile aynı aile olabilir. Ölçüm bedelsiz. |
| 4 | **HAKEM-KOŞMADI 112** | %6,0 | A | düşük | Bu sorular hiç denetlenmedi — yeni üretim değil, yalnız kapıdan geçirme. En ucuz kazanç. |
| 5 | **KAYNAK-EKSİK 777** | %42,0 | D | orta | En büyük aile ama tek parça değil: künye sözlüğü (158) · THP hesap bazında ambara yazma (134, FM) · teori eşleşme (91) · kalanı 2 ve 3'ten sonra yeniden ölçülür. |
| 6 | **Nöbetçi birikimi 107 bulgu** (95 zararlı: K2 54 · K4 32 · K1 14 · K3 7) | — | B | 0 | Kod sağlığı. Her biri ayrı eşdeğerlik provası ister; toplu regex ile düzeltme **YASAK** (bugün nöbetçinin kendi öz-sınav verisini yedi). |
| 7 | **Sözel hat 302 soru rafta** | 302 | C | 0 | Ödenmiş ama `DERS_ESLEME`'de karşılığı yok. Karar Cem'de: hat açılacak mı. |

**Sıra kuralı:** bedeli 0 olan ölçümler (2, 3) her zaman para harcayan onarımların (4, 5)
önünde koşar — çünkü ikisi de para harcanacak işin kapsamını küçültüyor.

---

## 5 · ÜÇ SORU — her onarımdan önce yazılı cevaplanır

1. **Kaç kaydı etkiliyor?** (rakam yoksa dokunma)
2. **Eşdeğerlik provası kaç fark verdi?** (hedeften fazlaysa düzeltme yanlış)
3. **Bu kusur bir daha sessizce dönebilir mi?** (dönebiliyorsa kapı ya da sayaç eklenir)

Üçüne de cevabı olmayan değişiklik **basılmaz**.
