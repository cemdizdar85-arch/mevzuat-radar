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
  # 30.08: iki oturum AYNI çalışma ağacını paylaşıyor. `site` kolu 44 HTML
  # dosyasını düzenlerken `alacak` kolu kapanmak istedi ve kapı düştü —
  # oysa o dosyalar BAŞKA KOLUN canlı işiydi, commit'lemek yanlış olurdu.
  # Kapıyı gevşetmek yerine bilinçli çıkış yolu açıldı: gerekçe YAZILIR ve
  # bırakılan dosyalar kütüğe geçer. Gerekçesiz bırakma yok.
  [string]$Birak = "",
  [switch]$Zorla,     # bayat kilidi ez (yalnız Cem söylerse)
  # 15.09: kilide oturumun ne yaptığı ve mesaj adı yazılır → başka oturum notu DOĞRU oturuma gönderir
  # (15.09'da "bitirme oturumuna not" iki yanlış oturuma gitti: adlar yalnız numaraydı).
  [string]$Is = "",   # kısa iş açıklaması: "kgk-soru", "bitirme basımı" …
  [string]$Ad = "",   # ListAgents'te görünen oturum adı (ör. mevzuat-i-i-cc) — mesaj adresi
  [switch]$KilitSinavi   # kilit mantığının öz-sınavı (kilit dosyasına ve depoya dokunmaz)
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
#  KİLİT KİMLİĞİ — 15.09.2026 DERSİ (iki kusur, biri kilidi fiilen işlevsiz bırakıyordu)
#  (1) Kilide `$PID` yazılıyordu: bu, `oturum.ps1`'i çalıştıran ve SANİYELER içinde kapanan
#      powershell sürecidir. Bir sonraki `-Ac` onu ölü görüp "sahipsiz kilit temizlendi" diyordu
#      → kilit kimseyi durdurmuyordu (14.09 ve 15.09 günlüklerinde "sahipsiz … temizlendi" satırları).
#  (2) `-Kapat -Kol X` kilidi KOLDAN siliyordu: 15.09 20:29'da site oturumu kendi eski kilidini
#      bırakırken sınav oturumunun canlı kilidini sildi.
#  ÇÖZÜM: kimlik = Claude oturumu. CLAUDE_CODE_SESSION_ID (oturum) + CLAUDE_PID (canlı süreç).
#  Ortam yoksa (elle terminal, robot): powershell/cmd dışındaki ilk ata süreç. Kapat YALNIZ kendi
#  oturumunun kilidini bırakır; başkasınınkini ancak -Zorla ile.
# --------------------------------------------------------------------------
function OturumKimligi {
  $oturumId = "$env:CLAUDE_CODE_SESSION_ID"
  $sahipPid = 0
  if("$env:CLAUDE_PID" -match '^\d+$'){ $sahipPid = [int]$env:CLAUDE_PID }
  if(-not $sahipPid){
    $surecNo = $PID
    for($adim=0; $adim -lt 8 -and $surecNo; $adim++){
      $surec = Get-CimInstance Win32_Process -Filter "ProcessId=$surecNo" -ErrorAction SilentlyContinue
      if(-not $surec){ break }
      if($surec.Name -notmatch '^(powershell|pwsh|cmd|conhost|bash|sh|git|OpenConsole)\.exe$'){ $sahipPid = [int]$surec.ProcessId; break }   # bash.exe: Claude'un Bash aracı zinciri (bash ×3 → claude.exe), site oturumu ölçtü 15.09
      $surecNo = $surec.ParentProcessId
    }
    if(-not $sahipPid){ $sahipPid = $PID }
  }
  if(-not $oturumId){ $oturumId = "pid-$sahipPid" }
  return [pscustomobject]@{ oturum = $oturumId; pid = $sahipPid }
}
function SahipYasiyorMu($o){
  $surec = Get-Process -Id ([int]$o.pid) -ErrorAction SilentlyContinue
  if(-not $surec){ return $false }
  # PID geri dönüşümü: aynı numarayı sonradan başlayan başka süreç almışsa sahipsiz
  try { if($surec.StartTime -gt ([datetime]$o.acilis)){ return $false } } catch { }
  return $true
}
function EskiBicimMi($o){ return (-not $o.PSObject.Properties['oturum']) }
function KilitAl($liste, [string]$kolAdi, $kimlik, [string]$isAciklamasi, [string]$mesajAdi, [bool]$zorlaGec){
  # GEÇİŞ (15.09): eski biçim kayıtta (oturum alanı yok) sahip PID'i HER ZAMAN ölüdür (kapanmış powershell);
  # yaşına göre değerlendirilir: BAYAT_SA'dan gençse KORUNUR ama ENGEL SAYILMAZ (kimin olduğu bilinemez,
  # engel sayılsa kendi eski kilidini de ezmek gerekirdi), bayatsa temizlenir. Site oturumu uyardı: yoksa ilk
  # yeni -Ac açık oturumların kaydını siler.
  $eskiGenc = @($liste | Where-Object { (EskiBicimMi $_) -and (SaatFark $_.acilis) -le $BAYAT_SA -and $_.kol -ne $kolAdi })
  $temizler = @($liste | Where-Object { if(EskiBicimMi $_){ (SaatFark $_.acilis) -gt $BAYAT_SA -or $_.kol -eq $kolAdi } else { -not (SahipYasiyorMu $_) } })
  $canli = @(@($liste | Where-Object { -not (EskiBicimMi $_) -and (SahipYasiyorMu $_) }) + $eskiGenc)
  $engel = @($canli | Where-Object { -not (EskiBicimMi $_) -and $_.kol -eq $kolAdi -and "$($_.oturum)" -ne $kimlik.oturum })
  if($engel.Count -and -not $zorlaGec){ return [pscustomobject]@{ sonuc='ENGEL'; liste=$canli; engel=$engel[0]; temizlenen=$temizler } }
  $sonuc = if($engel.Count){ 'DEVRALINDI' } elseif(@($canli | Where-Object { $_.kol -eq $kolAdi -and "$($_.oturum)" -eq $kimlik.oturum }).Count){ 'YENILENDI' } else { 'ALINDI' }
  $yeniListe = @($canli | Where-Object { $_.kol -ne $kolAdi })
  $yeniListe += [pscustomobject]@{ kol=$kolAdi; oturum=$kimlik.oturum; pid=$kimlik.pid; is=$isAciklamasi; ad=$mesajAdi; acilis=(Get-Date -Format 'o') }
  return [pscustomobject]@{ sonuc=$sonuc; liste=$yeniListe; engel=$(if($engel.Count){ $engel[0] } else { $null }); temizlenen=$temizler }
}
function KilitBirak($liste, [string]$kolAdi, $kimlik, [bool]$zorlaGec){
  $benim = @($liste | Where-Object { "$($_.oturum)" -eq $kimlik.oturum -and ($kolAdi -eq '' -or $_.kol -eq $kolAdi) })
  $baskasi = @($liste | Where-Object { $kolAdi -ne '' -and $_.kol -eq $kolAdi -and "$($_.oturum)" -ne $kimlik.oturum })
  $birakilan = @($benim)
  if($zorlaGec){ $birakilan += $baskasi }
  $kalan = @($liste | Where-Object { $birakilan -notcontains $_ })
  return [pscustomobject]@{ birakilan=$birakilan; baskasi=$(if($zorlaGec){ @() } else { $baskasi }); liste=$kalan }
}
function KilitSinavi {
  # Kilit mantığının kendi sınavı: sahte kimliklerle, dosyaya yazmadan. Canlı süreç = bu sınav süreci; ölü süreç = olmayan PID.
  $dusen = New-Object System.Collections.Generic.List[string]
  $gecmis = (Get-Date).AddHours(-1).ToString('o')   # yalnız ÖLÜ/eski kayıtlar için (1 sa önce = BAYAT_SA'dan genç)
  $canliPid = $PID
  $canliAcilis = (Get-Date).ToString('o')           # canlı kayıt: sınav sürecinin başlangıcından SONRA (PID geri dönüşüm kuralı)
  $oluPid = 999999; while(Get-Process -Id $oluPid -ErrorAction SilentlyContinue){ $oluPid-- }
  $oturumA = [pscustomobject]@{ oturum='oturum-A'; pid=$canliPid }
  $oturumB = [pscustomobject]@{ oturum='oturum-B'; pid=$canliPid }
  $kilitA = [pscustomobject]@{ kol='sinav'; oturum='oturum-A'; pid=$canliPid; is='kgk'; ad='a'; acilis=$canliAcilis }
  # 1) B, A'nın canlı sınav kilidine giremez
  $s1 = KilitAl @($kilitA) 'sinav' $oturumB 'baska' 'b' $false
  if($s1.sonuc -ne 'ENGEL'){ $dusen.Add("1 başka oturumun canlı kilidi ENGEL vermedi: $($s1.sonuc)") }
  # 2) A aynı kolu yeniden açınca yenilenir, çift kayıt olmaz
  $s2 = KilitAl @($kilitA) 'sinav' $oturumA 'kgk' 'a' $false
  if($s2.sonuc -ne 'YENILENDI' -or @($s2.liste).Count -ne 1){ $dusen.Add("2 aynı oturum yenilemesi: $($s2.sonuc) · kayıt $(@($s2.liste).Count)") }
  # 3) B '-Kapat -Kol sinav' A'nın kilidini SİLMEZ (15.09 20:29 olayı)
  $s3 = KilitBirak @($kilitA) 'sinav' $oturumB $false
  if(@($s3.liste).Count -ne 1 -or @($s3.baskasi).Count -ne 1){ $dusen.Add("3 başka oturum kilidi sildi: kalan $(@($s3.liste).Count)") }
  # 4) A kendi kilidini bırakır
  $s4 = KilitBirak @($kilitA) 'sinav' $oturumA $false
  if(@($s4.liste).Count -ne 0){ $dusen.Add("4 kendi kilidini bırakamadı") }
  # 5) sahibi ölü kilit temizlenir ve kol alınır (eski biçim: oturum alanı yok)
  $olu = [pscustomobject]@{ kol='sinav'; pid=$oluPid; acilis=$gecmis }
  $s5 = KilitAl @($olu) 'sinav' $oturumB '' '' $false
  if($s5.sonuc -ne 'ALINDI' -or @($s5.temizlenen).Count -ne 1){ $dusen.Add("5 ölü kilit temizlenmedi: $($s5.sonuc)") }
  # 6) -Kol verilmeden Kapat: yalnız kendi oturumunun BÜTÜN kollarını bırakır
  $kilitA2 = [pscustomobject]@{ kol='altyapi'; oturum='oturum-A'; pid=$canliPid; is=''; ad=''; acilis=$canliAcilis }
  $kilitB = [pscustomobject]@{ kol='site'; oturum='oturum-B'; pid=$canliPid; is=''; ad=''; acilis=$canliAcilis }
  $s6 = KilitBirak @($kilitA,$kilitA2,$kilitB) '' $oturumA $false
  if(@($s6.birakilan).Count -ne 2 -or @($s6.liste).Count -ne 1 -or $s6.liste[0].kol -ne 'site'){ $dusen.Add("6 kolsuz kapanış yanlış: bırakılan $(@($s6.birakilan).Count) · kalan $(@($s6.liste).Count)") }
  # 7) -Zorla ile başkasının kilidi devralınır
  $s7 = KilitAl @($kilitA) 'sinav' $oturumB 'baska' 'b' $true
  if($s7.sonuc -ne 'DEVRALINDI' -or "$($s7.liste[0].oturum)" -ne 'oturum-B'){ $dusen.Add("7 zorla devralma: $($s7.sonuc)") }
  # 8) GEÇİŞ: başka koldaki GENÇ eski biçim kayıt korunur, engel olmaz; aynı koldaki ve BAYAT eski kayıt temizlenir
  $eskiGencBaska = [pscustomobject]@{ kol='site'; pid=$oluPid; acilis=$gecmis }
  $eskiAyniKol = [pscustomobject]@{ kol='sinav'; pid=$oluPid; acilis=$gecmis }
  $eskiBayat = [pscustomobject]@{ kol='marka'; pid=$oluPid; acilis=(Get-Date).AddHours(-9).ToString('o') }
  $s8 = KilitAl @($eskiGencBaska,$eskiAyniKol,$eskiBayat) 'sinav' $oturumB 'kgk' 'b' $false
  if($s8.sonuc -ne 'ALINDI' -or @($s8.liste | Where-Object { $_.kol -eq 'site' }).Count -ne 1 -or @($s8.temizlenen).Count -ne 2){ $dusen.Add("8 geçiş: sonuç $($s8.sonuc) · site korundu $(@($s8.liste | Where-Object { $_.kol -eq 'site' }).Count) · temizlenen $(@($s8.temizlenen).Count)") }
  return $dusen.ToArray()
}

