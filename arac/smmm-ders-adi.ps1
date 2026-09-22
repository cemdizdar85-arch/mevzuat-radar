#requires -Version 5.1
<#
================================================================================
  SMMM DERS ADI — ETIKETTEN DERSE  (22.09.2026)  bedel 0

  NIYE AYRI DOSYA: bu esleme iki yerde birden lazim ve iki yerde AYRI durursa
  sessizce ayrisiyor. 22.09'da ayrismisti:
    · yayinci (arac/smmm-kasa-yayin.ps1) dersi etiketten cozuyor, cozemedigini
      "ders cozulemedi" diye DUSURUYOR;
    · uretici (motor/kalip-parti-uret.ps1) ise ders bilmeden calisiyordu.
  OLCULDU (22.09): 434 etiketin 5'i cozulemiyordu -> 187 taslak, bunlarin 58'i
  yayin sartini GECEN soru, ambara hic girmedi. Sebep: o partiler bu oturumda
  '-vergi' / '-hukuk' diye adlandirilmisti, haritada ise yalniz 'yvergi' /
  'yhukuk' vardi. Yani parasi odenmis 58 soru bir AD YAZIMI yuzunden rafta kaldi.

  🚫 BU ESLEME SUNU GORMEZ: etikette ders kisaltmasi HIC gecmiyorsa (ve parti
  icindeki 'ders' alani da bossa) dersi bulamaz - '' doner, cagiran taraf ne
  yapacagina kendi karar verir. Yeni bir parti adlandirmasi eklendiginde bu
  dosyaya da satir eklenir; oz-sinav bunu hatirlatir.

  ⚠ 'y' ONEKI CAKISMASI: 'yvergi' ile 'vergi' ayni etikette karismaz, cunku
    eslesme TIRE ILE AYRILMIS PARCA uzerinden yapilir: '-yvergi-' icinde
    '-vergi-' yoktur. Oz-sinavda bu vaka ayrica olculur.

  OZ-SINAV: powershell -NoProfile -File arac/smmm-ders-adi-sinavi.ps1
================================================================================
#>

# Kisaltma -> ekran adi. SIRA ONEMLI: uzun/ozel olan once ('ymeslek' 'meslek'ten once).
$script:SMMM_DERS_KISA = [ordered]@{
  'ymeslek'   = 'Meslek Hukuku'
  'fmuh'      = 'Finansal Muhasebe'
  'yfta'      = 'Finansal Tablolar ve Analizi'
  'maliyet'   = 'Maliyet Muhasebesi'
  'ydenetim'  = 'Muhasebe Denetimi'
  'yspk'      = 'Sermaye Piyasası Mevzuatı'
  'yvergi'    = 'Vergi Mevzuatı ve Uygulaması'
  'yhukuk'    = 'Hukuk'
  # --- 22.09.2026 eklenenler: 'y' oneksiz yazimlar (olcum/AB partileri boyle adlandirildi) ---
  'vergi'     = 'Vergi Mevzuatı ve Uygulaması'
  'hukuk'     = 'Hukuk'
  'fta'       = 'Finansal Tablolar ve Analizi'
  'denetim'   = 'Muhasebe Denetimi'
  'spk'       = 'Sermaye Piyasası Mevzuatı'
  'meslek'    = 'Meslek Hukuku'
}
$script:SMMM_DERS_SLUG = @{
  'Meslek Hukuku' = 'meslek-hukuku'; 'Finansal Muhasebe' = 'finansal-muhasebe'
  'Finansal Tablolar ve Analizi' = 'finansal-tablolar'; 'Maliyet Muhasebesi' = 'maliyet-muhasebesi'
  'Muhasebe Denetimi' = 'muhasebe-denetimi'; 'Sermaye Piyasası Mevzuatı' = 'sermaye-piyasasi'
  'Vergi Mevzuatı ve Uygulaması' = 'vergi'; 'Hukuk' = 'hukuk'
}
# Eski adli partiler (16.09 olculdu: parti icinde 'ders' alani BOS): bosluk partileri ders adini
# bitisik yazar, GM partileri kisa ad kullanir.
$script:SMMM_DERS_ESKI = [ordered]@{
  'smmm-bosluk-finansalmuhasebe' = 'Finansal Muhasebe'; 'smmm-bosluk-hukuk' = 'Hukuk'
  'smmm-bosluk-muhasebedenetimi' = 'Muhasebe Denetimi'; 'smmm-bosluk-sermayepiyasas' = 'Sermaye Piyasası Mevzuatı'
  'smmm-bosluk-vergimevzuat' = 'Vergi Mevzuatı ve Uygulaması'; 'smmm-bosluk-muhasebecilik' = 'Meslek Hukuku'
  'smmm-bosluk-finansaltablo' = 'Finansal Tablolar ve Analizi'; 'smmm-bosluk-maliyet' = 'Maliyet Muhasebesi'
  'smmm-denetim-' = 'Muhasebe Denetimi'; 'smmm-gm-p2-fta' = 'Finansal Tablolar ve Analizi'
  'smmm-gm-p2-vergi' = 'Vergi Mevzuatı ve Uygulaması'; 'smmm-gm-p2-maliyet' = 'Maliyet Muhasebesi'
}

function SmmmDersAdi([string]$etiket, $v) {
  foreach ($k in $script:SMMM_DERS_KISA.Keys) { if ($etiket -match "(^|-)$k(-|$)") { return $script:SMMM_DERS_KISA[$k] } }
  foreach ($k in $script:SMMM_DERS_ESKI.Keys) { if ($etiket.StartsWith($k)) { return $script:SMMM_DERS_ESKI[$k] } }
  $h = $(if ($v -and $v.PSObject.Properties['ders']) { "$($v.ders)" } else { '' })
  if ($h) { foreach ($d in $script:SMMM_DERS_KISA.Values) { if ($h -like "$($d.Split(' ')[0])*") { return $d } } }
  return ''
}
function SmmmDersSlug([string]$dersAdi) { return "$($script:SMMM_DERS_SLUG[$dersAdi])" }
