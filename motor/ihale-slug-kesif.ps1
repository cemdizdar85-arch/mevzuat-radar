# ============================================================================
#  IHALE SLUG KESIF - ilan.gov.tr'de SONUC ve DUZELTME ilanlari ayri dusuyor mu?
#  Cem 13.08: (2) sonuclanan ihaleler (3) ayni ihalenin ilanlarini birlestirme.
#  Ikisi de ayni soruya baglı: kaynak bu turleri veriyor mu, hangi kimlikle?
#  OLCUM betigi - HICBIR SEY YAZMAZ, yalniz sayar ve ornek gosterir.
# ============================================================================
param([int]$Sayfa = 30)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$hepsi = @()
$atla = 0
for($t=0; $t -lt $Sayfa; $t++){
  $govde = @{ adFilterAttributes = @(@{ attributeId = 2; attributeValueIds = @(45984) }); maxResultCount = 20; skipCount = $atla } | ConvertTo-Json -Depth 5
  try {
    $r = Invoke-RestMethod -Method Post -Uri "https://www.ilan.gov.tr/api/api/services/app/Ad/AdsByFilter" `
      -Headers @{ "Accept"="application/json"; "User-Agent"="Mozilla/5.0 (MevzuatRadar-IhaleRobotu)" } `
      -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 90
  } catch { Write-Host "HATA sayfa $t : $($_.Exception.Message)"; break }
  $sayfa2 = @($r.result.ads)
  if(-not $sayfa2.Count){ break }
  $hepsi += $sayfa2
  $atla += $sayfa2.Count
  Start-Sleep -Milliseconds 350
}
Write-Host ("Cekilen ham ilan: {0}" -f $hepsi.Count)

# --- 1) Slug ONEKI dagilimi (ilk 3 parca) ------------------------------------
$onekler = @{}
foreach($a in $hepsi){
  $s = "$($a.slugifyTitle)"
  $p = ($s -split '-')
  $onek = ($p[0..([math]::Min(2,$p.Count-1))] -join '-')
  if(-not $onekler.ContainsKey($onek)){ $onekler[$onek] = 0 }
  $onekler[$onek]++
}
Write-Host "`n=== SLUG ONEK DAGILIMI ==="
$onekler.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 25 | ForEach-Object {
  Write-Host ("  {0,-45} {1}" -f $_.Key, $_.Value)
}

# --- 2) SONUC / DUZELTME / IPTAL izi ------------------------------------------
$desen = [ordered]@{
  'sonuc'    = 'sonuc|sonu[cç]land|kesinle[sş]'
  'duzeltme' = 'duzeltme|d[uü]zeltme|tashih'
  'iptal'    = 'iptal'
  'uzatma'   = 'uzat|erteleme|ertelen'
}
Write-Host "`n=== TUR IZI (slug + baslik birlikte) ==="
foreach($d in $desen.GetEnumerator()){
  $bulunan = @($hepsi | Where-Object { ("$($_.slugifyTitle) $($_.title)") -imatch $d.Value })
  Write-Host ("  {0,-10} : {1} ilan" -f $d.Key, $bulunan.Count)
  foreach($b in ($bulunan | Select-Object -First 3)){
    Write-Host ("      · {0}" -f ("$($b.title)".Substring(0,[math]::Min(95,"$($b.title)".Length))))
    Write-Host ("        slug: {0}" -f "$($b.slugifyTitle)".Substring(0,[math]::Min(95,"$($b.slugifyTitle)".Length)))
  }
}

# --- 3) AYNI IHALE izi: ayni kurum + ayni/benzer baslik kac kez? --------------
# Birlestirme ancak SAGLAM bir ortak kimlik varsa yapilabilir. Once bakalim:
# aynı advertiserName + aynı ilk 40 karakter baslik kac defa tekrarliyor.
$grup = @{}
foreach($a in $hepsi){
  $b = "$($a.title)"; if($b.Length -gt 40){ $b = $b.Substring(0,40) }
  $anahtar = ("$($a.advertiserName)|$b").ToLower()
  if(-not $grup.ContainsKey($anahtar)){ $grup[$anahtar] = @() }
  $grup[$anahtar] += $a
}
$coklu = @($grup.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 })
Write-Host ("`n=== AYNI IHALE ADAYI (ayni kurum + ayni ilk 40 karakter) ===")
Write-Host ("  Tekil grup: {0} · birden fazla ilanli grup: {1}" -f $grup.Count, $coklu.Count)
foreach($g in ($coklu | Sort-Object { $_.Value.Count } -Descending | Select-Object -First 5)){
  Write-Host ("  [{0} ilan] {1}" -f $g.Value.Count, ("$($g.Value[0].advertiserName)"))
  foreach($x in $g.Value){
    Write-Host ("      #{0} · {1}" -f $x.adNo, ("$($x.title)".Substring(0,[math]::Min(80,"$($x.title)".Length))))
  }
}

# --- 4) Ham kayitta hangi alanlar var? (birlestirme kimligi arayisi) ---------
Write-Host "`n=== HAM KAYIT ALANLARI (ilk ilan) ==="
if($hepsi.Count){
  $hepsi[0].PSObject.Properties | ForEach-Object {
    $d = "$($_.Value)"; if($d.Length -gt 60){ $d = $d.Substring(0,60)+'...' }
    Write-Host ("  {0,-28} = {1}" -f $_.Name, $d)
  }
}
