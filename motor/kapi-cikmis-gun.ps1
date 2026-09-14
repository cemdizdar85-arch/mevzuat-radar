# ============================================================================
#  KAPI-CB ÇIKMIŞ CÜMLE BENZERLİĞİ + KAPI-GT GÜN TABANI   13.09.2026
#
#  NEDEN (Cem 13.09 "1.2.3 üçünü de yap", GM incelemesi smmm-gm-p1):
#   KAPI-CB: Denetim sorusunun (BDS 700) A ve C şıkları KGK 23.11.2024 SORU 26'nın
#   I-II öncülleriyle, B şıkkı KGK 19.11.2023 SORU 36 öncül II ile neredeyse kelimesi
#   kelimesine aynıydı; kod kapılarının hepsinden geçti. Sebep: KAPI-B (BenzerlikKusur)
#   yalnız SORU KÖKÜNÜ ve yalnız o konunun TEK çapasını karşılaştırıyor; şıklara,
#   öncüllere ve öteki sınavların (KGK/SGS/SMMM) çıkmışlarına hiç bakmıyordu.
#   Bu kapı sorunun kökünü, öncüllerini ve her şıkkı cümle cümle, ambardaki BÜTÜN
#   çıkmış soru metinleriyle (tur=cikmis-soru, üç sınav) karşılaştırır.
#   Benzerlik = ortak kelime / max(bizim kelime, çıkmış kelime) (katlanmış, >=2 harf).
#   Cümle en az 8 kelime değilse karşılaştırılmaz ("Yalnız I" gibi şıklar).
#   Karar: aynı çıkmış soruyla >= $KCB_ESIK benzer cümle sayısı $KCB_SERT_ADET ve üstüyse
#   SERT (yeniden paketlenmiş çıkmış soru); tek cümle ise NOT (kanun cümlesini aynen
#   alan her iki soruda da doğal olarak görülür; eşik 13.09 provasıyla seçildi,
#   bkz. veri/kapi-cikmis-gun-provasi.md).
#
#   KAPI-GT: FTA sorusu stokta kalma süresini 365 günle hesapladı ama soruda gün
#   tabanı yazmıyordu. Ölçüm (13.09, ambar çıkmışları): tabanı açıkça yazan 51
#   ifadenin 47'si 360 (SMMM 3/3, SGS 10/10, KGK 34/38), 4'ü 365 (yalnız KGK 2025);
#   gerçek sınav tabanı HER ZAMAN soruda yazar. Çözüm (açıklama, çeldirici yolu,
#   çözüm tablosu, adımlar) 360/365 ile bölüyor/çarpıyorsa soru kökü aynı tabanı
#   "360 gün" / "365 gün" diye söylemeli; söylemiyorsa ya da başka taban diyorsa SERT.
#
#  Kullanan: motor/kalip-parti-uret.ps1 (FAZ A + FAZ GM) · arac/kapi-cikmis-gun-provasi.ps1
#  Ambar çekilemezse KAPI-CB KÖR kalır ve bunu söyler (sessizce geçmez).
# ============================================================================
$KCB_ESIK = 0.80
$KCB_SERT_ADET = 2

