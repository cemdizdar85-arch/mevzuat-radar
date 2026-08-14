# ============================================================================
#  MULGA KUSURU TAM TARAMASI (14.08) - Cem: "bu baska kanunlarda varsa onu
#  duzeltelim... elle birebir okuyorum deme, hepsini".
#
#  KUSUR: parcalayici, maddenin ilk 70 karakterinde "(Mülga" gorunce maddeyi
#  KOMPLE atiyordu. Ama "(Mülga ibare:...)" / "(Mülga fıkra:...)" maddenin
#  KENDISI degil, icindeki bir parca mulga demektir - madde yururluktedir.
#
#  IKI ASAMALI OLCUM (hepsini indirmeden kesin sonuca varmak icin):
#   1) AMBARDAN: her dosyada madde numarasi surekliligi kirilmis mi? (1,2,3,5 ->
#      4 eksik). Eksik numara TEK BASINA kusur degil - madde gercekten mulga
#      olabilir. Bu asama SUPHELI dosyalari daraltir.
#   2) KAYNAKTAN: yalniz supheli dosyalarin PDF'i indirilir ve eksik numaranin
#      kaynakta "(Mülga ibare/fıkra" ile mi yoksa "(Mülga:" ile mi basladigina
#      BAKILIR. Boylece 666 kaynak yerine yalniz supheliler indirilir.
#
#  Hizli: JSON ayristirmak yerine dosyayi regex ile tarar (763 dosya ~saniyeler).
#  OLCUM betigi - hicbir sey yazmaz. -Kaynak ile 2. asama kosar.
# ============================================================================
param([switch]$Kaynak, [int]$KaynakTavan = 40, [string]$Slug = "", [switch]$Tani)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ambar = Join-Path $kok "veri\mevzuat"

# ---------- ASAMA 1: ambardan bosluk taramasi -------------------------------
# HIZ NOTU (olculdu): once her "kaynak_ad" icin AYRI bir regex kosuluyordu -
# 763 dosyada 14 dakikada bitmedi. Tek gecisli tek regex ile saniyelere indi.
# Compiled + negatif geriye bakis: "ek m.5" / "gec. m.5" / "muk. m.5" haric,
# yalniz duz "m.5" numaralari alinir.
$rxAd = [regex]::new('"kaynak_ad"\s*:\s*"[^"]*?(?<!ek )(?<!gec\. )(?<!muk\. )\bm\.(\d+)(?:[\s"\[])',
        [Text.RegularExpressions.RegexOptions]::Compiled)
$supheli = @()
foreach($f in (Get-ChildItem $ambar -Filter *.json | Where-Object { $_.Name -notmatch '^_|^indirme' })){
  $t = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
  $nolar = New-Object 'System.Collections.Generic.HashSet[int]'
  foreach($m in $rxAd.Matches($t)){ [void]$nolar.Add([int]$m.Groups[1].Value) }
  if($nolar.Count -lt 3){ continue }
  $dizi = @($nolar) | Sort-Object
  $ilk = $dizi[0]; $son = $dizi[-1]
  # HIZ TUZAGI (olculdu): once "for($ilk..$son)" dongusu + dizi "+=" kullaniliyordu.
  # Regex hizliydi (0,0 sn) ama bu dongu tarayiciyi 14 dakikada bitirmedi: kaynak_ad
  # icinde "m.2026" gibi TARIH benzeri numaralar olunca aralik binlere ciktı ve
  # "+=" her adimda diziyi kopyaladi -> O(n^2). Cozum: ArrayList + akil disi
  # araligi atla. Bir kanunun 3000'den fazla maddesi olmaz; oyle bir aralik
  # ayristirma hatasidir, bosluk degil.
  if(($son - $ilk) -gt 3000){ continue }
  $eksikL = New-Object System.Collections.ArrayList
  for($i=$ilk; $i -le $son; $i++){ if(-not $nolar.Contains($i)){ [void]$eksikL.Add($i) } }
  if($eksikL.Count){
    $supheli += [pscustomobject]@{ dosya=$f.Name; slug=$f.BaseName; madde=$nolar.Count; aralik="$ilk-$son"; eksik=@($eksikL) }
  }
}
$supheli = @($supheli | Sort-Object { $_.eksik.Count } -Descending)
$toplamEksik = ($supheli | ForEach-Object { $_.eksik.Count } | Measure-Object -Sum).Sum
Write-Host ("ASAMA 1 - AMBAR TARAMASI")
Write-Host ("  taranan dosya : {0}" -f @(Get-ChildItem $ambar -Filter *.json).Count)
Write-Host ("  bosluklu dosya: {0}" -f $supheli.Count)
Write-Host ("  eksik numara  : {0}" -f $toplamEksik)
Write-Host ""
Write-Host ("{0,-26} {1,6} {2,10} {3,6}  {4}" -f "DOSYA","MADDE","ARALIK","EKSIK","EKSIK NUMARALAR")
Write-Host ("-"*100)
foreach($s in ($supheli | Select-Object -First 25)){
  Write-Host ("{0,-26} {1,6} {2,10} {3,6}  {4}" -f $s.dosya, $s.madde, $s.aralik, $s.eksik.Count, (($s.eksik | Select-Object -First 12) -join ','))
}
if(-not $Kaynak){
  Write-Host "`n(2. asama icin: -Kaynak  — yalniz supheli dosyalarin PDF'i indirilip eksik maddenin"
  Write-Host " kaynakta '(Mülga ibare' mi '(Mülga:' mi oldugu OKUNUR. Tahmin degil, olcum.)"
  return
}

