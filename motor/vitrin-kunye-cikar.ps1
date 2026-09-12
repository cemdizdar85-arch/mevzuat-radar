# ============================================================================
#  VITRIN KUNYE CIKARICI — ana sayfanin afis bilgisini URUNUN KENDISINDEN alir.
#
#  NEDEN VAR (13.09.2026)
#  Cem: "sen ayrintili bu buldugun soruyu tumden bizim site cozsen gorcen."
#  Coztum ve gordum: Kaydir-Coz karti benim ana sayfaya elle yazdigim
#  panelden cok daha zengin - sinav kunyesi, sure, "Ne saniyorsun / Aslinda /
#  Nereden anlarsin", VERILENLER/HESAP ayrimi, 9 adimli "Nobetci anlatiyor",
#  hesap kagidi. Elle taklit ettigim her sey hem fakir hem SAPMAYA mahkumdu
#  (kart ureten asil makine motor/kaydir-coz.ps1, 225 KB).
#  Cem "birinci yap" dedi: vitrin karti elle yazilmaz, URUNUN KENDISI gosterilir.
#
#  MEKANIZMA ZATEN VARDI:
#    kaydir/vitrin/sgs.html  ->  ?vitrin=1 ana sayfa vitrini icin yapilmis
#    (tema dugmesi gizlenir, kasaya cevap YAZILMAZ ki "en cok yaniltan soru"
#    olcumu vitrin tiklamasiyla kirlenmesin) ve #s=<sira> derin baglantisi
#    "ana sayfa karti -> gunun sorusu" icin yazilmis.
#
#  BU BETIK NE YAPAR: o sayfadaki gomulu SORULAR dizisinden yalnizca KUNYEYI
#  cikarir (sira, ders, konu, donem, sorunun ilk cumlesi). Ana sayfa 304 KB'lik
#  urun sayfasini yuklemeden afisi cizer; ziyaretci "Nobetci cozsun"e basinca
#  gercek kart cerceve icinde acilir.
#
#  CIKTI: veri/vitrin-kunye.json
#  API maliyeti SIFIR. Dis baglanti YOK. Yalniz yerel dosya okur.
# ============================================================================
param([switch]$Kuru)

$ErrorActionPreference = "Stop"
$depoKok = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $depoKok "veri"))) {
  $gitKok = (git rev-parse --show-toplevel 2>$null)
  if ($gitKok) { $depoKok = ([string]$gitKok).Trim() }
}
Set-Location $depoKok

$vitrinYol = Join-Path $depoKok "kaydir\vitrin\sgs.html"
$hedefYol  = Join-Path $depoKok "veri\vitrin-kunye.json"

if (-not (Test-Path -LiteralPath $vitrinYol)) {
  Write-Host "VITRIN KUNYE: KIRMIZI - kaydir/vitrin/sgs.html yok, kunye YAZILMADI."
  exit 1
}

$sayfa = Get-Content $vitrinYol -Raw -Encoding UTF8
$bas = $sayfa.IndexOf('const SORULAR=')
if ($bas -lt 0) {
  Write-Host "VITRIN KUNYE: KIRMIZI - sayfada 'const SORULAR=' bulunamadi."
  exit 1
}
# Dizi TEK SATIRDA duruyor; satirin tamami alinir, ilk '[' ile son ']' arasi
# ayristirilir. (Sabit uzunlukta kesmek JSON'u ortadan boler - denendi, patladi.)
$satirSonu = $sayfa.IndexOf("`n", $bas)
if ($satirSonu -lt 0) { $satirSonu = $sayfa.Length }
$satir = $sayfa.Substring($bas, $satirSonu - $bas)
$acik = $satir.IndexOf('[')
$kapali = $satir.LastIndexOf(']')
if ($acik -lt 0 -or $kapali -le $acik) {
  Write-Host "VITRIN KUNYE: KIRMIZI - SORULAR dizisi ayristirilamadi."
  exit 1
}
$sorularMetni = $satir.Substring($acik, $kapali - $acik + 1)
$sorular = $sorularMetni | ConvertFrom-Json

# Cikmis sinav taramasinin TABANI: "son N sinavin M tanesinde cikti" cumlesi
# buradan kurulur, rakam uydurulmaz.
$taranan = 0
$tekSayfaYol = Join-Path $depoKok "veri\sinav-tek-sayfa.json"
if (Test-Path -LiteralPath $tekSayfaYol) {
  $tekSayfaMetni = Get-Content $tekSayfaYol -Raw -Encoding UTF8
  $tekSayfa = $tekSayfaMetni | ConvertFrom-Json
  if ($tekSayfa.cikmis -and $tekSayfa.cikmis.sgs_siklik) {
    $taranan = [int]$tekSayfa.cikmis.sgs_siklik.donem
  }
}

$kartlar = New-Object System.Collections.Generic.List[object]
$sira = 0
foreach ($s in $sorular) {
  # ders alani "Ticaret Hukuku|Ticaret ve Borclar" gelebiliyor - ilk parca alinir.
  $ders = ([string]$s.ders).Split('|')[0].Trim()
  $soruMetni = ([string]$s.soru).Trim()
  # Afiste sorunun TAMAMI degil ilk cumlesi durur; tamami kartta acilir.
  $ilkCumle = $soruMetni
  $nokta = $soruMetni.IndexOf('. ')
  if ($nokta -gt 40) { $ilkCumle = $soruMetni.Substring(0, $nokta + 1) }
  if ($ilkCumle.Length -gt 200) { $ilkCumle = $ilkCumle.Substring(0, 197) + "..." }

  $kartlar.Add([ordered]@{
    sira  = $sira
    ders  = $ders
    konu  = ([string]$s.konu).Trim()
    donem = [int]$s.donem
    ozet  = $ilkCumle
  })
  $sira++
}

Write-Host "VITRIN KUNYE CIKARICI"
Write-Host ("  urun sayfasi   : kaydir/vitrin/sgs.html")
Write-Host ("  kart sayisi    : {0}" -f $kartlar.Count)
Write-Host ("  taranan donem  : {0}" -f $taranan)
foreach ($k in $kartlar) {
  Write-Host ("     s={0,-2} {1,-22} {2,-34} {3,2} donem" -f $k.sira, $k.ders, $k.konu, $k.donem)
}

if ($kartlar.Count -eq 0) {
  Write-Host "  KIRMIZI - kart cikmadi, kunye YAZILMADI."
  exit 1
}
if ($Kuru) { Write-Host "  kuru kosu - dosyaya YAZILMADI."; exit 0 }

$cikti = [ordered]@{
  uretim        = (Get-Date -Format "yyyy-MM-dd HH:mm")
  uretici       = "motor/vitrin-kunye-cikar.ps1"
  kaynak        = "kaydir/vitrin/sgs.html"
  baglanti      = "kaydir/vitrin/sgs.html?vitrin=1&tema=acik#s="
  taranan_donem = $taranan
  adet          = $kartlar.Count
  # ⛔ @($kartlar) YAZILMAZ: depoda kayitli K3 tuzagi (List patlamasi).
  # [ordered]@{} icinde List[object] '@()' ile sarilinca PowerShell
  # "Bagimsiz degisken turleri eslesmiyor" diye patliyor - denendi, patladi.
  kartlar       = $kartlar.ToArray()
}

# BOM'SUZ: BOM'lu JSON'u tarayici ayristiricilari reddeder.
[IO.File]::WriteAllText($hedefYol, ($cikti | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding $false))
Write-Host ("  yazildi -> {0}" -f $hedefYol)
