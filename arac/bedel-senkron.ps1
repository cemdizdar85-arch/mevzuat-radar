#requires -Version 5.1
<#
================================================================================
  BEDEL SENKRON — harcama defteri yerel <-> ambar  (11.09.2026)
  ⛔ BU BETIK FRENIN KABLOSUDUR.

  Cem sordu: "kalitemizden olusturdugumuz kurallar, hicbirinde sikinti olmaz
  de mi patron". Olctum, cevap HAYIRDI. En tehlikeli bulgu:

  kalip-kosucu.ps1 aylik tavani YEREL bir dosyadan okuyor
  (veri/fabrika/bedel-kayit.jsonl, .gitignore'da). Kodun kendi satiri:
        if(-not (Test-Path $y)){ return $t }      <- dosya yoksa 0 DONDURUR
  GitHub Actions'ta o dosya YOK -> defter BOS -> "bu ay 0 USD harcanmis" ->
  1.700 USD durma esigi HIC TETIKLENMEZ. Bulut hatti bu betik olmadan
  kurulursa FRENSIZ kosar.

  NE YAPAR:
    -Yukle : yerel defteri ambara gonderir (yalniz AMBARDA OLMAYAN satirlar)
    -Indir : ambardaki satirlari yerel deftere ekler (yalniz eksik olanlar)
    -Ozet  : yerel ve ambar toplamlarini YAN YANA gosterir (kiyas)

  ⚠ TEKILLESTIRME: ayni parti iki kez kosarsa IKI SATIR olur - bu DOGRU,
    iki kez odendi. Tekillik anahtari (zaman + etiket + tutar) uclusudur;
    ayni saniyede ayni partiye ayni tutar iki kez yazilmaz.

  BEDEL 0 — yalniz ambar okuma/yazma.
================================================================================
#>
param(
  [switch]$Yukle,
  [switch]$Indir,
  [switch]$Ozet,
  [string]$Ay = '',                # 'YYYY-MM' (bos = bu ay)
  [switch]$Yaz,
  # 25.09.2026: yerel defterdeki 3 SAAT KAYMIS IKIZ satirlari (asagidaki SAAT DILIMI notu) yedekleyip cikarir. -Yaz olmadan kuru kosu.
  [switch]$YerelIkizTemizle,
  [switch]$Sinav                   # 25.09: TabloVar (±3 saat esleme) oz-sinavi; ag yok, anahtar gerekmez
)
# ⛔⭐ 25.09.2026 SAAT DILIMI (Cem "gm onerilerini yap" -> "devam et"). OLCULDU:
#   · Yukle / motor/api-hedef.ps1 Save-BedelKesin zamani ([datetime]$z).ToString('o') ile OFSETSIZ yolluyordu. Bulut
#     makinesinde (UTC) zararsiz; BU makinede (TR, +03) duvar saati ambara UTC diye yazildi -> ambarda 3 saat kaymis.
#   · Indir ambar zamanini ([datetime]) ile YEREL saate cevirip (+3) deftere yaziyordu -> AYNI harcama yerel defterde
#     ikinci kez (olculdu: 810 satir / 813,60 USD ikiz). Anahtar (zaman+etiket+tutar) iki hali farkli satir sandi; ambardaki
#     706 mukerrer satirin (793,60 USD, hepsi yazan=yerel-GK) da en olasi kaynagi bu (Yukle ayni satiri tekrar yollamis) -
#     KANITLANMADI, cunku eski gonderim gunlukleri yok.
#   DUZELTME: (1) yazarken zaman ACIK OFSETLE ([DateTimeOffset] yerel) · (2) 'zaten var mi' kontrolu ayni etiket+tutarin
#     ±3 saat kaymis halini de AYNI satir sayar (eski yanlis kayitlar ambarda duruyor) · (3) -YerelIkizTemizle.
#   🚫 GORMEZ: ayni partinin ayni kurusla tam 3 saat arayla gercekten iki kez odenmesini (ikizden ayiramaz; olasiligi
#     kurus hassasiyetinde 6 basamakli tutarla pratikte yok, ama olculmedi) · ambardaki eski mukerrerleri SILMEZ.
function ZamanOfsetli($zaman){ return ([DateTimeOffset]([datetime]::SpecifyKind([datetime]$zaman,[DateTimeKind]::Local))).ToString('o') }
function AnahtarKaydir([string]$anahtar,[int]$saat){
  $parca=$anahtar.Split('|',2); $z=[datetime]::MinValue
  if(-not [datetime]::TryParseExact($parca[0],'yyyy-MM-dd HH:mm',[cultureinfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$z)){ return $anahtar }
  return ($z.AddHours($saat).ToString('yyyy-MM-dd HH:mm',[cultureinfo]::InvariantCulture) + '|' + $parca[1])
}
function TabloVar($tablo,[string]$anahtar){
  foreach($kayma in 0,-3,3){ if($tablo.ContainsKey((AnahtarKaydir $anahtar $kayma))){ return $true } }
  return $false
}
if($Sinav){
  $dusen=New-Object System.Collections.Generic.List[string]
  $t=@{ '2026-09-07 23:58|smmm-w9-1-fmuh-zor|0.130000'=1 }
  if(-not (TabloVar $t '2026-09-07 23:58|smmm-w9-1-fmuh-zor|0.130000')){ $dusen.Add('ayni anahtar bulunamadi') }
  if(-not (TabloVar $t '2026-09-08 02:58|smmm-w9-1-fmuh-zor|0.130000')){ $dusen.Add('+3 saat ikiz bulunamadi (gun devri)') }
  if(-not (TabloVar $t '2026-09-07 20:58|smmm-w9-1-fmuh-zor|0.130000')){ $dusen.Add('-3 saat ikiz bulunamadi') }
  if(TabloVar $t '2026-09-08 00:58|smmm-w9-1-fmuh-zor|0.130000'){ $dusen.Add('+1 saat fark YANLIS ALARM') }
  if(TabloVar $t '2026-09-07 22:58|smmm-w9-1-fmuh-zor|0.130000'){ $dusen.Add('-1 saat fark YANLIS ALARM') }
  if(TabloVar $t '2026-09-08 02:58|smmm-w9-1-fmuh-zor|0.140000'){ $dusen.Add('farkli tutar YANLIS ALARM') }
  if(TabloVar $t '2026-09-08 02:58|smmm-w9-2-fmuh-zor|0.130000'){ $dusen.Add('farkli etiket YANLIS ALARM') }
  if((ZamanOfsetli '2026-09-07 23:58') -notmatch '^2026-09-07T23:58:00.*[+-]\d\d:\d\d$'){ $dusen.Add('ofsetli zaman bicimi: ' + (ZamanOfsetli '2026-09-07 23:58')) }
  if($dusen.Count){ $dusen | ForEach-Object { Write-Host "  DUSTU: $_" -ForegroundColor Red }; exit 1 }
  Write-Host 'BEDEL SENKRON OZ-SINAVI YESIL (8 vaka: 3 esleme · 4 yanlis alarm · 1 bicim)' -ForegroundColor Green; exit 0
}
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $here 'olcum-kapilari.ps1')
$ok=Test-OlcumKapilari -Sessiz
if((Dizi $ok).Count){ foreach($h in (Dizi $ok)){ Write-Host "  - $h" -ForegroundColor Red }; throw 'olcum kapilari dustu' }

if(-not $Ay){ $Ay=(Get-Date -Format 'yyyy-MM') }
$KEY="$($env:SUPABASE_SERVICE_KEY)".Trim()
if(-not $KEY){ $KEY="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok.' }
$TABAN='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
$SB=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'Content-Type'='application/json'
       Accept='application/json'; 'User-Agent'='mevzuat-radar-robot/1.0' }
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$defter=Join-Path $depoKok 'veri\fabrika\bedel-kayit.jsonl'
$yazan = if($env:GITHUB_RUN_ID){ "actions-$($env:GITHUB_RUN_ID)" } else { "yerel-$($env:COMPUTERNAME)" }

function YerelSatirlar{
  $l=New-Object System.Collections.Generic.List[object]
  if(-not (Test-Path $defter)){ return $l }
  foreach($s in (Get-Content $defter -Encoding UTF8)){
    if(-not $s.Trim()){ continue }
    $o=$null; try{ $o=$s|ConvertFrom-Json }catch{ continue }
    $l.Add($o)
  }
  return $l
}
function AmbarSatirlar([string]$ay){
  $l=New-Object System.Collections.Generic.List[object]
  $off=0
  while($true){
    # 19.09: sira KARARLI olmali - 'zaman.asc' tek basina esit zamanlarda rastgele sirayla doner,
    #   es zamanli ekleme varken offset sayfalamasi kayit kacirabilir/tekrarlayabilir (mukerrer satir savunmasi 3).
    $u=$TABAN+'/bedel_kaydi?select=zaman,etiket,ders,toplam_usd&ay=eq.'+[uri]::EscapeDataString($ay)+'&order=zaman.asc,id.asc&limit=1000&offset='+$off
    $r=$null
    try{ $r=Invoke-RestMethod -Uri $u -Headers $SB -TimeoutSec 90 }
    catch{ throw ("ambar okunamadi: " + $_.Exception.Message + " — rag-motor/sql/011_kalip_parti.sql BASILDI MI?") }
    $s=@($r); foreach($x in $s){ $l.Add($x) }
    if($s.Count -lt 1000){ break }
    $off+=1000
  }
  return $l
}
# Tekillik anahtari: dakika + etiket + tutar (yerel defter dakika hassasiyetinde yaziyor)
# ⛔⭐ 19.09.2026 MUKERRER SATIR SAVUNMASI (kok neden KANITLANMADI - asagidaki olcumlere bak).
#   OLCULDU: eylul defteri 22.644 satir / 26.111,82 USD; tekil (zaman+etiket+tutar) 3.399 satir /
#   2.833,84 USD -> 9,2 KAT sisme. Ambarda ayni satirin 31 kopyasi vardi (hepsi yazan='yerel-GK').
#   ⚠ KOK NEDEN OLCULDU AMA KANITLANAMADI — iki hipotez bugunku veriyle YENIDEN URETILEMEDI:
#     (a) saat dilimi: eski anahtar ile yeni anahtar bugun AYNI sonucu veriyor (ikisi de 796 satir),
#         yani [datetime] belirsizligi bu makinede farka yol acmiyor.
#     (b) sayfalama: 'zaman.asc' ile iki kez cekildi -> 21.878 / 21.878 satir, kacan ya da
#         tekrarlanan kayit YOK.
#   Geriye kalan en olasi aciklama: es zamanli yukleme + offset sayfalama (12-13.09'da paralel bulut
#   kosulari vardi; kayit eklenirken offset kayar). KANITLANMADI, iddia da EDILMIYOR.
#   SISME YALNIZ RAPOR DEGIL FREN SORUNU: butce kapisi ayni harcamayi 9 kez sayinca kosu, parasi
#   bitmeden durur (17.09 A/B'sinde B kolu FAZ B'ye gelmeden kesildi).
#   UC KATMAN SAVUNMA (hepsi bedel 0, dogru davranisi degistirmez):
#     1. anahtar belirsizligi kapandi: offsetli zaman DAIMA [datetimeoffset] ile yerel saate cevrilir,
#        tutar F6 sabit bicimde yazilir (0,13 ile 0,130000 ayni satirdir).
#     2. IC TEKILLESTIRME: ayni anahtardan birden cok satir varsa yalniz biri islenir (asagida).
#     3. sayfalama KARARLI siraya alindi (zaman.asc,id.asc) - es zamanli ekleme sirasinda kaymaz.
#   Okuma tarafi da tekillestirildi: motor/kalip-kosucu.ps1 (PlanHarcama/AyHarcama),
#   motor/uretim-plani.ps1, arac/sgs-a6-kos.ps1. Sismis dosya temizligi: arac/bedel-defter-tekille.ps1.
function Anahtar($zaman,$etiket,$tutar){
  $z=''; $m="$zaman".Trim()
  if($m -match '(Z|[+-]\d{2}:?\d{2})$'){
    $dto=[DateTimeOffset]::MinValue
    if([DateTimeOffset]::TryParse($m,[ref]$dto)){ $z=$dto.LocalDateTime.ToString('yyyy-MM-dd HH:mm') }
  }
  if(-not $z){ try{ $z=([datetime]$m).ToString('yyyy-MM-dd HH:mm') }catch{ $z=$m } }
  return ($z + '|' + "$etiket" + '|' + ([double]$tutar).ToString('F6',[cultureinfo]::InvariantCulture))
}

# ---------------------------------------------------------------------------
# ⚠ 11.09 22:55 — CEM KARARI: "BU İKİ RAKAMI İPTAL ET".
#
# Bu betik once konsol capasini (veri/fabrika/bedel-konsol.json) da tasiyacak
# sekilde genisletilmisti, cunku kosucu ile defter iki AYRI rakam goruyordu:
#     kosucunun gordugu 933,54 USD  ·  ham defter 630,15 USD  ·  fark 303,39
# Cem aylik tavani kapi olmaktan cikardi (gerekce: "bakiye kadar harcayacak ve
# istedigimiz soru kadar basacak"). Olculdu ve gerekce DOGRULANDI:
# motor/kalip-parti-uret.ps1'deki KAPI-BAKIYE her parti oncesi Anthropic
# bakiyesini yokluyor, yetmezse parti HIC BASLAMIYOR - ve o kapi bulutta da
# calisir, yerel dosyaya bagli degil.
#
# Bu yuzden capa mantigi EKLENMEDI: defter artik bir KAPI degil, yalniz
# harcama KAYDI. Tek is, iki tarafin ayni kaydi gormesi.
# Geri almak gerekirse: capa = bedel-konsol.json, kosucudaki AyHarcama()
# ile ayni mantik (capa + capadan sonraki satirlar).
# ---------------------------------------------------------------------------
$yerel=Dizi (YerelSatirlar)
$yerelAy=@($yerel|Where-Object{ "$($_.zaman)" -like "$Ay*" })
$ambar=Dizi (AmbarSatirlar $Ay)

$yT=0.0; foreach($x in $yerelAy){ $yT+=[double]$x.toplamUsd }
$aT=0.0; foreach($x in $ambar){ $aT+=[double]$x.toplam_usd }
# ⭐ 25.09.2026 (Cem "gm onerilerini yap"): OZET de TEKIL toplamla kiyaslar. OLCULDU: bulut kosusu "FARK 793,60 USD -
#   iki taraf ayni freni gormuyor" yaziyordu; ambardaki MUKERRER satirlar (ayni zaman+etiket+tutar) tam 706 satir /
#   793,60 USD cikti (hepsi yazan='yerel-GK', 07-15.09 - 19.09'da olculen sisme). Fren (kalip-kosucu PlanHarcama/AyHarcama)
#   zaten TEKIL sayiyor; yanlis alarmi yalniz bu ozet satiri uretiyordu (ham toplam). Ham toplam da basilir, gizlenmez.
#   🚫 GORMEZ: mukerrerleri SILMEZ (ambar satiri kalici silinmez - Cem karari gerekir).
$yTekil=@{}; foreach($x in $yerelAy){ $yTekil[(Anahtar $x.zaman $x.etiket $x.toplamUsd)]=[double]$x.toplamUsd }
$aTekil=@{}; foreach($x in $ambar){ $aTekil[(Anahtar $x.zaman $x.etiket $x.toplam_usd)]=[double]$x.toplam_usd }
$yTT=0.0; foreach($v in $yTekil.Values){ $yTT+=$v }
$aTT=0.0; foreach($v in $aTekil.Values){ $aTT+=$v }
Write-Host ("AY {0}" -f $Ay) -ForegroundColor Cyan
Write-Host ("  YEREL : {0,5} satir · {1,8:N2} USD  (tekil {2} satir · {3:N2} USD)" -f $yerelAy.Count,$yT,$yTekil.Count,$yTT)
Write-Host ("  AMBAR : {0,5} satir · {1,8:N2} USD  (tekil {2} satir · {3:N2} USD)" -f $ambar.Count,$aT,$aTekil.Count,$aTT)
if($ambar.Count -gt $aTekil.Count){ Write-Host ("  MUKERRER (ambar): {0} satir · {1:N2} USD - fren bunlari SAYMAZ" -f ($ambar.Count-$aTekil.Count),($aT-$aTT)) -ForegroundColor DarkYellow }
$fark=[math]::Abs($yTT-$aTT)
if($fark -gt 0.01){ Write-Host ("  ⚠ FARK : {0:N2} USD - iki taraf ayni freni gormuyor" -f $fark) -ForegroundColor Yellow }
else{ Write-Host "  ✓ toplamlar ayni" -ForegroundColor Green }

if($Ozet){ return }
if($YerelIkizTemizle){
  # Ikiz = ayni etiket+tutar, biri digerinden TAM 3 saat SONRA; cikan, INDIRILMIS olan (varsayim=true, satirlar bos -
  # Indir'in yazdigi bicim). Iki taraf da kendi uretimiyse (satirlar dolu) dokunulmaz, sayilir.
  $tumSatir=@(Get-Content $defter -Encoding UTF8)
  $anahtarSatir=@{}; for($i=0;$i -lt $tumSatir.Count;$i++){ $o=$null; try{ $o=$tumSatir[$i]|ConvertFrom-Json }catch{ continue }; if(-not $o){ continue }
    $anahtarSatir[(Anahtar $o.zaman $o.etiket $o.toplamUsd)]=$i }
  $cikacak=@{}; $dokunulmayan=0; $cikanUsd=0.0
  foreach($a in @($anahtarSatir.Keys)){
    $ikiz=AnahtarKaydir $a -3
    if(-not $anahtarSatir.ContainsKey($ikiz)){ continue }
    $o=$tumSatir[$anahtarSatir[$a]]|ConvertFrom-Json
    if([bool]$o.varsayim -and -not @($o.satirlar).Count){ $cikacak[$anahtarSatir[$a]]=$true; $cikanUsd+=[double]$o.toplamUsd } else { $dokunulmayan++ }
  }
  Write-Host ("YEREL IKIZ: {0} satir · {1:N2} USD cikarilacak · kendi uretimi oldugu icin dokunulmayan {2}" -f $cikacak.Count,$cikanUsd,$dokunulmayan) -ForegroundColor Cyan
  if(-not $Yaz){ Write-Host 'KURU KOSU - dosya degismedi. Yazmak icin: -YerelIkizTemizle -Yaz' -ForegroundColor Yellow; return }
  $yedekDizin='C:\TETIKTE-YEDEK\bedel-defter'; New-Item -ItemType Directory -Force $yedekDizin | Out-Null
  Copy-Item $defter (Join-Path $yedekDizin ("bedel-kayit-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.jsonl')) -Force
  $kalan=New-Object System.Collections.Generic.List[string]; for($i=0;$i -lt $tumSatir.Count;$i++){ if(-not $cikacak.ContainsKey($i)){ $kalan.Add($tumSatir[$i]) } }
  $mx=New-Object System.Threading.Mutex($false,'Global\tetikte-bedel-kayit'); $al=$false
  try{ $al=$mx.WaitOne(20000) }catch{ $al=$true }
  try{ [IO.File]::WriteAllLines($defter,$kalan,[Text.UTF8Encoding]::new($false)) } finally{ if($al){ try{ $mx.ReleaseMutex() }catch{} }; $mx.Dispose() }
  Write-Host ("YAZILDI: {0} -> {1} satir (yedek {2})" -f $tumSatir.Count,$kalan.Count,$yedekDizin) -ForegroundColor Green
  return
}
if(-not ($Yukle -or $Indir)){ throw 'Yon belirt: -Yukle · -Indir · -Ozet · -YerelIkizTemizle' }

$ambarAnahtar=@{}; foreach($x in $ambar){ $ambarAnahtar[(Anahtar $x.zaman $x.etiket $x.toplam_usd)]=$true }

if($Yukle){
  $gonderHam=@($yerelAy|Where-Object{ -not (TabloVar $ambarAnahtar (Anahtar $_.zaman $_.etiket $_.toplamUsd)) })   # 25.09: ±3 saat ikiz de "var" sayilir
  # 19.09: IC TEKILLESTIRME satir ici yapilir. ⛔ Once bunu bir FONKSIYON yapmistim; PS 5.1'de dizi donusu
  #   cagirana TEK NESNE olarak gecti, @() onu 1 ogeye sardi ve bulut "Durumu ambardan indir" adimi
  #   ConvertToFinalInvalidCastException ile dustu (run 35423527375). Yerel KURU kosuda "1 satir" yaziyordu
  #   ve bunu dogru sanmistim - kuru kosu yazma yoluna hic girmedigi icin hatayi gostermedi.
  $gorGon=@{}
  $gonder=@($gonderHam | Where-Object { $a=Anahtar $_.zaman $_.etiket $_.toplamUsd; if($gorGon.ContainsKey($a)){ $false } else { $gorGon[$a]=1; $true } })
  if($gonderHam.Count -ne $gonder.Count){ Write-Host ("  mukerrer yerel satir atlandi: {0:N0}" -f ($gonderHam.Count-$gonder.Count)) -ForegroundColor DarkYellow }
  Write-Host ("`nGONDERILECEK: {0:N0} satir" -f $gonder.Count) -ForegroundColor Green
  if(-not $Yaz){ Write-Host "KURU KOSU - ambara yazilmadi. Yazmak icin: -Yaz" -ForegroundColor Yellow; return }
  $n=0; $hata=0; $paket=New-Object System.Collections.Generic.List[object]
  foreach($x in $gonder){
    $paket.Add([ordered]@{
      zaman=(ZamanOfsetli $x.zaman); etiket="$($x.etiket)"; ders="$($x.ders)"   # 25.09: ofsetsiz 'o' TR saatini UTC diye yaziyordu
      toplam_usd=[double]$x.toplamUsd; varsayim=[bool]$x.varsayim
      satirlar=$x.satirlar; yazan=$yazan })
    if($paket.Count -ge 200){
      try{ [void](Invoke-RestMethod -Method Post -Uri ($TABAN+'/bedel_kaydi') -Headers ($SB+@{Prefer='return=minimal'}) -Body ([Text.Encoding]::UTF8.GetBytes(((Dizi $paket)|ConvertTo-Json -Depth 8))) -TimeoutSec 180); $n+=$paket.Count }
      catch{ Write-Host ("  ! paket yazilamadi: " + $_.Exception.Message) -ForegroundColor Red; $hata+=$paket.Count }
      $paket=New-Object System.Collections.Generic.List[object]
    }
  }
  if($paket.Count){
    try{ [void](Invoke-RestMethod -Method Post -Uri ($TABAN+'/bedel_kaydi') -Headers ($SB+@{Prefer='return=minimal'}) -Body ([Text.Encoding]::UTF8.GetBytes(((Dizi $paket)|ConvertTo-Json -Depth 8))) -TimeoutSec 180); $n+=$paket.Count }
    catch{ Write-Host ("  ! son paket yazilamadi: " + $_.Exception.Message) -ForegroundColor Red; $hata+=$paket.Count }
  }
  Write-Host ("YUKLENDI: {0:N0} satir · hata {1}" -f $n,$hata) -ForegroundColor Green
  return
}

# INDIR: ambar -> yerel (yalniz yerelde OLMAYAN)
$yerelAnahtar=@{}; foreach($x in $yerelAy){ $yerelAnahtar[(Anahtar $x.zaman $x.etiket $x.toplamUsd)]=$true }
$ekHam=@($ambar|Where-Object{ -not (TabloVar $yerelAnahtar (Anahtar $_.zaman $_.etiket $_.toplam_usd)) })   # 25.09: ±3 saat ikiz yerelde varsa EKLENMEZ
# 19.09: ambarda ayni satirin kopyalari var (olculdu: 31 kopyaya kadar) - yerele BIR kez yazilir.
$gorEk=@{}
$ek=@($ekHam | Where-Object { $a=Anahtar $_.zaman $_.etiket $_.toplam_usd; if($gorEk.ContainsKey($a)){ $false } else { $gorEk[$a]=1; $true } })
if($ekHam.Count -ne $ek.Count){ Write-Host ("  ambardaki mukerrer kopya atlandi: {0:N0}" -f ($ekHam.Count-$ek.Count)) -ForegroundColor DarkYellow }
Write-Host ("`nYEREL DEFTERE EKLENECEK: {0:N0} satir" -f $ek.Count) -ForegroundColor Green
if(-not $Yaz){ Write-Host "KURU KOSU - dosya yazilmadi. Yazmak icin: -Yaz" -ForegroundColor Yellow; return }
$sb=New-Object System.Text.StringBuilder
foreach($x in $ek){
  $o=[ordered]@{ zaman=([datetime]$x.zaman).ToString('yyyy-MM-dd HH:mm'); etiket="$($x.etiket)"
                 ders="$($x.ders)"; toplamUsd=[double]$x.toplam_usd; varsayim=$true; satirlar=@() }
  [void]$sb.AppendLine((ConvertTo-Json -InputObject $o -Compress -Depth 4))
}
# ⚠ Mutex: kosan tur ayni deftere ekliyor olabilir
$mx=New-Object System.Threading.Mutex($false,'Global\tetikte-bedel-kayit'); $al=$false
try{ $al=$mx.WaitOne(20000) }catch{ $al=$true }
try{ [IO.File]::AppendAllText($defter,$sb.ToString(),[Text.UTF8Encoding]::new($false)) }
finally{ if($al){ try{ $mx.ReleaseMutex() }catch{} }; $mx.Dispose() }
Write-Host ("EKLENDI: {0:N0} satir" -f $ek.Count) -ForegroundColor Green
