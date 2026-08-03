# ============================================================================
#  HESAP KODU DENETIMI (03.08.2026) — 0 USD, API YOK
#
#  NEDEN: Cem pilot taslaginda dort yanlis hesap kodu yakaladi — personel avansi
#  icin 253 (oysa 253 = TESIS, MAKINE VE CIHAZLAR; dogrusu 196), siparis avansi
#  icin 122 (dogrusu 159), kira teminati icin 127 (dogrusu 126), teslim alinmamis
#  demirbas pesinati icin 122 (dogrusu 259). Dordu de modelin kendi hafizasindan.
#
#  CEM'IN SORUSU: "gormedigim yerlerde neler var?" — HAKLI SORU. O yanlislar
#  TASLAKTA idi, kasaya yazilmadi. Ama kasadaki 27.478 soru da benzer bir uretimle
#  yazildi. Ayni hata orada da var mi? Bilmiyoruz. BILMEMEK KABUL EDILEMEZ.
#
#  BU SCRIPT: Tekduzen Hesap Plani'ni (veri/mevzuat/msugt-thp-tam.json) resmi
#  kod->ad listesi olarak okur, kasadaki HER sorunun metninde ve aciklamalarinda
#  gecen "NNN HesapAdi" iddialarini bulur ve resmi adla KARSILASTIRIR.
#
#  UC SONUC:
#    UYUYOR      : kod ve ad resmi listeyle ortusuyor
#    UYMUYOR     : kod var ama BASKA hesabin adi yazilmis  <-- Cem'in yakaladigi hata
#    KOD_YOK     : boyle bir hesap kodu THP'de yok
#
#  Rapor SAYI tasir; ornekler soru ID + kod + iddia + resmi ad seklinde, soru
#  METNI YAZILMAZ (public depo, 03.08 sizinti dersi).
#
#  ENV: SUPABASE_SERVICE_KEY · Cikti: veri/hesap-kodu-denetimi.json
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/hesap-kodu-denetimi.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 5
  if($j.Length -gt 60000){ $j = ConvertTo-Json -Depth 2 -InputObject @{ durum='KIRMIZI - rapor sismis'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1} | {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

# --- RESMI KOD -> AD LISTESI (Tekduzen Hesap Plani) ---
# ============================================================================
#  03.08 - "HESAP PLANI EKSIK" SANDIM, MESELE OKUMAYDI (Cem: "tam yut")
#
#  Denetim YALNIZ msugt-thp-tam.json okuyordu: 199 hesap, ve icinde 100 KASA,
#  102 BANKALAR, 120 ALICILAR, 600 YURTICI SATISLAR, 730 GENEL URETIM GIDERLERI
#  YOKTU. "Referans verimiz eksik" diye rapor ettim. YANLIS TESHIS.
#  Butun msugt*.json dosyalari birlesince 230 hesap ve o 19 temel hesabin 19'u
#  da VAR. Yani veri ambarda duruyordu; ben tek dosya okuyup eksik saniyordum.
#
#  Ders: "kaynak eksik" demeden once KAYNAGIN TAMAMINI okudugunu dogrula.
#  Bugun ucuncu kez ayni bicim: dar okuma -> yanlis sayi -> yanlis teshis.
# ============================================================================
$RESMI = @{}
$thpDizin = Join-Path $kok 'veri/mevzuat'
$okunanDosya = 0
foreach($f in (Get-ChildItem (Join-Path $thpDizin 'msugt*.json') -ErrorAction SilentlyContinue)){
  try {
    $j = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($b in @($j.belgeler)){
      # kaynak_ad ornegi: "THP 101 - ALINAN ÇEKLER"
      $m = [regex]::Match("$($b.kaynak_ad)", '(?i)THP\s*(\d{3})\s*[-–—]\s*(.+)$')
      if($m.Success -and -not $RESMI.ContainsKey($m.Groups[1].Value)){
        $RESMI[$m.Groups[1].Value] = $m.Groups[2].Value.Trim()
      }
    }
    $okunanDosya++
  } catch { Write-Host ("THP dosyasi okunamadi: {0}" -f $f.Name) }
}
Write-Host ("Resmi hesap kodu: {0} ({1} dosyadan birlestirildi)" -f $RESMI.Count, $okunanDosya)
if($RESMI.Count -lt 200){
  # Temel hesaplar yoksa denetim guvenilir degildir - sessizce devam etme.
  $eksikTemel = @('100','102','120','153','600','730') | Where-Object { -not $RESMI.ContainsKey($_) }
  if($eksikTemel.Count -gt 0){
    Write-Host ("!! KIRMIZI: temel hesaplar eksik: {0}" -f ($eksikTemel -join ', '))
    RaporYaz @{ durum='KIRMIZI'; sebep='THP referansi eksik'; okunan_kod=$RESMI.Count; eksik_temel=$eksikTemel }
    exit 1
  }
}

# --- kasa ---
$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu,soru,siklar,dogru,aciklama,kaynak,yayin&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)
if($kasa.Count -lt 1000){ Write-Host "!! SUPHELI: kasa kucuk gorundu - sayfalama kirik olabilir." }

# Turkce duyarsiz sadelestirme (imatch tuzagi: ASCII<->Turkce)
# 03.08 - IKINCI SAHTE ALARM. Ilk hali "-replace 'İ','I'" kullaniyordu; PowerShell
# -replace REGEX'tir ve dosya kodlamasina gore Turkce harfler beklenmedik davranir.
# Sonuc: "TAŞITLAR" -> "TAS TLAR" olup resmi "TAŞITLAR" ile UYMUYOR sayildi
# (601 YURTDIŞI SATIŞLAR da ayni sekilde). Yani sahte yanlislar uretiliyordu.
# Cozum: regex yok, KARAKTER KARAKTER acik esleme. Ne yaptigini gizlemeyen kod.
$HARF = @{
  [char]0x0130='I'; [char]0x0131='I'; [char]'i'='I'; [char]'I'='I'   # İ ı i I
  [char]0x015E='S'; [char]0x015F='S'                                  # Ş ş
  [char]0x011E='G'; [char]0x011F='G'                                  # Ğ ğ
  [char]0x00DC='U'; [char]0x00FC='U'                                  # Ü ü
  [char]0x00D6='O'; [char]0x00F6='O'                                  # Ö ö
  [char]0x00C7='C'; [char]0x00E7='C'                                  # Ç ç
}
function Sade([string]$t){
  if($null -eq $t){ return '' }
  $sb = New-Object Text.StringBuilder
  foreach($c in $t.ToCharArray()){
    if($HARF.ContainsKey($c)){ [void]$sb.Append($HARF[$c]); continue }
    $u = [char]::ToUpperInvariant($c)
    if(($u -ge 'A' -and $u -le 'Z') -or ($u -ge '0' -and $u -le '9')){ [void]$sb.Append($u) }
    else { [void]$sb.Append(' ') }
  }
  return (($sb.ToString()) -replace '\s+',' ').Trim()
}
# Ad benzerligi: 4+ harflik ORTAK kelime varsa "uyuyor" say. Boylece
# "196 PERSONEL AVANSLARI" ile resmi "PERSONEL AVANSLARI" tutar; ama
# "253 Personel Avanslari" resmi "TESIS MAKINE VE CIHAZLAR" ile TUTMAZ.
# 03.08 UCUNCU SAHTE ALARM DALGASI: birebir kelime esitligi Turkce EKLERI
# tanimiyordu. "KARSILIKLAR GIDERI" ile resmi "KARSILIK GIDERLERI" ayni hesap
# oldugu halde UYMUYOR sayildi; "HES KDVS" kisaltmasi da "HESAPLANAN KDV" ile
# tutmadi. 1.009'luk rakamin icinde bu tur masum sorular vardi - toplu yayindan
# cekseydik DOGRU sorulari da cekecektik. Yeni kural: iki kelimeden biri
# digerinin ONEKI ise (en az 3 harf) ayni kok sayilir. "KARSILIK"~"KARSILIKLAR",
# "GIDER"~"GIDERLERI", "HES"~"HESAPLANAN" tutar; "GELIR" ile "GELECEK" TUTMAZ.
function AdUyuyorMu([string]$iddia, [string]$resmi){
  $a = @((Sade $iddia) -split ' ' | Where-Object { $_.Length -ge 3 })
  $b = @((Sade $resmi) -split ' ' | Where-Object { $_.Length -ge 3 })
  if($a.Count -eq 0 -or $b.Count -eq 0){ return $true }   # karar veremiyorsak SUCLAMA
  foreach($k in $a){
    foreach($r in $b){
      if($k.StartsWith($r) -or $r.StartsWith($k)){ return $true }
    }
  }
  return $false
}

# ============================================================================
#  BIRIM TUZAGI — ilk olcumde (03.08 07:49) yakalandi, rakam SAHTEYDI.
#
#  Ilk desen "750 TL borc" ifadesindeki 750'yi HESAP KODU, "TL"yi de HESAP ADI
#  sandi. Sonuc: "kod 750 yazilan ad 'TL BORC' resmi ad 'ARASTIRMA VE GELISTIRME
#  GIDERLERI' - 212 kez" gibi 18.072 sahte yanlis ve %49'luk uydurma bir oran.
#  Ayni sekilde "480 adet" -> "boyle kod yok" sayildi.
#
#  Rakama degil ORNEGE bakmak yakaladi. Kural: yeni bir olcum kurulunca once
#  ilk on ornegi gozle oku; oran akla yatkin gorunse bile.
#
#  Iki filtre: (1) sayidan sonraki kelime BIRIM ise atla, (2) sayinin onunde
#  nokta/virgul/rakam varsa (1.750 gibi) bu bir tutardir, atla.
# ============================================================================
$BIRIM = @('TL','LIRA','LİRA','USD','EUR','ADET','GUN','GÜN','AY','YIL','SAAT','KG','TON','M2','MT','PUAN','KURUS','KURUŞ','TANE','KISI','KİŞİ','TAKSIT','TAKSİT')
# 03.08 - CEM: "253/181 sadece bu degil, hesap planina gore kontrol et."
# Denetim ZATEN 199 resmi hesabin tamamina bakiyor (tek tek koda degil). Ama
# DESEN dar oldugu icin bazi yazim bicimlerini hic gormuyordu; yani 738 rakami
# EKSIK. Olculen kacirmalar: "196 personel avanslari" (kucuk harf),
# "181 - GELIR TAHAKKUKLARI" (tire), "Personel Avanslari (196)" (ad once).
# "620 numarali hesap" gibi ADSIZ kullanim BILEREK disarida - orada
# dogrulanacak bir kod-ad eslesmesi yok.
$reKod  = [regex]'(?<![\d.,])\b([1-8]\d{2})(?!\d)\s*[-–—]?\s*(?!numaral|no.?lu|say[ıi]l|adet|kalem|tane|hesab|hesap|kodlu|nolu)([A-Za-zÇĞİÖŞÜçğıöşü][A-Za-zÇĞİÖŞÜçğıöşü\.]*(?:\s+[A-Za-zÇĞİÖŞÜçğıöşü\.]+){0,4})'
$reKod2 = [regex]'([A-Za-zÇĞİÖŞÜçğıöşü][A-Za-zÇĞİÖŞÜçğıöşü\.]*(?:\s+[A-Za-zÇĞİÖŞÜçğıöşü\.]+){0,4})\s*\(\s*([1-8]\d{2})\s*\)'
$uyuyor=0; $uymuyor=0; $kodYok=0; $birimAtlanan=0; $adDisiAtlanan=0
$soruUymuyor = @{}; $soruKodYok = @{}
$ornek = New-Object System.Collections.Generic.List[object]
$kodSayaci = @{}

foreach($s in $kasa){
  $tum = "$($s.soru)"
  if($s.siklar){ foreach($p in $s.siklar.PSObject.Properties){ $tum += ' ' + "$($p.Value)" } }
  if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){ $tum += ' ' + "$($p.Value)" } }
  # Iki bicim birlikte: "NNN Ad" ve "Ad (NNN)"
  $ciftler = New-Object System.Collections.Generic.List[object]
  foreach($mm in $reKod.Matches($tum)){  $ciftler.Add(@{ kod=$mm.Groups[1].Value; ad=$mm.Groups[2].Value.Trim() }) }
  foreach($mm in $reKod2.Matches($tum)){ $ciftler.Add(@{ kod=$mm.Groups[2].Value; ad=$mm.Groups[1].Value.Trim() }) }
  foreach($cf in $ciftler){
    $kod = $cf.kod
    $ad  = $cf.ad
    if($ad.Length -lt 4){ continue }
    # BIRIM TUZAGI: "750 TL borc" hesap kodu degil TUTARDIR - atla
    $ilkKelime = (Sade $ad) -split ' ' | Select-Object -First 1
    if($BIRIM -contains $ilkKelime){ $birimAtlanan++; continue }
    if(-not $RESMI.ContainsKey($kod)){
      $kodYok++; $soruKodYok["$($s.id)"] = 1
      continue
    }
    # ====================================================================
    #  BEYAZ LISTE (03.08 - ucuncu sahte alarm dalgasi)
    #
    #  Kelime avi calismadi: once "TL" (birim), sonra "hesabina" (hesap
    #  kelimesi), simdi "PARAGRAF" - metinde "...230 paragrafinda..." gecince
    #  paragraf kelimesini HESAP ADI sandim. Ilk yedi ornek 291 sahte alarm.
    #  Kara liste tutmak bitmez; her yeni kelime yeni yama demek.
    #
    #  DOGRU MANTIK TERSI: bir ifade ancak THP'DEKI HERHANGI BIR RESMI ADA
    #  benziyorsa "hesap adi iddiasi"dir. Hicbirine benzemiyorsa o zaten hesap
    #  adi degildir - suclanmaz, SESSIZCE ATLANIR.
    #  Boylece "yanlis" sayisi yalniz GERCEK kod-ad esleme hatalarini gosterir:
    #  ad bir hesap adi, ama YANLIS kodun adi (181/Diger Donen Varliklar gibi).
    # ====================================================================
    $adIddiaMi = $false
    foreach($resmiAd in $RESMI.Values){
      if(AdUyuyorMu $ad $resmiAd){ $adIddiaMi = $true; break }
    }
    if(-not $adIddiaMi){ $adDisiAtlanan++; continue }
    if(AdUyuyorMu $ad $RESMI[$kod]){ $uyuyor++ }
    else {
      $uymuyor++; $soruUymuyor["$($s.id)"] = 1
      $anah = "$kod|$(Sade $ad)"
      $kodSayaci[$anah] = 1 + $kodSayaci[$anah]
      if($ornek.Count -lt 40){
        $ornek.Add([ordered]@{ soru_id="$($s.id)"; ders="$($s.ders)"; kod=$kod
                               yazilan_ad=$ad; resmi_ad=$RESMI[$kod]; yayinda=$s.yayin })
      }
    }
  }
}

