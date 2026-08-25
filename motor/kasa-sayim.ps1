# ============================================================================
#  KASA SAYIMI — 28.07.2026
#
#  NEDEN VAR: GM yerelde ANON anahtarla calisiyor; soru_havuzu RLS ile kapali
#  oldugu icin kasada kac soru oldugunu OLCEMIYOR (Content-Range: */0 doner).
#  Butun plan bu sayiya bagli: kasa 2.000 ise bir hikaye, 6.000 ise baska.
#  Cem'e "sen SQL calistir" demek yerine, bugun kurulan SERVICE anahtarli kanal
#  ayni isi yapiyor: bu betik Actions'ta koser, sayar ve sonucu depoya yazar.
#
#  PARA HARCAMAZ: hicbir API cagrisi yok, yalniz Supabase okuma.
#  Cikti: veri/kasa-sayim.json  (+ ekrana ozet)
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
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

$SB_ANAHTAR = $env:SUPABASE_SERVICE_KEY
if(-not $SB_ANAHTAR){ Write-Host "SUPABASE_SERVICE_KEY yok - kasa sayimi atlandi."; exit 0 }
$H = @{ apikey = $SB_ANAHTAR; Authorization = "Bearer $SB_ANAHTAR" }

# KOR KALMA KURALI: Actions loglari bana kapali. Bu kosu uc kez YESIL bitti ve
# uc kez dosya uretmedi; sebebini goremedigim icin uc kez TAHMIN ettim. Bir kanal
# kendi hatasini yazamiyorsa kurulmus sayilmaz - kosu artik kendi logunu depoya
# birakiyor.
try { Start-Transcript -Path (Join-Path $kok 'veri/kasa-log.txt') -Force | Out-Null } catch {}

Write-Host "KASA SAYIMI basliyor... (kuyruk yenileme)"

