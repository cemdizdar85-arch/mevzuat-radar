# ============================================================================
#  RG INDIR - gunun Resmi Gazete fihristinden isletmeyi ilgilendiren tebligleri
#  bulup HAM .htm olarak motor/arsiv/<gun>/ altina indirir (windows-1254 bozulmadan,
#  bytes olarak). Kart motoru (kart-toplu.ps1) bu klasoru bekler.
#  Kullanim: -Gun 13-07-2026   (dd-MM-yyyy)
#  Cikti kodu her zaman 0 (sayi yok / ilgili teblig yok = hata degil).
# ============================================================================
param([Parameter(Mandatory=$true)][string]$Gun)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$p = $Gun.Split("-"); $Tarih = "$($p[0]).$($p[1]).$($p[2])"
$UA = "Mozilla/5.0 (MevzuatRadar-KartMotoru)"

function Norm([string]$s){
  if($null -eq $s){ return "" }
  $s = $s.Replace([string][char]0x130,"i").Replace("I","i")
  return $s.ToLowerInvariant()
}

# ============================================================================
#  SUZGEC TERSINE CEVRILDI (17.08.2026 - Cem: "RG'yi anlamayan insan bizim hap
#  bilgilerimizle onu okumus ve yutmus olsun")
#
#  ESKI KURGU: 40 kelimelik IZIN LISTESI. Fihrist basliginda bu kelimelerden
#  biri gecmiyorsa duzenleme INDIRILMIYORDU BILE. Kapsami 40 kelime belirliyordu.
#  OLCULDU (15-17.08.2026 fihristleri): 16 ve 17 Agustos'ta RG'de gercekten
#  yalnizca universite sinav yonetmeligi vardi - robot HAKLIYDI. Ama 15
#  Agustos'ta "Motorlu Kara Tasitlarinin Kiralanmasi Hakkinda Yonetmelik"
#  vardi ve KACTI: listede ne "kiralama" ne "tasit" ne "yonetmelik" var.
#  Arac kiralama musterisi olan her musaviri ilgilendirir.
#
#  YENI KURGU (Cem karari) - uc asama:
#    0) GURULTU ELE (bedava)   : universite yonetmeligi, atama, ilan...
#    1) KESIN ISABET (bedava)  : genisletilmis anahtar listesi -> dogrudan alinir
#    2) BILINMEYEN (tek cagri) : kalan basliklar TEK istekte modele sorulur
#  Sakin gunde 2. asama hic calismaz ya da 3-5 baslik icin bir kez calisir.
#  KOR KALMA FRENI: 2. asama cagrisi duserse bilinmeyenler ATILMAZ, ihtiyaten
#  ALINIR. Kacirmanin bedeli (urun sozunu tutamaz) fazladan bir kart
#  uretmenin bedelinden buyuktur.
# ============================================================================

# --- ASAMA 0: gurultu. Bunlar isletmeyi/musaviri ILGILENDIRMEZ. -------------
# Universite yonetmelikleri RG'nin en kalabalik kalemi ve tamami egitim ici
# duzenleme. "Atama", "ilan", "kadro" da oyle.
$GURULTU = @(
  'üniversitesi.*yönetmel', 'üniversitesine.*yönetmel', 'yüksek teknoloji enstitüsü.*yönetmel',
  'eğitim-öğretim ve sınav yönetmel', 'lisansüstü eğitim', 'ön lisans ve lisans',
  'uygulama ve araştırma merkezi yönetmel',
  'atanmasına dair', 'atama karar', '\batamalar\b', 'görevden alınma',
  'vatandaşlıktan çıkar', 'kamu personeli ilan', '\bilanlar\b', 'kadro ihdas',
  'nişan ve madalya', 'yasama dokunulmazl'
)

