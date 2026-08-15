# ============================================================================
#  MARKA PORTFOY OTO-DURUM (15.08.2026) - Cem "portfoy oto-durum robotu kur".
#
#  NE: Kullanicinin markalarinin (firmalar.markalar) TURKPATENT'teki DURUMUNU
#  TMview'den her gun cekip bir anlik tabloda (marka_durum) tutar. Durum
#  DEGISINCE (Basvuru->Yayimlandi->Tescilli / ret / devir) ya da YENILEME
#  yaklasinca (tescilli + basvuru+10yil'a <=180 gun) marka_uyari'ya uyari yazar
#  (panel bandi gosterir) + RESEND acikSA mail.
#
#  AD COZUMLEME: marka adini TMview TR'de ara, TAM-AD (Norm) eslesenleri al.
#  Tam 1 eslesme -> guvenle izle. 0 -> sicilde yok. >1 -> belirsiz (no gerekir),
#  uyari YOK (yanlis markayi izlemeyelim - "aman farkli marka" disiplini).
#
#  ENV: SUPABASE_SERVICE_KEY (zorunlu), RESEND_KEY/RESEND_FROM (ops.).
#  TABLO: veri/sql-marka-durum.sql + sql-marka-uyari.sql. Cikti: veri/marka-portfoy-durum-raporu.json
# ============================================================================
param([switch]$kuru, [int]$yenilemeGun = 180)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/marka-portfoy-durum-raporu.json'
function RaporYaz($o){ Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json -InputObject $o -Depth 6) -Encoding UTF8 -NoNewline }
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi (Actions'ta kosar)."; RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='ATLANDI - anahtar yok' }); exit 0 }
$KOK = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1"
$SB  = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function SbGet($yol){ $w=Invoke-WebRequest -Uri "$KOK/$yol" -Headers $SB -UseBasicParsing -TimeoutSec 120 -SkipHttpErrorCheck; $ham=if($w.RawContentStream){[Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())}else{$w.Content}; if([int]$w.StatusCode -ge 400){ throw ("Supabase {0}: {1}" -f $w.StatusCode,$ham) }; return @($ham | ConvertFrom-Json) }
function SbGonder($yol,$metot,$govde,$ekBaslik){ $b=[Text.Encoding]::UTF8.GetBytes(($govde|ConvertTo-Json -Compress -Depth 6)); $bsl=$SB+@{'Content-Type'='application/json'}+$ekBaslik; $w=Invoke-WebRequest -Uri "$KOK/$yol" -Method $metot -Headers $bsl -Body $b -UseBasicParsing -TimeoutSec 60 -SkipHttpErrorCheck; return [int]$w.StatusCode }

function Norm($s){ $s="$s"; $m=@{ ([char]0x00E7)='c'; ([char]0x00C7)='c'; ([char]0x011F)='g'; ([char]0x011E)='g'; ([char]0x0131)='i'; ([char]0x0130)='i'; ([char]0x00F6)='o'; ([char]0x00D6)='o'; ([char]0x015F)='s'; ([char]0x015E)='s'; ([char]0x00FC)='u'; ([char]0x00DC)='u' }; foreach($k in $m.Keys){ $s=$s.Replace([string]$k,$m[$k]) }; return (($s.ToLowerInvariant()) -replace '[^a-z0-9]','') }
$TMV="https://www.tmdn.org/tmview/api/search/results?translate=true"
$TH=@{ "User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126 Safari/537.36"; "Referer"="https://www.tmdn.org/tmview/"; "Content-Type"="application/json"; "Accept"="application/json" }
function TmvTR($terim){ $r=New-Object System.Collections.Generic.List[object]; if(-not $terim){return $r}
  $g=@{ page="1"; pageSize="30"; criteria="C"; basicSearch=$terim; fOffices=@("TR"); sortColumn="applicationDate"; desc=$true; fields=@("ST13","tmName","applicationNumber","applicationDate","tradeMarkStatus","niceClass") } | ConvertTo-Json -Compress
  try{ $w=Invoke-WebRequest -Uri $TMV -Method Post -Headers $TH -Body $g -TimeoutSec 30 -UseBasicParsing; $j=([Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()))|ConvertFrom-Json
    foreach($t in @($j.tradeMarks)){ $r.Add([pscustomobject]@{ st13="$($t.ST13)"; ad="$($t.tmName)"; no="$($t.applicationNumber)"; tarih=(try{([datetime]$t.applicationDate).ToString("dd.MM.yyyy")}catch{""}); durum="$($t.tradeMarkStatus)"; sinif=(@($t.niceClass) -join ',') }) }
  }catch{}
  Start-Sleep -Milliseconds 200; return $r }

$firmalar = SbGet "firmalar?select=id,user_id,email,markalar,kanal&markalar=not.is.null"
$snapshot = @{}
try{ foreach($d in (SbGet "marka_durum?select=user_id,marka,no,durum,st13")){ $snapshot["$($d.user_id)|$($d.marka)"]=$d } }catch{ Write-Host "marka_durum okunamadi (tablo yok olabilir)" }
$simdi=(Get-Date).Date
function DdmmToDate($s){ try{ return [datetime]::ParseExact($s,"dd.MM.yyyy",$null) }catch{ return $null } }

$degisim=New-Object System.Collections.Generic.List[object]; $izlenen=0; $belirsiz=0; $mailKuyruk=@{}
foreach($f in $firmalar){
  foreach($mk in (@($f.markalar) | Where-Object { "$_".Trim() })){
    $nm=Norm $mk; if($nm.Length -lt 2){ continue }
    $tam=@((TmvTR $mk) | Where-Object { (Norm $_.ad) -eq $nm })
    if($tam.Count -ne 1){ $belirsiz++; continue }   # 0=yok / >1=belirsiz -> izleme
    $r=$tam[0]; $izlenen++
    $anahtar="$($f.user_id)|$mk"
    $onceki=$snapshot[$anahtar]
    $uyariMetni=$null; $tip=$null
    if($onceki -and "$($onceki.durum)" -and "$($onceki.durum)" -ne "$($r.durum)"){
      $uyariMetni="durumu degisti: $($onceki.durum) -> $($r.durum)"; $tip="durum-degisikligi"
    }
    # yenileme yaklasti (tescilli + basvuru+10yil'a <= yenilemeGun)
    if(-not $uyariMetni -and $r.durum -match '(?i)regist' ){
      $bt=DdmmToDate $r.tarih
      if($bt){ $bitis=$bt.AddYears(10); $kalan=[int]($bitis-$simdi).TotalDays; if($kalan -le $yenilemeGun -and $kalan -ge -180){ $uyariMetni="yenileme yaklasiyor: koruma bitisi $($bitis.ToString('dd.MM.yyyy')) ($kalan gun)"; $tip="yenileme" } }
    }
    # snapshot upsert (durum guncel tut)
    if(-not $kuru){
      $g=[ordered]@{ user_id="$($f.user_id)"; marka=$mk; no=$r.no; durum=$r.durum; st13=$r.st13; sinif=$r.sinif; guncelleme=(Get-Date -Format 'yyyy-MM-dd') }
      SbGonder "marka_durum?on_conflict=user_id,marka" "Post" $g @{ Prefer='resolution=merge-duplicates,return=minimal' } | Out-Null
    }
    if($uyariMetni){
      $kayit=[ordered]@{ user_id="$($f.user_id)"; marka=$mk; basvuru_no=$r.no; benzer_ad=$uyariMetni; risk=$null; tip=$tip; ofis="TR"; durum=$r.durum; basvuru_tarih=$r.tarih }
      $degisim.Add($kayit)
      if(-not $kuru){ SbGonder "marka_uyari" "Post" ([ordered]@{ user_id=$kayit.user_id; marka=$mk; basvuru_no=("$tip|"+$r.no); benzer_ad=$uyariMetni; risk=$null; sinif_cakisiyor=$false; basvuru_tarih=$r.tarih; durum=$r.durum; tip=$tip; ofis="TR" }) @{ Prefer='return=minimal' } | Out-Null }
      if("$($f.kanal)" -eq 'mail' -and "$($f.email)" -match '^[^@\s]+@[^@\s]+\.[^@\s]+$'){ if(-not $mailKuyruk.ContainsKey("$($f.email)")){ $mailKuyruk["$($f.email)"]=New-Object System.Collections.Generic.List[object] }; $mailKuyruk["$($f.email)"].Add($kayit) }
    }
  }
}
# mail (RESEND acikSA)
$mailAtilan=0
if($env:RESEND_KEY -and -not $kuru){
  $from=if($env:RESEND_FROM){$env:RESEND_FROM}else{'Tetikte <bildirim@tetikte.com>'}
  foreach($mail in $mailKuyruk.Keys){ $liste=$mailKuyruk[$mail]
    $satir=($liste|ForEach-Object{ "<li><b>$($_.marka)</b>: $($_.benzer_ad)</li>" }) -join ""
    $html="<p>Merhaba,</p><p>Portfoyundeki markalarda durum guncellemesi:</p><ul>$satir</ul><p>Panelinden bak: https://tetikte.com/marka-portfoy.html</p><p>Tetikte</p>"
    $body=@{ from=$from; to=@($mail); subject="Marka durum guncellemesi"; html=$html }
    try{ $w=Invoke-WebRequest -Uri "https://api.resend.com/emails" -Method Post -Headers @{ Authorization="Bearer $($env:RESEND_KEY)"; 'Content-Type'='application/json' } -Body ([Text.Encoding]::UTF8.GetBytes(($body|ConvertTo-Json -Compress -Depth 6))) -UseBasicParsing -TimeoutSec 60 -SkipHttpErrorCheck; if([int]$w.StatusCode -lt 400){ $mailAtilan++ } }catch{} }
}
$ozet=[ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod=$(if($kuru){'KURU'}else{'CANLI'}); markali_firma=$firmalar.Count; izlenen_marka=$izlenen; belirsiz_ad=$belirsiz; degisim_uyari=$degisim.Count; mail_atilan=$mailAtilan; resend=[bool]$env:RESEND_KEY; ornekler=@($degisim|Select-Object -First 10); not="Tam-ad eslesen markalarin durumu TMview'den izlendi; degisen ya da yenilemesi yaklasan marka_uyari'ya yazildi. Belirsiz ad (0/>1 eslesme) izlenmedi." }
RaporYaz $ozet
Write-Host ("Izlenen: {0} - belirsiz: {1} - degisim/yenileme uyarisi: {2} - mail: {3}" -f $izlenen,$belirsiz,$degisim.Count,$mailAtilan)
