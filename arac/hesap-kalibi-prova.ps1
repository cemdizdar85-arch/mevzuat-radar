#requires -Version 5.1
<#
================================================================================
  HESAP KALIBI DOLDURMA PROVASI  (11.09.2026, Cem "bunu yap")

  AMAC: rag.konu_hesap_kalibi tablosunu (010_hesap_kalibi.sql) doldurmanin
  GERCEK bedelini olcmek. 5 konuda kosar, jeton sayar, 433 konunun maliyetini
  olculen orandan cikarir. TAHMIN VERMEZ - olcer.

  NEDEN PROVA: 11.09'da iki kez tahminim sasti (konu turu 0,001 dedim 0,0014
  cikti; KAPI-HG turunu 10 TL dedim 39 TL cikti). Cem'in kurali: "her seyde
  bedeli sor" - bedel ancak olculerek soylenir.

  HALUSINASYON KAPISI - bu provanin ASIL fikri:
  Modele hesap kodu UYDURTMUYORUZ. Ambardaki 269 THP hesabinin tam listesi
  (kod + resmi ad, ~10.400 karakter) istemin icine MENU olarak konur ve
  "yalniz bu listeden sec" denir. Listede olmayan kod donerse kod kapisi
  reddeder. Boylece "521 diye bir hesap var mi" sorusu modele hic sorulmaz.

  CIKTI: veri/_hesap-kalibi-prova.json + ekrana ozet. TABLOYA YAZMAZ
  (010 henuz basilmadi; once Cem okuyacak).

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/hesap-kalibi-prova.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/hesap-kalibi-prova.ps1 -Yaz
================================================================================
#>
param(
  [switch]$Yaz,                 # olmadan: kuru kosu, bedel 0
  [int]$Adet = 5,
  [string]$Konu = '',           # tek konuyu adiyla kos (sinama icin)
  [double]$TavanTL = 5          # prova tavani; asilirsa DURUR
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $depoKok 'motor\api-hedef.ps1')

$KEY = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim()
if(-not $KEY){ $KEY = "$($env:SUPABASE_SERVICE_KEY)".Trim() }
if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok.' }
# ⚠ Supabase gizli anahtar TARAYICI User-Agent'ini reddeder ("Forbidden use of
#   secret API key in browser"). Robot UA sart - 08.09'da bir oturum bunu bulmak
#   icin tur harcadi.
$SBH=@{ apikey=$KEY; Authorization="Bearer $KEY"; Accept='application/json'; 'User-Agent'='mevzuat-radar-robot/1.0' }
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$TABAN='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

function AmbarAl([string]$desen,[int]$limit=1){
  $u = $TABAN + '?select=kaynak_ad,metin&kaynak_ad=ilike.' + [uri]::EscapeDataString($desen) + "&limit=$limit"
  # ⚠ PS 5.1: `@(Invoke-RestMethod ...)` diziyi TEK ELEMANA sarar - cagrinin
  #   ciktisi zaten Object[] oldugu icin @() onu bir kutuya koyar ve Count 1 olur.
  #   Once degiskene alinir, sonra @() ile acilir. (11.09'da bu tuzaga 3. kez
  #   dusuldu: ConvertFrom-Json borusunda, secim dosyasi birlestirmede, burada.)
  $r = $null
  try{ $r = Invoke-RestMethod -Uri $u -Headers $SBH -TimeoutSec 90 }catch{ return @() }
  if($null -eq $r){ return @() }
  return @($r)
}

