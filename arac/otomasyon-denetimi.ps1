# ============================================================================
#  OTOMASYON DENETIMI (Katman 1 kapisi — her push'ta kosar, 0 USD, cagri YOK)
#
#  Cem (17.08.2026): "sitede otomatik guncellenmeyen veri kalmasin,
#  otomatik guncellesin her sey."
#
#  BU KAPI: sitenin okudugu her veri dosyasi icin sorar -
#     (1) ureten bir motor betigi var mi?
#     (2) o betigi CAGIRAN bir workflow var mi?
#     (3) betigin varsayilan kaynak yolu OLU mu (gecici klasor / scratchpad)?
#  Ucunden biri tutmazsa dosya "elle beslenen" sayilir.
#
#  17.08 OLCUMU - kapinin dogus sebebi:
#   - Sitenin okudugu 48 veri dosyasinin 21'inin hasatcisi VAR ama onu cagiran
#     workflow YOK; 6'sinin uretici betigi de yok.
#   - Daha kotusu: GTIP hasatcilarinin varsayilan kaynagi ESKI BIR OTURUMUN
#     GECICI KLASORU (".../45bc0a17.../scratchpad/rejim2026"). O klasorler
#     bugun BOS. Yani bu betikler zamanlayiciya baglansa da calismaz -
#     once KAYNAK INDIRICI gerekir. (Dogru kaynak yolu bilinen: ticaret.gov.tr
#     xlsx linkleri sayfa govdesinde YOK; listelerin resmi ekleri RG'de -
#     yilbasi mukerrer RG tam set + yil ici degisiklik karar ekleri.)
#
#  KABUL EDILMIS BORC: veri/otomasyon-borcu.json'daki dosyalar kapiyi
#  KIRMIZI YAPMAZ - bilinen ve kayitli eksiklerdir. Kapinin isi YENI bir elle
#  beslenen dosya eklenmesini engellemek; mevcut borcu her gun bagirip
#  alarm korlugu yaratmak degil. Borc kapandikca listeden silinir.
# ============================================================================
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot

# --- 1) sitenin okudugu veri dosyalari
$siteDosyalari = New-Object 'System.Collections.Generic.HashSet[string]'
foreach($h in (Get-ChildItem $kok -Filter *.html)){
  $icerik = [IO.File]::ReadAllText($h.FullName)
    # YORUMLARI AT (25.08): bu tarama da yorum icindeki dosya adlarini
    # "site bunu okuyor" sayiyordu. alacak-radari.html gizli kasaya gecisi
    # anlatan blok yorumda veri/alacak-arsiv.json adini ANIYOR ama OKUMUYOR;
    # dosya .gitignore'da oldugu icin kapi haksiz yere KIRMIZI kaliyordu.
    # (Ayni kusur arac/veri-bekcisi.ps1'te de vardi, orada da giderildi.)
    $icerik = [regex]::Replace($icerik, "(?s)<!--.*?-->", " ")
    $icerik = [regex]::Replace($icerik, "(?s)/\*.*?\*/", " ")
  foreach($m in [regex]::Matches($icerik, 'veri/([A-Za-z0-9._-]+\.json)')){
    [void]$siteDosyalari.Add($m.Groups[1].Value)
  }
}

