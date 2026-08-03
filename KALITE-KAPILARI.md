# KALİTE KAPILARI — hangi kural ölçülüyor, hangisi hâlâ dilek

**03.08.2026 · Cem'in sorusu:** *"Birincil kaynaktan çalışıyoruz diyoruz, bu hatayı
yapmamız normal değil. Görmediğim başka bir hata varsa onu nasıl engelleyeceğim?"*

---

## 1. Açığın kök sebebi: kural girdiye uygulandı, çıktıya uygulanmadı

"Birincil kaynak" kuralını **yutmaya** uyguladık, **yazmaya** uygulamadık:

| Adım | Durum |
|---|---|
| Resmî metni ambara yut | ✅ yapılıyor, ölçülüyor (yutma kapsama kapısı) |
| Yazarken kaynağı isteme ekle | ✅ yapılıyor |
| **Yazılan cümle gerçekten o metinde var mı** | ❌ **kimse bakmıyordu** |

Yani *"birincil kaynaktan çalışıyoruz"* **girdi için doğru, çıktı için yalandı.**
İddia hiç doğrulanmadı. Hesap kodu vakası (253/122/127) bunun ilk görünür örneği;
ama açık hesap koduna özel değil, **üretilen her alan için** geçerliydi.

## 2. İkinci kök sebep: kuralların çoğu İSTEMDE dilek olarak duruyordu

İsteme "uydurma" yazmak model için bir **temenni**dir, kod için bir **şart** değil.
Bir kural ancak **çıktıyı ölçen bir sayaç** varsa kuraldır.

**Kanıt:** D1–D9 kuralları haftalardır yazılıydı. Modelin dört yanlış şıkka aynı
cümleyi yazmasını, kanun dilini kopyalamasını, istenmemiş alanı üretmesini,
hesap kodu uydurmasını **hiçbiri engellemedi** — çünkü hiçbirinin sayacı yoktu.
Dördünü de Cem gözüyle buldu.

## 3. Üçüncü kök sebep: sessiz başarısızlık

Bu belge yazılırken bile yaşandı: hesap kodu denetimi koştu, GitHub **yeşil** dedi,
rapor hiç gelmedi. Commit adımı her hatayı `|| true` ile yutuyordu. Düzeltildi —
rapor yoksa veya push tutmazsa adım artık **kırmızı** biter.

> **Kural:** Yeşil koşu iş bitti demek değildir. Bir iş ancak şu cümle
> kurulabiliyorsa yapılmıştır: *"X yapıldı, geri okumayla Y'si doğrulandı,
> atlanan Z (sebep: …)"*.

---

## 4. KAPI ENVANTERİ — dürüst tablo

| Kural | Ne diyor | Ölçen kapı | Durum |
|---|---|---|---|
| D1 dört parça | 4 başlık zorunlu | `dort_parca_eksik` | ✅ 03.08 |
| D2 tuzak + Doğrusu | her yanlış şıkta | sözleşme ölçümü + `tekrar_kusurlu` | ✅ |
| D3 "çünkü doğru cevap X" yasak | — | ❌ **yok** | ⚠️ dilek |
| D4 dayanakta olmayan yazılamaz | uydurma yasak | `dayanak_disi_iddia` | ✅ 03.08 |
| D7 tablo / yevmiye | hesaplı soruda | sözleşme ölçümü | ✅ |
| D8 kavram tablosu | karşılaştırma | sözleşme ölçümü | ✅ |
| D9 sıklık künyesi | sayım yoksa yazma | JS'te `if(!k.d) return ''` | ✅ |
| D10 her şıkka ayrı | kopya cümle yasak | `tekrar_kusurlu` | ✅ 03.08 |
| D11 iyi olanı bozma | istenmeyeni at | `istenmeyen_alan` | ✅ 03.08 |
| D12 anne testi | sade dil | `kanun_kopyasi` + `yapayzeka_kokusu` | 🟡 kelime listesi kadar |
| D13 rakamı tersine çöz | işlem tutmalı | ❌ **yok** | ⚠️ dilek |
| D14 hesap kodu | dayanakta yoksa yazma | hesap kodu deseni + THP denetimi | ✅ 03.08 |

**Dürüst özet:** 14 kuralın **2'si hâlâ ölçülmüyor** (D3, D13), 1'i kısmen (D12).
Bunlar bilinen açıklar — bilinmeyen değil. Kapatılacaklar.

---

## 5. YAYIN KAPISI — Cem'in sorusunun asıl cevabı

Görmediğin hatayı **bana güvenerek** değil, **sayıya bakarak** engellersin.

**Kural:** *Bir soru, üstündeki bütün sayaçlar sıfır olmadan yayına çıkmaz.*

Yayından önce koşacak denetimler:

1. **Hesap kodu denetimi** — her kod THP'nin resmî adıyla uyuyor mu *(kuruldu, haftalık nöbet)*
2. **Oran/tutar denetimi** — her yüzde ve TL tutarı dayanak metninde geçiyor mu *(sırada)*
3. **Madde atfı denetimi** — "VUK m.275" denmiş, o maddede o hüküm var mı *(sırada)*
4. **Kaynak eşleşme denetimi** — kaç sorunun etiketi **yanlış** belgeye düşüyor *(sırada — hesap planı vakasının kök sebebi buydu)*
5. **Sözleşme ölçümü** — D1/D2/D7/D8 tamam mı *(var)*
6. **Örneklem okuması** — Cem rastgele N soru okur. Makine yalnız **öğretildiği**
   hata sınıfını görür; yeni sınıfı insan bulur. Bu adım kaldırılamaz.

## 6. Bu belgenin varlık sebebi

Cem: *"sana çok güvenmiştim, az kontrol ediyordum yaptıklarını, öyle değilmiş."*

Doğru tepki bana daha az güvenmek değil, **iddiayı sayısız kabul etmemek.**
Bundan sonra "yapıldı" cümlesinin yanında bir rakam yoksa o iş yapılmamıştır —
bunu senin hatırlatman değil, kapının kendisi söyleyecek.
