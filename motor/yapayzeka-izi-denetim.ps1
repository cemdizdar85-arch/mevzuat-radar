# ============================================================================
#  YAPAY ZEKA IZI DENETIMI - kullanici-yuzu metinler (14.08.2026)
#
#  Cem: "yazilarda yapay zeka izi yok deme, o da onemli, siteyi yapay zeka yapti
#        denmesin" + "bunu aklimiza alalim, yapay zeka kontrol yapilsin."
#
#  NE YAPAR: her .html sayfasinin KULLANICIYA GORUNEN metnini (script/style ve
#  HTML etiketleri cikarilmis) tarar, yapay zeka yazisinin tipik izlerini sayar:
#    - Gecis kaliplari: "ayrica / bununla birlikte / ozellikle / ote yandan /
#      dolayisiyla / dahasi / ustelik / ne var ki / bilhassa / keza"
#    - Em-dash (—) yogunlugu: insan Turkce metninde nadir; AI cok kullanir.
#    - "sadece ... degil, ayni zamanda" paralel kalibi
#    - Ellipsis (…) yogunlugu
#  Esik asan sayfalar KIRMIZI raporlanir (exit 1). Hafizadaki ders: iz DILDE,
#  iskelette degil; tekduzelik hatadan cok ele verir. [[yapayzeka-kokusu]]
#
#  NOT: bu betik KOD YORUMLARINI saymaz (onlar kullaniciya gitmez) - yalniz
#  govde metni + JS template-string ("...") icindeki gorunur metin.
# ============================================================================
param([int]$EmDashEsik = 4)   # 1000 kelimede izin verilen em-dash tavani
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

$gecisKaliplari = @(
  'ayrıca','bununla birlikte','öte yandan','dolayısıyla','dahası','üstelik ',
  'ne var ki','bilhassa','keza','esasen','nitekim','öyle ki','bir bakıma',
  'kaldı ki','söz konusu','ilgili olarak','bağlamında','çerçevesinde'
)

# kullaniciya gorunen metni cikar: script/style at, sonra etiketleri at.
# JS template string'ler <script> icinde ama kullaniciya innerHTML ile gidiyor;
# onlari da tarayabilmek icin script'i ATMADAN once ` ile sinirli stringleri al.
function GovdeMetni([string]$html){
  # 1) HTML govde (script/style disi)
  $govde = ($html -replace '(?s)<script.*?</script>','') -replace '(?s)<style.*?</style>',''
  $govde = ($govde -replace '<[^>]+>',' ') -replace '&nbsp;',' ' -replace '&amp;','&'
  # 2) script icindeki template-string ve tirnakli Turkce metinler (kullaniciya innerHTML)
  $strler = ""
  foreach($m in [regex]::Matches($html, '`([^`]{15,})`')){ $strler += " " + $m.Groups[1].Value }
  return (($govde + " " + $strler) -replace '\s+',' ')
}

$sonuc = New-Object Collections.ArrayList
foreach($f in (Get-ChildItem $kok -Filter *.html)){
  $html = Get-Content $f.FullName -Raw -Encoding UTF8
  $metin = GovdeMetni $html
  $kelime = [math]::Max(1, (($metin -split '\s+').Count))
  $emdash = ([regex]::Matches($metin,'—')).Count
  $emdashBin = [math]::Round(1000.0*$emdash/$kelime, 1)
  $ellipsis = ([regex]::Matches($metin,'…|\.\.\.')).Count
  $gecis = 0; $bulunanKalip = @()
  foreach($k in $gecisKaliplari){ $n=([regex]::Matches($metin,"(?i)\b$([regex]::Escape($k))")).Count; if($n){ $gecis+=$n; $bulunanKalip += "$k×$n" } }
  $paralel = ([regex]::Matches($metin,'(?i)sadece[^.]{0,40}değil[^.]{0,25}(aynı zamanda|hem de)')).Count
  $skor = $gecis*2 + $paralel*2 + [math]::Max(0, $emdashBin - $EmDashEsik)
  if($skor -gt 0 -or $emdashBin -gt $EmDashEsik){
    [void]$sonuc.Add([pscustomobject]@{
      Sayfa=$f.Name; Kelime=$kelime; EmDashBin=$emdashBin; Ellipsis=$ellipsis
      Gecis=$gecis; Paralel=$paralel; Skor=[math]::Round($skor,1); Kalip=($bulunanKalip -join ', ')
    })
  }
}

Write-Host "=== YAPAY ZEKA IZI DENETIMI ===`n"
if(-not $sonuc.Count){ Write-Host "Temiz: hicbir sayfada esik ustu iz yok."; exit 0 }
$sonuc = @($sonuc | Sort-Object Skor -Descending)
Write-Host ("{0,-26} {1,6} {2,9} {3,6} {4,5} {5,6}" -f 'SAYFA','kelime','emdash/bin','geçiş','paral','skor')
foreach($r in $sonuc){
  Write-Host ("{0,-26} {1,6} {2,9} {3,6} {4,5} {5,6}" -f $r.Sayfa, $r.Kelime, $r.EmDashBin, $r.Gecis, $r.Paralel, $r.Skor)
  if($r.Kalip){ Write-Host ("      geçiş kalıbı: " + $r.Kalip) }
}
$kirmizi = @($sonuc | Where-Object { $_.Gecis -gt 0 -or $_.Paralel -gt 0 -or $_.EmDashBin -gt ($EmDashEsik*2) })
Write-Host ("`n{0} sayfa esik ustu. En yuksek em-dash/geçiş olanlari elle sadelestir." -f $sonuc.Count)
if($kirmizi.Count){ exit 1 } else { exit 0 }
