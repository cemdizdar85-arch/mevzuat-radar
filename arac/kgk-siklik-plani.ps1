#requires -Version 5.1
<#
================================================================================
  KGK SIKLIK PLANI — plan konulari CIKMIS SIKLIGA gore secilir   (17.09.2026)
  Cem "1.2.3 ucunu de yap", 2. madde: "dalga 1'i siklige gore kuralim".

  NEDEN: eldeki dalga 1 plani (veri/sinav/plan-kgk-a1-denetim.json) bes standardi
  ELLE seciyordu; hangi konunun sinavda kac kez ciktigina bakmiyordu. SGS tarafinda
  olculen kural (arac/siklik-plani.ps1 basligi): gecmiste 1 kez cikmis konunun
  tekrar cikma olasiligi %2,6, 7+ kez cikanin %63,2. Bu yuzden:
    - TEK DONEMLIK KONU PLANA GIRMEZ (piyango bileti alinmaz).
    - Konular en cok cikandan baslanarak alinir; standart basina 1 soru = 1 konu
      (ayni konuya birden fazla tur yazilmaz - PARA HARCAYAN SORU BASIMI KURALI 5).

  KAYNAK: veri/siklik-kunyesi-kgk.json (motor/siklik-kunyesi.ps1 -Sinav KGK).
  Konu -> standart eslemesi motor/kalip-parti-uret.ps1'deki DENETIM_STD tablosunun
  AYNISIDIR; uretici kaynak paketini o tabloyla topluyor, plan da ayni tabloyla
  gruplaniyor ki paket ile konu ayni standardi gostersin.

  CIKTI: veri/sinav/konu/<etiket>.json (konu listeleri) + plan dosyasi.
  BEDEL 0 - yalniz yerel dosya okur, soru BASMAZ. Basim ayri komut ve Cem onayi:
    gh workflow run bulut-uretim.yml -f plan=<plan> -f paralel=<n> -f butce_usd=<USD>

  KULLANIM
    powershell -NoProfile -File arac/kgk-siklik-plani.ps1            # olc + goster
    powershell -NoProfile -File arac/kgk-siklik-plani.ps1 -Yaz       # plan + konu dosyalari
================================================================================
#>
param(
  [switch]$Yaz,
  [int]$Hedef = 80,                    # toplam soru adedi (olcum kosusu ~25 USD)
  [int]$EnAzDonem = 2,                 # tek donemlik konu plana girmez
  [string]$Etiket = 'kgk-olcum-tds',
  [string]$PlanYolu = 'veri\sinav\plan-kgk-olcum-tds-siklik.json'
)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here
$kunyeYolu = Join-Path $depoKok 'veri\siklik-kunyesi-kgk.json'
if(-not (Test-Path $kunyeYolu)){ Write-Host 'KOR: veri/siklik-kunyesi-kgk.json yok - once motor/siklik-kunyesi.ps1 -Sinav KGK'; exit 1 }
$kunye = Get-Content $kunyeYolu -Raw -Encoding UTF8 | ConvertFrom-Json

# motor/kalip-parti-uret.ps1 DENETIM_STD ile BIREBIR ayni (kaynak paketi ile plan ayni standardi gostersin)
$DENETIM_STD = @(
  @('iliskili taraf','BDS 550'), @('yonetim beyan','BDS 580'), @('yonetim iddia','BDS 315'), @('ic kontrol','BDS 315'),
  @('planlama','BDS 300'), @('belgelendir','BDS 230'), @('calisma kagit','BDS 230'), @('orneklem','BDS 530'),
  @('onemlilik','BDS 320'), @('kanit','BDS 500'), @('dis teyit|dogrulama','BDS 505'), @('acilis bakiye','BDS 510'),
  @('analitik','BDS 520'), @('tahmin','BDS 540'), @('bilanco sonrasi|sonraki olay','BDS 560'), @('sureklilik','BDS 570'),
  @('gorus|denetci raporu|rapor','BDS 700'), @('sartli|olumsuz|kacinma','BDS 705'), @('hile','BDS 240'),
  @('kalite','KYS 1'), @('denetim risk|tespit edememe|risk','BDS 200'), @('topluluk','BDS 600'), @('ic denetim','BDS 610'),
  @('uzman','BDS 620'), @('denetim sozlesme|sozlesme sart','BDS 210'), @('denetim sureci|bagimsiz denetim sureci','BDS 200')
)
function StandartBul([string]$KonuAdi){
  if($KonuAdi -match '\b(bds|kys|gds)\s*(\d{3,4})'){ return ("{0} {1}" -f $Matches[1].ToUpper(), $Matches[2]) }
  foreach($cift in $DENETIM_STD){ if($KonuAdi -match $cift[0]){ return $cift[1] } }
  return $null
}

