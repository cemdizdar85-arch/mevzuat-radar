# TETİKTE — RAG + Soru Üretme Motoru

C# .NET 10 · PostgreSQL 16+ · pgvector · Anthropic Claude · Gemini embedding

Bu klasör **kendi başına çalışan** bir alt sistemdir. Deponun PowerShell hattına
dokunmaz; kendi şeması (`rag`), kendi iş kuyruğu ve kendi göç kütüğü vardır.

---

## Çalıştırma — üç adım

### 1) Şemayı bas (bir kez)

```bash
psql "$PGURL" -f rag-motor/sql/001_init.sql
```

Basıldığını doğrula:

```sql
select * from rag.schema_migrations;
select rag.surum();
```

> Motor açılışta bu kaydı **kontrol eder**. `001_init` basılı değilse hiç
> başlamaz ve sebebini söyler. "Canlıda hangi sürüm koşuyor?" sorusu bu
> sistemde bir daha tahminle cevaplanmayacak.

### 2) Anahtarları ortam değişkeni olarak ver

```powershell
$env:ANTHROPIC_API_KEY = "sk-ant-..."
$env:GEMINI_API_KEY    = "AIza..."
$env:RAG__CONNECTIONSTRING = "Host=...;Database=tetikte;Username=...;Password=...;SSL Mode=Require"
```

Anahtarlar **koda ve appsettings.json'a yazılmaz**. `RAG__CONNECTIONSTRING`
(çift alt çizgi) `appsettings.json`'daki değeri ezer.

### 3) Motoru çalıştır

```bash
dotnet run --project rag-motor/src/Tetikte.Rag.Worker
```

İki işçi birden ayağa kalkar: **GommeIscisi** (yutma + vektör) ve
**SoruIscisi** (soru üretimi). İkisi de `rag.is_kuyrugu`'ndan beslenir.

---

## İş verme

Motor kuyruktan beslenir; iş vermek tek `insert`.

**Bir kanunu yut:**

```sql
insert into rag.is_kuyrugu (tur, yuk) values (
  'gomme',
  jsonb_build_object(
    'kod',   'VUK-213',
    'ad',    'Vergi Usul Kanunu (213 s.K.)',
    'tur',   'kanun',
    'url',   'https://www.mevzuat.gov.tr/...',
    'metin', $$ MADDE 1 — Bu Kanun hükümleri... $$
  )
);
```

**Soru ürettir:**

```sql
insert into rag.is_kuyrugu (tur, yuk) values (
  'soru',
  jsonb_build_object(
    'ders', 'Vergi Mevzuatı ve Uygulaması',
    'istekler', jsonb_build_array(
      jsonb_build_object('konu','amortisman ayırma şartları','zorluk','zor','adet',3),
      jsonb_build_object('konu','şüpheli alacak karşılığı','zorluk','kolay','adet',2)
    )
  )
);
```

**Bakım koşusu** (metinsiz `gomme` işi) — vektörü eksik kalan parçaları tamamlar:

```sql
insert into rag.is_kuyrugu (tur, yuk)
values ('gomme', '{"kod":"-","ad":"-","tur":"bakim"}'::jsonb);
```

**Sonuçlar:**

```sql
select ders, konu, zorluk, govde->>'soru' as soru, govde->>'dogru' as dogru
from rag.soru order by id desc limit 20;
```

---

## Mimari kararlar — ve neden

