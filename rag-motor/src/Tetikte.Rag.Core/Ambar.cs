using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;
using Npgsql;
using Pgvector;
using Pgvector.Npgsql;   // UseVector() burada - ayri paket degil, Pgvector icinde

namespace Tetikte.Rag.Core;

/// <summary>
/// Veritabani erisimi. EF Core KULLANILMIYOR - bilincli karar:
/// vektor arama, RRF ve FOR UPDATE SKIP LOCKED gibi desenler ham SQL ister;
/// ORM araya girince hem sorgu gorunmez olur hem de vektor tipi icin ek
/// esleme katmani gerekir. Npgsql + hazir SQL, bu is icin daha az parca.
/// </summary>
public sealed class Ambar : IAsyncDisposable
{
    private readonly NpgsqlDataSource _kaynak;

    public Ambar(IOptions<RagOptions> ayar)
    {
        var kurucu = new NpgsqlDataSourceBuilder(ayar.Value.ConnectionString);
        kurucu.UseVector();                       // pgvector tip eslemesi
        _kaynak = kurucu.Build();
    }

    public ValueTask DisposeAsync() => _kaynak.DisposeAsync();

    // ------------------------------------------------------------------ goc
    /// <summary>
    /// Uygulama acilirken "hangi SQL basili?" sorusu TAHMINLE cevaplanmaz.
    /// Beklenen goc basili degilse motor BASLAMAZ.
    /// </summary>
    public async Task GocDogrulaAsync(string beklenen, CancellationToken ct)
    {
        await using var k = await _kaynak.OpenConnectionAsync(ct);
        await using var komut = new NpgsqlCommand(
            "select count(*) from rag.schema_migrations where surum = $1", k);
        komut.Parameters.AddWithValue(beklenen);
        var sayi = (long)(await komut.ExecuteScalarAsync(ct) ?? 0L);
        if (sayi == 0)
            throw new InvalidOperationException(
                $"GOC EKSIK: '{beklenen}' basili degil. Once sql/001_init.sql calistirilmali.");
    }

    public async Task<string> CanliSurumAsync(CancellationToken ct)
    {
        await using var k = await _kaynak.OpenConnectionAsync(ct);
        await using var komut = new NpgsqlCommand("select rag.surum()", k);
        return (string)(await komut.ExecuteScalarAsync(ct) ?? "bilinmiyor");
    }

    // --------------------------------------------------------------- kaynak
    public async Task<long> KaynakYazAsync(string kod, string ad, string tur, string? url, CancellationToken ct)
    {
        await using var k = await _kaynak.OpenConnectionAsync(ct);
        await using var komut = new NpgsqlCommand("""
            insert into rag.kaynak (kod, ad, tur, url)
            values ($1, $2, $3, $4)
            on conflict (kod) do update
              set ad = excluded.ad, tur = excluded.tur, url = excluded.url, guncellendi = now()
            returning id
            """, k);
        komut.Parameters.AddWithValue(kod);
        komut.Parameters.AddWithValue(ad);
        komut.Parameters.AddWithValue(tur);
        komut.Parameters.AddWithValue((object?)url ?? DBNull.Value);
        return (long)(await komut.ExecuteScalarAsync(ct))!;
    }

    // ---------------------------------------------------------------- parca
    /// <summary>
    /// Parcalari yazar. MUKERRER FRENI icerik ozetindedir: ayni kaynagin ayni
    /// metni ikinci kez yazilmaz. Boylece yutma isi tekrar kosulabilir
    /// (idempotent) ve robot iki kez calisirsa ambar sismez.
    /// Donen deger: YENI yazilan parcalarin kimlikleri.
    /// </summary>
    public async Task<IReadOnlyList<long>> ParcaYazAsync(
        long kaynakId, IReadOnlyList<YeniParca> parcalar, CancellationToken ct)
    {
        if (parcalar.Count == 0) return [];

        var yeni = new List<long>();
        await using var k = await _kaynak.OpenConnectionAsync(ct);
        await using var islem = await k.BeginTransactionAsync(ct);

        foreach (var p in parcalar)
        {
            await using var komut = new NpgsqlCommand("""
                insert into rag.parca (kaynak_id, madde_no, baslik, metin, sira, icerik_ozeti)
                values ($1, $2, $3, $4, $5, $6)
                on conflict (kaynak_id, icerik_ozeti) do nothing
                returning id
                """, k, islem);
            komut.Parameters.AddWithValue(kaynakId);
            komut.Parameters.AddWithValue((object?)p.MaddeNo ?? DBNull.Value);
            komut.Parameters.AddWithValue((object?)p.Baslik ?? DBNull.Value);
            komut.Parameters.AddWithValue(p.Metin);
            komut.Parameters.AddWithValue(p.Sira);
            komut.Parameters.AddWithValue(Ozet(p.Metin));

            var sonuc = await komut.ExecuteScalarAsync(ct);
            if (sonuc is long id) yeni.Add(id);
        }

        await islem.CommitAsync(ct);
        return yeni;
    }

