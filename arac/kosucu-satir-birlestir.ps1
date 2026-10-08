# ============================================================================
#  KOŞUCU SATIR BİRLEŞTİRME — AYNI ETİKETLİ PLAN SATIRLARI   08.10.2026  (dot-source edilir; bedel 0)
#
#  NEDEN (ölçüldü 08.10, gm12 onarım planı): motor/kalip-kosucu.ps1 her plan satırını AYRI üretici süreci
#  olarak açıyordu. Aynı etiketli birden çok satır (onarım/korYenile planlarında her satır farklı pilotId)
#  olunca:
#    · ilk satır etiket sahipliğini alıyor, ötekiler "ATLANDI: <etiket> başka hatta basılıyor" diye 0 koduyla
#      SESSİZCE çıkıyordu (motor/kalip-parti-uret.ps1 ETİKET SAHİPLİĞİ) — koşucu bunu "BITTI" sayıyordu;
#    · sahiplik yarışı kaçtığında iki süreç AYNI önbellek dosyasına (kalip-parti-<etiket>.json) yazıyor,
#      son yazan öncekinin sonucunu siliyordu (kp-04/kp-05 sonucu kayboldu);
#    · seçim ve açıklama hakemi döngüsü satır başına koştuğu için aynı parti İKİ KEZ sayılıyordu.
#  ÇÖZÜM:
#    1) BİRLEŞTİR: aynı etiketli, pilotId'si DOLU ve pilotId DIŞINDAKİ BÜTÜN ALANLARI (korYenile, adimYenile,
#       simYenile, hakemYenileId, hazirYenileId, adet, ders, zorluk …) birebir aynı satırlar TEK satıra iner;
#       pilotId = kimliklerin ilk görülme sırasıyla birleşimi ("kp-01,kp-02"). Üretici virgüllü listeyi
#       destekler (kalip-parti-uret.ps1: model fazlarının hepsi `($PilotId -split ',') -notcontains $id`).
#    2) SIRALA: alanları farklı olan aynı etiketli satırlar birleşmez; koşucu onları AYNI ANDA açmaz
#       (KosucuSatirSec: uçan bir etiketin satırı, o süreç bitene kadar kuyrukta bekler).
#    3) Birleşme ve sıralama günlüğe yazılır (KOSUCU SATIR: …).
#  EŞDEĞERLİK: etiketi planda bir kez geçen satır NESNESİ AYNEN döner (kopya bile değil) → argüman listesi
#    birebir aynı. Fark yalnız aynı etiket tekrarı olan planlardadır (arac/kosucu-satir-sinavi.ps1 -Esdegerlik).
#  ⚠ PARMAK İZİ: birleşen satırın üreticisi -PilotId "kp-01,kp-02" alır; onarım tuzu (kalip-parti-uret.ps1
#    $script:PARMAK_TUZ) pilotId'yi taşıdığı için tek tek satırların ESKİ toplu sonuçları bu birleşik koşuda
#    hasat EDİLMEZ (aynı birleşik satır yeniden koşarsa kendi sonucunu hasat eder).
#  🚫 BU KAPI ŞUNU GÖRMEZ: farklı etiketlerin aynı önbellek dosyasını paylaşması (etiket = dosya adı, olamaz
#    sayılır) · iki AYRI koşucu/bulut işinin aynı etiketi açması (onu bulut-uretim.yml MEVZUAT_ATLA_ETIKET +
#    üretici sahipliği tutar) · pilotId'siz (bütün parti) satırla pilotId'li satırın birleşmesi (birleşmez,
#    sıralı koşar) · alan değerinin anlamca aynı ama yazımca farklı olması (true / "true") → sıralı koşar.
#  Öz-sınav + mutasyon: arac/kosucu-satir-sinavi.ps1 (dogrula.yml).
# ============================================================================

function KosucuSatirAnahtar($satir) {
  # pilotId DIŞINDAKİ bütün alanlar, ada göre sıralı, sıkıştırılmış JSON
  $alanlar = [ordered]@{}
  foreach ($alan in @($satir.PSObject.Properties | Sort-Object Name)) {
    if ($alan.Name -ceq 'pilotId') { continue }
    $alanlar[$alan.Name] = $alan.Value
  }
  return (ConvertTo-Json -InputObject $alanlar -Compress -Depth 10)
}

