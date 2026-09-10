using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Tetikte.Rag.Core;

/// <summary>
/// BAGLAM HAZIRLIGI (2. ayak) — ucu uca yutma:
///   ham metin -> parcalara bol -> ambara yaz -> vektorlerini uret -> yaz.
///
/// IDEMPOTENT: ayni belge iki kez yutulursa parcalar mukerrer freniyle
/// (icerik ozeti) atlanir, vektorler de yalniz eksik olanlar icin uretilir.
/// Yani bu servis korkusuzca yeniden kosulabilir - robot iki kez calisirsa
/// ne ambar sisir ne de gomme parasi ikinci kez odenir.
/// </summary>
public sealed class YutmaServisi(
    Ambar ambar,
    IGommeIstemcisi gomme,
    IOptions<RagOptions> ayar,
    ILogger<YutmaServisi> log)
{
    private readonly RagOptions _ayar = ayar.Value;
    private readonly MevzuatParcalayici _parcalayici =
        new(ayar.Value.ParcaHedefBoy, ayar.Value.ParcaBindirme);

    public async Task<(int Parca, int Vektor)> BelgeYutAsync(
        string kod, string ad, string tur, string? url, string hamMetin, CancellationToken ct)
    {
        var kaynakId = await ambar.KaynakYazAsync(kod, ad, tur, url, ct);

        var parcalar = _parcalayici.Parcala(hamMetin);
        if (parcalar.Count == 0)
        {
            log.LogWarning("PARCA CIKMADI: {Kod} ({Uzunluk} karakter)", kod, hamMetin.Length);
            return (0, 0);
        }

        var yeni = await ambar.ParcaYazAsync(kaynakId, parcalar, ct);
        log.LogInformation("{Kod}: {Toplam} parca cikti, {Yeni} yeni yazildi", kod, parcalar.Count, yeni.Count);

        var vektor = await EksikVektorleriUretAsync(ct);
        return (yeni.Count, vektor);
    }

    /// <summary>
    /// Vektoru olmayan parcalari yiginlar halinde gomer.
    /// Yigin boyu ayardan gelir: tek tek gommek hem yavas hem pahali,
    /// cok buyuk yigin ise tek hatada cok isi cope atar.
    /// </summary>
    public async Task<int> EksikVektorleriUretAsync(CancellationToken ct)
    {
        var toplam = 0;

        // Gomme ucu kapaliysa parcalar VEKTORSUZ kalir - kayip degil, eksik.
        // Anahtar gelince 'bakim kosusu' isi (metinsiz gomme yuku) hepsini
        // tamamlar; parcalar yeniden yutulmaz.
        if (!gomme.Acik)
        {
            log.LogWarning("GOMME KAPALI (GEMINI_API_KEY yok) - parcalar vektorsuz yazildi. " +
                           "Arama simdilik yalniz tam-metin kanalindan kosar.");
            return 0;
        }

        while (!ct.IsCancellationRequested)
        {
            var bekleyen = await ambar.VektorsuzParcalarAsync(gomme.Model, _ayar.GommeYiginBoyu, ct);
            if (bekleyen.Count == 0) break;

            var vektorler = await gomme.BelgeYiginGomAsync(
                bekleyen.Select(b => b.Metin).ToList(), ct);

            if (vektorler.Count != bekleyen.Count)
                throw new InvalidOperationException(
                    $"Gomme sayisi uyusmuyor: {vektorler.Count} vektor / {bekleyen.Count} parca. " +
                    "Sessizce hizalamak YANLIS vektoru YANLIS parcaya baglar - durduruldu.");

            var satirlar = bekleyen
                .Select((b, i) => (b.Id, vektorler[i]))
                .ToList();

            await ambar.VektorYazAsync(satirlar, gomme.Model, gomme.Boyut, ct);
            toplam += satirlar.Count;
            log.LogInformation("Gomme: {Bu} parca yazildi (toplam {Toplam})", satirlar.Count, toplam);
        }

        return toplam;
    }
}
