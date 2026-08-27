# ============================================================================
#  ZORLUK KIYASI - 26.08.2026 (Cem: "kolay buluyorum - once olc; ders ders
#  degil KONU KONU, cunku sinav her konudan farkli soru soruyor")
#
#  IKI OLCUM, AYNI DETERMINISTIK SKORLA (deneme.html zorluk() portu -
#  tablo/yevmiye +2, rakam yogunlugu +1/+2, hesap kalibi +1, uzunluk +1;
#  1=isinma 2=orta 3=sinav seviyesi):
#   A) SINAV DUZEYI: cikmis kitapcik sorulari (ambar tur=cikmis-soru bloblari
#      bolunup skorlanir) vs kasa sorulari -> "gercekten kolay miyiz?"
#   B) KONU DUZEYI: cikmis konu SIKLIGI (analiz dosyalari) x kasadaki o konunun
#      zorluk profili -> "sinavin sevdigi konuda sinav-seviyesi sorumuz var mi?"
#      Cikti: hedef listesi = cikmista sik + bizde Z3 kit.
#  OLCUM - hicbir sey yazmaz. Rapor: veri/zorluk-kiyas.json
# ============================================================================
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent']='mevzuat-radar-robot/1.0'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$KEY=$env:SUPABASE_SERVICE_KEY
$H=@{apikey=$KEY; Authorization="Bearer $KEY"}
$U='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'

# --- deterministik zorluk (deneme.html zorluk() birebir portu) ---
$reHesap=[regex]'(?i)ka[cç]t[iı]r|hesapla|tutar[iı] ne|oran[iı] ka[cç]|ka[cç] TL'
$reRakam=[regex]'\d[\d.,]{2,}'
function Zorluk([string]$soru,[string]$sikJson,[bool]$tabloVar,[bool]$yevmiyeVar){
  $p=0; $metin="$soru $sikJson"
  if($tabloVar){ $p+=2 }
  if($yevmiyeVar){ $p+=2 }
  $rak=$reRakam.Matches($metin).Count
  if($rak -ge 6){ $p+=2 } elseif($rak -ge 2){ $p+=1 }
  if($reHesap.IsMatch($soru)){ $p+=1 }
  if($soru.Length -gt 420){ $p+=1 }
  if($p -ge 4){ return 3 } elseif($p -ge 2){ return 2 } else { return 1 }
}

# ============ A1) KASA PROFILI (sinav + ders + konu kiriliminda) ============
Write-Host 'KASA taraniyor...'
$kasaSinav=@{}; $kasaKonu=@{}
$bas=0
while($true){
  $r=@(Invoke-RestMethod -Uri "$U/soru_havuzu?select=id,sinav,ders,konu,soru,siklar,tablo,yevmiye&order=id&limit=500&offset=$bas" -Headers $H -TimeoutSec 300 | % { $_ })
  if($r.Count -eq 0){ break }
  foreach($s in $r){
    $z=Zorluk "$($s.soru)" (($s.siklar | ConvertTo-Json -Compress -Depth 3)) ($null -ne $s.tablo) ($null -ne $s.yevmiye -and @($s.yevmiye).Count -gt 0)
    $sk="$($s.sinav)"
    if(-not $kasaSinav[$sk]){ $kasaSinav[$sk]=@{n=0;z1=0;z2=0;z3=0} }
    $kasaSinav[$sk].n++; $kasaSinav[$sk]["z$z"]++
    $kk="$($s.sinav)|$(("$($s.konu)").ToLowerInvariant().Trim())"
    if(-not $kasaKonu[$kk]){ $kasaKonu[$kk]=@{n=0;z3=0;ders="$($s.ders)"} }
    $kasaKonu[$kk].n++; if($z -eq 3){ $kasaKonu[$kk].z3++ }
  }
  $bas+=500
  if($bas % 5000 -eq 0){ Write-Host "  ...$bas" }
}

# ============ A2) CIKMIS PROFIL (SGS kitapciklari bolunup skorlanir) ============
Write-Host 'CIKMIS kitapciklar DISKTEN okunuyor (SGS arsivi - satirli txt)...'
$cikSay=@{n=0;z1=0;z2=0;z3=0}
$txtler=@(Get-ChildItem (Join-Path $kok 'veri\sgs-arsiv') -Recurse -Include *.txt -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '\.ocr\.' })
Write-Host "  disk arsivi: $($txtler.Count) txt"
foreach($f in $txtler){
  $m=[IO.File]::ReadAllText($f.FullName)
  # karnedeki bolme deseni: satir basi "N. " (ambar kopyalari tek satira
  # dustugu icin AMBARDAN DEGIL diskten okunur - 26.08 ilk kosu dersi)
  foreach($p in [regex]::Split($m, '(?m)^(?=\s{0,4}\d{1,3}\.\s)')){
    if($p.Trim().Length -lt 50){ continue }
    if($p -notmatch '^\s*(\d{1,3})\.'){ continue }
    $z=Zorluk $p '' $false $false
    $cikSay.n++; $cikSay["z$z"]++
  }
}
Write-Host "  cikmis soru: $($cikSay.n)"

