# ============================================================================
#  ALACAK ARSIVI -> SUPABASE  (19.08.2026, Cem: "bilgiler gizli olsun")
#
#  NIYE: 5.728 ilanlik arsiv depoda ACIK JSON olarak duruyordu; borclu adi,
#  VKN ve 1.657 TCKN tek tikla indirilebiliyordu. Arsiv artik yalniz Supabase'de
#  durur; disariya sadece RPC'lerden (alacak_ara / alacak_toplu / alacak_vitrin)
#  ve TAVANLI olarak cikar. Bu betik yazma ucudur.
#
#  KULLANIM
#    ilk tam yukleme :  $env:HEDEF='veri\alacak-arsiv.json'; ./motor/alacak-supabase-yukle.ps1
#    gunluk (robot)  :  ./motor/alacak-supabase-yukle.ps1        (canli dosyayi basar)
#
#  Anahtar: SUPABASE_SERVICE_KEY (User-env'de ya da Actions secret). YOKSA betik
#  "atlandi" der ve 0 ile cikar - kor kalmamak icin sebebi ekrana yazar.
#  Zenginlestirme koruma alacak_yaz() icinde (coalesce): bos borclu/VKN eskisini
#  SILMEZ, o yuzden gunluk kismi yukleme guvenlidir.
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

$SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co'
$anahtar = "$($env:SUPABASE_SERVICE_KEY)".Trim()
if (-not $anahtar) {
  Write-Host 'ATLANDI: SUPABASE_SERVICE_KEY yok - arsiv Supabase-e yazilmadi.'
  Write-Host '         Yerelde: anahtar-kur.cmd  |  Actions: repo Secrets -> SUPABASE_SERVICE_KEY'
  exit 0
}

$hedef = if ("$($env:HEDEF)".Trim()) { Join-Path $kok $env:HEDEF } else { Join-Path $kok 'veri\alacak-ilan-canli.json' }
if (-not (Test-Path $hedef)) { Write-Host "kaynak dosya yok: $hedef"; exit 0 }

$veri = Get-Content $hedef -Raw -Encoding UTF8 | ConvertFrom-Json
$kayitlar = @($veri.ilanlar)
if (-not $kayitlar.Count) { Write-Host 'kaynakta ilan yok - cikiliyor'; exit 0 }
Write-Host ("KAYNAK: {0} ({1} ilan)" -f (Split-Path $hedef -Leaf), $kayitlar.Count)

$basliklar = @{
  'apikey'        = $anahtar
  'Authorization' = "Bearer $anahtar"
  'Content-Type'  = 'application/json'
  'Accept'        = 'application/json'
  'User-Agent'    = 'MevzuatRadar-AlacakYukleyici'
}

function RpcCagir([string]$ad, $govde) {
  $json = $govde | ConvertTo-Json -Depth 8 -Compress
  Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/rpc/$ad" `
    -Headers $basliklar -Body ([System.Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 180
}

# --- YAZ (parti parti; 5.728 kaydi tek istekte gondermek zaman asimina girer) --
$PARTI = 400
$yazilan = 0
for ($i = 0; $i -lt $kayitlar.Count; $i += $PARTI) {
  $son   = [Math]::Min($i + $PARTI - 1, $kayitlar.Count - 1)
  $parca = @($kayitlar[$i..$son] | ForEach-Object {
    [ordered]@{
      ilanNo = "$($_.ilanNo)"; baslik = "$($_.baslik)"; kurum = "$($_.kurum)"
      il     = "$($_.il)";     ilce   = "$($_.ilce)";   tarih = "$($_.tarih)"
      tur    = "$($_.tur)";    url    = "$($_.url)"
      borclu = "$($_.borclu)"; vkn    = "$($_.vkn)";    tckn  = "$($_.tckn)"
      # 20.08: metin + ilanin kendisinde yazan alanlar (alacak-metin-ayristir.js).
      # SQL kolonlari yoksa alacak_yaz bunlari sessizce yok sayar — once
      # radar-app/sql/2026-08-20-alacak-metin-alanlari.sql kosulmali.
      metin      = "$($_.metin)";      esas_no    = "$($_.esas_no)"
      sicil_no   = "$($_.sicil_no)";   mahkeme    = "$($_.mahkeme)"
      muhlet_tip = "$($_.muhlet_tip)"; muhlet_ay  = "$($_.muhlet_ay)"
      muhlet_baslangic = "$($_.muhlet_baslangic)"
      muhlet_bitis     = "$($_.muhlet_bitis)"
      komiser    = "$($_.komiser)";    itiraz_gun = "$($_.itiraz_gun)"
      karar_durumu = "$($_.karar_durumu)"
      borclular  = @($_.borclular);    vknler     = @($_.vknler)
      tcknler    = @($_.tcknler)
    }
  })
  try {
    $n = RpcCagir 'alacak_yaz' @{ p_kayitlar = $parca }
    $yazilan += [int]"$n"
    Write-Host ("  parti {0,5}-{1,-5} -> {2} satir" -f ($i+1), ($son+1), $n)
  } catch {
    Write-Host ("  PARTI HATASI {0}-{1}: {2}" -f ($i+1), ($son+1), $_.Exception.Message)
    throw
  }
  Start-Sleep -Milliseconds 120
}

# --- GERI OKU (yaz -> geri oku -> karsilastir) --------------------------------
$ozet = RpcCagir 'alacak_sayi' @{}
Write-Host ''
Write-Host ("YAZILAN : {0} satir" -f $yazilan)
Write-Host ("KASADA  : {0} ilan - borclulu {1} - kimlikli (VKN/TCKN) {2}" -f $ozet.adet, $ozet.borclulu, $ozet.kimlikli)
if ([int]$ozet.adet -lt $kayitlar.Count) {
  throw ("KAYIP: kaynakta {0} ilan var, kasada {1} gorunuyor" -f $kayitlar.Count, $ozet.adet)
}
Write-Host 'TAMAM: arsiv kasada, depoda acik kopya yok.'