| Karar | Gerekçe |
|---|---|
| **Hibrit arama (vektör + FTS), RRF ile** | Saf vektör "VUK m.359" gibi tam eşleşmeleri kaçırır; saf metin eş anlamlıyı kaçırır. RRF puanları **toplamaz**, yalnız sıraya bakar — ölçek farkından doğan "mıknatıs belge" sorunu böylece imkânsızlaşır. |
| **Parça boyu 8.000 karakterle SQL'de sınırlı** | Bölünmemiş dev satır her yaygın kelimeyi içerir ve alakasız sorgularda öne çıkar. Veritabanı artık böyle bir satırı **kabul etmiyor**. |
| **Türkçe katlama tek fonksiyonda (`rag.katla`)** | Eski hatta sorgu tarafı Türkçe harfi *siliyor*, ambar tarafı *katlıyordu*; "tüfe" → "tfe" olup hiçbir şeye eşleşmiyordu. Artık iki taraf da aynı fonksiyondan geçiyor. |
| **Embedding ayrı tabloda (`parca_vektor`)** | Model değişince parçalar yeniden yutulmaz, yalnız vektörler yeniden üretilir. `model` sütunu iki modelin vektörünün karışmasını engeller. |
| **Asimetrik gömme** | Belge `RETRIEVAL_DOCUMENT`, sorgu `RETRIEVAL_QUERY` görev tipiyle gömülür. Karıştırmak aramayı sessizce bozar. |
| **Structured output (şema zorlanır)** | Serbest metinden JSON ayıklamak kırılgan bir onarım katmanı doğurur. Şema ile o katman hiç gerekmez. |
| **Prompt caching** | Kural bloğu her istekte aynen gidiyor. `System` + `CacheControl` ile bir kez ödenir, sonrasında onda bir fiyata okunur. Sıra kritik: sabit blok sınırdan **önce**, dayanak metin **sonra**. |
| **`SemaphoreSlim` boğazlı `Task.WhenAll`** | Sınırsız `WhenAll` 429'u önlemez, **üretir**. Eş zamanlılık tavanı tek yerden yönetilir (`EsZamanliIstek`). |
| **Bakiye hatası tekrarlanmaz** | Bakiye bitince her deneme aynı duvara çarpar; parti yarım kalır ve yeniden koşulduğunda aynı iş ikinci kez ödenir. Bakiye/kimlik hataları **kalıcı** sayılır, hemen yukarı fırlar. |
| **`for update skip locked`** | İki işçi aynı işi asla almaz; kilitli satır kimseyi bekletmez. |
| **EF Core yok** | Vektör arama, RRF ve `skip locked` ham SQL ister. ORM araya girince sorgu görünmez olur. |

---

## Ayarlar (`appsettings.json` → `Rag` bölümü)

| Anahtar | Varsayılan | Not |
|---|---|---|
| `EsZamanliIstek` | 4 | Aynı anda uçacak model isteği tavanı. 429 alıyorsan **bunu düşür**. |
| `GommeYiginBoyu` | 32 | Tek gömme çağrısındaki parça sayısı. |
| `AramaAdet` | 6 | Modele gidecek aday sayısı (şu an ilki kullanılıyor). |
| `AramaAdayHavuzu` | 60 | Her kanalın RRF öncesi aday sayısı. |
| `ParcaHedefBoy` | 2200 | Hedef parça boyu (karakter). |
| `ParcaBindirme` | 200 | Ardışık parçaların ortak kısmı. |
| `UretimModel` | `claude-sonnet-5` | Opus 5'e geçmek tek satır. |
| `EmbeddingBoyut` | 768 | Değiştirmek **SQL göçü ister** (`vector(768)`). |

---

## Dosya haritası

```
rag-motor/
├── sql/001_init.sql                      şema + hibrit arama (rag.ara) + göç kütüğü
└── src/
    ├── Tetikte.Rag.Core/
    │   ├── RagOptions.cs                 tüm ayarlar + sır okuma
    │   ├── Modeller.cs                   kayıt tipleri, üretilen soru şeması
    │   ├── Ambar.cs                      Npgsql erişimi, kuyruk, arama çağrısı
    │   ├── MevzuatParcalayici.cs         madde → fıkra → cümle, bindirmeli
    │   ├── GommeIstemcisi.cs             Gemini, asimetrik + L2 normalize
    │   ├── YutmaServisi.cs               uçtan uca yutma (idempotent)
    │   ├── SoruUretici.cs                arama + üretim + kapı + fatura
    │   └── Dayaniklilik.cs               Polly: 429/5xx, retry-after, jitter
    └── Tetikte.Rag.Worker/
        ├── Program.cs                    DI, göç kapısı, açılış
        ├── Isciler.cs                    GommeIscisi + SoruIscisi
        └── appsettings.json
```

---

## Bilinen sınır

Bu motor **ayrı bir sistemdir**. Deponun 44.731 satırlık mevcut ambarını,
12 kalite kapısını ve Kaydır-Çöz cevap kalıbını **devralmaz**. İkisini
birleştirmek ayrı bir iştir; bu klasör o birleşmenin sağlam tarafıdır.
