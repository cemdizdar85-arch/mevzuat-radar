# ============================================================================
#  VITRIN SORU SECICI — ana sayfanin doner soru havuzunu uretir.
#
#  NEDEN VAR (13.09.2026)
#  Cem: "tiklasin ve cozsun, sinavda en cok sorulan Finansal Muhasebe sorusu
#  girsin, farkimizi bastan gorsun" + "ambardan sec, bazilari kullanilmayan
#  sorular, ona dikkat et" + "her gun ayni olmamasi onemli, 20 secersin sonra
#  onlar doner".
#
#  20 soruyu ELLE secmek hata kaynagidir; secim DORT KAPIDAN gecer:
#    K1 YAYINDA MI  - soru yayin listesinde olmali. veri/vitrin/01-sgs.json'daki
#                     tv26xx sorulari "denetimde" ve HICBIRI yayin listesinde
#                     degil; Cem'in uyardigi "kullanilmayan soru" onlardir.
#    K2 HIZA        - dogru sikkin aciklamasi "Ne soruluyor" ile baslamali.
#                     Olculdu (13.09): sgs-t1-fmuh-kolay partisinde 53 yayin
#                     sorusunun 52'si hizali, kp-33 KAYMIS (dogru D ama
#                     "Ne soruluyor" C'de). Kaymis soru vitrine cikarsa dogru
#                     cevabi veren adaya "tuzaga dustun" der.
#    K3 TUZAK ADI   - her yanlis sikkin ADI KONMUS tuzagi olmali. Genel "Tuzak"
#                     etiketi farkimizi bosa dusurur.
#    K4 BOY         - ilk ekran sismesin: soru <= 300, en uzun sik <= 95 karakter.
#
#  SIRALAMA: once cok tekrarlayan konu (donem buyukten kucuge), esitlikte kisa
#  soru. Boylece vitrinde hem sik cikan hem hizli okunan soru durur.
#
#  CIKTI: veri/vitrin-soru-havuzu.json  (ana sayfa gun bazli dondurur)
#  API maliyeti SIFIR. Dis baglanti YOK. Yalniz yerel dosya okur.
# ============================================================================
param(
  [int]$Adet = 20,
  [switch]$Kuru        # kuru kosu: dosyaya yazmaz, yalniz sayar
)

$ErrorActionPreference = "Stop"
# Depo koku once betigin KENDI yerinden turetilir; git'e bagimli kalmaz.
# (Depo disindan cagrilinca "git rev-parse" bos donuyor ve betik patliyordu.)
$depoKok = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $depoKok "veri"))) {
  $gitKok = (git rev-parse --show-toplevel 2>$null)
  if ($gitKok) { $depoKok = ([string]$gitKok).Trim() }
}
Set-Location $depoKok

$secimKok  = Join-Path $depoKok "veri\sinav\kaydir-secim"
$fabrikaKok = Join-Path $depoKok "veri\fabrika"
$hedefYol  = Join-Path $depoKok "veri\vitrin-soru-havuzu.json"

# Ders onceligi OLCUMDEN gelir (veri/sinav-tek-sayfa.json, dersler.sinav_soru):
# SGS'de Finansal Muhasebe 26 soru, Denetim 16, Maliyet 8. Vitrin agirligi da oyle.
$yayinDosyalari = @(
  @{ ders = "Finansal Muhasebe";  dosya = "yayin-sgs-finansal-muhasebe.json" },
  @{ ders = "Maliyet Muhasebesi"; dosya = "yayin-sgs-maliyet-muhasebesi.json" }
)

$TUZAK_DESEN = '^\s*([^:]{3,45}[Tt]uza[gğ][ıi])\s*:\s*(.+)$'

function TuzakAyir {
  param([string]$Metin)
  # "Ad Tuzagi: aciklama" -> ad + metin. Ad yoksa $null doner (K3 kapisi).
  if ([string]::IsNullOrWhiteSpace($Metin)) { return $null }
  $e = [regex]::Match($Metin, $TUZAK_DESEN)
  if (-not $e.Success) { return $null }
  return [pscustomobject]@{ ad = $e.Groups[1].Value.Trim(); metin = $e.Groups[2].Value.Trim() }
}

$adaylar = New-Object System.Collections.Generic.List[object]
$sayac = [ordered]@{ bakilan = 0; govdesiz = 0; k2_hiza = 0; k3_tuzak = 0; k4_boy = 0; k6_cozum = 0; gecen = 0 }
$partiOnbellek = @{}

