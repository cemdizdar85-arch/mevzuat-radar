#requires -Version 5.1
# ============================================================================
#  KAYDIR-ÇÖZ EKSİKSİZLİK TARAMASI — kilitli kasadaki (paket_soru, sinav=smmm) bitirme soruları   24.09.2026 · bedel 0
#  Cem "1.2.3" (KAPI-KC'nin 3. maddesi): her gün Excel göreviyle birlikte koşar.
#  NEDEN: 24.09'da sitedeki bitirme sorularının 11'inde Nöbetçi'nin çözüm kartı eksikti (yanlış şık teşhisi, tuzak,
#  kural, dayanak). KAPI-KC (arac/smmm-yayin-sarti.ps1) yeni eksiği yayına sokmaz; bu tarama YAYINDAKİ kasayı ölçer —
#  kapı bozulursa ya da kasa başka yoldan yazılırsa burada görünür.
#  Ölçtüğü (kasa biçimi): soru · 5 şık · doğru cevap · her yanlış şıkta tuzak metni ve teşhis · kural · sade anlatım ·
#  adımlar · dayanak.
#  GÖRMEZ: alanın DOĞRU olup olmadığı (yalnız dolu mu) · sade şık notunun kendi şıkkını anlatıp anlatmadığı ·
#  teşhis alt alanları (yanılgı/gerçek/ayırt) tek tek.
#  Çıktı: veri/sinav/kc-eksik-rapor.json (yalnız kimlik + eksik alan adı; soru metni YOK). Eksik varsa çıkış 1.
#  Kullanım: powershell -NoProfile -File arac/kc-eksik-tarama.ps1
# ============================================================================
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'rapor-yaz.ps1')
$servisAnahtari = "$env:SUPABASE_SERVICE_KEY"; if (-not $servisAnahtari) { $servisAnahtari = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))" }
$servisAnahtari = $servisAnahtari.Trim(); if (-not $servisAnahtari) { throw 'SUPABASE_SERVICE_KEY yok' }
$istekBaslik = @{ apikey = $servisAnahtari; Authorization = "Bearer $servisAnahtari" }
$kusurSay = [ordered]@{}; $taranan = 0; $dersKusur = @{}; $kusurlu = New-Object System.Collections.Generic.List[object]
$sayfaBoyu = 200
for ($ofs = 0; ; $ofs += $sayfaBoyu) {
  $cevap = Invoke-WebRequest -UseBasicParsing -UserAgent 'mevzuat-radar-robot/1.0' -Headers $istekBaslik -Uri "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=id,ders,veri&sinav=eq.smmm&order=id.asc&limit=$sayfaBoyu&offset=$ofs" -TimeoutSec 300
  $satirlar = @(([Text.Encoding]::UTF8.GetString($cevap.RawContentStream.ToArray()) | ConvertFrom-Json) | ForEach-Object { $_ })
  foreach ($satir in $satirlar) {
    $taranan++; $veri = $satir.veri; if ($veri -is [string]) { $veri = $veri | ConvertFrom-Json }
    $dogruSik = "$($veri.dogru)".Trim().ToUpperInvariant(); $eksik = New-Object System.Collections.Generic.List[string]
    if (-not "$($veri.soru)".Trim()) { $eksik.Add('soru bos') }
    foreach ($harf in 'A', 'B', 'C', 'D', 'E') { if (-not "$($veri.siklar.$harf)".Trim()) { $eksik.Add('sik bos'); break } }
    if ($dogruSik -notin 'A', 'B', 'C', 'D', 'E') { $eksik.Add('dogru cevap yok') }
    $yanlislar = @('A', 'B', 'C', 'D', 'E' | Where-Object { $_ -ne $dogruSik })
    foreach ($harf in $yanlislar) { if (-not $veri.tuzak -or -not "$($veri.tuzak.$harf.metin)".Trim()) { $eksik.Add('tuzak eksik'); break } }
    foreach ($harf in $yanlislar) { if (-not $veri.teshis -or -not $veri.teshis.$harf) { $eksik.Add('teshis eksik'); break } }
    if (-not "$($veri.kural)".Trim()) { $eksik.Add('kural bos') }
    if (-not $veri.sade -or -not "$($veri.sade.dogru)".Trim()) { $eksik.Add('sade anlatim yok') }
    if (-not (@($veri.adimlar) | Where-Object { $_ })) { $eksik.Add('adimlar yok') }
    if (-not "$($veri.dayanak)".Trim()) { $eksik.Add('dayanak bos') }
    foreach ($ad in $eksik) { $kusurSay[$ad] = 1 + [int]$kusurSay[$ad] }
    if ($eksik.Count) { $dersKusur["$($satir.ders)"] = 1 + [int]$dersKusur["$($satir.ders)"]; $kusurlu.Add([ordered]@{ id = "$($satir.id)"; ders = "$($satir.ders)"; eksik = $eksik.ToArray() }) }
  }
  if ($satirlar.Count -lt $sayfaBoyu) { break }
}
if ($taranan -eq 0) { Write-Host 'KC TARAMA: KÖR — kasadan hiç soru okunamadı' -ForegroundColor Red; exit 2 }
$rapor = [ordered]@{
  olcum = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss'); kaynak = 'paket_soru sinav=smmm (kilitli kasa = sitedeki bitirme soruları)'
  taranan = $taranan; eksikli_soru = $kusurlu.Count; alan_sayimi = $kusurSay
  ders = [ordered]@{}; eksikli = @($kusurlu | Sort-Object { $_.id })
  gormez = 'alanın doğruluğu · sade şık notunun kendi şıkkını anlatması · teşhis alt alanları'
}
foreach ($ds in ($dersKusur.GetEnumerator() | Sort-Object Value -Descending)) { $rapor.ders[$ds.Name] = $ds.Value }
[void](RaporYaz -Hedef (Join-Path $depoKok 'veri\sinav\kc-eksik-rapor.json') -Nesne $rapor)
$durum = $(if ($kusurlu.Count) { 'KIRMIZI' } else { 'YEŞİL' })
"KC TARAMA: $durum · taranan $taranan · eksikli $($kusurlu.Count)$(if ($kusurlu.Count) { ' · ' + (($kusurSay.GetEnumerator() | ForEach-Object { "$($_.Name) $($_.Value)" }) -join ', ') })"
if ($kusurlu.Count) { exit 1 }
