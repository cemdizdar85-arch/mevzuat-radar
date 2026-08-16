# ============================================================================
#  DERS <-> KANUN UYUM KAPISI — "soru alakasiz bir kanuna mi baglanmis?"
#
#  DOGUSU (16.08.2026): damga denetiminin "metin degismis" kovasi okunurken
#  cikti. En buyuk grup Kamu Mali Yonetimi K. m.3'tu: 1.089 soru. Icerik
#  "cari oran hesaplama", "finansal oran analizi" - yani OZEL SEKTOR bilanco
#  analizi; dayanak ise KAMU IDARELERININ TANIM CETVELI. Dersi Maliye olan
#  yalniz 25 soru vardi; 1.064'u yanlis bagliydi. Tek bozuk parti degil,
#  kota-v2 #16-#26 partilerine yayilmis sistematik kusur.
#
#  NEDEN ONEMLI: bu, mevzuat degisikliginden BAGIMSIZ ve daha tehlikeli bir
#  kusur. Hakem soruyu alakasiz metinle yargilar; "destekliyor" diyemez ya da
#  daha kotusu uydurur. Damga denetimi bunu "metin degismis" sanip yanlis
#  kovaya koyuyordu.
#
#  OLCUT (temkinli): yalniz veri/ders-kanun-uyum.json'daki DAR KAPSAMLI
#  kanunlar icin hukum verilir. Tabloda olmayan kanun icin KUSUR DENMEZ.
#  VUK/TTK/GVK/KDV bilerek disarida - onlar hemen her muhasebe dersinde
#  mesru gecer. Emin olmadigimiza kusur demeyiz.
#
#  PARA HARCAMAZ. Varsayilan OLCUM; kasaya yazma YOK.
#  ENV: SUPABASE_SERVICE_KEY. Rapor: veri/ders-kanun-kapisi.json
# ============================================================================
param([int]$sinir = 0)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$KEY = $env:SUPABASE_SERVICE_KEY
if([string]::IsNullOrWhiteSpace($KEY)){ Write-Host 'SUPABASE_SERVICE_KEY yok - cikildi.'; exit 0 }
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$H = @{ apikey=$KEY; Authorization=("Bearer "+$KEY) }
$raporYol = Join-Path $kok 'veri/ders-kanun-kapisi.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 6), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

$tabloYol = Join-Path $kok 'veri/ders-kanun-uyum.json'
if(-not (Test-Path $tabloYol)){ Write-Host 'veri/ders-kanun-uyum.json yok - onayli tablo olmadan hukum verilmez.'; exit 0 }
$tabloHam = Get-Content $tabloYol -Raw -Encoding UTF8 | ConvertFrom-Json
$UYGUN_DERSLER = New-Object 'System.Collections.Generic.Dictionary[string,object]'
foreach($k in $tabloHam.kanunlar){
  $set = New-Object 'System.Collections.Generic.HashSet[string]'
  foreach($d in $k.uygun_dersler){ [void]$set.Add(("$d").Trim()) }
  $UYGUN_DERSLER[("$($k.kanun_no)").Trim()] = [pscustomobject]@{ ad="$($k.ad)"; dersler=$set }
}
Write-Host ("Tabloda {0} dar kapsamli kanun var (digerlerine hukum verilmez)." -f $UYGUN_DERSLER.Count)

Write-Host 'Kasa cekiliyor...'
$kasaSatirlari = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  $govde = $null
  foreach($deneme in 1..3){
    try {
      $r = Invoke-WebRequest -Uri ("$U`?select=id,ders,konu,kaynak,kanun_no,madde_no,uretim&kanun_no=not.is.null&order=id&limit=1000&offset=$bas") -Headers $H -UseBasicParsing -TimeoutSec 300
      $govde = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()); break
    } catch { if($deneme -eq 3){ throw }; Start-Sleep -Seconds (5*$deneme) }
  }
  $cozulmus = ConvertFrom-Json -InputObject $govde
  $adet = 0
  foreach($satir in $cozulmus){ [void]$kasaSatirlari.Add($satir); $adet++ }
  if($adet -eq 0){ break }
  $bas += 1000
  if($adet -lt 1000){ break }
}
Write-Host ("kanun_no dolu soru: {0}" -f $kasaSatirlari.Count)
$parti = $kasaSatirlari.ToArray()
if($sinir -gt 0 -and $sinir -lt $parti.Count){ $parti = $parti[0..($sinir-1)] }

