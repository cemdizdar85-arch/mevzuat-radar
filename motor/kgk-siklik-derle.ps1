# kgk-siklik-derle.ps1 - 06.08.2026
# KGK cikmis-soru ETIKETLERINDEN konu-siklik haritasi cikarir (0 USD, deterministik).
# Girdi : veri/kgk-arsiv/etiket/*.json (+ etiket/tmp/*.json parcalari)
# Cikti : veri/kgk-analiz.json  — REPOYA GIREBILIR: yalniz etiket+sayi tasir,
#         soru metni tasimaz (telif temiz). Kota agirliklandirmasinin dayanagi.
# Cem: "hangi soru sinavda cok cikiyorsa o sorulari daha cok calisacagiz."
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot
$etkDir = Join-Path $kok 'veri\kgk-arsiv\etiket'
$cikti  = Join-Path $kok 'veri\kgk-analiz.json'

$HARF = @{ [char]0x0130='i';[char]0x0131='i';[char]0x015E='s';[char]0x015F='s';[char]0x011E='g';[char]0x011F='g'
           [char]0x00DC='u';[char]0x00FC='u';[char]0x00D6='o';[char]0x00F6='o';[char]0x00C7='c';[char]0x00E7='c' }
function Sade([string]$t){
  $sb = New-Object Text.StringBuilder
  foreach($c in "$t".ToCharArray()){
    if($HARF.ContainsKey($c)){ [void]$sb.Append($HARF[$c]); continue }
    $u = [char]::ToLowerInvariant($c)
    if(($u -ge 'a' -and $u -le 'z') -or ($u -ge '0' -and $u -le '9') -or $u -eq '.'){ [void]$sb.Append($u) } else { [void]$sb.Append(' ') }
  }
  return (($sb.ToString()) -replace '\s+',' ').Trim()
}
# Modul adlarini tek catiya indir (yillar arasi ad farklari)
function ModulCati([string]$m){
  $s = Sade $m
  if($s -match 'muhasebe standart'){ return 'Muhasebe Standartlari' }
  if($s -match 'denetim standart|^denetim$|turkiye denetim'){ return 'Denetim Standartlari' }
  if($s -match 'kurumsal yonetim.*finansal|finansal yonetim.*kurumsal'){ return 'Kurumsal Yonetim + Finansal Yonetim (c)' }
  if($s -match 'surdurulebilirlik'){ return 'Surdurulebilirlik (f-g)' }
  if($s -match 'sermaye piyasasi.*bankacilik|bankacilik.*sigortacilik'){ return 'Ek Alanlar (eski birlesik)' }
  if($s -match 'sermaye piyasasi'){ return 'Sermaye Piyasasi (c-ek)' }
  if($s -match 'bankacilik'){ return 'Bankacilik (d)' }
  if($s -match 'sigortacilik|ozel emeklilik'){ return 'Sigortacilik-OE (e)' }
  if($s -match 'genel hukuk'){ return 'Genel Hukuk (eski)' }
  if($s -match '^muhasebe$'){ return 'Muhasebe (eski)' }
  return $m
}
# 06.08 DUZELTME (Cem: "yanlis bir sey yapmayalim" - hakliydi): FY-pozitif regex
# yaklasimi onlarca finans konusunu kaciriyordu ('sermaye varliklari fiyatlandirma
# modeli' CAPM'dir ama 'capm' kelimesi gecmez; senet iskontosu, Miller-Orr, EOQ,
# MM teorisi, turevler...). Guvenli yon TERSI: KY evreni DARDIR ve nettir
# (teblig/komite/genel kurul/pay sahipligi/vekalet). KY-desenine uymayan (c)
# sorusu FY sayilir.
function KyMi([string]$konu){
  $s = Sade $konu
  return ($s -match 'kurumsal yonetim|bagimsiz uye|bagimsiz yonetim kurulu|genel kurul|yonetim kurulu|komite|faaliyet raporu|menfaat sahip|kamuyu aydinlatma|pay sahip|yatirimci iliskileri|vekalet|asil vekil|vekil asil|internet sitesi|riskin erken saptanmasi|sorumluluk sigortasi|mali haklar|uyum aciklamasi|uyum raporu|zorunlu uygulama|ortaklik gruplari|azlik haklari|onemli islemler|teminat rehin ipotek|iliskili taraf|yaygin.*surekli|denetim kurulusu secimi|spk.*sure|spk.*resen|esitlik|ana ilkeler|ana bolumler|isletme fonksiyonlari|yonetimin temel fonksiyon|risk yonetimi ve ic kontrol raporu|banka komite muafiyeti|finansal kurulus|lisanslar')
}
function FyMi([string]$konu){
  $s = Sade $konu
  return ($s -match 'wacc|capm|anuite|bugunku deger|ic verim|npv|net bugunku|kaldirac|basabas|temettu|portfoy|beta|oran analiz|cari oran|likidite|dupont|isletme sermayesi|nakit dongusu|sermaye butcele|sermaye maliyeti|tahvil|hisse.*deger|finansal analiz|finansman|karlilik orani|aktif devir|stok devir|alacak devir|faaliyet kaldiraci|finansal planlama|proforma|risk.*getiri|sermaye yapisi|faiz hesap|faiz oran|efektif faiz|basit faiz|bilesik faiz|tahsil suresi|devir hizi|paranin zaman|firma degeri|isletme degeri|finansal varlik fiyat|repo|borsa endeks|halka arz fiyat')
}

