# ============================================================================
#  RENK SABITI DENETCISI — sabit yazilmis renk borcu ARTAMAZ.
#
#  NEDEN VAR (25.08.2026)
#  Site koyu temadan acik temaya gecerken 551 kontrast kirigi cikti. Hepsinin
#  koku ayniydi: renk bir yere SABIT yazilmisti ve tema degisince o yer
#  degismedi. Uc ayri yazim bicimine saklanmisti:
#      color:#93a1b3                                  duz
#      linear-gradient(...),#0d141e                   degrade YEDEGI
#      background:rgba(6,9,15,.85)                    yari saydam
#  Kontrast kapisi (arac/kontrast-kapisi.js) SONUCU yakalar. Bu denetci
#  SEBEBI yakalar - ve sebep henuz ekrana yansimadan.
#
#  NEDEN TOPTAN YASAK DEGIL
#  Bugun 62 dosyada 398 sabit renk var. Cogu mesru: marka amberi, basari
#  yesili, koyu bandin bilerek sabit tutulan zemini. Hepsini bir gecede
#  jetona cevirmek hem buyuk hem riskli. Bu yuzden kapi CIRCIR calisir:
#      borc ARTAMAZ  ·  azalabilir  ·  yeni dosya SIFIRDAN baslar
#  Boylece bugunku borc olduğu yerde donar, yeni kod temiz gelmek zorunda.
#
#  TABAN DOSYASI: veri/renk-sabiti-taban.json  (dosya adi -> izinli sayi)
#  Borc odendiginde taban kendiliginden GUNCELLENMEZ - bilerek. Azalmayi
#  gorup tabani elle indirmek, odenen borcun geri alinmasini engeller:
#      pwsh arac/renk-sabiti-denetcisi.ps1 -Tazele
#
#  KAPSAM DISI: stil.css ve stil-acik.css — jetonlarin TANIMLANDIGI yer.
#  Renk oraya yazilir; kapinin amaci zaten renkleri oraya toplamaktir.
#
#  GEREKCELI BORC (25.08 taramasinda tek tek bakildi, JETONA CEVRILMEYECEK)
#  Sabit renk her zaman kusur degildir. Su uc oberk bilerek sabit kalir:
#    1. MARKA VE DURUM RENKLERI dolgu olarak: #f5a524 / #ffc24b (amber),
#       #3ddc97 (basari), ve bunlarin uzerine binen koyu murekkep #03101f /
#       #03140d / #0a0c10 / #20160a. Bunlar iki temada da AYNI kalmali -
#       jetona baglanirsa marka rengi temayla birlikte kayar.
#    2. BASKI STILLERI: senaryo-raporu.html icindeki "@media print" blogu
#       (23 renk). Kagit her zaman beyazdir; oradaki #111/#333/#ccc
#       DOGRUDUR. Jetona baglanirsa site koyuya donunce ciktilar bozulur.
#    3. KAGIT PALETI: marka-rapor.html mukellefe gonderilen bir BELGEDIR,
#       sitenin temasini bilerek izlemez (kendi :root'u sayfanin sonunda,
#       stil-acik.css'ten SONRA durur ki gercekten kazansin).
#    4. GOSTERIM SAHNELERI: tetikte-marka.html markayi KOYU ve ACIK zemin
#       uzerinde yan yana gosteren bir ic calisma sayfasidir; iki sahne de
#       SABIT olmali, yoksa karsilastirmanin anlami kalmaz. Ayni sekilde
#       deneme.html'deki "temaSepya" sinif varyanti bilerek sicak kagittir.
#
#  25.08 ODEME TURU: 398 -> 328. Kalan gercek borc ~24 satir; gerisi
#  yukaridaki dort oberkte. Odenirken bulunan iki GERCEK kusur:
#    - gtip-ara.js arama sonuc karti "background:#06090f" sabitti; acik
#      temada var(--ink) siyah kartin uzerine biniyordu (1,13). Kart ancak
#      arama yapilinca olustugu icin kontrast kapisi goremiyordu. Dort
#      sayfayi etkiliyordu (gtip, fiyatfarki, senaryo-raporu, index).
#    - canli-deneme.html JS ile uretilen sik zemini "#0d1016" sabitti.
#  Bu ucu tabanda durur ve kapiyi dusurmez; amac YENI sabit renk eklenmesini
#  engellemek, mesru olanlari kovalamak degil.
#
#  API maliyeti SIFIR. Dis baglanti YOK.
# ============================================================================
param([switch]$Tazele)

$ErrorActionPreference = "Stop"
$kok = (git rev-parse --show-toplevel).Trim()
Set-Location $kok

$tabanYol = Join-Path $kok "veri\renk-sabiti-taban.json"
$muaf     = @("stil.css", "stil-acik.css")

# color/background/border/fill/stroke degerinde gecen her hex - degrade
# duraklari ve yari saydam yedekler dahil.
$desen = '(?:color|background|background-color|border[a-z-]*|fill|stroke)\s*:\s*[^;}"]*#[0-9a-fA-F]{3,8}'

$dosyalar = Get-ChildItem -Path $kok -File |
            Where-Object { $_.Extension -in @(".html", ".js", ".css") } |
            Where-Object { $muaf -notcontains $_.Name } |
            Sort-Object Name