# ============ B) KONU DUZEYI HEDEF LISTESI ============
Write-Host 'Konu duzeyi birlesiyor...'
$hedefler=New-Object System.Collections.Generic.List[object]
$girdiler=@(@('SGS','sgs-analiz.json'),@('SMMM','smmm-analiz.json'),@('KGK','kgk-analiz.json'))
foreach($gi in $girdiler){
  $sinavAd=$gi[0]
  $an=Get-Content (Join-Path $kok "veri\$($gi[1])") -Raw -Encoding UTF8 | ConvertFrom-Json
  $cikKonu=@{}
  foreach($d in @($an.donemler)){
    if(-not $d.konuSayim){ continue }
    foreach($p in @($d.konuSayim.PSObject.Properties)){
      $cikKonu[$p.Name] = [int]$cikKonu[$p.Name] + [int]$p.Value
    }
  }
  foreach($anah in $cikKonu.Keys){
    $parca=$anah -split '\|',2
    $ders=$parca[0]; $konu=if($parca.Count -gt 1){ $parca[1] } else { $anah }
    $kk="$sinavAd|$($konu.ToLowerInvariant().Trim())"
    $kasa=$kasaKonu[$kk]
    $kasaN=if($kasa){ $kasa.n } else { 0 }
    $kasaZ3=if($kasa){ $kasa.z3 } else { 0 }
    $hedefler.Add([pscustomobject]@{
      sinav=$sinavAd; ders=$(if($kasa -and $kasa.ders){ $kasa.ders } else { $ders }); konu=$konu
      cikmisAdet=$cikKonu[$anah]; kasaAdet=$kasaN; kasaZ3=$kasaZ3
      z3Oran=$(if($kasaN){ [math]::Round(100*$kasaZ3/$kasaN) } else { 0 })
    })
  }
}

# ============ RAPOR ============
$rapor=[ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  yontem='deneme.html zorluk() deterministik skoru iki tarafa esit uygulandi; cikmis tarafta tablo gorselleri metne gecmedigi icin cikmis zorlugu hafif EKSIK olculur (sinif bilinen yanlilik, raporda soyle)'
  kasa_sinav=$kasaSinav
  cikmis_sgs=$cikSay
  konular=$hedefler
}
$rapor | ConvertTo-Json -Depth 5 | Out-File (Join-Path $kok 'veri\zorluk-kiyas.json') -Encoding utf8
''
'======== A) SINAV DUZEYI (yuzde dagilim) ========'
"CIKMIS SGS ($($cikSay.n) soru): Z1 %$([math]::Round(100*$cikSay.z1/[math]::Max(1,$cikSay.n))) | Z2 %$([math]::Round(100*$cikSay.z2/[math]::Max(1,$cikSay.n))) | Z3 %$([math]::Round(100*$cikSay.z3/[math]::Max(1,$cikSay.n)))"
foreach($sk in $kasaSinav.Keys){
  $x=$kasaSinav[$sk]
  "KASA $sk ($($x.n)): Z1 %$([math]::Round(100*$x.z1/$x.n)) | Z2 %$([math]::Round(100*$x.z2/$x.n)) | Z3 %$([math]::Round(100*$x.z3/$x.n))"
}
''
'======== B) HEDEF LISTESI: cikmista SIK + bizde sinav-seviyesi KIT (ilk 25) ========'
$hedefler | ? { $_.cikmisAdet -ge 5 -and $_.z3Oran -lt 20 } | Sort-Object @{e='cikmisAdet';Descending=$true} | Select-Object -First 25 | % {
  "{0,-5} {1,-28} {2,-42} cikmis:{3,3}  kasa:{4,4}  Z3:%{5}" -f $_.sinav,$_.ders.Substring(0,[Math]::Min(28,$_.ders.Length)),$_.konu.Substring(0,[Math]::Min(42,$_.konu.Length)),$_.cikmisAdet,$_.kasaAdet,$_.z3Oran
}
"-> veri/zorluk-kiyas.json"
