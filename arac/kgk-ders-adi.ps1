#requires -Version 5.1
<#
================================================================================
  KGK DERS ADI — ETİKETTEN MODÜLE  (26-27.09.2026)  bedel 0 · dot-source edilir

  NİYE: KGK (Bağımsız Denetçilik) kilitli kasa yayını (arac/kgk-kasa-yayin.ps1) soruyu
  modül modül Kaydır-Çöz sayfasına dizer; modül adı buradan gelir. SMMM'nin eşi
  (arac/smmm-ders-adi.ps1) — ayrı dosya, çünkü Cem 27.09: "bu oturum YALNIZ KGK,
  SMMM betiklerine dokunma".

  ÇÖZÜM SIRASI
    (1) etiket parçası (tire sınırlı, düzenli ifade: 'bds315', 'kys1' gibi numaralı parçalar)
    (2) soru satırındaki 'ders' alanı — modül öneki ("b) ") atılır, TAM ad eşleşmesi.
        "Türkiye" iki modülde ortak olduğu için SMMM'deki gibi ilk kelimeyle eşleme YAPILMAZ.
    (3) konu → veri/sinav/kgk-konu-es.json 'd' (KGK kapsama tablosunun modül sözlüğü).
        Karma partiler ('kgk-olcum-kyfy': Kurumsal Yönetim + Finansal Yönetim) böyle çözülür.
  ÖLÇÜLDÜ (26.09, yerel 29 KGK partisi): HİÇBİRİNDE soru satırında 'ders' alanı yok.
  'gds' → Sürdürülebilirlik Denetimi: kapsama sözlüğünde 50 'gds …' etiketinin 50'si bu modülde.

  ESKİ HAT: kgk-bosluk-* · kgk-kurfin-30 · kgk-muhstd-20 (yalnız hakemli eski hat) yayına
  HİÇ girmez ($script:KGK_ESKI_HAT; yayıncı ve öz-sınav buradan okur).

  🚫 GÖRMEZ: konu adı sözlükte yazım farkıyla duruyorsa (3) çözemez → '' döner, yayıncı
     "ders çözülemedi" diye düşürür (sessiz değil, sayılır). Yeni parti adlandırması
     eklenince bu dosyaya satır eklenir; öz-sınavın KAPSAM ölçüsü bunu hatırlatır.
  ÖZ-SINAV: powershell -NoProfile -File arac/kgk-ders-adi-sinavi.ps1
