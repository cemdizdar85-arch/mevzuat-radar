# ============================================================================
#  OTURUM ON KONTROLU — bu depoda baska biri calisiyor mu?
#
#  NEDEN VAR (25.08.2026)
#  Ayni gun UC KEZ is kayboldu. Ikinci bir oturum ayni depoda calisiyordu:
#    1. menu.js + marka-serit.js renk duzeltmeleri diskten silindi.
#    2. stil-acik.css jeton calismasi silindi.
#    3. COMMIT EDILDIKTEN SONRA bile: diger oturum yerel HEAD'i origin/main'e
#       sifirlayinca commit daldan dustu, dosyalar diskten gitti. Commit
#       NESNESI duruyordu, oradan kurtarildi.
#  Ucunu de ancak OLCEREK fark ettim - duzelttigim sayfalar olcumde yine
#  kirik cikti. Olcmeseydim "duzelttim" diye rapor edecektim.
#
#  NE YAPAR
#  Baska bir oturumun izlerini arar ve UC DURUM doner:
#    AKTIF   - iz var, dikkatli calis
#    SESSIZ  - iz yok
#    KOR     - bakilamadi (git yok, depo degil)
#  Cikis kodu HER ZAMAN 0'dir. Bu bir KAPI degil, UYARIDIR - kimseyi
#  durdurmaz, ne yapmasi gerektigini soyler.
#
#  Kullanim:  pwsh arac/oturum-onkontrol.ps1
#             pwsh arac/oturum-onkontrol.ps1 -Dakika 30
# ============================================================================
param([int]$Dakika = 20)

$ErrorActionPreference = "Continue"

$kok = try { (git rev-parse --show-toplevel 2>$null).Trim() } catch { $null }
if (-not $kok) {
  Write-Host "OTURUM ON KONTROLU: KOR — git deposu bulunamadi, bakilamadi."
  exit 0
}
Set-Location $kok
$simdi = Get-Date
$esik  = $simdi.AddMinutes(-$Dakika)
$iz    = @()

# --- 1) son commit taze mi -------------------------------------------------
$sonTarih = try { [datetime](git log -1 --format=%cI 2>$null) } catch { $null }
if ($sonTarih -and $sonTarih -gt $esik) {
  $dk = [int]($simdi - $sonTarih).TotalMinutes
  $ozet = (git log -1 --format=%s 2>$null)
  if ($ozet.Length -gt 54) { $ozet = $ozet.Substring(0,54) + "..." }
  $iz += "son commit {0} dk once  ->  {1}" -f $dk, $ozet
}

# --- 2) reflog: yakinda reset/checkout olmus mu ----------------------------
# Calisan agaci hizalayan komutlar budur; commit'lenmemis isi silen de bunlar.
$reflog = git reflog --date=iso -n 25 2>$null
if ($reflog) {
  foreach ($satir in $reflog) {
    if ($satir -match '\{([^}]+)\}.*?:\s*(reset|checkout|merge|rebase|pull)') {
      $t = try { [datetime]$matches[1] } catch { $null }
      if ($t -and $t -gt $esik) {
        $iz += "reflog: {0} ({1} dk once)" -f $matches[2], [int]($simdi - $t).TotalMinutes
        break
      }
    }
  }
}

# --- 3) git kilidi acik mi (o an bir komut kosuyor) ------------------------
foreach ($kilit in @(".git\index.lock", ".git\HEAD.lock", ".git\refs\heads\main.lock")) {
  if (Test-Path -LiteralPath (Join-Path $kok $kilit)) {
    $iz += "git kilidi acik: $kilit  (SU AN bir git komutu kosuyor)"
  }
}

# --- 4) diskte taze degisen izlenen dosya ---------------------------------
$taze = git status --porcelain 2>$null | Where-Object { $_ -notmatch '^\?\?' } |
        ForEach-Object { $_.Substring(3).Trim('"') } |
        Where-Object { Test-Path -LiteralPath $_ } |
        Where-Object { (Get-Item -LiteralPath $_).LastWriteTime -gt $esik }
if ($taze) {
  $iz += "diskte {0} dosya son {1} dk icinde degismis" -f @($taze).Count, $Dakika
}

# --- 5) yerel dal uzagin GERISINDE mi (birisi sifirlamis olabilir) --------
git fetch -q origin 2>$null
$sayim = git rev-list --left-right --count origin/main...HEAD 2>$null
if ($sayim -and $sayim -match '^(\d+)\s+(\d+)$') {
  $geride = [int]$matches[1]; $ileride = [int]$matches[2]
  if ($geride -gt 0) { $iz += "yerel dal uzagin {0} commit GERISINDE" -f $geride }
  if ($ileride -gt 0) { $iz += "yerelde {0} YAYINLANMAMIS commit var (risk altinda)" -f $ileride }
}

# --- rapor ----------------------------------------------------------------
if ($iz.Count -eq 0) {
  Write-Host ("OTURUM ON KONTROLU: SESSIZ — son {0} dk icinde baska oturum izi yok." -f $Dakika)
  exit 0
}

Write-Host ("OTURUM ON KONTROLU: AKTIF — baska bir oturum bu depoda calisiyor olabilir." -f $Dakika)
Write-Host ""
foreach ($i in $iz) { Write-Host "    $i" }
Write-Host ""
Write-Host "  KURAL (25.08'de uc kez is kaybedildi):"
Write-Host "    1. Duzenleme ve 'git commit' TEK adimda yapilir. Arada olcum,"
Write-Host "       tarayici turu, baska dosya YOK."
Write-Host "    2. Commit yetmez. Yalniz UZAK kalicidir:"
Write-Host "         git worktree add --detach <gecici> origin/main"
Write-Host "         git cherry-pick -x <sha>  &&  git push origin HEAD:main"
Write-Host "    3. Duzeltmeden sonra dosyada aradigin deseni say:"
Write-Host "         grep -c '<desen>' <dosya>      sifirsa is geri alinmistir."
Write-Host "    4. Bir commit kaybolduysa nesnesi genelde durur:"
Write-Host "         git cat-file -t <sha>   ->  commit  ise cherry-pick ile kurtar."
exit 0
