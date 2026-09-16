# ============================================================================
#  SORU-DAYANAK NOBETCISI — 07.08.2026 (Cem'e soz: "mevzuat degisince sorular
#  nasil kontrol altinda tutulacak" sorusunun EKSIK HALKASI)
#
#  Zincir: ayna kanunu yeniden yutar -> _madde-damga.json'daki madde parmak
#  izleri degisir -> BU NOBETCI onceki tabanla karsilastirir -> damgasi
#  DEGISEN maddeye dayanan kasa sorulari (kanun_no + madde_no eslesmesi)
#  'mevzuat-degisti' notuyla yayindan cekilir -> hakem + GM yeniden yargilar.
#  Sayfalar icin ayni zincir 29.07'den beri vardi (dayanak-nobetci);
#  SORULAR icin bugune kadar yoktu - SGK 7,5->9 dersinin kalici ilaci.
#
#  Taban: veri/mevzuat/_madde-damga-onceki.json (ilk kosuda tohumlanir,
#  isaret atilmaz). PATCH kanali curl + fren (07.08 modem dersi).
#  Not EKLEME usulu - dolu kusur notu EZILMEZ (dil-kusuru dersi).
# ============================================================================
param([switch]$tohum)   # -tohum: yalniz taban kopyalanir, isaret atilmaz
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$guncelYol = Join-Path $kok 'veri\mevzuat\_madde-damga.json'
$oncekiYol = Join-Path $kok 'veri\mevzuat\_madde-damga-onceki.json'
$raporYol  = Join-Path $kok 'veri\soru-dayanak-raporu.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 5), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
if(-not (Test-Path $guncelYol)){ Write-Host 'madde-damga dosyasi yok - cikildi'; exit 0 }
$curlAd = if($env:OS -match 'Windows'){ 'curl.exe' } else { 'curl' }

