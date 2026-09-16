#requires -Version 5.1
# ============================================================================
#  REDDEDİLMİŞ SORUNUN KAYITLI KAYNAK PAKETİNİ SİL (16.09.2026, Cem "1.2.3 üçünü de yap")
#
#  NEDEN (ölçüldü 16.09): kurtarma turunda hakem paketi YENİDEN KURMAZ; sorunun kayıtlı `kaynak_metin_ozet`
#  alanını, o yoksa `kaynak_adlar` listesini kullanır (motor/kalip-parti-uret.ps1 ~3790). Yeni teori notu yazılsa
#  da eski (yanlış) paket döner, hakem aynı gerekçeyle HAYIR der: TMS kurtarmasında 3 soru iki turda böyle düştü.
#  Üreticinin tasarlanmış onarım yolu: bu iki alan silinirse paket DesenUret + AmbarCek ile TAZE kurulur (~3802).
#
#  KAPSAM: yalnız dört kapıdan GEÇMEMİŞ sorular (hakem EVET ∧ hakem2 EVET ∧ kör doğru olan soruya dokunulmaz —
#  "yayındaki soru değiştirilmez"). Soru metni, şıklar, cevap, dayanak DEĞİŞMEZ; yalnız iki önbellek alanı silinir.
#  Yedek: C:\TETIKTE-YEDEK\paket-tazele\<etiket>-<zaman>.json (satırın tam içeriği).
#  Kullanım: powershell -NoProfile -File arac/paket-tazele.ps1 -Liste "etiket|kp-01,etiket2|kp-03" [-Yaz]
# ============================================================================
param([Parameter(Mandatory = $true)][string]$Liste, [switch]$Yaz)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$SERVIS_ANAHTARI = "$env:SUPABASE_SERVICE_KEY"; if (-not $SERVIS_ANAHTARI) { $SERVIS_ANAHTARI = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))" }
$SERVIS_ANAHTARI = $SERVIS_ANAHTARI.Trim(); if (-not $SERVIS_ANAHTARI) { throw 'SUPABASE_SERVICE_KEY yok' }
$TABLO_UCU = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti'
$ISTEK_BASLIK = @{ apikey = $SERVIS_ANAHTARI; Authorization = "Bearer $SERVIS_ANAHTARI"; Accept = 'application/json'; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$YEDEK_DIZIN = 'C:\TETIKTE-YEDEK\paket-tazele'; New-Item -ItemType Directory -Force $YEDEK_DIZIN | Out-Null
$PARTI_ID = [ordered]@{}
foreach ($oge in ($Liste -split ',')) { $p = $oge.Trim() -split '\|'; if ($p.Count -ne 2) { continue }; if (-not $PARTI_ID.Contains($p[0])) { $PARTI_ID[$p[0]] = New-Object System.Collections.Generic.List[string] }; $PARTI_ID[$p[0]].Add($p[1]) }
$KOSAN_BULUT = @()
if ($Yaz) { $KOSAN_BULUT = @(& (Join-Path (Split-Path -Parent $PSScriptRoot) 'arac\bulut-kosan-etiketler.ps1') -Kati) }   # 16.09 kural: bulutta koşan partiye yazılmaz
foreach ($etiketAd in $PARTI_ID.Keys) {
  if ($KOSAN_BULUT -contains $etiketAd) { "ATLANDI (bulutta koşuyor): $etiketAd"; continue }
  $satirlar = @(Invoke-RestMethod -Uri ("$TABLO_UCU" + "?select=etiket,sinav,icerik&etiket=eq.$([uri]::EscapeDataString($etiketAd))") -Headers $ISTEK_BASLIK -TimeoutSec 180 | ForEach-Object { $_ })
  if (-not $satirlar.Count) { "YOK: $etiketAd"; continue }
  $satir = $satirlar[0]; $icerik = $satir.icerik
  $degisti = 0
  foreach ($kpAdi in $PARTI_ID[$etiketAd]) {
    $s = $icerik.$kpAdi
    if (-not $s) { "  $etiketAd $kpAdi : soru yok"; continue }
    $gecti = (("$($s.hakem.karar)" -match 'EVET') -and ("$($s.hakem2.karar)" -match 'EVET') -and ($s.kor_cozum.dogru_mu -eq $true))
    if ($gecti) { "  $etiketAd $kpAdi : KAPIDAN GEÇMİŞ, dokunulmadı"; continue }
    $silinen = @(foreach ($alan in 'kaynak_metin_ozet', 'kaynak_adlar') { if ($s.PSObject.Properties[$alan]) { $s.PSObject.Properties.Remove($alan); $alan } })
    "  $etiketAd $kpAdi : silinecek alan: $($silinen -join ', ')"
    if ($silinen.Count) { $degisti++ }
  }
  if (-not $degisti -or -not $Yaz) { continue }
  $yedekYolu = Join-Path $YEDEK_DIZIN ("$etiketAd-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json')
  # yedek: değişiklikten ÖNCEKİ satır yeniden okunup yazılır
  $ham = Invoke-WebRequest -UseBasicParsing -Uri ("$TABLO_UCU" + "?select=icerik&etiket=eq.$([uri]::EscapeDataString($etiketAd))") -Headers $ISTEK_BASLIK -TimeoutSec 180
  [IO.File]::WriteAllBytes($yedekYolu, $ham.RawContentStream.ToArray())
  $govde = '{"etiket":' + (ConvertTo-Json $etiketAd) + ',"sinav":' + (ConvertTo-Json "$($satir.sinav)") + ',"yazan":"paket-tazele","icerik":' + (ConvertTo-Json -InputObject $icerik -Depth 30 -Compress) + '}'
  [void](Invoke-RestMethod -Method Post -Uri ($TABLO_UCU + '?on_conflict=etiket') -Headers ($ISTEK_BASLIK + @{ Prefer = 'resolution=merge-duplicates,return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 300)
  "  YAZILDI: $etiketAd ($degisti soru) · yedek $yedekYolu"
}
