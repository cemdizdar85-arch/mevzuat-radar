# ============================================================================
#  SABAH RAPORU (19.08.2026, Cem karari: "sabah 7 cok gec - 4 kossun 5 kossun
#  6 kossun") - gecenin tek satirlik ozeti e-postayla.
#
#  NEDEN: robotlar kirmizi kaldiginda Cem ancak siteye bakinca goruyordu
#  (18.08: kartlar.yml 5 kosu kirmizi, site bir gun geride, kimse bilmiyordu).
#  Bu rapor "basinda olma" yukunu gunde 10 saniyelik tek bakisa indirir.
#
#  KOSU SAATLERI (kartlar.yml 03:07 TR'de yayin yapar):
#    04:06 TR - HER DURUMDA mail (yesil de olsa; "rapor gelmedi" de bir sinyal)
#    05:06 TR - yalniz KIRMIZI varsa YA DA dun kirmizi olup simdi yesilse
#    06:06 TR - ayni kural
#  Boylece yesil sabah = tek mail; kirmizi sabah = ilerleme gorunur.
#  Durum dosyasi: veri/sabah-rapor.json (ayni gunun onceki kosusunu hatirlar).
#
#  PARA HARCAMAZ. E-posta: web3forms (deneme.html'deki ayni acik anahtar -
#  anahtar tasarim geregi aciktir, alici sabittir).
#  ENV: GITHUB_TOKEN (Actions otomatik verir; actions:read yeter)
# ============================================================================
param([switch]$Kuru)   # -Kuru: mail atmaz, satiri yazar
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$REPO = 'cemdizdar85-arch/mevzuat-radar'
$WEB3 = '5b227e56-94fb-4123-a39a-4286f63db14a'
$durumYol = Join-Path $kok 'veri/sabah-rapor.json'

# --- gercek TR saati (runner UTC'dir; vitrin kapisindaki ikili deneme kalibi)
$tzTR = $null
foreach($tzAd in @('Europe/Istanbul','Turkey Standard Time')){ try { $tzTR = [TimeZoneInfo]::FindSystemTimeZoneById($tzAd); break } catch {} }
$trSimdi = if($tzTR){ [TimeZoneInfo]::ConvertTimeFromUtc([datetime]::UtcNow,$tzTR) } else { Get-Date }
$bugun = $trSimdi.ToString('dd.MM.yyyy')

# --- 1) site rozeti
$rozet = ''
try { $rozet = (Invoke-RestMethod -Uri ("https://tetikte.com/veri/kart-durum.json?cb=" + [DateTime]::UtcNow.Ticks) -TimeoutSec 30).sonTarama } catch { $rozet = 'OKUNAMADI' }
$siteGuncel = ($rozet -eq $bugun)

# --- 2) son 26 saatin kosulari (kirmizi hangi robotlar?)
$B = @{ 'User-Agent'='tetikte-sabah-raporu'; 'Accept'='application/vnd.github+json' }
if($env:GITHUB_TOKEN){ $B['Authorization'] = "Bearer $($env:GITHUB_TOKEN)" }
$esikUtc = [DateTime]::UtcNow.AddHours(-26).ToString('yyyy-MM-ddTHH:mm:ssZ')
# Liste yeniden->eskiye gelir: her robotun ILK gorulen tamamlanmis kosusu =
# SON kosusudur. Gece kirmizi olup sonra yesil bitmis robot alarm DEGILDIR
# (kendini kurtarmis) - alarm, son kosusu hala kirmizi olandir.
$sonSonuc = @{}          # robot adi -> son kosunun sonucu (ilk gorulen)
$toplamKosu = 0
foreach($sayfa in 1..3){
  $r = Invoke-RestMethod -Uri ("https://api.github.com/repos/$REPO/actions/runs?created=>%3D$esikUtc&per_page=100&page=$sayfa") -Headers $B -TimeoutSec 60
  $liste = @($r.workflow_runs)
  if($liste.Count -eq 0){ break }
  foreach($k in $liste){
    if($k.status -ne 'completed'){ continue }
    $toplamKosu++
    $ad = "$($k.name)"
    if(-not $sonSonuc.ContainsKey($ad)){ $sonSonuc[$ad] = "$($k.conclusion)" }
  }
  if($liste.Count -lt 100){ break }
}
$halaKirmizi = @($sonSonuc.Keys | Where-Object { $sonSonuc[$_] -eq 'failure' } | Sort-Object)

