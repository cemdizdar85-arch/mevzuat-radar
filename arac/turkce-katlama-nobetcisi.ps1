# ============================================================================
#  TÜRKÇE KATLAMA NÖBETÇİSİ — "I" ile "ı" karıştıran eşleştirme yayına çıkamaz
#
#  NEDEN VAR (30.08.2026): PowerShell'in `-match`, `.ToLower()`, `.ToUpper()`
#  işlemleri IgnoreCase için CurrentCulture kullanır. tr-TR makinede:
#      "IFLASINA".ToLower()  -> "ıflasına"   ('iflas' arayan desen ISKALAR)
#      "SINAV".ToLower()     -> "sınav"      ('sinav' arayan desen ISKALAR)
#  en-US runner'da ise:
#      "İNKILAP".ToLower()   -> "i̇nkilap"    (i + U+0307 birleşen nokta)
#      ve sonraki `-replace 'İ','i'` onu BULAMAZ.
#  Yani aynı kod iki makinede iki farklı sonuç verir; kusur sessizdir —
#  kapı hiçbir şey bulamaz ve "temiz" der.
#
#  BU KUSUR İKİ KEZ CANLI YAŞANDI:
#   · alacak damgası: 456 kaydın 456'sı "desteksiz" göründü, gerçekte 32'ydi
#     (424 yanlış alarm). Kaynağı `-match 'iflas'` idi, Katla() yoktu.
#   · ders-karnesi.ps1 `ResmiDers()`: 6 vakanın 4'ünde ders eşleşmesi
#     tutmuyordu (INKILAP, SINAV, Iflas, İNKILAP) — ve yalnız YERELDE.
#
#  ÖLÇÜT — CIRCIR (renk sabiti denetçisiyle aynı desen): bugünkü riskli
#  satır sayısı tabandan FAZLAYSA kırmızı. Var olan borç kapıyı sürekli
#  kırmızı tutmaz (sürekli kırmızı kapı kapı değildir); yalnız YENİ borç
#  eklenmesini engeller.
#
#  DOĞRUSU NASIL YAZILIR:
#      $s = $metin.Replace('İ','I').Replace('ı','i')... .ToLowerInvariant()
#  Önce ASCII'ye KATLA, SONRA kültürden bağımsız küçült. Ters sıra en-US'ta
#  bozulur. Örnek: motor/alacak-ilan-okuyucu-pilot.ps1 > function Katla.
#
#  Kullanım:  powershell -NoProfile -File arac/turkce-katlama-nobetcisi.ps1
#             ... -Tazele    (borç azaldıysa tabanı indir)
#             ... -Ayrinti   (riskli satırları tek tek bas)
# ============================================================================
param([switch]$Tazele, [switch]$Ayrinti)

$ErrorActionPreference = 'Continue'
$KOK   = Split-Path $PSScriptRoot -Parent
$TABAN = Join-Path $KOK 'veri\katlama-taban.json'

# --- RİSKLİ Mİ? Tek satırı sınıflandırır ----------------------------------
# Bu işlev kapının kalbidir; öz-sınavı aşağıda.
function RiskliSatir([string]$satir){
  if($satir -notmatch '\.ToLower\(\)|\.ToUpper\(\)'){ return $false }
  # yorum satırı sayılmaz (bu dosyanın kendi açıklamaları da öyle)
  if($satir -match '^\s*#'){ return $false }
  # zaten kültürden bağımsız
  if($satir -match 'ToLowerInvariant|ToUpperInvariant'){ return $false }
  # dosya adı / yol üretimi: "$tur.ToLower()" -> "mal", "yapim" (ASCII sabitler)
  if($satir -match 'Join-Path|\.txt|\.pdf|\.zip|\.html|\.ham|\.json|\.csv|FileName|Split-Path'){ return $false }
  # hash/hex küçültme: ASCII, kültür etkisi yok
  if($satir -match 'BitConverter|ComputeHash|MD5|SHA\d|\.Replace\(''-'''){ return $false }
  # URL/host: ASCII
  if($satir -match '\[System\.Uri\]|\.Host\b|https?:'){ return $false }
  return $true
}

