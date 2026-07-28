# ============================================================================
#  PROFESOR v2 — KATMAN 2  (28.07.2026)
#
#  NEDEN VAR: K2 denetcisi 107 itirazin 104'unde HAKSIZ cikti (%2,8 isabet).
#  Sebep tekti: K2'nin istemine maddenin ETIKETI gidiyordu ("VUK m.234"),
#  METNI degil. Yani K2 dogrulama yapmiyor, kendi hafizasindan cevap veriyordu.
#  Hafiza yanilir; metin yanilmaz. Profesor v2'nin istemine MADDENIN TAM METNI
#  gider (motor/madde-coz.ps1 ambardan getirir) ve model "yalniz bu metne
#  dayan" diye kisitlanir.
#
#  UC AYRI SORU sorulur — cunku bir soru uc ayri sekilde bozulabilir:
#    1) destek    : isaretli cevabi madde DESTEKLIYOR mu?
#    2) tek_dogru : sıklardan TAM OLARAK BIRI mi dogru? (iki dogru sik hatasi)
#    3) celiski   : aciklamalardan biri maddeyle CELISIYOR mu?
#
#  HAKEMIN HAKEMI: model her hukumde maddeden BIREBIR ALINTI vermek zorunda.
#  Alinti gercekten madde metninde geciyor mu diye MAKINEYLE bakilir. Gecmiyorsa
#  hukum COPE ATILIR ve soru GM'ye gider. Boylece profesorun uydurmasi da
#  yakalanir — Cem'in sarti: "hata olsa bile bizim yakalayacagimiz".
#
#  KURAL: metni cozulemeyen soru YARGILANMAZ, 'metin-yok' isaretlenip GM'ye
#  birakilir. Profesor asla bosluga hukum vermez.
#
#  PARA: -olcum modu HICBIR SEY HARCAMAZ, yalniz maliyet tahmini cikarir.
#  Gercek kosu Batch API ile yapilir (%50 indirim) ve ancak -calistir ile.
# ============================================================================
param(
  [switch]$olcum,        # para harcamaz: kac soru yargilanabilir + maliyet tahmini
  [switch]$calistir,     # GERCEK KOSU — para harcar
  [string]$kaynak = 'yerel',   # yerel | kasa
  [int]$sinir = 0,             # 0 = hepsi
  [string]$model = 'claude-sonnet-4-5-20250929',
  [string]$cikti = ''
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

# --- KENDI KAYDINI TUT. Actions loglari admin-kilitli; iki kosu ust uste dustu
# ve NEDEN dustugunu okuyamadik. Bir kanal, hatasini gosteremiyorsa kurulmus
# sayilmaz. Artik butun ciktisi dosyaya da yaziliyor ve is akisi commit'liyor.
$LOG = Join-Path $kok 'veri/profesor-log.txt'
try { Start-Transcript -Path $LOG -Force | Out-Null } catch { Write-Host "(transcript acilamadi: $($_.Exception.Message))" }

if(-not $olcum -and -not $calistir){
  Write-Host "Kullanim:"
  Write-Host "  profesor-v2.ps1 -olcum                 # PARA HARCAMAZ, maliyet cikarir"
  Write-Host "  profesor-v2.ps1 -calistir              # gercek kosu (Batch, %50 indirim)"
  exit 0
}

# --- madde cozucuyu yukle (fonksiyonlarini kullanacagiz)
. (Join-Path $here 'madde-coz.ps1') -kutuphane

$MAX_MADDE = 6000   # cok uzun maddeler kirpilir; kirpma ISARETLENIR

# ---------------------------------------------------------------- sorulari topla
function YerelSorular {
  $liste = New-Object System.Collections.Generic.List[object]
  foreach($d in @(Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter *.json -ErrorAction SilentlyContinue | Sort-Object Name)){
    try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
    if(-not $x.sorular){ continue }
    foreach($s in @($x.sorular)){ if($s){ $liste.Add($s) } }
  }
  return $liste
}
function KasaSorulari {
  $KEY = $env:SUPABASE_SERVICE_KEY
  if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - kasa okunamaz."; exit 1 }
  $H = @{ apikey=$KEY; Authorization="Bearer $KEY" }
  $u = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
  $liste = New-Object System.Collections.Generic.List[object]
  $bas = 0
  while($true){
    $s = Invoke-RestMethod -Uri "$u`?select=id,soru,siklar,dogru,aciklama,kaynak,ders,konu,sinav&order=id&offset=$bas&limit=500" -Headers $H -TimeoutSec 180
    $d = @($s); if($d.Count -eq 0){ break }
    foreach($x in $d){ $liste.Add($x) }
    if($d.Count -lt 500){ break }
    $bas += 500
  }
  return $liste
}

Write-Host ("PowerShell surumu: {0}" -f $PSVersionTable.PSVersion)
Write-Host ("Kok: {0}" -f $kok)
$sorular = if($kaynak -eq 'kasa'){ KasaSorulari } else { YerelSorular }
Write-Host ("Soru: {0} ({1})" -f $sorular.Count, $kaynak)
if($sorular.Count -eq 0){
  Write-Host "KIRMIZI: hic soru okunamadi. veri/fabrika bos ya da erisilemiyor."
  try { Stop-Transcript | Out-Null } catch {}
  exit 1
}

# ---------------------------------------------------------------- istem kurucu
function IstemKur($s, $maddeMetni, $maddeEtiket){
  $sik = ""
  foreach($h in @('A','B','C','D','E')){
    $v = "$($s.siklar.$h)"
    if($v.Trim().Length -gt 0){ $sik += "$h) $v`n" }
  }
  $ack = ""
  foreach($h in @('A','B','C','D','E')){
    $v = "$($s.aciklama.$h)"
    if($v.Trim().Length -gt 0){ $ack += "$h : $v`n" }
  }
  if($ack.Trim().Length -eq 0){ $ack = "(aciklama yok)" }

  return @"
Sen bir mevzuat denetcisisin. Asagida bir mevzuat huknunun TAM METNI ve bu hukme dayandigi iddia edilen bir sinav sorusu var.

MUTLAK KURAL: YALNIZCA asagidaki METNE dayanarak karar ver. Kendi hafizandan hukum ekleme. Metinde yazmayan bir seyi ne dogru ne yanlis say; metin yetmiyorsa "yetersiz" de. Metin disinda bir kaynaga atif yapma.

=== MEVZUAT METNI ($maddeEtiket) ===
$maddeMetni
=== METIN BITTI ===

SORU: $($s.soru)
SIKLAR:
$sik
ISARETLI DOGRU CEVAP: $($s.dogru)
SIK ACIKLAMALARI:
$ack

Su uc soruyu AYRI AYRI cevapla:
1. destek    — Isaretli cevap ($($s.dogru)) yukaridaki metin tarafindan destekleniyor mu? (evet / hayir / yetersiz)
2. tek_dogru — Siklardan TAM OLARAK BIRI mi dogru? Birden fazla sik dogruysa "hayir". (evet / hayir / yetersiz)
3. celiski   — Sik aciklamalarindan HERHANGI BIRI metinle celisiyor mu? (evet / hayir)

ALINTI ZORUNLU: "alinti" alanina, hukmune dayanak olan yeri METINDEN BIREBIR kopyala (en fazla 25 kelime). Kendi cumleni yazma, degistirme, ozetleme. Alintin metinde birebir gecmiyorsa hukmun gecersiz sayilacak.

SADECE gecerli JSON dondur, baska hicbir sey yazma:
{"destek":"evet|hayir|yetersiz","tek_dogru":"evet|hayir|yetersiz","celiski":"evet|hayir","dogru_sik":"A|B|C|D|E|bilinmiyor","gerekce":"<tek cumle>","alinti":"<metinden birebir>"}
"@
}

# ---------------------------------------------------------------- hazirlik
$isler = New-Object System.Collections.Generic.List[object]
$ist = [ordered]@{ toplam=0; metinYok=0; mevzuatDisi=0; hazir=0 }
$sayac = 0
foreach($s in $sorular){
  $ist.toplam++
  if($sinir -gt 0 -and $isler.Count -ge $sinir){ break }
  $k = "$($s.kaynak)"
  if(MevzuatDisiMi $k){ $ist.mevzuatDisi++; continue }
  $c = KaynakCoz $k
  if(-not $c -or "$($c.durum)" -notin @('cozuldu','cozuldu-standart')){ $ist.metinYok++; continue }
  if(-not $c.metin -or "$($c.metin)".Trim().Length -lt 40){ $ist.metinYok++; continue }
  $metin = "$($c.metin)"
  $kirpildi = $false
  if($metin.Length -gt $MAX_MADDE){ $metin = $metin.Substring(0,$MAX_MADDE); $kirpildi = $true }
  $isler.Add([pscustomobject]@{
    id      = "$($s.id)"
    soru    = $s
    etiket  = "$($c.ad)"
    metin   = $metin
    kirpildi= $kirpildi
    istem   = (IstemKur $s $metin "$($c.etiket)")
  })
  $ist.hazir++
  $sayac++
  if($sayac % 100 -eq 0){ Write-Host ("  ...{0}" -f $sayac) }
}

Write-Host ""
Write-Host "======== PROFESOR v2 HAZIRLIK ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-14} {1}" -f $k, $ist[$k]) }

