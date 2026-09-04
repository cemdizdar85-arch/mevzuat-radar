# ============================================================================
#  ALARM MAİLİ — robotların TEK posta kapısı (Resend)
#
#  NEDEN (04.09.2026, Cem "kurumsal firma olacağız, güvensiz yere gönderme"):
#  12 akış + 2 betik alarm maillerini web3forms üzerinden atıyordu; anahtar
#  depoda açıktı, veri üçüncü bir aracıdan geçiyordu. Artık her robot bu
#  betiği çağırır, mail doğrudan Resend'den (alan adı doğrulanmış:
#  DKIM/SPF/DMARC tam) gider. web3forms yedeği YOK — bilerek.
#
#  KULLANIM (Actions adımı, shell: pwsh):
#    env:
#      RESEND_KEY:  ${{ secrets.RESEND_KEY }}
#      RESEND_FROM: ${{ secrets.RESEND_FROM }}
#    run: ./arac/alarm-maili.ps1 -Konu 'TETIKTE ROBOT KIRMIZI - x dustu' -Mesaj "..."
#
#  ENV: RESEND_KEY (zorunlu) · RESEND_FROM (yoksa 'Tetikte <bildirim@tetikte.com>')
#       ALARM_ALICI (yoksa cemdizdar85@hotmail.com — alarm kutusu, müşteri verisi değil)
#
#  DÖNÜŞ: mail gittiyse 0. Gitmediyse de 0 — alarm adımı ana işi düşürmez;
#  ama sebebi BAĞIRARAK yazar (kör kalma kuralı). -Sert verilirse 1 döner.
# ============================================================================
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Konu,
  [Parameter(Mandatory = $true)][string]$Mesaj,
  [string]$Html = '',
  [string]$Alici = '',
  [string]$YanitAdresi = '',
  [switch]$Sert
)

$anahtar = ("$env:RESEND_KEY" -replace '[^\x21-\x7E]', '')
$gonderen = if ($env:RESEND_FROM) { "$env:RESEND_FROM".Trim() } else { 'Tetikte <bildirim@tetikte.com>' }
if (-not $Alici) { $Alici = if ($env:ALARM_ALICI) { "$env:ALARM_ALICI".Trim() } else { 'cemdizdar85@hotmail.com' } }

function Basarisiz([string]$neden) {
  Write-Host "!! ALARM MAILI GITMEDI: $neden"
  Write-Host "   Konu: $Konu"
  Write-Host "   (Mesaj asagida — mail gitmese de log KOR kalmasin)"
  Write-Host ($Mesaj -replace "`r", '')
  if ($Sert) { exit 1 } else { exit 0 }
}

if (-not $anahtar) { Basarisiz 'RESEND_KEY tanimli degil (Actions secrets / env)' }

if (-not $Html) {
  $kacis = [System.Net.WebUtility]::HtmlEncode($Mesaj)
  $Html = '<pre style="font-family:ui-monospace,Consolas,monospace;font-size:13px;white-space:pre-wrap">' + $kacis + '</pre>'
}

$govde = @{ from = $gonderen; to = @($Alici); subject = $Konu; text = $Mesaj; html = $Html }
if ($YanitAdresi) { $govde.reply_to = $YanitAdresi }
$json = $govde | ConvertTo-Json -Depth 4 -Compress

try {
  $r = Invoke-RestMethod -Method Post -Uri 'https://api.resend.com/emails' `
    -Headers @{ Authorization = "Bearer $anahtar" } `
    -Body ([Text.Encoding]::UTF8.GetBytes($json)) -ContentType 'application/json; charset=utf-8' -TimeoutSec 60
  Write-Host ("Alarm maili gonderildi (Resend, id={0}): {1}" -f $r.id, $Konu)
  exit 0
} catch {
  Basarisiz ("Resend hatasi: " + $_.Exception.Message)
}
