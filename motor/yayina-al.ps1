# ============================================================================
#  YAYINA ALMA HATTI - VANAYI ACAN BETIK  (10.08.2026, 0 USD, API YOK)
#
#  SORUN: kasada 30.569 soru var, YAYINDA 0. deneme.html sorulari
#  `yayin=true` filtresiyle cekiyor (satir 1948/1972), yani vana tek kolon.
#  Yukarida ne yaparsak yapalim - yutma, kapi, onarim - ogrenciye ulasmiyor.
#
#  BU BETIK NE YAPAR:
#   - yayin-kapisi-temiz-idler.json'u okur (hicbir kapiya takilmayan sorular)
#   - istege bagli ek suzgecler uygular (ders, sinav, zorluk, adet)
#   - secilen sorulari `yayin=true` yapar
#   - YAZ -> GERI OKU -> SAY: yazdiktan sonra kasadaki gercek sayiyi olcer
#
#  NE YAPMAZ: soru metnine DOKUNMAZ. Geri alinabilir - `-geriAl` ile
#  ayni liste yayindan indirilir.
#
#  GUVENLIK: varsayilan PROVA. Yazmak icin -yaz sart.
#  Ayrica -enCok ile tavan konur; yanlislikla tum kasa yayina acilmasin.
#
#  Cikti: veri/yayina-alma-raporu.json
# ============================================================================
param(
  [switch]$yaz,
  [switch]$geriAl,
  [string]$sinav = '',
  [string]$ders = '',
  [int]$enCok = 0,
  [string]$listeYolu = ''
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$kok = Split-Path $PSScriptRoot -Parent
$anahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')
if(-not $anahtar){ $anahtar = $env:SUPABASE_SERVICE_KEY }
if(-not $anahtar){ Write-Host 'SUPABASE_SERVICE_KEY yok.'; exit 1 }
$ADRES = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
$BASLIK = @{ apikey = $anahtar; Authorization = ('Bearer ' + $anahtar); 'User-Agent' = 'mevzuat-radar-robot/1.0' }
Add-Type -AssemblyName System.Net.Http
$istemci = New-Object System.Net.Http.HttpClient
$istemci.Timeout = [TimeSpan]::FromSeconds(120)
$istemci.DefaultRequestHeaders.Add('apikey',$anahtar)
$istemci.DefaultRequestHeaders.Add('Authorization',('Bearer '+$anahtar))
$istemci.DefaultRequestHeaders.Add('User-Agent','mevzuat-radar-robot/1.0')

function Say([string]$filtre){
  for($d=1; $d -le 3; $d++){
    try{
      $r = Invoke-WebRequest -UseBasicParsing -Uri "$ADRES/soru_havuzu?select=id&$filtre&limit=1" -Headers ($BASLIK + @{ Prefer='count=exact' }) -TimeoutSec 60
      return [int](($r.Headers['Content-Range'] -split '/')[-1])
    }catch{ if($d -eq 3){ return -1 }; Start-Sleep -Seconds $d }
  }
  return -1
}

# --- ONCE DURUM -------------------------------------------------------------
$oncekiYayin = Say 'yayin=eq.true'
$kasaToplam  = Say ''
Write-Host ("KASA: {0} | su an YAYINDA: {1}" -f $kasaToplam, $oncekiYayin)

if($listeYolu -eq ''){ $listeYolu = Join-Path $kok 'veri\yayin-kapisi-temiz-idler.json' }
if(-not (Test-Path $listeYolu)){
  Write-Host ''
  Write-Host "TEMIZ ID LISTESI YOK: $listeYolu"
  Write-Host "Once yayin kapisini kosturun:  motor\yayin-kapisi.ps1"
  exit 1
}
$liste = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($listeYolu,[Text.Encoding]::UTF8))
$adaylar = @($liste.idler)
Write-Host ("Temiz id listesi: {0} kayit (uretim tarihi {1})" -f $adaylar.Count, $liste.tarih)

