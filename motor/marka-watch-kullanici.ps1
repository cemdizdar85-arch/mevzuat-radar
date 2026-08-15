# ============================================================================
#  MARKA WATCH - KULLANICI (15.08.2026) - Cem "#4 per-user otomatik watch + mail".
#
#  NE: Her kullanicinin panele girdigi markalarini (firmalar.markalar) son
#  gunlerin TR basvurularina (veri/marka-yeni-basvurular.json) karsi benzerlik
#  motorundan gecirir; YENI benzer basvuru cikaninca marka_uyari tablosuna yazar
#  (panel gosterir) ve (RESEND acikSA) kullaniciya mail atar. Boylece kullanici
#  "senin markana benzer basvuru dustu" uyarisini kendisi bilmeden alir.
#
#  DEDUP: ayni (user, marka, basvuru_no) icin ikinci kez uyari YAZILMAZ/mail atilmaz.
#  ESIK: yalnizca isaret >= $esikIsaret ve (sinif cakisiyor ya da bilinmiyor) -
#  yuksek isabet; kullaniciyi gurultuye bogmayiz (SMK m.6: farkli sinif zayif).
#
#  ENV: SUPABASE_SERVICE_KEY (firmalar oku + marka_uyari yaz). RESEND_KEY/RESEND_FROM
#  (opsiyonel - yoksa mail atlanir, uyari yine panele yazilir). Mail YALNIZ kanal
#  'mail' olan + gecerli e-postali kullaniciya (mail politikasi).
#  TABLO: veri/sql-marka-uyari.sql (once calistirilmali).
#  Cikti: veri/marka-watch-raporu.json (GM gozetimi).
# ============================================================================
param([switch]$kuru, [int]$esikIsaret = 65)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/marka-watch-raporu.json'
function RaporYaz($o){ Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json -InputObject $o -Depth 6) -Encoding UTF8 -NoNewline }