# --- THP MENUSU: modelin secebilecegi TEK liste ------------------------------
$thp = AmbarAl 'THP %' 400
if(-not $thp.Count){ throw 'THP listesi ambardan alinamadi.' }
# Her satirin kaynak_ad'i zaten "THP 271 - ARAMA GİDERLERİ" bicimindedir;
# ayristirmaya gerek yok, on ek atilir. (Ilk denemede metinle birlestirip regex
# yazmistim: ad bittigi yerde hesap TANIMI basladigi icin ileri-bakis hic
# tutmadi ve menu 0 hesap cikti. Basit olan dogruydu.)
$ciftler = @($thp | ForEach-Object { ("$($_.kaynak_ad)" -replace '^\s*THP\s+','').Trim() } |
             Where-Object { $_ -match '^[1-7]\d{2}\s*-\s*\S' } | Sort-Object -Unique)
if($ciftler.Count -lt 150){ throw "THP menusu eksik ayristirildi: $($ciftler.Count) hesap (>=150 beklenir)" }
$MENU = $ciftler -join "`n"
Write-Host ("THP MENUSU: {0} hesap · {1:N0} karakter" -f $ciftler.Count,$MENU.Length) -ForegroundColor Cyan

# --- KONU SECIMI -------------------------------------------------------------
$oneriler = @((Get-Content (Join-Path $depoKok 'veri\kart-onerileri.json') -Raw -Encoding UTF8 | ConvertFrom-Json).oneriler)
$muh = @('Finansal Muhasebe','Maliyet Muhasebesi','Mali Tablolar Analizi','Turkiye Muhasebe Standartlari')
$havuz = @($oneriler | Where-Object { $muh -contains "$($_.ders)" -and "$($_.guc)" -eq 'GUCLU' })
Write-Host ("HAVUZ: {0} GUCLU muhasebe konusu (toplam hesap tasiyabilen 433)" -f $havuz.Count)

$sec = New-Object System.Collections.Generic.List[object]
if($Konu){
  # ⚠ Ilk surumde "hisse" gecen ILK konuyu sabit alip "Cem'in vakasi provaya
  #   girdi" saymistim; oysa eslesen konu 'hisse senedi deger dusuklugu' oldu,
  #   aranan 'sermaye taahhudu-hisse iptali' DEGIL. Yani sinama tasi hic
  #   konmamisti. Artik konu ADIYLA verilir, tahminle secilmez.
  $b = @($oneriler | Where-Object { "$($_.konu)" -eq $Konu })
  if(-not $b.Count){ $b = @($oneriler | Where-Object { "$($_.konu)" -like "*$Konu*" }) }
  if(-not $b.Count){ throw "Konu bulunamadi: '$Konu'" }
  foreach($s in ($b | Select-Object -First 1)){ $sec.Add($s) }
} else {
  foreach($s in @($havuz | Get-Random -Count $Adet -SetSeed 11092603)){ $sec.Add($s) }
}

$tahminUSD = $sec.Count * 0.008   # ilk tahmin; gercek olculecek
Write-Host ("PLAN: {0} konu · ilk tahmin {1:N3} USD (~{2:N1} TL)" -f $sec.Count,$tahminUSD,($tahminUSD*42)) -ForegroundColor Cyan
$sec | ForEach-Object { Write-Host ("  {0,-24} {1}" -f $_.ders,$_.konu) }
if(($tahminUSD*42) -gt $TavanTL){ throw "TAVAN ASILDI." }
if(-not $Yaz){ Write-Host "`nKURU KOSU - hicbir API cagrisi yapilmadi. Kosmak icin: -Yaz" -ForegroundColor Yellow; return }

$ISTEM = @'
Sen bir Tekduzen Hesap Plani uzmanisin. Sana bir MUHASEBE KONUSU ve o konunun
mevzuat dayanagi veriliyor. Gorevin, bu konuda soru yazacak birine HESAP KALIBI
cikarmak.

⛔ HESAP KODU UYDURMA. Yalnizca asagidaki THP LISTESINDEN sec. Listede olmayan
   kod yazarsan cevabin tumuyle reddedilir.
⛔ KURAL METNINI UYDURMA. `kural_metni` alanina, sana verilen KAYNAK METINLERINDEN
   BIREBIR ALINTI yaz ve `kural_kaynak_ad` alanina o metnin basligini yaz.
   Alinti yapacak uygun metin yoksa ikisini de bos birak.

