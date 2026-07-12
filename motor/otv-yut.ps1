# ============================================================================
#  OTV YUT - 4760 ekli (I)(II)(III)(IV) sayili listelerin GTIP KAPSAMINI cikar
#  Kaynak PDF sikistirilmis -> Word/pdftotext okuyamiyor. Claude API belge blogu
#  PDF'i gorsel okur. KURAL: sadece listede YAZAN pozisyonlari cikar, uydurma yok.
#  Cikti: scratchpad\otv-kapsam-ham.json  (sonra temizlenip veri\ya tasinir)
# ============================================================================
param(
  [string]$Pdf = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\otv-kanun.pdf",
  [string]$Model = "claude-sonnet-5"
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$key = (Get-Content "C:\Users\cemdi\.mevzuat-radar-api" -Raw).Trim()
$b64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($Pdf))
Write-Host "PDF boyut: $([math]::Round((Get-Item $Pdf).Length/1KB)) KB -> base64 $([math]::Round($b64.Length/1KB)) KB"

$istem = @"
Bu, 4760 sayili Ozel Tuketim Vergisi Kanunu'nun tam metni. Belgenin SONUNDA ekli dort liste var:
(I) SAYILI LISTE (akaryakit), (II) SAYILI LISTE (tasitlar), (III) SAYILI LISTE (alkol/tutun/icecek), (IV) SAYILI LISTE (lux).

GOREV: Her listede yer alan mallarin 4 HANELI TARIFE POZISYONLARINI (NN.NN formatinda, ornek 27.10, 87.03, 22.03, 33.03, 85.17) cikar.
Bir listede ayni pozisyon (or 27.10) altinda cok sayida alt kod olsa bile pozisyonu SADECE BIR KEZ yaz (tekillestir).
(III) liste A ve B cetvellerine bolunmusse hepsini III altinda topla.

KURALLAR:
- SADECE listelerde GERCEKTEN yer alan pozisyonlari yaz. Emin olmadigini YAZMA. Uydurma YASAK.
- Oran/tutar/TL YAZMA.
- Her pozisyonun yaninda 1-4 kelimelik kisa mal adi (listede yazan haliyle, Turkce).
- Pozisyon 4 haneli olmali: 8703.23... yerine 87.03 yaz. Ama liste bir pozisyonun sadece BELIRLI alt kodlarini kapsiyorsa yine pozisyonu yaz, ad kismina "(kismi)" ekle.

SADECE su JSON'u dondur (baska metin yok):
{"liste1":[{"p":"27.10","ad":"benzin, motorin"}],"liste2":[{"p":"87.03","ad":"binek otomobil"}],"liste3":[{"p":"22.03","ad":"bira"}],"liste4":[{"p":"33.03","ad":"parfum"}]}
"@

$content = @(
  @{ type="document"; source=@{ type="base64"; media_type="application/pdf"; data=$b64 } },
  @{ type="text"; text=$istem }
)
$govde = @{ model=$Model; max_tokens=6000; messages=@(@{ role="user"; content=$content }) } | ConvertTo-Json -Depth 12

Write-Host "API'ye gonderiliyor ($Model)..."
$r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 300

$metin = ""
foreach($b in $r.content){ if($b.type -eq "text"){ $metin += $b.text } }
Write-Host "stop_reason: $($r.stop_reason) | girdi tok: $($r.usage.input_tokens) | cikti tok: $($r.usage.output_tokens)"
$out = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\otv-kapsam-ham.json"
$metin | Out-File $out -Encoding utf8
Write-Host "--- CIKTI (ilk 1500) ---"
if($metin.Length -gt 1500){ $metin.Substring(0,1500) } else { $metin }
