# ============================================================================
#  TABLO HASAT v0 - aktif gozetim tebliglerinin resmi birlesik PDF'lerinden
#  TUM GTIP tablolarini ceker -> gtip-durum.json (GTIP sorgu urununun kalbi).
#  Kimlik dogrulamali: PDF'in icindeki teblig no eslesmezse kayit REDDEDILIR.
# ============================================================================
param([string]$Model = "claude-haiku-4-5")
$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$key = (Get-Content "C:\Users\cemdi\.mevzuat-radar-api" -Raw).Trim()
$esleme = (Get-Content (Join-Path $here "hafiza\eslesme-gozetim.json") -Raw -Encoding UTF8 | ConvertFrom-Json).esleme
$pdfDir = Join-Path $here "pdf"; New-Item -ItemType Directory -Force $pdfDir | Out-Null
$tabloDir = Join-Path $here "hafiza\tablolar"; New-Item -ItemType Directory -Force $tabloDir | Out-Null

# AKTIF SET: 2026 yilbasi seti + bugun degisiklik goren eski tebligler
$aktif = @()
foreach($p in $esleme.PSObject.Properties){ if($p.Name -like "2026/*"){ $aktif += $p.Name } }
$aktif += @("2018/5","2018/7","2018/8","2018/10","2019/6","2020/1","2020/6","2025/1","2025/9")
$aktif = $aktif | Select-Object -Unique

"Aktif set: $($aktif.Count) teblig | Model: $Model"
$topG = 0; $topC = 0; $ok = 0; $red = 0; $hata = 0

foreach($tno in $aktif){
  $mno = $esleme.$tno
  if(-not $mno){ Write-Host "eslemede yok: $tno"; continue }
  $guvenliAd = $tno.Replace("/","-")
  $ciktiYol = Join-Path $tabloDir ($guvenliAd + ".json")
  if(Test-Path $ciktiYol){ continue }   # kaldigi yerden devam
  try {
    # PDF indir (cache)
    $pdfYol = Join-Path $pdfDir ("gozetim-" + $guvenliAd + ".pdf")
    if(-not (Test-Path $pdfYol)){
      $wc = New-Object System.Net.WebClient
      $wc.Headers.Add("User-Agent","Mozilla/5.0")
      $b = $wc.DownloadData("https://www.mevzuat.gov.tr/MevzuatMetin/yonetmelik/9.5.$mno.pdf")
      if([System.Text.Encoding]::ASCII.GetString($b[0..3]) -ne "%PDF"){ Write-Host "$tno ($mno): PDF degil, atlandi"; $hata++; continue }
      [System.IO.File]::WriteAllBytes($pdfYol, $b)
      Start-Sleep -Milliseconds 600
    }
    $pdfB64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($pdfYol))

    $istem = @"
Bu PDF bir Ithalatta Gozetim Tebligi'nin resmi birlesik halidir. GOREV:
1) Tebligin numarasini oku.
2) Tablodaki TUM satirlari cikar: her GTIP icin birim gumruk kiymetini (birimiyle) yaz.
3) SADECE gecerli JSON: {"teblig_no":"YYYY/N","satirlar":[{"gtip":"kod","deger":"deger birim"}]}
Okuyamadigin satiri atla, tahmin etme. Kod formati genelde NNNN.NN.NN.NN.NN.
"@
    $icerik = @(
      @{ type="document"; source=@{ type="base64"; media_type="application/pdf"; data=$pdfB64 } },
      @{ type="text"; text=$istem }
    )
    $govde = @{ model=$Model; max_tokens=3500; messages=@(@{ role="user"; content=$icerik }) } | ConvertTo-Json -Depth 10
    $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 300
    $topG += $r.usage.input_tokens; $topC += $r.usage.output_tokens
    $c = $r.content[0].text.Trim()
    $c = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($c))
    if($c -match "(?s)\{.*\}"){ $c = $Matches[0] }
    $j = $c | ConvertFrom-Json

    # KIMLIK DOGRULAMA - altin kural
    $pdfNo = ($j.teblig_no -replace "\s","")
    if($pdfNo -ne $tno){
      Write-Host ("RED {0}: PDF kimligi '{1}' cikti - kayit yazilmadi" -f $tno, $j.teblig_no) -ForegroundColor Yellow
      $red++
      continue
    }
    $kayit = [ordered]@{ teblig=$tno; mevzuatNo=$mno; kaynak="https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=$mno&MevzuatTur=9&MevzuatTertip=5"; alinma="tek gecis (sorgu aninda dogrulanacak)"; satirlar=$j.satirlar }
    ($kayit | ConvertTo-Json -Depth 5) | Out-File $ciktiYol -Encoding utf8
    $ok++
    Write-Host ("OK {0}: {1} satir" -f $tno, @($j.satirlar).Count)
  } catch {
    $hata++
    Write-Host ("HATA {0}: {1}" -f $tno, ($_.Exception.Message -replace [regex]::Escape($key),"***")) -ForegroundColor Yellow
  }
}

# ---- birlesik durum veritabani: gtip-durum.json ------------------------------
$durum = @{}
Get-ChildItem $tabloDir -Filter "*.json" | ForEach-Object {
  $t = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($s in @($t.satirlar)){
    if(-not $s.gtip){ continue }
    if(-not $durum.ContainsKey($s.gtip)){ $durum[$s.gtip] = @() }
    $durum[$s.gtip] += [ordered]@{ deger=$s.deger; teblig=$t.teblig; kaynak=$t.kaynak }
  }
}
$sirali = [ordered]@{}
foreach($k in ($durum.Keys | Sort-Object)){ $sirali[$k] = $durum[$k] }
($sirali | ConvertTo-Json -Depth 5) | Out-File (Join-Path $here "hafiza\gtip-durum.json") -Encoding utf8

$maliyet = ($topG/1000000.0)*1.0 + ($topC/1000000.0)*5.0
""
"HASAT BITTI. Islenen: $ok | Kimlik reddi: $red | Hata: $hata"
"Token: $topG/$topC | Maliyet: ~$([math]::Round($maliyet,3)) USD"
"GTIP durum veritabani: $($sirali.Keys.Count) kod -> hafiza\gtip-durum.json"