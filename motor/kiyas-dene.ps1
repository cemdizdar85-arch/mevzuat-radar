# ============================================================================
#  KIYAS DENE v0 - Katman B kaniti: mevzuat.gov.tr'deki ESKI birlesik PDF'ten
#  belirli GTIP kodlarinin onceki kiymetini okur -> yeni degerle kiyaslanir.
# ============================================================================
param(
  [string]$PdfYol = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\teblig-40161.pdf",
  [string]$Kodlar = "6907.30.00.00.00, 6907.40.00.00.00, 6910.10.00.00.00",
  [string]$Model = "claude-haiku-4-5"
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$key = (Get-Content "C:\Users\cemdi\.mevzuat-radar-api" -Raw).Trim()

$pdfB64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($PdfYol))
$istem = @"
Bu PDF, mevzuat.gov.tr'den indirilmis bir Ithalatta Gozetim Tebligi'nin birlesik (guncel) halidir.

GOREV:
1) Once tebligin numarasini PDF'ten oku (or: 2018/5).
2) Tablodan SADECE su GTIP kodlarinin birim gumruk kiymetini oku: $Kodlar
3) SADECE gecerli JSON dondur, baska hicbir sey yazma:
{"teblig_no":"...","degerler":[{"gtip":"kod","deger":"deger birimiyle"}]}
Bir kodu tabloda bulamiyor/okuyamiyorsan deger alanina "okunamadi" yaz. Tahmin YASAK.
"@
$icerik = @(
  @{ type = "document"; source = @{ type = "base64"; media_type = "application/pdf"; data = $pdfB64 } },
  @{ type = "text"; text = $istem }
)
$govde = @{ model = $Model; max_tokens = 600; messages = @(@{ role="user"; content=$icerik }) } | ConvertTo-Json -Depth 10

Write-Host "PDF Claude'a gonderiliyor ($Model, $([math]::Round((Get-Item $PdfYol).Length/1KB)) KB)..."
$r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 300
$c = $r.content[0].text.Trim()
$c = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($c))
Write-Host "CEVAP:"; Write-Host $c
$maliyet = ($r.usage.input_tokens/1000000.0)*1.0 + ($r.usage.output_tokens/1000000.0)*5.0
Write-Host ("Token: {0}/{1} | Maliyet: ~{2:N4} USD" -f $r.usage.input_tokens, $r.usage.output_tokens, $maliyet)