# --- 2) motor betiklerinin yazdigi dosyalar (uretici haritasi)
#
# 17.08 KUSUR DUZELTMESI: ilk surum "adi gecen ilk betik"i uretici sayiyordu.
# Bu YANLIS YESIL uretir: zamanlanmis bir betik dosyayi yalnizca OKUYORSA bile
# dosya "otomatik" gorunur. Yakalandigi vaka: ihale-yurtici.json'i gercekte
# ihale-yurtici-hasat.ps1 yaziyor; kapi ise ihale-bulten-arsiv.ps1'i (dosyayi
# sadece okuyor) uretici sanmisti.
# "Yazma satirina yakinlik" da YETMEZ - denendi ve YANLIS KIRMIZI verdi:
# ihale-yurtici-hasat.ps1'de yol 152. satirda kuruluyor, yazma 180/270'te.
# DOGRU YOL degisken izlemek:
#   (a) $yol = ... veri\X.json     -> degisken X'e baglanir
#   (b) dosyada "Out-File $yol" / "WriteAllText($yol" varsa betik X'i YAZAR
#   (c) dosya adi yazma cagrisinin ICINDE geciyorsa (Out-File (Join-Path ...
#       "X.json")) dogrudan yazar sayilir
# Ayrica workflow'lar da dosya yazabiliyor: kartlar.yml veri/kart-durum.json'u
# dogrudan `echo ... > veri/kart-durum.json` ile uretiyor. Bu yuzden yml'ler de
# uretici olarak taranir.
$YAZMA = 'WriteAllText|WriteAllBytes|Out-File|Set-Content|Export-Csv|Export-Clixml'
$uretici    = New-Object 'System.Collections.Generic.Dictionary[string,string]'
$sadeceOkur = New-Object 'System.Collections.Generic.Dictionary[string,string]'
$oluKaynak = New-Object 'System.Collections.Generic.Dictionary[string,string]'
foreach($p in (Get-ChildItem (Join-Path $kok 'motor') -Filter *.ps1)){
  $icerik = [IO.File]::ReadAllText($p.FullName)
  $gecen  = New-Object 'System.Collections.Generic.HashSet[string]'
  foreach($m in [regex]::Matches($icerik, 'veri[/\\]([A-Za-z0-9._-]+\.json)')){ [void]$gecen.Add($m.Groups[1].Value) }

  # (a) degisken -> dosya baglantisi
  $degisken = New-Object 'System.Collections.Generic.Dictionary[string,string]'
  foreach($m in [regex]::Matches($icerik, '\$([A-Za-z_][A-Za-z0-9_]*)\s*=[^\r\n]*veri[/\\]([A-Za-z0-9._-]+\.json)')){
    $degisken[$m.Groups[1].Value] = $m.Groups[2].Value
  }
  # klasor degiskeni + ciplak dosya adi: $hedef = Join-Path $veriDir "gtip-askiya.json"
  # Burada satirda "veri/" gecmiyor. Yanlis eslesmemek icin yalniz sitenin
  # gercekten okudugu adlar kabul edilir. (askiya/balik/nihai-hasat boyle yaziyor;
  # bu desen kacinca uc dosya haksiz yere KIRMIZI olmustu.)
  foreach($m in [regex]::Matches($icerik, '\$([A-Za-z_][A-Za-z0-9_]*)\s*=[^\r\n]*[`"'']([A-Za-z0-9._-]+\.json)[`"'']')){
    if($siteDosyalari.Contains($m.Groups[2].Value) -and -not $degisken.ContainsKey($m.Groups[1].Value)){
      $degisken[$m.Groups[1].Value] = $m.Groups[2].Value
    }
  }

  $yazilan = New-Object 'System.Collections.Generic.HashSet[string]'
  # (b) degisken uzerinden yazma
  foreach($kv in $degisken.GetEnumerator()){
    $v = [regex]::Escape($kv.Key)
    if($icerik -match ("(?:$YAZMA)[^\r\n]*\`$$v\b") -or $icerik -match ("\`$$v\b[^\r\n]*\|\s*(?:$YAZMA)")){
      [void]$yazilan.Add($kv.Value)
    }
  }
  # (c) dosya adi dogrudan yazma cagrisinin icinde
  foreach($m in [regex]::Matches($icerik, "(?:$YAZMA)[^\r\n]*veri[/\\]([A-Za-z0-9._-]+\.json)")){ [void]$yazilan.Add($m.Groups[1].Value) }
  # (d) klasor degiskeni + ciplak dosya adi: Out-File (Join-Path $veriDir "X.json")
  #     Burada "veri/" on eki yok. Yanlis eslesmemek icin YALNIZ sitenin gercekten
  #     okudugu dosya adlari kabul edilir. (damping-hasat.ps1:72 boyle yaziyor.)
  foreach($m in [regex]::Matches($icerik, "(?:$YAZMA)[^\r\n]*[`"']([A-Za-z0-9._-]+\.json)[`"']")){
    if($siteDosyalari.Contains($m.Groups[1].Value)){ [void]$yazilan.Add($m.Groups[1].Value) }
  }

  foreach($ad in $yazilan){ if(-not $uretici.ContainsKey($ad)){ $uretici[$ad] = $p.Name } }
  foreach($ad in $gecen){ if((-not $yazilan.Contains($ad)) -and (-not $sadeceOkur.ContainsKey($ad))){ $sadeceOkur[$ad] = $p.Name } }

  # varsayilan kaynagi gecici/scratchpad yolu olan betik: kaynagi OLU
  if($icerik -match '(?i)AppData\\Local\\Temp|scratchpad'){
    if(-not $oluKaynak.ContainsKey($p.Name)){ $oluKaynak[$p.Name] = 'gecici klasor yolu' }
  }
}
# workflow'un KENDI yazdigi dosyalar (kabuk yonlendirmesi)
$ymlUretici = New-Object 'System.Collections.Generic.Dictionary[string,string]'
foreach($w in (Get-ChildItem (Join-Path $kok '.github/workflows') -Filter *.yml)){
  $icerik = [IO.File]::ReadAllText($w.FullName)
  foreach($m in [regex]::Matches($icerik, '>\s*veri/([A-Za-z0-9._-]+\.json)')){
    $ad = $m.Groups[1].Value
    if(-not $ymlUretici.ContainsKey($ad)){ $ymlUretici[$ad] = $w.Name }
  }
}

