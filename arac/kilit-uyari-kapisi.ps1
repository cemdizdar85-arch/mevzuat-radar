# ============================================================================
#  KİLİT UYARI KAPISI — Claude Code PreToolUse hook (Edit|Write|NotebookEdit)   15.09.2026
#
#  NEDEN VAR (Cem 15.09 "1.2.3 üçünüde yap", GM önerisi 3): kilit düzeni (motor/oturum.ps1) ancak oturum
#  -Ac ile kilit alırsa işe yarar. Ölçüm (son 3 günün oturum dökümleri, bedel 0): 1.066 depo düzenlemesinin
#  228'i (%21) oturumun açık kilidi yokken yapıldı; 15.09'da 104'ün 10'u, tek oturum. En büyük pay 10–12.09
#  (kalip-parti-uret.ps1 ×17, tuzak-nobetcisi.ps1 ×44). Kilitsiz düzenleme = başka oturum aynı dosyayı
#  düzenlerken kimse durdurulmaz.
#
#  NE YAPAR: depo içindeki bir dosya düzenlenmeden önce veri/OTURUM-KILIDI.json'da BU oturumun
#  (session_id) kaydı var mı bakar. Yoksa düzenlemeyi DURDURMAZ; Claude'un bağlamına ve kullanıcıya uyarı
#  düşer (additionalContext + systemMessage). Aynı oturuma en fazla 10 dakikada bir uyarır.
#  NE YAPMAZ: depo dışı dosya (hafıza, scratchpad), session_id yok, kilit dosyası okunamıyor → sessiz geçer.
#  permissionDecision YAZMAZ (yazsaydı izin sorularını atlatırdı).
#  ÖZ-SINAV: powershell -NoProfile -File arac/kilit-uyari-kapisi.ps1 -Sinav
# ============================================================================
param([switch]$Sinav)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
$UYARI_ARALIGI_DK = 10