if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi (bu robot Actions'ta kosar)."; RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='ATLANDI - anahtar yok' }); exit 0 }
$KOK = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1"
$SB  = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
function SbGet($yol){ $w=Invoke-WebRequest -Uri "$KOK/$yol" -Headers $SB -UseBasicParsing -TimeoutSec 120 -SkipHttpErrorCheck; $ham=if($w.RawContentStream){[Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())}else{$w.Content}; if([int]$w.StatusCode -ge 400){ throw ("Supabase {0}: {1}" -f $w.StatusCode,$ham) }; return @($ham | ConvertFrom-Json) }
function SbPost($yol,$govde){ $b=[Text.Encoding]::UTF8.GetBytes(($govde|ConvertTo-Json -Compress -Depth 6)); $w=Invoke-WebRequest -Uri "$KOK/$yol" -Method Post -Headers ($SB+@{'Content-Type'='application/json';Prefer='return=minimal'}) -Body $b -UseBasicParsing -TimeoutSec 60 -SkipHttpErrorCheck; return [int]$w.StatusCode }

# --- benzerlik motoru (marka-izleme.html ile ayni mantik, PS'e portlu) ------
function Norm($s){ $s="$s"; $m=@{ ([char]0x00E7)='c'; ([char]0x00C7)='c'; ([char]0x011F)='g'; ([char]0x011E)='g'; ([char]0x0131)='i'; ([char]0x0130)='i'; ([char]0x00F6)='o'; ([char]0x00D6)='o'; ([char]0x015F)='s'; ([char]0x015E)='s'; ([char]0x00FC)='u'; ([char]0x00DC)='u' }; foreach($k in $m.Keys){ $s=$s.Replace([string]$k,$m[$k]) }; return (($s.ToLowerInvariant()) -replace '[^a-z0-9]','') }
function Fon($s){ $s=Norm $s; $s=$s -replace '[iy]','i' -replace '[uv]','u' -replace '[kq]','k' -replace '[sz]','s' -replace '[cj]','c' -replace 'ph','f'; return ($s -replace '(.)\1+','$1') }
function Lev($a,$b){ $m=$a.Length; $n=$b.Length; if($m -eq 0){return $n}; if($n -eq 0){return $m}; $p=0..$n; for($i=1;$i -le $m;$i++){ $prev=$p[0]; $p[0]=$i; for($j=1;$j -le $n;$j++){ $t=$p[$j]; $c=if($a[$i-1] -eq $b[$j-1]){0}else{1}; $p[$j]=[Math]::Min([Math]::Min($p[$j]+1,$p[$j-1]+1),$prev+$c); $prev=$t } }; return $p[$n] }
function Benz($a,$b){ if(-not $a -or -not $b){return 0}; return [Math]::Round((1-(Lev $a $b)/[Math]::Max($a.Length,$b.Length))*100) }
# TMview canli sorgu (uluslararasi #7): terim + ofisler -> benzer kayitlar
$TMV = "https://www.tmdn.org/tmview/api/search/results?translate=true"
$TH  = @{ "User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126 Safari/537.36"; "Referer"="https://www.tmdn.org/tmview/"; "Content-Type"="application/json"; "Accept"="application/json" }
function TmvAra($terim,$ofisler){
  $sonuc = New-Object System.Collections.Generic.List[object]
  if(-not $terim -or $terim.Length -lt 2){ return $sonuc }
  $govde = @{ page="1"; pageSize="30"; criteria="C"; basicSearch=$terim; fOffices=@($ofisler); fields=@("tmName","applicationNumber","applicationDate","tradeMarkStatus","niceClass","office") } | ConvertTo-Json -Compress
  try{
    $w = Invoke-WebRequest -Uri $TMV -Method Post -Headers $TH -Body $govde -TimeoutSec 30 -UseBasicParsing
    $j = ([Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())) | ConvertFrom-Json
    foreach($t in @($j.tradeMarks)){
      $td = try{ ([datetime]$t.applicationDate).ToString("dd.MM.yyyy") }catch{ "" }
      $sonuc.Add([pscustomobject]@{ ad="$($t.tmName)"; no="$($t.applicationNumber)"; tarih=$td; durum="$($t.tradeMarkStatus)"; ofis="$($t.office)" })
    }
  }catch{}
  Start-Sleep -Milliseconds 200
  return $sonuc
}

# --- son basvurular indeksi (kompakt dizi) ---------------------------------
$idxYol = Join-Path $kok 'veri/marka-yeni-basvurular.json'
if(-not (Test-Path $idxYol)){ Write-Host "marka-yeni-basvurular.json yok - once marka-izleme-hasat"; RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='INDEKS YOK' }); exit 0 }
$idx = Get-Content $idxYol -Raw -Encoding UTF8 | ConvertFrom-Json
$kol = @($idx.kolon); $iAd=$kol.IndexOf('ad');$iNo=$kol.IndexOf('no');$iTr=$kol.IndexOf('tarih');$iSn=$kol.IndexOf('sinif');$iSa=$kol.IndexOf('sahip');$iDu=$kol.IndexOf('durum');$iYa=$kol.IndexOf('yayim')
$basvurular = @($idx.basvurular | ForEach-Object { [pscustomobject]@{ ad=$_[$iAd]; no=$_[$iNo]; tarih=$_[$iTr]; sinif=(("$($_[$iSn])").Split(',')|Where-Object{$_}); sahip=$_[$iSa]; durum=$_[$iDu]; yayim=$_[$iYa]; nAd=(Norm $_[$iAd]); fAd=(Fon $_[$iAd]) } })
Write-Host ("Indeks: {0} basvuru" -f $basvurular.Count)

