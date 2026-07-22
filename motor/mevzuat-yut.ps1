# ============================================================================
#  MEVZUAT YUT (GUNLUK) — kanunu madde madde yutan, GUNCEL kalan AYNA robotu.
#  Cem: "gunluk tazeleme lazim, RG gunluk cikiyor." Ilke: hiz = kaynagin hizi.
#  AKIS: (workflow bash adimi her kanunun mevzuat.gov.tr KONSOLIDE PDF'ini
#  indirip pdftotext ile ./_txt/<slug>.txt yapar) -> bu script her kanunu
#  hash'ler; hash DEGISTIYSE (kanun guncellendi/madde iptal) O KANUNU yeniden
#  parcalar + Supabase'e yeniden yukler + belge_tarihi=BUGUN (son senkron damgasi).
#  Degismeyeni ATLAR (israf yok). EZBER DEGIL: her gun guncel kaynagin aynasi.
#  ENV: SUPABASE_SERVICE_KEY (yukleme icin; yoksa yalniz dosya uretir).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try { [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance) } catch {}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$txtDir = Join-Path $kok "_txt"                 # bash adimi buraya <slug>.txt koyar
$mevzuatDir = Join-Path $kok "veri\mevzuat"
$durumYol = Join-Path $mevzuatDir "_durum.json"
$bugun = (Get-Date).ToString("yyyy-MM-dd")
if(-not (Test-Path $mevzuatDir)){ New-Item -ItemType Directory -Path $mevzuatDir -Force | Out-Null }

$manifest = Get-Content (Join-Path $kok "veri\mevzuat-kaynaklar.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$durum = @{}
if(Test-Path $durumYol){ try { (Get-Content $durumYol -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $durum[$_.Name] = $_.Value } } catch {} }

# --- madde madde parcalayici (eski "Madde N -" + modern "MADDE N-"; TR unsuz yumusamasi) ---
# 22.07.2026: taksimli madde (32/A, 32/C...) + TUM-BUYUK "EK MADDE/GECICI MADDE/MUKERRER MADDE"
# varyantlari eklendi — KVK 32/C (asgari KV) ve 7524 ek maddeleri bu desenin disinda kaliyordu.
function Parcala([string]$flatMetin, [string]$kanunAd, [string]$url){
  $rx = [regex]'(?:(?<pre>\p{Lu}[^:]{1,70}):\s*)?(?<tur>MÜKERRER MADDE|EK GEÇİCİ MADDE|EK MADDE|GEÇİCİ MADDE|Mükerrer MADDE|Ek Geçici MADDE|Ek MADDE|Geçici MADDE|MADDE|Mükerrer Madde|Ek Geçici Madde|Ek Madde|Geçici Madde|Madde)\s+(?<no>\d+(?:/[A-ZÇĞİÖŞÜ])?)\s*[–—-]'
  $m = $rx.Matches($flatMetin)
  $docs = New-Object System.Collections.Generic.List[object]
  for($i=0; $i -lt $m.Count; $i++){
    $start = $m[$i].Index
    $end = if($i -lt $m.Count-1){ $m[$i+1].Index } else { $flatMetin.Length }
    $govde = $flatMetin.Substring($start, $end-$start).Trim()
    $no = $m[$i].Groups['no'].Value; $tur = $m[$i].Groups['tur'].Value; $pre = $m[$i].Groups['pre'].Value.Trim()
    if($govde -match '^.{0,70}\(Mülga'){ continue }
    if($govde.Length -lt 60){ continue }
    $metin = if($govde.Length -gt 1800){ $govde.Substring(0,1800) } else { $govde }
    if($tur -match 'kerrer'){ $md = "muk. m.$no" } elseif($tur -match 'Ek Ge'){ $md = "ek gec. m.$no" } elseif($tur -match 'Ge'){ $md = "gec. m.$no" } elseif($tur -match 'Ek'){ $md = "ek m.$no" } else { $md = "m.$no" }
    $ad = if($pre){ "$kanunAd $md - $pre" } else { "$kanunAd $md" }
    $docs.Add([ordered]@{ tur="kanun-madde"; kaynak_ad=$ad; baslik=$pre; metin=$metin; kaynak_url=$url; belge_tarihi=$bugun })
  }
  $g=@{}; foreach($d in $docs){ $k=$d.kaynak_ad; if($g.ContainsKey($k)){ $g[$k]++; $d.kaynak_ad="$k ($($g[$k]))" } else { $g[$k]=1 } }
  return $docs
}

function Sha([string]$s){ $sha=[Security.Cryptography.SHA256]::Create(); ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($s))) -replace '-','').Substring(0,16) }

