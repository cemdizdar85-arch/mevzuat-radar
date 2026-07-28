# gm-okuma-09.ps1 - 28.07.2026  (BOM'lu kaydedilmeli)
# GM OKUMASI, PARTI 9: Hukuk dersinin 3568'e dayanan 27 sorusu ('katman1-temiz').
#
# AMBARDAN BIRINCI ELDEN OKUNAN MADDELER ve gercek icerikleri:
#   m.4  = Meslek mensubu olabilmenin GENEL SARTLARI
#          b) medeni haklari kullanma ehliyeti · d) TCK m.53 sureleri gecmis olsa
#          BILE zimmet/irtikap/rusvet/hirsizlik/dolandiricilik/sahtecilik/guveni
#          kotuye kullanma/hileli iflas/ihaleye fesat/aklama/kacakcilik suclarindan
#          mahkum olmamak · e) ceza veya disiplin sorusturmasi sonucu memuriyetten
#          cikarilmis olmamak
#   m.8  = YABANCI uyruklu SMMM'lere karsiliklilik sarti ile izin  (unvan engeliyle
#          HICBIR ilgisi yok - 3 soru buna atif yapmisti)
#   m.34 = Birlik GENEL KURULU'nun toplanmasi  (sir saklamayla ilgisi yok - 1 soru
#          buna atif yapmisti; sir saklama m.43'tur)
#   m.43 = Sir saklama
#   m.45 = Yasaklar + REKLAM YASAGI ("Meslek mensuplari, is elde etmek icin reklam
#          sayilabilecek faaliyetlerde bulunamazlar. Tabela veya basili kagitlarinda
#          ruhsatname ile belirlenen mesleki unvanlari disinda baska sifat
#          kullanamazlar.")  -> 5 soru bunu m.50'ye baglamisti
#   m.48 = Disiplin cezalari: a) uyarma b) kinama c) gecici olarak mesleki
#          faaliyetten alikoyma d) yeminli sifatini kaldirma e) meslekten cikarma.
#          + 27/3/2025-7546/4 ek fikra: ruhsatnameyi baskasina kullandirma /
#          baska meslek mensubunun adiyla beyanname gonderme -> MESLEKTEN CIKARMA
#   m.50 = Cikarilacak YONETMELIKLERIN listesi (itiraz suresi/reklam yasagi degil)
#   m.54 = YOKTUR. Kanun m.52'de biter. (1 soru m.54'e atif yapmisti.)
#
# SONUC: 27 sorunun 25'i ONAY (14'unde kaynak duzeltildi), 2'si BEKLET.
# Cevaplarin neredeyse tamami dogruydu; bozuk olan MADDE NUMARALARIYDI - bugunku
# desenin bir kez daha dogrulanmasi.
# Olumlu not: d66d3f33 sorusu m.48'e 2025'te eklenen YENI fikrayi (ruhsat
# kullandirma -> meslekten cikarma) DOGRU bilmis.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$M45 = "3568 s. SMMM K. m.45 (reklam yasağı — ek fıkra)"
$M48 = "3568 s. SMMM K. m.48 (disiplin cezaları)"

# id -> yeni kaynak (yalniz kaynak duzeltilecekler)
$KAYNAK = @{
  'd1fac320' = $M45
  '07830b79' = $M45
  'a3898d07' = $M45
  'ede93ecf' = $M45
  '177808ee' = "$M45; ayrıntı: TÜRMOB Reklam Yasağı Yönetmeliği"
  '2c498ade' = $M48
  'd2d3c926' = $M48
  'bf0c3d12' = $M48
  '4cce2848' = "$M48 ve m.26 (Oda Disiplin Kurulunun görevleri) — eski atıftaki m.54 Kanun'da YOKTUR, metin m.52'de biter"
  'aedfb6e9' = "$M48 ve m.26 (Oda Disiplin Kurulunun görevleri)"
  '06bf263f' = "3568 s. SMMM K. m.43 (sır saklama) — eski atıf m.34 Birlik Genel Kurulunun toplanmasını düzenler, konuyla ilgisi yoktur"
  '3dd3e67b' = "3568 s. SMMM K. m.4/e (ceza veya disiplin soruşturması sonucu memuriyetten çıkarılmış olmamak)"
  'ce5d32cc' = "3568 s. SMMM K. m.4/d (kaçakçılık suçundan mahkûmiyet) ve m.48 (meslekten çıkarma)"
  '1c7e3531' = "3568 s. SMMM K. m.4/b (medeni hakları kullanma ehliyeti)"
}

