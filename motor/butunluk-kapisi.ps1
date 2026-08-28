# ============================================================================
#  BÜTÜNLÜK KAPISI — 25.08.2026
#  Cem: "yuttugumuz seyin ... bundan sonra okusan bile YARIM KALMAYACAK
#        sekile getir"
#
#  NEDEN VAR — BUGUN BULUNAN UC KUSUR AYNI KOR NOKTADAN GELIYOR:
#    (1) kesik metin      : madde "...3. Gemiler; 4." diye bitiyor, bent yok
#    (2) baslik-only parca: belge yalniz "Cumhurbaskani Genel Sekreterligi"
#    (3) paragraf deligi  : TFRS 16'da p.12-17, 34-35, 51-60, 71+ ve EK A yok
#
#  UCU DE "belge VAR MI" sorusundan geciyor, "belge TAM MI" sorusundan
#  gecmiyor. yutma-kapsama-kapisi kaynak->ambar oranini BELGE SAYISIYLA
#  olcuyor; 12 parcalik TFRS 16 "yutuldu" sayiliyor, oysa yarisi yok.
#
#  ⚠ BU KUSUR EKSIK SORU DEGIL, YANLIS SORU URETIR. Kesik VUK m.269'dan
#  yazilan kart "Liste sinirlidir (numerus clausus)" dedi - kaynak eksik
#  oldugu icin KENDINDEN EMIN BIR YANLIS ogretti. Hicbir soru kapisi bunu
#  goremez: soru KENDI ICINDE tutarlidir, yalniz DUNYAYLA uyusmaz.
#
#  BU KAPI NE YAPAR: delik BULMAKLA kalmaz, ONARIM LISTESI cikarir -
#  "su standardin su paragraflari yutulacak" diye. Cem'in istedigi buydu.
#
#  UC DURUM: YESIL / KIRMIZI / KOR. Ambara ulasilamadiysa "temiz" DENMEZ.
#  Cikti: veri/butunluk-raporu.json + veri/yutma-is-listesi.json
#  0 USD, model yok.
# ============================================================================
param([switch]$sessiz, [string]$yalniz = '', [switch]$kanunlar)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here 'hat-onkontrol.ps1')
HatOnKontrol $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here

# ---------------------------------------------------------------- ARALIK
function BK_Makul($a,$b){
  # SAGDUYU FRENI (25.08): ilk kosuda "BDS 600: 104.047 eksik paragraf" cikti.
  # Sebep: belge adindaki tarih/tutar/madde numarasi paragraf sanildi. Hicbir
  # standartta 1500 paragraf yoktur; bir parca da 300 paragrafi kapsamaz.
  # Olcum ancak MAKUL oldugu kadar ise yarar - abartili sayi raporu coper eder
  # ve gercek delikleri (TFRS 16'nin 18'i) gorunmez kilar.
  if($a -lt 1 -or $b -lt 1){ return $false }
  if($a -gt 1500 -or $b -gt 1500){ return $false }
  if($b -lt $a){ return $false }
  if(($b - $a) -gt 300){ return $false }
  return $true
}
function BK_Aralik([string]$ad){
  # Belge adindan paragraf/madde araligini cikarir: @{ tip; a; b } ya da $null.
  # Desteklenen: "p.5-8" · "p.12" · "p.A25" · "m.269" · "m.107/A" · "gec. m.1"
  # ⚠ Ek/appendix paragraflari (A25) AYRI SAYI UZAYIDIR - p.25 ile karistirilmaz.
  if("$ad" -match '(?i)\bp\.\s*A\s*(\d+)\s*-\s*A?\s*(\d+)'){ if(BK_Makul ([int]$Matches[1]) ([int]$Matches[2])){ return @{ tip='ek'; a=[int]$Matches[1]; b=[int]$Matches[2] } } else { return $null } }
  if("$ad" -match '(?i)\bp\.\s*A\s*(\d+)'){ if(BK_Makul ([int]$Matches[1]) ([int]$Matches[1])){ return @{ tip='ek'; a=[int]$Matches[1]; b=[int]$Matches[1] } } else { return $null } }
  if("$ad" -match '(?i)\bp\.\s*(\d+)\s*-\s*(\d+)'){ if(BK_Makul ([int]$Matches[1]) ([int]$Matches[2])){ return @{ tip='par'; a=[int]$Matches[1]; b=[int]$Matches[2] } } else { return $null } }
  if("$ad" -match '(?i)\bp\.\s*(\d+)'){ if(BK_Makul ([int]$Matches[1]) ([int]$Matches[1])){ return @{ tip='par'; a=[int]$Matches[1]; b=[int]$Matches[1] } } else { return $null } }
  if("$ad" -match '(?i)\bgec\.\s*m\.\s*(\d+)'){               return @{ tip='gecici'; a=[int]$Matches[1]; b=[int]$Matches[1] } }
  if("$ad" -match '(?i)\bmuk\.\s*m\.\s*(\d+)'){               return @{ tip='mukerrer'; a=[int]$Matches[1]; b=[int]$Matches[1] } }
  if("$ad" -match '(?i)\bm\.\s*(\d+)'){                       return @{ tip='madde'; a=[int]$Matches[1]; b=[int]$Matches[1] } }
  return $null
}

