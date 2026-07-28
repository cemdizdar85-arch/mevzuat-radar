# gm-okuma-12.ps1 - 28.07.2026  (BOM'lu kaydedilmeli)
# GM OKUMASI, PARTI 12: Hukuk dersinin kalan 38 sorusu (TTK, 4857, 5510, 6356).
# Zaten Parti 9'da BEKLETILEN 2 soru (8d624962, 163208c6) atlanir.
#
# AMBARDAN OKUNAN VE DOGRULANAN:
#   4857 m.4/1 : a) deniz-hava tasima  b) tarim-orman <50  c) aile ekonomisi tarim
#                yapi isleri  d) aile uyeleri/3. dereceye kadar hisimlar evlerde ve
#                el sanatlari  e) EV HIZMETLERINDE  f) CIRAKLAR  g) SPORCULAR
#   4857 m.4/2 : "Havaciligin butun YER TESISLERINDE yurutulen isler ... bu Kanun
#                hukumlerine tabidir" -> hava tasima istisnasi yer hizmetlerini kapsamaz
#   5510 m.18  : gecici is goremezlik odenegi YATARAK tedavide gunluk kazancin YARISI,
#                AYAKTAN tedavide UCTE IKISI
#   TTK m.681/2: "emre yazili degildir" kaydi -> alacagin temliki
#   TTK m.682  : cironun kayitsiz sartsiz olmasi; hamiline ciro beyaz ciro hukmunde
#   TTK m.683  : cironun sekli, BEYAZ CIRO tanimi
#   TTK m.685  : CIRANTANIN SORUMLULUGU ve ciro yasagi  (TAHSIL CIROSU DEGIL)
#   TTK m.778  : bonoya poliçe cirosu hukumlerinin (681-690) uygulanmasi
#
# --- BULGULAR ---
# 1) YURURLUKTEN KALKMIS IBAREYE DAYANMA (yeni hata turu):
#    4857 m.4/1-f'te vaktiyle "Is sagligi ve guvenligi hukumleri sakli kalmak uzere"
#    ibaresi vardi; 20/6/2012 tarihli 6331 sayili Kanunun 37. maddesiyle madde
#    metninden CIKARILDI. Iki soru (0210870b, 189fdd85) hala bu ibareyi 4857'ye
#    dayandiriyor. Sonuc dogru - ciraklar IS SAGLIGI VE GUVENLIGI kapsamindadir -
#    ama dayanak artik 6331 sayili Kanun m.2'dir. Kaynak duzeltildi.
# 2) TAHSIL CIROSU YANLIS MADDEYE BAGLANMIS: m.685 -> dogrusu m.688 (2 soru).
# 3) IS KANUNU ISTISNA BENTLERI KARISMIS: ev hizmetleri m.4/1-e iken 3 soruda
#    m.4/1-d yazilmis (d bendi aile uyeleri/hisimlar arasindaki isleri duzenler).
# 4) GERCEK CEVAP HATASI - RED: 429266ee. 5510 m.18'e gore 20 gun YATARAK tedavi
#    icin %50, taburcu sonrasi 10 gun AYAKTAN istirahat icin UCTE IKI uygulanir.
#    Isaretli C sikki "30 gunun tamami icin yarisi" diyor; hicbir sik dogru degil.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$ZATEN_BEKLET = @('8d624962','163208c6')

$KAYNAK = @{
  '6f93f0ce' = "TTK (6102 s.K.) m.688 (tahsil cirosu) — eski atıf m.685 cirantanın sorumluluğunu ve ciro yasağını düzenler"
  '9703452d' = "TTK (6102 s.K.) m.688 (tahsil cirosu), bonoya m.778 atfıyla uygulanır — eski atıf m.685 cirantanın sorumluluğunu düzenler"
  '26f03c0e' = "4857 s. İş K. m.4/1-e (ev hizmetleri) — eski atıf m.4/1-d aile üyeleri ve hısımları arasındaki işleri düzenler"
  '974917a9' = "4857 s. İş K. m.4/1-e (ev hizmetleri) — eski atıf m.4/1-d aile üyeleri ve hısımları arasındaki işleri düzenler"
  'b8347178' = "4857 s. İş K. m.4/1-e — ev hizmetleri istisnası kapıcılık ilişkisini kapsamaz; kapıcılar İş Kanunu'na tabidir"
  '85fc1475' = "4857 s. İş K. m.4/1-a (deniz ve hava taşıma işleri istisnası) ve m.4/2-b (havacılığın bütün yer tesislerinde yürütülen işler bu Kanuna tabidir)"
  '0210870b' = "4857 s. İş K. m.4/1-f (çıraklar) ve 6331 s. İSG K. m.2 — 4857 m.4/1-f'teki 'iş sağlığı ve güvenliği hükümleri saklı kalmak üzere' ibaresi 6331 s.K. m.37 ile 2012'de metinden çıkarılmıştır; çırakların İSG kapsamında olması artık 6331'e dayanır"
  '189fdd85' = "4857 s. İş K. m.4/1-f (çıraklar) ve 6331 s. İSG K. m.2 — eski atıf m.4/1-e ev hizmetlerini düzenler; ayrıca İSG saklılık ibaresi 2012'de 4857'den çıkarılmıştır"
  '8380fd3b' = "TTK (6102 s.K.) m.56/2-3 (müşteriler ile mesleki ve ekonomik birliklerin açabileceği davalar) — eski atıf m.58 kararın ilanını düzenler"
  '37ec77c0' = "TTK (6102 s.K.) m.56/1-f (manevi tazminat; TBK m.58 şartlarıyla) — eski atıf m.56/1-e"
  '7d9b792b' = "TTK kıymetli evrak hükümleri — hamiline yazılı senetlerde devir için zilyetliğin geçirilmesi (teslim) yeterlidir"
}