# BEKLET: hukum Kanun'da yok
$BEKLET = @{
  '8d624962' = "GM BEKLETTI (28.07): 'meslek mensubu birden fazla büro açamaz' kuralı 3568 sayılı Kanun'da YOKTUR. Atıf yapılan m.45 hizmet akdiyle çalışma, ticari faaliyet ve reklam yasağını düzenler; ikinci büro yasağını değil. Bu kural Çalışma Usul ve Esasları Yönetmeliğindedir, yönetmelik ambarda bulunmadığı için karar verilemedi."
  '163208c6' = "GM BEKLETTI (28.07): şahsi iflas nedeniyle unvan kullanamama ve itibarın iadesiyle unvanın geri gelmesi 3568 sayılı Kanun'da açık bir hükümle düzenlenmiş değildir. Atıf yapılan m.8 YABANCI uyruklu meslek mensuplarına karşılıklılık şartıyla izin verilmesini düzenler; konuyla hiçbir ilgisi yoktur. Kaynak teyit edilmeden yayına alınmaz."
}

$ist = [ordered]@{ onay=0; kaynakDuzeltildi=0; beklet=0 }
$gorulen = @{}

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'katman1-temiz' -or "$($s.ders)" -ne 'Hukuk'){ continue }
    if("$($s.kaynak)" -notmatch '3568'){ continue }
    $id = "$($s.id)"; $gorulen[$id] = $true

    if($BEKLET.ContainsKey($id)){
      $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue $BEKLET[$id] -Force
      $s | Add-Member -NotePropertyName gerekenKaynak -NotePropertyValue "SMMM/YMM Çalışma Usul ve Esasları Yönetmeliği" -Force
      $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
      $ist.beklet++; $degisti = $true; continue
    }

    if($KAYNAK.ContainsKey($id)){
      $s | Add-Member -NotePropertyName eskiKaynak -NotePropertyValue "$($s.kaynak)" -Force
      $s.kaynak = $KAYNAK[$id]
      $ist.kaynakDuzeltildi++
    }

    $s.durum = 'gm-onay'
    $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM okudu (28.07): 3568 sayılı Kanun m.4, 8, 26, 34, 43, 45, 48, 50 ambardan birinci elden okundu; cevap doğrulandı, atıf yapılan madde gerekiyorsa düzeltildi." -Force
    $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
    $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue $(if("$($s.konu)" -match 'kinama'){'huk-3568-disiplin'}elseif("$($s.konu)" -match 'reklam'){'huk-3568-reklam'}elseif("$($s.konu)" -match 'engel'){'huk-3568-olma-sartlari'}else{'huk-3568-diger'}) -Force
    $ist.onay++; $degisti = $true
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 9 (Hukuk / 3568 blogu) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-18} {1}" -f $k, $ist[$k]) }
Write-Host ("  gorulen soru       {0}" -f $gorulen.Count)

# --- yazma sonrasi METIN dogrulamasi: m.50 / m.54 / m.34 / m.8 atifi kaldi mi
Write-Host ""
$kalan = 0
foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.ders)" -ne 'Hukuk' -or "$($s.durum)" -ne 'gm-onay'){ continue }
    if("$($s.kaynak)" -match '3568' -and "$($s.kaynak)" -match 'm\.(50|54|34|8)\b' -and "$($s.kaynak)" -notmatch 'YOKTUR|ilgisi yoktur'){
      $kalan++; Write-Host ("   KALDI: {0} -> {1}" -f $s.id, $s.kaynak)
    }
  }
}
if($kalan -eq 0){ Write-Host "   temiz — onaylananlarda hatalı m.50/m.54/m.34/m.8 atfı kalmadı" } else { Write-Host "KIRMIZI"; exit 1 }
