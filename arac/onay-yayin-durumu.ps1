# ============================================================================
#  ONAY YAYIN KAPISI - SINIFLAMA (22.10.2026, Cem "1.2.3")
#  Cem'in ONAY verdiği soru yayında değilse NEDENİNİ tek yerden söyler; arac/smmm-kasa-yayin.ps1 çağırır.
#
#  NEDEN AYRI DOSYA: 21-22.10'da bitirme kasa yayını iki gün KIRMIZI bitti. smmm-4k-a-fmuh-zor-r7/kp-03 yayın
#  şartından meşru düşmüştü ("mevzuat değişti", 21.10) ama kapı ret kütüğünü yayın şartından ÖNCE sorduğu için
#  (soru eski KAPI-KOR kaydıyla kütükte de duruyordu) normal düşüşü "ONAYA RAĞMEN RET KÜTÜĞÜ" diye kırmızıya çevirdi.
#  Ret kütüğüne takılan soru da adaya girmediğinden "aday değil = yayın şartı" çıkarımı yetmez; yayın şartından
#  düşenler ayrı küme ($sartDisi) olarak verilir.
#
#  SIRA: yayında → ikiz → yayın şartı (bilinen) → elle ret → ret kütüğü (KIRMIZI) → aday değil (yayın şartı)
#        → BİLİNMİYOR (KIRMIZI)
#  🚫 GÖRMEZ: yayın şartının kendisinin doğru olup olmadığı (ör. "mevzuat değişti" alarmı gerçek mi) · onay
#     parmak izinin bayatlığı (yayın şartı içinde).
#  Öz-sınav + mutasyon: arac/onay-yayin-durumu-sinavi.ps1 (dogrula.yml)
# ============================================================================

function OnayYayinDurumu([string]$k, $secimAn, $ikizDisi, $sartDisi, $ret, $adayAn) {
  $mut = "$env:ONAY_DURUM_MUTASYON"
  if ($secimAn.ContainsKey($k)) { return 'yayında' }
  if ($ikizDisi.ContainsKey($k)) { return 'ikiz' }
  if ($mut -eq 'sira-eski') {
    # 21.10 öncesi sıra (ret kütüğü yayın şartından önce) - yalnız öz-sınavın mutasyonu
    if ("$($ret[$k])" -like 'ELLE*') { return 'elle ret' }
    if ($ret.ContainsKey($k)) { return 'ONAYA RAĞMEN RET KÜTÜĞÜ' }
  }
  if ($mut -ne 'sart-yok' -and $sartDisi.ContainsKey($k)) { return 'yayın şartı' }
  if ("$($ret[$k])" -like 'ELLE*') { return 'elle ret' }
  if ($mut -ne 'ret-yok' -and $ret.ContainsKey($k)) { return 'ONAYA RAĞMEN RET KÜTÜĞÜ' }
  if (-not $adayAn.ContainsKey($k)) { return 'yayın şartı' }
  return 'BİLİNMİYOR'
}

function OnayYayinKirmiziMi([string]$durum) { return ($durum -in 'ONAYA RAĞMEN RET KÜTÜĞÜ', 'BİLİNMİYOR') }
