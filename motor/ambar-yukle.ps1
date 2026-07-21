# ============================================================================
#  AMBAR YUKLEYICI (#48) — veri/ambar-kaynaklar.json manifestini Supabase
#  'dokumanlar' tablosuna senkronlar. Motor (net-cevap edge) buradan tam-metin
#  (FTS) arayip alintiyla cevaplar. Kuratorlu icerik = bayat ozelge riski yok.
#  Idempotent: kaynak_ad'a gore var olani GUNCELLER, yoksa EKLER.
#  ENV: SUPABASE_SERVICE_KEY (zorunlu — RLS write yalniz service role).
#  Secret yoksa zarifce atlar (exit 0). GitHub Actions cron (GUNLUK) + manuel.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try { [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance) } catch {}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok — ambar yukleyici atlandi. (GitHub Settings -> Secrets)"; exit 0 }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY" }   # Content-Type POST/PATCH'te -ContentType ile verilir (PGRST102 fix)

# --- manifest ---
$manifestYol = Join-Path $kok "veri\ambar-kaynaklar.json"
if(-not (Test-Path $manifestYol)){ Write-Host "Manifest yok: $manifestYol"; exit 0 }
$belgeler = (Get-Content $manifestYol -Raw -Encoding UTF8 | ConvertFrom-Json).belgeler
if(-not $belgeler){ Write-Host "Manifest bos."; exit 0 }
Write-Host ("Manifest: {0} belge." -f @($belgeler).Count)

# --- IDEMPOTENT: yuklenecek kaynak_ad'lari ONCE sil, sonra hepsini POST et.
#   ESKI BUG: mevcut-kayit kontrolu "select=id,kaynak_ad" ile tum tabloyu cekmeye
#   calisiyordu ama Supabase REST varsayilan 1000 satir donuyor; 13k+ satirlik tabloda
#   bu 14 manifest kaydi ilk 1000'de olmadigindan "yok" sanilip HER GUN yeniden
#   eklendi (6 gunde 6 kopya -> retrieval'i bozdu). delete-first kesin idempotent:
#   kaynak_ad ile eslesen TUM kopyalari siler, ardindan tek kopya ekler.
foreach($b in $belgeler){
  if(-not $b.kaynak_ad){ continue }
  $q = [uri]::EscapeDataString("$($b.kaynak_ad)")
  try { Invoke-RestMethod -Method Delete -Uri "$SB_URL/rest/v1/dokumanlar?kaynak_ad=eq.$q" -Headers $H -TimeoutSec 90 | Out-Null } catch {}
}
$mevcut = @{}   # hepsi silindi -> asagidaki dongu hep POST yapar

function GonderBytes($json){ return [System.Text.Encoding]::UTF8.GetBytes($json) }

$eklenen = 0; $guncellenen = 0; $atlanan = 0
foreach($b in $belgeler){
  if(-not $b.kaynak_ad -or -not $b.metin){ $atlanan++; continue }
  $govde = [ordered]@{
    tur          = "$($b.tur)"
    kaynak_ad    = "$($b.kaynak_ad)"
    baslik       = "$($b.baslik)"
    metin        = "$($b.metin)"
    kaynak_url   = "$($b.kaynak_url)"
    belge_tarihi = $(if($b.belge_tarihi){ "$($b.belge_tarihi)" } else { $null })
  }
  $json = ($govde | ConvertTo-Json -Depth 5 -Compress)
  try {
    if($mevcut.ContainsKey("$($b.kaynak_ad)")){
      # GUNCELLE (PATCH) — kaynak_ad ile
      $q = [uri]::EscapeDataString("$($b.kaynak_ad)")
      $gonder = [System.Text.Encoding]::UTF8.GetBytes($json)
      Invoke-RestMethod -Method Patch -Uri "$SB_URL/rest/v1/dokumanlar?kaynak_ad=eq.$q" -Headers ($H + @{ Prefer = "return=minimal" }) -ContentType "application/json; charset=utf-8" -Body $gonder -TimeoutSec 90 | Out-Null
      $guncellenen++
    } else {
      # EKLE (POST)
      $gonder = [System.Text.Encoding]::UTF8.GetBytes($json)
      Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/dokumanlar" -Headers ($H + @{ Prefer = "return=minimal" }) -ContentType "application/json; charset=utf-8" -Body $gonder -TimeoutSec 90 | Out-Null
      $eklenen++
    }
  } catch {
    Write-Host ("HATA [{0}]: {1}" -f $b.kaynak_ad, $_)
  }
}

Write-Host ("AMBAR SENKRON TAMAM — eklenen={0} guncellenen={1} atlanan={2}" -f $eklenen, $guncellenen, $atlanan)
exit 0
