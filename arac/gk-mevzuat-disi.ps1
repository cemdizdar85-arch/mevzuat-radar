#requires -Version 5.1
# ============================================================================
#  GENEL KÜLTÜR DERSİNE MEVZUAT DAYANAĞI YAZILMAZ (13.09.2026, Cem "köprü düzeltmesi önce yap")
#
#  ÖLÇÜLDÜ: veri/fabrika/konu-koprusu.json'da SGS Matematik / Türkçe / Yabancı Dil konusu olup
#  cikmis_dayanak'ı bir mevzuat olan 47 kayıt vardı ("limit hesabi" ← III-45.1 Tebliği,
#  "turev hesabi" ← SPK Tebliğ V-51, "zaman secimi (used)" ← AYM K. 6216, "ses olaylari" ← CMK).
#  Kaynağı 31.08 tohumu veri/kopru-dayanak-sozlugu.json. kalip-parti-uret.ps1 tebliğ kodunu
#  konu teori notlarının ÖNÜNE koyduğu için kaynak paketi yanlış kanunla doluyordu; GM
#  sgs-gm5-mat-r1'de doğru iki soru (kp-03 limit, kp-11 türev) hakemden bu yüzden döndü.
#
#  KURAL: ders Matematik / Türkçe / Yabancı Dil ise (İnkılap HARİÇ: Soyadı Kanunu gibi meşru
#  kanun dayanakları var) ve dayanak metni mevzuat kalıbı taşıyorsa dayanak BOŞ sayılır.
#  Tüketici: motor/konu-koprusu-kur.ps1 (üretim anında). Eşdeğerlik provası aynı fonksiyonla.
# ============================================================================
$script:GK_MEVZUAT_RX='(?i)Tebli[gğ]|\bKanun|Y[oö]netmeli[kğ]|\bSPK\b|\bTMS\b|\bTFRS\b|\bVUK\b|\bTTK\b|\bTBK\b|\bGVK\b|\bKVK\b|\bBDS\b|\bCMK\b|\bHMK\b|s\.K\.\)|\bm\.\s*\d|\bRehber\b|\bKarar[iı]\b'
function GkDersMi([string]$bizimDers,[string]$arsivDers){
  if("$bizimDers" -match '(?i)^(Matematik|Turkce|Türkçe|Yabanci Dil|Yabancı Dil)$'){ return $true }
  if(-not "$bizimDers".Trim() -and "$arsivDers" -match '(?i)^(Matematik-Istatistik|Yabanci Dil)$'){ return $true }
  return $false
}
function GkMevzuatDisiMi([string]$bizimDers,[string]$arsivDers,[string]$dayanak){
  if(-not "$dayanak".Trim()){ return $false }
  if(-not (GkDersMi $bizimDers $arsivDers)){ return $false }
  return [bool]("$dayanak" -match $script:GK_MEVZUAT_RX)
}