$KEY = $env:SUPABASE_SERVICE_KEY
$H = if($KEY){ @{ apikey=$KEY; Authorization="Bearer $KEY" } } else { $null }
$degisen = New-Object System.Collections.Generic.List[string]

foreach($law in $manifest.kanunlar){
  $txt = Join-Path $txtDir "$($law.slug).txt"
  if(-not (Test-Path $txt)){
    # YEDEK YOL: indirme basarisiz (mevzuat.gov.tr runner'a yavas/kapali olabilir).
    # Kanun _durum'da hic yoksa (hic yuklenmemis) ama repoda hazir JSON varsa ONDAN yukle.
    # _durum'a hash YAZILMAZ -> kaynak indirilebildigi ilk gun gercek metinden yeniden yutulur.
    $hazirJson = Join-Path $mevzuatDir "$($law.slug).json"
    if($H -and -not $durum.ContainsKey($law.slug) -and (Test-Path $hazirJson)){
      try {
        $hd = (Get-Content $hazirJson -Raw -Encoding UTF8 | ConvertFrom-Json).belgeler
        foreach($d in @($hd)){ if($d.tur -eq 'kanun' -or -not $d.tur){ $d.tur = 'kanun-madde' } }   # 'kanun'->normalize; 'teblig' KORUNUR
        if(@($hd).Count -ge 5){
          $adPrefix = "$($law.ad)"; $q = [uri]::EscapeDataString("$adPrefix*")
          try { Invoke-RestMethod -Method Delete -Uri "$SB_URL/rest/v1/dokumanlar?tur=eq.kanun-madde&kaynak_ad=like.$q" -Headers ($H + @{ Prefer="return=minimal" }) -TimeoutSec 120 | Out-Null } catch {}
          for($i=0; $i -lt @($hd).Count; $i += 500){
            $son=[Math]::Min($i+500,@($hd).Count)-1; $dilim=@($hd)[$i..$son]
            $bj=($dilim | ConvertTo-Json -Depth 5); if(@($dilim).Count -eq 1){ $bj="[$bj]" }
            Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/dokumanlar" -Headers ($H + @{ Prefer="return=minimal" }) -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($bj)) -TimeoutSec 180 | Out-Null
          }
          # durum izi birak: 'yedek-json' -> her kosuda TEKRAR yuklemez; gercek indirme
          # basarili oldugu ilk gun hash uyusmaz -> kaynaktan yeniden yutulur (ayna kurali)
          $durum[$law.slug] = @{ hash='yedek-json'; son_senkron=$bugun; madde=@($hd).Count; ad=$law.ad }
          $degisen.Add($law.slug) | Out-Null
          Write-Host ("YEDEKTEN YUKLENDI (indirme yok, repo JSON): {0} -> {1} madde" -f $law.ad, @($hd).Count)
        }
      } catch { Write-Host "  yedek yukleme HATA [$($law.slug)]: $_" }
    } else {
      Write-Host "ATLA (txt yok): $($law.slug)"
    }
    continue
  }
  # TEBLIG guard: 'G9:' onekli kaynaklar (KDV GUT gibi) bolum-yapilidir; madde-parcalayici
  # onlari BOZUK parcalar -> gunluk re-yut ATLANIR (fallback tek yol; teblig-parser v2'de).
  if("$($law.pdfId)" -like 'G9:*'){ Write-Host "TEBLIG (madde yapisi yok) - gunluk re-yut atlandi: $($law.ad)"; continue }
  $raw = Get-Content $txt -Raw -Encoding UTF8
  $flat = ($raw -replace "\r?\n"," ") -replace "\s+"," "
  $yhash = Sha $flat
  $eski = if($durum.ContainsKey($law.slug)){ "$($durum[$law.slug].hash)" } else { "" }
  if($yhash -eq $eski){ Write-Host ("DEGISMEDI: {0}" -f $law.ad); continue }

  $url = if("$($law.pdfId)" -like 'G7:*'){ "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$("$($law.pdfId)".Substring(3))&mevzuatTur=KurumVeKurulusYonetmeligi&mevzuatTertip=5" }
         else { "https://www.mevzuat.gov.tr/mevzuatmetin/$($law.pdfId).pdf" }
  $docs = Parcala $flat "$($law.ad)" $url
  if($docs.Count -lt 5){ Write-Host ("UYARI az madde ({0}) -> {1}, atlandi (indirme bozuk olabilir)" -f $docs.Count, $law.ad); continue }
  # dosyaya yaz
  $json = (@{ belgeler=$docs } | ConvertTo-Json -Depth 6)
  [IO.File]::WriteAllBytes((Join-Path $mevzuatDir "$($law.slug).json"), [Text.Encoding]::UTF8.GetBytes($json))
  $durum[$law.slug] = @{ hash=$yhash; son_senkron=$bugun; madde=$docs.Count; ad=$law.ad }  # DIKKAT: $h yazma — PS case-insensitive, $H(headers+anahtar) ile CAKISIR
  $degisen.Add($law.slug) | Out-Null
  Write-Host ("YENIDEN YUTULDU: {0} -> {1} madde (son senkron {2})" -f $law.ad, $docs.Count, $bugun)

  # Supabase: bu kanunun eski satirlarini sil + yeniden yukle (yalniz degisen kanun)
  if($H){
    $adPrefix = "$($law.ad)"
    $q = [uri]::EscapeDataString("$adPrefix*")
    try { Invoke-RestMethod -Method Delete -Uri "$SB_URL/rest/v1/dokumanlar?tur=eq.kanun-madde&kaynak_ad=like.$q" -Headers ($H + @{ Prefer="return=minimal" }) -TimeoutSec 120 | Out-Null } catch { Write-Host "  sil UYARI: $_" }
    for($i=0; $i -lt $docs.Count; $i += 500){
      $son=[Math]::Min($i+500,$docs.Count)-1; $dilim=$docs[$i..$son]
      $bj = ($dilim | ConvertTo-Json -Depth 5); if($dilim.Count -eq 1){ $bj="[$bj]" }
      $gonder=[Text.Encoding]::UTF8.GetBytes($bj)
      try { Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/dokumanlar" -Headers ($H + @{ Prefer="return=minimal" }) -ContentType "application/json; charset=utf-8" -Body $gonder -TimeoutSec 180 | Out-Null } catch { Write-Host ("  ekle HATA batch {0}: {1}" -f $i,$_) }
    }
    Write-Host ("  Supabase guncellendi: {0}" -f $law.ad)
  }
}

# durum dosyasini yaz (commit edilir)
$dj = ($durum | ConvertTo-Json -Depth 5)
[IO.File]::WriteAllBytes($durumYol, [Text.Encoding]::UTF8.GetBytes($dj))

if($degisen.Count -eq 0){ Write-Host "GUNLUK MEVZUAT: hicbir kanun degismemis - is yok." }
else { Write-Host ("GUNLUK MEVZUAT: {0} kanun yeniden yutuldu -> {1}" -f $degisen.Count, ($degisen -join ', ')) }

# ============================================================================
# ETKI ZINCIRI (23.07.2026): kanun DEGISTIYSE, o kanuna atif yapan site
# icerigi (bilgi-tabani kayitlari) "yeniden dogrula" kuyruguna dusurulur ve
# mail atilir. Icerik otomatik degistirilmez — insan teyidiyle guncellenir.
# Hata olsa bile hasadi bozmasin diye tamamen try/catch icinde.
# ============================================================================
try {
  if($degisen.Count -gt 0){
    $kbYol = Join-Path $kok "veri/bilgi-tabani.json"
    $kb = Get-Content $kbYol -Raw -Encoding UTF8 | ConvertFrom-Json
    # degisen slug -> kanun adi (manifest'ten); kaynak alaninda ad-parcasi ara
    $adlar = @{}
    foreach($l in $manifest.kanunlar){ if($degisen -contains $l.slug){ $adlar[$l.slug]=$l.ad } }
    $etkilenen = New-Object System.Collections.Generic.List[object]
    foreach($kayit in $kb.kayitlar){
      $kk = "$($kayit.kaynak)".ToLowerInvariant()
      foreach($slug in $adlar.Keys){
        $ad = $adlar[$slug].ToLowerInvariant()
        # esleme: kanun numarasi (or. 5520) veya kisaltma parcasi (parantez oncesi ilk kelime)
        $no = [regex]::Match($ad,'\d{3,4}').Value
        $kisa = ($ad -split '[\s\(]')[0]
        if(($no -and $kk -match [regex]::Escape($no)) -or ($kisa.Length -ge 3 -and $kk -match [regex]::Escape($kisa))){
          $etkilenen.Add([pscustomobject]@{ id=$kayit.id; konu=$kayit.konu; kaynak=$kayit.kaynak; kanun=$adlar[$slug]; tarih=$bugun })
          break
        }
      }
    }
    if($etkilenen.Count -gt 0){
      $kuyrukYol = Join-Path $kok "veri/yeniden-dogrula.json"
      $mev = if(Test-Path $kuyrukYol){ Get-Content $kuyrukYol -Raw -Encoding UTF8 | ConvertFrom-Json } else { [pscustomobject]@{ kayitlar=@() } }
      $lst = New-Object System.Collections.Generic.List[object]
      if($mev.kayitlar){ $lst.AddRange(@($mev.kayitlar)) }
      foreach($e in $etkilenen){ if(-not ($lst | Where-Object { $_.id -eq $e.id -and $_.kanun -eq $e.kanun })){ $lst.Add($e) } }
      $outq = [pscustomobject]@{ guncelleme=$bugun; kayitlar=$lst.ToArray() }
      [IO.File]::WriteAllText($kuyrukYol, ($outq | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
      Write-Host ("ETKI ZINCIRI: {0} icerik kaydi degisen kanunlara atif yapiyor -> yeniden-dogrula kuyruguna yazildi." -f $etkilenen.Count)
      if($env:RESEND_KEY){
        $sat = ($etkilenen | Select-Object -First 20 | ForEach-Object { "<li><b>$($_.id)</b> ($($_.konu)) — atif: $($_.kaynak) — degisen: $($_.kanun)</li>" }) -join ""
        $html = "<h3>Etki Zinciri uyarisi</h3><p>Bugun degisen kanun(lar): <b>$($degisen -join ', ')</b>. Bu kanunlara atif yapan $($etkilenen.Count) icerik kaydi yeniden dogrulama kuyruguna alindi (icerik canlida, otomatik degisiklik yok).</p><ul>$sat</ul><p>Tetikte — kanun aynasi</p>"
        $mb = @{ from=$env:RESEND_FROM; to=@("cemdizdar85@hotmail.com"); subject="TETIKTE ETKI ZINCIRI: degisen kanun $($etkilenen.Count) icerigi etkiliyor"; html=$html } | ConvertTo-Json -Depth 3
        try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization="Bearer $($env:RESEND_KEY)" } -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" | Out-Null } catch { Write-Host "etki maili hatasi: $_" }
      }
    } else { Write-Host "ETKI ZINCIRI: degisen kanunlara atif yapan icerik yok." }
  }
} catch { Write-Host "ETKI ZINCIRI UYARI (hasat etkilenmedi): $_" }
exit 0
