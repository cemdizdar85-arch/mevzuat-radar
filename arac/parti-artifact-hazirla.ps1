# ============================================================================
#  PARTİ → ARTIFACT HAZIRLAYICI (02.09.2026 — Cem: "soruları bir yere at")
#  kalip-parti-<etiket>.html tam bir belgedir (<!doctype><html><head><body>).
#  Artifact yayını ise gövdeyi kendi iskeletine sarar; doctype/html/head/body
#  etiketleri GÖNDERİLMEZ. Bu betik <title> + <style> + gövdeyi tek dosyaya
#  çıkarır (sayfanın kendi koyu teması, gömülü JS ve tüm etkileşim korunur).
#  Çıktı: sql-yerel/artifact-<etiket>.html  (yayın dosyası; kasaya yazmaz)
#  KURAL: dış kaynak YOK — sayfa zaten kendi kendine yeter (CSP dostu).
# ============================================================================
param(
  [Parameter(Mandatory=$true)][string]$Etiket,
  [string]$Baslik = ''
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
$kaynak=Join-Path $depoKok "sql-yerel\kalip-parti-$Etiket.html"
if(-not (Test-Path $kaynak)){ throw "kaynak yok: $kaynak" }
$ham=Get-Content $kaynak -Raw -Encoding UTF8

# baslik: parametre > kaynak <title>
$bas=$Baslik
if(-not $bas){
  $mb=[regex]::Match($ham,'(?s)<title>(.*?)</title>')
  if($mb.Success){ $bas=$mb.Groups[1].Value.Trim() }
}
if(-not $bas){ $bas="Kalıp Partisi $Etiket" }

# style bloklari (head icindekiler dahil) ve GOVDE ayri ayri cikarilir
$stiller=@([regex]::Matches($ham,'(?s)<style>.*?</style>') | ForEach-Object { $_.Value })
$mg=[regex]::Match($ham,'(?s)<body[^>]*>(.*?)</body>')
if(-not $mg.Success){ throw 'govde bulunamadi (<body> yok)' }
$govde=$mg.Groups[1].Value

$cikti="<title>$bas</title>`n" + ($stiller -join "`n") + "`n" + $govde
$hedef=Join-Path $depoKok "sql-yerel\artifact-$Etiket.html"
[IO.File]::WriteAllText($hedef,$cikti,[Text.UTF8Encoding]::new($false))

# GERI OKUMA (kural: yaz -> geri oku -> karsilastir)
$geri=Get-Content $hedef -Raw -Encoding UTF8
$yasak=@([regex]::Matches($geri,'(?i)<(!doctype|html|head|body)[ >]') | ForEach-Object { $_.Value })
$soru=([regex]::Matches($geri,"class='soru'")).Count
"hazir: sql-yerel/artifact-$Etiket.html"
"  baslik : $bas"
"  boyut  : $([math]::Round($geri.Length/1KB,1)) KB"
"  soru   : $soru"
"  stil   : $($stiller.Count) blok"
"  yasak etiket (olmamali): $($yasak.Count)"
if($yasak.Count){ throw "iskelet etiketi sizdi: $($yasak -join ', ')" }
if($soru -eq 0){ throw 'govdede soru yok - donusum bozuk' }
