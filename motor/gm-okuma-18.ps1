# gm-okuma-18.ps1 - 28.07.2026  (BOM'lu kaydedilmeli)
# GM OKUMASI, PARTI 18 — karantinadaki Yabanci Dil blogu: 80 soru.
#
# SONUC: 80 sorunun 78'i DOGRU. K2 80 itirazinin 79'unda HAKSIZ (%1,25 isabet).
#
# NEDEN BU KADAR DUSUK: dil sorularinda "kaynak maddesi" diye bir sey yok.
# K2'nin istemine giden tek sey soru + isaretli cevap; dayanacak bir metin
# olmadigi icin itirazi saf MODEL ANLASMAZLIGINDAN ibaret kaliyor. Yani burada
# denetci bir sey DOGRULAMIYOR, sadece kendi cevabini soyluyor - ve tutmayinca
# soru karantinaya dusuyor. Bu, parasi odenmis 80 sorunun bosuna beklemesi demek.
# KARAR: dil derslerinde K2 itirazi TEK BASINA karantina sebebi olmamali.
#
# IKI GERCEK KUSUR:
#   0c0716a2 -> RED. "this exam is ___ important" sorusunda isaretli cevap
#     "absolutely". Oysa "important" DERECELENEBILIR (gradable) bir sifattir;
#     "absolutely" derecelenemeyen (ungradable/extreme) sifatlarla kullanilir:
#     absolutely essential, absolutely shocking. Ustelik siklardaki "very",
#     "quite" ve "rather" UCU DE dogru olur - yani hem cevap anahtari yanlis
#     hem de birden fazla dogru sik var. Cevap anahtari degistirilerek
#     kurtarilamaz. (Karsilastirma: cbb2ebf5 "absolutely exhausted" ve 81353e84
#     "absolutely shocking" DOGRU - cunku exhausted/shocking derecelenemez.)
#   c96dfd11 -> IKI DOGRU SIK. "She said that she ___ the project by the end of
#     the week" sorusunda hem D "would have finished" hem E "would finish"
#     dilbilgisel olarak dogru. E sikki, dolayli anlatimda YANLIS olan
#     "will finish" ile degistirildi; D tek dogru kaldi.
#
# HAVUZ TEKDUZELIGI (yine): so that/wake the baby 2 kez · take your umbrella/
# laptop 2 kez · sifat sirasi 3 kez · zarf sirasi 2 kez · since 2015 2 kez ·
# however 2 kez. Etiketlendi.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$GRUP = @{}
foreach($id in @('e3844a42','1b924591')){ $GRUP[$id]='yd-so-that' }
foreach($id in @('54ef4c5e','190d947b')){ $GRUP[$id]='yd-take-vs-bring' }
foreach($id in @('5b32bbbc','767249f7','18a324bc')){ $GRUP[$id]='yd-sifat-sirasi' }
foreach($id in @('acb43c50','ef5d995b')){ $GRUP[$id]='yd-zarf-sirasi' }
foreach($id in @('5443c8ce','7466a236')){ $GRUP[$id]='yd-since-for' }
foreach($id in @('e66c4f78','9436368b','a856eaa2')){ $GRUP[$id]='yd-however' }
foreach($id in @('fdcf856f','52b6cce0','d84adb11','08f837d3')){ $GRUP[$id]='yd-correlative' }
foreach($id in @('a4e1a9c0','93f9a32a','69cbef88','3060f287','3c4551aa')){ $GRUP[$id]='yd-whose' }
foreach($id in @('81353e84','cbb2ebf5')){ $GRUP[$id]='yd-absolutely-ungradable' }

$RED = @{
  '0c0716a2' = "GM RED (28.07): cevap anahtari dilbilgisel olarak savunulamaz. 'important' DERECELENEBILIR (gradable) bir sifattir; isaretlenen 'absolutely' ise derecelenemeyen (ungradable/extreme) sifatlarla kullanilir - absolutely essential, absolutely shocking. Ayrica siklardaki 'very', 'quite' ve 'rather' UCU DE dogru olur; yani hem cevap yanlis hem birden fazla dogru sik var. Cevap anahtari degistirilerek kurtarilamaz."
}

$ist = [ordered]@{ onay=0; sikDuzeltildi=0; red=0; grupEtiketlendi=0; gorulen=0 }

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'karantina' -or "$($s.ders)" -ne 'Yabanci Dil'){ continue }
    $id = "$($s.id)"; $ist.gorulen++

    if($RED.ContainsKey($id)){
      $s.durum = 'karantina-red'
      $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue $RED[$id] -Force
      $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
      $ist.red++; $degisti=$true; continue
    }

    if($id -eq 'c96dfd11'){
      $s.siklar.E = "will finish"
      $s.aciklama.E = "Yanlış. Ana cümlenin fiili 'said' (geçmiş) olduğu için dolaylı anlatımda 'will' geriye kayar ve 'would' olur; 'will finish' bu yapıda kullanılamaz."
      $s.aciklama.D = "Doğru. 'I will have finished the project by the end of the week' cümlesi dolaylı anlatıma aktarılırken 'will have finished' geriye kayarak 'would have finished' olur. 'by the end of the week' ifadesi de tamamlanmışlık (perfect) anlamını gerektirir."
      $s | Add-Member -NotePropertyName gmNot -NotePropertyValue "Şık düzeltildi: eski E şıkkı 'would finish' idi ve D ile birlikte İKİ DOĞRU ŞIK oluşturuyordu; dolaylı anlatımda yanlış olan 'will finish' ile değiştirildi." -Force
      $ist.sikDuzeltildi++
    }

    if($GRUP.ContainsKey($id)){ $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue $GRUP[$id] -Force; $ist.grupEtiketlendi++ }

    $s.durum = 'gm-onay'
    $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM HAKEMLIK ETTI (28.07): K2 itirazi HAKSIZ. Dil kurali tek tek dogrulandi, isaretli cevap dogru. NOT: dil sorularinda dayanilacak bir kaynak metni olmadigi icin K2'nin itirazi dogrulama degil, sadece kendi cevabini soylemesidir." -Force
    $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
    $ist.onay++; $degisti = $true
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 18 (karantina / Yabanci Dil) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-18} {1}" -f $k, $ist[$k]) }

Write-Host ""
$hata = 0
foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    if("$($s.id)" -eq 'c96dfd11' -and "$($s.siklar.E)" -ne 'will finish'){ $hata++; Write-Host "  SIK DUZELMEDI: c96dfd11/E" }
    if("$($s.id)" -eq '0c0716a2' -and "$($s.durum)" -ne 'karantina-red'){ $hata++; Write-Host "  RED YAZILMADI: 0c0716a2" }
  }
}
if($hata -eq 0){ Write-Host "   temiz — düzeltmeler metinde doğrulandı" } else { Write-Host "KIRMIZI"; exit 1 }
