# ============================================================================
#  IHRACAT KISIT HASAT - ihraci yasak / on izne bagli / kayda bagli mallar
#  Kaynaklar (birincil, indirilmis):
#   - kayda-bagli.txt : Ihraci Kayda Bagli Mallara Iliskin Teblig (2006/7, guncel)
#   - yasak.txt       : Ihraci Yasak ve On Izne Bagli Mallara Iliskin Teblig (96/31)
#  Kayda bagli: GTIP kodlu maddeler -> koda baglanir. Yasak/on izinli: isim bazli.
#  Cikti: veri\gtip-ihracat-kisit.json
# ============================================================================
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$sc   = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad"

# ---- KAYDA BAGLI (GTIP kodlu) - RESMI KAYNAK: mevzuat.gov.tr (9.5.10371.doc) ----
$kb = ([System.IO.File]::ReadAllText("$sc\kayda-resmi.txt", [System.Text.Encoding]::GetEncoding(1254))) -replace '\s+',' '
# resmi doc tiposu: "10.0l" / "10.0I" (buğday 10.01) -> duzelt
$kb = $kb -replace '10\.0[lI]', '10.01'
# degisiklik/ek tarihcelerini temizle (kod cikarimini sasirtmasin)
$kb = [regex]::Replace($kb, '\((?:Değişik|Ek|Mülga|Yeniden düzenleme)[^)]*\)', ' ')
$kbList = $kb.Substring($kb.IndexOf("KAYDA BAĞLI MALLAR LİSTESİ"))
$kaydaBagli = [ordered]@{}
$kaydaTanim = @()
# numarali maddelere bol
foreach($m in [regex]::Split($kbList, '(?<=[ ,\.])(?=\d{1,2}\s*[-–]\s)')){
  $md = $m.Trim(); if($md.Length -lt 6){ continue }
  if($md -match "Mülga"){ continue }
  # madde acilis metni (ilk 70 krkt, GTIP oncesi)
  $ad = ($md -replace '\(GT[İI]P.*$','' -replace '\(\d.*$','').Trim()
  $ad = ($ad -replace '^\d{1,2}\s*[-–]\s*','').Trim()
  if($ad.Length -gt 80){ $ad = $ad.Substring(0,80) }
  $kodBulundu = $false
  foreach($cm in [regex]::Matches($md, '\b\d{2,4}(?:\.\d{2}){1,4}\b')){
    $digits = ($cm.Value -replace '[^\d]','')
    if($digits.Length -lt 4){ continue }
    if(-not $kaydaBagli.Contains($digits)){ $kaydaBagli[$digits] = $ad }
    $kodBulundu = $true
  }
  if(-not $kodBulundu -and $ad.Length -ge 4 -and $ad -notmatch '^\d'){ $kaydaTanim += $ad }
}

# ---- YASAK + ON IZINLI (isim bazli) ----
$y = ([System.IO.File]::ReadAllText("$sc\yasak.txt", [System.Text.Encoding]::GetEncoding(1254))) -replace '\s+',' '
$yasakBas = $y.IndexOf("İHRACI YASAK MALLAR")
$onIzinBas = $y.IndexOf("ÖN İZNE BAĞLI MALLAR")
$kurumRx = '(Milli Savunma Bakanlığı|Sağlık Bakanlığı|Çevre[^.]{0,25}?Bakanlığı|Tarım[^.]{0,25}?Bakanlığı|Ekonomi Bakanlığı|Enerji[^.]{0,25}?Bakanlığı|Kültür[^.]{0,25}?Bakanlığı|Ticaret Bakanlığı)'
function BaslikMi([string]$ad){ return ($ad -match 'LİSTESİ|MADDE İZNİ|MADDE YASAL|İZNİ VEREN KURUM|Formun') }
function MaddeAdlari([string]$blok){
  $sonuc = @()
  foreach($m in [regex]::Split($blok, '(?<=[ \.])(?=\d{1,2}\s*[-–]\s*[A-ZÇĞİÖŞÜ(])')){
    $md = $m.Trim(); if($md.Length -lt 5){ continue }
    $ad = ($md -replace '^\d{1,2}\s*[-–]\s*','')
    $ad = ($ad -replace '\d{1,2}/\d{1,2}/\d{4}.*$','').Trim()
    $ad = ([regex]::Replace($ad, '\s*'+$kurumRx+'.*$','')).Trim()
    if((BaslikMi $ad)){ continue }
    if($ad.Length -gt 150){ $ad = $ad.Substring(0,150) }
    if($ad.Length -ge 4){ $sonuc += $ad }
  }
  return $sonuc
}
function OnIzinli([string]$blok){
  $sonuc = @()
  foreach($m in [regex]::Split($blok, '(?<=[ \.])(?=\d{1,2}\s*[-–]\s*[A-ZÇĞİÖŞÜ(])')){
    $md = $m.Trim(); if($md.Length -lt 5){ continue }
    $ad = ($md -replace '^\d{1,2}\s*[-–]\s*','')
    $kurum = ""
    $km = [regex]::Match($ad, $kurumRx)
    if($km.Success){ $kurum = $km.Value; $ad = $ad.Substring(0, $km.Index).Trim() }
    $ad = ($ad -replace '\d{1,2}/\d{1,2}/\d{4}.*$','').Trim()
    if((BaslikMi $ad)){ continue }
    if($ad.Length -gt 150){ $ad = $ad.Substring(0,150) }
    if($ad.Length -ge 4){ $sonuc += @{ mal=$ad; kurum=$kurum } }
  }
  return $sonuc
}
$yasak = @()
if($yasakBas -ge 0){ $blok = $y.Substring($yasakBas, [Math]::Max(0,$onIzinBas-$yasakBas)); $yasak = MaddeAdlari $blok }
$onIzin = @()
if($onIzinBas -ge 0){ $blok = $y.Substring($onIzinBas); $onIzin = OnIzinli $blok }

$out = [ordered]@{
  guncelleme = "İhracı Kayda Bağlı Mallara İlişkin Tebliğ (2006/7, en son İhracat 2025/2) + İhracı Yasak ve Ön İzne Bağlı Mallara İlişkin Tebliğ (96/31). Kaynak: Ticaret Bakanlığı / mevzuat.gov.tr."
  kaydaBagli = $kaydaBagli
  kaydaBagliTanim = $kaydaTanim
  yasak = $yasak
  onIzinli = $onIzin
}
$veriDir = Join-Path $kok "veri"
$hedef = Join-Path $veriDir "gtip-ihracat-kisit.json"
($out | ConvertTo-Json -Depth 4 -Compress) | Out-File $hedef -Encoding utf8
""
"IHRACAT KISIT HASAT BITTI."
"  kayda bagli (kodlu): $($kaydaBagli.Count) | kodsuz tanim: $($kaydaTanim.Count)"
"  yasak: $($yasak.Count) | on izinli: $($onIzin.Count)"
"veri\gtip-ihracat-kisit.json ($([math]::Round((Get-Item $hedef).Length/1KB)) KB)"
"--- kayda bagli ornekleri ---"
$i=0; foreach($k in $kaydaBagli.Keys){ if($i -ge 5){break}; "  $k => $($kaydaBagli[$k])"; $i++ }
"--- yasak ilk 5 ---"; $yasak | Select-Object -First 5 | ForEach-Object { "  - $_" }
"--- on izinli ilk 5 ---"; $onIzin | Select-Object -First 5 | ForEach-Object { "  - $($_.mal) [$($_.kurum)]" }