# --- 3) workflow'larin cagirdigi betikler
#
# 17.08 YANLIS YESIL: yorum satirlari da "cagri" sayiliyordu. hepsini-hasat.ps1
# icinde "Istisna: tanim-hasat.ps1 Excel COM ister, orkestrasyona dahil DEGIL"
# YORUMU vardi; kapi bunu cagri sanip gtip-tanim.json'u otomatik ilan etti.
# Yani dosyanin OTOMATIK OLMADIGINI soyleyen cumle, onu otomatik gosteriyordu.
# Artik referanslar aranmadan once yorumlar ayiklanir.
function YorumsuzMetin([string]$t){
  $satirlar = [regex]::Split($t, '\r?\n')
  $temiz = foreach($s in $satirlar){
    $i = $s.IndexOf('#')
    if($i -ge 0){ $s.Substring(0, $i) } else { $s }
  }
  return ($temiz -join "`n")
}
$cagrilan = New-Object 'System.Collections.Generic.HashSet[string]'
foreach($w in (Get-ChildItem (Join-Path $kok '.github/workflows') -Filter *.yml)){
  $icerik = YorumsuzMetin ([IO.File]::ReadAllText($w.FullName))
  foreach($m in [regex]::Matches($icerik, '([A-Za-z0-9._-]+\.ps1)')){ [void]$cagrilan.Add($m.Groups[1].Value) }
}
# BIR KADEME DOLAYLILIK: workflow'un cagirdigi betik BASKA bir betigi
# cagiriyorsa o da otomatiktir. Ornek: yanveri.yml -> yanveri-onarici.ps1 ->
# damping-hasat.ps1. Bu olmadan gtip-damping.json "elle" gorunuyordu.
foreach($tur in 1..2){   # iki tur: zincir iki halka derinlige kadar cozulur
  $eklenecek = New-Object 'System.Collections.Generic.List[string]'
  foreach($ad in $cagrilan){
    $yol = Join-Path $kok ('motor/' + $ad)
    if(-not (Test-Path $yol)){ continue }
    $ic = YorumsuzMetin ([IO.File]::ReadAllText($yol))
    foreach($m in [regex]::Matches($ic, '([A-Za-z0-9._-]+\.ps1)')){
      if(-not $cagrilan.Contains($m.Groups[1].Value)){ [void]$eklenecek.Add($m.Groups[1].Value) }
    }
  }
  foreach($e in $eklenecek){ [void]$cagrilan.Add($e) }
}

# --- 4) kabul edilmis borc
$borc = New-Object 'System.Collections.Generic.HashSet[string]'
$borcYol = Join-Path $kok 'veri/otomasyon-borcu.json'
if(Test-Path $borcYol){
  $b = Get-Content $borcYol -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($x in $b.dosyalar){ [void]$borc.Add(("$($x.dosya)").Trim()) }
}