$dosyalar = @(Get-ChildItem $etkDir -Filter *.json -ErrorAction SilentlyContinue) + @(Get-ChildItem (Join-Path $etkDir 'tmp') -Filter *.json -ErrorAction SilentlyContinue)
if($dosyalar.Count -eq 0){ Write-Host "Etiket dosyasi yok."; exit 1 }

$toplam = 0; $belirsiz = 0
$modulSay = @{}
$konuSay = @{}      # "modulCati|konu-sade" -> @{ konu, modul, adet, donemler(set) }
$donemSay = @{}
$gorulenKayit = @{} # dupe onleme: donem|oturum|modul|no

foreach($d in $dosyalar){
  $j = $null
  try { $j = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { Write-Host "BOZUK JSON atlandi: $($d.Name)"; continue }
  $donem = "$($j.donem)"; if(-not $donem){ $donem = $d.BaseName }
  foreach($s in @($j.sorular)){
    if(-not $s){ continue }
    $anah = "$donem|$($s.oturum)|$($s.modul)|$($s.no)"
    if($gorulenKayit.ContainsKey($anah)){ continue }
    $gorulenKayit[$anah] = 1
    $toplam++
    if(-not $donemSay.ContainsKey($donem)){ $donemSay[$donem] = 0 }
    $donemSay[$donem]++
    $mc = ModulCati "$($s.modul)"
    if($mc -eq 'Kurumsal Yonetim + Finansal Yonetim (c)'){
      $mc = if(KyMi "$($s.konu)"){ 'c: Kurumsal Yonetim' } else { 'c: Finansal Yonetim' }
    }
    if(-not $modulSay.ContainsKey($mc)){ $modulSay[$mc] = 0 }
    $modulSay[$mc]++
    $ks = Sade "$($s.konu)"
    if($ks -eq 'belirsiz' -or $ks -eq ''){ $belirsiz++; continue }
    $kk = "$mc|$ks"
    if(-not $konuSay.ContainsKey($kk)){ $konuSay[$kk] = [ordered]@{ modul=$mc; konu="$($s.konu)"; adet=0; donemler=@{} } }
    $konuSay[$kk].adet++
    $konuSay[$kk].donemler[$donem] = 1
  }
}

$konuListe = foreach($k in $konuSay.Keys){
  $x = $konuSay[$k]
  [pscustomobject]@{ modul=$x.modul; konu=$x.konu; adet=$x.adet; donem_sayisi=$x.donemler.Count }
}
$rapor = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama = 'KGK cikmis-soru konu-siklik haritasi. Kaynak: KGK Soru Arsivi resmi kitapciklari (yalniz A kitapcigi; etiket+sayi, soru metni yok). Kota agirliklandirma dayanagi.'
  toplam_etiketli_soru = $toplam
  belirsiz = $belirsiz
  donem_sayisi = $donemSay.Count
  donem_dagilimi = $donemSay
  modul_dagilimi = $modulSay
  en_sik_konular = @($konuListe | Sort-Object { -$_.adet } | Select-Object -First 120)
  fy_konulari = @($konuListe | Where-Object { $_.modul -eq 'c: Finansal Yonetim' } | Sort-Object { -$_.adet })
  ky_konulari = @($konuListe | Where-Object { $_.modul -eq 'c: Kurumsal Yonetim' } | Sort-Object { -$_.adet })
}
[IO.File]::WriteAllText($cikti, (ConvertTo-Json -InputObject $rapor -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host ("TAMAM: {0} soru, {1} donem, {2} modul catisi -> veri/kgk-analiz.json" -f $toplam, $donemSay.Count, $modulSay.Count)
$modulSay.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object { Write-Host ("  {0,-42} {1}" -f $_.Key, $_.Value) }
