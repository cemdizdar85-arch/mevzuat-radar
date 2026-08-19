# ============================================================================
#  KONU-KAYNAK KARNESI — PARALI MUSLUGUN ON SARTI
#  Cem 27.07: "musluk bosa para akitti - matematikte mevzuat yok, soru cikmadi;
#  yada yanlis cikan soru var. Muslugu acacagiz ama bosa atmayacak."
#
#  NE YAPAR: cikmis sinav konularinin (sgs-analiz.json, 16 donem, 1.798 konu)
#  HER BIRI icin ambarda KAYNAK METIN VAR MI diye olcer ve karne verir:
#     URET        -> ambarda kaynak var, fabrika bu konuda calisabilir
#     KAYNAK YOK  -> ambarda metin yok; fabrika GIRMEZ (once ambara eklenir)
#     MEVZUAT-DISI-> dersin dogasi geregi mevzuati yok (dil/genel kultur/
#                    matematik). Fabrika ASLA girmez, elle yazilir.
#
#  KURAL: paralı parti kosmadan ONCE bu karne bakilir. Kirmizi satira
#  fabrika sokulmaz - 27.07'de Matematik'te tam bu oldu, uretildi ve teyit
#  kapisi HEPSINI eledi. Para gitti, soru kalmadi.
#
#  API PARASI YEMEZ - yalniz Supabase okumasi.
#  ENV: SUPABASE_KEY (yoksa publishable anahtar ile okur; dokumanlar acik)
# ============================================================================
$ErrorActionPreference = "Stop"
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
# KOR KALMA KURALI: Actions loglari GM'ye kapali. Bu betik bugune kadar hic
# log birakmiyordu - 29.07'de kosup kosmadigi anlasilamadi, yalnizca ciktinin
# TARIHINE bakilarak "yenilenmemis" denebildi. Bir kanal kendi hatasini
# yazamiyorsa kurulmus sayilmaz.
try { Start-Transcript -Path (Join-Path $kok 'veri/karne-log.txt') -Force | Out-Null } catch {}
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$KEY = if($env:SUPABASE_KEY){ $env:SUPABASE_KEY } else { "sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg" }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

# Mevzuati OLMAYAN dersler: bunlar beceri/kultur dersi, kaynak metni yok.
# Fabrika bunlara GIRMEZ; sorulari elle yazilir (27.07'de 16 Matematik
# sorusu boyle yazildi, maliyeti sifir).
$MEVZUAT_DISI = @('Yabanci Dil','Genel Kultur-Genel Yetenek','Matematik-Istatistik','Matematik','Turkce','Inkilap')

# Konu adindan anlamli anahtar kelime cikarirken atilacaklar
$STOP = @('ve','ile','icin','bir','bu','su','o','de','da','ki','mi','mu','ne','nasil','hangi','olan','olarak','gibi','kadar','daha','cok','az','en','her','tum','veya','ya','ama','fakat','ancak','yani','iste','sonra','once','uzere','gore','karsi','dahil','haric','hesabi','hesap','kaydi','kavrami','yontemi','turu','sekli')

# TURKCE KOPRUSU (28.07 - push oncesi testte yakalandi):
# Sinav konu adlari ASCII yazili ("donemsellik kavrami"), ambar metni gercek
# Turkce ("donemsellik kavrami" -> o umlautlu, i noktasiz). Duz ilike ile
# ESLESMIYOR - ilk testte "donemsellik+kavram" 0 dondu. Cozum: ASCII harfi
# Turkce esiyle birlikte karakter sinifina cevirip PostgREST 'imatch'
# (buyuk/kucuk duyarsiz regex) kullanmak. Olculdu:
#   metin=ilike.*donemsellik*            -> 0   (ASCII)
#   metin=imatch.d[oo]nemsellik          -> 3   (koprulu)
#   metin=imatch.kar[ss][ii]l[ii]k       -> 620
# 28.07 2. tur — BITISIK/AYRIK YAZIM KOPRUSU: eslesme testinde 24 konudan
# yalnizca 8'i tutuyordu. Sebep icerik eksikligi DEGIL, yazim farkiydi -
# sinav konusu "ozsermaye" yazarken ambar metni "oz sermaye" diyor,
# "gayrisafilik" vs "gayri safilik", "basabas" vs "basa bas". Cozum: kelime
# ICINDEKI her harf ciftinin arasina OPSIYONEL BOSLUK (\s?) konuldu; harf
# dizisi bitisik kalmak zorunda ama arada bosluk olabilir. Bu, notlari
# tarayiciya gore egip bukmek yerine TARAYICIYI duzeltir.
function TurkceRegex([string]$s, [bool]$bosluklaEsnek = $true){
  $sb = New-Object Text.StringBuilder
  $oncekiHarfti = $false
  foreach($ch in $s.ToLower().ToCharArray()){
    $harfMi = ("$ch" -match '[\p{L}\p{Nd}]')
    # iki harf arasina opsiyonel bosluk koy (bitisik/ayrik yazim koprusu)
    if($bosluklaEsnek -and $harfMi -and $oncekiHarfti){ [void]$sb.Append('\s?') }
    switch -CaseSensitive ("$ch") {
      'c' { [void]$sb.Append('[c' + [char]0x00E7 + ']') }
      'g' { [void]$sb.Append('[g' + [char]0x011F + ']') }
      'i' { [void]$sb.Append('[i' + [char]0x0131 + ']') }
      'o' { [void]$sb.Append('[o' + [char]0x00F6 + ']') }
      's' { [void]$sb.Append('[s' + [char]0x015F + ']') }
      'u' { [void]$sb.Append('[u' + [char]0x00FC + ']') }
      default {
        if($harfMi){ [void]$sb.Append($ch) }
        elseif("$ch" -eq ' '){ [void]$sb.Append('\s+') }
        else { [void]$sb.Append('.') }
      }
    }
    $oncekiHarfti = $harfMi
  }
  return $sb.ToString()
}