function YolNormal([string]$yol){ return ("$yol" -replace '/', '\').TrimEnd('\').ToLowerInvariant() }
function UyariGerekli([string]$dosyaYolu, [string]$oturumId, $kayitlar, [string]$kok){
  if(-not $dosyaYolu -or -not $oturumId){ return $false }
  $dosyaN = YolNormal $dosyaYolu; $kokN = YolNormal $kok
  if(-not $dosyaN.StartsWith($kokN + '\')){ return $false }
  if($null -eq $kayitlar){ return $false }   # kilit dosyası okunamadı: kör uyarı yerine sessiz
  foreach($k in @($kayitlar)){ if($k -and $k.PSObject.Properties['oturum'] -and "$($k.oturum)" -eq $oturumId){ return $false } }
  return $true
}

if($Sinav){
  $kok = 'C:\d\mevzuat-radar'
  $benim = [pscustomobject]@{ kol='sinav'; oturum='aaa-111'; pid=1 }
  $baskasi = [pscustomobject]@{ kol='site'; oturum='bbb-222'; pid=2 }
  $eskiBicim = [pscustomobject]@{ kol='altyapi'; pid=3 }
  $vakalar = @(
    @{ ad='kilidim var';                 y='C:\d\mevzuat-radar\motor\x.ps1'; o='aaa-111'; k=@($benim,$baskasi); b=$false },
    @{ ad='kilidim yok, baskasi var';    y='C:\d\mevzuat-radar\motor\x.ps1'; o='ccc-333'; k=@($benim,$baskasi); b=$true },
    @{ ad='kilit listesi bos';           y='C:\d\mevzuat-radar\veri\a.json'; o='aaa-111'; k=@();                b=$true },
    @{ ad='eski bicim kayit sayilmaz';   y='C:\d\mevzuat-radar\veri\a.json'; o='aaa-111'; k=@($eskiBicim);      b=$true },
    @{ ad='depo disi (hafiza)';          y='C:\Users\u\.claude\memory\m.md'; o='ccc-333'; k=@();                b=$false },
    @{ ad='benzer ad, depo disi';        y='C:\d\mevzuat-radar-yedek\x.ps1'; o='ccc-333'; k=@();                b=$false },
    @{ ad='egik bolu + buyuk harf';      y='c:/D/Mevzuat-Radar/arac/y.ps1';  o='ccc-333'; k=@($benim);          b=$true },
    @{ ad='session_id yok';              y='C:\d\mevzuat-radar\motor\x.ps1'; o='';        k=@();                b=$false },
    @{ ad='kilit dosyasi okunamadi';     y='C:\d\mevzuat-radar\motor\x.ps1'; o='ccc-333'; k=$null;              b=$false }
  )
  $kotu = 0
  foreach($v in $vakalar){ $s = UyariGerekli $v.y $v.o $v.k $kok; $ok = ($s -eq $v.b); if(-not $ok){ $kotu++ }; Write-Host ("  {0,-30} uyari={1,-5} beklenen={2,-5} {3}" -f $v.ad,$s,$v.b,$(if($ok){'OK'}else{'HATA'})) }
  if($kotu){ Write-Host "  $kotu vaka DUSTU - kapi bozuk" -ForegroundColor Red; exit 2 }
  Write-Host ("  {0}/{0} GECTI" -f $vakalar.Count) -ForegroundColor Green; exit 0
}

try { $ham = [Console]::In.ReadToEnd(); if(-not $ham){ exit 0 }; $veri = $ham | ConvertFrom-Json } catch { exit 0 }
$dosyaYolu = ''; $oturumId = ''
try { $dosyaYolu = "$($veri.tool_input.file_path)"; if(-not $dosyaYolu){ $dosyaYolu = "$($veri.tool_input.notebook_path)" }; $oturumId = "$($veri.session_id)" } catch { exit 0 }
$kayitlar = @()
$kilitYolu = Join-Path $depoKok 'veri\OTURUM-KILIDI.json'
if(Test-Path $kilitYolu){ try { $kilit = Get-Content $kilitYolu -Raw -Encoding UTF8 | ConvertFrom-Json; $kayitlar = @($kilit.oturumlar) } catch { $kayitlar = $null } }
if(-not (UyariGerekli $dosyaYolu $oturumId $kayitlar $depoKok)){ exit 0 }

# seyreltme: aynı oturuma 10 dakikada bir
$izDosyasi = Join-Path $env:TEMP ("tetikte-kilit-uyari-" + ($oturumId -replace '[^A-Za-z0-9-]', '') + '.txt')
try { if((Test-Path $izDosyasi) -and ((Get-Date) - (Get-Item $izDosyasi).LastWriteTime).TotalMinutes -lt $UYARI_ARALIGI_DK){ exit 0 }; Set-Content $izDosyasi (Get-Date -Format o) } catch { }

$kollar = @($kayitlar | Where-Object { $_ -and $_.PSObject.Properties['oturum'] } | ForEach-Object { "$($_.kol) ($($_.ad))" }) -join ', '
if(-not $kollar){ $kollar = 'yok' }
$dosyaAdi = Split-Path $dosyaYolu -Leaf
$metin = "KILIT UYARISI: bu oturumun kilidi yok ama depo dosyasi duzenleniyor ($dosyaAdi). Duzenleme DURDURULMADI. " +
  "Once kol al: powershell -NoProfile -File motor/oturum.ps1 -Ac -Kol <kol> -Is `"<kisa is>`" -Ad `"<ListAgents adin>`". " +
  "Kolu baska oturum tutuyorsa betik ENGEL der: o oturuma SendMessage ile yaz, izin alirsan yollu commit (git commit -F msg -- <dosya>). " +
  "Su an acik kollar: $kollar."
$cikti = @{ systemMessage = $metin; hookSpecificOutput = @{ hookEventName = 'PreToolUse'; additionalContext = $metin } }
[Console]::Out.Write(($cikti | ConvertTo-Json -Depth 4 -Compress))
exit 0
