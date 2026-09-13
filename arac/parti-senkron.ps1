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
  [string]$Sinav  = 'SGS',
  [switch]$Zorla,                  # damga kiyaslamasini atla
  [switch]$Yaz                     # olmadan: kuru kosu
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $here 'olcum-kapilari.ps1')
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
  $n=0; $hata=0
  foreach($x in $g){
    $icerik=$null
    # ⚠ Kosan tur ayni dosyayi yaziyor olabilir - okuma YARISI. 3 kez dene.
    foreach($d in 1..3){ try{ $icerik=[IO.File]::ReadAllText($x.dosya.FullName,[Text.UTF8Encoding]::new($false)); break }catch{ Start-Sleep -Milliseconds 500 } }
    if(-not $icerik){ Write-Host ("  ! okunamadi: {0}" -f $x.etiket) -ForegroundColor Yellow; $hata++; continue }
    # Bozuk JSON gonderilmez
    try{ [void]($icerik|ConvertFrom-Json) }catch{ Write-Host ("  ! bozuk JSON, ATLANDI: {0}" -f $x.etiket) -ForegroundColor Red; $hata++; continue }
    $govde = '{"etiket":' + (ConvertTo-Json $x.etiket) + ',"sinav":' + (ConvertTo-Json $Sinav) +
             ',"yazan":' + (ConvertTo-Json $yazan) + ',"icerik":' + $icerik + '}'
    try{
      $b=[Text.Encoding]::UTF8.GetBytes($govde)
      [void](Invoke-RestMethod -Method Post -Uri ($TABAN+'?on_conflict=etiket') -Headers ($SB + @{ Prefer='resolution=merge-duplicates,return=minimal' }) -Body $b -TimeoutSec 300)
      $n++
      if($n % 20 -eq 0){ Write-Host ("  ... {0}/{1}" -f $n,$g.Count) -ForegroundColor DarkGray }
    }catch{ Write-Host ("  ! yazilamadi {0}: {1}" -f $x.etiket,$_.Exception.Message) -ForegroundColor Red; $hata++ }
  }
  Write-Host ("`nYUKLENDI: {0:N0} parti · hata {1}" -f $n,$hata) -ForegroundColor Green
  return
}

# --- INDIR: ambar -> yerel ----------------------------------------------------
$al=New-Object System.Collections.Generic.List[string]
foreach($et in $ambar.Keys){
  if($yerel.ContainsKey($et) -and -not $Zorla -and $yerel[$et].LastWriteTimeUtc -ge $ambar[$et].guncelleme){ continue }
  $al.Add($et)
}
$a=Dizi $al
Write-Host ("INDIRILECEK: {0:N0} parti" -f $a.Count) -ForegroundColor Green
if(-not $Yaz){ Write-Host "`nKURU KOSU - dosya yazilmadi. Yazmak icin: -Yaz" -ForegroundColor Yellow; return }
$n=0; $hata=0
foreach($et in $a){
  $u=$TABAN+'?select=icerik&etiket=eq.'+[uri]::EscapeDataString($et)
  try{
    $r=Invoke-RestMethod -Uri $u -Headers $SB -TimeoutSec 300
    $s=@($r); if(-not $s.Count){ continue }
    $j=ConvertTo-Json -InputObject $s[0].icerik -Depth 20
    [IO.File]::WriteAllText((Join-Path $fabrika "kalip-parti-$et.json"),$j,[Text.UTF8Encoding]::new($false))
    $n++
    if($n % 20 -eq 0){ Write-Host ("  ... {0}/{1}" -f $n,$a.Count) -ForegroundColor DarkGray }
  }catch{ Write-Host ("  ! indirilemedi {0}: {1}" -f $et,$_.Exception.Message) -ForegroundColor Red; $hata++ }
}
Write-Host ("`nINDIRILDI: {0:N0} parti · hata {1}" -f $n,$hata) -ForegroundColor Green
