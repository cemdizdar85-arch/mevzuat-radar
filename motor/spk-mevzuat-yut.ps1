# ============================================================================
#  SPK MEVZUAT SISTEMI YUTUCU (30.08.2026 — Cem: "1 yap")
#
#  GIRDI: veri/spk-mevzuat-envanteri.json + _kaynak/spk-mevzuat/*.pdf
#         (motor/spk-mevzuat-indir.ps1 indirdi ve dort kapidan gecirdi:
#          389/389 TAM, kaynak https://mevzuat.spk.gov.tr - SPK'nin kendi sistemi)
#
#  UC SINIF, UC YOL (olculdu, 75 belge orneklendi):
#    Ilke/Kurul Karari (258) : medyan 1.305 krk, 40/40'inda SIFIR "MADDE"
#                              -> maddeye bolunmez, BUTUN olarak yutulur
#    Mevzuat (121)           : medyan 44.842 krk, ortalama 23 madde
#                              -> madde madde parcalanir
#    Rehber (10)             : medyan 37.588 krk, 0 madde
#                              -> bolum bolum kesilir
#  Tek bir parcalayiciyla hepsini ezmek, kararlari tek blob yapardi - bugun
#  III-45.1'de tam bunun ne demek oldugunu gorduk.
#
#  MUKERRER FRENI (olculdu): 'sayi' alani dolu 90 mevzuat belgesinin 25'i
#  ZATEN AMBARDA (mevzuat.gov.tr kopyasi olarak). Ayni tebligi ikinci kez
#  yutmak soru ureticisini ayni metne iki kez baktirir. O 25 ATLANIR ve
#  adlariyla raporlanir - karar Cem'in.
#  Kararlar ve rehberler icin boyle bir risk YOK: mevzuat.gov.tr kurul
#  kararlarini TUTMAZ (bu depoda daha once olculdu).
#
#  ADLANDIRMA: her kaynak adi "SPK " ONEKIYLE baslar. Onek olmazsa
#  soru-uret-v2.ps1 ek-alan havuzu bu kaynaklara KOR kalir (24.08 BDDK dersi;
#  eslesme kaynak_ad'in BASINA capalidir: imatch.^onek).
#
#  KULLANIM:
#    powershell -File motor\spk-mevzuat-yut.ps1            # olc + rapor (YAZMAZ)
#    powershell -File motor\spk-mevzuat-yut.ps1 -uygula    # ambara yaz
# ============================================================================
param([switch]$uygula, [switch]$zorla, [int]$tavan = 0)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB   = 'https://bjrleanjpyujtajmazxn.supabase.co'
$KEY  = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host 'KOR: SUPABASE_SERVICE_KEY yok - olcum yapilir, YAZILMAZ.' -ForegroundColor Yellow }
$H = @{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot' }
$bugun = (Get-Date).ToString('yyyy-MM-dd')
$pdfDir = Join-Path $kok '_kaynak\spk-mevzuat'
$envYol = Join-Path $kok 'veri\spk-mevzuat-envanteri.json'
if(-not (Test-Path $envYol)){ throw "envanter yok: $envYol (once motor\spk-mevzuat-indir.ps1 kosun)" }
$envanter = Get-Content $envYol -Raw -Encoding UTF8 | ConvertFrom-Json

# --- ambardaki mevcut kaynak adlari (mukerrer freni + idempotentlik) --------
Write-Host 'Ambar okunuyor (mevcut kaynak adlari)...'
$mevcut = New-Object System.Collections.Generic.HashSet[string]
$bas = 0; $sonId = ''   # 08.09: offset (ordersiz, kararsiz) -> imlec (id=gt.)&order=id
while($true){
  try { $r = Invoke-RestMethod -Uri "$SB/rest/v1/dokumanlar?select=id,kaynak_ad$(if($sonId){"&id=gt.$sonId"})&order=id&limit=1000" -Headers $H -TimeoutSec 120 } catch { break }
  $a = @($r); if($a.Count -eq 0){ break }
  $sonId = "$($a[$a.Count-1].id)"
  foreach($x in $a){ [void]$mevcut.Add(("$($x.kaynak_ad)" -replace ' (m\.|gec\. m\.|ek m\.|muk\. m\.|bolum |\[)\S.*$','')) }
  $bas += 1000; if($a.Count -lt 1000){ break }
}
Write-Host ("  ambarda tekil kaynak (kok ad): {0}" -f $mevcut.Count)

function Temiz([string]$s){ (("$s" -replace '\s+',' ').Trim()) }
function KisaBaslik([string]$s,[int]$n=70){ $t = Temiz $s; if($t.Length -gt $n){ $t.Substring(0,$n).TrimEnd() } else { $t } }

# madde parcalayici — 30.08 genis tire sinifiyla (U+2010..U+2015 + U+2212 + '-')
$rxMadde = [regex]'(?<tur>MÜKERRER MADDE|EK GEÇİCİ MADDE|EK MADDE|GEÇİCİ MADDE|Mükerrer MADDE|Ek Geçici MADDE|Ek MADDE|Geçici MADDE|MADDE|Mükerrer Madde|Ek Geçici Madde|Ek Madde|Geçici Madde|Madde)\s+(?<no>\d+(?:/[A-ZÇĞİÖŞÜ])?)\s*(?:\(\s*(?:Değişik|Mülga|Ek|Yeniden|Başlığı|Değiştirilen)[^)]{0,140}\)\s*[:‐-―−-]?|[‐-―−-])'

# Dev parca esigi. BolumleriCikar'in `boy` varsayilaniyla AYNI kalmali:
# esik buyuk olursa esigi gecmeyen ama yine de sisik satirlar kalir.
#
# 10.09 AKSAM - 3500'DEN 1800'E INDIRILDI (olculdu). Ilk tazelemeden sonra
# altin test 43 -> 44 cikti ama kapali kalmadi. Sebep: SPK dilimleri 3.500
# karakterdi, AMBARIN GERI KALANI 1.800 (mevzuat-yut.ps1 $PARCA_BOY=1800,
# standart-yut.ps1 $dilimBoyu=1800, kgk-standart-yut.ps1 1800). Iki kat buyuk
# parca, ayni sorguda daha cok kelime tutar ve madde_ara'nin `kapsanan`
# bonusunu daha sik alir - yani kucultulmus bir miknatis olarak calismaya
# devam eder. Olcum: 'ticaret siciline tescil basvurusu' ve 'kacakcilik sucu'
# vakalarinda top-6'nin basi hala SPK parcalariydi.
# KURAL: ambardaki parca boyu TEK OLMALI. Ayricalikli buyuk parca yoktur.
$DEV_ESIK = 1800

function MaddeleriCikar([string]$flat,[string]$kokAd,[string]$url){
  # Ad sayaci HER BELGEDE sifirlanir. Belge disina tasarsa iki ayri belgenin
  # m.4'u de "(2)" eki alir ve gereksiz yere ayrisirlar.
  $script:adSayaci = @{}
  $m = $rxMadde.Matches($flat); $out = New-Object System.Collections.Generic.List[object]
  # 30.08 KAPSAMA ONARIMI (olculdu, prova kosusunda cikti): madde parcalayici
  # ILK MADDEDEN ONCEKI metni dusuruyordu - RG kunyesi, "Amac", "Dayanak",
  # yururlukten kaldirma cumlesi hep orada durur. Uzun tebligde bu %2, ama
  # KISA belgede %40: en dusuk kapsama %59,4 (IMKB Uyelik Yonetmeligi).
  # 42 belge %98'in altindaydi ve hepsi bu sebepten.
  # Ev kurali "en kucuk maddesine kadar" - giris metni de metindir.
  if($m.Count -gt 0 -and $m[0].Index -ge 60){
    $giris = $flat.Substring(0, $m[0].Index).Trim()
    if($giris.Length -ge 60){
      $out.Add([ordered]@{ tur='kanun-madde'; kaynak_ad="$kokAd [giris]"; baslik=''; metin=$giris; kaynak_url=$url; belge_tarihi=$bugun }) | Out-Null
    }
  }
  for($i=0;$i -lt $m.Count;$i++){
    $b=$m[$i].Index; $s=if($i -lt $m.Count-1){$m[$i+1].Index}else{$flat.Length}
    $gov=$flat.Substring($b,$s-$b).Trim()
    if($gov -match '^.{0,70}\(Mülga\s*(?:madde)?\s*:'){ continue }
    if($gov.Length -lt 60){ if($out.Count){ $out[$out.Count-1].metin = "$($out[$out.Count-1].metin) $gov" }; continue }
    $no=$m[$i].Groups['no'].Value; $tr=$m[$i].Groups['tur'].Value
    $md = if($tr -match 'kerrer'){"muk. m.$no"} elseif($tr -match 'Ek Ge'){"ek gec. m.$no"} elseif($tr -match 'Ge'){"gec. m.$no"} elseif($tr -match 'Ek'){"ek m.$no"} else {"m.$no"}

    # 10.09 AKSAM — BELGE ICI AD CAKISMASI (olculdu).
    # Ayni belgede AYNI madde numarasi birden fazla kez yakalanabiliyor: mevzuat
    # metinleri "MADDE 4 –" satirini degisiklik listelerinde ve eklerde TEKRAR
    # tasiyor. Iki govde de ayni adi ("... m.4") aliyor, dilimlenince ayni
    # "[1/n]" adlarini uretiyor ve REPO JSON'da birbirini eziyorlardi.
    # OLCUM: bir kosuda 4.149 parca uretildi, repo JSON'a yalnizca 3.691'i
    # dustu -> 458 satir kayboluyordu. Ambar sisiyor, repo JSON eksik kaliyor
    # ve tam yukleme o farki SILECEKTI.
    # COZUM: ayni ad ikinci kez ciktiginda sira eki alir - "m.4 (2)".
    # Parantez secildi: kaynak-kok.ps1 sondaki KOSELI eki kirpar, parantez
    # kok adin parcasi olarak kalir ve iki govde birbirinden ayrilir.
    if(-not $script:adSayaci){ $script:adSayaci = @{} }
    $tamAd = "$kokAd $md"
    if($script:adSayaci.ContainsKey($tamAd)){
      $script:adSayaci[$tamAd]++
      $md = "$md ($($script:adSayaci[$tamAd]))"
    } else {
      $script:adSayaci[$tamAd] = 1
    }

    # 10.09.2026 MIKNATIS ONARIMI (canli olcum).
    #
    # BULGU: madde govdesi HIC boy sinirina tabi degildi. Son maddenin sonu
    # $flat.Length'e kadar gidiyor; regex belgenin geri kalaninda MADDE
    # yakalayamazsa o TEK SATIR butun tebligi yutuyor. Canlida olculdu:
    #   SPK Teblig (Seri: X, No: 22) ... m.4   -> 146.979 karakter TEK SATIR
    #   SPK Teblig (Seri: V, No: 34) ... m.35  ->  81.226 karakter TEK SATIR
    #
    # BEDELI: 147 bin karakterlik metin Turkcedeki her kelimeyi icerir.
    # madde_ara v8'in `kapsanan` bonusu (1 + 0.35*(n-1)) bunu tepeye tasir.
    # 'Finansal Muhasebe demirbas cikisi' sorgusunda o satir DORT jetonun
    # DORDUNU birden tutuyor ve birinci geliyor - oysa bir bagimsiz denetim
    # tebligi. Fabrikanin atladigi 278 konunun 110'u tek bu satira dusuyordu.
    #
    # NEDEN GEC FARK EDILDI: "adinda m.4 var -> demek ki parcalanmis" diye
    # varsayildi. Madde ADI tasimak, madde BOYUNDA olmak demek degil.
    #
    # ADLANDIRMA: dilimler "m.4 [1/42]" olur. Bu bicim depoda ZATEN var
    # ("Avukatlik K. (1136 s.K.) m.44 [3/4]"); kaynak-kok.ps1 sondaki koseli
    # eki kirpip sonra ' m.4' konum ekini de kirptigi icin kok ad DEGISMEZ.
    if($gov.Length -gt $DEV_ESIK){
      $dilimler = BolumleriCikar $gov "$kokAd $md" $url
      Write-Host ("  ! DEV MADDE: {0} {1} = {2:N0} krk -> {3} dilime bolundu" -f $kokAd,$md,$gov.Length,@($dilimler).Count) -ForegroundColor Yellow
      foreach($d in $dilimler){ $out.Add($d) | Out-Null }
      continue
    }

    $out.Add([ordered]@{ tur='kanun-madde'; kaynak_ad="$kokAd $md"; baslik=''; metin=$gov; kaynak_url=$url; belge_tarihi=$bugun }) | Out-Null
  }
  return $out
}
function BolumleriCikar([string]$flat,[string]$kokAd,[string]$url,[int]$boy=1800){
  $out = New-Object System.Collections.Generic.List[object]
  if($flat.Length -le $boy){
    $out.Add([ordered]@{ tur='kanun-madde'; kaynak_ad=$kokAd; baslik=''; metin=$flat; kaynak_url=$url; belge_tarihi=$bugun }) | Out-Null
    return $out
  }
  $n=1; $d=0
  $toplam=[math]::Ceiling($flat.Length/$boy)
  while($d -lt $flat.Length){
    $uz=[Math]::Min($boy,$flat.Length-$d)
    $kes=$flat.Substring($d,$uz)
    $out.Add([ordered]@{ tur='kanun-madde'; kaynak_ad=("{0} [{1}/{2}]" -f $kokAd,$n,$toplam); baslik=''; metin=$kes.Trim(); kaynak_url=$url; belge_tarihi=$bugun }) | Out-Null
    $d+=$uz; $n++
  }
  return $out
}

# --- plan ------------------------------------------------------------------
# 10.09 AD CAKISMASI ONARIMI (olculdu). Baslik 70 karaktere kirpildigi icin
# FARKLI belgeler AYNI kok adi uretebiliyor. Olcum: 389 envanter kaydinda 3 ad
# cakisiyor (6 belge) - ama bunlar buyuk tebligler oldugu icin dilim adlari
# birebir cakisiyor ve 565 SATIR ayni ada dusuyor.
#
# BEDELI: ambar 5.160 satir tasirken repo JSON'u 4.595'te kaliyordu (JSON
# kaynak_ad ile anahtarli). motor/mevzuat-yukle.ps1 ambari o JSON'dan SIL-YAZ
# yaptigi icin bir sonraki tam yukleme 565 satiri UCURACAKTI.
#
# COZUM: cakisan kok adlara kaynak dosya adi eklenir - "(Mevzuat-266)". Parantez
# secildi cunku kaynak-kok.ps1 sondaki KOSELI eki kirpiyor; parantez kok adin
# parcasi olarak kalir ve iki belge birbirinden ayrilir.
function KokAdHesapla($d){
  $sinif = ($d.dosya -split '-')[0]
  $bas2  = KisaBaslik $d.baslik 70
  $ad = switch($sinif){
    'IlkeKarari' { "SPK Karari - $bas2" }
    'Rehber'     { "SPK Rehber - $bas2" }
    default      { if($d.sayi){ "SPK $($d.tur) ($($d.sayi)) - $bas2" } else { "SPK $($d.tur) - $bas2" } }
  }
  return (Temiz $ad)
}
$adSayaci = @{}
foreach($d in $envanter.dosyalar){ $a = KokAdHesapla $d; $adSayaci[$a] = 1 + $(if($adSayaci.ContainsKey($a)){ $adSayaci[$a] }else{ 0 }) }
$cakisan = @($adSayaci.GetEnumerator() | Where-Object { $_.Value -gt 1 })
if($cakisan.Count -gt 0){ Write-Host ("  ! AD CAKISMASI: {0} kok ad birden fazla belgede - dosya adi eklenerek ayristirilacak" -f $cakisan.Count) -ForegroundColor Yellow }

$plan=@(); $atlanan=@()
foreach($d in $envanter.dosyalar){
  $sinif = ($d.dosya -split '-')[0]
  $kokAd = KokAdHesapla $d
  if($adSayaci[$kokAd] -gt 1){
    $kokAd = Temiz ("{0} ({1})" -f $kokAd, [IO.Path]::GetFileNameWithoutExtension($d.dosya))
  }
  # idempotentlik: bu SPK kaynagi zaten yutulmussa atla
  if((-not $zorla) -and $mevcut.Contains($kokAd)){ $atlanan += [pscustomobject]@{ dosya=$d.dosya; sebep='zaten yutulmus'; ad=$kokAd }; continue }
  # MUKERRER FRENI: yalniz Mevzuat sinifi icin - ayni teblig mevzuat.gov.tr'den gelmis mi?
  if($sinif -eq 'Mevzuat' -and $d.sayi){
    $s2 = ($d.sayi -replace '\s+','')
    if($s2.Length -gt 3){
      $carpisan = $null
      foreach($k in $mevcut){ if((-not $k.StartsWith('SPK ')) -and ($k -replace '\s+','').Contains($s2)){ $carpisan=$k; break } }
      if($carpisan){ $atlanan += [pscustomobject]@{ dosya=$d.dosya; sebep="mukerrer (ambarda: $carpisan)"; ad=$kokAd }; continue }
    }
  }
  $plan += [pscustomobject]@{ dosya=$d.dosya; sinif=$sinif; kokAd=$kokAd; tur=$d.tur; sayi=$d.sayi; rg=$d.rg; url=("https://mevzuat.spk.gov.tr" + $d.uc) }
}
if($tavan -gt 0 -and $plan.Count -gt $tavan){ $plan = $plan[0..($tavan-1)] }

Write-Host ("PLAN: {0} belge yutulacak · {1} atlandi" -f $plan.Count, $atlanan.Count)
$g=@{}; $plan | ForEach-Object { $g[$_.sinif]=($g[$_.sinif]+1) }
Write-Host ("  sinif dagilimi: {0}" -f (($g.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ' · '))
$am=@{}; $atlanan | ForEach-Object { $k=($_.sebep -split ' \(')[0]; $am[$k]=($am[$k]+1) }
if($atlanan.Count){ Write-Host ("  atlanma sebepleri: {0}" -f (($am.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ' · ')) }

# --- yut -------------------------------------------------------------------
$rapor=@(); $toplamParca=0; $i=0
$tumBelgeler = New-Object System.Collections.Generic.List[object]   # repo JSON icin biriktirilir
foreach($p in $plan){
  $i++
  $pdf = Join-Path $pdfDir $p.dosya
  $tmp = [IO.Path]::GetTempFileName()
  $flat=''
  try {
    & pdftotext -enc UTF-8 -q $pdf $tmp 2>$null
    if(Test-Path $tmp){ $flat = Temiz (Get-Content $tmp -Raw -Encoding UTF8) }
  } finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
  if($flat.Length -lt 60){ $rapor += [pscustomobject]@{ ad=$p.kokAd; parca=0; durum='KIRMIZI'; sebep="metin cikmadi ($($flat.Length) krk)" }; continue }

  $docs = if($p.sinif -eq 'Mevzuat'){ MaddeleriCikar $flat $p.kokAd $p.url } else { BolumleriCikar $flat $p.kokAd $p.url }
  if($p.sinif -eq 'Mevzuat' -and @($docs).Count -eq 0){ $docs = BolumleriCikar $flat $p.kokAd $p.url }   # maddesiz mevzuat -> bolum

  # KAPSAMA: kaynak metnin yuzde kaci ambara giriyor
  $ambarKr = ((@($docs) | ForEach-Object { $_.metin }) -join ' ').Length
  $kapsama = if($flat.Length -gt 0){ [math]::Round(100*$ambarKr/$flat.Length,1) } else { 0 }

  if($uygula -and $KEY){
    try {
      $liste=@($docs)
      for($j=0; $j -lt $liste.Count; $j+=400){
        $son=[Math]::Min($j+400,$liste.Count)-1
        $dilim=@($liste[$j..$son])
        $bj = ($dilim | ConvertTo-Json -Depth 5); if($dilim.Count -eq 1){ $bj="[$bj]" }
        Invoke-RestMethod -Method Post -Uri "$SB/rest/v1/dokumanlar" -Headers ($H + @{ Prefer='return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($bj)) -TimeoutSec 180 | Out-Null
      }
      $rapor += [pscustomobject]@{ ad=$p.kokAd; parca=@($docs).Count; durum='YESIL'; sebep="kapsama %$kapsama" }
      $toplamParca += @($docs).Count
      foreach($d in @($docs)){ $tumBelgeler.Add([pscustomobject]@{ sinif=$p.sinif; kayit=$d }) | Out-Null }
    } catch {
      $rapor += [pscustomobject]@{ ad=$p.kokAd; parca=@($docs).Count; durum='KIRMIZI'; sebep="yukleme hatasi: $($_.Exception.Message)" }
    }
  } else {
    $rapor += [pscustomobject]@{ ad=$p.kokAd; parca=@($docs).Count; durum='PROVA'; sebep="kapsama %$kapsama" }
    $toplamParca += @($docs).Count
  }
  if($i % 40 -eq 0){ Write-Host ("  [{0}/{1}] {2} parca (toplam {3})" -f $i,$plan.Count,@($docs).Count,$toplamParca) }
}

# ============================================================================
# 30.08 AKSAM — REPO JSON'A DA YAZ. Bu adim EKLENMEDEN once 3.613 parca
# ambara yazildi ve AYNI GUN SILINDI.
# SEBEP: motor/mevzuat-yukle.ps1 ("Mevzuat Tam Yukleme") ambari
# veri/mevzuat/*.json'dan SIL-YAZ yapar. Repo JSON'unda olmayan her sey
# ucar. Betigin kendi yorumunda kural aynen yazili:
#   "elle yutulan her kaynak veri/mevzuat/ altina json olarak da eklenir"
# 27.08'de ayni sey yasanmis ve kural ORADAN cikarilmis; ben kurali bilip
# uygulamadim. Kanit: ayni gun yutulan TSPB (mevzuat-yut + manifest yolundan
# gectigi icin repo JSON'u vardi) HAYATTA KALDI - 116 parca duruyor.
# Artik yutma iki yere birden yazar: canli ambar + repo JSON.
# ============================================================================
if($uygula -and $KEY -and $toplamParca -gt 0){
  $repoDir = Join-Path $kok 'veri\mevzuat'
  if(-not (Test-Path $repoDir)){ New-Item -ItemType Directory -Path $repoDir -Force | Out-Null }
  $sinifDosya = @{ 'IlkeKarari'='spk-portal-karar'; 'Mevzuat'='spk-portal-mevzuat'; 'Rehber'='spk-portal-rehber' }
  # 10.09.2026 — SIL-YAZ TUZAGI KAPATILDI (yasandi, ayni gun).
  #
  # Bu blok repo JSON'unu YALNIZ BU KOSUDA uretilen belgelerle yaziyordu.
  # Tam yutmadan sonra 3 belge 500 hatasiyla dusmustu; eksigi tamamlamak icin
  # betik ikinci kez kosuldu ve spk-portal-mevzuat.json 3.239 parcadan
  # 93 PARCAYA DUSTU. Ambar dogruydu ama repo JSON'u eksikti - ve
  # motor/mevzuat-yukle.ps1 ambari bu dosyalardan SIL-YAZ yaptigi icin bir
  # sonraki tam yukleme 3.146 parcayi ucuracakti. 27.08'deki "robot kiyimi"
  # deseninin birebir aynisi.
  #
  # COZUM: dosya EZILMEZ, BIRLESTIRILIR. Anahtar kaynak_ad'dir; ayni ad
  # yeniden uretilmisse YENI kayit kazanir (tazeleme), uretilmemis eski
  # kayitlar YERINDE KALIR.
  #
  # NOT: bu birlestirme, kaynagi ambardan TAMAMEN silip yeniden yutma
  # senaryosunda eski adlari da tasir. Oyle bir tazelemede repo JSON'u
  # arac/spk-repo-json-onar.ps1 ile AMBARDAN yeniden kurulur - dogru kaynak
  # her zaman ambardir.
  foreach($s in $sinifDosya.Keys){
    $bu = @($tumBelgeler | Where-Object { $_.sinif -eq $s })
    if($bu.Count -eq 0){ continue }
    $yol = Join-Path $repoDir ($sinifDosya[$s] + '.json')

    $birlesik = [ordered]@{}
    if(Test-Path $yol){
      try {
        $eski = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach($e in @($eski.belgeler)){ if($e -and $e.kaynak_ad){ $birlesik["$($e.kaynak_ad)"] = $e } }
      } catch { Write-Host ("  UYARI: {0} okunamadi, sifirdan yaziliyor: {1}" -f $yol, $_.Exception.Message) -ForegroundColor Yellow }
    }
    $eskiSayi = $birlesik.Count
    foreach($b in $bu){ $birlesik["$($b.kayit.kaynak_ad)"] = $b.kayit }

    $govde = @{ belgeler = @($birlesik.Values) }
    [IO.File]::WriteAllText($yol, (ConvertTo-Json -InputObject $govde -Depth 6), [Text.UTF8Encoding]::new($false))
    Write-Host ("  repo JSON: veri/mevzuat/{0}.json  {1} -> {2} parca (bu kosu {3})" -f $sinifDosya[$s], $eskiSayi, $birlesik.Count, $bu.Count)
  }
  Write-Host '  -> bu dosyalar COMMIT EDILMELI; yoksa tam-yukleme robotu ambari yine siler.'
}

$kirmizi = @($rapor | Where-Object { $_.durum -eq 'KIRMIZI' })
Write-Host ''
Write-Host ("BELGE {0} · PARCA {1} · KIRMIZI {2}" -f $rapor.Count,$toplamParca,$kirmizi.Count)
foreach($k in $kirmizi){ Write-Host ("  KIRMIZI: {0} · {1}" -f $k.ad,$k.sebep) -ForegroundColor Red }

$cikti = [ordered]@{
  olcum=(Get-Date).ToString('s'); mod=if($uygula){'UYGULANDI'}else{'PROVA'}
  kaynak='https://mevzuat.spk.gov.tr (SPK kendi sistemi)'
  planlanan=$plan.Count; atlanan=$atlanan.Count; parca=$toplamParca; kirmizi=$kirmizi.Count
  atlananlar=$atlanan; belgeler=$rapor
}
[IO.File]::WriteAllText((Join-Path $kok 'veri\spk-yutma-raporu.json'), (ConvertTo-Json -InputObject $cikti -Depth 6), [Text.UTF8Encoding]::new($false))
Write-Host '  -> veri/spk-yutma-raporu.json'
if($kirmizi.Count){ exit 1 }
exit 0
