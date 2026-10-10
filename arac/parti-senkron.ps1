#requires -Version 5.1
<#
================================================================================
  PARTI SENKRON — parti onbellegi yerel <-> ambar  (11.09.2026)
  Cem: "bulut hattini simdi kuralim"

  NIYE: parti onbellegi (veri/fabrika/kalip-parti-*.json) yalniz Cem'in
  dizustunde ve .gitignore'da. GitHub Actions'ta uretim kosulsa is bitince
  onbellek KAYBOLUYOR. Bu betik o bagi kesiyor:
     -Indir  : ambardan yerele  (Actions isin BASINDA cagirir)
     -Yukle  : yerelden ambara  (Actions isin SONUNDA cagirir)
  Yerelde de ayni betik kullanilir; iki taraf ayni yerden okur/yazar.

  ⛔ URETICIYE DOKUNMAZ. kalip-parti-uret.ps1 yine ayni dosyaya yazar; bu
     betik sadece o dosyayi tasir. Boylece kosan turlar bozulmaz.

  ⚠ CAKISMA: ayni partiyi iki taraf ayni anda yazarsa SON YAZAN kazanir.
     Korunma: -Yukle YALNIZ yerelde DAHA YENI olani gonderir (guncelleme
     damgasi kiyaslanir), -Indir yalniz ambarda daha yeni olani alir.
     Zorlamak icin -Zorla.

  BEDEL 0 — yalniz ambar okuma/yazma, model cagrisi YOK.
================================================================================
#>
param(
  [switch]$Indir,
  [switch]$Yukle,
  [string]$Etiket = '',            # yalniz bu parti (bos = hepsi)
  [string]$OnEk = '',              # 16.09: yalniz bu onekle baslayan partiler (or. 'smmm-'); bos = hepsi
  [string]$Sinav  = 'SGS',
  [switch]$Zorla,                  # damga kiyaslamasini atla
  [switch]$Yaz,                    # olmadan: kuru kosu
  [switch]$Eski,                   # 03.10: eski tek tek + PS cevirmeli indirme (esdegerlik provasi icin)
  [string]$Hedef = ''              # 03.10: indirme klasoru (bos = veri\fabrika); prova ayri klasore indirir
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $here 'olcum-kapilari.ps1')
. (Join-Path $depoKok 'motor\model-kod.ps1')   # 10.10: ambara giden soru verisinde "model": "claude-…" -> nötr kod (yeni yazıcı ModelKod'u unutursa ağ)
$ok=Test-OlcumKapilari -Sessiz
if((Dizi $ok).Count){ foreach($h in (Dizi $ok)){ Write-Host "  - $h" -ForegroundColor Red }; throw 'olcum kapilari dustu' }

if(-not ($Indir -or $Yukle)){ throw 'Yon belirt: -Indir ya da -Yukle' }
if($Indir -and $Yukle){ throw 'Tek yon sec: -Indir YA DA -Yukle' }

$KEY="$($env:SUPABASE_SERVICE_KEY)".Trim()
if(-not $KEY){ $KEY="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok.' }
$TABAN='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti'
$SB=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'Content-Type'='application/json'
       Accept='application/json'; 'User-Agent'='mevzuat-radar-robot/1.0' }
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$fabrika=Join-Path $depoKok 'veri\fabrika'
New-Item -ItemType Directory -Force $fabrika | Out-Null
# Kim yaziyor - cakisma teshisi icin
$yazan = if($env:GITHUB_RUN_ID){ "actions-$($env:GITHUB_RUN_ID)" } else { "yerel-$($env:COMPUTERNAME)" }

