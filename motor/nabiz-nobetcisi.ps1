# ============================================================================
#  NABIZ NOBETCISI v3 — olcer + KENDI KURTARIR (Cem 31.07: "kosmama sansi
#  olmamasi lazim; surekli hatayla ben ugrasamam, en iyi onlemi al").
#  KATMAN 1 (kosu nabzi): kritik robotun son BASARILI kosusunun yasi.
#  KATMAN 2 (veri tazeligi): robotun yazdigi dosyadaki tarih damgasi
#     ("yesil kosu != tam veri" dersi).
#  v3 YENILIK — KURTARMA ZINCIRI: vardiyayi kacirani sadece raporlamaz,
#  workflow_dispatch ile ANINDA kosturur. Basarili kurtarma SESSIZDIR
#  (rapora yazilir, mail yok, kosu yesil biter). Yalniz su hallerde
#  KIRMIZI + mail: (a) dispatch basarisiz, (b) ESKALASYON - onceki
#  yoklamada kurtarma denendigi halde ayni madde HALA bayat (makine
#  cozemedi, insan baksin).
#  Alarm kanali: Resend varsa Resend, yoksa web3forms. Rapor:
#  veri/nabiz-raporu.json (kor kalma; sayi + kisa madde, PII yok).
#  ENV: GH_TOKEN (dispatch icin actions:write izni sart), RESEND_KEY/FROM.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$REPO = "cemdizdar85-arch/mevzuat-radar"
$BASLIK = @{ "User-Agent"="tetikte-nabiz"; "Accept"="application/vnd.github+json" }   # degisken adi $H OLAMAZ
if($env:GH_TOKEN){ $BASLIK["Authorization"] = "Bearer $($env:GH_TOKEN)" }

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$veri = Join-Path $kok "veri"
$raporYol = Join-Path $veri "nabiz-raporu.json"

# onceki yoklamada kurtarma denenen maddeler (eskalasyon tespiti icin)
$onceKurtarilan = @()
if(Test-Path $raporYol){
  try { $eski = Get-Content $raporYol -Raw -Encoding UTF8 | ConvertFrom-Json
        if($eski.kurtarilan_anahtar){ $onceKurtarilan = @($eski.kurtarilan_anahtar) } } catch {}
}

$kirmizi    = New-Object System.Collections.Generic.List[string]
$kurtarilan = New-Object System.Collections.Generic.List[string]
$kurtAnahtar= New-Object System.Collections.Generic.List[string]

function KurtarWorkflow([string]$dosya, [string]$ad){
  # zaten kuyrukta/kosuyorsa ikinci kez tetikleme (cift kosu yasagi)
  foreach($st in @("queued","in_progress")){
    try {
      $r = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/actions/workflows/$dosya/runs?status=$st&per_page=1" -Headers $BASLIK -TimeoutSec 60
      if(@($r.workflow_runs).Count -gt 0){ return "zaten-kosuyor" }
    } catch {}
  }
  try {
    Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/$REPO/actions/workflows/$dosya/dispatches" `
      -Headers $BASLIK -Body '{"ref":"main"}' -ContentType "application/json" -TimeoutSec 60 | Out-Null
    return "tetiklendi"
  } catch { return "DISPATCH-HATA: $($_.Exception.Message)" }
}

function KacirmaIsle([string]$anahtar, [string]$dosya, [string]$ad, [string]$neden){
  # eskalasyon: onceki yoklamada da kurtarilmisti ve hala bayat -> insan baksin
  if($onceKurtarilan -contains $anahtar){
    $script:kirmizi.Add("ESKALASYON: $ad -> kurtarma ise yaramadi ($neden). Actions loguna bak.")
    return
  }
  $sonuc = KurtarWorkflow $dosya $ad
  if($sonuc -eq "tetiklendi" -or $sonuc -eq "zaten-kosuyor"){
    $script:kurtarilan.Add("$ad -> $neden -> kurtarma: $sonuc")
    $script:kurtAnahtar.Add($anahtar)
    Write-Host "KURTARMA: $ad ($sonuc)"
  } else {
    $script:kirmizi.Add("KURTARILAMADI: $ad -> $neden -> $sonuc")
  }
}

