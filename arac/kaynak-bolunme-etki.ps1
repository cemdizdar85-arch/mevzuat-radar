# ============================================================================
#  KAYNAK BÖLÜNME ETKİSİ — yeniden bölünen standardın KOPAN paket bağları   16.09.2026
#  Cem "2 ve 3 yap" (GM 3; 92'nin isteği: "standart-yut bir kaynağı yeniden böldüğünde eski parça adına bağlı partileri raporlasın").
#
#  NEDEN VAR: motor/standart-yut.ps1 bir standardı yeniden yazınca bazı eski parça adları (ör. "TMS 36 Ek A - Tanımlanan terimler [7/8]")
#  ambardan kalkar. Partilerdeki soruların paket listesi (icerik.<kp>.kaynak_adlar) o adlara bakmaya devam eder; soru yeniden
#  yargılanınca paket eksik kurulur ve hakem "paket konuyu içermiyor" der. 16.09'da bu liste elle çıkarıldı (14 soru / 12 parti).
#
#  NE YAPAR (bedel 0, model yok):
#   1. Eski kayıtlar = standart-yut'un sildiğinden ÖNCE yazdığı yedek (veri/fabrika/yedek-<std>-<zaman>.json); yeni kayıtlar = ambar.
#   2. Kopan ad = eskide olup yenide olmayan ad. Yoksa rapor yazılmaz.
#   3. Her kopan ada YENİ ad önerisi: (a) eski adda paragraf numarası/aralığı varsa ("p.10-11", "p.46-47, p.52", "B98-B105") aynı
#      numaralı yeni parçalar; (b) eski metnin 30 harflik pencerelerinden ≥4'ünü taşıyan yeni parçalar (en çok isabet önce).
#   4. Bütün kalip_parti taranır; paketinde kopan ad olan her soru satır olur. soru_havuzu.kaynak alanı da taranır.
#   5. CSV: veri/fabrika/kaynak-bolunme-etki-<zaman>-<std>.csv
#      sütunlar: standart · etiket · sinav · kp · eski_ad · yeni_adlar · kapidan_gecti (hakem EVET ∧ hakem2 EVET ∧ kör=doğru ∧ sim=hedef)
#   6. -Tasi -Sinavlar KGK,SMMM -Yaz: YALNIZ verilen sınavların partilerinde eski ad yeni adlarla değiştirilir
#      (parti-senkron -Indir → yerel yedek kasaya → düzenle → -Yukle). SGS için kural: o sınavın oturumuna bırakılır.
#
#  Kullanım:
#    powershell -NoProfile -Command "& .\arac\kaynak-bolunme-etki.ps1 -Standart 'TFRS 18' -YedekDosya veri\fabrika\yedek-TFRS18-....json"
#    ... -Tasi -Sinavlar KGK,SMMM -Yaz        (bulutta koşan parti taşınmaz, sıraya yazılır)
#    powershell -NoProfile -Command "& .\arac\kaynak-bolunme-etki.ps1 -BekleyenleriIsle -Yaz"   (bulut boşalınca)
# ============================================================================
param(
  [string]$Standart = '',
  [string]$YedekDosya = '',
  [switch]$BekleyenleriIsle,   # 16.09: sıradaki (bulut koşarken ertelenen) taşımaları işler
  [switch]$Tasi,
  [string[]]$Sinavlar = @(),
  [switch]$Yaz
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
$sbAnahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'); if(-not $sbAnahtar){ $sbAnahtar = $env:SUPABASE_SERVICE_KEY }
if(-not $sbAnahtar){ Write-Host 'SUPABASE_SERVICE_KEY yok'; exit 1 }
$sbBasliklar = @{ apikey=$sbAnahtar; Authorization="Bearer $sbAnahtar"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$sbKok = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'

# --- 16.09 BULUT KAPISI (CLAUDE.md kuralı: bulutta koşan partiye ambardan yazılmaz; 92 isteği b30e6034) -------------------
#   bulut-uretim işi partiyi başta indirir, sonda TAMAMINI yükler. Arada yazılan bağ ya ezilir ya bulutun sonucunu siler.
#   Koşan partinin taşıması SIRAYA yazılır (veri/fabrika/kaynak-bolunme-bekleyen.csv); -BekleyenleriIsle bulut boşalınca işler.
#   Koşan işlerden biri plansızsa (partileri bilinemez) HİÇBİR parti yazılmaz, hepsi sıraya gider.
$siraYolu = Join-Path $depoKok 'veri\fabrika\kaynak-bolunme-bekleyen.csv'
function KosanEtiketler(){
  $yardimci = Join-Path $PSScriptRoot 'bulut-kosan-etiketler.ps1'
  if(-not (Test-Path $yardimci)){ return [pscustomobject]@{ tamam=$false; etiketler=@(); neden='bulut-kosan-etiketler.ps1 yok' } }
  try { $liste = @(& $yardimci -Kati); return [pscustomobject]@{ tamam=$true; etiketler=$liste; neden='' } }
  catch { return [pscustomobject]@{ tamam=$false; etiketler=@(); neden="$($_.Exception.Message)" } }
}
function BaglariYaz($bagSatirlari, [string]$damga){
  $kabuk = if(Get-Command powershell -ErrorAction SilentlyContinue){ 'powershell' } else { 'pwsh' }
  $kasa = Join-Path (Split-Path $depoKok) '_yerel-veri-kasasi\baglama-yedek'; New-Item -ItemType Directory -Force $kasa | Out-Null
  $kosan = KosanEtiketler
  $ertelenen = New-Object System.Collections.Generic.List[object]
  foreach($grup in ($bagSatirlari | Group-Object etiket)){
    $etiket = $grup.Name; $sinav = $grup.Group[0].sinav
    if(-not $kosan.tamam -or ($kosan.etiketler -contains $etiket)){
      $neden = if(-not $kosan.tamam){ "bulut durumu bilinmiyor: $($kosan.neden)" } else { 'bulutta koşuyor' }
      Write-Host ("  {0}: ERTELENDİ ({1}) — sıraya yazıldı" -f $etiket,$neden)
      foreach($bag in $grup.Group){ $ertelenen.Add($bag) }
      continue
    }
    & $kabuk -NoProfile -File (Join-Path $PSScriptRoot 'parti-senkron.ps1') -Indir -Etiket $etiket -Sinav $sinav -Yaz | Out-Null
    $partiYolu = Join-Path $depoKok "veri\fabrika\kalip-parti-$etiket.json"
    if(-not (Test-Path $partiYolu)){ Write-Host "  $etiket indirilemedi — sıraya yazıldı"; foreach($bag in $grup.Group){ $ertelenen.Add($bag) }; continue }
    Copy-Item $partiYolu (Join-Path $kasa "$damga-bolunme-kalip-parti-$etiket.json")
    $partiIcerik = Get-Content $partiYolu -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($bag in $grup.Group){
      $soru = $partiIcerik.($bag.kp); if(-not $soru){ continue }
      $yeniListe = New-Object System.Collections.Generic.List[string]
      foreach($ad in @($soru.kaynak_adlar)){
        if("$ad" -eq $bag.eski_ad){ foreach($yeniAd in ($bag.yeni_adlar -split ' ; ')){ if($yeniAd -and -not $yeniListe.Contains($yeniAd)){ $yeniListe.Add($yeniAd) } } }
        elseif(-not $yeniListe.Contains("$ad")){ $yeniListe.Add("$ad") }
      }
      $soru.kaynak_adlar = $yeniListe.ToArray()
    }
    [IO.File]::WriteAllText($partiYolu,(ConvertTo-Json $partiIcerik -Depth 30),(New-Object Text.UTF8Encoding($false)))
    & $kabuk -NoProfile -File (Join-Path $PSScriptRoot 'parti-senkron.ps1') -Yukle -Etiket $etiket -Sinav $sinav -Yaz | Out-Null
    $kontrol = @(Invoke-RestMethod -Uri "$sbKok/kalip_parti?select=icerik&etiket=eq.$etiket" -Headers $sbBasliklar -TimeoutSec 240)[0]
    $kalan = 0; foreach($bag in $grup.Group){ if(@($kontrol.icerik.($bag.kp).kaynak_adlar) -contains $bag.eski_ad){ $kalan++ } }
    Write-Host ("  {0}: {1} bağ taşındı · kasada eski ad kalan {2}" -f $etiket,$grup.Count,$kalan)
  }
  return $ertelenen.ToArray()
}
function SirayaYaz($eklenecek, $kalanEski){
  $hepsi = New-Object System.Collections.Generic.List[object]
  foreach($x in @($kalanEski)){ if($x){ $hepsi.Add(($x | Select-Object standart,etiket,sinav,kp,eski_ad,yeni_adlar,kapidan_gecti)) } }
  foreach($x in @($eklenecek)){ if($x){ $hepsi.Add(($x | Select-Object standart,etiket,sinav,kp,eski_ad,yeni_adlar,kapidan_gecti)) } }
  if($hepsi.Count){ $hepsi | Export-Csv $siraYolu -NoTypeInformation -Encoding UTF8 }
  else { Set-Content -Path $siraYolu -Value '"standart","etiket","sinav","kp","eski_ad","yeni_adlar","kapidan_gecti"' -Encoding UTF8 }
  Write-Host ("SIRA: {0} bağ bekliyor ({1})" -f $hepsi.Count,(Split-Path $siraYolu -Leaf))
}
if($BekleyenleriIsle){
  if(-not (Test-Path $siraYolu)){ Write-Host 'Sıra boş.'; exit 0 }
  $sira = @(Import-Csv $siraYolu)
  if(-not $sira.Count){ Write-Host 'Sıra boş.'; exit 0 }
  Write-Host ("SIRADA: {0} bağ · {1} parti" -f $sira.Count,@($sira.etiket | Select-Object -Unique).Count)
  if(-not $Yaz){ Write-Host 'KURU KOŞU — işlemek için -BekleyenleriIsle -Yaz'; exit 0 }
  $ertelenen = @(BaglariYaz $sira (Get-Date -Format 'yyyyMMdd-HHmm'))
  SirayaYaz @() $ertelenen
  exit 0
}
if(-not $Standart -or -not $YedekDosya){ Write-Host '-Standart ve -YedekDosya gerekli (ya da -BekleyenleriIsle).'; exit 1 }

function HarfDizisi([string]$metin){ return (($metin -replace '[^\p{L}]','').ToLowerInvariant()) }
function NumaraKumesi([string]$ad){
  # "TFRS 18 p.46-47, p.52 - …" → 46,47,52 · "TFRS 18 B98-B105 - …" → B98..B105 · "X p.A14 - …" → A14
  $sonuc = New-Object System.Collections.Generic.List[string]
  $bas = ($ad -split ' - ')[0]
  if($bas.StartsWith($Standart)){ $bas = $bas.Substring($Standart.Length) }   # standart numarası ("TMS 36") paragraf sanılmasın
  $noktali = [regex]::Match($bas,'p\.([A-Z]{0,2}\d{1,3}(?:\.\d{1,3}){1,3}[A-Z]{0,2})(?=[,\s]|$)')   # 16.09: TFRS 9 "p.3.2.2"
  if($noktali.Success){ $sonuc.Add($noktali.Groups[1].Value); return $sonuc }
  foreach($es in [regex]::Matches($bas,'(?:p\.|\s)([A-Z]{0,2})(\d{1,3})([A-Z]{0,2})(?:[-–]([A-Z]{0,2})(\d{1,3}))?(?=[,\s]|$)')){
    $onek = $es.Groups[1].Value; $ilk = [int]$es.Groups[2].Value
    if($es.Groups[5].Success -and $es.Groups[5].Value){
      $son = [int]$es.Groups[5].Value
      if($son -ge $ilk -and $son - $ilk -le 40){ for($n=$ilk; $n -le $son; $n++){ $sonuc.Add("$onek$n") } }
    } else { $sonuc.Add("$onek$ilk$($es.Groups[3].Value)") }
  }
  return $sonuc
}

# --- eski / yeni kayıtlar
$eskiKayitlar = New-Object System.Collections.Generic.List[object]
foreach($kayit in (Get-Content $YedekDosya -Raw -Encoding UTF8 | ConvertFrom-Json)){ $eskiKayitlar.Add($kayit) }   # PS 5.1: dizi foreach ile açılır
$suzgec = 'or=(kaynak_ad.eq.' + [uri]::EscapeDataString($Standart) + ',kaynak_ad.like.' + [uri]::EscapeDataString("$Standart *") + ')' +
          '&kaynak_ad=not.like.' + [uri]::EscapeDataString("$Standart Degisiklikleri*") + '&kaynak_ad=not.like.' + [uri]::EscapeDataString("$Standart Değişiklikleri*")
$yeniKayitlar = New-Object System.Collections.Generic.List[object]; $atla = 0
do { $sayfaAdet = 0; foreach($kayit in (Invoke-RestMethod -Uri "$sbKok/dokumanlar?select=kaynak_ad,metin&$suzgec&order=id&limit=1000&offset=$atla" -Headers $sbBasliklar -TimeoutSec 240)){ $yeniKayitlar.Add($kayit); $sayfaAdet++ }; $atla += 1000 } while($sayfaAdet -eq 1000)
$yeniAdKumesi = New-Object System.Collections.Generic.HashSet[string]; foreach($kayit in $yeniKayitlar){ [void]$yeniAdKumesi.Add("$($kayit.kaynak_ad)") }
$kopanAdlar = @($eskiKayitlar | ForEach-Object { "$($_.kaynak_ad)" } | Where-Object { -not $yeniAdKumesi.Contains($_) } | Select-Object -Unique)
Write-Host ("{0}: eski {1} · yeni {2} · kopan ad {3}" -f $Standart,$eskiKayitlar.Count,$yeniKayitlar.Count,$kopanAdlar.Count)
if($kopanAdlar.Count -eq 0){ Write-Host 'Kopan ad yok — rapor yazılmadı.'; exit 0 }

# --- yeni ad önerileri
$yeniNoHaritasi = @{}
foreach($kayit in $yeniKayitlar){ $noEs = [regex]::Match("$($kayit.kaynak_ad)",'\sp\.([A-Z]{0,2}\d{1,3}(?:\.\d{1,3}){0,3}[A-Z]{0,2})(?:\s|$)'); if($noEs.Success -and -not $yeniNoHaritasi.ContainsKey($noEs.Groups[1].Value)){ $yeniNoHaritasi[$noEs.Groups[1].Value] = "$($kayit.kaynak_ad)" } }
$yeniHarf = @{}; foreach($kayit in $yeniKayitlar){ $yeniHarf["$($kayit.kaynak_ad)"] = HarfDizisi "$($kayit.metin)" }
$oneri = @{}
foreach($kopanAd in $kopanAdlar){
  $liste = New-Object System.Collections.Generic.List[string]
  foreach($no in (NumaraKumesi $kopanAd)){ if($yeniNoHaritasi.ContainsKey($no) -and -not $liste.Contains($yeniNoHaritasi[$no])){ $liste.Add($yeniNoHaritasi[$no]) } }
  $eskiHarf = HarfDizisi ((@($eskiKayitlar | Where-Object { "$($_.kaynak_ad)" -eq $kopanAd }) | ForEach-Object { "$($_.metin)" }) -join '')
  $pencereler = @(); for($i=0; $i -le $eskiHarf.Length-30; $i+=30){ $pencereler += $eskiHarf.Substring($i,30) }
  if($liste.Count -eq 0 -and $pencereler.Count){
    $isabetler = foreach($ad in $yeniHarf.Keys){ $sayi = @($pencereler | Where-Object { $yeniHarf[$ad].Contains($_) }).Count; if($sayi -ge 4){ [pscustomobject]@{ ad=$ad; sayi=$sayi } } }
    foreach($isabet in @($isabetler | Sort-Object sayi -Descending | Select-Object -First 8)){ $liste.Add($isabet.ad) }
  }
  $oneri[$kopanAd] = $liste.ToArray()
}

# --- partiler
$kopanKume = New-Object System.Collections.Generic.HashSet[string]; foreach($ad in $kopanAdlar){ [void]$kopanKume.Add($ad) }
$satirlar = New-Object System.Collections.Generic.List[object]; $atla = 0; $partiSayisi = 0
do {
  $sayfa = @(); foreach($parti in (Invoke-RestMethod -Uri "$sbKok/kalip_parti?select=etiket,sinav,icerik&order=etiket&limit=20&offset=$atla" -Headers $sbBasliklar -TimeoutSec 300)){ $sayfa += $parti }
  foreach($parti in $sayfa){
    $partiSayisi++
    if(-not $parti.icerik){ continue }
    foreach($ozellik in $parti.icerik.PSObject.Properties){
      $soru = $ozellik.Value; if($soru -isnot [pscustomobject]){ continue }
      foreach($ad in @($soru.kaynak_adlar)){
        if(-not $kopanKume.Contains("$ad")){ continue }
        $gecti = ("$($soru.hakem.karar)" -eq 'EVET') -and ("$($soru.hakem2.karar)" -eq 'EVET') -and $soru.kor_cozum -and ("$($soru.kor_cozum.cevap)" -eq "$($soru.dogru)") -and $soru.simulasyon_sonnet -and ("$($soru.simulasyon_sonnet.cevap)" -eq "$($soru.simulasyon_sonnet.hedef)")
        $satirlar.Add([pscustomobject]@{ standart=$Standart; etiket=$parti.etiket; sinav=$parti.sinav; kp=$ozellik.Name; eski_ad="$ad"; yeni_adlar=(@($oneri["$ad"]) -join ' ; '); kapidan_gecti=[bool]$gecti })
      }
    }
  }
  $atla += 20
} while($sayfa.Count -eq 20)
$havuz = @(); $atla = 0
do { $sayfaAdet = 0; foreach($kayit in (Invoke-RestMethod -Uri ("$sbKok/soru_havuzu?select=id,sinav,kaynak,yayin&kaynak=like." + [uri]::EscapeDataString("$Standart*") + "&order=id&limit=1000&offset=$atla") -Headers $sbBasliklar -TimeoutSec 240)){ $sayfaAdet++; if($kopanKume.Contains("$($kayit.kaynak)")){ $havuz += $kayit } }; $atla += 1000 } while($sayfaAdet -eq 1000)
foreach($kayit in $havuz){ $satirlar.Add([pscustomobject]@{ standart=$Standart; etiket='soru_havuzu'; sinav=$kayit.sinav; kp="$($kayit.id)"; eski_ad="$($kayit.kaynak)"; yeni_adlar=(@($oneri["$($kayit.kaynak)"]) -join ' ; '); kapidan_gecti=[bool]$kayit.yayin }) }

$zaman = Get-Date -Format 'yyyyMMdd-HHmm'
$csvYolu = Join-Path $depoKok ("veri\fabrika\kaynak-bolunme-etki-$zaman-" + ($Standart -replace '[^A-Za-z0-9]','') + '.csv')
$satirlar | Export-Csv $csvYolu -NoTypeInformation -Encoding UTF8
Write-Host ("taranan parti {0} · kopan bağ {1} (soru havuzu {2}) · rapor {3}" -f $partiSayisi,$satirlar.Count,$havuz.Count,(Split-Path $csvYolu -Leaf))
foreach($grup in ($satirlar | Group-Object sinav)){ Write-Host ("  {0,-6} bağ {1,3} · parti {2,3} · kapıdan geçmiş {3}" -f $grup.Name,$grup.Count,@($grup.Group.etiket | Select-Object -Unique).Count,@($grup.Group | Where-Object kapidan_gecti).Count) }
$onerisiz = @($kopanAdlar | Where-Object { -not @($oneri[$_]).Count })
if($onerisiz.Count){ Write-Host ("  ⚠ yeni ad önerisi bulunamayan {0} ad: {1}" -f $onerisiz.Count,(($onerisiz | Select-Object -First 5) -join ' | ')) -ForegroundColor Yellow }

if(-not $Tasi){ exit 0 }
if(-not $Sinavlar.Count){ Write-Host '-Tasi için -Sinavlar gerekli (ör. KGK,SMMM). SGS kendi oturumuna bırakılır.'; exit 1 }
$tasinacak = @($satirlar | Where-Object { $_.etiket -ne 'soru_havuzu' -and $Sinavlar -contains $_.sinav -and $_.yeni_adlar })
Write-Host ("TAŞINACAK: {0} bağ · {1} parti ({2})" -f $tasinacak.Count,@($tasinacak.etiket | Select-Object -Unique).Count,($Sinavlar -join ','))
if(-not $Yaz){ Write-Host 'KURU KOŞU — yazmak için -Yaz'; exit 0 }
$ertelenen = @(BaglariYaz $tasinacak $zaman)
if($ertelenen.Count){ $eskiSira = if(Test-Path $siraYolu){ @(Import-Csv $siraYolu) } else { @() }; SirayaYaz $ertelenen $eskiSira }