# --- AMBAR DAMGALARI (icerik CEKILMEDEN: hafif) -------------------------------
function AmbarDamgalari{
  $h=@{}; $off=0
  while($true){
    $u=$TABAN+'?select=etiket,guncelleme,soru_sayisi&order=etiket.asc&limit=1000&offset='+$off
    if($Etiket){ $u=$TABAN+'?select=etiket,guncelleme,soru_sayisi&etiket=eq.'+[uri]::EscapeDataString($Etiket) }
    elseif($OnEk){ $u=$TABAN+'?select=etiket,guncelleme,soru_sayisi&order=etiket.asc&limit=1000&offset='+$off+'&etiket=like.'+[uri]::EscapeDataString($OnEk+'*') }
    $r=$null
    try{ $r=Invoke-RestMethod -Uri $u -Headers $SB -TimeoutSec 90 }
    catch{ throw ("ambar okunamadi: " + $_.Exception.Message + " — 011_kalip_parti.sql BASILDI MI? (radar-app/sql/UYGULANDI.md)") }
    # 13.09 ÖLÇÜLDÜ: [datetime]"2026-09-13T04:33:01+00:00" Kind=Local döner (07:33, TR +3); aşağıda dosyanın LastWriteTimeUtc'siyle
    # kıyaslanıyordu → ambar 3 saat "daha yeni" görünüyordu. Sonuç: kuru koşu 883 partinin HEPSİNİ indirilecek sayıyordu ve ambar
    # güncellemesinden sonraki 3 saat içinde yerelde değişen parti -Yukle'de SESSİZCE gönderilmiyordu. İki taraf da UTC.
    $s=@($r); foreach($x in $s){ $h["$($x.etiket)"]=[pscustomobject]@{ guncelleme=[DateTimeOffset]::Parse("$($x.guncelleme)").UtcDateTime; soru=[int]$x.soru_sayisi } }
    if($Etiket -or $s.Count -lt 1000){ break }
    $off+=1000
  }
  return $h
}

$ambar=AmbarDamgalari
Write-Host ("ambarda parti: {0:N0}" -f $ambar.Count) -ForegroundColor Cyan
$yerel=@{}
foreach($x in @(Get-ChildItem $fabrika -Filter 'kalip-parti-*.json' -ErrorAction SilentlyContinue)){
  $et=($x.BaseName -replace '^kalip-parti-','')
  if($Etiket -and $et -ne $Etiket){ continue }
  if($OnEk -and -not $et.StartsWith($OnEk)){ continue }
  $yerel[$et]=$x
}
Write-Host ("yerelde parti: {0:N0}" -f $yerel.Count) -ForegroundColor Cyan

# --- YUKLE: yerel -> ambar ----------------------------------------------------
if($Yukle){
  $gonder=New-Object System.Collections.Generic.List[object]
  foreach($et in $yerel.Keys){
    $f=$yerel[$et]
    if(-not $Zorla -and $ambar.ContainsKey($et) -and $ambar[$et].guncelleme -ge $f.LastWriteTimeUtc){ continue }
    $gonder.Add([pscustomobject]@{ etiket=$et; dosya=$f })
  }
  $g=Dizi $gonder
  Write-Host ("GONDERILECEK: {0:N0} parti" -f $g.Count) -ForegroundColor Green
  if(-not $Yaz){ Write-Host "`nKURU KOSU - ambara yazilmadi. Yazmak icin: -Yaz" -ForegroundColor Yellow; return }
  $n=0; $hata=0; $mzAlan=0; $mzParti=0
  foreach($x in $g){
    $icerik=$null
    # ⚠ Kosan tur ayni dosyayi yaziyor olabilir - okuma YARISI. 3 kez dene.
    foreach($d in 1..3){ try{ $icerik=[IO.File]::ReadAllText($x.dosya.FullName,[Text.UTF8Encoding]::new($false)); break }catch{ Start-Sleep -Milliseconds 500 } }
    if(-not $icerik){ Write-Host ("  ! okunamadi: {0}" -f $x.etiket) -ForegroundColor Yellow; $hata++; continue }
    # Bozuk JSON gonderilmez
    try{ [void]($icerik|ConvertFrom-Json) }catch{ Write-Host ("  ! bozuk JSON, ATLANDI: {0}" -f $x.etiket) -ForegroundColor Red; $hata++; continue }
    # 10.10 (CLAUDE.md "veriye model adı girmez"): yalnız "model":"claude-…" değeri çevrilir, başka bayt değişmez; '__' sistem kaydı çevrilmez.
    if(-not (ModelIziSistemPartisi $x.etiket)){ $mn=ModelIziNotrMetin $icerik; if($mn.sayi -gt 0){ $icerik=$mn.metin; $mzAlan+=$mn.sayi; $mzParti++ } }
    # 13.09 OLCULDU: ambardaki 975 partinin 15'i yanlis etiketliydi (smmm-* 6 + kgk-* 9 -> sinav=SGS), cunku -Yukle HER partiye
    # -Sinav'i (varsayilan SGS) basiyordu. Etiket oneki sinavi kesin soyluyorsa o kazanir; digerleri (sgs-, pilot6-, devir-, spl-) eskisi gibi.
    $sinavBu = if("$($x.etiket)" -match '^smmm-'){ 'SMMM' } elseif("$($x.etiket)" -match '^kgk-'){ 'KGK' } else { $Sinav }
    $govde = '{"etiket":' + (ConvertTo-Json $x.etiket) + ',"sinav":' + (ConvertTo-Json $sinavBu) +
             ',"yazan":' + (ConvertTo-Json $yazan) + ',"icerik":' + $icerik + '}'
    try{
      $b=[Text.Encoding]::UTF8.GetBytes($govde)
      [void](Invoke-RestMethod -Method Post -Uri ($TABAN+'?on_conflict=etiket') -Headers ($SB + @{ Prefer='resolution=merge-duplicates,return=minimal' }) -Body $b -TimeoutSec 300)
      $n++
      if($n % 20 -eq 0){ Write-Host ("  ... {0}/{1}" -f $n,$g.Count) -ForegroundColor DarkGray }
    }catch{ Write-Host ("  ! yazilamadi {0}: {1}" -f $x.etiket,$_.Exception.Message) -ForegroundColor Red; $hata++ }
  }
  Write-Host ("`nYUKLENDI: {0:N0} parti · hata {1}" -f $n,$hata) -ForegroundColor Green
  Write-Host ("MODEL-IZI: {0:N0} alan nötr koda çevrildi ({1:N0} parti) — 0 değilse bir yazıcı ModelKod kullanmıyor ya da eski veri" -f $mzAlan,$mzParti) -ForegroundColor $(if($mzAlan){'Yellow'}else{'DarkGray'})
  return
}

