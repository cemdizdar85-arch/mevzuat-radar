# gm-okuma-04.ps1 - 28.07.2026
# GM OKUMASI, PARTI 4: Yabanci Dil, 'katman1-temiz' 34 soru + havuz denge etiketleri.
#
# YONTEM: her soru elle okundu, gramer kurali dogrulandi. Matematik gibi Yabanci Dil'de
# de "kaynak soyledigini soyluyor mu" sorunu yoktur; kural ya dogrudur ya degildir.
# SONUC: 34 sorunun 34'unun da cevabi DOGRU. Sifir hata.
#
# ANCAK HAVUZ TEKDUZE. Olculdu:
#   * 34 sorunun 16'si "relative clause - where" konusunda (%47)
#   * bunlarin 9'u BIREBIR AYNI kalibi test ediyor: yer ismi + "where"
#     (warehouse, studio, hotel, restaurant, office, startup, Istanbul x2)
#   * Matematik partisinde de ayni sorun vardi: 51 sorunun 12'si "sabit fonksiyon"
#
# Bu bir CEVAP hatasi degil, URETIM PLANI hatasi. Sorular silinmiyor (parasi odendi);
# yerine BENZERLIK GRUBU etiketleniyor. Quiz motoru bir oturumda ayni gruptan
# EN FAZLA BIR soru servis etmelidir.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

# id -> benzerlik grubu
$GRUP = @{
  # YD: yer ismi + where (dokuz soru ayni kalip)
  'e04d6119'='yd-where-yer'; '5090cbea'='yd-where-yer'; '5b0235f4'='yd-where-yer'
  '7d7f3142'='yd-where-yer'; '63c15edb'='yd-where-yer'; '6249c5ca'='yd-where-yer'
  '86ed467d'='yd-where-yer'; '9f6d168f'='yd-where-yer'; 'afc483da'='yd-where-yer'
  # YD: "in which" <-> "where" donusumu
  '40187b62'='yd-where-donusum'; '5263ac1e'='yd-where-donusum'; '92f76684'='yd-where-donusum'
  # YD: soyut isim + where
  '9e3cb68b'='yd-where-soyut'; '1c408491'='yd-where-soyut'
  # YD: no sooner ... than
  '642e049a'='yd-no-sooner-than'; 'f92f4c9f'='yd-no-sooner-than'
  # Matematik: sabit fonksiyon (12 soru)
  '08634fcb'='mat-sabit-fonksiyon'; '817eb2d3'='mat-sabit-fonksiyon'; 'f3213791'='mat-sabit-fonksiyon'
  '3c5e2528'='mat-sabit-fonksiyon'; 'ea2db0b6'='mat-sabit-fonksiyon'; '4feafc42'='mat-sabit-fonksiyon'
  '14440331'='mat-sabit-fonksiyon'; 'e31ea4c5'='mat-sabit-fonksiyon'; '6ac85398'='mat-sabit-fonksiyon'
  'd999c894'='mat-sabit-fonksiyon'; '0aba624a'='mat-sabit-fonksiyon'; '023bc1cc'='mat-sabit-fonksiyon'
}

$ist = [ordered]@{ ydOnaylandi=0; grupEtiketlendi=0 }
$grupSayac = @{}

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    $id = "$($s.id)"

    # --- Yabanci Dil onayi
    if("$($s.durum)" -eq 'katman1-temiz' -and "$($s.ders)" -eq 'Yabanci Dil'){
      $s.durum = 'gm-onay'
      $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM elle okudu, gramer kurali dogrulandi (28.07). Dil dersinde kaynak mevzuat maddesi degil, kuralin kendisidir." -Force
      $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
      $ist.ydOnaylandi++; $degisti = $true
    }

    # --- benzerlik grubu etiketi (durum ne olursa olsun)
    if($GRUP.ContainsKey($id)){
      $g = $GRUP[$id]
      $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue $g -Force
      if($grupSayac.ContainsKey($g)){ $grupSayac[$g]++ } else { $grupSayac[$g] = 1 }
      $ist.grupEtiketlendi++; $degisti = $true
    }
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 4 (Yabanci Dil + denge) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-18} {1}" -f $k, $ist[$k]) }
Write-Host ""
Write-Host "--- benzerlik gruplari (quiz motoru bir oturumda gruptan 1 soru servis etmeli):"
$grupSayac.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { Write-Host ("    {0,-24} {1} soru" -f $_.Key, $_.Value) }
$eksik = @($GRUP.Keys | Where-Object { $true }).Count - $ist.grupEtiketlendi
if($eksik -ne 0){ Write-Host ("UYARI: {0} id etiketlenemedi (listede {1}, bulunan {2})" -f $eksik, $GRUP.Count, $ist.grupEtiketlendi) }
