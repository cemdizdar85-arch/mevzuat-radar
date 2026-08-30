# ============================================================================
#  GOREV KUR + GOREV NABZI (30.08.2026 — Cem: "1 yap")
#
#  NEDEN VAR (olculdu): gunluk robotlarin TAMAMI Cem'in dizustunde, Windows
#  zamanlanmis gorevlerinde kosuyordu ve bu gorevlerin tanimi DEPODA HIC YOKTU
#  - ne kurulum betigi, ne schtasks ciktisi. Tek gectikleri yer YUTMA-LISTESI'nde
#  duz cumleydi. Ustelik gorev eylemlerine MUTLAK yol gomuluydu
#  (OneDrive\Masaustu\...). Sonuc: makine degisirse, klasor adi degisirse ya da
#  OneDrive yolu kayarsa DORT KAPILIK gunluk zincir SESSIZCE olur ve depoda
#  bunu gosteren tek satir olmaz.
#  "Surekli kirmizi kapi kapi degildir" kuralinin kardesi: HIC KOSMAYAN KAPI DA
#  KAPI DEGILDIR.
#
#  BU BETIK IKI IS YAPAR:
#   1) BEYAN -> KURULUM. Asagidaki $GOREVLER tablosu gorevlerin TEK DOGRU
#      tanimidir. -uygula ile idempotent kurar/gunceller. Yollar betigin kendi
#      konumundan HESAPLANIR, gomulmez - klasor tasinirsa yeniden kosmak yeter.
#   2) NABIZ. Her kosuda gorevlerin gercek durumunu olcup veri/gorev-nabzi.json
#      yazar (YESIL/KIRMIZI/KOR - ucuncu sonuc kurali). -yayinla ile YALNIZ o
#      dosyayi commit+push eder; boylece CI nobetcisi (gorev-nobeti.yml)
#      dizustune hic bakmadan "robotlar susmus mu?" sorusunu cevaplayabilir.
#
#  KULLANIM:
#    powershell -File motor\gorev-kur.ps1            # yalniz olc + nabiz yaz
#    powershell -File motor\gorev-kur.ps1 -uygula    # gorevleri kur/guncelle
#    powershell -File motor\gorev-kur.ps1 -yayinla   # nabzi depoya bas
#
#  NOT (olculdu, degistirilmedi): uc gorevde de DisallowStartIfOnBatteries=True.
#  Yani dizustu 06:45'te PILDEYSE o gunun zinciri HIC kosmaz ve kimse duymaz.
#  Beyanda oldugu gibi birakildi (davranis degistirmek Cem'in karari); tek satir
#  cevirmekle acilir: pilKosma=$true.
# ============================================================================
param([switch]$uygula, [switch]$yayinla, [switch]$sessiz)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ps   = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

