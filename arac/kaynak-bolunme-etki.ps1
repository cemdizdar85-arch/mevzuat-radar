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
  [switch]$Yaz,
  [switch]$OzSinav,            # 07.10: süzgeç + kopuş freni öz-sınavı (ağsız, anahtarsız)
  [switch]$YalnizOneri,        # 08.10: yalnız "eski ad<TAB>öneriler" basar, partileri taramaz (eşdeğerlik provası)
  [switch]$KopusOnay           # 07.10: "yarıdan fazlası kopuyor" frenini elle aşar (meşru yeniden adlandırma); "yeni 0" freni aşılmaz
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot

# --- 07.10.2026 PARANTEZLİ AD HATASI (iş emri 26, ölçüldü) -------------------------------------------------------------------
#   Yeni kayıt süzgeci or=(kaynak_ad.eq.X,kaynak_ad.like.X *) idi. PostgREST or= listesinde değerdeki "(" ")" "," sözdizimi
#   sayılır: -Standart "GVK (193 s.K.)" ile koşunca "yeni 0 kayıt · kopan 370 ad · kopan bağ 2.799" dedi; gerçekte kopan ad 4,
#   bağlı soru 13. -Tasi -Yaz ile koşulsaydı 2.799 bağı boş öneriyle bozacaktı. Standart adlarında parantez olmadığı için
#   görülmemişti. Düzeltme: değer PostgREST'in kendi kaçışıyla çift tırnağa alınır ("X", içindeki \ ve " kaçışlı).
#   İkinci kapı (KOPUŞ FRENİ): yeni kayıt 0 ise ya da eski adların yarıdan fazlası kopuyorsa araç DURUR — süzgeç yine
#   bozulursa ya da standart henüz yazılmamışsa sessizce yanlış rapor vermez.
#   BU KAPI ŞUNU GÖRMEZ: gerçekten yarıdan fazlası yeniden adlanan meşru bölme (o zaman -KopusOnay yok; elle karar, rapor DURUR).
function OrDeger([string]$x){ return '"' + ($x -replace '\\','\\' -replace '"','\"') + '"' }
function YeniSuzgec([string]$std){
  return 'or=' + [uri]::EscapeDataString('(kaynak_ad.eq.' + (OrDeger $std) + ',kaynak_ad.like.' + (OrDeger "$std *") + ')') +
         '&kaynak_ad=not.like.' + [uri]::EscapeDataString("$std Degisiklikleri*") + '&kaynak_ad=not.like.' + [uri]::EscapeDataString("$std Değişiklikleri*")
}
function KopusFreni([int]$eskiSayi, [int]$yeniSayi, [int]$kopanSayi){
  if($eskiSayi -gt 0 -and $yeniSayi -eq 0){ return "yeni kayıt 0 (süzgeç bozuk ya da kaynak ambarda yok)" }
  if($eskiSayi -ge 4 -and $kopanSayi * 2 -gt $eskiSayi){ return "eski $eskiSayi adın $kopanSayi'i kopuyor (yarıdan fazla)" }
  return ''
}
# PostgREST or= listesinin üst düzey ayrıştırması (tırnak dışındaki virgül/parantez) — öz-sınavın hakemi
function OrListesiAyir([string]$ham){
  $ic = [uri]::UnescapeDataString($ham); if($ic -notmatch '^or=\((.*)\)$'){ return $null }; $ic = $Matches[1]
  $parca = New-Object System.Collections.Generic.List[string]; $buf = ''; $tirnak = $false; $derin = 0
  for($i=0; $i -lt $ic.Length; $i++){ $c = $ic[$i]
    if($tirnak){ if($c -eq '\'){ $buf += $c + $ic[$i+1]; $i++; continue }; if($c -eq '"'){ $tirnak = $false }; $buf += $c; continue }
    if($c -eq '"'){ $tirnak = $true; $buf += $c; continue }
    if($c -eq '('){ $derin++ } elseif($c -eq ')'){ $derin--; if($derin -lt 0){ return $null } }
    if($c -eq ',' -and $derin -eq 0){ $parca.Add($buf); $buf = ''; continue }
    $buf += $c }
  if($tirnak -or $derin -ne 0){ return $null }; $parca.Add($buf)
  # PostgREST: tirnaksiz degerde , ( ) : ayrilmis karakterdir -> sozdizimi bozuk sayilir
  foreach($k in $parca){ $es = [regex]::Match($k, '^[a-z_]+\.[a-z]+\.(.*)$'); if(-not $es.Success){ return $null }; $v = $es.Groups[1].Value; if(-not $v.StartsWith('"') -and $v -match '[,():]'){ return $null } }
  return ,$parca
}
function NumaraKumesi([string]$ad){
  # "TFRS 18 p.46-47, p.52 - …" → 46,47,52 · "TFRS 18 B98-B105 - …" → B98..B105 · "X p.A14 - …" → A14
  $sonuc = New-Object System.Collections.Generic.List[string]
  $bas = ($ad -split ' - ')[0]
  if($bas.StartsWith($Standart)){ $bas = $bas.Substring($Standart.Length) }   # standart numarası ("TMS 36") paragraf sanılmasın
  # 08.10: "Ek 5 p.4" → ek numarası (5) paragraf sanılmasın. Eskiden her ek adı fazladan "p.5" önerisi alıyordu (BDS 315'te 4 iki adlı öneri, metin örtüşmesi 0).
  if($env:KBE_MUTASYON -notin 'ekno','eski'){ $bas = $bas -replace '\bEk\s*\d+\s*',' ' }
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
# 08.10: indirilen parti dosyası BU çağrıda yeniden yazıldı mı. Değilse yerel kopya bayattır, ambara basılmaz.
#   🚫 GÖRMEZ: dosyanın tazelenip içeriğinin yine de eksik olması (indirme yarım yazdıysa) · saat kayması (2 sn pay).
function IndirmeTaze([string]$yol, [datetime]$onceUtc){
  if(-not (Test-Path $yol)){ return $false }
  if($env:KBE_MUTASYON -eq 'taze'){ return $true }
  return ((Get-Item $yol).LastWriteTimeUtc -ge $onceUtc)
}
# 08.10: aynı paragraf numaralı adaylardan seçim. Önce eski metnin 30 harflik pencerelerinin en çok bulunduğu aday (≥ %30);
#   örtüşme yoksa eski adla AYNI EK numarasını taşıyan (ek yoksa ana metin) aday; o da yoksa ilk aday (eski davranış).
#   🚫 GÖRMEZ: eski metin boşsa ve ek etiketi eski adda yanlış yazılmışsa (yalnız ad kuralına kalır).
function EkNo([string]$ad){ $es = [regex]::Match((($ad -split ' - ')[0]),'\bEk\s*(\d+)'); if($es.Success){ return $es.Groups[1].Value }; return '-' }
function AdaySec([string]$eskiAd, [string]$eskiHarf, [string[]]$adaylar, $yeniHarfTablo){
  if(-not $adaylar -or $adaylar.Count -eq 0){ return $null }
  if($adaylar.Count -eq 1){ return $adaylar[0] }
  if($env:KBE_MUTASYON -in 'ilk','eski'){ return $adaylar[0] }   # 'eski' = 08.10 öncesi davranış (eşdeğerlik provası)
  $pencereler = @(); for($i=0; $i -le $eskiHarf.Length-30; $i+=30){ $pencereler += $eskiHarf.Substring($i,30) }
  if($pencereler.Count){
    $enIyi = $null; $enIyiOran = 0.0
    foreach($a in $adaylar){ $m = "$($yeniHarfTablo[$a])"; $oran = @($pencereler | Where-Object { $m.Contains($_) }).Count / $pencereler.Count; if($oran -gt $enIyiOran){ $enIyiOran = $oran; $enIyi = $a } }
    if($enIyi -and $enIyiOran -ge 0.3){ return $enIyi }
  }
  if($env:KBE_MUTASYON -ne 'ek'){ $ayniEk = @($adaylar | Where-Object { (EkNo $_) -eq (EkNo $eskiAd) }); if($ayniEk.Count){ return $ayniEk[0] } }
  return $adaylar[0]
}
if($OzSinav){
  $gecti = 0; $kaldi = 0
  function Sina([string]$ad, [bool]$ok){ if($ok){ $script:gecti++; Write-Host "  OK    $ad" } else { $script:kaldi++; Write-Host "  KALDI $ad" -ForegroundColor Red } }
  foreach($std in 'TFRS 18','GVK (193 s.K.)','Sermaye Piyasası K. (6362 s.K.)','TİM ve İhr. Birlikleri K. (5910 s.K.)','A "tırnaklı", ad'){
    $p = OrListesiAyir ((YeniSuzgec $std) -split '&')[0]
    $beklenen = @(('kaynak_ad.eq.' + (OrDeger $std)), ('kaynak_ad.like.' + (OrDeger "$std *")))   # PS: virgul + dan siki baglanir, parantez sart
    Sina "süzgeç iki koşul ve tam değer: $std" ($null -ne $p -and $p.Count -eq 2 -and $p[0] -eq $beklenen[0] -and $p[1] -eq $beklenen[1])
  }
  # bağımsız (elle yazılmış) beklenen: OrDeger'in kendisiyle kıyas kör olurdu (07.10 mutasyonu bunu gösterdi)
  $pt = OrListesiAyir ((YeniSuzgec 'A "b", c') -split '&')[0]
  Sina 'tırnak kaçışı: A "b", c → elle beklenen' ($null -ne $pt -and $pt.Count -eq 2 -and $pt[0] -ceq 'kaynak_ad.eq."A \"b\", c"')
  $eskiBicim = 'or=' + [uri]::EscapeDataString('(kaynak_ad.eq.GVK (193 s.K.),kaynak_ad.like.GVK (193 s.K.) *)')
  $pe = OrListesiAyir $eskiBicim
  Sina 'hakem eski (tırnaksız) biçimi BOZUK görür' ($null -eq $pe -or $pe.Count -ne 2 -or $pe[0] -ne 'kaynak_ad.eq.GVK (193 s.K.)')
  Sina 'fren: yeni 0 → DUR (07.10 GVK vakası 370/0)' ([bool](KopusFreni 370 0 370))
  Sina 'fren: küçük kaynak eski 3 · yeni 0 → DUR (yalnız "yeni 0" kuralı yakalar)' ([bool](KopusFreni 3 0 1))
  Sina 'fren: 370 eskinin 200ü kopuyor → DUR' ([bool](KopusFreni 370 381 200))
  Sina 'fren: 370 eskinin 4ü kopuyor → GEÇ (07.10 gerçek GVK)' (-not (KopusFreni 370 381 4))
  Sina 'fren: TFRS 18 tipi 12 eskinin 5i kopuyor → GEÇ' (-not (KopusFreni 12 14 5))
  # 08.10 tazelik: parti-senkron -Etiket sessizce indirmeyince yereldeki ESKİ dosya ambara basılıyordu
  $gecici = Join-Path ([IO.Path]::GetTempPath()) ("kbe-taze-" + [guid]::NewGuid().ToString('N') + '.json')
  $once = (Get-Date).ToUniversalTime()
  Sina 'tazelik: dosya yok → YAZMA' (-not (IndirmeTaze $gecici $once))
  Set-Content -Path $gecici -Value '{}' -Encoding UTF8; (Get-Item $gecici).LastWriteTimeUtc = $once.AddHours(-5)
  Sina 'tazelik: dosya çağrıdan ÖNCE yazılmış (bayat yerel kopya) → YAZMA' (-not (IndirmeTaze $gecici $once))
  (Get-Item $gecici).LastWriteTimeUtc = $once.AddSeconds(1)
  Sina 'tazelik: dosya çağrıda yeniden yazılmış → YAZ' (IndirmeTaze $gecici $once)
  Remove-Item $gecici -ErrorAction SilentlyContinue
  # 08.10 aday seçimi (BDS 315 p.7 ↔ Ek 4 p.7 gerçek vakası; metin harfleri kısaltılmış)
  $tk = @{ 'X p.7 - Temel Kavramlar' = ('mesleki' * 3 + 'suphecilikdenetcininmeslekiyargisi' * 4); 'X Ek 4 p.7 - Kontrol Çevresi' = ('icdenetimfonksiyonukontrolcevresi' * 6) }
  $ad2 = @('X Ek 4 p.7 - Kontrol Çevresi','X p.7 - Temel Kavramlar')
  Sina 'aday: ek önde gelse de METNİ tutan ana metin seçilir' ((AdaySec 'X p.7 - BDS 200, 15-16' ('suphecilikdenetcininmeslekiyargisi' * 3) $ad2 $tk) -eq 'X p.7 - Temel Kavramlar')
  Sina 'aday: metin yoksa AYNI EK (eski adda ek yok → ana metin)' ((AdaySec 'X p.7 - BDS 200, 15-16' '' $ad2 $tk) -eq 'X p.7 - Temel Kavramlar')
  Sina 'aday: metin yoksa AYNI EK (eski "Ek 4" → Ek 4)' ((AdaySec 'X Ek 4 p.7 - Hakkında' '' @('X p.7 - Temel Kavramlar','X Ek 4 p.7 - Kontrol Çevresi') $tk) -eq 'X Ek 4 p.7 - Kontrol Çevresi')
  $Standart = 'BDS 315'
  Sina 'numara: "Ek 5 p.4" → yalnız 4 (ek no paragraf sayılmaz; 08.10 BDS 315 iki adlı öneri)' ((@(NumaraKumesi 'BDS 315 Ek 5 p.4 - Edinmek') -join ',') -eq '4')
  Sina 'numara: "p.46-47, p.52" → 46,47,52 (eski davranış)' ((@(NumaraKumesi 'BDS 315 p.46-47, p.52 - x') -join ',') -eq '46,47,52')
  $Standart = ''
  Sina 'aday: tek aday aynen'((AdaySec 'X p.9 - a' '' @('X p.9 - b') $tk) -eq 'X p.9 - b')
  Write-Host "OZ-SINAV: gecti $gecti - kaldi $kaldi"; exit $(if($kaldi){ 1 } else { 0 })
}
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
    $indirOnce = (Get-Date).ToUniversalTime().AddSeconds(-2)
    & $kabuk -NoProfile -File (Join-Path $PSScriptRoot 'parti-senkron.ps1') -Indir -Etiket $etiket -Sinav $sinav -Yaz | Out-Null
    $partiYolu = Join-Path $depoKok "veri\fabrika\kalip-parti-$etiket.json"
    # 08.10 (KGK oturumu): parti-senkron -Etiket 03.10'dan beri SESSİZCE indirmiyordu; bu araç da yereldeki ESKİ dosyayı düzenleyip
    #   -Yukle ile ambara basıyordu (bayat kopya ambardaki yeniyi ezer). Artık dosya bu çağrıda yeniden yazılmadıysa parti YAZILMAZ.
    if(-not (IndirmeTaze $partiYolu $indirOnce)){ Write-Host "  $etiket indirilemedi/tazelenmedi — sıraya yazıldı"; foreach($bag in $grup.Group){ $ertelenen.Add($bag) }; continue }
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

# --- eski / yeni kayıtlar
$eskiKayitlar = New-Object System.Collections.Generic.List[object]
foreach($kayit in (Get-Content $YedekDosya -Raw -Encoding UTF8 | ConvertFrom-Json)){ $eskiKayitlar.Add($kayit) }   # PS 5.1: dizi foreach ile açılır
$suzgec = YeniSuzgec $Standart   # 07.10: değer tırnaklı (parantezli kanun adları)
$yeniKayitlar = New-Object System.Collections.Generic.List[object]; $atla = 0
do { $sayfaAdet = 0; foreach($kayit in (Invoke-RestMethod -Uri "$sbKok/dokumanlar?select=kaynak_ad,metin&$suzgec&order=id&limit=1000&offset=$atla" -Headers $sbBasliklar -TimeoutSec 240)){ $yeniKayitlar.Add($kayit); $sayfaAdet++ }; $atla += 1000 } while($sayfaAdet -eq 1000)
$yeniAdKumesi = New-Object System.Collections.Generic.HashSet[string]; foreach($kayit in $yeniKayitlar){ [void]$yeniAdKumesi.Add("$($kayit.kaynak_ad)") }
$kopanAdlar = @($eskiKayitlar | ForEach-Object { "$($_.kaynak_ad)" } | Where-Object { -not $yeniAdKumesi.Contains($_) } | Select-Object -Unique)
Write-Host ("{0}: eski {1} · yeni {2} · kopan ad {3}" -f $Standart,$eskiKayitlar.Count,$yeniKayitlar.Count,$kopanAdlar.Count)
$fren = KopusFreni @($eskiKayitlar | ForEach-Object { "$($_.kaynak_ad)" } | Select-Object -Unique).Count $yeniKayitlar.Count $kopanAdlar.Count
# 07.10 (KGK oturumu): -KopusOnay = elle karar verilmiş MEŞRU yeniden adlandırma (BDS 250/402/550: standart-yut başlık düzeltmesi,
#   eski adların yarıdan fazlası gerçekten yeni başlığı aldı). Yalnız "yarıdan fazla" kuralını aşar; "yeni kayıt 0" freni HER ZAMAN durdurur.
#   Kullanan, CSV eşlemesini (tek yeni ad + aynı paragraf no) taşımadan ÖNCE ayrıca denetler.
if($fren -and $KopusOnay -and $yeniKayitlar.Count -gt 0){ Write-Host "KOPUŞ FRENİ ELLE AŞILDI (-KopusOnay): $fren" -ForegroundColor Yellow; $fren = '' }
if($fren){ Write-Host "DURDU (kopuş freni): $fren — rapor yazılmadı, taşıma yapılmadı. Süzgeci/yedeği kontrol et." -ForegroundColor Red; exit 2 }
if($kopanAdlar.Count -eq 0){ Write-Host 'Kopan ad yok — rapor yazılmadı.'; exit 0 }

# --- yeni ad önerileri
# 08.10 (KGK oturumu): numara → AD LİSTESİ. Eskiden numara başına İLK ad tutuluyordu; ana metin ve ekler aynı numarayı
#   taşıyınca (BDS 315 p.7 ↔ Ek 4 p.7, BDS 540 p.20 ↔ Ek 1 p.20) öneri yanlış eke gidiyordu: 08.10 metin yargısı 74 bağ (KGK/SMMM 55 onarıldı).
#   Seçim AdaySec ile: metin örtüşmesi, yoksa aynı ek.
$yeniNoHaritasi = @{}
foreach($kayit in $yeniKayitlar){ $noEs = [regex]::Match("$($kayit.kaynak_ad)",'\sp\.([A-Z]{0,2}\d{1,3}(?:\.\d{1,3}){0,3}[A-Z]{0,2})(?:\s|$)'); if($noEs.Success){ $k = $noEs.Groups[1].Value; if(-not $yeniNoHaritasi.ContainsKey($k)){ $yeniNoHaritasi[$k] = New-Object System.Collections.Generic.List[string] }; if(-not $yeniNoHaritasi[$k].Contains("$($kayit.kaynak_ad)")){ $yeniNoHaritasi[$k].Add("$($kayit.kaynak_ad)") } } }
$yeniHarf = @{}; foreach($kayit in $yeniKayitlar){ $yeniHarf["$($kayit.kaynak_ad)"] = HarfDizisi "$($kayit.metin)" }
$oneri = @{}
foreach($kopanAd in $kopanAdlar){
  $liste = New-Object System.Collections.Generic.List[string]
  $eskiHarf = HarfDizisi ((@($eskiKayitlar | Where-Object { "$($_.kaynak_ad)" -eq $kopanAd }) | ForEach-Object { "$($_.metin)" }) -join '')
  foreach($no in (NumaraKumesi $kopanAd)){ if($yeniNoHaritasi.ContainsKey($no)){ $secilen = AdaySec $kopanAd $eskiHarf $yeniNoHaritasi[$no].ToArray() $yeniHarf; if($secilen -and -not $liste.Contains($secilen)){ $liste.Add($secilen) } } }
  $pencereler = @(); for($i=0; $i -le $eskiHarf.Length-30; $i+=30){ $pencereler += $eskiHarf.Substring($i,30) }
  if($liste.Count -eq 0 -and $pencereler.Count){
    $isabetler = foreach($ad in $yeniHarf.Keys){ $sayi = @($pencereler | Where-Object { $yeniHarf[$ad].Contains($_) }).Count; if($sayi -ge 4){ [pscustomobject]@{ ad=$ad; sayi=$sayi } } }
    foreach($isabet in @($isabetler | Sort-Object sayi -Descending | Select-Object -First 8)){ $liste.Add($isabet.ad) }
  }
  $oneri[$kopanAd] = $liste.ToArray()
}
if($YalnizOneri){ foreach($k in ($oneri.Keys | Sort-Object)){ Write-Output ("ONERI`t{0}`t{1}" -f $k,(@($oneri[$k]) -join ' ; ')) }; exit 0 }

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