    public static string Ozet(string metin)
        => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(metin)));

    /// <summary>Vektoru olmayan parcalar — gomme isinin girdisi.</summary>
    public async Task<IReadOnlyList<(long Id, string Metin)>> VektorsuzParcalarAsync(
        string model, int tavan, CancellationToken ct)
    {
        var liste = new List<(long, string)>();
        await using var k = await _kaynak.OpenConnectionAsync(ct);
        await using var komut = new NpgsqlCommand("""
            select p.id, p.metin
            from rag.parca p
            left join rag.parca_vektor v on v.parca_id = p.id and v.model = $1
            where v.parca_id is null
            order by p.id
            limit $2
            """, k);
        komut.Parameters.AddWithValue(model);
        komut.Parameters.AddWithValue(tavan);

        await using var oku = await komut.ExecuteReaderAsync(ct);
        while (await oku.ReadAsync(ct))
            liste.Add((oku.GetInt64(0), oku.GetString(1)));
        return liste;
    }

    public async Task VektorYazAsync(
        IReadOnlyList<(long ParcaId, float[] Vektor)> satirlar,
        string model, int boyut, CancellationToken ct)
    {
        if (satirlar.Count == 0) return;

        await using var k = await _kaynak.OpenConnectionAsync(ct);
        await using var islem = await k.BeginTransactionAsync(ct);

        foreach (var (parcaId, vektor) in satirlar)
        {
            if (vektor.Length != boyut)
                throw new InvalidOperationException(
                    $"Vektor boyu {vektor.Length}, beklenen {boyut}. Model ayari ile SQL'deki vector({boyut}) uyusmuyor.");

            await using var komut = new NpgsqlCommand("""
                insert into rag.parca_vektor (parca_id, model, boyut, vektor)
                values ($1, $2, $3, $4)
                on conflict (parca_id, model) do update set vektor = excluded.vektor
                """, k, islem);
            komut.Parameters.AddWithValue(parcaId);
            komut.Parameters.AddWithValue(model);
            komut.Parameters.AddWithValue(boyut);
            komut.Parameters.AddWithValue(new Vector(vektor));
            await komut.ExecuteNonQueryAsync(ct);
        }

        await islem.CommitAsync(ct);
    }

    // ---------------------------------------------------------------- arama
    public async Task<IReadOnlyList<AramaSonucu>> AraAsync(
        string sorgu, float[] sorguVektoru, string model,
        int adet, int adayHavuzu, string? kaynakTur, CancellationToken ct)
    {
        var liste = new List<AramaSonucu>();
        await using var k = await _kaynak.OpenConnectionAsync(ct);
        await using var komut = new NpgsqlCommand(
            "select * from rag.ara($1, $2, $3, $4, $5, $6)", k);
        komut.Parameters.AddWithValue(sorgu);
        komut.Parameters.AddWithValue(new Vector(sorguVektoru));
        komut.Parameters.AddWithValue(model);
        komut.Parameters.AddWithValue(adet);
        komut.Parameters.AddWithValue(adayHavuzu);
        komut.Parameters.AddWithValue((object?)kaynakTur ?? DBNull.Value);

        await using var oku = await komut.ExecuteReaderAsync(ct);
        while (await oku.ReadAsync(ct))
        {
            liste.Add(new AramaSonucu(
                ParcaId:   oku.GetInt64(0),
                KaynakAd:  oku.GetString(1),
                KaynakKod: oku.GetString(2),
                MaddeNo:   oku.IsDBNull(3) ? null : oku.GetString(3),
                Baslik:    oku.IsDBNull(4) ? null : oku.GetString(4),
                Metin:     oku.GetString(5),
                Rrf:       oku.GetDouble(6),
                VektorSira: oku.IsDBNull(7) ? null : oku.GetInt32(7),
                MetinSira:  oku.IsDBNull(8) ? null : oku.GetInt32(8)));
        }
        return liste;
    }

    /// <summary>
    /// KONU KARTINDAN DAYANAK (rag.konu_dayanak).
    ///
    /// Arama KARARSIZ oldugu icin (olculdu 10.09: ayni sorgu bir kosuda VUK
    /// m.261'i, sonraki kosuda m.49'u getirdi; 'vergi ziyai cezasi' israrla
    /// m.370'i getirdi oysa m.341/m.344 ambarda duruyordu) dayanak once
    /// KAYITTAN okunur. Kart yoksa bos doner ve cagiran taraf aramaya duser -
    /// aradaki fark GORULUR, sessizce kapanmaz.
    /// </summary>
    public async Task<IReadOnlyList<AramaSonucu>> KonuKartindanAsync(
        string ders, string konu, int adet, CancellationToken ct)
    {
        var liste = new List<AramaSonucu>();
        await using var k = await _kaynak.OpenConnectionAsync(ct);
        await using var komut = new NpgsqlCommand(
            "select * from rag.konu_dayanak($1, $2, $3)", k);
        komut.Parameters.AddWithValue(ders);
        komut.Parameters.AddWithValue(konu);
        komut.Parameters.AddWithValue(adet);

        await using var oku = await komut.ExecuteReaderAsync(ct);
        while (await oku.ReadAsync(ct))
        {
            liste.Add(new AramaSonucu(
                ParcaId:    oku.GetInt64(0),
                KaynakAd:   oku.GetString(1),
                KaynakKod:  "",
                MaddeNo:    oku.IsDBNull(2) ? null : oku.GetString(2),
                Baslik:     null,
                Metin:      oku.GetString(3),
                Rrf:        1.0,          // kart kesin kayittir; siralama sorusu yok
                VektorSira: null,
                MetinSira:  null));
        }
        return liste;
    }

    // ----------------------------------------------------------------- soru
    public async Task SoruYazAsync(
        long parcaId, string ders, string konu, string zorluk,
        UretilenSoru soru, string model, int girisJeton, int cikisJeton, CancellationToken ct)
    {
        await using var k = await _kaynak.OpenConnectionAsync(ct);
        await using var komut = new NpgsqlCommand("""
            insert into rag.soru (parca_id, ders, konu, zorluk, govde, model, giris_jeton, cikis_jeton)
            values ($1, $2, $3, $4, $5::jsonb, $6, $7, $8)
            """, k);
        komut.Parameters.AddWithValue(parcaId);
        komut.Parameters.AddWithValue(ders);
        komut.Parameters.AddWithValue(konu);
        komut.Parameters.AddWithValue(zorluk);
        komut.Parameters.AddWithValue(JsonSerializer.Serialize(soru));
        komut.Parameters.AddWithValue(model);
        komut.Parameters.AddWithValue(girisJeton);
        komut.Parameters.AddWithValue(cikisJeton);
        await komut.ExecuteNonQueryAsync(ct);
    }

    /// <summary>
    /// Uretilen sorulari OKUNUR metne doker. JSON denetim icin degildir;
    /// kaliteyi goz denetleyecekse bicim insan icin olmali.
    /// </summary>
    public async Task<int> SoruRaporuAsync(string yol, CancellationToken ct)
    {
        var sb = new StringBuilder();
        sb.AppendLine("================================================================");
        sb.AppendLine("  TETIKTE RAG MOTORU — URETILEN SORULAR");
        sb.AppendLine($"  {DateTime.Now:dd.MM.yyyy HH:mm}");
        sb.AppendLine("================================================================");

        await using var k = await _kaynak.OpenConnectionAsync(ct);
        await using var komut = new NpgsqlCommand("""
            select s.ders, s.konu, s.zorluk, s.govde::text, s.model,
                   k.ad, p.madde_no, length(p.metin) as dayanak_boy
            from rag.soru s
            join rag.parca  p on p.id = s.parca_id
            join rag.kaynak k on k.id = p.kaynak_id
            order by s.konu, s.id
            """, k);

        var sira = 0;
        var sonKonu = "";
        await using var oku = await komut.ExecuteReaderAsync(ct);
        while (await oku.ReadAsync(ct))
        {
            var konu = oku.GetString(1);
            if (konu != sonKonu)
            {
                sonKonu = konu;
                sb.AppendLine();
                sb.AppendLine("----------------------------------------------------------------");
                sb.AppendLine($"KONU    : {konu}   ({oku.GetString(2)})");
                sb.AppendLine($"DAYANAK : {oku.GetString(5)} {oku.GetValue(6)}  ({oku.GetInt32(7):N0} krk)");
                sb.AppendLine("----------------------------------------------------------------");
            }

            var s = JsonSerializer.Deserialize<UretilenSoru>(oku.GetString(3));
            if (s is null) continue;
            sira++;

            sb.AppendLine();
            sb.AppendLine($"SORU {sira}");
            sb.AppendLine(s.Soru);
            sb.AppendLine();
            foreach (var (h, m) in new[] { ("A", s.Siklar.A), ("B", s.Siklar.B), ("C", s.Siklar.C), ("D", s.Siklar.D), ("E", s.Siklar.E) })
                sb.AppendLine($"   {h}) {m}");
            sb.AppendLine();
            sb.AppendLine($"   DOGRU CEVAP: {s.Dogru}");
            sb.AppendLine();
            sb.AppendLine("   COZUM:");
            foreach (var (h, m) in new[] { ("A", s.Aciklama.A), ("B", s.Aciklama.B), ("C", s.Aciklama.C), ("D", s.Aciklama.D), ("E", s.Aciklama.E) })
                sb.AppendLine($"   {(h == s.Dogru ? "+" : "-")} {h}) {m}");
            sb.AppendLine($"   DAYANAK: {s.Dayanak}");
        }

        sb.AppendLine();
        sb.AppendLine("================================================================");
        sb.AppendLine($"TOPLAM SORU: {sira}");
        sb.AppendLine("================================================================");

        await File.WriteAllTextAsync(yol, sb.ToString(), new UTF8Encoding(true), ct);
        return sira;
    }

    /// <summary>Madde tavani: ayni parcadan kac soru uretilmis?</summary>
    public async Task<int> ParcaSoruSayisiAsync(long parcaId, CancellationToken ct)
    {
        await using var k = await _kaynak.OpenConnectionAsync(ct);
        await using var komut = new NpgsqlCommand("select rag.parca_soru_sayisi($1)", k);
        komut.Parameters.AddWithValue(parcaId);
        return (int)(await komut.ExecuteScalarAsync(ct) ?? 0);
    }

    // -------------------------------------------------------------- kuyruk
    public async Task IsEkleAsync(string tur, object yuk, CancellationToken ct)
    {
        await using var k = await _kaynak.OpenConnectionAsync(ct);
        await using var komut = new NpgsqlCommand(
            "insert into rag.is_kuyrugu (tur, yuk) values ($1, $2::jsonb)", k);
        komut.Parameters.AddWithValue(tur);
        komut.Parameters.AddWithValue(JsonSerializer.Serialize(yuk));
        await komut.ExecuteNonQueryAsync(ct);
    }

    /// <summary>
    /// Kuyruktan is alir. `for update skip locked`: iki worker ayni isi ASLA
    /// almaz, ve kilitli satir bekletmez. Olceklendirmenin standart deseni.
    /// </summary>
    public async Task<(long Id, string Yuk)?> IsAlAsync(string tur, CancellationToken ct)
    {
        await using var k = await _kaynak.OpenConnectionAsync(ct);
        await using var komut = new NpgsqlCommand("""
            update rag.is_kuyrugu
               set durum = 'isleniyor', alindi = now(), deneme = deneme + 1
             where id = (
                   select id from rag.is_kuyrugu
                    where tur = $1 and durum = 'bekliyor'
                    order by id
                    for update skip locked
                    limit 1)
            returning id, yuk::text
            """, k);
        komut.Parameters.AddWithValue(tur);

        await using var oku = await komut.ExecuteReaderAsync(ct);
        if (!await oku.ReadAsync(ct)) return null;
        return (oku.GetInt64(0), oku.GetString(1));
    }

    public async Task IsKapatAsync(long id, bool basarili, string? hata, CancellationToken ct)
    {
        await using var k = await _kaynak.OpenConnectionAsync(ct);
        await using var komut = new NpgsqlCommand("""
            update rag.is_kuyrugu
               set durum = case when $2 then 'bitti'
                                when deneme >= 3 then 'hata'
                                else 'bekliyor' end,
                   son_hata = $3
             where id = $1
            """, k);
        komut.Parameters.AddWithValue(id);
        komut.Parameters.AddWithValue(basarili);
        komut.Parameters.AddWithValue((object?)hata ?? DBNull.Value);
        await komut.ExecuteNonQueryAsync(ct);
    }
}
