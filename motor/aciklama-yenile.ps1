# ============================================================================
#  ACIKLAMA YENILEME — 29.07.2026
#
#  NIYE: olcum yapildi. Aciklamalarimizin ortalamasi 162 KARAKTER, yani iki
#  cumle. O uzunlukta "bu sik yanlis cunku..." denir; KONU OGRETILMEZ. Cem'in
#  hedefi "kitabi ezberlemeden, soru cozerek konuyu ogretmek" - bu boyda olmaz.
#  Her sikka ayri aciklama zaten %100 var (iyi); eksik olan DERINLIK.
#
#  NE DEGISIR, NE DEGISMEZ:
#    DEGISIR : aciklama (her sik), hap
#    ASLA DEGISMEZ : soru metni, siklar, dogru cevap, kaynak
#  Aciklamayi zenginlestirmek icin sorunun kendisine dokunmak, yeni soru
#  uretmektir - bu kanaldan gecmez.
#
#  SABLON (dogru sik):
#    1) Ne soruluyor  - tek cumle, hic muhasebe bilmeyene
#    2) Kural         - maddeye dayali ama gunluk dille
#    3) Bu olayda     - kuralin soruya uygulanisi, adim adim
#    4) Akilda kalsin - tek cumlelik hap
#  Yanlis siklarda tek is: TUZAGI ADLANDIRMAK. "Yanlis" demek ogretmez;
#  "bu sik X ile Y'yi karistiriyor" ogretir. Sinavda kaybettiren sey bilgi
#  eksigi degil, karistirmadir.
#
#  RAKAM KAPISI (bu betigin asil sigortasi):
#  Yeni aciklamada gecen HER SAYI, kaynak metinde (madde metni + soru + siklar)
#  gecmek ZORUNDA. Gecmiyorsa o sorunun yenilemesi COPE ATILIR ve eski aciklama
#  KALIR. Bu gece bulunan uc gercek hatanin ucu de uydurulmus RAKAM/SUREYDI
#  (SGK %20 yerine %21, AATUHK 7 gun yerine 15, 3568 alikoyma suresi).
#  Aciklamayi zenginlestirirken ayni hatayi UretMEK, hic zenginlestirmemekten
#  kotudur.
# ============================================================================
param(
  [switch]$calistir,
  [string]$ders = '',        # yalniz bu ders (bos = hepsi)
  [int]$sinir = 0,           # kac soru (0 = hepsi)
  [string]$model = 'claude-sonnet-4-5-20250929',
  [string]$cikti = ''
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

$LOG = Join-Path $kok 'veri/aciklama-log.txt'
try { Start-Transcript -Path $LOG -Force | Out-Null } catch {}

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 1 }
$AK = "$env:ANTHROPIC_API_KEY".Trim()
$H  = @{ apikey=$KEY; Authorization="Bearer $KEY" }
$HW = $H + @{ Prefer="return=minimal" }
$HDR = @{ 'x-api-key'=$AK; 'anthropic-version'='2023-06-01' }

. (Join-Path $here 'madde-coz.ps1') -kutuphane

# --- sorulari cek
$u = "$SB_URL/rest/v1/soru_havuzu?select=id,sinav,ders,konu,soru,siklar,dogru,aciklama,hap,kaynak,kanun_no,madde_no&order=id"
if($ders){ $u += "&ders=eq." + [uri]::EscapeDataString($ders) }
$sorular = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  $s = Invoke-RestMethod -Uri "$u&offset=$bas&limit=500" -Headers $H -TimeoutSec 180
  $d = @($s); if($d.Count -eq 0){ break }
  foreach($x in $d){ $sorular.Add($x) }
  if($d.Count -lt 500){ break }
  $bas += 500
}
Write-Host ("Soru: {0}{1}" -f $sorular.Count, $(if($ders){" (ders: $ders)"}else{""}))
if($sorular.Count -eq 0){ Write-Host "KIRMIZI: soru okunamadi."; try{Stop-Transcript|Out-Null}catch{}; exit 1 }

