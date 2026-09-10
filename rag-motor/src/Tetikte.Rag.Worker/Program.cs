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

await uygulama.RunAsync();
