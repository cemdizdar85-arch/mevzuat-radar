# ============================================================================
#  KIYMET DEFTERI ONARICI (17.08.2026)
#
#  motor/hafiza/kiymetler.json = "eski -> yeni" seridinin TEMELI. Kart motoru
#  bir GTIP'in onceki kiymetini buradan okur. Defter bozuksa serit YALAN SOYLER.
#
#  17.08 OLCUMU (220 kod / 313 kayit):
#    sayisal deger        : 113
#    NICELIK OLMAYAN metin: 200   <-- defterin %64'u
#      ornek: 0713.20 -> "Istanbul Tekstil ve Konfeksiyon Ihracatci Birligi..."
#             3211.00.00.00.00 -> "mustahzar kurutucu maddeler (sikatifler)"
#             3215.90.70.00.12 -> "kaynakta belirtilmemis"
#    GTIP bicimine uymayan anahtar: 15  (biri 160 karakter, biri "336")
#    birden fazla kayitli kod      : 70  (bir kismi ayni gun ayni tebligden
#                                        iki satir, farki yalniz harf bozulmasi:
#                                        "1,5 ABD Dolari/kg" vs "1,5 ABD Dolari/Kg")
#
#  KURAL (kart-toplu.ps1 ile AYNI): anahtar GTIP biciminde olacak, deger
#  taninan bir BIRIM tasiyacak, (kod,tarih,teblig) tekil olacak.
#
#  VARSAYILAN OLCUM. Yazmak icin -Uygula. Yazmadan once yedek alinir ve
#  yazdiktan sonra GERI OKUNUP karsilastirilir (yaz -> geri oku -> karsilastir).
#
#  PARA HARCAMAZ.
# ============================================================================
param([switch]$Uygula)
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot
$yol = Join-Path $kok 'motor\hafiza\kiymetler.json'
if(-not (Test-Path $yol)){ Write-Host 'BULUNAMADI: motor/hafiza/kiymetler.json' -ForegroundColor Red; exit 1 }

$BIRIM = '(?<s>-?\d{1,3}(?:\.\d{3})*(?:,\d+)?|-?\d+(?:,\d+)?)\s*(?<b>%|ABD|USD|Dolar|Avro|Euro|EUR|TL|[kK][gG]|ton|adet)'
function KodGecerli([string]$k){ return ("$k".Trim() -match '^\d{4}(\.\d{2}){0,4}$') }

# ANAHTAR NORMALLESTIRME. Ilk surum 15 anahtari birden "bozuk" deyip atiyordu -
# 26 kayit. Tek tek okununca 15'in yalniz 4'u gercekten atilacakmis:
#   "54.07" "70.05" gibi 10 tanesi GECERLI TARIFE POZISYONU (fasil.pozisyon
#     yazimi) -> 4 haneye normallestirilir: 54.07 -> 5407
#   "7007.11.10.00.12, 7007.11.10.00.19, ..." virgullu liste -> AYRILIR
#   "70.05 (7005.29 haric)" kapsam kayitli -> tek koda indirilemez, ATILIR
#     (7005 yazmak "haric" kaydini yutar ve YANLIS bilgi uretir)
#   "336" ve "Lagocephalus sceleratus" GTIP degil -> ATILIR
# Ders: toptan atmadan once listeyi GOZLE oku.
function KodlariCoz([string]$ham){
  $k = "$ham".Trim()
  $cikan = New-Object System.Collections.Generic.List[string]
  if($k -match '[()]'){ return $cikan }                       # kapsam kayitli - guvenli degil
  foreach($parca in ($k -split ',')){
    $t = $parca.Trim()
    if(-not $t){ continue }
    if($t -match '^(\d{2})\.(\d{2})$'){ $cikan.Add($Matches[1] + $Matches[2]); continue }   # pozisyon
    if(KodGecerli $t){ $cikan.Add($t) }
  }
  return $cikan
}
function DegerGecerli([string]$d){
  $t = "$d".Trim()
  if(-not $t){ return $false }
  if($t.Length -gt 60){ return $false }
  if($t -match '(?i)belirtilmemis|belirtilmemiş|bilinmiyor'){ return $false }
  return ($t -match $BIRIM)
}
# Mukerrer tespiti icin degeri normallestir: bosluk/buyuk-kucuk/Turkce harf
# farki ayni kaydi iki kere yazdirmasin ("1,5 ABD Dolari/kg" = "1,5 ABD Dolari/Kg")
function Norm([string]$d){
  $t = "$d".ToLowerInvariant()
  $t = $t -replace '[ıİI]','i' -replace '[şŞ]','s' -replace '[ğĞ]','g' -replace '[üÜ]','u' -replace '[öÖ]','o' -replace '[çÇ]','c'
  return ($t -replace '\s+','')
}

