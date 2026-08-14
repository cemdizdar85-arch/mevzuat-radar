# ============================================================================
#  SITE DENETIMI (14.08) - Cem: "siteye tekrar bak sorun kaldi mi".
#  Tum HTML sayfalarini tarar ve SOMUT kusur arar:
#   1) KIRIK IC BAGLANTI  : href="x.html" ama dosya yok
#   2) EKSIK VERI DOSYASI : fetch('veri/x.json') ama dosya yok
#   3) BOZUK TURKCE       : mojibake izi (Ã¼, Å, Ä°, â€ gibi)
#   4) EKSIK MENU         : menu.js yok (site standardi)
#   5) BOS/EKSIK TITLE    : arama motoru ve sekme adi
#   6) KAPANMAMIS HTML    : </body></html> yok ya da cift
#  OLCUM betigi - hicbir sey yazmaz.
# ============================================================================
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
Set-Location $kok

$sayfalar = @(Get-ChildItem $kok -Filter *.html | Where-Object { $_.Name -notmatch '^_|test|yedek' })
Write-Host ("Taranan sayfa: {0}`n" -f $sayfalar.Count)

$kirikBag = @(); $eksikVeri = @(); $bozukTr = @(); $menuYok = @(); $titleYok = @(); $yapiBozuk = @()
$mojibake = [regex]'Ã[¼¶§Ÿ°Š]|â€™|â€œ|Å|Ä±|Ä°'

foreach($f in $sayfalar){
  $t = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
  $ad = $f.Name

  # 1) ic baglantilar
  foreach($m in ([regex]'href="([a-z0-9\-]+\.html)(?:[?#][^"]*)?"').Matches($t)){
    $hedef = $m.Groups[1].Value
    if(-not (Test-Path (Join-Path $kok $hedef))){ $kirikBag += "$ad -> $hedef" }
  }
  # 2) veri dosyalari
  foreach($m in ([regex]"veri/([a-z0-9\-\.]+\.json)").Matches($t)){
    $hedef = "veri/" + $m.Groups[1].Value
    if(-not (Test-Path (Join-Path $kok $hedef))){ $eksikVeri += "$ad -> $hedef" }
  }
  # 3) bozuk turkce (script/stil disinda, govde metninde)
  $govde = ($t -replace '(?s)<script.*?</script>','') -replace '(?s)<style.*?</style>',''
  $mm = $mojibake.Matches($govde)
  if($mm.Count){ $bozukTr += ("{0} ({1} iz, ornek: {2})" -f $ad, $mm.Count, $mm[0].Value) }
  # 4) menu
  # IC BELGE ISTISNASI (14.08): menusuz sayfa her zaman kusur degil. Bilincli ic
  # belgeler var (soru denetim masasi, kurulum kilavuzu, marka taslagi) - bunlar
  # SITEYE ACIK DEGIL: noindex tasiyorlar, basliklarinda "(ic belge)"/"(ic calisma)"
  # yaziyor ve hicbir yerden baglanti verilmiyor. Menuye eklenmemeleri KARAR.
  # Istisna DAR tutulur: yalniz noindex + baslikta ic-belge damgasi olan sayfa.
  # Boylece gercekten menu unutulmus bir arac sayfasi yine YAKALANIR.
  $icBelge = ($t -match 'noindex') -and ($t -match '(?i)<title>[^<]*\((?:iç belge|ic belge|iç çalışma|ic calisma)\)')
  if($t -notmatch 'menu\.js' -and -not $icBelge){ $menuYok += $ad }
  # 5) title
  $tm = [regex]::Match($t,'(?s)<title>(.*?)</title>')
  if(-not $tm.Success -or $tm.Groups[1].Value.Trim().Length -lt 8){ $titleYok += $ad }
  # 6) yapi
  $bodyKapanis = ([regex]::Matches($t,'</body>')).Count
  $htmlKapanis = ([regex]::Matches($t,'</html>')).Count
  if($bodyKapanis -ne 1 -or $htmlKapanis -ne 1){ $yapiBozuk += ("{0} (</body>={1} </html>={2})" -f $ad,$bodyKapanis,$htmlKapanis) }
}

function Yaz($baslik, $liste){
  Write-Host ("{0,-34} {1}" -f $baslik, $(if($liste.Count){"$($liste.Count) BULGU"}else{"temiz"}))
  foreach($x in ($liste | Select-Object -Unique | Select-Object -First 12)){ Write-Host ("    - " + $x) }
}
Yaz "1) Kirik ic baglanti"      $kirikBag
Yaz "2) Eksik veri dosyasi"     $eksikVeri
Yaz "3) Bozuk Turkce (mojibake)" $bozukTr
Yaz "4) menu.js eksik"          $menuYok
Yaz "5) Title eksik/kisa"       $titleYok
Yaz "6) HTML yapisi bozuk"      $yapiBozuk

$toplam = $kirikBag.Count + $eksikVeri.Count + $bozukTr.Count + $menuYok.Count + $titleYok.Count + $yapiBozuk.Count
Write-Host ("`n=== TOPLAM BULGU: {0} ===" -f $toplam)
