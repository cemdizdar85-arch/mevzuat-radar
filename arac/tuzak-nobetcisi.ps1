#requires -Version 5.1
<#
================================================================================
  TUZAK NOBETCISI — bilinen hatalari KOD CALISMADAN yakalar  (11.09.2026)
  Cem: "bu isi hizlandiracak ve profesyonel yapacak bir sey oner"

  NIYE VAR: 11.09'da en cok zamani ayni hatalari TEKRARLAMAK yedi:
    degisken cakismasi ($DERS <-> $ders)          6 KEZ
    @(... | ConvertFrom-Json) dizi sarma          3 kez
    @($list)  List[object] patlamasi              2 kez
    siralamasiz limit=1 var/yok testi             2 kez
  Toplami yarim gunden fazla. Tuzaklarin hepsi arac/olcum-kapilari.ps1'de
  YAZILI - ama yorum kimseyi DURDURMUYOR. $DERS tuzagina, tuzagi kendi elimle
  yazdiktan SONRA dustum.

  ILKE (Cem'in kurali): "Kural yazmak isin yarisi, MEKANIK KAPI diger yarisi."
  Bu betik o mekanik kapi. Kod CALISTIRILMAZ - okunur.

  ⛔ KURT MASALI OKUMAZ: her kural depoda GERI SINANDI. Yanlis alarm ureten
     kural KONULMADI - bugun tek olcutlu ikiz kapisi 14 vaka bildirip 3'u
     gercek cikmisti; o ders burada bastan uygulandi.

  ⚠ 5. TUZAK (Turkce katlama asimetrisi) BU BETIKTE YOK: statik olarak
     tespit edilemiyor - sorgunun katlanip katlanmadigi ancak calisma aninda
     belli oluyor. Onu olcum-kapilari.ps1'deki AmbarSorgu fonksiyonu kapatiyor.

  KULLANIM
    powershell -NoProfile -File arac/tuzak-nobetcisi.ps1              # tum depo
    powershell -NoProfile -File arac/tuzak-nobetcisi.ps1 -Yol motor\x.ps1
    powershell -NoProfile -File arac/tuzak-nobetcisi.ps1 -Degisen     # yalniz git'te degisenler
  BEDEL 0.
================================================================================
#>
param(
  [string]$Yol = '',          # tek dosya (bos = tum depo)
  [switch]$Degisen,           # yalniz git'te degismis .ps1 dosyalari
  [switch]$Sessiz             # yalniz ozet
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here

# ---------------------------------------------------------------------------
# KURALLAR — her biri: ad · aciklama · denetci
# Denetci: ($metin,$ast,$dosya) alir, bulgu listesi doner @{satir;ileti}
# ---------------------------------------------------------------------------
function K1-DegiskenCakismasi($metin,$ast,$dosya){
  # PS harf AYIRMAZ. $DERS=@{...} yazip sonra $ders='x' dersen TABLOYU EZERSIN.
  # Olculdu: 11.09'da ALTI kez yasandi (havuz-kur, ret-kutugu, plandan-parti-kur...)
  $bul=New-Object System.Collections.Generic.List[object]
  $atama=$ast.FindAll({param($x) $x -is [System.Management.Automation.Language.AssignmentStatementAst]},$true)
  $adlar=@{}
  foreach($a in $atama){
    $sol=$a.Left
    if($sol -isnot [System.Management.Automation.Language.VariableExpressionAst]){ continue }
    $ad=$sol.VariablePath.UserPath
    if($ad.Length -lt 3){ continue }
    if(-not $adlar.ContainsKey($ad.ToLowerInvariant())){ $adlar[$ad.ToLowerInvariant()]=New-Object System.Collections.Generic.List[object] }
    $adlar[$ad.ToLowerInvariant()].Add([pscustomobject]@{ ad=$ad; satir=$a.Extent.StartLineNumber })
  }
  # ⛔ ZARARLI ile ZARARSIZ AYRILIR. Ilk surumde her cakismayi bildiriyordum;
  #    konu-koprusu-kur.ps1'de $ANAHTAR (servis anahtari) satir 105'te eziliyor
  #    ama satir 38'de zaten basliga alinmis - ZARARSIZ. Boyle 14 bulgunun
  #    cogu gurultu olurdu. Bugun tek olcutlu ikiz kapisi 14 vaka bildirip 3'u
  #    gercek cikmisti; ayni hataya dusmeyelim.
  # OLCUT: BUYUK HARFLI sabit, kucuk harfli atamadan SONRA da OKUNUYOR mu?
  #        Okunuyorsa 🔴 ZARARLI (eski deger gitti), okunmuyorsa ⚠ RISKLI.
  # ⛔ 12.09 DARALTILDI (dorduncu kez): ATAMA HEDEFI OKUMA DEGILDIR.
  #    kaydir-coz.ps1:337 "$KEY=$env:SUPABASE_SERVICE_KEY" satiri, satir 268'deki
  #    dongu-ici $key yuzunden "ezildi ve HALA OKUNUYOR" diye ZARARLI bildirildi.
  #    Oysa 337 $KEY'i okumuyor, ATIYOR - eski deger zaten kullanilmayacakti.
  #    Atamanin SOL tarafindaki degisken dugumleri okuma sayilmaz.
  $atamaSol=@{}
  foreach($a in $atama){
    if($a.Left -is [System.Management.Automation.Language.VariableExpressionAst]){
      $atamaSol[("{0}:{1}" -f $a.Left.Extent.StartLineNumber,$a.Left.Extent.StartColumnNumber)]=$true
    }
  }
  $kullanim=@($ast.FindAll({param($x) $x -is [System.Management.Automation.Language.VariableExpressionAst]},$true) |
    Where-Object{ -not $atamaSol.ContainsKey(("{0}:{1}" -f $_.Extent.StartLineNumber,$_.Extent.StartColumnNumber)) })
  foreach($k in $adlar.Keys){
    $l=$adlar[$k].ToArray()
    $yazim=@($l|ForEach-Object{$_.ad}|Select-Object -Unique)
    if($yazim.Count -lt 2){ continue }
    $buyuk=@($yazim|Where-Object{ $_ -cmatch '^[A-Z][A-Z0-9_]{2,}$' })
    if(-not $buyuk.Count){ continue }
    # kucuk harfli (sabit OLMAYAN) ilk atama satiri
    # ⛔ -notcontains HARF AYIRMAZ! Ilk surumde burasi -notcontains idi:
    #    @('DERS') -notcontains 'ders'  ->  $false  (cunku -contains 'DERS' ile
    #    'ders'i AYNI sayar). Sart hep bosa cikti, kural HICBIR SEY bulmadi.
    #    Yani tuzak nobetcisi 3. TUZAGA KENDI ICINDE dustu. Oz-sinav yakaladi
    #    ("KOTU ornegi YAKALAMADI"); oz-sinav olmasaydi kapi sessizce kor koserdi.
    #    Ders: harf ayrimi gereken her yerde -c'li surum (-ceq/-cnotcontains).
    $ezen=@($l|Where-Object{ $buyuk -cnotcontains $_.ad }|Sort-Object satir|Select-Object -First 1)
    if(-not $ezen.Count){ continue }
    $ezenSatir=$ezen[0].satir
    # sabitin ezilmeden SONRAKI okumasi var mi?
    $sonraOkuma=@($kullanim|Where-Object{
      $_.VariablePath.UserPath -ceq $buyuk[0] -and $_.Extent.StartLineNumber -gt $ezenSatir })
    # ⛔ 12.09 (besinci daraltma): SABIT EZILDIKTEN SONRA YENIDEN ATANDIYSA ZARAR YOK.
    #    kaydir-coz.ps1:337 "$KEY=$env:...; $SBH=@{ apikey=$KEY; ... }" - ayni satirda
    #    once ATIYOR sonra okuyor. Satir numarasina bakan model bunu ayiramaz ve
    #    "eski deger GITTI" der; oysa deger tazelenmis. Sabitin ezilme satirindan
    #    SONRA bir atamasi varsa bulgu RISKLI'ye duser.
    #    (Tam dogru olcum veri akisi analizi ister; bu arac onu yapmaz ve YAPTIGINI
    #     IDDIA ETMEZ - suphede YANLIS ALARM URETMEMEYI secer.)
    $sonraAtama=@($l|Where-Object{ $_.ad -ceq $buyuk[0] -and $_.satir -gt $ezenSatir })
    $agir = ($sonraOkuma.Count -gt 0) -and ($sonraAtama.Count -eq 0)
    $isaret = if($agir){ '🔴 ZARARLI' } else { '⚠ RISKLI' }
    $not = if($agir){ ("sabit satir {0}'de EZILIYOR ve satir {1}'de HALA OKUNUYOR - eski deger GITTI" -f $ezenSatir,$sonraOkuma[0].Extent.StartLineNumber) }
           else { ("sabit satir {0}'de eziliyor ama sonrasinda OKUNMUYOR - bugun zararsiz, ad yine de degistirilmeli" -f $ezenSatir) }
    $ilk=($l|Sort-Object satir|Select-Object -First 1)
    $bul.Add([pscustomobject]@{ satir=$ilk.satir; agir=$agir
      ileti=("{0} DEGISKEN CAKISMASI: {1} · {2} (PS harf AYIRMAZ)" -f $isaret,($yazim -join ' / '),$not) })
  }
  return $bul.ToArray()
}

function K2-JsonDiziSarma($metin,$ast,$dosya){
  # @(Get-Content x | ConvertFrom-Json) -> PS 5.1 diziyi TEK ogeye sarar.  # nobetci:gec
  # Once DEGISKENE alinir, sonra @() ile sarilir.
  $bul=New-Object System.Collections.Generic.List[object]
  # OLCULDU (PS 5.1.26100, bu makine):
  #   @('[{"a":1},{"a":2},{"a":3}]' | ConvertFrom-Json).Count  ->  1   (dogrusu 3)  # nobetci:gec
  #   once degiskene alip @() ile sarinca                      ->  3
  # Yani tuzak GERCEK, varsayim degil.
  foreach($m in [regex]::Matches($metin,'@\(\s*(?:Get-Content|\$[\w]+)[^)]{0,200}?\|\s*ConvertFrom-Json[^)]{0,40}\)')){
    # ⚠ YANLIS ALARM AYIKLAMASI: satir satir JSONL okuyan kalip DOGRUDUR -
    #   @(Get-Content f | % { $_ | ConvertFrom-Json })  burada her satir ayri
    #   nesne, @() dogru sayiyor. Elle bakildi (cila-parti.ps1:181), gercek degil.
    if($m.Value -match 'ForEach-Object|\|\s*%\s*\{'){ continue }
    $satir=($metin.Substring(0,$m.Index) -split "`n").Count
    $bul.Add([pscustomobject]@{ satir=$satir
      ileti='@(... | ConvertFrom-Json): PS 5.1 diziyi TEK ogeye sarar. Once degiskene al, sonra @() ile sar. (arac/olcum-kapilari.ps1 JsonDizi)' })
  }
  return $bul.ToArray()
}

function K3-ListeSarma($metin,$ast,$dosya){
  # @($list) -- $list bir List[object] ise -- tr-TR PS 5.1'de ArgumentException atar.
  # .ToArray() kullanilir. (arac/olcum-kapilari.ps1 Dizi)
  $bul=New-Object System.Collections.Generic.List[object]
  # ⛔ 12.09 DARALTILDI — KURAL KURT MASALI OKUYORDU.
  #    Ilk surum List[<HER TUR>] yakaliyordu. kalip-parti-uret.ps1'e dokununca
  #    7 "ZARARLI" bulgu verdi; altisi da List[string] cikti ve HICBIRI patlamaz.
  #    OLCULDU (tr-TR, PS 5.1.26100) - @($liste) hangi turde patliyor:
  #      List[object]         -> PATLIYOR (ArgumentException)
  #      List[string]         -> calisiyor      List[psobject] -> calisiyor
  #      List[int]            -> calisiyor      List[hashtable] -> calisiyor
  #      List[pscustomobject] -> calisiyor      List[double]/[bool] -> calisiyor
  #    Yani tuzak YALNIZ List[object]'te var. Desen ona daraltildi.
  #    (Ayni ders bugun ucuncu kez: tek olcutlu ikiz kapisi 14'te 3, madde
  #     teshisi iki kez yanlis etiket, simdi bu. Kural yazmak kolay; kuralin
  #     YANLIS ALARMINI olcmek isin asil yarisi.)
  $listeAd=@([regex]::Matches($metin,'\$(\w+)\s*=\s*New-Object\s+System\.Collections\.Generic\.List\[object\]')|ForEach-Object{ $_.Groups[1].Value }|Select-Object -Unique)
  foreach($ad in $listeAd){
    foreach($m in [regex]::Matches($metin,('@\(\s*\$'+[regex]::Escape($ad)+'\s*\)'))){
      $satir=($metin.Substring(0,$m.Index) -split "`n").Count
      $bul.Add([pscustomobject]@{ satir=$satir
        ileti=("LIST SARMA: @(`$$ad) — List[object] tr-TR PS 5.1'de ArgumentException atar. `$$ad.ToArray() kullan.") })
    }
  }
  return $bul.ToArray()
}

function K4-SiralamasizTekSatir($metin,$ast,$dosya){
  # limit=1/2 + order= YOK -> var/yok testi DEGILDIR. Ilk donen baska belge olabilir.
  # 11.09: "492 Harclar ambarda yok" dedim, kanun 240 maddeyle yutulmustu.
  $bul=New-Object System.Collections.Generic.List[object]
  foreach($m in [regex]::Matches($metin,"[^\r\n]*limit=[12]\b[^\r\n]*")){
    $sat=$m.Value
    if($sat -match 'order='){ continue }                     # sirali ise sorun yok
    if($sat -match '^\s*#'){ continue }                       # yorum satiri
    if($sat -notmatch 'rest/v1|supabase'){ continue }         # ambar sorgusu degilse dokunma
    # ⛔ 12.09 DARALTILDI — BU KURAL DA KURT MASALI OKUYORDU.
    #    kalip-parti-uret.ps1:2986 ve :3524 "ZARARLI" bildirildi; ikisi de
    #    `kaynak_ad=eq.<ad>&limit=1` idi. OLCULDU: 3.000 satirlik orneklemde
    #    kaynak_ad TEKIL (3.000 ad / 0 mukerrer). Tekil bir alanda eq.+limit=1
    #    belirli sonuc doner - rastgele secim YOK, kusur da yok.
    #    Tuzak DESEN eslesmesinde: ilike/like/fts bircok satir dondurebilir ve
    #    sirasiz limit=1 onlardan RASTGELE birini alir. '492 Harclar ambarda
    #    yok' yanilgisi tam buydu.
    #    Bu yuzden: desenli sorgu isaretlenir, eq.'li sorgu isaretlenmez.
    if($sat -match '=eq\.' -and $sat -notmatch '=(i?like|fts)'){ continue }
    $satir=($metin.Substring(0,$m.Index) -split "`n").Count
    $bul.Add([pscustomobject]@{ satir=$satir
      ileti="SIRALAMASIZ TEK SATIR: limit=1/2 + order= YOK. Var/yok testi DEGILDIR - ilk donen baska belge olabilir (11.09: '492 ambarda yok' yanilgisi). order= ekle ve limit>=3 yap." })
  }
  return $bul.ToArray()
}

function K5-BomsuzTurkce($metin,$ast,$dosya){
  # PS 5.1 BOM'suz UTF-8'i ANSI sanar -> Turkce iceren .ps1 ayristirilamaz.
  $bul=New-Object System.Collections.Generic.List[object]
  # ⛔ -cmatch ZORUNLU. Ilk surumde -notmatch idi ve kural 104 dosya bildirdi;
  #    olctum, 59'unda TEK BIR TURKCE HARF YOKTU. Sebep 4. TUZAK: -match harf
  #    ayirmaz ve tr-TR kulturunde ASCII 'I' ile 'ı' AYNI harftir. "GERI YUKLEME"
  #    yazan saf ASCII dosya, sinifin icindeki 'ı' yuzunden eslesti.
  #    Yani nobetci, yakalamak icin yazildigi tuzagin KENDISINE dustu (ikinci kez).
  #    Sinif zaten iki yazimi da tasiyor (çğıöşü + ÇĞİÖŞÜ), -cmatch dogru olcum.
  #    Olcum: gercek sayi 104 degil 45.
  if($metin -cnotmatch '[çğıöşüÇĞİÖŞÜ]'){ return $bul.ToArray() }
  $b=[IO.File]::ReadAllBytes($dosya)
  if($b.Length -lt 3 -or -not ($b[0] -eq 239 -and $b[1] -eq 187 -and $b[2] -eq 191)){
    $bul.Add([pscustomobject]@{ satir=1
      ileti='BOM YOK: Turkce iceren .ps1 BOM''lu UTF-8 kaydedilmeli (PS 5.1 ANSI sanar, betik ayristirilamaz).' })
  }
  return $bul.ToArray()
}

$KURALLAR=@(
  @{ ad='K1-CAKISMA';   fn=(Get-Item function:K1-DegiskenCakismasi) }
  @{ ad='K2-JSONDIZI';  fn=(Get-Item function:K2-JsonDiziSarma) }
  @{ ad='K3-LISTSARMA'; fn=(Get-Item function:K3-ListeSarma) }
  @{ ad='K4-SIRASIZ';   fn=(Get-Item function:K4-SiralamasizTekSatir) }
  @{ ad='K5-BOMSUZ';    fn=(Get-Item function:K5-BomsuzTurkce) }
)

# ---------------------------------------------------------------------------
# OZ-SINAV: her kural BILINEN KOTU ve BILINEN IYI ornekle sinanir.
# Kirmizi donerse nobetciye GUVENILMEZ - depo taranmaz.
# ---------------------------------------------------------------------------
function Test-TuzakNobetcisi([switch]$Sessiz2){
  $hata=New-Object System.Collections.Generic.List[string]
  # nobetci:bolge-basla — asagisi BILEREK BOZUK ornek koddur (test verisi).
  #   Gerekce: kendi test fixture'ini kusur diye bildiren kapi gurultu uretir;
  #   bu dort bulgu ilk -Degisen kosusunda tam da boyle cikti.
  $ornek=@(
    # K1 IKI ornekle sinanir: yakalama + AGIRLIK AYRIMI dogru mu?
    #   1) sabit ezildikten SONRA da okunuyor  -> 🔴 ZARARLI  (agirBekle=$true)
    #   2) eziliyor ama bir daha okunmuyor     -> ⚠ RISKLI    (agirBekle=$false)
    # Ikisi de BULGU olmali; ayrim yalniz agirlikta. Yanlis ayrim = kurt masali.
    @{ kural='K1-CAKISMA';   kotu='$DERS=@{a=1}
$ders="x"
$z=$DERS.a';                                    iyi='$DERS_TABLO=@{a=1}
$ders="x"'; agirBekle=$true }
    @{ kural='K1-CAKISMA';   kotu='$DERS=@{a=1}
$ders="x"';                                     iyi='$SABIT_TABLO=@{a=1}
$x="y"'; agirBekle=$false }
    @{ kural='K2-JSONDIZI';  kotu='$x=@(Get-Content a.json | ConvertFrom-Json)'; iyi='$h=Get-Content a.json | ConvertFrom-Json
$x=@($h)' }
    # JSONL kalibi DOGRU - alarm verilmemeli (elle dogrulandi: cila-parti.ps1:181)
    @{ kural='K2-JSONDIZI';  kotu='$x=@($ham | ConvertFrom-Json)'; iyi='$x=@(Get-Content a.jsonl | % { $_ | ConvertFrom-Json })' }
    @{ kural='K3-LISTSARMA'; kotu='$l=New-Object System.Collections.Generic.List[object]
$d=@($l)'; iyi='$l=New-Object System.Collections.Generic.List[object]
$d=$l.ToArray()' }
    # List[string] PATLAMAZ (olculdu) - alarm verilmemeli. 12.09'da bu vaka
    # kalip-parti-uret.ps1'de 6 yanlis alarm uretmisti.
    @{ kural='K3-LISTSARMA'; kotu='$l=New-Object System.Collections.Generic.List[object]
$d=@($l)'; iyi='$l=New-Object System.Collections.Generic.List[string]
$d=@($l)' }
    @{ kural='K4-SIRASIZ';   kotu='$u="https://x.supabase.co/rest/v1/t?select=a&ad=ilike.%25x%25&limit=1"'; iyi='$u="https://x.supabase.co/rest/v1/t?select=a&order=a.asc&limit=5"' }
    # eq. ile TEKIL alan sorgusu belirlidir - alarm verilmemeli (olculdu 12.09:
    # kaynak_ad 3.000 ornekte tekil; kural 2 yanlis alarm uretmisti).
    @{ kural='K4-SIRASIZ';   kotu='$u="https://x.supabase.co/rest/v1/t?select=a&ad=like.x%25&limit=2"'; iyi='$u="https://x.supabase.co/rest/v1/t?select=metin&kaynak_ad=eq.VUK+m.231&limit=1"' }
  )
  # nobetci:bolge-bitir
  $gec=Join-Path $env:TEMP ('tuzak-sinav-'+[guid]::NewGuid().ToString('N')+'.ps1')
  foreach($o in $ornek){
    $k=($KURALLAR|Where-Object{ $_.ad -eq $o.kural }|Select-Object -First 1)
    foreach($tur in @('kotu','iyi')){
      $kod=$o[$tur]
      [IO.File]::WriteAllText($gec,$kod,(New-Object Text.UTF8Encoding $true))
      $a=[System.Management.Automation.Language.Parser]::ParseInput($kod,[ref]$null,[ref]$null)
      $b=@(& $k.fn $kod $a $gec)
      if($tur -eq 'kotu' -and $b.Count -eq 0){ $hata.Add("$($o.kural): KOTU ornegi YAKALAMADI") }
      if($tur -eq 'kotu' -and $b.Count -gt 0 -and $o.ContainsKey('agirBekle')){
        $gercek=[bool]$b[0].agir
        if($gercek -ne [bool]$o.agirBekle){ $hata.Add("$($o.kural): AGIRLIK YANLIS - beklenen $($o.agirBekle), cikan $gercek") }
      }
      if($tur -eq 'iyi'  -and $b.Count -gt 0){ $hata.Add("$($o.kural): IYI ornege YANLIS ALARM verdi -> $($b[0].ileti)") }
    }
  }
  # --- K5 AYRI SINANIR: olcutu dosyanin BAYTLARI, metni degil --------------
  #     Uc vaka: (a) BOM'suz + gercek turkce  -> BULGU
  #              (b) BOM'suz + saf ASCII ama "GERI" gibi I'li  -> BULGU YOK
  #                  (bu vaka 59 yanlis alarmin tamamini uretiyordu)
  #              (c) BOM'lu + turkce  -> BULGU YOK
  $k5=($KURALLAR|Where-Object{ $_.ad -eq 'K5-BOMSUZ' }|Select-Object -First 1)
  $k5Vaka=@(
    @{ ad='BOMsuz+turkce'; kod='$x="baska is"'.Replace('baska','başka'); bom=$false; bekle=$true }
    @{ ad='BOMsuz+ASCII-I'; kod='# GERI YUKLEME ISI'; bom=$false; bekle=$false }
    @{ ad='BOMlu+turkce';  kod='$x="baska is"'.Replace('baska','başka'); bom=$true;  bekle=$false }
  )
  foreach($v in $k5Vaka){
    [IO.File]::WriteAllText($gec,$v.kod,(New-Object Text.UTF8Encoding ([bool]$v.bom)))
    $metin=[IO.File]::ReadAllText($gec,[Text.UTF8Encoding]::new($true))
    $b=@(& $k5.fn $metin $null $gec)
    $var=($b.Count -gt 0)
    if($var -ne [bool]$v.bekle){ $hata.Add("K5-BOMSUZ: $($v.ad) vakasi YANLIS - beklenen bulgu=$($v.bekle), cikan=$var") }
  }

  Remove-Item $gec -Force -ErrorAction SilentlyContinue
  if(-not $Sessiz2){
    if($hata.Count){ Write-Host "⛔ TUZAK NOBETCISI OZ-SINAVI KIRMIZI:" -ForegroundColor Red; foreach($h in $hata.ToArray()){ Write-Host "   - $h" -ForegroundColor Red } }
    else{ Write-Host ("TUZAK NOBETCISI OZ-SINAVI YESIL ({0}/{0} kural · kotu yakalandi, iyiye alarm yok)" -f $ornek.Count) -ForegroundColor Green }
  }
  return ,$hata.ToArray()
}

$sinav=Test-TuzakNobetcisi
if(@($sinav).Count){ throw 'oz-sinav dustu - nobetciye guvenilmez' }

# ---------------------------------------------------------------------------
# TARAMA
# ---------------------------------------------------------------------------
$dosyalar=New-Object System.Collections.Generic.List[string]
if($Yol){ $dosyalar.Add((Resolve-Path $Yol).Path) }
elseif($Degisen){
  # ⚠ git'in stderr'i ($ErrorActionPreference='Stop' altinda) NativeCommandError
  #   atip betigi OLDURUYOR - "LF will be replaced by CRLF" uyarisi bile yetti.
  #   Yerel EAP dusurulur; git'in cikis kodu zaten okunmuyor, liste yeter.
  function GitDosya([string[]]$arg){
    $eskiEAP=$ErrorActionPreference; $ErrorActionPreference='SilentlyContinue'
    try{ return @(& git -C $depoKok @arg 2>$null) } finally{ $ErrorActionPreference=$eskiEAP }
  }
  foreach($s in (GitDosya @('diff','--name-only','HEAD'))){
    if("$s" -match '\.ps1$'){ $t=Join-Path $depoKok "$s"; if(Test-Path $t){ $dosyalar.Add($t) } }
  }
  foreach($s in (GitDosya @('diff','--cached','--name-only'))){
    if("$s" -match '\.ps1$'){ $t=Join-Path $depoKok "$s"; if(Test-Path $t){ $dosyalar.Add($t) } }
  }
  foreach($s in (GitDosya @('ls-files','--others','--exclude-standard'))){
    if("$s" -match '\.ps1$'){ $t=Join-Path $depoKok "$s"; if(Test-Path $t){ $dosyalar.Add($t) } }
  }
}
else{
  foreach($d in @('motor','arac')){
    foreach($x in @(Get-ChildItem (Join-Path $depoKok $d) -Filter '*.ps1' -ErrorAction SilentlyContinue)){ $dosyalar.Add($x.FullName) }
  }
}
$liste=@($dosyalar.ToArray()|Select-Object -Unique)
Write-Host ("taranan dosya: {0}" -f $liste.Count) -ForegroundColor Cyan

$tumBulgu=New-Object System.Collections.Generic.List[object]
foreach($f in $liste){
  $metin=$null
  try{ $metin=[IO.File]::ReadAllText($f,[Text.UTF8Encoding]::new($true)) }catch{ continue }
  $ast=$null
  try{ $ast=[System.Management.Automation.Language.Parser]::ParseInput($metin,[ref]$null,[ref]$null) }catch{ continue }
  # --- SUSTURMA ISARETLERI --------------------------------------------------
  # Nobetcinin KENDI oz-sinav ornekleri bilerek BOZUK koddur; kendi test
  # verisini kusur diye bildiren kapi, ilk gun kapatilan kapidir.
  #   # nobetci:gec                     -> o SATIR atlanir
  #   # nobetci:bolge-basla / -bitir    -> arasindaki satirlar atlanir
  # ⚠ Gerekce ZORUNLU degil ama YAZILIR - susturma sessiz kalirsa kapi corur.
  $satirlar=$metin -split "`r?`n"
  $sus=@{}; $bolge=$false
  for($i=0;$i -lt $satirlar.Count;$i++){
    $s=$satirlar[$i]
    if($s -match 'nobetci:bolge-basla'){ $bolge=$true }
    if($bolge -or $s -match 'nobetci:gec'){ $sus[$i+1]=$true }
    if($s -match 'nobetci:bolge-bitir'){ $bolge=$false }
  }
  foreach($k in $KURALLAR){
    $b=@()
    try{ $b=@(& $k.fn $metin $ast $f) }catch{}
    foreach($x in $b){ if($sus.ContainsKey([int]$x.satir)){ continue }
      $agirMi=$false; if($x.PSObject.Properties['agir']){ $agirMi=[bool]$x.agir } else { $agirMi=$true }
      $tumBulgu.Add([pscustomobject]@{ dosya=(Split-Path $f -Leaf); kural=$k.ad; satir=$x.satir; ileti=$x.ileti; agir=$agirMi }) }
  }
}
$bul=$tumBulgu.ToArray()
$agirSay=@($bul|Where-Object{$_.agir}).Count
Write-Host ("BULGU: {0} · bunlarin {1} tanesi ZARARLI (digerleri riskli ama bugun zararsiz)" -f $bul.Count,$agirSay) -ForegroundColor $(if($agirSay){'Red'}elseif($bul.Count){'Yellow'}else{'Green'})
if($bul.Count){
  Write-Host ""
  foreach($g in ($bul|Group-Object kural|Sort-Object Count -Descending)){ Write-Host ("  {0,-14} {1,4}" -f $g.Name,$g.Count) }
  if(-not $Sessiz){
    Write-Host ""
    foreach($x in ($bul|Sort-Object dosya,satir)){
      Write-Host ("  {0}:{1}  [{2}]" -f $x.dosya,$x.satir,$x.kural) -ForegroundColor Yellow
      Write-Host ("      {0}" -f $x.ileti) -ForegroundColor DarkGray
    }
  }
}
# ⛔ COMMIT'I YALNIZ ZARARLI BULGU DURDURUR. Riskli olanlar uyari kalir -
#    469 dosyalik depoda hepsini durdurmak kapiyi ilk gun kapatirdi.
exit $(if($agirSay){ 1 } else { 0 })