# 18.08 DERS (olcemedigine-kusur-deme): sorgu HATASI "kayit yok" DEGILDIR.
# Ilk buyuk kosuda hiz siniri yuzunden sorgular sessizce -1 dondu ve TMS 37
# (ambarda 95 kayit) bile KAYNAK YOK sayildi. Artik: 3 deneme + geri cekilme,
# yine olmazsa konu OLCULEMEDI olarak isaretlenir - KAYNAK YOK denmez.
$script:hataliSorgu = 0
function KayitSay([string]$filtre){
  for($deneme=1; $deneme -le 3; $deneme++){
    try {
      $u = "$SB_URL/rest/v1/dokumanlar?select=id&$filtre&limit=1"
      $r = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers ($H + @{ Prefer = "count=exact" }) -TimeoutSec 45
      return [int](($r.Headers['Content-Range'] -split '/')[-1])
    } catch {
      if($deneme -lt 3){ Start-Sleep -Seconds (2 * $deneme) }
    }
  }
  $script:sorguHata = $true
  $script:hataliSorgu++
  return -1
}

# --- konu listesini topla ---
# 18.08: girdi/cikti ortamdan secilebilir (varsayilan davranis AYNEN korunur).
# KARNE_GIRDI=smmm-analiz.json + KARNE_CIKTI=konu-kaynak-karnesi-smmm.json ile
# ayni motor Yeterlilik arsivini de olcer; CI kosusu bu degiskenleri bilmez.
$girdiAd = if($env:KARNE_GIRDI){ $env:KARNE_GIRDI } else { "sgs-analiz.json" }
$analiz = Get-Content (Join-Path $kok "veri\$girdiAd") -Raw -Encoding UTF8 | ConvertFrom-Json
$konular = @{}
foreach($d in @($analiz.donemler)){
  if(-not $d.konuSayim){ continue }
  foreach($p in @($d.konuSayim.PSObject.Properties)){
    if($konular.ContainsKey($p.Name)){ $konular[$p.Name] += [int]$p.Value } else { $konular[$p.Name] = [int]$p.Value } }
}
Write-Host ("Konu sayisi: {0} (16 donem birlestirilmis)" -f $konular.Count)

