# KGK KALIP ELLE ETİKETİ — okuyucu brifi (03.11.2026, Cem "Evet, kur"; sözleşme B30/B31)

Görev: sana verilen girdi dosyasındaki HER çıkmış KGK sorusunun **soru cümlesi kalıbını** 17 harften biriyle etiketle.
Konuyu, doğru cevabı, zorluğu DEĞİL; sorunun **nasıl sorulduğunu** etiketliyorsun. Kendi yargınla oku; hiçbir betiğe/ayırıcıya bakma.

## 17 KALIP (bitirme sözlüğüyle AYNI harfler — veri/sinav/bitirme-kalip-elle-320.json)
| Harf | Kalıp | Ayırt edici |
|---|---|---|
| A | doğrudur | "…hangisi doğrudur / doğru olarak verilmiştir / doğru bir ifadedir" |
| B | yanlıştır | "…hangisi yanlıştır / yanlış olarak verilmiştir" |
| C | değildir / sayılmaz | "…değildir / sayılmaz / yer almaz / girmez / kullanılmaz / olamaz / gerekmez" (olumsuz ama "yanlış" kelimesi yok) |
| U | sayılır / görevidir | "…hangisi … sayılır / girer / kapsamındadır / biridir / görevidir / tabidir" (olumlu üyelik/kapsam: listeden doğru OLANI seç) |
| D | öncüllü | kökte I., II., III. … öncüller ve "hangileri / hangisi veya hangileri"; şıklar "Yalnız I", "I ve III"… — başka kalıp kelimesi olsa da D ÖNCE gelir |
| E | boşluk | "…boş bırakılan yere / (I) …" doldurma |
| G | hüküm sayısı / zamanı | cevap bir SÜRE, ORAN, EŞİK, ADET ya da TARİH ama hesap yok, kuralın kendisi ezberden ("kaç gün içinde", "en az yüzde kaçı", "ne zaman") |
| F | hesap | kökteki verilerle hesap yapılıp sayı/tutar bulunur (faiz, NBD, değer düşüklüğü, ertelenmiş vergi tutarı, oran hesabı…) |
| L | sırasıyla | "…sırasıyla aşağıdakilerin hangisinde doğru verilmiştir" (iki/üç boşluk ya da iki/üç kavram eşleşmesi tek şıkta) |
| I | defter kaydı | yevmiye kaydı / muhasebe kaydı şıklarda |
| J | hangi hesap | "…hangi hesapta izlenir / hangi hesaba kaydedilir" |
| K | kayıt → işlem | verilen kaydın hangi işlemin karşılığı olduğu |
| M | tanım ↔ terim | tanım verilip kavram sorulur ya da kavram verilip tanımı/niteliği sorulur ("…aşağıdakilerden hangisidir" ama içerik tanım/nitelik; olumlu-olumsuz karar yok) |
| N | yetkili merci | "…hangi kurum/merci/organ tarafından / kime bildirilir / kim yetkilidir" |
| O | eylem → ceza / suç | "…hangi ceza / hangi suç / hangi yaptırım uygulanır" |
| P | durum → davranış | vaka verilip "denetçi ne yapmalıdır / hangi görüşü vermelidir / hangi karar alınır" |
| S | grafik / tablo yorumu | verilen grafik/tablonun yorumu (hesap yoksa) |

Öncelik (iki kalıp birden görünüyorsa): D > E > K > S > L > I > J > B > C > P > O > N > A > G > F > U > M.
"hangisi yanlıştır" içeren öncüllü soru = D. Kökte veri olsa da cevap sayı değilse F değildir. Tablo verip hesap isteyen = F.

## Girdi / çıktı
- Girdi: `C:\TETIKTE-CALISMA\kgk-is\kalip\girdi-<N>.json` — dizi: {kimlik, modul, kok, siklar[5]}. Metin iki sütunlu PDF'ten çıktı; kök
  bazen yan sütunla karışık olabilir — soru cümlesini (genelde kökün SON cümlesi) bul. Okunamayacak kadar bozuksa harf `?`.
- Çıktı: `C:\TETIKTE-CALISMA\kgk-is\kalip\etiket-<N>.json` — nesne {"<kimlik>": "<harf>"} — girdideki HER kimlik için tek harf.
  UTF-8 BOM'suz; yazdıktan sonra `node -e` ile parse et ve kimlik sayısının girdiyle eşit olduğunu doğrula.
- Başka HİÇBİR yere yazma (depo, ambar, git yok). Soru metnini çıktıya koyma.
- Kararsız kaldığın soruları son mesajda kimlikle say (en çok 10), hangi iki harf arasında kaldığını yaz.

Son mesaj (en çok 5 satır): parça no · soru sayısı · harf dağılımı (harf:adet) · `?` sayısı · kararsızlar.
