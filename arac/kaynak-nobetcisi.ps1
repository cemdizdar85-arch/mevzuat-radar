# ============================================================================
#  KAYNAK NOBETCISI (v2) - resmi kaynaklari izler; DETERMINISTIK olani OTOMATIK
#  yeniden hasat eder (robot degistirir), hepsini Cem'e mail atar (o kontrol eder).
#  GitHub Actions (ubuntu + pwsh) uzerinde GUNLUK kosar.
#  GUVENLIK: yapay zeka ile okuma-yazma YOK. Sadece resmi Excel'i indirip AYNI
#  regex harvest'ini calistirir (uydurma imkansiz). Hata olursa alert'e duser.
# ============================================================================
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$veriDir = Join-Path $kok "veri"
$hashDosya = Join-Path $veriDir ".kaynak-hash.json"
$UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) MevzuatRadar-Nobetci"
$is = New-Object System.Collections.Generic.List[string]   # islem gunlugu (maile)

function Hashle($bytes){ $sha=[System.Security.Cryptography.SHA256]::Create(); return ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-','') }
function HashMetin([string]$s){ return (Hashle ([System.Text.Encoding]::UTF8.GetBytes($s))) }
function Sayfa([string]$url){ try { return (Invoke-WebRequest -Uri $url -UserAgent $UA -TimeoutSec 90 -UseBasicParsing).Content } catch { return $null } }
function Indir([string]$url,[string]$hedef){ try { Invoke-WebRequest -Uri $url -UserAgent $UA -TimeoutSec 300 -UseBasicParsing -OutFile $hedef; return (Test-Path $hedef) } catch { return $false } }
# sayfadan .zip data linkini cikar (yillik degisen hash'li url'yi yakalar)
function ZipLink([string]$html,[string]$anahtar){
  if(-not $html){ return $null }
  $m = [regex]::Match($html, '(https?://[^"'']*?/data/[^"'']*?' + $anahtar + '[^"'']*?\.zip)', 'IgnoreCase')
  if($m.Success){ return ([System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)) }
  # goreli link olabilir
  $m2 = [regex]::Match($html, '(/data/[^"'']*?' + $anahtar + '[^"'']*?\.zip)', 'IgnoreCase')
  if($m2.Success){ return "https://ticaret.gov.tr" + [System.Net.WebUtility]::HtmlDecode($m2.Groups[1].Value) }
  return $null
}
function XlsxKlasor([string]$kok){  # icinde .xlsx olan klasoru bul
  $d = Get-ChildItem $kok -Recurse -Filter *.xlsx -ErrorAction SilentlyContinue | Select-Object -First 1
  if($d){ return $d.Directory.FullName } else { return $null }
}
# sayfadan .xlsx data linkini cikar (tarih degisince url degisir; anahtar ile filtrele)
function XlsxLink([string]$html,[string]$anahtar){
  if(-not $html){ return $null }
  $m = [regex]::Match($html, '(https?://[^"'']*?/data/[^"'']*?' + $anahtar + '[^"'']*?\.xlsx)', 'IgnoreCase')
  if($m.Success){ return ([System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)) }
  $m2 = [regex]::Match($html, '(/data/[^"'']*?' + $anahtar + '[^"'']*?\.xlsx)', 'IgnoreCase')
  if($m2.Success){ return "https://ticaret.gov.tr" + [System.Net.WebUtility]::HtmlDecode($m2.Groups[1].Value) }
  return $null
}

# --- onceki hash'ler ---
$onceki = @{}
if(Test-Path $hashDosya){ try { $j = Get-Content $hashDosya -Raw -Encoding UTF8 | ConvertFrom-Json; foreach($p in $j.PSObject.Properties){ $onceki[$p.Name] = $p.Value } } catch {} }
$yeni = @{}
$veriDegisti = $false
$mailSatir = @()

# ============ 1) DETERMINISTIK: Ithalat Rejimi + IGV Excel -> oto yeniden hasat ============
$rejimSayfa = "https://ticaret.gov.tr/ithalat/ithalat-mevzuati/ithalat-rejimi-karari-igv-karari-ve-ithalat-tebligleri/1-ithalat-rejimi-kararikarar-sayisi3350karar-metni-ve-tablolar-konsolide-edilmis-olup-gunceldir"
$igvSayfa   = "https://ticaret.gov.tr/ithalat/ithalat-mevzuati/ithalat-rejimi-karari-igv-karari-ve-ithalat-tebligleri/2-ithalatta-ilave-gumruk-vergisi-uygulanmasina-iliskin-karar-karar-sayisi-3351-karar-metni-ve-tablolar-konsolide-edilmis-olup-gunceldir"
$rejimZipUrl = ZipLink (Sayfa $rejimSayfa) "rejim"
$igvZipUrl   = ZipLink (Sayfa $igvSayfa) "igv"
$is.Add("rejim zip: $rejimZipUrl")
$is.Add("igv zip: $igvZipUrl")

if($rejimZipUrl -and $igvZipUrl){
  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("kaynak_" + [System.IO.Path]::GetRandomFileName())
  New-Item -ItemType Directory -Force $tmp | Out-Null
  $rzip = Join-Path $tmp "rejim.zip"; $izip = Join-Path $tmp "igv.zip"
  $ok1 = Indir $rejimZipUrl $rzip; $ok2 = Indir $igvZipUrl $izip
  if($ok1 -and $ok2){
    $birlesikHash = (Hashle ([System.IO.File]::ReadAllBytes($rzip))) + (Hashle ([System.IO.File]::ReadAllBytes($izip)))
    $yeni["Ithalat Rejimi + IGV Excel"] = $birlesikHash
    if($onceki.ContainsKey("Ithalat Rejimi + IGV Excel") -and $onceki["Ithalat Rejimi + IGV Excel"] -ne $birlesikHash){
      $is.Add("DEGISTI: Ithalat Rejimi/IGV Excel -> yeniden hasat baslıyor")
      try {
        Expand-Archive -Path $rzip -DestinationPath (Join-Path $tmp "rejim") -Force
        Expand-Archive -Path $izip -DestinationPath (Join-Path $tmp "igv") -Force
        $rk = XlsxKlasor (Join-Path $tmp "rejim"); $ik = XlsxKlasor (Join-Path $tmp "igv")
        if($rk -and $ik){
          # ALT-SUREC: hepsini-hasat'in exit kodu nobetciyi kesmesin (izole)
          $psExe = if(Get-Command pwsh -ErrorAction SilentlyContinue){ "pwsh" } else { "powershell" }
          $hepYol = Join-Path $here "..\motor\hepsini-hasat.ps1"
          & $psExe -NoProfile -ExecutionPolicy Bypass -File $hepYol -RejimKlasor $rk -IgvKlasor $ik
          if($LASTEXITCODE -eq 0){
            $veriDegisti = $true
            $mailSatir += "OTOMATIK GUNCELLENDI: Ithalat Rejimi/IGV degisti, veri/*.json yeniden uretildi (deterministik). Commit'lendi - KONTROL ET."
            $is.Add("yeniden hasat TAMAM")
          } else {
            $mailSatir += "DIKKAT: Ithalat Rejimi/IGV degisti, otomatik hasat KISMEN hata verdi (exit $LASTEXITCODE) - veri commit edilmedi, ELLE bak: $rejimZipUrl"
            $is.Add("hasat exit $LASTEXITCODE - veri commit YOK")
          }
        } else { $mailSatir += "DIKKAT: Ithalat Rejimi/IGV Excel degisti AMA otomatik hasat yapilamadi (xlsx klasoru bulunamadi) - ELLE bak: $rejimZipUrl"; $is.Add("xlsx klasoru yok") }
      } catch {
        $mailSatir += "DIKKAT: Ithalat Rejimi/IGV degisti, otomatik hasat HATA verdi - ELLE bak. Hata: $($_.Exception.Message)"
        $is.Add("hasat HATA: $($_.Exception.Message)")
      }
    } elseif(-not $onceki.ContainsKey("Ithalat Rejimi + IGV Excel")){ $is.Add("ILK KAYIT: Ithalat Rejimi/IGV") }
    else { $is.Add("AYNI: Ithalat Rejimi/IGV") }
  } else { $is.Add("Excel indirilemedi"); if($onceki.ContainsKey("Ithalat Rejimi + IGV Excel")){ $yeni["Ithalat Rejimi + IGV Excel"]=$onceki["Ithalat Rejimi + IGV Excel"] } }
  try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}

# ============ 1b) DETERMINISTIK: Damping/subvansiyon "Yururlukteki Onlemler" xlsx -> oto hasat ============
#  Ticaret Bak. tum yururlukteki damping/subvansiyon onlemlerini TEK konsolide Excel'de yayinlar
#  (dosya adi tarihli: "Yururlukteki Onlemler <tarih>.xlsx"). Degisince damping-hasat.ps1 ile
#  gtip-damping.json yeniden uretilir (deterministik, AI YOK).
$dampingSayfa = "https://www.ticaret.gov.tr/ithalat/ticaret-politikasi-savunma-araclari/damping-ve-subvansiyon"
$dampingXlsxUrl = XlsxLink (Sayfa $dampingSayfa) "nlemler"
$is.Add("damping xlsx: $dampingXlsxUrl")
if($dampingXlsxUrl){
  $tmpD = Join-Path ([System.IO.Path]::GetTempPath()) ("damping_" + [System.IO.Path]::GetRandomFileName())
  New-Item -ItemType Directory -Force $tmpD | Out-Null
  $dxlsx = Join-Path $tmpD "damping.xlsx"
  if(Indir $dampingXlsxUrl $dxlsx){
    $dhash = Hashle ([System.IO.File]::ReadAllBytes($dxlsx))
    $yeni["Damping Yururlukteki Onlemler"] = $dhash
    if($onceki.ContainsKey("Damping Yururlukteki Onlemler") -and $onceki["Damping Yururlukteki Onlemler"] -ne $dhash){
      $is.Add("DEGISTI: Damping onlemler xlsx -> yeniden hasat")
      try {
        $psExe = if(Get-Command pwsh -ErrorAction SilentlyContinue){ "pwsh" } else { "powershell" }
        $dhYol = Join-Path $here "..\motor\damping-hasat.ps1"
        & $psExe -NoProfile -ExecutionPolicy Bypass -File $dhYol -Xlsx $dxlsx
        if($LASTEXITCODE -eq 0){
          $veriDegisti = $true
          $mailSatir += "OTOMATIK GUNCELLENDI: Damping/subvansiyon yururlukteki onlemler degisti, gtip-damping.json yeniden uretildi (deterministik). Commit'lendi - KONTROL ET."
          $is.Add("damping hasat TAMAM")
        } else {
          $mailSatir += "DIKKAT: Damping onlemler degisti, otomatik hasat hata (exit $LASTEXITCODE) - veri commit edilmedi, ELLE bak: $dampingXlsxUrl"
          $is.Add("damping hasat exit $LASTEXITCODE")
        }
      } catch { $mailSatir += "DIKKAT: Damping hasat HATA - ELLE bak. $($_.Exception.Message)"; $is.Add("damping HATA: $($_.Exception.Message)") }
    } elseif(-not $onceki.ContainsKey("Damping Yururlukteki Onlemler")){ $is.Add("ILK KAYIT: Damping") }
    else { $is.Add("AYNI: Damping") }
  } else { $is.Add("damping xlsx indirilemedi"); if($onceki.ContainsKey("Damping Yururlukteki Onlemler")){ $yeni["Damping Yururlukteki Onlemler"]=$onceki["Damping Yururlukteki Onlemler"] } }
  try { Remove-Item $tmpD -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}

# ============ 2) ALERT: nuansli kaynaklar (robot YAZMAZ, sadece haber verir) ============
$alertKaynaklar = @(
  @{ ad="GİB güncel KDV oranları (PDF)"; url="https://cdn.gib.gov.tr/api/gibportal-file/file/getFileResources?objectKey=arsiv/yardim-kaynaklar/yararli-bilgiler/kdv-oranlari.pdf" }
  @{ ad="Ticaret Bak. Güncel Vergi Kodları"; url="https://ticaret.gov.tr/gumruk-islemleri/dijital-gumruk-uygulamalari/edi-xml-referans-mesajlari/guncel-vergi-kodlari" }
  @{ ad="İthalat Rejimi değişiklik kararları (2026)"; url="https://ticaret.gov.tr/ithalat/ithalat-mevzuati/ithalat-rejimi-karari-igv-karari-ve-ithalat-tebligleri/1-1-ithalat-rejimi-kararinda-degisiklik-yapilmasina-iliskin-kararlar-2026-yili" }
)
foreach($k in $alertKaynaklar){
  $c = Sayfa $k.url
  if($null -eq $c){ if($onceki.ContainsKey($k.ad)){ $yeni[$k.ad]=$onceki[$k.ad] }; continue }
  $h = HashMetin $c
  $yeni[$k.ad] = $h
  if($onceki.ContainsKey($k.ad) -and $onceki[$k.ad] -ne $h){ $mailSatir += "DEGISTI (elle bak): $($k.ad) -> $($k.url)"; $is.Add("DEGISTI(alert): $($k.ad)") }
  elseif(-not $onceki.ContainsKey($k.ad)){ $is.Add("ILK KAYIT: $($k.ad)") } else { $is.Add("AYNI: $($k.ad)") }
}

# --- hash guncelle + mail ---
($yeni | ConvertTo-Json) | Out-File $hashDosya -Encoding utf8
$is | ForEach-Object { Write-Host $_ }
if($mailSatir.Count -gt 0){
  $mail = @{
    access_key="5b227e56-94fb-4123-a39a-4286f63db14a"
    subject="KAYNAK NOBETCISI ($(Get-Date -Format dd.MM.yyyy)): degisiklik var"
    from_name="Mevzuat Radari Kaynak Nobetcisi"; email="cemdizdar85@hotmail.com"
    "Durum"=($mailSatir -join "`n")
    "Not"="Deterministik olanlar (Ithalat Rejimi/IGV) OTOMATIK guncellendi ve commit'lendi - sadece kontrol et. 'elle bak' yazanlar nuansli (KDV/OTV) - birincil metni okuyup elle guncelle. Robot asla uydurmaz."
  } | ConvertTo-Json
  try { Invoke-RestMethod -Method Post -Uri "https://api.web3forms.com/submit" -Body ([System.Text.Encoding]::UTF8.GetBytes($mail)) -ContentType "application/json" -TimeoutSec 30 | Out-Null; Write-Host "MAIL gonderildi" } catch { Write-Host "MAIL hata: $($_.Exception.Message)" }
} else { Write-Host "Degisiklik yok - mail yok." }
if($veriDegisti){ Write-Host "VERI DEGISTI - CI commit edecek." }