function KosucuSatirBirlestir($planSatirlari) {
  $cikanSatir = New-Object System.Collections.Generic.List[object]
  $gunlukSatir = New-Object System.Collections.Generic.List[string]
  $grupYeri = @{}      # "etiket`nanahtar" -> çıkan listedeki yeri
  $grupKimlik = @{}    # aynı anahtar -> kimlik listesi (ilk görülme sırası)
  $grupSay = @{}       # aynı anahtar -> birleşen satır sayısı
  foreach ($planSatir in @($planSatirlari)) {
    if ($null -eq $planSatir) { continue }
    $satirEtiket = "$($planSatir.etiket)"
    $satirPilot = "$(if ($planSatir.PSObject.Properties['pilotId']) { $planSatir.pilotId })".Trim()
    if ($satirPilot -and $satirEtiket) {   # etiketsiz satır (koşucu planı olmayan dosyalar: plan-siklik, plan-smmm-ilgi-*) hiç gruplanmaz
      $grupAnahtar = $satirEtiket + "`n" + (KosucuSatirAnahtar $planSatir)
      $yeniKimlik = @($satirPilot -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
      if ($grupYeri.ContainsKey($grupAnahtar)) {
        foreach ($kimlik in $yeniKimlik) { if (-not $grupKimlik[$grupAnahtar].Contains($kimlik)) { $grupKimlik[$grupAnahtar].Add($kimlik) } }
        $grupSay[$grupAnahtar]++
        continue
      }
      $grupYeri[$grupAnahtar] = $cikanSatir.Count
      $grupKimlik[$grupAnahtar] = New-Object System.Collections.Generic.List[string]
      foreach ($kimlik in $yeniKimlik) { if (-not $grupKimlik[$grupAnahtar].Contains($kimlik)) { $grupKimlik[$grupAnahtar].Add($kimlik) } }
      $grupSay[$grupAnahtar] = 1
    }
    $cikanSatir.Add($planSatir)
  }
  # birleşen gruplar: özgün nesne DEĞİŞTİRİLMEZ, sığ kopyaya birleşik pilotId yazılır
  foreach ($grupAnahtar in @($grupYeri.Keys)) {
    if ($grupSay[$grupAnahtar] -lt 2) { continue }
    $yer = $grupYeri[$grupAnahtar]
    $kopya = $cikanSatir[$yer].PSObject.Copy()
    $kopya.pilotId = ($grupKimlik[$grupAnahtar].ToArray() -join ',')
    $cikanSatir[$yer] = $kopya
    $gunlukSatir.Add("KOSUCU SATIR BIRLESTI: $($kopya.etiket) · $($grupSay[$grupAnahtar]) satır → 1 · pilotId $($kopya.pilotId)")
  }
  # birleşmeyen aynı etiketli satırlar: sıralı koşacak
  $etiketSayac = [ordered]@{}
  foreach ($cikan in $cikanSatir) { $e = "$($cikan.etiket)"; if (-not $e) { continue }; if (-not $etiketSayac.Contains($e)) { $etiketSayac[$e] = 0 }; $etiketSayac[$e]++ }
  foreach ($e in @($etiketSayac.Keys)) { if ($etiketSayac[$e] -gt 1) { $gunlukSatir.Add("KOSUCU SATIR SIRALI: $e · $($etiketSayac[$e]) satır (alanları farklı ya da pilotId'siz) → aynı anda koşmaz, sırayla") } }
  return [pscustomobject]@{ satirlar = $cikanSatir.ToArray(); gunluk = $gunlukSatir.ToArray() }
}

# Kuyruktan başlatılabilecek İLK satırın yeri; uçan bir sürecin etiketini taşıyan satır atlanır. Hepsi bekliyorsa -1.
function KosucuSatirSec($kuyrukListe, $ucanListe) {
  $ucanEtiket = @{}
  foreach ($ucanKayit in $ucanListe) { if ("$($ucanKayit.s.etiket)") { $ucanEtiket["$($ucanKayit.s.etiket)"] = 1 } }
  for ($sira = 0; $sira -lt $kuyrukListe.Count; $sira++) {
    if (-not $ucanEtiket.ContainsKey("$($kuyrukListe[$sira].etiket)")) { return $sira }
  }
  return -1
}

# Seçim / açıklama hakemi / karne için etiket başına TEK satır (ilk görülen)
function KosucuTekilEtiket($planSatirlari) {
  $gorulenEtiket = @{}
  $tekil = New-Object System.Collections.Generic.List[object]
  foreach ($planSatir in @($planSatirlari)) { $e = "$($planSatir.etiket)"; if ($e -and $gorulenEtiket.ContainsKey($e)) { continue }; $gorulenEtiket[$e] = 1; $tekil.Add($planSatir) }
  return $tekil.ToArray()
}
