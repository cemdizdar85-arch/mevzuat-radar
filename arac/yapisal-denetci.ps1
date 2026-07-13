# ============================================================================
#  YAPISAL DENETCI  (Katman 1 — kalici sigorta)
#  Amac: "dogru cevabi bilmeye gerek olmadan" IMKANSIZ/CELISKILI veriyi yakalamak.
#  Her push'ta CI'da kosar; bir ihlal -> exit 1 (deploy durur, Cem'e gorunur).
#  Bu turda bulunan iki KRITIK hata (damping %1200, kurk over-claim) bu tur
#  kurallarla ONCEDEN yakalanirdi. Kural "cevap" degil YAPI dener -> zehirlenemez.
#
#  Ekleme kurali: yeni kural = yeni Kontrol satiri. Kural, veriden BAGIMSIZ bir
#  dogruyu ifade etmeli (oran araligi, monotonluk, "haric => kismi" gibi).
# ============================================================================
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$veri = Join-Path $kok "veri"

$hatalar = New-Object System.Collections.Generic.List[string]
$uyarilar = New-Object System.Collections.Generic.List[string]
function Hata($m){ $script:hatalar.Add($m) }
function Uyari($m){ $script:uyarilar.Add($m) }
function asArr($x){ if($null -eq $x){ return @() }; if($x -is [array]){ return $x }; return @($x) }
function Yukle($ad){
  $p = Join-Path $veri $ad
  if(-not (Test-Path $p)){ Hata "$ad : DOSYA YOK"; return $null }
  try { return (Get-Content $p -Raw -Encoding UTF8 | ConvertFrom-Json) }
  catch { Hata "$ad : JSON PARSE HATASI — $($_.Exception.Message)"; return $null }
}
function Say($x){ # kultur-bagimsiz sayi (virgul ondalik -> nokta, InvariantCulture ile parse)
  if($x -is [double] -or $x -is [int] -or $x -is [long] -or $x -is [decimal]){ return [double]$x }
  $s = "$x" -replace '\s','' -replace '%','' -replace ',','.'
  $d = 0.0
  if([double]::TryParse($s,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$d)){ return $d }
  return $null
}
function Sentinel($t){ return ("$t" -match '^__.+__$') }  # __yok__/__pharma__/__tekstil__ = kod DEGIL, ozel isaretci
$KDV_GECERLI = @(1,10,20)   # Turkiye KDV oranlari (2023 sonrasi): baska deger IMKANSIZ

Write-Host "== YAPISAL DENETCI ==" -ForegroundColor Cyan

# --- 0) TUM veri/*.json parse edilebiliyor mu (kesik/bozuk dosya) ---
Get-ChildItem $veri -Filter *.json | ForEach-Object {
  try { Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null }
  catch { Hata "$($_.Name) : GECERSIZ JSON — $($_.Exception.Message)" }
}

# --- 1) KDV ---
$KDV = Yukle "gtip-kdv.json"
if($KDV){
  $g = Say $KDV.genelOran
  if($null -eq $g -or -not ($KDV_GECERLI -contains [int]$g)){ Hata "gtip-kdv.json : genelOran '$($KDV.genelOran)' KDV ORANI DEGIL (beklenen 1/10/20)" }
  foreach($fp in $KDV.fasil.PSObject.Properties){
    $f = $fp.Name
    if($f -notmatch '^\d{2}$'){ Hata "gtip-kdv.json : fasil anahtari '$f' 2-hane degil" }
    foreach($grup in @('o1','o10')){
      foreach($h in (asArr $fp.Value.$grup)){
        foreach($pz in (asArr $h.poz)){ if((Sentinel $pz)){ continue }; if("$pz" -notmatch '^\d{4}$'){ Hata "gtip-kdv.json fasil $f/$grup : poz '$pz' 4-hane degil" } }
        foreach($kd in (asArr $h.kod)){ if((Sentinel $kd)){ continue }; if("$kd" -notmatch '^\d{6,12}$'){ Hata "gtip-kdv.json fasil $f/$grup : kod '$kd' 6-12 hane rakam degil" } }
        if($h.PSObject.Properties.Name -contains 'kosul' -and $h.kosul -isnot [bool]){ Hata "gtip-kdv.json fasil $f/$grup : kosul bool degil" }
        if($h.PSObject.Properties.Name -contains 'tumF'  -and $h.tumF  -isnot [bool]){ Hata "gtip-kdv.json fasil $f/$grup : tumF bool degil" }
      }
    }
  }
}

