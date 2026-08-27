# ============================================================================
#  YUTMA REÇETESİ — 25.08.2026
#  Cem: "1-2-3 yap" (GM onerisi 1)
#
#  NEDEN VAR: 25.08'de bu sirayi ELLE kurdum ve arada UC AGIR HATA yaptim,
#  ucu de VERI SILDI:
#    (1) onek suzgeci kardes standartlari kapsadi -> 8 standart birden dustu
#    (2) kuculme freni yoktu -> iyi metin ozetle degistirildi, "DOGRULANDI" dedi
#    (3) ayri yayin (TMS 28 RG 31.07.2026 degisikligi) silindi, geri yazilmadi
#  Ucu de duzeltildi AMA duzeltmeler betiklerin ICINDE. Sira yanlis kurulursa
#  yine hata olur. Bu recete sirayi CIVATALAR.
#
#  SIRA (pazarliksiz):
#    1) BUTUNLUK KAPISI  - once OLC. Delik yoksa dokunma.
#    2) KURU PROVA       - her standardi once yazmadan gor (kuculme freni burada da calisir)
#    3) UYGULA           - yalniz prova temiz cikanlara
#    4) EKSIK TAMAMLA    - yedekte olup ambarda olmayan AYRI YAYINLARI geri koy
#    5) BUTUNLUK KAPISI  - yeniden olc, delik kapandi mi
#
#  ⚠ 4. ADIM ATLANAMAZ: yeni PDF ayri yayinlari (degisiklik tebligleri)
#  icermez; onek suzgeci onlari sildiyse yalnizca bu adim geri getirir.
#
#  0 USD, model yok. Varsayilan KURU PROVA.
# ============================================================================
param([string[]]$liste = @(), [switch]$uygula, [switch]$olcumAtla)
$ErrorActionPreference='Continue'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
# ⚠ 25.08 GECE DERSI: Adim 4 "bugunun TUM yedeklerini" isliyordu. Ayni gun iki
# oturum kosunca oburunun (gunduz onariminin) yedeklerindeki ONARIM ONCESI
# artiklar da "eksik" sanilip ambara GERI BASILDI: +2.207 cop kayit, kesik
# belge 18 -> 137. Adim 4 yalniz BU KOSUNUN urettigi yedekleri islemeli.
$koseBasi = Get-Date
function Adim($n,$b){ Write-Host ''; Write-Host ("======== ADIM {0}: {1} ========" -f $n,$b) }

# --- 1) ONCE OLC
if(-not $olcumAtla){
  Adim 1 'BUTUNLUK KAPISI (once olc)'
  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'butunluk-kapisi.ps1') 2>&1 |
    Select-String 'Oz-sinav|KAYNAK:|kesik belge|GERCEK KESIK|SORUNLU' | Select-Object -First 6 | ForEach-Object { Write-Host "  $_" }
  $rapor = Join-Path $depoKok 'veri/butunluk-raporu.json'
  if($liste.Count -eq 0 -and (Test-Path $rapor)){
    $coz = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($rapor,[Text.Encoding]::UTF8))
    $liste = @(@($coz.is_listesi) | Where-Object { $_.eksik_paragraf -gt 0 } |
               Sort-Object -Property @{e='eksik_paragraf';Descending=$true} | ForEach-Object { "$($_.kaynak)" })
    Write-Host ("  -> kapinin cikardigi is listesi: {0} kaynak" -f $liste.Count)
  }
}
if($liste.Count -eq 0){ Write-Host 'Islenecek kaynak yok.'; exit 0 }

# --- 2) KURU PROVA
Adim 2 ('KURU PROVA — ' + $liste.Count + ' kaynak')
$temiz=@(); $atlanan=@()
foreach($std in $liste){
  $c = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'standart-yut.ps1') -standart $std 2>&1
  $sat=@($c | ForEach-Object { "$_" })
  $hepsi = $sat -join ' '
  if($hepsi -match 'KUCULME FRENI'){ $atlanan += "$std (kuculme)"; Write-Host ("  {0,-12} FREN - atlandi" -f $std); continue }
  if($hepsi -match 'PDF DEGIL|kalip bilinmiyor|bulunamadi'){ $atlanan += "$std (kaynak yok)"; Write-Host ("  {0,-12} kaynak yok - atlandi" -f $std); continue }
  $y=''; foreach($x in $sat){ if($x -match 'YENI HALI\s*:\s*(\d+) parca · ([\d\.]+)'){ $y="$($Matches[1])p / $($Matches[2])" } }
  if(-not $y){ $atlanan += "$std (prova okunamadi)"; Write-Host ("  {0,-12} prova okunamadi - atlandi" -f $std); continue }
  $temiz += $std
  Write-Host ("  {0,-12} prova TEMIZ -> {1}" -f $std,$y)
}
Write-Host ''
Write-Host ("  prova temiz: {0} · atlanan: {1}" -f $temiz.Count,$atlanan.Count)
foreach($a in $atlanan){ Write-Host "    - $a" }
if(-not $uygula){ Write-Host ''; Write-Host 'KURU PROVA MODU — yazma yapilmadi. -uygula ile kos.'; exit 0 }

# --- 3) UYGULA
Adim 3 ('UYGULA — ' + $temiz.Count + ' kaynak')
$yazilan=@(); $dusen=@()
foreach($std in $temiz){
  $c = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'standart-yut.ps1') -standart $std -uygula 2>&1
  $hepsi = (@($c | ForEach-Object { "$_" })) -join ' '
  if($hepsi -match 'DOGRULANDI'){ $yazilan += $std; Write-Host ("  {0,-12} YAZILDI ve dogrulandi" -f $std) }
  else { $dusen += $std; Write-Host ("  {0,-12} !! DUSTU - ambar korundu" -f $std) }
}

# --- 4) EKSIK TAMAMLA (ayri yayinlar)
Adim 4 'EKSIK KAYIT TAMAMLAMA (ayri yayinlar geri konur)'
$fab = Join-Path $depoKok 'veri/fabrika'
$bugun = (Get-Date -Format 'yyyyMMdd')
foreach($f in (Get-ChildItem $fab -Filter "yedek-*-$bugun-*.json" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -ge $koseBasi })){
  $c = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'eksik-kayit-tamamla.ps1') -yedekDosya $f.Name -uygula 2>&1
  $hepsi = (@($c | ForEach-Object { "$_" })) -join ' '
  if($hepsi -match 'TAMAMLANDI: (\d+)'){ Write-Host ("  {0,-42} +{1} kayit" -f $f.Name,$Matches[1]) }
}

# --- 5) YENIDEN OLC
Adim 5 'BUTUNLUK KAPISI (teyit)'
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'butunluk-kapisi.ps1') 2>&1 |
  Select-String 'KAYNAK:|kesik belge|SORUNLU' | Select-Object -First 4 | ForEach-Object { Write-Host "  $_" }

Write-Host ''
Write-Host '================ RECETE OZETI ================'
Write-Host ("  yazilan: {0} · dusen: {1} · atlanan: {2}" -f $yazilan.Count,$dusen.Count,$atlanan.Count)
if($dusen.Count){ Write-Host ("  DUSENLER: {0}" -f ($dusen -join ', ')) }
if($atlanan.Count){ Write-Host ("  ATLANANLAR: {0}" -f ($atlanan -join ', ')) }
Write-Host '  Yedekler: veri/fabrika/yedek-*.json  (geri donus: motor\yedekten-geri-yukle.ps1)'