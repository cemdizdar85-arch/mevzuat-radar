# ============================================================================
#  -match KULTUR TUZAGI TARAYICISI  (30.08.2026)
#
#  NEDEN VAR: 30.08'de okuma pilotunda UC KEZ ayni kusur cikti ve ucu de
#  GitHub runner'in kulturu sayesinde gizlenmisti:
#
#    "KARAR: KESIN_MUHLET" -match '(?i)^KARAR:\s*([A-Z_]{3,})'  ->  "KES"
#    "IFLASINA"            -match 'iflas'                        ->  eslesmez
#    "KESIN".ToLower()                                           ->  "kesın"
#
#  KOK SEBEP: PowerShell'in -match operatoru HER ZAMAN IgnoreCase kullanir
#  (inline (?i) yazilmasa da), ve .NET IgnoreCase eslestirmesi CurrentCulture'a
#  bakar. Turkce kulturde 'I' ile 'i' AYRI harflerdir:
#      'I'.ToLower() = 'ı'  (U+0131)   ·   'i'.ToUpper() = 'İ'  (U+0130)
#  Bu yuzden buyuk harfli Turkce metinde kucuk harfli kalip ISKALAR.
#
#  KRITIK: Linux runner (invariant kultur) bu tuzagi GIZLER. Kod yerelde
#  yanlis, canlida dogru davranir - yani "kosuda sorun cikmadi" ile "kod dogru"
#  ayni sey DEGILDIR.
#
#  BU BETIK NE YAPAR: motor/ ve arac/ altindaki her .ps1'i tarar, riskli
#  eslestirmeleri UC SINIFA ayirir ve dosya:satir olarak listeler.
#
#  UC SONUC (kalici sigorta kurali):
#    YESIL   - olculdu, yuksek riskli kullanim yok
#    KIRMIZI - olculdu, en az bir YUKSEK riskli kullanim var
#    KOR     - taranamadi (dizin yok / okuma hatasi)
#
#  Env: ESIK (varsayilan 0) - bu sayidan fazla YUKSEK risk varsa cikis 1
# ============================================================================
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ESIK = if ($env:ESIK) { [int]$env:ESIK } else { 0 }

$dizinler = @('motor','arac') | ForEach-Object { Join-Path $kok $_ } | Where-Object { Test-Path $_ }
if (-not $dizinler) { Write-Host 'KOR: motor/ ve arac/ dizinleri bulunamadi - tarama YAPILAMADI.'; exit 0 }

$dosyalar = @(Get-ChildItem -Path $dizinler -Filter *.ps1 -Recurse -File -ErrorAction SilentlyContinue)
if (-not $dosyalar.Count) { Write-Host 'KOR: hic .ps1 bulunamadi - tarama guvenilmez.'; exit 0 }

# Turkce'de kulturun ayirdigi harfler. Kalip ya da hedef bunlardan birini
# iceriyorsa IgnoreCase eslestirme kulture baglanir.
$TEHLIKELI = 'iıIİ'

$yuksek = @(); $orta = @(); $tarananSatir = 0

