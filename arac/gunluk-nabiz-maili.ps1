# ============================================================================
#  GUNLUK NABIZ MAILI  (25.08.2026)
#
#  CEM: "gunluk nabiz maili ekle."
#
#  NEDEN BU, ALARM MAILINDEN FARKLI. Alarm maili yalniz KOTU haberde gider;
#  gitmezse (spam, itibar, kesinti) hicbir sey olmamis gibi gorunur - sessizlik
#  "her sey yolunda" sanilir. Bu mail HER GUN gider, iyi gunde de.
#  Boylece SESSIZLIK KENDISI SINYAL olur: mail gelmediyse ya sistem ya da mail
#  yolu bozulmustur. Ikisi de bilinmesi gereken seydir.
#  (Klasik "olu adam dugmesi" mantigi.)
#
#  38 GUNLUK DERS: Kanun Aynasi 38 gun kirmizi kaldi ve HER KOSUDA mail gitti.
#  Ucuncusunden sonra kimse okumaz. O yuzden bu mail KISA: tek satir hukum,
#  gerekirse birkac satir ayrinti, ve durum sayfasina baglanti. Uzun mail
#  okunmaz; okunmayan mail yoktur.
#
#  KONU SATIRI SABIT KALIPTA: "Tetikte gunluk nabiz - <HUKUM> (GG.AA)".
#  Sabit onek suzgec/kural kurmayi kolaylastirir; degisen kisim goz taramasi
#  icin yeterlidir. Boylece gelen kutusunda tek bakista "hangi gun kirmizi"
#  gorulur.
#
#  GONDERIM SONUCU KAYDEDILIR (bugunun kor-kalma dersi): 14 dosya Resend,
#  21 dosya web3forms kullaniyor ve COGU "gonder ve unut" - teslim edildi mi
#  bilinmiyordu. Bu betik sonucu veri/nabiz-maili-raporu.json'a yazar. Not:
#  bu "gonderim kabul edildi" demektir, "gelen kutusuna dustu" DEMEZ - onu
#  hicbir gonderici garanti edemez.
#
#  ENV: RESEND_KEY + RESEND_FROM (varsa Resend; yoksa web3forms yedegi)
#  KULLANIM: pwsh arac/gunluk-nabiz-maili.ps1  [-Kuru]
#  CIKIS: 0 gonderildi ya da kuru kosu · 1 iki kanal da basarisiz
# ============================================================================
param([switch]$Kuru)
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$kok = Split-Path -Parent $PSScriptRoot
Set-Location $kok

function RaporOku($yol) { if (Test-Path $yol) { try { return Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json } catch {} } return $null }

# --- durum.html ile AYNI kaynaklardan, AYNI mantikla hukum ---
# Ikisi ayri sey soylerse hangisine inanilacagi belirsiz olur; tek dogruluk
# kaynagi olsun diye kurallar birebir ayni tutuldu.
$satirlar = New-Object System.Collections.ArrayList
$kirmizi = 0; $uyari = 0; $bilinmez = 0

function Degerlendir([string]$ad, [string]$yol, [scriptblock]$oku) {
  $d = RaporOku $yol
  if ($null -eq $d) {
    $script:bilinmez++
    [void]$script:satirlar.Add("BILINMIYOR  $ad - rapor okunamadi")
    return
  }
  $s = & $oku $d
  switch ($s.d) {
    'KIRMIZI' { $script:kirmizi++ }
    'UYARI'   { $script:uyari++ }
  }
  [void]$script:satirlar.Add(("{0,-11} {1} - {2}" -f $s.d, $ad, $s.m))
}

Degerlendir 'Veri kapisi' 'veri/veri-kapisi-raporu.json' {
  param($d); if ([int]$d.red -gt 0) { @{d='KIRMIZI'; m="$($d.red) dosya reddedildi (eski saglam surum yerinde)"} }
  else { @{d='TEMIZ'; m="$($d.denetlenen) dosya denetlendi, hepsi gecti"} } }

Degerlendir 'Veri tazeligi' 'veri/veri-tazelik-raporu.json' {
  param($d); if ([int]$d.bayat -gt 0) { @{d='KIRMIZI'; m="$($d.bayat) dosyaya taze veri gelmiyor"} }
  else { @{d='TEMIZ'; m="taze $($d.taze) · bilincli elle $($d.bilincli_elle) · ritmi tanimsiz $($d.tanimsiz)"} } }

Degerlendir 'Zincir sirasi' 'veri/zincir-haritasi.json' {
  param($d); if ([int]$d.sira_riski -gt 0) { @{d='UYARI'; m="$($d.sira_riski) cift takvime yasliyor"} }
  else { @{d='TEMIZ'; m="$($d.cift) bagimlilik · olaya bagli $($d.olaya_bagli) · sira riski 0"} } }

Degerlendir 'Baglanmamis katman' 'veri/baglanmamis-raporu.json' {
  param($d); $n = @($d.cagrilmayan_betik).Count + @($d.atesalmayan_push_dali).Count
  if ($n -gt 0) { @{d='UYARI'; m="$n bulgu (is listesi, kapi degil)"} } else { @{d='TEMIZ'; m='bulgu yok'} } }

