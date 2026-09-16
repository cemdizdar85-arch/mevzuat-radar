# ============================================================================
#  VERİ EZİCİ TARAMASI — hangi betik hangi veri dosyasını BAŞKA BİÇİMLE ezebilir?   16.09.2026
#  Cem "2 ve 3 yap" (GM 3: kütük kapısının kapsamını veri/ altına genişlet).
#
#  NEDEN VAR: 16.09'da iki eski betik (kgk-siklik-derle, cikmis-soru-karnesi) güncel dosyayı başka biçimle yazıyordu;
#  koşturulunca 29 dönemlik kgk-analiz.json'u ezdi. Tek sayfa kütük kapısı yalnız 19 girdiyi görür. Bu tarama depodaki
#  git'te izlenen bütün veri/**.json dosyalarına aynı soruyu sorar.
#
#  YÖNTEM (ağ yok, betik koşturulmaz, bedel 0):
#   - Yazıcı = dosya adını (yaprak) YAZMA satırında anan betik: satırda WriteAllText/RaporYaz/Set-Content/Out-File/
#     Export-Csv/Add-Content geçer ve (a) yaprak aynı satırdadır ya da (b) yaprağı taşıyan bir değişken o satırdadır.
#   - Güncel dosya bir JSON NESNESİ ise üst düzey alan adları alınır; yazıcı betikte bu adlardan biri bile geçmiyorsa
#     yazıcı "EZİCİ ADAYI"dır (dosyayı başka biçimle yazabilir). Betik dosyayı OKUYUP zenginleştiriyorsa (aynı yaprak
#     Get-Content/ConvertFrom-Json satırında) "ZENGİNLEŞTİRİCİ" sayılır, aday değildir.
#   - Birden çok yazıcısı olan dosyalar ayrıca listelenir (iki yazar = 27.08 kıyımının sınıfı).
#  Çıktı: veri/veri-ezici-taramasi.json (RaporYaz). Çıkış: 0; -Kapi verilirse EZİCİ ADAYI varken 1.
#  Bilinen zayıflık: alan adı betiğin YORUMUNDA geçse de sayılır (koruma yorumları bu yüzden adları anar).
#  İlk ölçüm 16.09: 16 aday → 14'ü yanlış alarm (interpolasyon, başka klasör, sözlük dosyası) → kural düzeltildi;
#  2'si GERÇEK (kurtarma-turu → kurtarma-ambar-eksigi, rg-gozetim-cikar → gozetim-teblig-zinciri) → korumaya alındı.
# ============================================================================
param([switch]$Kapi)   # -Kapi: EZİCİ ADAYI varsa çıkış 1 (haftalık iş akışı)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path (Join-Path $depoKok 'arac') 'rapor-yaz.ps1')
Set-Location $depoKok
$yazmaDeseni = 'WriteAllText|RaporYaz|Set-Content|Out-File|Export-Csv|Add-Content|WriteAllBytes'
$okumaDeseni = 'Get-Content|ReadAllText|ConvertFrom-Json|Import-Csv'

# --- betik dizini: her betik için yazdığı ve okuduğu yapraklar
$betikler = @(Get-ChildItem (Join-Path $depoKok 'motor'),(Join-Path $depoKok 'arac') -Filter *.ps1 -File)
$yazarlar = @{}      # yaprak -> List[betik adı]
$okuyanYazar = @{}   # "yaprak|betik" -> $true (dosyayı okuyup yazıyor)
$betikMetinleri = @{}
foreach($betik in $betikler){
  $metin = [IO.File]::ReadAllText($betik.FullName,[Text.Encoding]::UTF8)
  $betikMetinleri[$betik.Name] = $metin
  $satirlar = $metin -split "`r?`n"
  $degiskenYaprak = @{}
  foreach($satir in $satirlar){
    foreach($es in [regex]::Matches($satir,'\$(\w+)\s*=[^=].*?(?<![\$\w\-\.}/\\])((?:[\w\-]+[/\\])*[\w\-\.]+\.json)')){ $degiskenYaprak[$es.Groups[1].Value] = $es.Groups[2].Value }
  }
  foreach($satir in $satirlar){
    $yapraklar = New-Object System.Collections.Generic.HashSet[string]
    foreach($es in [regex]::Matches($satir,'(?<![\$\w\-\.}/\\])((?:[\w\-]+[/\\])*[\w\-\.]+\.json)')){ [void]$yapraklar.Add($es.Groups[1].Value) }   # 16.09: $degisken.json interpolasyonu yaprak sayılmaz; klasör parçası korunur
    foreach($ad in $degiskenYaprak.Keys){ if($satir -match ('\$' + [regex]::Escape($ad) + '\b')){ [void]$yapraklar.Add($degiskenYaprak[$ad]) } }
    if(-not $yapraklar.Count){ continue }
    $yazma = $satir -match $yazmaDeseni
    $okuma = $satir -match $okumaDeseni
    foreach($yolParcasi in $yapraklar){
      $yaprak = Split-Path ($yolParcasi -replace '\\','/') -Leaf
      $klasorIzi = if($yolParcasi -match '[/\\]'){ ($yolParcasi -replace '\\','/') } else { '' }
      if($yazma){ if(-not $yazarlar.ContainsKey($yaprak)){ $yazarlar[$yaprak] = New-Object System.Collections.Generic.List[object] }; $yazarlar[$yaprak].Add([pscustomobject]@{ betik=$betik.Name; iz=$klasorIzi }) }
      if($okuma){ $okuyanYazar["$yaprak|$($betik.Name)"] = $true }
    }
  }
}

