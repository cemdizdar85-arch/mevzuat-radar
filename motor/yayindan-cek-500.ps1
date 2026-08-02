# ============================================================================
#  YAYINDAN CEKICI (500-OKUMA) — 02.08.2026
#
#  NEDEN: 31.07'deki yayindan-cek.ps1 yalniz HAKEM destegi olmayanlari cekti.
#  500-okumanin 11 KESIN YANLIS + riskli sorulari hakemden 'destek=evet'
#  aldigi icin AGDA KALMADI - yayinda kaldilar (Cem yakaladi: "sitede hala
#  gorunuyor"). Bu script insan-okumasinin hukmunu uygular:
#    1) KESIN YANLIS sira'lari (11 soru)
#    2) RISKLI sira'lari (defterde acik hukumlu 12 satir)
#    3) TTK 482/iskat kumesi KASA CAPINDA (uretici m.482'de sistematik
#       "ihtar gerekmez" hatasi - defter: "tum 482 sorulari yayin disi")
#  yayin=false + yayin_notu yazar, GERI OKUYUP dogrular, rapor birakir.
#
#  SORU SILINMEZ - yalniz yayindan iner; onarim + hakem + okundu-onay
#  sonrasi tekrar degerlendirilir. Actions'ta pwsh ile kosar (PATCH 5.1'de yok).
#  NOT: Defter sayaci riskli 16 diyor, acik hukumlu satir 12 - kalan 4
#  geriye-donuk cevrilen hukumlerde; ikinci geciste taranacak (raporda not).
# ============================================================================
param([switch]$yaz)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$raporYol = Join-Path $kok 'veri/yayindan-cek-500.json'

trap {
  $g = ""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g = $_.ErrorDetails.Message }
  [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber
  }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("HATA (satir {0}): {1} | sunucu: {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g)
  exit 1
}

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - atlandi."; exit 0 }
$H = @{ apikey = $KEY }
if($KEY -like 'eyJ*'){ $H.Authorization = "Bearer $KEY" }

# --- 500-okuma defterinden sira -> kasa id haritasi ---
$defter = Get-Content (Join-Path $kok 'veri/denetim-500.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$KESIN  = @(12,15,38,41,42,88,118,125,169,230,498)
$RISKLI = @(46,84,86,108,128,149,152,163,198,316,336,430)
$hedef = @{}   # id -> sebep
foreach($k in $defter.kayitlar){
  if($KESIN  -contains [int]$k.sira){ $hedef["$($k.id)"] = "kesin-yanlis (Q$($k.sira))" }
  elseif($RISKLI -contains [int]$k.sira){ $hedef["$($k.id)"] = "riskli (Q$($k.sira))" }
}
Write-Host ("Defterden cozulen kimlik: {0} (kesin {1} + riskli {2} beklenir)" -f $hedef.Count, $KESIN.Count, $RISKLI.Count)

# --- TTK 482/iskat kumesi: kasa capinda (500 orneklemi disindakiler dahil) ---
$k482 = @(Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id,kaynak&kaynak=ilike.*482*&limit=500" -Headers $H -TimeoutSec 60)
$kume482 = @($k482 | Where-Object { "$($_.kaynak)" -match '(TTK|6102)' -and "$($_.kaynak)" -match '\b482\b' })
foreach($s in $kume482){ if(-not $hedef.ContainsKey("$($s.id)")){ $hedef["$($s.id)"] = "ttk482-kumesi" } }
Write-Host ("TTK 482 kumesi (kasa capinda): {0} soru" -f $kume482.Count)

# --- mevcut durum: kaci su an yayinda? ---
$idler = @($hedef.Keys)
$yayinda = @()
for($b = 0; $b -lt $idler.Count; $b += 50){
  $parca = $idler[$b..([Math]::Min($b+49, $idler.Count-1))]
  $liste = ($parca | ForEach-Object { '"' + $_ + '"' }) -join ','
  $yayinda += @(Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id&yayin=eq.true&id=in.($liste)" -Headers $H -TimeoutSec 60)
}
Write-Host ("Hedef {0} sorudan su an YAYINDA: {1}" -f $idler.Count, $yayinda.Count)

if(-not $yaz){
  [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='OLCUM'; mod='olcum'
    hedef_toplam=$idler.Count; su_an_yayinda=$yayinda.Count
    kesin=$KESIN.Count; riskli_acik_hukum=$RISKLI.Count; ttk482=$kume482.Count
    not='Cekme icin -yaz ile kosulmali.'
  }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
  Write-Host "OLCUM modu - hicbir sey yazilmadi. Rapor: veri/yayindan-cek-500.json"
  exit 0
}

# --- UYGULA: yayin=false + sebepli not (idempotent) ---
$cekilen = 0
foreach($grup in ($hedef.GetEnumerator() | Group-Object Value)){
  $gidler = @($grup.Group | ForEach-Object { $_.Key })
  for($b = 0; $b -lt $gidler.Count; $b += 50){
    $parca = $gidler[$b..([Math]::Min($b+49, $gidler.Count-1))]
    $liste = ($parca | ForEach-Object { '"' + $_ + '"' }) -join ','
    $govde = ConvertTo-Json -InputObject @{ yayin = $false; yayin_notu = "500-okuma yayindan cekme: $($grup.Name) - onarim+hakem+okundu-onay sonrasi degerlendirilir (02.08.2026)" } -Compress
    Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?id=in.($liste)" -Method Patch -Headers ($H + @{ 'Content-Type'='application/json'; Prefer='return=minimal' }) -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 60 | Out-Null
    $cekilen += $parca.Count
  }
}

# --- GERI OKUMA: hedeflerden hala yayinda kalan var mi? 0 olmali ---
$kalan = @()
for($b = 0; $b -lt $idler.Count; $b += 50){
  $parca = $idler[$b..([Math]::Min($b+49, $idler.Count-1))]
  $liste = ($parca | ForEach-Object { '"' + $_ + '"' }) -join ','
  $kalan += @(Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id&yayin=eq.true&id=in.($liste)" -Headers $H -TimeoutSec 60)
}

[IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$(if($kalan.Count -eq 0){'TAMAM'}else{'KIRMIZI'})
  hedef_toplam=$idler.Count; islenen=$cekilen; oncesinde_yayinda=$yayinda.Count
  geri_okuma_hala_yayinda=$kalan.Count
  kesin=$KESIN.Count; riskli_acik_hukum=$RISKLI.Count; ttk482=$kume482.Count
  eksik_riskli_notu='Defter sayaci riskli 16, acik hukumlu satir 12 - kalan 4 ikinci geciste.'
}) -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host ("CEKME BITTI: islenen {0}, geri-okumada hala yayinda {1} (0 olmali)" -f $cekilen, $kalan.Count)
if($kalan.Count -gt 0){ exit 1 }
