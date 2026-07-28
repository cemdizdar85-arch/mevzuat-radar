# gm-okuma-11.ps1 - 28.07.2026  (BOM'lu kaydedilmeli)
# GM OKUMASI, PARTI 11: Hukuk dersinin VUK + KDVK'ya dayanan 16 sorusu.
#
# AMBARDAN BIRINCI ELDEN OKUNAN MADDELER — hepsi DOGRU atiflanmis:
#   VUK m.29  ikmalen tarh · m.30 resen tarh · m.128 yoklamaya yetkililer
#   VUK m.131 yoklama fisi ve imzadan kacinma · m.134 incelemenin maksadi
#   VUK m.135 incelemeye yetkililer · m.142 arama (sulh ceza hakimi karari)
#   VUK m.148 bilgi verme odevi
#   KDVK m.2/5 trampa iki ayri teslim · m.3/a isletmeden cekme
#   KDVK m.10/a teslim/hizmet ani · m.10/c kisim kisim teslim
#   KDVK m.11/1-a + m.12/2 hizmet ihraci
#
# 16 SORUNUN 16'SININ DA CEVABI DOGRU. Bu blokta ATIF hatasi CIKMADI - vergi
# maddelerini model dogru biliyor. Ancak IKI SIKKIN METNI kanunla tam ortusmuyordu:
#
#   a80f3722 (m.135): sik, yetkilileri sayarken "VEYA VERGI DAIRESI MUDURLERI"ni
#            atlamis. Kanun: "Vergi Mufettisleri, Vergi Mufettis Yardimcilari, ilin
#            en buyuk mal memuru veya vergi dairesi mudurleri tarafindan yapilir."
#            Eksik sayim, adayin "vergi dairesi muduru inceleme yapamaz" diye
#            ogrenmesine yol acardi - ustelik B sikki tam bunu iddia ediyor.
#   ce5cb941 (m.148): sikkin kuyrugu "sozlu istenirse bilgi yaziya gecirilip
#            ilgiliye imzalattirilir" diyordu. Bu m.148'de YOK; o usul yoklama
#            fisine (m.131) aittir. Kanun: "Bilgiler yazi veya sozle istenilir.
#            Sozle istenen bilgileri vermeyenlere keyfiyet YAZI ILE TEKIT ve cevap
#            vermeleri icin kendilerine munasip bir muhlet tayin olunur."

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$ist = [ordered]@{ onay=0; sikDuzeltildi=0; gorulen=0 }

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'katman1-temiz' -or "$($s.ders)" -ne 'Hukuk'){ continue }
    if("$($s.kaynak)" -notmatch '213|VUK|KDV'){ continue }
    $id = "$($s.id)"; $ist.gorulen++

    if($id -eq 'a80f3722'){
      $s.siklar.E = "Vergi Müfettişleri, Vergi Müfettiş Yardımcıları, ilin en büyük mal memuru veya vergi dairesi müdürleri vergi incelemesi yapmaya yetkilidir; ayrıca Gelir İdaresi Başkanlığının merkez ve taşra teşkilatında müdür kadrolarında görev yapanlar her hâlde bu yetkiyi haizdir"
      $s.aciklama.E = "Doğru. VUK m.135 yetkilileri şöyle sayar: Vergi Müfettişleri, Vergi Müfettiş Yardımcıları, ilin en büyük mal memuru veya vergi dairesi müdürleri. Buna ek olarak GİB merkez ve taşra teşkilatında müdür kadrolarında görev yapanlar her hâl ve takdirde vergi inceleme yetkisini haizdir. Yani yetki ne yalnız Vergi Müfettişlerine ne de yalnız vergi dairesi müdürüne aittir."
      $s | Add-Member -NotePropertyName gmNot -NotePropertyValue "Şık düzeltildi: eski metin 'vergi dairesi müdürleri'ni saymıyordu; aday m.135'i eksik öğrenirdi." -Force
      $ist.sikDuzeltildi++
    }

    if($id -eq 'ce5cb941'){
      $s.siklar.E = "Kamu idareleri, mükellefler ve mükellefle iş ilişkisinde bulunan gerçek/tüzel kişiler istenen bilgiyi vermekle yükümlüdür; bilgiler yazı veya sözle istenir, sözle istenen bilgiyi vermeyenlere durum yazıyla tekit edilip cevap için uygun bir süre verilir"
      $s.aciklama.E = "Doğru. VUK m.148: 'Kamu idare ve müesseseleri, mükellefler veya mükelleflerle muamelede bulunan diğer gerçek ve tüzel kişiler... istenecek bilgileri vermeye mecburdurlar. Bilgiler yazı veya sözle istenilir. Sözle istenen bilgileri vermeyenlere keyfiyet yazı ile tekit ve cevap vermeleri için kendilerine münasip bir mühlet tayin olunur.' Ayrıca ilgililer bilgi istenmek üzere vergi dairesine zorla getirilemez."
      $s | Add-Member -NotePropertyName gmNot -NotePropertyValue "Şık düzeltildi: eski metnin 'sözlü istenirse yazıya geçirilip imzalattırılır' kuyruğu m.148'de yoktur; o usul yoklama fişine (m.131) aittir." -Force
      $ist.sikDuzeltildi++
    }

    $s.durum = 'gm-onay'
    $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM okudu (28.07): VUK m.29,30,128,131,134,135,142,148 ve KDVK m.2/5, 3/a, 10/a, 10/c, 11-12 ambardan birinci elden okundu; cevap ve atıf doğrulandı." -Force
    $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
    $g = if("$($s.kaynak)" -match 'KDV'){'huk-kdv-vdo'} else {'huk-vuk-tarh-oncesi'}
    $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue $g -Force
    $ist.onay++; $degisti = $true
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 11 (Hukuk / VUK+KDV) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-16} {1}" -f $k, $ist[$k]) }

# --- yazma sonrasi METIN dogrulamasi
Write-Host ""
$hata = 0
foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    if("$($s.id)" -eq 'a80f3722' -and "$($s.siklar.E)" -notmatch 'vergi dairesi müdürleri'){ $hata++; Write-Host "  DUZELMEDI: a80f3722" }
    if("$($s.id)" -eq 'ce5cb941' -and "$($s.siklar.E)" -match 'imzalattırılır'){ $hata++; Write-Host "  DUZELMEDI: ce5cb941" }
  }
}
if($hata -eq 0){ Write-Host "   temiz — şık düzeltmeleri metinde doğrulandı" } else { Write-Host "KIRMIZI"; exit 1 }
