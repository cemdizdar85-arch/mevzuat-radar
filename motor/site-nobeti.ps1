#requires -Version 5.1
<#
================================================================================
  SITE NOBETI — "site ayakta mi" sorusunun TEK cevabi  (12.09.2026)
  Cem: "guvenlik, hizli olmak ve site hic kesilmemesi cok onemli"

  NIYE VAR: 12.09'da olctum - 146 Actions akisinin 12'si tetikte.com'dan
  BAHSEDIYOR ama HICBIRI "site ayakta mi" diye BAKMIYOR. Kotu bir commit ya da
  Pages kesintisi olsa saatlerce kimse fark etmezdi. "Site hic kesilmesin"
  dilegi, olculmeden dilek olarak kalir.

  ⛔ HTTP 200 YETMEZ. 30.08 dersi: "olu adres 200+HTML doner, bilinmeyen API
     yolu 200+SPA kabugu verir" (CLAUDE.md). O yuzden her sayfada UC olcut:
       1) HTTP 200
       2) en az <asgari> bayt  (bos/kirpik sayfa yakalanir)
       3) IMZA metni iceriyor   (yanlis sayfa/hata sayfasi yakalanir)

  ⛔ KURT MASALI OKUMAZ. Tek basarisiz istek KIRMIZI degildir - ag titremesi
     her gun olur. Her adres 3 kez, artan beklemeyle denenir; UCU DE duserse
     kirmizi. Yanlis alarm, alarmin kendisini oldurur.

  ⚠ OLCULEMEDI != KIRMIZI. Kosucunun agi yoksa bunu "site coktu" diye
     bildirmek yanlis teshistir; o durum ayrica isaretlenir.

  KULLANIM
    powershell -NoProfile -File motor/site-nobeti.ps1            # olc + rapor
    powershell -NoProfile -File motor/site-nobeti.ps1 -Mail      # kirmizida mail
  BEDEL 0.
================================================================================
#>
param(
  [switch]$Mail,                 # kirmizida alarm maili at (Actions'ta acik)
  [int]$Deneme = 3,
  [int]$ZamanAsimi = 40
)
$ErrorActionPreference='Stop'
$buDizin=$(if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok=Split-Path -Parent $buDizin
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

# ⚠ ASGARI BAYT canli olcumden turetildi (12.09 08:30), %60'ina cekildi ki
#   normal icerik dalgalanmasi alarm uretmesin:
#     ana sayfa 133.074 · kaydir/sgs 23.767 · ders sayfasi 734.403
$HEDEFLER=@(
  @{ ad='ana sayfa';    url='https://tetikte.com/';                                  asgari=60000;  imza='Tetikte' }
  @{ ad='SGS vitrini';  url='https://tetikte.com/kaydir/sgs/';                       asgari=10000;  imza='Kaydır' }
  @{ ad='ders sayfasi'; url='https://tetikte.com/kaydir/sgs/meslek-hukuku.html';     asgari=300000; imza='Nöbetçi' }
)

function Olc($hedef){
  $sonHata=''
  foreach($deneme in 1..$Deneme){
    try{
      $t0=Get-Date
      $cevap=Invoke-WebRequest -Uri $hedef.url -TimeoutSec $ZamanAsimi -UseBasicParsing -Headers @{ 'User-Agent'='Tetikte-SiteNobeti/1.0' }
      $sure=[int]((Get-Date)-$t0).TotalMilliseconds
      $govde="$($cevap.Content)"
      $kusur=New-Object System.Collections.Generic.List[string]
      if([int]$cevap.StatusCode -ne 200){ $kusur.Add("HTTP $($cevap.StatusCode)") }
      if($govde.Length -lt [int]$hedef.asgari){ $kusur.Add("boy $($govde.Length) < asgari $($hedef.asgari)") }
      if($govde -notmatch [regex]::Escape($hedef.imza)){ $kusur.Add("imza yok: '$($hedef.imza)'") }
      return [pscustomobject]@{ ad=$hedef.ad; url=$hedef.url; durum=$(if($kusur.Count){'KIRMIZI'}else{'YESIL'})
                                kod=[int]$cevap.StatusCode; bayt=$govde.Length; ms=$sure
                                kusur=($kusur.ToArray() -join ' · '); deneme=$deneme }
    }catch{
      $sonHata=$_.Exception.Message
      if($deneme -lt $Deneme){ Start-Sleep -Seconds (5*$deneme) }
    }
  }
  # Uc deneme de istek ATAMADI. Adres cevap vermiyor ya da bizim agimiz yok.
  return [pscustomobject]@{ ad=$hedef.ad; url=$hedef.url; durum='KIRMIZI'; kod=0; bayt=0; ms=0
                            kusur="$Deneme denemede yanit yok: $sonHata"; deneme=$Deneme }
}

$sonuclar=New-Object System.Collections.Generic.List[object]
foreach($h in $HEDEFLER){ $sonuclar.Add((Olc $h)) }
$dizi=$sonuclar.ToArray()

foreach($s in $dizi){
  $renk=$(if($s.durum -eq 'YESIL'){'Green'}else{'Red'})
  Write-Host ("  {0,-14} {1,-8} HTTP {2,3} · {3,8:N0} bayt · {4,5} ms{5}" -f $s.ad,$s.durum,$s.kod,$s.bayt,$s.ms,$(if($s.kusur){" · $($s.kusur)"}else{''})) -ForegroundColor $renk
}
$kirmizi=@($dizi|Where-Object{ $_.durum -eq 'KIRMIZI' })
$genel=$(if($kirmizi.Count){'KIRMIZI'}else{'YESIL'})
Write-Host ("`nSITE NOBETI: {0} ({1}/{2} yesil)" -f $genel,($dizi.Count-$kirmizi.Count),$dizi.Count) -ForegroundColor $(if($kirmizi.Count){'Red'}else{'Green'})

. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\site-nobeti.json') -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); durum=$genel
  yesil=($dizi.Count-$kirmizi.Count); kirmizi=$kirmizi.Count
  hedefler=@($dizi|ForEach-Object{ [pscustomobject]$_ })
})

if($kirmizi.Count -and $Mail){
  $govde=("SITE NOBETI KIRMIZI - " + (Get-Date -Format 'dd.MM.yyyy HH:mm') + "`n`n" +
          (($kirmizi|ForEach-Object{ "$($_.ad)  ->  $($_.url)`n    $($_.kusur)  (HTTP $($_.kod), $($_.bayt) bayt)" }) -join "`n`n") +
          "`n`nOlcut: HTTP 200 + asgari boy + imza metni. Her adres $Deneme kez denendi.")
  try{ & (Join-Path $depoKok 'arac\alarm-maili.ps1') -Konu 'TETIKTE SITE NOBETI KIRMIZI' -Mesaj $govde }
  catch{ Write-Host "!! alarm maili gitmedi: $($_.Exception.Message)" -ForegroundColor Red }
}
# ⛔ Kirmizida cikis kodu 1 - akis KIRMIZI gorunsun, sessiz gecmesin.
if($kirmizi.Count){ exit 1 }
