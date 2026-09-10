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
    /// KONU URETIMI — bir konu, UC ZORLUK, TEK ARAMA.
    ///
    /// Akis: dayanagi BIR KEZ bul -> madde tavanindan kalan butceyi hesapla ->
    ///       butceyi zorluklara bol -> zorluklari es zamanli urettir.
    ///
    /// Neden boyle: uc zorlugu uc bagimsiz istek olarak acmak dayanagi uc kez
    /// arattirir (uc gomme cagrisi, ayni sonuc) ve madde tavanini YARISA sokar -
    /// uc istek de ayni anda "bu parcada kac soru var" diye bakip ucu de "0"
    /// gorur. Parca 586'da 9 soru olmasinin sebebi tam olarak buydu.
    /// </summary>
    public async Task<IReadOnlyList<UretimSonucu>> KonuUretAsync(
        KonuIstegi istek, CancellationToken ct)
    {
        var zorluklar = istek.Zorluklar.Count > 0 ? istek.Zorluklar : KonuIstegi.UcSeviye;

        var dayanak = await DayanakBulAsync(istek.Ders, istek.Konu, ct);
        if (dayanak is null)
            return [new UretimSonucu([], 0, _ayar.UretimModel, 0, 0, "dayanak yok")];

        // MADDE TAVANI TEK YERDE. Kalan butce burada olculur, asagida bolunur;
        // boylece es zamanli zorluk cagrilari tavani birlikte asamaz.
        var mevcut = await ambar.ParcaSoruSayisiAsync(dayanak.ParcaId, ct);
        var butce = _ayar.MaddeTavani - mevcut;
        if (butce <= 0)
        {
            log.LogInformation("TAVAN: parca {Id} zaten {Sayi} soru tasiyor, atlandi.",
                dayanak.ParcaId, mevcut);
            return [new UretimSonucu([], dayanak.ParcaId, _ayar.UretimModel, 0, 0, "madde tavani dolu")];
        }

        // BUTCE DAGITIMI: her zorluga esit pay, artan varsa KOLAYDAN baslayarak
        // birer birer dagitilir. Kolay sorular havuzun tabanidir; kisitli
        // butcede once taban dolar.
        var pay = new int[zorluklar.Count];
        var kalan = Math.Min(butce, zorluklar.Count * istek.AdetHer);
        for (var i = 0; kalan > 0; i = (i + 1) % zorluklar.Count, kalan--)
            pay[i]++;

        log.LogInformation("{Konu}: parca {Id} · tavan butcesi {Butce} · dagitim {Dagitim}",
            istek.Konu, dayanak.ParcaId, butce,
            string.Join(" ", zorluklar.Select((z, i) => $"{z}={pay[i]}")));

        var isler = zorluklar.Select(async (zorluk, i) =>
        {
            if (pay[i] == 0)
                return new UretimSonucu([], dayanak.ParcaId, _ayar.UretimModel, 0, 0, "butce kalmadi");
            try
            {
                return await ZorlukUretAsync(
                    new SoruIstegi(istek.Ders, istek.Konu, zorluk, pay[i]), dayanak, ct);
            }
            catch (Exception ex)
            {
                // Bir zorluk dusunce digerleri devam eder.
                log.LogError(ex, "Zorluk dustu: {Konu}/{Zorluk}", istek.Konu, zorluk);
                return new UretimSonucu([], dayanak.ParcaId, _ayar.UretimModel, 0, 0, ex.Message);
            }
        });

        return await Task.WhenAll(isler);
    }

    /// <summary>
    /// Bir konu icin: dayanagi bul, o dayanaktan N soru urettir, ambara yaz.
    /// Dayanak bulunamazsa URETMEZ - kaynaksiz soru yazilmaz.
    /// TEK ZORLUK yolu; uc seviye icin <see cref="KonuUretAsync"/> kullanilir.
    /// </summary>
    public async Task<UretimSonucu> UretAsync(SoruIstegi istek, CancellationToken ct)
    {
        var dayanak0 = await DayanakBulAsync(istek.Ders, istek.Konu, ct);
        if (dayanak0 is null)
            return new UretimSonucu([], 0, _ayar.UretimModel, 0, 0, "dayanak yok");

        var mevcut0 = await ambar.ParcaSoruSayisiAsync(dayanak0.ParcaId, ct);
        if (mevcut0 >= _ayar.MaddeTavani)
        {
            log.LogInformation("TAVAN: parca {Id} zaten {Sayi} soru tasiyor, atlandi.", dayanak0.ParcaId, mevcut0);
            return new UretimSonucu([], dayanak0.ParcaId, _ayar.UretimModel, 0, 0, "madde tavani dolu");
        }

        var istek0 = istek with { Adet = Math.Min(istek.Adet, _ayar.MaddeTavani - mevcut0) };
        return await ZorlukUretAsync(istek0, dayanak0, ct);
    }

    /// <summary>
    /// DAYANAK ARAMA — konu karti once, arama sonra. Tek yerde durur ki
    /// zorluklar arasinda TEKRARLANMASIN.
    /// </summary>
    private async Task<AramaSonucu?> DayanakBulAsync(string ders, string konu, CancellationToken ct)
    {
        var sorgu = $"{ders} {konu}";

        // ZARIF DUSUS: gomme ucu kapaliysa sifir vektorle devam edilir.
        // rag.ara'daki RRF bir FULL OUTER JOIN oldugu icin bos vektor kanali
        // sonucu BOZMAZ, yalnizca daraltir - arama tam-metin kanalindan koşar.
        // Cokmek yerine daralmak dogru davranis: gomme anahtari operasyonel bir
        // eksiklik, mimari bir hata degil.
        // NULL = "vektor kanali yok" demektir. SIFIR VEKTOR gondermek ise
        // kanali kapatmaz, GURULTU uretir (bkz. sql/005_vektorsuz_arama.sql).
        float[]? sorguVektoru = gomme.Acik
            ? await gomme.SorguGomAsync(sorgu, ct)
            : null;

        // ONCE KONU KARTI, SONRA ARAMA.
        // Dayanak bir arama sonucu degil bir KAYITTIR: karti olan konu kesin
        // cevap alir, olmayan konu aramaya duser. 10.09'da olculdu - arama ayni
        // sorguya iki kosuda iki farkli madde dondurebiliyor; soru fabrikasi
        // bunun uzerine kurulmaz.
        var adaylar = await ambar.KonuKartindanAsync(ders, konu, _ayar.AramaAdet, ct);
        var kaynakYolu = "konu karti";

        if (adaylar.Count == 0)
        {
            adaylar = await ambar.AraAsync(
                sorgu, sorguVektoru, gomme.Model,
                _ayar.AramaAdet, _ayar.AramaAdayHavuzu, kaynakTur: null, ct);
            kaynakYolu = gomme.Acik ? "hibrit arama" : "tam metin aramasi (vektor kanali kapali)";
        }
        log.LogInformation("{Konu}: dayanak yolu = {Yol}, {Adet} aday", konu, kaynakYolu, adaylar.Count);

        if (adaylar.Count == 0)
        {
            log.LogWarning("KAYNAKSIZ: '{Konu}' icin dayanak bulunamadi - soru URETILMEDI.", konu);
            return null;
        }

        return adaylar[0];
    }

    /// <summary>
    /// TEK ZORLUK URETIMI — dayanak ZATEN bulunmus, tavan ZATEN olculmus olarak
    /// gelir. Modeli cagirir, kapidan geceni ambara yazar.
    /// </summary>
    private async Task<UretimSonucu> ZorlukUretAsync(
        SoruIstegi istek, AramaSonucu dayanak, CancellationToken ct)
    {
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
    /// COKLU URETIM — konu listesi, her konu UC ZORLUK. Task.WhenAll ile
    /// hepsi acilir; es zamanlilik tavani bogazdan gelir, tek yerden yonetilir.
    /// </summary>
    public async Task<IReadOnlyList<UretimSonucu>> TopluKonuUretAsync(
        IReadOnlyList<KonuIstegi> istekler, CancellationToken ct)
    {
        var isler = istekler.Select(async i =>
        {
            try
            {
                return await KonuUretAsync(i, ct);
            }
            catch (Exception ex)
            {
                // BIR KONU TUM PARTIYI DUSURMEZ.
                log.LogError(ex, "Uretim dustu: {Ders}/{Konu}", i.Ders, i.Konu);
                return (IReadOnlyList<UretimSonucu>)
                    [new UretimSonucu([], 0, _ayar.UretimModel, 0, 0, ex.Message)];
            }
        });

        var sonuclar = (await Task.WhenAll(isler)).SelectMany(x => x).ToList();
        Ozetle(sonuclar, istekler.Count);
        return sonuclar;
    }

    /// <summary>
    /// COKLU URETIM — TEK ZORLUK yolu. Bogaz zaten asagida oldugu icin
    /// burada listeyi oldugu gibi acabiliriz.
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
        Ozetle(sonuclar, istekler.Count);
        return sonuclar;
    }

    /// <summary>Parti sonu kutugu. Fatura HER ZAMAN basilir - olculmeyen harcama yonetilemez.</summary>
    private void Ozetle(IReadOnlyList<UretimSonucu> sonuclar, int istekSayisi)
    {
        var uretilen = sonuclar.Sum(s => s.Sorular.Count);
        var giris = sonuclar.Sum(s => s.GirisJeton);
        var cikis = sonuclar.Sum(s => s.CikisJeton);
        var zorlukDagilimi = string.Join(" · ", sonuclar
            .Where(s => s.Sorular.Count > 0)
            .GroupBy(s => s.Zorluk ?? "?")
            .Select(g => $"{g.Key}={g.Sum(x => x.Sorular.Count)}"));

        log.LogInformation(
            "PARTI BITTI: {Soru} soru / {Istek} konu · [{Dagilim}] · giris {Giris:N0} cikis {Cikis:N0} jeton · tahmini {Usd:N4} USD",
            uretilen, istekSayisi, zorlukDagilimi, giris, cikis, Fatura(giris, cikis));
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

                        {ZorlukYonergesi(istek.Zorluk)}

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

        // ADET KAPISI: model istenenden fazla soru dondurebilir. Fazlasi
        // KESILIR - yoksa madde tavani icin ayrilan butce asilir ve tavan
        // yine yariya girer (parca 586'da 9/8 boyle olmustu).
        var saglam = paket.Sorular.Where(s => Gecerli(s, dayanak)).Take(istek.Adet).ToList();
        if (saglam.Count < paket.Sorular.Count)
            log.LogWarning("{Dusen} soru KAPIDA elendi ya da adet asimindan kesildi ({Konu}/{Zorluk})",
                paket.Sorular.Count - saglam.Count, istek.Konu, istek.Zorluk);

        return new UretimSonucu(
            saglam,
            dayanak.ParcaId,
            _ayar.UretimModel,
            (int)yanit.Usage.InputTokens,
            (int)yanit.Usage.OutputTokens,
            Hata: null,
            Zorluk: istek.Zorluk);
    }

    /// <summary>
    /// ZORLUK YONERGESI — DEGISKEN kisma girer, onbellek sinirindan SONRA.
    ///
    /// NEDEN SABIT BLOKTA DEGIL: kural blogu her istekte AYNEN gidip onbellekten
    /// okunuyor. Zorluk istekten isteke degistigi icin oraya konursa onbellek
    /// HER cagride gecersizlesir ve isabet sifira duser. Degisken olan degisken
    /// tarafta durur.
    ///
    /// Uc seviye "daha uzun soru = daha zor" demek DEGILDIR. Fark, adaydan
    /// istenen ZIHINSEL ISLEMDE:
    ///   kolay -> hukmu TANIMA        (tek unsur, dogrudan)
    ///   orta  -> hukmu AYIRT ETME    (sart/istisna, iki unsurun bilesimi)
    ///   zor   -> hukmu UYGULAMA      (olay kurgusu, sonuca goturme)
    /// </summary>
    private static string ZorlukYonergesi(string zorluk) => zorluk.ToLowerInvariant() switch
    {
        "kolay" => """
            ZORLUK YONERGESI - KOLAY:
            Hukmu TANIMA seviyesi. Dayanak metindeki TEK bir unsuru dogrudan sor:
            bir tanim, bir sart, bir sure, bir yetkili merci. Soru koku kisa ve
            tek katmanli olsun. Olay kurgusu KURMA. Celdiriciler yine
            savunulabilir olsun ama dogru cevap, metni okumus bir adayin
            duraksamadan bulacagi netlikte olmali.
            """,

        "orta" => """
            ZORLUK YONERGESI - ORTA:
            Hukmu AYIRT ETME seviyesi. Iki unsuru birlikte sor ya da kural ile
            ISTISNASINI karsi karsiya getir: "sart saglanmazsa ne olur",
            "hangi hal bu kapsamin DISINDADIR", "kural su, peki su durumda".
            Aday metni okumus olmakla yetinemesin, iki hukmu birbirinden
            ayirabilsin. Kisa bir durum cumlesi kurabilirsin ama uzun senaryo
            YAZMA.
            """,

        _ => """
            ZORLUK YONERGESI - ZOR:
            Hukmu UYGULAMA seviyesi. Somut bir OLAY kurgusu ver (mukellef,
            islem, tarih/tutar metinde varsa) ve adaydan hukmu o olaya
            uygulayip SONUCA gitmesini iste. Birden cok sartin birlikte
            saglanmasi, ya da bir sartin eksikligi sonucu nasil degistirdigi
            sorulabilir. Kurguda kullandigin her unsur dayanak metinden gelmeli -
            metinde olmayan rakam ya da sure UYDURMA.
            """
    };

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
