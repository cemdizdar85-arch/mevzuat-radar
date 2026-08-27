# ============================================================================
#  KESIK METIN NÖBETÇİSİ — 25.08.2026
#  Cem: "1-2-3 yap" (GM onerisi 1)
#
#  NEDEN VAR: 25.08'de kart hakemi ambardaki VUK m.269 metninin
#      "...3. Gemiler ve diger tasitlar; 4."
#  diye BITTIGINI buldu. 4. bendin NUMARASI yazilmis, ICERIGI yazilmamis.
#  Belge 352 karakter ve devam parcasi yok - gercek kesilme.
#
#  ⚠ BU KUSUR EKSIK SORU DEGIL, YANLIS SORU URETIR:
#  O metinden yazilan kart 1-3 bentlerini sayip ustune "Liste sinirlidir
#  (numerus clausus)" yazdi. Kaynak eksik oldugu icin kart KENDINDEN EMIN
#  BIR YANLIS ogretti. Aday sinavda 4. bendi gorunce yanlis isaretler.
#
#  ⚠ HICBIR KAPI BUNU GOREMEZ: kesik kaynaktan yazilan soru kapilara TEMIZ
#  gorunur - ici tutarlidir, yalniz DUNYAYLA uyusmaz. Bu yuzden ayri nobetci.
#
#  YUTMA KAPSAMA KAPISININ KOR NOKTASI: o kapi belge SAYISINI olcuyor,
#  belge BUTUNLUGUNU olcmuyor. %98 kapsama yesil yanarken icerideki metinler
#  yarim olabilir. Bu nobetci o bosluğu kapatir.
#
#  UC DURUM (kalici-sigorta-3katman kurali): YESIL / KIRMIZI / KOR.
#  Ambara hic ulasilamadiysa "temiz" DENMEZ - KOR denir.
#
#  Cikti: veri/kesik-metin-raporu.json  ·  0 USD, model yok
# ============================================================================
param([switch]$sessiz, [string]$tur = '')

function KM_Kesik([string]$metin){
  # Metin, icerigi yazilmamis bir liste/bolum numarasiyla mi bitiyor?
  $s = "$metin".TrimEnd()
  if($s.Length -eq 0){ return $false }
  return ($s -match '(?m)(^|[\s;,:])\d{1,2}(\.\d{1,2})*\.\s*$')
}

function KM_SonrakiParcaAdi([string]$ad){
  # Belge bir PARCA ise, DEVAM parcasinin kaynak_ad'ini dondurur; degilse ''.
  # 25.08 dersi: once @{kok;no;son} donduren bir surum yazdim, sonraki adi
  # cagiran tarafta IKI ADIMDA kuruyordum ve ContainsKey dali sessizce
  # atlaniyordu -> her parca "kesik" sayildi, mesru sinir sayaci 0'da kaldi.
  # Adi URETEN yer, deseni COZEN yer olmali. Tek adim, tek sorumluluk.
  if("$ad" -match '(?i)^(.*\bbolum\s+)(\d+)\s*$'){
    return ($Matches[1] + ([int]$Matches[2] + 1))
  }
  if("$ad" -match '(?i)^(.*)\[(\d+)/(\d+)\]\s*$'){
    $simdi=[int]$Matches[2]; $toplam=[int]$Matches[3]
    if($simdi -ge $toplam){ return '' }          # son parca: devami yok
    return ("{0}[{1}/{2}]" -f $Matches[1], ($simdi+1), $toplam)
  }
  return ''
}