# ---------------------------------------------------------------------------
# KATMAN 1 — kosu nabzi. dosya-adi -> @(gorunen ad, en fazla kac saat).
# DOSYA ADIYLA sorgulanir (ad kaymasi imkansiz). Cron'u kapali robotlar
# listede YOK; cron acilinca buraya da eklenir.
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
  # 07.08 (kural: yeni cron'lu robot nabza DOSYA ADIYLA girer) - 06.08 kurulan denetciler:
  "duyuru-nobetcisi.yml" = @("Kurum Duyuru Nobetcisi (gunluk)", 30)
  "aritmetik-kapisi.yml" = @("Aritmetik Kapisi (haftalik)", 192)
  "ders-etiket.yml"      = @("Ders-Etiket Denetimi (haftalik)", 192)
  "ic-tutarlilik.yml"    = @("Ic-Tutarlilik Denetimi (haftalik)", 192)
  # 19.08 - Bildirim Nobeti LISTEDE YOKTU ve gunlerce kirmizi kaldi ($KOK/$kok
  # cakismasi); ogrenci itirazi cekilmeden bekleseydi kimse gormeyecekti.
  # Nobetcileri izlemeyen nabiz, nobetcinin olumune kordur. Gunde 3 kosu var;
  # 30 saatlik esik en az bir basarili kosuyu garanti eder.
  "bildirim-nobeti.yml"  = @("Bildirim Nobeti (ogrenci itirazi)", 30)
}

$simdi = (Get-Date).ToUniversalTime()
foreach($dosya in $izlenen.Keys){
  $ad   = $izlenen[$dosya][0]
  $esik = [double]$izlenen[$dosya][1]
  try {
    $u = "https://api.github.com/repos/$REPO/actions/workflows/$dosya/runs?status=success&per_page=1"
    $r = Invoke-RestMethod -Uri $u -Headers $BASLIK -TimeoutSec 60
    $son = $r.workflow_runs | Select-Object -First 1
    if(-not $son){
      KacirmaIsle "KOSU:$dosya" $dosya $ad "hic basarili kosu yok"
    } else {
      $yas = ($simdi - ([datetime]$son.created_at).ToUniversalTime()).TotalHours
      if($yas -gt $esik){
        KacirmaIsle "KOSU:$dosya" $dosya $ad ("son basarili kosu {0:N1} saat once (esik {1}s)" -f $yas, $esik)
      } else {
        Write-Host ("ok kosu : {0} ({1:N1}s)" -f $ad, $yas)
      }
    }
  } catch { $kirmizi.Add("KOSU: $ad -> API hatasi: $($_.Exception.Message)") }
  Start-Sleep -Milliseconds 250
}

# ---------------------------------------------------------------------------
# KATMAN 2 — veri tazeligi. Damga bayatsa o veriyi yazan ROBOT kurtarilir.
# Gun-cozunurluklu damgalara esik >= 48 saat.
# ---------------------------------------------------------------------------
$simdiTR = $simdi.AddHours(3)
function TarihYasSaat([string]$s){
  foreach($f in @('dd.MM.yyyy HH:mm','dd.MM.yyyy')){
    try { $t=[datetime]::ParseExact($s,$f,[Globalization.CultureInfo]::InvariantCulture); return ($simdiTR-$t).TotalHours } catch {}
  }
  return $null
}
function VeriKontrol([string]$dosyaAd, [scriptblock]$damgaAl, [double]$esikSaat, [string]$etiket, [string]$robotDosya, [string]$robotAd){
  $yol = Join-Path $veri $dosyaAd
  if(-not (Test-Path $yol)){ $script:kirmizi.Add("VERI: $etiket -> dosya yok ($dosyaAd)"); return }
  try {
    $j = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
    $damga = & $damgaAl $j
    if([string]::IsNullOrWhiteSpace($damga)){ $script:kirmizi.Add("VERI: $etiket -> tarih damgasi BOS ($dosyaAd)"); return }
    $yas = TarihYasSaat $damga
    if($null -eq $yas){ $script:kirmizi.Add("VERI: $etiket -> damga okunamadi: '$damga'"); return }
    if($yas -gt $esikSaat){
      KacirmaIsle "VERI:$dosyaAd" $robotDosya $robotAd ("{0} damgasi {1} ({2:N0} saat eski; esik {3}s)" -f $etiket, $damga, $yas, $esikSaat)
    } else {
      Write-Host ("ok veri : {0} ({1})" -f $etiket, $damga)
    }
  } catch { $script:kirmizi.Add("VERI: $etiket -> okunamadi: $($_.Exception.Message)") }
}