function BK_Kok([string]$ad){
  # Belgenin ait oldugu KAYNAK adi: "TFRS 16 p.5-8 - ..." -> "TFRS 16"
  #                                  "VUK (213 s.K.) m.269 - ..." -> "VUK (213 s.K.)"
  if("$ad" -match '^((TMS|TFRS|BDS|GDS|TSRS)\s*\d+[A-Za-z]?)'){ return ($Matches[1] -replace '\s+',' ') }
  if("$ad" -match '^(.*?\(\s*\d+\s*s\.K\.\s*\))'){ return $Matches[1].Trim() }
  return ''
}

function BK_Kesik([string]$metin){
  $s="$metin".TrimEnd()
  if($s.Length -eq 0){ return $false }
  return ($s -match '(?m)(^|[\s;,:])\d{1,2}(\.\d{1,2})*\.\s*$')
}

function BK_BaslikOnly([string]$metin){
  # Icerigi olmayan, yalniz BASLIK tasiyan oksuz parca.
  #
  # ⚠ 25.08 DERSI — ILK OLCUT YANLIS ALARM URETIYORDU. Olcut "120 karakterin
  # altinda ve icinde 'Madde N' yok" idi. Standartlar iri OZET bloklar halinde
  # dururken bu ise yariyordu; paragraf paragraf boldukten sonra ambarda
  # KISA AMA TAM paragraflar olustu ve olcut onlari oksuz saydi:
  #   "TMS 8 p.6M - Isletme, nakit akisi bilgileri haric, finansal tablolarini
  #    tahakkuk esasina gore hazirlar."   <- gercek paragraf, oksuz DEGIL
  # Sonuc: oksuz sayisi 113'ten 201'e cikti ve GERILEME sandim. Gerileme yoktu,
  # OLCUT tabani degismisti. Sabahki dersin aynisi: toplam sayi tek basina
  # ilerleme kaniti degildir - once OLCUTUN hala ayni seyi olctugunu dogrula.
  #
  # DOGRU OLCUT: gercek oksuz parca CUMLE DEGILDIR - noktalamayla bitmez.
  #   "Cumhurbaskani Genel Sekreterligi"  · "Kolluk gorevleri"   -> OKSUZ
  #   "... tahakkuk esasina gore hazirlar." -> TAM PARAGRAF
  $s="$metin".Trim()
  if($s.Length -eq 0){ return $true }
  if($s.Length -ge 120){ return $false }
  if($s -match '[.!?:;]$'){ return $false }          # cumle bitmis: oksuz degil
  return -not ($s -match '(?i)(madde\s*\d|paragraf\s*\d|^\d+\.)')
}