# --- 1) toplam (count=exact, tek istek)
$toplam = -1
try {
  $r = Invoke-WebRequest -UseBasicParsing -Uri "$SB_URL/rest/v1/soru_havuzu?select=id&limit=1" `
       -Headers ($H + @{ Prefer='count=exact' }) -TimeoutSec 90
  $toplam = [int](($r.Headers['Content-Range'] -split '/')[-1])
} catch { Write-Host ("KRITIK: toplam sayilamadi - {0}" -f $_.Exception.Message); exit 1 }
Write-Host ("  TOPLAM: {0} soru" -f $toplam)

# --- 2) kirilim icin tum kayitlari sayfali cek (yalniz siniflandirma alanlari)
$kayit = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  $s = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id,sinav,ders,konu,kaynak&order=id&offset=$bas&limit=1000" -Headers $H -TimeoutSec 180
  $d = @($s); if($d.Count -eq 0){ break }
  foreach($x in $d){ $kayit.Add($x) }
  if($d.Count -lt 1000){ break }
  $bas += 1000
  Write-Host ("  ...{0}" -f $kayit.Count)
}
Write-Host ("  cekilen: {0}" -f $kayit.Count)

# --- YAPAY ZEKA KOKUSU TARAMASI (29.07, Cem'in uyarisi: "eski sorularda da
# yapay zeka yaptigi belli olmasin"). Uyari yerinde: o sorularin ACIKLAMALARINI
# BIZ yeniledik, yani makine izi varsa BIZIM koydugumuzdur.
# Once OLCUM: kac soruda gercekten iz var? Tahminle duzeltme turu acmak, bu gece
# uc kez yanlis ciktigim seyin aynisi olur.
# NOT: dort parcali iskelet (Ne soruluyor / Kural / Bu olayda / Akilda kalsin)
# BURADA IZ SAYILMAZ - Amerikan hazirlik sirketleri de ayni tutarli iskeleti
# kullanir, bu profesyonellik isaretidir. Iz olan sey DILDIR: placeholder unvan,
# hepsi yuvarlak tutar, sisirme klise, ayni cumlenin tekrari.
$kokuSay = [ordered]@{ bakilan=0; placeholder=0; hepsiYuvarlak=0; klise=0; tekduzeTuzak=0; toplamIzli=0 }
$KLISE = @('önem arz et','unutulmamalıdır','dikkat edilmelidir','bu bağlamda','ilgili mevzuat uyarınca','söz konusudur ki')
function KokuTara($soruMetni, $aciklamaMetni){
  $iz = @()
  $hepsi = "$soruMetni $aciklamaMetni"
  if($soruMetni -match '(?i)\b(ABC|XYZ|ABCD)\s*(ticaret|gıda|tekstil|a\.?ş|ltd|işletme|şirket)' -or
     $soruMetni -match '(?i)\b(X|Y|Z)\s+(A\.?Ş\.?|İşletmesi|Ltd)'){ $iz += 'placeholder' }
  $tutar = @([regex]::Matches("$soruMetni", '(\d{1,3}(?:\.\d{3})+)\s*(?:TL|lira)') | ForEach-Object { $_.Groups[1].Value })
  if($tutar.Count -ge 3 -and (@($tutar | Where-Object { $_ -match '\.000$' }).Count -eq $tutar.Count)){ $iz += 'hepsiYuvarlak' }
  foreach($kl in $KLISE){ if($hepsi -match [regex]::Escape($kl)){ $iz += 'klise'; break } }
  return $iz
}

function Grupla($alanAdi){
  $g = @{}
  foreach($k in $kayit){ $v = "$($k.$alanAdi)"; if($v.Trim().Length -eq 0){ $v = '(bos)' }
    if($g.ContainsKey($v)){ $g[$v]++ } else { $g[$v] = 1 } }
  return $g
}

$sinav = Grupla 'sinav'
$ders  = Grupla 'ders'

# --- 3) sinav x ders capraz
$capraz = @{}
foreach($k in $kayit){
  $a = "$($k.sinav)"; if($a.Trim().Length -eq 0){ $a='(bos)' }
  $b = "$($k.ders)";  if($b.Trim().Length -eq 0){ $b='(bos)' }
  $key = "$a|$b"; if($capraz.ContainsKey($key)){ $capraz[$key]++ } else { $capraz[$key]=1 }
}

# --- 4) KONU BAZLI YOGUNLUK (kota sisteminin girdisi): hangi konuda kac soru var
$konu = @{}
foreach($k in $kayit){
  $key = "$($k.ders)|$($k.konu)"
  if($konu.ContainsKey($key)){ $konu[$key]++ } else { $konu[$key]=1 }
}

# --- 5) KAYNAK TIPI: kac soru bir KANUN MADDESINE dayaniyor (bag kurulabilir mi)
$mevzuatli = 0; $mevzuatsiz = 0
foreach($k in $kayit){
  $c = "$($k.kaynak)"
  if($c -match '(?i)\d{3,4}\s*say[ıi]l[ıi]|\(\d{3,4}\s*s\.K\.\)|\b(VUK|TTK|TBK|GVK|KDVK|KVK|AATUHK|[İI]YUK|TCK|CMK|SMK|[ÖO]TV|Anayasa)\b|\b(TMS|TFRS|BDS)\s*\d|tebli|y[oö]netmelik'){ $mevzuatli++ } else { $mevzuatsiz++ }
}

Write-Host ""
Write-Host "================ KASA SAYIMI ================"
Write-Host ("  TOPLAM SORU : {0}" -f $toplam)
Write-Host ""
Write-Host "  --- sinav bazinda"
$sinav.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { Write-Host ("     {0,-10} {1}" -f $_.Key, $_.Value) }
Write-Host ""
Write-Host "  --- ders bazinda"
$ders.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { Write-Host ("     {0,-34} {1}" -f $_.Key, $_.Value) }
Write-Host ""
Write-Host "  --- kaynak tipi (bag kurulabilirlik)"
Write-Host ("     mevzuata dayanan (madde bagi kurulabilir) : {0}" -f $mevzuatli)
Write-Host ("     mevzuat disi (dil/matematik/teori)        : {0}" -f $mevzuatsiz)
Write-Host ""
Write-Host "  --- EN YOGUN 20 KONU (kota sisteminin girdisi)"
$konu.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 20 | ForEach-Object { Write-Host ("     {0,4}x  {1}" -f $_.Value, $_.Key) }
Write-Host ""
Write-Host ("  --- tekil konu sayisi: {0}" -f $konu.Count)

# --- YAPAY ZEKA KOKUSU: BUTUN KASAYI TARA (sayfali, soru + dogru sik aciklamasi)
Write-Host ""
Write-Host "  --- YAPAY ZEKA KOKUSU TARAMASI (butun kasa)"
$izli = New-Object System.Collections.Generic.List[string]
$bas2 = 0
while($true){
  $u3 = "$SB_URL/rest/v1/soru_havuzu?select=id,soru,dogru,aciklama&order=id&offset=$bas2&limit=500"
  try { $h3 = Invoke-WebRequest -UseBasicParsing -Uri $u3 -Headers $H -TimeoutSec 180 } catch { break }
  $g3 = if($h3.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($h3.Content) } else { "$($h3.Content)" }
  $d3 = @(); foreach($x in (ConvertFrom-Json $g3)){ $d3 += $x }
  if($d3.Count -eq 0){ break }
  foreach($q in $d3){
    $kokuSay.bakilan++
    $ac = "$($q.aciklama.($q.dogru))"
    $iz = KokuTara "$($q.soru)" $ac
    if($iz -contains 'placeholder'){ $kokuSay.placeholder++ }
    if($iz -contains 'hepsiYuvarlak'){ $kokuSay.hepsiYuvarlak++ }
    if($iz -contains 'klise'){ $kokuSay.klise++ }
    if($iz.Count){ $kokuSay.toplamIzli++; $izli.Add("$($q.id)") }
  }
  if($d3.Count -lt 500){ break }
  $bas2 += 500
}
foreach($k in $kokuSay.Keys){ Write-Host ("     {0,-16} {1}" -f $k, $kokuSay[$k]) }
if($kokuSay.bakilan -gt 0){ Write-Host ("     IZLI ORAN      : %{0:N1}" -f (100.0*$kokuSay.toplamIzli/$kokuSay.bakilan)) }
try {
  $ij = ConvertTo-Json -InputObject ([object[]]$izli) -Depth 3; if([string]::IsNullOrWhiteSpace($ij)){ $ij='[]' }
  [IO.File]::WriteAllText((Join-Path $kok "veri/koku-izli.json"), $ij, (New-Object Text.UTF8Encoding($false)))
  Write-Host ("-> veri/koku-izli.json  ({0} kimlik, uslup turu icin)" -f $izli.Count)
} catch { Write-Host ("koku listesi yazilamadi: {0}" -f $_.Exception.Message) }

# --- ORNEK DOKUMU: GM yerelde ANON anahtarla kasayi OKUYAMIYOR. Aciklamalari
# yeniledik ama GM ciktinin metnini goremedi - "elle okuyacagim" sozu boslukta
# kaldi. Rapor rakami verir, METNI vermez. Bu blok birkac sorunun yeni
# aciklamasini depoya dokuyor ki GM gercekten OKUSUN.
try {
  # 30.07 PS TUZAGI: @(IRM) diziyi tek nesne sarar. Once ata, sonra sar.
  $oHam = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id,ders,konu,soru,siklar,dogru,aciklama,hap,yevmiye,tablo&ders=eq.Finansal%20Muhasebe&order=id&limit=4" -Headers $H -TimeoutSec 90
  $o = @($oHam)
  [IO.File]::WriteAllText((Join-Path $kok "veri/kasa-ornek.json"), (@($o) | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("-> veri/kasa-ornek.json  ({0} ornek soru, tam metin)" -f @($o).Count)
} catch { Write-Host ("ornek dokumu alinamadi: {0}" -f $_.Exception.Message) }

# --- YENI URETIM DOKUMU: uretilen sorularin HEPSI yayin=false. Bu, GM okumadan
# ogrenciye gitmesinler diye konmus bir kilit - ama ayni kilit GM'nin de onlari
# ANON anahtarla gormesini engelliyor. Kilidin, denetimi imkansiz kilmasi olmaz:
# denetlenemeyen bir parti, denetimden gecmis sayilamaz.
# Ders BASINA 3 soru dokuluyor: tek dersten 20 ornek, sekiz kapinin yedisini
# hic gormeden "parti iyi" dedirtir.
# Ders adlarini TAHMIN ETMIYORUZ. Ilk deneme sekiz ders adini elle yazmisti;
# hicbiri tutmadi, sorgular bos dondu, dosya hic yazilmadi ve is akisi YINE
# YESIL BITTI. Bu yuzden artik once ham cekilir, gruplama PowerShell'de yapilir:
# kasada ders adi ne yaziyorsa o kullanilir.
try {
  # IKI ADIM: once HAFIF sorgu (yalniz id+ders). Tek hamlede 400 sorunun tam
  # metnini cekmek, sorgunun kendisi mi yoksa filtre mi bos dondu ayirt
  # ettirmiyordu - agir sorgu duserse "hic soru yok" gibi gorunuyor.
  # id alani GUID - SIRALI SAYI DEGIL. "order=id.desc + limit" bu yuzden "en yeni
  # 400"u degil RASTGELE 400'u getiriyordu ve icinden 1 tane yayin=false cikinca
  # neredeyse "163 denetlenmemis soru yayinda" alarmi verecektim. Ornekleme,
  # SAYIM degildir: once count=exact ile GERCEK sayi olculur.
  $ky = -1
  try {
    $rk = Invoke-WebRequest -UseBasicParsing -Uri "$SB_URL/rest/v1/soru_havuzu?select=id&yayin=is.false&limit=1" -Headers ($H + @{ Prefer='count=exact' }) -TimeoutSec 90
    $ky = [int](($rk.Headers['Content-Range'] -split '/')[-1])
  } catch { Write-Host ("     yayin=false sayimi alinamadi: {0}" -f $_.Exception.Message) }
  Write-Host ("     KASADA yayin=false (denetim bekleyen) : {0}" -f $ky)
  # AYNI SUZGEC, IKI FARKLI SONUC: sayim 194 dedi, cekim 1 satir getirdi. Bu
  # ikisinden biri yalan soyluyor ve hangisi oldugunu TAHMIN etmeyecegim - ham
  # cevabin kendisi loga yaziliyor.
  # SUNUCU TARAFI KIRPMA: Supabase istek basina EN FAZLA 1000 satir donuyor.
  # "limit=6000" yazmak ise yaramadi; sessizce 1000'de kesti. Sayim 4.107 derken
  # cekim tam 1000 getirdi - TAM YUVARLAK SAYI HEP KIRPMA ISARETIDIR.
  # O haliyle biraksaydim 3.107 soru kuyruga hic girmeyecek, hakem onlari hic
  # gormeyecek, ben de "hepsi yargilandi" sanacaktim.
  $hafif = New-Object System.Collections.Generic.List[object]
  $ofs = 0
  while($true){
    $u = "$SB_URL/rest/v1/soru_havuzu?select=id,ders&yayin=is.false&order=id&offset=$ofs&limit=1000"
    $ham = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $H -TimeoutSec 120
    $govde = if($ham.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($ham.Content) } else { "$($ham.Content)" }
    $dilim = @(); foreach($x in (ConvertFrom-Json $govde)){ $dilim += $x }
    if($dilim.Count -eq 0){ break }
    foreach($x in $dilim){ $hafif.Add($x) }
    Write-Host ("     ...cekilen {0}" -f $hafif.Count)
    if($dilim.Count -lt 1000){ break }
    $ofs += 1000
    if($ofs -gt 20000){ Write-Host "     GUVENLIK DURDURMASI: 20.000 asildi"; break }
  }
  Write-Host ("     cekilen yayin=false kayit: {0}" -f $hafif.Count)
  if($ky -gt 0 -and $hafif.Count -lt $ky){
    Write-Host ("     UYARI: sayim {0} diyor, cekim {1} getirdi - EKSIK." -f $ky, $hafif.Count)
  }
  # 29.07 - GM ORNEGI KUCULTULDU: ders basina 8 -> 1, tavan 10 soru.
  # Cem: "duvar kur kimse goremesin, baska acik varsa o kapansin".
  # Tarama: bu dokum 120, pilot dokumu 40 soruyu TAM METINLE public depoya
  # yaziyordu; veri/fabrika ile birlikte 745 parali soru disaridaydi.
  # Ama dokumu tamamen kapatmak da yanlis olurdu: bu gece iki gercek kusur
  # (TMS 40 -> VUK m.275 yanlis kaynagi ve THP 723'te cevap-aciklama celiskisi)
  # ancak SORULAR OKUNARAK bulundu; rapor ikisini de temiz gostermisti.
  # Denge: kalite denetimi icin ON soru yeter, 120 gerekmez.
  $ORNEK_TAVAN = 10
  $say=@{}; $sec = New-Object System.Collections.Generic.List[string]
  foreach($s in $hafif){
    if($sec.Count -ge $ORNEK_TAVAN){ break }
    $d = "$($s.ders)"; if(-not $say.ContainsKey($d)){ $say[$d]=0 }
    if($say[$d] -ge 1){ continue }
    $say[$d]++; $sec.Add("$($s.id)")
  }
  foreach($k in ($say.Keys|Sort-Object)){ Write-Host ("       {0,-34} {1}" -f $k, $say[$k]) }
  # Invoke-RestMethod BURADA GUVENILIR DEGIL: 194 kayitlik diziyi tek parca
  # dondurdu, @() da onu 1 eleman saydi. "cekilen: 1" yazdiran buydu - veri
  # eksik degildi, OKUMA bicimi bozuktu. Ham cek, kendin cozumle.
  # DENETIM KUYRUGU: profesor -idler ile hedefli kosabiliyor. yayin=false olan
  # her sorunun kimligi buraya yazilir; hakem butun kasayi bastan yargilamak
  # yerine yalniz denetim bekleyenlere bakar. Ayni isi ikinci kez odememek icin.
  try {
    $kuyruk = @($hafif | ForEach-Object { "$($_.id)" })
    $kj = ConvertTo-Json -InputObject $kuyruk -Depth 3
    if([string]::IsNullOrWhiteSpace($kj)){ $kj = '[]' }
    [IO.File]::WriteAllText((Join-Path $kok "veri/denetim-kuyrugu.json"), $kj, (New-Object Text.UTF8Encoding($false)))
    Write-Host ("-> veri/denetim-kuyrugu.json  ({0} kimlik, profesor -idler icin)" -f $kuyruk.Count)
  } catch { Write-Host ("kuyruk yazilamadi: {0}" -f $_.Exception.Message) }

  $y = @()
  if($sec.Count){
    $liste = (($sec | ForEach-Object { '"' + $_ + '"' }) -join ',')
    $u2 = "$SB_URL/rest/v1/soru_havuzu?select=id,ders,konu,soru,siklar,dogru,aciklama,hap,kaynak,yevmiye,tablo&id=in.($liste)"
    $h2 = Invoke-WebRequest -UseBasicParsing -Uri $u2 -Headers $H -TimeoutSec 120
    $g2 = if($h2.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($h2.Content) } else { "$($h2.Content)" }
    $y = @($g2 | ConvertFrom-Json)
    Write-Host ("     tam metin cekilen: {0} (istenen {1})" -f $y.Count, $sec.Count)
  }
  # ConvertTo-Json'a BORU ile bos dizi vermek $null dondurur, WriteAllText de
  # $null'da patlar - ilk denemeyi sessizce dusuren ikinci kusur buydu.
  $js = ConvertTo-Json -InputObject ([object[]]$y) -Depth 8
  if([string]::IsNullOrWhiteSpace($js)){ $js = '[]' }
  [IO.File]::WriteAllText((Join-Path $kok "veri/yeni-uretim-ornek.json"), $js, (New-Object Text.UTF8Encoding($false)))
  Write-Host ("-> veri/yeni-uretim-ornek.json  ({0} yeni soru, GM okumasi icin)" -f @($y).Count)
} catch { Write-Host ("yeni uretim dokumu alinamadi: {0}" -f $_.Exception.Message) }

# --- PILOT OKUMASI: yeni bir hattin ILK partisi hedefli okunur.
# Ders basina 3 soruluk genel dokum, "SGS pilotu SGS SEVIYESINDE mi yoksa
# Yeterlilik agirliginda mi" sorusunu cevaplamaz - o soru icin AYNI dersin
# AYNI kosudan cikan sorulari yan yana gormek gerekir. Suzgec ENV ile verilir,
# boylece bir sonraki yeni hat (Matematik) icin betik degistirmeye gerek kalmaz.
# UCRETSIZ: yalniz Supabase okumasi.
$PILOT_SINAV = "$env:PILOT_SINAV"
$PILOT_DERS  = "$env:PILOT_DERS"
if($PILOT_SINAV -or $PILOT_DERS){
  try {
    $suz = @("yayin=is.false")
    if($PILOT_SINAV){ $suz += "sinav=eq.$([uri]::EscapeDataString($PILOT_SINAV))" }
    if($PILOT_DERS){  $suz += "ders=eq.$([uri]::EscapeDataString($PILOT_DERS))" }
    $up = "$SB_URL/rest/v1/soru_havuzu?select=id,sinav,ders,konu,soru,siklar,dogru,aciklama,hap,kaynak,kanun_no,madde_no,uretim,yevmiye,tablo&" +
          ($suz -join '&') + "&order=uretim.desc&limit=10"   # 29.07: 40 -> 10, bkz. asagidaki not
    $hp = Invoke-WebRequest -UseBasicParsing -Uri $up -Headers $H -TimeoutSec 120
    $gp = if($hp.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($hp.Content) } else { "$($hp.Content)" }
    $py = @($gp | ConvertFrom-Json)
    $pj = ConvertTo-Json -InputObject ([object[]]$py) -Depth 8
    if([string]::IsNullOrWhiteSpace($pj)){ $pj = '[]' }
    [IO.File]::WriteAllText((Join-Path $kok "veri/pilot-ornek.json"), $pj, (New-Object Text.UTF8Encoding($false)))
    Write-Host ("-> veri/pilot-ornek.json  ({0} soru; suzgec sinav='{1}' ders='{2}')" -f @($py).Count, $PILOT_SINAV, $PILOT_DERS)
    if(@($py).Count -eq 0){ Write-Host "   UYARI: suzgec bos dondu - sinav/ders etiketi bekledigin gibi yazilmamis olabilir." }

    # --- KAYNAK TURU SAYIMI (40'lik ornek DEGIL, TAM SAYIM)
    # 29.07 dersi: 40 soruluk ornekten "onarim tuttu mu" sonucu cikarmaya
    # calistim ve cikaramadim - ornek Pilot-1 ile Pilot-2'yi KARISTIRIYORDU
    # (ikisinin uretim damgasi ayniydi). Orneklem sayim degildir; bu blok
    # count=exact ile TAM sayar.
    # Olcunun anlami: Pilot-1 SIFIR standart/hesap-plani uretmisti (40/40 kanun),
    # eski toplu aktarimda da yok. Yani bu sayilar dogrudan onarimin urunudur.
    function TurSay([string]$ek){
      try {
        $u = "$SB_URL/rest/v1/soru_havuzu?select=id&" + ($suz -join '&') + "&" + $ek + "&limit=1"
        $h = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers ($H + @{ Prefer='count=exact' }) -TimeoutSec 90
        return [int](($h.Headers['Content-Range'] -split '/')[-1])
      } catch { return -1 }
    }
    # --- PILOT KUYRUGU: hakem bu kimliklere hedefli koser (-idler).
    # Genel denetim kuyrugu 4.400+ kimlik ve buyuk cogunlugu Yeterlilik; oradan
    # 'sinir' ile ornek cekmek pilot sorularinin hakemden gecip gecmedigini
    # OLCMEZ. Karar verilecek soru bu iki pilot oldugu icin kuyrugu ayiriyorum.
    try {
      $pk = New-Object System.Collections.Generic.List[string]
      $ofsP = 0
      while($true){
        $uk = "$SB_URL/rest/v1/soru_havuzu?select=id&" + ($suz -join '&') + "&order=id&offset=$ofsP&limit=1000"
        $hk = Invoke-WebRequest -UseBasicParsing -Uri $uk -Headers $H -TimeoutSec 120
        $gkk = if($hk.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($hk.Content) } else { "$($hk.Content)" }
        $dk = @($gkk | ConvertFrom-Json)
        foreach($r in $dk){ $pk.Add("$($r.id)") }
        if($dk.Count -lt 1000){ break }
        $ofsP += 1000
      }
      $pj = ConvertTo-Json -InputObject ([object[]]$pk) -Depth 3
      if([string]::IsNullOrWhiteSpace($pj)){ $pj = '[]' }
      [IO.File]::WriteAllText((Join-Path $kok "veri/pilot-kuyrugu.json"), $pj, (New-Object Text.UTF8Encoding($false)))
      Write-Host ("-> veri/pilot-kuyrugu.json  ({0} kimlik, hakem -idler icin)" -f $pk.Count)
    } catch { Write-Host ("pilot kuyrugu yazilamadi: {0}" -f $_.Exception.Message) }

    $nStd = TurSay "kanun_no=eq.STD"
    $nThp = TurSay "kanun_no=eq.THP"
    $nTop = TurSay "id=not.is.null"
    Write-Host ("   KAYNAK TURU TAM SAYIM (sinav='{0}' ders='{1}', yayin=false):" -f $PILOT_SINAV, $PILOT_DERS)
    Write-Host ("     standart (STD)    : {0}" -f $nStd)
    Write-Host ("     hesap plani (THP) : {0}" -f $nThp)
    Write-Host ("     toplam            : {0}" -f $nTop)
    if($nTop -gt 0 -and $nStd -ge 0 -and $nThp -ge 0){
      Write-Host ("     standart+THP orani: %{0:N1}" -f (100.0*($nStd+$nThp)/$nTop))
    }
  } catch { Write-Host ("pilot dokumu alinamadi: {0}" -f $_.Exception.Message) }
}

$rapor = [ordered]@{
  tarih = (Get-Date -Format "dd.MM.yyyy HH:mm")
  toplam = $toplam
  cekilen = $kayit.Count
  sinav = $sinav
  ders = $ders
  sinav_ders = $capraz
  kaynak_tipi = [ordered]@{ mevzuata_dayanan = $mevzuatli; mevzuat_disi = $mevzuatsiz }
  tekil_konu = $konu.Count
  konu_yogunluk = $konu
}
$yol = Join-Path $kok "veri/kasa-sayim.json"
[IO.File]::WriteAllText($yol, ($rapor | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host "-> veri/kasa-sayim.json"

# --- VITRIN SAYILARI (30.07): ana sayfa kanit bandinin CANLI kaynagi.
# Kural (Cem, otomatik guncelleme VARSAYILAN): vitrindeki hicbir rakam elle
# yasamaz. soru_uretilen buradaki sayimdan, hakem_denetimi hakem-hasadi.json
# karar sayisindan; gtip onceki dosyadan tasinir (ayri hatta elle teyitli).
#
# 21.08 DUZELTME: "arac" da onceki dosyadan tasiniyordu, yani ELLE yasiyordu
# ve kurala aykiriydi. Vitrin 25 diyordu, izgarada 26 calisan arac vardi -
# bir eksik. Artik SAYILIYOR. Sayim kurali:
#   izgaradaki kart + hedef dosya VAR + icinde hem girdi (input/select/
#   textarea) hem de buton/onclick olan sayfa = ARAC.
#   Girdisi olmayan rehber/icerik sayfasi ARAC SAYILMAZ (KDV Iade Rehberi,
#   Bilgi Havuzu, Donem Plani, Son Gun, Esik Rehberi, Kurulus Evrak Cantasi,
#   Genc Musavir, Bugun RG, Gunun Kartlari - 21.08'de 9 tane).
#   Olcum 21.08: 35 kart -> 26 arac + 9 rehber.
# Sayim sifir donerse (index.html okunamadi/izgara degisti) eski deger
# korunur - vitrin bos rakam gostermez.
try {
  $vYol = Join-Path $kok "veri/vitrin-sayilar.json"
  $eski = if(Test-Path $vYol){ Get-Content $vYol -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }

  $aracSayim = 0
  try {
    $ixIcerik = Get-Content (Join-Path $kok "index.html") -Raw -Encoding UTF8
    $aracHedef = [regex]::Matches($ixIcerik, '<a class="arac[^"]*" href="([^"#]+)') |
                 ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
    foreach($hedef in $aracHedef){
      $sayfaYol = Join-Path $kok $hedef
      if(-not (Test-Path $sayfaYol)){ continue }
      $sayfa = Get-Content $sayfaYol -Raw -Encoding UTF8
      $girdiSay = [regex]::Matches($sayfa, '<(input|select|textarea)\b').Count
      $butonSay = [regex]::Matches($sayfa, '<button\b|onclick=').Count
      if($girdiSay -ge 1 -and $butonSay -ge 1){ $aracSayim++ }
    }
    Write-Host ("-> arac sayimi: {0} kart tarandi, {1} calisan arac" -f $aracHedef.Count, $aracSayim)
  } catch { Write-Host ("arac sayilamadi, eski deger korunuyor: {0}" -f $_.Exception.Message); $aracSayim = 0 }
  $hakemSay = if($eski){ $eski.hakem_denetimi } else { 0 }
  $hhYol = Join-Path $kok "veri/hakem-hasadi.json"
  if(Test-Path $hhYol){
    try { $hh = Get-Content $hhYol -Raw -Encoding UTF8 | ConvertFrom-Json
          $hSay = [int]$hh.tekil_yargi
          if($hSay -gt 0){ $hakemSay = $hSay } } catch {}
  }
  $vitrin = [ordered]@{
    _not = "Vitrin kanit bandinin CANLI sayilari. kasa-sayim.ps1 her kosuda gunceller - ELLE DUZENLEME buraya degil, kaynaklara yapilir."
    tarih = (Get-Date -Format "dd.MM.yyyy")
    soru_uretilen = $toplam
    hakem_denetimi = $hakemSay
    # 25.08 DUZELTME: bu satir hicbir sey SAYMIYORDU - onceki degeri tasiyor,
    # yoksa elle yazilmis 13400 koyuyordu. Vitrindeki "canli sayac" bu kalem
    # icin donmus bir sabitti; sitede "her gun kendiliginden guncellenir"
    # yazarken GTIP rakami sabit duruyordu. Olculdu: gercek 15.717.
    # Artik gercekten SAYIYOR; okunamazsa eskiye duser, UYDURMAZ.
    gtip_kayit = $(
      $gYol = Join-Path $kok "veri\gtip-tanim.json"
      $gSay = 0
      if(Test-Path $gYol){
        try{
          $gObj = (Get-Content $gYol -Raw -Encoding UTF8) | ConvertFrom-Json
          $gSay = @($gObj.PSObject.Properties).Count
        } catch { $gSay = 0 }
      }
      if($gSay -gt 0){ $gSay } elseif($eski -and $eski.gtip_kayit){ $eski.gtip_kayit } else { 0 }
    )
    arac = if($aracSayim -gt 0){ $aracSayim } elseif($eski -and $eski.arac){ $eski.arac } else { 26 }
  }
  [IO.File]::WriteAllText($vYol, ($vitrin | ConvertTo-Json -Depth 3), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("-> veri/vitrin-sayilar.json  (soru {0}, hakem {1}, arac {2})" -f $toplam, $hakemSay, $vitrin.arac)
} catch { Write-Host ("vitrin sayilari yazilamadi: {0}" -f $_.Exception.Message) }

if($toplam -ne $kayit.Count){
  Write-Host ("UYARI: sayfali cekimde {0} kayit geldi ama toplam {1}. Fark incelenmeli." -f $kayit.Count, $toplam)
}
exit 0

try{Stop-Transcript|Out-Null}catch{}

# 29.07 aksam: pilot-2 okumasi icin tetik (PILOT_SINAV/PILOT_DERS is akisinda ayarli).
