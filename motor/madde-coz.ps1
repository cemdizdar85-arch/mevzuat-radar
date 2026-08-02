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
  # 28.07 IKI DUZELTME:
  # (1) Eski desen "m.1" ile "m.10" ayrimini SONRAKI KARAKTERE bakarak yapiyordu;
  #     artik dogrudan "ardindan rakam GELMESIN" deniyor. Postgres ileri-bakisi
  #     (?![0-9]) destekler, yani eleme VERITABANINDA yapilir.
  # (2) limit 30'du ve siralama alfabetikti. "Harclar K. (492 s.K.) ek m.1 [1/8]"
  #     gibi kayitlar alfabetik olarak ONCE geldigi icin ilk 30 kayit tamamen
  #     'ek m.1*' olabiliyor ve ARANAN "m.1" limite hic girmiyordu; sonra da
  #     'ambarda-yok' deniyordu. 16 soru tam bu yuzden baglanamamisti - madde
  #     ambarda VARDI. Limit 200'e cikarildi.
  $desen = "$kanunNo.*[^a-zA-Z0-9]m\.$maddeNo(?![0-9])"
  try {
    $r = Invoke-RestMethod -Uri ("$SB_URL/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=imatch." + [uri]::EscapeDataString($desen) + "&order=kaynak_ad&limit=200") -Headers $H -TimeoutSec 60
  } catch { $script:onbellek[$anahtar] = $null; return $null }

  # Seri ayrimi SART: "213 m.5" ile "213 gec. m.5" ve "213 ek m.5" UC AYRI
  # maddedir. Karistirmak, soruya YANLIS METNI dayanak yapmak demektir - ki bu
  # hakemin hatasindan daha kotudur, cunku hakem o metne bakip "destekliyor"
  # der ve hata dogrulanmis gibi gecer.
  # Ambarda UC ayri seri var: "gec. m." (1.927 kayit), "ek m." (459 kayit),
  # "mük. m." (98 kayit). Bunlar duz maddeden AYRI hukumlerdir.
  $ozelSeri = '(?i)gec\.\s*m\.|ge[çc]ici\s*m|ek\s+m\.|m[üu]k\.\s*m\.'
  if($seri -eq 'gec'){    $kayitlar = @($r) | Where-Object { "$($_.kaynak_ad)" -match '(?i)gec\.\s*m\.|ge[çc]ici\s*m' } }
  elseif($seri -eq 'ek'){ $kayitlar = @($r) | Where-Object { "$($_.kaynak_ad)" -match '(?i)ek\s+m\.' } }
  elseif($seri -eq 'muk'){$kayitlar = @($r) | Where-Object { "$($_.kaynak_ad)" -match '(?i)m[üu]k\.\s*m\.' } }
  else {                  $kayitlar = @($r) | Where-Object { "$($_.kaynak_ad)" -notmatch $ozelSeri } }
  if(@($kayitlar).Count -eq 0){ $script:onbellek[$anahtar] = $null; return $null }

  # ayni maddenin parcalarini sirala ve birlestir; farkli madde varsa (m.4 ararken m.40
  # gelmesi gibi) ELE: kaynak_ad'da "m.<no>" hemen ardindan rakam GELMEMELI
  $temiz = @($kayitlar | Where-Object { "$($_.kaynak_ad)" -match ("[^a-zA-Z0-9]m\." + $maddeNo + "(?!\d)") })
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

