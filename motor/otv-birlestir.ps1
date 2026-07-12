# ============================================================================
#  OTV BIRLESTIR - iki bagimsiz okumayi (otv-kapsam-1/2.json) union'la
#  -> veri\gtip-otv.json (pozisyon -> {liste, ad}). Mojibake duzeltilir.
#  KURAL: iki okumadan HERHANGI birinde gecen pozisyon dahil (false-negative az).
# ============================================================================
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$b = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad"

function Mojibake([string]$s){
  if($s -match "Ã|Ä|Å|Â"){ return [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($s)) }
  return $s
}
function OkuPoz($yol){ $h=[System.IO.File]::ReadAllText($yol,[System.Text.Encoding]::UTF8); $j=$h -replace '(?s)^.*?(\{.*\}).*?$','$1'; return ($j | ConvertFrom-Json) }

$o1 = OkuPoz "$b\otv-kapsam-1.json"; $o2 = OkuPoz "$b\otv-kapsam-2.json"
$listeAd = @{ liste1="I"; liste2="II"; liste3="III"; liste4="IV" }
$listeAcik = @{
  "I"  = "I — akaryakıt ve türevleri (maktu, litre/kg başına)"
  "II" = "II — motorlu taşıtlar (matrah/motor diliminde değişen oran)"
  "III"= "III — alkol, tütün, alkolsüz içecek (maktu + oran)"
  "IV" = "IV — lüks ve dayanıklı tüketim malları (oran)"
}
$poz = [ordered]@{}
foreach($liste in @("liste1","liste2","liste3","liste4")){
  $rom = $listeAd[$liste]
  $hepsi = @()
  foreach($o in @($o1,$o2)){ foreach($x in @($o.$liste)){ if($x.p){ $hepsi += ,@{ p=$x.p; ad=(Mojibake ([string]$x.ad)) } } } }
  foreach($x in $hepsi){
    $digits = ($x.p -replace '[^\d]','')
    if($digits.Length -lt 2){ continue }
    if(-not $poz.Contains($digits)){ $poz[$digits] = @{ liste=$rom; ad=$x.ad } }
  }
}

$out = [ordered]@{
  guncelleme = "4760 sayılı ÖTV Kanunu ekli listeler (mevzuat.gov.tr resmî metin, çift bağımsız okuma)"
  not = "Bu bir KAPSAM göstergesidir: pozisyon bir ÖTV listesinde geçiyorsa işaretlenir. Oran/tutar buraya YAZILMAZ — Liste I/III maktu (6 ayda bir değişir), Liste II matrah dilimli, Liste IV oranlıdır ve Cumhurbaşkanı Kararlarıyla sık güncellenir. Kesin oran/tam kod kapsamı için GİB güncel ÖTV listelerine bakınız."
  listeAcik = $listeAcik
  pozisyon = $poz
}
$veriDir = Join-Path $kok "veri"; New-Item -ItemType Directory -Force $veriDir | Out-Null
$hedef = Join-Path $veriDir "gtip-otv.json"
($out | ConvertTo-Json -Depth 5 -Compress) | Out-File $hedef -Encoding utf8

""
"OTV BIRLESTIR BITTI. Pozisyon: $($poz.Count)"
"veri\gtip-otv.json ($([math]::Round((Get-Item $hedef).Length/1KB)) KB)"
foreach($rom in @("I","II","III","IV")){
  $say = @($poz.Keys | Where-Object { $poz[$_].liste -eq $rom }).Count
  "  Liste $rom : $say pozisyon"
}
"--- ornek ---"
foreach($k in @("8703","2710","2203","8517","8418","6109")){ if($poz.Contains($k)){ "  $k -> Liste $($poz[$k].liste) : $($poz[$k].ad)" } else { "  $k -> OTV YOK" } }
