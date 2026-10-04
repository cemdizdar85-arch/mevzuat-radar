# ============================================================================
#  DUYURU NOBETCISI — 06.08.2026 (Cem onayi #18 + "baska izlenmeyen varsa izleyelim")
#
#  NEDEN: 14.01.2026 TURMOB YK karari (0,25 goturme + hesap makinesi yasagi +
#  20 soru/45 dk) RG'de HIC yayimlanmadi - mevzuat.gov.tr aynasi goremezdi.
#  Kurum DUYURULARI ayri bir kanal ve izlenmiyordu. Bu robot o deligi kapatir.
#
#  NE YAPAR: kurum duyuru sayfalarini gunde bir tarar, link+basligi
#  veri/duyuru-durum.json'daki gorulmuslerle kiyaslar; YENI olanlari
#  veri/duyuru-yeni.json'a yazar ve commit'ler. Ben (Claude) her oturumda
#  duyuru-yeni.json'a bakarim; kritik duyuru varsa okuma isi acilir.
#
#  KOR KALMA KURALI: her kurum icin durum satiri yazilir (YESIL/KIRMIZI).
#  0 link donen kurum sessizce gecilmez, KIRMIZI gorunur. TURMOB ve GIB
#  sayfalari JS-dinamik oldugu icin ILK GUNDEN KIRMIZI bilinir (Faz 2:
#  API ucu bulunacak); TESMER SMMM/SGS duyurularini zaten tasiyor.
# ============================================================================
param([switch]$Mail)   # 05.10 SINAV NOBETI: yeni sinav duyurusu varsa Cem'e mail (Actions'ta acik)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$UA ='Mozilla/5.0 (Windows NT 10.0; Win64; x64) mevzuat-radar-duyuru-nobetcisi/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$durumYol = Join-Path $kok 'veri/duyuru-durum.json'
$yeniYol  = Join-Path $kok 'veri/duyuru-yeni.json'

function JsonYaz([string]$yol, $n){ [IO.File]::WriteAllText($yol, (ConvertTo-Json -InputObject $n -Depth 6), (New-Object Text.UTF8Encoding($false))) }

# --- kurum tanimlari: her biri {ad, url, tur} - tur linklerin nasil ayiklanacagini secer
$KURUMLAR = @(
  [pscustomobject]@{ ad='TESMER';     tur='wp-rest'; url='https://www.tesmer.org.tr/?rest_route=/wp/v2/posts&per_page=20&_fields=title,link,date' },
  [pscustomobject]@{ ad='KGK';        tur='href';    url='https://kgk.gov.tr/';                    desen='(?i)(duyuru|sinav|standart)'; kokUrl='https://kgk.gov.tr' },
  [pscustomobject]@{ ad='SGK';        tur='href';    url='https://www.sgk.gov.tr/';                desen='^/duyuru/detay/';             kokUrl='https://www.sgk.gov.tr' },
  [pscustomobject]@{ ad='TURKPATENT'; tur='href';    url='https://www.turkpatent.gov.tr/duyurular';desen='^/duyurular/';                kokUrl='https://www.turkpatent.gov.tr' },
  # JS-dinamik sayfalar: duz HTML'de duyuru linki yok - bilerek KIRMIZI kalir,
  # Faz 2'de API ucu bulunup tur degistirilecek. Sessiz delik olmasin diye listede.
  # 05.10.2026 SINAV NOBETI: TURMOB 'href' turuyle 12 link donuyordu ve YESIL gorunuyordu ama hepsi SAYFA NUMARASIYDI
  # (/Haberler/1../Haberler/110) - haber linkleri tirnaksiz yaziliyor (href=/haberler/<guid>/...) ve desen gormuyordu.
  # Yani TURMOB aylarca KOR izlendi. 'turmob' turu tirnaksiz linki + tarih + basligi okur.
  [pscustomobject]@{ ad='TURMOB';     tur='turmob';  url='https://www.turmob.org.tr/Haberler';     kokUrl='https://www.turmob.org.tr' },
  [pscustomobject]@{ ad='GIB';        tur='href';    url='https://www.gib.gov.tr/duyurular';       desen='(?i)duyuru';                  kokUrl='https://www.gib.gov.tr' }
)