foreach ($grup in $yayinDosyalari) {
  $yayinYol = Join-Path $secimKok $grup.dosya
  if (-not (Test-Path -LiteralPath $yayinYol)) {
    Write-Host ("  ! yayin listesi yok, atlandi: {0}" -f $grup.dosya)
    continue
  }
  # K2 tuzagi (dizi sarma) icin ConvertFrom-Json dogrudan degiskene alinir.
  $yayinMetni = Get-Content $yayinYol -Raw -Encoding UTF8
  $yayinListesi = $yayinMetni | ConvertFrom-Json

  foreach ($kayit in $yayinListesi) {
    $sayac.bakilan++
    $etiket = [string]$kayit.etiket
    $soruKimlik = [string]$kayit.id
    if ([string]::IsNullOrWhiteSpace($etiket) -or [string]::IsNullOrWhiteSpace($soruKimlik)) { $sayac.govdesiz++; continue }

    if (-not $partiOnbellek.ContainsKey($etiket)) {
      $partiYol = Join-Path $fabrikaKok ("kalip-parti-{0}.json" -f $etiket)
      if (Test-Path -LiteralPath $partiYol) {
        $partiMetni = Get-Content $partiYol -Raw -Encoding UTF8
        $partiOnbellek[$etiket] = $partiMetni | ConvertFrom-Json
      } else {
        $partiOnbellek[$etiket] = $null
      }
    }
    $parti = $partiOnbellek[$etiket]
    if ($null -eq $parti) { $sayac.govdesiz++; continue }

    $soru = $parti.$soruKimlik
    if ($null -eq $soru -or $null -eq $soru.siklar -or $null -eq $soru.aciklama) { $sayac.govdesiz++; continue }
    if ([string]::IsNullOrWhiteSpace([string]$soru.soru) -or [string]::IsNullOrWhiteSpace([string]$soru.dogru)) { $sayac.govdesiz++; continue }

    $dogruHarf = ([string]$soru.dogru).Trim()

    # --- K2: HIZA ---------------------------------------------------------
    $dogruAciklama = [string]$soru.aciklama.$dogruHarf
    if ($dogruAciklama -notmatch 'Ne soruluyor') { $sayac.k2_hiza++; continue }

    # --- K4: BOY ----------------------------------------------------------
    $sikListesi = @($soru.siklar.PSObject.Properties)
    if ($sikListesi.Count -lt 4) { $sayac.govdesiz++; continue }
    $enUzunSik = 0
    foreach ($s in $sikListesi) {
      $u = ([string]$s.Value).Length
      if ($u -gt $enUzunSik) { $enUzunSik = $u }
    }
    if (([string]$soru.soru).Length -gt 300 -or $enUzunSik -gt 95) { $sayac.k4_boy++; continue }

    # --- K3: HER YANLIS SIKKIN ADI KONMUS TUZAGI ---------------------------
    $tuzaklar = [ordered]@{}
    $tuzakTam = $true
    foreach ($s in $sikListesi) {
      $harf = $s.Name
      if ($harf -eq $dogruHarf) { continue }
      $ayrilan = TuzakAyir -Metin ([string]$soru.aciklama.$harf)
      if ($null -eq $ayrilan) { $tuzakTam = $false; break }
      $tuzaklar[$harf] = [ordered]@{ ad = $ayrilan.ad; metin = $ayrilan.metin }
    }
    if (-not $tuzakTam) { $sayac.k3_tuzak++; continue }

    # --- K6: COZUM TABLOSU -------------------------------------------------
    # Vitrin sik SORMAZ, COZUMU GOSTERIR (Cem: "sik vermeyecektik, nasil
    # cozdugumuzu gosterecektik"). Gosterilecek tablo yoksa soru vitrine
    # cikamaz. En az iki satir gerekir: bir ara islem + bir sonuc.
    $cozumSatir = @()
    if ($soru.cozum_tablo -and $soru.cozum_tablo.satirlar) {
      foreach ($satir in $soru.cozum_tablo.satirlar) {
        $hucre = @($satir)
        if ($hucre.Count -ge 2) {
          $cozumSatir += ,@([string]$hucre[0], [string]$hucre[1])
        }
      }
    }
    if ($cozumSatir.Count -lt 2) { $sayac.k6_cozum++; continue }

    # "En sik hata" adimi: adimlar icinde "En sik hata" geceni.
    # BULUNAMAZSA adi konmus ilk tuzaktan doldurulur - vitrinde bu satir BOS
    # KALAMAZ, cunku farkimiz orada duruyor (13.09 olcumu: havuzdaki her
    # soruda yok, "gelir tahakkuku" sorusunda bos cikti).
    $enSikHata = ""
    if ($soru.adimlar) {
      foreach ($adim in $soru.adimlar) {
        $anlatim = [string]$adim.anlatim
        if ($anlatim -match 'En s[ıi]k hata') { $enSikHata = $anlatim; break }
      }
    }
    if ([string]::IsNullOrWhiteSpace($enSikHata)) {
      foreach ($harf in $tuzaklar.Keys) {
        $enSikHata = ("{0}: {1}" -f $tuzaklar[$harf].ad, $tuzaklar[$harf].metin)
        break
      }
    }
    if ([string]::IsNullOrWhiteSpace($enSikHata)) { $sayac.k6_cozum++; continue }

    $siklar = [ordered]@{}
    foreach ($s in $sikListesi) { $siklar[$s.Name] = [string]$s.Value }

    $sayac.gecen++
    $adaylar.Add([pscustomobject]@{
      id       = ("{0}/{1}" -f $etiket, $soruKimlik)
      ders     = $grup.ders
      konu     = [string]$soru.konu
      donem    = [int]$soru.donem
      soru     = [string]$soru.soru
      siklar   = $siklar
      dogru    = $dogruHarf
      hap      = [string]$soru.hap
      kural    = $dogruAciklama
      tuzak    = $tuzaklar
      dayanak  = (($soru.dayanak | Out-String).Trim())
      cozum    = $cozumSatir
      enSikHata = $enSikHata
      taktik   = ([string]$soru.sinav_taktigi)
      soruBoy  = ([string]$soru.soru).Length
    })
  }
}