Uc sey istiyorum:
1) dogru_hesaplar: bu konudaki tipik islemin DOGRU kaydinda gecen hesap kodlari.
2) tuzaklar: ogrencinin YANLISLIKLA kullanabilecegi, birbirine karistirilan
   hesaplar. Her tuzak icin NEDEN yanlis oldugunu TEK CUMLE yaz. "Yasak" demek
   yetmez - ayirt edici olcutu soyle. Ornek bicim:
   {"kod":"520","ad":"Hisse Senedi İhraç Primleri",
    "neden":"520 YENI cikarilan senedin primli satisi icindir; burada senet yeni
             cikarilmiyor, iptal edilenin yerine satiliyor."}
   En az 2, en fazla 4 tuzak. Tuzak, dogru_hesaplar ile AYNI kod olamaz.
3) zorluk: yalniz "kolay", "zor" ya da "cokzor". Baska kelime yazma.

Cevap YALNIZ JSON, oncesinde/sonrasinda hicbir metin yok:
{"dogru_hesaplar":["..."],"tuzaklar":[{"kod":"","ad":"","neden":""}],
 "kural_metni":"","kural_kaynak_ad":"","zorluk":""}
'@

function Coz2($metin){
  $t="$metin"; $i=$t.IndexOf('{'); $j=$t.LastIndexOf('}')
  if($i -lt 0 -or $j -le $i){ return $null }
  try{ return ($t.Substring($i,$j-$i+1) | ConvertFrom-Json) }catch{ return $null }
}
$GECERLI = @{}
foreach($c in $ciftler){ $GECERLI[($c -split ' - ')[0]] = ($c -split ' - ',2)[1] }

