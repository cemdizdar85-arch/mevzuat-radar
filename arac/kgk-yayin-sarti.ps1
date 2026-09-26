# ============================================================================
#  KGK (BAĞIMSIZ DENETÇİLİK) YAYIN ŞARTI — TEK TANIM   27.09.2026  (dot-source edilir; bedel 0)
#
#  Cem: "SGS ve SMMM'deki bütün kurallar KGK'da da olacak" + 27.09 "bu oturum YALNIZ KGK, SMMM betiklerine dokunma".
#  KARAR: şart KOPYALANMADI — arac/smmm-yayin-sarti.ps1 DEĞİŞTİRİLMEDEN yüklenir ve SmmmYayinSarti çağrılır. Neden: aynı iş
#  iki yerde durunca sessizce ayrışıyor (22.09 ders adı haritası ve ikiz cetveli olayları, arac/smmm-ders-adi.ps1 ve
#  arac/ikiz-olcusu.ps1 başlıkları). Bitirmeye eklenen her yeni kapı KGK'ya da kendiliğinden geçer — Cem'in şartı tam budur.
#  Sınava göre değişen YALNIZ onay dosyası: veri/sinav/kgk-insan-onay.json (bugün YOK; arac/smmm-onay.ps1 onu yazmaz)
#  → KGK'da kör çözümü yanlış soru için "Cem onayı + kaynaklı ikinci çözüm" istisnası KAPALI (güvenli yön). Açılması Cem kararı.
#
#  UYGULANAN KAPILAR (SmmmYayinSarti sırasıyla; 27.09 okundu):
#   doğru şık açıklaması dolu · hakem EVET · DERS-DISI/KONU-DISI/CIFT-ANLAM yok · hakem HESAP-YANLIS yok (formül/hesap) ·
#   KAPI-KH kodsuz hesap adı · MEVZUAT DEĞİŞTİ engeli (veri/sinav/mevzuat-degisti-yeni-hat.json; motor/soru-dayanak-nobetcisi.ps1
#   ambarın TÜM kalip_parti'sini tarar → kgk-* dahil; standartlar "ad|<kaynak adı>" anahtarıyla damgalanır, motor/madde-damga.ps1) ·
#   KAPI-HAD güncel had tutarı · simülasyon KOŞMUŞ ve doğru · kör çözüm doğru (istisna yalnız onayla) · hakem2 EVET ·
#   KAPI-KC Kaydır-Çöz eksiksizlik (5 şık açıklaması, yanlış şık teşhisleri, sade anlatım, adımlar, dayanak).
#  EK (yalnız KGK): kimlik 'kgk-' ile başlamalı (başka sınavın sorusu KGK kasasına giremez).
#  SGS'DEN GELİP BURADA OLMAYAN: KAPI-HS (mühürlü hesap kalıbı) — veri/hesap-kalibi.json'da yalnız SGS 'Finansal Muhasebe'
#   satırı var (5), KGK için mühürlü kalıp YOK → kapı KGK'da koşacak veri bulamaz (ölçüldü 27.09). Çırçır (cevap dağılımı)
#   kapısı SGS yayın akışında (yayin-bas.yml); SMMM'de de yok — KGK'da açık nokta.
#  🚫 GÖRMEZ: SmmmYayinSarti'nin gördüklerinin ötesini (onun körlükleri burada da geçerli); onay dosyası bozuksa "onay yok" sayılır.
#  Öz-sınav: arac/kgk-ders-adi-sinavi.ps1 (yayın şartı vakaları dahil)
# ============================================================================
. (Join-Path $PSScriptRoot 'smmm-yayin-sarti.ps1')   # DEĞİŞTİRİLMEDEN kullanılır (SMMM oturumunun dosyası)

function KgkOnayHarita([string]$depoKokYolu) {
  $harita = @{}
  $yol = Join-Path (Join-Path (Join-Path $depoKokYolu 'veri') 'sinav') 'kgk-insan-onay.json'
  if (-not (Test-Path $yol)) { return $harita }
  $ham = $null; try { $ham = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json } catch { Write-Warning "kgk-insan-onay.json okunamadı ($($_.Exception.Message)) — hiçbir KGK onayı geçerli sayılmıyor"; return $harita }
  foreach ($kayit in @(foreach ($o in $ham) { $o })) { if ($kayit -and $kayit.anahtar -and "$($kayit.anahtar)".StartsWith('kgk-')) { $harita["$($kayit.anahtar)"] = $kayit } }
  return $harita
}

function KgkYayinSarti([string]$anahtar, $soruNesne, $onayHarita) {
  if (-not "$anahtar".StartsWith('kgk-')) { return [pscustomobject]@{ gecer = $false; neden = 'KGK dışı kimlik' } }
  return (SmmmYayinSarti $anahtar $soruNesne $onayHarita)
}
