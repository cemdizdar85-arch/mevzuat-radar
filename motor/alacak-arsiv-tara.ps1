# ============================================================================
#  ALACAK ARSIV TARAYICI (bir defalik geriye donuk tarama) — 19.08.2026
#  Cem: "arsiv turuna basla" (rakipte 19.309 kayit, bizde 19 gunluk havuz vardi)
#
#  29.08.2026 DUZELTME - eski notun hukmu yanlisti:
#  Filtre calismiyor sanilmisti; asil sebep YANLIS ALAN gonderilmesiydi.
#  Denenen adlar (categoryId/adCategoryId/searchText...) API'de yok; sitenin
#  kendi istegi yakalandi, dogru alan 'keys.txv' + 'sorting':
#    {"keys":{"txv":[12]},"sorting":"publish_time desc","skipCount":0,...}
#    txv 12 = Iflas Hukuku Davalari (49 = konkordato, 50 = iflas/tasfiye)
#  Sayfa boyutu 20'de SABIT (50/100/500 istense de 20 doner).
#
#  Eskiden: genel liste + slug eleme, ~1.250 istek (25.000 skip tavani).
#  Simdi  : kategori dogrudan, ~286 istek. OLCULDU: 5.705 ilan, ~5 dakika.
#
#  IKI YONLU TARAMA: sayfalama tavani ~5.500-6.000 civarinda. Kategori bugun
#  bunun altinda ama buyurse tek yon yetmez; bu yuzden hem 'desc' (en yeniden)
#  hem 'asc' (en eskiden) taranip birlestirilir - iki pencere ortada bulusur.
#
#  KAYNAK PENCERESI (29.08.2026 olcumu): ilan.gov.tr TAM 365 GUN tutuyor.
#  En eski konkordato ilani = bugun - 365 gun. Tarih suzgeci (ppdmin/ppdmax)
#  ile 1 yil oncesi istendiginde SIFIR doner. Yani arsiv GERIYE buyumez;
#  yalniz zamanla derinlesir - kaynaktan dusen kayitlari biz tuttugumuz icin.
#
#  Bu betik gunluk nobette KOSMAZ (alacak-ilan-hasat.ps1 o isi yapar);
#  arsivi bir kez doldurmak icindir. Tekrar calistirilabilir (idempotent:
#  ilanNo bazli tekillestirme, mevcut kayitlar korunur).
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$yol  = Join-Path $kok 'veri\alacak-ilan-canli.json'
$TAVAN = if ($env:TAVAN) { [int]$env:TAVAN } else { 8000 }   # kategorili tarama: 28.000'e gerek yok

function IlanTur([string]$metin){
  $m = $metin.ToLowerInvariant()
  if($m.Contains('konkordato') -or $m.Contains('muhlet')){ return 'konkordato' }
  if($m.Contains('iflas') -or $m.Contains('müflis') -or $m.Contains('muflis')){ return 'iflas' }
  return 'diger'
}

$H = @{ 'Accept'='application/json'; 'User-Agent'='Mozilla/5.0 (MevzuatRadar-AlacakRobotu)' }
$bulunan = @{}   # ilanNo -> kayit
$istek = 0; $donenToplam = 0; $slugDisi = 0
$basla = Get-Date