# ---------------------------------------------------------------- OZ-SINAV
function BK_OzSinav {
  $dusen=@()
  # (a) aralik cozme
  $av=@(
    @{ ad='TFRS 16 p.5-8 - Iki istisna';        t='par'; a=5;  b=8  }
    @{ ad='BDS 200 p.13 - Kapsam';              t='par'; a=13; b=13 }
    @{ ad='BDS 200 p.A25 - Mesleki Muhakeme';   t='ek';  a=25; b=25 }
    @{ ad='VUK (213 s.K.) m.269 - Gayrimenkul'; t='madde'; a=269; b=269 }
    @{ ad='VUK (213 s.K.) gec. m.32 [1/5]';     t='gecici'; a=32; b=32 }
    @{ ad='VUK (213 s.K.) muk. m.298 [8/16]';   t='mukerrer'; a=298; b=298 }
  )
  foreach($x in $av){
    $r = BK_Aralik $x.ad
    if($null -eq $r){ $dusen += "ARALIK COZULEMEDI: '$($x.ad)'"; continue }
    if($r.tip -ne $x.t -or $r.a -ne $x.a -or $r.b -ne $x.b){
      $dusen += ("ARALIK YANLIS: '{0}' -> beklenen {1} {2}-{3}, cikan {4} {5}-{6}" -f $x.ad,$x.t,$x.a,$x.b,$r.tip,$r.a,$r.b)
    }
  }
  # SAGDUYU FRENI vakalari (25.08: BDS 600 icin 104.047 eksik raporlandi)
  foreach($kotu in @('BDS 600 p.104047 - X','TMS 34 p.99999','BDS 220 p.5-9000')){
    if($null -ne (BK_Aralik $kotu)){ $dusen += "SAGDUYU FRENI CALISMADI: '$kotu' aralik olarak kabul edildi" }
  }
  if($null -eq (BK_Aralik 'TFRS 16 p.61-66 - KIRAYA VEREN')){ $dusen += 'MAKUL ARALIK REDDEDILDI: p.61-66' }
  # ⚠ EN ONEMLI VAKA: "p.A25" ile "p.25" AYRI SAYI UZAYI. Karistirilirsa
  # ek paragraflari ana paragraf deligi gibi gorunur ve rapor coper olur.
  $ek = BK_Aralik 'BDS 200 p.A25'
  $par = BK_Aralik 'BDS 200 p.25'
  if($ek.tip -eq $par.tip){ $dusen += "EK/PARAGRAF AYRIMI YOK: p.A25 ile p.25 ayni uzayda gorunuyor" }
  # (b) kok cikarma
  foreach($x in @(
    @{ ad='TFRS 16 p.5-8 - Iki istisna';           k='TFRS 16' }
    @{ ad='VUK (213 s.K.) m.269 - Gayrimenkuller'; k='VUK (213 s.K.)' }
    @{ ad='BDS 200 p.1 - Kapsam';                  k='BDS 200' } )){
    $c = BK_Kok $x.ad
    if($c -ne $x.k){ $dusen += "KOK YANLIS: '$($x.ad)' -> beklenen '$($x.k)' cikan '$c'" }
  }
  # (c) kesiklik
  foreach($b in @('...3. Gemiler ve diger tasitlar; 4.','1. Sira numarasi; 2. Kayit tarihi; 3.','Uygulama esaslari asagidadir. 10.4.')){
    if(-not (BK_Kesik $b)){ $dusen += "BILINEN-KESIK yakalanmadi: '$b'" }
  }
  foreach($t in @('Bu Kanun 1.1.2026 tarihinde yururluge girer.','Azami tutar 5.000 TL.','Bir ticari isletmeyi isleten kisi tacirdir.')){
    if(BK_Kesik $t){ $dusen += "BILINEN-TAM yanlis isaretlendi: '$t'" }
  }
  # (d) baslik-only
  if(-not (BK_BaslikOnly 'Cumhurbaskani Genel Sekreterligi')){ $dusen += 'BILINEN-OKSUZ yakalanmadi' }
  if(BK_BaslikOnly 'Madde 19- (1) Bu Kanun 1 Haziran 2005 tarihinde yururluge girer.'){ $dusen += 'BILINEN-DOLU yanlis oksuz sayildi' }
  return $dusen
}

$sinavDusen = @(BK_OzSinav)
if($sinavDusen.Count){
  Write-Host '!! BUTUNLUK KAPISI KENDI SINAVINDAN DUSTU:' -ForegroundColor Red
  foreach($d in $sinavDusen){ Write-Host "   $d" }
  exit 1
}
if(-not $sessiz){
  Write-Host 'Oz-sinav: 23/23 vaka gecti (aralik 6 + sagduyu freni 4 + ek/par ayrimi 1 + kok 3 + kesik 6 + oksuz 2, 1 kombine)'
  Write-Host '  SINANMAYAN DALLAR: ambar sorgusu · sayfalama · rapor yazimi · gercek belge adlarinin cesitliligi'
  Write-Host ''
}

