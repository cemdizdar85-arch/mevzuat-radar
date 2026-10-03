# arac/ayri-kopya.ps1 — UZUN İŞ İÇİN AYRI ÇALIŞMA KOPYASI (03.10.2026, Cem "1 ve 2 yap")
#
# NEDEN: 03.10'da iki oturum AYNI çalışma klasörünü paylaştı. Biri motor/kaydir-coz.ps1'de ambarın tamamında
# eşdeğerlik provası koştururken öteki oturumun her commit'indeki `git merge --autostash` dosyayı kaldırıp geri
# koydu ("dosyaya yazma, ajanın provası bozulur" uyarısı geldi). Uzun prova / ajan işi kendi kopyasında koşar.
#
# KULLANIM
#   powershell -NoProfile -File arac/ayri-kopya.ps1 -Ac  -Ad kisaltma-provasi     # C:\TETIKTE-CALISMA\kisaltma-provasi
#   powershell -NoProfile -File arac/ayri-kopya.ps1 -Liste
#   powershell -NoProfile -File arac/ayri-kopya.ps1 -Kapat -Ad kisaltma-provasi   # commit'siz iş varsa KAPATMAZ
#   powershell -NoProfile -File arac/ayri-kopya.ps1 -Temizle                       # git'in "prunable" dediği ölü kayıtlar
#
# NE YAPAR (-Ac): origin/main'den DAL AÇMADAN (detached) bir git worktree kurar -> robotların yazdığı dal yok, CLAUDE.md
#   "dal açıp uzun süre çalışmak" yasağına girmez. veri\fabrika (gitignore; soru partisi önbelleği) ana klasördeki
#   önbelleğe BAĞLANTI (junction) olur - 2.491 parti yeniden inmez. sql-yerel\ kopyada ayrıdır.
#   Kopyada iş bitince: commit -> git push origin HEAD:main (oturum.ps1 kuralları aynen geçerli).
# GÖRMEZ: veri\fabrika ortak olduğu için iki kopyada AYNI ANDA parti indirme/yazma çakışır (yalnız okuma güvenli).
#   OneDrive dışında durur (C:\TETIKTE-CALISMA) - OneDrive düzenlemeleri sessizce geri alabiliyor (CLAUDE.md kök notu).
param([switch]$Ac, [switch]$Kapat, [switch]$Liste, [switch]$Temizle, [string]$Ad = '')
# git ilerlemesini stderr'e yazar; 'Stop' altında bu SONLANDIRICI olur (K6 - 03.10 ilk denemede tam böyle yarıda kaldı).
# Karar her git çağrısından sonra $LASTEXITCODE ile verilir.
$ErrorActionPreference = 'Continue'
$kok = Split-Path $PSScriptRoot -Parent
$tabanKlasor = 'C:\TETIKTE-CALISMA'
Set-Location $kok

if ($Liste) { git worktree list; return }
if ($Temizle) { git worktree prune -v; git worktree list; return }
if (-not $Ad -or $Ad -notmatch '^[a-z0-9][a-z0-9\-]{1,40}$') { throw '-Ad gerekli: küçük harf, rakam, tire (ör. kisaltma-provasi)' }
$yol = Join-Path $tabanKlasor $Ad

if ($Ac) {
  if (Test-Path $yol) { throw "zaten var: $yol (önce -Kapat ya da başka -Ad)" }
  New-Item -ItemType Directory -Force $tabanKlasor | Out-Null
  git fetch -q origin main
  git worktree add -q --detach $yol origin/main
  if ($LASTEXITCODE -ne 0) { throw 'git worktree add başarısız' }
  $fabAna = Join-Path $kok 'veri\fabrika'; $fabKopya = Join-Path $yol 'veri\fabrika'
  if (Test-Path $fabAna) {
    if (Test-Path $fabKopya) { Remove-Item $fabKopya -Recurse -Force }
    cmd /c mklink /J "$fabKopya" "$fabAna" | Out-Null
  }
  "AÇILDI: $yol  (origin/main, dalsız)"
  "  veri\fabrika -> $fabAna (bağlantı)"
  "  İş bitince kopyada: git add ... ; git commit -F ... ; git push origin HEAD:main"
  "  Kapat: powershell -NoProfile -File arac/ayri-kopya.ps1 -Kapat -Ad $Ad"
  return
}
if ($Kapat) {
  if (-not (Test-Path $yol)) { throw "yok: $yol" }
  Push-Location $yol
  $kirli = @(git status --porcelain | Where-Object { $_ -notmatch 'veri/fabrika' })
  $itilmemis = @(git log --oneline origin/main..HEAD)
  Pop-Location
  if ($kirli.Count) { throw "commit'siz değişiklik var ($($kirli.Count) dosya) - önce commit+push ya da bilerek sil" }
  if ($itilmemis.Count) { throw "itilmemiş $($itilmemis.Count) commit var - önce git push origin HEAD:main" }
  # bağlantıyı önce kaldır: junction silinirken HEDEF (ana önbellek) silinmesin
  $fabKopya = Join-Path $yol 'veri\fabrika'
  if (Test-Path $fabKopya) { cmd /c rmdir "$fabKopya" | Out-Null }
  git worktree remove --force $yol; if ($LASTEXITCODE -ne 0) { throw 'git worktree remove başarısız' }
  "KAPATILDI: $yol"
  return
}
throw 'Yön belirt: -Ac / -Kapat / -Liste / -Temizle'
