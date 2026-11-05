#requires -Version 5.1
# ============================================================================
#  KGK KART KAYNAK BORCU — BDDK + SEDDK düzenlemeleri ambara   05.11.2026 · BEDEL 0
#
#  NEDEN: C:\TETIKTE-CALISMA\kgk-is\kart\KAYNAK-YOK.md — 26 KGK konu kartı "AMBARDA YOK" (K1b); bankacılık
#    ve sigortacılık yönetmelik/tebliğ/genelgeleri ambarda yoktu. İş emri: kgk-is\basim\IS-EMRI-YUTMA-0511.md.
#  KAYNAK: yalnız resmî yayın — mevzuat.gov.tr konsolide PDF (GeneratePdf, TR-IP) ve seddk.gov.tr genelge PDF'i.
#    Metin veri/mevzuat-hazir/<slug>.txt; parçalar motor/mevzuat-yut.ps1 ile ANAHTARSIZ kuru koşuda üretildi
#    (veri/mevzuat/<slug>.json). Bu betik o JSON'ları ambara yazar: önce ön kontrol (ambarda bu önekle kayıt
#    beklenen sayıda mı), sonra yedek, sil (önek, tur=kanun-madde), ekle, GERİ OKU (sayı + metin birebir).
#  NEDEN mevzuat-yut ile doğrudan yazılmadı: yeni kaynak "değişen kanun" sayılır → SORU ETKİ ZİNCİRİ adlardaki
#    yılı (2006/2012/2021...) kanun_no sanıp yayındaki soruları askıya alabilir; bilgi-tabanı zinciri de "Sigorta"
#    gibi ilk kelimeyle sahte eşleşme üretir (kuru koşuda 7 sahte kayıt ölçüldü, dosya geri alındı).
#  -Slug verilmezse plandaki hepsi. -Uygula yoksa KURU (yalnız ön kontrol, yazmaz).
# ============================================================================
param([switch]$Uygula, [string[]]$Slug = @())
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
$anahtarSb = "$($env:SUPABASE_SERVICE_KEY)".Trim(); if (-not $anahtarSb) { $anahtarSb = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $anahtarSb) { throw 'SUPABASE_SERVICE_KEY yok' }
$basliklarSb = @{ apikey = $anahtarSb; Authorization = "Bearer $anahtarSb"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$tabloAdr = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$yedekKlasor = 'C:\TETIKTE-YEDEK\ambar-yut-20261105'
# slug -> ambarda beklenen ESKİ kayıt sayısı (tutmazsa hiçbir şey yazılmaz). Hepsi yeni kaynak: 0.
$planTam = [ordered]@{
  'bddk-yp-net-genel-pozisyon-yon' = 0; 'bddk-bs-bagimsiz-denetim-yon' = 0; 'bddk-faaliyet-raporu-yon' = 0
  'bddk-kurumsal-yonetim-yon' = 0; 'bddk-birlesme-devir-yon' = 0; 'sigorta-finansal-raporlama-yon' = 0
  'sigorta-mali-bunye-yon' = 0; 'sigorta-bilgilendirme-yon' = 0; 'bes-yon' = 0; 'bes-kismen-odeme-yon' = 0
  'sigorta-finansal-tablo-sunum-teblig' = 0; 'sigorta-finansal-tablo-sunum-teblig-2023' = 0; 'sigorta-mesleki-sorumluluk-genel-sart' = 0
  'seddk-genelge-2022-8' = 0; 'seddk-genelge-2024-1' = 0; 'seddk-genelge-2024-16' = 0; 'seddk-genelge-2025-4' = 0; 'seddk-genelge-2025-5' = 0; 'seddk-genelge-2024-10' = 0
  'seddk-genelge-2024-32' = 0; 'seddk-genelge-2025-33' = 0; 'seddk-genelge-2024-13' = 0
}
$plan = [ordered]@{}; foreach ($k in $planTam.Keys) { if (-not $Slug.Count -or $Slug -contains $k) { $plan[$k] = $planTam[$k] } }
if (-not $plan.Count) { throw 'plan boş (-Slug tutmadı)' }
$manifest = Get-Content (Join-Path $depoKok 'veri\mevzuat-kaynaklar.json') -Raw -Encoding UTF8 | ConvertFrom-Json

function AmbarOku([string]$ad) {
  $q = [uri]::EscapeDataString("$ad*")
  $w = Invoke-WebRequest -UseBasicParsing -Uri "$tabloAdr`?select=id,tur,kaynak_ad,baslik,metin,kaynak_url,belge_tarihi&tur=eq.kanun-madde&kaynak_ad=like.$q&order=kaynak_ad.asc&limit=5000" -Headers $basliklarSb -TimeoutSec 120
  @(([Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) | ConvertFrom-Json) | ForEach-Object { $_ })
}

# 1) ÖN KONTROL
$is = New-Object System.Collections.Generic.List[object]
foreach ($s in $plan.Keys) {
  $law = @($manifest.kanunlar | Where-Object { $_.slug -eq $s }); if ($law.Count -ne 1) { throw "manifestte yok/çift: $s" }
  $ad = "$($law[0].ad)"
  $json = Join-Path $depoKok "veri\mevzuat\$s.json"; if (-not (Test-Path $json)) { throw "kuru koşu JSON'u yok: $json" }
  $docs = @((Get-Content $json -Raw -Encoding UTF8 | ConvertFrom-Json).belgeler)
  if (-not $docs.Count) { throw "boş JSON: $s" }
  $adlar = @{}
  foreach ($d in $docs) {
    if (-not "$($d.kaynak_ad)".StartsWith("$ad ")) { throw "ad öneki tutmuyor: $($d.kaynak_ad)" }
    if ("$($d.kaynak_url)" -notlike 'https://www.mevzuat.gov.tr/File/GeneratePdf?*' -and "$($d.kaynak_url)" -notlike 'https://www.seddk.gov.tr/*' -and "$($d.kaynak_url)" -notlike 'https://seddk.gov.tr/*') { throw "url resmî değil: $($d.kaynak_ad) -> $($d.kaynak_url)" }
    if (-not "$($d.metin)".Trim()) { throw "boş metin: $($d.kaynak_ad)" }
    if ($adlar.ContainsKey("$($d.kaynak_ad)")) { throw "çift ad: $($d.kaynak_ad)" }; $adlar["$($d.kaynak_ad)"] = 1
  }
  $eski = @(AmbarOku $ad)
  Write-Host ("  {0}: ambarda {1} (beklenen {2}) -> yeni {3} parça" -f $s, $eski.Count, $plan[$s], $docs.Count)
  if ($eski.Count -ne $plan[$s]) { throw "ÖN KONTROL TUTMADI: $s — ambarda $($eski.Count) kayıt, beklenen $($plan[$s]); hiçbir şey yazılmadı" }
  $is.Add([pscustomobject]@{ slug = $s; ad = $ad; docs = $docs; eski = $eski })
}
if (-not $Uygula) { "KURU: $($is.Count) kaynak hazır, ön kontrol TAMAM — yazılmadı (-Uygula)"; return }

# 2) YAZ — yedek (ambar durumu, boş olsa da), sil (önek), ekle, geri oku
New-Item -ItemType Directory -Force $yedekKlasor | Out-Null
$damga = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach ($p in $is) {
  $yd = Join-Path $yedekKlasor ("{0}.ambar.{1}.json" -f $p.slug, $damga)
  [IO.File]::WriteAllText($yd, (ConvertTo-Json -InputObject @($p.eski) -Depth 5), (New-Object Text.UTF8Encoding $false))
  if ($p.eski.Count) {
    $q = [uri]::EscapeDataString("$($p.ad)*")
    Invoke-RestMethod -Method Delete -Uri "$tabloAdr`?tur=eq.kanun-madde&kaynak_ad=like.$q" -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -TimeoutSec 120 | Out-Null
  }
  $govde = ConvertTo-Json -InputObject @($p.docs | ForEach-Object { [ordered]@{ tur = 'kanun-madde'; kaynak_ad = $_.kaynak_ad; baslik = "$($_.baslik)"; metin = $_.metin; kaynak_url = $_.kaynak_url; belge_tarihi = $_.belge_tarihi } }) -Depth 5
  Invoke-RestMethod -Method Post -Uri $tabloAdr -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 180 | Out-Null
  $geri = @(AmbarOku $p.ad)
  if ($geri.Count -ne $p.docs.Count) { throw "GERİ OKUMA TUTMADI (sayı): $($p.slug) ambar $($geri.Count) / depo $($p.docs.Count) — yedek: $yd" }
  foreach ($d in $p.docs) {
    $g = @($geri | Where-Object { $_.kaynak_ad -ceq $d.kaynak_ad })
    if ($g.Count -ne 1 -or "$($g[0].metin)" -cne "$($d.metin)" -or "$($g[0].baslik)" -cne "$($d.baslik)" -or "$($g[0].kaynak_url)" -cne "$($d.kaynak_url)") { throw "GERİ OKUMA TUTMADI: $($d.kaynak_ad) — yedek: $yd" }
  }
  Write-Host ("  AMBAR YAZILDI + geri okundu (birebir {0}/{0}): {1}" -f $p.docs.Count, $p.ad)
}
"UYGULANDI: $($is.Count) kaynak · yedek klasörü $yedekKlasor"