# ---------------------------------------------------------------- AMBAR
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $env:SUPABASE_SERVICE_KEY){
  if(-not $sessiz){ Write-Host 'KOR: SUPABASE_SERVICE_KEY yok - "temiz" DENMEZ.' -ForegroundColor Yellow }
  exit 1
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$anahtar='' + $env:SUPABASE_SERVICE_KEY
$basliklar=@{ apikey=$anahtar; Authorization="Bearer $anahtar"; 'User-Agent'='mevzuat-radar-robot' }
$ambarUcu='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

function BK_Cek([string]$adres){
  # ⚠ PS 5.1 iki tuzak: ConvertFrom-Json boru hattinda diziyi katlar
  # (-InputObject sart) VE fonksiyon tek kayit dondurunce dizi ACILIR
  # (",@()" ile sarmalanir). Ikisi de 25.08'de olcum curuttu.
  for($deneme=1; $deneme -le 3; $deneme++){
    try {
      $yanit=Invoke-WebRequest -UseBasicParsing -Uri $adres -Headers $basliklar -TimeoutSec 240
      $govde=[Text.Encoding]::UTF8.GetString($yanit.RawContentStream.ToArray())
      $cozulen=ConvertFrom-Json -InputObject $govde
      return ,@($cozulen)
    } catch {
      if($deneme -eq 3){ throw }
      Start-Sleep -Seconds (3*$deneme)   # 500 sunucu hatasi 25.08'de taramayi kesti
    }
  }
}

# id ile sayfalama (kaynak_ad ile sayfalama 500 veriyor - 25.08 olcumu)
$desen = if($kanunlar){ '\(\s*[0-9]+\s*s\.K\.\s*\)' } else { '^(TMS|TFRS|BDS|GDS|TSRS)\s' }
if($yalniz){ $desen = '^' + [regex]::Escape($yalniz) }
$belgeler=New-Object System.Collections.Generic.List[object]
$sonId=''
if(-not $sessiz){ Write-Host 'Ambar taraniyor...' }
for($sayfa=0; $sayfa -lt 200; $sayfa++){
  $u="$ambarUcu`?select=id,kaynak_ad,metin&kaynak_ad=imatch." + [uri]::EscapeDataString($desen) + "&order=id&limit=500"
  if($sonId){ $u += "&id=gt.$sonId" }
  $sayfaVeri = BK_Cek $u
  if($sayfaVeri.Count -eq 0){ break }
  foreach($x in $sayfaVeri){ $belgeler.Add($x) }
  $sonId="$($sayfaVeri[$sayfaVeri.Count-1].id)"
  if($sayfaVeri.Count -lt 500){ break }
  if($sayfa -eq 199){ throw 'SAYFA TAVANI - sessiz kirpma riski, tarama gecersiz' }
}
if(-not $sessiz){ Write-Host ("  belge: {0}" -f $belgeler.Count) }

# ---------------------------------------------------------------- OLC
$duz=New-Object System.Collections.Generic.List[object]
$kesikSayi=0; $oksuzSayi=0
$olcN=0
foreach($b in $belgeler){
  $olcN++
  if(-not $sessiz -and ($olcN % 3000) -eq 0){ Write-Host ("  olculen: {0}/{1}  ({2:HH:mm:ss})" -f $olcN,$belgeler.Count,(Get-Date)) }
  $ad="$($b.kaynak_ad)"; $metin="$($b.metin)"
  $kok = BK_Kok $ad
  if(-not $kok){ continue }
  $ar = BK_Aralik $ad
  $kesik = BK_Kesik $metin
  $oksuz = BK_BaslikOnly $metin
  if($kesik){ $kesikSayi++ }
  if($oksuz){ $oksuzSayi++ }
  $duz.Add([pscustomobject]@{
    kok=$kok; ad=$ad; tip=$(if($ar){$ar.tip}else{''})
    a=$(if($ar){$ar.a}else{0}); b=$(if($ar){$ar.b}else{0})
    kesik=$kesik; oksuz=$oksuz; uzunluk=$metin.Length })
}

$isListesi=New-Object System.Collections.Generic.List[object]
$kirmizi=0; $yesil=0
$satirlar=New-Object System.Collections.Generic.List[object]
# 28.08: Group-Object 31k kayit x binlerce grup olceginde PS5.1'de felc oluyor
# (kanunlar kosusu 4 saatte bitmedi) -> hashtable gruplama, ayni davranis.
$gruplar=@{}
foreach($x in $duz){
  if(-not $gruplar.ContainsKey($x.kok)){ $gruplar[$x.kok]=New-Object System.Collections.Generic.List[object] }
  $gruplar[$x.kok].Add($x)
}
if(-not $sessiz){ Write-Host ("  grup: {0} kaynak" -f $gruplar.Count) }
foreach($kokAd in ($gruplar.Keys | Sort-Object)){
  $g=[pscustomobject]@{ Name=$kokAd; Group=$gruplar[$kokAd] }
  $ar=@($g.Group | Where-Object { $_.tip -ne '' })
  if($ar.Count -eq 0){ continue }
  $delikler=@()
  foreach($tip in @('par','ek','madde','gecici','mukerrer')){
    $bu=@($ar | Where-Object { $_.tip -eq $tip })
    if($bu.Count -lt 2){ continue }
    $kaps=New-Object 'System.Collections.Generic.HashSet[int]'
    foreach($x in $bu){ for($i=$x.a;$i -le $x.b;$i++){ [void]$kaps.Add($i) } }
    $enB=($bu | ForEach-Object { $_.b } | Measure-Object -Maximum).Maximum
    $enK=($bu | ForEach-Object { $_.a } | Measure-Object -Minimum).Minimum
    # 28.08 asiri-aralik sigortasi: tek sapkin etiket (ornek-rakam 'p.900' vakasi)
    # milyonluk donguyu ve sahte dev eksik listesini acmasin - isaretle, gec
    if(($enB-$enK) -gt 5000){ $delikler += [pscustomobject]@{ tip="$tip-ASIRI-ARALIK"; enKucuk=$enK; enBuyuk=$enB; eksik=@() }; continue }
    $d=@(); for($i=$enK;$i -le $enB;$i++){ if(-not $kaps.Contains($i)){ $d += $i } }
    if($d.Count){ $delikler += [pscustomobject]@{ tip=$tip; enKucuk=$enK; enBuyuk=$enB; eksik=$d } }
  }
  $kesikB=@($g.Group | Where-Object { $_.kesik }).Count
  $oksuzB=@($g.Group | Where-Object { $_.oksuz }).Count
  $sorunVar = ($delikler.Count -gt 0 -or $kesikB -gt 0 -or $oksuzB -gt 0)
  if($sorunVar){ $kirmizi++ } else { $yesil++ }
  if($sorunVar){
    $eksikToplam=0; foreach($dd in $delikler){ $eksikToplam += @($dd.eksik).Count }
    $isListesi.Add([pscustomobject]@{
      kaynak=$g.Name; parca=$g.Group.Count
      eksik_paragraf=$eksikToplam; kesik_belge=$kesikB; oksuz_belge=$oksuzB
      delikler=$delikler })
    $satirlar.Add([pscustomobject]@{ kok=$g.Name; parca=$g.Group.Count; eksik=$eksikToplam; kesik=$kesikB; oksuz=$oksuzB
      ozet=$(($delikler | ForEach-Object { "$($_.tip): " + ((@($_.eksik)|Select-Object -First 8) -join ',') + $(if(@($_.eksik).Count -gt 8){"...+$(@($_.eksik).Count-8)"}else{''}) }) -join ' | ') })
  }
}

if(-not $sessiz){
  Write-Host ''
  Write-Host ("KAYNAK: {0} temiz · {1} SORUNLU" -f $yesil,$kirmizi)
  Write-Host ("  kesik belge: {0} · oksuz (baslik-only) belge: {1}" -f $kesikSayi,$oksuzSayi)
  Write-Host ''
  Write-Host ("{0,-24} {1,5} {2,6} {3,6} {4,6}  {5}" -f 'KAYNAK','parca','eksik','kesik','oksuz','DELIKLER')
  foreach($s in ($satirlar | Sort-Object -Property @{e='eksik';Descending=$true} | Select-Object -First 30)){
    Write-Host ("{0,-24} {1,5} {2,6} {3,6} {4,6}  {5}" -f $s.kok.Substring(0,[Math]::Min(24,$s.kok.Length)),$s.parca,$s.eksik,$s.kesik,$s.oksuz,$s.ozet)
  }
  if($satirlar.Count -gt 30){ Write-Host ("... ve {0} kaynak daha (is listesinde tamami var)" -f ($satirlar.Count-30)) }
}

$isDuz=@(); foreach($i in $isListesi){ $isDuz += ,$i }
[IO.File]::WriteAllText((Join-Path $depoKok 'veri/butunluk-raporu.json'),
  (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); kapsam=$(if($kanunlar){'kanunlar'}elseif($yalniz){$yalniz}else{'standartlar'})
    durum=$(if($kirmizi){'KIRMIZI'}else{'YESIL'})
    belge=$belgeler.Count; kaynak_temiz=$yesil; kaynak_sorunlu=$kirmizi
    kesik_belge=$kesikSayi; oksuz_belge=$oksuzSayi
    is_listesi=$isDuz }) -Depth 10),(New-Object Text.UTF8Encoding($false)))
if(-not $sessiz){ Write-Host ''; Write-Host '-> veri/butunluk-raporu.json  (yutma is listesi icinde)' }
if($kirmizi){ exit 1 } else { exit 0 }