# --- BEYAN: gorevlerin tek dogru tanimi -------------------------------------
# betikler: sirayla kosacak motor\*.ps1 dosyalari. Her girdi ARGUMAN tasiyabilir
# ("betik.ps1 -anahtar"). Tek elemanli ve argumansizsa -File, degilse zincir
# -Command olarak kurulur ve ciktilar log dosyasina yazilir.
$GOREVLER = @(
  @{ ad='MevzuatRadar-YerelAyna';     saat='06:30'; sinir='PT3H'; pilKosma=$true;
     betikler=@('yerel-ayna.ps1') }
  @{ ad='MevzuatRadar-SurumTazeligi'; saat='06:45'; sinir='PT3H'; pilKosma=$true;
     log='veri\fabrika\surum-tazeligi-son-kosu.txt'
     # 30.08 AKSAM — DORT ADIM CI'YA TASINDI (.github/workflows/ambar-kapilari.yml)
     # Cem: "bilgisayarim acik olmasa da calissin, tatile gitsem olmayacak mi?"
     # Olculdu (veri/ip-olcum-raporu.md, runner IP 52.173.162.33):
     #   mevzuat.gov.tr -> HTTP 000, baglanti bile kurulamiyor (ENGELLI)
     #   diger hedefler -> hepsi iniyor
     # butunluk-kapisi · ambar-envanteri · veri-katalogu · saglik-karnesi
     # YALNIZ Supabase ile konusuyor - laptopa bagli kalmalari icin sebep yok.
     # Artik CI'da 08:00 UTC'de kosuyorlar; laptop kapaliyken de olcum yapilir.
     # BURADA BIRAKILMADILAR cunku iki yerde birden kosarlarsa ayni dosyalari
     # yazip commit'te carpisirlar.
     # 30.08 (ikinci tur): SURUM TAZELIGI DE CI'YA TASINDI. Olculdu -
     # kgk.gov.tr runner'dan INIYOR (TFRS 10 538 KB · BDS 200 1,25 MB, iki
     # farkli runner IP'siyle). Ustelik CI'da kalmasi ZORUNLU oldu: surum
     # karnesi gitignore'da oldugu icin CI envanteri o veriyi ancak AYNI
     # KOSUDA uretirse gorebiliyor (ilk denemede "Surum olculen 0" gerilemesi
     # tam bundan cikti).
     # Bu gorevde yerelde KALAN tek is: gorev-kur -yayinla. O da dogasi geregi
     # burada kosmali - YEREL gorevlerin nabzini olcer, CI oradan bakamaz.
     betikler=@('gorev-kur.ps1 -yayinla') }
  @{ ad='MevzuatRadar-YerelIndirici'; saat='09:30'; sinir='PT2H'; pilKosma=$true;
     betikler=@('yerel-indirici.ps1') }
)

function EylemKur($g){
  # 30.08: her betik girdisi "dosya.ps1 [arguman]" olabilir. Bolme YALNIZ ilk
  # bosluktan yapilir; kalan kisim aynen arguman olarak gecer.
  $parcalar = @()
  foreach($b in @($g.betikler)){
    if(-not $b){ continue }
    $d = ($b -split ' ',2)
    $dosya = Join-Path $here $d[0]
    if($d.Count -gt 1 -and $d[1]){ $parcalar += ("& '{0}' {1}" -f $dosya, $d[1]) }
    else { $parcalar += ("& '{0}'" -f $dosya) }
  }
  foreach($e in @($g.ek)){ if($e){ $parcalar += ("& '{0}' {1}" -f (Join-Path $here ($e -split ' ')[0]), (($e -split ' ',2)[1])) } }
  $tekArgumansiz = (@($g.betikler).Count -eq 1) -and (@($g.betikler)[0] -notmatch ' ') -and (-not @($g.ek))
  if($tekArgumansiz -and -not $g.log){
    return @{ arg = ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $here (@($g.betikler)[0]))) }
  }
  $logYol = if($g.log){ Join-Path $kok $g.log } else { Join-Path $kok ('veri\fabrika\{0}-son-kosu.txt' -f $g.ad) }
  $zincir = @()
  for($i=0; $i -lt $parcalar.Count; $i++){
    $yon = if($i -eq 0){ '*>' } else { '*>>' }
    $zincir += ("{0} {1} '{2}'" -f $parcalar[$i], $yon, $logYol)
  }
  return @{ arg = ('-NoProfile -ExecutionPolicy Bypass -Command "{0}"' -f (($zincir -join '; ') -replace '"','`"')) }
}

# --- WORKTREE FRENI ---------------------------------------------------------
# 30.08 denemesinde cikti: bu betik bir git WORKTREE'sinden kosarsa $kok gecici
# bir klasoru gosterir ve -uygula gorevlere O YOLU gomer - worktree silinince
# uc robot birden olur. Worktree'de .git bir DOSYADIR (dizin degil); kurulum
# yalniz gercek calisma kopyasindan yapilir.
$gitYol = Join-Path $kok '.git'
$worktreeMi = (Test-Path $gitYol -PathType Leaf)
if($uygula -and $worktreeMi){
  Write-Host "KURULUM REDDEDILDI: burasi bir git worktree'si ($kok)." -ForegroundColor Red
  Write-Host "  Gorevlere gecici yol gomulurdu. -uygula'yi GERCEK calisma kopyasindan kos." -ForegroundColor Red
  exit 2
}

