# ============================================================================
#  UYARI ROBOTU (#44 push) — her firmayı profiline göre tarar, YENİ eşleşmeyi
#  firma_uyarilari'na yazar; e-posta varsa Resend ile bildirir.
#  Kaynaklar: veri/ihale-yurtici.json (il) + veri/kartlar-guncel.json (GTİP).
#  ENV: SUPABASE_SERVICE_KEY (zorunlu), RESEND_KEY + RESEND_FROM (opsiyonel).
#  Secret yoksa zarifçe atlar (exit 0). GitHub Actions cron ile günlük.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok — uyari robotu atlandi. (GitHub Settings -> Secrets)"; exit 0 }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY"; "Content-Type"="application/json" }

function GtipNorm($s){ if($null -eq $s){ return "" }; return ([regex]::Replace("$s",'[^\d]','')) }
function GtipEslesir($fk,$kk){ $a=GtipNorm $fk; $b=GtipNorm $kk; if($a.Length -lt 4 -or $b.Length -lt 4){ return $false }; $k=[Math]::Min($a.Length,$b.Length); return ($a.Substring(0,$k) -eq $b.Substring(0,$k)) }
function TrUp($s){ if($null -eq $s){ return "" }; return (("$s" -replace 'i','İ' -replace 'ı','I').ToUpper()) }

# --- veri kaynaklari ---
$ihale = @(); try { $ihale = (Get-Content (Join-Path $kok "veri\ihale-yurtici.json") -Raw -Encoding UTF8 | ConvertFrom-Json).ilanlar } catch {}
$kartlar = @(); try { $kartlar = (Get-Content (Join-Path $kok "veri\kartlar-guncel.json") -Raw -Encoding UTF8 | ConvertFrom-Json).kartlar } catch {}

# --- firmalar (service role RLS'i bypass eder) ---
$firmalar = Invoke-RestMethod -Method Get -Uri "$SB_URL/rest/v1/firmalar?select=*" -Headers $H -TimeoutSec 90
if(-not $firmalar){ Write-Host "Firma yok."; exit 0 }

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
  if($ilU){ foreach($x in $ihale){ if((TrUp $x.il) -eq $ilU){
    $bas = "$($x.baslik)"; $bulunan += @{ tur="ihale"; baslik=$bas; detay=("$($x.kurum) · $($x.il) · $($x.tarih)"); url=$x.url; onem="orta" }
  } } }
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

if($yeni.Count -eq 0){ Write-Host "Yeni uyari yok."; exit 0 }

# --- toplu yaz ---
$body = ($yeni | ConvertTo-Json -Depth 5)
if($yeni.Count -eq 1){ $body = "[$body]" }
Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/firma_uyarilari" -Headers $H -Body ([Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 90 | Out-Null
Write-Host ("Yazilan yeni uyari: {0}" -f $yeni.Count)

# --- mail (Resend, opsiyonel) ---
$RK = $env:RESEND_KEY; $RF = $env:RESEND_FROM
if($RK -and $RF){
  $sent=0
  foreach($fid in $mailKuyruk.Keys){
    $m = $mailKuyruk[$fid]; if(-not $m.satirlar.Count){ continue }
    $html = "<h2>Radar uyariniz — $($m.ad)</h2><p>Firmanizi ilgilendiren yeni gelismeler:</p><p>" + ($m.satirlar -join "<br>") + "</p><p><a href='https://cemdizdar85-arch.github.io/mevzuat-radar/radar-app.html'>Panele git &rarr;</a></p><p style='color:#888;font-size:12px'>Mevzuat Radari — bir Dizdar Denetim A.S. yazilimidir.</p>"
    $mb = @{ from=$RF; to=@($m.email); subject="Radar: firmanizi ilgilendiren $($m.satirlar.Count) yeni gelisme"; html=$html } | ConvertTo-Json -Depth 4
    try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization="Bearer $RK"; "Content-Type"="application/json" } -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -TimeoutSec 60 | Out-Null; $sent++ } catch { Write-Host "Mail hata ($($m.email)): $($_.Exception.Message)" }
  }
  Write-Host ("Gonderilen mail: {0}" -f $sent)
} else { Write-Host "RESEND_KEY/FROM yok — mail atlandi (uyarilar panoda gorunur)." }
