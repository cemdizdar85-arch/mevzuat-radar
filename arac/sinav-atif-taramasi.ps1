#requires -Version 5.1
<#
================================================================================
  SINAV ATIF TARAMASI — çıkmış sınav metninden mevzuat atıfı çıkarır,
  RAG ambarıyla çarpıştırır  (10.09.2026)

  NEDEN BU ARAÇ: önceki eksik denetimi `ders-profili.json`'u okuyordu — 54
  dersin 24'ünü kapsıyor ve içeriği elle derlenmiş bir liste. Bu araç kaynağı
  SINAVIN KENDİSİNE çeviriyor: ambardaki çıkmış sınav parçalarından atıfları
  doğrudan çıkarır. "Müfredatta ne gerekiyor" sorusu tahminle değil SAYIMLA
  cevaplanır.

  ÜÇ KİMLİK DESENİ (ad karşılaştırması YAPILMAZ — üç kez denendi, üçü de
  yanlış cevap verdi; bkz. dayanak-ad-koprusu):
    kanun     : "<no> sayılı"          -> 6102, 213, 3568
    standart  : "BDS/TMS/TFRS/KKS <no>" -> TMS 16, BDS 315
    tebliğ    : "Seri: <roma>, No: <no>"

  KARA LİSTE: `veri/YUTULMAYACAK-MEVZUAT.md` içindeki `KARA:` satırları okunur.
  Oradaki bir kalem "ambarda yok" çıkarsa EKSİK değil KARA-LİSTE sayılır —
  mülga/süresi dolmuş mevzuat eksik değildir, bilerek yutulmamıştır.
  ⚠️ Kimlik dosyada AÇIKÇA yazar, metinden tahmin EDİLMEZ: 10.09'da regex
  denemesi "Halefi" sütunundaki TFRS 15/16'yı da yakalayıp kara listeye aldı.

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/sinav-atif-taramasi.ps1
================================================================================
#>
param(
  [int]$EnAzAtif = 3,
  [string]$Hedef = 'veri\sinav-atif-taramasi.json'
)
$ErrorActionPreference = 'Stop'
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here
$motor   = Join-Path $depoKok 'rag-motor\motor.ps1'