# ============================================================================
# VANA SERTLESTIRME (13.08.2026 — Cem: "siteye girecek veri KESINLIKLE dogru
# olacak"): makine kapisi tek basina YETMEZ (pilot: kapi-temiz 60 sorunun
# 22'si okuyucuda kusurlu cikti). Yayin sarti artik IKI KANIT birden:
#   (1) kapi-temiz (bu liste)  VE  (2) OKUYUCU-UYGUN (GM okuyucu hukmu).
# veri/gm-okuyucu/okundu-temiz.json'da olmayan soru yayina GIREMEZ;
# veri/gm-okuyucu/kusurlu-idler.json'dakiler her durumda DISLANIR.
# GeriAl (-geriAl) bu suzgece takilmaz — yayindan indirme her zaman serbest.
# ============================================================================
if(-not $geriAl){
  $okunduYolu  = Join-Path $kok 'veri\gm-okuyucu\okundu-temiz.json'
  $kusurluYolu = Join-Path $kok 'veri\gm-okuyucu\kusurlu-idler.json'
  $okundu = @{}
  if(Test-Path $okunduYolu){
    foreach($oid in @((ConvertFrom-Json ([IO.File]::ReadAllText($okunduYolu,[Text.Encoding]::UTF8))).idler)){ $okundu["$oid"]=$true }
  }
  if($okundu.Count -eq 0){
    Write-Host ''
    Write-Host 'OKUNDU-TEMIZ LISTESI YOK/BOS: hicbir soru yayina alinamaz.'
    Write-Host 'Once GM okuyucu hattini kosturun (GM-OKUYUCU-SARTNAME.md); hukumler'
    Write-Host 'motor\okundu-temiz-topla.ps1 ile listeye derlenir.'
    exit 1
  }
  $kusurlu = @{}
  if(Test-Path $kusurluYolu){
    foreach($kid in @((ConvertFrom-Json ([IO.File]::ReadAllText($kusurluYolu,[Text.Encoding]::UTF8))).idler)){ $kusurlu["$kid"]=$true }
  }
  $onceki = $adaylar.Count
  $adaylar = @($adaylar | Where-Object { $okundu.ContainsKey("$($_.id)") -and -not $kusurlu.ContainsKey("$($_.id)") })
  Write-Host ("VANA KURALI: kapi-temiz {0} aday -> okuyucu-uygun kesisimi {1} (kusurlu dislandi: {2} listede)" -f $onceki, $adaylar.Count, $kusurlu.Count)
}

# --- SUZGECLER --------------------------------------------------------------
if($sinav -ne ''){ $adaylar = @($adaylar | Where-Object { "$($_.sinav)" -eq $sinav }); Write-Host ("  sinav={0} -> {1}" -f $sinav,$adaylar.Count) }
if($ders -ne ''){ $adaylar = @($adaylar | Where-Object { "$($_.ders)" -like "*$ders*" }); Write-Host ("  ders~{0} -> {1}" -f $ders,$adaylar.Count) }
if($enCok -gt 0 -and $adaylar.Count -gt $enCok){ $adaylar = @($adaylar | Select-Object -First $enCok); Write-Host ("  tavan {0} -> {1}" -f $enCok,$adaylar.Count) }

Write-Host ''
Write-Host ("ISLENECEK: {0} soru  |  hedef durum: yayin={1}" -f $adaylar.Count, (-not $geriAl))
Write-Host ''
Write-Host 'DERS DAGILIMI:'
$adaylar | Group-Object ders | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
  Write-Host ("  {0,-40} {1}" -f $_.Name,$_.Count)
}

if(-not $yaz){
  Write-Host ''
  Write-Host 'PROVA modu - kasaya DOKUNULMADI. Yazmak icin -yaz ekleyin.'
  exit 0
}