# ---------------------------------------------------------------- maliyet tahmini
$girisKr = 0; $cikisTahmin = 260   # JSON cevap ~260 token
foreach($i in $isler){ $girisKr += $i.istem.Length }
# Turkce metin icin kaba cevrim: ~3 karakter = 1 token (TAHMIN, olculmus deger degil)
$girisTok = [math]::Round($girisKr / 3)
$cikisTok = $isler.Count * $cikisTahmin

# LISTE FIYATI (1M token basina, USD) — Sonnet ailesi
$FIY_GIRIS = 3.0
$FIY_CIKIS = 15.0
$hamUSD   = ($girisTok/1e6*$FIY_GIRIS) + ($cikisTok/1e6*$FIY_CIKIS)
$batchUSD = $hamUSD / 2      # Batch API %50 indirim

Write-Host ""
Write-Host "======== MALIYET TAHMINI (TAHMINDIR, olculmus degil) ========"
Write-Host ("  yargilanacak soru : {0}" -f $isler.Count)
Write-Host ("  giris  ~{0:N0} token   (kaba cevrim: 3 karakter = 1 token)" -f $girisTok)
Write-Host ("  cikis  ~{0:N0} token   (soru basina ~{1} token varsayimi)" -f $cikisTok, $cikisTahmin)
Write-Host ("  model  : {0}" -f $model)
Write-Host ("  liste fiyati    : ~{0:N2} USD" -f $hamUSD)
Write-Host ("  BATCH (%50 ind.): ~{0:N2} USD  <-- kullanilacak yol" -f $batchUSD)
Write-Host ("  soru basina     : ~{0:N4} USD" -f $(if($isler.Count){ $batchUSD/$isler.Count } else { 0 }))

