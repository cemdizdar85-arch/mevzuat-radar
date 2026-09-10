using System.Net;
using Microsoft.Extensions.Logging;
using Polly;
using Polly.Retry;

namespace Tetikte.Rag.Core;

/// <summary>
/// HATA TOLERANSI (4. ayak).
///
/// TASARIM: iki katman birlikte calisir ve ikisi de gerekli.
///   1) BOGAZ (SemaphoreSlim) — istek SAYISINI bastan sinirlar.
///      Task.WhenAll'i sinirsiz acmak, 429'u ONLEMEK yerine URETIR.
///   2) TEKRAR (Polly) — 429/5xx/aglama durumunda usteI geri cekilme + jitter.
///
/// KRITIK AYRINTI: sunucu `retry-after` verdiyse ONA UYULUR. Kendi hesabimizi
/// sunucunun soyledigine tercih etmek, sinir penceresini uzatir.
///
/// JITTER NEDEN SART: es zamanli 4 istek ayni anda 429 yer, hepsi ayni sure
/// bekler, ayni anda geri doner ve yine 429 yer ("thundering herd"). Rastgele
/// sacilma bunu kirar.
/// </summary>
public static class Dayaniklilik
{
    private static readonly HttpStatusCode[] TekrarlanabilirDurumlar =
    [
        HttpStatusCode.RequestTimeout,        // 408
        HttpStatusCode.Conflict,              // 409
        HttpStatusCode.TooManyRequests,       // 429
        HttpStatusCode.InternalServerError,   // 500
        HttpStatusCode.BadGateway,            // 502
        HttpStatusCode.ServiceUnavailable,    // 503
        HttpStatusCode.GatewayTimeout         // 504
    ];

    /// <summary>
    /// GUNLUK KOTA TUKENMESI TEKRARLANMAZ (10.09.2026 olculdu, pahaliya).
    ///
    /// 429 iki AYRI seyi anlatir ve ikisine ayni tepki verilmez:
    ///   · DAKIKALIK hiz siniri  -> beklersen gecer, TEKRAR DENENIR
    ///   · GUNLUK kota tukenmesi -> beklemek gecmez, TEKRAR DENEMEK KOTAYI YER
    ///
    /// Olculen bedel: `gomme` kosusu 32'lik yiginlarla calisiyordu. Gunluk kota
    /// dolunca Polly her yigini BES KEZ tekrar denedi - her deneme 32 istek
    /// sayildigi icin tek bir yigin 160 istek harciyordu. Gunun 1.000'lik
    /// kotasi tekrar denemelerle tukendi ve HICBIR vektor uretilemedi.
    /// Ayni ders Anthropic tarafinda "credit balance" icin zaten yaziliydi;
    /// Gemini tarafinda eksik kalmis.
    ///
    /// Ayirt edici isaret govdededir: "Quota exceeded for metric: ...
    /// free_tier_requests, limit: 1000". Bu KALICI bir durumdur - gun donene
    /// kadar degismez.
    /// </summary>
    private static bool GunlukKotaTukendi(HttpResponseMessage? y)
    {
        if (y is null || y.StatusCode != HttpStatusCode.TooManyRequests) return false;
        try
        {
            var govde = y.Content.ReadAsStringAsync().GetAwaiter().GetResult();
            return govde.Contains("Quota exceeded", StringComparison.OrdinalIgnoreCase)
                || govde.Contains("free_tier", StringComparison.OrdinalIgnoreCase)
                || govde.Contains("billing details", StringComparison.OrdinalIgnoreCase);
        }
        catch { return false; }
    }