Write-Host "VITRIN SORU SECICI"
Write-Host ("  bakilan yayin kaydi : {0}" -f $sayac.bakilan)
Write-Host ("  govdesi bulunamayan : {0}" -f $sayac.govdesiz)
Write-Host ("  K2 hiza dusuren     : {0}" -f $sayac.k2_hiza)
Write-Host ("  K3 adsiz tuzak      : {0}" -f $sayac.k3_tuzak)
Write-Host ("  K4 boy asan         : {0}" -f $sayac.k4_boy)
Write-Host ("  K6 cozum tablosuz   : {0}" -f $sayac.k6_cozum)
Write-Host ("  DORT KAPIDAN GECEN  : {0}" -f $sayac.gecen)

if ($adaylar.Count -eq 0) {
  Write-Host "  KIRMIZI - hicbir soru gecmedi, havuz YAZILMADI."
  exit 1
}

# Cok tekrarlayan konu once; esitlikte kisa soru once.
$siralanmis = $adaylar | Sort-Object @{ Expression = "donem"; Descending = $true }, @{ Expression = "soruBoy"; Descending = $false }

# --- K5: KONU CESITLILIGI -------------------------------------------------
# Ilk kosuda secilen 20'nin 5'i "muhasebe bilgi sistemi", 4'u "ozkaynak
# hesaplama" cikti: havuz donerken ziyaretci ayni soruyu farkli kelimelerle
# tekrar gorurdu. Her konudan EN IYI bir soru alinir; 20'ye ulasilmazsa
# kalan yerler ayni siralamayla ikinci turda doldurulur.
$secilen = New-Object System.Collections.Generic.List[object]
$gorulenKonu = New-Object System.Collections.Generic.HashSet[string]
foreach ($aday in $siralanmis) {
  if ($secilen.Count -ge $Adet) { break }
  $anahtar = ($aday.ders + "|" + $aday.konu).ToLowerInvariant()
  if ($gorulenKonu.Add($anahtar)) { $secilen.Add($aday) }
}
if ($secilen.Count -lt $Adet) {
  foreach ($aday in $siralanmis) {
    if ($secilen.Count -ge $Adet) { break }
    if (-not $secilen.Contains($aday)) { $secilen.Add($aday) }
  }
}

Write-Host ("  havuza alinan       : {0}" -f ($secilen.Count))
foreach ($x in $secilen) {
  Write-Host ("     {0,-34} {1,3} donem  {2,3} kr  {3}" -f $x.konu, $x.donem, $x.soruBoy, $x.id)
}

if ($Kuru) { Write-Host "  kuru kosu - dosyaya YAZILMADI."; exit 0 }

$cikti = [ordered]@{
  uretim  = (Get-Date -Format "yyyy-MM-dd HH:mm")
  uretici = "motor/vitrin-soru-sec.ps1"
  kapilar = "K1 yayinda · K2 aciklama hizasi · K3 adi konmus tuzak · K4 boy · K5 konu cesitliligi · K6 cozum tablosu"
  adet    = $secilen.Count
  sorular = @($secilen | Select-Object id, ders, konu, donem, soru, siklar, dogru, hap, kural, tuzak, dayanak, cozum, enSikHata, taktik)
}

# BOM'SUZ yazilir: BOM'lu JSON'u Node/tarayici ayristiricilari reddeder.
[IO.File]::WriteAllText($hedefYol, ($cikti | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding $false))
Write-Host ("  yazildi -> {0}" -f $hedefYol)