if (-not ('KapiCikmisDizin' -as [type])) {
Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

public class KapiCikmisDizin {
  List<HashSet<string>> seg = new List<HashSet<string>>();
  List<int> segBirim = new List<int>();
  Dictionary<string, List<int>> ilan = new Dictionary<string, List<int>>();
  public List<string> Birimler = new List<string>();
  public const int MinKelime = 8;
  static readonly Regex Bol = new Regex(@"(?<=[.?!;])\s+|\s+(?=[A-E]\)\s)|\s+(?=(?:I|II|III|IV|V|VI)\.\s)|\n+", RegexOptions.Compiled);
  static readonly Regex SoruBol = new Regex(@"(?=SORU \d+\s*:)", RegexOptions.Compiled);
  static readonly Regex SoruBas = new Regex(@"^SORU (\d+)\s*:", RegexOptions.Compiled);

  public static string Katla(string s) {
    if (s == null) return "";
    StringBuilder sb = new StringBuilder(s.Length);
    foreach (char c0 in s) {
      char c = c0;
      switch (c) {
        case 'ç': case 'Ç': c = 'c'; break;
        case 'ğ': case 'Ğ': c = 'g'; break;
        case 'ı': case 'I': case 'İ': case 'î': case 'Î': c = 'i'; break;
        case 'ö': case 'Ö': c = 'o'; break;
        case 'ş': case 'Ş': c = 's'; break;
        case 'ü': case 'Ü': case 'û': case 'Û': c = 'u'; break;
        case 'â': case 'Â': c = 'a'; break;
        case '̇': continue;
      }
      c = char.ToLowerInvariant(c);
      sb.Append((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') ? c : ' ');
    }
    return sb.ToString();
  }
  public static HashSet<string> Kume(string s) {
    HashSet<string> k = new HashSet<string>();
    foreach (string w in Katla(s).Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries)) { if (w.Length >= 2) k.Add(w); }
    return k;
  }
  public static string[] Parcala(string s) { return Bol.Split(s ?? ""); }
  public static int KelimeSayisi(string s) { return Kume(s).Count; }
  public int SegmentSayisi { get { return seg.Count; } }

  public void BelgeEkle(string ad, string metin) {
    if (string.IsNullOrEmpty(metin)) return;
    string duz = Regex.Replace(metin, @"[ \t\r\f]+", " ");
    foreach (string p in SoruBol.Split(duz)) {
      Match m = SoruBas.Match(p);
      if (!m.Success) continue;
      int birim = Birimler.Count;
      Birimler.Add(ad + " · SORU " + m.Groups[1].Value);
      foreach (string c in Parcala(p.Substring(m.Length))) {
        HashSet<string> k = Kume(c);
        if (k.Count < MinKelime) continue;
        int sid = seg.Count; seg.Add(k); segBirim.Add(birim);
        foreach (string w in k) { List<int> l; if (!ilan.TryGetValue(w, out l)) { l = new List<int>(); ilan[w] = l; } l.Add(sid); }
      }
    }
  }
  // 13.09 SMMM klasik (yazılı) sınav: "SORU n" işareti düzensiz; soru kısmı işaretlerden parçalara bölünür, işaret yoksa tek parça
  static readonly Regex KlasikBol = new Regex(@"(?=\b(?:SORU|Soru)\s*\d+|(?<![\d.,])\d\s*-\s*\))", RegexOptions.Compiled);
  public void BelgeEkleKlasik(string ad, string soruKismi) {
    if (string.IsNullOrEmpty(soruKismi)) return;
    string duz = Regex.Replace(soruKismi, @"\s+", " ");
    int n = 0;
    foreach (string p in KlasikBol.Split(duz)) {
      if (p.Trim().Length < 40) continue;
      n++; int birim = Birimler.Count; Birimler.Add(ad + " · klasik parça " + n.ToString(CultureInfo.InvariantCulture));
      foreach (string c in Parcala(p)) {
        HashSet<string> k = Kume(c);
        if (k.Count < MinKelime) continue;
        int sid = seg.Count; seg.Add(k); segBirim.Add(birim);
        foreach (string w in k) { List<int> l; if (!ilan.TryGetValue(w, out l)) { l = new List<int>(); ilan[w] = l; } l.Add(sid); }
      }
    }
  }
  int Df(string w) { List<int> l; return ilan.TryGetValue(w, out l) ? l.Count : 0; }

  // Dönüş: "probIndex<TAB>birim<TAB>benzerlik" (her prob için her birimde en yüksek benzerlik, esik ve üstü)
  public List<string> Ara(string[] problar, double esik) {
    List<string> sonuc = new List<string>();
    for (int i = 0; i < problar.Length; i++) {
      HashSet<string> P = Kume(problar[i]);
      if (P.Count < MinKelime) continue;
      List<string> sirali = new List<string>(P);
      sirali.Sort(delegate (string a, string b) { return Df(a).CompareTo(Df(b)); });
      // benzerlik >= esik ise P'nin en fazla floor((1-esik)|P|) kelimesi ortak DEĞİLDİR → en nadir floor(..)+1 kelimeden biri mutlaka ortaktır
      int kac = (int)Math.Floor((1.0 - esik) * P.Count) + 1; if (kac > sirali.Count) kac = sirali.Count;
      HashSet<int> aday = new HashSet<int>();
      for (int j = 0; j < kac; j++) { List<int> l; if (ilan.TryGetValue(sirali[j], out l)) foreach (int s in l) aday.Add(s); }
      Dictionary<int, double> enIyi = new Dictionary<int, double>();
      foreach (int s in aday) {
        HashSet<string> S = seg[s]; int ortak = 0;
        foreach (string w in P) if (S.Contains(w)) ortak++;
        double b = (double)ortak / Math.Max(P.Count, S.Count);
        if (b >= esik) { int bi = segBirim[s]; double eski; if (!enIyi.TryGetValue(bi, out eski) || b > eski) enIyi[bi] = b; }
      }
      foreach (KeyValuePair<int, double> kv in enIyi) sonuc.Add(i.ToString(CultureInfo.InvariantCulture) + "\t" + Birimler[kv.Key] + "\t" + kv.Value.ToString("0.00", CultureInfo.InvariantCulture));
    }
    return sonuc;
  }
}
'@
}

$script:CIKMIS_DIZIN = $null
$script:CIKMIS_DIZIN_KOR = ''
$script:KCB_KLASIK_SMMM = $false   # 13.09: üretici $Sinav -eq 'SMMM' iken açar (klasik SMMM soru kısmı dizine); varsayılan kapalı → SGS/KGK dizini aynı
# 14.09 KAPI-CB DİSK ÖNBELLEĞİ (Cem, paralel hat notu: "253 belgeyi günde bir kez indirip diskten okusun; paralel hatlarda en büyük
# süre kazancı bu"). ÖLÇÜLDÜ (pilot 1309 günlükleri): her parti CikmisDiziniKur'da çıkmış soruları (tur=cikmis-soru) ve bitirmede klasik
# SMMM belgelerini ambardan BAŞTAN indiriyordu; 3 paralel partide aynı indirme aynı anda üç kez.
# Kural: ambar sayfalarının HAM JSON gövdesi günde bir kez yerel diske (OneDrive DIŞI: %LOCALAPPDATA%\tetikte\cikmis-onbellek\<anahtar>-<gün>)
# yazılır, gün içindeki bütün koşular oradan okur. Okuyan kod gövdeyi ağdan gelmiş gibi AYNI ConvertFrom-Json yolundan geçirir → dizin
# birebir aynı. Aynı gün paralel partilerden yalnız biri indirir (makine çapında Mutex), ötekiler bekleyip diskten okur. İndirme yarıda
# düşerse klasör silinir ve hata eskisi gibi yukarı atılır (KAPI-CB KÖR). TAMAM işareti olmayan klasör okunmaz. Eski günlerin klasörü silinir.
# Bedel: gün içinde ambarda yeni çıkmış belge eklenirse kapı onu ertesi gün görür (Cem'in istediği "günde bir kez").
function CikmisOnbellekDizini([string]$anahtar) {
  $kokD = $(if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'tetikte' } else { [IO.Path]::GetTempPath() })
  return (Join-Path (Join-Path $kokD 'cikmis-onbellek') ("$anahtar-" + (Get-Date -Format 'yyyyMMdd')))
}
function CikmisSayfalariOku([string]$anahtar, [string]$adresTaban, $basliklar) {
  $dizinD = CikmisOnbellekDizini $anahtar
  $tamamYol = Join-Path $dizinD 'TAMAM'
  $kilit = $null; $sahip = $false
  try {
    if (-not (Test-Path $tamamYol)) {
      $kilit = New-Object System.Threading.Mutex($false, "Global\tetikte-cikmis-onbellek-$anahtar")
      try { $sahip = $kilit.WaitOne(900000) } catch [System.Threading.AbandonedMutexException] { $sahip = $true }
    }
    $sayfalar = New-Object System.Collections.Generic.List[string]
    $yazabilir = ($sahip -or -not $kilit)   # kilidi 15 dk bekleyip ALAMAYAN parti diske DOKUNMAZ (öteki indirirken klasörü silmesin); yalnız ağdan okur
    if (Test-Path $tamamYol) {
      foreach ($dosyaS in @(Get-ChildItem $dizinD -Filter 'sayfa-*.json' | Sort-Object Name)) { $sayfalar.Add([IO.File]::ReadAllText($dosyaS.FullName, [Text.UTF8Encoding]::new($false))) }
      Write-Host "  KAPI-CB disk önbelleği ($anahtar): $($sayfalar.Count) sayfa diskten okundu" -ForegroundColor DarkGray
      return , $sayfalar
    }
    if ($yazabilir) { if (Test-Path $dizinD) { Remove-Item $dizinD -Recurse -Force }; New-Item -ItemType Directory -Force $dizinD | Out-Null }
    else { Write-Host "  KAPI-CB disk önbelleği ($anahtar): indirme kilidi 15 dk içinde alınamadı → bu koşu yalnız ağdan okuyor, diske yazmıyor" -ForegroundColor DarkYellow }
    $ofsD = 0
    try {
      while ($true) {
        $adrD = $adresTaban + $ofsD
        $yanitD = $null
        for ($denD = 1; $denD -le 3; $denD++) { try { $yanitD = Invoke-WebRequest -Uri $adrD -Headers $basliklar -UseBasicParsing -TimeoutSec 180; break } catch { if ($denD -eq 3) { throw }; Start-Sleep -Seconds (5 * $denD) } }
        $icerikD = $yanitD.Content
        if ($yazabilir) { [IO.File]::WriteAllText((Join-Path $dizinD ('sayfa-{0:D4}.json' -f $sayfalar.Count)), $icerikD, [Text.UTF8Encoding]::new($false)) }
        $sayfalar.Add($icerikD)
        $adetD = @((ConvertFrom-Json -InputObject $icerikD)).Count
        $ofsD += $adetD
        if ($adetD -lt 40) { break }
      }
    } catch { if ($yazabilir) { Remove-Item $dizinD -Recurse -Force -ErrorAction SilentlyContinue }; throw }
    if (-not $yazabilir) { return , $sayfalar }
    [IO.File]::WriteAllText($tamamYol, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), [Text.UTF8Encoding]::new($false))
    foreach ($eskiD in @(Get-ChildItem (Split-Path $dizinD -Parent) -Directory -Filter "$anahtar-*" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -ne $dizinD })) { Remove-Item $eskiD.FullName -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Host "  KAPI-CB disk önbelleği ($anahtar): ambardan indirildi, $($sayfalar.Count) sayfa diske yazıldı" -ForegroundColor DarkGray
    return , $sayfalar
  } finally { if ($sahip) { try { $kilit.ReleaseMutex() } catch {} }; if ($kilit) { $kilit.Dispose() } }
}

