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
            // HER KONU UC ZORLUKTA uretilir: kolay + orta + zor.
            // Eskiden burada zorluk "zor" olarak SABITTI; ambardaki 35 sorunun
            // 35'i de 'zor' cikmisti, yani zorluk sutunu hic bilgi tasimiyordu.
            if (args.Length < 3) { gunluk2.LogError("kullanim: soru <ders> <konu1> [konu2] ..."); return; }
            var ders = args[1];
            var ayar3 = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<RagOptions>>().Value;
            var istekler = args.Skip(2)
                .Select(k => new KonuIstegi(ders, k, KonuIstegi.UcSeviye, ayar3.ZorlukBasinaAdet))
                .ToList();
            var uretici2 = sp.GetRequiredService<SoruUretici>();
            var sonuclar = await uretici2.TopluKonuUretAsync(istekler, CancellationToken.None);
            foreach (var s in sonuclar)
                gunluk2.LogInformation("  parça {Parca} · {Zorluk} · {Adet} soru · {Hata}",
                    s.ParcaId, s.Zorluk ?? "-", s.Sorular.Count, s.Hata ?? "-");
            return;
        }
        case "aramakarne":
        {
            // KART-KAPALI OLCUM: konu kartlarini DEVRE DISI birakip aramanin
            // KENDI gucunu olcer.
            //
            // NEDEN GEREKLI: kart acikken vektor kanalinin katkisi GORUNMEZ -
            // kart zaten dogru maddeyi veriyor, arama hic devreye girmiyor.
            // "Hibrit arama ise yariyor mu" sorusu ancak kart kapaliyken
            // cevaplanabilir. Beklenen madde konu kartindan OKUNUR ama arama
            // ona BAKMAZ; kart burada CETVELDIR, kilavuz degil.
            //
            //   dotnet run -- aramakarne <ders> <konu>=<beklenen madde> ...
            //   ornek: aramakarne 'Vergi Mevzuatı ve Uygulaması' 'supheli alacak karsiligi=m.323'
            if (args.Length < 3) { gunluk2.LogError("kullanim: aramakarne <ders> <konu>=<beklenen> ..."); return; }
            var ders2 = args[1];
            var ambar3 = sp.GetRequiredService<Ambar>();
            var gomme2 = sp.GetRequiredService<IGommeIstemcisi>();
            var ayar2 = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<RagOptions>>().Value;

            var isabet = 0; var toplam = 0;
            foreach (var cift in args.Skip(2))
            {
                var p = cift.Split('=', 2);
                if (p.Length != 2) continue;
                var konu2 = p[0]; var beklenen = p[1];
                toplam++;

                var sorgu2 = $"{ders2} {konu2}";
                // Gomme kapaliysa NULL gonderilir - SIFIR VEKTOR DEGIL.
                // Sifir vektor kanali kapatmaz, rastgele siralama uretip tam
                // metin kanalini asagi iter; boyle bir kiyas tam metnin hakkini
                // yer (bkz. sql/005_vektorsuz_arama.sql).
                float[]? vek = gomme2.Acik
                    ? await gomme2.SorguGomAsync(sorgu2, CancellationToken.None)
                    : null;

                var bulunan = await ambar3.AraAsync(sorgu2, vek, gomme2.Model,
                    ayar2.AramaAdet, ayar2.AramaAdayHavuzu, null, CancellationToken.None);

                var ilk = bulunan.FirstOrDefault();
                var tuttu = ilk is not null && (ilk.MaddeNo ?? "").Contains(beklenen, StringComparison.OrdinalIgnoreCase);
                if (tuttu) isabet++;

                gunluk2.LogInformation("{Durum} {Konu}: bekle {Bekle} -> {Bulunan}  (v-sira {V}, m-sira {M}, ilk5: {Ilk5})",
                    tuttu ? "ISABET" : "ISKA ", konu2, beklenen, ilk?.MaddeNo ?? "(bos)",
                    ilk?.VektorSira?.ToString() ?? "-", ilk?.MetinSira?.ToString() ?? "-",
                    string.Join(" | ", bulunan.Take(5).Select(b => b.MaddeNo ?? "?")));
            }
            gunluk2.LogInformation("ARAMA KARNESI: {Isabet}/{Toplam}  (gomme {Durum})",
                isabet, toplam, gomme2.Acik ? "ACIK - hibrit" : "KAPALI - yalniz tam metin");
            return;
        }
        case "goc":
        {
            // GOC BASMA: sql/*.sql dosyasini motorun kendi baglantisindan kosar.
            // Elle SQL editorune yapistirma donemi bitti - uc kez yanlis
            // pencereye yapistirildi, uc tur kaybedildi.
            if (args.Length < 2) { gunluk2.LogError("kullanim: goc <sql-dosyasi>"); return; }
            var ambar4 = sp.GetRequiredService<Ambar>();
            gunluk2.LogInformation("GOC BASILIYOR: {Yol}", Path.GetFullPath(args[1]));
            await ambar4.SqlDosyasiCalistirAsync(args[1], CancellationToken.None);
            gunluk2.LogInformation("GOC TAMAM · CANLI SURUM: {Surum}",
                await ambar4.CanliSurumAsync(CancellationToken.None));
            return;
        }
        case "olc":
        {
            // OLCUM AGZI (salt okunur). "Kac parca, kac vektor, indeks var mi"
            // sorulari tahminle degil bununla cevaplanir.
            //   dotnet run -- olc "select count(*) from rag.parca"
            if (args.Length < 2) { gunluk2.LogError("kullanim: olc \"<select ...>\""); return; }
            var ambar5 = sp.GetRequiredService<Ambar>();
            Console.WriteLine(await ambar5.OlcAsync(args[1], CancellationToken.None));
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