function Katla([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
        -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
        -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}

# --- KARA LISTE (acik isaretli satirlardan) ---------------------------------
$KARA = New-Object System.Collections.Generic.HashSet[string]
$karaYol = Join-Path $depoKok 'veri\YUTULMAYACAK-MEVZUAT.md'
if(Test-Path $karaYol){
  foreach($m in [regex]::Matches((Get-Content $karaYol -Raw -Encoding UTF8), '(?m)^\s*KARA:\s*(.+?)\s*$')){
    [void]$KARA.Add((Katla $m.Groups[1].Value))
  }
}
Write-Host ("kara liste: {0} kalem  ({1})" -f $KARA.Count, (($KARA | Sort-Object) -join ', ')) -ForegroundColor DarkYellow

function MotorOlc([string]$sql){
  $ham = & $motor olc $sql 2>&1
  $out = New-Object System.Collections.ArrayList
  foreach($s in $ham){
    $t = "$s"
    if($t -match '^\s*(info|CANLI)' -or -not $t.Trim()){ continue }
    [void]$out.Add($t)
  }
  return $out
}

# --- 1) KANUN ATIFLARI ------------------------------------------------------
Write-Host "`n== KANUN ATIFLARI ==" -ForegroundColor Cyan
$kanunSql = @"
with sinav as (
  select p.metin from rag.parca p join rag.kaynak k on k.id=p.kaynak_id where k.tur='cikmis-sinav'
),
atif as (select trim(m[1]) as no from sinav, lateral regexp_matches(metin, '(\d{3,5})\s*say[ıi]l[ıi]', 'g') as m)
select no, count(*) as atif,
       coalesce((select string_agg(distinct k.kod, ', ') from rag.kaynak k
                  where k.tur <> 'cikmis-sinav' and (k.ad like '%'||no||'%' or k.kod like '%'||no||'%')), '-') as ambarda
from atif group by no having count(*) >= $EnAzAtif order by count(*) desc
"@
$kanunSat = MotorOlc $kanunSql

# --- 2) STANDART ATIFLARI ---------------------------------------------------
Write-Host "== STANDART ATIFLARI ==" -ForegroundColor Cyan
$stdSql = @"
with sinav as (
  select p.metin from rag.parca p join rag.kaynak k on k.id=p.kaynak_id where k.tur='cikmis-sinav'
),
atif as (select upper(trim(m[1])) || ' ' || trim(m[2]) as std
         from sinav, lateral regexp_matches(metin, '\m(BDS|TMS|TFRS|KKS)\s*[-]?\s*(\d{1,3})\M', 'gi') as m)
select std, count(*) as atif,
       coalesce((select string_agg(distinct k.kod, ', ') from rag.kaynak k
                  where k.tur <> 'cikmis-sinav'
                    and (rag.katla(k.ad) like '%'||rag.katla(std)||'%'
                      or rag.katla(k.kod) like '%'||replace(rag.katla(std),' ','')||'%')), '-') as ambarda
from atif group by std having count(*) >= $EnAzAtif order by count(*) desc
"@
$stdSat = MotorOlc $stdSql

# --- 3) KOVALAMA ------------------------------------------------------------
$kayit = New-Object System.Collections.ArrayList
function Isle($satirlar, [string]$tur){
  foreach($s in $satirlar){
    $p = "$s" -split "`t"
    if($p.Count -lt 3){ continue }
    $kimlik = $p[0].Trim(); if($kimlik -eq 'no' -or $kimlik -eq 'std'){ continue }
    $atif = 0; [void][int]::TryParse($p[1].Trim(), [ref]$atif)
    $ambarda = $p[2].Trim()
    $durum = if($ambarda -and $ambarda -ne '-'){ 'VAR' }
             elseif($KARA.Contains((Katla $kimlik))){ 'KARA-LISTE' }
             else { 'EKSIK' }
    [void]$kayit.Add([pscustomobject]@{ tur=$tur; kimlik=$kimlik; atif=$atif; ambarda=$ambarda; durum=$durum })
  }
}
Isle $kanunSat 'kanun'
Isle $stdSat  'standart'

$var   = @($kayit | Where-Object { $_.durum -eq 'VAR' })
$eksik = @($kayit | Where-Object { $_.durum -eq 'EKSIK' })
$kara  = @($kayit | Where-Object { $_.durum -eq 'KARA-LISTE' })

Write-Host ""
Write-Host ("TARANAN ATIF KALEMI : {0}  (>= {1} atif)" -f $kayit.Count, $EnAzAtif)
Write-Host ("  VAR        {0,4}" -f $var.Count)   -ForegroundColor Green
Write-Host ("  KARA-LISTE {0,4}   <- bilerek yutulmadi" -f $kara.Count) -ForegroundColor DarkYellow
Write-Host ("  EKSIK      {0,4}   <- YUTULACAK" -f $eksik.Count) -ForegroundColor $(if($eksik.Count){'Red'}else{'Green'})
if($eksik.Count){
  Write-Host "`n=== YUTULACAKLAR ===" -ForegroundColor Red
  $eksik | Sort-Object atif -Descending | ForEach-Object { Write-Host ("  {0,4} atif · [{1}] {2}" -f $_.atif,$_.tur,$_.kimlik) }
}
if($kara.Count){
  Write-Host "`n(kara liste - yutulmayacak):" -ForegroundColor DarkYellow
  $kara | Sort-Object atif -Descending | ForEach-Object { Write-Host ("  {0,4} atif · {1}" -f $_.atif,$_.kimlik) }
}

$rapor = [ordered]@{
  olcum  = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  kaynak = 'rag.parca (tur=cikmis-sinav) icindeki mevzuat atiflari x rag.kaynak'
  kural  = 'Kimlik ile eslesme (kanun no / standart kodu). Kara listedeki kalem EKSIK sayilmaz.'
  esik   = $EnAzAtif
  var = $var.Count; kara_liste = $kara.Count; eksik = $eksik.Count
  kayitlar = @($kayit | Sort-Object @{e='durum'},@{e='atif';Descending=$true})
}
. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok $Hedef) -Nesne $rapor
Write-Host ("`n-> {0}" -f $Hedef)
