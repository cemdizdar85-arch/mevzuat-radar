# ============================================================================
#  TAVANSIZ PAKET İZLEME — 15.09.2026
#  Cem "1.2.3 üçünüde yap" (GM önerisi 3): kaynak paketi tavansız yapıldı
#  (commit 66c413f6, 15.09 19:40). Sonraki partilerde hakem ret oranı bozuluyor mu?
#
#  NE ÖLÇER (yalnız yerel parti önbellekleri veri/fabrika/kalip-parti-*.json; yazma yok, model yok, bedel 0):
#   - parti başına soru, hakem kararı olan, hakem reddi, ret oranı
#   - TAVANSIZ İZİ: saklanan kaynak_metin_ozet > 4.500 kr olan soru sayısı (eski tavanda imkânsız)
#   - dönem: önbellek dosyası 66c413f6 sonrası değişmiş VE tavansız izi taşıyorsa "TAVANSIZ",
#     değişmemişse "ÖNCE", değişmiş ama iz yoksa "BELİRSİZ" (yeniden hakem, çizim, senkron da dosyayı değiştirir)
#  ⚠ KARIŞTIRICI: 7223deb6 (15.09 19:36, SGS GM oturumu) KAPI-HG'yi aynı akşam değiştirdi
#    (tutar/birim izleyen sayı hesap kodu sayılmıyor) — muhasebe partilerinde ret farkının bir kısmı ondan gelebilir.
#  ⚠ Hakem kararında tarih yok; dönem ayrımı dosya zamanı + iz ile YAKLAŞIKTIR.
#
#  15.09 ~21:20 EK (Cem "1.2.3 üçünüde yap", GM önerisi 1): aynı akşam ÜÇ değişiklik girdi; ret farkı
#  hangisine ait ayrılabilsin diye her parti satırı "hangi değişiklik açık olabilirdi" etiketini taşır:
#   HG = 7223deb6 KAPI-HG (19:36:44, üç sınav) · TAVANSIZ = 66c413f6 (19:40:07, üç sınav)
#   IT = fb80f8a4 KAPI-İT ilgisiz TEORİ süzgeci (21:01:34, varsayılan YALNIZ SGS; SMMM/KGK -IlgisizTeoriSuzgeci ac ister)
#  Kural: dosya değişim anı ≥ commit anı ise değişiklik "açık olabilir" (üst sınır; dosyada eski sorular da durur).
#  İT izi: model yazımı soruda kaynak_adlar'da konu köküyle eşleşmeyen TEORİ notu sayısı (süzgeç açıkken yeni
#  sorularda 0 olmalı). Kök mantığı kalip-parti-uret.ps1 KAPI-İT bloğuyla aynı (Katla2 + genel kelime listesi).
#
#  Çıktı: veri/tavan-izleme.json (RaporYaz: sonuç değişmediyse dosyaya dokunmaz)
#  Kullanım: powershell -NoProfile -File arac/tavan-izleme.ps1 [-Ders 'fmuh']
# ============================================================================
param([string]$Ders = '')
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'rapor-yaz.ps1')
$degisimAni = [datetime]'2026-09-15T19:40:07'
$eskiTavan = 4500
$degisiklikler = @(
  [pscustomobject]@{ kod='HG';       commit='7223deb6'; an=[datetime]'2026-09-15T19:36:44'; sinavlar=@('SGS','SMMM','KGK'); aciklama='KAPI-HG tutar/birim izleyen sayı hesap kodu sayılmaz' },
  [pscustomobject]@{ kod='TAVANSIZ'; commit='66c413f6'; an=[datetime]'2026-09-15T19:40:07'; sinavlar=@('SGS','SMMM','KGK'); aciklama='kaynak paketi tavansız' },
  [pscustomobject]@{ kod='IT';       commit='fb80f8a4'; an=[datetime]'2026-09-15T21:01:34'; sinavlar=@('SGS');               aciklama='KAPI-İT ilgisiz TEORİ notu süzgeci (varsayılan yalnız SGS)' }
)
$itGenel = @('hesap','hesabi','kaydi','kayit','tutar','islem','isletme','teori','notu','hesaplama','yontem','yontemi','ornek','uygulama','tanimi','turleri','genel','temel','ilke','ilkesi')
function Katla2([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
        -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
        -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}
function IlgisizTeoriSayisi($kayit){
  if($kayit.PSObject.Properties['yazar'] -and "$($kayit.yazar)" -eq 'GM'){ return -1 }
  $adlar = @($kayit.kaynak_adlar | ForEach-Object { "$_" } | Where-Object { $_ })
  $kokler = @([regex]::Matches((Katla2 "$($kayit.konu)"),'[a-z]{4,}') | ForEach-Object { $_.Value } | Where-Object { $itGenel -notcontains $_ } | ForEach-Object { if($_.Length -gt 5){ $_.Substring(0,5) } else { $_ } } | Select-Object -Unique)
  if(-not $adlar.Count -or -not $kokler.Count){ return -1 }
  $sayi = 0
  foreach($ad in $adlar){ if($ad -notmatch '^(TEORI|Teori Notu)'){ continue }; $adK = Katla2 $ad; if(-not @($kokler | Where-Object { $adK.Contains($_) }).Count){ $sayi++ } }
  return $sayi
}

$partiSatirlari = New-Object System.Collections.Generic.List[object]
foreach($dosya in (Get-ChildItem (Join-Path $depoKok 'veri\fabrika') -Filter 'kalip-parti-*.json')){
  if($dosya.Name -match 'prova-'){ continue }
  if($Ders -and $dosya.Name -notmatch [regex]::Escape($Ders)){ continue }
  try{ $onbellek = Get-Content $dosya.FullName -Raw -Encoding UTF8 | ConvertFrom-Json }catch{ continue }
  $soruSayisi=0; $hakemli=0; $retSayisi=0; $izSayisi=0; $itOlculen=0; $itIlgisizSoru=0
  foreach($ozellik in $onbellek.PSObject.Properties){
    if($ozellik.Name -notlike 'kp-*'){ continue }
    $kayit = $ozellik.Value
    if(-not $kayit -or -not $kayit.PSObject.Properties['soru'] -or -not "$($kayit.soru)"){ continue }
    $soruSayisi++
    if($kayit.PSObject.Properties['hakem'] -and $kayit.hakem -and "$($kayit.hakem.karar)"){ $hakemli++; if("$($kayit.hakem.karar)" -ne 'EVET'){ $retSayisi++ } }
    if($kayit.PSObject.Properties['kaynak_metin_ozet'] -and "$($kayit.kaynak_metin_ozet)".Length -gt $eskiTavan){ $izSayisi++ }
    if($kayit.PSObject.Properties['kaynak_adlar']){ $ilgisiz = IlgisizTeoriSayisi $kayit; if($ilgisiz -ge 0){ $itOlculen++; if($ilgisiz -gt 0){ $itIlgisizSoru++ } } }
  }
  if(-not $soruSayisi){ continue }
  $sinav = if($dosya.Name -match '-kgk-'){ 'KGK' } elseif($dosya.Name -match 'smmm|-yet-|bitirme'){ 'SMMM' } else { 'SGS' }
  $donem = if($dosya.LastWriteTime -lt $degisimAni){ 'ONCE' } elseif($izSayisi -gt 0){ 'TAVANSIZ' } else { 'BELIRSIZ' }
  $acikKodlar = @($degisiklikler | Where-Object { $dosya.LastWriteTime -ge $_.an -and $_.sinavlar -contains $sinav } | ForEach-Object { $_.kod })
  $partiSatirlari.Add([pscustomobject]@{
    parti = ($dosya.BaseName -replace '^kalip-parti-','')
    sinav = $sinav
    donem = $donem
    acik_olabilir = $(if($acikKodlar.Count){ $acikKodlar -join '+' } else { 'HICBIRI' })
    it_olculen = $itOlculen
    ilgisiz_teorili_soru = $itIlgisizSoru
    soru = $soruSayisi
    hakemli = $hakemli
    ret = $retSayisi
    ret_orani = $(if($hakemli){ [math]::Round(100.0*$retSayisi/$hakemli,1) } else { $null })
    tavansiz_izi = $izSayisi
    dosya_zamani = $dosya.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
  })
}

$ozet = New-Object System.Collections.Generic.List[object]
foreach($grup in ($partiSatirlari.ToArray() | Group-Object sinav,donem,acik_olabilir | Sort-Object Name)){
  $g=@($grup.Group); $hakemToplam=($g | Measure-Object hakemli -Sum).Sum; $retToplam=($g | Measure-Object ret -Sum).Sum
  $itToplam=($g | Measure-Object it_olculen -Sum).Sum; $ilgisizToplam=($g | Measure-Object ilgisiz_teorili_soru -Sum).Sum
  $ozet.Add([pscustomobject]@{ sinav=$g[0].sinav; donem=$g[0].donem; acik_olabilir=$g[0].acik_olabilir; parti=$g.Count; hakemli=$hakemToplam; ret=$retToplam; ret_orani=$(if($hakemToplam){ [math]::Round(100.0*$retToplam/$hakemToplam,1) } else { $null }); tavansiz_izi=($g | Measure-Object tavansiz_izi -Sum).Sum; ilgisiz_teorili_soru_orani=$(if($itToplam){ [math]::Round(100.0*$ilgisizToplam/$itToplam,1) } else { $null }) })
}

$cikti = [ordered]@{
  olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  degisim = '66c413f6 kaynak paketi tavansız (15.09 19:40); karıştırıcı 7223deb6 KAPI-HG (15.09 19:36); fb80f8a4 KAPI-İT (15.09 21:01, varsayılan yalnız SGS)'
  degisiklikler = @($degisiklikler | ForEach-Object { [ordered]@{ kod=$_.kod; commit=$_.commit; an=$_.an.ToString('yyyy-MM-dd HH:mm:ss'); sinavlar=($_.sinavlar -join ','); aciklama=$_.aciklama } })
  kural = 'ONCE: dosya değişimden önce · TAVANSIZ: sonra değişmiş + kaynak_metin_ozet > 4.500 kr izi · BELIRSIZ: sonra değişmiş, iz yok · acik_olabilir: dosya zamanı ≥ commit anı olan değişiklikler (üst sınır) · ilgisiz_teorili_soru_orani: model yazımı soruların kaynak listesinde konuyla ilgisiz TEORİ notu olan payı (KAPI-İT açıkken yeni sorularda düşmeli)'
  ozet = $ozet.ToArray()
  partiler = $partiSatirlari.ToArray() | Sort-Object donem,sinav,parti
}
[void](RaporYaz -Hedef (Join-Path $depoKok 'veri\tavan-izleme.json') -Nesne $cikti -Sessiz)
foreach($satir in $ozet){ "{0,-5} {1,-9} {2,-16} parti {3,4} · hakemli {4,6} · ret {5,5} · ret oranı %{6} · tavansız izi {7} · ilgisiz TEORİ'li soru %{8}" -f $satir.sinav,$satir.donem,$satir.acik_olabilir,$satir.parti,$satir.hakemli,$satir.ret,$satir.ret_orani,$satir.tavansiz_izi,$satir.ilgisiz_teorili_soru_orani }
$yeni = @($partiSatirlari.ToArray() | Where-Object { $_.donem -eq 'TAVANSIZ' })
if($yeni.Count){ "TAVANSIZ dönem partileri:"; foreach($p in ($yeni | Sort-Object parti)){ "  {0,-40} {4,-16} soru {1,3} · ret %{2} · iz {3}" -f $p.parti,$p.soru,$p.ret_orani,$p.tavansiz_izi,$p.acik_olabilir } } else { "TAVANSIZ dönem partisi henüz yok (karşılaştırma için yeni üretim bekleniyor)." }
