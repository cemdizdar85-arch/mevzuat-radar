#requires -Version 5.1
<#
================================================================================
  KONU ETIKETI SECIMI — MUFREDAT MENUSUYLE  (11.09.2026, Cem "yeniden kos")

  NIYE YENIDEN: 11.09 ikinci gorus turu (arac/konu-hakem-turu.ps1) 71 yanlis
  etiket buldu ve her biri icin dogru etiketi ONERDI - ama SERBEST METIN olarak.
  Uygulamadan once olculdu: onerilen 68 etiketin 66'si 1.409 konuluk MUFREDAT
  LISTESINDE YOK. Uygulansaydi "etiket soruyu anlatiyor" sorunu cozulur ama
  "etiket bir mufredat konusuna denk geliyor" ozelligi KIRILIRDI - o 66 soru
  kapsama olcumunden tamamen duserdi. Yani duzeltirken asil amaci bozardik.

  ⭐ ILKE: KIMLIK YAZILMAZ, SECILIR.
  Bugunku uc hatanin da koku ayni: kimlik alanini modele YAZDIRMAK.
    kp-80      : hesap kodunu ezberinden yazdi -> 529 (dogrusu 521)
    71 etiket  : etiketi girdi olarak aldi, sessizce sapti
    66 oneri   : bu betigin oncesinde serbest metin yazdirildi
  Karsi kanit da bugunden: hesap kalibi provasinda 269 hesaplik MENU verildi ve
  "yalniz buradan sec" dendi -> 6 konuda 0 uydurma kod.
  Bu betik ayni kisiti etikete uygular: model YAZMAZ, mufredattan SECER.

  NE YAPAR: her isaretli soru icin, o DERSIN mufredat konu listesi isteme MENU
  olarak konur; model sorunun olctugu konuyu menuden secer. Donen deger menude
  yoksa kod REDDEDER (uydurma kapisi). Menude uygun konu yoksa model 'YOK' der -
  bu, mufredata YENI KONU eklenmesi gerektigini soyleyen ayri bir sinyaldir ve
  kendiliginden uygulanmaz.

  DERSE DOKUNMAZ: menu yalniz sorunun kendi dersinden kurulur. Sorunun baska
  derse ait oldugu hukmu hakemin `ders_uyum` alanindadir, ayri kapidir.

  BEDEL: menu ~2,5K + soru ~1K jeton, cikti ~100. Haiku 1/5 USD/M ->
  ~0,004 USD/soru · 71 soru ~0,28 USD (~12 TL). Tavanla korunur.

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-etiket-sec.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-etiket-sec.ps1 -Yaz
================================================================================
#>
param(
  [switch]$Yaz,
  [double]$TavanTL = 20,
  [int]$Ornek = 0
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $depoKok 'motor\api-hedef.ps1')