if (-not $dosyalar) { Write-Host "RENK SABITI DENETCISI: kokte dosya yok, atlandi."; exit 0 }

$simdi = [ordered]@{}
foreach ($d in $dosyalar) {
  $metin = Get-Content $d.FullName -Raw -Encoding UTF8
  if ($null -eq $metin) { $metin = "" }
  $n = ([regex]::Matches($metin, $desen)).Count
  if ($n -gt 0) { $simdi[$d.Name] = $n }
}

$toplam = ($simdi.Values | Measure-Object -Sum).Sum
if ($null -eq $toplam) { $toplam = 0 }

# --- taban tazeleme -------------------------------------------------------
if ($Tazele) {
  # BOM'SUZ yazilir. PowerShell 5.1'de "Set-Content -Encoding UTF8" dosyanin
  # basina BOM koyar; BOM'lu JSON'u PowerShell okur ama Node/Python gibi
  # standart ayristiricilar "Unexpected token" diye REDDEDER. Depoda JSON'u
  # okuyan her sey PowerShell degil - bu yuzden BOM'suz yaziyoruz.
  [IO.File]::WriteAllText($tabanYol, ($simdi | ConvertTo-Json), (New-Object Text.UTF8Encoding $false))
  Write-Host ("RENK SABITI DENETCISI: taban tazelendi - {0} dosya, {1} sabit renk." -f $simdi.Count, $toplam)
  Write-Host "  $tabanYol"
  exit 0
}

if (-not (Test-Path -LiteralPath $tabanYol)) {
  # Kor kalma kurali: taban yoksa "temiz" demeyiz.
  Write-Host "RENK SABITI DENETCISI: KOR — taban dosyasi yok, karsilastirma YAPILAMADI."
  Write-Host "  Kur: pwsh arac/renk-sabiti-denetcisi.ps1 -Tazele"
  exit 1
}

$taban = @{}
(Get-Content $tabanYol -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties |
  ForEach-Object { $taban[$_.Name] = [int]$_.Value }

$tabanToplam = 0; $taban.Values | ForEach-Object { $tabanToplam += $_ }

Write-Host ("RENK SABITI DENETCISI: {0} dosya denetlendi. Sabit renk {1} (taban {2})." -f `
            $dosyalar.Count, $toplam, $tabanToplam)

$artan = @(); $yeni = @(); $azalan = @()
foreach ($ad in $simdi.Keys) {
  $s = $simdi[$ad]
  if (-not $taban.ContainsKey($ad)) { $yeni += [pscustomobject]@{ Ad=$ad; Simdi=$s } }
  elseif ($s -gt $taban[$ad])       { $artan += [pscustomobject]@{ Ad=$ad; Taban=$taban[$ad]; Simdi=$s } }
  elseif ($s -lt $taban[$ad])       { $azalan += [pscustomobject]@{ Ad=$ad; Taban=$taban[$ad]; Simdi=$s } }
}
foreach ($ad in $taban.Keys) {
  if (-not $simdi.Contains($ad)) { $azalan += [pscustomobject]@{ Ad=$ad; Taban=$taban[$ad]; Simdi=0 } }
}

if ($azalan.Count -gt 0) {
  Write-Host ""
  Write-Host "  Borc azalmis (tebrikler) - tabani indir ki geri alinamasin:"
  foreach ($a in ($azalan | Sort-Object { $_.Taban - $_.Simdi } -Descending)) {
    Write-Host ("    {0,-26} {1} -> {2}" -f $a.Ad, $a.Taban, $a.Simdi)
  }
  Write-Host "    pwsh arac/renk-sabiti-denetcisi.ps1 -Tazele"
}

if ($artan.Count -eq 0 -and $yeni.Count -eq 0) {
  Write-Host "  Temiz - yeni sabit renk eklenmemis."
  exit 0
}

Write-Host ""
Write-Host "  KIRMIZI - sabit yazilmis renk EKLENMIS:"
foreach ($a in $artan) {
  Write-Host ("    {0,-26} {1} -> {2}   (+{3})" -f $a.Ad, $a.Taban, $a.Simdi, ($a.Simdi - $a.Taban))
}
foreach ($y in $yeni) {
  Write-Host ("    {0,-26} YENI DOSYA, {1} sabit renk" -f $y.Ad, $y.Simdi)
}
Write-Host ""
Write-Host "  Tema jetonlarini kullan - iki temada da dogru calisirlar:"
Write-Host "    metin  var(--ink) var(--muted) var(--dim) var(--amber) var(--link)"
Write-Host "    zemin  var(--taban) var(--yuzey) var(--kagit) var(--amber-dolgu)"
Write-Host "    durum  var(--red) var(--green)"
Write-Host ""
Write-Host "  DIKKAT - kolay kacan iki bicim:"
Write-Host "    linear-gradient(...),#0d141e     degrade YEDEGI de sabittir"
Write-Host "    background:rgba(6,9,15,.85)      yari saydam koyu da sabittir"
Write-Host ""
Write-Host "  Renk gercekten sabit kalmali ise (marka rengi, bilerek koyu bant)"
Write-Host "  tabani tazele ve commit mesajinda NEDEN oldugunu yaz."
exit 1
