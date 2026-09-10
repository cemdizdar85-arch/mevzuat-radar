using System.Text;
using System.Text.RegularExpressions;

namespace Tetikte.Rag.Core;

/// <summary>
/// BAGLAM HAZIRLIGI (2. ayak) — kanun metnini MANTIKLI parcalara boler.
///
/// UC KATMANLI STRATEJI, sirayla:
///   1) MADDE sinirlari  — mevzuatin kendi dogal birimi. "MADDE 359 —" gibi.
///   2) FIKRA sinirlari  — madde tavani asarsa "(1)", "a)", "1." ile boler.
///   3) CUMLE sinirlari  — o da yetmezse cumleden keser, ASLA kelime ortasindan.
///
/// NEDEN BU SIRA: bu depoda 10.09'da olculdu — bolunmemis buyuk parcalar
/// aramada MIKNATIS gibi calisiyor (cok kelime icerdikleri icin alakasiz
/// sorgularda one cikiyorlar) ve ayrica soru ureticisinin kirpma tavanina
/// takilip metnin bir kismi modele HIC gitmiyor. Iki zarar da parcanin
/// yanlis birimde olmasindan doguyor.
///
/// BINDIRME (overlap): ardisik parcalar arasinda birkac yuz karakter ortak
/// birakilir. Sebep: bir hukmun sarti onceki cumlede, sonucu sonrakinde
/// olabilir; tam sinirdan kesmek o bagi koparir.
/// </summary>
public sealed partial class MevzuatParcalayici(int hedefBoy = 2200, int bindirme = 200)
{
    // SQL'deki CHECK ile AYNI olmali (rag.parca: length between 40 and 8000).
    public const int MutlakTavan = 8000;
    public const int EnAzBoy = 40;

    private readonly int _hedefBoy = Math.Clamp(hedefBoy, 400, MutlakTavan);
    private readonly int _bindirme = Math.Clamp(bindirme, 0, 800);

    // Turkce mevzuatta madde basligi. Genis tire sinifi (U+2010..U+2015, U+2212)
    // ONEMLI: PDF'ten cikan metinlerde normal '-' yerine bunlar geliyor.
    [GeneratedRegex(
        @"(?<tur>MÜKERRER\s+MADDE|EK\s+GEÇİCİ\s+MADDE|EK\s+MADDE|GEÇİCİ\s+MADDE|Mükerrer\s+Madde|Ek\s+Geçici\s+Madde|Ek\s+Madde|Geçici\s+Madde|MADDE|Madde)\s+(?<no>\d+(?:/[A-ZÇĞİÖŞÜ])?)\s*(?:\([^)]{0,160}\)\s*)?[:‐-―−\-–—]?",
        RegexOptions.Compiled)]
    private static partial Regex MaddeDeseni();

    // Fikra / bent basligi: "(1)", "a)", "1." satir basinda
    [GeneratedRegex(@"(?m)^\s*(?:\(\d{1,2}\)|[a-zçğıöşü]\)|\d{1,2}\.)\s", RegexOptions.Compiled)]
    private static partial Regex FikraDeseni();

    // Cumle sonu: nokta/soru/unlem + bosluk. Kisaltmalari (m., s., vb.) ELEMEZ,
    // ama kesim noktasi secerken en sondakini aldigimiz icin zarar vermez.
    [GeneratedRegex(@"[.!?](?=\s)", RegexOptions.Compiled)]
    private static partial Regex CumleSonu();

    [GeneratedRegex(@"[ \t ]+", RegexOptions.Compiled)]
    private static partial Regex FazlaBosluk();

