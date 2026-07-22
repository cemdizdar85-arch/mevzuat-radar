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
if(-not (Test-Path $onayYol)){ Write-Host "onay dosyasi yok."; exit 0 }
$onay = Get-Content $onayYol -Raw -Encoding UTF8 | ConvertFrom-Json

$paket = @($onay.sorular | Where-Object { $_.durum -eq 'paket-havuzu' })
if($paket.Count -eq 0){ Write-Host "Tasinacak paket sorusu yok."; exit 0 }
Write-Host ("Tasinacak: {0} soru" -f $paket.Count)

$govde = @($paket | ForEach-Object {
  [ordered]@{
    id=$_.id; sinav="$($_.sinav)"; ders="$($_.ders)"; konu="$($_.konu)"; soru="$($_.soru)"
    siklar=$_.siklar; dogru="$($_.dogru)"; aciklama=$_.aciklama
    kaynak="$($_.kaynak)"; hap="$($_.hap)"; onay="$($_.onay)"; uretim="$($_.uretim)"
  }
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
$onay.sorular = @($onay.sorular | Where-Object { $_.durum -ne 'paket-havuzu' })
$onay.guncelleme = (Get-Date -Format "dd.MM.yyyy HH:mm")
[IO.File]::WriteAllText($onayYol, ($onay | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
Write-Host ("TAMAM: {0} soru kilitli havuza tasindi, depodan cikarildi." -f $paket.Count)
exit 0