# En sik tekrarlanan yanlis eslesmeler (once bunlari duzeltmek en cok soruyu kurtarir)
$sikYanlis = New-Object System.Collections.Generic.List[object]
foreach($k in ($kodSayaci.Keys | Sort-Object { -$kodSayaci[$_] } | Select-Object -First 20)){
  $par = $k -split '\|'
  $sikYanlis.Add([ordered]@{ kod=$par[0]; yazilan_ad=$par[1]; resmi_ad=$RESMI[$par[0]]; adet=$kodSayaci[$k] })
}

$rapor = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='DENETIM (0 USD, hicbir sey degistirilmedi)'
  kasa=$kasa.Count; resmi_hesap_kodu=$RESMI.Count
  iddia_uyuyor=$uyuyor
  iddia_uymuyor=$uymuyor
  iddia_kod_yok=$kodYok
  birim_atlanan=$birimAtlanan     # "750 TL" gibi tutar sanilan, elenen eslesmeler
  ad_disi_atlanan=$adDisiAtlanan  # THP adlarinin hicbirine benzemeyen ("paragraf") - hesap adi iddiasi degil
  soru_uymuyor=$soruUymuyor.Count
  soru_kod_yok=$soruKodYok.Count
  yanlis_orani_yuzde=$(if(($uyuyor+$uymuyor) -gt 0){ [Math]::Round(100.0*$uymuyor/($uyuyor+$uymuyor),2) } else { 0 })
  en_sik_yanlis=$sikYanlis.ToArray()
  ornekler=$ornek.ToArray()
  not='Yalniz OLCUM. Kasada hicbir sey degistirilmedi. Ad benzerliginde karar verilemeyen durumlar UYUYOR sayilir (suphede suclamiyoruz), yani gercek yanlis sayisi bundan AZ DEGILDIR.'
}
RaporYaz $rapor
Write-Host "`n=== HESAP KODU DENETIMI ==="
Write-Host ("  Resmi kod listesi : {0}" -f $RESMI.Count)
Write-Host ("  Iddia UYUYOR      : {0}" -f $uyuyor)
Write-Host ("  Iddia UYMUYOR     : {0}  <-- YANLIS" -f $uymuyor)
Write-Host ("  THP'de kod YOK    : {0}" -f $kodYok)
Write-Host ("  Etkilenen soru    : {0} (uymayan) + {1} (kod yok)" -f $soruUymuyor.Count, $soruKodYok.Count)
Write-Host ("  Yanlis orani      : %{0}" -f $rapor.yanlis_orani_yuzde)

# yeniden-kosum 03.08 08:2x - ilk temiz olcum push yarisini kaybetti