if($olcum){
  Write-Host ""
  Write-Host "OLCUM MODU — hicbir istek atilmadi, 0 USD harcandi."
  $ozet = [ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); kaynak=$kaynak; model=$model
    toplam=$ist.toplam; mevzuat_disi=$ist.mevzuatDisi; metin_yok=$ist.metinYok; yargilanabilir=$isler.Count
    tahmini_batch_usd=[math]::Round($batchUSD,2)
  }
  [IO.File]::WriteAllText((Join-Path $kok 'veri/profesor-olcum.json'), ($ozet | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
  Write-Host "-> veri/profesor-olcum.json"
  exit 0
}

# ---------------------------------------------------------------- GERCEK KOSU
$AK = "$env:ANTHROPIC_API_KEY".Trim()
if(-not $AK){ Write-Host "ANTHROPIC_API_KEY yok - kosu yapilamaz."; exit 1 }
if($isler.Count -eq 0){ Write-Host "Yargilanacak soru yok."; exit 0 }

$HDR = @{ 'x-api-key'=$AK; 'anthropic-version'='2023-06-01' }
$BATCH_MAX = 400   # tek partide en fazla

# --- HATA DEFTERI: Actions loglari admin-kilitli oldugu icin hata DOSYAYA yazilir.
# Is akisi bu dosyayi always() ile commit'ler; boylece kosu neden dustu diye
# kor kalmayiz. Depoda daha once ayni karar paket-yukle.ps1 icin alinmisti.
function HataYaz([string]$nerede, [string]$mesaj, [string]$sunucu, $ek){
  $y = Join-Path $kok 'veri/profesor-hata.json'
  $k = [ordered]@{
    zaman = (Get-Date -Format 'dd.MM.yyyy HH:mm')
    nerede = $nerede
    mesaj = $mesaj
    sunucu_cevabi = $(if($sunucu.Length -gt 1500){ $sunucu.Substring(0,1500) } else { $sunucu })
    ek = $ek
  }
  [IO.File]::WriteAllText($y, ($k | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("HATA [{0}]: {1}" -f $nerede, $mesaj)
  if($sunucu){ Write-Host ("SUNUCU: {0}" -f $sunucu.Substring(0,[Math]::Min(400,$sunucu.Length))) }
}

# --- SON KALKAN: yukaridaki try/catch'lerin disinda, BEKLENMEYEN bir yerde hata
# cikarsa da defter yazilsin. Iki kosu ust uste hata defteri BIRAKMADAN dustu;
# demek ki hata ongordugum yerlerde degildi. Artik nerede olursa olsun yakalanir.
trap {
  try {
    HataYaz "beklenmeyen" "$($_.Exception.Message)" "$($_.ScriptStackTrace)" @{
      satir = "$($_.InvocationInfo.ScriptLineNumber)"
      komut = "$($_.InvocationInfo.Line)".Trim()
      tur   = "$($_.Exception.GetType().FullName)"
    }
  } catch {}
  try { Stop-Transcript | Out-Null } catch {}
  exit 1
}

# --- ON KONTROL: 400 soruluk bir parti hazirlayip gondermeden ONCE anahtar ve
# model kimligi tek satirlik bir istekle sinanir. Maliyeti birkac token'dir.
# Iki kosu gonderim adiminda dustu; sebep anahtar/model ise bunu 1 saniyede ve
# neredeyse bedava ogrenmek, 1,5 USD'lik partiyi ceviren bir hatayla ogrenmekten
# iyidir. Hata mesaji da dogrudan sunucudan gelir - tahmin etmeye gerek kalmaz.
Write-Host "ON KONTROL: anahtar + model kimligi sinaniyor..."
try {
  $dene = @{ model=$model; max_tokens=1; messages=@(@{ role='user'; content='tamam' }) } | ConvertTo-Json -Depth 5
  $ok = Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages' -Headers $HDR -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($dene)) -TimeoutSec 60
  Write-Host ("  ON KONTROL TAMAM - model: {0}" -f $ok.model)
} catch {
  $cevap = ""
  try { $cevap = (New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() } catch {}
  HataYaz "on-kontrol" $_.Exception.Message $cevap @{ model=$model; not="Anahtar ya da model kimligi gecersiz. Parti GONDERILMEDI - para harcanmadi." }
  try { Stop-Transcript | Out-Null } catch {}
  exit 1
}

$sonuclar = @{}
$script:gercekGiris = 0
$script:gercekCikis = 0
$partiler = [math]::Ceiling($isler.Count / $BATCH_MAX)
for($p=0; $p -lt $partiler; $p++){
  $dilim = @($isler[($p*$BATCH_MAX)..([math]::Min(($p+1)*$BATCH_MAX-1, $isler.Count-1))])
  $req = @()
  $ix = 0
  foreach($i in $dilim){
    $req += @{
      custom_id = ("s{0}" -f $ix)
      params = @{
        model = $model
        max_tokens = 500
        messages = @(@{ role='user'; content=$i.istem })
      }
    }
    $ix++
  }
  $govde = @{ requests = $req } | ConvertTo-Json -Depth 8
  Write-Host ("PARTI {0}/{1}: {2} soru gonderiliyor ({3:N0} KB govde)..." -f ($p+1), $partiler, $dilim.Count, ($govde.Length/1024))
  # 28.07: Actions loglari admin-kilitli. Hata ekrana yazilip kaybolursa kor kaliriz;
  # depo kuralı: HATA DOSYAYA YAZILIR, is akisi always() ile commit'ler.
  try {
    $b = Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages/batches' -Headers $HDR -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde))
  } catch {
    $cevap = ""
    try { $cevap = (New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() } catch {}
    HataYaz "batch-gonderim" $_.Exception.Message $cevap @{ parti=($p+1); adet=$dilim.Count; govde_kb=[math]::Round($govde.Length/1024) }
    throw
  }
  $bid = $b.id
  Write-Host ("  batch id: {0}" -f $bid)

  $tur = 0
  while($true){
    Start-Sleep -Seconds 20
    $tur++
    $st = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages/batches/$bid" -Headers $HDR
    Write-Host ("  durum: {0}" -f $st.processing_status)
    if($st.processing_status -eq 'ended'){ break }
    # 90 tur = 30 dakika. Batch normalde dakikalar icinde biter; bu asilma kalkanidir.
    if($tur -ge 90){ Write-Host "  ZAMAN ASIMI: parti 30 dk'da bitmedi, birakiliyor."; break }
  }
  # Sonuc adresini SABIT KODLAMA - durum cevabindaki results_url kullanilir.
  # Sabit adres bir yonlendirmeye takilirsa basliklar tasinmaz ve 403 alinir;
  # o hata da parayi harcadiktan SONRA cikar, en pahali yerde.
  $sonucAdres = if($st.results_url){ "$($st.results_url)" } else { "https://api.anthropic.com/v1/messages/batches/$bid/results" }
  Write-Host ("  sonuc adresi: {0}" -f $sonucAdres)
  try {
    $satirlar = (Invoke-WebRequest -UseBasicParsing -Uri $sonucAdres -Headers $HDR -TimeoutSec 300).Content -split "`n"
  } catch {
    $cevap = ""
    try { $cevap = (New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() } catch {}
    # BURASI KRITIK: parti islendi, yani PARA HARCANDI. Sonuc alinamazsa batch id
    # kaydedilir; ayni parayi ikinci kez odemeden sonuc elle cekilebilir.
    HataYaz "sonuc-cekme" $_.Exception.Message $cevap @{ batch_id=$bid; adres=$sonucAdres; UYARI="PARTI ISLENDI - PARA HARCANDI. Bu batch id ile sonuc yeniden cekilebilir, tekrar gonderilmemeli." }
    throw
  }
  foreach($sat in $satirlar){
    if("$sat".Trim().Length -eq 0){ continue }
    $r = $sat | ConvertFrom-Json
    $n = [int]("$($r.custom_id)".Substring(1))
    $is = $dilim[$n]
    if("$($r.result.type)" -ne 'succeeded'){ $sonuclar[$is.id] = @{ hata="$($r.result.type)" }; continue }
    # GERCEK FATURA: tahmin degil, API'nin dondurdugu token sayisi. Rakam disiplini.
    $script:gercekGiris += [int]"$($r.result.message.usage.input_tokens)"
    $script:gercekCikis += [int]"$($r.result.message.usage.output_tokens)"
    $txt = "$($r.result.message.content[0].text)"
    $mt = [regex]::Match($txt, '\{[\s\S]*\}')
    if(-not $mt.Success){ $sonuclar[$is.id] = @{ hata='json-yok' }; continue }
    try { $j = $mt.Value | ConvertFrom-Json } catch { $sonuclar[$is.id] = @{ hata='json-bozuk' }; continue }
    $sonuclar[$is.id] = $j
  }
}

# ---------------------------------------------------------------- HAKEMIN HAKEMI
function Sadelestir([string]$t){
  $x = "$t".ToLowerInvariant()
  $x = $x -replace '[''‘’"“”]', "'"
  $x = $x -replace '[^\p{L}\p{Nd}]', ''
  return $x
}
$rapor = New-Object System.Collections.Generic.List[object]
$sy = [ordered]@{ temiz=0; bayrak=0; alintiUydurma=0; hata=0 }
foreach($i in $isler){
  $h = $sonuclar[$i.id]
  if(-not $h -or $h.hata){ $sy.hata++; continue }
  $al = Sadelestir "$($h.alinti)"
  $md = Sadelestir $i.metin
  $gecerli = ($al.Length -ge 20 -and $md.Contains($al))
  if(-not $gecerli){ $sy.alintiUydurma++ }
  $sorunlu = ("$($h.destek)" -ne 'evet') -or ("$($h.tek_dogru)" -ne 'evet') -or ("$($h.celiski)" -eq 'evet')
  if($sorunlu){ $sy.bayrak++ } else { $sy.temiz++ }
  $rapor.Add([pscustomobject]@{
    id=$i.id; etiket=$i.etiket; kirpildi=$i.kirpildi
    destek="$($h.destek)"; tek_dogru="$($h.tek_dogru)"; celiski="$($h.celiski)"
    profesor_cevabi="$($h.dogru_sik)"; isaretli="$($i.soru.dogru)"
    gerekce="$($h.gerekce)"; alinti="$($h.alinti)"
    alinti_dogrulandi=$gecerli
    hukum = $(if(-not $gecerli){ 'GECERSIZ-GM-OKUSUN' } elseif($sorunlu){ 'BAYRAK' } else { 'TEMIZ' })
  })
}

Write-Host ""
Write-Host "======== PROFESOR v2 SONUC ========"
foreach($k in $sy.Keys){ Write-Host ("  {0,-16} {1}" -f $k, $sy[$k]) }
Write-Host ("  NOT: alinti dogrulanmayan {0} hukum COPE ATILDI, sorular GM'ye gidiyor." -f $sy.alintiUydurma)

# ---------------------------------------------------------------- KALIBRASYON
# Yerel kosuda sorularin bir kismini GM ELLE OKUDU ve etiketledi:
#   durum='karantina-red' -> GM BOZUK dedi   (profesor de bayrak kaldirmali)
#   durum='gm-onay'       -> GM SAGLAM dedi  (profesor temiz demeli)
# Bu iki kume profesorun ISABETINI olcer. Olcmeden tam kasaya para harcanmaz.
$kal = [ordered]@{ redToplam=0; redYakalanan=0; onayToplam=0; onayTemiz=0 }
foreach($i in $isler){
  $d = "$($i.soru.durum)"
  $r = @($rapor | Where-Object { $_.id -eq $i.id })[0]
  if(-not $r){ continue }
  if($d -eq 'karantina-red'){ $kal.redToplam++;  if($r.hukum -eq 'BAYRAK'){ $kal.redYakalanan++ } }
  if($d -eq 'gm-onay'){       $kal.onayToplam++; if($r.hukum -eq 'TEMIZ'){  $kal.onayTemiz++ } }
}
Write-Host ""
Write-Host "======== KALIBRASYON (GM etiketine karsi) ========"
Write-Host ("  GM'nin REDDETTIGI  : {0} soru -> profesor {1}'ini yakaladi" -f $kal.redToplam, $kal.redYakalanan)
Write-Host ("  GM'nin ONAYLADIGI  : {0} soru -> profesor {1}'ine temiz dedi" -f $kal.onayToplam, $kal.onayTemiz)
if($kal.onayToplam -gt 0){
  $yanlisAlarm = $kal.onayToplam - $kal.onayTemiz
  Write-Host ("  YANLIS ALARM       : {0} (GM saglam dedi, profesor bayrak kaldirdi)" -f $yanlisAlarm)
  Write-Host  "  NOT: yanlis alarm zararsizdir - o soru GM'ye geri gelir, yayina gitmez."
}

# ---------------------------------------------------------------- GERCEK FATURA
$gG = $script:gercekGiris; $gC = $script:gercekCikis
$gercekUSD = (($gG/1e6*$FIY_GIRIS) + ($gC/1e6*$FIY_CIKIS)) / 2   # Batch %50
Write-Host ""
Write-Host "======== GERCEK FATURA (API'nin dondurdugu token) ========"
Write-Host ("  giris  : {0:N0} token   (tahmin {1:N0} idi)" -f $gG, $girisTok)
Write-Host ("  cikis  : {0:N0} token   (tahmin {1:N0} idi)" -f $gC, $cikisTok)
Write-Host ("  TUTAR  : ~{0:N2} USD  (Batch %50 indirimli, liste fiyati {1}/{2} USD-M varsayimi)" -f $gercekUSD, $FIY_GIRIS, $FIY_CIKIS)

$yol = if($cikti){ $cikti } else { Join-Path $kok 'veri/profesor-v2-rapor.json' }
[IO.File]::WriteAllText($yol, ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); model=$model; kaynak=$kaynak
  ozet=$sy; kalibrasyon=$kal
  fatura=[ordered]@{ giris_token=$gG; cikis_token=$gC; batch_usd=[math]::Round($gercekUSD,2) }
  sonuclar=$rapor
} | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ("-> {0}" -f $yol)
try { Stop-Transcript | Out-Null } catch {}
exit 0
