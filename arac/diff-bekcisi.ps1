# ============================================================================
#  DIFF BEKCISI — robotun/insanin KAZAYLA VERI SILMESINE karsi CI freni.
#  Kural: kritik veri dosyalarinda kayit sayisi onceki commit'e gore %10'dan
#  fazla DUSEMEZ. Bilincli operasyonlar commit mesajina [veri-operasyonu]
#  yazarak gecebilir. API maliyeti SIFIR.
#  Dogrulama Kapisi (dogrula.yml) icinden her push'ta kosar.
# ============================================================================
$ErrorActionPreference = "Stop"
$kok = (git rev-parse --show-toplevel).Trim()
Set-Location $kok

# commit mesajinda gecis bileti var mi
$mesaj = (git log -1 --format=%B) -join " "
if($mesaj -match '\[veri-operasyonu\]'){ Write-Host "DIFF BEKCISI: [veri-operasyonu] bileti var, kontrol atlandi."; exit 0 }

# izlenen dosyalar: yol + kayit sayisini veren sayac ifadesi
$izlenen = @(
  @{ yol='veri/bilgi-tabani.json';      say={ param($j) @($j.kayitlar).Count } },
  @{ yol='veri/sgs-analiz.json';        say={ param($j) @($j.donemler).Count } },
  @{ yol='veri/soru-bankasi-onay.json'; say={ param($j) @($j.sorular).Count } },
  @{ yol='veri/soru-bankasi.json';      say={ param($j) @($j.sorular).Count } },
  @{ yol='veri/smmm-analiz.json';       say={ param($j) @($j.donemler).Count } },
  @{ yol='veri/mevzuat-kaynaklar.json'; say={ param($j) @($j.kanunlar).Count } },
  @{ yol='veri/sinav-arsiv.json';       say={ param($j) @($j.donemler).Count } },
  @{ yol='veri/gtip-tanim.json';        say={ param($j) @($j.PSObject.Properties).Count } }
)

$hata = $false
foreach($iz in $izlenen){
  if(-not (Test-Path $iz.yol)){ continue }
  # onceki surum var mi (yeni dosyaysa kontrol yok)
  $eskiHam = $null
  try { $eskiHam = git show ("HEAD~1:" + $iz.yol) 2>$null } catch {}
  if(-not $eskiHam){ continue }
  try {
    $yeni = & $iz.say (Get-Content $iz.yol -Raw -Encoding UTF8 | ConvertFrom-Json)
    $eski = & $iz.say (($eskiHam -join "`n") | ConvertFrom-Json)
  } catch { Write-Host ("  uyari: {0} sayilamadi, atlandi" -f $iz.yol); continue }
  if($eski -gt 0 -and $yeni -lt $eski){
    $dusus = ($eski - $yeni) / [double]$eski
    if($dusus -gt 0.10){
      Write-Host ("  ALARM: {0} kayit sayisi {1} -> {2} (%{3} dusus!)" -f $iz.yol, $eski, $yeni, [math]::Round($dusus*100))
      $hata = $true
    } else {
      Write-Host ("  kucuk dusus (izinli): {0} {1} -> {2}" -f $iz.yol, $eski, $yeni)
    }
  } else {
    Write-Host ("  ok: {0} {1} -> {2}" -f $iz.yol, $eski, $yeni)
  }
}

if($hata){
  Write-Host ""
  Write-Host "DIFF BEKCISI KIRMIZI: kritik veri dosyasinda >%10 kayit kaybi."
  Write-Host "Bilincli bir operasyonsa commit mesajina [veri-operasyonu] ekleyip yeniden push'la."
  exit 1
}
Write-Host "DIFF BEKCISI: veri kaybi yok."
exit 0
