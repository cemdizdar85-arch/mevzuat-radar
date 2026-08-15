# ============================================================================
#  MARKA IZLEME HASADI (15.08.2026) - Cem "marka watch kur" (#1 canli bulten borusu).
#
#  KAYNAK: TMview (EUIPO/TMDN) genel arama API'si - TURKPATENT (TR) verisini
#  YAPISAL JSON olarak, CAPTCHA'siz, sunucudan verir. 561 MB font-sifreli bulten
#  PDF'ine ve portal arama API'sinin HUMAN_CHECK token'ina GEREK YOK.
#    POST https://www.tmdn.org/tmview/api/search/results?translate=true
#    govde: {page,pageSize,criteria:"C",basicSearch:"",fOffices:["TR"],
#            sortColumn:"applicationDate",desc:true,fields:[...]}
#  Bos basicSearch = tum TR; applicationDate azalan = en yeni basvurular ustte.
#  TAZELIK OLCULDU (15.08.2026): en yeni kayit 09.08.2026 = ~6 gun gecikme.
#  "Filed" (yayimlanmamis) kayitta applicantName gizli ("Legally Restricted
#  Until Publication Date") -> sahip=null; yayimlaninca gercek sahip + itiraz
#  saati (SMK m.18, 2 ay) baslar.
#
#  CIKTI: veri/marka-yeni-basvurular.json - kompakt (istemci indirir, Izleme
#  araci kullanicinin markasiyla benzerlik motorundan eslestirir).
# ============================================================================
param([switch]$Yaz, [int]$Gun = 30, [int]$PageSize = 100, [int]$BeklemeMs = 350, [int]$AzamiSayfa = 400)
$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$yol  = Join-Path $kok "veri\marka-yeni-basvurular.json"
$uc   = "https://www.tmdn.org/tmview/api/search/results?translate=true"
$h = @{ "User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126 Safari/537.36"; "Referer"="https://www.tmdn.org/tmview/"; "Content-Type"="application/json"; "Accept"="application/json" }
$kesim = (Get-Date).Date.AddDays(-$Gun)
$alanlar = @("ST13","tmName","applicationNumber","applicationDate","tradeMarkStatus","niceClass","applicantName")
$gizli = "Legally Restricted"

function TarihStr($iso){ try{ return ([datetime]$iso).ToString("dd.MM.yyyy") }catch{ return "" } }

# TMview SERT TAVAN: page*pageSize > 10000 olunca 500/400 doner (ES max_result_window).
# Bu yuzden tek sorgu ~10.000 (en yeni ~15 gun) kaydi verir; ustu cekilemez.
# Cozum: robot HER GUN kosup en yeniyi ceker; gunluk delta minik oldugundan
# tavan bir daha bitmez (ilk backfill ~15 gun, sonra birikir - ozet not).
$TAVAN = 10000
$hepsi = New-Object Collections.ArrayList
$sayfa = 1; $dur = $false; $ardHata = 0
while(-not $dur -and $sayfa -le $AzamiSayfa){
  if(($sayfa * $PageSize) -gt $TAVAN){ Write-Host ("  (TMview 10.000 tavani - durduruldu, sayfa {0})" -f $sayfa); break }
  $govde = @{ page="$sayfa"; pageSize="$PageSize"; criteria="C"; basicSearch=""; fOffices=@("TR"); sortColumn="applicationDate"; desc=$true; fields=$alanlar } | ConvertTo-Json -Compress
  # PS 5.1 TUZAGI: Invoke-RestMethod, yanitta charset yoksa govdeyi Latin-1 sanip
  # Turkce marka adlarini bozuyor (mojibake). Ham byte'i UTF-8 cozeriz.
  try{
    $resp = Invoke-WebRequest -Uri $uc -Method Post -Headers $h -Body $govde -TimeoutSec 40 -UseBasicParsing
    $json = [Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
    $r = $json | ConvertFrom-Json
    $ardHata = 0
  }
  catch{ $ardHata++; if($ardHata -ge 3){ Write-Host ("  (ardisik {0} hata - durduruldu, sayfa {1})" -f $ardHata, $sayfa); break }; Start-Sleep -Milliseconds 800; $sayfa++; continue }
  $kayitlar = @($r.tradeMarks)
  if($kayitlar.Count -eq 0){ break }
  foreach($k in $kayitlar){
    $t = [datetime]$k.applicationDate
    if($t -ge $kesim){
      $sahipHam = (@($k.applicantName) -join ", ")
      $sahip = if($sahipHam -and $sahipHam -notmatch $gizli){ $sahipHam } else { $null }
      [void]$hepsi.Add([ordered]@{
        ad     = "$($k.tmName)"
        no     = "$($k.applicationNumber)"
        tarih  = (TarihStr $k.applicationDate)
        sinif  = @($k.niceClass)
        sahip  = $sahip
        durum  = "$($k.tradeMarkStatus)"
        st13   = "$($k.ST13)"
      })
    }
  }
  $enEski = ($kayitlar | ForEach-Object { [datetime]$_.applicationDate } | Measure-Object -Minimum).Minimum
  if($enEski -lt $kesim){ $dur = $true }
  if(($sayfa % 10) -eq 0){ Write-Host ("  sayfa {0} - toplanan {1}" -f $sayfa, $hepsi.Count) }
  $sayfa++
  Start-Sleep -Milliseconds $BeklemeMs
}
Write-Host ("`nTMview TR - pencere {0} gun (>= {1:dd.MM.yyyy}) - toplanan basvuru: {2} - taranan sayfa: {3}" -f $Gun, $kesim, $hepsi.Count, ($sayfa-1))

if($Yaz){
  $obj = [ordered]@{
    guncelleme = ("Kaynak: TMview (EUIPO/TMDN), TURKPATENT (TR) verisi. Son cekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + ".")
    not = ("Son " + $Gun + " gunde TURKPATENT'e dusen marka basvurulari (TMview uzerinden, ~gun mertebesinde gecikmeli). Yayimlanmamis kayitta basvuru sahibi gizlidir; yayimlaninca SMK m.18 2 aylik itiraz suresi baslar.")
    pencereGun = $Gun
    sayi = $hepsi.Count
    basvurular = @($hepsi)
  }
  ($obj | ConvertTo-Json -Depth 6) | Out-File $yol -Encoding utf8
  $geri = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  $boy = (Get-Item $yol).Length
  $moji = @($geri.basvurular | Where-Object { $_.ad -match ([char]0x00C3) }).Count
  Write-Host ("-> {0}" -f $yol)
  Write-Host ("   yazildi: {0} basvuru - {1:N0} KB - geri okuma {2} - mojibake {3}" -f $geri.sayi, ($boy/1KB), @($geri.basvurular).Count, $moji)
} else { Write-Host "(olcum modu - yazmak icin -Yaz)" }
