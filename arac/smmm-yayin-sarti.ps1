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

if (-not (Get-Command Get-KodsuzHesapAdi -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'kimlik-ayikla.ps1') }   # 16.09 KAPI-KH için (çağıranın kapsamına yüklenir)
. (Join-Path $PSScriptRoot 'mevzuat-degisti.ps1')   # 16.09 yeni hat mevzuat engel listesi
$script:MD_LISTE = $null
. (Join-Path $PSScriptRoot 'had-kapisi.ps1')   # 23.09 KAPI-HAD
$script:HAD_HARITA = $null
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
# ⭐ 24.09.2026 KAPI-KC — KAYDIR-ÇÖZ EKSİKSİZLİK (Cem "1.2.3"): sitedeki 3.385 bitirme sorusu tarandı, 11'inde Nöbetçi'nin kaydırmalı
#   çözümü eksikti (8 teşhis kartı yok · 3 dayanak boş · 2 tuzak yok · 1 kural boş). Kök: yayın şartı yalnız "açıklama VAR ama doğru
#   şıkkınki boş"u yakalıyordu — açıklama alanı HİÇ yoksa (smmm-4k-a-maliyet-kolay-r1-2/kp-07) ya da yanlış bir şıkkınki boşsa geçiyordu.
#   Eksik sayılır: herhangi bir şıkkın açıklaması boş/yok · herhangi bir YANLIŞ şıkkın teşhisi yok · sade anlatım (sade.dogru) boş ·
#   adımlar yok · dayanak boş. Döner: eksik adları (boşsa tam).
#   🚫 GÖRMEZ: alanın İÇERİĞİNİN doğruluğunu (hakem/sim ölçer); açıklamanın tuzak kalıbına ("X Tuzağı: …") uyup uymadığını.
function SmmmKcEksik($v) {
  $eksik = New-Object System.Collections.Generic.List[string]
  $dogruHarf = "$($v.dogru)".Trim().ToUpperInvariant()
  foreach ($harf in 'A', 'B', 'C', 'D', 'E') {
    $ac = $(if ($v.PSObject.Properties['aciklama'] -and $v.aciklama -and $v.aciklama -isnot [string]) { $v.aciklama.$harf } else { $null })
    $dolu = $(if ($null -eq $ac) { $false } elseif ($ac -is [string]) { [bool]$ac.Trim() } else { [bool](@($ac.PSObject.Properties | Where-Object { "$($_.Value)".Trim() }).Count) })
    if (-not $dolu) { $eksik.Add("açıklama $harf"); }
  }
  foreach ($harf in @('A', 'B', 'C', 'D', 'E' | Where-Object { $_ -ne $dogruHarf })) {
    if (-not ($v.PSObject.Properties['teshis'] -and $v.teshis -and $v.teshis.PSObject.Properties[$harf] -and $v.teshis.$harf)) { $eksik.Add("teşhis $harf") }
  }
  if (-not ($v.PSObject.Properties['sade'] -and $v.sade -and "$($v.sade.dogru)".Trim())) { $eksik.Add('sade anlatım') }
  if (-not ($v.PSObject.Properties['adimlar'] -and @($v.adimlar | Where-Object { $_ }).Count)) { $eksik.Add('adımlar') }
  if (-not "$($v.dayanak)".Trim()) { $eksik.Add('dayanak') }
  return $eksik.ToArray()   # ⚠ virgülsüz: ", dizi" + çağıranın @() sarması boş listeyi 1 elemanlı yapar (K3) → kapı HER soruyu düşürürdü
}
function SmmmYayinSarti([string]$anahtar, $soruNesne, $onayHarita) {
  $v = $soruNesne
  if (-not $v -or -not $v.soru) { return [pscustomobject]@{ gecer = $false; neden = 'soru yok' } }
  # 14.09: doğru şıkkın açıklaması boş soru ekranda "Doğrusu" kısmı boş çıkar (pilot ymeslek-zor kp-01) → geçmez
  $dogruHarf = "$($v.dogru)".Trim().ToUpperInvariant()
  if ($v.aciklama -and $v.aciklama -isnot [string] -and -not "$($v.aciklama.$dogruHarf)".Trim()) { return [pscustomobject]@{ gecer = $false; neden = "doğru şık $dogruHarf için açıklama boş" } }
  if ("$($v.hakem.karar)" -ne 'EVET') { return [pscustomobject]@{ gecer = $false; neden = 'hakem EVET değil' } }
  if ("$($v.hakem.ders_uyum)" -eq 'DERS-DISI') { return [pscustomobject]@{ gecer = $false; neden = 'hakem DERS-DISI' } }
  if ("$($v.hakem.konu_uyum)" -eq 'KONU-DISI') { return [pscustomobject]@{ gecer = $false; neden = 'hakem KONU-DISI' } }
  if ("$($v.hakem.tek_anlam)" -eq 'CIFT-ANLAM') { return [pscustomobject]@{ gecer = $false; neden = 'hakem CIFT-ANLAM' } }
  # 16.09 (Cem "SGS'nin yapıp bizim atladığımız bir şey varsa basmadan yapalım"): SGS yayın betiği (arac/sgs-650-bas.ps1 DusmeSebebi)
  # hakem HESAP-YANLIS ve KAPI-KH (doğru şıkta kodsuz hesap adı) sorularını düşürüyordu; bitirme yayın şartında ikisi de YOKTU.
  if ("$($v.hakem.hesap_uyum)" -eq 'HESAP-YANLIS') { return [pscustomobject]@{ gecer = $false; neden = 'hakem HESAP-YANLIS' } }
  $khY = @(Get-KodsuzHesapAdi "$($v.siklar.$dogruHarf)")
  if ($khY.Count) { return [pscustomobject]@{ gecer = $false; neden = "KAPI-KH kodsuz hesap adı: $($khY -join ', ')" } }
  # 16.09 mevzuat nöbetçisi (yeni hat): dayandığı madde değişen/silinen soru, yeniden yazılana kadar geçmez
  if ($null -eq $script:MD_LISTE) { $script:MD_LISTE = MdListeOku (Split-Path -Parent $PSScriptRoot) }
  $mdE = MdEngel $script:MD_LISTE $anahtar $v
  if ($mdE) { return [pscustomobject]@{ gecer = $false; neden = "mevzuat değişti: $($mdE.kaynak) ($($mdE.tur), $($mdE.tarih))" } }
  # 23.09 KAPI-HAD (arac/had-kapisi.ps1): dayandığı maddenin güncel haddinden farklı tutarı GERÇEK diye veren soru geçmez
  if ($null -eq $script:HAD_HARITA) { $script:HAD_HARITA = HadHaritaOku (Split-Path -Parent $PSScriptRoot) }
  $hadI = HadIddiasi $v $script:HAD_HARITA @(@($v.kaynak_adlar) | ForEach-Object { MdAnahtar "$_" })
  if ($hadI) { return [pscustomobject]@{ gecer = $false; neden = "KAPI-HAD yanlış had tutarı: $hadI" } }
  foreach ($sa in 'simulasyon_sonnet', 'simulasyon') { if ($v.PSObject.Properties[$sa] -and $v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu) { return [pscustomobject]@{ gecer = $false; neden = 'simülasyon yanlış' } } }
  # 14.09 (Cem "1.2 yap", GM önerisi): simülasyonu HİÇ koşmamış soru da geçmez. Ölçüldü: pilot smmm-pilot-ymeslek-zor kp-01 adımları
  # (çözüm anlatımı) yazılmadığı için simülasyon sessizce atlandı, kural yalnız "yanlış değil" dediğinden anlatımsız + sınanmamış soru seçildi.
  if (-not (SmmmSimDogru $v)) { return [pscustomobject]@{ gecer = $false; neden = $(if (-not ($v.PSObject.Properties['adimlar'] -and @($v.adimlar).Count)) { 'çözüm anlatımı (adımlar) yok → simülasyon koşamadı' } else { 'simülasyon hiç koşmadı' }) } }
  if (-not (SmmmKorDogru $v)) {
    $ist = SmmmKorIstisna $anahtar $v $onayHarita
    if (-not $ist.gecer) { return [pscustomobject]@{ gecer = $false; neden = "kör çözüm yanlış; $($ist.neden)" } }
  }
  if (-not ($v.PSObject.Properties['hakem2'] -and $v.hakem2 -and "$($v.hakem2.karar)" -eq 'EVET')) { return [pscustomobject]@{ gecer = $false; neden = 'hakem2 EVET değil' } }
  $kcEksik = @(SmmmKcEksik $v); if ($kcEksik.Count) { return [pscustomobject]@{ gecer = $false; neden = "KAPI-KC Kaydır-Çöz eksik: $($kcEksik -join ', ')" } }
  return [pscustomobject]@{ gecer = $true; neden = $(if (SmmmKorDogru $v) { 'tüm şartlar' } else { 'tüm şartlar (kör istisnası: Cem onayı + kaynaklı çözüm)' }) }
}