Degerlendir 'Robot nabzi' 'veri/nabiz-raporu.json' {
  param($d); if ([int]$d.kirmizi -gt 0) { @{d='KIRMIZI'; m=(@($d.maddeler)[0])} }
  else { @{d='TEMIZ'; m="izlenen robot $($d.izlenen_robot) · $($d.durum)"} } }

# --- TEK HUKUM: en kotu durum kazanir; BILINMEYEN YESIL SAYILMAZ ---
if ($kirmizi -gt 0)      { $hukum = 'KIRMIZI';      $bas = "$kirmizi yerde kirmizi" }
elseif ($bilinmez -gt 0) { $hukum = 'EKSIK OLCUM';  $bas = "$bilinmez kaynak okunamadi" }
elseif ($uyari -gt 0)    { $hukum = 'YOLUNDA';      $bas = "kirmizi yok · $uyari is listesi maddesi" }
else                     { $hukum = 'YOLUNDA';      $bas = 'tum nobetciler temiz' }

$gun  = Get-Date -Format 'dd.MM'
$konu = "Tetikte gunluk nabiz - $hukum ($gun)"
$govdeDuz = "$bas`n`n" + ($satirlar -join "`n") + "`n`nAyrinti: https://tetikte.com/durum.html`n`nBu mail HER GUN gider. Gelmedigi gun bir sey olmus demektir."
$satirHtml = ($satirlar | ForEach-Object { "<li style=""font-family:monospace;font-size:13px"">$_</li>" }) -join ''
$govdeHtml = "<p><b>$bas</b></p><ul>$satirHtml</ul>" +
             "<p><a href=""https://tetikte.com/durum.html"">Sistem durumu sayfasi</a></p>" +
             "<p style=""color:#888;font-size:12px"">Bu mail her gun gider. Gelmedigi gun bir sey olmus demektir.</p>"

Write-Host "=== GUNLUK NABIZ MAILI ==="
Write-Host ("HUKUM: {0} - {1}" -f $hukum, $bas)
$satirlar | ForEach-Object { Write-Host ("  {0}" -f $_) }

$kanal = ''; $gonderildi = $false; $hata = ''
if ($Kuru) {
  Write-Host "KURU KOSU - mail gonderilmedi."
} elseif ($env:RESEND_KEY -and $env:RESEND_FROM) {
  $mb = @{ from=$env:RESEND_FROM; to=@("cemdizdar85@hotmail.com"); subject=$konu; html=$govdeHtml; text=$govdeDuz } | ConvertTo-Json -Depth 3
  try {
    Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" `
      -Headers @{ Authorization = ("Bearer " + ("$env:RESEND_KEY" -replace '[^\x21-\x7E]','')) } `
      -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" -TimeoutSec 40 | Out-Null
    $kanal='resend'; $gonderildi=$true; Write-Host "MAIL (resend) gonderildi"
  } catch { $hata = "$_"; Write-Host "resend hatasi: $_" }
}
# Resend yoksa YA DA basarisizsa web3forms yedegi. Tek kanala guvenmeyiz.
if (-not $Kuru -and -not $gonderildi) {
  $mb = @{ access_key="5b227e56-94fb-4123-a39a-4286f63db14a"; subject=$konu; from_name="Tetikte Nabiz"
           "Durum"=$bas; "Nobetciler"=($satirlar -join "`n"); "Ayrinti"="https://tetikte.com/durum.html" } | ConvertTo-Json -Depth 3
  try {
    Invoke-RestMethod -Method Post -Uri "https://api.web3forms.com/submit" -Body ([Text.Encoding]::UTF8.GetBytes($mb)) `
      -ContentType "application/json" -TimeoutSec 40 | Out-Null
    $kanal='web3forms'; $gonderildi=$true; Write-Host "MAIL (web3forms) gonderildi"
  } catch { $hata = ($hata + ' | web3forms: ' + $_); Write-Host "web3forms hatasi: $_" }
}

# GONDERIM SONUCU KAYDEDILIR - "gonder ve unut" bitti.
# NOT: "gonderildi" = saglayici istegi KABUL ETTI demektir; gelen kutusuna
# dustugunu GARANTI ETMEZ. Onu hicbir gonderici garanti edemez; durum.html
# tam bu yuzden var.
$rapor = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  hukum = $hukum; ozet = $bas
  kirmizi = $kirmizi; uyari = $uyari; bilinmeyen = $bilinmez
  gonderildi = $gonderildi; kanal = $kanal; hata = $hata; kuru = [bool]$Kuru
  not = "gonderildi = saglayici kabul etti; gelen kutusuna dustugu GARANTI DEGIL. Kesin dogruluk kaynagi: durum.html"
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/nabiz-maili-raporu.json'), ($rapor | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host "-> veri/nabiz-maili-raporu.json"

if (-not $Kuru -and -not $gonderildi) { Write-Host "IKI KANAL DA BASARISIZ - mail yolu bozuk."; exit 1 }
exit 0
