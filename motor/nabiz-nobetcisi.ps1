# ============================================================================
#  NABIZ NOBETCISI v2 — "her yer kontrollu ve sigortali" (Cem 23.07 + 30.07).
#  IKI KATMAN birden olcer:
#   KATMAN 1 (kosu nabzi): her kritik robotun SON BASARILI kosusunun yasi.
#     Vardiyasini kaciran robot = sessizce olmus robot.
#   KATMAN 2 (veri tazeligi): robotun YAZDIGI dosyadaki tarih damgasi.
#     Cunku "yesil kosu != tam veri" — robot kosar ama yazamazsa
#     kosu nabzi temiz gorunur, veri yine bayatlar. Iki katman birbirini kollar.
#  Alarm: exit 1 (GitHub sahibine hata maili atar) + Resend varsa Resend,
#  yoksa web3forms uzerinden mail (kaynak-nobetcisiyle ayni kanal).
#  Rapor: veri/nabiz-raporu.json (kor kalma — sayi + kisa madde, PII yok).
#  ENV: GH_TOKEN (Actions GITHUB_TOKEN yeter), RESEND_KEY/RESEND_FROM (istege bagli).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$REPO = "cemdizdar85-arch/mevzuat-radar"
$BASLIK = @{ "User-Agent"="tetikte-nabiz" }   # degisken adi $H OLAMAZ (PS buyuk-kucuk ayirmaz, hap $h ile carpisir)
if($env:GH_TOKEN){ $BASLIK["Authorization"] = "Bearer $($env:GH_TOKEN)" }

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$veri = Join-Path $kok "veri"

# ---------------------------------------------------------------------------
# KATMAN 1 — kosu nabzi. dosya-adi -> @(gorunen ad, en fazla kac saat).
# 30.07 duzeltme: eski liste GORUNEN ADLARLA esliyordu ve 3'u yanlisti
# ("Link Nobetcisi" != "Olu Link Nobetcisi") -> o robotlar hep "kosu yok"
# gorunuyordu. Artik DOSYA ADIYLA sorgulaniyor - ad kaymasi imkansiz.
# Cron'u kapali robotlar (gece/soru-uret/sinav-analiz, tasarruf modu) listede
# YOK; cron acilinca buraya da eklenir (kalici sigorta notu).
# ---------------------------------------------------------------------------
$izlenen = [ordered]@{
  "kaynak.yml"        = @("Kaynak Nobetcisi (ihale+kaynaklar)", 30)
  "kartlar.yml"       = @("Hap Kartlar", 30)
  "rg-nobeti.yml"     = @("RG Nobeti", 30)
  "radar.yml"         = @("Gunluk RG Taramasi", 30)
  "mevzuat.yml"       = @("Gunluk Kanun Aynasi", 30)
  "uyari.yml"         = @("Radar Uyari Robotu", 30)
  "kasa-sayim.yml"    = @("Kasa Sayimi (vitrin sayilari)", 30)
  "ambar.yml"         = @("Bilgi Ambari Yukleyici", 30)
  "ders-remap.yml"    = @("Ders Remap", 30)
  "parti-liste.yml"   = @("Parti Listesi", 30)
  "link.yml"          = @("Olu Link Nobetcisi", 30)
  "smoke.yml"         = @("Smoke Nobetcisi", 30)
  "takvim.yml"        = @("Sinav Takvimi Nobetcisi (TESMER PDF)", 30)
  "kalite-tarama.yml" = @("Kasa Kalite Taramasi (haftalik)", 192)
  "yedek.yml"         = @("Haftalik Yedek", 192)
}

$kirmizi = New-Object System.Collections.Generic.List[string]
$simdi = (Get-Date).ToUniversalTime()
foreach($dosya in $izlenen.Keys){
  $ad   = $izlenen[$dosya][0]
  $esik = [double]$izlenen[$dosya][1]
  try {
    $u = "https://api.github.com/repos/$REPO/actions/workflows/$dosya/runs?status=success&per_page=1"
    $r = Invoke-RestMethod -Uri $u -Headers $BASLIK -TimeoutSec 60
    $son = $r.workflow_runs | Select-Object -First 1
    if(-not $son){ $kirmizi.Add("KOSU: $ad -> hic basarili kosu yok"); continue }
    $yas = ($simdi - ([datetime]$son.created_at).ToUniversalTime()).TotalHours
    if($yas -gt $esik){
      $kirmizi.Add(("KOSU: {0} -> son basarili kosu {1:N1} saat once (esik {2}s)" -f $ad, $yas, $esik))
    } else {
      Write-Host ("ok kosu : {0} ({1:N1}s)" -f $ad, $yas)
    }
  } catch { $kirmizi.Add("KOSU: $ad -> API hatasi: $($_.Exception.Message)") }
  Start-Sleep -Milliseconds 250
}