# --- ASAMA 1: kesin isabet. Isletmeyi ilgilendiren konu anahtarlari. --------
# 17.08 GENISLETILDI: eski liste yalniz ithalat/GTIP/vergi eksenindeydi.
$ANAHTARLAR = @(
  "gözetim","damping","korunma önlem","ek mali yükümlülük","haksız rekabet","ilave gümrük","ithalat rejimi","askıya alma",
  "ithalat","ihracat","gümrük","tarife kontenjan","kota","menşe","dahilde işleme","hariçte işleme",
  "katma değer vergisi","kdv","özel tüketim","ötv","gelir vergisi","kurumlar vergisi","vergi usul","damga vergisi","harçlar",
  "sosyal güvenlik","sgk","asgari ücret","prime esas",
  "ürün güvenliği","denetimi tebliğ","tareks","ce işaret",
  "teşvik","destek","yatırımlarda devlet yardım",
  "sınai mülkiyet","kamu ihale","ihale tebliğ","kambiyo","ihracat bedel",
  # --- 17.08 eklenenler: musaviri/isletmeyi ilgilendirdigi halde listede
  # olmadigi icin kacan konular. 15.08 arac kiralama yonetmeligi "kiralama"
  # kelimesi olmadigi icin kacmisti.
  "kiralama","taşıt","araç muayene","karayolu taşıma","lojistik",
  "ticaret sicil","şirket","anonim","limited","birleşme","bölünme","tasfiye",
  "iş sağlığı","iş güvenliği","çalışma","işçi","işveren","kıdem","fazla çalışma",
  "e-fatura","e-arşiv","e-defter","elektronik belge","elektronik tebligat",
  "bağımsız denetim","muhasebe standard","finansal raporlama","defter",
  "tüketici","perakende","elektronik ticaret","ödeme hizmet","banka kart",
  "kişisel veri","bilgi güvenliği",
  "çek","senet","faiz","yeniden değerleme","enflasyon düzeltme",
  "meslek mensup","serbest muhasebeci","yeminli mali",
  "ruhsat","yetki belgesi","lisans","işyeri açma","imar","yapı denetim",
  "gıda","hijyen","ambalaj","atık","çevre izin","karbon",
  "turizm","konaklama","sağlık hizmet","eczane","tıbbi cihaz"
)

$url = "https://www.resmigazete.gov.tr/$Tarih"
Write-Host "Fihrist: $url"
try {
  $html = (Invoke-WebRequest -Uri $url -UserAgent $UA -TimeoutSec 60 -UseBasicParsing).Content
} catch {
  Write-Host "Fihrist alinamadi ($Tarih) - bugun sayi yok olabilir. Cikiliyor."
  exit 0
}

$rx = [regex]'(?is)<a[^>]+href="(?<u>[^"]*eskiler/\d{4}/\d{2}/(?<d>\d{8}-\d+)\.htm)"[^>]*>(?<t>.*?)</a>'
$tumu = @()
foreach($m in $rx.Matches($html)){
  $t = ($m.Groups["t"].Value -replace "<[^>]+>"," " -replace "\s+"," ").Trim()
  $t = [System.Net.WebUtility]::HtmlDecode($t)
  if($t.Length -lt 15){ continue }
  $u = $m.Groups["u"].Value
  if($u -notmatch "^https?:"){ $u = "https://www.resmigazete.gov.tr" + $(if($u.StartsWith("/")){""}else{"/"}) + $u }
  if($tumu | Where-Object { $_.url -eq $u }){ continue }
  $tumu += [pscustomobject]@{ url = $u; dosya = ($m.Groups["d"].Value + ".htm"); baslik = $t }
}
Write-Host ("Fihristte {0} duzenleme var." -f $tumu.Count)

# --- ASAMA 0 + 1: bedava ayirma ---------------------------------------------
# DIKKAT - PS DEGISKEN CAKISMASI: biriktirici adi "$gurultu" OLAMAZ.
# PowerShell degisken adlarinda buyuk/kucuk harf AYIRMAZ; $gurultu ile
# $GURULTU AYNI degiskendir. "$gurultu = @()" satiri desen listesini
# siliyordu ve eleyici hep 0 buluyordu (17.08'de tam bu oldu).
$secilen = @(); $elenenler = @(); $bilinmeyen = @()
foreach($s in $tumu){
  $n = Norm $s.baslik
  $g = $false
  foreach($d in $GURULTU){ if($n -match $d){ $g = $true; break } }
  if($g){ $elenenler += $s; continue }
  $vur = $false
  foreach($a in $ANAHTARLAR){ if($n.Contains((Norm $a))){ $vur = $true; break } }
  if($vur){ $secilen += $s } else { $bilinmeyen += $s }
}
Write-Host ("  gurultu elendi: {0} | kesin isabet: {1} | bilinmeyen: {2}" -f $elenenler.Count, $secilen.Count, $bilinmeyen.Count)