if($KilitSinavi){
  $sinavSonucu = @(KilitSinavi)
  if($sinavSonucu.Count){ $sinavSonucu | ForEach-Object { Yaz "  ⛔ $_" 'Red' }; exit 1 }
  Yaz "KİLİT ÖZ-SINAVI YEŞİL (8 vaka)" 'Green'; exit 0
}

function EskiBicimUyarisi($kayitlar){
  # 15.09 (Cem "kilit düzenini diğer oturumlara da oturtalım"): eski biçim kayıt kimliksizdir — hiçbir oturumu durdurmaz,
  # mesaj adı yoktur. Sahibi yeni biçimle yeniden açsın; açmazsa BAYAT_SA sonra kendiliğinden temizlenir.
  $eskiler = @($kayitlar | Where-Object { EskiBicimMi $_ })
  if(-not $eskiler.Count){ return }
  Write-Host ("  ⚠ {0} eski biçim kilit kaydı (kimliksiz, kimseyi durdurmaz): {1}" -f $eskiler.Count, (($eskiler | ForEach-Object { $_.kol }) -join ', ')) -ForegroundColor Yellow
  Write-Host "     O kolda çalışan oturum kaydını yenilesin: motor/oturum.ps1 -Ac -Kol <kol> -Is `"<kısa iş>`" -Ad `"<ListAgents adı>`" ($BAYAT_SA sa sonra kendiliğinden silinir)" -ForegroundColor Yellow
}
function KilitSatiri($o){
  $sure = SaatFark $o.acilis
  $ek = @(); if("$($o.is)"){ $ek += "iş: $($o.is)" }; if("$($o.ad)"){ $ek += "mesaj adı: $($o.ad)" }
  $durum = if(EskiBicimMi $o){ 'eski biçim (kimlik yok)' } elseif(SahipYasiyorMu $o){ 'canlı' } else { 'SAHİPSİZ' }
  return ("{0,-10} {1,5} sa · {2} · oturum {3}{4}" -f $o.kol, $sure, $durum, ("$($o.oturum)".Substring(0,[Math]::Min(8,"$($o.oturum)".Length))), $(if($ek.Count){ ' · ' + ($ek -join ' · ') } else { '' }))
}

