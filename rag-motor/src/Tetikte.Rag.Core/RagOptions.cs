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

    /// <summary>
    /// Tek gomme cagrisindaki parca sayisi.
    /// OLCULDU (10.09): batchEmbedContents yigin icindeki HER PARCAYI ayri
    /// istek sayiyor. Yani yigin buyutmek kotayi korumaz - yalniz ag gidis
    /// donusunu azaltir. Kota dolunca da 32'lik yiginin tekrari 32 istek yer.
    /// 16: aglama ile kota israfi arasinda olculmus orta yol.
    /// </summary>
    public int GommeYiginBoyu { get; set; } = 16;

    /// <summary>
    /// Gomme yiginlari arasi bekleme (ms).
    /// OLCULDU (10.09): Gemini UCRETSIZ kotasi DAKIKALIK istek sinirlidir.
    /// Yiginlari arka arkaya atmak 429 uretiyor - hatayi ONLEMEK yerine
    /// URETIYOR. Polly 429'da retry-after'a uyup toparliyor ama her seferinde
    /// bir dakika kaybediliyor. Fren, o kaybi bastan onler.
    /// Ucretli kotaya gecilirse 0'a cekilebilir.
    /// </summary>
    public int GommeFrenMs { get; set; } = 9000;

    // --- Uretim tavani ------------------------------------------------------
    /// <summary>
    /// Bir parcadan cikabilecek EN COK soru. Ayni maddeden sinirsiz soru
    /// cikarsa havuz tekrara duser.
    /// 8 = uc seviyeye (kolay/orta/zor) ikiser-ucer soru dagitmaya yeter.
    /// </summary>
    public int MaddeTavani { get; set; } = 8;

    /// <summary>Uc seviyenin HER BIRINDEN istenen soru sayisi (varsayilan parti boyu).</summary>
    public int ZorlukBasinaAdet { get; set; } = 2;

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

    /// <summary>
    /// Gomme anahtari var mi? Yoksa motor COKMEZ: arama yalniz tam-metin
    /// kanalindan kosar (rag.ara'nin RRF'i full outer join oldugu icin bos
    /// vektor kanali sonucu bozmaz, sadece daraltir).
    /// Bilincli karar: gomme anahtari operasyonel bir eksiklik, mimari bir
    /// hata degil. Anahtar gelince vektor kanali kendiliginden acilir -
    /// tek yapilacak sey 'bakim kosusu' isi eklemektir.
    /// </summary>
    public static bool GommeAcik =>
        !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("GEMINI_API_KEY"));
}
