# ============================================================================
#  VERI KAPISI — bozuk veri SITEYE ULASAMAZ  (25.08.2026, Faz 1)
#
#  CEM (25.08): "sitede iki uc gunde bir veri aldiklari yer patliyor. Bunu
#  kalici olarak nasil bitiririz?"
#
#  OLCULEN KOK SEBEP (tahmin degil):
#    * 85 is akisi veri/*.json commit'liyor
#    * bunlardan YALNIZ 1'i commit ONCESI denetim yapiyor
#    * GitHub Pages DOGRUDAN main dalindan yayinliyor
#  Yani zincir su: robot yazar -> commit -> Pages ANINDA yayinlar -> site
#  patlar -> SONRA dogrula.yml kirmizi yanar. Bekci vardi ama KAPIDA DEGIL,
#  OLAY YERINDEYDI (ve o kapi 6 gundur kirmiziydi, kimse bakmiyordu).
#
#  BU BETIK O KAPIYI YERINE KOYAR. Robot commit'inden ONCE kosar:
#    - sozlesmeli her degisen veri dosyasini denetler
#    - GECMEYENI COMMIT ETTIRMEZ: `git checkout HEAD -- <dosya>` ile son
#      SAGLAM surumu geri koyar
#  Sonuc: site "bozuk" olamaz; en kotu ihtimalle "biraz eski" olur.
#
#  NEDEN GIT'TEKI SURUM "SON SAGLAM SURUM"?
#  Cunku HEAD'deki hali daha once bu kapidan gecmis olandir. Ayri bir yedek
#  deposu kurmaya gerek yok - git zaten surum deposu. Mimariyle uyumlu.
#
#  EN GUCLU TEK KURAL: HACIM DUSUSU.
#  Dis kaynak bozuldugunda genelde HATA VERMEZ; AZ veri ya da BOS doner. Bu
#  yuzden "kayit sayisi ya da bayt, oncekine gore %X'ten fazla dustuyse RED"
#  kurali sessiz bozulmalarin cogunu tek basina yakalar. (Ayni ders hafizada
#  zaten vardi: "yesil kosu != tam veri, yazma sonrasi sayim sart".)
#
#  KULLANIM:
#    pwsh arac/veri-kapisi.ps1                # degisen sozlesmeli dosyalari dener
#    pwsh arac/veri-kapisi.ps1 -Deneme        # RAPOR yazar, geri alma YAPMAZ
#    pwsh arac/veri-kapisi.ps1 -Dosya veri/x.json
#
#  CIKIS: 0 hepsi gecti (ya da denetlenecek dosya yok) · 1 en az bir dosya
#  REDDEDILDI ve geri alindi (veri GUVENDE ama robot bozuk uretiyor - bakilmali)
#
#  IS AKISINA BAGLAMA (git add'den ONCE):
#      - name: Veri kapisi (bozuk veri commit edilmesin)
#        shell: pwsh
#        run: ./arac/veri-kapisi.ps1
# ============================================================================
param(
  [string]$Dosya,          # tek dosya dene (bos = degisen tum sozlesmeli dosyalar)
  [switch]$Deneme          # prova: reddi RAPORLAR ama dosyayi geri ALMAZ
)
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot
Set-Location $kok

$sozYol = Join-Path $kok 'veri/_sozlesme.json'
if (-not (Test-Path $sozYol)) { Write-Host "veri/_sozlesme.json yok - kapi atlandi."; exit 0 }
$soz = Get-Content $sozYol -Raw -Encoding UTF8 | ConvertFrom-Json
$varsayilanTavan = if ($soz.varsayilan.dusus_tavani) { [double]$soz.varsayilan.dusus_tavani } else { 0.30 }

# --- KAYIT OLCUSU: bicimden bagimsiz olmali ---
# Dosyalarimiz uc bicimde: (a) dizi, (b) ust anahtarlari kayit olan nesne,
# (c) icinde buyuk dizi tasiyan kunye nesnesi. Ucunu de kapsayan tek olcu:
# max(ust anahtar sayisi, en buyuk ic dizi/nesne eleman sayisi).
function KayitSayisi($j) {
  if ($null -eq $j) { return 0 }
  if ($j -is [Array]) { return $j.Count }
  $ust = @($j.PSObject.Properties).Count
  $enb = 0
  foreach ($p in $j.PSObject.Properties) {
    if ($p.Value -is [Array]) { if ($p.Value.Count -gt $enb) { $enb = $p.Value.Count } }
    elseif ($p.Value -and -not ($p.Value -is [string]) -and -not ($p.Value -is [ValueType]) -and $p.Value.PSObject) {
      $ic = @($p.Value.PSObject.Properties).Count
      if ($ic -gt $enb) { $enb = $ic }
    }
  }
  return [Math]::Max($ust, $enb)
}

