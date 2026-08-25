# ============================================================================
#  SIRALAMA TARTISI — madde_ara puanlama formullerini CANLIYA YAZMADAN olcer
#
#  NEDEN (25.08.2026): Bu depoda sıralama formulu denemenin tek yolu, canli
#  veritabanina `create or replace function` basip altin testi kosturmakti.
#  Bedeli kayitli:
#    v3 (17.07) — IDF agirligi, DOGRU fikir, canliya yazildi -> statement
#                 timeout 57014 -> geri alindi
#    v6 (19.08) — kelime kokune inme, canliya yazildi -> isabet 48/48'den
#                 41/48'e DUSTU -> geri alindi
#  Yani iki tur "canlida dene, boz, geri al" yasandi. Sebep formullerin kotu
#  olmasi degil, ONCEDEN OLCULEMEMESIYDI.
#
#  25.08'de ayni tuzagin esigine bir daha gelindi: altin test 38 gun kor
#  kostuktan sonra 40/48'e dusmus bulundu; "cesitlilik tavani" cozum diye
#  onerildi. Simule edilince 7 dusen vakadan yalniz 1'ini duzelttigi goruldu.
#  Canliya yazilsaydi ucuncu geri-alma turu olacakti.
#
#  BU ARAC O TURU BITIRIR: aday havuzunu BIR KEZ diske ceker, sonra formuller
#  saniyeler icinde CEVRIMDISI denenir ve 48 altin vakaya karsi skorlanir.
#  Kazanan formul bulunmadan SQL yazilmaz.
#
#  SADAKAT: eslesmeler belgenin KENDI `arama_fold` tsvector'unden okunur
#  (Postgres'in urettigi sozcukler), df ise PostgREST fts sayimiyla ALINIR.
#  Yani puanlama girdileri canlidakiyle ayni; taklit edilen sey yok.
#
#  KULLANIM:
#    pwsh arac/sirala-tarti.ps1 -Topla    # havuzu cek (bir kez, ~birkac dk)
#    pwsh arac/sirala-tarti.ps1 -Dene     # formulleri skorla (saniyeler)
#    pwsh arac/sirala-tarti.ps1 -Dene -Ayrinti   # dusen vakalari da yaz
#
#  Havuz dosyasi buyuktur ve TUREVDIR -> veri/ degil, yerel onbellek olarak
#  .tarti-havuz.json'a yazilir ve .gitignore'a girer (depoyu sismanlatmayiz).
# ============================================================================
param(
  [switch]$Topla,
  [switch]$Dene,
  [switch]$Dil,         # DIL KANALI: sorgu on-islemesi varyantlarini UCTAN UCA olcer
  [switch]$Kapak,       # CESITLILIK TAVANI: ek soyma + ayni madde/belge elemesi
  [switch]$Ayrinti,
  [int]$Aday = 300,     # madde_ara'nin aday havuzu (v7: limit 300)
  [int]$Vaka = 0        # yalniz ilk N altin vakayi topla (hizli deneme; 0 = hepsi)
)
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'

