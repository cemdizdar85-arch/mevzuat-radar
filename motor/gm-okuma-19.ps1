# gm-okuma-19.ps1 - 05.08.2026 gece  (BOM'lu kaydedilmeli)
# GM IKINCI GOZ TURU: fabrika deposunda gmDenetim'siz gorunen 17 soru yeniden
# okundu (Cem: "okuma yutma onlar olsun"). SONUC: 17/17 mevcut durumla UYUMLU -
# 15 gm-onay dogru, 2 kasa-mukerrer dogru. TTK 482/483 ve VUK 359 sorulari
# ambardan birinci elden teyit edildi (iskat yetkisi m.482/2, usul m.483/1-2).
#
# Bu betik yalniz UC kucuk kusuru duzeltir:
#  1) e7ac546a: aciklamadaki "simdiki zaman eki '-uyor'" ifadesi dilbilgisel
#     olarak gevsekti (ek -yor'dur; u yardimci unludur) - aciklama netlestirildi.
#  2) 7602eeac: konu etiketi 'balkan antanti' idi, soru bir YAZIM sorusu -
#     etiket 'kisa cizgi kullanimi' yapildi (karne/istatistik dogru saysin).
#  3) 40a147aa + 607e9bf4: ayni kurali (sayi+isim bilesik sifat) test ediyor -
#     benzerGrup etiketi (quiz bir oturumda gruptan 1 soru servis etmeli).

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$GRUP = @{ '40a147aa'='yd-bilesik-sifat-sayi'; '607e9bf4'='yd-bilesik-sifat-sayi' }
$ist = [ordered]@{ aciklamaDuzeltildi=0; konuDuzeltildi=0; grupEtiketlendi=0; ikinciGozDamgasi=0 }
$hedefIds = @('93fc62d5','d03eab47','3ed39549','e7ac546a','a7333bf4','40a147aa','7602eeac','607e9bf4','87f6762e','0021f87f','74e9181e','af48374e','88126c74','a975cf82','8d8f1464','eba52857','0a901bdd')

foreach($d in @(Get-ChildItem $fabrikaDir -Filter toplu-*.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false
  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    $id = "$($s.id)"
    if($hedefIds -notcontains $id){ continue }

    if($id -eq 'e7ac546a'){
      $s.aciklama.A = "Doğru: kök olan 'koş' ile ek bloğu '-uyor' (yardımcı ünlü u + şimdiki zaman eki -yor) kısa çizgiyle bitişik ve boşluksuz ayrılmıştır; gösterimin dayandığı sınır hece değil, gerçek kök-ek sınırıdır."
      $ist.aciklamaDuzeltildi++; $degisti = $true
    }
    if($id -eq '7602eeac' -and "$($s.konu)" -eq 'balkan antanti'){
      $s.konu = 'kisa cizgi kullanimi'
      $ist.konuDuzeltildi++; $degisti = $true
    }
    if($GRUP.ContainsKey($id)){
      $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue $GRUP[$id] -Force
      $ist.grupEtiketlendi++; $degisti = $true
    }
    $s | Add-Member -NotePropertyName gmIkinciGoz -NotePropertyValue "05.08.2026 gece - GM ikinci okuma: karar mevcut durumla uyumlu (TTK 482/483 + VUK 359 ambar teyitli)" -Force
    $ist.ikinciGozDamgasi++; $degisti = $true
  }
  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 19 (ikinci goz, 05.08) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-20} {1}" -f $k, $ist[$k]) }
if($ist.ikinciGozDamgasi -ne 17){ Write-Host ("UYARI: 17 beklenirken {0} damgalandi" -f $ist.ikinciGozDamgasi) }