# --- hangi dosyalar denetlenecek ---
$sozlesmeli = @($soz.dosyalar.PSObject.Properties.Name)
if ($Dosya) {
  $adaylar = @($Dosya -replace '\\','/')
} else {
  # calisma agacinda HEAD'e gore degismis veri dosyalari
  $degisen = @(git diff --name-only HEAD -- 'veri/*.json' 2>$null) + @(git diff --name-only --cached HEAD -- 'veri/*.json' 2>$null)
  $adaylar = @($degisen | Where-Object { $_ } | ForEach-Object { $_ -replace '\\','/' } | Select-Object -Unique)
}
$denetlenecek = @($adaylar | Where-Object { $sozlesmeli -contains $_ })

Write-Host "=== VERI KAPISI ==="
Write-Host ("sozlesmeli dosya: {0} | degisen: {1} | denetlenecek: {2}" -f $sozlesmeli.Count, $adaylar.Count, $denetlenecek.Count)
if ($denetlenecek.Count -eq 0) {
  Write-Host "Denetlenecek sozlesmeli degisiklik yok - gecildi."
  exit 0
}

$red = New-Object System.Collections.ArrayList
$gecen = New-Object System.Collections.ArrayList

foreach ($f in $denetlenecek) {
  $k = $soz.dosyalar.$f
  $tavan = if ($k.dusus_tavani) { [double]$k.dusus_tavani } else { $varsayilanTavan }
  $asgari = if ($k.asgari_kayit) { [int]$k.asgari_kayit } else { 0 }
  $sebepler = New-Object System.Collections.ArrayList

  if (-not (Test-Path $f)) {
    [void]$sebepler.Add("dosya YOK")
  } else {
    $yeniBayt = (Get-Item $f).Length
    $yeniJ = $null
    try { $yeniJ = Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json } catch { [void]$sebepler.Add("JSON PARSE ETMIYOR: $($_.Exception.Message)") }

    if ($null -ne $yeniJ) {
      $yeniKayit = KayitSayisi $yeniJ
      if ($yeniKayit -lt $asgari) { [void]$sebepler.Add("kayit $yeniKayit < asgari $asgari") }

      # --- HACIM DUSUSU: HEAD'deki son saglam surumle karsilastir ---
      $eskiHam = $null
      try { $eskiHam = (git show "HEAD:$f" 2>$null) | Out-String } catch {}
      if ($eskiHam -and $eskiHam.Trim()) {
        $eskiBayt = [Text.Encoding]::UTF8.GetByteCount($eskiHam)
        $eskiKayit = 0
        try { $eskiKayit = KayitSayisi ($eskiHam | ConvertFrom-Json) } catch {}
        if ($eskiKayit -gt 0) {
          $dususK = ($eskiKayit - $yeniKayit) / [double]$eskiKayit
          if ($dususK -gt $tavan) { [void]$sebepler.Add(("kayit dususu %{0:N0} (>{1:P0}): {2} -> {3}" -f ($dususK*100), $tavan, $eskiKayit, $yeniKayit)) }
        }
        if ($eskiBayt -gt 0) {
          $dususB = ($eskiBayt - $yeniBayt) / [double]$eskiBayt
          if ($dususB -gt $tavan) { [void]$sebepler.Add(("bayt dususu %{0:N0} (>{1:P0}): {2} -> {3}" -f ($dususB*100), $tavan, $eskiBayt, $yeniBayt)) }
        }
      }
    }
  }

  if ($sebepler.Count -gt 0) {
    Write-Host ("  RED  {0}" -f $f)
    foreach ($s in $sebepler) { Write-Host ("        - {0}" -f $s) }
    [void]$red.Add([ordered]@{ dosya=$f; sebepler=@($sebepler) })
    if (-not $Deneme) {
      # SON SAGLAM SURUMU GERI KOY - yayin korunur
      git checkout HEAD -- $f 2>&1 | Out-Null
      Write-Host ("        -> son saglam surum geri konuldu (HEAD)")
    }
  } else {
    Write-Host ("  GECTI {0}" -f $f)
    [void]$gecen.Add($f)
  }
}

$rapor = [ordered]@{
  tarih   = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  deneme  = [bool]$Deneme
  denetlenen = $denetlenecek.Count
  gecen   = $gecen.Count
  red     = $red.Count
  reddedilenler = @($red)
  not = "RED olan dosya COMMIT EDILMEZ; HEAD'deki son saglam surum geri konur. Site bozuk veri gormez, en kotu ihtimalle bir tur eski veri gorur."
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/veri-kapisi-raporu.json'), ($rapor | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))

Write-Host "-----------------------------------------"
Write-Host ("VERI KAPISI: {0} gecti, {1} REDDEDILDI / {2}" -f $gecen.Count, $red.Count, $denetlenecek.Count)
if ($red.Count -gt 0) {
  Write-Host ""
  Write-Host "VERI GUVENDE (eski surum yerinde) ama BIR ROBOT BOZUK URETIYOR - bakilmali."
  Write-Host "Ayrinti: veri/veri-kapisi-raporu.json"
  exit 1
}
exit 0
