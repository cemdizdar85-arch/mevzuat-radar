using System.Text.Json;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Tetikte.Rag.Core;

namespace Tetikte.Rag.Worker;

/// <summary>
/// Kuyruktan 'gomme' isi alir. Yuk bicimi:
///   { "kod":"VUK-213", "ad":"Vergi Usul Kanunu", "tur":"kanun", "url":null, "metin":"..." }
/// 'metin' yoksa yalniz eksik vektorleri tamamlar (bakim koşusu).
/// </summary>
public sealed class GommeIscisi(
    Ambar ambar,
    YutmaServisi yutma,
    ILogger<GommeIscisi> log) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        log.LogInformation("Gomme iscisi ayakta.");

        while (!ct.IsCancellationRequested)
        {
            var isim = await ambar.IsAlAsync("gomme", ct);
            if (isim is null)
            {
                // Bos kuyrukta dondurmemek icin bekle. Uretimde LISTEN/NOTIFY
                // ile olay tabanli hale getirilebilir; bu olcekte yoklama yeterli.
                await Task.Delay(TimeSpan.FromSeconds(5), ct);
                continue;
            }

            var (id, yuk) = isim.Value;
            try
            {
                var y = JsonSerializer.Deserialize<GommeYuku>(yuk)
                        ?? throw new InvalidOperationException("gomme yuku cozulemedi");

                if (string.IsNullOrWhiteSpace(y.Metin))
                {
                    var n = await yutma.EksikVektorleriUretAsync(ct);
                    log.LogInformation("Bakim kosusu: {N} vektor tamamlandi", n);
                }
                else
                {
                    var (parca, vektor) = await yutma.BelgeYutAsync(
                        y.Kod, y.Ad, y.Tur, y.Url, y.Metin, ct);
                    log.LogInformation("{Kod}: {Parca} parca / {Vektor} vektor", y.Kod, parca, vektor);
                }

                await ambar.IsKapatAsync(id, true, null, ct);
            }
            catch (OperationCanceledException) when (ct.IsCancellationRequested)
            {
                throw;
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Gomme isi dustu (id={Id})", id);
                await ambar.IsKapatAsync(id, false, ex.Message, CancellationToken.None);
            }
        }
    }

    private sealed record GommeYuku(string Kod, string Ad, string Tur, string? Url, string? Metin);
}

/// <summary>
/// Kuyruktan 'soru' isi alir. Yuk bicimi:
///   { "ders":"Vergi", "istekler":[ {"konu":"amortisman","adet":2}, ... ] }
/// 'zorluk' verilmezse konu KOLAY+ORTA+ZOR olmak uzere uc seviyede uretilir;
/// tek seviye isteniyorsa "zorluk":"zor" ya da "zorluklar":["kolay","zor"] yazilir.
/// Butun istekler Task.WhenAll ile AYNI ANDA acilir; es zamanlilik tavani
/// SoruUretici icindeki bogazdan gelir.
/// </summary>
public sealed class SoruIscisi(
    Ambar ambar,
    SoruUretici uretici,
    ILogger<SoruIscisi> log) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        log.LogInformation("Soru iscisi ayakta.");

        while (!ct.IsCancellationRequested)
        {
            var isim = await ambar.IsAlAsync("soru", ct);
            if (isim is null)
            {
                await Task.Delay(TimeSpan.FromSeconds(5), ct);
                continue;
            }

            var (id, yuk) = isim.Value;
            try
            {
                var y = JsonSerializer.Deserialize<SoruYuku>(yuk)
                        ?? throw new InvalidOperationException("soru yuku cozulemedi");

                // ZORLUK GERI UYUMU: yuk tek bir "zorluk" veriyorsa o zorluk
                // kullanilir; vermiyorsa UC SEVIYE birden uretilir. Boylece
                // eski kuyruk yukleri calismaya devam eder ama VARSAYILAN
                // artik tek seviye degil, uc seviyedir.
                var istekler = y.Istekler
                    .Select(i => new KonuIstegi(
                        y.Ders,
                        i.Konu,
                        (IReadOnlyList<string>?)i.Zorluklar
                            ?? (i.Zorluk is null ? KonuIstegi.UcSeviye : [i.Zorluk]),
                        i.Adet ?? 2))
                    .ToList();

                var sonuclar = await uretici.TopluKonuUretAsync(istekler, ct);

                var dusen = sonuclar.Count(s => s.Hata is not null);
                if (dusen == sonuclar.Count && sonuclar.Count > 0)
                    throw new InvalidOperationException(
                        $"Butun istekler dustu. Ilk sebep: {sonuclar[0].Hata}");

                log.LogInformation("Is {Id} bitti: {Ok}/{Toplam} istek uretti",
                    id, sonuclar.Count - dusen, sonuclar.Count);

                await ambar.IsKapatAsync(id, true, dusen > 0 ? $"{dusen} istek dustu" : null, ct);
            }
            catch (OperationCanceledException) when (ct.IsCancellationRequested)
            {
                throw;
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Soru isi dustu (id={Id})", id);
                await ambar.IsKapatAsync(id, false, ex.Message, CancellationToken.None);
            }
        }
    }

    /// <summary>Kuyruk yukundeki konu satiri. Zorluk alanlari ISTEGE BAGLI - yoksa uc seviye uretilir.</summary>
    private sealed record KonuYuku(string Konu, string? Zorluk, List<string>? Zorluklar, int? Adet);
    private sealed record SoruYuku(string Ders, List<KonuYuku> Istekler);
}
