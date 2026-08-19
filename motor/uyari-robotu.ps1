# ============================================================================
#  UYARI ROBOTU (#44 push) — her firmayı profiline göre tarar, YENİ eşleşmeyi
#  firma_uyarilari'na yazar; e-posta varsa Resend ile bildirir.
#  Kaynaklar: veri/ihale-yurtici.json (il) + veri/kartlar-guncel.json (GTİP).
#  ENV: SUPABASE_SERVICE_KEY (zorunlu), RESEND_KEY + RESEND_FROM (opsiyonel).
#  Secret yoksa zarifçe atlar (exit 0). GitHub Actions cron ile günlük.
# ============================================================================
$ErrorActionPreference = "Stop"
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

# KOR KALMA KURALI (30.07): kosu iz birakmali - yesil bitip sessiz kalmak yok.
# veri/uyari-ozet.json YALNIZ SAYI tasir (depo public; e-posta/VKN asla girmez).
$ozetYol = Join-Path $kok "veri/uyari-ozet.json"
function OzetYaz($n){ [IO.File]::WriteAllText($ozetYol, (ConvertTo-Json -InputObject $n -Depth 4), (New-Object Text.UTF8Encoding($false))) }
trap {
  OzetYaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="HATA"
    hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message)
  exit 1
}

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){
  OzetYaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="ATLANDI"; not="SUPABASE_SERVICE_KEY yok" })
  Write-Host "SUPABASE_SERVICE_KEY yok — uyari robotu atlandi. (GitHub Settings -> Secrets)"; exit 0
}
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY"; "Content-Type"="application/json" }

function GtipNorm($s){ if($null -eq $s){ return "" }; return ([regex]::Replace("$s",'[^\d]','')) }
function GtipEslesir($fk,$kk){ $a=GtipNorm $fk; $b=GtipNorm $kk; if($a.Length -lt 4 -or $b.Length -lt 4){ return $false }; $k=[Math]::Min($a.Length,$b.Length); return ($a.Substring(0,$k) -eq $b.Substring(0,$k)) }
# 30.07 TURKIYE-I TUZAGI DUZELTMESI: -replace buyuk/kucuk DUYARSIZDIR ve
# invariant kulturde 'i' deseni 'I'yi de yakalar - il eslesmesi bulutta
# sessizce sapabilirdi. Denetcideki ders (yapisal-denetci TrKucuk) kardes
# betige uygulandi: -creplace (duyarli) + ToUpperInvariant.
function TrUp($s){ if($null -eq $s){ return "" }; return (("$s" -creplace 'i','İ' -creplace 'ı','I').ToUpperInvariant()) }

# 30.07: ilan.gov.tr akisi ihale-DISI kayit da tasir (mahkeme/icra/tebligat).
# Panel bunlari eliyor; robot elemeden "ihale" diye uyari yazamaz - uyeye
# durusma ilanini ihale diye mail atmak guven oldurur. Panelle AYNI liste.
$IHALE_DISI = @('durusma','duruşma','tebligat','tebliğ','ilanen','mahkeme','icra','cekilis','çekiliş','genel kurul','kayyim','kayyım','iflas','konkordato','veraset')
function IhaleMi($x){
  $t = ("$($x.baslik) $($x.kurum)").ToLowerInvariant()
  foreach($kelime in $IHALE_DISI){ if($t.Contains($kelime)){ return $false } }
  return $true
}