# --- 1) KURULUM (yalniz -uygula) --------------------------------------------
$kurulumRapor = @()
foreach($g in $GOREVLER){
  $eylem = EylemKur $g
  $mevcut = $null
  try { $mevcut = Get-ScheduledTask -TaskName $g.ad -ErrorAction Stop } catch {}
  $mevcutArg = if($mevcut){ ($mevcut.Actions | Select-Object -First 1).Arguments } else { $null }
  # 30.08 KUSUR (olculdu, canli vaka): karsilastirma YALNIZ komut satirina
  # bakiyordu. Pil ayarini beyanda cevirdim, kurulum "degismedi" dedi ve
  # gorevler ESKI ayarla kaldi - cunku komut satiri ayniydi. Yani beyan ile
  # gercek arasindaki AYAR farkini kurulum GOREMIYORDU. Ayni kor nokta tetik
  # saati icin de gecerliydi: biri elle 06:45'i 09:00 yapsa yine "degismedi".
  $farklar = @()
  if($mevcut){
    if("$mevcutArg".Trim() -ne $eylem.arg.Trim()){ $farklar += 'komut' }
    $beklenenPilYasak = (-not $g.pilKosma)
    if([bool]$mevcut.Settings.DisallowStartIfOnBatteries -ne $beklenenPilYasak){ $farklar += 'pilde-baslama' }
    if([bool]$mevcut.Settings.StopIfGoingOnBatteries     -ne $beklenenPilYasak){ $farklar += 'pilde-durdur' }
    $mevcutSaat = ''
    try { $mevcutSaat = ([datetime]$mevcut.Triggers[0].StartBoundary).ToString('HH:mm') } catch {}
    if($mevcutSaat -and $mevcutSaat -ne $g.saat){ $farklar += 'tetik-saati' }
  }
  $ayni = $mevcut -and ($farklar.Count -eq 0)
  $satir = [ordered]@{ ad=$g.ad; kurulu=[bool]$mevcut; beyanla_ayni=[bool]$ayni; farklar=($farklar -join ','); yapilan='olculdu' }

  if($uygula -and -not $ayni){
    try {
      $a = New-ScheduledTaskAction -Execute $ps -Argument $eylem.arg
      $t = New-ScheduledTaskTrigger -Daily -At ([datetime]::ParseExact($g.saat,'HH:mm',$null))
      $p = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
      $s = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Parse(($g.sinir -replace '^PT','' -replace 'H',':00:00')))
      $s.DisallowStartIfOnBatteries = -not $g.pilKosma
      $s.StopIfGoingOnBatteries     = -not $g.pilKosma
      Register-ScheduledTask -TaskName $g.ad -Action $a -Trigger $t -Principal $p -Settings $s -Force | Out-Null
      $satir.yapilan = if($mevcut){ 'guncellendi' } else { 'kuruldu' }
    } catch { $satir.yapilan = "HATA: $($_.Exception.Message)" }
  } elseif($uygula) { $satir.yapilan = 'degismedi' }
  $kurulumRapor += [pscustomobject]$satir
}

