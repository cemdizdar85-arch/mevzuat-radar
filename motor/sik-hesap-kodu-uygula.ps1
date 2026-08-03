# ============================================================================
#  SIK HESAP KODU UYGULAYICI (03.08.2026 gece) — KASAYA YAZAR (dikkat)
#
#  Girdi: veri/sik-hesap-kodu-onerisi.json (sik-hesap-kodu-oneri.ps1 uretir)
#  Is: onerilen kod duzeltmelerini kasadaki SORU/SIK/ACIKLAMA metinlerine uygular.
#  AI CAGRISI YOK - 0 USD. Ama KASAYA YAZAR, o yuzden uc sigorta var:
#
#   1) YEDEK: dokunulan her alanin ESKI HALI once ozel kovaya yazilir
#      (onarim-taslak/yedek-sik-kod-<damga>.json). Yedek yazilamazsa IS DURUR.
#   2) YAYIN KAPISI: yalnizca yayin=false sorulara dokunulur. Yayindaki bir
#      soru listede cikarsa o satir ATLANIR ve rapora yazilir.
#   3) GERI OKUMA: yazilan her soru tekrar cekilir; beklenen metin yoksa
#      "dogrulanmadi" sayilir - "yapildi" demek icin geri okuma sart (kor
#      kalma kurali).
#
#  IKI GUVEN SINIFI (03.08 olcumu):
#   - YUKSEK: ayni (kod,ad) cifti sorunun 2+ alaninda tekrarliyor -> ad KASITLI
#     yazilmis, hatali olan koddur. 342 oneri.
#   - DUSUK : cift yalniz 1 alanda geciyor -> yon belirsiz, regex yanlis cift
#     kurmus olabilir ("...Verilen Cekler (103) Kasa hesabindan..."). 317 oneri.
#  Varsayilan -tier yuksek. Hepsini uygulamak icin -tier hepsi (Cem'in acik
#  onayiyla).
#
#  MODLAR:
#   (varsayilan) KURU : hicbir sey yazilmaz, ne olacagi raporlanir.
#   -uygula           : GERCEK YAZMA (tetik dosyasinda BAS sarti workflow'da).
#
#  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
param(
  [switch]$uygula,
  [ValidateSet('yuksek','hepsi')][string]$tier = 'yuksek'
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$oneriYol = Join-Path $kok 'veri/sik-hesap-kodu-onerisi.json'
$raporYol = Join-Path $kok 'veri/sik-hesap-kodu-uygulama-raporu.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 6
  # Rapor SAYI tasir, soru metni TASIMAZ (03.08 sizinti dersi).
  if($j.Length -gt 20480){ $j = ConvertTo-Json -Depth 2 -InputObject @{ durum='KIRMIZI - rapor sismis'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1} | {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g)
  exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 0 }
$U    = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$STOR = "https://bjrleanjpyujtajmazxn.supabase.co/storage/v1"
$KOVA = 'onarim-taslak'
$SB   = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

if(-not (Test-Path $oneriYol)){ Write-Host "Oneri dosyasi yok - once sik-hesap-kodu-oneri.ps1 kosulmali."; RaporYaz @{durum='KIRMIZI'; sebep='oneri dosyasi yok'}; exit 1 }
$oneriler = @((Get-Content $oneriYol -Raw -Encoding UTF8 | ConvertFrom-Json).oneriler)
Write-Host ("Oneri dosyasinda: {0} satir" -f $oneriler.Count)

# --- GUVEN SINIFI: ayni soruda ayni (kod,ad) cifti kac alanda geciyor ---
$tekrar = @{}
foreach($o in $oneriler){
  $an = "$($o.soru_id)|$($o.yazili_kod)|$($o.yazili_ad)"
  if(-not $tekrar.ContainsKey($an)){ $tekrar[$an] = 0 }
  $tekrar[$an]++
}
$secilen = New-Object System.Collections.Generic.List[object]
foreach($o in $oneriler){
  $an = "$($o.soru_id)|$($o.yazili_kod)|$($o.yazili_ad)"
  $yuksekMi = ($tekrar[$an] -ge 2)
  if($tier -eq 'yuksek' -and -not $yuksekMi){ continue }
  $secilen.Add($o)
}
Write-Host ("Tier '{0}' -> islenecek: {1} satir" -f $tier, $secilen.Count)

# --- dokunulacak sorulari kasadan cek ---
$idler = @($secilen | ForEach-Object { "$($_.soru_id)" } | Select-Object -Unique)
$asil = @{}
for($b=0; $b -lt $idler.Count; $b+=50){
  $dilim = $idler[$b..([Math]::Min($b+49, $idler.Count-1))]
  $liste = ($dilim | ForEach-Object { '"' + $_ + '"' }) -join ','
  foreach($s in (CekListe "$U`?select=id,soru,siklar,aciklama,yayin&id=in.($liste)")){ if($null -ne $s){ $asil["$($s.id)"] = $s } }
}
Write-Host ("Kasadan cekilen soru: {0} / {1}" -f $asil.Count, $idler.Count)

# --- degisiklikleri HAZIRLA (henuz yazma) + YEDEK topla ---
$yedek     = New-Object System.Collections.Generic.List[object]
$yazilacak = @{}   # soru_id -> @{ alanAdi = yeniDeger }
$atlanan   = New-Object System.Collections.Generic.List[object]
$degisen = 0; $bulunamayan = 0; $yayindaAtlanan = 0

foreach($o in $secilen){
  $sid = "$($o.soru_id)"
  if(-not $asil.ContainsKey($sid)){ $bulunamayan++; continue }
  $s = $asil[$sid]
  # SIGORTA 2: yayindaki soruya DOKUNULMAZ
  if($s.yayin){ $yayindaAtlanan++; $atlanan.Add([ordered]@{ soru_id=$sid; sebep='yayinda' }); continue }

  $parca = "$($o.alan)" -split '\.'
  $kok0 = $parca[0]; $harf = if($parca.Count -gt 1){ $parca[1] } else { '' }
  $eski = ''
  try {
    if($kok0 -eq 'soru'){ $eski = "$($s.soru)" }
    elseif($kok0 -eq 'siklar'   -and $s.siklar   -and $s.siklar.PSObject.Properties[$harf]){   $eski = "$($s.siklar.$harf)" }
    elseif($kok0 -eq 'aciklama' -and $s.aciklama -and $s.aciklama.PSObject.Properties[$harf]){ $eski = "$($s.aciklama.$harf)" }
  } catch {}
  if($eski -eq ''){ $bulunamayan++; continue }

  # Zaten uygulanmis olabilir (tekrar kosu) - o zaman degistirecek bir sey yok
  $aranan = "$($o.yazili_kod) $($o.yazili_ad)"
  if($eski -notlike "*$aranan*"){ $atlanan.Add([ordered]@{ soru_id=$sid; alan="$($o.alan)"; sebep='eski metin bulunamadi (zaten duzeltilmis olabilir)' }); continue }
  $yeni = $eski.Replace($aranan, "$($o.onerilen_kod) $($o.onerilen_ad)")
  if($yeni -eq $eski){ continue }

  if(-not $yazilacak.ContainsKey($sid)){ $yazilacak[$sid] = @{} }
  # ayni alanda birden cok duzeltme olabilir - zincirle
  if($yazilacak[$sid].ContainsKey("$($o.alan)")){
    $ara = $yazilacak[$sid]["$($o.alan)"]
    if($ara -like "*$aranan*"){ $yazilacak[$sid]["$($o.alan)"] = $ara.Replace($aranan, "$($o.onerilen_kod) $($o.onerilen_ad)") }
  } else {
    $yazilacak[$sid]["$($o.alan)"] = $yeni
  }
  # SIGORTA 1: eski hali yedege (TAM metin - yedek ozel kovaya gider, depoya DEGIL)
  $yedek.Add([ordered]@{ soru_id=$sid; alan="$($o.alan)"; eski_metin=$eski })
  $degisen++
}
Write-Host ("Hazirlanan degisiklik: {0} alan / {1} soru" -f $degisen, $yazilacak.Count)

# --- KURU MOD: yazma, yalniz raporla ---
if(-not $uygula){
  RaporYaz ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='KURU (0 USD, KASAYA YAZILMADI)'; tier=$tier
    oneri_dosyasi=$oneriler.Count; secilen=$secilen.Count
    hazirlanan_degisiklik=$degisen; etkilenen_soru=$yazilacak.Count
    yayinda_atlanan=$yayindaAtlanan; bulunamayan=$bulunamayan
    atlanan_ornek=@($atlanan | Select-Object -First 10)
    not='Bu bir PROVA. Gercek yazma icin -uygula gerekir (workflow tetiginde BAS sarti).'
  })
  Write-Host "`n=== KURU KOSU - kasaya hicbir sey yazilmadi ==="
  exit 0
}