# --------------------------------------------------------------------------
#  NABIZ — oturum açılışında hook'tan otomatik koşar. Karar vermez, FOTOĞRAF
#  çeker: tel nerede, kim nerede çalışıyor, commit'siz iş var mı.
#  30.08 dersi: oturum bu bilgiyi görmeden çalışmaya başlarsa çakışma üretiyor.
# --------------------------------------------------------------------------
if($Nabiz){
  try {
    git -C $KOK fetch origin main -q | Out-Null
    $geri  = [int](git -C $KOK rev-list --count HEAD..origin/main)
    $ileri = [int](git -C $KOK rev-list --count origin/main..HEAD)
    $kirli = @(git -C $KOK status --short | Where-Object { $_ -match '^( M|M |MM|A |AM)' }).Count
    $dal   = git -C $KOK rev-parse --abbrev-ref HEAD

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
      foreach($o in $acikKollar){ Write-Host ("    " + (KilitSatiri $o)) -ForegroundColor Yellow }
      Write-Host "  -> bu kollara DOKUNMA" -ForegroundColor Yellow
      EskiBicimUyarisi $acikKollar
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
  foreach($o in $k.oturumlar){ Yaz ("  " + (KilitSatiri $o)) }
  EskiBicimUyarisi @($k.oturumlar)
  $benimKimligim = OturumKimligi
  Yaz ("  (bu oturum: {0})" -f $benimKimligim.oturum) 'DarkGray'
  exit 0
}

# --------------------------------------------------------------------------
if($Ac){
  if($Kol -eq "" -or $KOLLAR -notcontains $Kol){
    Yaz "HATA: -Kol ver. Geçerli: $($KOLLAR -join ' · ')" 'Red'; exit 1
  }

  # --- 0/3 · MERGE DRIVER'I KUR ------------------------------------------
  # .gitattributes'teki "merge=tetikte-robot" kuralı, driver git config'de
  # TANIMLI DEĞİLSE sessizce hiçbir şey yapmaz - kural çalışıyor sanılır ve
  # robot çıktıları yine çakışır (30.08'de "merge=ours" ile tam bu yaşandı;
  # "ours" git'in built-in driver'ı DEĞİL, yalnız text/binary/union var).
  # Tanım yerel config'de durur, depoda taşınamaz - o yüzden her açılışta kurulur.
  if(-not (git -C $KOK config --get merge.tetikte-robot.driver)){
    git -C $KOK config merge.tetikte-robot.name "Tetikte robot ciktisi: cakismada yereldeki korunur"
    git -C $KOK config merge.tetikte-robot.driver "true"
    Yaz "  robot-cikti merge driver'i kuruldu" 'DarkGray'
  }

  # --- 0.5/3 · DEPO DURUMU TEMİZ Mİ? (06.09.2026) -----------------------------
  # Eski bir oturumdan yarım kalmış REBASE varken (".git/rebase-merge", HEAD dalsız) betik yine merge etti: birleşme
  # detached HEAD'e gitti, push'lar ana tele ulaştı ama yerel `main` 29 commit geride kaldı, robot dosyası iki kez çakıştı.
  # Kural: yarım kalmış rebase / merge / cherry-pick ya da dalsız HEAD varsa HİZALAMA YAPILMAZ, önce toparlanır.
  $gitDir = (git -C $KOK rev-parse --git-dir); if($gitDir -and -not [IO.Path]::IsPathRooted($gitDir)){ $gitDir = Join-Path $KOK $gitDir }
  $yarim = @()
  foreach($iz in 'rebase-merge','rebase-apply'){ if(Test-Path (Join-Path $gitDir $iz)){ $yarim += "yarım REBASE ($iz)" } }
  foreach($iz in 'MERGE_HEAD','CHERRY_PICK_HEAD','REVERT_HEAD','BISECT_LOG'){ if(Test-Path (Join-Path $gitDir $iz)){ $yarim += "yarım $($iz -replace '_HEAD|_LOG','')" } }
  $dal = (git -C $KOK symbolic-ref -q --short HEAD)
  if(-not $dal){ $yarim += "HEAD dalsız (detached) - $(git -C $KOK rev-parse --short HEAD)" }
  elseif($dal -ne 'main'){ Yaz "  ⚠ dal '$dal' (main değil) - kural: dalda uzun çalışılmaz" 'Yellow' }
  if($yarim.Count){
    Yaz "`n  ⛔ DEPO YARIM İŞ HÂLİNDE - hizalama yapılmadı:" 'Red'
    $yarim | ForEach-Object { Yaz "     • $_" 'Red' }
    Yaz "     Toparlama: git status → (rebase ise) git rebase --quit → git checkout main → gerekirse git branch -f main HEAD" 'Red'
    Yaz "     Kaybolacak commit varsa önce: git branch yedek-<tarih> <sha>" 'Red'
    exit 3
  }

  Yaz "`n=== 1/3 · ANA TELLE HİZALAMA ===" 'Cyan'
  git -C $KOK fetch origin main -q | Out-Null
  $geri  = [int](git -C $KOK rev-list --count HEAD..origin/main)
  $ileri = [int](git -C $KOK rev-list --count origin/main..HEAD)
  Yaz "  geride: $geri commit · ileride: $ileri commit"

  if($geri -gt 0){
    Yaz "  -> birleştiriliyor..." 'Yellow'
    $cikti = git -C $KOK merge origin/main --no-edit
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

  # 30.08: sahibi ölü kilit temizlenir (çöken oturum kolu saatlerce kapatmasın).
  # 15.09: sahip = Claude oturumu (OturumKimligi). Canlı oturumun kilidi yaşına bakılmadan yalnız -Zorla ile ezilir.
  $kimlik = OturumKimligi
  $alim = KilitAl $liste $Kol $kimlik $Is $Ad ([bool]$Zorla)
  foreach($o in @($alim.temizlenen)){ Yaz ("  ⚠ sahipsiz/eski kilit temizlendi: {0} (süreç {1})" -f $o.kol, $o.pid) 'Yellow' }
  if($alim.sonuc -eq 'ENGEL'){
    Yaz "`n  ⛔ '$Kol' kolunda başka bir CANLI oturum çalışıyor:" 'Red'
    Yaz ("     " + (KilitSatiri $alim.engel)) 'Red'
    Yaz "     BU KOLA DOKUNMA. Cem'e söyle, başka kol öner$(if("$($alim.engel.ad)"){ " ya da o oturuma mesaj at: $($alim.engel.ad)" })." 'Red'
    Yaz "     Boş kollar: $((($KOLLAR | Where-Object { @($alim.liste).kol -notcontains $_ }) -join ' · '))" 'Yellow'
    exit 3
  }
  if($alim.sonuc -eq 'DEVRALINDI'){ Yaz ("  ⚠ -Zorla: '{0}' kilidi başka oturumdan devralındı ({1})" -f $Kol, $alim.engel.oturum) 'Yellow' }
  KilitYaz ([pscustomobject]@{ oturumlar = @($alim.liste) })
  Yaz ("  -> '{0}' {1} (oturum {2}, süreç {3})" -f $Kol, $(if($alim.sonuc -eq 'YENILENDI'){ 'kilidi yenilendi' } else { 'kilitlendi' }), $kimlik.oturum, $kimlik.pid) 'Green'
  if(-not $Is -or -not $Ad){ Yaz "  ⓘ Başka oturumlar seni bulabilsin: -Is `"kısa iş`" -Ad <ListAgents'teki adın> ver ve oturum başlığını '$Kol · <iş>' yap." 'DarkGray' }

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

  if($izlenen.Count -gt 0 -and $Birak -eq ""){
    Yaz "`n  ⛔ $($izlenen.Count) dosya commit'lenmemiş — OTURUM BİTMEDİ:" 'Red'
    $izlenen | Select-Object -First 15 | ForEach-Object { Yaz "     $_" 'Red' }
    Yaz "`n  Ya commit'le ya da bilerek bıraktığını söyle:" 'Red'
    Yaz "     ... -Kapat -Kol $Kol -Birak `"neden bırakıldığı`"" 'Yellow'
    exit 1
  }
  if($izlenen.Count -gt 0){
    # Bilinçli bırakma: sessizce geçilmez, KÜTÜĞE YAZILIR. Böylece "kim
    # bıraktı, neden" sorusu üç gün sonra da cevaplanabilir.
    Yaz "`n  ⚠ $($izlenen.Count) dosya BİLEREK bırakıldı: $Birak" 'Yellow'
    $izlenen | Select-Object -First 10 | ForEach-Object { Yaz "     $_" 'DarkGray' }
    $kutuk = Join-Path $KOK 'veri\oturum-birakilanlar.txt'
    $satir = "{0} · kol={1} · gerekce={2} · dosya={3}`r`n{4}`r`n" -f `
      (Get-Date -Format 'dd.MM.yyyy HH:mm'), $Kol, $Birak, $izlenen.Count, (($izlenen | ForEach-Object { "    $_" }) -join "`r`n")
    Add-Content -Path $kutuk -Value $satir -Encoding UTF8
    Yaz "  -> kütüğe yazıldı: veri/oturum-birakilanlar.txt" 'DarkGray'
  }

  # --- TUZAK NÖBETÇİSİ (11.09.2026) --------------------------------------
  # Cem'in kuralı: "kural yazmak işin yarısı, MEKANİK KAPI diğer yarısı."
  # 11.09'da en çok zamanı aynı hataları tekrarlamak yedi (değişken çakışması
  # ALTI kez, @(...|ConvertFrom-Json) üç kez). Hepsi arac/olcum-kapilari.ps1'de
  # YAZILIYDI; yorum kimseyi durdurmadı. Bu kapı durdurur.
  #
  # ⚠ Yalnız BU OTURUMDA DEĞİŞEN .ps1 dosyalarına bakar. Depoda 210 eski bulgu
  #   var; hepsini kapatmak kapıyı ilk gün kapatırdı. Yeni kusur girmez, eski
  #   birikim ayrı iş emri. Tam liste: arac/tuzak-nobetcisi.ps1 (parametresiz).
  # ⚠ Yalnız 🔴 ZARARLI bulgu durdurur; ⚠ RİSKLİ olanlar uyarı kalır.
  $nob = Join-Path $KOK 'arac\tuzak-nobetcisi.ps1'
  if(Test-Path $nob){
    $nobCikti = & powershell -NoProfile -File $nob -Degisen 2>&1
    if($LASTEXITCODE -ne 0){
      if($Birak -eq ""){
        Yaz "`n  ⛔ TUZAK NÖBETÇİSİ DURDURDU — değişen betikte bilinen tuzak var:" 'Red'
        $nobCikti | ForEach-Object { Yaz "     $_" 'Red' }
        Yaz "`n  Ya düzelt ya da bilerek bıraktığını söyle:" 'Red'
        Yaz "     ... -Kapat -Kol $Kol -Birak `"neden bırakıldığı`"" 'Yellow'
        exit 3
      }
      Yaz "`n  ⚠ Tuzak nöbetçisi bulgu verdi, BİLEREK geçildi: $Birak" 'Yellow'
      $nobCikti | ForEach-Object { Yaz "     $_" 'DarkGray' }
    } else { Yaz "  ✓ tuzak nöbetçisi temiz (değişen betikler)" 'Green' }
  }

  # 16.09 (Cem "1.2.3 üçünü de yap", GM 3): KAYNAK ÖLÇÜM ARACININ ÖZ-SINAVI.
  # Neden: 16.09'da arac/smmm-kaynak-olcum.ps1 iki kez SESSİZCE boş sonuç verdi (paralel çağrıda boşluklu yol
  # tırnaklanmamıştı) ve bir kez 2.095 konuluk ölçüm dosyasının üstüne 0 konu yazdı. Tuzak nöbetçisi bunu görmez:
  # kod sözdizimi temizdi, bozulan DAVRANIŞTI. Öz-sınav iki bilinen konuyu ambardan ölçer (bedel 0, ~10 sn) ve
  # paketin dolu gelmesini şart koşar. YALNIZ o araç ya da üreticisi bu oturumda değiştiyse koşar; DURDURMAZ, uyarır.
  $degisenPs = @(git -C $KOK status --porcelain | ForEach-Object { ($_ -replace '^..\s+','').Trim() })
  $ilgili = @($degisenPs | Where-Object { $_ -match 'arac/smmm-kaynak-olcum\.ps1|motor/kalip-parti-uret\.ps1' })
  $olcAr = Join-Path $KOK 'arac\smmm-kaynak-olcum.ps1'
  if($ilgili.Count -and (Test-Path $olcAr)){
    Yaz "  kaynak ölçüm aracı öz-sınavı (bedel 0)..." 'DarkGray'
    $ozCikti = & powershell -NoProfile -File $olcAr -OzSinav 2>&1
    if($LASTEXITCODE -ne 0){
      Yaz "  ⚠ KAYNAK ÖLÇÜM ARACI ÖZ-SINAVI DÜŞTÜ — ölçüm koşturma, önce onar:" 'Red'
      $ozCikti | Select-Object -Last 4 | ForEach-Object { Yaz "     $_" 'Red' }
    } else { Yaz "  ✓ kaynak ölçüm aracı öz-sınavı tamam" 'Green' }
  }

  git -C $KOK fetch origin main -q | Out-Null
  $ileri = [int](git -C $KOK rev-list --count origin/main..HEAD)
  if($ileri -gt 0){
    Yaz "  $ileri commit itilecek..." 'Yellow'
    for($i=1; $i -le 5; $i++){
      git -C $KOK push origin HEAD:main | Out-Null
      if($LASTEXITCODE -eq 0){ Yaz "  -> itildi (deneme $i)" 'Green'; break }
      git -C $KOK fetch origin main -q | Out-Null
      git -C $KOK merge origin/main --no-edit -q | Out-Null
      if(git -C $KOK diff --name-only --diff-filter=U){ Yaz "  ⛔ itmede çakışma — elle çöz" 'Red'; exit 2 }
      Start-Sleep -Seconds 2
    }
  } else { Yaz "  itilecek commit yok" 'Green' }

  # --- KİLİDİ BIRAK ------------------------------------------------------
  # 30.08 KUSUR: burada filtre `$_.pid -ne $PID` idi ve HİÇBİR ZAMAN
  # çalışmıyordu. Sebep: `-Ac` ayrı bir powershell süreci (PID X), `-Kapat`
  # bambaşka bir süreç (PID Y). Filtre "Y'ye eşit olmayanları tut" dediği
  # için X'i her seferinde KORUYORDU. Sonuç: "kilit bırakıldı" yazıyordu
  # ama kilit duruyordu; bir sonraki oturum aynı kola giremiyordu.
  # (Kendi kurduğum kapı beni durdurdu - kapı çalıştı, mantık yanlıştı.)
  #
  # 30.08: ölçüt PID değil KOL oldu. 15.09 KUSUR: KOL tek başına da yanlış — site oturumu "-Kapat -Kol sinav"
  # ile sınav oturumunun CANLI kilidini sildi. Doğru ölçüt: KOL + OTURUM. Kapanan oturum yalnız KENDİ açtığı
  # kilidi bırakır; -Kol verilmezse kendi oturumunun bütün kollarını bırakır; başkasınınkini ancak -Zorla ile.
  # Eski biçim kayıt (oturum alanı yok) kimseye ait sayılmaz; -Kol ile adıyla verilirse bırakılır (geçiş kolaylığı).
  $k = KilitOku
  if($k){
    $kimlik = OturumKimligi
    $tumListe = @($k.oturumlar)
    $eskiAdli = @($tumListe | Where-Object { (EskiBicimMi $_) -and $Kol -ne '' -and $_.kol -eq $Kol })
    $yeniBicim = @($tumListe | Where-Object { -not (EskiBicimMi $_) })
    $birakma = KilitBirak $yeniBicim $Kol $kimlik ([bool]$Zorla)
    $kalanListe = @(@($birakma.liste) + @($tumListe | Where-Object { (EskiBicimMi $_) -and $eskiAdli -notcontains $_ }))
    $birakilanlar = @(@($birakma.birakilan) + $eskiAdli)
    if($birakilanlar.Count){
      KilitYaz ([pscustomobject]@{ oturumlar = $kalanListe })
      foreach($o in $birakilanlar){ Yaz ("  -> '{0}' kilidi bırakıldı{1}" -f $o.kol, $(if(EskiBicimMi $o){ ' (eski biçim kayıt)' } elseif("$($o.oturum)" -ne $kimlik.oturum){ ' (-Zorla: başka oturumun)' } else { '' })) }
    } else { Yaz "  -> bu oturumun açık kilidi yok$(if($Kol){ " ('$Kol')" })" 'DarkGray' }
    foreach($o in @($birakma.baskasi)){
      Yaz ("  ⚠ '{0}' kilidi BAŞKA bir oturumun — dokunulmadı: {1}" -f $o.kol, (KilitSatiri $o)) 'Yellow'
      Yaz "     Gerçekten terk edilmişse Cem onayıyla: ... -Kapat -Kol $($o.kol) -Zorla" 'Yellow'
    }
  }
  Yaz "  ✅ OTURUM TEMİZ KAPANDI`n" 'Green'
  exit 0
}

Yaz "Kullanım:" 'Cyan'
Yaz "  powershell -NoProfile -File motor/oturum.ps1 -Ac -Kol alacak"
Yaz "  powershell -NoProfile -File motor/oturum.ps1 -Kapat"
Yaz "  powershell -NoProfile -File motor/oturum.ps1 -Durum"
Yaz "  Kollar: $($KOLLAR -join ' · ')"