# --- kullanici firmalari + markalari ---------------------------------------
$firmalar = SbGet "firmalar?select=id,user_id,email,firma_adi,markalar,sinif,kanal&markalar=not.is.null"
Write-Host ("Markali firma kaydi: {0}" -f $firmalar.Count)
# zaten gonderilmis uyarilar (dedup)
$gonderilmis = @{}
try{ foreach($u in (SbGet "marka_uyari?select=user_id,marka,basvuru_no")){ $gonderilmis["$($u.user_id)|$($u.marka)|$($u.basvuru_no)"]=$true } }catch{ Write-Host ("marka_uyari okunamadi (tablo yok olabilir): {0}" -f $_.Exception.Message) }

$yeniUyari = New-Object System.Collections.Generic.List[object]
$mailKuyruk = @{}
foreach($f in $firmalar){
  $markalar = @($f.markalar) | Where-Object { "$_".Trim() }
  $ksin = @("$($f.sinif)".Split(',') | Where-Object { $_ -match '^\d+$' })
  foreach($mk in $markalar){
    $nm = Norm $mk; $fm = Fon $mk; if($nm.Length -lt 2){ continue }
    # --- TR: yerel indekse karsi ---
    foreach($x in $basvurular){
      $yazim = Benz $nm $x.nAd; $fonetik = Benz $fm $x.fAd; $isaret = [Math]::Max($yazim,$fonetik)
      if($isaret -lt $esikIsaret){ continue }
      $cak = if($ksin.Count -and $x.sinif.Count){ [bool](@($ksin | Where-Object { $x.sinif -contains $_ }).Count) } else { $null }
      if($cak -eq $false){ continue }   # farkli sinif = zayif, uyari atma
      $anahtar = "$($f.user_id)|$mk|$($x.no)"
      if($gonderilmis.ContainsKey($anahtar)){ continue }
      $risk = if($cak -eq $true){ $isaret } else { [Math]::Round($isaret*0.85) }
      $kayit = [ordered]@{ user_id="$($f.user_id)"; email="$($f.email)"; firma="$($f.firma_adi)"; marka=$mk; basvuru_no="$($x.no)"; benzer_ad=$x.ad; risk=$risk; isaret=$isaret; sinif_cak=$cak; basvuru_tarih=$x.tarih; durum=$x.durum; tip="benzer-tr"; ofis="TR" }
      $yeniUyari.Add($kayit); $gonderilmis[$anahtar]=$true
      if("$($f.kanal)" -eq 'mail' -and "$($f.email)" -match '^[^@\s]+@[^@\s]+\.[^@\s]+$'){ if(-not $mailKuyruk.ContainsKey("$($f.email)")){ $mailKuyruk["$($f.email)"]=New-Object System.Collections.Generic.List[object] }; $mailKuyruk["$($f.email)"].Add($kayit) }
    }
    # --- #7 ULUSLARARASI: TMview'de EM(EUIPO)+WO(WIPO) canli sorgu (marka basina) ---
    foreach($x in (TmvAra $mk @("EM","WO"))){
      $yazim = Benz $nm (Norm $x.ad); $fonetik = Benz $fm (Fon $x.ad); $isaret=[Math]::Max($yazim,$fonetik)
      if($isaret -lt $esikIsaret){ continue }
      $anahtar = "$($f.user_id)|$mk|$($x.no)"
      if($gonderilmis.ContainsKey($anahtar)){ continue }
      $kayit = [ordered]@{ user_id="$($f.user_id)"; email="$($f.email)"; firma="$($f.firma_adi)"; marka=$mk; basvuru_no="$($x.no)"; benzer_ad=$x.ad; risk=$isaret; isaret=$isaret; sinif_cak=$null; basvuru_tarih=$x.tarih; durum=$x.durum; tip="benzer-intl"; ofis=$x.ofis }
      $yeniUyari.Add($kayit); $gonderilmis[$anahtar]=$true
      if("$($f.kanal)" -eq 'mail' -and "$($f.email)" -match '^[^@\s]+@[^@\s]+\.[^@\s]+$'){ if(-not $mailKuyruk.ContainsKey("$($f.email)")){ $mailKuyruk["$($f.email)"]=New-Object System.Collections.Generic.List[object] }; $mailKuyruk["$($f.email)"].Add($kayit) }
    }
  }
}
Write-Host ("Yeni uyari: {0} - mail kuyrugu: {1} kullanici" -f $yeniUyari.Count, $mailKuyruk.Count)

