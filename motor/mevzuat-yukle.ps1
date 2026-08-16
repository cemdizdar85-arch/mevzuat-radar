# ============================================================================
#  MEVZUAT YUKLEYICI  —  veri/mevzuat/*.json (kanun madde-belgeleri) -> Supabase
#  'dokumanlar' tablosu. Beyin (net-cevap) FTS ile MADDENIN KENDISINDEN alintiyla
#  cevaplar. Kaynak: mevzuat.gov.tr konsolide metin (pdftotext, madde madde).
#  tur='kanun-madde' -> kuratorlu 14 ambar belgesine (ambar-yukle) DOKUNMAZ.
#  Idempotent: once tur=kanun-madde siler, sonra toplu ekler (batch=500).
#  ENV: SUPABASE_SERVICE_KEY (zorunlu). Yoksa zarifce atlar (exit 0).
# ============================================================================
$ErrorActionPreference = "Stop"
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try { [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance) } catch {}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - mevzuat yukleyici atlandi."; exit 0 }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

$dir = Join-Path $kok "veri/mevzuat"
if(-not (Test-Path $dir)){ Write-Host "veri/mevzuat yok."; exit 0 }

# --- topla + dedup (kaynak_ad) ---
$hepsi = New-Object System.Collections.Generic.List[object]
$gorulen = @{}
Get-ChildItem $dir -Filter *.json | ForEach-Object {
  $d = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($b in @($d.belgeler)){
    if(-not $b.kaynak_ad -or -not $b.metin){ continue }
    $k = "$($b.kaynak_ad)"
    if($gorulen.ContainsKey($k)){ continue }
    $gorulen[$k] = $true
    $hepsi.Add([ordered]@{
      tur          = $(if($b.tur){ "$($b.tur)" } else { "kanun-madde" })   # standart-madde (TMS/BDS) belgeleri kendi turunu tasir
      kaynak_ad    = $k
      baslik       = "$($b.baslik)"
      metin        = "$($b.metin)"
      kaynak_url   = "$($b.kaynak_url)"
      belge_tarihi = $null
    })
  }
}
Write-Host ("Yuklenecek: {0} madde-belgesi" -f $hepsi.Count)
if($hepsi.Count -eq 0){ exit 0 }

# --- once eski kayitlari sil (idempotent) ---
# 27.07.2026 DUZELTME: silme listesinde 'teblig' YOKTU. Dosyalardaki 1.288
# teblig kaydi her kosuda siliNMEden yeniden ekleniyordu; ambarda ayni
# kaynak_ad'dan 45 KOPYA birikmisti (57.622 satir). Silme listesine eklendi.
# KURAL: bu betik hangi tur'leri EKLIYORSA, hepsini SILMEK zorunda.
# 27.07 2. tur: tek sorguda silme 57.622 satirda Supabase statement timeout'una
# takildi (is 15 sn'de kirmizi bitti, ambar hic degismedi). Artik tur tur ve
# PARCALI siliniyor: id listesi cekilir, id=in.(...) ile silinir, bitene kadar.
# 28.07 4. tur — BOS PENCERE: eski akis "HEPSINI sil, sonra HEPSINI ekle" idi;
# 14.960 kaydin yazilmasi dakikalar surdugu icin ambar O SURE BOYUNCA TAMAMEN
# BOS kaliyordu (27.07'de gozle goruldu: kanun-madde 0). Site o anda sorgu
# yaparsa bos sonuc doner. Artik TUR TUR: bir tur silinir ve HEMEN geri yazilir,
# sonra digerine gecilir. Boylece ayni anda yalnizca TEK tur bos kalir ve
# penceresi kendi buyuklugu kadar surer. (Tam sifir pencere icin surum-kolonlu
# mavi-yesil takas gerekir; o sema degisikligi istiyor, ayri is olarak duruyor.)
$SILINECEK = @('teori-notu','standart-madde','teblig','kanun-madde')   # kucukten buyuge
function TurSil($t){
  $tur_silinen = 0
  while($true){
    try {
      $ids = Invoke-RestMethod -Method Get -Uri "$SB_URL/rest/v1/dokumanlar?select=id&tur=eq.$t&limit=1000" -Headers $H -TimeoutSec 120
    } catch { Write-Host ("KRITIK: id cekilemedi ({0}): {1}" -f $t, $_); exit 1 }
    $liste = @($ids)
    if($liste.Count -eq 0){ break }
    # 27.07 3. tur: id UUID (36 krk). 1000 id'yi tek URL'e koymak 39.007
    # karakterlik bir filtre ediyor ve sunucu 400 donuyor - OLCULDU:
    #   100'luk  -> 3.907 krk  -> OK
    #   1000'luk -> 39.007 krk -> 400 Hatali Istek
    # Silme 100'luk dilimlere bolundu. UUID'ler tirnaklandi; testte tirnaksiz
    # da calisti, yani ariza SADECE URL UZUNLUGUYDU - tirnak ek guvence.
    for($j=0; $j -lt $liste.Count; $j += 100){
      $alt = @($liste[$j..([Math]::Min($j+99, $liste.Count-1))])
      $filtre = "id=in.(" + (($alt | ForEach-Object { '"' + $_.id + '"' }) -join ',') + ")"
      try {
        Invoke-RestMethod -Method Delete -Uri "$SB_URL/rest/v1/dokumanlar?$filtre" -Headers ($H + @{ Prefer = "return=minimal" }) -TimeoutSec 180 | Out-Null
        $tur_silinen += $alt.Count
      } catch { Write-Host ("KRITIK: silme basarisiz ({0}): {1} - cift kayit riski, kosu durduruluyor." -f $t, $_); exit 1 }
    }
  }
  Write-Host ("  silindi: {0,-16} {1} satir" -f $t, $tur_silinen)
}

