#requires -Version 5.1
<#
================================================================================
  HESAP KALIBI DOLDURMA  (11.09.2026, Cem "1.2.3 ucunude yap" - 1. is)

  Prova (arac/hesap-kalibi-prova.ps1) gecti: 6 konuda 0 uydurma kod, 521 testi
  gecti, olculen bedel 0,0085 USD/konu. Bu betik ayni mekanigi TUM havuzda kosar.

  ⛔ ODENEN IS KAYBOLMAZ - iki katman:
    1) ARTIMLI YAZIM: her konudan sonra veri/hesap-kalibi.json yeniden yazilir.
       Cokme/kesinti olursa o ana kadar odenen is diskte durur.
    2) DEVAM ETME: dosyada zaten kayit olan konu ATLANIR (API cagrilmaz).
       Yeniden baslatmak ikinci kez para yakmaz.
  09.09 dersi: 5,75 USD, 08.09 dersi: 18+39 USD kayip - ikisi de "kosu yarida
  oldu, urun nerede" diye baslamisti.

  HALUSINASYON KAPILARI (provada olculdu, 0 uydurma):
    MENU  : 269 THP hesabinin tam listesi isteme konur, "yalniz buradan sec"
    KOD   : donen her kod menuye karsi denetlenir; uyduran kayit REDDEDILIR
    ALINTI: kural_metni'nin ilk 45 karakteri kaynak paketinde aranir

  ⛔ TABLOYA YAZMAZ. rag-motor/sql/010_hesap_kalibi.sql HENUZ BASILMADI.
  Cikti JSON'dur; SQL basildiginda bu dosyadan yuklenecek.

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/hesap-kalibi-doldur.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/hesap-kalibi-doldur.ps1 -Yaz
================================================================================
#>
param(
  [switch]$Yaz,
  [double]$TavanTL = 200,
  [int]$Adet = 0,           # >0 ise yalniz ilk N konu
  [string]$Konu = ''         # tek konuyu adiyla kos (sinama icin)
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $depoKok 'motor\api-hedef.ps1')
$HEDEF=Join-Path $depoKok 'veri\hesap-kalibi.json'

$KEY = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim()
if(-not $KEY){ $KEY = "$($env:SUPABASE_SERVICE_KEY)".Trim() }
if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok.' }
$SBH=@{ apikey=$KEY; Authorization="Bearer $KEY"; Accept='application/json'; 'User-Agent'='mevzuat-radar-robot/1.0' }
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$TABAN='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
function AmbarAl([string]$desen,[int]$limit=1){
  # ⚠ PS 5.1: @(Invoke-RestMethod ...) diziyi TEK ELEMANA sarar. Once degiskene.
  $u=$TABAN+'?select=kaynak_ad,metin&kaynak_ad=ilike.'+[uri]::EscapeDataString($desen)+"&limit=$limit"
  # 11.09: burasi SESSIZ dusuyordu - catch hatayi yutup bos dizi donduruyordu ve
  # "THP menusu eksik: 0" diye ANLAMSIZ bir hata veriyordu. Bugunku sessiz kapi
  # dersi burada da gecerli: kapi neden dustugunu SOYLER.
  $r=$null
  try{ $r=Invoke-RestMethod -Uri $u -Headers $SBH -TimeoutSec 90 }
  catch{ Write-Host ("  AMBAR HATASI ({0}): {1}" -f $desen,$_.Exception.Message) -ForegroundColor Red; return @() }
  if($null -eq $r){ return @() }; return @($r)
}

# --- MENU --------------------------------------------------------------------
$thp = AmbarAl 'THP %' 400
$ciftler = @($thp | ForEach-Object { ("$($_.kaynak_ad)" -replace '^\s*THP\s+','').Trim() } |
             Where-Object { $_ -match '^[1-7]\d{2}\s*-\s*\S' } | Sort-Object -Unique)