# --- ASAMA 2: bilinmeyenleri TEK cagrida sinifla -----------------------------
# Sakin gunde 3-5 baslik; tek istek, birkac yuz jeton. Cagri duserse baslik
# ATILMAZ, ihtiyaten alinir (kacirmanin bedeli daha buyuk).
$asama2Not = ''
if($bilinmeyen.Count){
  $siniflandi = $false
  try {
    . (Join-Path $here 'api-hedef.ps1')
    $liste = (0..($bilinmeyen.Count-1) | ForEach-Object { "$($_+1). $($bilinmeyen[$_].baslik)" }) -join "`n"
    $istem = @"
Asagida bugunku Resmi Gazete'den baslIklar var. Her biri icin sor:
"Turkiye'de bir mali musaviri ya da bir isletmeyi (vergi, SGK, ticaret,
ruhsat, sektorel yukumluluk, ceza, tesvik acisindan) ilgilendirir mi?"

SADECE ilgilendirenlerin numaralarini virgulle ayirarak yaz. Hicbiri
ilgilendirmiyorsa sadece YOK yaz. Baska hicbir sey yazma.

$liste
"@
    $c = Invoke-ClaudeMesaj -Model 'claude-haiku-4-5' -Icerik $istem -MaxTok 100
    $cevap = "$($c.metin)".Trim()
    if($cevap -match '(?i)^yok'){
      $asama2Not = "bilinmeyen $($bilinmeyen.Count) baslik modele soruldu, hicbiri ilgili degil"
      $siniflandi = $true
    } else {
      $nolar = @([regex]::Matches($cevap, '\d+') | ForEach-Object { [int]$_.Value })
      if($nolar.Count){
        foreach($no in $nolar){ if($no -ge 1 -and $no -le $bilinmeyen.Count){ $secilen += $bilinmeyen[$no-1] } }
        $asama2Not = "bilinmeyen $($bilinmeyen.Count) baslikten $($nolar.Count) tanesi ilgili bulundu"
        $siniflandi = $true
      }
    }
  } catch {
    Write-Host ("  ASAMA 2 SINIFLANDIRMA YAPILAMADI: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
  }
  if(-not $siniflandi){
    # KOR KALMA FRENI: sessizce dusurmek YOK.
    Write-Host ("  -> {0} bilinmeyen baslik IHTIYATEN alindi (siniflandirma yok)." -f $bilinmeyen.Count) -ForegroundColor Yellow
    $secilen += $bilinmeyen
    $asama2Not = "siniflandirma yapilamadi, $($bilinmeyen.Count) baslik ihtiyaten alindi"
  }
}

# --- SESSIZ GUN DURUSTLUGU --------------------------------------------------
# Kart cikmadigi gun site hicbir sey soylemiyordu; ziyaretci 3 gun onceki karti
# gorup "bu site durmus" saniyordu. Artik NEDEN kart olmadigi yaziliyor.
$sebep = if($tumu.Count -eq 0){ "Resmî Gazete'de bugün düzenleme yayımlanmadı." }
         elseif($secilen.Count -gt 0){ "" }
         elseif($elenenler.Count -eq $tumu.Count){
           "Bugün Resmî Gazete'de $($tumu.Count) düzenleme vardı; hepsi üniversite yönetmeliği/atama türü. İşletmeni ilgilendiren yok."
         } else {
           "Bugün Resmî Gazete'de $($tumu.Count) düzenleme vardı; hiçbiri işletmeni ilgilendirmiyor."
         }
