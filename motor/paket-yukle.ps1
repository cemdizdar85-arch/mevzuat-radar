# ============================================================================
#  PAKET HAVUZU TASIYICI — onay dosyasindaki durum='paket-havuzu' sorulari
#  Supabase 'soru_havuzu' tablosuna (kilitli; yalniz uye okur) tasir ve
#  PUBLIC depodan SILER. Parali icerik depoda tutulmaz — sizinti vektoru.
#  Idempotent: upsert (ayni id tekrar yuklenirse gunceller).
#  ENV: SUPABASE_SERVICE_KEY zorunlu. Yoksa zarifce atlar (exit 0).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - tasiyici atlandi."; exit 0 }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY"; Prefer = "resolution=merge-duplicates,return=minimal" }

$onayYol = Join-Path $kok "veri/soru-bankasi-onay.json"
$onay = if(Test-Path $onayYol){ Get-Content $onayYol -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }

# 23.07: fabrika/el-partisi kanali da tuketilir — veri/fabrika/*.json icindeki
# durum='paket-havuzu' (GM onay damgali) sorular ayni sekilde kasaya tasinir,
# tuketilen soru dosyadan cikarilir, sorusu kalmayan dosya SILINIR.
$fabrikaDir = Join-Path $kok "veri/fabrika"
$fabrikaDosyalari = @(); if(Test-Path $fabrikaDir){ $fabrikaDosyalari = @(Get-ChildItem $fabrikaDir -Filter *.json) }

$paket = @()
if($onay){ $paket += @($onay.sorular | Where-Object { $_.durum -eq 'paket-havuzu' }) }
$fabrikaIcerik = @{}
foreach($fd in $fabrikaDosyalari){
  try {
    $ic = Get-Content $fd.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $fabrikaIcerik[$fd.FullName] = $ic
    $paket += @($ic.sorular | Where-Object { $_.durum -eq 'paket-havuzu' })
  } catch { Write-Host ("UYARI: {0} okunamadi, atlandi" -f $fd.Name) }
}
if($paket.Count -eq 0){ Write-Host "Tasinacak paket sorusu yok."; exit 0 }
Write-Host ("Tasinacak: {0} soru" -f $paket.Count)

# 23.07 sigortasi: yevmiye (gorsel T-cetveli verisi) tabloda kolon ister.
# Kolon yoksa VE tasinacak sorularda yevmiye varsa TASIMA DURUR (veri kaybi yasak);
# once radar-app/sql/2026-07-23-soru-havuzu.sql'deki ALTER calistirilmali.
$yevmiyeKolonu = $true
try { Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=yevmiye&limit=1" -Headers @{ apikey=$KEY; Authorization="Bearer $KEY" } -TimeoutSec 30 | Out-Null }
catch { $yevmiyeKolonu = $false }
$yevmiyeliVar = @($paket | Where-Object { $_.yevmiye -and @($_.yevmiye).Count -gt 0 }).Count -gt 0
if($yevmiyeliVar -and -not $yevmiyeKolonu){
  Write-Host "HATA: sorularda yevmiye verisi var ama tabloda 'yevmiye' kolonu yok - kayip olmasin diye tasima DURDU."
  Write-Host "COZUM: SQL Editor'de calistir: alter table soru_havuzu add column if not exists yevmiye jsonb;"
  exit 1
}
# 24.07 (Cem/UWorld exhibit fikri): tablo alani (mini gelir tablosu/bilanco gorseli) — ayni sigorta.
$tabloKolonu = $true
try { Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=tablo&limit=1" -Headers @{ apikey=$KEY; Authorization="Bearer $KEY" } -TimeoutSec 30 | Out-Null }
catch { $tabloKolonu = $false }
$tabloluVar = @($paket | Where-Object { $_.tablo }).Count -gt 0
if($tabloluVar -and -not $tabloKolonu){
  Write-Host "HATA: sorularda tablo (gorsel) verisi var ama tabloda 'tablo' kolonu yok - tasima DURDU."
  Write-Host "COZUM: SQL Editor'de calistir: alter table soru_havuzu add column if not exists tablo jsonb;"
  exit 1
}

$govde = @($paket | ForEach-Object {
  $satir = [ordered]@{
    id=$_.id; sinav="$($_.sinav)"; ders="$($_.ders)"; konu="$($_.konu)"; soru="$($_.soru)"
    siklar=$_.siklar; dogru="$($_.dogru)"; aciklama=$_.aciklama
    kaynak="$($_.kaynak)"; hap="$($_.hap)"; onay="$($_.onay)"; uretim="$($_.uretim)"
  }
  if($yevmiyeKolonu){ $satir['yevmiye'] = $_.yevmiye }
  if($tabloKolonu){ $satir['tablo'] = $_.tablo }
  $satir
})
$json = ConvertTo-Json -InputObject $govde -Depth 6
$gonder = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/soru_havuzu" -Headers $H `
  -ContentType "application/json; charset=utf-8" -Body $gonder -TimeoutSec 120 | Out-Null
Write-Host "Supabase'e yuklendi."

# dogrulama: yuklenen id'ler tabloda gercekten var mi (silmeden ONCE kontrol)
$idListe = ($paket | ForEach-Object { $_.id }) -join ','
$kontrol = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?id=in.($idListe)&select=id" `
  -Headers @{ apikey=$KEY; Authorization="Bearer $KEY" } -TimeoutSec 60
if(@($kontrol).Count -ne $paket.Count){
  Write-Host ("HATA: dogrulama tutmadi ({0}/{1}) - depo dosyasina DOKUNULMADI." -f @($kontrol).Count, $paket.Count)
  exit 1
}
Write-Host ("Dogrulandi: {0}/{1} kayit tabloda." -f @($kontrol).Count, $paket.Count)

# ancak dogrulama sonrasi depodan temizle
if($onay){
  $onay.sorular = @($onay.sorular | Where-Object { $_.durum -ne 'paket-havuzu' })
  $onay.guncelleme = (Get-Date -Format "dd.MM.yyyy HH:mm")
  [IO.File]::WriteAllText($onayYol, ($onay | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
}
foreach($fdYol in $fabrikaIcerik.Keys){
  $ic = $fabrikaIcerik[$fdYol]
  $kalan = @($ic.sorular | Where-Object { $_.durum -ne 'paket-havuzu' })
  if($kalan.Count -eq 0){
    Remove-Item $fdYol -Force
    Write-Host ("  {0}: tum sorular tasindi, dosya silindi" -f (Split-Path $fdYol -Leaf))
  } else {
    $ic.sorular = $kalan
    [IO.File]::WriteAllText($fdYol, ($ic | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
    Write-Host ("  {0}: {1} soru kaldi (paket olmayanlar)" -f (Split-Path $fdYol -Leaf), $kalan.Count)
  }
}
Write-Host ("TAMAM: {0} soru kilitli havuza tasindi, depodan cikarildi." -f $paket.Count)
exit 0
