using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Polly;

namespace Tetikte.Rag.Core;

public interface IGommeIstemcisi
{
    /// <summary>Belge tarafi (ambara yazilacak metin).</summary>
    Task<float[]> BelgeGomAsync(string metin, CancellationToken ct);

    /// <summary>Sorgu tarafi. AYRI gorev tipi kullanilir - asimetrik gomme.</summary>
    Task<float[]> SorguGomAsync(string sorgu, CancellationToken ct);

    Task<IReadOnlyList<float[]>> BelgeYiginGomAsync(IReadOnlyList<string> metinler, CancellationToken ct);

    string Model { get; }
    int Boyut { get; }
}

/// <summary>
/// Gemini gomme ucu.
///
/// NEDEN GEMINI: Anthropic'in gomme API'si YOKTUR ve bu depo zaten Gemini
/// anahtarini tasiyor (bedava kotali capraz dogrulama hatti). Ikinci bir
/// saglayici hesabi acmadan gomme alinabilecek tek yer burasi.
///
/// ASIMETRIK GOMME: belge RETRIEVAL_DOCUMENT, sorgu RETRIEVAL_QUERY gorev
/// tipiyle gomulur. Ayni metin iki gorev tipinde FARKLI vektor uretir ve
/// dogru eslesme ancak dogru cift kullanilinca olusur. Ikisini karistirmak
/// aramayi sessizce bozar - bu yuzden iki AYRI metot var, tek bayrakli tek
/// metot degil.
///
/// NORMALIZE: vektorler L2-normalize edilir. Cosine mesafesi normalize
/// vektorlerde nokta carpimina indirgenir; HNSW de boylece kararli calisir.
/// </summary>
public sealed class GeminiGommeIstemcisi : IGommeIstemcisi
{
    private const string Taban = "https://generativelanguage.googleapis.com/v1beta/models";

    private readonly HttpClient _http;
    private readonly RagOptions _ayar;
    private readonly ResiliencePipeline<HttpResponseMessage> _hat;
    private readonly ILogger<GeminiGommeIstemcisi> _log;

    public string Model => _ayar.EmbeddingModel;
    public int Boyut => _ayar.EmbeddingBoyut;

    public GeminiGommeIstemcisi(
        HttpClient http,
        IOptions<RagOptions> ayar,
        ILogger<GeminiGommeIstemcisi> log)
    {
        _http = http;
        _ayar = ayar.Value;
        _log = log;
        _hat = Dayaniklilik.HttpHatti(log);
    }

    public Task<float[]> BelgeGomAsync(string metin, CancellationToken ct)
        => TekGomAsync(metin, "RETRIEVAL_DOCUMENT", ct);

    public Task<float[]> SorguGomAsync(string sorgu, CancellationToken ct)
        => TekGomAsync(sorgu, "RETRIEVAL_QUERY", ct);

    public async Task<IReadOnlyList<float[]>> BelgeYiginGomAsync(
        IReadOnlyList<string> metinler, CancellationToken ct)
    {
        if (metinler.Count == 0) return [];

        var istekler = metinler.Select(m => new GomIstek(
            Model: $"models/{_ayar.EmbeddingModel}",
            Content: new Icerik([new Parca(Kirp(m))]),
            TaskType: "RETRIEVAL_DOCUMENT",
            OutputDimensionality: _ayar.EmbeddingBoyut)).ToList();

        var govde = new YiginIstek(istekler);
        var url = $"{Taban}/{_ayar.EmbeddingModel}:batchEmbedContents?key={RagOptions.GeminiApiKey}";

        var yanit = await _hat.ExecuteAsync(
            async token => await _http.PostAsJsonAsync(url, govde, token), ct);

        await DogrulaAsync(yanit, ct);

        var cozum = await yanit.Content.ReadFromJsonAsync<YiginYanit>(cancellationToken: ct)
                    ?? throw new InvalidOperationException("Gomme yaniti cozulemedi.");

        return cozum.Embeddings.Select(e => Normalize(e.Values)).ToList();
    }

    private async Task<float[]> TekGomAsync(string metin, string gorev, CancellationToken ct)
    {
        var govde = new GomIstek(
            Model: $"models/{_ayar.EmbeddingModel}",
            Content: new Icerik([new Parca(Kirp(metin))]),
            TaskType: gorev,
            OutputDimensionality: _ayar.EmbeddingBoyut);

        var url = $"{Taban}/{_ayar.EmbeddingModel}:embedContent?key={RagOptions.GeminiApiKey}";

        var yanit = await _hat.ExecuteAsync(
            async token => await _http.PostAsJsonAsync(url, govde, token), ct);

        await DogrulaAsync(yanit, ct);

        var cozum = await yanit.Content.ReadFromJsonAsync<TekYanit>(cancellationToken: ct)
                    ?? throw new InvalidOperationException("Gomme yaniti cozulemedi.");

        return Normalize(cozum.Embedding.Values);
    }

    private async Task DogrulaAsync(HttpResponseMessage yanit, CancellationToken ct)
    {
        if (yanit.IsSuccessStatusCode) return;

        // HATA GOVDESI TASINIR. "istek dustu" deyip sebebi yutmak kor birakir:
        // kota mi, model adi mi, bicim mi - govde soyler.
        var g = await yanit.Content.ReadAsStringAsync(ct);
        _log.LogError("Gomme ucu {Durum}: {Govde}", (int)yanit.StatusCode, Kisalt(g));
        throw new HttpRequestException($"Gomme ucu {(int)yanit.StatusCode}: {Kisalt(g)}");
    }

    /// <summary>Gomme ucunun jeton tavanini asmamak icin. Parcalayici zaten 8.000'i asmiyor.</summary>
    private static string Kirp(string s) => s.Length <= 8000 ? s : s[..8000];

    private static string Kisalt(string s) => s.Length <= 400 ? s : s[..400];

    private static float[] Normalize(float[] v)
    {
        double kare = 0;
        foreach (var x in v) kare += (double)x * x;
        var uzunluk = Math.Sqrt(kare);
        if (uzunluk < 1e-12) return v;
        var c = new float[v.Length];
        for (var i = 0; i < v.Length; i++) c[i] = (float)(v[i] / uzunluk);
        return c;
    }

    // --- tel bicimleri -------------------------------------------------------
    private sealed record Parca([property: JsonPropertyName("text")] string Text);
    private sealed record Icerik([property: JsonPropertyName("parts")] IReadOnlyList<Parca> Parts);

    private sealed record GomIstek(
        [property: JsonPropertyName("model")] string Model,
        [property: JsonPropertyName("content")] Icerik Content,
        [property: JsonPropertyName("taskType")] string TaskType,
        [property: JsonPropertyName("outputDimensionality")] int OutputDimensionality);

    private sealed record YiginIstek(
        [property: JsonPropertyName("requests")] IReadOnlyList<GomIstek> Requests);

    private sealed record Gomme([property: JsonPropertyName("values")] float[] Values);
    private sealed record TekYanit([property: JsonPropertyName("embedding")] Gomme Embedding);
    private sealed record YiginYanit([property: JsonPropertyName("embeddings")] IReadOnlyList<Gomme> Embeddings);
}