# ---------- ASAMA 2: supheli dosyalarin kaynagini oku -----------------------
$manifest = Get-Content (Join-Path $kok "veri\mevzuat-kaynaklar.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$pdfIdler = @{}
foreach($k in @($manifest.kanunlar)){ $pdfIdler["$($k.slug)"] = "$($k.pdfId)" }
# TUZAK (olculdu): degisken adi "$pid" SECILEMEZ - PowerShell'in yerlesik,
# SALT OKUNUR degiskeni (process id). Uzerine yazmaya calisinca betik "Cannot
# overwrite variable PID because it is read-only or constant" deyip duser.
# Ayni ailenin diger yerlesikleri: $host $error $args $input $matches $psitem
# $true $false $null $home $pwd $profile. Kisa ad secerken bunlara dikkat.
# (Bkz. ps-degisken-cakismasi dersi - o buyuk/kucuk harf cakismasiydi, bu yerlesik.)
$kls = Join-Path ([IO.Path]::GetTempPath()) "tetikte-mulga"
if(-not (Test-Path $kls)){ New-Item -ItemType Directory -Force $kls | Out-Null }
$curl = @(Get-Command curl.exe,curl -CommandType Application -ErrorAction SilentlyContinue)[0].Source
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"

Write-Host ("`nASAMA 2 - KAYNAKTAN DOGRULAMA (en cok eksigi olan {0} dosya)" -f $KaynakTavan)
$kurbanlar = @(); $okunamayan = @()
$hedefler = if($Slug){ @($supheli | Where-Object { $_.slug -eq $Slug }) } else { @($supheli | Select-Object -First $KaynakTavan) }
foreach($s in $hedefler){
  $pdfKimlik = $pdfIdler["$($s.slug)"]
  if(-not $pdfKimlik){ $okunamayan += "$($s.slug) (manifestte yok)"; continue }
  $pdf = Join-Path $kls "$($s.slug).pdf"; $txt = Join-Path $kls "$($s.slug).txt"
  # 14.08: pdfId "HAZIR" olan kaynaklarin metni ZATEN DEPODA duruyor
  # (veri/mevzuat-hazir/<slug>.txt - RG'den elle hazirlanan ekli tebligler,
  # kararlar). Bunlari mevzuat.gov.tr'den indirmeye calismak bosuna ve sonucu
  # "indirilemedi" oluyordu; vukgt577ek ile diib-karar bu yuzden olculememisti.
  $hazirYol = Join-Path $kok "veri\mevzuat-hazir\$($s.slug).txt"
  if($pdfKimlik -eq 'HAZIR'){
    if(Test-Path $hazirYol){ Copy-Item $hazirYol $txt -Force }
    else { $okunamayan += "$($s.slug) (HAZIR ama depoda metin yok)"; continue }
  }
  elseif(-not (Test-Path $txt)){
    # 14.08 olculdu: teblig/yonetmelik PDF'leri "MevzuatMetin/yonetmelik/" ALT
    # KLASORUNDE duruyor (tur kodu 9.x / 7.x). Duz "MevzuatMetin/9.5.13354.pdf"
    # 60 KB'lik hata sayfasi donduruyor - kik-genel-teblig bu yuzden inmemisti.
    $u = if($pdfKimlik -like 'G7:*'){ "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$($pdfKimlik.Substring(3))&mevzuatTur=KurumVeKurulusYonetmeligi&mevzuatTertip=5" }
         elseif($pdfKimlik -like 'G9:*'){ "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$($pdfKimlik.Substring(3))&mevzuatTur=Teblig&mevzuatTertip=5" }
         elseif($pdfKimlik -match '^[79]\.'){ "https://www.mevzuat.gov.tr/MevzuatMetin/yonetmelik/$pdfKimlik.pdf" }
         else { "https://www.mevzuat.gov.tr/MevzuatMetin/$pdfKimlik.pdf" }
    # TUZAK: pdftotext uyarisini ("May not be a PDF file") stderr'e yaziyor;
    # $ErrorActionPreference=Stop altinda PowerShell bunu HATA sayip betigi
    # dusuruyordu. Yerli programin stderr'i hata degildir - gecici olarak gevsetilir.
    $eskiTercih = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    & $curl -sS -L --max-time 40 -A $ua -H "Referer: https://www.mevzuat.gov.tr/" -o $pdf $u 2>$null
    if((Test-Path $pdf) -and (Get-Item $pdf).Length -gt 5000){ & pdftotext -enc UTF-8 $pdf $txt 2>$null | Out-Null }
    $ErrorActionPreference = $eskiTercih
    Start-Sleep -Milliseconds 1200   # kaynaga nazik: seri yagmur engelleniyor
  }
  if(-not (Test-Path $txt)){ $okunamayan += "$($s.slug) (indirilemedi)"; continue }
  $m = ([IO.File]::ReadAllText($txt, [Text.Encoding]::UTF8)) -replace '\s+',' '
  $kusurlu = @(); $gercekMulga = 0; $bulunamayan = 0
  foreach($no in $s.eksik){
    # maddenin kaynaktaki basini bul
    # TUZAK (olculdu, Gumruk Yonetmeligi vakasi): duz "MADDE 4" ararken
    # "GEÇİCİ MADDE 4" ve "EK MADDE 4" de eslesiyordu - ambar tarafinda bunlar
    # zaten "gec. m.4" / "ek m.4" olarak AYRI tutuluyor. Onek elenmezse geçici
    # madde, kayip duz madde sanilir ve 25 sahte "kusur" uretilir.
    $r = [regex]::Match($m, "(?:^|\s)(?<!GEÇİCİ )(?<!EK )(?<!MÜKERRER )(?<!Geçici )(?<!Ek )(?<!Mükerrer )(?:MADDE|Madde)\s+$no\s*[–—-]\s*(.{0,90})")
    if($Tani -and $no -in @(311,567,251,4)){
      Write-Host ("    [TANI] m.{0} · metin {1:N0} krk · regex {2}" -f $no, "$m".Length, $r.Success)
    }
    if(-not $r.Success){ $bulunamayan++; continue }
    # OLCUT (elle dogrulanarak uc kez duzeltildi - Gumruk Yon. m.251/311 vakalari):
    #  · ilk 70 karakterde "(Mülga:" ya da "(Mülga madde:" -> MADDENIN KENDISI mulga,
    #    atilmasi DOGRU. Dikkat: bu ibare basta olmayabilir; "(Başlığı ile Birlikte
    #    Değişik:RG-...) (Mülga:RG-...)" gibi ONCE baska parantez gelebilir - bu
    #    yuzden "^\s*" ile degil, ilk 70 karakter icinde ARANIR.
    #  · ilk 70 karakterde yalniz "(Mülga ibare/fıkra/bent" varsa -> madde YURURLUKTE,
    #    ambarda OLMALIYDI = KUSUR.
    # 14.08 KUSUR: bu satir bir duzenleme sirasinda YANLISLIKLA SILINMISTI -
    # $bas hic atanmadigi icin butun maddeler "bulunamayan" sayildi ve tarama
    # "kusur yok" dedi. Tani ciktisi olmasa fark edilmezdi: regex True donuyordu
    # ama siniflandirma bos metinle calisiyordu. (Ders: bir kapinin "temiz"
    # demesi, kapinin CALISTIGI anlamina gelmez - once bilinen bir vakayla sina.)
    $bas = "$($r.Groups[1].Value)"
    if(-not $bas){ $bulunamayan++; continue }
    $ilk70 = $bas.Substring(0, [math]::Min(70, $bas.Length))
    if($ilk70 -match '\(Mülga\s*(?:madde)?\s*:'){ $gercekMulga++ }
    elseif($ilk70 -match '\(Mülga\s*(?:ibare|fıkra|bent|cümle)'){ $kusurlu += $no }
    else { $bulunamayan++ }   # baska sebep - hukum verilmez, OLCULEMEDI sayilir
  }
  if($kusurlu.Count){
    $kurbanlar += [pscustomobject]@{ slug=$s.slug; kayip=$kusurlu; gercekMulga=$gercekMulga }
    Write-Host ("  KUSUR  {0,-20} kayip {1,3} · gercek mulga {2,3} · kaynakta yok {3,3} | {4}" -f `
      $s.slug, $kusurlu.Count, $gercekMulga, $bulunamayan, (($kusurlu | Select-Object -First 10) -join ','))
  } else {
    # DURUSTLUK: kaynakta BULUNAMAYAN numaraya "temiz" denmez - o OLCULEMEDI.
    Write-Host ("  temiz  {0,-20} gercek mulga {1,3} · kaynakta bulunamayan (olculemedi) {2,3}" -f `
      $s.slug, $gercekMulga, $bulunamayan)
  }
}
Write-Host ("`n=== SONUC ===")
Write-Host ("  kusurdan etkilenen dosya: {0}" -f $kurbanlar.Count)
Write-Host ("  kaybolan madde toplam   : {0}" -f (($kurbanlar | ForEach-Object { $_.kayip.Count } | Measure-Object -Sum).Sum))
if($okunamayan.Count){ Write-Host ("  okunamayan: {0}" -f ($okunamayan -join ', ')) }
if($kurbanlar.Count){
  Write-Host "`nYENIDEN YUTULACAK SLUG LISTESI (mevzuat-yut.ps1 -> SADECE):"
  Write-Host ("  " + (($kurbanlar | ForEach-Object { $_.slug }) -join ','))
}
