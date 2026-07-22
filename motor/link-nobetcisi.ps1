# ============================================================================
#  OLU LINK NOBETCISI — sitedeki tum DIS linkleri haftalik yoklar.
#  "Kaynaga bagliyiz" diyen sitede kirik kaynak linki en ucuz rezilliktir;
#  onu ziyaretciden once biz gorelim. API maliyeti SIFIR (saf HTTP kontrol).
#  Cikti: veri/kirik-linkler.json + kirik varsa mail (RESEND varsa).
#  Nazik tarama: istekler arasi bekleme, tekil linkler, UA/Referer başlıklı.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$UA = "Mozilla/5.0 (compatible; TetikteLinkNobetcisi/1.0; +https://tetikte.com)"

# 1) tum html'lerden dis linkleri topla
$dosyalar = @(Get-ChildItem (Join-Path $kok "*.html")) + @(Get-ChildItem (Join-Path $kok "sayfalar") -Filter *.html -ErrorAction SilentlyContinue)
$linkler = @{}
foreach($f in $dosyalar){
  $t = Get-Content $f.FullName -Raw -Encoding UTF8
  foreach($m in [regex]::Matches($t,'href="(https?://[^"]+)"')){
    $u = $m.Groups[1].Value
    # gurultu disi birak: kendi alanlarimiz + sayac + form servisi (POST ucu, GET 405 doner)
    if($u -match 'tetikte\.com|cemdizdar85-arch\.github\.io|goatcounter|web3forms|zgo\.at'){ continue }
    if(-not $linkler.ContainsKey($u)){ $linkler[$u] = New-Object System.Collections.Generic.List[string] }
    $linkler[$u].Add($f.Name)
  }
}
Write-Host ("{0} sayfadan {1} tekil dis link toplandi." -f $dosyalar.Count, $linkler.Count)

# 2) yokla (nazik: 300ms ara; mevzuat.gov.tr icin Referer sart)
$kirik = New-Object System.Collections.Generic.List[object]
$i=0
foreach($u in $linkler.Keys){
  $i++
  $hdr = @{ "User-Agent"=$UA }
  if($u -match 'mevzuat\.gov\.tr'){ $hdr["Referer"]="https://www.mevzuat.gov.tr/" }
  $kod = $null; $hata = $null
  try {
    $r = Invoke-WebRequest -Uri $u -Headers $hdr -TimeoutSec 30 -UseBasicParsing -MaximumRedirection 5 -Method Get
    $kod = [int]$r.StatusCode
  } catch {
    if($_.Exception.Response){ $kod = [int]$_.Exception.Response.StatusCode.value__ } else { $hata = $_.Exception.Message }
  }
  # 403/405/429: site botu sevmiyor ama LINK BUYUK IHTIMAL SAGLAM -> kirik sayma, 'kontrol' isaretle
  if($null -ne $kod -and $kod -ge 400 -and $kod -notin 403,405,429){
    $kirik.Add([ordered]@{ url=$u; kod=$kod; sayfalar=($linkler[$u] | Select-Object -Unique) -join ", " })
    Write-Host ("  KIRIK ({0}): {1}" -f $kod, $u)
  } elseif($hata){
    $kirik.Add([ordered]@{ url=$u; kod="baglanti-yok"; sayfalar=($linkler[$u] | Select-Object -Unique) -join ", " })
    Write-Host ("  ERISILEMEDI: {0}" -f $u)
  }
  Start-Sleep -Milliseconds 300
}

# 3) sonuc
$out = [pscustomobject]@{ tarama=(Get-Date -Format "dd.MM.yyyy HH:mm"); toplamLink=$linkler.Count; kirikSayisi=$kirik.Count; kirikler=$kirik.ToArray() }
[IO.File]::WriteAllText((Join-Path $kok "veri/kirik-linkler.json"), ($out | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
if($kirik.Count -eq 0){ Write-Host "TEMIZ: kirik dis link yok."; exit 0 }
Write-Host ("{0} KIRIK LINK bulundu." -f $kirik.Count)
if($env:RESEND_KEY){
  $sat = ($kirik | Select-Object -First 25 | ForEach-Object { "<li><a href='$($_.url)'>$($_.url)</a> — kod: $($_.kod) — gecen sayfa: $($_.sayfalar)</li>" }) -join ""
  $html = "<h3>Olu Link Nobetcisi raporu</h3><p>$($linkler.Count) dis link tarandi, <b>$($kirik.Count)</b> kirik/erisimsiz bulundu:</p><ul>$sat</ul><p>Duzeltme: dogru guncel linki bul, sayfada degistir. Tetikte — link nobetcisi</p>"
  $mb = @{ from=$env:RESEND_FROM; to=@("cemdizdar85@hotmail.com"); subject="TETIKTE LINK NOBETCISI: $($kirik.Count) kirik dis link"; html=$html } | ConvertTo-Json -Depth 3
  try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization="Bearer $($env:RESEND_KEY)" } -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" | Out-Null; Write-Host "rapor maili gitti" } catch { Write-Host "mail hatasi: $_" }
}
exit 0