$karne = New-Object System.Collections.Generic.List[object]
$say = @{ URET=0; 'KAYNAK YOK'=0; 'MEVZUAT-DISI'=0; 'OLCULEMEDI'=0 }
$n = 0
foreach($anahtar in ($konular.Keys | Sort-Object)){
  $n++
  $parca = $anahtar -split '\|', 2
  $ders = $parca[0]; $konu = if($parca.Count -gt 1){ $parca[1] } else { $anahtar }
  $adet = $konular[$anahtar]

  if($MEVZUAT_DISI -contains $ders){
    $karne.Add([ordered]@{ ders=$ders; konu=$konu; cikmisSoru=$adet; ambarKayit=0; karar='MEVZUAT-DISI'; not='Dersin mevzuati yok - elle yazilir, fabrika girmez' })
    $say['MEVZUAT-DISI']++
    continue
  }

  # 18.08: hiz siniri sigortasi - sorgular arasi kisa nefes
  Start-Sleep -Milliseconds 120
  $script:sorguHata = $false

  # 1) konuda standart atfi var mi (tms 40, tfrs 15, bds 260)
  $std = [regex]::Match($konu, '(tms|tfrs|bds)\s*(\d{1,3})', 'IgnoreCase')
  $bulunan = -1; $nasil = ''
  if($std.Success){
    $kod = ($std.Groups[1].Value).ToUpper() + '*' + $std.Groups[2].Value + '*'
    $bulunan = KayitSay ("kaynak_ad=like." + [uri]::EscapeDataString($kod))
    $nasil = "standart atfi: $($std.Groups[1].Value.ToUpper()) $($std.Groups[2].Value)"
  }
  # 28.07 3. tur — BASLIK KOR NOKTASI: tarayici yalnizca 'metin' alanina
  # bakiyordu. Elle yazilan notlarda konu ifadesi cogu zaman KAYNAK_AD veya
  # BASLIK alaninda gecip govdede farkli kelimelerle anlatiliyor ("yatay
  # analiz kurallari" basliktaydi, metinde "YATAY (KARSILASTIRMALI) ANALIZ"
  # yaziyordu). Bu yuzden yazilmis notlar "kaynak yok" gorunuyordu.
  # Artik UC ALANDA birden aranir: metin OR kaynak_ad OR baslik.
  # 2) tam ifade (Turkce + bitisik/ayrik koprulu regex ile), UC ALANDA
  if($bulunan -le 0){
    $rx = [uri]::EscapeDataString((TurkceRegex $konu))
    $bulunan = KayitSay ("or=(metin.imatch.$rx,kaynak_ad.imatch.$rx,baslik.imatch.$rx)")
    if($bulunan -gt 0){ $nasil = "tam ifade" }
  }
  # 3) en uzun iki anlamli kelime birlikte; her kelime UC ALANDAN BIRINDE
  if($bulunan -le 0){
    $kelimeler = @($konu -split '[^\p{L}\d]+' | Where-Object { $_.Length -ge 5 -and $STOP -notcontains $_.ToLower() } | Sort-Object { -$_.Length } | Select-Object -First 2)
    if($kelimeler.Count -ge 1){
      $parcalar = @()
      foreach($kel in $kelimeler){
        $r = [uri]::EscapeDataString((TurkceRegex $kel))
        $parcalar += "or(metin.imatch.$r,kaynak_ad.imatch.$r,baslik.imatch.$r)"
      }
      $bulunan = KayitSay ("and=(" + ($parcalar -join ',') + ")")
      if($bulunan -gt 0){ $nasil = "anahtar kelime: " + ($kelimeler -join ' + ') }
    }
  }

  if($bulunan -gt 0){
    $karne.Add([ordered]@{ ders=$ders; konu=$konu; cikmisSoru=$adet; ambarKayit=$bulunan; karar='URET'; not=$nasil })
    $say['URET']++
  } elseif($script:sorguHata){
    # sorgu(lar) hata dondu - yokluk OLCULMEDI, iddia edilemez
    $karne.Add([ordered]@{ ders=$ders; konu=$konu; cikmisSoru=$adet; ambarKayit=-1; karar='OLCULEMEDI'; not='Sorgu hatasi (3 deneme) - kaynak yok DENEMEZ, yeniden olculmeli' })
    $say['OLCULEMEDI']++
  } else {
    $karne.Add([ordered]@{ ders=$ders; konu=$konu; cikmisSoru=$adet; ambarKayit=0; karar='KAYNAK YOK'; not='Ambarda metin bulunamadi - once kaynak yutulmali' })
    $say['KAYNAK YOK']++
  }
  if($n % 100 -eq 0){ Write-Host ("  ...{0}/{1}" -f $n, $konular.Count) }
}

# --- yaz ---
$cikti = [ordered]@{
  guncelleme = (Get-Date).ToString('yyyy-MM-dd HH:mm')
  aciklama   = "Konu-Kaynak Karnesi: her cikmis sinav konusu icin ambarda kaynak metin var mi. PARALI PARTI KOSMADAN ONCE BAKILIR; 'KAYNAK YOK' ve 'MEVZUAT-DISI' satirlarina fabrika SOKULMAZ."
  ozet       = $say
  konular    = $karne.ToArray()
}
$ciktiAd = if($env:KARNE_CIKTI){ $env:KARNE_CIKTI } else { "konu-kaynak-karnesi.json" }
$yol = Join-Path $kok "veri\$ciktiAd"
[IO.File]::WriteAllText($yol, ($cikti | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "=========== KONU-KAYNAK KARNESI ==========="
Write-Host ("  URET (kaynak var)        : {0}" -f $say['URET'])
Write-Host ("  KAYNAK YOK (once yut)    : {0}" -f $say['KAYNAK YOK'])
Write-Host ("  MEVZUAT-DISI (elle yaz)  : {0}" -f $say['MEVZUAT-DISI'])
Write-Host ("  OLCULEMEDI (sorgu hatasi): {0}" -f $say['OLCULEMEDI'])
Write-Host ("  hatali sorgu toplami     : {0}" -f $script:hataliSorgu)
Write-Host ("  -> {0}" -f $yol)
Write-Host ""
Write-Host "--- KAYNAK YOK olan, EN COK SORU CIKMIS 20 konu (oncelikli yutma listesi):"
$karne | Where-Object { $_.karar -eq 'KAYNAK YOK' } | Sort-Object { -$_.cikmisSoru } | Select-Object -First 20 | ForEach-Object {
  Write-Host ("   {0,2} soru | {1,-26} | {2}" -f $_.cikmisSoru, $_.ders, $_.konu)
}
exit 0
