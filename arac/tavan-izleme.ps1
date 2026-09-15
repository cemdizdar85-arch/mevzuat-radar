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
#  Çıktı: veri/tavan-izleme.json (RaporYaz: sonuç değişmediyse dosyaya dokunmaz)
#  Kullanım: powershell -NoProfile -File arac/tavan-izleme.ps1 [-Ders 'fmuh']
# ============================================================================
param([string]$Ders = '')
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'rapor-yaz.ps1')
$degisimAni = [datetime]'2026-09-15T19:40:07'
$eskiTavan = 4500

$partiSatirlari = New-Object System.Collections.Generic.List[object]
foreach($dosya in (Get-ChildItem (Join-Path $depoKok 'veri\fabrika') -Filter 'kalip-parti-*.json')){
  if($dosya.Name -match 'prova-'){ continue }
  if($Ders -and $dosya.Name -notmatch [regex]::Escape($Ders)){ continue }
  try{ $onbellek = Get-Content $dosya.FullName -Raw -Encoding UTF8 | ConvertFrom-Json }catch{ continue }
  $soruSayisi=0; $hakemli=0; $retSayisi=0; $izSayisi=0
  foreach($ozellik in $onbellek.PSObject.Properties){
    if($ozellik.Name -notlike 'kp-*'){ continue }
    $kayit = $ozellik.Value
    if(-not $kayit -or -not $kayit.PSObject.Properties['soru'] -or -not "$($kayit.soru)"){ continue }
    $soruSayisi++
    if($kayit.PSObject.Properties['hakem'] -and $kayit.hakem -and "$($kayit.hakem.karar)"){ $hakemli++; if("$($kayit.hakem.karar)" -ne 'EVET'){ $retSayisi++ } }
    if($kayit.PSObject.Properties['kaynak_metin_ozet'] -and "$($kayit.kaynak_metin_ozet)".Length -gt $eskiTavan){ $izSayisi++ }
  }
  if(-not $soruSayisi){ continue }
  $sinav = if($dosya.Name -match '-kgk-'){ 'KGK' } elseif($dosya.Name -match 'smmm|-yet-|bitirme'){ 'SMMM' } else { 'SGS' }
  $donem = if($dosya.LastWriteTime -lt $degisimAni){ 'ONCE' } elseif($izSayisi -gt 0){ 'TAVANSIZ' } else { 'BELIRSIZ' }
  $partiSatirlari.Add([pscustomobject]@{
    parti = ($dosya.BaseName -replace '^kalip-parti-','')
    sinav = $sinav
    donem = $donem
    soru = $soruSayisi
    hakemli = $hakemli
    ret = $retSayisi
    ret_orani = $(if($hakemli){ [math]::Round(100.0*$retSayisi/$hakemli,1) } else { $null })
    tavansiz_izi = $izSayisi
    dosya_zamani = $dosya.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
  })
}

$ozet = New-Object System.Collections.Generic.List[object]
foreach($grup in ($partiSatirlari.ToArray() | Group-Object sinav,donem | Sort-Object Name)){
  $g=@($grup.Group); $hakemToplam=($g | Measure-Object hakemli -Sum).Sum; $retToplam=($g | Measure-Object ret -Sum).Sum
  $ozet.Add([pscustomobject]@{ sinav=$g[0].sinav; donem=$g[0].donem; parti=$g.Count; hakemli=$hakemToplam; ret=$retToplam; ret_orani=$(if($hakemToplam){ [math]::Round(100.0*$retToplam/$hakemToplam,1) } else { $null }); tavansiz_izi=($g | Measure-Object tavansiz_izi -Sum).Sum })
}

$cikti = [ordered]@{
  olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  degisim = '66c413f6 kaynak paketi tavansız (15.09 19:40); karıştırıcı 7223deb6 KAPI-HG (15.09 19:36)'
  kural = 'ONCE: dosya değişimden önce · TAVANSIZ: sonra değişmiş + kaynak_metin_ozet > 4.500 kr izi · BELIRSIZ: sonra değişmiş, iz yok'
  ozet = $ozet.ToArray()
  partiler = $partiSatirlari.ToArray() | Sort-Object donem,sinav,parti
}
[void](RaporYaz -Hedef (Join-Path $depoKok 'veri\tavan-izleme.json') -Nesne $cikti -Sessiz)
foreach($satir in $ozet){ "{0,-5} {1,-9} parti {2,4} · hakemli {3,6} · ret {4,5} · ret oranı %{5} · tavansız izi {6}" -f $satir.sinav,$satir.donem,$satir.parti,$satir.hakemli,$satir.ret,$satir.ret_orani,$satir.tavansiz_izi }
$yeni = @($partiSatirlari.ToArray() | Where-Object { $_.donem -eq 'TAVANSIZ' })
if($yeni.Count){ "TAVANSIZ dönem partileri:"; foreach($p in ($yeni | Sort-Object parti)){ "  {0,-40} soru {1,3} · ret %{2} · iz {3}" -f $p.parti,$p.soru,$p.ret_orani,$p.tavansiz_izi } } else { "TAVANSIZ dönem partisi henüz yok (karşılaştırma için yeni üretim bekleniyor)." }