function CikmisDiziniKur($basliklar) {
  if ($null -ne $script:CIKMIS_DIZIN -or $script:CIKMIS_DIZIN_KOR) { return $script:CIKMIS_DIZIN }
  $dizinYeni = New-Object KapiCikmisDizin
  $belgeSay = 0; $ofs = 0
  try {
    # 14.09: sayfalar günlük disk önbelleğinden (ağdan aynı sorgu, aynı sıra; gövde aynı ConvertFrom-Json yolundan geçer)
    foreach ($icerikSayfa in (CikmisSayfalariOku 'cikmis-soru' 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&tur=eq.cikmis-soru&order=id.asc&limit=40&offset=' $basliklar)) {
      $satirlar = @((ConvertFrom-Json -InputObject $icerikSayfa))
      foreach ($st in $satirlar) { if ($st) { $dizinYeni.BelgeEkle("$($st.kaynak_ad)", "$($st.metin)"); $belgeSay++ } }
      $ofs += $satirlar.Count
    }
  } catch { $script:CIKMIS_DIZIN_KOR = "ambar çekilemedi: $($_.Exception.Message)"; Write-Host "  KAPI-CB KÖR: $($script:CIKMIS_DIZIN_KOR)" -ForegroundColor Red; return $null }
  if ($belgeSay -lt 100) { $script:CIKMIS_DIZIN_KOR = "ambardan yalnız $belgeSay çıkmış belge geldi (beklenen >= 100)"; Write-Host "  KAPI-CB KÖR: $($script:CIKMIS_DIZIN_KOR)" -ForegroundColor Red; return $null }
  # 13.09 Cem "1. yap" (klasik→test dönüştürme): SMMM koşusunda klasik (yazılı) SMMM sınavlarının SORU KISMI da dizine girer
  # (komisyon cevabı kısmı girmez: kanun alıntısı gürültüsü). Yalnız $KCB_KLASIK_SMMM açıkken; SGS/KGK koşusunda dizin AYNI.
  if ($script:KCB_KLASIK_SMMM) {
    $klasikSay = 0; $ofsK = 0
    try {
      # 14.09: sayfalar günlük disk önbelleğinden (ağdan aynı sorgu, aynı sıra)
      foreach ($icerikK in (CikmisSayfalariOku 'cikmis-klasik-smmm' ('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&tur=eq.cikmis-komisyon-cevabi&kaynak_ad=ilike.' + [uri]::EscapeDataString('%smmm_%') + '&order=id.asc&limit=40&offset=') $basliklar)) {
        $satirK = @((ConvertFrom-Json -InputObject $icerikK))
        foreach ($stK in $satirK) {
          if (-not $stK) { continue }
          $metinK = ("$($stK.metin)" -replace '\s+', ' ')
          if (-not [regex]::IsMatch($metinK, '\bSORULAR\b|\bSORU\s*\d+|\bSoru\s*\d+|(?<![\d.,])\d\s*-\s*\)|İSTENİLEN|İstenilen|hesaplayınız|yapınız|açıklayınız|yazınız|belirtiniz')) { continue }   # yalnız cevap belgesi
          $cevapK = [regex]::Match($metinK, '\bCEVAPLAR\b|\bCEVAP\s*1\b|\bCevap\s*1\b|\bYANITLAR\b')
          $soruK = $(if ($cevapK.Success) { $metinK.Substring(0, $cevapK.Index) } else { $metinK })
          $dizinYeni.BelgeEkleKlasik("$($stK.kaynak_ad)", $soruK); $klasikSay++
        }
        $ofsK += $satirK.Count
      }
      Write-Host "  KAPI-CB klasik SMMM soru kısmı dizine eklendi: $klasikSay belge" -ForegroundColor DarkGray
    } catch { Write-Host "  KAPI-CB klasik SMMM eklenemedi (test dizini yine çalışır, klasik KÖR): $($_.Exception.Message)" -ForegroundColor Red }
  }
  Write-Host "  KAPI-CB çıkmış cümle dizini: $belgeSay belge · $($dizinYeni.Birimler.Count) soru · $($dizinYeni.SegmentSayisi) cümle" -ForegroundColor DarkGray
  $script:CIKMIS_DIZIN = $dizinYeni
  return $dizinYeni
}

# İç içe alan (string / dizi / nesne) → düz metin
function KcgMetin($deger) {
  if ($null -eq $deger) { return '' }
  if ($deger -is [string]) { return $deger }
  if ($deger -is [System.Collections.IEnumerable]) { return ((@($deger) | ForEach-Object { KcgMetin $_ }) -join ' ') }
  if ($deger -is [psobject] -and $deger.PSObject.Properties.Count) { return ((@($deger.PSObject.Properties) | ForEach-Object { KcgMetin $_.Value }) -join ' ') }
  return "$deger"
}

# Sorunun karşılaştırılacak cümleleri: kök (öncül satırları dahil) + her şık.
# 13.09 PROVA (986 parti / 6.856 soru) iki yanlış alarm sınıfı gösterdi, ikisi prob dışı:
#  (1) SORU CÜMLESİ: "…yapacağı muhasebe kaydı aşağıdakilerden hangisidir?" her sınavda aynı kalıptır, kopya değildir.
#  (2) YEVMİYE SATIRI: "770 GENEL YÖNETİM GİDERLERİ 150.000 / 360 ÖDENECEK VERGİ…" hesap kodu + resmî hesap adı + tutar; kelimeleri
#      Tekdüzen Hesap Planı'ndan gelir, her kayıt sorusunda benzer. Hesap kodlu ya da sayı ağırlıklı (>= %30) parça karşılaştırılmaz.
function CikmisProbUygun([string]$parca) {
  if ([KapiCikmisDizin]::KelimeSayisi($parca) -lt [KapiCikmisDizin]::MinKelime) { return $false }
  if ($parca -match '(?i)hangisi|hangileri|kaçtır|kaç\s+(TL|₺|gün|yıl|ay|adet|birim|puan)|aşağıdaki(ler)?\s|yukarıdaki') { return $false }
  if ($parca -cmatch '(?<![\d.,])[1-7]\d{2}\s+[A-ZÇĞİÖŞÜ][a-zçğıöşüA-ZÇĞİÖŞÜ]') { return $false }
  $kelimeler = @(([KapiCikmisDizin]::Katla($parca)) -split '\s+' | Where-Object { $_.Length -ge 1 })
  $sayilar = @($kelimeler | Where-Object { $_ -match '^\d+$' })
  if ($kelimeler.Count -and ($sayilar.Count / $kelimeler.Count) -ge 0.30) { return $false }
  return $true
}
function CikmisProblar($soruNesne) {
  $liste = New-Object System.Collections.Generic.List[string]
  foreach ($parca in [KapiCikmisDizin]::Parcala("$($soruNesne.soru)")) { if (CikmisProbUygun $parca) { $liste.Add($parca.Trim()) } }
  if ($soruNesne.siklar) {
    foreach ($harf in 'A', 'B', 'C', 'D', 'E') {
      foreach ($parca in [KapiCikmisDizin]::Parcala("$($soruNesne.siklar.$harf)")) { if (CikmisProbUygun $parca) { $liste.Add($parca.Trim()) } }
    }
  }
  return , $liste.ToArray()
}

# Dönüş: kusur (sert) · not (tek cümle) · kor · isabet (ham satırlar, prova için)
function CikmisCumleKapisi($soruNesne, $basliklar) {
  $sonucNesne = [pscustomobject]@{ kusur = @(); not = @(); kor = ''; isabet = @() }
  if (-not $soruNesne -or -not $soruNesne.soru) { return $sonucNesne }
  $dz = CikmisDiziniKur $basliklar
  if (-not $dz) { $sonucNesne.kor = $script:CIKMIS_DIZIN_KOR; return $sonucNesne }
  $problar = CikmisProblar $soruNesne
  if (-not $problar.Count) { return $sonucNesne }
  $hamIsabet = @($dz.Ara($problar, $KCB_ESIK))
  $sonucNesne.isabet = $hamIsabet
  if (-not $hamIsabet.Count) { return $sonucNesne }
  $birimProb = @{}; $birimEnYuksek = @{}
  foreach ($satirIsabet in $hamIsabet) {
    $pr = $satirIsabet -split "`t"
    if (-not $birimProb.ContainsKey($pr[1])) { $birimProb[$pr[1]] = @{}; $birimEnYuksek[$pr[1]] = 0.0 }
    $birimProb[$pr[1]][[int]$pr[0]] = 1
    $bn = [double]::Parse($pr[2], [Globalization.CultureInfo]::InvariantCulture); if ($bn -gt $birimEnYuksek[$pr[1]]) { $birimEnYuksek[$pr[1]] = $bn }
  }
  foreach ($birimAd in @($birimProb.Keys | Sort-Object { - $birimProb[$_].Count }, { $_ })) {
    $adet = $birimProb[$birimAd].Count
    $ornekCumle = $problar[@($birimProb[$birimAd].Keys | Sort-Object)[0]]; if ($ornekCumle.Length -gt 90) { $ornekCumle = $ornekCumle.Substring(0, 90) + '…' }
    $yazi = "$birimAd ile $adet cümle %$([int]($KCB_ESIK*100))+ aynı (en yüksek $($birimEnYuksek[$birimAd].ToString('0.00',[Globalization.CultureInfo]::InvariantCulture)); ör. '$ornekCumle')"
    if ($adet -ge $KCB_SERT_ADET) { $sonucNesne.kusur += $yazi } else { $sonucNesne.not += $yazi }
  }
  # aynı çıkmış soru A/B kitapçıkta iki kez bulunur: rapor kısa kalsın
  $sonucNesne.kusur = @($sonucNesne.kusur | Select-Object -First 2)
  $sonucNesne.not = @($sonucNesne.not | Select-Object -First 2)
  return $sonucNesne
}

# KAPI-GT: çözüm 360/365 ile hesaplıyorsa soru kökü aynı tabanı yazmalı
# 13.09 PROVA: yevmiye satırındaki "150.000 / 360 ÖDENECEK VERGİ VE FONLAR" hesap kodu gün tabanı sanılıyordu → sayıdan sonra büyük harfle
# başlayan kelime (hesap adı) gelirse kullanım sayılmaz.
function GunTabaniKullanimi([string]$metin) {
  return @([regex]::Matches($metin, '(?<![\d.,])(360|365)(?!\s+[A-ZÇĞİÖŞÜ])\s*[/÷×xX\*]|[/÷×xX\*]\s*(360|365)(?![\d.,])(?!\s+[A-ZÇĞİÖŞÜ])') | ForEach-Object { if ($_.Groups[1].Success) { $_.Groups[1].Value } else { $_.Groups[2].Value } } | Select-Object -Unique)
}
function GunTabaniKapisi($soruNesne, $adimListe) {
  $cikti = @()
  if (-not $soruNesne) { return $cikti }
  $tabloMetin = $(if ($soruNesne.PSObject.Properties['cozum_tablo']) { KcgMetin $soruNesne.cozum_tablo } else { '' })
  $tumMetin = (KcgMetin $soruNesne.aciklama) + ' ' + $(if ($soruNesne.PSObject.Properties['celdirici_yol']) { KcgMetin $soruNesne.celdirici_yol } else { '' }) + ' ' + $tabloMetin
  $dogruAdimMetin = ''
  foreach ($adimTek in @($adimListe)) {
    if ($adimTek -and $adimTek.PSObject.Properties['formul']) {
      $tumMetin += ' ' + "$($adimTek.formul)"
      if ("$($adimTek.formul)" -notmatch 'HATALI') { $dogruAdimMetin += ' ' + "$($adimTek.formul)" }
    }
  }
  $kullanilan = @(GunTabaniKullanimi $tumMetin)
  if (-not $kullanilan.Count) { return $cikti }
  $yazilan = @([regex]::Matches("$($soruNesne.soru)", '(?<![\d.,])(360|365)\s*gün') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
  if (-not $yazilan.Count) { return @("çözüm yılı $($kullanilan -join '/') gün alıyor ama soru kökünde gün tabanı yazmıyor ('1 yıl $($kullanilan[0]) gün kabul edilecektir')") }
  # Taban yazılıysa yalnız DOĞRU yol denetlenir: yanlış tabanı kullanan çeldirici (bilerek yanlış) meşrudur.
  $dogruHarf = "$($soruNesne.dogru)"
  $dogruMetin = $(if ($dogruHarf -and $soruNesne.aciklama -and $soruNesne.aciklama.PSObject.Properties[$dogruHarf]) { KcgMetin $soruNesne.aciklama.$dogruHarf } else { '' }) + ' ' + $tabloMetin + ' ' + $dogruAdimMetin
  foreach ($gunTaban in @(GunTabaniKullanimi $dogruMetin)) { if ($yazilan -notcontains $gunTaban) { $cikti += "soru kökü $($yazilan -join '/') gün diyor, doğru çözüm $gunTaban gün kullanıyor" } }
  return $cikti
}

# ============================================================================
#  PARA BİRİMİ = SON İKİ SINAVIN KULLANDIĞI   13.09.2026
#  Cem 13.09: "sınavda çıkanlara bak, son iki sınava ne çıktıysa o para birimini kullan".
#  Ölçüm (ambar çıkmışları, 13.09): SMMM 2026/1+2026/2 ₺ 423 · TL 2 | SGS 2026/1+2026/2 ₺ 296 · TL 0 |
#  KGK 2025 Kasım + 2026 ₺ 0 · TL 800. Karar HER KOŞUDA yeniden ölçülür (yeni dönem gelirse kendiliğinden döner).
#  UYGULAMA ALANI: yalnız $PARA_BIRIMI_UYGULANAN'daki sınavlar. SGS ölçümü de ₺ ama SGS bankası (6.477 soru) TL ile
#  basıldı; SGS'ye geçiş karışık banka yaratır → SGS kararı Cem'de. Listede olmayan sınavda ağ çağrısı YOK, birim TL (davranış aynı).
# ============================================================================
$PARA_BIRIMI_UYGULANAN = @('SMMM')
$PARA_TL_DESENI = '(?<![A-Za-zÇĞİÖŞÜçğıöşü])TL(?![A-Za-zÇĞİÖŞÜçğıöşü])'

# Çıkmış belge adından sıralanabilir dönem anahtarı: SMMM/SGS yıl*100+dönem, KGK yıl*100+ay
function CikmisDonemBilgi([string]$belgeAd) {
  $mt = [regex]::Match($belgeAd, 'smmm_(20[0-3]\d)_(\d)_'); if ($mt.Success) { return @{ anahtar = [int]$mt.Groups[1].Value * 100 + [int]$mt.Groups[2].Value; etiket = "$($mt.Groups[1].Value)/$($mt.Groups[2].Value)" } }
  $mt = [regex]::Match($belgeAd, 'SGS (20[0-3]\d)/(\d)'); if ($mt.Success) { return @{ anahtar = [int]$mt.Groups[1].Value * 100 + [int]$mt.Groups[2].Value; etiket = "$($mt.Groups[1].Value)/$($mt.Groups[2].Value)" } }
  $ayTablo = @{ ocak = 1; subat = 2; mart = 3; nisan = 4; mayis = 5; haziran = 6; temmuz = 7; agustos = 8; eylul = 9; ekim = 10; kasim = 11; aralik = 12 }
  $mt = [regex]::Match($belgeAd, '(\d{1,2})_([A-Za-zÇĞİÖŞÜçğıöşü]+)_(20[0-3]\d)')
  if ($mt.Success) { $ayKatli = ([KapiCikmisDizin]::Katla($mt.Groups[2].Value)).Trim(); if ($ayTablo.ContainsKey($ayKatli)) { return @{ anahtar = [int]$mt.Groups[3].Value * 100 + $ayTablo[$ayKatli]; etiket = "$($mt.Groups[3].Value) $($mt.Groups[2].Value)" } } }
  return $null
}

function SinavParaBirimi([string]$sinavAdi, $basliklar) {
  $pbSonuc = [pscustomobject]@{ birim = 'TL'; olculen = ''; kanit = ''; uygulandi = $false }
  if ($PARA_BIRIMI_UYGULANAN -notcontains $sinavAdi) { $pbSonuc.kanit = "$sinavAdi için uygulanmıyor (karar yalnız: $($PARA_BIRIMI_UYGULANAN -join ', '))"; return $pbSonuc }
  $donemSayim = @{}; $ofs = 0
  try {
    while ($true) {
      $adr = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&tur=eq.cikmis-soru&kaynak_ad=ilike.' + [uri]::EscapeDataString("CIKMIS SINAV - $sinavAdi %") + '&order=id.asc&limit=40&offset=' + $ofs
      $sayfaYanit = Invoke-WebRequest -Uri $adr -Headers $basliklar -UseBasicParsing -TimeoutSec 180
      $sayfaSatir = @((ConvertFrom-Json -InputObject $sayfaYanit.Content))
      foreach ($st in $sayfaSatir) {
        if (-not $st) { continue }
        $bilgi = CikmisDonemBilgi "$($st.kaynak_ad)"; if (-not $bilgi) { continue }
        if (-not $donemSayim.ContainsKey($bilgi.anahtar)) { $donemSayim[$bilgi.anahtar] = @{ etiket = $bilgi.etiket; lira = 0; tl = 0 } }
        $donemSayim[$bilgi.anahtar].lira += ([regex]::Matches("$($st.metin)", '₺')).Count
        $donemSayim[$bilgi.anahtar].tl += ([regex]::Matches("$($st.metin)", $PARA_TL_DESENI)).Count
      }
      $ofs += $sayfaSatir.Count
      if ($sayfaSatir.Count -lt 40) { break }
    }
  } catch { $pbSonuc.kanit = "KÖR: ambar çekilemedi ($($_.Exception.Message)) — varsayılan TL"; return $pbSonuc }
  if ($donemSayim.Count -lt 2) { $pbSonuc.kanit = "KÖR: $sinavAdi için dönemli çıkmış $($donemSayim.Count) (en az 2 gerek) — varsayılan TL"; return $pbSonuc }
  $sonIki = @($donemSayim.Keys | Sort-Object -Descending | Select-Object -First 2)
  $liraTop = 0; $tlTop = 0; $etiketler = @()
  foreach ($anh in $sonIki) { $liraTop += $donemSayim[$anh].lira; $tlTop += $donemSayim[$anh].tl; $etiketler += $donemSayim[$anh].etiket }
  $pbSonuc.olculen = $(if ($liraTop -gt $tlTop) { '₺' } else { 'TL' })
  $pbSonuc.kanit = "son iki dönem $($etiketler -join ' + '): ₺ $liraTop · TL $tlTop"
  $pbSonuc.birim = $pbSonuc.olculen; $pbSonuc.uygulandi = $true
  return $pbSonuc
}

# Soru nesnesinde para birimi "TL" → "₺" (yerinde). Kanun/çıkmış alıntısı ve hakem kayıtları DOKUNULMAZ.
$PARA_DOKUNULMAZ_ALAN = @('dayanak', 'capa_metin', 'capa_kaynak', 'kaynak_metin_ozet', 'kaynak_adlar', 'atif_genisletme', 'hakem', 'hakem2', 'kor_cozum', 'gm_kapi')
function ParaBirimiOnar($deger, [string]$hedefBirim) {
  if ($hedefBirim -ne '₺' -or $null -eq $deger) { return $deger }
  if ($deger -is [string]) { return [regex]::Replace($deger, $PARA_TL_DESENI, '₺') }
  if ($deger -is [System.Collections.IList]) { for ($ix = 0; $ix -lt $deger.Count; $ix++) { $deger[$ix] = ParaBirimiOnar $deger[$ix] $hedefBirim }; return , $deger }
  if ($deger -is [System.Management.Automation.PSCustomObject]) {
    foreach ($pr in @($deger.PSObject.Properties)) { if ($PARA_DOKUNULMAZ_ALAN -contains $pr.Name) { continue }; $pr.Value = ParaBirimiOnar $pr.Value $hedefBirim }
    return $deger
  }
  return $deger
}
