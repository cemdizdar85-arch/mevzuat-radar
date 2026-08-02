# ============================================================================
#  SIKLIK KUNYESI (SINAV-KURALLARI D9) — 02.08.2026, 0 USD, API YOK
#
#  CEM: "senin onerin vardi onu yapacaktin." Dogru - siklik kunyesi BENIM
#  onerimdi ve BEDAVA. Parali motoru beklemesine gerek yok.
#
#  NE YAPAR: 35 donemlik cikmis kitapcik haritasindan (veri/sgs-analiz.json)
#  her KONUNUN kac donemde ciktigini ve toplam kac soru geldigini sayar.
#  Cikti soru ekraninda kunye olarak gosterilir: "Bu konu son 35 donemin
#  7'sinde cikti, toplam 9 soru."
#
#  D9 FRENI: sayim yoksa kunye YAZILMAZ. "Sik cikar" gibi olcusuz ifade yasak.
#  Cikti: veri/siklik-kunyesi.json
# ============================================================================
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$kaynak = Join-Path $kok 'veri/sgs-analiz.json'
$cikti  = Join-Path $kok 'veri/siklik-kunyesi.json'
if(-not (Test-Path $kaynak)){ Write-Host "sgs-analiz.json yok - cikildi."; exit 1 }

$a = Get-Content $kaynak -Raw -Encoding UTF8 | ConvertFrom-Json
$donemler = @($a.donemler | Where-Object { $_.konuSayim })
Write-Host ("Donem: {0}" -f $donemler.Count)

# Turkce-toleransli normalize: kasadaki etiketle kitapciktaki etiket birebir
# ayni yazilmiyor; aksan/buyuk-kucuk farkini eritip esitliyoruz.
function Norm([string]$t){
  $s = "$t".ToLower()
  $s = $s -replace '[çÇ]','c' -replace '[ğĞ]','g' -replace '[ıİİ]','i' -replace '[öÖ]','o' -replace '[şŞ]','s' -replace '[üÜ]','u'
  $s = $s -replace '[^a-z0-9| ]',' ' -replace '\s+',' '
  return $s.Trim()
}

$konu = @{}
foreach($d in $donemler){
  $gorulen = @{}
  foreach($p in $d.konuSayim.PSObject.Properties){
    $anah = Norm $p.Name
    if(-not $anah){ continue }
    if(-not $konu.ContainsKey($anah)){ $konu[$anah] = @{ donem = 0; soru = 0; ad = $p.Name } }
    $konu[$anah].soru += [int]$p.Value
    if(-not $gorulen[$anah]){ $konu[$anah].donem++; $gorulen[$anah] = $true }
  }
}
Write-Host ("Benzersiz konu: {0}" -f $konu.Count)

# En cok cikan 25 konu — bunlar "sinavin belkemigi", pazarlamada da kullanilir
$enCok = $konu.GetEnumerator() | Sort-Object { $_.Value.donem }, { $_.Value.soru } -Descending | Select-Object -First 25

$tablo = [ordered]@{}
foreach($k in ($konu.GetEnumerator() | Sort-Object Name)){
  $tablo[$k.Key] = [ordered]@{ d = $k.Value.donem; s = $k.Value.soru; ad = $k.Value.ad }
}

$rapor = [ordered]@{
  tarih         = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  kaynak        = 'veri/sgs-analiz.json — cikmis SGS kitapciklarinin konu sayimi'
  donem_sayisi  = $donemler.Count
  konu_sayisi   = $konu.Count
  en_cok_cikan  = @($enCok | ForEach-Object { [ordered]@{ konu = $_.Value.ad; donem = $_.Value.donem; soru = $_.Value.soru } })
  konular       = $tablo
  kullanim      = 'Anahtar = Norm("<ders>|<konu>"). Kasadaki soru bu anahtarla aranir; BULUNAMAZSA kunye GOSTERILMEZ (D9 freni: sayim yoksa yazilmaz).'
}
Set-Content -LiteralPath $cikti -Value (ConvertTo-Json -InputObject $rapor -Depth 6) -Encoding UTF8 -NoNewline
Write-Host "`n=== EN COK CIKAN 10 KONU ==="
$enCok | Select-Object -First 10 | ForEach-Object {
  Write-Host ("  {0,2}/{1} donem · {2,3} soru · {3}" -f $_.Value.donem, $donemler.Count, $_.Value.soru, $_.Value.ad)
}
Write-Host ("`n-> {0}" -f $cikti)
