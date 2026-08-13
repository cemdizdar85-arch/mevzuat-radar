# ============================================================================
#  IHALE KAPSAM TARAMASI - Cem 14.08: "ihale ile ilgili atladigimiz yutmadigimiz
#  okumadigimiz hicbir sey olmasin; siteye eklememiz gereken eklemedigimiz bir
#  sey olmasin".
#
#  UC SORU:
#   A) Sayfa/veri hangi mevzuata ATIF yapiyor, o metin AMBARDA var mi?
#      (Atif var ama metin yoksa "kaynak okunmadan hukum" verilmis demektir.)
#   B) 4734/4735'in hangi KONULARI sayfada islenmis, hangileri hic yok?
#   C) Resmi ikincil mevzuat envanterinde bizde olmayan ne var?
#
#  OLCUM betigi - hicbir sey yazmaz.
# ============================================================================
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ambarYol = Join-Path $kok "veri\mevzuat"

# --- A) SAYFADAKI ATIFLAR ----------------------------------------------------
$metin = ""
foreach($p in @("ihale-radari.html")){ $metin += (Get-Content (Join-Path $kok $p) -Raw -Encoding UTF8) }
foreach($p in @("ihale-4734-katilim.json","ihale-4734-ek.json","ihale-yurtdisi-rehber.json")){
  $y = Join-Path $kok "veri\$p"; if(Test-Path $y){ $metin += (Get-Content $y -Raw -Encoding UTF8) }
}

# Ambarda hangi kaynaklar var (kaynak_ad'lardan)
$ambarAdlar = @{}
foreach($f in Get-ChildItem $ambarYol -Filter *.json){
  try { $j = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($b in @($j.belgeler)){ $a = "$($b.kaynak_ad)"; if($a){ $ambarAdlar[$a] = $f.Name } }
}
Write-Host ("Ambarda toplam kaynak_ad: {0}" -f $ambarAdlar.Count)

# Sayfada gecen ikincil mevzuat adlari
$aranan = [ordered]@{
  '4734 s. Kamu İhale Kanunu'          = @('4734')
  '4735 s. Kamu İhale Sözleşmeleri K.' = @('4735')
  '2886 s. Devlet İhale Kanunu'        = @('2886')
  'Kamu İhale Genel Tebliği'           = @('Kamu İhale Genel Tebliğ')
  'Yerli Malı Tebliği (SGM)'           = @('Yerli Malı Tebliğ','SGM-2024','SGM 2024')
  'Eşik değer tebliği (yıllık)'        = @('eşik değer','Eşik Değer','2026/1')
  'Mal Alımı İhaleleri Uyg. Yön.'      = @('Mal Alımı İhaleleri Uygulama')
  'Hizmet Alımı İhaleleri Uyg. Yön.'   = @('Hizmet Alımı İhaleleri Uygulama')
  'Yapım İşleri İhaleleri Uyg. Yön.'   = @('Yapım İşleri İhaleleri Uygulama')
  'Elektronik İhale Uyg. Yön.'         = @('Elektronik İhale Uygulama')
  'İhalelere Yönelik Başvurular Yön.'  = @('Başvurular Hakkında Yönetmelik','İhalelere Yönelik Başvuru')
  'Benzer İş Grupları Tebliği'         = @('Benzer İş Grupları')
  'AB 2014/24/EU direktifi'            = @('2014/24')
}
Write-Host "`n=== A) SAYFA ATIF YAPIYOR MU · AMBARDA VAR MI ==="
Write-Host ("{0,-40} {1,-12} {2}" -f "KAYNAK","SAYFADA","AMBARDA")
Write-Host ("-"*78)
$acik = @()
foreach($a in $aranan.GetEnumerator()){
  $sayfada = $false
  foreach($d in $a.Value){ if($metin -match [regex]::Escape($d)){ $sayfada = $true; break } }
  $ambarda = $false
  foreach($k in $ambarAdlar.Keys){
    foreach($d in $a.Value){ if($k -match [regex]::Escape($d)){ $ambarda = $true; break } }
    if($ambarda){ break }
  }
  Write-Host ("{0,-40} {1,-12} {2}" -f $a.Key, $(if($sayfada){"ATIF VAR"}else{"-"}), $(if($ambarda){"VAR"}else{"YOK"}))
  if($sayfada -and -not $ambarda){ $acik += $a.Key }
}
if($acik.Count){
  Write-Host "`n>>> ACIK: sayfa ATIF yapiyor ama metin AMBARDA YOK ({0} kaynak)" -f $acik.Count
  $acik | ForEach-Object { Write-Host ("    - " + $_) }
} else { Write-Host "`n>>> Sayfanin atif yaptigi her kaynak ambarda." }

# --- B) 4734 KONU KAPSAMASI --------------------------------------------------
# Kanunun ana konulari; sayfada islenmis mi?
$konular = [ordered]@{
  'Eşik değerler (m.8)'                 = @('eşik değer')
  'İhaleye katılamayacaklar (m.11)'     = @('katılamayacak','ihale dışı','yasaklı')
  'İlan süreleri (m.13)'                = @('ilan süre','13 üncü madde','ilan tarihinden')
  'Açık ihale usulü (m.19)'             = @('açık ihale')
  'Belli istekliler (m.20)'             = @('belli istekliler')
  'Pazarlık usulü (m.21)'               = @('pazarlık usul')
  'Doğrudan temin (m.22)'               = @('doğrudan temin')
  'Yaklaşık maliyet (m.9)'              = @('yaklaşık maliyet')
  'Geçici teminat (m.33)'               = @('geçici teminat')
  'Teminat olarak kabul edilen (m.34)'  = @('teminat mektub','teminat olarak kabul')
  'Aşırı düşük teklif (m.38)'           = @('aşırı düşük','sınır değer')
  'Kesin teminat (m.43)'                = @('kesin teminat')
  'Şikayet (m.55)'                      = @('şikayet','şikâyet')
  'İtirazen şikayet — KİK (m.56)'       = @('itirazen')
  'Yasaklama (m.58)'                    = @('yasaklama','ihalelere katılmaktan')
  'Yerli malı fiyat avantajı (m.63)'    = @('yerli malı','yerli istekli')
  'Sözleşme türleri (4735 m.6)'         = @('birim fiyat sözleşme','anahtar teslim')
  'Fiyat farkı (4735 m.8)'              = @('fiyat farkı')
  'Sözleşmenin feshi (4735 m.19-20)'    = @('fesih','feshed')
}
Write-Host "`n=== B) 4734/4735 KONULARI SAYFADA ISLENMIS MI ==="
$eksikKonu = @()
foreach($k in $konular.GetEnumerator()){
  $var = $false
  foreach($d in $k.Value){ if($metin -imatch [regex]::Escape($d)){ $var = $true; break } }
  Write-Host ("  {0,-38} {1}" -f $k.Key, $(if($var){"islenmis"}else{"YOK"}))
  if(-not $var){ $eksikKonu += $k.Key }
}
Write-Host ("`n>>> Sayfada hic gecmeyen konu: {0}" -f $eksikKonu.Count)
$eksikKonu | ForEach-Object { Write-Host ("    - " + $_) }