# --- ÖZ-SINAV (93 kapı kuralı) --------------------------------------------
# Vakaların hepsi bu depodan GERÇEK satırlardır; "bekleniyor" sütunu elle
# okunmuştur. Kapı gevşerse ya da sıkışırsa burada patlar ve ÖLÇÜM YAPILMAZ.
$SINAV = @(
  # riskli olanlar - hepsi gerçek kusur ya da gerçek risk
  @{ s = '  $k = "$konu".ToLower()';                                        b = $true  },
  @{ s = '    $s = "$t".ToLower()';                                         b = $true  },
  @{ s = '  $anahtar = ("$($a.advertiserName)|$b").ToLower()';              b = $true  },
  @{ s = '  $sec = $sec.ToLower()';                                         b = $true  },
  # güvenli olanlar - kapı bunlara KONUŞMAMALI
  @{ s = '$hazir = Join-Path $Klasor ("bulten-{0}.txt" -f $tur.ToLower())'; b = $false },
  @{ s = '$h = [BitConverter]::ToString($md5.ComputeHash($b)).ToLower()';   b = $false },
  @{ s = 'try { $h = ([System.Uri]$url).Host.ToLower() } catch { }';        b = $false },
  @{ s = '  $s = $t.Replace(''İ'',''I'').ToLowerInvariant()';               b = $false },
  @{ s = '  # burada .ToLower() kullanilmamali diye yazilmis bir yorum';    b = $false }
)
$kotu = @($SINAV | Where-Object { (RiskliSatir $_.s) -ne $_.b })
if($kotu.Count){
  Write-Host "OZ-SINAV DUSTU - kapi bozuk, olcum YAPILMADI:" -ForegroundColor Red
  $kotu | ForEach-Object { Write-Host ("  beklenen={0}  satir: {1}" -f $_.b, $_.s) -ForegroundColor Red }
  exit 2
}

# --- ölçüm ----------------------------------------------------------------
$dosyalar = @(Get-ChildItem (Join-Path $KOK 'motor\*.ps1') -File) +
            @(Get-ChildItem (Join-Path $KOK 'arac\*.ps1')  -File)
$bugun = @{}
$ayrintiListe = @()
foreach($f in ($dosyalar | Sort-Object Name)){
  if($f.Name -eq 'turkce-katlama-nobetcisi.ps1'){ continue }   # kendi vakalarımız
  $satirlar = [System.IO.File]::ReadAllLines($f.FullName, [System.Text.Encoding]::UTF8)
  $n = 0
  for($i=0; $i -lt $satirlar.Count; $i++){
    if(RiskliSatir $satirlar[$i]){
      $n++
      $ayrintiListe += [pscustomobject]@{ Dosya=$f.Name; Satir=($i+1); Kod=$satirlar[$i].Trim() }
    }
  }
  if($n -gt 0){ $bugun[$f.Name] = $n }
}
$toplam = ($bugun.Values | Measure-Object -Sum).Sum
if(-not $toplam){ $toplam = 0 }

# --- taban ----------------------------------------------------------------
$tabanVar = Test-Path $TABAN
$tabanH = @{}
$tabanToplam = 0
if($tabanVar){
  $t = Get-Content $TABAN -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($p in $t.dosyalar.PSObject.Properties){ $tabanH[$p.Name] = [int]$p.Value }
  $tabanToplam = [int]$t.toplam
}

Write-Host ("TURKCE KATLAMA NOBETCISI: {0} betik denetlendi. Riskli satir {1} (taban {2})." -f $dosyalar.Count, $toplam, $(if($tabanVar){$tabanToplam}else{'YOK'}))