# --- YAZ (toplu, id listesiyle) --------------------------------------------
# PostgREST'te `id=in.(a,b,c)` ile toplu PATCH yapilabilir. URL uzunlugu
# sinirli oldugu icin 100'luk kumelere bolunur.
$hedefDeger = (-not $geriAl)
$json = ConvertTo-Json -InputObject ([ordered]@{ yayin = $hedefDeger }) -Compress
$yazilan = 0; $bozuk = 0; $kume = 0
for($i = 0; $i -lt $adaylar.Count; $i += 100){
  $parca = @($adaylar | Select-Object -Skip $i -First 100)
  $idler = ($parca | ForEach-Object { $_.id }) -join ','
  $filtre = 'id=in.(' + $idler + ')'
  $kod = 0; $hata = ''
  for($d = 1; $d -le 3; $d++){
    try{
      $istek = New-Object System.Net.Http.HttpRequestMessage ((New-Object System.Net.Http.HttpMethod('PATCH'))),($ADRES+'/soru_havuzu?'+$filtre)
      $istek.Content = New-Object System.Net.Http.StringContent ($json,[Text.Encoding]::UTF8,'application/json')
      $istek.Headers.TryAddWithoutValidation('Prefer','return=minimal') | Out-Null
      $cevap = $istemci.SendAsync($istek).GetAwaiter().GetResult()
      $kod = [int]$cevap.StatusCode
      if($kod -ge 300){ $hata = $cevap.Content.ReadAsStringAsync().GetAwaiter().GetResult() }
      $cevap.Dispose(); $istek.Dispose()
      break
    }catch{
      $hata = $_.Exception.Message
      if($d -eq 3){ $kod = 599 } else { Start-Sleep -Milliseconds (700*$d) }
    }
  }
  $kume++
  if($kod -lt 300){ $yazilan += $parca.Count } else { $bozuk += $parca.Count; Write-Host ("  KUME {0} DUSTU (kod {1}) {2}" -f $kume,$kod,$hata) }
  if($kume % 10 -eq 0){ Write-Host ("  ...{0}/{1}" -f $yazilan,$adaylar.Count) }
}

# --- GERI OKU VE SAY: asil kapi ---------------------------------------------
Start-Sleep -Seconds 2
$sonrakiYayin = Say 'yayin=eq.true'
$beklenen = if($geriAl){ $oncekiYayin - $yazilan } else { $oncekiYayin + $yazilan }
Write-Host ''
Write-Host '================ SONUC ================'
Write-Host ("Islenen         : {0}" -f $yazilan)
Write-Host ("Dusen           : {0}" -f $bozuk)
Write-Host ("YAYINDA (once)  : {0}" -f $oncekiYayin)
Write-Host ("YAYINDA (sonra) : {0}" -f $sonrakiYayin)
Write-Host ("Beklenen        : {0}" -f $beklenen)
$tutuyor = ($sonrakiYayin -eq $beklenen)
if($tutuyor){ Write-Host 'DOGRULANDI: kasadaki sayi beklenene esit.' }
else { Write-Host ('!! UYUMSUZ - fark {0}. Sayim ile yazim tutmuyor, incelenmeli.' -f ($sonrakiYayin - $beklenen)) }

$rapor = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod=$(if($geriAl){'GERI AL'}else{'YAYINA AL'})
  kasa=$kasaToplam; islenen=$yazilan; dusen=$bozuk
  yayindaOnce=$oncekiYayin; yayindaSonra=$sonrakiYayin; beklenen=$beklenen; dogrulandi=$tutuyor
  suzgec=[ordered]@{ sinav=$sinav; ders=$ders; enCok=$enCok }
  not='Soru metnine dokunulmaz, yalniz yayin kolonu degisir. -geriAl ile ayni liste yayindan indirilir.'
}
[IO.File]::WriteAllText((Join-Path $kok 'veri\yayina-alma-raporu.json'), ($rapor | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host ("Kanit: veri/yayina-alma-raporu.json")
if(-not $tutuyor){ exit 1 }
