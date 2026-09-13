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

  # ⛔ 13.09.2026 — BOM: ReadAllText BOM'u SESSİZCE YUTAR, kıyas onu göremez. Eskiden BOM'lu dosya
  # içerik aynıysa "değişmedi" sayılıp HİÇ yeniden yazılmıyordu -> BOM kalıcı oluyordu (veri/ altında
  # ölçüldü: 121 BOM'lu JSON). BOM'lu mevcut dosya içerik aynı olsa bile yeniden (BOM'suz) yazılır.
  $mevcutBomlu = $false
  if(Test-Path $Hedef){
    try {
      $akis = [System.IO.File]::OpenRead($Hedef)
      $ilkUc = New-Object byte[] 3
      $okunan = $akis.Read($ilkUc, 0, 3)
      $akis.Close()
      $mevcutBomlu = ($okunan -eq 3 -and $ilkUc[0] -eq 0xEF -and $ilkUc[1] -eq 0xBB -and $ilkUc[2] -eq 0xBF)
    } catch { $mevcutBomlu = $false }
  }

  if($eskiJson -and -not $mevcutBomlu -and (Notrle $eskiJson) -eq (Notrle $yeniJson)){
    if(-not $Sessiz){
      Write-Host ("  degismedi, dokunulmadi: {0}" -f (Split-Path $Hedef -Leaf)) -ForegroundColor DarkGray
    }
    return $false
  }

  # ⛔ 13.09.2026 — BOM'SUZ YAZ. "Set-Content -Encoding UTF8" Windows PowerShell 5.1'de dosyanın başına
  # BOM koyar, PowerShell 7'de koymaz: aynı robot hangi makinede koştuğuna göre farklı bayt üretiyordu.
  # Ölçülen bedel: veri/sinav-tek-sayfa.json 13.09 10:51'de Windows'ta BOM'lu yazıldı; Node JSON.parse
  # reddetti, motor/vitrin-soru-sec.js SESSİZCE eşit ağırlığa düştü (Finansal Muhasebe 70 yerde 5).
  # BOM'lu JSON'u Node/Python ayrıştırıcıları reddeder; bu yardımcı 68 betikte kullanılıyor.
  [System.IO.File]::WriteAllText($Hedef, $yeniJson + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding $false))
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
  # 4) yazilan dosya BOM'SUZ olmali (Windows PowerShell 5.1'de de)
  $bayt = [System.IO.File]::ReadAllBytes($gec)
  if($bayt.Length -ge 3 -and $bayt[0] -eq 0xEF -and $bayt[1] -eq 0xBB -and $bayt[2] -eq 0xBF){ Write-Host "  HATA: yazilan dosya BOM'lu" -ForegroundColor Red; $kotu++ }
  # 5) mevcut dosya BOM'lu + icerik AYNI -> yine de yazmali ve BOM'u atmali
  $nesne5 = [pscustomobject]@{ olcum='03.03.2026 09:00'; sayi=6 }
  [System.IO.File]::WriteAllText($gec, ($nesne5 | ConvertTo-Json -Depth 8), (New-Object System.Text.UTF8Encoding $true))
  $d5 = RaporYaz -Hedef $gec -Nesne $nesne5 -Sessiz
  $bayt5 = [System.IO.File]::ReadAllBytes($gec)
  if($d5 -ne $true){ Write-Host "  HATA: BOM'lu dosya icerik ayni diye yeniden yazilmadi" -ForegroundColor Red; $kotu++ }
  if($bayt5.Length -ge 3 -and $bayt5[0] -eq 0xEF -and $bayt5[1] -eq 0xBB -and $bayt5[2] -eq 0xBF){ Write-Host "  HATA: yeniden yazimdan sonra BOM hala duruyor" -ForegroundColor Red; $kotu++ }
  # 6) BOM'suz + icerik ayni -> dokunmamali (eski davranis bozulmadi)
  $d6 = RaporYaz -Hedef $gec -Nesne $nesne5 -Sessiz
  if($d6 -ne $false){ Write-Host "  HATA: BOM'suz ve icerik ayni ama yine yazdi" -ForegroundColor Red; $kotu++ }
  Remove-Item $gec -Force -ErrorAction SilentlyContinue
  if($kotu){ Write-Host "  OZ-SINAV DUSTU" -ForegroundColor Red; exit 2 }
  Write-Host "  RAPOR YAZICI OZ-SINAVI: 6/6 GECTI" -ForegroundColor Green
  exit 0
}
