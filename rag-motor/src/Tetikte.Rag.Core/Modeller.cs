using System.Text.Json.Serialization;

namespace Tetikte.Rag.Core;

public sealed record Kaynak(long Id, string Kod, string Ad, string Tur);

/// <summary>Aramanin ve soru uretiminin birimi.</summary>
public sealed record Parca(
    long Id,
    long KaynakId,
    string? MaddeNo,
    string? Baslik,
    string Metin,
    int Sira);

/// <summary>Parcalayicidan cikan, henuz veritabanina yazilmamis parca.</summary>
public sealed record YeniParca(string? MaddeNo, string? Baslik, string Metin, int Sira);

/// <summary>Hibrit aramanin dondurdugu satir. <paramref name="Rrf"/> kanal siralarindan turer.</summary>
public sealed record AramaSonucu(
    long ParcaId,
    string KaynakAd,
    string KaynakKod,
    string? MaddeNo,
    string? Baslik,
    string Metin,
    double Rrf,
    int? VektorSira,
    int? MetinSira);

/// <summary>Uretim istegi: hangi ders/konu/zorlukta kac soru.</summary>
public sealed record SoruIstegi(string Ders, string Konu, string Zorluk, int Adet);

// --- Modelin dondurecegi JSON. Sema, structured output ile ZORLANIR --------
public sealed class UretilenSoru
{
    [JsonPropertyName("soru")]      public string Soru { get; set; } = "";
    [JsonPropertyName("siklar")]    public Siklar Siklar { get; set; } = new();
    [JsonPropertyName("dogru")]     public string Dogru { get; set; } = "";
    [JsonPropertyName("aciklama")]  public Siklar Aciklama { get; set; } = new();
    [JsonPropertyName("dayanak")]   public string Dayanak { get; set; } = "";
}

public sealed class Siklar
{
    [JsonPropertyName("A")] public string A { get; set; } = "";
    [JsonPropertyName("B")] public string B { get; set; } = "";
    [JsonPropertyName("C")] public string C { get; set; } = "";
    [JsonPropertyName("D")] public string D { get; set; } = "";
    [JsonPropertyName("E")] public string E { get; set; } = "";
}

public sealed class SoruPaketi
{
    [JsonPropertyName("sorular")] public List<UretilenSoru> Sorular { get; set; } = [];
}

/// <summary>Uretim sonucu + faturasi. Fatura HER ZAMAN tasinir - olculmeyen harcama yonetilemez.</summary>
public sealed record UretimSonucu(
    IReadOnlyList<UretilenSoru> Sorular,
    long ParcaId,
    string Model,
    int GirisJeton,
    int CikisJeton,
    string? Hata = null);
