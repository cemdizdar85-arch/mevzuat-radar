#requires -Version 5.1
# ============================================================================
#  VERGİ TÜRÜ UYUŞMAZLIĞI — konu bir vergiyi anıyor, dayanak başka bir verginin / ilgisiz bir kanunun (16.09.2026)
#  (Cem "1.2.3 üçünü de yap", GM 3: "köprünün kanun bağını kaynağında düzeltelim")
#
#  ÖLÇÜLDÜ (bedel 0): veri/fabrika/konu-koprusu.json
#    SMMM: "kdv'nin konusu" ← ÖTV K. (4760) m.1 · "otv ilk iktisap" ← GVGT 311 · "kdv mahsup tevkifat" ← GVGT 330 ·
#          "kdv hizmet sayilan haller" ← 5510 SGK K. · "teblig usulleri ve kdv matrahi" ← 6458 Yabancılar K. ·
#          "gelir vergisi beyanname cesitleri" ← Ar-Ge Teşvik K. (5746)
#    SGS (oturum 92): 9 KDV konusu ← Gelir Vergisi Genel Tebliği 301/311/330; ÖTV teslim ← KDV GUT; harçlar ← Bankacılık K.
#  Kaynağı 31.08 tohumu veri/kopru-dayanak-sozlugu.json ve kasadaki soruların kaynak alanı. Yanlış dayanak kaynak paketini
#  yanlış kanunla dolduruyor; kanun kısaltması eklendikçe (16.09 ÖTV) bu yanlış bağlar "güçlü paket"e dönüşüyor.
#
#  KURAL: konu adı bir vergi türü anıyorsa dayanak ya (a) o verginin kendi kanun/tebliğ ailesinden, ya (b) her vergi konusunda
#  meşru ortak aileden (VUK, AATUHK, THP/MSUGT, TTK, TEORİ notu, TMS/TFRS, İYUK) olmalı. Değilse dayanak BOŞ sayılır.
#  GV ve KV konuları birbirinin ailesini de kabul eder (karşılık/stopaj bağları meşru). Konu iki vergi anıyorsa ikisi de kabul.
#  Karşılaştırma harf ve kültürden bağımsızdır (katlanmış ASCII): tr-TR'de 'i' ≠ 'I' tuzağı burada yok.
#  Tüketici: motor/konu-koprusu-kur.ps1 (üretim anında, $script:VERGI_UYUSMAZ_SINAV listesindeki sınavlar için).
# ============================================================================
function VtKatla([string]$s){
  $s="$s".Replace([char]0x0130,'i').Replace([char]0x0131,'i').Replace('I','i').Replace([char]0x015E,'s').Replace([char]0x015F,'s').Replace([char]0x011E,'g').Replace([char]0x011F,'g').Replace([char]0x00DC,'u').Replace([char]0x00FC,'u').Replace([char]0x00D6,'o').Replace([char]0x00F6,'o').Replace([char]0x00C7,'c').Replace([char]0x00E7,'c').Replace([char]0x00C2,'a').Replace([char]0x00E2,'a')
  return (($s.ToLowerInvariant() -replace '[^a-z0-9]+',' ').Trim())
}
# konu adında vergi türü (katlanmış metin üzerinde)
$script:VT_KONU=[ordered]@{
  KDV='\bkdv\b|katma deger'; OTV='\botv\b|ozel tuketim'; GV='\bgelir vergisi\b|\bgvk\b'; KV='\bkurumlar vergisi\b|\bkvk\b'
  DV='\bdamga vergisi\b'; HARC='\bharc(lar|i)?\b'; VIV='\bveraset\b|\bintikal vergisi\b'; MTV='\bmotorlu tasit(lar)? vergisi\b'
}
# dayanak metninde vergi ailesi (katlanmış metin üzerinde)
$script:VT_AILE=[ordered]@{
  KDV='\b3065\b|\bkdvk\b|\bkdv\b|katma deger'; OTV='\b4760\b|\botv\b|ozel tuketim'; GV='\b193\b|\bgvk\b|gelir vergisi'
  KV='\b5520\b|\bkvk\b|kurumlar vergisi'; DV='\b488\b|damga vergisi'; HARC='\b492\b|\bharc'; VIV='\b7338\b|veraset'; MTV='\b197\b|motorlu tasit'
}
$script:VT_ORTAK='\bvuk\b|\b213\b|vergi usul|\b6183\b|\baatuhk\b|amme alacak|\bthp\b|\bmsugt\b|tekduzen|muhasebe sistemi|\bttk\b|\b6102\b|\bteori\b|\btms\b|\btfrs\b|\b2577\b|\biyuk\b'
function VergiTuruUyusmazMi([string]$konu,[string]$dayanak){
  if(-not "$dayanak".Trim()){ return $false }
  $k=VtKatla $konu; $d=VtKatla $dayanak
  $kendi=@(foreach($t in $script:VT_KONU.Keys){ if($k -match $script:VT_KONU[$t]){ $t } })
  if($kendi.Count -eq 0){ return $false }                    # vergi anmayan konu: kural uygulanmaz
  if($d -match $script:VT_ORTAK){ return $false }            # her vergi konusunda meşru ortak aile
  $kabul=New-Object System.Collections.Generic.List[string]
  foreach($t in $kendi){ $kabul.Add($t); if($t -eq 'GV'){ $kabul.Add('KV') }; if($t -eq 'KV'){ $kabul.Add('GV') } }
  foreach($t in $kabul){ if($d -match $script:VT_AILE[$t]){ return $false } }
  return $true
}