if($ciftler.Count -lt 150){ throw "THP menusu eksik: $($ciftler.Count)" }
$MENU=($ciftler -join "`n")
# THP kayitlari METINLERIYLE saklanir - konu eslesmesinde kaynak olarak kullanilir
function Katla2Y([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
       -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
       -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}
$KONU_DOLGU=@('ile','icin','veya','bir','olan','gibi','hesap','kaydi','islem','yonte','tutar','genel','ozel','kavra','tanim','hesabi','analizi')
$THP_KAYIT=@($thp | ForEach-Object { [pscustomobject]@{ ad="$($_.kaynak_ad)"; k=(Katla2Y "$($_.kaynak_ad)"); metin="$($_.metin)" } })
$GECERLI=@{}; foreach($c in $ciftler){ $GECERLI[($c -split ' - ')[0]]=($c -split ' - ',2)[1] }
Write-Host ("THP MENUSU: {0} hesap" -f $ciftler.Count) -ForegroundColor Cyan

# --- HAVUZ -------------------------------------------------------------------
$oneriler=@((Get-Content (Join-Path $depoKok 'veri\kart-onerileri.json') -Raw -Encoding UTF8 | ConvertFrom-Json).oneriler)
$muh=@('Finansal Muhasebe','Maliyet Muhasebesi','Mali Tablolar Analizi','Turkiye Muhasebe Standartlari')
$havuz=@($oneriler | Where-Object { $muh -contains "$($_.ders)" })

# --- DEVAM ETME: elde ne var --------------------------------------------------
$eski=@{}
if(Test-Path $HEDEF){
  $e=Get-Content $HEDEF -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($x in @($e.satirlar)){ $eski["$($x.ders)|$($x.konu)"]=$x }
  Write-Host ("ELDE VAR: {0} konu (atlanacak, yeniden para yakilmaz)" -f $eski.Count) -ForegroundColor Green
}
$kalan=@($havuz | Where-Object { -not $eski.ContainsKey("$($_.ders)|$($_.konu)") })
if($Konu){ $kalan=@($havuz | Where-Object { "$($_.konu)" -like "*$Konu*" } | Select-Object -First 1) }
elseif($Adet -gt 0){ $kalan=@($kalan | Select-Object -First $Adet) }

$tahminUSD=$kalan.Count*0.0085
Write-Host ("HAVUZ {0} · KALAN {1} · tahmini {2:N2} USD (~{3:N0} TL)" -f $havuz.Count,$kalan.Count,$tahminUSD,($tahminUSD*42)) -ForegroundColor Cyan
if(($tahminUSD*42) -gt $TavanTL){ throw ("TAVAN ASILDI: {0:N0} TL > {1:N0} TL" -f ($tahminUSD*42),$TavanTL) }
if(-not $Yaz){ Write-Host "`nKURU KOSU - API cagrisi yok. Kosmak icin: -Yaz" -ForegroundColor Yellow; return }
if(-not $kalan.Count){ Write-Host 'Kalan konu yok.' -ForegroundColor Green; return }

$ISTEM = @'
Sen bir Tekduzen Hesap Plani uzmanisin. Sana bir MUHASEBE KONUSU ve o konunun
mevzuat dayanagi veriliyor. Gorevin, bu konuda soru yazacak birine HESAP KALIBI
cikarmak.

⛔ HESAP KODU UYDURMA. Yalnizca THP LISTESINDEN sec. Listede olmayan kod yazarsan
   cevabin tumuyle reddedilir.
⛔ KURAL METNINI UYDURMA. `kural_metni` alanina KAYNAK METINLERINDEN BIREBIR
   ALINTI yaz, `kural_kaynak_ad` alanina o metnin basligini yaz. Uygun metin
   yoksa ikisini de bos birak.
⛔ KONU HESAP ICERMIYORSA (ornegin bir denetim/teori konusuysa) bos don:
   dogru_hesaplar [] ve tuzaklar []. Zorlama.

1) dogru_hesaplar: bu konudaki tipik islemin DOGRU kaydinda gecen kodlar.
2) tuzaklar: ogrencinin karistirabilecegi hesaplar. Her biri icin NEDEN yanlis
   oldugunu TEK CUMLE yaz - "yasak" demek yetmez, AYIRT EDICI OLCUTU soyle.
   En az 2, en fazla 4. Tuzak, dogru_hesaplar ile ayni kod olamaz.
3) zorluk: yalniz "kolay", "zor" ya da "cokzor".

Cevap YALNIZ JSON:
{"dogru_hesaplar":["..."],"tuzaklar":[{"kod":"","ad":"","neden":""}],
 "kural_metni":"","kural_kaynak_ad":"","zorluk":""}
