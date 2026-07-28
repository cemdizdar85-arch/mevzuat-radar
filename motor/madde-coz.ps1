# ============================================================================
#  MADDE COZUCU — 28.07.2026
#
#  NEDEN VAR: Profesor v2'nin tek eksigi maddenin METNI. Ama sorulardaki 'kaynak'
#  alani SERBEST METIN: "3568 sayili Kanun m.27", "KDVK (3065 s.K.) m.10/c",
#  "TBK m.72/1", "GVK m.40/1 bent 5"... Bunlari ambardaki kayda baglayamazsak
#  profesore kitap veremeyiz.
#
#  Bu betik PARA HARCAMAZ. Iki isi var:
#    1) KaynakCoz(): bir kaynak metnini (kanun_no, madde_no) cifitine ayirir ve
#       ambardan o maddenin TAM METNINI (parcali ise hepsini birlestirerek) getirir
#    2) Olcum modu: yerel tum sorularin kaynagini cozmeyi dener ve COZME ORANINI
#       raporlar. Oran dusukse profesor v2 kosturulmaz - once cozucu duzeltilir.
#
#  KURAL: cozulemeyen kaynak "bilinmiyor" olarak isaretlenir. Profesor, metni
#  olmayan soruyu YARGILAMAZ; GM'ye birakir. Uydurma yok.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$KEY = if($env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY } else { "sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg" }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

# --- KISALTMA -> KANUN NUMARASI (ambardaki kaynak_ad bicimlerinden cikarildi)
$KISALTMA = @{
  'vuk'='213'; 'kdvk'='3065'; 'kdv'='3065'; 'ttk'='6102'; 'tbk'='6098'; 'gvk'='193'
  'kvk'='5520'; 'aatuhk'='6183'; 'iyuk'='2577'; 'tck'='5237'; 'cmk'='5271'
  'kvkk'='6698'; 'otv'='4760'; 'sgk'='5510'; 'anayasa'='2709'; 'fsek'='5846'
  'smk'='6769'; 'iik'='2004'; 'hmk'='6100'; 'spk'='6362'; 'kik'='4734'
  'is k'='4857'; 'is kanunu'='4857'; 'sendikalar'='6356'; 'isg'='6331'
  'smmm'='3568'; 'ymm'='3568'; 'mtv'='197'; 'vik'='488'
}

# --- ambar onbellegi: ayni madde defalarca istenirse tek sorgu
$script:onbellek = @{}

function KanunNo([string]$kaynak){
  $k = "$kaynak"
  # 28.07 DUZELTME: eski desen numaradan sonra "K." ya da "Kanun" ARIYORDU.
  # "6356 sayili STSK m.41" gibi kanun adinin KISALTMAYLA yazildigi 58 kayit
  # bu yuzden cozulemiyordu. Artik numaradan sonra "sayili" gelmesi yeterli.
  $m = [regex]::Match($k, '(?<![\d/])(\d{3,4})\s*say[ıi]l[ıi]')
  if($m.Success){ return $m.Groups[1].Value }
  $m1b = [regex]::Match($k, '(?<![\d/])(\d{3,4})\s*s\.\s*(?:K\.|Kanun)')
  if($m1b.Success){ return $m1b.Groups[1].Value }
  $m2 = [regex]::Match($k, '\((\d{3,4})\s*s\.K\.\)')
  if($m2.Success){ return $m2.Groups[1].Value }
  # 28.07 DUZELTME: ambardaki bir kayit bicimi "Anayasa (2709) m.10" - numara
  # parantez icinde, "s.K." YOK. Damga betiginde ayni bosluk 1.436 maddeyi
  # kapsam disi birakmisti; ayni desen burada da eksikti.
  $m2b = [regex]::Match($k, '\((\d{3,4})\)')
  if($m2b.Success){ return $m2b.Groups[1].Value }
  # yoksa kisaltmadan cevir
  $d = $k.ToLowerInvariant() -replace 'ı','i' -replace 'ö','o' -replace 'ü','u' -replace 'ş','s' -replace 'ç','c' -replace 'ğ','g'
  foreach($ks in ($KISALTMA.Keys | Sort-Object { -$_.Length })){
    if($d -match ('(?<![a-z])' + [regex]::Escape($ks) + '(?![a-z])')){ return $KISALTMA[$ks] }
  }
  return $null
}