# --- 05.10 SINAV NOBETI: duyuru SMMM adayini ilgilendiriyor mu? (basliktan; ozet YOK - okunmamis duyuruya yorum yazilmaz)
#     TESMER sinav kurumudur ama seminer/egitim de yayimlar -> TESMER de suzgecten gecer.
#     GORMEZ: basliginda bu kelimeler olmayan ama sinavi etkileyen duyuru (or. "Yonetim Kurulu Karari") - mailde
#     yalniz sinav olanlar gelir; tum yeniler yine veri/duyuru-yeni.json'da.
function SinavMi([string]$metin, [string]$kurum){
  if($kurum -notin @('TESMER','TURMOB','KGK')){ return $false }
  # 05.10 olculdu: TURMOB "Webinar | ... CIA CHALLENGE SINAVI Avantaji" SMMM sinavi degil -> webinar/CIA disarida
  if($metin -match '(?i)(webinar|\bCIA\b)'){ return $false }
  return [bool]($metin -match '(?i)(s[ıiIİ]nav|SGS|staj|SMMM|YMM|yeterlilik|ba[ğg][ıiIİ]ms[ıiIİ]z denet|ba[şs]vuru|sonu[çc]lar|itiraz|takvim|hesap makin)')
}

# --- gorulmusler
$gorulen = @{}
if(Test-Path $durumYol){
  try { foreach($g in (Get-Content $durumYol -Raw -Encoding UTF8 | ConvertFrom-Json).gorulen){ $gorulen["$g"]=1 } } catch {}
}
$ilkKosu = ($gorulen.PSBase.Count -eq 0)

$yeniler = New-Object System.Collections.Generic.List[object]
$durumlar = New-Object System.Collections.Generic.List[object]
foreach($k in $KURUMLAR){
  $linkler = @()
  $hata = ''
  try {
    $r = Invoke-WebRequest -Uri $k.url -UseBasicParsing -TimeoutSec 45 -UserAgent $UA
    $ic = "$($r.Content)"
    if($k.tur -eq 'wp-rest'){
      foreach($p in ($ic | ConvertFrom-Json)){
        $linkler += [pscustomobject]@{ url="$($p.link)"; baslik=([Net.WebUtility]::HtmlDecode("$($p.title.rendered)")); tarih="$($p.date)" }
      }
    } elseif($k.tur -eq 'turmob'){
      # <a href=/haberler/<guid>/<slug>> <p ...> dd.MM.yyyy</p> <span>Baslik</span>
      foreach($m in [regex]::Matches($ic, '(?s)href="?(/haberler/[0-9a-f-]{36}/[^"\s>]*)"?\s*>\s*<p[^>]*>.*?(\d{2}\.\d{2}\.\d{4})\s*</p>\s*<span>(.*?)</span>')){
        $linkler += [pscustomobject]@{ url=($k.kokUrl + $m.Groups[1].Value); baslik=([Net.WebUtility]::HtmlDecode($m.Groups[3].Value.Trim())); tarih=$m.Groups[2].Value }
      }
    } else {
      foreach($m in [regex]::Matches($ic, 'href="([^"]{8,220})"')){
        $u = $m.Groups[1].Value
        if($u -notmatch $k.desen){ continue }
        if($u -match '\.(css|js|png|jpg|ico|woff)'){ continue }
        if($u -notmatch '^https?:'){ $u = $k.kokUrl + $u }
        $linkler += [pscustomobject]@{ url=$u; baslik=''; tarih='' }
      }
      $linkler = @($linkler | Sort-Object url -Unique | Select-Object -First 60)
    }
  } catch { $hata = $_.Exception.Message }
  $kurumYeni = 0
  # 05.10: kurumun okuma bicimi degisince (TURMOB) mevcut linklerin HICBIRI gorulmus degildir -> hepsi "yeni" sanilip
  # mail seli olur. Kurumun simdiki linklerinden hic biri gorulmemisse o kurum TOHUM sayilir (yeni uretilmez).
  $kurumTohum = ($linkler.Count -gt 0) -and -not @($linkler | Where-Object { $gorulen.ContainsKey($_.url) }).Count
  foreach($l in $linkler){
    if($gorulen.ContainsKey($l.url)){ continue }
    $gorulen[$l.url] = 1
    $kurumYeni++
    if(-not $ilkKosu -and -not $kurumTohum){
      $yeniler.Add([pscustomobject]@{ kurum=$k.ad; url=$l.url; baslik=$l.baslik; tarih=$l.tarih; gorulme=(Get-Date -Format 'dd.MM.yyyy HH:mm'); sinav=(SinavMi "$($l.baslik) $([uri]::UnescapeDataString($l.url))" $k.ad) })
    }
  }
  if($kurumTohum){ Write-Host ("  {0}: okuma bicimi yeni - {1} link TOHUM sayildi" -f $k.ad, $linkler.Count) }
  $renk = if($hata){ 'KIRMIZI' } elseif($linkler.Count -eq 0){ 'KIRMIZI' } else { 'YESIL' }
  $durumlar.Add([pscustomobject]@{ kurum=$k.ad; durum=$renk; linkSayisi=$linkler.Count; yeni=$kurumYeni; hata=$hata })
  Write-Host ("{0,-11} {1,-8} link:{2,3} yeni:{3}" -f $k.ad, $renk, $linkler.Count, $kurumYeni)
}