# --- veri kaynaklari ---
$ihale = @(); try { $ihale = (Get-Content (Join-Path $kok "veri\ihale-yurtici.json") -Raw -Encoding UTF8 | ConvertFrom-Json).ilanlar } catch {}
$kartlar = @(); try { $kartlar = (Get-Content (Join-Path $kok "veri\kartlar-guncel.json") -Raw -Encoding UTF8 | ConvertFrom-Json).kartlar } catch {}
# 30.07 (#63): yapilandirma/af firsat penceresi - RG tarayicisi yazar
$firsatlar = @(); try { $firsatlar = @((Get-Content (Join-Path $kok "veri\firsat-guncel.json") -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler) } catch {}

# 30.07 (#64): ayni ilan akisindaki ICRA SATISLARI ihale-disi copten FIRSATA
# doner - sektorundeki makine/stok/tasinmaz icradan ucuza. Ele listesindeki
# oteki turler (durusma/tebligat/veraset...) firsat DEGILDIR, girmez.
function IcraSatisMi($x){
  $t = ("$($x.baslik) $($x.kurum)").ToLowerInvariant()
  foreach($k in @('icra','açık artırma','açik artirma','acik artirma')){ if($t.Contains($k)){ return $true } }
  return $false
}

# --- firmalar (service role RLS'i bypass eder) ---
# 30.07 PS TUZAGI: @(IRM ...) diziyi tek nesne sarar (N firma = "1 firma"
# gorunur, uyeler karisir). Once ata, sonra sar.
$firmalarHam = Invoke-RestMethod -Method Get -Uri "$SB_URL/rest/v1/firmalar?select=*" -Headers $H -TimeoutSec 90
$firmalar = @($firmalarHam)
if(-not $firmalar.Count){
  OzetYaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="TAMAM"; firma=0; yeni_uyari=0
    not="Henuz firma eklenmemis - panelden '+ Firma ekle' ile baslanir."
    veri=[ordered]@{ rg_karti=@($kartlar).Count; ihale_ilani=@($ihale).Count } })
  Write-Host "Firma yok."; exit 0
}

# --- mevcut uyarilar (tekrar yazmamak icin anahtar seti) ---
$mevcut = @{}
try {
  $ex = Invoke-RestMethod -Method Get -Uri "$SB_URL/rest/v1/firma_uyarilari?select=firma_id,tur,baslik" -Headers $H -TimeoutSec 90
  foreach($u in @($ex)){ $mevcut["$($u.firma_id)|$($u.tur)|$($u.baslik)"] = $true }
} catch {}

$yeni = New-Object System.Collections.Generic.List[object]
$mailKuyruk = @{}   # firma_id -> @{email; ad; satirlar}

foreach($f in $firmalar){
  $bulunan = @()
  # 1) IHALE (il)
  $ilU = TrUp $f.il
  if($ilU){ foreach($x in $ihale){ if((IhaleMi $x) -and (TrUp $x.il) -eq $ilU){
    $bas = "$($x.baslik)"; $bulunan += @{ tur="ihale"; baslik=$bas; detay=("$($x.kurum) · $($x.il) · $($x.tarih)"); url=$x.url; onem="orta" }
  } } }
  # 1b) FIRSAT-ICRA (#64): ildeki icra satislari - ucuza varlik firsati
  if($ilU){ foreach($x in $ihale){ if((IcraSatisMi $x) -and (TrUp $x.il) -eq $ilU){
    $bulunan += @{ tur="firsat-icra"; baslik="$($x.baslik)"; detay=("İcradan satış fırsatı: $($x.kurum) · $($x.tarih) — ucuza varlık, ilana bak"); url=$x.url; onem="orta" }
  } } }
  # 1c) FIRSAT (#63): yapilandirma/af penceresi - TUM uyelere, profil sarti yok
  foreach($fm in $firsatlar){
    $bulunan += @{ tur="firsat"; baslik="$($fm.baslik)"; detay="Yapılandırma/af penceresi açıldı — başvuru süresi kaçırılmamalı, ayrıntı kaynakta."; url=$fm.url; onem="yuksek" }
  }
  # 2) RG KARTI (GTIP)
  foreach($k in $kartlar){ foreach($fk in @($f.gtip_kodlari)){ $eslesti=$false
    foreach($kk in @($k.gtip)){ if(GtipEslesir $fk $kk){ $eslesti=$true; break } }
    if($eslesti){
      $onem = if("$($k.etki)" -match "aleyhine"){ "yuksek" } else { "orta" }
      $bulunan += @{ tur="rg"; baslik="$($k.baslik)"; detay=("$($k.ne_oldu)"); url=$k.url; onem=$onem }
      break
    } } }
  # yalniz YENI olanlari kuyruga al
  foreach($b in $bulunan){
    $ak = "$($f.id)|$($b.tur)|$($b.baslik)"
    if($mevcut.ContainsKey($ak)){ continue }
    $mevcut[$ak] = $true
    $yeni.Add([ordered]@{ firma_id=$f.id; user_id=$f.user_id; tur=$b.tur; baslik=$b.baslik; detay=$b.detay; url=$b.url; onem=$b.onem })
    if($f.email){
      if(-not $mailKuyruk.ContainsKey($f.id)){ $mailKuyruk[$f.id] = @{ email=$f.email; ad=$f.firma_adi; satirlar=@() } }
      $mailKuyruk[$f.id].satirlar += "• [$($b.tur.ToUpper())] $($b.baslik)"
    }
  }
}