function MaddeNo([string]$kaynak){
  $k = "$kaynak"
  # "m.40", "m. 40", "madde 40", "40 inci maddesi"
  $m = [regex]::Match($k, '(?:m\.\s*|madde\s+)(\d{1,4})')
  if($m.Success){ return $m.Groups[1].Value }
  $m2 = [regex]::Match($k, '(\d{1,4})\s*(?:inci|nci|uncu|üncü|ıncı)\s+madde')
  if($m2.Success){ return $m2.Groups[1].Value }
  return $null
}

function GeciciMi([string]$kaynak){
  return ("$kaynak" -match '(?i)ge[çc]ici\s*m|gec\.\s*m|ek\s+m\.')
}

# --- ambardan maddenin TAM metnini getir (parcali ise birlestir)
# 28.07: $seri eklendi. Onceden 'gec. m.' ve 'ek m.' atiflari HIC cozulmuyordu -
# 'gecici-ek-madde' deyip birakiyorduk. Oysa o maddeler ambarda VAR; yalniz
# ayri seri olduklari icin normal aramadan DISLANIYORLARDI. Cozmemek demek,
# o maddeye dayanan sorunun madde degistiginde sessizce yanlis kalmasi demek.
# Ozellikle gecici maddeler en cok DEGISEN maddelerdir (EYT, af, yapilandirma).
function MaddeMetni([string]$kanunNo, [string]$maddeNo, [string]$seri = ''){
  if(-not $kanunNo -or -not $maddeNo){ return $null }
  $anahtar = "$kanunNo|$seri$maddeNo"
  if($script:onbellek.ContainsKey($anahtar)){ return $script:onbellek[$anahtar] }

  # kaynak_ad kaliplari: "VUK (213 s.K.) m.40", "5510 s. SGK Kanunu m.8 [2/5]",
  # "KDVK (3065 s.K.) m.2 - Teslim". Kanun numarasi + m.NN (sonrasinda baslik/parca olabilir)
  # ONEMLI: "gec. m." ve "ek m." HARIC - onlar ayri seri.
  $desen = "$kanunNo.*[^a-z]m\.$maddeNo(\s|-|\[|/|$)"
  try {
    $r = Invoke-RestMethod -Uri ("$SB_URL/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=imatch." + [uri]::EscapeDataString($desen) + "&order=kaynak_ad&limit=30") -Headers $H -TimeoutSec 60
  } catch { $script:onbellek[$anahtar] = $null; return $null }

  # Seri ayrimi SART: "213 m.5" ile "213 gec. m.5" ve "213 ek m.5" UC AYRI
  # maddedir. Karistirmak, soruya YANLIS METNI dayanak yapmak demektir - ki bu
  # hakemin hatasindan daha kotudur, cunku hakem o metne bakip "destekliyor"
  # der ve hata dogrulanmis gibi gecer.
  $gecEk = '(?i)gec\.\s*m\.|ge[çc]ici\s*m|ek\s+m\.'
  if($seri -eq 'gec'){    $kayitlar = @($r) | Where-Object { "$($_.kaynak_ad)" -match '(?i)gec\.\s*m\.|ge[çc]ici\s*m' } }
  elseif($seri -eq 'ek'){ $kayitlar = @($r) | Where-Object { "$($_.kaynak_ad)" -match '(?i)ek\s+m\.' } }
  else {                  $kayitlar = @($r) | Where-Object { "$($_.kaynak_ad)" -notmatch $gecEk } }
  if(@($kayitlar).Count -eq 0){ $script:onbellek[$anahtar] = $null; return $null }

  # ayni maddenin parcalarini sirala ve birlestir; farkli madde varsa (m.4 ararken m.40
  # gelmesi gibi) ELE: kaynak_ad'da "m.<no>" hemen ardindan rakam GELMEMELI
  $temiz = @($kayitlar | Where-Object { "$($_.kaynak_ad)" -match ("[^a-z]m\." + $maddeNo + "(?!\d)") })
  if(@($temiz).Count -eq 0){ $script:onbellek[$anahtar] = $null; return $null }

  $sirali = @($temiz | Sort-Object { $p=[regex]::Match("$($_.kaynak_ad)", '\[(\d+)/\d+\]'); if($p.Success){ [int]$p.Groups[1].Value } else { 0 } })
  $metin = (@($sirali | ForEach-Object { "$($_.metin)" }) -join " ")
  $sonuc = [ordered]@{ kanun=$kanunNo; madde="$seri$maddeNo"; parca=@($sirali).Count; ad=$sirali[0].kaynak_ad; metin=$metin }
  $script:onbellek[$anahtar] = $sonuc
  return $sonuc
}

