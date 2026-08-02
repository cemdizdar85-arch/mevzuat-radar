# Mükerrer eleme: YAPILMAYACAK — çünkü mükerrer yok

**Tarih:** 02.08.2026 gece · **Maliyet:** 0 USD · **Kasaya yazılan:** hiçbir şey

## Kısa hâli

Onarım hattının 1. adımı "bedava eleme"ydi: tarama 852 grupta **3.821 mükerrer soru**
saymıştı, grup başına 1 bırakınca **2.969 soru elenecekti**. Bu yapılmadı.
Ölçüm, o 3.821 rakamının **yanlış** olduğunu gösterdi. Gerçek birebir mükerrer: **0**.

## Neden yanlıştı

`motor/onarim-tarama.ps1:148-157` mükerrer parmak izini şöyle kuruyor:

    parmak izi = kaynak adı + doğru şıkkın RAKAMSIZLAŞTIRILMIŞ ilk 80 karakteri

İki ayrı sorun var:

1. **Parmak izi soruyu değil CEVABI ölçüyor.** Aynı kaynağa dayanan ve aynı doğru
   cevabı olan iki soru, kökleri bambaşka olsa bile "mükerrer" sayılıyor.
2. **Rakamlar siliniyor.** "Amortisman tutarı 20.000 TL" ile "50.000 TL" aynı ize
   düşüyor; hesap sorularının farklı rakamlı varyantları kopya sanılıyor.

## Kanıt (en büyük grup: VUK m.275, 186 soru)

Şampiyon soru — Demirbaş Makina Ltd. Şti., 2022/2023 karşılaştırmalı gelir tablosu
(net satışlar 847.300 / 1.024.600 TL), maliyete ihtiyari dahil edilen unsur soruluyor.

"Mükerrer" sayılan iki soru:

- Demir Çelik Döküm San. Tic. Ltd. Şti., **2024** yılı, net satışlar **2.847.000 TL** —
  farklı firma, farklı yıl, farklı rakamlar.
- *"Bir mobilya imalatçısı dönem sonunda tamamlanan bir masa takımının maliyet bedelini
  hesaplarken hangi unsuru isteğe bağlı olarak maliyete ekleyebilir?"* — tamamen başka
  bir senaryo, tek satırlık kavram sorusu.

Üçü de VUK m.275'e dayanıyor ve doğru cevapları aynı. Ama bunlar kopya değil,
**aynı kuralın farklı yüzlerini soran alıştırma varyantları.** Öğrenci 186'sını
çözerse kopya görmüş olmaz, o maddeyi ezberlemiş olur.

## Sonuçlar

- **2.969 soru kasada kalıyor.** Hiçbiri yayından indirilmedi.
- **Paralı iş küçülmedi.** "Önce eleyelim, paralı işten 2.969 düşsün" beklentisi
  geçersiz — paralı parti tam boyunda kalıyor. Fiyat kartındaki bu gerekçe düzeltilmeli.
- **Gerçek sorun eleme değil DAĞILIM.** VUK m.275'te 186 soru varsa bu mükerrerlik
  değil, konu yığılmasıdır. İlacı silme değil **kota** — sınav kurucusunun ders/konu
  ağırlığına uyması. Bu ayrı bir iş.
- `motor/mukerrer-ele.ps1` çalışır durumda ve **rakam kapısı takılı**: rakamlar dahil
  birebir aynı olmayan soruyu elemez. İleride gerçek kopya çıkarsa hazır bekliyor.

## Ders

Tarayıcının verdiği sayı bir **iddia**dır, ölçüm değil. "3.821 mükerrer" cümlesi
haftalardır defterde duruyordu ve doğru sanılıyordu; uygulamadan önce üç örneği gözle
okumak yeterli oldu. **Sayıyı uygulamadan önce örneğini gör.**