    /// <summary>HTTP hatti icin (gomme ucu). HttpResponseMessage donduren cagrilarda kullanilir.</summary>
    public static ResiliencePipeline<HttpResponseMessage> HttpHatti(ILogger logger, int enFazlaDeneme = 5)
        => new ResiliencePipelineBuilder<HttpResponseMessage>()
            .AddRetry(new RetryStrategyOptions<HttpResponseMessage>
            {
                ShouldHandle = new PredicateBuilder<HttpResponseMessage>()
                    // Gunluk kota tukendiyse TEKRAR DENENMEZ - denemek kotayi yer.
                    .HandleResult(r => TekrarlanabilirDurumlar.Contains(r.StatusCode) && !GunlukKotaTukendi(r))
                    .Handle<HttpRequestException>()
                    .Handle<TaskCanceledException>(),
                MaxRetryAttempts = enFazlaDeneme,
                BackoffType = DelayBackoffType.Exponential,
                UseJitter = true,
                Delay = TimeSpan.FromSeconds(2),
                MaxDelay = TimeSpan.FromMinutes(2),

                // Sunucunun sozu bizimkinden ustundur.
                DelayGenerator = args =>
                {
                    var ra = args.Outcome.Result?.Headers.RetryAfter;
                    if (ra?.Delta is { } delta)
                        return ValueTask.FromResult<TimeSpan?>(delta);
                    if (ra?.Date is { } tarih)
                        return ValueTask.FromResult<TimeSpan?>(tarih - DateTimeOffset.UtcNow);
                    return ValueTask.FromResult<TimeSpan?>(null); // null => usteI geri cekilme
                },

                OnRetry = args =>
                {
                    logger.LogWarning(
                        "Gomme ucu tekrar deneniyor {Deneme}/{Tavan} — durum {Durum}, bekleme {Bekleme}",
                        args.AttemptNumber + 1, enFazlaDeneme,
                        args.Outcome.Result?.StatusCode.ToString() ?? args.Outcome.Exception?.GetType().Name,
                        args.RetryDelay);
                    return ValueTask.CompletedTask;
                }
            })
            .AddTimeout(TimeSpan.FromMinutes(2))
            .Build();

    /// <summary>
    /// SDK hatti icin (Anthropic istemcisi kendi HttpClient'ini tasir).
    /// Istisna tipine gore karar verir; SDK'nin firlattigi tipler
    /// Anthropic.Exceptions altindadir ama biz ADA BAGLI kalmiyoruz:
    /// mesajda/durumda 429 gecen her sey tekrarlanabilir sayilir. Boylece
    /// SDK surumu tip adini degistirse de kapi calismaya devam eder.
    /// </summary>
    public static ResiliencePipeline SdkHatti(ILogger logger, int enFazlaDeneme = 5)
        => new ResiliencePipelineBuilder()
            .AddRetry(new RetryStrategyOptions
            {
                ShouldHandle = new PredicateBuilder().Handle<Exception>(Tekrarlanabilir),
                MaxRetryAttempts = enFazlaDeneme,
                BackoffType = DelayBackoffType.Exponential,
                UseJitter = true,
                Delay = TimeSpan.FromSeconds(3),
                MaxDelay = TimeSpan.FromMinutes(3),
                OnRetry = args =>
                {
                    logger.LogWarning(
                        "Model cagrisi tekrar deneniyor {Deneme}/{Tavan} — {Hata}; bekleme {Bekleme}",
                        args.AttemptNumber + 1, enFazlaDeneme,
                        args.Outcome.Exception?.Message, args.RetryDelay);
                    return ValueTask.CompletedTask;
                }
            })
            .Build();

    /// <summary>
    /// BAKIYE HATASI TEKRARLANMAZ. Bu depoda 10.09'da olculdu: bakiye bitince
    /// her deneme ayni duvara carpiyor, parti yarim kaliyor ve yeniden
    /// kosuldugunda ayni is IKINCI KEZ odeniyor. Bakiye/kimlik/gecersiz istek
    /// hatalari KALICI'dir - hemen yukari firlar.
    /// </summary>
    private static bool Tekrarlanabilir(Exception ex)
    {
        var m = ex.Message;
        if (m.Contains("credit balance", StringComparison.OrdinalIgnoreCase)) return false;
        if (m.Contains("authentication", StringComparison.OrdinalIgnoreCase)) return false;
        if (m.Contains("invalid_request", StringComparison.OrdinalIgnoreCase)) return false;
        if (m.Contains("permission", StringComparison.OrdinalIgnoreCase)) return false;

        if (ex is HttpRequestException or TaskCanceledException or TimeoutException) return true;
        if (m.Contains("429") || m.Contains("rate_limit", StringComparison.OrdinalIgnoreCase)) return true;
        if (m.Contains("overloaded", StringComparison.OrdinalIgnoreCase)) return true;
        if (m.Contains("500") || m.Contains("502") || m.Contains("503") || m.Contains("529")) return true;

        return false;
    }
}
