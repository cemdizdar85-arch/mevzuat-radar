# gm-okuma-06.ps1 - 28.07.2026  (BOM'lu kaydedilmeli - Turkce karakter var)
# GM OKUMASI, PARTI 6: Muh. ve Mali Mus. Meslek Hukuku, 'katman1-temiz' 19 soru.
#
# KAYNAK: 3568 sayili Kanun m.16, 22-30, 43, 45, 48-51 AMBARDAN birinci elden okundu.
#
# TESPIT EDILEN GERCEKLER:
#   m.25/son : "Oda Disiplin Kurulunun kararlarina karsi teblig tarihinden itibaren
#              OTUZ GUN icinde Birlik Disiplin Kuruluna itiraz edilebilir."  -> 30 GUN
#   m.25     : "Uyeler kendi aralarindan bir baskan secerler."
#   m.27     : "Denetleme Kurulu ... Genel Kurula rapor vermekle gorevlidir."
#   m.43     : sir saklama yukumlulugu (m.45 DEGIL; m.45 yasaklar/reklam yasagi)
#   m.30     : Birligin gelirleri = odalardan paylar + malvarligi geliri + ruhsatname
#              ucretleri + "genel hukumler cercevesinde elde edilen BAGIS VE YARDIMLAR"
#              (m.51 = "Bu Kanun yayimi tarihinde yururluge girer" - atif tamamen yanlisti)
#   m.23 dn. : Oda Yonetim Kurulu uye sayisi = binin altinda 5 asil 5 yedek, 1000-5000
#              arasi 7 asil 7 yedek, 5000 uzeri 9 asil 9 yedek (yedek = asil, ama SABIT 5 DEGIL)
#
# EN AGIR BULGU: ayni havuzda hem "15 gun" hem "30 gun" ogreten sorular vardi.
# Aday bu havuzdan calissa BIRBIRIYLE CELISEN iki kural ogrenecekti.
# 19 sorunun 13'unde mudahale gerekti (%68).

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"
$M25 = "3568 s. SMMM K. m.25/son fıkra"

