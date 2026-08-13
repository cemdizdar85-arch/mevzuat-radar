# ============================================================================
#  BULTEN GUNLUK - hasat + commit + push (YEREL yedek yol)
#  14.08: GitHub Actions'in Linux'undan KIK'e TLS el sikismasi kurulamadi
#  ("The SSL connection could not be established" - dort turde de). Ayni betik
#  Cem'in Windows makinesinde sorunsuz kosuyor. Bu sarmalayici, Actions cozulene
#  kadar (ya da kalici olarak) yerel gorev zamanlayicisindan gunde bir kosar.
#
#  Kurulum:  motor/bulten-zamanla.ps1  (bir kez calistirilir)
#  Elle kosu: motor/bulten-gunluk.ps1
# ============================================================================
param([switch]$PushYok)
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
Set-Location $kok

$log = Join-Path $kok "veri\bulten-gunluk-son-kosu.txt"
$bas = Get-Date -Format "dd.MM.yyyy HH:mm"
"[$bas] baslangic" | Out-File $log -Encoding utf8

# TUZAK (olculdu): "2>&1 | Tee-Object" hasat ciktisini kaydetmiyordu - betik
# Write-Host kullaniyor, Write-Host BORU HATTINA AKMAZ. Kayit iki satir kaliyordu,
# yani sorun ciktiginda kor kalacaktik. Tum akislari birlestiren "*>&1" sart.
& (Join-Path $here "ihale-bulten-hasat.ps1") -Turler Mal,Yapim,Hizmet,Danismanlik -Yaz *>&1 |
  Tee-Object -FilePath $log -Append
$kod = $LASTEXITCODE
if($null -eq $kod){ $kod = 0 }

if($kod -ne 0){
  "[$(Get-Date -Format 'HH:mm')] KIRMIZI: hasat basarisiz (cikis $kod) - commit YOK" | Tee-Object -FilePath $log -Append
  exit $kod
}
if($PushYok){ "[$(Get-Date -Format 'HH:mm')] -PushYok verildi, commit atlandi" | Tee-Object -FilePath $log -Append; exit 0 }

# yalniz bu iki dosya - baska bir seyi yanlislikla commit'lememek icin
git add veri/ihale-bulten-durum.json 2>&1 | Out-Null
git diff --cached --quiet
$degisti = ($LASTEXITCODE -ne 0)   # PS'te "(komut; ifade)" tek parantezde birlesmez
if(-not $degisti){
  "[$(Get-Date -Format 'HH:mm')] degisiklik yok - commit gerekmedi" | Tee-Object -FilePath $log -Append
  exit 0
}
git commit -q -m ("Kamu Ihale Bulteni: iptal/duzeltme guncellendi ({0})" -f (Get-Date -Format "dd.MM.yyyy")) 2>&1 | Out-Null
# 30.07 dersi: rebase ile push arasindaki saniyede baska robot push'layinca yaris
# kaybediliyor - denemeli dongu.
$n = 0
while($true){
  git pull --rebase -q 2>&1 | Out-Null
  git push -q 2>&1 | Out-Null
  if($LASTEXITCODE -eq 0){ break }
  $n++
  if($n -ge 4){ "[$(Get-Date -Format 'HH:mm')] push 4 denemede basarisiz" | Tee-Object -FilePath $log -Append; exit 1 }
  Start-Sleep -Seconds 5
}
"[$(Get-Date -Format 'HH:mm')] YESIL: guncellendi ve yayinlandi" | Tee-Object -FilePath $log -Append
