# gm-okuma-08.ps1 - 28.07.2026  (BOM'lu kaydedilmeli)
# GM OKUMASI, PARTI 8: Maliye 21 + Ekonomi 13 = 34 soru ('katman1-temiz').
#
# YONTEM: kavram sorulari teoriyle, hesap sorusu elle hesaplanarak, 5018 atiflari
# AMBARDAN birinci elden okunarak denetlendi.
#   5018 m.7  = Mali saydamlik (teyit edildi - 4 soru dogru atif yapmis)
#   5018 m.41 = Faaliyet raporlari (teyit edildi - 2 soru dogru)
#   5018 m.49 = Muhasebe sistemi; m.50 = kayit zamani/tahakkuk (ayri maddeler)
#   5018 m.9  = Stratejik planlama ve performans esasli butceleme
#
# SONUC: 34 sorunun 34'unun de CEVABI DOGRU.
#   Ornek dogrulama: [1] SM 90.000 + GMSI 40.000 = 130.000 matrah;
#   110.000 x %15 = 16.500, kalan 20.000 x %20 = 4.000, toplam 20.500 TL -> C dogru.
#
# IKI ATIF HATASI DUZELTILDI:
#   0ae69a9d: kaynak "5018 m.9 (konjonkturel etkilerden ayristirma ilkesi)" yaziyordu.
#             m.9 STRATEJIK PLANLAMA'yi duzenler; boyle bir ilke icermez. Yapisal
#             butce dengesi bir MALIYE TEORISI kavramidir, 5018 hukmu degil.
#   047b1c05: kaynak m.49'a tahakkuk esasini yuklemis; tahakkuk/kayit zamani m.50'dir.
#
# Bu iki hata da bugunku desenle birebir ortusuyor: cevap dogru, MADDE NUMARASI yanlis.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$GRUP = @{}
foreach($id in @('b2d376c1','fd2a66ea','85239b8c','5fc8233a','e067f5a1','fc9164e3','0a4ca968','32f16092','24050667')){ $GRUP[$id]='eko-marshall-lerner' }
foreach($id in @('ae004b93','15f8cc4c','8dc56cc4','9b7d826c')){ $GRUP[$id]='mal-saydamlik-m7' }
foreach($id in @('b32385ce','1166340f')){ $GRUP[$id]='mal-faaliyet-raporu-m41' }
foreach($id in @('3a47d2e2','30feaecb','4175bc2d','47991c06')){ $GRUP[$id]='mal-parafiskal' }
foreach($id in @('b9071dbb','160b3f72','9613bcb7','edb75186')){ $GRUP[$id]='mal-vergi-siniflandirma' }

$ist = [ordered]@{ onay=0; kaynakDuzeltildi=0; grupEtiketlendi=0 }

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'katman1-temiz'){ continue }
    if(@('Maliye','Ekonomi') -notcontains "$($s.ders)"){ continue }
    $id = "$($s.id)"

    if($id -eq '0ae69a9d'){
      $s.kaynak = "Maliye teorisi — yapısal (konjonktürel olarak düzeltilmiş) bütçe dengesi kavramı; OECD/IMF mali izleme çerçevesi"
      $s | Add-Member -NotePropertyName gmNot -NotePropertyValue "Kaynak düzeltildi: eskiden '5018 m.9 (konjonktürel etkilerden ayrıştırma ilkesi)' yazıyordu. 5018 m.9 stratejik planlama ve performans esaslı bütçelemeyi düzenler; konjonktürel ayrıştırmaya dair bir hüküm içermez. Yapısal bütçe dengesi bir maliye teorisi kavramıdır, kanun hükmü değildir." -Force
      $ist.kaynakDuzeltildi++
    }
    if($id -eq '047b1c05'){
      $s.kaynak = "5018 s. Kanun m.49 (muhasebe sistemi) ve m.50 (kayıt zamanı — tahakkuk esası)"
      $s | Add-Member -NotePropertyName gmNot -NotePropertyValue "Kaynak düzeltildi: tahakkuk esası/kayıt zamanı m.49'da değil m.50'de düzenlenmiştir." -Force
      $ist.kaynakDuzeltildi++
    }

    if($GRUP.ContainsKey($id)){ $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue $GRUP[$id] -Force; $ist.grupEtiketlendi++ }

    $s.durum = 'gm-onay'
    $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM okudu (28.07): kavram teoriyle, hesap elle, 5018 atıfları ambardan birinci elden denetlendi. Cevap doğrulandı." -Force
    $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
    $ist.onay++; $degisti = $true
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 8 (Maliye + Ekonomi) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-18} {1}" -f $k, $ist[$k]) }

# --- yazma sonrasi METIN dogrulamasi
Write-Host ""
foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($x.sorular)){
    if("$($s.id)" -eq '0ae69a9d' -or "$($s.id)" -eq '047b1c05'){ Write-Host ("  {0} -> {1}" -f $s.id, $s.kaynak) }
  }
}
if($ist.onay -ne 34){ Write-Host ("UYARI: beklenen 34, onaylanan {0}" -f $ist.onay) }