# --- 3) tek satir
$durum = if($siteGuncel -and $halaKirmizi.Count -eq 0){ 'YESIL' } else { 'KIRMIZI' }
$satir = if($durum -eq 'YESIL'){
  "TETIKTE SABAH YESIL — site $rozet guncel, gece $toplamKosu kosu, acik kirmizi yok"
} else {
  $p = @()
  if(-not $siteGuncel){ $p += "site GERIDE (rozet $rozet, beklenen $bugun)" }
  if($halaKirmizi.Count -gt 0){ $p += ("kirmizi: " + (($halaKirmizi | Select-Object -First 4) -join ', ') + $(if($halaKirmizi.Count -gt 4){" +$($halaKirmizi.Count-4)"}else{''})) }
  "TETIKTE SABAH KIRMIZI — " + ($p -join ' | ')
}
Write-Host $satir

# --- 4) gonderim karari (04 her zaman; 05/06 yalniz kirmizi ya da duzeldi)
$onceki = $null
if(Test-Path $durumYol){ try { $onceki = Get-Content $durumYol -Raw -Encoding UTF8 | ConvertFrom-Json } catch {} }
$ilkKosuMu = (-not $onceki) -or ("$($onceki.tarih)" -ne $bugun)
$dunKirmiziIdi = $onceki -and ("$($onceki.tarih)" -eq $bugun) -and ("$($onceki.durum)" -eq 'KIRMIZI')
$gonder = $ilkKosuMu -or ($durum -eq 'KIRMIZI') -or ($dunKirmiziIdi -and $durum -eq 'YESIL')
if($dunKirmiziIdi -and $durum -eq 'YESIL'){ $satir = $satir + ' (DUZELDI)' }

if($Kuru){ Write-Host "KURU KOSU - mail atilmadi. gonder=$gonder"; exit 0 }
if(-not $gonder){ Write-Host 'Ayni sabah ikinci yesil - mail atilmadi (kural: 04 her zaman, sonrasi yalniz kirmizi/duzeldi).'; exit 0 }

# 19.08 ILK KOSU DERSI: web3forms CI'dan CALISMAZ - GitHub'in veri merkezi
# IP'si Cloudflare bot korumasina takiliyor ("Just a moment..."). Tarayicidan
# calisiyor olmasi yaniltti. Kanal nabiz-nobetcisi ile ayni: Resend birincil,
# web3forms yalniz yedek (yerel kosuda ise yarar, CI'da buyuk ihtimal duser).
$mesaj = ("Saat (TR): {0}`nSite rozeti: {1}`nGece tamamlanan kosu: {2}`nAcik kirmizi: {3}`n`nAyrinti: https://github.com/$REPO/actions" -f $trSimdi.ToString('HH:mm'), $rozet, $toplamKosu, $(if($halaKirmizi.Count){$halaKirmizi -join ', '}else{'yok'}))
$gitti = $false
if($env:RESEND_KEY){
  $html = '<p><b>' + $satir + '</b></p><pre>' + $mesaj + '</pre>'
  $mb = @{ from=$env:RESEND_FROM; to=@('cemdizdar85@hotmail.com'); subject=$satir; html=$html } | ConvertTo-Json -Depth 3
  try { Invoke-RestMethod -Method Post -Uri 'https://api.resend.com/emails' -Headers @{ Authorization="Bearer $($env:RESEND_KEY)" } -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType 'application/json' -TimeoutSec 60 | Out-Null; $gitti = $true; Write-Host 'Mail (resend) gonderildi.' } catch { Write-Host "resend hatasi: $($_.Exception.Message)" }
}
if(-not $gitti){
  $govde = @{ access_key=$WEB3; subject=$satir; from_name='Tetikte Sabah Raporu'; email='cemdizdar85@hotmail.com'; message=$mesaj } | ConvertTo-Json
  try { $y = Invoke-RestMethod -Uri 'https://api.web3forms.com/submit' -Method Post -ContentType 'application/json' -UserAgent 'Mozilla/5.0 (TetikteNobetci)' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 60; if($y.success){ $gitti = $true; Write-Host 'Mail (web3forms) gonderildi.' } } catch { Write-Host "web3forms hatasi: $($_.Exception.Message)" }
}
if(-not $gitti){ Write-Host 'MAIL GONDERILEMEDI - iki kanal da dustu.'; exit 1 }

# durum dosyasi (05/06 kosusu bugunu bilsin)
@{ tarih=$bugun; durum=$durum; saat=$trSimdi.ToString('HH:mm'); satir=$satir } | ConvertTo-Json | Out-File $durumYol -Encoding utf8
