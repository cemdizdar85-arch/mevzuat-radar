# ============================================================================
#  SMOKE NOBETCISI — her gun tum canli sayfalari yoklar: sayfa ACILIYOR MU,
#  beklenen icerik YERINDE MI? "Site sessizce bozuldu, ilk ziyaretci gordu"
#  durumunu onler. API maliyeti SIFIR (saf HTTP + icerik imzasi kontrolu).
#  Kirmizi varsa mail. (JS-motoru derin kontrolu v2'de — playwright.)
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$TABAN = "https://tetikte.com"
$UA = "Mozilla/5.0 (compatible; TetikteSmoke/1.0)"

# sayfa -> sayfada MUTLAKA gecmesi gereken imza metni
$SAYFALAR = [ordered]@{
  "/"                    = "Yükümlülük Karnesi"
  "/index.html"          = "Tüm araçlar"
  "/gtip.html"           = "GTİP"
  "/soru-cevap.html"     = "Net Cevap"
  "/kartlar.html"        = "Hap Kartları"
  "/radar.html"          = "RG"
  "/ceza-asistani.html"  = "Ceza Asistanı"
  "/risk-taramasi.html"  = "Risk Taraması"
  "/senaryo-raporu.html" = "Senaryo"
  "/hizmet.html"         = "Hizmet Faturası"
  "/fiyatfarki.html"     = "Debit"
  "/kdv-iade-rehberi.html" = "KDV İade"
  "/hatirlatici.html"    = "Hatırlatıcı"
  "/belge-kasasi.html"   = "Belge Kasası"
  "/kurulus.html"        = "kurmalısın"
  "/kurulus-evrak.html"  = "Evrak Çantası"
  "/bilgi.html"          = "Bilgi Havuzu"
  "/destekler.html"      = "Destek"
  "/ihale-radari.html"   = "İhale"
  "/alacak-radari.html"  = "Alacak"
  "/marka-radari.html"   = "Marka"
  "/marka-itiraz.html"   = "İtiraz"
  "/evrak-radari.html"   = "Evrak"
  "/fis-fabrikasi.html"  = "Fiş Fabrikası"
  "/asgari-kv.html"      = "Asgari Kurumlar"
  "/genc.html"           = "Genç Müşavir"
  "/deneme.html"         = "Deneme Sınavı"
  "/songun.html"         = "Son Gün 5 Saat"
  "/donem-plani.html"    = "Dönem Planı"
  "/veri/soru-bankasi.json" = "sorular"
  "/radar-app.html"      = "Radar Paneli"
  "/kvkk.html"           = "Aydınlatma"
  "/uyelik-sozlesmesi.html" = "Üyelik"
  "/mesafeli-satis.html" = "Mesafeli"
  "/teslimat-iade.html"  = "Teslimat"
  "/iletisim.html"       = "Hakkımızda"
  "/menu.js"             = "GRUPLAR"
  "/veri/sgs-analiz.json" = "donemler"
  "/veri/sinav-takvimi.json" = "sonTeyit"
  "/veri/kart-durum.json" = "sonTarama"
}

$kirmizi = New-Object System.Collections.Generic.List[string]
foreach($yol in $SAYFALAR.Keys){
  $imza = $SAYFALAR[$yol]
  $u = $TABAN + $yol
  try {
    $r = Invoke-WebRequest -Uri $u -Headers @{ "User-Agent"=$UA } -TimeoutSec 30 -UseBasicParsing
    if([int]$r.StatusCode -ne 200){ $kirmizi.Add("$yol -> HTTP $($r.StatusCode)"); continue }
    if($r.Content -notmatch [regex]::Escape($imza)){ $kirmizi.Add("$yol -> imza metni YOK ('$imza')"); continue }
    # boyut tabani yalniz sayfalara: kucuk ama mesru JSON iskeleleri (ornek: bos soru bankasi) alarm degildir
    if($yol -notmatch '\.json$' -and $r.Content.Length -lt 500){ $kirmizi.Add("$yol -> supheli kucuk icerik ($($r.Content.Length) bayt)"); continue }
    Write-Host "ok: $yol"
  } catch {
    $kod = if($_.Exception.Response){ [int]$_.Exception.Response.StatusCode.value__ } else { "baglanti-yok" }
    $kirmizi.Add("$yol -> $kod")
  }
  Start-Sleep -Milliseconds 150
}

if($kirmizi.Count -eq 0){ Write-Host "SMOKE TEMIZ: $($SAYFALAR.Count) uc noktanin tamami saglikli."; exit 0 }
Write-Host "SMOKE KIRMIZI:"; $kirmizi | ForEach-Object { Write-Host "  $_" }
if($env:RESEND_KEY){
  $sat = ($kirmizi | ForEach-Object { "<li>$_</li>" }) -join ""
  $html = "<h3>Smoke Nobetcisi ALARM</h3><p>tetikte.com gunluk saglik taramasinda $($kirmizi.Count) sorun:</p><ul>$sat</ul><p>Hemen bak — ziyaretci gormeden duzelt. Tetikte</p>"
  $mb = @{ from=$env:RESEND_FROM; to=@("cemdizdar85@hotmail.com"); subject="TETIKTE SMOKE ALARM: $($kirmizi.Count) sayfa sorunlu"; html=$html } | ConvertTo-Json -Depth 3
  try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization="Bearer $($env:RESEND_KEY)" } -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" | Out-Null } catch { Write-Host "mail hatasi: $_" }
}
exit 1
