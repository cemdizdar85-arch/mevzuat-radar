# ============================================================================
#  KART URET v0 - tek tebligi Claude'a okutup hap kart JSON'u uretir.
#  Kullanim: powershell -ExecutionPolicy Bypass -File kart-uret.ps1 -Dosya 20260711-31.htm -Gun 11-07-2026
#  Anahtar: C:\Users\cemdi\.mevzuat-radar-api (repo disi)
# ============================================================================
param(
  [Parameter(Mandatory=$true)][string]$Dosya,
  [Parameter(Mandatory=$true)][string]$Gun,
  [string]$Model = "claude-haiku-4-5"
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$key = (Get-Content "C:\Users\cemdi\.mevzuat-radar-api" -Raw).Trim()

# --- tebligi oku (RG eski sayfalari windows-1254) ----------------------------
$yol = Join-Path $here ("arsiv\" + $Gun + "\" + $Dosya)
if(-not (Test-Path $yol)){ "Teblig dosyasi yok: $yol"; exit 1 }
$ham = [System.IO.File]::ReadAllBytes($yol)
$html = [System.Text.Encoding]::GetEncoding(1254).GetString($ham)
$metin = ($html -replace "(?is)<script.*?</script>","" -replace "(?is)<style.*?</style>","" -replace "<[^>]+>"," " -replace "&nbsp;"," " -replace "\s+"," ").Trim()
$metin = [System.Net.WebUtility]::HtmlDecode($metin)
if($metin.Length -gt 12000){ $metin = $metin.Substring(0,12000) }

# --- gomulu gorselleri bul + indir (GTIP tablolari gorselde!) ----------------
$tarihKlas = $Gun.Split("-")   # 11-07-2026 -> yil icin [2], ay [1]
$tabanUrl = "https://www.resmigazete.gov.tr/eskiler/$($tarihKlas[2])/$($tarihKlas[1])/"
$imgSrcler = [regex]::Matches($html,'(?i)<img[^>]+src="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique -First 3
$icerik = @()
$wc = New-Object System.Net.WebClient
foreach($src in $imgSrcler){
  $imgUrl = if($src -match "^https?:"){ $src } else { $tabanUrl + ($src -replace "^\./","") }
  try {
    $wc.Headers.Add("User-Agent","Mozilla/5.0 (MevzuatRadar-v0)")
    $imgBytes = $wc.DownloadData($imgUrl)
    $mime = if($src -match "\.png$"){ "image/png" } else { "image/jpeg" }
    $icerik += @{ type = "image"; source = @{ type = "base64"; media_type = $mime; data = [Convert]::ToBase64String($imgBytes) } }
    Write-Host ("Gorsel eklendi: {0} ({1} KB)" -f $src, [math]::Round($imgBytes.Length/1KB))
  } catch { Write-Host ("Gorsel indirilemedi: " + $imgUrl) -ForegroundColor Yellow }
}

$istem = @"
Sen Mevzuat Radari'nin kart motorusun. Asagida bir Resmi Gazete tebligi metni (ve varsa tablo goruntuleri) var. Gorevin: Turkiye'deki ithalatci/ihracatci KOBI patronunun 30 saniyede anlayacagi bir 'hap bilgi karti' verisi cikarmak.

ALTIN KURALLAR:
1) Rakam, tarih, oran, GTIP kodu SADECE verilen metinden/goruntuden alinir. Emin olamadigin her sey icin "kaynakta belirtilmemis" yaz. ASLA tahmin etme, ASLA uydurma.
2) Sade Turkce - jargonsuz. 'Annem anlar mi?' testi.
3) SADECE gecerli JSON dondur, baska hicbir sey yazma.

JSON semasi:
{
  "baslik_sade": "tek cumle, patron diliyle",
  "ne_oldu": "1-2 cumle",
  "gtip_kodlari": ["goruntu ve metindeki TUM kodlar; okunamiyorsa bos birak"],
  "urun_tanimi": "hangi esya/urun grubu",
  "kimi_ilgilendirir": "kim etkilenir",
  "ne_yapmali": "somut adim(lar)",
  "yururluk": "yururluk tarihi/kurali - kaynaktan",
  "birim_kiymet": "tablodaki gozetim/birim kiymet degerleri ozet - kaynaktan, yoksa 'kaynakta belirtilmemis'",
  "guven_notu": "okuyamadigin/emin olamadigin kisimlar"
}

TEBLIG METNI:
$metin
"@
$icerik += @{ type = "text"; text = $istem }

$govde = @{ model = $Model; max_tokens = 1500;
  messages = @(@{ role = "user"; content = $icerik }) } | ConvertTo-Json -Depth 10

Write-Host "Claude'a gonderiliyor ($Model)..."
$r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" -Headers @{ "x-api-key" = $key; "anthropic-version" = "2023-06-01" } -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json"

$cevap = $r.content[0].text.Trim()
# PS 5.1 cevabi Latin-1 sanarak cozer - UTF-8'e geri cevir
$cevap = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($cevap))
if($cevap -match "(?s)\{.*\}"){ $cevap = $Matches[0] }   # olasi kod bloklarini ayikla

$ciktiDir = Join-Path $here "kartlar"
New-Item -ItemType Directory -Force $ciktiDir | Out-Null
$kartYol = Join-Path $ciktiDir ($Dosya -replace "\.htm$",".json")
[System.IO.File]::WriteAllText($kartYol, $cevap, (New-Object System.Text.UTF8Encoding($true)))

# maliyet (Haiku 4.5: 1$/MTok girdi, 5$/MTok cikti)
$maliyet = ($r.usage.input_tokens/1000000.0)*1.0 + ($r.usage.output_tokens/1000000.0)*5.0
Write-Host ""
Write-Host ("KART URETILDI: {0}" -f $kartYol) -ForegroundColor Green
Write-Host ("Token: girdi {0} / cikti {1} | Maliyet: ~{2:N4} USD" -f $r.usage.input_tokens, $r.usage.output_tokens, $maliyet)
