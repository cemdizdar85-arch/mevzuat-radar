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
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) mevzuat-radar-duyuru-nobetcisi/1.0'
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
  [pscustomobject]@{ ad='TURMOB';     tur='href';    url='https://www.turmob.org.tr/Haberler';     desen='(?i)/(haberler|duyuru)/';     kokUrl='https://www.turmob.org.tr' },
  [pscustomobject]@{ ad='GIB';        tur='href';    url='https://www.gib.gov.tr/duyurular';       desen='(?i)duyuru';                  kokUrl='https://www.gib.gov.tr' }
)

# --- gorulmusler
$gorulen = @{}
if(Test-Path $durumYol){
  try { foreach($g in (Get-Content $durumYol -Raw -Encoding UTF8 | ConvertFrom-Json).gorulen){ $gorulen["$g"]=1 } } catch {}
}
$ilkKosu = ($gorulen.Count -eq 0)

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
  foreach($l in $linkler){
    if($gorulen.ContainsKey($l.url)){ continue }
    $gorulen[$l.url] = 1
    $kurumYeni++
    if(-not $ilkKosu){
      $yeniler.Add([pscustomobject]@{ kurum=$k.ad; url=$l.url; baslik=$l.baslik; tarih=$l.tarih; gorulme=(Get-Date -Format 'dd.MM.yyyy HH:mm') })
    }
  }
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
