# KAPI-OM ÖZEL MALİYET 5 YIL KURALI (27.09.2026, Cem "1.2.3 üçünü de yap"; SGS oturumu bildirdi)
#
# NEDEN: ambarda 'THP 264 - ÖZEL MALİYETLER' (MSUGT 1992) ve bir teori notu "kira süresi beş yıldan fazlaysa beş yılda
#   itfa" diyor. Vergi kuralı 2005'ten beri başka: VUK m.327 (5398 s.K. 24. md.) "kira veya işletme hakkı süresine göre
#   eşit yüzdelerle itfa edilir" — beş yıl sınırı YOK (27.09 ambardan okundu). ÖLÇÜLDÜ 27.09 (elle okuma): SGS'de
#   1 cevap yanlış + 5 açıklama eski kuralı anlatıyor; SMMM'de 1 cevap yanlış (kira 6 yıl, 5 yılla hesap) + 5 açıklama.
# KURAL: sorunun ÖĞRENCİNİN GÖRDÜĞÜ alanlarında (kök, şık, açıklama, teşhis, sade, konu girişi, adımlar, dayanak, hap,
#   taktik…) özel maliyet / 264 geçiyor ve bir CÜMLE eski kuralı geçerli diye anlatıyorsa kusur. Cümlede itfa/amorti/
#   özel maliyet/264 geçmeli (TBK'daki "beş yıldan uzun süreli kira sözleşmesi" meşrudur). Cümle eski kuralı REDDEDİYORSA
#   (yoktur, geçersiz, kaldırıl, uygulanmaz, 2005, 5398, artık) kusur değildir.
# ÖLÇÜLDÜ 27.09 (yerel kasanın TAMAMI, 14.187 soru: SMMM 6.231 · SGS 7.327 · KGK 501 · diğer 128): 26 soru düştü (SGS 11,
#   SMMM 15), elle okunan 26'nın 26'sı eski kuralı anlatıyordu. SGS'nin elle bulduğu 6 kusurlu vakanın 6'sı yakalandı,
#   doğru dediği 7 vakada alarm yok. Benim elle bulduğum SMMM 1 cevap yanlış + 5 açıklama kusurunun 6'sı yakalandı.
# 🚫 GÖRMEZ: kuralı sayıyla uygulayıp hiç söylemeyen soru (kira 6 yıl, tutar /5 ile hesaplanmış, metinde "beş yıl"
#   ifadesi yok) · desende olmayan anlatım ("azami süre 60 ay", "altmış ayda") · İngilizce metin · iç alanlar
#   (kaynak_metin_ozet, hakem, kör, ikiz — kaynağın alıntısı ya da yayına çıkmayan kayıt) · THP 260/262/263'ün KENDİ
#   beş yıl kuralı (kusur değildir; aynı cümlede 264/özel maliyet geçerse görür).
# Öz-sınav: arac/ozel-maliyet-kapisi-sinavi.ps1 (dogrula.yml). Kullanan: motor/kalip-parti-uret.ps1 (FAZ A + FAZ GM),
#   arac/hazir-soru-denetle.ps1, arac/smmm-yayin-sarti.ps1.

function OmMetinler($deger) {
  # bir soru nesnesinin bütün metin alanlarını düz dizgi listesine açar (iç içe nesne/dizi dahil)
  $liste = New-Object System.Collections.Generic.List[string]
  $yigin = New-Object System.Collections.Stack; $yigin.Push($deger)
  while ($yigin.Count) {
    $x = $yigin.Pop()
    if ($null -eq $x) { continue }
    if ($x -is [string]) { if ($x.Trim()) { $liste.Add($x) }; continue }
    if ($x -is [System.Collections.IDictionary]) { foreach ($v in $x.Values) { $yigin.Push($v) }; continue }
    if ($x -is [System.Collections.IEnumerable]) { foreach ($v in $x) { $yigin.Push($v) }; continue }
    if ($x -is [pscustomobject]) { foreach ($p in $x.PSObject.Properties) { $yigin.Push($p.Value) }; continue }
  }
  return , $liste
}