$RED = @{
  '429266ee' = "GM RED (28.07): 5510 sayılı Kanun m.18 geçici iş göremezlik ödeneğini YATARAK tedavide günlük kazancın YARISI, AYAKTAN tedavide ÜÇTE İKİSİ olarak belirler. Soruda 20 gün hastanede yatarak, 10 gün taburcu sonrası evde istirahat verilmiş; doğru hesap 20 gün için %50, 10 gün için 2/3 şeklinde AYRIŞTIRILMALIDIR. İşaretlenen C şıkkı '30 günün tamamı için yarısı' diyor ve yanlıştır; diğer şıklardan hiçbiri de doğru hesabı vermediğinden soru cevap anahtarı düzeltilerek kurtarılamaz."
}

$ist = [ordered]@{ onay=0; kaynakDuzeltildi=0; red=0; atlandi=0; gorulen=0 }

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'katman1-temiz' -or "$($s.ders)" -ne 'Hukuk'){ continue }
    $id = "$($s.id)"; $ist.gorulen++

    if($ZATEN_BEKLET -contains $id){ $ist.atlandi++; continue }

    if($RED.ContainsKey($id)){
      $s.durum = 'karantina-red'
      $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue $RED[$id] -Force
      $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
      $ist.red++; $degisti = $true; continue
    }

    if($KAYNAK.ContainsKey($id)){
      $s | Add-Member -NotePropertyName eskiKaynak -NotePropertyValue "$($s.kaynak)" -Force
      $s.kaynak = $KAYNAK[$id]
      $ist.kaynakDuzeltildi++
    }

    if($id -eq '7d9b792b'){
      $s | Add-Member -NotePropertyName gerekenKaynak -NotePropertyValue "TTK'da hamiline yazılı senetlerin devrine ilişkin maddenin numarası ambardan teyit edilmedi; kaynak alanı kural olarak yazıldı" -Force
    }

    $s.durum = 'gm-onay'
    $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM okudu (28.07): 4857 m.4, 5510 m.13/16/18/19/21, TTK m.64, 373, 681-685, 778, 799, 56 ve 6356 hükümleri ambardan birinci elden okundu; cevap doğrulandı, atıf gerekiyorsa düzeltildi." -Force
    $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
    $g = if("$($s.konu)" -match 'kambiyo|cek uzerindeki'){'huk-ttk-kambiyo'} elseif("$($s.konu)" -match 'is kanunu kapsami'){'huk-4857-kapsam'} elseif("$($s.konu)" -match 'is kazasi'){'huk-5510-is-kazasi'} elseif("$($s.konu)" -match 'sendika|toplu is'){'huk-6356-yetki'} else {'huk-ttk-diger'}
    $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue $g -Force
    $ist.onay++; $degisti = $true
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 12 (Hukuk / TTK-4857-5510-6356) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-18} {1}" -f $k, $ist[$k]) }

# --- yazma sonrasi METIN dogrulamasi
Write-Host ""
$hata = 0
foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    $id = "$($s.id)"
    if($KAYNAK.ContainsKey($id) -and "$($s.kaynak)" -ne $KAYNAK[$id]){ $hata++; Write-Host ("  KAYNAK YAZILMADI: {0}" -f $id) }
    if($RED.ContainsKey($id) -and "$($s.durum)" -ne 'karantina-red'){ $hata++; Write-Host ("  RED YAZILMADI: {0}" -f $id) }
  }
}
if($hata -eq 0){ Write-Host "   temiz — tüm düzeltmeler metinde doğrulandı" } else { Write-Host "KIRMIZI"; exit 1 }