$kapsamDisi = 0; $uyumluSayi = 0; $supheli = 0
$dagilim = @{}; $partiDagilim = @{}
$ornekler = New-Object System.Collections.Generic.List[object]
foreach($s in $parti){
  $kn = ("$($s.kanun_no)").Trim()
  if(-not $UYGUN_DERSLER.ContainsKey($kn)){ $kapsamDisi++; continue }
  $ders = ("$($s.ders)").Trim()
  if($UYGUN_DERSLER[$kn].dersler.Contains($ders)){ $uyumluSayi++; continue }
  $supheli++
  $anahtar = $kn + ' -> ' + $ders
  if($dagilim.ContainsKey($anahtar)){ $dagilim[$anahtar]++ } else { $dagilim[$anahtar] = 1 }
  $up = "$($s.uretim)"
  if($partiDagilim.ContainsKey($up)){ $partiDagilim[$up]++ } else { $partiDagilim[$up] = 1 }
  if($ornekler.Count -lt 200){
    $ornekler.Add([pscustomobject]@{ id="$($s.id)"; ders=$ders; konu="$($s.konu)"; kanun=$kn; madde="$($s.madde_no)"; kaynak="$($s.kaynak)"; uretim=$up })
  }
}
$toplam = $kapsamDisi + $uyumluSayi + $supheli

Write-Host ''
Write-Host '======== DERS <-> KANUN UYUM KAPISI ========'
Write-Host ("  taranan          : {0}" -f $parti.Count)
Write-Host ("  tabloda YOK      : {0}  (hukum verilmedi)" -f $kapsamDisi)
Write-Host ("  uyumlu           : {0}" -f $uyumluSayi)
Write-Host ("  SUPHELI          : {0}  <-- alakasiz kanuna baglanmis" -f $supheli)
Write-Host ("  KOVA TOPLAMI     : {0} / {1}  {2}" -f $toplam, $parti.Count, $(if($toplam -eq $parti.Count){'(tutuyor)'}else{'(TUTMUYOR)'}))
if($dagilim.Count){
  Write-Host ''
  Write-Host '  EN COK SUPHE UYANDIRAN ESLESMELER:'
  foreach($a in ($dagilim.Keys | Sort-Object { -$dagilim[$_] } | Select-Object -First 12)){
    Write-Host ("     {0,5}  {1}" -f $dagilim[$a], $a)
  }
}
if($partiDagilim.Count){
  Write-Host ''
  Write-Host '  URETIM PARTISI DAGILIMI (ilk 8):'
  foreach($p in ($partiDagilim.Keys | Sort-Object { -$partiDagilim[$_] } | Select-Object -First 8)){
    Write-Host ("     {0,5}  {1}" -f $partiDagilim[$p], $p)
  }
}

RaporYaz ([ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='OLCUM'
  taranan = $parti.Count; tabloda_yok = $kapsamDisi; uyumlu = $uyumluSayi; supheli = $supheli
  kova_toplami = $toplam; hesap_tutuyor = ($toplam -eq $parti.Count)
  eslesme_dagilimi = $dagilim
  uretim_partisi_dagilimi = $partiDagilim
  ornekler = $ornekler.ToArray()   # @($list) bu ortamda ArgumentException firlatiyor
  not = 'Yalniz tablodaki dar kapsamli kanunlar icin hukum verilir; tabloda olmayan kanun icin kusur DENMEZ. Kasaya yazma YOK - isaretleme ayri karar.'
})
Write-Host ''
Write-Host '-> veri/ders-kanun-kapisi.json'
Write-Host 'OLCUM modu - kasaya hicbir sey yazilmadi.'