# --- STANDART YOLU: "TMS 1 m.38", "BDS 240 p.12", "TFRS 9 p.4.4.1"
function StandartMetni([string]$kaynak){
  $m = [regex]::Match("$kaynak", '(?i)\b(TMS|TFRS|BDS)\s*(\d{1,3})')
  if(-not $m.Success){ return $null }
  $ad = $m.Groups[1].Value.ToUpperInvariant(); $no = $m.Groups[2].Value
  $anahtar = "STD|$ad|$no"
  if($script:onbellek.ContainsKey($anahtar)){ return $script:onbellek[$anahtar] }
  try {
    $r = Invoke-RestMethod -Uri ("$SB_URL/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=imatch." + [uri]::EscapeDataString("$ad\s*$no(?!\d)") + "&order=kaynak_ad&limit=25") -Headers $H -TimeoutSec 60
  } catch { $script:onbellek[$anahtar] = $null; return $null }
  if(@($r).Count -eq 0){ $script:onbellek[$anahtar] = $null; return $null }
  $metin = (@($r | ForEach-Object { "$($_.kaynak_ad): $($_.metin)" }) -join "`n")
  $sonuc = [ordered]@{ standart="$ad $no"; parca=@($r).Count; ad=$r[0].kaynak_ad; metin=$metin }
  $script:onbellek[$anahtar] = $sonuc
  return $sonuc
}

# --- MEVZUAT DISI MI: dil, matematik, teori sorularinin dayanacagi bir MADDE yoktur.
# Bunlar "cozulemedi" degildir; cozulecek metin YOKTUR. Profesor bunlari madde
# uzerinden yargilamaz - zaten bugunku olcumde bu tipte SIFIR hata cikti.
function MevzuatDisiMi([string]$kaynak){
  $k = "$kaynak"
  if($k.Trim().Length -eq 0){ return $true }
  if($k -match '(?i)\b(TMS|TFRS|BDS)\s*\d'){ return $false }
  if($k -match '(?i)tebli|MSUGT|tekd[uü]zen|hesap plan'){ return $false }
  if($k -match '(?i)y[oö]netmelik'){ return $false }
  if($k -match '(?i)\d{3,4}\s*say[ıi]l[ıi]|\(\d{3,4}\s*s\.K\.\)'){ return $false }
  if($k -match '(?i)\b(VUK|TTK|TBK|GVK|KDVK|KDV Kanunu|KVK|AATUHK|[İI]YUK|TCK|CMK|SMK|[İI][İI]K|[ÖO]TV|Anayasa)\b'){ return $false }
  return $true    # teori notu, dil kurali, matematik formulu, tarih bilgisi...
}

