# ============================================================================
#  SMMM YETERLILIK CEVAP ANAHTARI CIKARIMI (13.09.2026)
#  SGS karsiligi: motor/sgs-cevap-anahtari.ps1 (Cem 13.09: "staja baslamada ne
#  yaptiysak bunda aynisi").
#
#  OLCULDU: 2026/1 ve 2026/2 test kitapciklarinin 16'sinin 16'sinda anahtar
#  kitapcigin SON SAYFASINDA basili:
#      "<Ders> Cevap Anahtari"
#      A Kitapcigi | B | C | D Soru No | Dogru Cevap Sikki   (+ bazen "IPTAL")
#  Yayimlanan PDF A kitapcigidir -> 'a' = A kitapcigi soru no -> dogru harf.
#  B/C/D numaralari da saklanir (baska kitapcik gelirse eslestirme icin).
#  Klasik (2008-2025) donemlerde test anahtari yoktur; o dosyalar atlanir.
#
#  CIKTI: veri/smmm-cevap-anahtari.json
#    { donemler: { "2026/1|01": { ders_kodu, kitapcik, adet, kesintisiz,
#                                 a:{"1":"A",...}, iptal:["14"], bcd:{...} } } }
#  KULLANIM: motor/celdirici-olcum.ps1 -Sinav SMMM, arac/cevap-dagilimi-olc.ps1.
#  BEDAVA - yerel metin, ag yok. Elle duzenlenmez; yeni kitapcik gelince kosar.
# ============================================================================
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
$klasor = Join-Path $depoKok 'veri\smmm-arsiv\txt'
$dosyalar = @(Get-ChildItem $klasor -Filter 'smmm_*.txt' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^smmm_\d{4}_\d_\d{2}\.txt$' })
if(-not $dosyalar.Count){ Write-Host 'KOR: veri/smmm-arsiv/txt yok (yalniz yerelde). Dosyaya dokunulmadi.'; exit 0 }

$donemTablo = [ordered]@{}
$anahtarsiz = 0
foreach($f in ($dosyalar | Sort-Object Name)){
  $metinTam = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
  $baslik = [regex]::Match($metinTam, '(?i)Cevap\s+Anahtar')
  if(-not $baslik.Success){ $anahtarsiz++; continue }
  $parcaAd = [regex]::Match($f.Name, 'smmm_(\d{4})_(\d)_(\d{2})\.txt')
  $anahtarAdi = "$($parcaAd.Groups[1].Value)/$($parcaAd.Groups[2].Value)|$($parcaAd.Groups[3].Value)"
  $kuyruk = $metinTam.Substring($baslik.Index)
  $harfA = [ordered]@{}; $bcd = [ordered]@{}; $iptalList = New-Object System.Collections.Generic.List[string]
  foreach($satirEs in [regex]::Matches($kuyruk, '(?m)^\s*(\d{1,2})\s+(\d{1,2})\s+(\d{1,2})\s+(\d{1,2})\s+([A-E])\b(.*)$')){
    $noA = [int]$satirEs.Groups[1].Value
    if($noA -lt 1 -or $noA -gt 60 -or $harfA.Contains("$noA")){ continue }
    $harfA["$noA"] = $satirEs.Groups[5].Value
    $bcd["$noA"] = @([int]$satirEs.Groups[2].Value, [int]$satirEs.Groups[3].Value, [int]$satirEs.Groups[4].Value)
    # 'IPTAL' pdftotext'te I + U+0307 (ayrik nokta) cikabiliyor -> yalniz 'PTAL' aranir
    if($satirEs.Groups[6].Value -match '(?i)PTAL\b'){ $iptalList.Add("$noA") }
  }
  if($harfA.Count -eq 0){ $anahtarsiz++; continue }   # klasik komisyon cevabinda "cevap anahtari" gecen metin: tablo yok
  $nolar = @($harfA.Keys | ForEach-Object { [int]$_ } | Sort-Object)
  $kesintisiz = ($nolar.Count -gt 0 -and $nolar[0] -eq 1 -and $nolar[-1] -eq $nolar.Count)
  $donemTablo[$anahtarAdi] = [ordered]@{ ders_kodu = $parcaAd.Groups[3].Value; kitapcik = $f.Name; adet = $harfA.Count; kesintisiz = $kesintisiz; a = $harfA; iptal = $iptalList.ToArray(); bcd = $bcd }
}
$cikti = [ordered]@{
  olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  kaynak = 'kitapcik son sayfasi "<Ders> Cevap Anahtari" tablosu (TESMER PDF, A kitapcigi)'
  kitapcik = $dosyalar.Count; anahtarli = $donemTablo.Count; anahtarsiz_klasik = $anahtarsiz
  donemler = $donemTablo
}
$null = RaporYaz -Hedef (Join-Path $depoKok 'veri\smmm-cevap-anahtari.json') -Nesne $cikti -Derinlik 6 -Sessiz:$Sessiz
if(-not $Sessiz){
  Write-Host ("SMMM cevap anahtari: {0} dosya - anahtarli {1} - anahtarsiz (klasik) {2}" -f $dosyalar.Count, $donemTablo.Count, $anahtarsiz)
  foreach($d in $donemTablo.Keys){ $x = $donemTablo[$d]; Write-Host ("  {0}: {1} soru - kesintisiz {2} - iptal {3}" -f $d, $x.adet, $x.kesintisiz, ($x.iptal -join ',')) }
}
