# ============================================================================
#  MULGA-DAYANAK CEKICI - 19.08.2026 (Cem: "10 mulga-dayanakli soruyu ayikla")
#
#  NEDEN: 09.08 olcumu kasada MULGA mevzuata dayanan 10 soru buldu
#  (TMS 17 -> 8, TMS 18 -> 1, eski TTK 6762 -> 1). "En gunceliz" iddiasinin
#  on kosulu: yururlukten kalkmis metne dayanan soru agda durmaz.
#  Halefler ambarda TAM: TMS 17 -> TFRS 16, TMS 18 -> TFRS 15, 6762 -> 6102.
#
#  IKI ASAMA (hesap-kodu dersi: toptan duzeltme yasak, once oku):
#   varsayilan  = OLCUM: adaylari bulur, id+ders+kaynak metaverisini rapora
#                 yazar, HICBIR SEY DEGISTIRMEZ. GM raporu okur.
#   -yaz        = CEKME: yayin=false + gerekceli yayin_notu, GERI OKUYUP
#                 dogrular. SORU SILINMEZ; guncel halefiyle yeniden yazilinca
#                 hakem+GM sonrasi geri acilabilir.
#
#  Rapora soru METNI YAZILMAZ (parali icerik public depoya girmez) - yalniz
#  id/ders/kaynak-atfi metaverisi.
#  Actions'ta pwsh ile kosar (PATCH 5.1'de yok). PARA HARCAMAZ.
# ============================================================================
param([switch]$yaz)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$raporYol = Join-Path $kok 'veri/mulga-cek-sonuc.json'

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

function Getir([string]$uri){
  $r = Invoke-RestMethod -Uri $uri -Headers $H -TimeoutSec 60
  return @($r | Where-Object { $null -ne $_ })
}

# --- ADAY TOPLAMA: kaba ilike ile genis cek, KESIN regex ile daralt --------
# Kaba desen kasitli genis (TMS*17 "TMS 17x"i de yakalar); kesin karar
# istemci tarafinda kelime-sinirli regexle verilir. TMS 170+ yoktur ama
# guvenlik icin sinir konur.
$MULGA = @(
  @{ ad='TMS 17 (mulga -> TFRS 16)'; kaba='*TMS*17*';  kesin='(?i)\bTMS\s*17\b(?!\d)' },
  @{ ad='TMS 18 (mulga -> TFRS 15)'; kaba='*TMS*18*';  kesin='(?i)\bTMS\s*18\b(?!\d)' },
  @{ ad='eski TTK 6762 (mulga -> 6102)'; kaba='*6762*'; kesin='\b6762\b' }
)

$hedef = @{}   # id -> [ordered]@{sebep; ders; kaynak}
foreach($m in $MULGA){
  $adaylar = @()
  foreach($kolonFiltre in @(
      ("kaynak=ilike." + [uri]::EscapeDataString($m.kaba)),
      ("kanun_no=ilike." + [uri]::EscapeDataString($m.kaba)) )){
    try { $adaylar += Getir "$SB_URL/rest/v1/soru_havuzu?select=id,ders,kaynak,kanun_no,madde_no&$kolonFiltre&limit=500" }
    catch { Write-Host ("  aday sorgusu atlandi ({0}): {1}" -f $kolonFiltre, $_.Exception.Message) }
  }
  $sayilan = 0
  foreach($a in $adaylar){
    $metaveri = "$($a.kaynak) $($a.kanun_no)"
    if($metaveri -notmatch $m.kesin){ continue }
    if($hedef.ContainsKey("$($a.id)")){ continue }
    $hedef["$($a.id)"] = [ordered]@{ sebep=$m.ad; ders="$($a.ders)"; kaynak="$($a.kaynak)"; kanun_no="$($a.kanun_no)"; madde_no="$($a.madde_no)" }
    $sayilan++
  }
  Write-Host ("{0}: kaba {1} aday -> kesin {2}" -f $m.ad, $adaylar.Count, $sayilan)
}
$idler = @($hedef.Keys)
Write-Host ("TOPLAM HEDEF: {0} (09.08 olcumu 10 demisti)" -f $idler.Count)