$j = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
$girenKayit = 0; $girenKod = 0
$kotuKod = New-Object System.Collections.Generic.List[string]
$kotuDeger = New-Object System.Collections.Generic.List[string]
$mukerrer = 0; $tutulan = 0
$yeni = [ordered]@{}

$havuz = @{}          # normallestirilmis kod -> kayit listesi
$normalize = 0
foreach($p in ($j.PSObject.Properties | Sort-Object Name)){
  $girenKod++
  $kod = $p.Name.Trim()
  $liste = @($p.Value)
  # @() SART: PowerShell fonksiyondan donen tek elemanli koleksiyonu ACIYOR,
  # $kodlar duz string oluyor ve $kodlar[0] ILK KARAKTERI veriyor ("3009.40"[0]="3").
  # Bu tuzak "216 kod normallestirildi" gibi yanlis bir sayim uretmisti.
  $kodlar = @(KodlariCoz $kod)
  if($kodlar.Count -eq 0){
    $girenKayit += $liste.Count
    $kisa = if($kod.Length -gt 40){ $kod.Substring(0,40) + '...' } else { $kod }
    $kotuKod.Add(("{0}  ({1} kayit)" -f $kisa, $liste.Count))
    continue
  }
  if($kodlar.Count -ne 1 -or $kodlar[0] -ne $kod){ $normalize++ }
  foreach($r in $liste){
    $girenKayit++
    if(-not (DegerGecerli $r.deger)){
      if($kotuDeger.Count -lt 400){ $kotuDeger.Add(("{0} -> {1}" -f $kod, "$($r.deger)")) }
      continue
    }
    # ayni kayit birden fazla koda dagitilabilir (virgullu liste); her kod
    # kendi kovasinda tekillestirilir
    $ilkSayildi = $false
    foreach($kk in $kodlar){
      if(-not $havuz.ContainsKey($kk)){ $havuz[$kk] = New-Object System.Collections.Generic.List[object] }
      $anahtar = "$($r.tarih)|$($r.teblig)|$(Norm $r.deger)"
      $varMi = $false
      foreach($v in $havuz[$kk]){ if("$($v.tarih)|$($v.teblig)|$(Norm $v.deger)" -eq $anahtar){ $varMi = $true; break } }
      if($varMi){ if(-not $ilkSayildi){ $mukerrer++; $ilkSayildi = $true }; continue }
      $havuz[$kk].Add([ordered]@{ tarih="$($r.tarih)"; deger="$($r.deger)".Trim(); teblig="$($r.teblig)" })
      if(-not $ilkSayildi){ $tutulan++; $ilkSayildi = $true }
    }
  }
}
# CELISKI AYIKLAMA (17.08). kiymet-temizle cikitisinda yakalandi:
#   5407 -> 06.05.2026 | 5,6 ABD dolari/kg | 20260506-3.htm
#        -> 06.05.2026 | 5,5 ABD dolari/kg | 20260506-3.htm
# AYNI teblig, AYNI gun, IKI FARKLI deger. Muhtemel sebep: teblig pozisyon
# altindaki alt kodlara ayri kiymet veriyor, cikarim hepsini pozisyon
# anahtarina yazmis. Hangisinin dogru oldugu BILINEMEZ.
# Karar: ikisi de DUSER. Yanlis bir "eski deger" gostermek, hic gostermemekten
# kotudur - serit "%2 artti" diye uydurma bir rakam basardi.
$celiski = 0
foreach($kk in ($havuz.Keys | Sort-Object)){
  # .ToArray() SART: @(Generic.List) PS 5.1'de "Bagimsiz degisken turleri
  # eslesmiyor" diye patliyor. Bu tuzak bugun UCUNCU kez cikti (harf-onar.ps1,
  # kart olcumu, burasi).
  $liste = $havuz[$kk].ToArray()
  # (tarih|teblig) basina kac AYRI deger var?
  $grup = @{}
  foreach($r in $liste){
    $a = "$($r.tarih)|$($r.teblig)"
    if(-not $grup.ContainsKey($a)){ $grup[$a] = New-Object System.Collections.Generic.List[string] }
    if(-not $grup[$a].Contains((Norm $r.deger))){ [void]$grup[$a].Add((Norm $r.deger)) }
  }
  $kirli = @($grup.Keys | Where-Object { $grup[$_].Count -gt 1 })
  if($kirli.Count -gt 0){
    $liste = @($liste | Where-Object { $kirli -notcontains "$($_.tarih)|$($_.teblig)" })
    foreach($a in $kirli){ $celiski += $grup[$a].Count }
  }
  if($liste.Count -eq 0){ continue }
  # kronolojik sirala: serit "onceki deger"i dogru bulsun
  $yeni[$kk] = @($liste | Sort-Object {
    $t = [datetime]::MinValue
    [void][datetime]::TryParseExact($_.tarih,'dd.MM.yyyy',$null,[Globalization.DateTimeStyles]::None,[ref]$t); $t })
}

