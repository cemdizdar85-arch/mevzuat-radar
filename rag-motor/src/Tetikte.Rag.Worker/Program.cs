using Anthropic;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Tetikte.Rag.Core;
using Tetikte.Rag.Worker;

var kurucu = Host.CreateApplicationBuilder(args);

// Ayar: appsettings.json + ortam degiskeni (ortam ustundur).
kurucu.Services
    .AddOptions<RagOptions>()
    .Bind(kurucu.Configuration.GetSection(RagOptions.Bolum))
    .Validate(a => !string.IsNullOrWhiteSpace(a.ConnectionString),
              "Rag:ConnectionString bos - appsettings.json ya da RAG__CONNECTIONSTRING ile ver.")
    .Validate(a => a.EmbeddingBoyut == 768,
              "Su an sema vector(768) ile kurulu. Boyutu degistirmek SQL gocu ister.")
    .ValidateOnStart();

// Ambar tekil: NpgsqlDataSource kendi havuzunu tasir, her istekte yeniden
// kurmak havuzu bosa cikarir.
kurucu.Services.AddSingleton<Ambar>();

// Gomme istemcisi: IHttpClientFactory uzerinden - soket tukenmesini onler.
kurucu.Services.AddHttpClient<IGommeIstemcisi, GeminiGommeIstemcisi>(h =>
{
    h.Timeout = TimeSpan.FromMinutes(3);
});

// Anthropic istemcisi tekil. Anahtar ortamdan okunur, kodda DURMAZ.
kurucu.Services.AddSingleton(_ => new AnthropicClient
{
    ApiKey = RagOptions.AnthropicApiKey
});

kurucu.Services.AddSingleton<YutmaServisi>();
kurucu.Services.AddSingleton<SoruUretici>();

kurucu.Services.AddHostedService<GommeIscisi>();
kurucu.Services.AddHostedService<SoruIscisi>();

var uygulama = kurucu.Build();

// ACILIS KAPISI: goc basili degilse motor HIC BASLAMAZ.
// Bu depoda 10.09'da olculdu - canlida hangi surumun kostugu bilinmedigi icin
// bir gun boyunca kosmayan bir fonksiyon ayarlandi. Bir daha olmayacak.
await using (var kapsam = uygulama.Services.CreateAsyncScope())
{
    var ambar = kapsam.ServiceProvider.GetRequiredService<Ambar>();
    var gunluk = kapsam.ServiceProvider.GetRequiredService<ILoggerFactory>().CreateLogger("Acilis");

    await ambar.GocDogrulaAsync("001_init", CancellationToken.None);
    gunluk.LogInformation("CANLI SEMA SURUMU: {Surum}", await ambar.CanliSurumAsync(CancellationToken.None));
}

// ============================================================================
//  KOMUT SATIRI MODU — kuyruğa girmeden tek iş çalıştırmak için.
//
//  NEDEN VAR: rag şeması PostgREST'ten erişilemiyor (ölçüldü: PGRST106), yani
//  kuyruğa iş eklemenin dışarıdan kolay bir yolu yok. Bu mod, yutma ve üretimi
//  doğrudan çalıştırır - aynı servisler, aynı kapılar, sadece kuyruk yok.
//
//    dotnet run -- yut  <kod> <ad> <tur> <metin-dosyasi>
//    dotnet run -- soru <ders> <konu1> [konu2] ...
//    dotnet run -- gomme            (vektörü eksik parçaları tamamlar)
//
//  Argümansız çalışırsa normal Worker olarak kuyruğu dinler.
// ============================================================================
if (args.Length > 0)
{
    await using var kapsam2 = uygulama.Services.CreateAsyncScope();
    var sp = kapsam2.ServiceProvider;
    var gunluk2 = sp.GetRequiredService<ILoggerFactory>().CreateLogger("Komut");

    switch (args[0].ToLowerInvariant())
    {
        case "yut":
        {
            if (args.Length < 5) { gunluk2.LogError("kullanim: yut <kod> <ad> <tur> <metin-dosyasi>"); return; }
            var metin = await File.ReadAllTextAsync(args[4]);
            gunluk2.LogInformation("YUTULUYOR: {Kod} ({Uzunluk:N0} karakter)", args[1], metin.Length);
            var yutma2 = sp.GetRequiredService<YutmaServisi>();
            var (parca, vektor) = await yutma2.BelgeYutAsync(args[1], args[2], args[3], null, metin, CancellationToken.None);
            gunluk2.LogInformation("BITTI: {Parca} yeni parça · {Vektor} vektör", parca, vektor);
            return;
        }
        case "gomme":
        {
            var yutma3 = sp.GetRequiredService<YutmaServisi>();
            var n = await yutma3.EksikVektorleriUretAsync(CancellationToken.None);
            gunluk2.LogInformation("BAKIM: {N} vektör tamamlandı", n);
            return;
        }
        case "soru":
        {
            if (args.Length < 3) { gunluk2.LogError("kullanim: soru <ders> <konu1> [konu2] ..."); return; }
            var ders = args[1];
            var istekler = args.Skip(2).Select(k => new SoruIstegi(ders, k, "zor", 3)).ToList();
            var uretici2 = sp.GetRequiredService<SoruUretici>();
            var sonuclar = await uretici2.TopluUretAsync(istekler, CancellationToken.None);
            foreach (var s in sonuclar)
                gunluk2.LogInformation("  parça {Parca} · {Adet} soru · {Hata}",
                    s.ParcaId, s.Sorular.Count, s.Hata ?? "-");
            return;
        }
        case "rapor":
        {
            // Uretilen sorulari OKUNUR metne cevirir. JSON insan icin degil;
            // kaliteyi goz denetleyecekse okunur bicim sart.
            var ambar2 = sp.GetRequiredService<Ambar>();
            var yol = args.Length > 1 ? args[1] : "sorular.txt";
            var n = await ambar2.SoruRaporuAsync(yol, CancellationToken.None);
            gunluk2.LogInformation("RAPOR: {N} soru -> {Yol}", n, Path.GetFullPath(yol));
            return;
        }
        default:
            gunluk2.LogError("bilinmeyen komut: {Komut}", args[0]);
            return;
    }
}

await uygulama.RunAsync();