# --- uyarilari marka_uyari'ya yaz (panel gosterir) -------------------------
$yazildi=0; $yaziHata=0
if(-not $kuru){
  foreach($u in $yeniUyari){
    $govde = [ordered]@{ user_id=$u.user_id; marka=$u.marka; basvuru_no=$u.basvuru_no; benzer_ad=$u.benzer_ad; risk=$u.risk; sinif_cakisiyor=[bool]($u.sinif_cak -eq $true); basvuru_tarih=$u.basvuru_tarih; durum=$u.durum; tip=$u.tip; ofis=$u.ofis }
    $sc = SbPost "marka_uyari" $govde
    if($sc -ge 400){ $yaziHata++ } else { $yazildi++ }
  }
}

# --- mail (RESEND acikSA; yoksa atla, uyari yine panelde) ------------------
$mailAtilan=0
if($env:RESEND_KEY -and -not $kuru){
  $from = if($env:RESEND_FROM){ $env:RESEND_FROM } else { 'Tetikte <bildirim@tetikte.com>' }
  foreach($mail in $mailKuyruk.Keys){
    $liste = $mailKuyruk[$mail]
    $satir = ($liste | ForEach-Object { "<li><b>$($_.marka)</b> markana benzer: <b>$($_.benzer_ad)</b> (basvuru $($_.basvuru_no), $($_.basvuru_tarih), risk %$($_.risk)$(if($_.sinif_cak -eq $true){', sinif cakisiyor'})).</li>" }) -join ""
    $html = "<p>Merhaba,</p><p>Izledigimiz markalarina benzer <b>$($liste.Count)</b> yeni basvuru TURKPATENT'e dustu:</p><ul>$satir</ul><p>Detay ve itiraz suresi icin panelinden bak: https://tetikte.com/marka-izleme.html · Itiraz suresi yayimdan 2 aydir (SMK m.18).</p><p>Tetikte</p>"
    $body = @{ from=$from; to=@($mail); subject=("Marka izleme: {0} yeni benzer basvuru" -f $liste.Count); html=$html }
    try{ $w=Invoke-WebRequest -Uri "https://api.resend.com/emails" -Method Post -Headers @{ Authorization="Bearer $($env:RESEND_KEY)"; 'Content-Type'='application/json' } -Body ([Text.Encoding]::UTF8.GetBytes(($body|ConvertTo-Json -Compress -Depth 6))) -UseBasicParsing -TimeoutSec 60 -SkipHttpErrorCheck; if([int]$w.StatusCode -lt 400){ $mailAtilan++ } }catch{}
  }
} else { Write-Host "RESEND_KEY yok - mail atlandi (uyarilar panelde gorunur)." }

$ozet = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod=$(if($kuru){'KURU'}else{'CANLI'})
  markali_firma=$firmalar.Count; indeks_basvuru=$basvurular.Count; esik_isaret=$esikIsaret
  yeni_uyari=$yeniUyari.Count; panele_yazildi=$yazildi; yazi_hata=$yaziHata
  mail_kullanici=$mailKuyruk.Count; mail_atilan=$mailAtilan; resend=[bool]$env:RESEND_KEY
  ornekler=@($yeniUyari | Select-Object -First 10)
  not="Yeni benzer basvuru marka_uyari'ya yazildi (panel gosterir); RESEND acikSA mail de atildi. Dedup: (user,marka,basvuru_no)."
}
RaporYaz $ozet
Write-Host ("`n-> {0}" -f $raporYol)
Write-Host ("panele yazilan uyari: {0} - mail: {1} - resend: {2}" -f $yazildi, $mailAtilan, [bool]$env:RESEND_KEY)