================================================================================
#>
$script:KGK_DERS_KISA = [ordered]@{
  'tms'     = 'Türkiye Muhasebe Standartları'
  'tfrs'    = 'Türkiye Muhasebe Standartları'
  'muhstd'  = 'Türkiye Muhasebe Standartları'
  'tds'     = 'Türkiye Denetim Standartları'
  'bds\d*'  = 'Türkiye Denetim Standartları'
  'kys\d*'  = 'Türkiye Denetim Standartları'
  'ky'      = 'Kurumsal Yönetim'
  'fy'      = 'Finansal Yönetim'
  'spk'     = 'Sermaye Piyasası Mevzuatı'
  'bank'    = 'Bankacılık Mevzuatı'
  'banka'   = 'Bankacılık Mevzuatı'
  'sigorta' = 'Sigortacılık ve Özel Emeklilik Mevzuatı'
  'tsrs'    = 'Kurumsal Sürdürülebilirlik Raporlaması'
  'gds'     = 'Sürdürülebilirlik Denetimi'
}
$script:KGK_ESKI_HAT = '^kgk-(bosluk-.*|kurfin-30|muhstd-20)$'
$script:KGK_DERS_SLUG = @{
  'Türkiye Muhasebe Standartları' = 'muhasebe-standartlari'; 'Türkiye Denetim Standartları' = 'denetim-standartlari'
  'Kurumsal Yönetim' = 'kurumsal-yonetim'; 'Finansal Yönetim' = 'finansal-yonetim'
  'Sermaye Piyasası Mevzuatı' = 'sermaye-piyasasi'; 'Bankacılık Mevzuatı' = 'bankacilik'
  'Sigortacılık ve Özel Emeklilik Mevzuatı' = 'sigortacilik'; 'Kurumsal Sürdürülebilirlik Raporlaması' = 'surdurulebilirlik-raporlamasi'
  'Sürdürülebilirlik Denetimi' = 'surdurulebilirlik-denetimi'
}
# arac/kgk-konu-kapsama.js katla() ile aynı katlama (sözlük anahtarları böyle yazılı)
function KgkKatla([string]$s) {
  $t = "$s".Replace([char]0x0130, 'I').Replace([char]0x0131, 'i').ToLowerInvariant()
  $t = $t.Replace([string][char]0x0307, '') -replace 'ş', 's' -replace 'ğ', 'g' -replace 'ü', 'u' -replace 'ö', 'o' -replace 'ç', 'c' -replace '[âà]', 'a' -replace 'î', 'i' -replace 'û', 'u' -replace "['’]", ''
  return (($t -replace '[^a-z0-9 ]', ' ') -replace '\s+', ' ').Trim()
}
# modül adı ("a) …" kapsama biçimi ya da kısa biçim) → kanonik ders adı
$script:KGK_DERS_TAKMA = @{}
foreach ($kgkKanonikDersDongusu in @($script:KGK_DERS_SLUG.Keys)) { $script:KGK_DERS_TAKMA[(KgkKatla $kgkKanonikDersDongusu)] = $kgkKanonikDersDongusu }
Remove-Variable kgkKanonikDersDongusu -ErrorAction SilentlyContinue   # dot-source eden betiğe döngü değişkeni sızmasın (K1)
$script:KGK_DERS_TAKMA[(KgkKatla 'Sigortacılık ve Özel Emeklilik')] = 'Sigortacılık ve Özel Emeklilik Mevzuatı'
$script:KGK_DERS_TAKMA[(KgkKatla 'Sürdürülebilirlik Raporlaması')] = 'Kurumsal Sürdürülebilirlik Raporlaması'
function KgkModulAdi([string]$modul) {
  $sade = ("$modul" -replace '^\s*[a-zçğıöşü]\)\s*', '').Trim()
  return "$($script:KGK_DERS_TAKMA[(KgkKatla $sade)])"
}
$script:KGK_KONU_ES = $null
$script:KGK_ARAC_DIZINI = $PSScriptRoot   # dot-source anında bu dosyanın klasörü (arac/)
function KgkKonuModulu([string]$konu) {
  if (-not "$konu".Trim()) { return '' }
  if ($null -eq $script:KGK_KONU_ES) {
    $script:KGK_KONU_ES = @{}
    $esYol = Join-Path (Join-Path (Join-Path (Split-Path -Parent $script:KGK_ARAC_DIZINI) 'veri') 'sinav') 'kgk-konu-es.json'
    if (Test-Path $esYol) { foreach ($p in (Get-Content $esYol -Raw -Encoding UTF8 | ConvertFrom-Json).esleme.PSObject.Properties) { $script:KGK_KONU_ES[$p.Name] = "$($p.Value.d)" } }
  }
  $a = KgkKatla $konu
  if (-not $script:KGK_KONU_ES.ContainsKey($a)) { return '' }
  return (KgkModulAdi $script:KGK_KONU_ES[$a])
}
function KgkDersAdi([string]$etiket, $v) {
  foreach ($k in $script:KGK_DERS_KISA.Keys) { if ($etiket -match "(^|-)$k(-|$)") { return $script:KGK_DERS_KISA[$k] } }
  $h = $(if ($v -and $v.PSObject.Properties['ders']) { "$($v.ders)" } else { '' })
  if ($h) { $m = KgkModulAdi $h; if ($m) { return $m } }
  $konuAd = $(if ($v -and $v.PSObject.Properties['konu']) { "$($v.konu)" } else { '' })
  return (KgkKonuModulu $konuAd)
}
function KgkDersSlug([string]$dersAdi) { return "$($script:KGK_DERS_SLUG[$dersAdi])" }
