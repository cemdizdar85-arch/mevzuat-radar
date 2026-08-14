# ============================================================================
#  MEVZUAT TAM YENILEME (14.08) - Cem: "robotu kostur diger 426 duzelt".
#
#  NEDEN: parcalayicida bugun IKI kusur bulundu ve duzeltildi
#   (1) "(Mülga ibare/fıkra" iceren madde komple atiliyordu,
#   (2) "Madde 13 (Değişik: ...)-" gibi yazimlar hic goruumuyordu.
#  Duzeltmenin etkisi ancak kaynak YENIDEN YUTULUNCA gorunur. Robot hash
#  degismedigi icin yeniden yutmaz - bu betik damgalari silip zorlar.
#
#  KOR NOKTA UYARISI: madde-bosluk taramasi 766 dosyayi tarayip 103 supheliyi
#  kaynaktan okudu, ama bir kanunun SON maddeleri kayipsa bosluk olusmaz ve
#  tarama goremez. Tam yeniden yutma o kor noktayi da kapatir.
#
#  KAYNAGA NAZIK: mevzuat.gov.tr seri istek yagmurunu kesiyor. Istekler arasi
#  bekleme + 5 ardisik hatada DEVRE KESICI var (Actions'taki desenin aynisi).
#  Hazir metni depoda olan kaynak INDIRILMEZ, dosyadan kopyalanir.
# ============================================================================
param(
  [int]$Tavan = 0,          # 0 = hepsi
  [switch]$YalnizIndir,     # yutma yapma, sadece metinleri hazirla
  [switch]$YalnizYut        # indirme yapma, mevcut _txt ile yut
)
$ErrorActionPreference = "Continue"
if($PSVersionTable.PSVersion.Major -lt 6){ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 }
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$txtDir = Join-Path $kok "_txt"
$hazirDir = Join-Path $kok "veri\mevzuat-hazir"
if(-not (Test-Path $txtDir)){ New-Item -ItemType Directory -Force $txtDir | Out-Null }
$curl = @(Get-Command curl.exe,curl -CommandType Application -ErrorAction SilentlyContinue)[0].Source
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
$manifest = Get-Content (Join-Path $kok "veri\mevzuat-kaynaklar.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$kaynaklar = @($manifest.kanunlar)
if($Tavan -gt 0){ $kaynaklar = @($kaynaklar | Select-Object -First $Tavan) }

if(-not $YalnizYut){
  Write-Host ("1) METIN HAZIRLAMA - {0} kaynak" -f $kaynaklar.Count)
  $hazir=0; $inen=0; $atlanan=0; $hata=0; $ardisikHata=0; $devreKesik=$false
  foreach($k in $kaynaklar){
    $slug = "$($k.slug)"; $kimlik = "$($k.pdfId)"
    $txt = Join-Path $txtDir "$slug.txt"
    if(Test-Path $txt){ $atlanan++; continue }              # bu kosuda zaten hazirlandi
    $hazirYol = Join-Path $hazirDir "$slug.txt"
    if($kimlik -eq 'HAZIR' -or (Test-Path $hazirYol)){
      if(Test-Path $hazirYol){ Copy-Item $hazirYol $txt -Force; $hazir++ }
      else { $hata++; Write-Host ("   HAZIR ama depoda yok: {0}" -f $slug) }
      continue
    }
    if($devreKesik){ $atlanan++; continue }
    $u = if($kimlik -like 'G7:*'){ "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$($kimlik.Substring(3))&mevzuatTur=KurumVeKurulusYonetmeligi&mevzuatTertip=5" }
         elseif($kimlik -like 'G9:*'){ "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$($kimlik.Substring(3))&mevzuatTur=Teblig&mevzuatTertip=5" }
         elseif($kimlik -match '^[79]\.'){ "https://www.mevzuat.gov.tr/MevzuatMetin/yonetmelik/$kimlik.pdf" }
         else { "https://www.mevzuat.gov.tr/MevzuatMetin/$kimlik.pdf" }
    $pdf = Join-Path $txtDir "$slug.pdf"
    & $curl -sS -L --max-time 45 -A $ua -H "Referer: https://www.mevzuat.gov.tr/" -o $pdf $u 2>$null
    $iyi = (Test-Path $pdf) -and ((Get-Item $pdf).Length -gt 20000)
    if($iyi){
      & pdftotext -enc UTF-8 $pdf $txt 2>$null | Out-Null
      if(Test-Path $txt){ $inen++; $ardisikHata=0 } else { $hata++ }
    } else {
      $hata++; $ardisikHata++
      if($ardisikHata -ge 5){ $devreKesik=$true; Write-Host "   !! DEVRE KESICI: 5 ardisik hata - kaynak yagmuru kesiyor, kalan indirmeler atlandi" }
    }
    if(Test-Path $pdf){ Remove-Item $pdf -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Milliseconds 1500
    if((($hazir+$inen+$hata) % 50) -eq 0){ Write-Host ("   ... {0} hazir · {1} indi · {2} hata" -f $hazir,$inen,$hata) }
  }
  Write-Host ("   SONUC: {0} depodan · {1} indirildi · {2} zaten vardi · {3} hata" -f $hazir,$inen,$atlanan,$hata)
}
if($YalnizIndir){ Write-Host "(-YalnizIndir verildi, yutma yapilmadi)"; return }

# --- 2) damgalari sil (hash degismese de yeniden yutsun) ---------------------
$durumYol = Join-Path $kok "veri\mevzuat\_durum.json"
$metniOlan = @(Get-ChildItem $txtDir -Filter *.txt | ForEach-Object { $_.BaseName })
Write-Host ("`n2) DAMGA SIFIRLAMA - metni hazir olan {0} kaynak" -f $metniOlan.Count)
if(Test-Path $durumYol){
  $durum = Get-Content $durumYol -Raw -Encoding UTF8 | ConvertFrom-Json
  $silinen = 0
  foreach($s in $metniOlan){ if($durum.PSObject.Properties.Name -contains $s){ $durum.PSObject.Properties.Remove($s); $silinen++ } }
  ($durum | ConvertTo-Json -Depth 6) | Out-File $durumYol -Encoding utf8
  Write-Host ("   {0} damga silindi" -f $silinen)
}
Write-Host "`n3) YUTMA (mevzuat-yut.ps1)"
Set-Location $kok
& (Join-Path $here "mevzuat-yut.ps1")