# GUVENLIK FRENI: beklenen ~10; 40'i asarsa desen patlamis demektir - yazma.
if($idler.Count -gt 40){
  [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='FREN'
    hedef_toplam=$idler.Count; not='Beklenen ~10, bulunan >40 - desen supheli, hicbir sey yazilmadi.'
  }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
  Write-Host "FREN: aday sayisi beklenenin cok ustunde - cikildi."; exit 1
}

# --- kaci su an yayinda? ---
$yayinda = @()
if($idler.Count -gt 0){
  $liste = ($idler | ForEach-Object { '"' + $_ + '"' }) -join ','
  $yayinda = Getir "$SB_URL/rest/v1/soru_havuzu?select=id&yayin=eq.true&id=in.($liste)"
}
Write-Host ("Su an yayinda: {0}" -f $yayinda.Count)

if(-not $yaz){
  [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='OLCUM'; mod='olcum'
    hedef_toplam=$idler.Count; su_an_yayinda=$yayinda.Count
    adaylar=@($hedef.GetEnumerator() | ForEach-Object { [ordered]@{ id=$_.Key; sebep=$_.Value.sebep; ders=$_.Value.ders; kaynak=$_.Value.kaynak; kanun_no=$_.Value.kanun_no; madde_no=$_.Value.madde_no } })
    not='OLCUM modu - hicbir sey yazilmadi. Cekme icin -yaz ile kosulmali.'
  }) -Depth 5), (New-Object Text.UTF8Encoding($false)))
  Write-Host "OLCUM modu - rapor: veri/mulga-cek-sonuc.json"
  exit 0
}

# --- UYGULA: yayin=false + sebepli not (idempotent; soru SILINMEZ) ---------
$cekilen = 0
foreach($grup in ($hedef.GetEnumerator() | Group-Object { $_.Value.sebep })){
  $gidler = @($grup.Group | ForEach-Object { $_.Key })
  for($b = 0; $b -lt $gidler.Count; $b += 50){
    $parca = $gidler[$b..([Math]::Min($b+49, $gidler.Count-1))]
    $liste = ($parca | ForEach-Object { '"' + $_ + '"' }) -join ','
    $govde = ConvertTo-Json -InputObject @{ yayin = $false; yayin_notu = "MULGA DAYANAK 19.08.2026: $($grup.Name). Yururlukten kalkmis metne dayaniyor; guncel halefiyle yeniden yazilip hakem+GM onayindan gecmeden geri ACILMAZ." } -Compress
    Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?id=in.($liste)" -Method Patch -Headers ($H + @{ 'Content-Type'='application/json'; Prefer='return=minimal' }) -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 60 | Out-Null
    $cekilen += $parca.Count
  }
}

# --- GERI OKUMA: hedeflerden hala yayinda olan var mi? 0 olmali ------------
$kalan = @()
if($idler.Count -gt 0){
  $liste = ($idler | ForEach-Object { '"' + $_ + '"' }) -join ','
  $kalan = Getir "$SB_URL/rest/v1/soru_havuzu?select=id&yayin=eq.true&id=in.($liste)"
}

[IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$(if($kalan.Count -eq 0){'TAMAM'}else{'KIRMIZI'})
  mod='yaz'; hedef_toplam=$idler.Count; islenen=$cekilen
  oncesinde_yayinda=$yayinda.Count; geri_okuma_hala_yayinda=$kalan.Count
  adaylar=@($hedef.GetEnumerator() | ForEach-Object { [ordered]@{ id=$_.Key; sebep=$_.Value.sebep; ders=$_.Value.ders; kaynak=$_.Value.kaynak; kanun_no=$_.Value.kanun_no; madde_no=$_.Value.madde_no } })
}) -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host ("CEKME BITTI: islenen {0}, geri-okumada hala yayinda {1} (0 olmali)" -f $cekilen, $kalan.Count)
if($kalan.Count -gt 0){ exit 1 }
