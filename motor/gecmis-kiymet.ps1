# ============================================================================
#  GECMIS KIYMET - geri-tarama arsivindeki (bir yillik) gozetim/damping
#  tebliglerinden GTIP+kiymet cikarir, tarihiyle hafizaya isler -> kiyas
#  motoru bir yillik degisim gecmisiyle dolar.
#  Butce sinirli: ~3 USD'de durur. Kaldigi yerden devam eder (islenen.txt).
# ============================================================================
param([double]$ButceUSD = 3.0, [string]$Model = "claude-haiku-4-5")
$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$key = (Get-Content "C:\Users\cemdi\.mevzuat-radar-api" -Raw).Trim()
$log = Join-Path $here "cikti\gecmis-kiymet.log"
$islenenYol = Join-Path $here "hafiza\gecmis-islenen.txt"
$islenen = @{}
if(Test-Path $islenenYol){ Get-Content $islenenYol | ForEach-Object { $islenen[$_] = $true } }

# mevcut kiymet hafizasini yukle (tarihce dizisi)
$hafizaYol = Join-Path $here "hafiza\kiymetler.json"
$hafiza = @{}
if(Test-Path $hafizaYol){
  $j = Get-Content $hafizaYol -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($p in $j.PSObject.Properties){ $hafiza[$p.Name] = [System.Collections.ArrayList]@($p.Value) }
}

function Kaydet(){
  $obj = [ordered]@{}
  foreach($k in ($hafiza.Keys | Sort-Object)){ $obj[$k] = $hafiza[$k] }
  ($obj | ConvertTo-Json -Depth 5) | Out-File $hafizaYol -Encoding utf8
}

$gunler = Get-ChildItem (Join-Path $here "arsiv") -Directory | Sort-Object Name
Add-Content $log ("BASLADI " + (Get-Date).ToString("HH:mm") + " | gun: $($gunler.Count) | butce: $ButceUSD USD")
$harcanan = 0.0; $islenenSayi = 0; $kayitEklenen = 0

foreach($gun in $gunler){
  $parts = $gun.Name.Split("-")   # GG-AA-YYYY
  $tarih = "$($parts[0]).$($parts[1]).$($parts[2])"
  $tabanUrl = "https://www.resmigazete.gov.tr/eskiler/$($parts[2])/$($parts[1])/"
  foreach($dosya in (Get-ChildItem $gun.FullName -Filter "*.htm")){
    if($harcanan -ge $ButceUSD){ Add-Content $log "BUTCE DOLDU ($([math]::Round($harcanan,3)) USD)"; Kaydet; exit 0 }
    $anahtar = "$($gun.Name)/$($dosya.Name)"
    if($islenen[$anahtar]){ continue }

    try {
      $ham = [System.IO.File]::ReadAllBytes($dosya.FullName)
      $html = [System.Text.Encoding]::GetEncoding(1254).GetString($ham)
      $metin = ($html -replace "(?is)<script.*?</script>","" -replace "(?is)<style.*?</style>","" -replace "<[^>]+>"," " -replace "&nbsp;"," " -replace "\s+"," ").Trim()
      $metin = [System.Net.WebUtility]::HtmlDecode($metin)
      if($metin.Length -gt 10000){ $metin = $metin.Substring(0,10000) }
      # sadece kiymet iceren tebligleri isle (gozetim/damping); digerini isaretleyip gec
      if($metin -notmatch "(?i)gözetim|damping|haksız rekabet|birim kıymet|gümrük kıymeti"){ $islenen[$anahtar]=$true; Add-Content $islenenYol $anahtar; continue }

      $gorseller = @()
      foreach($src in ([regex]::Matches($html,'(?i)<img[^>]+src="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique -First 2)){
        $imgUrl = if($src -match "^https?:"){ $src } else { $tabanUrl + ($src -replace "^\./","") }
        try { $wc=New-Object System.Net.WebClient; $wc.Headers.Add("User-Agent","Mozilla/5.0"); $b=$wc.DownloadData($imgUrl); $mime=if($src -match "\.png$"){"image/png"}else{"image/jpeg"}; $gorseller += @{type="image";source=@{type="base64";media_type=$mime;data=[Convert]::ToBase64String($b)}} } catch {}
      }
      $istem = "Bu bir Resmi Gazete gozetim/damping tebligi. Tablodan NET okudugun her GTIP icin birim kiymeti/oranı cikar. SADECE JSON: {`"satirlar`":[{`"gtip`":`"kod`",`"deger`":`"deger birimiyle`"}]}. Okuyamadigin satiri ATLA, tahmin etme. TEBLIG METNI: $metin"
      $icerik = @() + $gorseller + @(@{type="text";text=$istem})
      $govde = @{ model=$Model; max_tokens=1500; messages=@(@{role="user";content=$icerik}) } | ConvertTo-Json -Depth 10
      $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 200
      $harcanan += ($r.usage.input_tokens/1e6)*1.0 + ($r.usage.output_tokens/1e6)*5.0
      $c = $r.content[0].text.Trim()
      $c = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($c))
      if($c -match "(?s)\{.*\}"){ $c = $Matches[0] }
      $j = $c | ConvertFrom-Json

      foreach($s in @($j.satirlar)){
        if(-not $s.gtip -or -not $s.deger){ continue }
        $kod = ($s.gtip -as [string]).Trim()
        if($kod -notmatch '^\d'){ continue }
        if(-not $hafiza.ContainsKey($kod)){ $hafiza[$kod] = [System.Collections.ArrayList]@() }
        # ayni tarih+deger varsa ekleme
        $var = $false; foreach($e in $hafiza[$kod]){ if($e.tarih -eq $tarih -and (($e.deger -as [string]).Trim() -eq ($s.deger -as [string]).Trim())){ $var=$true; break } }
        if(-not $var){ [void]$hafiza[$kod].Add([pscustomobject]@{ tarih=$tarih; deger=($s.deger -as [string]).Trim(); teblig=$dosya.Name }); $kayitEklenen++ }
      }
      $islenen[$anahtar]=$true; Add-Content $islenenYol $anahtar; $islenenSayi++
      if(($islenenSayi % 10) -eq 0){ Kaydet; Add-Content $log ("  {0} teblig islendi | {1} kayit | {2:N3} USD | {3}" -f $islenenSayi, $kayitEklenen, $harcanan, (Get-Date).ToString("HH:mm")) }
    } catch {
      Add-Content $log ("HATA $anahtar : " + ($_.Exception.Message -replace [regex]::Escape($key),"***"))
      $islenen[$anahtar]=$true; Add-Content $islenenYol $anahtar
    }
    Start-Sleep -Milliseconds 300
  }
}
Kaydet
Add-Content $log ("BITTI " + (Get-Date).ToString("HH:mm") + " | islenen: $islenenSayi | kayit: $kayitEklenen | harcanan: $([math]::Round($harcanan,3)) USD | hafizadaki kod: $($hafiza.Keys.Count)")