'@
function Coz2($m){ $t="$m"; $i=$t.IndexOf('{'); $j=$t.LastIndexOf('}'); if($i -lt 0 -or $j -le $i){ return $null }; try{ return ($t.Substring($i,$j-$i+1)|ConvertFrom-Json) }catch{ return $null } }
function Slug([string]$d,[string]$k){
  $t=("$d-$k" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToUpperInvariant()
  return (($t -replace '[^A-Z0-9]+','-').Trim('-'))
}

$sonuc=New-Object System.Collections.Generic.List[object]
foreach($k in $eski.Keys){ $sonuc.Add($eski[$k]) }
$tokG=0;$tokC=0;$n=0;$uydurmaKayit=0;$bosKayit=0;$script:kaynaksiz=0
foreach($kn in $kalan){
  $n++
  # --- KAYNAK 1: KONUYLA ESLESEN THP HESAP TANIMLARI (11.09) ----------------
  # OLCULDU: 433 muhasebe konusunun 306'si (%71) adinda bir THP hesabiyla
  # dogrudan eslesiyor ve eslesmeler isabetli ("amortisman ayirma" -> 268
  # Birikmis Amortismanlar / 796 Amortismanlar / 257).
  # RAG adaylari ayni konulara "SPK Altyapi GYO Tebligi", "KUMI FRS" gibi
  # alakasiz belgeler getiriyordu - bu is icin ASIL kaynak hesap tanimlarinin
  # kendisidir. Adaylar ikincil kaynak olarak KALIR ama ONCE bu gelir.
  $parca=New-Object System.Collections.Generic.List[string]
  $knKel=@([regex]::Matches((Katla2Y "$($kn.konu)"),'[a-z0-9]{4,}') | ForEach-Object { $_.Value } |
           Where-Object { $KONU_DOLGU -notcontains $_ } | Select-Object -Unique)
  if($knKel.Count){
    # ⚠ "ILK 6" DEGIL "EN COK ESLESEN 6" - ayni dersi bugun iki kez ogrendim.
    #   Ilk surumde siralamadan ilk 6 alinmisti: "sermaye taahhudu-hisse iptali"
    #   konusunda "sermaye" 8 hesapla eslesti, 521 HISSE SENEDI IPTAL KARLARI
    #   listeden KESILDI ve model yine 529 dedi. (Ayni kusur KAPI-KS'de kaynak
    #   paketi icin duzeltilmisti; burada tekrar uretmisim.)
    # ⚠ KOK ESLESMESI: Turkce sondan eklemeli, "iptali" ile "iptal" ayni koktur.
    #   Tam eslesme arayinca 521 ikinci kelimeden de puan alamiyordu.
    $esler=@($THP_KAYIT | ForEach-Object {
        $a=$_.k
        $p2=@($knKel | Where-Object { $kk=$(if($_.Length -gt 5){ $_.Substring(0,5) } else { $_ }); $a -match [regex]::Escape($kk) }).Count
        [pscustomobject]@{ ad=$_.ad; metin=$_.metin; p=$p2 }
      } | Where-Object { $_.p -ge 1 } | Sort-Object p -Descending | Select-Object -First 6)
    foreach($e in $esler){ $parca.Add("[$($e.ad)] $($e.metin)") }
    if($esler.Count){ Write-Host ("      THP tanimi: {0}" -f (@($esler | ForEach-Object { ($_.ad -replace '^THP\s+','') -replace ' -.*','' }) -join ',')) -ForegroundColor DarkCyan }
  }
  # ⚠ 11.09 KENDI HATAM, 142 TL'YE MAL OLDU: aday kaydinda alan adi `kaynak_ad`,
  #   ben `.ad` okumustum. Bos donunce hicbir kaynak cekilmedi ve 433 konunun
  #   TAMAMI kaynaksiz kosuldu; 358'i (dogru olarak) bos dondu, "dolan" 75'i ise
  #   EZBERDEN doldu - tam da onlemeye calistigimiz sey. Alan adi dogrulanmadan
  #   toplu kosu baslatilmaz.
  foreach($a in (@($kn.adaylar) | Select-Object -First 2)){
    $ad = if($a -is [string]){ $a }
          elseif($a.PSObject.Properties['kaynak_ad']){ "$($a.kaynak_ad)" }
          elseif($a.PSObject.Properties['ad']){ "$($a.ad)" }
          else { '' }
    if(-not $ad){ continue }
    foreach($x in (AmbarAl $ad 1)){ $parca.Add("[$($x.kaynak_ad)] " + "$($x.metin)".Substring(0,[Math]::Min(2200,"$($x.metin)".Length))) }
  }
  $kaynak=($parca -join "`n---`n")
  $istek=$ISTEM+"`n`n=== THP LISTESI (yalniz buradan sec) ===`n$MENU"+
         "`n`n=== DERS ===`n$($kn.ders)`n=== KONU ===`n$($kn.konu)"+
         "`n=== KAYNAK METINLERI ===`n"+$(if($kaynak){$kaynak}else{'(kaynak cekilemedi)'})
  # --- KAYNAKSIZ KOSU KAPISI (11.09) --------------------------------------
  # Bu betik bir kez 142 TL'yi kaynaksiz yakti (alan adi hatasi, yukarida).
  # Artik ilk 10 konuda HIC kaynak cekilemezse kosu DURUR - sessizce devam edip
  # ezberden doldurmaz.
  if(-not $kaynak.Trim()){ $script:kaynaksiz++ }
  if($n -ge 10 -and $script:kaynaksiz -ge $n){
    throw ("KAYNAKSIZ KOSU: ilk {0} konunun hicbirinde ambardan kaynak cekilemedi. " +
           "Aday alan adi ya da ambar sorgusu bozuk olabilir. Kosu DURDURULDU - " +
           "kaynaksiz doldurma ezberden doldurmaktir." -f $n)
  }
  $y=$null
  foreach($d in 1..3){ try{ $y=Invoke-ClaudeMesaj -Model 'claude-haiku-4-5-20251001' -Icerik $istek -MaxTok 900; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } }
  $tokG+=[int]$y.girdi; $tokC+=[int]$y.cikti
  $r=Coz2 $y.metin

  $uyd=@(); $tuz=@()
  if($r){
    foreach($kod in @($r.dogru_hesaplar)){ if(-not $GECERLI.ContainsKey("$kod")){ $uyd+="$kod" } }
    foreach($t in @($r.tuzaklar)){
      if(-not $t -or -not "$($t.kod)".Trim()){ continue }
      if(-not $GECERLI.ContainsKey("$($t.kod)")){ $uyd+="$($t.kod)"; continue }
      if("$($t.neden)".Trim()){ $tuz+=[pscustomobject]@{ kod="$($t.kod)"; ad=$GECERLI["$($t.kod)"]; neden="$($t.neden)" } }
    }
  }
  $alintiOk=$true
  if($r -and "$($r.kural_metni)".Trim()){
    $km=("$($r.kural_metni)" -replace '\s+',' ').Trim()
    $bas=$km.Substring(0,[Math]::Min(45,$km.Length))
    if(-not ($kaynak -replace '\s+',' ').Contains($bas)){ $alintiOk=$false }
  }
  $dogru=@(@($r.dogru_hesaplar) | Where-Object { $GECERLI.ContainsKey("$_") })
  $zor="$($r.zorluk)"; if($zor -notin @('kolay','zor','cokzor')){ $zor=$null }

  if($uyd.Count){ $uydurmaKayit++ }
  if(-not $dogru.Count -and -not $tuz.Count){ $bosKayit++ }

  $sonuc.Add([pscustomobject]@{
    konu_id=(Slug $kn.ders $kn.konu); ders="$($kn.ders)"; konu="$($kn.konu)"
    dogru_hesaplar=$dogru; tuzaklar=$tuz
    kural_metni=$(if($alintiOk){ "$($r.kural_metni)" } else { '' })
    kural_kaynak_ad=$(if($alintiOk){ "$($r.kural_kaynak_ad)" } else { '' })
    zorluk=$zor; dolduran='model'; dogrulandi=$false
    uydurma_kod=($uyd -join ','); alinti_ok=$alintiOk
  })

  # --- ARTIMLI YAZIM: her konudan sonra. Odenen is asla kaybolmaz. ----------
  $bedel=($tokG*1.0/1e6)+($tokC*5.0/1e6)
  $cikti=[ordered]@{
    olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); model='claude-haiku-4-5'
    kapilar='MENU (269 hesap) + KOD denetimi + ALINTI denetimi'
    menu_hesap=$ciftler.Count; toplam=$sonuc.Count
    bu_kosu=@{ konu=$n; jeton_girdi=$tokG; jeton_cikti=$tokC; bedel_usd=[math]::Round($bedel,4) }
    uydurma_kod_ureten=$uydurmaKayit; bos_donen=$bosKayit
    satirlar=$sonuc
  }
  [IO.File]::WriteAllText($HEDEF,[string](ConvertTo-Json -InputObject $cikti -Depth 8),[Text.UTF8Encoding]::new($false))

  $renk=if($uyd.Count){'Red'}elseif(-not $dogru.Count){'DarkGray'}else{'Green'}
  Write-Host ("[{0}/{1}] {2,-34} dogru:{3,-16} tuzak:{4}" -f $n,$kalan.Count,$kn.konu,($dogru -join ','),$tuz.Count) -ForegroundColor $renk
  if($uyd.Count){ Write-Host ("      UYDURMA KOD REDDEDILDI: {0}" -f ($uyd -join ',')) -ForegroundColor Red }
  if($n % 25 -eq 0){ Write-Host ("      --- {0} konu · {1:N3} USD (~{2:N0} TL)" -f $n,$bedel,($bedel*42)) -ForegroundColor Cyan }
}
$bedel=($tokG*1.0/1e6)+($tokC*5.0/1e6)
Write-Host ""
Write-Host ("BITTI: {0} yeni konu · toplam kayit {1}" -f $n,$sonuc.Count) -ForegroundColor Green
Write-Host ("BEDEL: {0:N3} USD (~{1:N0} TL) · uydurma kod ureten {2} · bos donen {3}" -f $bedel,($bedel*42),$uydurmaKayit,$bosKayit)
Write-Host "-> veri/hesap-kalibi.json"
