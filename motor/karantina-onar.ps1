# karantina-onar.ps1 - 28.07.2026
# GM okumasinin MEKANIK kismi. Parasi odenmis ama yapisal kusur ya da DETEKTOR HATASI
# yuzunden karantinada bekleyen sorulari onarir / akladigini isaretler.
#
# ONEMLI: hicbir soru bu betikle kasaya GIRMEZ. durum='karantina' korunur.
# Betik yalnizca (a) yapisal kusuru duzeltir, (b) yanlis alarmi belgeler,
# (c) GM'nin okumasi gereken kuyrugu isaretler. Serbest birakma karari GM'nindir.
#
# Neden gerekti (olculdu, 28.07):
#   tekrar-eden-sik 38 -> 30'unda BES SIKKIN HEPSI FARKLI (detektor hatasi)
#   mukerrer-kok    38 -> 36'sinin yerel havuzda IKIZI YOK; eski kural kokun ilk
#                          60 karakterine bakiyordu, genel kaliplar carpisiyordu
#                          (kok neden: toplu-uret.ps1 / soru-uret.ps1 - duzeltildi)
#   sik-sayisi/bos-sik 15 -> 11 bos F sikki + 4 sizan alan; biri (tobin vergisi)
#                          dogru cevabi siklarin icine dusurmus, ust alan BOSTU
#   hap-zayif       15 -> 15'inde de hap alani TAMAMEN BOS; GM elle yazacak

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"
if(-not (Test-Path $fabrikaDir)){ Write-Host "fabrika klasoru yok"; exit 1 }

function Fold($s){ return ("$s".ToLowerInvariant().Trim() -replace 'ç','c' -replace 'ğ','g' -replace 'ı','i' -replace 'ö','o' -replace 'ş','s' -replace 'ü','u' -replace '\s+',' ') }
function SikMetni($s){ return @($s.siklar.PSObject.Properties | Where-Object { $_.Name -match '^[A-E]$' } | ForEach-Object { "$($_.Value)" }) -join ' ' }
function KokAnahtar($s){ return (Fold $s.soru) + '||' + (Fold (SikMetni $s)) }

# ---- 1. TUM yerel havuzu tara: mukerrer tespiti icin tam liste gerekli
$dosyalar = @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)
$sayac = @{}
foreach($d in $dosyalar){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($x.sorular)){ if(-not $s){ continue }
    $k = KokAnahtar $s
    if($sayac.ContainsKey($k)){ $sayac[$k]++ } else { $sayac[$k] = 1 } } }
Write-Host ("Yerel havuz: {0} tekil kok+sik anahtari" -f $sayac.Count)

# ---- 2. Dosya dosya onar
$ist = [ordered]@{ sikTemizlendi=0; cevapKurtarildi=0; yanlisAlarmSik=0; yanlisAlarmKok=0;
                   gercekMukerrer=0; gercekTekrarSik=0; hapYazilacak=0; dokunulmadi=0 }
$okumaKuyrugu = New-Object System.Collections.Generic.List[object]

foreach($d in $dosyalar){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'karantina'){ continue }
    $r = "$($s.redSebep)"
    if($r -notmatch 'tekrar-eden-sik|sik-sayisi|bos-sik|hap-zayif|mukerrer-kok'){ $ist.dokunulmadi++; continue }
    $onarim = New-Object System.Collections.Generic.List[string]

    # --- (a) siklara sizan A-E disi anahtarlar
    $fazla = @($s.siklar.PSObject.Properties | Where-Object { $_.Name -notmatch '^[A-E]$' })
    foreach($p in $fazla){
      # dogru cevap siklarin icine dusmusse ve ust alan bossa YUKARI TASI (yoksa
      # sorunun cevabi kalmaz - tobin vergisi vakasi)
      if($p.Name -eq 'dogru' -and "$($p.Value)".Trim() -match '^[A-E]$' -and "$($s.dogru)".Trim().Length -eq 0){
        $s.dogru = "$($p.Value)".Trim()
        $onarim.Add("dogru cevap siklardan ust alana tasindi ($($s.dogru))")
        $ist.cevapKurtarildi++
      }
      $s.siklar.PSObject.Properties.Remove($p.Name)
      $onarim.Add("siklardan A-E disi anahtar cikarildi: $($p.Name)")
      $degisti = $true
    }
    if($fazla.Count -gt 0){ $ist.sikTemizlendi++ }

    # --- (b) tekrar-eden-sik: siklar GERCEKTEN ayni mi?
    if($r -match 'tekrar-eden-sik'){
      $v = @($s.siklar.PSObject.Properties | Where-Object { $_.Name -match '^[A-E]$' } | ForEach-Object { (Fold $_.Value) } | Where-Object { $_.Length -gt 0 })
      $tekil = @($v | Select-Object -Unique).Count
      if($tekil -eq $v.Count){
        $onarim.Add("YANLIS ALARM: bes sikkin hepsi birbirinden farkli - tekrar yok")
        $ist.yanlisAlarmSik++
      } else {
        $onarim.Add("GERCEK KUSUR: birebir ayni sik var, sik metni duzeltilmeli")
        $ist.gercekTekrarSik++
      }
      $degisti = $true
    }

    # --- (c) mukerrer-kok: ikizi gercekten var mi?
    if($r -match 'mukerrer-kok'){
      if($sayac[(KokAnahtar $s)] -gt 1){
        $onarim.Add("GERCEK MUKERRER: ayni kok VE ayni siklar havuzda tekrar ediyor")
        $ist.gercekMukerrer++
      } else {
        $onarim.Add("YANLIS ALARM: eski kural kokun ilk 60 karakterine bakiyordu; bu sorunun havuzda ikizi YOK")
        $ist.yanlisAlarmKok++
      }
      $degisti = $true
    }

    # --- (d) hap-zayif
    if($r -match 'hap-zayif'){
      if("$($s.hap)".Trim().Length -eq 0){
        $onarim.Add("hap alani BOS - GM elle yazacak")
        $ist.hapYazilacak++
      } else {
        $onarim.Add("YANLIS ALARM: hap alani dolu")
      }
      $degisti = $true
    }

    if($onarim.Count -gt 0){
      $s | Add-Member -NotePropertyName onarim -NotePropertyValue ($onarim -join ' | ') -Force
      $s | Add-Member -NotePropertyName onarimTarih -NotePropertyValue "28.07.2026" -Force
      # durum DEGISMEZ: karantinadan cikarma karari GM okumasina aittir
      $okumaKuyrugu.Add([ordered]@{ dosya=$d.Name; id="$($s.id)"; ders="$($s.ders)"; konu="$($s.konu)";
        sebep=$r; onarim=($onarim -join ' | ') })
    }
  }

  if($degisti){
    [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
  }
}

Write-Host ""
Write-Host "======== MEKANIK ONARIM SONUCU ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-20} {1}" -f $k, $ist[$k]) }

$kuyrukYol = Join-Path $kok "veri\gm-okuma-kuyrugu.json"
[IO.File]::WriteAllText($kuyrukYol, ([ordered]@{ guncelleme="28.07.2026"; adet=$okumaKuyrugu.Count; kayitlar=$okumaKuyrugu } | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host ("-> okuma kuyrugu: veri/gm-okuma-kuyrugu.json ({0} kayit)" -f $okumaKuyrugu.Count)
Write-Host "NOT: hicbir soru kasaya girmedi. durum='karantina' korundu."
