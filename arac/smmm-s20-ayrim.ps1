#requires -Version 5.1
# ============================================================================
#  SON 20 GÜN YETERLİLİK DENEMESİ NORMAL BANKAYA GİRMEZ (05.11.2026, bedel 0)
#  Cem 04.11 gece talimatı: "normal bankaya Son 20 Gün sorusu koyma" + "eldeki 86 soru Son 20 Gün'de KULLANILMAZ, normal bankada kalır".
#  NİYE: 28.10'da dalga 1'in 86 sorusu smmm-kasa-yayin.ps1 smmm-s20-* partilerini dışlamadığı için normal bankaya girdi
#    (SGS'de havuz-kur.ps1 sgs-s20-*'i 27.10'dan beri dışlıyor). Yeni deneme etiketi: smmm-s20-<ders>-d<N>-<zorluk>.
#  KURAL: SmmmS20DenemeMi $etiket → yalnız `^smmm-s20-<harf>+-d<rakam>+-` (deneme partisi) TRUE. Eski dalga-1 etiketleri
#    (smmm-s20-fmuh-g1-zor, smmm-s20-yvergi-k-kolay …) FALSE → bankada kalır, dokunulmaz.
#  Bağ: arac/smmm-kasa-yayin.ps1 aday döngüsü (deneme partisi seçim dışı, düşen sayımı "s20 deneme").
#  🚫 GÖRMEZ: etiketi bu kalıba uymayan başka Son 20 Gün partisi · paket_soru'ya başka yoldan yazılan soru.
#  Öz-sınav: powershell -NoProfile -File arac/smmm-s20-ayrim.ps1 -Sinav   ·   mutasyon: $env:S20_AYRIM_MUTASYON='kapali'|'genis'
# ============================================================================
param([switch]$Sinav)
function SmmmS20DenemeMi([string]$etiket) {
  $m = "$env:S20_AYRIM_MUTASYON"
  if ($m -eq 'kapali') { return $false }
  if ($m -eq 'genis') { return ($etiket -like 'smmm-s20-*') }
  return ($etiket -match '^smmm-s20-[a-z]+-d\d+-')
}
if ($Sinav) {
  $vaka = @(
    @('smmm-s20-fmuh-d1-zor', $true), @('smmm-s20-yvergi-d5-kolay', $true), @('smmm-s20-ydenetim-d2-cokzor', $true), @('smmm-s20-maliyet-d1-zor', $true),
    @('smmm-s20-fmuh-g1-zor', $false), @('smmm-s20-yvergi-k-cokzor', $false), @('smmm-s20-fmuh-g4-kolay', $false),
    @('smmm-4k-a-fmuh-cokzor-r1', $false), @('smmm-bt-kd1-3010', $false), @('sgs-s20-fmuh-d1-zor', $false))
  $hata = 0
  foreach ($v in $vaka) { $s = SmmmS20DenemeMi $v[0]; if ($s -ne $v[1]) { $hata++; Write-Host "HATA $($v[0]) beklenen $($v[1]) bulunan $s" } }
  Write-Host "S20 AYRIM OZ-SINAVI: $($vaka.Count - $hata)/$($vaka.Count)"
  if ($hata) { exit 1 } else { exit 0 }
}
