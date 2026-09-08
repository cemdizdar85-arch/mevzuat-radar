# ============================================================================
#  KURULUS NOBET POSTACISI - kurulus_nobet kasasindaki kayitlara mail atar
#
#  NEDEN VAR (08.09.2026, Cem "GM onerilerini yapalim" #1): kurulus-nobeti.html
#  takvimi ICS olarak indirtiyordu ve kaydi Cem'e mail atiyordu; KULLANICIYA
#  hicbir sey gitmiyordu. Rakiplerin (Firstbase) asil urunu hatirlatmadir.
#  Bu robot her sabah:
#    1) hosgeldin bos olan kayda takvimin TAMAMINI (tekrarsiz olaylar + aylik
#       tekrarlarin ilk ornekleri) bir kez yollar, hosgeldin damgasini basar
#    2) 3 gun icinde gelen olaylar icin hatirlatma yollar; son_hatirlatma'yi
#       ileri alir (ayni olay iki kez gitmez)
#  Mail kapisi: arac/alarm-maili.ps1 (Resend, -Alici ile kullaniciya).
#  'iptal' ELLE islenir: yanit adresi Cem'in alarm kutusu; Cem iptal=true yapar.
#  Rapor: veri/kurulus-nobet-postaci-raporu.json (SAYILAR - e-posta yazilmaz).
#  ENV: SUPABASE_SERVICE_KEY, RESEND_KEY, RESEND_FROM; NOBET_YANIT (yoksa ALARM_ALICI)
#  API maliyeti: Resend ucretsiz katman (gunluk 100 / aylik 3.000) - tavan asagida.
# ============================================================================
param([switch]$Kuru, [int]$Tavan = 80, [int]$OnGun = 3)
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
. (Join-Path $kok 'arac\rapor-yaz.ps1')
$raporYol = Join-Path $kok 'veri/kurulus-nobet-postaci-raporu.json'
$API = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
$yanit = if ($env:NOBET_YANIT) { $env:NOBET_YANIT } elseif ($env:ALARM_ALICI) { $env:ALARM_ALICI } else { 'cemdizdar85@hotmail.com' }

function Rapor($nesne){ RaporYaz -Hedef $raporYol -Nesne $nesne -Derinlik 5 -ZamanAlanlari @('tarih') | Out-Null }

if (-not $env:SUPABASE_SERVICE_KEY) {
  Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KOR - SUPABASE_SERVICE_KEY yok' })
  Write-Host 'SUPABASE_SERVICE_KEY yok - KOR.'; exit 2
}
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }

