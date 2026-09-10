# ============================================================================
#  VUK SINAV PROVASI — RAG hattinin ucu uca ilk gercek karnesi
#
#  NE YAPAR: bes VUK konusu icin (1) dayanagi ambardan ARAR, (2) YALNIZ o
#  dayanakla modele soru yazdirir, (3) kapilardan gecirir, (4) Cem'in
#  okuyabilecegi TEMIZ METIN olarak yazar.
#
#  NEDEN BU BETIK, NEDEN DOGRUDAN C# WORKER DEGIL:
#  C# motoru derli ve sema basili, ama canli kosmasi icin bu makinede olmayan
#  IKI kimlik gerekiyor:
#     · GEMINI_API_KEY        (gomme ucu - vektor kanali)
#     · Postgres sifresi      (Npgsql dogrudan baglanti; elimizde PostgREST
#                              anahtari var, veritabani sifresi yok)
#  Bu betik o iki kimligi GEREKTIRMEDEN ayni hatti kosar: istem blogu, JSON
#  semasi ve kapilar SoruUretici.cs ile BIREBIR AYNIDIR. Fark tek: dayanak
#  eski ambardan (madde_ara) gelir, yeni rag semasindan degil.
#  Kimlikler gelince tek fark kalkar.
#
#  PARA: tek parali adim model cagrisidir. Bes konu x ~3 soru, sonnet-5 liste
#  fiyatiyla ~0,10 USD. Fatura GERCEK jetonlardan hesaplanir ve rapora yazilir.
#
#  CIKTI: veri/vuk-sinav-provasi.txt  (okunur metin)  +  .json (ham)
#  KOSMA: powershell -NoProfile -File arac/vuk-sinav-provasi.ps1
# ============================================================================
param(
  [string]$Model = 'claude-sonnet-5',
  [int]$Adet = 3,
  [int]$FrenMs = 1500,
  # Yalniz belirtilen konular kosulur (kismi tekrar icin - butun turu yeniden
  # kosmak parayi ikinci kez odemek olurdu). Bos ise hepsi kosar.
  [string[]]$Konu = @(),
  # Kismi kosuda onceki sonuclarin uzerine EKLENIR, ezilmez.
  [switch]$Ekle
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$kok = Split-Path -Parent $PSScriptRoot
$SB  = 'https://bjrleanjpyujtajmazxn.supabase.co'
$SKEY= if($env:SB_PUBLISHABLE){ $env:SB_PUBLISHABLE } else { 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' }
$SH  = @{ apikey=$SKEY; Authorization="Bearer $SKEY" }
$AKEY= $env:ANTHROPIC_API_KEY
if(-not $AKEY){ Write-Host 'KOR: ANTHROPIC_API_KEY yok (0 USD harcandi).'; exit 3 }
$AH  = @{ 'x-api-key'=$AKEY; 'anthropic-version'='2023-06-01' }

# --- bes konu: SMMM sinav mufredatindan, VUK'un farkli bolumlerinden --------
# 'ek' alani: KANUNUN kendi dilindeki karsilik. Sinav mufredatinin dili ile
# kanun metninin dili ayrisiyor ("amortisman ayirma sartlari" <-> "amortisman
# mevzuu"); arama ancak ikincisiyle tutuyor.
# 'madde' alani = KONU KARTI. Arama bu maddeyi getirmezse dogrudan cekilir.
# NEDEN HEPSINDE VAR (olculdu 10.09): madde_ara KARARSIZ. Ayni sorgu
# ('VUK degerleme olculeri') bir kosuda m.261'i, sonraki kosuda m.49'u
# (Uygulama suresi) getirdi. Kararsiz arama uzerine soru fabrikasi kurulmaz.
# Hafizadaki tasarim da bunu soyluyor: "soru konu kartindan turer".
$KONULAR = @(
  @{ ders='Vergi Mevzuatı ve Uygulaması'; konu='degerleme olculeri ve maliyet bedeli'; zorluk='zor'   ; ek=@('degerleme olculeri','maliyet bedeli'); madde='VUK (213 s.K.) m.261%' }
  @{ ders='Vergi Mevzuatı ve Uygulaması'; konu='amortisman ayirma sartlari';           zorluk='zor'   ; ek=@('amortisman mevzuu','amortisman nispetleri'); madde='VUK (213 s.K.) m.313%' }
  @{ ders='Vergi Mevzuatı ve Uygulaması'; konu='supheli alacak karsiligi';             zorluk='zor'   ; ek=@('supheli alacaklar'); madde='VUK (213 s.K.) m.323%' }
  # 'vergi ziyai cezasi' ilk turda m.370'i (Izaha davet) getirdi - ILGILI ama
  # YANLIS madde. Dogrusu m.341 (vergi ziyai tanimi) ve m.344 (cezasi).
  # Kanunun kendi basliklariyla arattiriyoruz.
  @{ ders='Vergi Mevzuatı ve Uygulaması'; konu='vergi ziyai cezasi';                   zorluk='kolay' ; ek=@('vergi ziyai tanimi','ziyaa ugratilan vergi','vergi ziyai cezasi kesilir'); madde='VUK (213 s.K.) m.344%' }
  @{ ders='Vergi Mevzuatı ve Uygulaması'; konu='fatura duzenleme suresi';              zorluk='kolay' ; ek=@('faturanin nizami','fatura nizami','faturanin sekli'); madde='VUK (213 s.K.) m.231%' }
)

$script:son=[datetime]::MinValue
function Fren { $g=([datetime]::UtcNow-$script:son).TotalMilliseconds; if($g -lt $FrenMs){ Start-Sleep -Milliseconds ([int]($FrenMs-$g)) }; $script:son=[datetime]::UtcNow }
function Cagir([scriptblock]$is,[int]$deneme=4){
  $son=''
  foreach($d in 1..$deneme){
    Fren
    try{ return (& $is) }
    catch{
      $son=$_.Exception.Message
      if($d -eq $deneme){ throw "$deneme denemede de dustu: $son" }
      Write-Host ("    ... deneme {0}/{1} dustu ({2}), bekleniyor" -f $d,$deneme,$son) -ForegroundColor DarkYellow
      Start-Sleep -Seconds (3*$d)
    }
  }
}

# --- 1) DAYANAK ARA --------------------------------------------------------
# madde_ara genis arar; biz VUK'a daraltiyoruz cunku sinav konusu VUK'tan.
# (Yeni motorda bu is rag.ara'nin p_kaynak_tur suzgecine denk gelir.)
function TekSorgu([string]$sorgu,[int]$adet){
  # adet 12: madde_ara 57014 statement timeout'una aralikli takiliyor (bugun
  # olculdu: 'amortisman' 3.368 ms, 3 sn'lik sinirin dibinde) ve genis adet o
  # riski buyutur. Sunucu hatasi bir CEVAP DEGILDIR - "dayanak yok" sayilmaz.
  $b = @{ sorgu=$sorgu; adet=$adet } | ConvertTo-Json -Compress
  $r = Cagir { Invoke-WebRequest -Method Post -Uri "$SB/rest/v1/rpc/madde_ara" -Headers $SH -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($b)) -UseBasicParsing -UserAgent 'mevzuat-radar-robot/1.0' -TimeoutSec 180 } 8
  return @([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json | ForEach-Object { $_ })
}

# SORGU GENISLETME (query expansion).
# Ilk provada 5 konunun 2'si "kaynaksiz" dondu: 'amortisman ayirma sartlari'
# ve 'vergi ziyai cezasi'. Sebep konunun ambarda olmamasi DEGIL - VUK m.313
# ("Amortisman mevzuu") ve m.341 ambarda duruyor. Sorgu dili ile KANUNUN dili
# ayrisiyor: sinav mufredati "amortisman ayirma sartlari" der, kanun
# "amortisman mevzuu" der.
# Cozum: ayni konu icin birden fazla sorgu bicimi denenir, ilk VUK isabeti
# alinir. Bu, konu kartlarinin yerini tutan ucuz bir vekildir; kalici cozum
# konu -> kanun dili eslesmesini veriye yazmaktir.
function DayanakBul([string]$ders,[string]$konu,[string[]]$ekSorgular){
  # SIRA ONEMLI (olculdu): once KANUNUN KENDI DILI, sonra mufredat dili.
  # Ilk surumde genel sorgu basta duruyordu ve 'vergi ziyai cezasi' icin
  # m.370'i (Izaha davet) getiriyordu - m.370 de bir VUK maddesi oldugu icin
  # fonksiyon ORADA DURUYOR, kanun-dili sorgularina hic sira gelmiyordu.
  # "Ilk VUK isabeti" yeterli olcut degil; once EN OZGUL sorgu denenir.
  $adaylar = @()
  if($ekSorgular){ foreach($e in $ekSorgular){ $adaylar += "VUK $e" } }
  $adaylar += @("$ders $konu", "VUK $konu")

  foreach($s in $adaylar){
    $j = TekSorgu $s 12
    $vukKanun = @($j | Where-Object { "$($_.kaynak_ad)" -match '^VUK \(213' })
    if($vukKanun.Count -gt 0){ Write-Host ("    sorgu tuttu: '{0}'" -f $s) -ForegroundColor DarkGray; return $vukKanun[0] }
  }
  # Kanun maddesi hic bulunamadiysa VUK genel tebligi kabul edilir (son care).
  foreach($s in $adaylar){
    $j = TekSorgu $s 12
    $vukHer = @($j | Where-Object { "$($_.kaynak_ad)" -match '^VUK' })
    if($vukHer.Count -gt 0){ return $vukHer[0] }
  }
  return $null
}

# KONU KARTI YEDEGI — arama tutmadiginda dogrudan madde adiyla ceker.
#
# NEDEN VAR (olculdu 10.09): 'vergi ziyai cezasi' konusunda madde_ara
# israrla m.370'i (Izaha davet) donduruyor. Oysa DOGRU maddeler ambarda
# DURUYOR: "VUK (213 s.K.) m.341 - Vergi ziyai" (639 krk) ve m.344 (1.244 krk).
# Yani kaynak eksik degil, ARAMA BULAMIYOR - sabah olculen %29,4'luk kusurun
# tek madde uzerindeki suçustu hali.
#
# Bu yedek, hafizadaki "konu karti katmani" tasariminin en yalin halidir:
# konu -> madde eslesmesi VERIYE yazilir, aramanin insafina birakilmaz.
# Kalici cozum de budur; burada tek konu icin elle verilmis durumda.
function MaddeGetirDogrudan([string]$adDeseni){
  $u = "/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike." + [uri]::EscapeDataString($adDeseni) + "&limit=1"
  $r = Cagir { Invoke-WebRequest -Uri ($SB+$u) -Headers $SH -UseBasicParsing -UserAgent 'mevzuat-radar-robot/1.0' -TimeoutSec 120 } 5
  $j = @([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json | ForEach-Object { $_ })
  if($j.Count -eq 0){ return $null }
  return $j[0]
}

# --- 2) ISTEM: SoruUretici.cs'teki KuralBlogu ile BIREBIR AYNI -------------
$KURAL = @"
Sen Turkiye'deki mali musavirlik sinavlari icin coktan secmeli soru yazan
bir editorsun. Sana bir DERS, bir KONU ve bir DAYANAK METIN verilir.

DEGISMEZ KURALLAR:
1. Soru YALNIZCA dayanak metne dayanir. Metinde YAZMAYAN hicbir rakam,
   oran, sure ya da esik kullanma - ne soruda ne aciklamada. Emin
   degilsen sayi verme.
2. Hafizandan yazma. Bildigini sandigin bir hukum metinde yoksa YOKTUR.
3. Bes sik: A, B, C, D, E. Yalniz biri dogru, digerleri savunulabilir
   bicimde yanlis olmali - sacma celdirici yazma.
4. Dogru sikkin metnini soru kokunde TEKRARLAMA (cevap sizintisi).
5. Her sik icin aciklama yaz: dogru olan neden dogru, yanlis olanlar
   neden yanlis. Aciklama da yalniz dayanak metne dayanir.
6. 'dayanak' alanina hangi hukme dayandigini tek cumleyle yaz.
7. Yapay zeka kokusu YASAK: "Bu baglamda", "onemlidir ki", "sonuc olarak"
   gibi dolgu kaliplar kullanma. Gercek bir sinav sorusu gibi yaz.
8. Konu dayanak metinde YOKSA soru uretme - bos liste dondur.
9. MEVZUAT TARIHCESI SORULMAZ. Madde metnindeki degisiklik dipnotlari
   - "(Ek: 30/12/1980-2365/46 md.)", "(Degisik: ...)", "(Muk: ...)" -
   kaynak kunyesidir, HUKUM DEGILDIR. "Bu bent hangi kanunla eklendi",
   "en son hangi degisiklik yapildi" gibi sorular YASAKTIR. Sinav
   adayinin bilmesi gereken sey hukmun KENDISIDIR, ne zaman
   degistirildigi degil.
10. SIRALAMA / EZBER SORULMAZ. Bir hukmun kanun metninde KACINCI sirada,
   kacinci bentte, kacinci fikrada durdugu SORULMAZ: "rayic bedel kacinci
   olcudur", "hangi bentte duzenlenmistir", "kac numarali fikradadir"
   YASAKTIR. Bunlar dizgi bilgisidir, hukuk bilgisi degil; gercek sinavda
   sorulmaz. Bunun yerine hukmun UYGULANISINI, SARTLARINI, ISTISNALARINI
   ya da SURELERINI sor.
"@

$sikSema = @{ type='object'; additionalProperties=$false; required=@('A','B','C','D','E')
  properties=@{ A=@{type='string'}; B=@{type='string'}; C=@{type='string'}; D=@{type='string'}; E=@{type='string'} } }
$SEMA = @{
  type='object'; additionalProperties=$false; required=@('sorular')
  properties=@{ sorular=@{ type='array'; items=@{
    type='object'; additionalProperties=$false
    required=@('soru','siklar','dogru','aciklama','dayanak')
    properties=@{ soru=@{type='string'}; siklar=$sikSema
      dogru=@{ type='string'; enum=@('A','B','C','D','E') }
      aciklama=$sikSema; dayanak=@{type='string'} } } } }
}

$script:gG=0; $script:gC=0
function ModeliCagir($istek,$dayanak){
  $kirp=$false; $metin="$($dayanak.metin)"
  if($metin.Length -gt 6000){ $metin=$metin.Substring(0,6000); $kirp=$true }
  $kullanici = @"
DERS   : $($istek.ders)
KONU   : $($istek.konu)
ZORLUK : $($istek.zorluk)
ADET   : $Adet

=== DAYANAK METIN ($($dayanak.kaynak_ad)) ===
$metin
=== METIN BITTI ===
$(if($kirp){ "NOT: metin uzun oldugu icin ilk 6.000 karakteri gosterildi. GORMEDIGIN kisma dayali soru YAZMA." })
"@
  $govde = @{
    model=$Model; max_tokens=8000
    system=@(@{ type='text'; text=$KURAL; cache_control=@{ type='ephemeral' } })
    messages=@(@{ role='user'; content=$kullanici })
    output_config=@{ format=@{ type='json_schema'; schema=$SEMA } }
  } | ConvertTo-Json -Depth 20

  $ham = Cagir { Invoke-WebRequest -Method Post -Uri 'https://api.anthropic.com/v1/messages' -Headers $AH -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -UseBasicParsing -TimeoutSec 240 } 3
  # PS 5.1 charset tuzagi: bayti kendimiz cozuyoruz, yoksa Turkce bozulur.
  $y = [Text.Encoding]::UTF8.GetString($ham.RawContentStream.ToArray()) | ConvertFrom-Json
  $script:gG += [int]$y.usage.input_tokens; $script:gC += [int]$y.usage.output_tokens
  $t = ($y.content | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ''
  return ($t | ConvertFrom-Json)
}

# --- 3) KAPILAR: SoruUretici.Gecerli() ile BIREBIR AYNI --------------------
# KURAL 10'UN MEKANIK KAPISI (Cem kusur bildirimi 10.09).
# Istem yumusak bir kapidir: kural 9 eklendikten SONRA ayni turda
# "rayic bedel KACINCI olcu olarak yer almaktadir?" cikti. Kural yazmak isin
# yarisi; kapi diger yarisi. SoruUretici.cs'teki SiralamaDeseni ile SENKRON.
$RX_SIRALAMA = [regex]::new('ka[çc]([ıi])nc([ıi])|ka[çc]\s+numaral([ıi])|hangi\s+ben[dt]|bendinde\s+d[üu]zenlen|s([ıi])ra\s+numaras([ıi])','IgnoreCase')

function Gecerli($s){
  if([string]::IsNullOrWhiteSpace("$($s.soru)")){ return 'bos soru' }
  if($RX_SIRALAMA.IsMatch("$($s.soru)")){ return 'siralama/ezber sorusu (kural 10)' }
  $d="$($s.dogru)"
  if($d.Length -ne 1 -or 'ABCDE'.IndexOf($d) -lt 0){ return "gecersiz dogru sik: '$d'" }
  $siklar=@("$($s.siklar.A)","$($s.siklar.B)","$($s.siklar.C)","$($s.siklar.D)","$($s.siklar.E)")
  if(@($siklar|Where-Object{[string]::IsNullOrWhiteSpace($_)}).Count -gt 0){ return 'bos sik' }
  if(@($siklar|ForEach-Object{$_.ToLower()}|Select-Object -Unique).Count -ne 5){ return 'ikiz sik' }
  if([string]::IsNullOrWhiteSpace("$($s.dayanak)")){ return 'dayanak yazilmamis' }
  $dogruMetin = switch($d){ 'A'{$siklar[0]} 'B'{$siklar[1]} 'C'{$siklar[2]} 'D'{$siklar[3]} default{$siklar[4]} }
  if($dogruMetin.Length -gt 12 -and "$($s.soru)".ToLower().Contains($dogruMetin.ToLower())){ return 'cevap sizintisi' }
  return $null
}

# --- kos -------------------------------------------------------------------
$sonuc = New-Object System.Collections.ArrayList
$jsonYolOnce = Join-Path $kok 'veri\vuk-sinav-provasi.json'
if($Ekle -and (Test-Path $jsonYolOnce)){
  try {
    $o = Get-Content $jsonYolOnce -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($b in @($o.bloklar)){ if($Konu.Count -eq 0 -or $Konu -notcontains "$($b.konu)"){ [void]$sonuc.Add($b) } }
    Write-Host ("Onceki turdan tasinan blok: {0}" -f $sonuc.Count)
  } catch { Write-Host 'UYARI: onceki json okunamadi, sifirdan yaziliyor' -ForegroundColor Yellow }
}

$kosulacak = if($Konu.Count -gt 0){ @($KONULAR | Where-Object { $Konu -contains $_.konu }) } else { $KONULAR }
foreach($k in $kosulacak){
  Write-Host ("KONU: {0}" -f $k.konu)
  $day = DayanakBul $k.ders $k.konu $k.ek
  # ARAMA DOGRU MADDEYI BULAMADIYSA konu karti yedegi devreye girer.
  if($k.madde){
    $bekleniyor = ($k.madde -replace '%$','')
    if((-not $day) -or ("$($day.kaynak_ad)" -notlike "$bekleniyor*")){
      $dogrudan = MaddeGetirDogrudan $k.madde
      if($dogrudan){
        $iskalanan = if($day){ "$($day.kaynak_ad)" } else { '(hicbir sey)' }
        Write-Host ("    ARAMA ISKALADI (getirdigi: {0}) -> konu karti yedegi kullanildi" -f $iskalanan) -ForegroundColor Yellow
        $day = $dogrudan
      }
    }
  }
  if(-not $day){ Write-Host '  KAYNAKSIZ - soru URETILMEDI' -ForegroundColor Yellow
    [void]$sonuc.Add([pscustomobject]@{ konu=$k.konu; zorluk=$k.zorluk; dayanak_ad=''; sorular=@(); red=@('dayanak yok') }); continue }
  Write-Host ("  dayanak: {0}  ({1:N0} krk)" -f $day.kaynak_ad, "$($day.metin)".Length)

  $paket = ModeliCagir $k $day
  $saglam=@(); $red=@(); $redHam=@()
  foreach($s in @($paket.sorular)){
    $sebep = Gecerli $s
    # REDDEDILEN SORU DA SAKLANIR: "kapida red 1" demek yetmez, NEYIN
    # reddedildigi gorulmeden kapinin hakli olup olmadigi denetlenemez.
    if($sebep){ $red += $sebep; $redHam += $s } else { $saglam += $s }
  }
  Write-Host ("  uretilen {0} · model dondurdu {1} · kapida red {2}" -f $saglam.Count, @($paket.sorular).Count, $red.Count)
  [void]$sonuc.Add([pscustomobject]@{ konu=$k.konu; zorluk=$k.zorluk; dayanak_ad="$($day.kaynak_ad)"; sorular=$saglam; red=$red; red_ham=$redHam })
}

$usd = ($script:gG/1e6)*2.0 + ($script:gC/1e6)*10.0

# --- 4) OKUNUR METIN -------------------------------------------------------
$sb = New-Object Text.StringBuilder
[void]$sb.AppendLine('================================================================')
[void]$sb.AppendLine('  TETIKTE RAG MOTORU - VUK SINAV PROVASI')
[void]$sb.AppendLine(('  ' + (Get-Date -Format 'dd.MM.yyyy HH:mm') + '   model: ' + $Model))
[void]$sb.AppendLine('================================================================')
[void]$sb.AppendLine('')
$sn=0
foreach($b in $sonuc){
  [void]$sb.AppendLine('----------------------------------------------------------------')
  [void]$sb.AppendLine(('KONU    : ' + $b.konu + '   (' + $b.zorluk + ')'))
  [void]$sb.AppendLine(('DAYANAK : ' + $b.dayanak_ad))
  if($b.red.Count -gt 0){ [void]$sb.AppendLine(('KAPIDA RED: ' + ($b.red -join ', '))) }
  [void]$sb.AppendLine('----------------------------------------------------------------')
  foreach($s in @($b.sorular)){
    $sn++
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(("SORU $sn"))
    [void]$sb.AppendLine("$($s.soru)")
    [void]$sb.AppendLine('')
    foreach($h in 'A','B','C','D','E'){ [void]$sb.AppendLine(("   $h) " + $s.siklar.$h)) }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(("   DOGRU CEVAP: " + $s.dogru))
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('   COZUM:')
    foreach($h in 'A','B','C','D','E'){
      $im = if($h -eq "$($s.dogru)"){ '+' } else { '-' }
      [void]$sb.AppendLine(("   $im $h) " + $s.aciklama.$h))
    }
    [void]$sb.AppendLine(('   DAYANAK: ' + $s.dayanak))
  }
  [void]$sb.AppendLine('')
}
[void]$sb.AppendLine('================================================================')
[void]$sb.AppendLine(("TOPLAM SORU: $sn"))
[void]$sb.AppendLine(("FATURA     : {0:N4} USD  (giris {1:N0} / cikis {2:N0} jeton)" -f $usd,$script:gG,$script:gC))
[void]$sb.AppendLine('================================================================')

$metinYol = Join-Path $kok 'veri\vuk-sinav-provasi.txt'
[IO.File]::WriteAllText($metinYol, $sb.ToString(), [Text.UTF8Encoding]::new($true))
$jsonYol = Join-Path $kok 'veri\vuk-sinav-provasi.json'
[IO.File]::WriteAllText($jsonYol, (@{ olcum=(Get-Date -Format 'dd.MM.yyyy HH:mm'); model=$Model; fatura=@{ giris=$script:gG; cikis=$script:gC; usd=[math]::Round($usd,4) }; bloklar=$sonuc } | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($true))

Write-Host ''
Write-Host ("BITTI: {0} soru · {1:N4} USD" -f $sn,$usd)
Write-Host ("  -> veri/vuk-sinav-provasi.txt")