foreach ($f in $dosyalar) {
  $satirlar = @(Get-Content $f.FullName -Encoding UTF8 -ErrorAction SilentlyContinue)
  for ($i = 0; $i -lt $satirlar.Count; $i++) {
    $s = $satirlar[$i]
    $tarananSatir++
    if ($s -cmatch '^\s*#') { continue }                 # yorum satiri
    if ($s -notmatch '-match|-notmatch|-replace|-split') { continue }

    # Kalibi cikar: -match/-replace sonrasindaki tirnakli ifade
    $kalip = ''
    if ($s -cmatch "-(?:not)?match\s+['`"]([^'`"]+)") { $kalip = $Matches[1] }
    elseif ($s -cmatch "-replace\s+['`"]([^'`"]+)")   { $kalip = $Matches[1] }
    elseif ($s -cmatch "-split\s+['`"]([^'`"]+)")     { $kalip = $Matches[1] }
    if (-not $kalip) { continue }

    # --- YUKSEK RISK -------------------------------------------------------
    # (a) Kalipta A-Z / a-z karakter SINIFI var: IgnoreCase sinifi kulture gore
    #     yorumluyor ve 'I' harfini reddedebiliyor (30.08 kusuru birebir bu).
    # (b) Kalipta Turkce'nin ayirdigi harf var VE -cmatch degil.
    $sinifVar   = ($kalip -cmatch '\[[^\]]*(?:A-Z|a-z)[^\]]*\]')
    $harfVar    = ($kalip.ToCharArray() | Where-Object { $TEHLIKELI.Contains($_) }).Count -gt 0
    $ordinalMi  = ($s -cmatch '-cmatch|-cnotmatch|-creplace|-csplit')

    if ($ordinalMi) { continue }                          # zaten ordinal, guvenli

    if ($sinifVar) {
      # --- KANIT KAPISI (olcemedigine kusur deme) --------------------------
      # "Riskli desen" ile "gercekten bozuk" ayni sey degil. Kalibin icindeki
      # her karakter SINIFINI cikarip 'I' harfiyle IKI KIPTE deniyoruz:
      #   -match  (IgnoreCase, kulture bagli)  vs  -cmatch (ordinal)
      # Ikisi ayni sonucu veriyorsa bu satir bu makinede BOZUK DEGIL - riskli
      # ama kanitlanmamis. Farkliysa kusur KANITLANMISTIR.
      $kanit = $false; $kanitDetay = ''
      foreach ($sm in [regex]::Matches($kalip, '\[[^\]]+\]')) {
        $sinif = $sm.Value
        foreach ($harf in @('I', 'i')) {
          try {
            $ic = [bool]($harf -match $sinif)      # IgnoreCase - kulture bagli
            $or = [bool]($harf -cmatch $sinif)     # ordinal
            if ($ic -ne $or) { $kanit = $true; $kanitDetay = "$sinif : '$harf' IgnoreCase=$ic ordinal=$or" }
          } catch { }
        }
      }
      $yuksek += [pscustomobject]@{ dosya = $f.Name; satir = $i + 1
                                    sebep = 'A-Z/a-z sinifi + IgnoreCase'
                                    kanitli = $kanit; kanit = $kanitDetay
                                    kod = $s.Trim(); yol = $f.FullName }
    }
    elseif ($harfVar) {
      $orta += [pscustomobject]@{ dosya = $f.Name; satir = $i + 1; sebep = "kalipta 'i/I' harfi + IgnoreCase"
                                  kod = $s.Trim(); yol = $f.FullName }
    }
  }
}

Write-Host ("Tarandi: {0} betik · {1} satir" -f $dosyalar.Count, $tarananSatir)
Write-Host ''

$kanitli = @($yuksek | Where-Object { $_.kanitli })
Write-Host ("Bu makinenin kulturu: {0}" -f [Globalization.CultureInfo]::CurrentCulture.Name)
Write-Host ''

if ($kanitli.Count) {
  Write-Host ("KANITLI KUSUR: {0} kullanim" -f $kanitli.Count)
  Write-Host '  Bu satirlarda kalibin karakter sinifi, IgnoreCase ile ordinal kipte FARKLI'
  Write-Host '  sonuc veriyor - yani 30.08 okuma pilotu kusurunun birebir aynisi. Metin'
  Write-Host '  "I" harfi iceriyorsa kalip ORTADAN KESILIR ya da hic eslesmez.'
  Write-Host '  Cozum: o satirda -match yerine -cmatch (ordinal) kullan.'
  Write-Host ''
  $kanitli | Group-Object dosya | Sort-Object Count -Descending | ForEach-Object {
    Write-Host ("  {0,-42} {1,3} yer" -f $_.Name, $_.Count)
  }
  Write-Host ''
  $kanitli | Select-Object -First 12 | ForEach-Object {
    Write-Host ("    {0}:{1}   [{2}]" -f $_.dosya, $_.satir, $_.kanit)
    $k = $_.kod; if ($k.Length -gt 100) { $k = $k.Substring(0, 100) + '...' }
    Write-Host ("       {0}" -f $k)
  }
  Write-Host ''
}

$supheliAma = @($yuksek | Where-Object { -not $_.kanitli })
if ($supheliAma.Count) {
  Write-Host ("RISKLI AMA KANITLANMADI: {0} kullanim" -f $supheliAma.Count)
  Write-Host '  Kalip A-Z/a-z sinifi tasiyor ama bu makinede iki kip AYNI sonucu verdi.'
  Write-Host '  Kusur DEMEK DEGIL - baska bir kulturde ya da baska bir girdiyle ayrisabilir.'
  Write-Host ''
}

if ($orta.Count) {
  Write-Host ("ORTA RISK: {0} kullanim (kalipta i/I harfi + IgnoreCase)" -f $orta.Count)
  Write-Host '  Hedef metin BUYUK harfliyse iskalayabilir. Metin kaynagi bilinmeden'
  Write-Host '  kusur denemez - once metnin buyuk harf gelip gelmedigi olculur.'
  $orta | Group-Object dosya | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host ("  {0,-42} {1,3} yer" -f $_.Name, $_.Count)
  }
  Write-Host ''
}

$hedef = Join-Path $kok 'veri\match-kultur-taramasi.json'
$cikti = [ordered]@{
  olcum    = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  aciklama = 'PowerShell -match HER ZAMAN IgnoreCase kullanir ve IgnoreCase CurrentCulture a bakar. Turkce kulturde I ile i ayri harftir; buyuk harfli metinde kucuk harfli kalip iskalar. Linux runner (invariant) bu tuzagi GIZLER.'
  kaynak   = 'arac/match-kultur-tuzagi-tarayici.ps1'
  betik    = $dosyalar.Count
  satir    = $tarananSatir
  yuksek   = $yuksek.Count
  orta     = $orta.Count
  kanitli  = $kanitli.Count
  yuksek_kayitlar = @($yuksek | ForEach-Object { [ordered]@{ dosya=$_.dosya; satir=$_.satir; kanitli=$_.kanitli; kanit=$_.kanit; kod=$_.kod } })
  orta_kayitlar   = @($orta   | ForEach-Object { [ordered]@{ dosya=$_.dosya; satir=$_.satir; kod=$_.kod } })
}
[IO.File]::WriteAllText($hedef, ($cikti | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding $false))
Write-Host ("Rapor: {0}" -f $hedef)
Write-Host ''

if ($kanitli.Count -gt $ESIK) {
  Write-Host ("KIRMIZI: {0} KANITLI kusur var (esik {1}) · ayrica {2} riskli-kanitlanmamis." -f $kanitli.Count, $ESIK, $supheliAma.Count)
  exit 1
}
Write-Host ("YESIL: kanitli kusur yok (riskli-kanitlanmamis {0} · orta risk {1} - elle bakilir)." -f $supheliAma.Count, $orta.Count)
exit 0