if($yeni.Count -eq 0){
  OzetYaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="TAMAM"; firma=$firmalar.Count; yeni_uyari=0
    not="Bugun yeni eslesme yok - mukerrer kilidi eskiyi tekrar yazmaz."
    veri=[ordered]@{ rg_karti=@($kartlar).Count; ihale_ilani=@($ihale).Count } })
  Write-Host "Yeni uyari yok."; exit 0
}

# --- toplu yaz ---
$body = ($yeni | ConvertTo-Json -Depth 5)
if($yeni.Count -eq 1){ $body = "[$body]" }
Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/firma_uyarilari" -Headers $H -Body ([Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 90 | Out-Null
Write-Host ("Yazilan yeni uyari: {0}" -f $yeni.Count)

# --- mail (Resend, opsiyonel) ---
$RK = ("$env:RESEND_KEY" -replace '[^\x21-\x7E]',''); $RF = $env:RESEND_FROM
if($RK -and $RF){
  $sent=0
  foreach($fid in $mailKuyruk.Keys){
    $m = $mailKuyruk[$fid]; if(-not $m.satirlar.Count){ continue }
    $html = "<h2>Radar uyariniz — $($m.ad)</h2><p>Firmanizi ilgilendiren yeni gelismeler:</p><p>" + ($m.satirlar -join "<br>") + "</p><p><a href='https://tetikte.com/radar-app.html'>Panele git &rarr;</a></p><p style='color:#888;font-size:12px'>Tetikte — bir Dizdar Denetim A.S. yazilimidir.</p>"
    $mb = @{ from=$RF; to=@($m.email); reply_to="cem@dizdardenetim.com"; subject="Radar: firmanizi ilgilendiren $($m.satirlar.Count) yeni gelisme"; html=$html } | ConvertTo-Json -Depth 4
    try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization="Bearer $RK"; "Content-Type"="application/json" } -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -TimeoutSec 60 | Out-Null; $sent++ } catch { Write-Host "Mail hata ($($m.email)): $($_.Exception.Message)" }
  }
  Write-Host ("Gonderilen mail: {0}" -f $sent)
} else { $sent = 0; Write-Host "RESEND_KEY/FROM yok — mail atlandi (uyarilar panoda gorunur)." }

OzetYaz ([ordered]@{
  tarih = (Get-Date -Format "dd.MM.yyyy HH:mm"); durum = "TAMAM"
  firma = $firmalar.Count; yeni_uyari = $yeni.Count; mail_gonderilen = $sent
  mail_notu = if($RK -and $RF){ "RESEND takili" } else { "RESEND anahtari yok - uyarilar panele yazildi, mail atlandi" }
  veri = [ordered]@{ rg_karti = @($kartlar).Count; ihale_ilani = @($ihale).Count }
})
Write-Host ("TAMAM: {0} firma, {1} yeni uyari." -f $firmalar.Count, $yeni.Count)