$atilanKodKaydi = 0
foreach($s in $kotuKod){ if($s -match '\((\d+) kayit\)'){ $atilanKodKaydi += [int]$Matches[1] } }

# TUTULAN sayisi celiski DUSULDUKTEN SONRA basilir. Ilk surumde cikarma
# yazdirmadan SONRA yapiliyordu; rapor "117 tutuldu" derken dosyaya 96 yaziyordu.
# Kendi raporunun yalan soylemesi, kusurun kendisinden tehlikelidir.
$tutulan = $tutulan - $celiski
$kova = $tutulan + $celiski + $atilanKodKaydi + $kotuDeger.Count + $mukerrer
Write-Host '======== KIYMET DEFTERI ONARIMI ========'
Write-Host ("  giren kod / kayit           : {0} / {1}" -f $girenKod, $girenKayit)
Write-Host ("  TUTULAN kayit               : {0}" -f $tutulan)
Write-Host ("  atilan - anahtar bozuk      : {0} kayit ({1} kod)" -f $atilanKodKaydi, $kotuKod.Count)
Write-Host ("  atilan - deger nicelik degil: {0}" -f $kotuDeger.Count)
Write-Host ("  atilan - mukerrer           : {0}" -f $mukerrer)
Write-Host ("  atilan - CELISKI (ayni teblig/gun, farkli deger) : {0}" -f $celiski)
Write-Host ("  KOVA TOPLAMI                : {0} = {1}  {2}" -f $kova, $girenKayit, $(if($kova -eq $girenKayit){'TAMAM'}else{'TUTMADI!'}))
if($kova -ne $girenKayit){ Write-Host '  KIRMIZI: kova toplami tutmadi - sayim guvenilmez.' -ForegroundColor Red; exit 1 }
Write-Host ("  anahtari normallestirilen   : {0} kod (54.07 -> 5407, virgullu liste ayrildi)" -f $normalize)
Write-Host ("  cikan kod sayisi            : {0}" -f $yeni.Count)

Write-Host ''
Write-Host '  --- anahtari bozuk olanlar (ilk 6) ---'
foreach($s in ($kotuKod | Select-Object -First 6)){ Write-Host ('     ' + $s) }
Write-Host '  --- degeri nicelik olmayanlar (ilk 6) ---'
foreach($s in ($kotuDeger | Select-Object -First 6)){
  $k = if($s.Length -gt 80){ $s.Substring(0,80) + '...' } else { $s }
  Write-Host ('     ' + $k)
}

if(-not $Uygula){
  Write-Host ''
  Write-Host 'OLCUM MODU - defter YAZILMADI. Yazmak icin: -Uygula'
  exit 0
}

# yedek
$yedek = $yol + '.yedek-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
Copy-Item $yol $yedek
[IO.File]::WriteAllText($yol, ($yeni | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($true)))

# YAZ -> GERI OKU -> KARSILASTIR
$geri = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
$geriKod = @($geri.PSObject.Properties).Count
$geriKayit = 0
foreach($p in $geri.PSObject.Properties){ $geriKayit += @($p.Value).Count }
Write-Host ''
Write-Host ("  yedek       : {0}" -f (Split-Path $yedek -Leaf))
Write-Host ("  geri okuma  : {0} kod / {1} kayit" -f $geriKod, $geriKayit)
if($geriKod -ne $yeni.Count -or $geriKayit -ne $tutulan){
  Write-Host '  KIRMIZI: geri okuma yazilanla TUTMADI - yedegi geri koy.' -ForegroundColor Red; exit 1
}
Write-Host '  yaz -> geri oku -> karsilastir: TUTTU'
exit 0
