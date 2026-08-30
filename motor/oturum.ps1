# ============================================================================
#  OTURUM NÖBETÇİSİ — "konuşmalar birbirine karışmasın"
#
#  NEDEN VAR (30.08.2026): İki tel 3 gün ayrı kaldı. 66 commit yerelde,
#  878 commit uzakta, 245 dosya hiç commit'lenmemiş, 89 dosya çakıştı.
#  Aynı iş iki kez yapılmıştı (Senaryo Raporu commit'i iki ayrı hash'te).
#
#  ÜÇ İŞ YAPAR:
#   -Ac    : ana telle hizala + iş kolunu kilitle + kütüğe yaz
#   -Kapat : commit'siz iş kaldı mı ölç + it + kilidi bırak
#   -Durum : kim nerede çalışıyor
#
#  Kilit dosyası YERELDİR (git'e girmez) - aynı makinedeki oturumlar görür,
#  kilit dosyasının kendisi çakışma üretmez.
# ============================================================================
param(
  [switch]$Ac,
  [switch]$Kapat,
  [switch]$Durum,
  [switch]$Nabiz,     # oturum açılışında otomatik koşar (hook)
  [string]$Kol = "",
  [switch]$Zorla      # bayat kilidi ez (yalnız Cem söylerse)
)

$ErrorActionPreference = 'Stop'
$KOK      = Split-Path $PSScriptRoot -Parent
$KILIT    = Join-Path $KOK 'veri\OTURUM-KILIDI.json'
$KOLLAR   = @('alacak','marka','destek','ihale','sinav','site','pazarlama','altyapi')
$BAYAT_SA = 4     # bu kadar saatten eski kilit "bayat" sayılır

