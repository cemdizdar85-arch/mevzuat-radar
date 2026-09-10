#requires -Version 5.1
<#
================================================================================
  RAG TAM HAT — mevzuat + çıkmış sınav + gömme, tek zincir (10.09.2026)

  Cem: "BAŞLAT SIRAYLA HEPSİNİ" / "YUTMA BİTİNCE GÖMMEYE BAŞLA"

  ADIMLAR (sırayla, biri düşerse sonrakine GEÇİLMEZ):
    1) Mevzuat yutma   : veri/mevzuat/*.json  -> rag.parca
    2) Sınav dışa aktar: Supabase -> _yerel-veri-kasasi/cikmis-sinav/*.json
    3) Sınav yutma     : o klasör -> rag.parca (tur = cikmis-sinav)
    4) GÖMME           : vektörü eksik BÜTÜN parçalar, tek koşuda

  NEDEN GÖMME EN SONDA: her yutmadan sonra gömme çağırmak yığın verimini
  öldürür — 64'lük yığın yerine 3'lük yığın atılır, aynı iş kat kat uzun sürer
  ve dakikalık kotayı boşa yer. Önce ambar dolar, sonra TEK koşu bütün
  boşlukları kapatır.

  IDEMPOTENT: her adım kendi mükerrer frenine sahip. Yarıda kesilirse aynı
  komut kaldığı yerden devam eder — yeniden yazılan parça yok, ikinci kez
  ödenen gömme yok. Korkusuzca yeniden koşulabilir.

  KULLANIM
    powershell -NoProfile -File rag-motor/tam-hat.ps1
    powershell -NoProfile -File rag-motor/tam-hat.ps1 -Atla 1,2   # 1. ve 2. adımı atla
================================================================================
#>
param(
  [int[]]$Atla = @(),
  [int]$SinavTavan = 700
)

$ErrorActionPreference = 'Stop'
$motorKok = $PSScriptRoot
$depoKok  = Split-Path -Parent $motorKok
$kasa     = Join-Path (Split-Path -Parent $depoKok) '_yerel-veri-kasasi\cikmis-sinav'
$motor    = Join-Path $motorKok 'motor.ps1'

function Adim([int]$no, [string]$ad, [scriptblock]$is) {
  if ($Atla -contains $no) { Write-Host "[$no] ATLANDI - $ad" -ForegroundColor DarkGray; return }
  Write-Host ""
  Write-Host ("=" * 70) -ForegroundColor Cyan
  Write-Host ("[{0}] {1}   ({2})" -f $no, $ad, (Get-Date -Format 'HH:mm:ss')) -ForegroundColor Cyan
  Write-Host ("=" * 70) -ForegroundColor Cyan
  $bas = Get-Date
  & $is
  if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
    throw "ADIM $no DUSTU (cikis kodu $LASTEXITCODE) - zincir DURDURULDU. Sonraki adimlara gecilmedi."
  }
  Write-Host ("[{0}] BITTI - {1:N1} dakika" -f $no, ((Get-Date) - $bas).TotalMinutes) -ForegroundColor Green
}

function Nabiz([string]$etiket) {
  & $motor olc "select (select count(*) from rag.kaynak) as kaynak, (select count(*) from rag.parca) as parca, (select count(*) from rag.parca_vektor) as vektor, (select count(*) from rag.parca p where not exists (select 1 from rag.parca_vektor v where v.parca_id=p.id)) as vektorsuz" 2>&1 |
    Select-String -Pattern '^\s*\d+\s' | ForEach-Object { Write-Host "  NABIZ $etiket -> $($_.Line.Trim())" -ForegroundColor Yellow }
}

Write-Host "RAG TAM HAT basliyor" -ForegroundColor White
Nabiz 'baslangic'

Adim 1 'MEVZUAT YUTMA (veri/mevzuat/*.json)' {
  & $motor yutdizin (Join-Path $depoKok 'veri\mevzuat') |
    Select-String -Pattern 'TOPLU YUTMA|ATLANDI|PARCA CIKMADI'
}
Nabiz 'mevzuat sonrasi'

Adim 2 'CIKMIS SINAV DISA AKTAR (Supabase -> yerel kasa)' {
  & powershell -NoProfile -File (Join-Path $depoKok 'arac\cikmis-sinav-disaver.ps1') -Tavan $SinavTavan |
    Select-String -Pattern 'YAZILDI|SGS|KGK|SMMM|!'
}

Adim 3 'CIKMIS SINAV YUTMA (tur = cikmis-sinav)' {
  if (-not (Test-Path $kasa)) { throw "Sinav kasasi yok: $kasa" }
  & $motor yutdizin $kasa | Select-String -Pattern 'TOPLU YUTMA|ATLANDI'
}
Nabiz 'sinav sonrasi'

Adim 4 'GOMME (vektoru eksik BUTUN parcalar)' {
  & $motor gomme | Select-String -Pattern 'BAKIM|Gomme: .*000|TAMAMLANAMADI|HATA'
}
Nabiz 'BITIS'

Write-Host ""
Write-Host "TAM HAT BITTI." -ForegroundColor Green
Write-Host "Siradaki: konu kartlari (rag.kart_sagligi) ve arama karnesi." -ForegroundColor Green