$atlananSayfa = 0
foreach ($yon in 'desc','asc') {
  $atla = 0; $bosTur = 0
  Write-Host ("--- {0} yonunde tarama ---" -f $yon)
  while ($atla -lt $TAVAN) {
    $govde = '{"keys":{"txv":[12]},"sorting":"publish_time ' + $yon + '","skipCount":' + $atla + ',"maxResultCount":20}'
    # DIKKAT: hatayi 'veri bitti' SANMA - 29.08 olcumunde tam bu yuzden kategori
    # toplami 5.001 olculmustu (dogrusu 5.705). Hata != bos sayfa. Ayni sayfa 3 kez
    # denenir; ucu de duserse sayfa ATLANIR ama sayilir ve sonda rapor edilir.
    $r = $null
    for ($deneme = 1; $deneme -le 3 -and $null -eq $r; $deneme++) {
      try {
        $r = Invoke-RestMethod -Method Post -Uri 'https://www.ilan.gov.tr/api/api/services/app/Ad/AdsByFilter' `
          -Headers $H -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType 'application/json' -TimeoutSec 90
        $istek++
      } catch {
        Write-Host ("  istek hatasi ({0} skip={1}, deneme {2}/3): {3}" -f $yon, $atla, $deneme, $_.Exception.Message)
        if ($deneme -lt 3) { Start-Sleep -Seconds 3 }
      }
    }
    if ($null -eq $r) {
      Write-Host ("  UYARI: {0} skip={1} sayfasi 3 denemede alinamadi - ATLANDI" -f $yon, $atla)
      $atlananSayfa++
      $atla += 20
      continue
    }
    $sayfa = @($r.result.ads)
    if (-not $sayfa.Count) { $bosTur++; if ($bosTur -ge 3) { Write-Host ("  bos sayfa x3 ({0} skip={1}) -> son, duruluyor" -f $yon, $atla); break } }
    else { $bosTur = 0 }
    $donenToplam += $sayfa.Count

    foreach ($a in $sayfa) {
      # slug suzgeci ARTIK YEDEK KEMER (kategori dogrudan istendi); elenen olursa say
      if ("$($a.slugifyTitle)" -notmatch '^iflas-hukuku') { $slugDisi++; continue }
      $tarih = ''
      if ($a.publishStartDate) { try { $tarih = ([datetime]$a.publishStartDate).ToString('dd.MM.yyyy') } catch { $tarih = "$($a.publishStartDate)".Substring(0,10) } }
      $no = "$($a.adNo)"
      if (-not $bulunan.ContainsKey($no)) {
        $bulunan[$no] = [ordered]@{
          ilanNo = $a.adNo
          baslik = $a.title
          kurum  = $a.advertiserName
          il     = $a.addressCityName
          ilce   = $a.addressCountyName
          tarih  = $tarih
          tur    = (IlanTur "$($a.title) $($a.slugifyTitle)")
          url    = "https://www.ilan.gov.tr/ilan/$($a.id)/$($a.slugifyTitle)"
        }
      }
    }
    $atla += 20
    if ($atla % 1000 -eq 0) {
      $sonT = if ($sayfa.Count) { try { ([datetime]$sayfa[-1].publishStartDate).ToString('dd.MM.yyyy') } catch { '?' } } else { '?' }
      Write-Host ("  {0} skip={1,5} · birikim={2,5} · o sayfadaki tarih={3} · gecen={4:mm\:ss}" -f $yon, $atla, $bulunan.Count, $sonT, ((Get-Date) - $basla))
    }
    Start-Sleep -Milliseconds 200
  }
}

Write-Host ("TARAMA BITTI: {0} istek, {1} iflas/konkordato ilani bulundu ({2:mm\:ss})" -f $istek, $bulunan.Count, ((Get-Date) - $basla))
if ($atlananSayfa -gt 0) {
  Write-Host ("UYARI: {0} sayfa alinamadi (~{1} kayit gorulmedi). Tarama EKSIK - tekrar kosulmali." -f $atlananSayfa, ($atlananSayfa * 20))
}

# --- OZ-SINAV: txv suzgeci hala calisiyor mu? ---
if ($donenToplam -gt 0) {
  $oran = [math]::Round(100 * ($donenToplam - $slugDisi) / $donenToplam, 1)
  if ($oran -lt 80) {
    throw ("txv=12 suzgeci kaymis: donen {0} kaydin yalniz %{1}'i iflas-hukuku. Kaynak kategori kimligini degistirmis olabilir - ilan.gov.tr kategori sayfasindan txv teyit edilmeden arsiv YAZILMAZ." -f $donenToplam, $oran)
  }
  Write-Host ("oz-sinav: {0} kayit donen, %{1} iflas-hukuku (kategori suzgeci saglam)" -f $donenToplam, $oran)
}

# --- mevcut havuzla BIRLESTIR (mevcut kayitlar korunur: borclu/vkn zenginlestirmesi kaybolmasin) ---
$mevcut = @()
if (Test-Path $yol) {
  $j = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  $mevcut = @($j.ilanlar)
  # yedek
  Copy-Item $yol ($yol + '.yedek') -Force
}
$eskiSayi = @($mevcut).Count
$havuz = [ordered]@{}
foreach ($e in $mevcut) { $havuz["$($e.ilanNo)"] = $e }          # once mevcut (zengin) kayitlar
foreach ($k in $bulunan.Keys) { if (-not $havuz.Contains($k)) { $havuz[$k] = $bulunan[$k] } }

# tarihe gore yeni->eski sirala
$liste = @($havuz.Values) | Sort-Object -Property @{ Expression = {
  try { [datetime]::ParseExact("$($_.tarih)", 'dd.MM.yyyy', $null) } catch { [datetime]'1900-01-01' } } } -Descending

$cikti = [ordered]@{
  guncelleme = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  kaynak     = 'Basin Ilan Kurumu Resmi Ilan Portali (ilan.gov.tr) - iflas-hukuku kategorisi'
  adet       = @($liste).Count
  ilanlar    = $liste
}
[System.IO.File]::WriteAllText($yol, ($cikti | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding $false))

# --- YAZ -> GERI OKU -> KARSILASTIR ---
$geri = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
$yeniSayi = @($geri.ilanlar).Count
$tarihler = @($geri.ilanlar) | ForEach-Object { try { [datetime]::ParseExact("$($_.tarih)",'dd.MM.yyyy',$null) } catch {} }
$enEski = ($tarihler | Measure-Object -Minimum).Minimum
$enYeni = ($tarihler | Measure-Object -Maximum).Maximum
Write-Host ("GERI OKUMA: {0} -> {1} ilan (+{2}); tarih araligi {3:dd.MM.yyyy} .. {4:dd.MM.yyyy}" -f $eskiSayi, $yeniSayi, ($yeniSayi-$eskiSayi), $enEski, $enYeni)
if ($yeniSayi -lt $eskiSayi) { throw 'KAYIP VAR: yeni sayi eskiden kucuk - yedekten don (.yedek)' }
