# ============================================================================
#  MARKA PORTFOY HASADI (20.08.2026) - "Firma unvanindan TUM markalari".
#  Cem: "vergi numarasina gore kimin ne kadar markasi var gorebiliyor muyuz?"
#
#  OLCUM (20.08, bu betigin dayanagi):
#   * VERGI NO ile arama YOK (ne TURKPATENT ne TMview vergi no alani sunuyor).
#     Aranabilen alan SAHIP ADI (unvan) -> bu betik unvandan gider.
#   * TMview `fAName` = sahip adi filtresi (dizi = OR). ARCELIK ANONIM SIRKETI
#     -> 1.120 marka, +Registered -> 693. (Marka tarafinda `fApplicantName`
#     SESSIZCE yok sayilir - tasarim/Designs alani; yok sayilan filtre 2,8M
#     sonuc dondurur, "calisti" sanma tuzagi.)
#   * autocomplete/applicantName?text=<ad> -> ayni firmanin YAZIM VARYANTLARI
#     (Arcelik icin 15 tane). Varyantlar OR'lanmazsa portfoy EKSIK cikar.
#   * translate parametresi verilmezse durum INGILIZCE sabit gelir
#     (Filed/Registered/Ended) - robot icin dogrusu bu; Turkceye sayfa cevirir.
#   * TMview CORS'a KAPALI (tetikte.com origin'inden fetch = Failed to fetch)
#     -> tarayici dogrudan soramaz, bu yuzden robot sorar, Supabase'e yazar.
#
#  NE YAPAR:
#   1) UYE firmalari (firmalar.firma_adi) -> portfoyu cek -> marka_portfoy
#      tablosuna yaz; yenilemesine <=180 gun kalan varsa marka_uyari + mail.
#   2) VITRIN talepleri (marka_talep, durum='bekliyor') -> ayni hesabi yap ->
#      sonuc jsonb + durum='hazir'; e-posta birakildiysa raporu mail'le yolla.
#
#  HESAP (SMK m.23): koruma BASVURU tarihinden 10 yil; sonraki donem sonu =
#  basvuru + 10*n (bugunden sonraki ilk). Yenileme talebi son 6 ayda; kacarsa
#  bitisten sonra 6 ay ek sure + ek ucret (m.23/2-3). Yenilenip yenilenmedigini
#  API soylemez -> sicil durumu "Registered" ise onceki donemler yenilenmis
#  kabul edilir, metinde bu VARSAYIM oldugu yazilir (rakam disiplini).
#
#  ENV: SUPABASE_SERVICE_KEY (zorunlu), RESEND_KEY/RESEND_FROM (opsiyonel).
#  TABLO: veri/sql-marka-portfoy.sql (bir kez Supabase SQL Editor'de kosar).
#  CIKTI: veri/marka-portfoy-raporu.json
# ============================================================================
param(
  [switch]$kuru,                 # yazma yok, yalniz olc
  [string]$Unvan = "",           # elle test: tek unvan sorgula, Supabase'e dokunma
  [int]$TalepAdet = 40,          # bir kosuda islenecek bekleyen vitrin talebi
  [int]$MaxKayit = 600,          # unvan basina cekilecek azami marka
  [int]$YenilemeGun = 180,       # kac gun kala uyari (m.23: son 6 ay)
  [int]$BeklemeMs = 200,
  [switch]$YalnizTalep,          # sik kosan kuyruk isleyici (marka-talep.yml, 10 dk)
  [switch]$YalnizUye             # gunluk uye portfoyu tazeleme (kaynak.yml)
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/marka-portfoy-raporu.json'
$simdi = (Get-Date).Date

# --- TMview ----------------------------------------------------------------
$TMV  = "https://www.tmdn.org/tmview/api/search/results"          # translate YOK: durumlar Ingilizce sabit
$TMAC = "https://www.tmdn.org/tmview/api/search/autocomplete/applicantName?text="
$TH = @{ "User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126 Safari/537.36"; "Referer"="https://www.tmdn.org/tmview/"; "Accept"="application/json" }
$ALAN = @("ST13","tmName","applicationNumber","applicationDate","registrationDate","tradeMarkStatus","niceClass","applicantName","oppositionPeriodStart")

function Norm($s){
  $s = "$s"
  $m = @{ ([char]0x00E7)='c'; ([char]0x00C7)='c'; ([char]0x011F)='g'; ([char]0x011E)='g'; ([char]0x0131)='i'; ([char]0x0130)='i'; ([char]0x00F6)='o'; ([char]0x00D6)='o'; ([char]0x015F)='s'; ([char]0x015E)='s'; ([char]0x00FC)='u'; ([char]0x00DC)='u' }
  foreach($k in $m.Keys){ $s = $s.Replace([string]$k, $m[$k]) }
  return (($s.ToLowerInvariant()) -replace '[^a-z0-9]','')
}
# Unvan kuyruklarini at (SANAYI VE TICARET ANONIM SIRKETI vb.) - autocomplete'e
# kisa cekirdek verilir, varyantlari o getirir.
$EKLER = @('anonim sirketi','limited sirketi','sanayi ve ticaret','sanayi ticaret','ticaret limited','ticaret anonim','ithalat ihracat','a s','a.s.','ltd sti','ltd. sti.','ltd','sti','as','anonim','limited','sirketi','sanayi','ticaret','san','tic','holding','group','grup')
# Turkce harfleri ASCII'ye indirger ama BOSLUKLARI korur (kelime bazli ek ayiklama icin).
# NOT: ekler ASCII yazili; unvan "ANONIM SIRKETI" gibi Turkce harfliyse dogrudan
# eslesmez - o yuzden once burada duzlestiriyoruz (ilk surumde bu atlanmisti ve
# cekirdek "arcelik" yerine tum unvan cikip varyantlarin yarisi eleniyordu).
function DuzMetin($s){
  $s = "$s"
  $m = @{ ([char]0x00E7)='c'; ([char]0x00C7)='C'; ([char]0x011F)='g'; ([char]0x011E)='G'; ([char]0x0131)='i'; ([char]0x0130)='I'; ([char]0x00F6)='o'; ([char]0x00D6)='O'; ([char]0x015F)='s'; ([char]0x015E)='S'; ([char]0x00FC)='u'; ([char]0x00DC)='U' }
  foreach($k in $m.Keys){ $s = $s.Replace([string]$k, $m[$k]) }
  return ((($s.ToLowerInvariant()) -replace '[^a-z0-9]',' ') -replace '\s+',' ').Trim()
}
function Cekirdek($unvan){
  $t = " " + (DuzMetin $unvan) + " "
  foreach($e in $EKLER){ $t = $t -replace ("\s" + [regex]::Escape($e) + "\s"), " " }
  $t = ($t -replace '\s+',' ').Trim()
  if(-not $t){ $t = (($unvan -replace '\s+',' ').Trim()) }
  return $t
}
function Jstr($s){ if($null -eq $s){ return '""' }; return (ConvertTo-Json ([string]$s) -Compress) }
# PS 5.1'de (try{...}catch{...}) IFADE olarak kullanilamaz (pwsh 7'de olur) -
# betik hem yerelde (5.1) hem Actions'ta (pwsh) kossun diye tarih cevirisi fonksiyonda.
function DTarih($v){ if(-not $v){ return '' }; try{ return ([datetime]$v).ToString('dd.MM.yyyy') }catch{ return '' } }
function TmvIstek($govdeJson){
  $b = [Text.Encoding]::UTF8.GetBytes($govdeJson)
  $w = Invoke-WebRequest -Uri $TMV -Method Post -Headers $TH -ContentType "application/json" -Body $b -TimeoutSec 60 -UseBasicParsing
  return ([Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) | ConvertFrom-Json)
}
# Sahip adi varyantlari: once tam unvan, bos donerse cekirdek, o da bossa ilk kelime
function Varyantlar($unvan){
  $sonuc = New-Object System.Collections.Generic.List[string]   # cekirdekle BASLAYANLAR (guvenli)
  $yedek = New-Object System.Collections.Generic.List[string]   # cekirdegi iceren ama basta olmayanlar
  $nUnv = Norm $unvan
  $cek  = Cekirdek $unvan
  $adaylar = @($unvan, $cek)
  $ilk = ($cek -split ' ')[0]
  if($ilk.Length -ge 4){ $adaylar += $ilk }
  foreach($sorgu in ($adaylar | Select-Object -Unique)){
    if(-not "$sorgu".Trim()){ continue }
    try{
      $w = Invoke-WebRequest -Uri ($TMAC + [uri]::EscapeDataString($sorgu)) -Headers $TH -TimeoutSec 30 -UseBasicParsing
      $liste = ([Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) | ConvertFrom-Json)
    }catch{ continue }
    foreach($o in @($liste)){
      $ad = "$($o.text)"; if(-not $ad){ continue }
      $nAd = Norm $ad
      # Eslesme disiplini: cekirdek adin varyantta gecmesi SART (yanlis firmayi
      # portfoye koymayalim). Ters yon de kabul (kullanici tam unvan yazdi,
      # sicilde kisa kayitli olabilir).
      $nCek = Norm $cek
      if($nCek.Length -lt 4){ continue }
      # BASLANGIC KURALI: "arcelik as" AL; "elcin arcelik" / "sennur arcelik" ALMA.
      # (Ilk surumde salt icerme vardi ve ayni soyadli KISILER portfoye giriyordu -
      #  yanlis firmanin markasini gostermek en pahali hata.)
      if($nAd.StartsWith($nCek) -or ($nUnv.Length -ge 6 -and $nUnv.StartsWith($nAd) -and $nAd.Length -ge 6)){
        if(-not $sonuc.Contains($ad)){ $sonuc.Add($ad) }
      }
      elseif($nAd.Contains($nCek)){ if(-not $yedek.Contains($ad)){ $yedek.Add($ad) } }
    }
    if($sonuc.Count -ge 25){ break }
    Start-Sleep -Milliseconds $BeklemeMs
  }
  # Hic tam baslangic eslesmesi yoksa (or. "Dizdar Denetim" -> "MEHMET DIZDAR DENETIM")
  # iceren kayitlara dus; aksi halde sonuc bos kalirdi.
  if($sonuc.Count -eq 0 -and $yedek.Count -gt 0){ return @($yedek | Select-Object -First 10) }
  return @($sonuc | Select-Object -First 25)
}
function SahipMarkalari($varyantlar){
  $cikti = New-Object System.Collections.Generic.List[object]
  if(-not $varyantlar -or @($varyantlar).Count -eq 0){ return $cikti }
  $adDizi = '[' + ((@($varyantlar) | ForEach-Object { Jstr $_ }) -join ',') + ']'
  $alanDizi = '[' + ((@($ALAN) | ForEach-Object { Jstr $_ }) -join ',') + ']'
  $sayfa = 1; $gorulen = @{}
  while($true){
    if(($sayfa * 100) -gt $MaxKayit + 100){ break }
    $g = '{"page":"' + $sayfa + '","pageSize":"100","criteria":"C","basicSearch":"","fAName":' + $adDizi + ',"fOffices":["TR"],"sortColumn":"applicationDate","desc":true,"fields":' + $alanDizi + '}'
    try{ $j = TmvIstek $g }catch{ break }
    $kayit = @($j.tradeMarks)
    if($kayit.Count -eq 0){ break }
    foreach($k in $kayit){
      $no = "$($k.applicationNumber)"; if(-not $no -or $gorulen.ContainsKey($no)){ continue }
      $gorulen[$no] = 1
      $cikti.Add([pscustomobject]@{
        ad     = "$($k.tmName)"
        no     = $no
        tarih  = (DTarih $k.applicationDate)
        tescil = (DTarih $k.registrationDate)
        yayim  = (DTarih $k.oppositionPeriodStart)
        durum  = "$($k.tradeMarkStatus)"
        sinif  = ((@($k.niceClass) -join ','))
        sahip  = ((@($k.applicantName) -join ', '))
        st13   = "$($k.ST13)"
      })
      if($cikti.Count -ge $MaxKayit){ break }
    }
    if($cikti.Count -ge $MaxKayit){ break }
    $sayfa++
    Start-Sleep -Milliseconds $BeklemeMs
  }
  return $cikti
}
function DdmmToDate($s){ try{ return [datetime]::ParseExact("$s",'dd.MM.yyyy',$null) }catch{ return $null } }

# --- SMK m.23 hesabi --------------------------------------------------------
#  hal: guvende | yenileme-penceresi | ek-sure | dusmus | surecte | bilinmiyor
function Hesapla($m){
  $bt = DdmmToDate $m.tarih
  $d  = "$($m.durum)"
  $tescilliMi = ($d -match '(?i)regist')                       # Registered
  $bittiMi    = ($d -match '(?i)(ended|expir|withdraw|refus|invalid|surrender)')
  $o = [ordered]@{ hal='bilinmiyor'; donem_sonu=''; kalan_gun=$null; ek_sure_sonu=''; not='' }
  if(-not $bt){ $o.not = 'Basvuru tarihi okunamadi.'; return $o }
  if($bittiMi){ $o.hal='dusmus'; $o.not = 'Sicilde "' + $d + '" gorunuyor - koruma sona ermis.'; return $o }
  # sonraki 10 yillik donem sonu
  $n = 1; while($bt.AddYears(10*$n) -lt $simdi){ $n++ }
  $donemSonu = $bt.AddYears(10*$n)
  $oncekiSonu = $bt.AddYears(10*($n-1))
  $o.donem_sonu = $donemSonu.ToString('dd.MM.yyyy')
  $o.kalan_gun = [int]($donemSonu - $simdi).TotalDays
  $o.ek_sure_sonu = $donemSonu.AddMonths(6).ToString('dd.MM.yyyy')
  if(-not $tescilliMi){
    $o.hal = 'surecte'
    $o.not = 'Basvuru asamasi (sicil durumu: ' + $d + ').'
    if($m.yayim){ $ys = (DdmmToDate $m.yayim); if($ys){ $o.not += ' Bultende yayim ' + $m.yayim + '; ucuncu kisilerin itiraz suresi ' + $ys.AddMonths(2).ToString('dd.MM.yyyy') + ' (m.18).' } }
    return $o
  }
  # tescilli
  if($n -gt 1 -and ([int]($simdi - $oncekiSonu).TotalDays) -le 180){
    $o.hal = 'ek-sure'
    $o.not = 'Koruma donemi ' + $oncekiSonu.ToString('dd.MM.yyyy') + ' tarihinde doldu; sicil hala tescilli gosteriyor. Yenilediysen sonraki bitis ' + $o.donem_sonu + '. Yenilemediysen 6 aylik ek sure ' + $oncekiSonu.AddMonths(6).ToString('dd.MM.yyyy') + ' gunune kadar (ek ucretle, m.23/3) - sicilden teyit et.'
    return $o
  }
  if($o.kalan_gun -le $YenilemeGun){
    $o.hal = 'yenileme-penceresi'
    $o.not = 'Yenileme penceresi ACIK: koruma ' + $o.donem_sonu + ' tarihinde bitiyor (' + $o.kalan_gun + ' gun). Talep son 6 ayda verilir; kacarsan ' + $o.ek_sure_sonu + ' tarihine kadar ek ucretle (m.23).'
    return $o
  }
  $o.hal = 'guvende'
  $o.not = 'Sonraki koruma bitisi ' + $o.donem_sonu + ' (' + $o.kalan_gun + ' gun). Onceki donemler yenilenmis kabul edildi (sicil durumu tescilli).'
  return $o
}
function PortfoyKur($unvan){
  $vars = Varyantlar $unvan
  $mrk  = SahipMarkalari $vars
  $liste = New-Object System.Collections.Generic.List[object]
  foreach($m in $mrk){
    $h = Hesapla $m
    $liste.Add([pscustomobject]@{ ad=$m.ad; no=$m.no; tarih=$m.tarih; sinif=$m.sinif; durum=$m.durum; sahip=$m.sahip; yayim=$m.yayim; hal=$h.hal; donem_sonu=$h.donem_sonu; kalan_gun=$h.kalan_gun; not=$h.not })
  }
  $sirali = @($liste | Sort-Object -Property @{Expression={ switch($_.hal){ 'ek-sure'{0} 'yenileme-penceresi'{1} 'surecte'{2} 'guvende'{3} 'dusmus'{4} default{5} } }}, @{Expression={ if($null -ne $_.kalan_gun){ $_.kalan_gun } else { 99999 } }})
  return [pscustomobject]@{
    unvan       = $unvan
    varyantlar  = @($vars)
    markalar    = $sirali
    sayi        = @($sirali).Count
    tescilli    = @($sirali | Where-Object { $_.durum -match '(?i)regist' }).Count
    yenileme    = @($sirali | Where-Object { $_.hal -eq 'yenileme-penceresi' }).Count
    ek_surede   = @($sirali | Where-Object { $_.hal -eq 'ek-sure' }).Count
    dusmus      = @($sirali | Where-Object { $_.hal -eq 'dusmus' }).Count
    surecte     = @($sirali | Where-Object { $_.hal -eq 'surecte' }).Count
  }
}

# --- ELLE TEST MODU (Supabase'e hic dokunmaz) -------------------------------
if($Unvan){
  $p = PortfoyKur $Unvan
  Write-Host ("UNVAN: {0}" -f $p.unvan)
  Write-Host ("Varyant ({0}): {1}" -f @($p.varyantlar).Count, (@($p.varyantlar) -join ' | '))
  Write-Host ("Marka {0} - tescilli {1} - yenileme penceresi {2} - ek sure {3} - dusmus {4} - surecte {5}" -f $p.sayi,$p.tescilli,$p.yenileme,$p.ek_surede,$p.dusmus,$p.surecte)
  foreach($m in (@($p.markalar) | Select-Object -First 15)){ Write-Host ("  [{0}] {1} ({2}) sinif {3} - {4} - {5}" -f $m.hal,$m.ad,$m.no,$m.sinif,$m.durum,$m.donem_sonu) }
  return
}

# --- Supabase ---------------------------------------------------------------
if(-not $env:SUPABASE_SERVICE_KEY){
  Write-Host "SUPABASE_SERVICE_KEY yok - cikildi (Actions'ta kosar). Elle test: -Unvan 'FIRMA ADI'"
  Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='ATLANDI - anahtar yok' }) -Depth 4) -Encoding UTF8 -NoNewline
  exit 0
}
$KOK = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1"
$SB  = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function SbGet($yol){ $w=Invoke-WebRequest -Uri "$KOK/$yol" -Headers $SB -UseBasicParsing -TimeoutSec 120 -SkipHttpErrorCheck; $ham=if($w.RawContentStream){[Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())}else{$w.Content}; if([int]$w.StatusCode -ge 400){ throw ("Supabase {0}: {1}" -f $w.StatusCode,$ham) }; return @($ham | ConvertFrom-Json) }
function SbGonder($yol,$metot,$govde,$ekBaslik){ $b=[Text.Encoding]::UTF8.GetBytes(($govde|ConvertTo-Json -Compress -Depth 8)); $bsl=$SB+@{'Content-Type'='application/json'}+$ekBaslik; $w=Invoke-WebRequest -Uri "$KOK/$yol" -Method $metot -Headers $bsl -Body $b -UseBasicParsing -TimeoutSec 90 -SkipHttpErrorCheck; if([int]$w.StatusCode -ge 400){ $ham=if($w.RawContentStream){[Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())}else{$w.Content}; Write-Host ("  ! Supabase {0} {1}: {2}" -f $metot,$yol,$ham) }; return [int]$w.StatusCode }