function Katla([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
       -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
       -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}

# --- MUFREDAT: ders -> konu listesi -----------------------------------------
$katHam = Get-Content (Join-Path $depoKok 'veri\kart-onerileri.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$mufredat=@{}
foreach($x in @($katHam.oneriler)){
  $d="$($x.ders)"; if(-not $d){ continue }
  if(-not $mufredat.ContainsKey($d)){ $mufredat[$d]=New-Object System.Collections.Generic.List[string] }
  if($mufredat[$d] -notcontains "$($x.konu)"){ $mufredat[$d].Add("$($x.konu)") }
}
# --- DERS ADI KOPRUSU --------------------------------------------------------
# Mufredat anahtarlari SINIFLANDIRICININ ham adlaridir ("Ticaret ve Borclar",
# "Is ve Sosyal Guvenlik"); sorularin ders alani ise EKRAN adidir ("Ticaret
# Hukuku", "İş ve Sosyal Güvenlik Hukuku"). Koprusuz `ContainsKey` bos doner ve
# 71 sorunun buyuk kismi "MENU YOK" diye atlanirdi.
# Ticaret/Borclar AYRISMASI bilincli: TESMER Yonergesi m.6.2 ikisini AYRI ders
# sayar (6+6 soru) ama mufredat siniflandiricisi BIRLESIK tutmus. Menu birlesik
# listeden kurulur - konu secimi icin dogru olan budur; DERS hukmu ayri kapida.
$DERS_KOPRU = @{
  'ticaret hukuku'                = 'Ticaret ve Borclar'
  'borclar hukuku'                = 'Ticaret ve Borclar'
  'is ve sosyal guvenlik hukuku'  = 'Is ve Sosyal Guvenlik'
}
function MenuAnahtari([string]$ders){
  $k = Katla $ders
  if($DERS_KOPRU.ContainsKey($k)){ return $DERS_KOPRU[$k] }
  foreach($m in $mufredat.Keys){ if((Katla $m) -eq $k){ return $m } }
  return $null
}

Write-Host "MUFREDAT MENULERI:" -ForegroundColor Cyan
foreach($d in ($mufredat.Keys | Sort-Object)){
  $m=($mufredat[$d] -join "`n")
  if($mufredat[$d].Count -ge 10){ Write-Host ("  {0,-32} {1,4} konu · {2,6:N0} kr" -f $d,$mufredat[$d].Count,$m.Length) }
}

# --- ISARETLI SORULAR --------------------------------------------------------
$turHam = Get-Content (Join-Path $depoKok 'veri\konu-hakem-turu.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$aday = @(@($turHam.satirlar) | Where-Object { "$($_.karar)" -eq 'YANLIS' })
if($Ornek -gt 0){ $aday=@($aday | Select-Object -First $Ornek) }
$tahminUSD = $aday.Count * 0.004
Write-Host ("`nISARETLI: {0} soru · tahmini {1:N3} USD (~{2:N1} TL)" -f $aday.Count,$tahminUSD,($tahminUSD*42)) -ForegroundColor Cyan
if(($tahminUSD*42) -gt $TavanTL){ throw "TAVAN ASILDI." }
if(-not $Yaz){ Write-Host "`nKURU KOSU - API cagrisi yapilmadi. Kosmak icin: -Yaz" -ForegroundColor Yellow; return }

$ISTEM = @'
Bir sinav sorusunun HANGI MUFREDAT KONUSUNU olctugunu belirleyeceksin.

⛔ KONU ADI YAZMA. Asagidaki MUFREDAT LISTESINDEN birebir SEC ve aynen kopyala.
   Listede olmayan bir ad yazarsan cevabin reddedilir.
⛔ Sorunun dogrulugunu, celdiricilerini, dilini YARGILAMA. Tek isin konuyu bulmak.

Sorunun OLCTUGU seyi bul - konu adi soru metninde gecmese de olur. Ornek: soru
"makine satisi" diyorsa ve listede "duran varlik satisi" varsa onu sec.

Listede sorunun olctugu konu GERCEKTEN yoksa, uydurma: "YOK" yaz ve
"eksik_konu" alanina mufredata eklenmesi gereken konu adini kucuk harfle oner.

Cevap YALNIZ JSON:
{"secilen":"listeden birebir kopya ya da YOK","eksik_konu":"","gerekce":"tek cumle"}
'@

function Coz2($m){ $t="$m"; $i=$t.IndexOf('{'); $j=$t.LastIndexOf('}'); if($i -lt 0 -or $j -le $i){ return $null }; try{ return ($t.Substring($i,$j-$i+1)|ConvertFrom-Json) }catch{ return $null } }

$onb=@{}; $sonuc=New-Object System.Collections.Generic.List[object]
$tokG=0;$tokC=0;$n=0;$uydurma=0;$yok=0
foreach($a in $aday){
  $n++
  $ders="$($a.ders)"
  $mAnahtar = MenuAnahtari $ders
  if(-not $mAnahtar){ Write-Host ("  MENU YOK: {0} ({1}/{2})" -f $ders,$a.etiket,$a.id) -ForegroundColor Yellow; continue }
  $menu=($mufredat[$mAnahtar] -join "`n")

  $et="$($a.etiket)"
  if(-not $onb.ContainsKey($et)){
    $cf=Join-Path $depoKok "veri\fabrika\kalip-parti-$et.json"
    $onb[$et]= if(Test-Path $cf){ Get-Content $cf -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
  }
  $v=$onb[$et]; if($v){ $v=$v.($a.id) }
  if(-not $v -or -not $v.soru){ continue }
  $sik=(@('A','B','C','D','E') | ForEach-Object { "$_) $($v.siklar.$_)" }) -join "`n"

  $istek = $ISTEM + "`n`n=== MUFREDAT LISTESI ($mAnahtar) ===`n$menu" +
           "`n`n=== SORU ===`n$($v.soru)`n=== SIKLAR ===`n$sik`n=== DOGRU SIK ===`n$($v.dogru)" +
           "`n=== SU ANKI (YANLIS) ETIKET ===`n$($a.konu)"

  $y=$null
  foreach($d in 1..3){ try{ $y=Invoke-ClaudeMesaj -Model 'claude-haiku-4-5-20251001' -Icerik $istek -MaxTok 300; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } }
  $tokG+=[int]$y.girdi; $tokC+=[int]$y.cikti
  $k=Coz2 $y.metin
  $sec="$($k.secilen)".Trim()

  # --- UYDURMA KAPISI: secilen menude var mi -------------------------------
  $gecerli=$false; $tamAd=''
  if($sec -and $sec -ne 'YOK'){
    $sk=Katla $sec
    foreach($m in $mufredat[$mAnahtar]){ if((Katla $m) -eq $sk){ $gecerli=$true; $tamAd=$m; break } }
  }
  $durum = if($sec -eq 'YOK'){ 'MENUDE-YOK' } elseif($gecerli){ 'SECILDI' } else { 'UYDURMA' }
  if($durum -eq 'UYDURMA'){ $uydurma++ }
  if($durum -eq 'MENUDE-YOK'){ $yok++ }

  $sonuc.Add([pscustomobject]@{
    ders=$ders; etiket=$et; id=$a.id; eski="$($a.konu)"
    yeni=$tamAd; durum=$durum; ham_secim=$sec
    eksik_konu="$($k.eksik_konu)"; gerekce="$($k.gerekce)"
    tur_onerisi="$($a.onerilen)"
  })
  $renk = switch($durum){ 'SECILDI'{'Green'} 'MENUDE-YOK'{'Yellow'} default{'Red'} }
  Write-Host ("[{0}/{1}] {2} {3}" -f $n,$aday.Count,$et,$a.id) -ForegroundColor $renk -NoNewline
  if($durum -eq 'SECILDI'){ Write-Host ("  '{0}' -> '{1}'" -f $a.konu,$tamAd) }
  elseif($durum -eq 'MENUDE-YOK'){ Write-Host ("  MENUDE YOK · onerilen yeni konu: '{0}'" -f $k.eksik_konu) }
  else{ Write-Host ("  ⛔ UYDURMA: '{0}' menude yok" -f $sec) }
}

$bedel=($tokG*1.0/1e6)+($tokC*5.0/1e6)
Write-Host ""
Write-Host ("BITTI: {0} soru · SECILDI {1} · MENUDE-YOK {2} · UYDURMA {3}" -f $sonuc.Count,
  @($sonuc|Where-Object{$_.durum -eq 'SECILDI'}).Count,$yok,$uydurma) -ForegroundColor Green
Write-Host ("BEDEL: girdi {0} · cikti {1} jeton · {2:N4} USD (~{3:N1} TL)" -f $tokG,$tokC,$bedel,($bedel*42))

. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\_etiket-secim.json') -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); model='claude-haiku-4-5'
  ilke='KIMLIK YAZILMAZ, SECILIR: model mufredat menusunden secer; menude olmayan ad kod tarafindan reddedilir.'
  bedel_usd=[math]::Round($bedel,4)
  toplam=$sonuc.Count
  secildi=@($sonuc|Where-Object{$_.durum -eq 'SECILDI'}).Count
  menude_yok=$yok; uydurma=$uydurma
  satirlar=$sonuc
})
Write-Host "`n-> veri/_etiket-secim.json"
Write-Host "SIRADAKI: arac/konu-etiket-onar.ps1 bu dosyadan okuyacak sekilde baglanacak."