# --- 2) OTV (KURK-SINIFI KURAL burada) ---
$OTV = Yukle "gtip-otv.json"
if($OTV){
  $listeGecerli = @('I','II','III','IV')
  foreach($pp in $OTV.pozisyon.PSObject.Properties){
    $poz = $pp.Name; $rec = $pp.Value
    if($poz -notmatch '^\d{2}$' -and $poz -notmatch '^\d{4}$'){ Hata "gtip-otv.json : pozisyon anahtari '$poz' 2/4-hane degil" }
    if($rec.liste -and -not ($listeGecerli -contains "$($rec.liste)")){ Hata "gtip-otv.json $poz : liste '$($rec.liste)' I/II/III/IV degil" }
    # KURK KURALI: kapsamNot'ta DISLAMA ('haric'/'disi') gecen kayit, kod beyaz-listesi
    # VEYA kismi:true tasimali. Yoksa router DISLANAN kodlari 'OTV var' gosterir (over-claim).
    $kn = "$($rec.kapsamNot)"
    if($kn -match '(?i)(hariç|haric|dışı|disi|dışıdır|disidir|DIŞ)'){
      $kodVar = (asArr $rec.kod).Count -gt 0
      $kismi  = ($rec.PSObject.Properties.Name -contains 'kismi' -and $rec.kismi -eq $true)
      if(-not $kodVar -and -not $kismi){
        Hata "gtip-otv.json $poz : kapsamNot DISLAMA iceriyor ama 'kod' beyaz-listesi de 'kismi:true' de YOK -> over-claim riski (kurk-sinifi)"
      }
    }
    foreach($kd in (asArr $rec.kod)){ if((Sentinel $kd)){ continue }; if("$kd" -notmatch '^\d{4,12}$'){ Hata "gtip-otv.json $poz : kod '$kd' gecersiz" } }
  }
}

# --- 3) GECIKME ZAMMI ---
$GZ = Yukle "gecikme-zammi.json"
if($GZ){
  $a = Say $GZ.aylik
  if($null -eq $a -or $a -le 0 -or $a -ge 20){ Hata "gecikme-zammi.json : aylik '$($GZ.aylik)' makul araligin (0-20) disinda" }
  if("$($GZ.tarih)" -notmatch '^\d{2}\.\d{2}\.\d{4}$'){ Hata "gecikme-zammi.json : tarih '$($GZ.tarih)' gg.aa.yyyy degil" }
}

