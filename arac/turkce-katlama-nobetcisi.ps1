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

# ============================================================================
#  31.08.2026 — KAPININ KÖR NOKTASI KAPANDI (SPL çıkmış sınav hasadında yandı)
#
#  Bu nöbetçi 30.08'de yalnız `.ToLower()/.ToUpper()` arıyordu. Bugün aynı
#  kökten İKİNCİ bir katman canlı vurdu ve kapı hiçbir şey görmedi:
#
#    `-replace` PowerShell'de VARSAYILAN OLARAK HARF AYIRMAZ.
#    Yani `-replace 'ç','c'` büyük 'Ç'yi DE yakalar ve yerine KÜÇÜK 'c' koyar:
#        "KİTAPÇIĞI" -> "KITAPcIgI"
#    Sonra bu bozuk metne desen tutturulmaya çalışılıyor ve tutmuyor.
#    Harf ayırmak için `-creplace` gerekir; ya da katlama ÖNCE
#    ToLowerInvariant() ile yapılır, ya da desen [çÇ] gibi İKİ HÂLİ de yazar.
#
#  CANLI VAKA: SPL arşiv sayfasındaki 334 kitapçık etiketi "A KİTAPÇIĞI" idi;
#  sınıflandırma 334 yerine 4 eşleşme buldu, yani kitapçıkların TAMAMI sessizce
#  eleniyordu — tam da "yarım yutma".
#
#  ⚠️ KAPININ HÂLÂ GÖREMEDİĞİ (dürüstçe yazıyorum, "kapsıyor" demiyorum):
#  Deseni SAF ASCII olan ama girdisi TÜRKÇE olan eşleştirme —
#      "ANAHTARI" -match '(?i)anahtari'
#  tr-TR'de FALSE, en-US runner'da TRUE döner. Satıra bakarak anlaşılamaz,
#  çünkü girdinin Türkçe olup olmadığı çalışma zamanında belli olur.
#  Bunun çaresi kapı değil KURAL: Türkçe metinle eşleştirme yapmadan önce
#  ASCII'ye katla, deseni küçük harf yaz, `(?i)` KULLANMA.
# ============================================================================

# --- RİSKLİ Mİ? (KATLAMA) Tek satırı sınıflandırır ------------------------
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

