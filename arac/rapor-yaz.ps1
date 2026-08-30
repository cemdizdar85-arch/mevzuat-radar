# ============================================================================
#  RAPOR YAZICI — "içerik değişmediyse dosyaya dokunma"
#
#  NEDEN VAR (30.08.2026): Denetim betiklerinin hepsi çıktılarına bir `olcum`
#  zaman damgası koyuyor. Sonuç: ölçüm sonucu HİÇ değişmese bile dosya her
#  koşuda "değişmiş" görünüyor. Etkileri gün boyu görüldü:
#    · kapanış denetimi her seferinde takılıyor ("1 dosya commit'lenmemiş")
#    · robot akışları içerik aynıyken commit üretiyor — kütükte gürültü
#    · iki koşu aynı anda yazınca gereksiz yere çakışma çıkıyor
#
#  Bu yardımcı, yeni raporu diskteki sürümle ZAMAN ALANLARI HARİÇ kıyaslar.
#  Aynıysa dosyaya HİÇ dokunmaz (mtime bile değişmez); farklıysa yazar.
#
#  Kullanım:
#      . (Join-Path $PSScriptRoot 'rapor-yaz.ps1')
#      RaporYaz -Hedef $yol -Nesne $cikti          # varsayılan: 'olcum' alanı
#      RaporYaz -Hedef $yol -Nesne $cikti -ZamanAlanlari @('olcum','uretim')
#
#  DÖNÜŞ: $true yazıldıysa, $false değişmediği için atlandıysa.
# ============================================================================

function RaporYaz {
  param(
    [Parameter(Mandatory=$true)][string]$Hedef,
    [Parameter(Mandatory=$true)]$Nesne,
    [string[]]$ZamanAlanlari = @('olcum','olcum_zamani','guncelleme','uretim','tarih_damgasi'),
    [int]$Derinlik = 8,
    [switch]$Sessiz
  )

  $yeniJson = $Nesne | ConvertTo-Json -Depth $Derinlik

  # Kıyas için zaman alanlarını nötrle: yalnız İÇERİK karşılaştırılsın.
  # Alan adı satır başında "  "olcum": ..." biçiminde geçer; değeri silinir.
  function Notrle([string]$j){
    if(-not $j){ return '' }
    foreach($a in $ZamanAlanlari){
      $j = [regex]::Replace($j, '("' + [regex]::Escape($a) + '"\s*:\s*)"[^"]*"', '$1"@@ZAMAN@@"')
    }
    # satır sonu farkı kıyası bozmasın
    return ($j -replace "`r`n", "`n").Trim()
  }

  $eskiJson = $null
  if(Test-Path $Hedef){
    try { $eskiJson = [System.IO.File]::ReadAllText($Hedef, [System.Text.Encoding]::UTF8) } catch { $eskiJson = $null }
  }

  if($eskiJson -and (Notrle $eskiJson) -eq (Notrle $yeniJson)){
    if(-not $Sessiz){
      Write-Host ("  degismedi, dokunulmadi: {0}" -f (Split-Path $Hedef -Leaf)) -ForegroundColor DarkGray
    }
    return $false
  }

  $yeniJson | Set-Content $Hedef -Encoding UTF8
  if(-not $Sessiz){
    Write-Host ("  yazildi: {0}" -f (Split-Path $Hedef -Leaf)) -ForegroundColor Green
  }
  return $true
}

# --- ÖZ-SINAV (93 kapı kuralı) --------------------------------------------
# `... rapor-yaz.ps1 -Sinav` ile çağrılırsa kendini sınar. Dot-source
# edildiğinde çalışmaz (o zaman $args boştur).
if($args -contains '-Sinav'){
  $gec = Join-Path $env:TEMP ("rapor-yaz-sinav-" + [guid]::NewGuid().ToString('N').Substring(0,6) + '.json')
  $kotu = 0
  # 1) ilk yazma
  $a = RaporYaz -Hedef $gec -Nesne ([pscustomobject]@{ olcum='01.01.2026 10:00'; sayi=5 }) -Sessiz
  if($a -ne $true){ Write-Host "  HATA: ilk yazma yapilmadi" -ForegroundColor Red; $kotu++ }
  # 2) YALNIZ zaman degisti -> yazmamali
  $b = RaporYaz -Hedef $gec -Nesne ([pscustomobject]@{ olcum='02.02.2026 20:00'; sayi=5 }) -Sessiz
  if($b -ne $false){ Write-Host "  HATA: yalniz zaman degisti ama yazdi" -ForegroundColor Red; $kotu++ }
  # 3) ICERIK degisti -> yazmali
  $c = RaporYaz -Hedef $gec -Nesne ([pscustomobject]@{ olcum='02.02.2026 20:00'; sayi=6 }) -Sessiz
  if($c -ne $true){ Write-Host "  HATA: icerik degisti ama yazmadi" -ForegroundColor Red; $kotu++ }
  Remove-Item $gec -Force -ErrorAction SilentlyContinue
  if($kotu){ Write-Host "  OZ-SINAV DUSTU" -ForegroundColor Red; exit 2 }
  Write-Host "  RAPOR YAZICI OZ-SINAVI: 3/3 GECTI" -ForegroundColor Green
  exit 0
}