function MailAt($kime,$konu,$html,$duz){
  if(-not $env:RESEND_KEY -or $kuru){ return $false }
  $from = if($env:RESEND_FROM){ $env:RESEND_FROM } else { 'Tetikte <uyari@tetikte.com>' }
  $body = @{ from=$from; to=@($kime); reply_to='cem@dizdardenetim.com'; subject=$konu; html=$html; text=$duz; headers=@{ 'List-Unsubscribe'='<mailto:cem@dizdardenetim.com?subject=iptal>' } }
  try{
    $w = Invoke-WebRequest -Uri 'https://api.resend.com/emails' -Method Post -Headers @{ Authorization=("Bearer " + ("$env:RESEND_KEY" -replace '[^\x21-\x7E]','')); 'Content-Type'='application/json' } -Body ([Text.Encoding]::UTF8.GetBytes(($body|ConvertTo-Json -Compress -Depth 6))) -UseBasicParsing -TimeoutSec 60 -SkipHttpErrorCheck
    return ([int]$w.StatusCode -lt 400)
  }catch{ return $false }
}
function SatirlarHtml($p){
  $s = ""
  foreach($m in (@($p.markalar) | Select-Object -First 40)){
    $etiket = switch($m.hal){ 'ek-sure'{'EK SÜRE'} 'yenileme-penceresi'{'YENİLEME AÇIK'} 'dusmus'{'DÜŞMÜŞ'} 'surecte'{'SÜREÇTE'} default{'güvende'} }
    $s += "<li><b>" + $m.ad + "</b> (" + $m.no + ", sınıf " + $m.sinif + ") — " + $etiket + ($(if($m.donem_sonu){ " · koruma bitişi " + $m.donem_sonu } else { "" })) + "</li>"
  }
  return $s
}

