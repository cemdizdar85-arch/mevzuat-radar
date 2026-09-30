# arac/aciklama-hakemi-uretim.ps1 — AÇIKLAMA HAKEMİ ÜRETİM BAĞLANTISI (30.09.2026, Cem "b yap": yeni üretime bağla)
# motor/kalip-kosucu.ps1 8.1 seçiminden ÖNCE çağırır. Bu planın YENİ (kör/hakem2 tarihi >= AH_BASLANGIC) ve dört hakemden geçmiş,
# henüz 'aciklama_hakem' kararı olmayan sorularını toplu olarak açıklama hakemine gönderir; kararı kayda yazar (arac/aciklama-hakem-yaz.js),
# harcamayı bedel defterine "<ilk parti>/AH" etiketiyle yazar (koşucu PlanHarcama plana sayar).
# Seçim kuralı (koşucu + arac/havuz-kur.ps1): YENİ soru ancak aciklama_hakem.karar = TEMIZ ise seçilir.
# PARA: soru başı ≈0,017 USD (30.09 ölçümü). Plan bütçesi (MEVZUAT_BUTCE_USD) kalanı en kötü durumu karşılamıyorsa GÖNDERMEZ;
#   o sorular kararsız kalır → seçilmez (sonraki koşuda bütçe varsa). MEVZUAT_YALNIZ_HASAT=1 iken yeni parti açılmaz (araç zaten durur).
# 🚫 GÖRMEZ: plan dışı yollardan kasaya giren soru (havuz-kur kapısı ayrıca bakar) · toplu kuyruk zaman aşımında bekleyen karar
#   (sonraki halka bedava hasat eder; o ana kadar soru seçilmez) · hakemin yanlış alarmı (etiketli ölçümde temizlerin 12/25'i, çoğu gerçek kusurdu).
$script:AH_BASLANGIC = $(if ($env:AH_BASLANGIC) { $env:AH_BASLANGIC } else { '2026-10-01' })   # ortam değişkeni yalnız prova içindir
function AhYeniMi($v) { $t = @("$(if($v.kor_cozum){ $v.kor_cozum.tarih })", "$(if($v.hakem2){ $v.hakem2.tarih })") | Where-Object { $_ } | Sort-Object -Descending | Select-Object -First 1; return [bool]($t -and "$t" -ge $script:AH_BASLANGIC) }
function AhAday($v) {
  if (-not $v -or -not $v.soru) { return $false }
  if ($v.PSObject.Properties['aciklama_hakem'] -and $v.aciklama_hakem) { return $false }
  if ("$($v.hakem.karar)" -ne 'EVET' -or "$($v.hakem.ders_uyum)" -eq 'DERS-DISI' -or "$($v.hakem.konu_uyum)" -eq 'KONU-DISI' -or "$($v.hakem.tek_anlam)" -eq 'CIFT-ANLAM') { return $false }
  if (-not ($v.hakem2 -and "$($v.hakem2.karar)" -eq 'EVET')) { return $false }
  foreach ($sa in 'simulasyon_sonnet', 'simulasyon') { if ($v.PSObject.Properties[$sa] -and $v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu) { return $false } }
  return (AhYeniMi $v)
}
# koşucu ve havuz-kur için: YENİ soru açıklama hakeminden TEMIZ almadıysa seçilmez
function AhSecilemez($v) { return [bool]((AhYeniMi $v) -and -not ($v.PSObject.Properties['aciklama_hakem'] -and "$($v.aciklama_hakem.karar)" -eq 'TEMIZ')) }

function AciklamaHakemUretim([string]$Kok, $satirlar, [double]$planHarcanan = 0, [string]$Fabrika = '') {
  if (-not $Fabrika) { $Fabrika = Join-Path $Kok 'veri\fabrika' }
  $rapor = [ordered]@{ aday = 0; gonderilen = 0; temiz = 0; kusurlu = 0; olculemedi = 0; butce_yok = 0; usd = 0 }
  . (Join-Path $Kok 'motor\api-hedef.ps1')
  . (Join-Path $Kok 'arac\aciklama-hakemi-cekirdek.ps1')
  $model = 'claude-opus-5-5'; $maxTok = 1600
  $isler = New-Object System.Collections.Generic.List[object]; $harita = @{}
  foreach ($s in @($satirlar)) {
    $cf = Join-Path $Fabrika "kalip-parti-$($s.etiket).json"; if (-not (Test-Path $cf)) { continue }
    $c = ConvertFrom-Json -InputObject (Get-Content $cf -Raw -Encoding UTF8)
    foreach ($p in $c.PSObject.Properties) { if (AhAday $p.Value) { $id = "ah$($isler.Count + 1)"; $harita[$id] = @("$($s.etiket)", $p.Name); $isler.Add((AciklamaHakemIs $id $p.Value $model 'medium' $maxTok)) } }
  }
  $rapor.aday = $isler.Count
  if (-not $isler.Count) { return [pscustomobject]$rapor }
  $kar = 0; foreach ($i in $isler) { $kar += "$($i.icerik[0].text)".Length }
  $enKotu = 0.5 * ((($kar / 1.6) / 1e6) * 4 + (($isler.Count * $maxTok) / 1e6) * 20)   # Opus 5.5 toplu; /1,6 temkinli (30.09 ölçümü ~1,7 kr/jeton)
  if ("$env:MEVZUAT_BUTCE_USD" -match '^\d+([.,]\d+)?$') {
    $butce = [double]::Parse(("$env:MEVZUAT_BUTCE_USD" -replace ',', '.'), [Globalization.CultureInfo]::InvariantCulture)
    if ($planHarcanan + $enKotu -gt $butce) { $rapor.butce_yok = $isler.Count; return [pscustomobject]$rapor }
  }
  $etiket = "$(@($satirlar)[0].etiket)/AH"
  $sonuc = Invoke-ClaudeToplu -Isler $isler.ToArray() -Etiket $etiket -BeklemeDk $(if ($env:MEVZUAT_TOPLU_BEKLE_DK -match '^\d+$') { [int]$env:MEVZUAT_TOPLU_BEKLE_DK } else { 180 }) -OnbelleksizToplu
  $rapor.gonderilen = $isler.Count
  $kararlar = @{}
  foreach ($id in $harita.Keys) {
    if (-not $sonuc.ContainsKey($id)) { continue }   # zaman aşımı: karar yok → seçilmez, sonraki halka bedava hasat
    $kr = AciklamaHakemKarar $sonuc[$id]
    if ($kr.karar -eq 'OLCULEMEDI') { $rapor.olculemedi++; continue }
    if ($kr.karar -eq 'TEMIZ') { $rapor.temiz++ } else { $rapor.kusurlu++ }
    $et = $harita[$id][0]; $kp = $harita[$id][1]; if (-not $kararlar.ContainsKey($et)) { $kararlar[$et] = @{} }
    $kararlar[$et][$kp] = [ordered]@{ karar = $kr.karar; kusurlar = @($kr.kusurlar); model = $model; tarih = (Get-Date -Format 'yyyy-MM-dd') }
  }
  if ($kararlar.Count) {
    $tmp = [IO.Path]::GetTempFileName()
    try { [IO.File]::WriteAllText($tmp, (ConvertTo-Json -InputObject $kararlar -Depth 8), [Text.UTF8Encoding]::new($false)); & node (Join-Path $Kok 'arac\aciklama-hakem-yaz.js') $tmp | Out-Host }
    finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
  }
  $u = AciklamaHakemBedelYaz $etiket $Kok; if ($u) { $rapor.usd = $u }
  return [pscustomobject]$rapor
}
