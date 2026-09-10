# Vektör kanalının gerçek katkısı — kart kapalı ölçüm

*10.09.2026 · ölçen: `dotnet run -- aramakarne` · şema sürümü `005_vektorsuz_arama`*

## Neden bu ölçüm

"Hibrit arama işe yarıyor mu?" sorusu **konu kartı açıkken cevaplanamaz**: kart
zaten doğru maddeyi veriyor, arama hiç devreye girmiyor. Bu yüzden kart katmanı
devre dışı bırakıldı ve motorun **kendi arama gücü** ölçüldü. Beklenen madde
karttan okundu ama arama ona bakmadı — kart burada **cetveldir**, kılavuz değil.

Ders: VUK / Vergi Mevzuatı ve Uygulaması. 5 konu, 637 vektörlü parça.

## ⚠ İlk ölçüm HAKSIZDI — düzeltildi

İlk turda "vektör kapalı" hali **sıfır vektör göndermek** demekti (zarif düşüş).
Sıfır vektör kanalı kapatmaz: pgvector bütün satırları eşit uzaklıkta görür,
kanal **rastgele** bir sıralama döndürür, o gürültü RRF'e girip tam metin
kanalının doğru sonucunu aşağı iter.

Çıktıda görünüyordu: kapalı sanılan koşuda `v-sira 60`, `v-sira 17` yazıyordu.
Böyle bir kıyas tam metnin hakkını yer, vektörün katkısını **olduğundan büyük**
gösterir. `sql/005_vektorsuz_arama.sql` ile `rag.ara` v3'e geçildi: `p_vektor`
NULL ise vektör kanalı **hiç kurulmaz**. Dürüst rakamlar aşağıdadır.

| Kurgu | İlk (haksız) ölçüm | Dürüst ölçüm |
|---|---|---|
| Yalnız tam metin | 0/5 | **1/5** |
| Hibrit (vektör açık) | 3/5 | **3/5** |

## Dürüst sonuç: 1/5 → 3/5

### Yalnız tam metin (`v-sira -` = kanal gerçekten kapalı)

| Konu | Beklenen | Bulunan | m-sıra |
|---|---|---|---|
| değerleme ölçüleri | m.261 | mük. m.30 [1/3] | 1 |
| amortisman ayırma şartları | m.313 | m.4 | 1 |
| şüpheli alacak karşılığı | m.323 | m.4 | 1 |
| **vergi ziyaı cezası** | **m.344** | **m.344** ✅ | 1 |
| fatura düzenleme sınırları | m.231 | m.4 | 1 |

**Teşhis:** tam metin kanalı `m.4`, `mük. m.30`, `geç. m.1` gibi **jenerik
mıknatıs parçalara** düşüyor. Bunlar konuyla ilgisiz ama sorgu kelimelerini
("vergi", "kanun", "mükellef") yoğun içeriyor. Klasik FTS kusuru.

### Hibrit (vektör açık)

| Konu | Beklenen | Bulunan | v-sıra | m-sıra |
|---|---|---|---|---|
| değerleme ölçüleri | m.261 | m.32 ✗ | 15 | 5 |
| amortisman ayırma şartları | m.313 | m.318 ✗ | 4 | 8 |
| **şüpheli alacak karşılığı** | **m.323** | **m.323** ✅ | **1** | 7 |
| **vergi ziyaı cezası** | **m.344** | **m.344** ✅ | 2 | 1 |
| **fatura düzenleme sınırları** | **m.231** | **m.231** ✅ | **1** | 5 |

## Vektör kanalının kurtardığı iki konu

`v-sıra 1` ama `m-sıra 5-7` olan iki satır, katkının **kanıtıdır**:

- **şüpheli alacak karşılığı** — vektör 1., tam metin 7. sırada. Tam metin tek
  başına `m.4`'e düşmüştü.
- **fatura düzenleme sınırları** — vektör 1., tam metin 5. sırada. Tam metin tek
  başına `m.4`'e düşmüştü.

Vektör kanalı bu iki konuda doğru maddeyi **tepeye taşıdı**. `vergi ziyaı cezası`
zaten iki kanalda da tutuyordu — yani gerçek net kazanç **+2 konu**.

## Kaçan ikisi ıska değil, komşu

- `m.261` yerine `m.32`: ikisi de değerleme; m.32 "vergi matrahının re'sen
  takdiri", m.261 "değerleme ölçüleri". Konu komşuluğu var, madde yanlış.
- `m.313` yerine `m.318`: ikisi de amortisman bölümünde ardışık madde.

Anlamsal arama **doğru bölgeyi** buluyor, **doğru maddeyi** her zaman bulamıyor.

## Karar: konu kartı katmanı KALDIRILAMAZ

3/5, soru üretimi için yeterli değil. %40 oranında yanlış maddeden soru üretmek
kabul edilemez — bir yanlış soru, on doğru sorunun güvenini götürür.

Bu yüzden `SoruUretici` **önce konu kartına** bakar, kart yoksa aramaya düşer ve
hangi yoldan geldiğini kütüğe yazar (`dayanak yolu = konu karti | hibrit arama`).
Vektör kanalı kartı **değiştirmez**, kartı olmayan konular için **taban kaliteyi
1/5'ten 3/5'e çıkarır**. İkisi birlikte çalışır.

## Sıradaki iş

1. Kart kapsamını genişletmek — VUK için 6 doğrulanmış kart var, konu sayısı çok
   daha fazla. `rag.kartsiz_konular` görünümü açığı listeliyor.
2. `hnsw.ef_search` ayarını ölçmek — şu an varsayılan (40). Yükseltmek geri
   çağırmayı artırabilir, gecikmeyi de artırır. Ölçmeden değiştirilmeyecek.
3. Parça boyu ölçümü — m.261 gibi uzun maddeler tek parçaya sığmıyorsa vektörü
   sulanıyor olabilir.