# 27.09 ikinci tur (yayındaki 5 sorunun elle dökümü): "uzunsa beş yıla", "en çok/en fazla beş yıl", "kira süresi veya/ya da
#   … beş yıl" anlatımları ilk desende yoktu (w10-2 cokzor kp-04'te 7 cümle, w4 kolay kp-10'da 1 cümle kaçıyordu) → eklendi.
$script:OM_ESKI_KURAL = '(?i)(beş|5)\s*yıl(dan|ı)?\s*(daha\s+)?(fazla|uzun|aş)|(beş|5)\s*yıl(lık)?\s*(üst\s*|yasal\s*|kanuni\s*)?sınır|(kanuni|yasal)\s*(beş|5)\s*yıl|(beş|5)\s*yıl(\s+ile)?\s+sınırl|(uzunsa|fazlaysa|aşarsa|geçerse)\s*(beş|5)\s*yıl|(en\s*(çok|fazla)|azami)\s*(beş|5)\s*yıl|kira\s*süresi(nde|ne)?\s*(veya|ya\s*da)\s*[^.;]{0,25}?(beş|5)\s*yıl'
$script:OM_BAGLAM = '(?i)özel\s*maliyet|\b264\b'
$script:OM_CUMLE_BAGLAM = '(?i)özel\s*maliyet|\b264\b|[iİ]tfa|amorti'   # 'İtfa' cümle başında: Linux'ta (?i) İ/i eşlemeyebilir
# Yalnız ÖĞRENCİNİN GÖRDÜĞÜ, bizim yazdığımız alanlar. İç alanlar bakılmaz: kaynak_metin_ozet ve dayanak_alinti kaynağın
# birebir alıntısıdır (kök çözüm kaynak notu, bkz. KAYNAK-BORCU), hakem/ikiz/kör/simülasyon kayıtları yayına çıkmaz.
# ÖLÇÜLDÜ 27.09: iç alanlar dahil edilince 13.382 soruda 121 düşüş, 118'i yalnız kaynak_metin_ozet yüzündendi.
$script:OM_IC_ALAN = @('kaynak_metin_ozet','dayanak_alinti','kaynak_adlar','capa_metin','hakem','hakem2','ikiz','ikiz_sema','kor_cozum','kor_cozum_kaynakli','simulasyon_sonnet','gm_kapi','aritmetik','hesap_kod','hesap_genisletme','yazar','donem','konu','pencere_kavram')
$script:OM_RED = '(?i)yoktur|\byok\b|bulunmaz|geçersiz|kaldırıl|uygulanmaz|\b2005\b|5398|eski\s+kural|mülga|artık|\bdahi\b'   # 'uzunsa dahi kira süresinde' doğru anlatımdır (teori notu 27.09)
# ret sözcüğü "değil" bilerek yok: "beş yılda değil kira süresinde" doğru anlatımdır ama eski kural cümlesine de ("5 yıldan
# kısa değil") girer; yalnız sıkı ret ifadeleri geçerli sayılır.

function OzelMaliyetKapisi($a) {
  $out = @(); if (-not $a) { return $out }
  $gorunen = $a
  if ($a -is [pscustomobject]) {
    $gorunen = [ordered]@{}
    foreach ($p in $a.PSObject.Properties) { if ($script:OM_IC_ALAN -notcontains $p.Name) { $gorunen[$p.Name] = $p.Value } }
  }
  $metinler = OmMetinler $gorunen
  $tum = ($metinler -join ' ')
  if ($tum -notmatch $script:OM_BAGLAM) { return $out }   # metinde özel maliyet / 264 hiç geçmiyor
  foreach ($m in $metinler) {
    foreach ($cumle in ([regex]::Split($m, '(?<=[.;!?])\s+|\r?\n'))) {
      if ($cumle -notmatch $script:OM_ESKI_KURAL) { continue }
      if ($cumle -match $script:OM_RED) { continue }
      # cümle itfa/özel maliyet anlatmıyorsa sayılmaz (ör. TBK'da "beş yıldan uzun süreli kira sözleşmesi" kuralı meşrudur)
      if ($cumle -notmatch $script:OM_CUMLE_BAGLAM) { continue }
      $kisa = ($cumle -replace '\s+', ' ').Trim(); if ($kisa.Length -gt 140) { $kisa = $kisa.Substring(0, 140) + '…' }
      $out += "özel maliyette eski 'beş yıl' kuralı (VUK m.327: kira süresine göre, sınır yok): '$kisa'"
    }
  }
  return @($out | Select-Object -Unique)
}