# ===================== GERCEK YAZMA =====================
# SIGORTA 1: once YEDEK yaz, tutmazsa IS DURUR
$damga = Get-Date -Format 'MMdd-HHmm'
$yedekAd = "yedek-sik-kod-$damga.json"
$yedekBayt = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); tier=$tier; kayit=$yedek.ToArray() } -Depth 6))
Invoke-RestMethod -Uri "$STOR/object/$KOVA/$yedekAd" -Method Post `
  -Headers ($SB + @{ 'Content-Type'='application/json'; 'x-upsert'='true' }) -Body $yedekBayt -TimeoutSec 180 | Out-Null
$yedekGeri = -1
try { $h = Invoke-WebRequest -Uri "$STOR/object/$KOVA/$yedekAd" -Headers $SB -UseBasicParsing -TimeoutSec 120; $yedekGeri = $h.RawContentLength } catch { $yedekGeri = -1 }
if($yedekGeri -lt 100){
  Write-Host "!! YEDEK YAZILAMADI - hicbir sey degistirilmedi."
  RaporYaz @{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KIRMIZI'; sebep='yedek yazilamadi, yazma iptal'; yedek=$yedekAd }
  exit 1
}
Write-Host ("Yedek yazildi: {0} ({1} kayit)" -f $yedekAd, $yedek.Count)

# --- PATCH ile yaz (kismi upsert NOT NULL duvarina carpar - 27.07 dersi) ---
$yazilan = 0; $yazmaHatasi = 0
foreach($sid in $yazilacak.Keys){
  $s = $asil[$sid]
  $govde = @{}
  $siklarYeni = $null; $aciklamaYeni = $null
  foreach($alan in $yazilacak[$sid].Keys){
    $p = $alan -split '\.'
    if($p[0] -eq 'soru'){ $govde['soru'] = $yazilacak[$sid][$alan] }
    elseif($p[0] -eq 'siklar'){
      if($null -eq $siklarYeni){ $siklarYeni = $s.siklar }
      $siklarYeni.$($p[1]) = $yazilacak[$sid][$alan]
    }
    elseif($p[0] -eq 'aciklama'){
      if($null -eq $aciklamaYeni){ $aciklamaYeni = $s.aciklama }
      $aciklamaYeni.$($p[1]) = $yazilacak[$sid][$alan]
    }
  }
  if($null -ne $siklarYeni){   $govde['siklar']   = $siklarYeni }
  if($null -ne $aciklamaYeni){ $govde['aciklama'] = $aciklamaYeni }
  try {
    $b = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $govde -Depth 8))
    Invoke-RestMethod -Uri "$U`?id=eq.$sid" -Method Patch -Headers ($SB + @{ 'Content-Type'='application/json'; 'Prefer'='return=minimal' }) -Body $b -TimeoutSec 120 | Out-Null
    $yazilan++
  } catch { $yazmaHatasi++ }
}
Write-Host ("Yazilan soru: {0} (hata {1})" -f $yazilan, $yazmaHatasi)