$uyeIslenen = 0; $uyeUyari = 0; $talepIslenen = 0; $mailAtilan = 0; $ornekler = New-Object System.Collections.Generic.List[object]

# --- 1) UYE FIRMALARI -------------------------------------------------------
$firmalar = @()
if(-not $YalnizTalep){ try{ $firmalar = SbGet "firmalar?select=id,user_id,email,firma_adi,kanal&firma_adi=not.is.null" }catch{ Write-Host ("firmalar okunamadi: {0}" -f $_.Exception.Message) }
foreach($f in $firmalar){
  $unv = "$($f.firma_adi)".Trim(); if($unv.Length -lt 3){ continue }
  try{ $p = PortfoyKur $unv }catch{ Write-Host ("  ! {0}: {1}" -f $unv, $_.Exception.Message); continue }
  $uyeIslenen++
  if($ornekler.Count -lt 8){ $ornekler.Add([ordered]@{ unvan=$unv; marka=$p.sayi; yenileme=$p.yenileme; ek_sure=$p.ek_surede; dusmus=$p.dusmus }) }
  if(-not $kuru){
    $kayit = [ordered]@{ user_id="$($f.user_id)"; unvan=$unv; varyantlar=@($p.varyantlar); marka_sayisi=$p.sayi; tescilli=$p.tescilli; yenileme_yakin=$p.yenileme; ek_surede=$p.ek_surede; dusmus=$p.dusmus; markalar=@($p.markalar); guncelleme=(Get-Date).ToString('o') }
    SbGonder "marka_portfoy?on_conflict=user_id,unvan" "Post" $kayit @{ Prefer='resolution=merge-duplicates,return=minimal' } | Out-Null
  }
  # kritik olanlar -> uyari + mail
  $kritik = @($p.markalar | Where-Object { $_.hal -eq 'yenileme-penceresi' -or $_.hal -eq 'ek-sure' })
  foreach($k in $kritik){
    $uyeUyari++
    if(-not $kuru){
      SbGonder "marka_uyari" "Post" ([ordered]@{ user_id="$($f.user_id)"; marka=$k.ad; basvuru_no=("portfoy-yenileme|" + $k.no); benzer_ad=$k.not; risk=$null; sinif_cakisiyor=$false; basvuru_tarih=$k.tarih; durum=$k.durum; tip='portfoy-yenileme'; ofis='TR' }) @{ Prefer='return=minimal' } | Out-Null
    }
  }
  if($kritik.Count -gt 0 -and "$($f.kanal)" -eq 'mail' -and "$($f.email)" -match '^[^@\s]+@[^@\s]+\.[^@\s]+$'){
    $satir = ($kritik | ForEach-Object { "<li><b>" + $_.ad + "</b> (" + $_.no + "): " + $_.not + "</li>" }) -join ""
    $duz   = ($kritik | ForEach-Object { "- " + $_.ad + " (" + $_.no + "): " + $_.not }) -join "`n"
    $html  = "<p>Merhaba,</p><p><b>" + $unv + "</b> adına sicilde görünen markalardan " + $kritik.Count + " tanesinin yenileme tarihi yaklaştı:</p><ul>" + $satir + "</ul><p>Yenileme talebi koruma bitişinden önceki 6 ay içinde verilir; kaçırılırsa 6 ay ek süre + ek ücret (SMK m.23). Panelden bak: https://tetikte.com/marka-portfoy.html</p><p>Tetikte</p><p style='color:#888;font-size:12px'>Bu maili marka radarı aboneliğin için alıyorsun; kapatmak için bu maile 'iptal' yanıtı ver.</p>"
    if(MailAt $f.email ("Marka yenileme uyarısı - " + $unv) $html ("Merhaba,`n`n" + $unv + " adına markalarında yenileme tarihi yaklaşan " + $kritik.Count + " kayıt var:`n" + $duz + "`n`nYenileme talebi bitişten önceki 6 ayda verilir; kaçarsa 6 ay ek süre + ek ücret (SMK m.23).`nPanel: https://tetikte.com/marka-portfoy.html`n`nTetikte`nKapatmak için bu maile 'iptal' yanıtı ver.")){ $mailAtilan++ }
  }
}

}   # <- if(-not $YalnizTalep)