$sonuc=New-Object System.Collections.Generic.List[object]
$tokG=0;$tokC=0;$n=0
foreach($kn in $sec){
  $n++
  # Konunun dayanagi + ilgili kaynak metinleri
  $aday = @($kn.adaylar) | Select-Object -First 2
  $parca=New-Object System.Collections.Generic.List[string]
  foreach($a in $aday){
    $ad = if($a -is [string]){ $a } elseif($a.PSObject.Properties['kaynak_ad']){ "$($a.kaynak_ad)" } elseif($a.PSObject.Properties['ad']){ "$($a.ad)" } else { '' }   # 11.09: alan adi kaynak_ad
    if(-not $ad){ continue }
    foreach($x in (AmbarAl $ad 1)){ $parca.Add("[$($x.kaynak_ad)] " + "$($x.metin)".Substring(0,[Math]::Min(2200,"$($x.metin)".Length))) }
  }
  $kaynak = ($parca -join "`n---`n")
  $istek = $ISTEM + "`n`n=== THP LISTESI (yalniz buradan sec) ===`n$MENU" +
           "`n`n=== DERS ===`n$($kn.ders)`n=== KONU ===`n$($kn.konu)" +
           "`n=== KAYNAK METINLERI ===`n" + $(if($kaynak){$kaynak}else{'(kaynak cekilemedi)'})

  $y=$null
  foreach($d in 1..3){ try{ $y=Invoke-ClaudeMesaj -Model 'claude-haiku-4-5-20251001' -Icerik $istek -MaxTok 900; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } }
  $tokG+=[int]$y.girdi; $tokC+=[int]$y.cikti
  $k=Coz2 $y.metin

  # --- KOD KAPISI: model listede olmayan kod dondurduyse yakala -------------
  $uydurma=@()
  if($k){
    foreach($kod in @($k.dogru_hesaplar)){ if(-not $GECERLI.ContainsKey("$kod")){ $uydurma+="dogru:$kod" } }
    foreach($t in @($k.tuzaklar)){ if($t -and -not $GECERLI.ContainsKey("$($t.kod)")){ $uydurma+="tuzak:$($t.kod)" } }
  }
  # --- ALINTI KAPISI: kural_metni gercekten kaynakta geciyor mu -------------
  $alintiOk = $true; $alintiNot=''
  if($k -and "$($k.kural_metni)".Trim()){
    $km = ("$($k.kural_metni)" -replace '\s+',' ').Trim()
    $kk = ($kaynak -replace '\s+',' ')
    $bas = $km.Substring(0,[Math]::Min(45,$km.Length))
    if(-not $kk.Contains($bas)){ $alintiOk=$false; $alintiNot='kural_metni kaynakta BULUNAMADI (uydurma olabilir)' }
  }

  $satir=[pscustomobject]@{
    ders=$kn.ders; konu=$kn.konu
    dogru=(@($k.dogru_hesaplar) -join ',')
    tuzak_adet=@($k.tuzaklar).Count
    tuzaklar=@($k.tuzaklar | ForEach-Object { "$($_.kod)" })
    zorluk="$($k.zorluk)"
    kural_kaynak="$($k.kural_kaynak_ad)"
    uydurma_kod=($uydurma -join ',')
    alinti_ok=$alintiOk; alinti_not=$alintiNot
    jeton="$($y.girdi)/$($y.cikti)"
  }
  $sonuc.Add($satir)
  $renk = if($uydurma.Count -or -not $alintiOk){'Yellow'}else{'Green'}
  Write-Host ("[{0}/{1}] {2}" -f $n,$sec.Count,$kn.konu) -ForegroundColor $renk
  Write-Host ("     dogru: {0}  tuzak: {1}  zorluk: {2}" -f $satir.dogru,($satir.tuzaklar -join ','),$satir.zorluk)
  foreach($t in @($k.tuzaklar)){ Write-Host ("     ! {0} {1} - {2}" -f $t.kod,$t.ad,$t.neden) -ForegroundColor DarkGray }
  if($uydurma.Count){ Write-Host ("     ⛔ UYDURMA KOD: {0}" -f ($uydurma -join ',')) -ForegroundColor Red }
  if(-not $alintiOk){ Write-Host ("     ⚠ {0}" -f $alintiNot) -ForegroundColor Yellow }
}

$bedel = ($tokG*1.0/1e6) + ($tokC*5.0/1e6)
$birim = $bedel/[Math]::Max(1,$sonuc.Count)
Write-Host ""
Write-Host ("OLCULEN BEDEL: girdi {0} · cikti {1} jeton · {2:N4} USD" -f $tokG,$tokC,$bedel) -ForegroundColor Green
Write-Host ("  soru basina : {0:N4} USD  (~{1:N2} TL)" -f $birim,($birim*42)) -ForegroundColor Green
Write-Host ("  433 KONU    : {0:N2} USD  (~{1:N0} TL)  <- Cem'in karar verecegi rakam" -f ($birim*433),($birim*433*42)) -ForegroundColor Cyan
Write-Host ("  uydurma kod ureten konu: {0}/{1}" -f @($sonuc|Where-Object{$_.uydurma_kod}).Count,$sonuc.Count)
Write-Host ("  alintisi dogrulanmayan : {0}/{1}" -f @($sonuc|Where-Object{-not $_.alinti_ok}).Count,$sonuc.Count)

. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\_hesap-kalibi-prova.json') -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); model='claude-haiku-4-5'
  menu_hesap=$ciftler.Count
  konu=$sonuc.Count; jeton=@{girdi=$tokG;cikti=$tokC}
  bedel_usd=[math]::Round($bedel,4); birim_usd=[math]::Round($birim,4)
  tahmin_433_usd=[math]::Round($birim*433,2); tahmin_433_tl=[math]::Round($birim*433*42,0)
  satirlar=$sonuc
})
Write-Host "`n-> veri/_hesap-kalibi-prova.json"