$ist = [ordered]@{ onay=0; cevapAnahtariDuzeltildi=0; metinDuzeltildi=0; red=0; beklet=0 }

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'katman1-temiz'){ continue }
    if("$($s.ders)" -notlike '*Meslek Hukuku*'){ continue }
    $id = "$($s.id)"
    $karar = $null

    switch($id){

      # ---- BEKLET: hukum Kanun'da degil, Odalar/Disiplin Yonetmeliginde. Ambarda yonetmelik yok.
      { $_ -in @('00bc85b5','33d4f51e','695ffde5','cdab9eb7') } {
        $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM BEKLETTI (28.07): sorunun dayandigi hukum 3568 sayili Kanun'da YOK; SMMM ve YMM Odalari Yonetmeligi ile Disiplin Yonetmeliginde duzenleniyor. Bu yonetmelikler ambarda bulunmadigi icin karar verilemedi. Atif yapilan madde de (m.24/m.25/m.26) bu konuyu duzenlemiyor." -Force
        $s | Add-Member -NotePropertyName gerekenKaynak -NotePropertyValue "SMMM/YMM Odalari Yonetmeligi + SMMM ve YMM Disiplin Yonetmeligi" -Force
        $ist.beklet++; $karar='beklet'; break }

      '293e0af8' {
        $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM BEKLETTI (28.07): TURMOB Disiplin Kurulu kararina karsi acilacak davada gorevli mahkemenin Danistay mi yoksa idare mahkemesi mi oldugu 3568'den cikmiyor; Danistay Kanunu m.24 ambarda yok. Sure (60 gun, IYUK m.7) dogru olsa da MERCI teyit edilmeden yayina alinmaz." -Force
        $s | Add-Member -NotePropertyName gerekenKaynak -NotePropertyValue "2575 s. Danistay Kanunu m.24" -Force
        $ist.beklet++; $karar='beklet'; break }

      # ---- RED: kaynak sorunun iddiasini desteklemiyor
      'e056e9af' {
        $s.durum = 'karantina-red'
        $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM RED (28.07): iki ayri hata. (1) Atif m.51'e yapilmis; m.51 'Bu Kanun yayimi tarihinde yururluge girer' hukmudur, Birligin gelirleriyle ilgisi yoktur - dogru madde m.30'dur. (2) m.30 Birligin gelirlerini 'odalardan paylar, malvarligi geliri, ruhsatname ucretleri ve genel hukumler cercevesinde elde edilen BAGIS VE YARDIMLAR' olarak sayar; kanunda 'VASIYET' gecmez. Isaretlenen B sikki 'bagis ve vasiyetler kanunda sayilan gelir kalemleri arasindadir' diyor - bu ifade kanun metniyle dogrulanmiyor." -Force
        $ist.red++; $karar='red'; break }

      # ---- CEVAP ANAHTARI YANLIS: 15 gun -> 30 gun (sik B zaten dogru cevabi tasiyor)
      'e31b9cff' {
        $s.dogru = 'B'
        $s.aciklama.A = "Yanlış. 15 gün, oda disiplin kurulu kararlarına itiraz süresi değildir. 3568 m.25/son fıkra süreyi otuz gün olarak belirler. (15 günlük süre, m.24'te yönetim kurulu üyeliğinden istifa etmiş sayılma kararına itiraz için öngörülmüştür — farklı bir konudur.)"
        $s.aciklama.B = "Doğru. 3568 sayılı Kanun m.25/son fıkra: 'Oda Disiplin Kurulunun kararlarına karşı tebliğ tarihinden itibaren otuz gün içinde Birlik Disiplin Kuruluna itiraz edilebilir.' Süre tebliğden başlar, karar tarihinden değil."
        $s.kaynak = $M25
        $ist.cevapAnahtariDuzeltildi++; $karar='onay'; break }

      # ---- METIN DUZELTMESI: kokte/siklarda 15 gun yaziyordu
      '43b29b72' {
        $s.soru = $s.soru -replace '15 günlük itiraz süresinin', '30 günlük itiraz süresinin'
        $s.kaynak = $M25
        $ist.metinDuzeltildi++; $karar='onay'; break }

      'd334857d' {
        $s.soru = $s.soru -replace '15 günlük itiraz süresi', '30 günlük itiraz süresi'
        $s.siklar.A = "Öğrenme tarihinden itibaren 30 gün geçtiği için itiraz hakkı düşmüştür"
        $s.siklar.D = "Tebliğ yapılmasa da kararın verildiği tarihten 30 gün geçtiği için süre dolmuştur"
        $s.kaynak = $M25
        $ist.metinDuzeltildi++; $karar='onay'; break }

      '71b5dc2d' {
        $s.siklar.B = "Ceza türü ne olursa olsun itiraz süresi 30 gündür, kanun cezanın ağırlığına göre ayrım yapmaz"
        $s.siklar.C = "Meslekten çıkarma cezasında itiraz süresi cezanın ağırlığı nedeniyle 60 güne çıkar"
        $s.aciklama.B = "Doğru. 3568 m.25/son fıkra süreyi ceza türünden bağımsız olarak otuz gün belirler; uyarmadan meslekten çıkarmaya kadar bütün cezalar için aynı süre işler."
        $s.kaynak = $M25
        $ist.metinDuzeltildi++; $karar='onay'; break }

      '0f750ea6' {
        $s.soru = $s.soru -replace '1 aylık itiraz süresi', '30 günlük itiraz süresi'
        $s.kaynak = $M25
        $ist.metinDuzeltildi++; $karar='onay'; break }

      'e3d51ae6' {
        $s.siklar.E = "3568 sayılı Kanun m.43 kapsamındaki sır saklama yükümlülüğüne aykırıdır, çünkü meslek ilişkisi sona ermiş olsa da işi dolayısıyla öğrenilen bilgi ve sırlar ifşa edilemez"
        $s.aciklama.E = "Doğru. 3568 m.43: 'Meslek mensupları ve bunların yanlarında çalışanlar, işleri dolayısıyla öğrendikleri bilgi ve sırları ifşa edemezler.' Madde yükümlülüğü sözleşme süresiyle sınırlamaz, yazılı/sözlü ayrımı yapmaz ve bilginin türüne göre daraltmaz. İstisnaları yalnızca suç teşkil eden hallerin yetkili mercilere bildirilmesi, adli/idari inceleme ve tanıklıktır."
        $s.kaynak = "3568 s. SMMM K. m.43"
        $ist.metinDuzeltildi++; $karar='onay'; break }

      '1047802e' {
        $s.siklar.D = "Yedek üye sayısı asıl üye sayısıyla birebir aynıdır; asıl üye sayısı ise odanın büyüklüğüne göre 5, 7 veya 9'dur"
        $s.aciklama.D = "Doğru. 3568 m.22'ye göre Oda Yönetim Kurulu, üye sayısı binin altında olan odalarda beş asıl ve beş yedek, bin ilâ beşbin arasında olan odalarda yedi asıl ve yedi yedek, beşbini aşan odalarda dokuz asıl ve dokuz yedek üyeden oluşur. Yedek sayısı her durumda asıl sayısına eşittir; ancak sabit olarak 5 değildir, oda büyüklüğüne göre değişir."
        $s.kaynak = "3568 s. SMMM K. m.22 (5786 s.K. ile değişik)"
        $ist.metinDuzeltildi++; $karar='onay'; break }

      # ---- SADECE KAYNAK DUZELTMESI (cevap zaten dogru)
      '5370cbdb' { $s.kaynak = $M25; $karar='onay'; break }
      'd2b09f44' { $s.kaynak = $M25; $karar='onay'; break }
      '0bf56ba8' { $s.kaynak = $M25; $karar='onay'; break }
      '84d88564' { $s.kaynak = $M25; $karar='onay'; break }
      '5666d135' { $s.kaynak = "3568 s. SMMM K. m.27"; $karar='onay'; break }
      'f2db6506' { $s.kaynak = "3568 s. SMMM K. m.25"; $karar='onay'; break }

      default { $karar = $null }
    }

    if($karar -eq 'onay'){
      $s.durum = 'gm-onay'
      if(-not $s.PSObject.Properties['gmKarar']){
        $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM okudu; 3568 sayili Kanun ambardan birinci elden teyit edildi. Atif yapilan madde duzeltildi." -Force
      }
      $ist.onay++
    }
    if($karar){ $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force; $degisti = $true }
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 6 (Meslek Hukuku) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-26} {1}" -f $k, $ist[$k]) }

# --- YAZMA SONRASI METIN DOGRULAMASI (sayaca guvenme)
Write-Host ""
Write-Host "--- '15 gun' iddiasi kaldi mi:"
$kalan = 0
foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.ders)" -notlike '*Meslek Hukuku*'){ continue }
    $hepsi = "$($s.soru) " + (@($s.siklar.PSObject.Properties | ForEach-Object { "$($_.Value)" }) -join ' ')
    if($hepsi -match '15 gün' -and "$($s.durum)" -eq 'gm-onay'){ $kalan++; Write-Host ("   KALDI: {0}" -f $s.id) }
  }
}
if($kalan -eq 0){ Write-Host "   temiz - onaylananlarda '15 gun' iddiasi yok" } else { Write-Host "KIRMIZI"; exit 1 }