    public IReadOnlyList<YeniParca> Parcala(string hamMetin)
    {
        var metin = Duzlestir(hamMetin);
        if (metin.Length < EnAzBoy) return [];

        var cikti = new List<YeniParca>();
        var eslesmeler = MaddeDeseni().Matches(metin);

        if (eslesmeler.Count == 0)
        {
            // Maddesiz belge (rehber, kurul karari, teori notu): dogrudan
            // fikra/cumle katmanina duser.
            foreach (var (govde, _) in Dilimle(metin))
                Ekle(cikti, null, null, govde);
            return cikti;
        }

        // GIRIS: ilk maddeden onceki metin de METINDIR (RG kunyesi, amac,
        // kapsam, dayanak hep orada durur). ATLANMAZ - ama SINIRSIZ da
        // birakilmaz: kendi basina dilimlenir.
        var ilk = eslesmeler[0].Index;
        if (ilk >= EnAzBoy)
        {
            var giris = metin[..ilk].Trim();
            foreach (var (govde, _) in Dilimle(giris))
                Ekle(cikti, null, "Giriş", govde);
        }

        for (var i = 0; i < eslesmeler.Count; i++)
        {
            var bas = eslesmeler[i].Index;
            var son = i < eslesmeler.Count - 1 ? eslesmeler[i + 1].Index : metin.Length;
            var govdeTam = metin[bas..son].Trim();
            if (govdeTam.Length < EnAzBoy) continue;

            var maddeNo = MaddeAdi(eslesmeler[i].Groups["tur"].Value, eslesmeler[i].Groups["no"].Value);

            var dilimler = Dilimle(govdeTam);
            if (dilimler.Count == 1)
            {
                Ekle(cikti, maddeNo, null, dilimler[0].Govde);
            }
            else
            {
                // Uzun madde: parca adinda kacinci dilim oldugu DURUR ki
                // "m.359 [2/3]" diye izlenebilsin.
                for (var d = 0; d < dilimler.Count; d++)
                    Ekle(cikti, $"{maddeNo} [{d + 1}/{dilimler.Count}]", null, dilimler[d].Govde);
            }
        }

        return cikti;
    }

    private static void Ekle(List<YeniParca> liste, string? maddeNo, string? baslik, string metin)
    {
        var t = metin.Trim();
        if (t.Length < EnAzBoy) return;
        if (t.Length > MutlakTavan) t = t[..MutlakTavan];   // SQL CHECK'i asla tetiklemeyelim
        liste.Add(new YeniParca(maddeNo, baslik, t, liste.Count));
    }

    private static string MaddeAdi(string tur, string no)
    {
        var t = tur.ToLowerInvariant();
        if (t.Contains("mükerrer")) return $"muk. m.{no}";
        if (t.Contains("ek geçici")) return $"ek gec. m.{no}";
        if (t.Contains("geçici")) return $"gec. m.{no}";
        if (t.StartsWith("ek")) return $"ek m.{no}";
        return $"m.{no}";
    }

    private readonly record struct Dilim(string Govde, int Bas);

    /// <summary>
    /// Hedef boyu asan metni fikra, olmazsa cumle sinirindan keser; ardisik
    /// dilimlere bindirme ekler.
    /// </summary>
    private List<Dilim> Dilimle(string metin)
    {
        if (metin.Length <= _hedefBoy) return [new Dilim(metin, 0)];

        var sonuc = new List<Dilim>();
        var imlec = 0;

        while (imlec < metin.Length)
        {
            var kalan = metin.Length - imlec;
            if (kalan <= _hedefBoy)
            {
                sonuc.Add(new Dilim(metin[imlec..], imlec));
                break;
            }

            var pencereSon = imlec + _hedefBoy;
            var kesim = KesimNoktasi(metin, imlec, pencereSon);

            sonuc.Add(new Dilim(metin[imlec..kesim], imlec));

            // Bindirmeli ilerle; ama ASLA geri gitme (sonsuz dongu freni).
            var sonraki = kesim - _bindirme;
            imlec = sonraki > imlec ? sonraki : kesim;
        }

        return sonuc;
    }

    /// <summary>Pencere icindeki EN IYI kesim: once fikra basi, sonra cumle sonu, olmazsa bosluk.</summary>
    private static int KesimNoktasi(string metin, int bas, int pencereSon)
    {
        var enAz = bas + 200;                        // cok kucuk dilim uretme
        if (pencereSon >= metin.Length) return metin.Length;

        var pencere = metin[bas..pencereSon];

        var fikralar = FikraDeseni().Matches(pencere);
        for (var i = fikralar.Count - 1; i >= 0; i--)
        {
            var m = bas + fikralar[i].Index;
            if (m > enAz) return m;
        }

        var cumleler = CumleSonu().Matches(pencere);
        for (var i = cumleler.Count - 1; i >= 0; i--)
        {
            var m = bas + cumleler[i].Index + 1;
            if (m > enAz) return m;
        }

        var bosluk = pencere.LastIndexOf(' ');
        if (bosluk > 200) return bas + bosluk;

        return pencereSon;   // son care: sert kesim
    }

    /// <summary>PDF'ten gelen metinde satir sonlari ve cok bosluk gurultudur; tsvector'u de sisirir.</summary>
    private static string Duzlestir(string s)
    {
        var t = s.Replace("\r\n", "\n").Replace('\r', '\n');
        var sb = new StringBuilder(t.Length);
        foreach (var satir in t.Split('\n'))
            sb.Append(satir.Trim()).Append(' ');
        return FazlaBosluk().Replace(sb.ToString(), " ").Trim();
    }
}
