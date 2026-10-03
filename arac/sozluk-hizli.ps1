# arac/sozluk-hizli.ps1 — Kaydır-Çöz Türkçe sözlüğünün SICAK DÖNGÜSÜ derlenmiş C#'ta (03.10.2026, Cem "1 ve 2 yap")
#
# NEDEN: motor/kaydir-coz.ps1 her basımda bütün soru partilerinden (03.10: 2.491 dosya) kelime sayıp Türkçe sözlük kurar.
#   04.09'da 36 partiyle 100 sn ölçülmüştü; parti sayısı 70 katına çıktı. Kelime başına PS'de 19 -creplace (Katla) +
#   iç içe hashtable artırımı: 03.10'da yerelde 70 soruluk vitrin basımı 2 saatte bitmedi, bulutta "Sayfalari bas"
#   adımı 43 dk sürüyordu (parti önbelleği her koşuda yeni olduğu için sözlük her yayında baştan kuruluyor).
#
# NE DEĞİŞİR: YALNIZ kaydir-coz.ps1'deki tek satır (kelime ayıkla -> katla -> say) bu C# işlevine gider. JSON okuma,
#   metin toplama, sözlükten SOZ/ENF/IVAR seçimi PS'de AYNEN kalır. Eşdeğerlik koşulları:
#   - Katla: aynı 19 harf eşlemesi + ToLowerInvariant (kaydir-coz.ps1 Katla ile karakter karakter aynı tablo)
#   - küçültme: ToLower(tr-TR) (PS'deki $w.ToLower([cultureinfo]::GetCultureInfo('tr-TR')))
#   - düzenli ifade: aynı desen, aynı (varsayılan) seçenekler
#   - iç sözlükler: PS @{} ile AYNI karşılaştırıcı (CultureAwareComparer = StringComparer.CurrentCultureIgnoreCase,
#     03.10 yansıtmayla ölçüldü) -> aynı anahtar birleşmesi ve aynı dolaşma sırası (SOZ/ENF seçimindeki eşitlik kırılımı buna bağlı)
# Eşdeğerlik provası: arac/sozluk-hizli-prova.ps1 (eski PS yolu ile yeni yolun SOZ/ENF/IVAR çıktısı bayt bayt aynı mı).
# GÖRMEZ: kaydir-coz.ps1 Katla tablosu değişirse burası kendiliğinden değişmez - prova bu yüzden her iki yolu da koşar.

if (-not ('TtSozluk' -as [type])) {
  Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Collections;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
public static class TtSozluk {
  static readonly Regex Rx = new Regex("[A-Za-zÇĞİÖŞÜçğıöşüÂâÎîÛû]{3,}");
  static readonly CultureInfo Tr = CultureInfo.GetCultureInfo("tr-TR");
  public static string Katla(string s) {
    if (s == null) s = "";
    StringBuilder sb = new StringBuilder(s.Length);
    foreach (char c in s) {
      switch (c) {
        case 'İ': case 'I': case 'ı': case 'Î': case 'î': sb.Append('i'); break;
        case 'Ğ': case 'ğ': sb.Append('g'); break;
        case 'Ü': case 'ü': case 'Û': case 'û': sb.Append('u'); break;
        case 'Ş': case 'ş': sb.Append('s'); break;
        case 'Ö': case 'ö': sb.Append('o'); break;
        case 'Ç': case 'ç': sb.Append('c'); break;
        case 'Â': case 'â': sb.Append('a'); break;
        default: sb.Append(c); break;
      }
    }
    return sb.ToString().ToLowerInvariant();
  }
  // PS karşılığı: foreach($m in [regex]::Matches($mt,...)){ $w=$m.Value; $lw=$w.ToLower(tr); $k=Katla $w;
  //   if(-not $SAY.ContainsKey($k)){ $SAY[$k]=@{} }; if(-not $SAY[$k].ContainsKey($lw)){ $SAY[$k][$lw]=0 }; $SAY[$k][$lw]++ }
  public static void Ekle(Hashtable say, string mt) {
    if (mt == null) return;
    foreach (Match m in Rx.Matches(mt)) {
      string w = m.Value; string lw = w.ToLower(Tr); string k = Katla(w);
      Hashtable h;
      if (!say.ContainsKey(k)) { h = new Hashtable(StringComparer.CurrentCultureIgnoreCase); say[k] = h; } else { h = (Hashtable)say[k]; }
      if (!h.ContainsKey(lw)) { h[lw] = 0; }
      h[lw] = (int)h[lw] + 1;
    }
  }
  // 03.10 (madde 1): sözlük ÖNBELLEĞİ sekmeli metin. Satır: "S<TAB>kök<TAB>biçim" | "E<TAB>kök<TAB>biçim" | "I<TAB>kök".
  // Anahtarlar düzenli ifadenin harf sınıfından gelir (sekme/satır sonu taşıyamaz). Tablolar PS'de @{} ile kurulur,
  // burada yalnız doldurulur (aynı karşılaştırıcı). PS'deki eski JSON yolu: ders başına 18 sn (2.491 parti, 03.10).
  public static void Yaz(string yol, Hashtable soz, Hashtable enf, Hashtable ivar) {
    StringBuilder sb = new StringBuilder();
    foreach (DictionaryEntry e in soz) sb.Append("S\t").Append((string)e.Key).Append('\t').Append(Convert.ToString(e.Value)).Append('\n');
    foreach (DictionaryEntry e in enf) sb.Append("E\t").Append((string)e.Key).Append('\t').Append(Convert.ToString(e.Value)).Append('\n');
    foreach (DictionaryEntry e in ivar) sb.Append("I\t").Append((string)e.Key).Append('\n');
    System.IO.File.WriteAllText(yol, sb.ToString(), new UTF8Encoding(false));
  }
  public static void Yukle(string yol, Hashtable soz, Hashtable enf, Hashtable ivar) {
    foreach (string sat in System.IO.File.ReadAllLines(yol, new UTF8Encoding(false))) {
      if (sat.Length < 3) continue;
      string[] p = sat.Split('\t');
      if (p[0] == "S" && p.Length == 3) soz[p[1]] = p[2];
      else if (p[0] == "E" && p.Length == 3) enf[p[1]] = p[2];
      else if (p[0] == "I" && p.Length == 2) ivar[p[1]] = true;
      else throw new Exception("sozluk onbellegi bozuk satir: " + sat);
    }
  }
}
'@
}