if($Ayrinti -and $ayrintiListe.Count){
  Write-Host ""
  Write-Host "RISKLI SATIRLAR:" -ForegroundColor Cyan
  $ayrintiListe | ForEach-Object {
    $k = $_.Kod; if($k.Length -gt 84){ $k = $k.Substring(0,84)+'...' }
    Write-Host ("  {0,-32} {1,5}: {2}" -f $_.Dosya, $_.Satir, $k)
  }
}

if($Tazele){
  $yaz = [ordered]@{
    aciklama = "Turkce katlama nobetcisinin tabani. Sayilar DOSYA BASINA riskli .ToLower()/.ToUpper() satiridir. Borc ARTARSA kapi kirmizi olur; azalirsa -Tazele ile indirilir. Dogrusu: once Replace ile ASCII'ye katla, SONRA ToLowerInvariant()."
    olcum    = (Get-Date).ToString('dd.MM.yyyy HH:mm')
    toplam   = $toplam
    dosyalar = [ordered]@{}
  }
  foreach($k in ($bugun.Keys | Sort-Object)){ $yaz.dosyalar[$k] = $bugun[$k] }
  ($yaz | ConvertTo-Json -Depth 4) | Set-Content $TABAN -Encoding UTF8
  Write-Host ("  taban tazelendi - {0} dosya, {1} riskli satir." -f $bugun.Count, $toplam) -ForegroundColor Green
  Write-Host ("  {0}" -f $TABAN) -ForegroundColor DarkGray
  exit 0
}

if(-not $tabanVar){
  Write-Host "  TABAN YOK - once bir kez tazele: ... -Tazele" -ForegroundColor Yellow
  exit 0
}

# --- cırcır: dosya bazında artış var mı? ----------------------------------
$artan = @(); $azalan = @()
foreach($d in ($bugun.Keys | Sort-Object)){
  $eski = if($tabanH.ContainsKey($d)){ $tabanH[$d] } else { 0 }
  if($bugun[$d] -gt $eski){ $artan  += ("    {0,-32} {1} -> {2}   (+{3})" -f $d, $eski, $bugun[$d], ($bugun[$d]-$eski)) }
  elseif($bugun[$d] -lt $eski){ $azalan += ("    {0,-32} {1} -> {2}" -f $d, $eski, $bugun[$d]) }
}
foreach($d in ($tabanH.Keys | Sort-Object)){
  if(-not $bugun.ContainsKey($d) -and $tabanH[$d] -gt 0){ $azalan += ("    {0,-32} {1} -> 0" -f $d, $tabanH[$d]) }
}

if($azalan.Count){
  Write-Host ""
  Write-Host "  Borc azalmis (tebrikler) - tabani indir ki geri alinamasin:" -ForegroundColor Green
  $azalan | ForEach-Object { Write-Host $_ -ForegroundColor Green }
  Write-Host "    powershell -NoProfile -File arac/turkce-katlama-nobetcisi.ps1 -Tazele" -ForegroundColor Green
}

if($artan.Count){
  Write-Host ""
  Write-Host "  KIRMIZI - kulture bagli kucultme EKLENMIS:" -ForegroundColor Red
  $artan | ForEach-Object { Write-Host $_ -ForegroundColor Red }
  Write-Host ""
  Write-Host "  Dogrusu: once ASCII'ye katla, SONRA kulturden bagimsiz kucult:" -ForegroundColor Yellow
  Write-Host "    `$s = `$metin.Replace([char]0x0130,'I').Replace([char]0x0131,'i')...ToLowerInvariant()" -ForegroundColor Yellow
  Write-Host "  Ornek: motor/alacak-ilan-okuyucu-pilot.ps1 > function Katla" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "  Kucultme gercekten kulture bagli olmali ise (or. yalniz ASCII sabit) tabani tazele ve NEDENINI commit'e yaz." -ForegroundColor Yellow
  exit 1
}

Write-Host "  Temiz - yeni kulture bagli kucultme eklenmemis." -ForegroundColor Green
exit 0
