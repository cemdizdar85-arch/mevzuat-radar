namespace Tetikte.Rag.Core;

/// <summary>
/// Motorun tek ayar noktasi. appsettings.json + ortam degiskeni ile doldurulur.
/// SIR TUTMAZ: anahtarlar yalniz ortam degiskeninden okunur (bkz. <see cref="AnthropicApiKey"/>).
/// </summary>
public sealed class RagOptions
{
    public const string Bolum = "Rag";

    /// <summary>Npgsql baglanti dizesi. Ornek: Host=...;Database=...;Username=...;Password=...;SSL Mode=Require</summary>
    public string ConnectionString { get; set; } = "";

    // --- Gomme (embedding) --------------------------------------------------
    // Anthropic'in gomme ucu YOKTUR. Bu depoda zaten Gemini anahtari kullaniliyor
    // (bedava kotali capraz dogrulama hatti), o yuzden gomme Gemini'den alinir.
    public string EmbeddingModel { get; set; } = "gemini-embedding-001";

    /// <summary>
    /// 768 secildi. gemini-embedding-001 3072'ye kadar cikabiliyor ama
    /// outputDimensionality ile kisaltma destekleniyor (Matryoshka). 768:
    /// HNSW indeksini ~4 kat kucultur, geri cagirmadan olculebilir kayip vermez.
    /// DEGISTIRIRSEN sql/001_init.sql'deki vector(768) de degisir - ikisi birlikte.
    /// </summary>
    public int EmbeddingBoyut { get; set; } = 768;

    // --- Uretim (generation) ------------------------------------------------
    /// <summary>
    /// Depodaki olculmus uretim modeli. Opus 5'e gecmek tek satir: burayi degistir.
    /// </summary>
    public string UretimModel { get; set; } = "claude-sonnet-5";

    public int MaxTokens { get; set; } = 8000;

    // --- Es zamanlilik ------------------------------------------------------
    /// <summary>
    /// Task.WhenAll SINIRSIZ acilirsa 429 firtinasi olur. Bu sayi ayni anda
    /// ucacak istek tavanidir; hesabin dakikalik istek sinirina gore ayarla.
    /// </summary>
    public int EsZamanliIstek { get; set; } = 4;

    public int GommeYiginBoyu { get; set; } = 32;

    // --- Arama --------------------------------------------------------------
    public int AramaAdet { get; set; } = 6;
    public int AramaAdayHavuzu { get; set; } = 60;

    // --- Parcalama ----------------------------------------------------------
    /// <summary>Hedef parca boyu (karakter). SQL'deki CHECK tavani 8000.</summary>
    public int ParcaHedefBoy { get; set; } = 2200;

    /// <summary>Parcalar arasi bindirme: kesilen cumlenin baglami kaybolmasin.</summary>
    public int ParcaBindirme { get; set; } = 200;

    // --- Sirlar (yalniz ortamdan) ------------------------------------------
    public static string AnthropicApiKey =>
        Environment.GetEnvironmentVariable("ANTHROPIC_API_KEY")
        ?? throw new InvalidOperationException("ANTHROPIC_API_KEY ortam degiskeni yok.");

    public static string GeminiApiKey =>
        Environment.GetEnvironmentVariable("GEMINI_API_KEY")
        ?? throw new InvalidOperationException("GEMINI_API_KEY ortam degiskeni yok.");
}