# ---------------------------------------------------------------------------
# KATMAN 2 — veri tazeligi. Dosyadaki tarih damgasi sozlesmeden eskiyse alarm.
# Tarihler TR saatiyle yazilir -> simdiTR ile karsilastirilir.
# Gun-cozunurluklu damgalar (saat yok) icin esik >= 48 saat tutulur.
# ---------------------------------------------------------------------------
$simdiTR = $simdi.AddHours(3)
function TarihYasSaat([string]$s){
  # 'dd.MM.yyyy HH:mm' ya da 'dd.MM.yyyy' kabul eder; parse edilemezse $null
  foreach($f in @('dd.MM.yyyy HH:mm','dd.MM.yyyy')){
    try { $t=[datetime]::ParseExact($s,$f,[Globalization.CultureInfo]::InvariantCulture); return ($simdiTR-$t).TotalHours } catch {}
  }
  return $null
}
function VeriKontrol([string]$dosyaAd, [scriptblock]$damgaAl, [double]$esikSaat, [string]$etiket){
  $yol = Join-Path $veri $dosyaAd
  if(-not (Test-Path $yol)){ $script:kirmizi.Add("VERI: $etiket -> dosya yok ($dosyaAd)"); return }
  try {
    $j = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
    $damga = & $damgaAl $j
    if([string]::IsNullOrWhiteSpace($damga)){ $script:kirmizi.Add("VERI: $etiket -> tarih damgasi BOS ($dosyaAd)"); return }
    $yas = TarihYasSaat $damga
    if($null -eq $yas){ $script:kirmizi.Add("VERI: $etiket -> damga okunamadi: '$damga'"); return }
    if($yas -gt $esikSaat){
      $script:kirmizi.Add(("VERI: {0} -> damga {1} ({2:N0} saat eski; esik {3}s)" -f $etiket, $damga, $yas, $esikSaat))
    } else {
      Write-Host ("ok veri : {0} ({1})" -f $etiket, $damga)
    }
  } catch { $script:kirmizi.Add("VERI: $etiket -> okunamadi: $($_.Exception.Message)") }
}

VeriKontrol "kart-durum.json"    { param($j) $j.sonTarama } 48  "RG tarama damgasi (kart-durum)"
VeriKontrol "uyari-ozet.json"    { param($j) $j.tarih }     30  "Uyari robotu ozeti"
VeriKontrol "vitrin-sayilar.json" { param($j) $j.tarih }    48  "Vitrin kanit sayilari"
VeriKontrol "kalite-tarama.json" { param($j) $j.tarih }     216 "Kasa kalite taramasi (haftalik)"
VeriKontrol "ihale-yurtici.json" { param($j)
  $m=[regex]::Match("$($j.guncelleme)",'Son çekim: (\d{2}\.\d{2}\.\d{4} \d{2}:\d{2})')
  if($m.Success){ $m.Groups[1].Value } else { $null }
} 36 "Yurt ici ihale beslemesi"

# ---------------------------------------------------------------------------
# RAPOR (kor kalma) — her kosuda yazilir; CI always() ile commit'ler.
# ---------------------------------------------------------------------------
$rapor = [ordered]@{
  tarih   = $simdiTR.ToString("dd.MM.yyyy HH:mm")
  durum   = if($kirmizi.Count -eq 0){"TAMAM"}else{"ALARM"}
  kirmizi = $kirmizi.Count
  izlenen_robot = $izlenen.Count
  izlenen_veri  = 5
  maddeler = @($kirmizi)
}
$rapor | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $veri "nabiz-raporu.json") -Encoding UTF8

if($kirmizi.Count -eq 0){ Write-Host "NABIZ TEMIZ: tum robotlar vardiyasinda, tum damgalar taze."; exit 0 }

Write-Host "NABIZ KIRMIZI ($($kirmizi.Count)):"; $kirmizi | ForEach-Object { Write-Host "  $_" }

# --- mail: Resend varsa Resend; yoksa web3forms (kaynak-nobetcisi kanali) ---
$konu = "TETIKTE NABIZ ALARM: $($kirmizi.Count) sorun"
if($env:RESEND_KEY){
  $sat = ($kirmizi | ForEach-Object { "<li>$_</li>" }) -join ""
  $html = "<h3>Nabiz Nobetcisi ALARM</h3><ul>$sat</ul><p>Actions sekmesinden ilgili robotun loguna bak. Tetikte</p>"
  $mb = @{ from=$env:RESEND_FROM; to=@("cemdizdar85@hotmail.com"); subject=$konu; html=$html } | ConvertTo-Json -Depth 3
  try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization="Bearer $($env:RESEND_KEY)" } -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" | Out-Null; Write-Host "MAIL (resend) gonderildi" } catch { Write-Host "resend hatasi: $_" }
} else {
  $mb = @{
    access_key = "5b227e56-94fb-4123-a39a-4286f63db14a"
    subject    = $konu
    from_name  = "Tetikte Nabiz Nobetcisi"
    "Alarmlar" = ($kirmizi -join "`n")
    "Not"      = "Actions sekmesinden ilgili robotun son kosusunun loguna bak."
  } | ConvertTo-Json -Depth 3
  try { Invoke-RestMethod -Method Post -Uri "https://api.web3forms.com/submit" -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" -TimeoutSec 30 | Out-Null; Write-Host "MAIL (web3forms) gonderildi" } catch { Write-Host "web3forms hatasi: $_" }
}
exit 1