function IstemKur($s, $maddeMetni){
  $sik = ""; foreach($h in @('A','B','C','D','E')){ $v="$($s.siklar.$h)"; if($v.Trim()){ $sik += "$h) $v`n" } }
  $dayanak = if($maddeMetni){ "=== DAYANAK METIN ($($s.kaynak)) ===`n$maddeMetni`n=== METIN BITTI ===`n" } else { "(Bu soru bir kanun maddesine dayanmiyor - dil/matematik/genel kultur. Dayanak sorunun kendi kurgusudur.)`n" }
  return @"
Sen bir SMMM sinav hazirlik platformunun editorusun. Gorevin bir sorunun ACIKLAMALARINI yeniden yazmak.

$dayanak
SORU: $($s.soru)
SIKLAR:
$sik
DOGRU CEVAP: $($s.dogru)

MUTLAK KURALLAR:
1. SORUYU, SIKLARI VE DOGRU CEVABI DEGISTIRME. Yalniz aciklamalari yazacaksin.
2. Yukaridaki dayanak metinde YAZMAYAN hicbir rakam, oran, sure ya da esik YAZMA. Emin degilsen sayi vermeden anlat. Uydurulmus tek bir rakam butun isi bozar.
3. HIC MUHASEBE BILMEYEN birine anlatiyorsun. Teknik terimi ilk kullandiginda parantez icinde tek cumleyle acikla.
4. Cumleler kisa: ortalama 20 kelimeyi gecmesin. Edilgen degil etken yaz ("kayit yapilir" degil, "isletme su kaydi yapar").

DOGRU SIKKIN ($($s.dogru)) aciklamasi DORT PARCA olacak, bu basliklarla ve bu sirayla:
Ne soruluyor: <tek cumle>
Kural: <maddeye dayali, gunluk dille>
Bu olayda: <kuralin bu soruya uygulanisi, adim adim, varsa rakamli>
Akilda kalsin: <tek cumle>
Uzunlugu 400-700 karakter olsun.

YANLIS SIKLARIN her birinde TEK IS var: tuzagi adlandirmak. Kalip:
"<Bu sik> X ile Y'yi karistiriyor. X sudur; Y ise budur."
120-250 karakter. "Yanlistir" deyip gecme - ogrenci NEYI karistirdigini gormeli.

hap: butun sorunun tek cumlelik ozeti (en fazla 120 karakter).

SADECE gecerli JSON dondur, baska hicbir sey yazma:
{"aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"hap":"..."}
Sorunun bos olan sikki varsa o harfi de bos string birak.
"@
}

# --- isler
$isler = New-Object System.Collections.Generic.List[object]
$ist = [ordered]@{ toplam=0; hazir=0; metinli=0; metinsiz=0 }
foreach($s in $sorular){
  $ist.toplam++
  if($sinir -gt 0 -and $isler.Count -ge $sinir){ break }
  $metin = ''
  if($s.kanun_no -and $s.madde_no -and "$($s.kanun_no)" -notin @('STD','THP')){
    $m = MaddeMetni "$($s.kanun_no)" ("$($s.madde_no)" -replace '^(gec|ek|muk)','') $( if("$($s.madde_no)" -match '^(gec|ek|muk)'){ $Matches[1] } else { '' } )
    if($m -and $m.metin){ $metin = "$($m.metin)"; if($metin.Length -gt 6000){ $metin = $metin.Substring(0,6000) } }
  }
  if($metin){ $ist.metinli++ } else { $ist.metinsiz++ }
  $isler.Add([pscustomobject]@{ id="$($s.id)"; soru=$s; metin=$metin; istem=(IstemKur $s $metin) })
  $ist.hazir++
  if($ist.hazir % 200 -eq 0){ Write-Host ("  hazirlanan ...{0}" -f $ist.hazir) }
}
Write-Host ""
foreach($k in $ist.Keys){ Write-Host ("  {0,-10} {1}" -f $k, $ist[$k]) }

# --- maliyet
$gk=0; foreach($i in $isler){ $gk += $i.istem.Length }
$gt=[math]::Round($gk/3); $ct=$isler.Count*700
$FG=3.0; $FC=15.0
$tahmin = (($gt/1e6*$FG)+($ct/1e6*$FC))/2
Write-Host ""
Write-Host ("MALIYET TAHMINI (Batch %50): ~{0:N2} USD   soru basina ~{1:N4}" -f $tahmin, $(if($isler.Count){$tahmin/$isler.Count}else{0}))
if(-not $calistir){ Write-Host "OLCUM MODU - istek atilmadi, 0 USD."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }
if(-not $AK){ Write-Host "ANTHROPIC_API_KEY yok."; exit 1 }

# --- batch
$sonuc=@{}; $gG=0; $gC=0
$PARTI=400
for($p=0; $p -lt [math]::Ceiling($isler.Count/$PARTI); $p++){
  $dilim=@($isler[($p*$PARTI)..([math]::Min(($p+1)*$PARTI-1,$isler.Count-1))])
  $req=@(); foreach($i in $dilim){ $req += @{ custom_id="$($i.id)"; params=@{ model=$model; max_tokens=2000; messages=@(@{role='user';content=$i.istem}) } } }
  $govde=@{requests=$req}|ConvertTo-Json -Depth 8
  Write-Host ("PARTI {0}: {1} soru ({2:N0} KB)" -f ($p+1), $dilim.Count, ($govde.Length/1024))
  $b = Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages/batches' -Headers $HDR -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde))
  $tur=0
  while($true){ Start-Sleep -Seconds 20; $tur++
    $st = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages/batches/$($b.id)" -Headers $HDR
    if($st.processing_status -eq 'ended'){ break }
    if($tur -ge 90){ Write-Host "  ZAMAN ASIMI"; break } }
  $adres = if($st.results_url){ "$($st.results_url)" } else { "https://api.anthropic.com/v1/messages/batches/$($b.id)/results" }
  $cev = Invoke-WebRequest -UseBasicParsing -Uri $adres -Headers $HDR -TimeoutSec 300
  # PS7 metin tanimadigi cevaplarda byte dizisi dondurur - 28.07'de ogrenildi
  $metinCevap = if($cev.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($cev.Content) } else { "$($cev.Content)" }
  foreach($sat in ($metinCevap -split "`r?`n")){
    if("$sat".Trim().Length -eq 0){ continue }
    try { $r = $sat | ConvertFrom-Json } catch { continue }
    if("$($r.result.type)" -ne 'succeeded'){ continue }
    $gG += [int]"$($r.result.message.usage.input_tokens)"; $gC += [int]"$($r.result.message.usage.output_tokens)"
    $mt=[regex]::Match("$($r.result.message.content[0].text)", '\{[\s\S]*\}')
    if(-not $mt.Success){ continue }
    try { $sonuc["$($r.custom_id)"] = ($mt.Value | ConvertFrom-Json) } catch {}
  }
}

# --- RAKAM KAPISI + yazma
function Sayilar([string]$t){
  $l=@(); foreach($m in [regex]::Matches("$t", '\d[\d\.,]*')){ $l += ($m.Value.TrimEnd('.',',')) }
  return $l
}
$ozet=[ordered]@{ yenilenen=0; rakamRed=0; bosRed=0; cevapsiz=0; yazmaHatasi=0 }
$red = New-Object System.Collections.Generic.List[object]
foreach($i in $isler){
  $y = $sonuc[$i.id]
  if(-not $y -or -not $y.aciklama){ $ozet.cevapsiz++; continue }
  $yeniMetin = ""
  foreach($h in @('A','B','C','D','E')){ $yeniMetin += " " + "$($y.aciklama.$h)" }
  $yeniMetin += " " + "$($y.hap)"
  # dogru sikkin aciklamasi bos olamaz
  if("$($y.aciklama.$($i.soru.dogru))".Trim().Length -lt 100){ $ozet.bosRed++; continue }

  # RAKAM KAPISI: yeni aciklamadaki her sayi kaynakta gecmeli
  $kaynakMetin = $i.metin + " " + "$($i.soru.soru)"
  foreach($h in @('A','B','C','D','E')){ $kaynakMetin += " " + "$($i.soru.siklar.$h)" }
  $kaynakSay = @{}; foreach($n in (Sayilar $kaynakMetin)){ $kaynakSay[$n]=1 }
  $uydurma = @()
  foreach($n in (Sayilar $yeniMetin)){
    if($n.Length -le 1){ continue }              # 1-2 gibi sira sayilari
    if($kaynakSay.ContainsKey($n)){ continue }
    $uydurma += $n
  }
  if($uydurma.Count -gt 0){
    $ozet.rakamRed++
    $red.Add([pscustomobject]@{ id=$i.id; sebep='rakam-kaynakta-yok'; rakamlar=($uydurma -join ',') })
    continue
  }

  $govde = @{ aciklama=$y.aciklama; hap="$($y.hap)" } | ConvertTo-Json -Depth 5
  try {
    Invoke-RestMethod -Method Patch -Uri "$SB_URL/rest/v1/soru_havuzu?id=eq.$($i.id)" -Headers $HW `
      -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 60 | Out-Null
    $ozet.yenilenen++
  } catch { $ozet.yazmaHatasi++ }
}

$gercek = (($gG/1e6*$FG)+($gC/1e6*$FC))/2
Write-Host ""
Write-Host "======== ACIKLAMA YENILEME ========"
foreach($k in $ozet.Keys){ Write-Host ("  {0,-14} {1}" -f $k, $ozet[$k]) }
Write-Host ("  GERCEK FATURA : ~{0:N2} USD  ({1:N0} giris + {2:N0} cikis token)" -f $gercek, $gG, $gC)
Write-Host ("  NOT: rakam kapisindan donen {0} sorunun ESKI aciklamasi KALDI - bozulmadi." -f $ozet.rakamRed)

$yol = if($cikti){ $cikti } else { Join-Path $kok 'veri/aciklama-rapor.json' }
[IO.File]::WriteAllText($yol, ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); ders=$ders; model=$model
  ozet=$ozet; fatura=[ordered]@{ giris=$gG; cikis=$gC; usd=[math]::Round($gercek,2) }
  redler=@($red | Select-Object -First 100)
} | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ("-> {0}" -f $yol)
try{Stop-Transcript|Out-Null}catch{}
exit 0
