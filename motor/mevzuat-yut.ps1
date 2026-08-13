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
    # 14.08 KUSUR (olculdu, Yerli Mali Tebligi vakasi): bu kontrol "(Mülga" gordugu
    # anda maddeyi atiyordu - ama "(Mülga ibare:...)" / "(Mülga fıkra:...)" MADDENIN
    # KENDISI degil, ICINDEKI bir parca mulga demektir; madde yururlukte.
    # Somut zarar: Yerli Mali Tebligi m.4 (yerli mali kabul sartlari) ve m.8 (yerli
    # katki orani formulu) ambara HIC GIRMEDI - ikisi de "(1) Sanayi (Mülga ibare:
    # RG-15/10/2025-33048) urunlerinin..." diye basliyor. Kapsama %77,7'ye dusmustu.
    # Artik yalniz MADDENIN KENDISI mulgaysa atlanir: "(Mülga:" veya "(Mülga madde".
    if($govde -match '^.{0,70}\(Mülga\s*(?:madde)?\s*:'){ continue }
    # 02.08 CEM KURALI ("ustunkoru degil, en kucuk maddesine kadar"): 60
    # karakterden kisa madde ATILIYORDU. Kisa madde de maddedir (yururluk,
    # yurutme, tanim fikralari) ve soru-cevap araci onlari da arar. Artik
    # atilmaz - onceki maddeye eklenir, yani metin kaybi sifir.
    if($govde.Length -lt 60){
      if($docs.Count -gt 0){ $docs[$docs.Count-1].metin = "$($docs[$docs.Count-1].metin) $govde" }
      continue
    }
    if($tur -match 'kerrer'){ $md = "muk. m.$no" } elseif($tur -match 'Ek Ge'){ $md = "ek gec. m.$no" } elseif($tur -match 'Ge'){ $md = "gec. m.$no" } elseif($tur -match 'Ek'){ $md = "ek m.$no" } else { $md = "m.$no" }
    $ad = if($pre){ "$kanunAd $md - $pre" } else { "$kanunAd $md" }

    # 27.07.2026 DUZELTME — 1800 KESIGI:
    # Eski hal: $govde.Substring(0,1800) -> maddenin gerisi SESSIZCE KAYBOLUYORDU.
    # Olculdu: dosyalardaki 14.961 belgenin 1.730'u (%11,6) tam 1800 karakterde
    # kesikti. Somut zarar: SMK m.5'in muvafakatname fikrasi (5/3) ambarda YOKTU;
    # 27.07'de marka basvurusunda eksik bilgiyle konusuldu, RG metnine gidilerek
    # yakalandi. En cok etkilenen: SGK 5510 (132), Gumruk Yon. (103), SSIY (61),
    # VUK (59), SPK (58), GVK (57), TTK (53).
    # Yeni hal: KESMIYOR, PARCALIYOR. Uzun madde ~1800'luk parcalara CUMLE
    # SINIRINDAN bolunur; her parca ayri kayit olur, adina [1/3] eki gelir.
    # Tam metin korunur, kayitlar aramaya/retrieval'a uygun boyutta kalir.
    $PARCA_BOY = 1800
    $parcalar = New-Object System.Collections.Generic.List[string]
    if($govde.Length -le $PARCA_BOY){ $parcalar.Add($govde) }
    else {
      $kalan = $govde
      while($kalan.Length -gt $PARCA_BOY){
        $kes = $kalan.Substring(0, $PARCA_BOY)
        $kir = $kes.LastIndexOf('. ')                     # once cumle sonu
        if($kir -lt 900){ $kir = $kes.LastIndexOf(' ') }  # olmazsa son bosluk
        if($kir -lt 900){ $kir = $PARCA_BOY - 1 }         # o da olmazsa duz kes
        $parcalar.Add($kalan.Substring(0, $kir+1).Trim())
        $kalan = $kalan.Substring($kir+1).Trim()
      }
      if($kalan.Length -gt 0){ $parcalar.Add($kalan) }
    }
    for($p=0; $p -lt $parcalar.Count; $p++){
      $adTam = if($parcalar.Count -eq 1){ $ad } else { "$ad [$($p+1)/$($parcalar.Count)]" }
      $docs.Add([ordered]@{ tur="kanun-madde"; kaynak_ad=$adTam; baslik=$pre; metin=$parcalar[$p]; kaynak_url=$url; belge_tarihi=$bugun })
    }
  }
  $g=@{}; foreach($d in $docs){ $k=$d.kaynak_ad; if($g.ContainsKey($k)){ $g[$k]++; $d.kaynak_ad="$k ($($g[$k]))" } else { $g[$k]=1 } }
  return $docs
}