# --- INDIR: ambar -> yerel ----------------------------------------------------
$al=New-Object System.Collections.Generic.List[string]
$atlanan=0
foreach($et in $ambar.Keys){
  # 03.10.2026: etiketinde "/" olan kayıtlar soru partisi DEĞİL, sistem kaydı (__bekleyen/msgbatch_*, __hazir/*). Dosya adına
  #   yazılamadıkları için HİÇBİR ZAMAN diske inmediler - ama her yayında içerikleriyle tamamen indirilip atılıyorlardı:
  #   bulut günlüğü 03.10: "INDIRILECEK 14,240" -> 11.765'i bu kayıt, her biri "indirilemedi" satırı (34 dk'nın çoğu).
  #   Atlamak diske yazılanı DEĞİŞTİRMEZ (zaten yazılamıyorlardı). Onları okuyan kendi yolundan okur (arac/bekleyen-senkron.ps1).
  if($et -like '*/*'){ $atlanan++; continue }
  if($yerel.ContainsKey($et) -and -not $Zorla -and $yerel[$et].LastWriteTimeUtc -ge $ambar[$et].guncelleme){ continue }
  $al.Add($et)
}
# 08.10.2026 (KGK oturumu): @(...) SART. Dizi tek elemanli diziyi dondurunce PowerShell onu acar, $a duz metin olur;
#   hizli yolda $a[0..0] etiketin ILK HARFINI verir ("k"), ambar bos doner, eski yol da bos doner, hata SAYILMAZ:
#   -Etiket ile her indirme 03.10'dan beri "INDIRILDI: 0 parti · hata 0" diyordu (kaynak-bolunme-etki bu yolu kullanir).
$a=@(Dizi $al)
Write-Host ("INDIRILECEK: {0:N0} parti (sistem kaydı atlandı: {1:N0})" -f $a.Count,$atlanan) -ForegroundColor Green
if(-not $Yaz){ Write-Host "`nKURU KOSU - dosya yazilmadi. Yazmak icin: -Yaz" -ForegroundColor Yellow; return }
$hedefKlasor = if($Hedef){ New-Item -ItemType Directory -Force $Hedef | Out-Null; (Resolve-Path $Hedef).Path } else { $fabrika }
$n=0; $hata=0
# 03.10.2026 (Cem "1 ve 2 yap"): HIZLI YOL. Bulutta bu dongu her yayinda 34,5 dk suruyordu (2.491 parti, tek tek;
#   her parti PS nesnesine cevrilip ConvertTo-Json -Depth 20 ile yeniden yaziliyordu - PS 5.1'de en yavas adim).
#   Simdi: ambarin dondurdugu HAM JSON'daki icerik oldugu gibi yazilir (yeniden cevirme yok) + 8 parti AYNI ANDA iner.
#   Okuyucular dosyayi JSON olarak ayristirir; bicim (girinti) farki onlar icin yoktur. Esdegerlik: arac/parti-senkron-prova.ps1
#   (iki yolun dosyalari AYRISTIRILIP alan alan kiyaslanir, ambarin tamami). Bir parti hizli yolda dusmezse eski yoldan denenir.
#   GORMEZ: ambar icerik alani nesne degilse (null/dizi) hizli yol o partiyi eski yola birakir.
if(-not $Eski -and $a.Count){
  Add-Type -AssemblyName System.Net.Http
  $hc = New-Object System.Net.Http.HttpClient; $hc.Timeout = [TimeSpan]::FromSeconds(300)
  [void]$hc.DefaultRequestHeaders.TryAddWithoutValidation('apikey', $KEY)
  [void]$hc.DefaultRequestHeaders.TryAddWithoutValidation('Authorization', "Bearer $KEY")
  [void]$hc.DefaultRequestHeaders.TryAddWithoutValidation('Accept', 'application/vnd.pgrst.object+json')
  [void]$hc.DefaultRequestHeaders.TryAddWithoutValidation('User-Agent', 'mevzuat-radar-robot/1.0')
  $kalan = New-Object System.Collections.Generic.List[string]
  for($i=0; $i -lt $a.Count; $i+=8){
    $grup = @($a[$i..([Math]::Min($i+7,$a.Count-1))])
    $isler = @($grup | ForEach-Object { [pscustomobject]@{ et=$_; is=$hc.GetStringAsync($TABAN+'?select=icerik&etiket=eq.'+[uri]::EscapeDataString($_)) } })
    try{ [void][Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($isler | ForEach-Object { $_.is })) }catch{ }
    foreach($x in $isler){
      if($x.is.Status -ne 'RanToCompletion'){ $kalan.Add($x.et); continue }
      $g = $x.is.Result.Trim(); $on = '{"icerik":'
      if(-not $g.StartsWith($on) -or -not $g.EndsWith('}')){ $kalan.Add($x.et); continue }
      $ic = $g.Substring($on.Length, $g.Length - $on.Length - 1).Trim()
      if(-not $ic.StartsWith('{')){ $kalan.Add($x.et); continue }
      # 03.10 tam prova: bir etiket dosya yoluna yazılamadı (DirectoryNotFound) ve tüm hızlı yolu durdurdu - eski yol bunu
      #   parti başına yakalıyordu; aynı davranış: yazılamayan parti eski yola bırakılır (orada da hata sayılır)
      try{ [IO.File]::WriteAllText((Join-Path $hedefKlasor "kalip-parti-$($x.et).json"),$ic,[Text.UTF8Encoding]::new($false)) }catch{ $kalan.Add($x.et); continue }
      $n++
    }
    if($n -and ($n % 200 -lt 8)){ Write-Host ("  ... {0}/{1}" -f $n,$a.Count) -ForegroundColor DarkGray }
  }
  $hc.Dispose()
  if($kalan.Count){ Write-Host ("  hizli yolda inmeyen {0} parti eski yoldan deneniyor" -f $kalan.Count) -ForegroundColor Yellow }
  $a = @(Dizi $kalan)
}
foreach($et in $a){
  $u=$TABAN+'?select=icerik&etiket=eq.'+[uri]::EscapeDataString($et)
  try{
    $r=Invoke-RestMethod -Uri $u -Headers $SB -TimeoutSec 300
    $s=@($r); if(-not $s.Count){ Write-Host ("  ! ambarda bos dondu {0}" -f $et) -ForegroundColor Red; $hata++; continue }   # 08.10: sessiz gecis "hata 0" yalanini uretiyordu
    $j=ConvertTo-Json -InputObject $s[0].icerik -Depth 20
    [IO.File]::WriteAllText((Join-Path $hedefKlasor "kalip-parti-$et.json"),$j,[Text.UTF8Encoding]::new($false))
    $n++
    if($n % 20 -eq 0){ Write-Host ("  ... {0}/{1}" -f $n,$a.Count) -ForegroundColor DarkGray }
  }catch{ Write-Host ("  ! indirilemedi {0}: {1}" -f $et,$_.Exception.Message) -ForegroundColor Red; $hata++ }
}
Write-Host ("`nINDIRILDI: {0:N0} parti · hata {1}" -f $n,$hata) -ForegroundColor Green
