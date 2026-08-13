# ============================================================================
#  YANVERI ONARICI (13.08.2026) — Cem: "yan verilerin otomatik onarimi yok,
#  bunu yapalim." Damping/IGV/rejim gibi xlsx tabanli gtip yan verilerini
#  KAYNAGINDAN tazeler. Ilke ayni: tek okumayla basilmaz, kapisiz basilmaz.
#
#  KONTROL ZINCIRI (xlsx icin dogru karsiliklar):
#   K1 CIFT INDIRME : ayni dosya iki kez indirilir, SHA256 esit degilse DUR
#                     (ag bozulmasi / yarim dosya sigortasi).
#   K2 SURUM DAMGASI: link adi + icerik hash'i onceki surumle ayni ise CIK
#                     (bos yere basma yok). Degistiyse devam.
#   K3 HASAT        : mevcut deterministik hasatci kosulur (LLM yok, birebir).
#   K4 SAPMA KAPISI : yeni kayit sayisi 0 ise ya da eskiye gore %30'dan fazla
#                     sapiyorsa KIRMIZI - eski veri GERI KONUR, basilmaz.
#   K5 CIPA KAPISI  : eski setin ilk 8 kaydindan en az %60'i yeni sette de
#                     bulunmali (koklu onlemler bir gunde topluca kalkmaz;
#                     kalktiysa insan gorsun).
#   GECERSE         : basilir + TAM DIFF maili ("DEGISTIRDIM: +eklenen -cikan").
#
#  KULLANIM:
#    ./motor/yanveri-onarici.ps1 -Kaynak damping [-Uygula]
#    ./motor/yanveri-onarici.ps1 -DuyuruSinyal     # ithalat.ticaret.gov.tr/duyurular yeni girdi maili
# ============================================================================
param(
  [string]$Kaynak,
  [switch]$Uygula,
  [switch]$DuyuruSinyal
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0'
$damgaYol = Join-Path $kok 'veri\yanveri-damga.json'

# KAYIT DEFTERI: yeni yan veri eklenince buraya satir eklenir.
# sayfa = xlsx linkinin YAYINLANDIGI resmi sayfa; linkDesen = href regex'i.
$KAYNAKLAR = @{
  damping = @{
    sayfa     = 'https://ticaret.gov.tr/ithalat/ticaret-politikasi-savunma-araclari/damping-ve-subvansiyon'
    linkDesen = 'href="([^"]*Y[^"]*r[^"]*rl[^"]*kteki[^"]*nlemler[^"]*\.xlsx)"'
    hasatci   = 'damping-hasat.ps1'
    cikti     = 'gtip-damping.json'
    anahtarAlan = 'm'   # cipa esles(tir)me alani (urun adi)
  }
  # IGV (3351) / REJIM (3350) LISTELERI - 13.08 kesif notu:
  # ticaret.gov.tr konsolide sayfalari robota ACIK (200) ama xlsx linkleri
  # govdede YOK (icerik ayri bilesenden). DOGRU KAYNAK YOLU: listelerin resmi
  # ekleri RG'de yayimlaniyor - yilbasi mukerrer RG (tam set) + yil ici
  # degisiklik kararlarinin ekleri (RG statik, robot-erisilebilir).
  # PLAN (v2): RG-sinyal 'ithalat rejimi/ilave gumruk' basligi yakaladigi gun
  # karar ekini RG'den indir -> igv-hasat-ulke/xlsx-igv hasatcisina ver ->
  # ayni 5 kapidan gecir. O zamana kadar: cift sinyal ayni gun haber veriyor,
  # hasat elle (deseni kanitli).
}

function Mail([string]$konu,[string]$govde){
  $mb = @{ access_key='5b227e56-94fb-4123-a39a-4286f63db14a'; subject=$konu; from_name='Tetikte Yanveri Onarici'; email='cemdizdar85@hotmail.com'; message=$govde } | ConvertTo-Json -Depth 3
  try { Invoke-RestMethod -Uri 'https://api.web3forms.com/submit' -Method Post -ContentType 'application/json' -UserAgent 'Mozilla/5.0 (TetikteNobetci)' -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -TimeoutSec 30 | Out-Null } catch { Write-Host "mail gitmedi: $($_.Exception.Message)" }
}
function Sha([byte[]]$b){ $s=[Security.Cryptography.SHA256]::Create(); ([BitConverter]::ToString($s.ComputeHash($b)) -replace '-','').Substring(0,20) }
function DamgaOku(){ if(Test-Path $damgaYol){ Get-Content $damgaYol -Raw -Encoding UTF8 | ConvertFrom-Json } else { [pscustomobject]@{} } }
function DamgaYaz($d){ [IO.File]::WriteAllText($damgaYol, ($d|ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false))) }

