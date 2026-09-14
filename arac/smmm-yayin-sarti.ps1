# ============================================================================
#  BİTİRME (SMMM) YAYIN ŞARTI — TEK TANIM   14.09.2026  (dot-source edilir; bedel 0)
#
#  NEDEN (Cem 14.09 "(a) + kaynaklı ikinci çözüm + senin onayın; ben siteye yanlış bir soru girmesini
#  istemiyorum, onu engelle"): Kör çözüm (cevap anahtarını görmeden çözen model) kanunun ince bir kuralını
#  bilmediği için bizim KURDUĞUMUZ TUZAĞA düştüğünde soru atılıyordu (smmm-gm-p1-yvergi: KVK m.11/1-ı "%50").
#  Yeni kural bu soruları yalnız ÜÇ KİLİT birlikte açıksa yayına alır:
#   1) KAYNAKLI İKİNCİ ÇÖZÜM doğru (kanun metniyle çözen model bizim cevabımızı buldu)  → kor_cozum_kaynakli.dogru_mu
#   2) CEM ONAYI (veri/sinav/smmm-insan-onay.json, yalnız arac/smmm-onay.ps1 yazar)          → karar = ONAY
#   3) PARMAK İZİ tutuyor: onay verildiği andaki soru + beş şık + cevap harfi aynen duruyor; tek harf
#      değişirse onay KENDİLİĞİNDEN düşer.
#  Öteki şartların HİÇBİRİ gevşemez (hakem EVET · ders/konu uyumu · tek anlam · simülasyon · hakem2 EVET).
#
#  KULLANAN: motor/kalip-kosucu.ps1 (seçim) · motor/kaydir-coz.ps1 (sayfa basımında SON KAPI) · arac/smmm-onay.ps1
#  SGS/KGK soruları bu dosyadan geçmez (çağıranlar yalnız smmm-* etiketinde çağırır).
# ============================================================================

function SmmmParmakIzi($soruNesne) {
  $parca = @("$($soruNesne.soru)") + @('A', 'B', 'C', 'D', 'E' | ForEach-Object { "$($soruNesne.siklar.$_)" }) + @("$($soruNesne.dogru)".Trim().ToUpperInvariant())
  $bayt = [Text.Encoding]::UTF8.GetBytes(($parca -join [char]0x1E))
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return (($sha.ComputeHash($bayt) | ForEach-Object { $_.ToString('x2') }) -join '') } finally { $sha.Dispose() }
}

function SmmmOnayHarita([string]$depoKokYolu) {
  $harita = @{}
  $yol = Join-Path (Join-Path (Join-Path $depoKokYolu 'veri') 'sinav') 'smmm-insan-onay.json'
  if (-not (Test-Path $yol)) { return $harita }
  # bozuk dosya SGS seçimini çökertmesin; bitirme tarafı "onay yok" sayılır → kapı KAPALI kalır (güvenli yön)
  $ham = $null; try { $ham = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json } catch { Write-Warning "smmm-insan-onay.json okunamadı ($($_.Exception.Message)) — hiçbir bitirme onayı geçerli sayılmıyor"; return $harita }
  foreach ($kayit in @(foreach ($o in $ham) { $o })) { if ($kayit -and $kayit.anahtar) { $harita["$($kayit.anahtar)"] = $kayit } }   # dosya sırasıyla: son kayıt geçerli
  return $harita
}

function SmmmKorDogru($soruNesne) {
  return [bool]($soruNesne.PSObject.Properties['kor_cozum'] -and $soruNesne.kor_cozum -and $soruNesne.kor_cozum.PSObject.Properties['dogru_mu'] -and [bool]$soruNesne.kor_cozum.dogru_mu)
}

# Simülasyon koşmuş VE doğru mu (Sonnet ya da Haiku kaydı)
function SmmmSimDogru($soruNesne) {
  foreach ($sa in 'simulasyon_sonnet', 'simulasyon') { if ($soruNesne.PSObject.Properties[$sa] -and $soruNesne.$sa -and $soruNesne.$sa.PSObject.Properties['dogru_mu'] -and [bool]$soruNesne.$sa.dogru_mu) { return $true } }
  return $false
}