# --- 2) NABIZ: gorevler gercekten kosuyor mu? -------------------------------
# Gunluk gorev icin esik 36 saat: bir gun atlamak (makine kapali) tolere edilir,
# IKI gun atlamak edilmez. Okuyamadigimiz gorev "yok" degil KOR'dur.
$ESIK_SAAT = 36
$simdi = Get-Date
$nabiz = @()
$hukum = 'YESIL'
foreach($g in $GOREVLER){
  $s = [ordered]@{ ad=$g.ad; beklenen_saat=$g.saat; durum='KOR'; sebep=''; son_kosu=$null; son_sonuc=$null; gecikme_saat=$null; gorev_durumu=$null; pilde_bekliyor=$false }
  try {
    $t = Get-ScheduledTask -TaskName $g.ad -ErrorAction Stop
    $i = $t | Get-ScheduledTaskInfo -ErrorAction Stop
    $s.son_kosu  = if($i.LastRunTime){ $i.LastRunTime.ToString('s') } else { $null }
    $s.son_sonuc = $i.LastTaskResult
    $s.gorev_durumu = "$($t.State)"
    # 30.08 YALANCI YESIL (olculdu, canli vaka): gorev 'Queued' halinde
    # SAATLERCE bekleyebilir ve HIC KOSMAZ - en yaygin sebep
    # DisallowStartIfOnBatteries=True + dizustunun pilde olmasi.
    # Tuzak: Windows bu durumda bile LastRunTime'i TETIKLEME anina gunceller
    # ve LastTaskResult onceki BASARILI kosudan 0 kalir. Yani nabiz
    # "az once kostu, sonuc 0" diye YESIL derdi - gorev hic baslamamisken.
    # Olculen vaka: 30.08 04:22 tetiklendi, 15 dk sonra hala Queued,
    # BatteryStatus=1 (pilde, %61), zincir hic kosmadi.
    $pilde = $false
    try { $bat = Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop; if($bat -and $bat.BatteryStatus -eq 1){ $pilde = $true } } catch {}
    $s.pilde_bekliyor = ($pilde -and $t.Settings.DisallowStartIfOnBatteries -and $t.State -eq 'Queued')
    if($t.State -eq 'Disabled'){ $s.durum='KIRMIZI'; $s.sebep='gorev DEVRE DISI' }
    elseif($s.pilde_bekliyor){ $s.durum='KIRMIZI'; $s.sebep='KUYRUKTA BEKLIYOR: makine PILDE ve gorev "pilde baslama" yasagi tasiyor - zincir KOSMUYOR' }
    elseif($t.State -eq 'Queued'){ $s.durum='KOR'; $s.sebep='gorev KUYRUKTA (henuz baslamadi) - son kosu bilgisi guvenilmez' }
    elseif(-not $i.LastRunTime){ $s.durum='KIRMIZI'; $s.sebep='hic kosmamis' }
    else {
      $gec = [math]::Round(($simdi - $i.LastRunTime).TotalHours,1)
      $s.gecikme_saat = $gec
      # 30.08 UCUNCU YALANCI SINYAL (olculdu): LastTaskResult'un HER SIFIR
      # OLMAYAN degeri hata DEGILDIR. Windows zamanlayicisi bilgi amacli
      # kodlar da dondurur ve bunlar 0'dan farklidir:
      #   267009 (0x41301) SCHED_S_TASK_RUNNING   -> gorev SU ANDA kosuyor
      #   267011 (0x41303) SCHED_S_TASK_HAS_NOT_RUN -> hic kosmamis
      #   267010 (0x41302) SCHED_S_TASK_DISABLED
      # Canli vaka: zincir kosarken nabiz "son kosu HATA ile bitti (kod 267009)"
      # dedi. Kosan gorevi arizali ilan etmek, arizayi kacirmak kadar zararli -
      # kurt masali nobetciyi degersizlestirir.
      $BILGI_KODU = @(267009,267011,267010)
      if($t.State -eq 'Running' -or $i.LastTaskResult -eq 267009){
        $s.durum='YESIL'; $s.sebep='SU ANDA KOSUYOR'
      }
      elseif($gec -gt $ESIK_SAAT){ $s.durum='KIRMIZI'; $s.sebep=("son kosu {0} saat once (esik {1})" -f $gec,$ESIK_SAAT) }
      elseif($i.LastTaskResult -ne 0 -and $BILGI_KODU -notcontains $i.LastTaskResult){
        $s.durum='KIRMIZI'; $s.sebep=("son kosu HATA ile bitti (kod {0})" -f $i.LastTaskResult)
      }
      elseif($BILGI_KODU -contains $i.LastTaskResult){ $s.durum='KOR'; $s.sebep=("bilgi kodu {0} - gercek sonuc bilinmiyor" -f $i.LastTaskResult) }
      else { $s.durum='YESIL' }
    }
  } catch {
    $s.durum='KOR'; $s.sebep=("gorev okunamadi: {0}" -f $_.Exception.Message)
  }
  if($s.durum -eq 'KIRMIZI'){ $hukum='KIRMIZI' }
  elseif($s.durum -eq 'KOR' -and $hukum -eq 'YESIL'){ $hukum='KOR' }
  $nabiz += [pscustomobject]$s
}