# ---------- DUYURU SINYALI (ikinci bagimsiz kaynak; RG-sinyalin esi) ----------
if($DuyuruSinyal){
  $u = 'https://ithalat.ticaret.gov.tr'
  $html = & curl.exe -s -L -A $UA --max-time 60 $u
  if($LASTEXITCODE -ne 0){ throw "duyuru sayfasi indirilemedi" }
  $html = $html -join "`n"
  $duyurular = @([regex]::Matches($html,'href="(/duyurular/[^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
  $d = DamgaOku
  $eski = @(); if($d.PSObject.Properties['duyurular']){ $eski = @($d.duyurular) }
  $yeni = @($duyurular | Where-Object { $eski -notcontains $_ })
  if($yeni.Count -gt 0 -and $eski.Count -gt 0){
    Mail 'TETIKTE YANVERI SINYALI - Ithalat Gn.Md. yeni duyuru' ("ithalat.ticaret.gov.tr'de yeni duyuru(lar) - rejim/IGV/askiya degisikligi olabilir:`n" + (($yeni | ForEach-Object { $u + $_ }) -join "`n") + "`n`nGTIP yan verisi etkileniyorsa: ./motor/yanveri-onarici.ps1 -Kaynak damping -Uygula (damping) ya da elle hasat.")
    Write-Host ("YENI DUYURU: {0}" -f $yeni.Count)
  } else { Write-Host "duyuru: yeni yok ($($duyurular.Count) girdi)." }
  if($d.PSObject.Properties['duyurular']){ $d.duyurular = $duyurular } else { $d | Add-Member -NotePropertyName duyurular -NotePropertyValue $duyurular }
  # 13.08 Cem: "her yere kontrolu koyalim" - KONTROL EDILDI damgasi (degisiklik olmasa da).
  # Nabiz bunu izler: damga eskirse "kontrol mekanizmasi durmus" alarmi.
  $dt=(Get-Date).ToString('dd.MM.yyyy HH:mm')
  if($d.PSObject.Properties['duyuruKontrol']){ $d.duyuruKontrol=$dt } else { $d | Add-Member -NotePropertyName duyuruKontrol -NotePropertyValue $dt }
  DamgaYaz $d
  exit 0
}

# ---------- XLSX ONARIM AKISI --------------------------------------------------
if(-not $Kaynak -or -not $KAYNAKLAR.ContainsKey($Kaynak)){ throw ("Kaynak ver: " + ($KAYNAKLAR.Keys -join ', ')) }
$K = $KAYNAKLAR[$Kaynak]
Write-Host "=== YANVERI: $Kaynak ==="

# xlsx linkini resmi sayfadan cek (curl.exe: PS5.1 TLS'i ticaret.gov.tr'ye yetmiyor)
function CurlIndir([string]$url,[string]$hedefYol){
  & curl.exe -s -L -A $UA --max-time 120 -o $hedefYol $url
  if($LASTEXITCODE -ne 0 -or -not (Test-Path $hedefYol)){ throw "curl indiremedi: $url" }
}
$sayfaTmp = Join-Path $env:TEMP "yanveri-$Kaynak-sayfa.html"
CurlIndir $K.sayfa $sayfaTmp
$sayfa = Get-Content $sayfaTmp -Raw -Encoding UTF8
$m = [regex]::Match($sayfa, $K.linkDesen)
if(-not $m.Success){ Mail "YANVERI KIRMIZI ($Kaynak) - xlsx linki sayfada BULUNAMADI" "Sayfa yapisi degismis olabilir: $($K.sayfa)"; throw 'link yok' }
$xlsxUrl = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)
if($xlsxUrl -notmatch '^https?:'){ $xlsxUrl = 'https://ticaret.gov.tr' + $xlsxUrl }
$xlsxUrl = [System.Uri]::EscapeUriString($xlsxUrl)   # bosluk + Turkce karakterli dosya adlari
Write-Host "link: $xlsxUrl"

# K1: cift indirme + hash esitligi
$p1 = Join-Path $env:TEMP "yanveri-$Kaynak-1.xlsx"; $p2 = Join-Path $env:TEMP "yanveri-$Kaynak-2.xlsx"
CurlIndir $xlsxUrl $p1
Start-Sleep -Seconds 2
CurlIndir $xlsxUrl $p2
$h1 = Sha ([IO.File]::ReadAllBytes($p1)); $h2 = Sha ([IO.File]::ReadAllBytes($p2))
if($h1 -ne $h2){ Mail "YANVERI KIRMIZI ($Kaynak) - iki indirme AYNI CIKMADI" "Ag bozulmasi olabilir; basilmadi. $xlsxUrl"; throw 'K1: indirme tutarsiz' }
Write-Host "K1 GECTI: cift indirme birebir ($h1)"

# K2: surum damgasi (url + hash onceki ile ayni mi)
$d = DamgaOku
$onceki = if($d.PSObject.Properties[$Kaynak]){ $d.$Kaynak } else { $null }
if($onceki -and $onceki.sha -eq $h1){
  # "kontrol edildi" tarihi degismese de yazilir - nabiz kontrol mekanizmasini izler (Cem 13.08)
  $onceki | Add-Member -NotePropertyName kontrol -NotePropertyValue ((Get-Date).ToString('dd.MM.yyyy HH:mm')) -Force
  DamgaYaz $d
  Write-Host "K2: degisiklik yok (ayni surum). Kontrol damgasi yazildi, cikiliyor."; exit 0 }
Write-Host ("K2: YENI SURUM (eski: {0})" -f $(if($onceki){ $onceki.url } else { 'ilk kayit' }))

# K3: hasat (eski ciktiyi yedekle, hasatciyi kostur)
$ciktiYol = Join-Path $kok ("veri\" + $K.cikti)
$yedek = Join-Path $env:TEMP ("yanveri-eski-" + $K.cikti)
$eskiVeri = $null
if(Test-Path $ciktiYol){ Copy-Item $ciktiYol $yedek -Force; $eskiVeri = Get-Content $ciktiYol -Raw -Encoding UTF8 | ConvertFrom-Json }
& (Join-Path $here $K.hasatci) -Xlsx $p1
$yeniVeri = Get-Content $ciktiYol -Raw -Encoding UTF8 | ConvertFrom-Json

# K4: sapma kapisi
$eskiN = if($eskiVeri){ @($eskiVeri).Count } else { 0 }
$yeniN = @($yeniVeri).Count
if($yeniN -eq 0 -or ($eskiN -gt 0 -and [math]::Abs($yeniN-$eskiN)/$eskiN -gt 0.30)){
  if(Test-Path $yedek){ Copy-Item $yedek $ciktiYol -Force }
  Mail "YANVERI KIRMIZI ($Kaynak) - SAPMA KAPISI: $eskiN -> $yeniN" "Kayit sayisi asiri sapti; eski veri GERI KONDU, basilmadi. Elle bak: $xlsxUrl"
  throw 'K4: sapma'
}
Write-Host "K4 GECTI: kayit $eskiN -> $yeniN"

# K5: cipa kapisi (eskinin ilk 8 kaydindan >= %60'i yeni sette)
if($eskiN -gt 0){
  $alan = $K.anahtarAlan
  $cipa = @($eskiVeri | Select-Object -First 8)
  $yeniAnahtar = @($yeniVeri | ForEach-Object { "$($_.u)|$($_.$alan)" })
  $bulunan = @($cipa | Where-Object { $yeniAnahtar -contains "$($_.u)|$($_.$alan)" }).Count
  if($bulunan -lt [math]::Ceiling($cipa.Count*0.6)){
    Copy-Item $yedek $ciktiYol -Force
    Mail "YANVERI KIRMIZI ($Kaynak) - CIPA KAPISI: koklu kayitlar kayip ($bulunan/$($cipa.Count))" "Eski setin bilinen kayitlari yeni sette yok; yapisal degisim olabilir. Eski veri GERI KONDU. $xlsxUrl"
    throw 'K5: cipa'
  }
  Write-Host "K5 GECTI: cipa $bulunan/$($cipa.Count)"
}

# DIFF + karar
$diffEk=@(); $diffCik=@()
if($eskiVeri){
  $alan = $K.anahtarAlan
  $eskiK = @($eskiVeri | ForEach-Object { "$($_.u)|$($_.$alan)" })
  $yeniK = @($yeniVeri | ForEach-Object { "$($_.u)|$($_.$alan)" })
  $diffEk  = @($yeniK | Where-Object { $eskiK -notcontains $_ } | Select-Object -Unique -First 25)
  $diffCik = @($eskiK | Where-Object { $yeniK -notcontains $_ } | Select-Object -Unique -First 25)
}
if(-not $Uygula){
  if(Test-Path $yedek){ Copy-Item $yedek $ciktiYol -Force }   # rapor modunda dokunma
  Mail "YANVERI RAPOR ($Kaynak) - yeni surum var, -Uygula verilmedi" ("Yeni: $xlsxUrl`nKayit: $eskiN -> $yeniN`n+ " + ($diffEk -join "`n+ ") + "`n- " + ($diffCik -join "`n- "))
  Write-Host "rapor modu: eski veri geri kondu."; exit 0
}
if($d.PSObject.Properties[$Kaynak]){ $d.$Kaynak = [pscustomobject]@{ url=$xlsxUrl; sha=$h1; tarih=(Get-Date).ToString('yyyy-MM-dd') } }
else { $d | Add-Member -NotePropertyName $Kaynak -NotePropertyValue ([pscustomobject]@{ url=$xlsxUrl; sha=$h1; tarih=(Get-Date).ToString('yyyy-MM-dd') }) }
DamgaYaz $d
Mail "YANVERI DEGISTIRDIM ($Kaynak): $eskiN -> $yeniN kayit" ("Kaynak: $xlsxUrl`nK1 cift-indirme birebir, K4 sapma ve K5 cipa kapilari GECTI.`n`nEKLENEN (ilk 25):`n+ " + ($diffEk -join "`n+ ") + "`n`nCIKAN (ilk 25):`n- " + ($diffCik -join "`n- "))
Write-Host "UYGULANDI + damga + mail."