function Yaz($m, $renk='Gray'){ Write-Host $m -ForegroundColor $renk }
function KilitOku {
  if(Test-Path $KILIT){ try { return (Get-Content $KILIT -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null } }
  return $null
}
function KilitYaz($o){
  $d = Split-Path $KILIT -Parent
  if(-not (Test-Path $d)){ New-Item -ItemType Directory -Force -Path $d | Out-Null }
  ($o | ConvertTo-Json -Depth 6) | Set-Content $KILIT -Encoding UTF8
}
function SaatFark($iso){
  try { return [math]::Round(((Get-Date) - [datetime]::Parse($iso)).TotalHours, 1) } catch { return 999 }
}

# --------------------------------------------------------------------------
#  NABIZ — oturum açılışında hook'tan otomatik koşar. Karar vermez, FOTOĞRAF
#  çeker: tel nerede, kim nerede çalışıyor, commit'siz iş var mı.
#  30.08 dersi: oturum bu bilgiyi görmeden çalışmaya başlarsa çakışma üretiyor.
# --------------------------------------------------------------------------
if($Nabiz){
  try {
    git -C $KOK fetch origin main -q 2>&1 | Out-Null
    $geri  = [int](git -C $KOK rev-list --count HEAD..origin/main 2>$null)
    $ileri = [int](git -C $KOK rev-list --count origin/main..HEAD 2>$null)
    $kirli = @(git -C $KOK status --short 2>$null | Where-Object { $_ -match '^( M|M |MM|A |AM)' }).Count
    $dal   = git -C $KOK rev-parse --abbrev-ref HEAD 2>$null

    Write-Host "`n===== TETİKTE · OTURUM NABZI =====" -ForegroundColor Cyan
    Write-Host "  dal: $dal"
    if($geri -gt 0){ Write-Host "  ⛔ ANA TELDEN $geri COMMIT GERİDE — çalışmadan önce hizala" -ForegroundColor Red }
    else { Write-Host "  ✅ ana telle eşit" -ForegroundColor Green }
    if($ileri -gt 0){ Write-Host "  ⚠ $ileri commit itilmemiş" -ForegroundColor Yellow }
    if($kirli -gt 0){ Write-Host "  ⚠ $kirli dosya commit'siz" -ForegroundColor Yellow }

    # DİKKAT: değişken adı $ac OLAMAZ - PowerShell harf ayırmaz, -Ac switch
    # parametresine dizi atamaya kalkar ve betik çöker (30.08'de yaşandı).
    $k = KilitOku
    $acikKollar = if($k){ @($k.oturumlar) } else { @() }
    if($acikKollar.Count -gt 0){
      Write-Host "  AÇIK KOLLAR:" -ForegroundColor Yellow
      foreach($o in $acikKollar){ Write-Host ("    {0} ({1} sa, pid={2})" -f $o.kol, (SaatFark $o.acilis), $o.pid) -ForegroundColor Yellow }
      Write-Host "  -> bu kollara DOKUNMA" -ForegroundColor Yellow
    } else { Write-Host "  açık oturum yok" }

    Write-Host "  Başlarken: powershell -NoProfile -File motor/oturum.ps1 -Ac -Kol <kol>" -ForegroundColor Cyan
    Write-Host "==================================`n" -ForegroundColor Cyan
  } catch { Write-Host "nabiz olculemedi: $_" -ForegroundColor DarkGray }
  exit 0
}

# --------------------------------------------------------------------------
if($Durum){
  $k = KilitOku
  if(-not $k -or -not $k.oturumlar -or @($k.oturumlar).Count -eq 0){ Yaz "Açık oturum yok." 'Green'; exit 0 }
  Yaz "`n=== AÇIK OTURUMLAR ===" 'Cyan'
  foreach($o in $k.oturumlar){
    $s = SaatFark $o.acilis
    $et = if($s -gt $BAYAT_SA){ "BAYAT ($s sa)" } else { "$s sa" }
    Yaz ("  {0,-12} pid={1,-8} {2}" -f $o.kol, $o.pid, $et)
  }
  exit 0
}

# --------------------------------------------------------------------------
if($Ac){
  if($Kol -eq "" -or $KOLLAR -notcontains $Kol){
    Yaz "HATA: -Kol ver. Geçerli: $($KOLLAR -join ' · ')" 'Red'; exit 1
  }

  Yaz "`n=== 1/3 · ANA TELLE HİZALAMA ===" 'Cyan'
  git -C $KOK fetch origin main -q 2>&1 | Out-Null
  $geri  = [int](git -C $KOK rev-list --count HEAD..origin/main)
  $ileri = [int](git -C $KOK rev-list --count origin/main..HEAD)
  Yaz "  geride: $geri commit · ileride: $ileri commit"

  if($geri -gt 0){
    Yaz "  -> birleştiriliyor..." 'Yellow'
    $cikti = git -C $KOK merge origin/main --no-edit 2>&1
    $cak = git -C $KOK diff --name-only --diff-filter=U
    if($cak){
      Yaz "`n  ⛔ ÇAKIŞMA — $(@($cak).Count) dosya. ÖLÇMEDEN ÇÖZME." 'Red'
      Yaz "     Reçete: CLAUDE.md > ÇAKIŞMA ÇÖZME REÇETESİ" 'Red'
      $cak | ForEach-Object { Yaz "       $_" 'Red' }
      exit 2
    }
    Yaz "  -> temiz birleşti" 'Green'
  }

  $kirli = @(git -C $KOK status --short | Where-Object { $_ -match '^( M|M |MM|A |AM)' }).Count
  if($kirli -gt 0){ Yaz "  ⚠ $kirli dosya commit'siz duruyor (başka oturumdan kalmış olabilir)" 'Yellow' }

  Yaz "`n=== 2/3 · İŞ KOLU KİLİDİ ===" 'Cyan'
  $k = KilitOku
  if(-not $k){ $k = [pscustomobject]@{ oturumlar = @() } }
  $liste = @($k.oturumlar)

  $cakisan = $liste | Where-Object { $_.kol -eq $Kol -and $_.pid -ne $PID }
  if($cakisan){
    $s = SaatFark $cakisan[0].acilis
    if($s -le $BAYAT_SA -and -not $Zorla){
      Yaz "`n  ⛔ '$Kol' kolunda başka oturum çalışıyor ($s saattir, pid=$($cakisan[0].pid))." 'Red'
      Yaz "     BU KOLA DOKUNMA. Cem'e söyle, başka kol öner." 'Red'
      Yaz "     Boş kollar: $((($KOLLAR | Where-Object { $liste.kol -notcontains $_ }) -join ' · '))" 'Yellow'
      exit 3
    }
    Yaz "  ⚠ '$Kol' kolunda bayat kilit vardı ($s sa) — devralınıyor" 'Yellow'
    $liste = $liste | Where-Object { $_.kol -ne $Kol }
  }

  $liste = @($liste | Where-Object { $_.pid -ne $PID })
  $liste += [pscustomobject]@{ kol=$Kol; pid=$PID; acilis=(Get-Date -Format 'o'); dal=(git -C $KOK rev-parse --abbrev-ref HEAD) }
  KilitYaz ([pscustomobject]@{ oturumlar = $liste })
  Yaz "  -> '$Kol' kilitlendi (pid=$PID)" 'Green'

  Yaz "`n=== 3/3 · HAZIR ===" 'Cyan'
  Yaz "  Dal: $(git -C $KOK rev-parse --abbrev-ref HEAD) · ana telle eşit"
  Yaz "  İş bitince MUTLAKA: powershell -NoProfile -File motor/oturum.ps1 -Kapat`n" 'Yellow'
  exit 0
}

# --------------------------------------------------------------------------
if($Kapat){
  Yaz "`n=== KAPANIŞ ===" 'Cyan'
  $bekleyen = @(git -C $KOK status --short | Where-Object { $_ -match '^( M|M |MM|A |AM|\?\?)' })
  $izlenen  = @($bekleyen | Where-Object { $_ -notmatch '^\?\?' })

  if($izlenen.Count -gt 0){
    Yaz "`n  ⛔ $($izlenen.Count) dosya commit'lenmemiş — OTURUM BİTMEDİ:" 'Red'
    $izlenen | Select-Object -First 15 | ForEach-Object { Yaz "     $_" 'Red' }
    Yaz "`n  Ya commit'le ya da bilerek bıraktığını söyle." 'Red'
    exit 1
  }

  git -C $KOK fetch origin main -q 2>&1 | Out-Null
  $ileri = [int](git -C $KOK rev-list --count origin/main..HEAD)
  if($ileri -gt 0){
    Yaz "  $ileri commit itilecek..." 'Yellow'
    for($i=1; $i -le 5; $i++){
      git -C $KOK push origin HEAD:main 2>&1 | Out-Null
      if($LASTEXITCODE -eq 0){ Yaz "  -> itildi (deneme $i)" 'Green'; break }
      git -C $KOK fetch origin main -q 2>&1 | Out-Null
      git -C $KOK merge origin/main --no-edit -q 2>&1 | Out-Null
      if(git -C $KOK diff --name-only --diff-filter=U){ Yaz "  ⛔ itmede çakışma — elle çöz" 'Red'; exit 2 }
      Start-Sleep -Seconds 2
    }
  } else { Yaz "  itilecek commit yok" 'Green' }

  $k = KilitOku
  if($k){
    $kalan = @($k.oturumlar | Where-Object { $_.pid -ne $PID })
    KilitYaz ([pscustomobject]@{ oturumlar = $kalan })
    Yaz "  -> kilit bırakıldı"
  }
  Yaz "  ✅ OTURUM TEMİZ KAPANDI`n" 'Green'
  exit 0
}

Yaz "Kullanım:" 'Cyan'
Yaz "  powershell -NoProfile -File motor/oturum.ps1 -Ac -Kol alacak"
Yaz "  powershell -NoProfile -File motor/oturum.ps1 -Kapat"
Yaz "  powershell -NoProfile -File motor/oturum.ps1 -Durum"
Yaz "  Kollar: $($KOLLAR -join ' · ')"