VeriKontrol "kart-durum.json"     { param($j) $j.sonTarama } 48  "RG tarama damgasi"        "kartlar.yml"       "Hap Kartlar"
VeriKontrol "uyari-ozet.json"     { param($j) $j.tarih }     30  "Uyari robotu ozeti"       "uyari.yml"         "Radar Uyari Robotu"
VeriKontrol "vitrin-sayilar.json" { param($j) $j.tarih }     48  "Vitrin kanit sayilari"    "kasa-sayim.yml"    "Kasa Sayimi"
VeriKontrol "kalite-tarama.json"  { param($j) $j.tarih }     216 "Kasa kalite taramasi"     "kalite-tarama.yml" "Kasa Kalite Taramasi"
VeriKontrol "ihale-yurtici.json"  { param($j)
  $m=[regex]::Match("$($j.guncelleme)",'Son çekim: (\d{2}\.\d{2}\.\d{4} \d{2}:\d{2})')
  if($m.Success){ $m.Groups[1].Value } else { $null }
} 36 "Yurt ici ihale beslemesi" "kaynak.yml" "Kaynak Nobetcisi"

# 13.08 Cem: "net cevap veriyor DEME, her yere kontrolu koy" - KONTROLUN
# KONTROLU: veri tazeleyen robotlarin "kontrol ettim" damgalari eskirse
# (robot durmus/sessiz olmus demektir) ALARM. Degisiklik olmamasi mazeret
# degildir; damga her kosuda yazilir.
VeriKontrol "teblig-damga.json"  { param($j) $j.tarih } 48 "Gozetim teblig damgasi (43 teblig)" "mevzuat.yml" "Kanun Aynasi"
VeriKontrol "yanveri-damga.json" { param($j) if($j.damping){ if($j.damping.PSObject.Properties['kontrol']){$j.damping.kontrol}else{$j.damping.tarih+' 12:00'} } } 96 "Damping listesi kontrolu" "yerel-indirici" "Yanveri Onarici"
VeriKontrol "yanveri-damga.json" { param($j) $j.duyuruKontrol } 96 "Ithalat Gn.Md. duyuru sinyali" "yerel-indirici" "Yanveri Onarici"

