#requires -Version 5.1
# ============================================================================
#  TSRS UYGULAMA KAPSAMI — 3 eksik karar yutuldu + kapsam kararı konsolide   22.10.2026 · BEDEL 0
#
#  NEDEN: KGK t8 okuyucusu ölçtü — ambarda yoktu:
#    (1) KGK 16/12/2024 [01/28294] kapsam kararında değişiklik (RG 18.12.2024-32756),
#    (2) KGK 25/06/2025 [01/33130] TSRS Uygulama Kapsamına İlişkin Usul ve Esaslar (RG 16.07.2025-32957),
#    (3) KGK 25/12/2025 [01/38488] TSRS 1 E4/E5/E6(b) geçiş muafiyetlerinin uzatılması (RG 30.12.2025-33123);
#    ayrıca kapsam kararı (RG 29.12.2023-32414 1.Mük) m.3/1 değişikliksiz (bayat) ve m.2/m.3 giriş sırası bozuktu;
#    eşik kararında (RG 16.01.2026-33139) resmî metinde olmayan "MADDE 1/MADDE 2" etiketleri vardı.
#  KAYNAK: dört RG PDF'i de TARANMIŞ (metin katmanı yok) — tesseract (tur) + sayfa görüntüsüyle satır satır okundu;
#    metin veri/mevzuat-hazir/<slug>.txt, parçalar motor/mevzuat-yut.ps1 ile (anahtarsız kuru koşu) üretildi:
#    veri/mevzuat/<slug>.json. Bu betik o JSON'ları ambara yazar (mevzuat-yut ile aynı silme deseni:
#    tur=kanun-madde & kaynak_ad like '<ad>*'), önce yedek alır, sonra geri okur.
#  NEDEN mevzuat-yut ile doğrudan yazılmadı: kaynak adlarındaki "2024/2025" yılı, yut betiğinin SORU ETKİ ZİNCİRİ'nde
#    kanun_no sanılıyor (\b\d{3,5}\b) — yayındaki soruları yanlışlıkla askıya alma riski; bilgi-tabanı zinciri de
#    yıl rakamıyla ilgisiz 2 kayda (sgk-5-puan, ba-bs-kaldirildi) sahte eşleşme üretti (ölçüldü).
#  (4) 14.08.2025/34844 portföy yönetim şirketleri kararı: RG'de YOK → kaynak KGK Duyurusu 2025-53 (kgk.gov.tr).
#  -Uygula yoksa KURU (yalnız ön kontrol).
# ============================================================================
param([switch]$Uygula)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
$anahtarSb = "$($env:SUPABASE_SERVICE_KEY)".Trim(); if (-not $anahtarSb) { $anahtarSb = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $anahtarSb) { throw 'SUPABASE_SERVICE_KEY yok' }
$basliklarSb = @{ apikey = $anahtarSb; Authorization = "Bearer $anahtarSb"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$tabloAdr = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$yedekKlasor = Join-Path (Split-Path -Parent $depoKok) '_yerel-veri-kasasi\teori-yedek'
# slug -> ambarda beklenen ESKİ kayıt sayısı (fazlası/eksiği varsa hiçbir şey yazılmaz)
# 1. koşu (02:11): kapsam 10, eşik 1, diğerleri 0. 2. koşu (koordinatör: 14.08.2025/34844 PYŞ kararı eklendi): kapsam 11 + PYŞ 0
$plan = [ordered]@{ 'kgk-tsrs-kapsam' = 11; 'kgk-tsrs-pys-kapsam-2025' = 0 }
$manifest = Get-Content (Join-Path $depoKok 'veri\mevzuat-kaynaklar.json') -Raw -Encoding UTF8 | ConvertFrom-Json

function AmbarOku([string]$ad) {
  $q = [uri]::EscapeDataString("$ad*")
  $w = Invoke-WebRequest -UseBasicParsing -Uri "$tabloAdr`?select=id,tur,kaynak_ad,baslik,metin,kaynak_url,belge_tarihi&tur=eq.kanun-madde&kaynak_ad=like.$q&order=kaynak_ad.asc" -Headers $basliklarSb -TimeoutSec 120
  @(([Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) | ConvertFrom-Json) | ForEach-Object { $_ })
}

# 1) ÖN KONTROL
$is = New-Object System.Collections.Generic.List[object]
foreach ($slug in $plan.Keys) {
  $law = @($manifest.kanunlar | Where-Object { $_.slug -eq $slug }); if ($law.Count -ne 1) { throw "manifestte yok: $slug" }
  $ad = "$($law[0].ad)"
  $docs = @((Get-Content (Join-Path $depoKok "veri\mevzuat\$slug.json") -Raw -Encoding UTF8 | ConvertFrom-Json).belgeler)
  foreach ($d in $docs) {
    if (-not "$($d.kaynak_ad)".StartsWith($ad)) { throw "ad öneki tutmuyor: $($d.kaynak_ad)" }
    if ("$($d.kaynak_url)" -notlike 'https://www.resmigazete.gov.tr/eskiler/*' -and "$($d.kaynak_url)" -notlike 'https://kgk.gov.tr/*') { throw "url resmî değil: $($d.kaynak_ad)" }
    if ("$($d.kaynak_ad)" -notmatch '^TSRS') { throw "KAPI-AILE ^TSRS dışı ad: $($d.kaynak_ad)" }
  }
  $eski = @(AmbarOku $ad)
  Write-Host ("  {0}: ambarda {1} (beklenen {2}) → yeni {3} parça" -f $slug, $eski.Count, $plan[$slug], $docs.Count)
  if ($eski.Count -ne $plan[$slug]) { throw "ÖN KONTROL TUTMADI: $slug — ambarda $($eski.Count) kayıt, beklenen $($plan[$slug]); hiçbir şey yazılmadı" }
  $is.Add([pscustomobject]@{ slug = $slug; ad = $ad; docs = $docs; eski = $eski })
}
if (-not $Uygula) { "KURU: $($is.Count) kaynak hazır, ön kontrol TAMAM — yazılmadı (-Uygula)"; return }

# 2) YAZ — yedek, sil (önek), ekle, geri oku
New-Item -ItemType Directory -Force $yedekKlasor | Out-Null
$damga = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach ($p in $is) {
  if ($p.eski.Count) {
    $yd = Join-Path $yedekKlasor ("{0}.ambar.{1}.json" -f $p.slug, $damga)
    [IO.File]::WriteAllText($yd, (ConvertTo-Json -InputObject @($p.eski) -Depth 5), (New-Object Text.UTF8Encoding $false))
    Write-Host "  yedek: $yd"
    $q = [uri]::EscapeDataString("$($p.ad)*")
    Invoke-RestMethod -Method Delete -Uri "$tabloAdr`?tur=eq.kanun-madde&kaynak_ad=like.$q" -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -TimeoutSec 120 | Out-Null
  }
  $govde = ConvertTo-Json -InputObject @($p.docs | ForEach-Object { [ordered]@{ tur = 'kanun-madde'; kaynak_ad = $_.kaynak_ad; baslik = "$($_.baslik)"; metin = $_.metin; kaynak_url = $_.kaynak_url; belge_tarihi = $_.belge_tarihi } }) -Depth 5
  Invoke-RestMethod -Method Post -Uri $tabloAdr -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 180 | Out-Null
  $geri = @(AmbarOku $p.ad)
  if ($geri.Count -ne $p.docs.Count) { throw "GERİ OKUMA TUTMADI (sayı): $($p.slug) ambar $($geri.Count) / depo $($p.docs.Count)" }
  foreach ($d in $p.docs) {
    $g = @($geri | Where-Object { $_.kaynak_ad -ceq $d.kaynak_ad })
    if ($g.Count -ne 1 -or "$($g[0].metin)" -cne "$($d.metin)" -or "$($g[0].baslik)" -cne "$($d.baslik)" -or "$($g[0].kaynak_url)" -cne "$($d.kaynak_url)") { throw "GERİ OKUMA TUTMADI: $($d.kaynak_ad)" }
  }
  Write-Host ("  AMBAR YAZILDI + geri okundu (birebir {0}/{0}): {1}" -f $p.docs.Count, $p.ad)
}
"UYGULANDI: $($is.Count) kaynak"