# --- SIGORTA 3: GERI OKU ve dogrula ---
$dogrulanan = 0; $dogrulanmayan = 0
$kontrolId = @($yazilacak.Keys)
for($b=0; $b -lt $kontrolId.Count; $b+=50){
  $dilim = $kontrolId[$b..([Math]::Min($b+49, $kontrolId.Count-1))]
  $liste = ($dilim | ForEach-Object { '"' + $_ + '"' }) -join ','
  foreach($s in (CekListe "$U`?select=id,soru,siklar,aciklama&id=in.($liste)")){
    if($null -eq $s){ continue }
    $sid = "$($s.id)"
    $hepsiTamam = $true
    foreach($alan in $yazilacak[$sid].Keys){
      $p = $alan -split '\.'
      $simdi = ''
      try {
        if($p[0] -eq 'soru'){ $simdi = "$($s.soru)" }
        elseif($p[0] -eq 'siklar'   -and $s.siklar.PSObject.Properties[$p[1]]){   $simdi = "$($s.siklar.$($p[1]))" }
        elseif($p[0] -eq 'aciklama' -and $s.aciklama.PSObject.Properties[$p[1]]){ $simdi = "$($s.aciklama.$($p[1]))" }
      } catch {}
      if($simdi -ne $yazilacak[$sid][$alan]){ $hepsiTamam = $false }
    }
    if($hepsiTamam){ $dogrulanan++ } else { $dogrulanmayan++ }
  }
}

RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  durum=$(if($dogrulanmayan -eq 0 -and $yazmaHatasi -eq 0){'TAMAM'}else{'KIRMIZI'})
  mod='UYGULANDI (KASAYA YAZILDI)'; tier=$tier
  yedek_dosyasi=$yedekAd; yedek_kayit=$yedek.Count; yedek_bayt=$yedekGeri
  hazirlanan_degisiklik=$degisen; etkilenen_soru=$yazilacak.Count
  yazilan_soru=$yazilan; yazma_hatasi=$yazmaHatasi
  geri_okuma_dogrulanan=$dogrulanan; geri_okuma_dogrulanmayan=$dogrulanmayan
  yayinda_atlanan=$yayindaAtlanan; bulunamayan=$bulunamayan
  not="Geri alma: ozel kovadaki $yedekAd dosyasindaki eski_metin degerleri geri yazilir."
})
Write-Host "`n=== UYGULAMA BITTI ==="
Write-Host ("  Yazilan soru      : {0}" -f $yazilan)
Write-Host ("  Geri okuma TAMAM  : {0}" -f $dogrulanan)
Write-Host ("  Geri okuma HATA   : {0}" -f $dogrulanmayan)
if($dogrulanmayan -gt 0 -or $yazmaHatasi -gt 0){ exit 1 }