# --- 2) VITRIN TALEPLERI ----------------------------------------------------
$talepler = @()
if(-not $YalnizUye){
try{ $talepler = SbGet ("marka_talep?select=id,jeton,unvan,email&durum=eq.bekliyor&order=created_at.asc&limit=" + $TalepAdet) }catch{ Write-Host ("marka_talep okunamadi (tablo yok olabilir): {0}" -f $_.Exception.Message) }
foreach($t in $talepler){
  $unv = "$($t.unvan)".Trim()
  $sonucJson = $null; $hata = $null
  try{ $p = PortfoyKur $unv }catch{ $hata = $_.Exception.Message; $p = $null }
  if($p){
    $sonucJson = [ordered]@{ unvan=$p.unvan; varyantlar=@($p.varyantlar); sayi=$p.sayi; tescilli=$p.tescilli; yenileme=$p.yenileme; ek_surede=$p.ek_surede; dusmus=$p.dusmus; surecte=$p.surecte; markalar=@($p.markalar | Select-Object -First 200) }
  }
  $talepIslenen++
  if(-not $kuru){
    $govde = [ordered]@{ durum=$(if($hata){'hata'}else{'hazir'}); sonuc=$sonucJson; hata=$hata; islendi_at=(Get-Date).ToString('o') }
    SbGonder ("marka_talep?jeton=eq." + [uri]::EscapeDataString("$($t.jeton)")) "Patch" $govde @{ Prefer='return=minimal' } | Out-Null
  }
  if($p -and "$($t.email)" -match '^[^@\s]+@[^@\s]+\.[^@\s]+$'){
    $html = "<p>Merhaba,</p><p><b>" + $unv + "</b> için sicil taraması hazır: <b>" + $p.sayi + " marka</b> bulundu (" + $p.tescilli + " tescilli, " + $p.yenileme + " yenileme penceresi açık, " + $p.dusmus + " düşmüş).</p><ul>" + (SatirlarHtml $p) + "</ul><p>Tamamı ve tarih takvimi: https://tetikte.com/marka-portfoy.html?jeton=" + $t.jeton + "</p><p>Kaynak: TÜRKPATENT verisi (TMview). Koruma süresi başvurudan 10 yıl, yenileme son 6 ayda (SMK m.23). Sicil kaydını teyit etmeden işlem yapma.</p><p>Tetikte</p><p style='color:#888;font-size:12px'>Bu maili tetikte.com'da marka sorgusu yaptığın için alıyorsun; kapatmak için bu maile 'iptal' yanıtı ver.</p>"
    $duz  = "Merhaba,`n`n" + $unv + " icin sicil taramasi hazir: " + $p.sayi + " marka (" + $p.tescilli + " tescilli, " + $p.yenileme + " yenileme penceresi acik, " + $p.dusmus + " dusmus).`nTamami: https://tetikte.com/marka-portfoy.html?jeton=" + $t.jeton + "`n`nKaynak: TURKPATENT verisi (TMview). Koruma basvurudan 10 yil, yenileme son 6 ayda (SMK m.23).`n`nTetikte`nKapatmak icin bu maile 'iptal' yaniti ver."
    if(MailAt $t.email ("Marka taraması hazır - " + $unv) $html $duz){ $mailAtilan++ }
  }
}
}   # <- if(-not $YalnizUye)

$ozet = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  mod = $(if($kuru){'KURU'}else{'CANLI'})
  uye_firma = $uyeIslenen
  uye_yenileme_uyarisi = $uyeUyari
  vitrin_talebi = $talepIslenen
  mail = $mailAtilan
  resend = [bool]$env:RESEND_KEY
  ornekler = @($ornekler)
  not = "Unvan -> TMview autocomplete varyantlari -> fAName (OR) -> TR marka portfoyu. Koruma bitisi basvuru+10*n (SMK m.23); tescilli kayitta onceki donemler yenilenmis kabul edilir."
}
Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json -InputObject $ozet -Depth 6) -Encoding UTF8 -NoNewline
Write-Host ("Uye firma: {0} - yenileme uyarisi: {1} - vitrin talebi: {2} - mail: {3}" -f $uyeIslenen,$uyeUyari,$talepIslenen,$mailAtilan)
