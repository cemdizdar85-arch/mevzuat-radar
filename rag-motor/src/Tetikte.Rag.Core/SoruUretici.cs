using System.Text.Json;
using System.Text.RegularExpressions;
using Anthropic;
using Anthropic.Models.Messages;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Polly;

namespace Tetikte.Rag.Core;

/// <summary>
/// SORU URETIM MOTORU (3. ayak).
///
/// AKIS: konu -> sorgu gomme -> hibrit arama (RRF) -> en ilgili parca ->
///       modele SADECE o parca ile istem -> semasi ZORLANMIS JSON -> ambar.
///
/// UC TASARIM KARARI:
///
/// 1) STRUCTURED OUTPUT. Model "JSON dondur" diye rica edilmiyor, semasi
///    OutputConfig.Format ile ZORLANIYOR. Serbest metinden JSON ayiklamak
///    (```json cit temizleme, son '}' arama) kirilgan bir onarim katmani
///    dogurur; sema ile o katman hic gerekmez.
///
/// 2) ONBELLEK (prompt caching). Kural blogu her istekte AYNEN gidiyor ve
///    bu depoda olculdu: girisin buyuk cogunlugu sabit blok. CacheControl
///    ile o blok bir kez odenir, sonraki isteklerde onda bir fiyata okunur.
///    SIRA ONEMLI: sabit blok System'de ve onbellek sinirindan ONCE; degisken
///    olan (dayanak metin + konu) mesajda, yani sinirdan SONRA. Ters kurulursa
///    onbellek her istekte gecersizlesir ve isabet sifir olur.
///
/// 3) BOGAZLI Task.WhenAll. Es zamanli uretim SemaphoreSlim ile sinirlanir.
///    Sinirsiz WhenAll 429'u onlemez, URETIR.
/// </summary>
public sealed class SoruUretici(
    AnthropicClient istemci,
    Ambar ambar,
    IGommeIstemcisi gomme,
    IOptions<RagOptions> ayar,
    ILogger<SoruUretici> log)
{
    private readonly RagOptions _ayar = ayar.Value;
    private readonly ResiliencePipeline _hat = Dayaniklilik.SdkHatti(log);
    private readonly SemaphoreSlim _bogaz = new(ayar.Value.EsZamanliIstek, ayar.Value.EsZamanliIstek);

    /// <summary>
    /// Bir konu icin: dayanagi bul, o dayanaktan N soru urettir, ambara yaz.
    /// Dayanak bulunamazsa URETMEZ - kaynaksiz soru yazilmaz.
    /// </summary>
    public async Task<UretimSonucu> UretAsync(SoruIstegi istek, CancellationToken ct)
    {
        var sorgu = $"{istek.Ders} {istek.Konu}";

        // ZARIF DUSUS: gomme ucu kapaliysa sifir vektorle devam edilir.
        // rag.ara'daki RRF bir FULL OUTER JOIN oldugu icin bos vektor kanali
        // sonucu BOZMAZ, yalnizca daraltir - arama tam-metin kanalindan koşar.
        // Cokmek yerine daralmak dogru davranis: gomme anahtari operasyonel bir
        // eksiklik, mimari bir hata degil.
        var sorguVektoru = gomme.Acik
            ? await gomme.SorguGomAsync(sorgu, ct)
            : new float[_ayar.EmbeddingBoyut];

        var adaylar = await ambar.AraAsync(
            sorgu, sorguVektoru, gomme.Model,
            _ayar.AramaAdet, _ayar.AramaAdayHavuzu, kaynakTur: null, ct);

        if (adaylar.Count == 0)
        {
            log.LogWarning("KAYNAKSIZ: '{Konu}' icin dayanak bulunamadi - soru URETILMEDI.", istek.Konu);
            return new UretimSonucu([], 0, _ayar.UretimModel, 0, 0, "dayanak yok");
        }

        var dayanak = adaylar[0];

        // MADDE TAVANI: ayni parcadan sinirsiz soru cikarsa havuz tekrara duser.
        var mevcut = await ambar.ParcaSoruSayisiAsync(dayanak.ParcaId, ct);
        if (mevcut >= 8)
        {
            log.LogInformation("TAVAN: parca {Id} zaten {Sayi} soru tasiyor, atlandi.", dayanak.ParcaId, mevcut);
            return new UretimSonucu([], dayanak.ParcaId, _ayar.UretimModel, 0, 0, "madde tavani dolu");
        }

        await _bogaz.WaitAsync(ct);
        try
        {
            var sonuc = await _hat.ExecuteAsync(
                async token => await ModeliCagirAsync(istek, dayanak, token), ct);

            foreach (var s in sonuc.Sorular)
                await ambar.SoruYazAsync(dayanak.ParcaId, istek.Ders, istek.Konu, istek.Zorluk,
                                         s, sonuc.Model, sonuc.GirisJeton, sonuc.CikisJeton, ct);

            return sonuc;
        }
        finally
        {
            _bogaz.Release();
        }
    }

    /// <summary>
    /// COKLU URETIM — Task.WhenAll. Bogaz zaten UretAsync icinde oldugu icin
    /// burada listeyi oldugu gibi acabiliriz: es zamanlilik tavani tek yerden
    /// yonetilir.
    /// </summary>
    public async Task<IReadOnlyList<UretimSonucu>> TopluUretAsync(
        IReadOnlyList<SoruIstegi> istekler, CancellationToken ct)
    {
        var isler = istekler.Select(async i =>
        {
            try
            {
                return await UretAsync(i, ct);
            }
            catch (Exception ex)
            {
                // BIR ISTEK TUM PARTIYI DUSURMEZ. Hatali olan hatasiyla doner,
                // digerleri devam eder; parti sonunda hepsi raporlanir.
                log.LogError(ex, "Uretim dustu: {Ders}/{Konu}", i.Ders, i.Konu);
                return new UretimSonucu([], 0, _ayar.UretimModel, 0, 0, ex.Message);
            }
        });

        var sonuclar = await Task.WhenAll(isler);

        var uretilen = sonuclar.Sum(s => s.Sorular.Count);
        var giris = sonuclar.Sum(s => s.GirisJeton);
        var cikis = sonuclar.Sum(s => s.CikisJeton);
        log.LogInformation(
            "PARTI BITTI: {Soru} soru / {Istek} istek · giris {Giris:N0} cikis {Cikis:N0} jeton · tahmini {Usd:N4} USD",
            uretilen, istekler.Count, giris, cikis, Fatura(giris, cikis));

        return sonuclar;
    }

    /// <summary>claude-sonnet-5 liste fiyati: giris 2 USD/M, cikis 10 USD/M. Model degisirse BURASI da degisir.</summary>
    private static double Fatura(int giris, int cikis) => giris / 1e6 * 2.0 + cikis / 1e6 * 10.0;

    private async Task<UretimSonucu> ModeliCagirAsync(
        SoruIstegi istek, AramaSonucu dayanak, CancellationToken ct)
    {
        var yanit = await istemci.Messages.Create(new MessageCreateParams
        {
            Model = _ayar.UretimModel,
            MaxTokens = _ayar.MaxTokens,

            // SABIT BLOK — onbellek sinirindan ONCE. Degistirirsen onbellek sifirlanir.
            System = new List<TextBlockParam>
            {
                new()
                {
                    Text = KuralBlogu,
                    CacheControl = new CacheControlEphemeral()
                }
            },

            // DEGISKEN KISIM — sinirdan SONRA.
            Messages =
            [
                new()
                {
                    Role = Role.User,
                    Content = $"""
                        DERS   : {istek.Ders}
                        KONU   : {istek.Konu}
                        ZORLUK : {istek.Zorluk}
                        ADET   : {istek.Adet}

                        === DAYANAK METIN ({dayanak.KaynakAd} {dayanak.MaddeNo}) ===
                        {dayanak.Metin}
                        === METIN BITTI ===
                        """
                }
            ],

            // Sema ZORLANIR: cikti mutlaka bu bicimde gelir.
            OutputConfig = new OutputConfig
            {
                Format = new JsonOutputFormat { Schema = Sema }
            }
        }, cancellationToken: ct);

        var metin = string.Concat(
            yanit.Content.Select(b => b.Value).OfType<TextBlock>().Select(t => t.Text));

        var paket = JsonSerializer.Deserialize<SoruPaketi>(metin)
                    ?? new SoruPaketi();

        var saglam = paket.Sorular.Where(s => Gecerli(s, dayanak)).ToList();
        if (saglam.Count < paket.Sorular.Count)
            log.LogWarning("{Dusen} soru KAPIDA elendi ({Konu})",
                paket.Sorular.Count - saglam.Count, istek.Konu);

        return new UretimSonucu(
            saglam,
            dayanak.ParcaId,
            _ayar.UretimModel,
            (int)yanit.Usage.InputTokens,
            (int)yanit.Usage.OutputTokens);
    }

    /// <summary>
    /// SIRALAMA / EZBER SORUSU KAPISI (Cem kusur bildirimi, 10.09.2026).
    ///
    /// Kural 10 istemde yaziyor ama ISTEM YUMUSAK BIR KAPIDIR: model onu
    /// %100 uygulamaz. Olculdu - kural 9 (tarihce) eklendikten sonra ayni
    /// turda "rayic bedel KACINCI olcu olarak yer almaktadir?" sorusu cikti.
    /// Kural yazmak isin yarisi; mekanik kapi diger yarisi.
    /// </summary>
    private static readonly Regex SiralamaDeseni = new(
        @"ka[çc]([ıi])nc([ıi])|ka[çc]\s+numaral([ıi])|hangi\s+ben[dt]|bendinde\s+d[üu]zenlen|s([ıi])ra\s+numaras([ıi])|ka[çc]([ıi])nc([ıi])\s+f([ıi])kra",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);

    /// <summary>
    /// KAPI. Model ne derse desin, bu sartlar saglanmadan soru ambara girmez.
    /// Bicimsel ama ucuz; asil hukuki denetim ayri bir hakem adimidir.
    /// </summary>
    private static bool Gecerli(UretilenSoru s, AramaSonucu dayanak)
    {
        if (string.IsNullOrWhiteSpace(s.Soru)) return false;
        if (SiralamaDeseni.IsMatch(s.Soru)) return false;   // kural 10
        if (!"ABCDE".Contains(s.Dogru, StringComparison.Ordinal) || s.Dogru.Length != 1) return false;

        var siklar = new[] { s.Siklar.A, s.Siklar.B, s.Siklar.C, s.Siklar.D, s.Siklar.E };
        if (siklar.Any(string.IsNullOrWhiteSpace)) return false;
        if (siklar.Distinct(StringComparer.OrdinalIgnoreCase).Count() != 5) return false;   // ikiz sik
        if (string.IsNullOrWhiteSpace(s.Dayanak)) return false;

        // CEVAP SIZINTISI: dogru sik, soru kokunde birebir gecmemeli.
        var dogruMetin = s.Dogru switch
        {
            "A" => s.Siklar.A, "B" => s.Siklar.B, "C" => s.Siklar.C,
            "D" => s.Siklar.D, _ => s.Siklar.E
        };
        if (dogruMetin.Length > 12 && s.Soru.Contains(dogruMetin, StringComparison.OrdinalIgnoreCase))
            return false;

        return true;
    }

    // ------------------------------------------------------------------ istem
    private const string KuralBlogu = """
        Sen Turkiye'deki mali musavirlik sinavlari icin coktan secmeli soru yazan
        bir editorsun. Sana bir DERS, bir KONU ve bir DAYANAK METIN verilir.

        DEGISMEZ KURALLAR:
        1. Soru YALNIZCA dayanak metne dayanir. Metinde YAZMAYAN hicbir rakam,
           oran, sure ya da esik kullanma - ne soruda ne aciklamada. Emin
           degilsen sayi verme.
        2. Hafizandan yazma. Bildigini sandigin bir hukum metinde yoksa YOKTUR.
        3. Bes sik: A, B, C, D, E. Yalniz biri dogru, digerleri savunulabilir
           bicimde yanlis olmali - saçma celdirici yazma.
        4. Dogru sikkin metnini soru kokunde TEKRARLAMA (cevap sizintisi).
        5. Her sik icin aciklama yaz: dogru olan neden dogru, yanlis olanlar
           neden yanlis. Aciklama da yalniz dayanak metne dayanir.
        6. 'dayanak' alanina hangi hukme dayandigini tek cumleyle yaz.
        7. Yapay zeka kokusu YASAK: "Bu baglamda", "onemlidir ki", "sonuc olarak"
           gibi dolgu kaliplar kullanma. Gercek bir sinav sorusu gibi yaz.
        8. Konu dayanak metinde YOKSA soru uretme - bos liste dondur.
        9. MEVZUAT TARIHCESI SORULMAZ. Madde metnindeki degisiklik dipnotlari
           - "(Ek: 30/12/1980-2365/46 md.)", "(Degisik: ...)", "(Muk: ...)" -
           kaynak kunyesidir, HUKUM DEGILDIR. "Bu bent hangi kanunla eklendi",
           "en son hangi degisiklik yapildi" gibi sorular YASAKTIR. Sinav
           adayinin bilmesi gereken sey hukmun KENDISIDIR, ne zaman
           degistirildigi degil.
        10. SIRALAMA / EZBER SORULMAZ. Bir hukmun kanun metninde KACINCI sirada,
           kacinci bentte, kacinci fikrada durdugu SORULMAZ: "rayic bedel
           kacinci olcudur", "hangi bentte duzenlenmistir", "kac numarali
           fikradadir" YASAKTIR. Bunlar dizgi bilgisidir, hukuk bilgisi degil;
           gercek sinavda sorulmaz. Bunun yerine hukmun UYGULANISINI, SARTLARINI,
           ISTISNALARINI ya da SURELERINI sor.
        """;

    private static readonly Dictionary<string, JsonElement> Sema = new()
    {
        ["type"] = JsonSerializer.SerializeToElement("object"),
        ["additionalProperties"] = JsonSerializer.SerializeToElement(false),
        ["required"] = JsonSerializer.SerializeToElement(new[] { "sorular" }),
        ["properties"] = JsonSerializer.SerializeToElement(new
        {
            sorular = new
            {
                type = "array",
                items = new
                {
                    type = "object",
                    additionalProperties = false,
                    required = new[] { "soru", "siklar", "dogru", "aciklama", "dayanak" },
                    properties = new
                    {
                        soru = new { type = "string" },
                        siklar = SikSemasi,
                        dogru = new { type = "string", @enum = new[] { "A", "B", "C", "D", "E" } },
                        aciklama = SikSemasi,
                        dayanak = new { type = "string" }
                    }
                }
            }
        })
    };

    private static object SikSemasi => new
    {
        type = "object",
        additionalProperties = false,
        required = new[] { "A", "B", "C", "D", "E" },
        properties = new
        {
            A = new { type = "string" },
            B = new { type = "string" },
            C = new { type = "string" },
            D = new { type = "string" },
            E = new { type = "string" }
        }
    };
}