# --- 4) VERGI SABITLERI ---
$VS = Yukle "vergi-sabitleri.json"
if($VS){
  # GV dilimleri: esikler artan, oranlar artan, oran 0-45
  $dil = asArr $VS.gvDilimler
  $onEsik = -1.0; $onOran = -1.0
  for($i=0; $i -lt $dil.Count; $i++){
    $esik = $dil[$i][0]; $oran = Say $dil[$i][1]
    if($null -eq $oran -or $oran -lt 0 -or $oran -gt 45){ Hata "vergi-sabitleri.json gvDilimler[$i] : oran '$oran' 0-45 disinda" }
    elseif($oran -le $onOran){ Hata "vergi-sabitleri.json gvDilimler[$i] : oran artmiyor ($onOran -> $oran)" }
    $onOran = $oran
    if($null -ne $esik){ $e = Say $esik; if($e -le $onEsik){ Hata "vergi-sabitleri.json gvDilimler[$i] : esik artmiyor ($onEsik -> $e)" }; $onEsik = $e }
  }
  foreach($n in @('kvOran')){ $v = Say $VS.$n; if($null -ne $v -and ($v -lt 0 -or $v -gt 45)){ Hata "vergi-sabitleri.json $n : '$v' 0-45 disinda" } }
  if($VS.kvOranlari){ foreach($kp in $VS.kvOranlari.PSObject.Properties){ if($kp.Name -eq 'not'){ continue }; $v = Say $kp.Value; if($null -ne $v -and ($v -lt 0 -or $v -gt 45)){ Hata "vergi-sabitleri.json kvOranlari.$($kp.Name) : '$v' 0-45 disinda" } } }
  $ps = Say $VS.karPayiStopaj; if($null -ne $ps -and ($ps -lt 0 -or $ps -gt 30)){ Hata "vergi-sabitleri.json karPayiStopaj : '$ps' 0-30 disinda" }
  # Asgari ucret ic tutarlilik
  $au = $VS.asgariUcret2026
  if($au){
    $brut = Say $au.brutAylik; $net = Say $au.netAylik
    $taban = Say $au.sgkTabanAylik; $tavan = Say $au.sgkTavanAylik
    if($null -ne $brut -and $null -ne $net -and $net -ge $brut){ Hata "vergi-sabitleri.json asgariUcret : netAylik ($net) brutAylik ($brut) tutarindan kucuk olmali - imkansiz" }
    if($null -ne $taban -and $null -ne $tavan){
      if($tavan -le $taban){ Hata "vergi-sabitleri.json asgariUcret : sgkTavan ($tavan) sgkTaban ($taban) tutarindan kucuk/esit - imkansiz" }
      else {
        $kat = [math]::Round($tavan / $taban, 3)
        # SGK tavani = taban x KAT (5510 m.82; 7,5 idi, 7566 s.K. ile 01.01.2026 -> 9).
        # DERS: kanuni sabiti koda GOMME (eskir). Bunun yerine: (a) akil-sagligi bandi 7-9,5,
        # (b) NOTUN soyledigi 'X kat' ile gercek orani karsilastir -> not+sayi birlikte guncellenmezse yakalar.
        if($kat -lt 7 -or $kat -gt 9.5){ Hata "vergi-sabitleri.json asgariUcret : sgkTavan/sgkTaban orani $kat, makul bandin (7 - 9,5 kat) disinda. Tavan veya taban YANLIS." }
        else {
          $mn = [regex]::Match("$($au.not)", '(\d+[.,]?\d*)\s*kat')
          if($mn.Success){
            $notKat = Say $mn.Groups[1].Value
            if($null -ne $notKat -and [math]::Abs($notKat - $kat) -gt 0.05){ Hata "vergi-sabitleri.json asgariUcret : NOT '$notKat kat' diyor ama sgkTavan/sgkTaban orani $kat - not veya sayi guncellenmemis (celisik)." }
          }
        }
      }
    }
    if($null -ne $brut -and $null -ne $taban -and [math]::Abs($brut - $taban) -gt 1){ Uyari "vergi-sabitleri.json asgariUcret : brutAylik ($brut) ile sgkTabanAylik ($taban) esit degil - genelde esittir, teyit et" }
  }
  # Kidem tavani: yil ikinci yarisi ilk yarisindan buyuk/esit (memur katsayisi artar)
  $kt = $VS.kidemTazminatiTavani2026
  if($kt){ $o = Say $kt.ocakHaziran; $t = Say $kt.temmuzAralik; if($null -ne $o -and $null -ne $t -and $t -lt $o){ Hata "vergi-sabitleri.json kidemTavani : temmuzAralik ($t) < ocakHaziran ($o) — imkansiz" } }
}

# --- 5) CVOA (royalti/faiz stopaj ust siniri) ---
$CV = Yukle "cvoa-oranlar.json"
if($CV -and $CV.ulkeler){
  foreach($up in $CV.ulkeler.PSObject.Properties){
    foreach($alan in @('r','f')){
      if($up.Value.PSObject.Properties.Name -contains $alan){
        $v = Say $up.Value.$alan
        if($null -eq $v -or $v -lt 0 -or $v -gt 30){ Hata "cvoa-oranlar.json $($up.Name).$alan : '$($up.Value.$alan)' 0-30 disinda (CVOA stopaj ust siniri)" }
      }
    }
  }
}

# --- 6) DAMPING (metin alani; imkansiz-% sizinti taramasi — UYARI) ---
$DP = Yukle "gtip-damping.json"
if($DP){
  foreach($r in (asArr $DP)){
    $t = "$($r.t)"
    foreach($m in [regex]::Matches($t, '%\s*(\d+[.,]?\d*)')){
      $v = Say $m.Groups[1].Value
      if($null -ne $v -and $v -gt 500){ Uyari "gtip-damping.json k=$($r.k) : '$($m.Value)' %500 ustu - spesifik vergi (dolar/ton) yanlislikla yuzde mi okundu? teyit et" }
    }
  }
}

