# ============================================================================
#  SINAV PROVASI SONUÇ MAİLİ — çağırıcı (11.10.2026, Cem: "sonucu sonra mail ile atmak mantıklı")
#  İş uç fonksiyonda (radar-app/edge/prova-sonuc-mail.ts): e-posta adresi, puan, yüzdelik SUNUCUDA birleşir.
#  Bu betik yalnız oturum kodu + mod yollar, ekrana yalnız SAYI basar (kişi verisi günlüğe/depoya girmez).
#  Bu makinede koşar (servis anahtarı kullanıcı ortam değişkeninde); Actions'a bağlanmadı.
#
#  SIRA (oturum kapandıktan sonra):
#    1) .\motor\canli-yuzdelik.ps1 -oturum SGS-1710        -> veri/canli/sonuc-SGS-1710.json yayında
#    2) .\motor\prova-sonuc-mail.ps1 -Oturum SGS-1710 -Prova -Alici <kendi adresin>   -> tek mail, örnek/ilk satır
#    3) Cem maili görür, "gönder" der ->
#       .\motor\prova-sonuc-mail.ps1 -Oturum SGS-1710 -Toplu -Onay "<tarih> Cem: <sözü>"
#  ⛔ Cem onayı olmadan -Toplu YOK. Fonksiyon -Onay boşsa 403 verir; yüzdelik yayınlanmadıysa 409.
#  🚫 GÖRMEZ: mailin gelen kutusuna düşüp düşmediği (Resend paneli) · onay metninin gerçekten Cem'den gelmesi.
# ============================================================================
param(
  [Parameter(Mandatory=$true)][ValidatePattern('^(SGS|YET)-[0-9]{4}$')][string]$Oturum,
  [switch]$Prova,
  [string]$Alici = '',
  [switch]$Toplu,
  [string]$Onay = ''
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$anahtar = $env:SUPABASE_SERVICE_KEY
if(-not $anahtar){ $anahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $anahtar){ throw 'SUPABASE_SERVICE_KEY yok' }
if($Prova -eq $Toplu){ throw 'Ya -Prova ya -Toplu' }
$uc = 'https://bjrleanjpyujtajmazxn.supabase.co/functions/v1/prova-sonuc-mail'
$baslik = @{ apikey = $anahtar; Authorization = "Bearer $anahtar" }

function Cagir($govde){
  $json = ConvertTo-Json -InputObject $govde -Compress
  $bayt = [Text.Encoding]::UTF8.GetBytes($json)
  try {
    return Invoke-RestMethod -Method Post -Uri $uc -Headers $baslik -ContentType 'application/json; charset=utf-8' -Body $bayt -TimeoutSec 150 -UserAgent 'tetikte-bakim/1.0'
  } catch {
    $kod = $null; try { $kod = [int]$_.Exception.Response.StatusCode } catch {}
    throw ("prova-sonuc-mail HATA (HTTP {0})" -f $kod)
  }
}

if($Prova){
  if($Alici -notmatch '^[^@\s]+@[^@\s]+\.[a-z]{2,}$'){ throw '-Alici gecerli bir adres olmali' }
  $r = Cagir @{ oturum = $Oturum; mod = 'prova'; alici = $Alici }
  Write-Host ("PROVA MAILI GITTI: ornek veri={0} · tablodan gercek satir={1} · yuzdelik yayinda={2}" -f $r.ornek, $r.gercek_satir, $r.yuzdelik_yayinda)
  exit 0
}

if(-not $Onay.Trim()){ throw '-Onay bos: Cem onayi olmadan toplu gonderim YOK' }
$toplam = 0; $adressiz = 0; $tur = 0
while($true){
  $tur++
  $r = Cagir @{ oturum = $Oturum; mod = 'toplu'; onay = $Onay }
  $toplam += [int]$r.gonderilen; $adressiz += [int]$r.adressiz
  Write-Host ("tur {0}: gonderilen {1} · adressiz {2} · kalan {3}" -f $tur, $r.gonderilen, $r.adressiz, $r.kalan)
  if([int]$r.kalan -le 0 -or [int]$r.gonderilen -eq 0 -or $tur -ge 200){ break }
}
Write-Host ("TOPLU BITTI: {0} mail · {1} adressiz satir" -f $toplam, $adressiz)
