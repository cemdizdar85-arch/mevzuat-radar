# ONARIM MOTORU — ŞARTNAME (02.08.2026 gecesi)

**Neden bu belge:** Cem'in kuralı *"paralı işlemi bir kez çalıştırıp bırakalım"* ve
*"tekrar tekrar yapmayalım"*. Motor yazılırken bu gecenin kararlarından biri bile
unutulursa ikinci kez para vermek gerekir. Hepsi burada.

**Motor daha YAZILMADI. Bugüne kadar yapılan: kural + ölçüm. Soruya işlenen: SIFIR.**

---

## 1. ÖLÇÜLEN EKSİKLER (02.08 19:39, kasa 27.478, 28 sayfa)

| Kalem | Eksik soru | İlgili soru tipi toplamı |
|---|---|---|
| D2 — "Doğrusu:" cümlesi | **27.478** | tamamı |
| D7 — hesap tablosu | **8.334** | 9.765 hesaplı soru |
| D8 — karşılaştırma tablosu | **4.651** | 4.896 kavram sorusu |
| D7 — yevmiye fişi | **4.514** | 4.515 kayıt sorusu |
| D2 — tuzak adlandırma | **5.531** | tamamı |
| D1 — dört parça | **1.319** | tamamı (%95 zaten tam) |

**Kritik gözlem:** eksikler AYNI sorularda kümeleniyor (hesap sorusunun hem tablosu
hem Doğrusu'su yok). Bu yüzden **soru başına TEK çağrı** hem mümkün hem doğal.

---

## 2. MOTORUN SÖZLEŞMESİ — bir soruya bir kez dokun

Motor bir soruyu alır, **eksik olan NE varsa hepsini aynı çağrıda** üretir:

1. **D1** dört parça eksikse: *Ne soruluyor · Kural · Bu olayda · Akılda kalsın* (400-700 kr)
2. **D2** her yanlış şıkta: tuzağın adı + **"Doğrusu: <tek cümle>"** (150-320 kr, ≥3 şıkta)
3. **D7** hesaplı soruda: hesap tablosu (kalem → tutar → toplam)
4. **D7** kayıt sorusunda: yevmiye fişi (borç/alacak, hesap adı **ve kodu**)
5. **D8** kavram sorusunda: karşılaştırma tablosu, sorunun konusu olan satır işaretli
6. **D9** sıklık künyesi: **BEDAVA, ayrı iş** — `veri/sgs-analiz.json`'dan hesaplanır,
   API'ye sorulmaz. Sayım yoksa künye YAZILMAZ.

**Zaten tam olan maddeye DOKUNULMAZ** — istem "şu alanlar eksik, yalnız onları üret"
der; motor mevcut metni yeniden yazmaz (hem para hem kalite kaybı olur).

---

## 3. KIRMIZI ÇİZGİLER

- **D4:** yanlış şık açıklaması da mevzuattır — olmayan kanun/madde/oran YAZILAMAZ.
  "Doğrusu" cümlesi **yalnız sorunun dayanak metninden** türetilir; dayanak
  çözülemiyorsa (kasanın %11,5'i) o soru **atlanır**, uydurulmaz.
- **D3:** "Bu şık yanlış çünkü doğru cevap X" YASAK — öğretmez.
- **Yazma yolu PATCH** olacak (kısmi upsert NOT NULL duvarına çarpar — 27.07 dersi).
- **Geri okuma zorunlu:** yazılan her soru geri okunup alan gerçekten dolmuş mu
  doğrulanır. Doğrulanmayan "yapıldı" sayılmaz.
- **Kör kalma:** her koşu `veri/onarim-motor-raporu.json` yazar — işlenen, yazılan,
  doğrulanan, atlanan (sebebiyle), **gerçek token/fatura**.

---

## 4. SIRA — bu sıra bozulursa para boşa gider

1. **ÖNCE BEDAVA DÜZELTMELER:** etiket remap (1.414), ASCII (165), homoglif (13),
   istem artığı (2). *Aynı soru iki kez satın alınmaz: etiketi yanlış bir soruya
   paralı açıklama yazdırırsak, etiket sonradan düzelince o parayı ikinci kez öderiz.*
   > ~~mükerrer eleme (3.821)~~ **LİSTEDEN ÇIKTI.** 02.08 gece ölçüldü: gerçek birebir
   > mükerrer **0**. Tarama parmak izi soruyu değil cevabı ölçüyor ve rakamları siliyor;
   > aynı maddeye dayanan farklı senaryolar kopya sanılmış. Kanıt: `MUKERRER-BULGUSU.md`.
   > Eski gerekçe *"elenecek soruya para verilmez"* geçersiz — elenecek soru yok,
   > paralı iş küçülmedi.
2. **SONRA 10 SORULUK GÖZLE KONTROL** — çıktı Cem'e gösterilir.
3. **SONRA 200'LÜK PİLOT** — gerçek fatura ölçülür, tahmin katsayıları düzeltilir.
4. **SONRA TAM PARTİ** — Cem'in "bas"ıyla.

---

## 5. MALİYET TABANI (ölçülmüş)

- `dogrusu-ekle.ps1` ölçümü: **tüm kasaya "Doğrusu" = 22,94 USD**
  (soru başına ~3.000 giriş + ~250 çıkış token, Haiku batch)
- Tablo/yevmiye üretimi daha uzun çıktı → pilot ölçecek
- **Benim önceki 81 USD tahminim 3,5 kat yanlıştı** — katsayı uydurmuştum.
  Pilot ölçümü olmadan tam partiye rakam verilmeyecek.

---

## 6. "YAPILDI" NE DEMEK

Bir kalem ancak şu cümle kurulabildiğinde yapılmış sayılır:
**"X soruya işlendi, geri okumayla Y'si doğrulandı, atlanan Z (sebep: …)."**

Kurala yazmak, listeye eklemek, workflow kurmak — hiçbiri "yapıldı" değildir.
*(Bu gecenin dersi: manifestte var ≠ yutuldu · listede var ≠ yapıldı ·
yeşil koştu ≠ doğru veri · kurala yazdım ≠ soruya eklendi.)*