# --- toplu ekle ---
# 27.07.2026 DUZELTME: eski hal batch=500 idi ve basarisiz partiyi SESSIZCE
# yutup devam ediyordu (sadece Write-Host). Bu yuzden 3.162 kayit (3.088
# kanun-madde + 74 standart-madde, ic. tum MSUGT ilkeleri ve 44 THP hesabi)
# ambara hic girmemis, kosu yine de YESIL gorunmustu. Artik: parti kucultuldu,
# basarisiz parti 3 kez denenir, yine olmazsa TEK TEK yazilir ve sonunda
# eksik varsa is KIRMIZI biter. Sessiz veri kaybi yok.
$batch = 200; $eklenen = 0; $basarisiz = New-Object System.Collections.Generic.List[object]

function Gonder($kayitlar){
  $json = ($kayitlar | ConvertTo-Json -Depth 5)
  if(@($kayitlar).Count -eq 1){ $json = "[$json]" }   # tek elemanda PS array'i acar
  $gonder = [System.Text.Encoding]::UTF8.GetBytes($json)
  Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/dokumanlar" -Headers ($H + @{ Prefer = "return=minimal" }) -ContentType "application/json; charset=utf-8" -Body $gonder -TimeoutSec 300 | Out-Null
}

# TUR TUR: sil -> HEMEN geri yaz. Boylece bos pencere tek turle sinirli kalir.
foreach($t in $SILINECEK){
  $turKayit = @($hepsi | Where-Object { "$($_.tur)" -eq $t })
  Write-Host ("--- {0}: {1} kayit (once siliniyor, hemen ardindan yaziliyor)" -f $t, $turKayit.Count)
  TurSil $t
  if($turKayit.Count -eq 0){ Write-Host ("  {0}: dosyalarda kayit yok, yalniz temizlendi." -f $t); continue }
  for($i=0; $i -lt $turKayit.Count; $i += $batch){
    $son = [Math]::Min($i+$batch, $turKayit.Count) - 1
    $dilim = @($turKayit[$i..$son])
    $ok = $false
    for($deneme=1; $deneme -le 3 -and -not $ok; $deneme++){
      try { Gonder $dilim; $ok = $true }
      catch {
        Write-Host ("  UYARI [{0}] batch {1}-{2} deneme {3}/3: {4}" -f $t, $i, $son, $deneme, $_)
        if($deneme -lt 3){ Start-Sleep -Seconds (5 * $deneme) }
      }
    }
    if($ok){ $eklenen += $dilim.Count }
    else {
      # parti 3 kez dustu -> tek tek yaz, boylece yalniz gercekten bozuk kayit duser
      Write-Host ("  [{0}] batch {1}-{2} 3 denemede gecmedi -> tek tek yaziliyor" -f $t, $i, $son)
      foreach($k in $dilim){
        try { Gonder @($k); $eklenen++ }
        catch { $basarisiz.Add($k.kaynak_ad); Write-Host ("    DUSEN: {0} | {1}" -f $k.kaynak_ad, $_) }
      }
    }
  }
  Write-Host ("  {0}: geri yazildi ({1}/{2} toplam)" -f $t, $eklenen, $hepsi.Count)
}
# dosyalarda olup SILINECEK listesinde OLMAYAN bir tur varsa fark edilsin
$bilinmeyen = @($hepsi | Where-Object { $SILINECEK -notcontains "$($_.tur)" })
if($bilinmeyen.Count -gt 0){
  Write-Host ("KIRMIZI: silme listesinde OLMAYAN tur(ler) var -> {0} kayit yazilmadi. Turler: {1}" -f $bilinmeyen.Count, (($bilinmeyen | ForEach-Object { $_.tur } | Sort-Object -Unique) -join ', '))
  Write-Host "  (Silinmeyen bir turu eklemek 45x cift kayit felaketini tekrarlar - once SILINECEK listesine ekle.)"
  exit 1
}

Write-Host ("MEVZUAT YUKLENDI - {0}/{1} belge yazildi." -f $eklenen, $hepsi.Count)
if($basarisiz.Count -gt 0){
  Write-Host ("KIRMIZI: {0} kayit ambara GIRMEDI. Ilk 20:" -f $basarisiz.Count)
  $basarisiz | Select-Object -First 20 | ForEach-Object { Write-Host ("   - " + $_) }
  exit 1
}
if($eklenen -ne $hepsi.Count){
  Write-Host ("KIRMIZI: sayim tutmuyor ({0} != {1})." -f $eklenen, $hepsi.Count)
  exit 1
}
exit 0