$guncel = (Get-Content $guncelYol -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler
if($tohum -or -not (Test-Path $oncekiYol)){
  Copy-Item $guncelYol $oncekiYol -Force
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TOHUM'; not='taban kopyalandi; isaret atilmadi. Sonraki kosular gercek degisimi yakalar.' })
  Write-Host 'TOHUM: taban kuruldu.'; exit 0
}
$onceki = (Get-Content $oncekiYol -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler

# --- degisenler (damga farkli) + silinenler
$degisen = New-Object System.Collections.Generic.List[string]
$silinen = New-Object System.Collections.Generic.List[string]
foreach($p in $onceki.PSObject.Properties){
  $g = $guncel.PSObject.Properties[$p.Name]
  if($null -eq $g){ $silinen.Add($p.Name); continue }
  if("$($g.Value.damga)" -ne "$($p.Value.damga)"){ $degisen.Add($p.Name) }
}
Write-Host ("degisen madde: {0} | silinen: {1}" -f $degisen.Count, $silinen.Count)

$isaretli=0; $etkilenen = New-Object System.Collections.Generic.List[object]
# 16.08 DUZELTME (1): kapi yalniz $degisen'e bakiyordu. Degisen 0 ama SILINEN
# varsa blok HIC calismiyor, yani mulga/kaldirilmis maddeye dayanan sorular
# sessizce yayinda kaliyordu. Ikisinin toplamina bakilir.
if(($degisen.Count + $silinen.Count) -gt 0){
  $SRV = $env:SUPABASE_SERVICE_KEY
  foreach($anahtar in ($degisen + $silinen)){
    # 16.08 DUZELTME (2): 'ad|...' anahtarlari (standart/teblig) kanun_no+madde_no
    # sorgusunda HICBIR ZAMAN eslesmiyor - 16.08 kosusunda 4.489 bosuna istek
    # atildi. Yalniz kanun tipi anahtar sorgulanir; standart tarafi ayri is.
    if($anahtar -notmatch '^\d+\|'){ continue }
    $par = $anahtar -split '\|'
    if($par.Count -lt 2){ continue }
    $kanun = $par[0]; $madde = $par[1]
    # o maddeye dayanan sorular
    $r = & $curlAd -s -H "apikey: $SRV" -H "User-Agent: mevzuat-radar-robot/1.0" ("$U`?select=id,yayin_notu&kanun_no=eq." + [uri]::EscapeDataString($kanun) + "&madde_no=eq." + [uri]::EscapeDataString($madde) + "&limit=500")
    $sorular = @()
    try { $sorular = @(($r | ConvertFrom-Json)) } catch {}
    if(-not $sorular.Count){ continue }
    $etkilenen.Add([pscustomobject]@{ madde=$anahtar; soru=$sorular.Count; tur=$(if($silinen -contains $anahtar){'SILINDI'}else{'degisti'}) })
    foreach($s in $sorular){
      if("$($s.yayin_notu)" -match 'mevzuat-degisti'){ continue }
      $yeniNot = if("$($s.yayin_notu)".Trim()){ "$($s.yayin_notu)" + ' | mevzuat-degisti: ' + $anahtar } else { ('mevzuat-degisti ' + (Get-Date -Format 'dd.MM.yyyy') + ': ' + $anahtar + ' damgasi degisti - hakem+GM yeniden yargilamali') }
      $gov = ConvertTo-Json -Compress -InputObject @{ yayin=$false; yayin_notu=$yeniNot }
      $tmp=[IO.Path]::GetTempFileName(); [IO.File]::WriteAllText($tmp,$gov,(New-Object Text.UTF8Encoding($false)))
      $kod = & $curlAd -s -o ($(if($env:OS -match 'Windows'){'NUL'}else{'/dev/null'})) -w "%{http_code}" -X PATCH -H "apikey: $SRV" -H "Content-Type: application/json" -H "Prefer: return=minimal" -H "User-Agent: mevzuat-radar-robot/1.0" --data-binary "@$tmp" ("$U`?id=eq." + $s.id)
      Remove-Item $tmp -Force -ErrorAction SilentlyContinue
      if("$kod" -eq '204'){ $isaretli++ }
      Start-Sleep -Milliseconds 300
    }
  }
}

# --- 16.09 YENİ HAT (Cem "SGS gibi nöbetçi ... herşey var"): Kaydır-Çöz soruları soru_havuzu'nda DEĞİL; ambar kalip_parti'de
# üretilir, kilitli kasaya (paket_soru) yayımlanır. Damgası değişen/silinen maddeyi KAYNAK olarak kullanmış (kaynak_adlar) her
# yeni hat sorusu engel listesine yazılır (arac/mevzuat-degisti.ps1; yalnız kimlik + içerik izi) ve kasadan çekilir.
# Yayın şartları listeyi okur; soru yeniden yazılırsa içerik izi değişir ve engel kalkar. Parti dosyalarına YAZILMAZ
# (CLAUDE.md: bulutta koşan partiye ambardan yazılmaz).
$yeniHatEngel = 0; $yeniHatHata = $false; $kasadanCekilen = 0
$kanunAnah = @(($degisen + $silinen) | Where-Object { $_ -match '^\d+\|' })
if ($kanunAnah.Count) {
  . (Join-Path (Join-Path $kok 'arac') 'mevzuat-degisti.ps1')
  $kokTur = @{}
  foreach ($a in $kanunAnah) {
    $kay = $(if ($guncel.PSObject.Properties[$a]) { $guncel.$a } else { $onceki.$a })
    $mk = MdMaddeKoku "$($kay.ad)"
    if ($mk) { $kokTur[$mk] = @{ anahtar = $a; tur = $(if ($silinen -contains $a) { 'SILINDI' } else { 'degisti' }) } }
  }
  if ($kokTur.Count) {
    try {
      $liste = MdListeOku $kok
      $Hs = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
      $yeniAnah = New-Object System.Collections.Generic.List[string]
      for ($ofs = 0; ; $ofs += 40) {
        $yan = Invoke-WebRequest -UseBasicParsing -Uri ("https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti?select=etiket,icerik&order=etiket.asc&limit=40&offset=$ofs") -Headers $Hs -TimeoutSec 300
        $jp = ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($yan.RawContentStream.ToArray()))
        $partiler = @($jp | ForEach-Object { $_ })
        foreach ($pr in $partiler) {
          $ic = $pr.icerik; if ($ic -is [string]) { $ic = ConvertFrom-Json -InputObject $ic }
          foreach ($q in $ic.PSObject.Properties) {
            $v = $q.Value; if (-not $v -or -not $v.PSObject.Properties['soru'] -or -not $v.soru) { continue }
            foreach ($ka in @($v.kaynak_adlar)) {
              $mk = MdMaddeKoku "$ka"
              if (-not ($mk -and $kokTur.ContainsKey($mk))) { continue }
              $an = "$($pr.etiket)/$($q.Name)"; $iz = MdIcerikIzi $v
              if (-not ($liste.ContainsKey($an) -and "$($liste[$an].iz)" -eq $iz)) {
                $liste[$an] = [pscustomobject][ordered]@{ anahtar = $an; iz = $iz; madde = $kokTur[$mk].anahtar; kaynak = $mk; tur = $kokTur[$mk].tur; tarih = (Get-Date -Format 'dd.MM.yyyy') }
                $yeniAnah.Add($an)
              }
              break
            }
          }
        }
        if ($partiler.Count -lt 40) { break }
      }
      if ($yeniAnah.Count) {
        $listeNesne = [ordered]@{ aciklama = 'Yeni hat (Kaydır-Çöz) soruları: dayandığı madde değişti/silindi. Yayın şartları geçirmez; soru yeniden yazılırsa (iz değişir) engel kalkar. Üreten: motor/soru-dayanak-nobetcisi.ps1'; kayitlar = @($liste.Values | Sort-Object anahtar) }
        [IO.File]::WriteAllText((MdListeYolu $kok), (ConvertTo-Json -InputObject $listeNesne -Depth 4), (New-Object Text.UTF8Encoding($false)))
        $yeniHatEngel = $yeniAnah.Count
        # kilitli kasadan çek (tablo henüz yoksa 404/400 → atla; liste yine yayın şartında engeller)
        for ($i = 0; $i -lt $yeniAnah.Count; $i += 50) {
          $parca = @($yeniAnah | Select-Object -Skip $i -First 50 | ForEach-Object { '"' + ($_ -replace '"', '') + '"' }) -join ','
          try {
            [void](Invoke-WebRequest -UseBasicParsing -Method Delete -Uri ("https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?id=in.(" + [uri]::EscapeDataString($parca) + ")") -Headers ($Hs + @{ Prefer = 'return=minimal' }) -TimeoutSec 120)
            $kasadanCekilen += [math]::Min(50, $yeniAnah.Count - $i)
          } catch {
            $kodK = 0; try { $kodK = [int]$_.Exception.Response.StatusCode } catch {}
            if ($kodK -eq 404 -or $kodK -eq 400) { Write-Host 'paket_soru tablosu yok — kasadan çekme atlandı (liste yayını engeller)'; break }
            throw
          }
        }
      }
      Write-Host ("YENİ HAT: değişen madde kökü {0} · yeni engellenen soru {1} · kasadan çekilen {2}" -f $kokTur.Count, $yeniHatEngel, $kasadanCekilen)
    } catch { $yeniHatHata = $true; Write-Host "YENİ HAT TARAMASI DÜŞTÜ: $($_.Exception.Message)" }
  }
}

# 16.08 DUZELTME (3): taban KOSULSUZ ilerliyordu. Kosu yarida hata alsa bile
# "onceki damga" ileri gidiyor ve DEGISIM SINYALI KALICI OLARAK KAYBOLUYORDU -
# o madde bir daha hic "degisti" demezdi. Artik taban yalniz isaretleme
# tamamlandiysa ilerler; aksi halde bir sonraki kosu ayni degisimi yeniden
# gorur (tekrar gormek, kaybetmekten iyidir).
$isaretlemeTamam = (($isaretli -gt 0) -or ($etkilenen.Count -eq 0)) -and -not $yeniHatHata   # 16.09: yeni hat taraması düştüyse sinyal korunur
if($isaretlemeTamam){
  Copy-Item $guncelYol $oncekiYol -Force
  Write-Host 'Taban ilerletildi.'
} else {
  Write-Host 'TABAN ILERLETILMEDI: etkilenen soru bulundu ama hicbiri isaretlenemedi - sinyal korunuyor.'
}
$durum = if($isaretlemeTamam){ 'TAMAM' } else { 'KIRMIZI' }
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$durum
  degisenMadde=$degisen.Count; silinenMadde=$silinen.Count; isaretlenenSoru=$isaretli
  taban_ilerletildi=$isaretlemeTamam
  yeniHatEngellenen=$yeniHatEngel; yeniHatKasadanCekilen=$kasadanCekilen; yeniHatTaramaHatasi=$yeniHatHata
  etkilenen=@($etkilenen | Select-Object -First 100)
  not='Isaretlenen sorular yayin=false + mevzuat-degisti notu tasir; hakem+GM yargisi sonrasi geri acilir.'
})
Write-Host ("{0}: {1} soru mevzuat-degisti notuyla cekildi." -f $durum, $isaretli)
if($durum -eq 'KIRMIZI'){ exit 1 }
