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
  [switch]$Yaz
)
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
Write-Host ("AY {0}" -f $Ay) -ForegroundColor Cyan
Write-Host ("  YEREL : {0,5} satir · {1,8:N2} USD" -f $yerelAy.Count,$yT)
Write-Host ("  AMBAR : {0,5} satir · {1,8:N2} USD" -f $ambar.Count,$aT)
$fark=[math]::Abs($yT-$aT)
if($fark -gt 0.01){ Write-Host ("  ⚠ FARK : {0:N2} USD - iki taraf ayni freni gormuyor" -f $fark) -ForegroundColor Yellow }
else{ Write-Host "  ✓ toplamlar ayni" -ForegroundColor Green }

if($Ozet){ return }
if(-not ($Yukle -or $Indir)){ throw 'Yon belirt: -Yukle · -Indir · -Ozet' }

$ambarAnahtar=@{}; foreach($x in $ambar){ $ambarAnahtar[(Anahtar $x.zaman $x.etiket $x.toplam_usd)]=$true }

if($Yukle){
  $gonderHam=@($yerelAy|Where-Object{ -not $ambarAnahtar.ContainsKey((Anahtar $_.zaman $_.etiket $_.toplamUsd)) })
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
      zaman=([datetime]$x.zaman).ToString('o'); etiket="$($x.etiket)"; ders="$($x.ders)"
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
$ekHam=@($ambar|Where-Object{ -not $yerelAnahtar.ContainsKey((Anahtar $_.zaman $_.etiket $_.toplam_usd)) })
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