# --- 7) BIRINCIL KAYNAK ZORLAMASI (Kural 1: yalniz resmi kaynak; ikincil YASAK) ---
# Cem kurali: veri HEP birincilden (resmigazete.gov.tr / mevzuat.gov.tr / gib.gov.tr /
# ticaret.gov.tr / sgk.gov.tr). Ikincil (KPMG, muhasebe siteleri, wiki) teyit icin bile YASAK.
$ikincilKaynaklar = @('kpmg','deloitte','pwc','pricewaterhouse','ernst&young','verginet','muhasebetr','muhasebenews','bloomberght','ekonomist.com','wikipedia')
$resmiIsaret = '(?i)(resm[iî]\s*gazete|\bRG\b|say[iı]l[iı]|gib|gov\.tr|\bmadde\b|\bm\.\s*\d|tebli[gğ]|kanun|karar|BKK)'
Get-ChildItem $veri -Filter *.json | ForEach-Object {
  $metin = Get-Content $_.FullName -Raw -Encoding UTF8
  foreach($k in $ikincilKaynaklar){
    if($metin.ToLower().Contains($k.ToLower())){ Hata "$($_.Name) : IKINCIL KAYNAK '$k' geciyor - Kural 1 ihlali. Bu veri gercek birincilden (RG/mevzuat.gov.tr/GIB) teyit edilip damga degistirilmeli." }
  }
}
# Kritik sayisal dosyalar birincil DAMGA tasimali (kaynak/not alaninda resmi isaret)
if($GZ -and "$($GZ.kaynak)" -notmatch $resmiIsaret){ Hata "gecikme-zammi.json : kaynak alaninda birincil isaret (RG/GIB/sayili/madde) YOK" }
if($VS){
  $vsKaynak = "$($VS.kaynaklar | ConvertTo-Json -Depth 6)" + "$($VS.asgariUcret2026.not)" + "$($VS.kvOranlari.not)"
  if($vsKaynak -notmatch $resmiIsaret){ Hata "vergi-sabitleri.json : kaynak/not metninde birincil isaret YOK" }
}
if($OTV -and "$($OTV.guncelleme)" -notmatch $resmiIsaret){ Hata "gtip-otv.json : guncelleme (kaynak damgasi) alaninda birincil isaret YOK" }
if($KDV -and "$($KDV.guncelleme)" -notmatch $resmiIsaret){ Hata "gtip-kdv.json : guncelleme (kaynak damgasi) alaninda birincil isaret YOK" }
if($CV  -and "$($CV.kaynak)"      -notmatch $resmiIsaret){ Hata "cvoa-oranlar.json : kaynak damgasi alaninda birincil isaret YOK" }

# --- 8) KRITIK JS DUZELTME KAYNAK-ISARETCISI (port-test JS'i dogrudan korumaz; bu korur) ---
# Bu turda duzeltilen JS bug'lari geri alinirsa yakala. Isaretci = duzeltmenin karakteristik kod parcasi.
$kritikDuzeltmeler = @(
  @{ dosya='senaryo-raporu.html'; isaret=@('spesifik','match(/%'); ac='damping dolar/ton->yuzde bug fix (spesifik ayrimi)' }
  @{ dosya='gtip.html';           isaret=@('rec.kismi','Array.isArray(rad)'); ac='kurk kismi + radar normalize' }
)
foreach($kd in $kritikDuzeltmeler){
  $yol = Join-Path $kok $kd.dosya
  if(-not (Test-Path $yol)){ Hata "$($kd.dosya) : DOSYA YOK"; continue }
  $icerik = Get-Content $yol -Raw -Encoding UTF8
  foreach($mark in $kd.isaret){
    if(-not $icerik.Contains($mark)){ Hata "$($kd.dosya) : KRITIK DUZELTME ISARETCISI '$mark' YOK -> $($kd.ac) geri alinmis olabilir (regresyon)" }
  }
}

# ---------------------------------------------------------------------------
""
if($uyarilar.Count -gt 0){
  Write-Host "UYARILAR ($($uyarilar.Count)):" -ForegroundColor Yellow
  $uyarilar | ForEach-Object { Write-Host "   ? $_" -ForegroundColor Yellow }
  ""
}
if($hatalar.Count -gt 0){
  Write-Host "!!! YAPISAL DENETCI: $($hatalar.Count) IHLAL — deploy durdu:" -ForegroundColor Red
  $hatalar | ForEach-Object { Write-Host "   X $_" -ForegroundColor Red }
  exit 1
}
Write-Host "YAPISAL DENETCI: tum kurallar temiz." -ForegroundColor Green