function KaynakCoz([string]$kaynak){
  if(MevzuatDisiMi $kaynak){ return [ordered]@{ durum='mevzuat-disi'; kaynak=$kaynak } }
  $std = StandartMetni $kaynak
  if($std){ return [ordered]@{ durum='cozuldu-standart'; kaynak=$kaynak; standart=$std.standart; parca=$std.parca; ad=$std.ad; metin=$std.metin } }
  $kn = KanunNo $kaynak
  $mn = MaddeNo $kaynak
  if(-not $kn){ return [ordered]@{ durum='kanun-bulunamadi'; kaynak=$kaynak } }
  if(-not $mn){ return [ordered]@{ durum='madde-bulunamadi'; kaynak=$kaynak; kanun=$kn } }
  # 28.07: gec./ek maddeler artik kendi serilerinde ARANIYOR, birakilmiyor.
  # Onceden 'gecici-ek-madde' deyip vazgeciyorduk; oysa ambarda varlar. Ustelik
  # gecici maddeler en cok DEGISEN maddelerdir (EYT, af, yapilandirma) - yani
  # tam da nobet tutmamiz gereken yerdi.
  $seri = ''
  if("$kaynak" -match '(?i)ge[çc]ici\s*m|gec\.\s*m'){ $seri = 'gec' }
  elseif("$kaynak" -match '(?i)ek\s+m\.'){ $seri = 'ek' }
  $m = MaddeMetni $kn $mn $seri
  if(-not $m){ return [ordered]@{ durum=$(if($seri){'gecici-ek-ambarda-yok'}else{'ambarda-yok'}); kaynak=$kaynak; kanun=$kn; madde="$seri$mn" } }
  return [ordered]@{ durum='cozuldu'; kaynak=$kaynak; kanun=$kn; madde="$seri$mn"; parca=$m.parca; ad=$m.ad; metin=$m.metin }
}

# ============================ OLCUM MODU ====================================
if($args -contains '-olcum' -or $args.Count -eq 0){
  Write-Host "MADDE COZUCU - OLCUM (para harcamaz)"
  $fabrikaDir = Join-Path $kok "veri\fabrika"
  $sorular = @()
  Get-ChildItem $fabrikaDir -Filter *.json | ForEach-Object {
    try { $x = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { return }
    foreach($s in @($x.sorular)){ if($s){ $sorular += $s } }
  }
  Write-Host ("Yerel soru: {0}" -f $sorular.Count)

  $ist = @{}
  $ornek = @{}
  $i = 0
  foreach($s in $sorular){
    $i++
    if($i % 100 -eq 0){ Write-Host ("  ...{0}" -f $i) }
    $k = "$($s.kaynak)"
    if($k.Trim().Length -eq 0){ $d='kaynak-bos' } else { $c = KaynakCoz $k; $d = $c.durum }
    if($ist.ContainsKey($d)){ $ist[$d]++ } else { $ist[$d]=1 }
    if(-not $ornek.ContainsKey($d)){ $ornek[$d] = $k }
  }

  Write-Host ""
  Write-Host "================ KAYNAK COZME ORANI ================"
  $toplam = $sorular.Count
  foreach($d in ($ist.Keys | Sort-Object { -$ist[$_] })){
    Write-Host ("  {0,-22} {1,5}  (%{2})   ornek: {3}" -f $d, $ist[$d], [Math]::Round(100.0*$ist[$d]/$toplam,1), $(if($ornek[$d].Length -gt 55){$ornek[$d].Substring(0,55)+'...'}else{$ornek[$d]}))
  }
  $coz = if($ist.ContainsKey('cozuldu')){ $ist['cozuldu'] } else { 0 }
  Write-Host ""
  Write-Host ("  COZULEN: {0}/{1} = %{2}" -f $coz, $toplam, [Math]::Round(100.0*$coz/$toplam,1))
  Write-Host ""
  if($coz -lt ($toplam*0.5)){
    Write-Host "KIRMIZI: cozme orani %50'nin altinda. Profesor v2 bu haliyle kosturulmaz;"
    Write-Host "         once cozucu duzeltilir. (Para harcamadan once tespit edildi.)"
    exit 2
  }
  Write-Host "YESIL: cozme orani yeterli, profesor v2 kurulabilir."
  exit 0
}