function KM_OzSinav {
  # KAPI KENDI SINAVINI GECMELI (25.08: nobetci yazdim, aradigi seyi
  # goremiyordu; oz-sinav olmasa "temiz" derdim ve yalan olurdu).
  $dusen = @()
  $bozuk = @(
    'Asagida yazili kiymetler gayrimenkuller gibi degerlenir: 1. Mutemmim cuzuler; 2. Tesisat; 3. Gemiler; 4.'
    'Bu defterde su bilgiler bulunur. 1. Sira numarasi; 2. Kayit tarihi; 3.'
    'II - Manevi haklar: 1.'
    'Uygulama esaslari asagidadir. 10.4.'
  )
  $temiz = @(
    'Bir ticari isletmeyi kismen de olsa kendi adina isleten kisiye tacir denir.'
    'Bu tebliğ 1.1.2026 tarihinde yururluge girer.'          # sonu tarih - kesik DEGIL
    'Oran yuzde 20 olarak uygulanir; azami tutar 5.000 TL.'  # sonu tutar - kesik DEGIL
    'Madde 275 - Imal edilen emtianin maliyet bedeline su unsurlar girer: mammul madde, iscilik, genel uretim gideri payi ve ambalaj gideri.'
  )
  foreach($b in $bozuk){ if(-not (KM_Kesik $b)){ $dusen += "BILINEN-KESIK yakalanmadi: `"$($b.Substring([Math]::Max(0,$b.Length-40)))`"" } }
  # PARCA ADI dali: 25.08'de bu dal sessizce calismiyordu ve butun parcalar
  # "kesik" sayiliyordu. Artik sinavla civatali.
  $parcaVaka = @(
    @{ ad='Gumruk K. (4458 s.K.) m.3 [2/6]';        bekle='Gumruk K. (4458 s.K.) m.3 [3/6]' }
    @{ ad='Kamu Ihale Genel Tebligi m.28 [8/19]';   bekle='Kamu Ihale Genel Tebligi m.28 [9/19]' }
    @{ ad='GELIR VERGISI GENEL TEBLIGI bolum 1';    bekle='GELIR VERGISI GENEL TEBLIGI bolum 2' }
    @{ ad='Gumruk K. (4458 s.K.) m.3 [6/6]';        bekle='' }          # son parca: devami YOK
    @{ ad='Kooperatifler K. (1163 s.K.) m.74';      bekle='' }          # parca DEGIL
  )
  foreach($pv in $parcaVaka){
    $cikan = KM_SonrakiParcaAdi $pv.ad
    if("$cikan" -ne "$($pv.bekle)"){ $dusen += ("PARCA ADI YANLIS: '$($pv.ad)' -> beklenen '$($pv.bekle)' cikan '$cikan'") }
  }
  foreach($t in $temiz){ if(KM_Kesik $t){ $dusen += "BILINEN-TAM yanlis isaretlendi: `"$($t.Substring([Math]::Max(0,$t.Length-40)))`"" } }
  return $dusen
}

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here
$raporYolu = Join-Path $depoKok 'veri/kesik-metin-raporu.json'

function KM_Rapor($nesne){
  [IO.File]::WriteAllText($raporYolu,(ConvertTo-Json -InputObject $nesne -Depth 8),(New-Object Text.UTF8Encoding($false)))
}

# --- 1) OZ-SINAV: goremedigini arayan nobetci guvenilmez
$sinavDusen = @(KM_OzSinav)
if($sinavDusen.Count){
  if(-not $sessiz){
    Write-Host '!! KESIK METIN NOBETCISI KENDI SINAVINDAN DUSTU:' -ForegroundColor Red
    foreach($d in $sinavDusen){ Write-Host "   $d" }
  }
  KM_Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KOR'; sebep='oz-sinav dustu'; dusen=$sinavDusen })
  exit 1
}
if(-not $sessiz){
  Write-Host ("Oz-sinav: 13/13 vaka gecti (4 kesik + 4 tam + 5 parca-adi)")
  # 25.08 DERSI - PAHALIYA OGRENILDI: bu sinav 13/13 gectigi HALDE devam-parcasi
  # ARAMASI olu duruyordu (fonksiyon tek kayit dondurunce dizi acilir,
  # PSCustomObject.Count = $null). Sinav ad URETIMINI olcuyordu, ARAMAYI degil.
  # Sonuc: 93 yerine 620 kesik raporlandi. Neyin kanitlanmadigi YAZILIR.
  Write-Host '  SINANMAYAN DALLAR: ambar sorgusu · devam-parcasi ARAMASI · rapor yazimi'
}

# --- 2) AMBARI TARA
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $env:SUPABASE_SERVICE_KEY){
  if(-not $sessiz){ Write-Host 'KOR: SUPABASE_SERVICE_KEY yok - ambar okunamadi. "temiz" DENMEZ.' -ForegroundColor Yellow }
  KM_Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KOR'; sebep='anahtar yok' })
  exit 1
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$anahtar = $env:SUPABASE_SERVICE_KEY
$basliklar = @{ apikey=$anahtar; Authorization="Bearer $anahtar"; 'User-Agent'='mevzuat-radar-robot' }
$ambarUcu = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$desenAsili = [uri]::EscapeDataString('[0-9]+\.[[:space:]]*$')

function KM_Cek([string]$adres){
  # PS 5.1: ConvertFrom-Json BORU HATTINDA diziyi katlar - IKI ADIM sart.
  $yanit = Invoke-WebRequest -UseBasicParsing -Uri $adres -Headers $basliklar -TimeoutSec 300
  $govde = [Text.Encoding]::UTF8.GetString($yanit.RawContentStream.ToArray())
  $cozulen = ConvertFrom-Json -InputObject $govde
  return @($cozulen)
}

try {
  $suzgec = "$ambarUcu`?select=id,tur,kaynak_ad,kaynak_url,metin&metin=imatch.$desenAsili&order=id&limit=2000"
  if($tur){ $suzgec += "&tur=eq.$tur" }
  $adaylar = KM_Cek $suzgec
} catch {
  if(-not $sessiz){ Write-Host ("KOR: ambar sorgusu dustu - {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
  KM_Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KOR'; sebep="sorgu hatasi: $($_.Exception.Message)" })
  exit 1
}

# --- 3) MESRU PARCA SINIRLARINI AYIKLA
# En buyuk yanlis-pozitif kaynagi: ambar uzun belgeleri "... bolum 2" ya da
# "... [2/3]" diye boluyor; parcanin ortasinda kesilmesi NORMALDIR - devami
# baska kayitta duruyor. 25.08 olcumu: 255 adayin 174'u tam bu sinifti.
$gercek = New-Object System.Collections.Generic.List[object]
$mesruSinir = 0
$devamOnbellek = @{}
foreach($belge in $adaylar){
  if(-not (KM_Kesik "$($belge.metin)")){ continue }
  $sonrakiAd = KM_SonrakiParcaAdi "$($belge.kaynak_ad)"
  if($sonrakiAd){
    if(-not $devamOnbellek.ContainsKey($sonrakiAd)){
      try {
        $sorguAdresi = "$ambarUcu`?select=id&kaynak_ad=eq." + [uri]::EscapeDataString($sonrakiAd) + "&limit=1"
        # ⚠ 25.08 TUZAK: KM_Cek @(...) dondurse bile PowerShell TEK ELEMANLI
        # diziyi ACAR ve cagiran TEK NESNE alir. PSCustomObject'in .Count'u
        # $null'dur -> "$null -ge 1" FALSE -> devam parcasi VAR olmasina ragmen
        # YOK sayilir. Ana sorgu 831 kayit donduğu icin orada dizi kaliyordu ve
        # tuzak gorunmuyordu: HATA YALNIZ TEK SONUCLU SORGUDA ortaya cikiyor.
        # Cozum: cagri yerinde YENIDEN sarmala, sayiya degil VARLIGA bak.
        $bulunan = @(KM_Cek $sorguAdresi)
        $devamOnbellek[$sonrakiAd] = ($bulunan.Count -ge 1 -and $null -ne $bulunan[0])
      } catch {
        $devamOnbellek[$sonrakiAd] = $false
      }
    }
    if($devamOnbellek[$sonrakiAd]){ $mesruSinir++; continue }
  }
  $metin = "$($belge.metin)"
  $gercek.Add([ordered]@{
    id = "$($belge.id)"; tur = "$($belge.tur)"; kaynak_ad = "$($belge.kaynak_ad)"
    kaynak_url = "$($belge.kaynak_url)"; uzunluk = $metin.Length
    son_60 = $metin.Substring([Math]::Max(0,$metin.Length-60))
  })
}

# --- 4) KARAR
$durum = if($gercek.Count -eq 0){ 'YESIL' } else { 'KIRMIZI' }
if(-not $sessiz){
  Write-Host ''
  Write-Host ("Asili numarayla biten belge : {0}" -f $adaylar.Count)
  Write-Host ("  mesru parca siniri        : {0}" -f $mesruSinir)
  Write-Host ("  GERCEK KESIK              : {0}" -f $gercek.Count)
  if($gercek.Count){
    Write-Host ''
    Write-Host 'KIRMIZI — kaynagi kesik belgeler (kanuna gore ilk 15):' -ForegroundColor Red
    $sayi = 0
    foreach($g in ($gercek | Sort-Object kaynak_ad)){
      $sayi++; if($sayi -gt 15){ break }
      Write-Host ("  {0,-56} ...{1}" -f $g.kaynak_ad.Substring(0,[Math]::Min(56,$g.kaynak_ad.Length)), $g.son_60.Trim())
    }
    if($gercek.Count -gt 15){ Write-Host ("  ... ve {0} belge daha (raporda tamami var)" -f ($gercek.Count-15)) }
    Write-Host ''
    Write-Host 'Bu belgelerden yazilan soru/kart KENDINDEN EMIN YANLIS ogretir.'
    Write-Host 'Onarim: kaynak_url''den kanunu yeniden yut, sonra soru-damga-tazele.ps1 kos.'
  } else {
    Write-Host 'YESIL — kaynagi kesik belge yok.'
  }
}
$duz = @(); foreach($g in $gercek){ $duz += ,([pscustomobject]$g) }
KM_Rapor ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$durum
  aday=$adaylar.Count; mesru_parca_siniri=$mesruSinir; gercek_kesik=$gercek.Count
  belgeler=$duz
})
if(-not $sessiz){ Write-Host '-> veri/kesik-metin-raporu.json' }
if($gercek.Count){ exit 1 } else { exit 0 }