$nabizYol = Join-Path $kok 'veri\gorev-nabzi.json'
$cikti = [ordered]@{
  olcum   = $simdi.ToString('s')
  makine  = $env:COMPUTERNAME
  kullanici = $env:USERNAME
  kok     = $kok
  esik_saat = $ESIK_SAAT
  hukum   = $hukum
  gorevler = $nabiz
  kurulum  = $kurulumRapor
  not = 'Beyan motor/gorev-kur.ps1 icinde. Gorev dusseydi burasi KIRMIZI olur; CI nobetcisi (.github/workflows/gorev-nobeti.yml) bu dosyanin YASINA ve hukmune bakar.'
}
[IO.File]::WriteAllText($nabizYol, (ConvertTo-Json -InputObject $cikti -Depth 5), [Text.UTF8Encoding]::new($false))

# --- 3) YAYIN: yalniz nabiz dosyasi (dirty agac tuzagina karsi) -------------
# 30.08 DERSI: bu depoda `git add` + `git commit` GUVENLI DEGIL - indekste
# baskasinin staged dosyalari birikiyor ve commit onlari da suruklüyor.
# Bu yuzden YOL BELIRTILEREK commit edilir: `git commit -- <yol>` indeksin
# geri kalanini gormezden gelir.
if($yayinla){
  try {
    Push-Location $kok
    & git add -- 'veri/gorev-nabzi.json' 2>&1 | Out-Null
    $fark = & git diff --cached --name-only -- 'veri/gorev-nabzi.json'
    if($fark){
      & git commit -q -m ("gorev nabzi: {0} ({1})" -f $hukum, $simdi.ToString('dd.MM.yyyy HH:mm')) -- 'veri/gorev-nabzi.json' 2>&1 | Out-Null
      & git fetch -q origin 2>&1 | Out-Null
      & git push -q origin HEAD:main 2>&1 | Out-Null
      if(-not $sessiz){ Write-Host 'NABIZ YAYINLANDI (yalniz veri/gorev-nabzi.json).' }
    } elseif(-not $sessiz){ Write-Host 'NABIZ: degisiklik yok, commit yok.' }
  } catch {
    if(-not $sessiz){ Write-Host "NABIZ YAYIN UYARI (olcum etkilenmedi): $($_.Exception.Message)" }
  } finally { Pop-Location }
}

if(-not $sessiz){
  foreach($s in $nabiz){
    $renk = switch($s.durum){ 'YESIL' {'Green'} 'KIRMIZI' {'Red'} default {'Yellow'} }
    $ek = if($s.sebep){ " · $($s.sebep)" } elseif($s.gecikme_saat -ne $null){ " · son kosu $($s.gecikme_saat) saat once" } else { '' }
    Write-Host ("[{0}] {1} ({2}){3}" -f $s.durum, $s.ad, $s.beklenen_saat, $ek) -ForegroundColor $renk
  }
  foreach($k in $kurulumRapor){ if($k.yapilan -ne 'olculdu'){ Write-Host ("  kurulum: {0} -> {1}" -f $k.ad, $k.yapilan) -ForegroundColor Cyan } }
  if(-not $uygula){
    $farkli = @($kurulumRapor | Where-Object { -not $_.beyanla_ayni })
    if($farkli.Count){ Write-Host ("BEYANLA FARKLI: {0} gorev (-uygula ile duzelir): {1}" -f $farkli.Count, (($farkli.ad) -join ', ')) -ForegroundColor Yellow }
  }
  Write-Host ("HUKUM: {0}" -f $hukum) -ForegroundColor $(if($hukum -eq 'YESIL'){'Green'}elseif($hukum -eq 'KIRMIZI'){'Red'}else{'Yellow'})
  Write-Host ("  -> veri/gorev-nabzi.json")
}

if($hukum -eq 'KIRMIZI'){ exit 1 }
exit 0