$konular = New-Object System.Collections.Generic.List[object]
foreach($p in $kunye.konular.PSObject.Properties){
  $ad = "$($p.Value.ad)"
  if($ad -notlike 'Denetim Standartlari|*'){ continue }
  $d = [int]$p.Value.d
  if($d -lt $EnAzDonem){ continue }
  $metin = ($ad -split '\|',2)[1]
  $std = StandartBul $metin
  if(-not $std){ continue }   # standardi cozulemeyen konu plana girmez (paket yanlis standarda gider)
  $konular.Add([pscustomobject]@{ konu=$metin; donem=$d; soru=[int]$p.Value.s; std=$std })
}
Write-Host ("Kunye: {0} donem · TDS konusu {1} (>= {2} donem, standardi cozulen)" -f $kunye.donem_sayisi, $konular.Count, $EnAzDonem)
if(-not $konular.Count){ Write-Host 'Plana girecek konu yok.'; exit 1 }

# Standartlar toplam donem agirligina gore siralanir; hedefe ulasana kadar alinir.
$gruplar = @($konular | Group-Object std | ForEach-Object {
  [pscustomobject]@{ std=$_.Name; agirlik=[int](($_.Group | Measure-Object donem -Sum).Sum); konular=@($_.Group | Sort-Object donem, soru -Descending) }
} | Sort-Object agirlik -Descending)

$secili = New-Object System.Collections.Generic.List[object]
$toplam = 0
foreach($g in $gruplar){
  if($toplam -ge $Hedef){ break }
  $alinacak = [Math]::Min($g.konular.Count, ($Hedef - $toplam))
  $secili.Add([pscustomobject]@{ std=$g.std; agirlik=$g.agirlik; konular=@($g.konular | Select-Object -First $alinacak) })
  $toplam += $alinacak
}
Write-Host ("Secilen: {0} standart · {1} konu = {2} soru" -f $secili.Count, $toplam, $toplam)
foreach($s in $secili){ Write-Host ("  {0,-9} {1,3} konu · donem agirligi {2,3} · en cok: {3} ({4} donem)" -f $s.std, $s.konular.Count, $s.agirlik, $s.konular[0].konu, $s.konular[0].donem) }
if(-not $Yaz){ Write-Host "`nKURU PROVA - yazmak icin -Yaz"; exit 0 }

# 3'ten az konusu olan standartlar TEK partide birlesir: parti yalnizca toplu cagri
# birimi, kaynak paketi zaten KONU bazinda toplaniyor (DENETIM_STD). 21 satir -> ~10.
$buyuk = @($secili | Where-Object { $_.konular.Count -ge 3 })
$kucuk = @($secili | Where-Object { $_.konular.Count -lt 3 })
if($kucuk.Count){
  $karmaKonu = @($kucuk | ForEach-Object { $_.konular } | Sort-Object donem, soru -Descending)
  $buyuk += [pscustomobject]@{ std='KARMA'; agirlik=[int](($kucuk | Measure-Object agirlik -Sum).Sum); konular=$karmaKonu }
  Write-Host ("  KARMA: {0} standardin {1} konusu tek partide birlestirildi" -f $kucuk.Count, $karmaKonu.Count)
}
$secili = $buyuk

$konuKlasoru = Join-Path $depoKok 'veri\sinav\konu'
[void](New-Item -ItemType Directory -Force $konuKlasoru)
$u8 = New-Object Text.UTF8Encoding($false)
$plan = New-Object System.Collections.Generic.List[object]
foreach($s in $secili){
  $slug = ($s.std -replace '\s+','').ToLowerInvariant()
  # K1: $etiket ile $Etiket AYNI degiskendir (PS harf ayirmaz) - parti adi birikirdi
  $partiEtiket = "$Etiket-$slug"
  $dosya = "veri/sinav/konu/$partiEtiket.json"
  [IO.File]::WriteAllText((Join-Path $depoKok ($dosya -replace '/','\')), [string](ConvertTo-Json -InputObject @($s.konular | ForEach-Object { $_.konu }) -Depth 3), $u8)
  $plan.Add([ordered]@{ ders='Türkiye Denetim Standartları'; dersAd='b) Türkiye Denetim Standartları'; etiket=$partiEtiket; adet=$s.konular.Count; sinav='KGK'; konuDosya=$dosya; toplu=$true; disla='' })
}
# K3: @(List) + -InputObject ArgumentException atar -> ToArray()
$planJson = [string](ConvertTo-Json -InputObject $plan.ToArray() -Depth 4)
[IO.File]::WriteAllText((Join-Path $depoKok $PlanYolu), $planJson, $u8)
Write-Host ("`n-> {0} ({1} satir / {2} soru)" -f $PlanYolu, $plan.Count, $toplam)
Write-Host "Basim AYRI komut + Cem onayi: gh workflow run bulut-uretim.yml -f plan=$($PlanYolu -replace '\\','/') -f paralel=4 -f butce_usd=25"
