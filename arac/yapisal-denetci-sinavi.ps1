# OZ-SINAV: yapisal-denetci.ps1 Kural 1 ad-alani maskelemesi
# Amac: duzeltme KAPIYI ZAYIFLATMIYOR mu? Firma ADI gecerse gecmeli,
# KAYNAK olarak gecerse yine yakalanmali.
# Desen, denetci betiginden BIREBIR kopyalandi (tek kaynak).

$ikincilKaynaklar = @('kpmg','deloitte','pwc','pricewaterhouse','ernst&young','verginet','muhasebetr','muhasebenews','bloomberght','ekonomist.com','wikipedia')
$adAlanDeseni = '"(?:ad|adi|unvan|unvani|firma|firmaAdi|sahip|sahibi|basvuran|istekli|kazanan|yuklenici|marka|markaAdi|kurum|kurumlar|idare|idareAdi)"\s*:\s*"(?:[^"\\]|\\.)*"'

function Yakalanir([string]$metin) {
  $t = [regex]::Replace($metin, $adAlanDeseni, '"_ad_":""', 'IgnoreCase')
  foreach ($k in $ikincilKaynaklar) {
    if ([regex]::IsMatch($t, '\b' + [regex]::Escape($k) + '\b', 'IgnoreCase')) { return $true }
  }
  return $false
}

# vaka = @(ad, metin, beklenen_yakalanir_mi)
$vakalar = @(
  @('A1 firma adi alani (GERCEK VAKA: ihale-firma-ozet)',
    '{"guncelleme":"Kaynak: Kamu Ihale Bulteni (KIK)","firmalar":[{"ad":"KPMG Bagimsiz Denetim A.S.","ihaleSayisi":12}]}', $false),
  @('A2 idare adi alani (GERCEK VAKA: ihale-idare-ozet)',
    '{"kaynak":"KIK sonuc ilanlari","idareler":[{"idareAdi":"PwC Danismanlik ile calisan idare","sayi":3}]}', $false),
  @('A3 marka sahibi alani (marka-yeni-basvurular tuzagi)',
    '{"kaynak":"TURKPATENT bulteni","basvurular":[{"sahibi":"Deloitte Touche Tohmatsu","no":"2026/1"}]}', $false),
  @('B1 KAYNAK alaninda ikincil -> YAKALANMALI',
    '{"oran":20,"kaynak":"KPMG vergi rehberi 2026"}', $true),
  @('B2 NOT alaninda ikincil -> YAKALANMALI',
    '{"oran":20,"not":"PwC raporuna gore oran yukseldi"}', $true),
  @('B3 ACIKLAMA alaninda ikincil -> YAKALANMALI',
    '{"aciklama":"Kaynak wikipedia sayfasindan alindi"}', $true),
  @('B4 URL alaninda ikincil -> YAKALANMALI',
    '{"url":"https://muhasebetr.com/haber/123","deger":5}', $true),
  @('C1 base64 copunde alt-dizi (01.09 tuzagi) -> YAKALANMAMALI',
    '{"script":"ScriptResource.axd?d=L9pwcta7bQ2xKpmgz"}', $false),
  @('C2 ad alani DISINDA duz metinde ikincil -> YAKALANMALI',
    '{"dayanak":"Ernst&Young sirkuleri"}', $true),
  @('D1 temiz birincil veri -> YAKALANMAMALI',
    '{"kaynak":"Resmi Gazete 21.09.2026 sayili 33377","madde":"m.8"}', $false)
)

$gecen = 0; $kalan = 0
Write-Host "== OZ-SINAV: Kural 1 ad-alani maskelemesi =="
foreach ($v in $vakalar) {
  $sonuc = Yakalanir $v[1]
  $ok = ($sonuc -eq $v[2])
  if ($ok) { $gecen++ } else { $kalan++ }
  $isaret = if ($ok) { 'GECTI' } else { 'KALDI' }
  Write-Host ("  [{0}] {1}  (beklenen yakalanir={2}, cikan={3})" -f $isaret, $v[0], $v[2], $sonuc)
}
Write-Host ""
Write-Host ("SONUC: {0} gecti / {1} kaldi (toplam {2})" -f $gecen, $kalan, $vakalar.Count)
if ($kalan -gt 0) { exit 1 } else { exit 0 }