# ---------------------------------------------------------------------------
# HAZIR KAYNAK YASLANMASI (13.08 Cem: "acik noktalari kapatalim").
# Manifestte pdfId=HAZIR olan metinler robotca TAZELENMEZ (indirilemeyen .doc,
# taranmis PDF vb.) - elle yenilenene kadar sessizce eskir. 180 gunu asan
# HAZIR metin ALARM'a girer: "kaynagina bak, degisti mi, metni tazele".
# ---------------------------------------------------------------------------
try {
  $man = Get-Content (Join-Path $kok "veri\mevzuat-kaynaklar.json") -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($k in $man.kanunlar){
    if("$($k.pdfId)" -ne 'HAZIR'){ continue }
    $tx = Join-Path $kok ("veri\mevzuat-hazir\" + $k.slug + ".txt")
    if(-not (Test-Path $tx)){ $kirmizi.Add("HAZIR kaynak dosyasi YOK: $($k.slug) ($($k.ad))"); continue }
    $yas = ((Get-Date) - (Get-Item $tx).LastWriteTime).TotalDays
    if($yas -gt 180){ $kirmizi.Add(("HAZIR kaynak {0} gundur tazelenmedi: {1} ({2}) - kaynagini kontrol et, elle yenile" -f [int]$yas, $k.slug, $k.ad)) }
  }
} catch { Write-Host "HAZIR yas kontrolu atlandi: $($_.Exception.Message)" }

# ---------------------------------------------------------------------------
# RAPOR (kor kalma) — her kosuda yazilir; CI always() ile commit'ler.
# kurtarilan_anahtar: bir SONRAKI yoklamanin eskalasyon tespiti icin.
# ---------------------------------------------------------------------------
$durum = if($kirmizi.Count -gt 0){"ALARM"} elseif($kurtarilan.Count -gt 0){"KURTARMA"} else {"TAMAM"}
$rapor = [ordered]@{
  tarih   = $simdiTR.ToString("dd.MM.yyyy HH:mm")
  durum   = $durum
  kirmizi = $kirmizi.Count
  kurtarma = $kurtarilan.Count
  izlenen_robot = $izlenen.Count
  izlenen_veri  = 5
  maddeler = @($kirmizi)
  kurtarilan = @($kurtarilan)
  kurtarilan_anahtar = @($kurtAnahtar)
}
$rapor | ConvertTo-Json -Depth 4 | Set-Content $raporYol -Encoding UTF8

if($kurtarilan.Count -gt 0){ Write-Host "KURTARMA ($($kurtarilan.Count)):"; $kurtarilan | ForEach-Object { Write-Host "  $_" } }
if($kirmizi.Count -eq 0){
  if($kurtarilan.Count -gt 0){ Write-Host "NABIZ: kacirma vardi, KURTARMA tetiklendi - sonraki yoklama dogrular." }
  else { Write-Host "NABIZ TEMIZ: tum robotlar vardiyasinda, tum damgalar taze." }
  exit 0
}

Write-Host "NABIZ KIRMIZI ($($kirmizi.Count)):"; $kirmizi | ForEach-Object { Write-Host "  $_" }

# --- mail: yalniz makinenin COZEMEDIGI icin (Resend varsa Resend; yoksa web3forms) ---
# 19.08 onemsiz-kutu dersi: TUM-BUYUK konu + HTML-tek govde spam puani yukseltir;
# konu cumle duzeni, her maile duz-metin (text) alternatif eklenir.
$konu = "Tetikte nabiz alarmi: $($kirmizi.Count) sorun (makine cozemedi)"
if($env:RESEND_KEY){
  $sat = ($kirmizi | ForEach-Object { "<li>$_</li>" }) -join ""
  $html = "<h3>Nabiz Nobetcisi alarmi</h3><p>Otomatik kurtarma denendi ama cozulemedi:</p><ul>$sat</ul><p>Actions sekmesinden ilgili robotun loguna bak. Tetikte</p>"
  $duz = "Nabiz Nobetcisi alarmi`n`nOtomatik kurtarma denendi ama cozulemedi:`n" + (($kirmizi | ForEach-Object { "- $_" }) -join "`n") + "`n`nActions sekmesinden ilgili robotun loguna bak. Tetikte"
  $mb = @{ from=$env:RESEND_FROM; to=@("cemdizdar85@hotmail.com"); subject=$konu; html=$html; text=$duz } | ConvertTo-Json -Depth 3
  try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization=("Bearer " + ("$env:RESEND_KEY" -replace '[^\x21-\x7E]','')) } -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" | Out-Null; Write-Host "MAIL (resend) gonderildi" } catch { Write-Host "resend hatasi: $_" }
} else {
  $mb = @{
    access_key = "5b227e56-94fb-4123-a39a-4286f63db14a"
    subject    = $konu
    from_name  = "Tetikte Nabiz Nobetcisi"
    "Alarmlar" = ($kirmizi -join "`n")
    "Not"      = "Otomatik kurtarma denendi ama cozulemedi. Actions sekmesinden ilgili robotun loguna bak."
  } | ConvertTo-Json -Depth 3
  try { Invoke-RestMethod -Method Post -Uri "https://api.web3forms.com/submit" -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" -TimeoutSec 30 | Out-Null; Write-Host "MAIL (web3forms) gonderildi" } catch { Write-Host "web3forms hatasi: $_" }
}
exit 1