$otomatik = 0; $yeniElle = New-Object System.Collections.Generic.List[object]; $bilinenBorc = 0
$oluAma = New-Object System.Collections.Generic.List[string]   # otomatik ama varsayilan kaynagi gecici yol
# borc listesinde durdugu halde ARTIK otomatik olan dosyalar: liste kendi
# kendini temizlesin diye raporlanir (kapiyi dusurmez, ama silinmezse liste
# yalan soylemeye baslar)
$gereksizBorc = New-Object System.Collections.Generic.List[string]
foreach($d in ($siteDosyalari | Sort-Object)){
  $sebep = $null
  # workflow dosyayi KENDI yaziyorsa (kabuk yonlendirmesi) zaten otomatiktir
  if($ymlUretici.ContainsKey($d)){ $otomatik++; if($borc.Contains($d)){ [void]$gereksizBorc.Add($d) }; continue }
  if(-not $uretici.ContainsKey($d)){
    # dosyaya yalnizca okuma amacli dokunan betik varsa bunu ACIKCA soyle -
    # "ureten betik YOK" ile karistirmak sessiz hata sinifidir
    if($sadeceOkur.ContainsKey($d)){ $sebep = ("YAZAN betik yok (yalniz okuyan var: {0})" -f $sadeceOkur[$d]) }
    else { $sebep = 'ureten betik YOK' }
  }
  else {
    $bet = $uretici[$d]
    if(-not $cagrilan.Contains($bet)){ $sebep = "betik var ($bet) ama CAGIRAN WORKFLOW YOK" }
    # NOT: "kaynak yolu olu" tek basina KUSUR SAYILMAZ. Cagiran betik dosya
    # yolunu acikca gecirebilir (yanveri-onarici -> damping-hasat boyle calisir);
    # varsayilan parametreye bakip kusur demek YANLIS POZITIF uretir. Bu durum
    # asagida ayri bir BILGI listesinde raporlanir, kapiyi dusurmez.
    elseif($oluKaynak.ContainsKey($bet)){ [void]$oluAma.Add(("{0} ({1})" -f $d, $bet)) }
  }
  if(-not $sebep){ $otomatik++; if($borc.Contains($d)){ [void]$gereksizBorc.Add($d) }; continue }
  if($borc.Contains($d)){ $bilinenBorc++; continue }
  $yeniElle.Add([pscustomobject]@{ dosya=$d; sebep=$sebep })
}

Write-Host '======== OTOMASYON DENETIMI ========'
Write-Host ("  sitenin okudugu veri dosyasi : {0}" -f $siteDosyalari.Count)
Write-Host ("  OTOMATIK                     : {0}" -f $otomatik)
Write-Host ("  kabul edilmis borc (kayitli) : {0}" -f $bilinenBorc)
Write-Host ("  YENI ELLE BESLENEN           : {0}" -f $yeniElle.Count)
if($gereksizBorc.Count -gt 0){
  Write-Host ''
  Write-Host '  BORC LISTESINDEN SILINEBILIR (artik otomatik):'
  foreach($g in $gereksizBorc){ Write-Host ("     " + $g) }
}
if($oluAma.Count -gt 0){
  Write-Host ''
  Write-Host '  BILGI - otomatik ama betigin VARSAYILAN kaynagi gecici yol:'
  foreach($o in $oluAma){ Write-Host ("     " + $o) }
  Write-Host '     (cagiran betik yolu acikca geciriyorsa sorun degil - kapiyi dusurmez)'
}
if($yeniElle.Count -gt 0){
  Write-Host ''
  Write-Host 'KIRMIZI - su dosyalar elle besleniyor ve borc listesinde de YOK:'
  foreach($y in $yeniElle){ Write-Host ("   {0,-32} {1}" -f $y.dosya, $y.sebep) }
  Write-Host ''
  Write-Host 'Cozum: ya hasatciyi bir workflow''a bagla, ya da bilincli bir'
  Write-Host 'karar ise veri/otomasyon-borcu.json''a GEREKCESIYLE ekle.'
  exit 1
}
Write-Host ''
Write-Host 'Otomasyon denetimi yesil - yeni elle beslenen veri dosyasi yok.'