# --- yaz
JsonYaz $durumYol ([ordered]@{
  guncelleme=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  kurumDurumlari=$durumlar
  gorulen=@($gorulen.Keys | Sort-Object)
})
# yeni dosyasi: son kosunun yenileri + onceki OKUNMAMIS yeniler korunur
$eskiYeni = @()
if(Test-Path $yeniYol){ try { $eskiYeni = @((Get-Content $yeniYol -Raw -Encoding UTF8 | ConvertFrom-Json).yeniler | Where-Object { -not $_.okundu }) } catch {} }
JsonYaz $yeniYol ([ordered]@{
  guncelleme=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  not=$(if($ilkKosu){'ILK KOSU: mevcut duyurular tohum olarak gorulmus sayildi, yeni uretilmedi.'}else{''})
  yeniler=@($eskiYeni + $yeniler)
})
Write-Host ("Bitti. Yeni duyuru: {0}{1}" -f $yeniler.Count, $(if($ilkKosu){' (ilk kosu - tohum)'}else{''}))

# --- 05.10 SINAV NOBETI: sinav duyurusu geldiyse Cem'e haber (baslik + resmi link; yorum/ozet YOK)
$sinavYeni = @($yeniler | Where-Object { $_.sinav })
Write-Host ("Sinav duyurusu: {0}" -f $sinavYeni.Count)
if($sinavYeni.Count -and $Mail){
  $satir = ($sinavYeni | ForEach-Object { "- [$($_.kurum)] $($_.tarih) $($_.baslik)`n  $($_.url)" }) -join "`n"
  $govde = "Yeni sinav duyurusu ($($sinavYeni.Count)):`n`n$satir`n`nSitede: https://tetikte.com/sinav-nobeti.html (sayfa robotla tazelenir)`nInstagram gorseli (yerelde): node motor/sinav-nobeti-gorsel.js`nPaylasmadan once duyurunun kendisini oku; gorsel yalniz resmi basligi ve linki tasir."
  try{ & (Join-Path $kok 'arac\alarm-maili.ps1') -Konu ("TETIKTE SINAV NOBETI: " + $sinavYeni[0].baslik) -Mesaj $govde }
  catch{ Write-Host "!! sinav nobeti maili gitmedi: $($_.Exception.Message)" }
}