# --- izlenen json dosyaları
$izlenen = @(git ls-files veri | Where-Object { $_ -like '*.json' })
$adaylar = New-Object System.Collections.Generic.List[object]
$cokYazarli = New-Object System.Collections.Generic.List[object]
$kontrolEdilen = 0
foreach($yol in $izlenen){
  $yaprak = Split-Path $yol -Leaf
  if(-not $yazarlar.ContainsKey($yaprak)){ continue }
  $tamYol = Join-Path $depoKok $yol
  if(-not (Test-Path $tamYol) -or (Get-Item $tamYol).Length -gt 30MB){ continue }
  $yolDuz = ($yol -replace '\\','/')
  $betikListesi = @($yazarlar[$yaprak] | Where-Object { -not $_.iz -or $yolDuz.EndsWith($_.iz.TrimStart('.','/')) } | ForEach-Object { $_.betik } | Select-Object -Unique)
  if(-not $betikListesi.Count){ continue }
  if($betikListesi.Count -gt 1){ $cokYazarli.Add([ordered]@{ dosya=$yol; yazarlar=$betikListesi }) }
  try { $icerik = Get-Content $tamYol -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if($null -eq $icerik -or $icerik -is [array] -or $icerik -isnot [pscustomobject]){ continue }
  $alanlar = @($icerik.PSObject.Properties.Name)
  if(-not $alanlar.Count){ continue }
  # 16.09: alanlarının çoğu tanımlayıcı değilse (GTİP kodu, kimlik, tarih) dosya SÖZLÜKTÜR; biçim denetimi anlamsız
  $tanimlayici = @($alanlar | Where-Object { $_ -match '^[A-Za-z_çğıöşüÇĞİÖŞÜ][\wçğıöşüÇĞİÖŞÜ]*$' }).Count
  if($tanimlayici -lt ($alanlar.Count / 2)){ continue }
  $kontrolEdilen++
  foreach($betikAdi in $betikListesi){
    $metin = $betikMetinleri[$betikAdi]
    $eksik = @($alanlar | Where-Object { $metin -notmatch ('\b' + [regex]::Escape($_) + '\b') })
    if(-not $eksik.Count){ continue }
    $zenginlestirici = $okuyanYazar.ContainsKey("$yaprak|$betikAdi")
    $adaylar.Add([ordered]@{ dosya=$yol; betik=$betikAdi; sinif=$(if($zenginlestirici){'ZENGİNLEŞTİRİCİ (okuyup yazar)'}else{'EZİCİ ADAYI'}); eksik_alan=$eksik; alan_sayisi=$alanlar.Count; son_commit=((git log -1 --format='%ad %s' --date=short -- $yol) -join '') })
  }
}
$ezici = @($adaylar | Where-Object { $_.sinif -eq 'EZİCİ ADAYI' })
$rapor = [ordered]@{
  olcum = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  kural = 'EZİCİ ADAYI: dosyayı yazan betikte güncel dosyanın üst düzey alanlarından en az biri geçmiyor ve betik dosyayı okumuyor → koşturulursa dosyayı başka biçimle yazabilir. Elle doğrulanmadan "hata" denmez.'
  izlenen_json = $izlenen.Count
  yazari_bilinen_ve_nesne = $kontrolEdilen
  ezici_adayi = $ezici.Count
  zenginlestirici_eksik_alanli = @($adaylar | Where-Object { $_.sinif -ne 'EZİCİ ADAYI' }).Count
  cok_yazarli_dosya = $cokYazarli.Count
  adaylar = $adaylar.ToArray()
  cok_yazarli = $cokYazarli.ToArray()
}
[void](RaporYaz -Hedef (Join-Path (Join-Path $depoKok 'veri') 'veri-ezici-taramasi.json') -Nesne $rapor -Sessiz)
Write-Host ("izlenen json {0} · yazıcısı bilinen nesne {1} · EZİCİ ADAYI {2} · çok yazarlı {3}" -f $izlenen.Count,$kontrolEdilen,$ezici.Count,$cokYazarli.Count)
foreach($a in ($ezici | Sort-Object { $_.dosya })){ Write-Host ("  {0,-48} ← {1,-32} eksik: {2}" -f $a.dosya,$a.betik,(($a.eksik_alan | Select-Object -First 5) -join ',')) }
if($Kapi -and $ezici.Count){ exit 1 }
exit 0
