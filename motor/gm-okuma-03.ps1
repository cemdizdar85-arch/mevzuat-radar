# gm-okuma-03.ps1 - 28.07.2026
# GM OKUMASI, PARTI 3: Matematik-Istatistik, 'katman1-temiz' 51 soru.
#
# YONTEM: her soru ELLE COZULDU ve isaretli cevapla karsilastirildi. Matematikte
# "kaynak soyledigini soyluyor mu" sorunu YOKTUR; dogrulama tam ve kesindir.
#
# SONUC: 51 sorunun 51'i de MATEMATIKSEL OLARAK DOGRU. Sifir cevap hatasi.
#   (Karsilastirma: mevzuat sorularinda 17 okumada 4 hata cikti - %24.)
#
# IKI KUSUR BULUNDU:
#   1) MUKERRER CIFT (ayni soru, farkli sik dizilimi - yeni kok+siklar kurali bunu
#      yakalayamaz, cunku siklar farkli. GM okumasi yakaladi):
#        e656afde ~ a09bd285  : lim(x->2)(x^2-4)/(x-2) = 4
#        dd4f450e ~ 99af87e9  : lim(x->0) sin(5x)/x   = 5
#      Her ciftten biri tutuldu, digeri red.
#   2) KONU DENGESIZLIGI: 51 sorunun 12'si "sabit fonksiyon" konusunda (%24).
#      Bu bir cevap hatasi degil, URETIM PLANI hatasi; konu listesi tek konuya
#      asiri agirlik vermis. Sorular gecerli, ancak yayinda konu dagilimi
#      dengelenmeden hepsi ayni havuza konmamali.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

# tutulan <- red edilen
$MUKERRER = @{
  '99af87e9' = "GM RED (28.07): dd4f450e ile ayni soru - lim(x->0) sin(5x)/x. Siklarin dizilimi farkli oldugu icin otomatik mukerrer kontrolu yakalayamadi, GM okumasinda goruldu. dd4f450e tutuldu (yapay baglam icermiyor)."
  'e656afde' = "GM RED (28.07): a09bd285 ile ayni soru - lim(x->2)(x^2-4)/(x-2). Siklarin dizilimi farkli oldugu icin otomatik mukerrer kontrolu yakalayamadi, GM okumasinda goruldu. a09bd285 tutuldu (celdiricileri daha iyi: -4 isaret hatasini yakaliyor)."
}

$ist = [ordered]@{ onaylandi=0; mukerrerRed=0; toplamGorulen=0 }
$konuSayac = @{}

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'katman1-temiz'){ continue }
    if("$($s.ders)" -ne 'Matematik-Istatistik'){ continue }
    $ist.toplamGorulen++
    $id = "$($s.id)"
    $k = "$($s.konu)"; if($konuSayac.ContainsKey($k)){ $konuSayac[$k]++ } else { $konuSayac[$k] = 1 }

    if($MUKERRER.ContainsKey($id)){
      $s.durum = 'karantina-red'
      $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue $MUKERRER[$id] -Force
      $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
      $ist.mukerrerRed++; $degisti = $true
      continue
    }

    $s.durum = 'gm-onay'
    $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM elle cozdu, isaretli cevap dogrulandi (28.07). Matematik sorusunda kaynak teyidi gerekmez; dogrulama hesaplama ile tamdir." -Force
    $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
    $ist.onaylandi++; $degisti = $true
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 3 (Matematik) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-16} {1}" -f $k, $ist[$k]) }
Write-Host ""
Write-Host "--- konu dagilimi (denge kontrolu):"
$konuSayac.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { Write-Host ("    {0,-34} {1}" -f $_.Key, $_.Value) }
if($ist.toplamGorulen -ne 51){ Write-Host ("UYARI: beklenen 51, gorulen {0}" -f $ist.toplamGorulen) }