function Sha([string]$s){ $sha=[Security.Cryptography.SHA256]::Create(); ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($s))) -replace '-','').Substring(0,16) }

$KEY = $env:SUPABASE_SERVICE_KEY
# 07.08: sb_secret anahtar robot User-Agent ister ("Forbidden use of secret API
# key in browser") - UA'siz IRM tarayici sayilip TUM ekleri reddediyordu.
$H = if($KEY){ @{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' } } else { $null }
$degisen = New-Object System.Collections.Generic.List[string]

foreach($law in $manifest.kanunlar){
  # ==========================================================================
  #  SADECE filtresi (05.08 - kurtarma hatti icin)
  #
  #  NEDEN: son 5 gunluk-ayna kosusunun BESI de iptal (03.08 12:42'den beri).
  #  Olum sarmali: kosu 6 saatlik GitHub tavaninda oluyor -> _durum.json hic
  #  commit'lenmiyor -> sonraki kosu her seyi "ilk kez" sanip 650 kaynagi
  #  bastan indiriyor -> yine tavana takiliyor. Sonuc: 2 gundur ambara TEK
  #  kaynak inmedi; 6 SMMM yonetmeligi de bu batakta bekliyordu.
  #
  #  SADECE="slug1,slug2" verilirse yalniz o kaynaklar islenir - kucuk
  #  kurtarma kosulari tam turun kaderine bagli olmaz. Bos/verilmemisse
  #  davranis eskisiyle BIREBIR ayni (tam tur).
  # ==========================================================================
  if("$($env:SADECE)".Trim() -ne ''){
    $sadeceListe = @("$($env:SADECE)" -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    if($sadeceListe -notcontains "$($law.slug)"){ continue }
  }
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
  # 02.08 CEM KURALI: TEBLIGLER ARTIK ATLANMIYOR. Eski hal: 'G9:' onekli
  # kaynaklar (KDV GUT, VUK 509, KVK GUT, SPK II-17.1) madde yapili olmadigi
  # icin gunluk aynada HIC yutulmuyordu - yani teblig degisse bile ambar eski
  # kaliyordu ve soru-cevap araci bayat metinle cevap veriyordu. Artik madde
  # deseni tutmazsa BOLUM parcalayicisi devreye girer (asagida), metin ambara
  # tam girer. Kural: "okumadigimiz metin kalmayacak".
  # SEYREK KAYNAK (02.08): teblig arsivi (yuzlerce VUK GT) her gun indirilmez -
  # bir kez yutulur, sonra HAFTADA BIR (pazar) tazelenir. ZORLA hepsini acar.
  # Amac: kanunlarin gunluk tazeligi 185 tebligin indirme yuku yuzunden gecikmesin.
  if($law.PSObject.Properties['seyrek'] -and $law.seyrek -eq $true){
    $ilkKez = -not $durum.ContainsKey($law.slug)
    $pazar  = ((Get-Date).DayOfWeek -eq 'Sunday')
    $zorla  = ("$($env:ZORLA)" -eq "1" -or "$($env:ZORLA)" -eq "true")
    if(-not ($ilkKez -or $pazar -or $zorla)){ continue }
  }
  $raw = Get-Content $txt -Raw -Encoding UTF8
  $flat = ($raw -replace "\r?\n"," ") -replace "\s+"," "
  $yhash = Sha $flat
  $eski = if($durum.ContainsKey($law.slug)){ "$($durum[$law.slug].hash)" } else { "" }
  # ZORLA=1: hash ayni olsa bile yeniden yut. Parcalayici degistiginde (or.
  # 27.07 1800-kesigi duzeltmesi) kanun metni degismedigi icin hash de aynidir
  # ve hicbir kanun yeniden yutulmaz; bu bayrak o kapiyi acar.
  if($yhash -eq $eski -and "$($env:ZORLA)" -ne "1" -and "$($env:ZORLA)" -ne "true"){ Write-Host ("DEGISMEDI: {0}" -f $law.ad); continue }
  if($yhash -eq $eski){ Write-Host ("ZORLA: {0} (hash ayni ama yeniden yutuluyor)" -f $law.ad) }

  $url = if("$($law.pdfId)" -like 'G7:*'){ "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$("$($law.pdfId)".Substring(3))&mevzuatTur=KurumVeKurulusYonetmeligi&mevzuatTertip=5" }
         else { "https://www.mevzuat.gov.tr/mevzuatmetin/$($law.pdfId).pdf" }
  $docs = Parcala $flat "$($law.ad)" $url
  # 02.08 CEM KURALI: madde deseni tutmayan metin (teblig/bolum yapili) ARTIK
  # ATLANMIYOR - bolum bolum yutuluyor. Eski hal "az madde -> atlandi" diyip
  # metni ambarin disinda birakiyordu. Indirme gercekten bozuksa metin cok
  # kisadir; o durumda (<4.000 karakter) atlama korunur.
  if($docs.Count -lt 5){
    # 07.08: esik 4000 -> 300. Oran/had tebligleri (orn. VUK GT 585, 688 kr)
    # GERCEKTEN tek paragraftir ve 4000 esigi onlari "bozuk" diye disarida
    # birakiyordu. Bozuk-indirme riski artik kaynakta cozuldu: yerel-ayna
    # %PDF imzasi dogruluyor, bot HTML'i buraya ulasamiyor.
    if($flat.Length -lt 300){ Write-Host ("UYARI cok kisa metin ({0} kr) -> {1}, atlandi (indirme bozuk)" -f $flat.Length, $law.ad); continue }
    Write-Host ("MADDE DESENI TUTMADI ({0} parca) -> {1}: BOLUM parcalayicisi devrede" -f $docs.Count, $law.ad)
    $docs = New-Object System.Collections.Generic.List[object]
    $BOY = 1800; $d = 0; $n = 1
    while($d -lt $flat.Length){
      $boy = [Math]::Min($BOY, $flat.Length - $d)
      $kes = $flat.Substring($d, $boy)
      if($d + $boy -lt $flat.Length){
        $kir = $kes.LastIndexOf('. ')
        if($kir -lt 900){ $kir = $kes.LastIndexOf(' ') }
        if($kir -ge 900){ $kes = $kes.Substring(0, $kir+1); $boy = $kir+1 }
      }
      $docs.Add([ordered]@{ tur="kanun-madde"; kaynak_ad=("$($law.ad) bolum $n"); baslik=""; metin=$kes.Trim(); kaynak_url=$url; belge_tarihi=$bugun })
      $d += $boy; $n++
    }
  }
  # KAPSAMA KAPISI (02.08): kaynak metnin yuzde kaci ambara girdi? %98 alti KIRMIZI.
  $ambarKr = ((($docs | ForEach-Object { $_.metin }) -join ' ') -replace '\s+',' ').Length
  $kapsama = if($flat.Length -gt 0){ [math]::Round(100*$ambarKr/$flat.Length,1) } else { 0 }
  if($kapsama -lt 98){ Write-Host ("  KAPSAMA UYARISI: {0} -> %{1} (mulga maddeler dusuldugunde normal olabilir)" -f $law.ad, $kapsama) }
  else { Write-Host ("  kapsama %{0}" -f $kapsama) }
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

# ============================================================================
# SORU ETKI ZINCIRI (13.08.2026 — Cem: "kanun-degisince-soru-askiya, yapalim"):
# kanun DEGISTIYSE, o kanuna dayanan YAYINDAKI sorular OTOMATIK ASKIYA alinir
# (yayin=false + yayin_notu damgasi). Soru masum kanitlanana dek yayinda kalmaz;
# okuyucu hatti yeniden dogrulayinca insan karariyla geri acilir. try/catch:
# hata olsa bile hasat bozulmaz.
# ============================================================================
try {
  if($degisen.Count -gt 0 -and $H){
    $kanunNolar = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($l in $manifest.kanunlar){
      if($degisen -contains $l.slug){
        $no = [regex]::Match("$($l.ad)",'\b\d{3,5}\b').Value
        if(-not $no){ $no = [regex]::Match("$($l.slug)",'\d{3,5}').Value }
        if($no){ [void]$kanunNolar.Add($no) }
      }
    }
    if($kanunNolar.Count -gt 0){
      $inListe = ($kanunNolar | ForEach-Object { '"' + $_ + '"' }) -join ','
      $sr = Invoke-WebRequest -UseBasicParsing -Uri "$SB_URL/rest/v1/soru_havuzu?select=id,ders,kanun_no&yayin=eq.true&kanun_no=in.($inListe)&limit=2000" -Headers $H -TimeoutSec 120
      $askiAday = @(([Text.Encoding]::UTF8.GetString($sr.RawContentStream.ToArray()) | ConvertFrom-Json))
      if($askiAday.Count -gt 0){
        $notMetni = "ETKI-ZINCIRI ASKISI $bugun : dayandigi kanun degisti ($(($kanunNolar) -join ',')) - okuyucu yeniden dogrulayana kadar yayin disi."
        $govde = (@{ yayin=$false; yayin_notu=$notMetni } | ConvertTo-Json)
        foreach($grup in ($askiAday | Group-Object { [math]::Floor([array]::IndexOf($askiAday,$_)/100) })){
          $idIn = ($grup.Group | ForEach-Object { '"' + $_.id + '"' }) -join ','
          Invoke-RestMethod -Method Patch -Uri "$SB_URL/rest/v1/soru_havuzu?id=in.($idIn)" -Headers ($H + @{ Prefer='return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120 | Out-Null
        }
        Write-Host ("SORU ETKI ZINCIRI: {0} yayindaki soru askiya alindi (kanun: {1})." -f $askiAday.Count, ($kanunNolar -join ', '))
        if($env:RESEND_KEY){
          $sat2 = ($askiAday | Select-Object -First 25 | ForEach-Object { "<li><b>$($_.id)</b> ($($_.ders)) — kanun $($_.kanun_no)</li>" }) -join ""
          $html2 = "<h3>Soru Etki Zinciri</h3><p>Degisen kanun(lar) <b>$($kanunNolar -join ', ')</b> nedeniyle <b>$($askiAday.Count)</b> yayindaki soru OTOMATIK ASKIYA alindi. Okuyucu hatti yeniden dogrulayinca insan karariyla acilir.</p><ul>$sat2</ul><p>Tetikte — soru sigortasi</p>"
          $mb2 = @{ from=$env:RESEND_FROM; to=@("cemdizdar85@hotmail.com"); subject="TETIKTE SORU ASKISI: kanun degisti, $($askiAday.Count) soru yayindan cekildi"; html=$html2 } | ConvertTo-Json -Depth 3
          try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization="Bearer $($env:RESEND_KEY)" } -Body ([Text.Encoding]::UTF8.GetBytes($mb2)) -ContentType "application/json" | Out-Null } catch { Write-Host "soru-aski maili hatasi: $_" }
        }
      } else { Write-Host "SORU ETKI ZINCIRI: degisen kanunlara dayanan yayinda soru yok." }
    }
  }
} catch { Write-Host "SORU ETKI ZINCIRI UYARI (hasat etkilenmedi): $_" }
exit 0