$kok = Split-Path -Parent $PSScriptRoot
$SB  = 'https://bjrleanjpyujtajmazxn.supabase.co'
$KEY = if ($env:SB_PUBLISHABLE) { $env:SB_PUBLISHABLE } else { 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' }
$H   = @{ apikey = $KEY; Authorization = "Bearer $KEY" }
$havuzYol = Join-Path $kok '.tarti-havuz.json'
$setYol   = Join-Path $kok 'veri/ambar-altin-test.json'

# --- ambar-testi.ps1 / edge net-cevap.ts ile AYNI on-isleme (sapmamali) ---
$STOP = @('var','varsa','yok','kac','ne','nasil','mi','mu','olur','odeme','sure','suresi','icin','ile','bir','bu','kesilir','geldi','aldim','nedir','kadar','gibi','daha','cok','hangi')
function Fold([string]$s) {
  $s = $s.ToLower([System.Globalization.CultureInfo]::GetCultureInfo('tr-TR'))
  ($s -replace 'ı','i' -replace 'ş','s' -replace 'ğ','g' -replace 'ü','u' -replace 'ö','o' -replace 'ç','c' -replace 'â','a' -replace 'î','i' -replace 'û','u')
}
function Jetonla([string]$soru) {
  $t = (Fold $soru) -replace '[^\w\s]',' ' -split '\s+' | Where-Object { $_.Length -ge 3 -and $STOP -notcontains $_ } | Select-Object -First 8
  # KURUM TAKMA ADI (edge ile ayni)
  @($t | ForEach-Object { if ($_ -eq 'sgk') { 'sigortali','sosyal','prim' } else { $_ } }) | Select-Object -First 8
}
# v7 ile ayni: to_tsquery('simple', w||':*') oncesi 15 karaktere kirpma + temizlik
function V7Jeton([string]$w) { $x = ($w -replace '[^a-z0-9]',''); if ($x.Length -gt 15) { $x.Substring(0,15) } else { $x } }

# ---------------------------------------------------------------------------
#  TOPLAMA
# ---------------------------------------------------------------------------
function Topla-Havuz {
  $set = Get-Content -Raw -Encoding UTF8 $setYol | ConvertFrom-Json
  $vakalar = @($set.vakalar)
  if ($Vaka -gt 0 -and $Vaka -lt $vakalar.Count) { $vakalar = @($vakalar | Select-Object -First $Vaka); Write-Host ("KISITLI DENEME: ilk {0} vaka" -f $Vaka) }
  Write-Host ("Altin vaka: {0}" -f $vakalar.Count)

  # 25.08 OLCUMU: Supabase bu ucta ISTEK YAGMURUNU 500 ile kesiyor (ardisik
  # cagrilarda bir gelen bir dusen desen gorulddu; ayni cagri sakin ortamda
  # 12/12 basarili). Bu bir SORGU hatasi degil, HIZ meselesi. Onun icin her
  # dis cagri fren + geri-cekilmeli tekrar ile sarilir.
  $script:sonCagri = [datetime]::MinValue
  function Fren([int]$ms = 1200) {
    $gecen = ([datetime]::UtcNow - $script:sonCagri).TotalMilliseconds
    if ($gecen -lt $ms) { Start-Sleep -Milliseconds ([int]($ms - $gecen)) }
    $script:sonCagri = [datetime]::UtcNow
  }
  # HATA YUTULMAZ: ilk surumde son hatanin metni atiliyordu ve toplama
  # "4 denemede de dustu" deyip SEBEBI SOYLEMIYORDU - kor kalindi, sebep
  # tahminle arandi. Artik gercek istisna mesaji tasinir.
  function Cagir([scriptblock]$is, [string]$etiket) {
    $sonHata = ''
    foreach ($d in 1..4) {
      Fren
      try { return (& $is) }
      catch {
        $sonHata = $_.Exception.Message
        if ($_.Exception.Response) {
          try {
            $sr = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
            $g = $sr.ReadToEnd(); $sr.Close()
            if ($g) { $sonHata += " || govde: " + $g.Substring(0, [Math]::Min(300, $g.Length)) }
          } catch {}
        }
        if ($d -eq 4) { throw "$etiket : 4 deneme -> $sonHata" }
        Start-Sleep -Seconds (3 * $d)
      }
    }
  }

  $dfOnbellek = @{}
  function Df([string]$tok) {
    if ($dfOnbellek.ContainsKey($tok)) { return $dfOnbellek[$tok] }
    $u = "$SB/rest/v1/dokumanlar?select=id&arama_fold=fts(simple)." + [uri]::EscapeDataString($tok + ':*') + "&limit=1"
    $n = Cagir {
      $r = Invoke-WebRequest -Uri $u -Headers ($H + @{ Prefer = 'count=exact' }) -UseBasicParsing
      [int](("$($r.Headers['Content-Range'])") -replace '.*/','')
    } "df($tok)"
    $dfOnbellek[$tok] = $n
    return $n
  }
  # cikmis% disi toplam (v7'nin N'i) — agirlik paydasiyla ayni tanim
  # Bu sayim da frenli/tekrarli olmali: 25.08'de sarmalsiz birakildigi icin
  # hiz sinirina takilinca TUM toplama daha ilk satirda dustu.
  $N = Cagir {
    $rn = Invoke-WebRequest -Uri "$SB/rest/v1/dokumanlar?select=id&tur=not.like.cikmis*&limit=1" -Headers ($H + @{ Prefer='count=exact' }) -UseBasicParsing
    [int](("$($rn.Headers['Content-Range'])") -replace '.*/','')
  } "N-sayimi"
  Write-Host ("Ambar (cikmis% haric): {0}" -f $N)

  $cikti = [ordered]@{ uretim=(Get-Date -Format 'dd.MM.yyyy HH:mm'); N=$N; aday=$Aday; vakalar=@() }
  $i = 0
  foreach ($v in $vakalar) {
    $i++
    $jet = @(Jetonla $v.soru | ForEach-Object { V7Jeton $_ } | Where-Object { $_.Length -ge 3 })
    if (-not $jet) { Write-Host ("  [{0}/{1}] ATLANDI (jeton yok): {2}" -f $i,$vakalar.Count,$v.soru); continue }

    $govde = @{ sorgu = ($jet -join ' '); adet = $Aday } | ConvertTo-Json -Compress
    # ALAN KISITI SART (25.08 olcumu): adet=300'u TAM govdeyle istemek 1.449 KB
    # / 6 sn ediyor ve ilk cagridan sonra ard arda 500 aliniyordu (ilk toplama
    # kosusu 48 vakadan 47'sini boyle kaybetti). select ile daraltinca ayni
    # sorgu 501 KB / 1,3 sn ve ard arda sorunsuz kosuyor. 'metin' cikarildi:
    # yalniz uzunluk-normalizasyonu formulu icin gerekiyordu, o hipotez de
    # 25.08'de dogrudan olculup CURUTULDU (parcalar tekduze boyutta).
    $sec = "?select=kaynak_ad,tur,arama_fold"
    $urlRpc = "$SB/rest/v1/rpc/madde_ara$sec"
    # DEGISKEN CAKISMASI TUZAGI (25.08, bu betikte CANLI yasandi): sonuc
    # degiskeni once `$aday` idi ve parametre `$Aday`. PowerShell buyuk/kucuk
    # harf AYIRMAZ -> ikisi AYNI degisken. Ilk vakadan sonra parametre sonuc
    # dizisiyle eziliyor, sonraki istek `{"adet":[{...300 kayit...}]}` olarak
    # gidiyor ve PostgREST 400 donuyordu. Ilk kosuda 48 vakanin 47'si boyle
    # kayboldu ve sebep "hiz siniri" sanildi. Ders hafizada ZATEN yaziliydi
    # (ps-degisken-cakismasi) - yazili ders korumuyor. Ad artik ayrik.
    try {
      $sonucSet = Cagir { ,@(Invoke-RestMethod -Method Post -Uri $urlRpc -Headers $H -ContentType 'application/json' -Body $govde) } "rpc"
    } catch { Write-Host ("  [{0}/{1}] ATLANDI ({2}): {3}" -f $i,$vakalar.Count,$_.Exception.Message,$v.soru); continue }
    $sonucSet = @($sonucSet)
    if ($sonucSet.Count -eq 0) { Write-Host ("  [{0}/{1}] ATLANDI (0 aday): {2}" -f $i,$vakalar.Count,$v.soru); continue }

    $agir = @(); foreach ($t in $jet) { $agir += [Math]::Log(($N + 1) / ([double](Df $t) + 1)) + 0.3 }

    # ArrayList: `$dizi += [ordered]@{}` deseni PS 5.1'de guvenilmez sayim
    # uretiyordu (ilk kosuda her vaka "1 aday" gorundu). Add() ile kesin.
    $kayitlar = New-Object System.Collections.ArrayList
    foreach ($d in $sonucSet) {
      # arama_fold tsvector metnini sozcuk kumesine cevir: 'kelime':1,7 'digeri':3
      $sozcuk = @([regex]::Matches("$($d.arama_fold)", "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
      $eslesen = New-Object System.Collections.ArrayList
      for ($k = 0; $k -lt $jet.Count; $k++) {
        $p = $jet[$k]
        foreach ($w in $sozcuk) { if ($w.StartsWith($p)) { [void]$eslesen.Add($k); break } }
      }
      [void]$kayitlar.Add([ordered]@{
        ad = [string]$d.kaynak_ad
        tur = [string]$d.tur
        e = @($eslesen)       # eslesen jeton indeksleri
      })
    }
    $cikti.vakalar += [ordered]@{
      soru = [string]$v.soru
      beklenen = @($v.beklenen)
      jetonlar = $jet
      agirlik = $agir
      adaylar = $kayitlar
    }
    Write-Host ("  [{0}/{1}] {2}  -> {3} aday" -f $i,$vakalar.Count,$v.soru,$kayitlar.Count)
  }
  [IO.File]::WriteAllText($havuzYol, ($cikti | ConvertTo-Json -Depth 8 -Compress), (New-Object Text.UTF8Encoding($false)))
  Write-Host ""
  Write-Host ("-> {0}  ({1:N1} MB, {2} vaka, {3} farkli jeton)" -f $havuzYol, ((Get-Item $havuzYol).Length/1MB), $cikti.vakalar.Count, $dfOnbellek.Count)
}

# ---------------------------------------------------------------------------
#  FORMULLER — hepsi (aday, vakaBilgisi) alir, PUAN doner. Yenisini eklemek
#  icin listeye bir satir yazmak yeter; canli veritabanina dokunulmaz.
# ---------------------------------------------------------------------------
$FORMULLER = [ordered]@{

  # CANLIDAKI (v7). Karsilastirma tabani budur.
  'v7-canli' = {
    param($a,$v)
    $s = 0.0; foreach ($k in $a.e) { $s += $v.agirlik[$k] }
    $tw = switch ($a.tur) { 'teori-notu' { 0.55 } 'standart' { 0.85 } default { 1.0 } }
    $s * $tw * (1 + 0.35 * [Math]::Max($a.e.Count - 1, 0))
  }

  # v7 + ambardaki GERCEK tur adi ('standart' degil 'standart-madde' — v7'deki
  # dal hic eslesmiyordu, olu koddu).
  'v7+turadi' = {
    param($a,$v)
    $s = 0.0; foreach ($k in $a.e) { $s += $v.agirlik[$k] }
    $tw = switch ($a.tur) { 'teori-notu' { 0.55 } 'standart-madde' { 0.85 } default { 1.0 } }
    $s * $tw * (1 + 0.35 * [Math]::Max($a.e.Count - 1, 0))
  }

  # IDF TAVANI: nadir ama alakasiz soru kelimesi ('baglar' df=100) formulu
  # ele geciriyordu. Agirligi tavanlayinca cop kelime belgeyi tek basina
  # yukari cekemez.
  'idf-tavan-3' = {
    param($a,$v)
    $s = 0.0; foreach ($k in $a.e) { $s += [Math]::Min($v.agirlik[$k], 3.0) }
    $tw = switch ($a.tur) { 'teori-notu' { 0.55 } 'standart-madde' { 0.85 } default { 1.0 } }
    $s * $tw * (1 + 0.35 * [Math]::Max($a.e.Count - 1, 0))
  }
  'idf-tavan-2' = {
    param($a,$v)
    $s = 0.0; foreach ($k in $a.e) { $s += [Math]::Min($v.agirlik[$k], 2.0) }
    $tw = switch ($a.tur) { 'teori-notu' { 0.55 } 'standart-madde' { 0.85 } default { 1.0 } }
    $s * $tw * (1 + 0.35 * [Math]::Max($a.e.Count - 1, 0))
  }

  # KAPSAMA ORANI: mutlak jeton sayisi yerine sorgunun YUZDE KACINI karsiladigi.
  # Uzun sorularda 'daha cok kelime tutturan kazanir' etkisini kirar.
  'kapsama-orani' = {
    param($a,$v)
    $s = 0.0; foreach ($k in $a.e) { $s += $v.agirlik[$k] }
    $tw = switch ($a.tur) { 'teori-notu' { 0.55 } 'standart-madde' { 0.85 } default { 1.0 } }
    $s * $tw * ($a.e.Count / [double]$v.jetonlar.Count)
  }

  # EN NADIR JETON SARTI: sorgunun en ayirt edici kelimesini icermeyen belge
  # agir ceza alir (VUK m.5 'mahremiyet'i iceriyordu ama 'kimleri'/'baglar'
  # tutturan alakasiz belgelere yeniliyordu).
  'en-nadir-sart' = {
    param($a,$v)
    $enNadir = 0; for ($i=1; $i -lt $v.agirlik.Count; $i++) { if ($v.agirlik[$i] -gt $v.agirlik[$enNadir]) { $enNadir = $i } }
    $s = 0.0; foreach ($k in $a.e) { $s += $v.agirlik[$k] }
    $tw = switch ($a.tur) { 'teori-notu' { 0.55 } 'standart-madde' { 0.85 } default { 1.0 } }
    $ceza = if ($a.e -contains $enNadir) { 1.0 } else { 0.25 }
    $s * $tw * $ceza * (1 + 0.35 * [Math]::Max($a.e.Count - 1, 0))
  }

  # IDF tavani + kapsama orani birlikte
  'tavan3+kapsama' = {
    param($a,$v)
    $s = 0.0; foreach ($k in $a.e) { $s += [Math]::Min($v.agirlik[$k], 3.0) }
    $tw = switch ($a.tur) { 'teori-notu' { 0.55 } 'standart-madde' { 0.85 } default { 1.0 } }
    $s * $tw * ($a.e.Count / [double]$v.jetonlar.Count)
  }

  # IDF tavani + en-nadir sarti birlikte
  'tavan3+nadir' = {
    param($a,$v)
    $enNadir = 0; for ($i=1; $i -lt $v.agirlik.Count; $i++) { if ($v.agirlik[$i] -gt $v.agirlik[$enNadir]) { $enNadir = $i } }
    $s = 0.0; foreach ($k in $a.e) { $s += [Math]::Min($v.agirlik[$k], 3.0) }
    $tw = switch ($a.tur) { 'teori-notu' { 0.55 } 'standart-madde' { 0.85 } default { 1.0 } }
    $ceza = if ($a.e -contains $enNadir) { 1.0 } else { 0.25 }
    $s * $tw * $ceza * (1 + 0.35 * [Math]::Max($a.e.Count - 1, 0))
  }
}
# NOT: 'uzunluk-norm' formulu KALDIRILDI. Hipotez (uzun belge kisa maddeyi
# eziyor) 25.08'de dogrudan olculup curutuldu: kazananlar ~1.535-1.689 kr,
# beklenen belge ~1.137-1.789 kr — parcalar tekduze boyutta. Formulu tutmak
# icin her adayin metin uzunlugunu cekmek gerekiyordu, o da cevabi 1,4 MB'a
# cikarip toplamayi dusuruyordu. Curutulmus hipotez icin bedel odenmez.

# CESITLILIK TAVANI: puanlamadan BAGIMSIZ bir son-suzgec. Ayni maddeden en
# fazla 1, ayni belgeden en fazla 2 parca. Her formulle birlestirilebilir.
function MaddeAnahtar([string]$k) { ($k -replace '\s*\[\d+/\d+\]\s*$','').Trim() }
function BelgeAnahtar([string]$k) {
  $x = MaddeAnahtar $k
  $x = [regex]::Replace($x, '\s+((gec\.|muk\.|mük\.|ek|mükerrer)\s+)?m\.\s*\d.*$', '')
  $x = [regex]::Replace($x, '\s+(bolum|bölüm)\s+\d.*$', '', 'IgnoreCase')
  $x.Trim()
}

function Skorla([scriptblock]$formul, [bool]$cesitlilik) {
  $havuz = Get-Content -Raw -Encoding UTF8 $havuzYol | ConvertFrom-Json
  $gecen = 0; $dusenler = @()
  foreach ($v in $havuz.vakalar) {
    $puanli = foreach ($a in $v.adaylar) { [pscustomobject]@{ ad=$a.ad; p=(& $formul $a $v) } }
    $sirali = $puanli | Sort-Object -Property p -Descending
    $ust = @(); $mS = @{}; $bS = @{}
    foreach ($d in $sirali) {
      if ($cesitlilik) {
        $mk = MaddeAnahtar $d.ad; $bk = BelgeAnahtar $d.ad
        if ([int]$mS[$mk] -ge 1) { continue }
        if ([int]$bS[$bk] -ge 2) { continue }
        $mS[$mk] = [int]$mS[$mk] + 1; $bS[$bk] = [int]$bS[$bk] + 1
      }
      $ust += $d
      if ($ust.Count -ge 6) { break }
    }
    $adlar = $ust | ForEach-Object { Fold $_.ad }
    $tuttu = $false
    foreach ($b in @($v.beklenen)) { if ($adlar | Where-Object { $_ -like "*$b*" }) { $tuttu = $true; break } }
    if ($tuttu) { $gecen++ } else { $dusenler += $v.soru }
  }
  [pscustomobject]@{ Gecen=$gecen; Toplam=@($havuz.vakalar).Count; Dusenler=$dusenler }
}

function Dene-Formuller {
  if (-not (Test-Path $havuzYol)) { Write-Host "Havuz yok. Once: pwsh arac/sirala-tarti.ps1 -Topla"; exit 1 }
  $sonuc = @()
  foreach ($ad in $FORMULLER.Keys) {
    foreach ($ces in @($false,$true)) {
      $r = Skorla $FORMULLER[$ad] $ces
      $sonuc += [pscustomobject]@{ Formul=$ad; Cesitlilik=$(if($ces){'+cesit'}else{'-'}); Gecen=$r.Gecen; Toplam=$r.Toplam; Dusenler=$r.Dusenler }
    }
  }
  Write-Host ""
  Write-Host "==================== SIRALAMA TARTISI ===================="
  $sonuc | Sort-Object Gecen -Descending | ForEach-Object {
    "{0,-16} {1,-8} {2,3}/{3}" -f $_.Formul, $_.Cesitlilik, $_.Gecen, $_.Toplam
  }
  $taban = ($sonuc | Where-Object { $_.Formul -eq 'v7-canli' -and $_.Cesitlilik -eq '-' }).Gecen
  $en = $sonuc | Sort-Object Gecen -Descending | Select-Object -First 1
  Write-Host "---------------------------------------------------------"
  Write-Host ("TABAN (canlidaki v7): {0}/{1}" -f $taban, $en.Toplam)
  Write-Host ("EN IYI: {0} {1} -> {2}/{3}   (fark: {4:+#;-#;0})" -f $en.Formul, $en.Cesitlilik, $en.Gecen, $en.Toplam, ($en.Gecen - $taban))
  Write-Host ""
  Write-Host "KURAL: taban asilmadan SQL YAZILMAZ. Asildiysa da once bu tabloyu"
  Write-Host "Cem'e goster - kazanan formul canliya CEM'IN onayiyla yazilir."
  if ($Ayrinti) {
    Write-Host ""
    foreach ($s in ($sonuc | Sort-Object Gecen -Descending)) {
      Write-Host ("--- {0} {1} ({2}/{3}) dusenler:" -f $s.Formul, $s.Cesitlilik, $s.Gecen, $s.Toplam)
      foreach ($d in $s.Dusenler) { Write-Host ("      {0}" -f $d) }
    }
  }
}

# ===========================================================================
#  DIL KANALI — 25.08.2026
#
#  Tarti sunu kanitladi: 8 dusen vakanin 8'i SEKIZ ayri siralama formulunde de
#  ayni sekilde dusuyor. Yani sorun puanlamada DEGIL. Sebep dilsel: dogru belge
#  sorgunun kelimelerini icermiyor.
#      "vergi mahremiyeti KIMLERI BAGLAR"  ->  VUK m.5 metni "KIMSELER" diyor
#  Icermedigi kelime yuzunden kaybeden belgeyi hicbir formul kurtaramaz.
#
#  KRITIK KOLAYLIK: sorgu on-islemesi SQL'DE DEGIL, ISTEMCIDE (edge/net-cevap.ts
#  ve motor/ambar-testi.ps1). madde_ara kelimeleri disaridan aliyor. Yani bu
#  duzeltme HIC SQL DEPLOY'U GEREKTIRMEZ - v6 koku Postgres'in icine gomup
#  geri alinmisti, biz ayni hatayi yapmiyoruz.
#
#  ONEK ESLESMESI ISI KOLAYLASTIRIYOR: to_tsquery('simple','sicil:*') hem
#  "sicili" hem "siciline" hem "sicilinde"yi tutar. Yani KOKU KISALTMAK
#  KAPSAMI GENISLETIR; tek risk asiri kisaltip alakasiz kelimeye yayilmak
#  ("bag" -> "bagimsiz","baglanti"). Onun icin kok uzunlugu tabanli fren var.
#
#  Bu mod UCTAN UCA olcer: varyanti gercek madde_ara'ya sorar, top-6'ya bakar.
#  Simulasyon degil - canli hattin ta kendisi, yalniz istek oncesi degisiyor.
# ===========================================================================

# Turkce cekim eklerini KOKE DOGRU soyar. Fold'lanmis (ASCII) girdi bekler.
# Kok $enAz karakterin altina duserse soyma DURUR - asiri kisalma = gurultu.
$EKLER = @('lerinin','larinin','lerine','larina','lerini','larini','lerin','larin','leri','lari','ler','lar',
           'sinin','sinin','nin','nun','nin','in','un',
           'sine','sina','ine','ina','ye','ya','e','a',
           'sinde','sinda','inde','inda','de','da','te','ta',
           'sinden','sindan','inden','indan','den','dan','ten','tan',
           'siyle','iyle','yle','le','la',
           'ligi','lugi','lik','lik','luk','lugu',
           'si','su','i','u',
           'mesi','masi','mek','mak','me','ma')
# EN UZUN EKI DENE, KOK KISA KALIYORSA HIC SOYMA.
# Ilk surum "uzun ek engellenirse kisa eke dus" diyordu ve kelime kiyiyordu:
#   cezasi -> cezas ('si' engellendi, 'i' soyuldu) · koruma -> korum · vergisi -> verg
# Yanlis ek soymak, hic soymamaktan kotudur: ortaya kelime olmayan bir kok
# cikiyor ve onek eslesmesi alakasiz yere yayiliyor. Dogru davranis: gercek eki
# soy ya da kelimeye DOKUNMA.
$EKLER_SIRALI = $EKLER | Sort-Object { $_.Length } -Descending
function EkSoy([string]$w, [int]$enAz) {
  $x = $w
  for ($tur = 0; $tur -lt 3; $tur++) {
    $ek = $EKLER_SIRALI | Where-Object { $x.EndsWith($_) } | Select-Object -First 1
    if (-not $ek) { break }
    if ($x.Length - $ek.Length -lt $enAz) { break }   # kok cok kisalir -> DUR
    $x = $x.Substring(0, $x.Length - $ek.Length)
  }
  return $x
}

# Soru cumlesinin TASIYICI OLMAYAN kelimeleri. Mevcut STOP listesi yalnizca
# 25 kelime ve soru kaliplarini kacirıyor ("kimleri","baglar","yapilir"...).
# Bunlar nadir oldugu icin IDF'te YUKSEK agirlik aliyor ve alakasiz belgeyi
# yukari cekiyor - olculen zehirlenme mekanizmasi tam buydu.
$STOP_GENIS = $STOP + @(
  'kimler','kimleri','kimlere','hangileri','hangisi','neler','nelerdir',
  'baglar','baglayan','yapilir','yapilan','verilir','verilen','alinir','alinan',
  'olabilir','olacak','gerekir','gereken','gore','kadar','nereye','nereden','nerede',
  'zamani','zamanda','durumunda','halinde','sartlari','sartlar','sarti',
  'uygulanir','sayilir','edilir','etmek','olmak','bulunan'
)

function Jetonla2([string]$soru, [string[]]$stop, [int]$ekEnAz) {
  $t = (Fold $soru) -replace '[^\w\s]',' ' -split '\s+' |
       Where-Object { $_.Length -ge 3 -and $stop -notcontains $_ }
  if ($ekEnAz -gt 0) { $t = @($t | ForEach-Object { EkSoy $_ $ekEnAz }) }
  $t = @($t | ForEach-Object { V7Jeton $_ } | Where-Object { $_.Length -ge 3 } | Select-Object -Unique)
  @($t | Select-Object -First 8)
}

function Dil-Kanali {
  $set = Get-Content -Raw -Encoding UTF8 $setYol | ConvertFrom-Json
  $vakalar = @($set.vakalar)
  if ($Vaka -gt 0 -and $Vaka -lt $vakalar.Count) { $vakalar = @($vakalar | Select-Object -First $Vaka) }

  $script:sonCagri = [datetime]::MinValue
  function Fren2([int]$ms = 900) {
    $g = ([datetime]::UtcNow - $script:sonCagri).TotalMilliseconds
    if ($g -lt $ms) { Start-Sleep -Milliseconds ([int]($ms - $g)) }
    $script:sonCagri = [datetime]::UtcNow
  }
  function Sor([string[]]$jet) {
    if (-not $jet) { return @() }
    $govde = @{ sorgu = ($jet -join ' '); adet = 6 } | ConvertTo-Json -Compress
    $sonHata = ''
    foreach ($d in 1..4) {
      Fren2
      try { return @(Invoke-RestMethod -Method Post -Uri "$SB/rest/v1/rpc/madde_ara?select=kaynak_ad" -Headers $H -ContentType 'application/json' -Body $govde) }
      catch { $sonHata = $_.Exception.Message; Start-Sleep -Seconds (2 * $d) }
    }
    throw "rpc: $sonHata"
  }

  # ekEnAz=0 -> ek soyma YOK. 4/5 -> kok en az bu kadar karakter kalsin.
  $varyantlar = [ordered]@{
    'mevcut (taban)'      = @{ stop = $STOP;        ek = 0 }
    'genis-durak'         = @{ stop = $STOP_GENIS;  ek = 0 }
    'ek-soyma(kok>=5)'    = @{ stop = $STOP;        ek = 5 }
    'ek-soyma(kok>=4)'    = @{ stop = $STOP;        ek = 4 }
    'genis+ek(kok>=5)'    = @{ stop = $STOP_GENIS;  ek = 5 }
    'genis+ek(kok>=4)'    = @{ stop = $STOP_GENIS;  ek = 4 }
  }

  $rapor = @()
  foreach ($vad in $varyantlar.Keys) {
    $ayar = $varyantlar[$vad]
    $gecen = 0; $hata = 0; $dusenler = @()
    foreach ($v in $vakalar) {
      $jet = Jetonla2 $v.soru $ayar.stop $ayar.ek
      try { $r = Sor $jet } catch { $hata++; $dusenler += ($v.soru + ' [RPC]'); continue }
      $adlar = $r | ForEach-Object { Fold ([string]$_.kaynak_ad) }
      $tuttu = $false
      foreach ($b in @($v.beklenen)) { if ($adlar | Where-Object { $_ -like "*$b*" }) { $tuttu = $true; break } }
      if ($tuttu) { $gecen++ } else { $dusenler += $v.soru }
    }
    $rapor += [pscustomobject]@{ Varyant=$vad; Gecen=$gecen; Toplam=$vakalar.Count; Rpc=$hata; Dusenler=$dusenler }
    Write-Host ("  {0,-20} {1,3}/{2}   (rpc hatasi: {3})" -f $vad, $gecen, $vakalar.Count, $hata)
  }

  Write-Host ""
  Write-Host "==================== DIL KANALI ===================="
  $taban = ($rapor | Where-Object { $_.Varyant -eq 'mevcut (taban)' }).Gecen
  $rapor | Sort-Object Gecen -Descending | ForEach-Object {
    "{0,-20} {1,3}/{2}   {3:+#;-#;0}" -f $_.Varyant, $_.Gecen, $_.Toplam, ($_.Gecen - $taban)
  }
  Write-Host "----------------------------------------------------"
  $en = $rapor | Sort-Object Gecen -Descending | Select-Object -First 1
  Write-Host ("TABAN: {0}/{1}   EN IYI: {2} -> {3}/{1}  ({4:+#;-#;0})" -f $taban, $en.Toplam, $en.Varyant, $en.Gecen, ($en.Gecen - $taban))
  Write-Host ""
  Write-Host "Kazanan varyant SQL DEGIL, ISTEMCI degisikligidir:"
  Write-Host "  radar-app/edge/net-cevap.ts  +  motor/ambar-testi.ps1  (ikisi SENKRON kalmali)"
  if ($Ayrinti) {
    foreach ($s in ($rapor | Sort-Object Gecen -Descending)) {
      Write-Host ("--- {0} ({1}/{2}) dusenler:" -f $s.Varyant, $s.Gecen, $s.Toplam)
      foreach ($d in $s.Dusenler) { Write-Host ("      {0}" -f $d) }
    }
  }
}

# ===========================================================================
#  KAPAK MODU — ek soyma + CESITLILIK TAVANI birlikte (25.08)
#
#  Dil kanali ek soymayla 41 -> 44/48 verdi. Kalan 4 dusenden 'tapu harci'
#  tam da cesitlilik tavaninin daha once duzelttigi vakaydi (o sorguda top-6'nin
#  4'u AYNI maddenin (Harclar GT 56 ek m.12) farkli parcalariydi). Yani ikisi
#  birlikte 45 olabilir - ama IDDIA EDILMEZ, OLCULUR.
#
#  ONEMLI: tavan da SQL GEREKTIRMIYOR. Istemci madde_ara'dan daha genis bir
#  havuz ister (adet=30), ayni madde/belgeden fazlasini eler, kalan ilk 6'yi
#  kullanir. Yani bu da edge tarafinda yapilabilir - v6 dersi: mantigi
#  Postgres'in icine gomme.
# ===========================================================================
function Kapak-Olc {
  $set = Get-Content -Raw -Encoding UTF8 $setYol | ConvertFrom-Json
  $vakalar = @($set.vakalar)
  if ($Vaka -gt 0 -and $Vaka -lt $vakalar.Count) { $vakalar = @($vakalar | Select-Object -First $Vaka) }

  $script:sonCagri = [datetime]::MinValue
  function Fren3([int]$ms = 900) {
    $g = ([datetime]::UtcNow - $script:sonCagri).TotalMilliseconds
    if ($g -lt $ms) { Start-Sleep -Milliseconds ([int]($ms - $g)) }
    $script:sonCagri = [datetime]::UtcNow
  }
  function Sor3([string[]]$jet, [int]$adet) {
    if (-not $jet) { return @() }
    $govde = @{ sorgu = ($jet -join ' '); adet = $adet } | ConvertTo-Json -Compress
    foreach ($d in 1..4) {
      Fren3
      try { return @(Invoke-RestMethod -Method Post -Uri "$SB/rest/v1/rpc/madde_ara?select=kaynak_ad" -Headers $H -ContentType 'application/json' -Body $govde) }
      catch { if ($d -eq 4) { throw }; Start-Sleep -Seconds (2 * $d) }
    }
  }
  # havuzdan tavani uygulayarak ilk 6'yi sec
  function Suz([object[]]$r, [int]$maddeTavan, [int]$belgeTavan) {
    $ust = @(); $mS = @{}; $bS = @{}
    foreach ($d in $r) {
      $mk = MaddeAnahtar ([string]$d.kaynak_ad); $bk = BelgeAnahtar ([string]$d.kaynak_ad)
      if ([int]$mS[$mk] -ge $maddeTavan) { continue }
      if ([int]$bS[$bk] -ge $belgeTavan) { continue }
      $mS[$mk] = [int]$mS[$mk] + 1; $bS[$bk] = [int]$bS[$bk] + 1
      $ust += $d
      if ($ust.Count -ge 6) { break }
    }
    return $ust
  }

  $varyantlar = [ordered]@{
    'ek5 kapaksiz'        = @{ ek=5; stop=$STOP; adet=6;  mt=99; bt=99 }
    'ek5 + tavan(1/2)@30' = @{ ek=5; stop=$STOP; adet=30; mt=1;  bt=2  }
    'ek5 + tavan(1/3)@30' = @{ ek=5; stop=$STOP; adet=30; mt=1;  bt=3  }
    'ek5 + tavan(2/3)@30' = @{ ek=5; stop=$STOP; adet=30; mt=2;  bt=3  }
    'ek5 + tavan(1/2)@60' = @{ ek=5; stop=$STOP; adet=60; mt=1;  bt=2  }
    'mevcut + tavan(1/2)' = @{ ek=0; stop=$STOP; adet=30; mt=1;  bt=2  }
  }

  $rapor = @()
  foreach ($vad in $varyantlar.Keys) {
    $a = $varyantlar[$vad]
    $gecen = 0; $olculemeyen = 0; $dusenler = @()
    foreach ($v in $vakalar) {
      $jet = Jetonla2 $v.soru $a.stop $a.ek
      try { $r = Sor3 $jet $a.adet } catch { $olculemeyen++; continue }
      $ust = Suz $r $a.mt $a.bt
      $adlar = $ust | ForEach-Object { Fold ([string]$_.kaynak_ad) }
      $tuttu = $false
      foreach ($b in @($v.beklenen)) { if ($adlar | Where-Object { $_ -like "*$b*" }) { $tuttu = $true; break } }
      if ($tuttu) { $gecen++ } else { $dusenler += $v.soru }
    }
    $rapor += [pscustomobject]@{ Varyant=$vad; Gecen=$gecen; Olculemeyen=$olculemeyen; Toplam=$vakalar.Count; Dusenler=$dusenler }
    Write-Host ("  {0,-22} {1,3}/{2}   (olculemeyen: {3})" -f $vad, $gecen, $vakalar.Count, $olculemeyen)
  }

  Write-Host ""
  Write-Host "============== CESITLILIK TAVANI OLCUMU =============="
  $taban = ($rapor | Where-Object { $_.Varyant -eq 'ek5 kapaksiz' }).Gecen
  $rapor | Sort-Object Gecen -Descending | ForEach-Object {
    "{0,-22} {1,3}/{2}   {3:+#;-#;0}" -f $_.Varyant, $_.Gecen, $_.Toplam, ($_.Gecen - $taban)
  }
  Write-Host "------------------------------------------------------"
  $en = $rapor | Sort-Object Gecen -Descending | Select-Object -First 1
  Write-Host ("TABAN (ek5, tavansiz): {0}/{1}   EN IYI: {2} -> {3}/{1}" -f $taban, $en.Toplam, $en.Varyant, $en.Gecen)
  if ($Ayrinti) {
    foreach ($s in ($rapor | Sort-Object Gecen -Descending)) {
      Write-Host ("--- {0} ({1}/{2}) dusenler:" -f $s.Varyant, $s.Gecen, $s.Toplam)
      foreach ($d in $s.Dusenler) { Write-Host ("      {0}" -f $d) }
    }
  }
}

if ($Topla) { Topla-Havuz }
elseif ($Dene) { Dene-Formuller }
elseif ($Dil) { Dil-Kanali }
elseif ($Kapak) { Kapak-Olc }
else { Write-Host "Kullanim: -Topla | -Dene | -Dil | -Kapak  [-Ayrinti] [-Vaka N]" }