function Getir($yol){
  $w = Invoke-WebRequest -Uri "$API/$yol" -Headers $SB -UseBasicParsing -TimeoutSec 120 -SkipHttpErrorCheck
  $ham = if ($w.RawContentStream) { [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
  if ([int]$w.StatusCode -ge 400) { throw ("Supabase {0}: {1}" -f $w.StatusCode, $ham) }
  return @($ham | ConvertFrom-Json)
}
function Yama($id, $govde){
  # 08.09 kusur: kuru kosu mail atmadan "hosgeldin" damgasi basiyordu; gercek kosu
  # hos geldini atlayip dogrudan hatirlatmaya gecti (Cem'in kutusunda olculdu).
  if ($Kuru) { Write-Host "  KURU: kayit $id damgalanmadi"; return }
  $json = $govde | ConvertTo-Json -Compress
  $w = Invoke-WebRequest -Uri "$API/kurulus_nobet?id=eq.$id" -Method Patch -Headers ($SB + @{ 'Content-Type'='application/json'; Prefer='return=minimal' }) -Body ([Text.Encoding]::UTF8.GetBytes($json)) -UseBasicParsing -TimeoutSec 60 -SkipHttpErrorCheck
  if ([int]$w.StatusCode -ge 400) { throw ("PATCH $id -> $($w.StatusCode)") }
}
function HtmlGovde([string]$metin){
  # Duz metin -> okunur HTML: satir sonlari <br>, tarih satirlari kalin, baglantilar tiklanir.
  $k = [System.Net.WebUtility]::HtmlEncode($metin)
  $k = [regex]::Replace($k, '(?m)^(\d{2} \w{3} \d{4})  (.+)$', '<b style="color:#1b1a18">$1</b> · <b>$2</b>')
  $k = [regex]::Replace($k, '(https://\S+)', '<a href="$1" style="color:#a04a08">$1</a>')
  $k = $k -replace "`r?`n", '<br>'
  return '<div style="font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif;font-size:15px;line-height:1.6;color:#1b1a18;max-width:640px">' + $k + '</div>'
}
function Gonder($alici, $konu, $metin){
  if ($Kuru) { Write-Host "  KURU: $alici <- $konu"; return $true }
  # 08.09 olculdu: alarm-maili "gonderildi" satirini Write-Host ile basar; o akis 2>&1 ile
  # TOPLANMAZ (pwsh bilgi akisi). Mail gitti ama betik "gitmedi" sayip damga basmadi,
  # kosu KIRMIZI oldu. *>&1 butun akislari toplar.
  $cikti = & (Join-Path $kok 'arac\alarm-maili.ps1') -Konu $konu -Mesaj $metin -Html (HtmlGovde $metin) -Alici $alici -YanitAdresi $yanit *>&1
  $ok = ($cikti -join "`n") -match 'gonderildi'
  if (-not $ok) { Write-Host ("  MAIL GITMEDI: " + (($cikti -join ' ') -replace $alici, '<alici>')) }
  return $ok
}
$AD = @{ sahis='Şahıs işletmesi'; ltd='Limited şirket'; as='Anonim şirket' }
$AY = @('Oca','Şub','Mar','Nis','May','Haz','Tem','Ağu','Eyl','Eki','Kas','Ara')
function Gun([datetime]$d){ return ('{0:00} {1} {2}' -f $d.Day, $AY[$d.Month-1], $d.Year) }
function Temiz([string]$s){ return ([regex]::Replace($s, '<[^>]+>', '') -replace '\s+', ' ').Trim() }

try {
  $kayitlar = Getir 'kurulus_nobet?select=id,eposta,tur,tescil_tarihi,olaylar,hosgeldin,son_hatirlatma,gonderim_sayisi&iptal=eq.false&order=id&limit=2000'
} catch {
  Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KOR - tablo okunamadi'; hata="$($_.Exception.Message)"; olasi_sebep='radar-app/sql/2026-09-08-kurulus-nobet.sql basilmamis ya da service key yetkisiz' })
  Write-Host "Tablo okunamadi: $($_.Exception.Message)"; exit 2
}
$bugun = (Get-Date).Date
Write-Host ("Aktif kayit: {0}" -f $kayitlar.Count)
$hos = 0; $hat = 0; $hata = 0; $gonderilen = 0
foreach ($k in $kayitlar) {
  if ($gonderilen -ge $Tavan) { Write-Host "  TAVAN ($Tavan) doldu, kalanlar yarin."; break }
  $olaylar = @($k.olaylar | ForEach-Object { try { [pscustomobject]@{ d=[datetime]::ParseExact("$($_.d)",'yyyy-MM-dd',$null); ad=Temiz "$($_.ad)"; ne=Temiz "$($_.ne)"; dy=Temiz "$($_.dy)"; tekrar=[bool]$_.tekrar } } catch { $null } } | Where-Object { $_ } | Sort-Object d)
  if ($olaylar.Count -eq 0) { continue }
  $tescil = [datetime]::ParseExact("$($k.tescil_tarihi)",'yyyy-MM-dd',$null)
  try {
    if (-not $k.hosgeldin) {
      # 1) HOS GELDIN: takvimin tamami (tekrarli olaylarin ilk 3'u)
      $tekrarSay = @{}
      $satirlar = foreach ($o in $olaylar) {
        if ($o.tekrar) { $anahtar = ($o.ad -replace '\(.*\)','').Trim(); if (-not $tekrarSay.ContainsKey($anahtar)) { $tekrarSay[$anahtar]=0 }; $tekrarSay[$anahtar]++; if ($tekrarSay[$anahtar] -gt 3) { continue } }
        "{0}  {1}`n    {2}`n    Dayanak: {3}" -f (Gun $o.d), $o.ad, $o.ne, $o.dy
      }
      $metin = @"
Merhaba,

$($AD[$k.tur]) için $(Gun $tescil) tescil tarihine göre ilk 12 ayın takvimi aşağıda. Bu tarihlerin her birinden $OnGun gün önce sana bir hatırlatma yazacağız. Takvim yön vericidir; beyan günleri hafta sonuna denk gelince izleyen iş gününe kayar, kesin tarihleri muhasebecinle teyit et.

$($satirlar -join "`n`n")

(Aylık tekrar eden beyanların yalnız ilk üçü yazıldı; hatırlatmalar her ay gelir.)

Takvimi telefonuna eklemek ve tarihlerin kaynağını görmek için: https://tetikte.com/kurulus-nobeti.html#takvim

Nöbeti durdurmak istersen bu maile "iptal" yazıp yanıtla, kaydını sileriz.
Tetikte · Kuruluş Nöbeti
"@
      if (Gonder $k.eposta ("Kuruluş Nöbeti: " + $AD[$k.tur] + " ilk 12 ay takvimin") $metin) {
        Yama $k.id @{ hosgeldin = (Get-Date).ToUniversalTime().ToString('o'); gonderim_sayisi = ([int]$k.gonderim_sayisi + 1) }
        $hos++; $gonderilen++
      } else { $hata++ }
      continue   # ayni gun ikinci mail yok; hatirlatmalar yarin baslar
    }
    # 2) HATIRLATMA: [bugun, bugun+OnGun] araligindaki olaylar, son_hatirlatma'dan sonrakiler
    $son = if ($k.son_hatirlatma) { [datetime]::ParseExact("$($k.son_hatirlatma)",'yyyy-MM-dd',$null) } else { [datetime]'2000-01-01' }
    $yakin = @($olaylar | Where-Object { $_.d -ge $bugun -and $_.d -le $bugun.AddDays($OnGun) -and $_.d -gt $son })
    if ($yakin.Count -eq 0) { continue }
    $satirlar = foreach ($o in $yakin) { "{0}  {1}`n    {2}`n    Dayanak: {3}" -f (Gun $o.d), $o.ad, $o.ne, $o.dy }
    $metin = @"
Merhaba,

$($AD[$k.tur]) takviminde önümüzdeki $OnGun gün içinde şu tarih(ler) var:

$($satirlar -join "`n`n")

Hafta sonuna denk gelen beyan günü izleyen iş gününe kayar; muhasebecinle teyit et.
Takvimin tamamı: https://tetikte.com/kurulus-nobeti.html#takvim

Nöbeti durdurmak istersen bu maile "iptal" yazıp yanıtla.
Tetikte · Kuruluş Nöbeti
"@
    $konu = "Kuruluş Nöbeti: " + (Gun $yakin[0].d) + " · " + $yakin[0].ad
    if (Gonder $k.eposta $konu $metin) {
      $enSon = ($yakin | Sort-Object d | Select-Object -Last 1).d
      Yama $k.id @{ son_hatirlatma = $enSon.ToString('yyyy-MM-dd'); gonderim_sayisi = ([int]$k.gonderim_sayisi + 1) }
      $hat++; $gonderilen++
    } else { $hata++ }
  } catch { $hata++; Write-Host ("  kayit {0} hata: {1}" -f $k.id, $_.Exception.Message) }
}
$durum = if ($hata) { 'KIRMIZI' } else { 'YESIL' }
Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$durum; mod=$(if($Kuru){'KURU'}else{'CANLI'}); aktif_kayit=$kayitlar.Count; hosgeldin_gonderilen=$hos; hatirlatma_gonderilen=$hat; hata=$hata; tavan=$Tavan; on_gun=$OnGun; not='E-posta adresleri rapora yazilmaz; kayitlar yalniz kasada (RLS: anon ekler, okuyamaz).' })
Write-Host ("KURULUS NOBET POSTACISI: {0} | hos geldin {1} | hatirlatma {2} | hata {3}" -f $durum, $hos, $hat, $hata)
if ($hata) { exit 1 }
exit 0