# --- RİSKLİ Mİ? (HARF AYIRMAYAN -replace / -match) ------------------------
# Kural: deseninde ÇIPLAK bir Türkçe harf geçen `-replace` / `-match` risklidir,
# çünkü operatör harf ayırmaz — büyük hâli de yakalanır ve yanlış hâlle
# değiştirilir. Üç şey satırı GÜVENLİ yapar:
#   (1) `-creplace` / `-cmatch`  : harf ayıran sürüm, bilinçli tercih
#   (2) `ToLowerInvariant()`     : metin zaten katlanmış, büyük hâl kalmadı
#   (3) `[çÇ]` gibi SINIF        : iki hâl de yazılmış, sonuç belirli
# 31.08 - KAPI ÖNCE YANLIŞ ALARM VERDİ, ÖLÇÜLDÜ VE DARALTILDI.
# İlk yazımı yalnız TEK SATIRA bakıyordu ve 8 dosyayı suçladı:
#     $s = $s.ToLowerInvariant()
#     return ($s -replace 'ı','i' -replace 'ş','s' ...)     <-- "riskli" dedi
# Oysa bu deponun DOĞRU deyimi tam olarak budur: önce küçült, sonra katla.
# Sekizinin sekizi de doğruydu. Suçlayan kapı, susan kapıdan beterdir
# (ev kuralı: ölçemediğine kusur deme). Bu yüzden ÖNCEKİ 3 SATIR da okunur.
function RiskliKatlamaDeseni([string]$satir, [string]$onceki = ''){
  if($satir -match '^\s*#'){ return '' }
  if($satir -notmatch '-(replace|match|notmatch)\b'){ return '' }
  if($satir -match '-(creplace|cmatch|cnotmatch)\b'){ return '' }
  if($satir -match 'ToLowerInvariant|ToUpperInvariant'){ return '' }
  # Metin bu satıra gelmeden önce küçültülmüşse büyük hâl kalmamıştır.
  # `.ToLower(...)` kültürü AÇIKÇA verilmiş hâli de sayılır (bilinçli tercih).
  if($onceki -match 'ToLowerInvariant|ToUpperInvariant|\.ToLower\('){ return '' }
  # Her desenin İÇİNDEN karakter sınıfları ([çÇ] gibi) ÇIKARILIR, geriye kalan
  # metinde Türkçe harf varsa desen ÇIPLAKTIR.
  # (İlk yazımım `(?<!\[)` ile tek karaktere bakıyordu; `[çÇ]` sınıfında 'Ç'
  #  köşeli parantezin hemen ardında olmadığı için sınıf yine riskli sayılıyordu
  #  — kapı doğru yazımı da suçluyordu. Öz-sınav bunu yakaladı.)
  # İki ayrı ağırlık, tek torbaya konmaz:
  #   desen-replace : metni BOZAR   (büyük 'Ç' de yakalanıp küçük 'c' olur)
  #   desen-match   : eşleşmeyi KAÇIRIR (tr-TR ile en-US farklı sonuç verir)
  $sonuc = ''
  foreach($m in [regex]::Matches($satir, "-(replace|match|notmatch)\s*'([^']*)'")){
    $desen = [regex]::Replace($m.Groups[2].Value, '\[[^\]]*\]', '')
    # `-cmatch` ŞART. `-match` harf ayırmaz ve tr-TR'de sınıftaki 'İ' ASCII 'i'
    # ile EŞLEŞİR: saf ASCII olan '(?i)kitapcigi' deseni "Türkçe harf içeriyor"
    # sanılıp riskli işaretleniyordu. Yani kapının kendisi tam da ölçmeye
    # çalıştığı tuzağa düştü — öz-sınav yakaladı (31.08).
    if($desen -cmatch '[çğıİöşüÇĞÖŞÜ]'){
      if($m.Groups[1].Value -eq 'replace'){ return 'desen-replace' }
      $sonuc = 'desen-match'
    }
  }
  return $sonuc
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

# --- ÖZ-SINAV 2: HARF AYIRMAYAN DESEN ------------------------------------
# Vakaların hepsi bu depodan GERÇEK satırlardır (31.08 taraması).
$SINAV2 = @(
  # RİSKLİ — çıplak Türkçe harf, önünde katlama yok
  @{ s = "  `$t = `$t -replace 'ç','c' -replace 'ğ','g' -replace 'ı','i'";                 b = $true  },
  @{ s = "  return (`$s -replace 'ç','c' -replace 'ğ','g' -replace 'ö','o')";              b = $true  },
  @{ s = "`$t = `$s -replace 'Ayrıntılı bilgi(y|si)?e?\s+EKAP',''";                        b = $true  },
  # GÜVENLİ — sınıf iki hâli de yazmış
  @{ s = "  `$s = `$s -replace '[çÇ]','c' -replace '[ğĞ]','g' -replace '[ıİ]','i'";        b = $false },
  # GÜVENLİ — metin zaten kültürden bağımsız katlanmış
  @{ s = "function Fold(`$s){ return (`"`$s`".ToLowerInvariant() -replace 'ç','c') }";     b = $false },
  # GÜVENLİ — harf ayıran sürüm bilinçli seçilmiş
  @{ s = "  `$t = `$t -creplace 'Ç','C' -creplace 'ç','c'";                                b = $false },
  # GÜVENLİ — desen saf ASCII (bu kapının GÖREMEDİĞİ katman; burada da susmalı)
  @{ s = "  if(`$etiket -match '(?i)kitapcigi'){ }";                                       b = $false },
  # GÜVENLİ — yorum satırı
  @{ s = "  # -replace 'ç','c' harf ayirmaz diye yazilmis bir yorum";                      b = $false },
  # GÜVENLİ — bu deponun DOĞRU deyimi: önceki satırda küçültme var
  @{ s = "  return (`$s -replace 'ı','i' -replace 'ş','s')"; o = "  `$s = `$s.ToLowerInvariant()"; b = $false },
  # GÜVENLİ — kültür AÇIKÇA verilmiş küçültme de sayılır
  @{ s = "  (`$s -replace 'ı','i' -replace 'ç','c')"; o = "  `$s = `$s.ToLower([CultureInfo]::GetCultureInfo('tr-TR'))"; b = $false },
  # RİSKLİ — önceki satırlarda küçültme YOK
  @{ s = "  return (`$s -replace 'ı','i' -replace 'ş','s')"; o = "  if(`$null -eq `$s){ return '' }"; b = $true }
)
$kotu2 = @($SINAV2 | Where-Object { [bool](RiskliKatlamaDeseni $_.s "$($_.o)") -ne $_.b })

if($kotu.Count -or $kotu2.Count){
  Write-Host "OZ-SINAV DUSTU - kapi bozuk, olcum YAPILMADI:" -ForegroundColor Red
  $kotu  | ForEach-Object { Write-Host ("  [katlama] beklenen={0}  satir: {1}" -f $_.b, $_.s) -ForegroundColor Red }
  $kotu2 | ForEach-Object { Write-Host ("  [desen]   beklenen={0}  satir: {1}" -f $_.b, $_.s) -ForegroundColor Red }
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
    $tur = ''
    if(RiskliSatir $satirlar[$i]){ $tur = 'katlama' }
    else {
      $bas = [Math]::Max(0, $i - 3)
      $onc = if($i -gt 0){ ($satirlar[$bas..($i-1)] -join "`n") } else { '' }
      $tur = RiskliKatlamaDeseni $satirlar[$i] $onc
    }
    if($tur){
      $n++
      $ayrintiListe += [pscustomobject]@{ Dosya=$f.Name; Satir=($i+1); Tur=$tur; Kod=$satirlar[$i].Trim() }
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
$sinifSayim = $ayrintiListe | Group-Object Tur | Sort-Object Name
foreach($g in $sinifSayim){
  $ne = switch($g.Name){
    'katlama'       { 'kulture bagli .ToLower()/.ToUpper()' }
    'desen-replace' { 'harf ayirmayan -replace -> METNI BOZAR' }
    'desen-match'   { 'harf ayirmayan -match  -> ESLESMEYI KACIRIR' }
    default         { $g.Name }
  }
  Write-Host ("   {0,-14} {1,4}  {2}" -f $g.Name, $g.Count, $ne)
}

if($Ayrinti -and $ayrintiListe.Count){
  Write-Host ""
  Write-Host "RISKLI SATIRLAR:" -ForegroundColor Cyan
  $ayrintiListe | ForEach-Object {
    $k = $_.Kod; if($k.Length -gt 74){ $k = $k.Substring(0,74)+'...' }
    Write-Host ("  {0,-30} {1,5} [{2,-7}]: {3}" -f $_.Dosya, $_.Satir, $_.Tur, $k)
  }
}

if($Tazele){
  # 31.08: taban artik SINIF KIRILIMI da tasiyor. Sebep: bu kosuda taban
  # 64'ten 174'e sicradi ve dosya sayaclari uc sinifi tek torbada tuttugu icin
  # "yeni borc mu, yeni OLCUM SINIFI mi?" ayirt edilemiyordu. Kirilim yazilinca
  # bir sonraki sicramanin kaynagi tek bakista gorulur.
  $yaz = [ordered]@{
    aciklama = "Turkce katlama nobetcisinin tabani. UC SINIF olculur: katlama (kulture bagli .ToLower()/.ToUpper()) · desen-replace (harf ayirmayan -replace, METNI BOZAR) · desen-match (harf ayirmayan -match, ESLESMEYI KACIRIR). Borc ARTARSA kapi kirmizi olur; azalirsa -Tazele ile indirilir. Dogrusu: once ASCII'ye katla, SONRA ToLowerInvariant(); desen kucuk harf yazilir, (?i) kullanilmaz."
    olcum    = (Get-Date).ToString('dd.MM.yyyy HH:mm')
    toplam   = $toplam
    siniflar = [ordered]@{}
    dosyalar = [ordered]@{}
  }
  foreach($g in ($ayrintiListe | Group-Object Tur | Sort-Object Name)){ $yaz.siniflar[$g.Name] = $g.Count }
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