# Kör çözüm yanlışken yayına izin veren TEK istisna — üç kilit
function SmmmKorIstisna([string]$anahtar, $soruNesne, $onayHarita) {
  $kaynakli = $(if ($soruNesne.PSObject.Properties['kor_cozum_kaynakli']) { $soruNesne.kor_cozum_kaynakli } else { $null })
  if (-not ($kaynakli -and $kaynakli.PSObject.Properties['dogru_mu'] -and [bool]$kaynakli.dogru_mu)) { return [pscustomobject]@{ gecer = $false; neden = 'kaynaklı ikinci çözüm yok ya da yanlış' } }
  # kaynaklı karar BU soru metnine ve BU kör cevaba ait olmalı (soru ya da kör çözüm sonradan değiştiyse bayat karar yayın açamaz)
  if ("$($kaynakli.parmak_izi)" -ne (SmmmParmakIzi $soruNesne)) { return [pscustomobject]@{ gecer = $false; neden = 'kaynaklı çözüm eski soru metnine ait (parmak izi tutmuyor)' } }
  if ("$($kaynakli.kor_cevap)" -ne "$($soruNesne.kor_cozum.cevap)") { return [pscustomobject]@{ gecer = $false; neden = 'kaynaklı çözüm eski kör çözüme ait' } }
  if ("$($kaynakli.cevap)" -ne "$($soruNesne.dogru)".Trim().ToUpperInvariant()) { return [pscustomobject]@{ gecer = $false; neden = 'kaynaklı çözüm cevabı anahtarla tutmuyor' } }
  if (-not $onayHarita.ContainsKey($anahtar)) { return [pscustomobject]@{ gecer = $false; neden = 'Cem onayı bekliyor' } }
  $onay = $onayHarita[$anahtar]
  if ("$($onay.karar)" -ne 'ONAY') { return [pscustomobject]@{ gecer = $false; neden = "Cem kararı: $($onay.karar)" } }
  if ("$($onay.parmak_izi)" -ne (SmmmParmakIzi $soruNesne)) { return [pscustomobject]@{ gecer = $false; neden = 'onaydan sonra soru/şık/cevap değişmiş (parmak izi tutmuyor) — onay geçersiz' } }
  return [pscustomobject]@{ gecer = $true; neden = "Cem onayı $($onay.tarih) + kaynaklı çözüm doğru" }
}

# Tam yayın şartı (kalip-kosucu 8.1 ile aynı sıra) + kör istisnası
function SmmmYayinSarti([string]$anahtar, $soruNesne, $onayHarita) {
  $v = $soruNesne
  if (-not $v -or -not $v.soru) { return [pscustomobject]@{ gecer = $false; neden = 'soru yok' } }
  if ("$($v.hakem.karar)" -ne 'EVET') { return [pscustomobject]@{ gecer = $false; neden = 'hakem EVET değil' } }
  if ("$($v.hakem.ders_uyum)" -eq 'DERS-DISI') { return [pscustomobject]@{ gecer = $false; neden = 'hakem DERS-DISI' } }
  if ("$($v.hakem.konu_uyum)" -eq 'KONU-DISI') { return [pscustomobject]@{ gecer = $false; neden = 'hakem KONU-DISI' } }
  if ("$($v.hakem.tek_anlam)" -eq 'CIFT-ANLAM') { return [pscustomobject]@{ gecer = $false; neden = 'hakem CIFT-ANLAM' } }
  foreach ($sa in 'simulasyon_sonnet', 'simulasyon') { if ($v.PSObject.Properties[$sa] -and $v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu) { return [pscustomobject]@{ gecer = $false; neden = 'simülasyon yanlış' } } }
  # 14.09 (Cem "1.2 yap", GM önerisi): simülasyonu HİÇ koşmamış soru da geçmez. Ölçüldü: pilot smmm-pilot-ymeslek-zor kp-01 adımları
  # (çözüm anlatımı) yazılmadığı için simülasyon sessizce atlandı, kural yalnız "yanlış değil" dediğinden anlatımsız + sınanmamış soru seçildi.
  if (-not (SmmmSimDogru $v)) { return [pscustomobject]@{ gecer = $false; neden = $(if (-not ($v.PSObject.Properties['adimlar'] -and @($v.adimlar).Count)) { 'çözüm anlatımı (adımlar) yok → simülasyon koşamadı' } else { 'simülasyon hiç koşmadı' }) } }
  if (-not (SmmmKorDogru $v)) {
    $ist = SmmmKorIstisna $anahtar $v $onayHarita
    if (-not $ist.gecer) { return [pscustomobject]@{ gecer = $false; neden = "kör çözüm yanlış; $($ist.neden)" } }
  }
  if (-not ($v.PSObject.Properties['hakem2'] -and $v.hakem2 -and "$($v.hakem2.karar)" -eq 'EVET')) { return [pscustomobject]@{ gecer = $false; neden = 'hakem2 EVET değil' } }
  return [pscustomobject]@{ gecer = $true; neden = $(if (SmmmKorDogru $v) { 'tüm şartlar' } else { 'tüm şartlar (kör istisnası: Cem onayı + kaynaklı çözüm)' }) }
}