$durumYol = Join-Path (Split-Path -Parent $here) "veri\rg-gun-durum.json"
try {
  $durum = [ordered]@{
    gun = $Tarih; bakilan = $tumu.Count; elenen = $elenenler.Count
    ilgili = $secilen.Count; bilinmeyen = $bilinmeyen.Count
    sebep = $sebep; asama2 = $asama2Not
    basliklar = @($tumu | ForEach-Object { $_.baslik })
  }
  [IO.File]::WriteAllText($durumYol, ($durum | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
} catch { Write-Host "  gun durumu yazilamadi: $($_.Exception.Message)" -ForegroundColor Yellow }

if(-not $secilen.Count){ Write-Host "Ilgili teblig bulunamadi ($Tarih). $sebep"; exit 0 }

$hedef = Join-Path $here ("arsiv\" + $Gun)
New-Item -ItemType Directory -Force $hedef | Out-Null
$ok = 0
$wc = New-Object System.Net.WebClient
foreach($s in $secilen){
  try {
    # HAM byte indir - windows-1254 kodlamasi bozulmadan diske yazilir
    # NOT: WebClient header'lari HER istekten sonra sifirlar -> UA dongu icinde eklenir
    $wc.Headers.Add("User-Agent",$UA)
    $b = $wc.DownloadData($s.url)
    [System.IO.File]::WriteAllBytes((Join-Path $hedef $s.dosya), $b)
    $ok++
    Write-Host ("  indirildi: {0}  ({1})" -f $s.dosya, $s.baslik.Substring(0,[Math]::Min(70,$s.baslik.Length)))
  } catch { Write-Host ("  INDIRILEMEDI: " + $s.url) -ForegroundColor Yellow }
  Start-Sleep -Milliseconds 400
}
Write-Host ("TOPLAM: {0}/{1} teblig -> {2}" -f $ok, $secilen.Count, $hedef)

# ---------------------------------------------------------------------------
# GTIP VERI SINYALI (13.08 Cem: "haber beklemeden... acik noktalari kapat").
# Bugunku basliklar gtip.html'i besleyen VERIYI etkileyebilecek turdense
# (gozetim/damping/IGV/rejim/askiya/OTV/KDV) Cem'e ayni gun mail duser -
# kart uretiminden BAGIMSIZ ve anahtarsiz/bedava. 11.07 revalorizasyonu
# 3 gun fark edilmemisti; bu sinyalle ayni gun ogrenilir.
# ---------------------------------------------------------------------------
$GTIP_ETKI = @("gözetim","damping","ilave gümrük","ithalat rejimi","askıya alma","korunma önlem","ek mali yükümlülük","özel tüketim","katma değer vergisi")
$vuranlar = @($secilen | Where-Object { $t = Norm $_.baslik; ($GTIP_ETKI | Where-Object { $t.Contains((Norm $_)) }).Count -gt 0 })
if($vuranlar.Count -gt 0){
  $liste = ($vuranlar | ForEach-Object { "- " + $_.baslik }) -join "`n"
  Write-Host ("GTIP SINYALI: {0} baslik veriyi etkileyebilir - mail gonderiliyor." -f $vuranlar.Count)
  $mb = @{
    access_key = "5b227e56-94fb-4123-a39a-4286f63db14a"
    subject    = "TETIKTE GTIP SINYALI - bugunku RG'de veriyi etkileyebilecek teblig var ($Gun)"
    from_name  = "Tetikte RG Nobetcisi"
    email      = "cemdizdar85@hotmail.com"
    message    = "Bugunku RG'de gtip.html verilerini (gozetim/damping/IGV/rejim/askiya/OTV/KDV) etkileyebilecek basliklar:`n$liste`n`nYapilacak: ilgili tabloyu iki bagimsiz okumayla (parser + gorsel) teyit edip gtip veri dosyasini guncelle - 13.08 revalorizasyon yamasi ornektir."
  } | ConvertTo-Json -Depth 3
  try { Invoke-RestMethod -Uri "https://api.web3forms.com/submit" -Method Post -ContentType "application/json" -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -TimeoutSec 30 | Out-Null; Write-Host "Sinyal maili gitti." } catch { Write-Host ("Sinyal maili gitmedi: " + $_.Exception.Message) }
}
exit 0