# --- TEKDUZEN HESAP PLANI YOLU (MSUGT Sira No:1)
# Kasa taramasinda 291 soru "kanun-bulunamadi" ile baglanamadi; hepsi hesap
# planina dayaniyordu: "MSUGT Tekduzen Hesap Plani - 730 Genel Uretim Giderleri"
# gibi. Bunlar kanun MADDESI degil, TEBLIG EKI - kanun/madde deseni onlari
# goremezdi. Oysa ambarda 230 kayit halinde duruyorlar ("THP 730 - Genel Uretim
# Giderleri", kaynak: Resmi Gazete 21447 sayili nusha) ve icleri dolu.
# Muhasebe/Maliyet dersleri kasanin buyuk bir bolumu; kapsam disi birakilamaz.
function HesapPlaniMetni([string]$kaynak){
  $k = "$kaynak"
  if($k -notmatch '(?i)MSUGT|tekd[uü]zen|hesap plan|\bTHP\b'){ return $null }
  # 3 haneli hesap kodlarini topla. "213 sayili VUK" gibi KANUN numaralarini
  # disla - yoksa kanun atfini hesap kodu sanip yanlis metin getiririz.
  $kodlar = @()
  foreach($m in [regex]::Matches($k, '(?<![\d.])([1-7]\d{2})(?![\d])')){
    $son = $k.Substring($m.Index + $m.Length)
    if($son -match '^\s*(say[ıi]l[ıi]|s\.\s*K\.|S[ıi]ra)'){ continue }
    if($kodlar -notcontains $m.Groups[1].Value){ $kodlar += $m.Groups[1].Value }
  }
  if($kodlar.Count -eq 0){ return $null }
  if($kodlar.Count -gt 4){ $kodlar = $kodlar[0..3] }
  $anahtar = "THP|" + ($kodlar -join ',')
  if($script:onbellek.ContainsKey($anahtar)){ return $script:onbellek[$anahtar] }
  $parcalar = @()
  foreach($kod in $kodlar){
    try {
      # 30.07 PS TUZAGI: @(IRM) cok satirli cevabi tek nesne sarar. Once ata, sonra sar.
      $rHam = Invoke-RestMethod -Uri ("$SB_URL/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=imatch." + [uri]::EscapeDataString("^THP\s$kod(?![0-9])") + "&limit=3") -Headers $H -TimeoutSec 60
      $r = @($rHam)
    } catch { continue }
    # 28.07: burada once $x.PSObject.Properties['metin'] ile "alan var mi" diye
    # bakiyordum; kayit DOLU geldigi halde False donuyordu ve fonksiyon sessizce
    # null veriyordu - yani hesap plani yolu hic calismiyordu ama hicbir hata da
    # vermiyordu. Alanin VARLIGINI degil DEGERINI kontrol etmek hem dogru hem sade.
    foreach($x in $r){ if("$($x.metin)".Trim().Length -gt 0){ $parcalar += "$($x.kaynak_ad): $($x.metin)" } }
  }
  if($parcalar.Count -eq 0){ $script:onbellek[$anahtar] = $null; return $null }
  $sonuc = [ordered]@{ hesap=($kodlar -join ','); parca=$parcalar.Count; ad=("THP " + ($kodlar -join '/')); metin=($parcalar -join "`n") }
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

# ---------------------------------------------------------------------------
# TEORI KAPISI (02.08.2026 — Cem: "teori kapisini kur")
# OLCUM: hakemin "destek=yetersiz" dedigi 8.577 sorunun 7.377'si MUHASEBE
# KAVRAM sorusu (dikey analiz, katki payi, birlesik maliyet...). Bunlarin dogru
# dayanagi ne kanun maddesi ne hesap plani - TEORI NOTU. Notlar ambara sonradan
# girdigi icin uretici o soruları bulabildigi en yakin kanuna baglamis; hakem de
# hakli olarak "bu metin bunu soylemiyor" demis.
# Bu kapi, konu/kaynak metnindeki anahtar kelimelerle ambardaki 'Teori Notu -'
# kayitlarini arar. Bulursa DOGRU metni dondurur. Uydurma yok: yalniz ambarda
# GERCEKTEN duran nota baglar, bulamazsa dokunmaz.
function TeoriNotuMetni([string]$kaynak, [string]$konu){
  $havuz = ("$konu " + "$kaynak").ToLowerInvariant()
  if($havuz.Trim().Length -lt 4){ return $null }
  # 4+ harfli anlamli kelimeler (TR harfleri sadelestirilir - ambar aramasi imatch)
  $kel = @()
  foreach($w in (($havuz -replace '[ıİ]','i' -replace '[şŞ]','s' -replace '[ğĞ]','g' -replace '[üÜ]','u' -replace '[öÖ]','o' -replace '[çÇ]','c') -split '[^a-z0-9]+')){
    if($w.Length -ge 5 -and $kel -notcontains $w){ $kel += $w }
  }
  if($kel.Count -eq 0){ return $null }
  if($kel.Count -gt 6){ $kel = $kel[0..5] }
  $anahtar = "TEORI|" + ($kel -join ',')
  if($script:onbellek.ContainsKey($anahtar)){ return $script:onbellek[$anahtar] }
  $desen = '^Teori Notu.*(' + ($kel -join '|') + ')'
  try {
    $rHam = Invoke-RestMethod -Uri ("$SB_URL/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=imatch." + [uri]::EscapeDataString($desen) + "&limit=8") -Headers $H -TimeoutSec 60
    $r = @($rHam)
  } catch { return $null }
  if($r.Count -eq 0){ $script:onbellek[$anahtar] = $null; return $null }

  # 02.08 PILOT DERSI (0,31 USD ile ogrenildi, 40 USD kurtarildi):
  # "herhangi bir kelime tutarsa bagla" cok gevsekti. Pilotta 31 soru teori
  # notuyla eslesti ama eslesmeler ALAKASIZDI: "pesin odenen vergilerin
  # muhasebe kaydi" sorusu 'vergi teorisi' notuna, "bagli ortaklik paylarinin
  # muhasebelestirilmesi" 'paranin zaman degeri' notuna baglanmisti. Tek
  # tesadufi kelime yetiyordu ve hakem haklı olarak "bu metin bunu soylemiyor"
  # dedi. YANLIS NOTA BAGLAMAKTANSA KAYNAKSIZ BIRAKMAK YEGDIR.
  # Artik adaylar PUANLANIR: baslikta gecen anahtar kelime 3 puan, metinde
  # gecen 1 puan. Esik: en az 2 farkli kelime baslikta VEYA 1 baslik + 3 metin.
  $enIyi = $null; $enIyiPuan = 0
  foreach($aday in $r){
    $bas = ("$($aday.kaynak_ad)").ToLowerInvariant() -replace '[ıİ]','i' -replace '[şŞ]','s' -replace '[ğĞ]','g' -replace '[üÜ]','u' -replace '[öÖ]','o' -replace '[çÇ]','c'
    $met = ("$($aday.metin)").ToLowerInvariant() -replace '[ıİ]','i' -replace '[şŞ]','s' -replace '[ğĞ]','g' -replace '[üÜ]','u' -replace '[öÖ]','o' -replace '[çÇ]','c'
    $basHit = 0; $metHit = 0
    foreach($w in $kel){
      if($bas.Contains($w)){ $basHit++ }
      elseif($met.Contains($w)){ $metHit++ }
    }
    $puan = ($basHit * 3) + $metHit
    if($puan -gt $enIyiPuan -and ($basHit -ge 2 -or ($basHit -ge 1 -and $metHit -ge 3))){
      $enIyiPuan = $puan; $enIyi = $aday
    }
  }
  if(-not $enIyi){ $script:onbellek[$anahtar] = $null; return $null }   # emin degilsen BAGLAMA
  $sonuc = [ordered]@{ ad = "$($enIyi.kaynak_ad)"; parca = 1; metin = "$($enIyi.metin)"; puan = $enIyiPuan }
  $script:onbellek[$anahtar] = $sonuc
  return $sonuc
}

# --- B13 KOMSU MADDE (03.08.2026, 500-okumasi dersi): TTK 482 etiketli uc soru
#     aslinda m.483'un hukmunu soruyordu; hakem yalniz 482'yi gorunce ya
#     "yetersiz" dedi ya da yanlisi onayladi. Cozum: duz sayili maddelerde
#     n-1 ve n+1 metinleri de getirilir; hakem "destek komsudaysa kaynak
#     kaymasi var" diye HUKUM verebilir. Yalniz duz seri (muk/gec/ek haric).
function KomsuMetinleri([string]$kanunNo, [string]$maddeNo){
  $liste = @()
  $n = 0
  if(-not [int]::TryParse("$maddeNo", [ref]$n)){ return $liste }
  foreach($km in @(($n-1), ($n+1))){
    if($km -lt 1){ continue }
    $m = MaddeMetni $kanunNo "$km" ''
    if($m -and "$($m.metin)".Trim().Length -ge 40){
      $mt = "$($m.metin)"
      if($mt.Length -gt 1200){ $mt = $mt.Substring(0,1200) }
      $liste += ,([ordered]@{ madde = "$km"; ad = "$($m.ad)"; metin = $mt })
    }
  }
  return $liste
}

function KaynakCoz([string]$kaynak, [string]$konu = ''){
  if(MevzuatDisiMi $kaynak){
    # mevzuat disi = teori alani. Once ambardaki teori notuna bakilir; varsa
    # soru ARTIK KAYNAKSIZ DEGILDIR ve hakem dogru metinle yargilar.
    $tn = TeoriNotuMetni $kaynak $konu
    if($tn){ return [ordered]@{ durum='cozuldu-teori'; kaynak=$kaynak; ad=$tn.ad; parca=$tn.parca; metin=$tn.metin } }
    return [ordered]@{ durum='mevzuat-disi'; kaynak=$kaynak }
  }
  $std = StandartMetni $kaynak
  if($std){ return [ordered]@{ durum='cozuldu-standart'; kaynak=$kaynak; standart=$std.standart; parca=$std.parca; ad=$std.ad; metin=$std.metin } }
  # Hesap plani KANUN yolundan ONCE denenir: "MSUGT 360 hesap aciklamasi;
  # 213 sayili VUK muhtasar beyan esasi" gibi BILESIK atiflarda asil dayanak
  # hesap planidir; kanun yolu once calissa 213'e sapar ve yanlis metni getirir.
  $thp = HesapPlaniMetni $kaynak
  if($thp){ return [ordered]@{ durum='cozuldu-hesapplani'; kaynak=$kaynak; hesap=$thp.hesap; parca=$thp.parca; ad=$thp.ad; metin=$thp.metin } }
  $kn = KanunNo $kaynak
  $mn = MaddeNo $kaynak
  if(-not $kn){ return [ordered]@{ durum='kanun-bulunamadi'; kaynak=$kaynak } }
  if(-not $mn){ return [ordered]@{ durum='madde-bulunamadi'; kaynak=$kaynak; kanun=$kn } }
  # 28.07: gec./ek maddeler artik kendi serilerinde ARANIYOR, birakilmiyor.
  # Onceden 'gecici-ek-madde' deyip vazgeciyorduk; oysa ambarda varlar. Ustelik
  # gecici maddeler en cok DEGISEN maddelerdir (EYT, af, yapilandirma) - yani
  # tam da nobet tutmamiz gereken yerdi.
  # MUKERRER EN TEHLIKELISI: ambarda 98 'mük. m.' kaydi var ve cozucu bunu
  # bilmiyordu. "VUK Mük. Madde 279" atfini gorunce DUZ m.279'u getiriyordu -
  # yani soruya YANLIS MADDENIN METNINI dayanak yapiyordu. Bu, hakemin kendi
  # hatasindan daha kotudur: hakem o yanlis metne bakip "destekliyor" der ve
  # hata DOGRULANMIS gibi gecer. Once mukerrer bakilir.
  $seri = ''
  if("$kaynak" -match '(?i)m[üu]k(errer)?\.?\s*(m\.|madde)'){ $seri = 'muk' }
  elseif("$kaynak" -match '(?i)ge[çc]ici\s*m|gec\.\s*m'){ $seri = 'gec' }
  elseif("$kaynak" -match '(?i)ek\s+m\.'){ $seri = 'ek' }
  $m = MaddeMetni $kn $mn $seri
  if(-not $m){
    # 02.08: madde ambarda yoksa son care olarak teori notuna bakilir - soru
    # kavram sorusu olabilir ve uretici onu yanlislikla bir kanuna baglamistir.
    $tn2 = TeoriNotuMetni $kaynak $konu
    if($tn2){ return [ordered]@{ durum='cozuldu-teori'; kaynak=$kaynak; ad=$tn2.ad; parca=$tn2.parca; metin=$tn2.metin } }
    return [ordered]@{ durum=$(if($seri){"seri-$seri-ambarda-yok"}else{'ambarda-yok'}); kaynak=$kaynak; kanun=$kn; madde="$seri$mn" }
  }
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
