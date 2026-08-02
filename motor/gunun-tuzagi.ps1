# ============================================================================
#  GUNUN TUZAGI — 02.08.2026 (Cem onayi: "devam", pazarlama oneri #4)
#
#  NEDEN: Pazar arastirmasi (02.08) su boslugu buldu — Fuat Hoca 38.000,
#  Suat Hoca 25.800 takipcili ama IKISI DE motivasyon/basari tebrigi
#  paylasiyor; SISTEMLI gunluk soru paylasan YOK. Bizde bunun stoku
#  sonsuz (27.478 soru) ve maliyeti SIFIR — soru zaten uretilmis, zaten
#  dogrulanmis. Yapay zekaya tek kurus verilmez.
#
#  NE YAPAR: kasadan gunde BIR yayindaki soruyu secer, paylasima hazir
#  json'a yazar (veri/gunun-tuzagi.json) — tuzak.html sayfasi ve Cem'in
#  Instagram paylasimi bunu okur.
#
#  SECIM KURALI (deterministik, kurada oynama yok):
#    - yayin = true (H1/hakem/mukerrer kapilarindan gecmis)
#    - soru + 5 sik + dogru + aciklama + kaynak TAM olacak
#    - aciklama zengin olacak (ogretici olsun diye asgari uzunluk)
#    - DAHA ONCE PAYLASILMAMIS olacak (veri/tuzak-gecmisi.json)
#    - kalanlar icinde tarih-tohumlu sirayla secilir
#
#  ONE SORU/GUN BILINCLI PAZARLAMA GIDERIDIR: depo public, bu soru
#  herkese acilir. Yilda ~365 soru = kasanin %1,3'u. Karsiliginda her gun
#  organik erisim. Toplu sizinti DEGIL - tek soru, kayitli, geri izlenebilir.
# ============================================================================
param([switch]$yaz)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# sb_secret anahtar "tarayici" User-Agent'iyla reddedilir (02.08 dersi)
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB   = "https://bjrleanjpyujtajmazxn.supabase.co"
$ciktiYol  = Join-Path $kok 'veri/gunun-tuzagi.json'
$gecmisYol = Join-Path $kok 'veri/tuzak-gecmisi.json'

trap {
  $g = ""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g = $_.ErrorDetails.Message }
  [IO.File]::WriteAllText($ciktiYol, (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber
  }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("HATA (satir {0}): {1} | {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g)
  exit 1
}

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - atlandi."; exit 0 }
$H = @{ apikey = $KEY }
if($KEY -like 'eyJ*'){ $H.Authorization = "Bearer $KEY" }

# Bos [] icin $null donebilir; @() ile dizi-icinde-dizi olusabilir (02.08 dersi)
function Getir([string]$uri){
  $r = Invoke-RestMethod -Uri $uri -Headers $H -TimeoutSec 90
  return @($r | Where-Object { $null -ne $_ })
}

# --- gecmis: daha once paylasilan kimlikler ---
$gecmis = @()
if(Test-Path $gecmisYol){
  try { $gecmis = @((Get-Content $gecmisYol -Raw -Encoding UTF8 | ConvertFrom-Json).paylasilan) } catch { $gecmis = @() }
}
$gecmisKume = @{}; foreach($g in $gecmis){ if($g){ $gecmisKume["$g"] = $true } }
Write-Host ("Gecmiste paylasilan: {0}" -f $gecmisKume.Count)

# --- aday havuzu: yayinda + alanlari tam ---
# order= SART (PostgREST sayfalamasinda order yoksa satirlar tekrarlanir/atlanir - 27.07 dersi)
$adaylar = @()
for($ofs = 0; $ofs -lt 4000; $ofs += 1000){
  $parca = Getir ("{0}/rest/v1/soru_havuzu?select=id,sinav,ders,konu,soru,siklar,dogru,aciklama,kaynak&yayin=eq.true&order=id&limit=1000&offset={1}" -f $SB, $ofs)
  if($parca.Count -eq 0){ break }
  $adaylar += $parca
  if($parca.Count -lt 1000){ break }
}
Write-Host ("Yayindaki soru (taranan): {0}" -f $adaylar.Count)

# 02.08 GERCEK: kasada su an YAYINDA soru YOK - 466'si bugun onarim icin cekildi,
# gerisini hakem kapisi tutuyor. Vitrin bankasi (veri/soru-bankasi.json) ise ZATEN
# herkese acik ve onayli. Kasa bosken oradan secmek hem dogru hem guvenli:
# zaten yayinda olan bir soruyu paylasmis oluruz, yeni sizinti yaratmayiz.
if($adaylar.Count -eq 0){
  $vitrinYol = Join-Path $kok 'veri/soru-bankasi.json'
  if(Test-Path $vitrinYol){
    $vb = Get-Content $vitrinYol -Raw -Encoding UTF8 | ConvertFrom-Json
    $adaylar = @($vb.sorular | Where-Object { "$($_.durum)" -eq 'yayin' -or -not $_.durum })
    Write-Host ("Kasada yayinda soru yok -> VITRIN BANKASINA dusuldu: {0} soru" -f $adaylar.Count)
    $kaynakEtiket = 'vitrin-bankasi'
  }
} else { $kaynakEtiket = 'kasa' }

$uygun = @($adaylar | Where-Object {
  $s = $_
  $s.soru -and $s.dogru -and $s.kaynak -and $s.siklar -and $s.aciklama -and
  ("$($s.soru)".Length -ge 60) -and
  ("$($s.kaynak)".Length -ge 6) -and
  # aciklama zengin olsun: paylasimda ogretecegimiz sey bu
  (($s.aciklama | ConvertTo-Json -Compress -Depth 3).Length -ge 300) -and
  (-not $gecmisKume["$($s.id)"])
})
Write-Host ("Uygun aday (tam + daha once paylasilmamis): {0}" -f $uygun.Count)

if($uygun.Count -eq 0){
  [IO.File]::WriteAllText($ciktiYol, (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='ADAY YOK'
    not='Yayinda, alanlari tam ve daha once paylasilmamis soru bulunamadi.'
    taranan=$adaylar.Count; gecmis=$gecmisKume.Count
  }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
  Write-Host "Uygun aday yok - rapor yazildi."; exit 0
}

# --- deterministik secim: gunun tarihinden tohum (ayni gun ayni soru) ---
$tohumMetin = (Get-Date -Format 'yyyy-MM-dd')
$tohum = 0
foreach($ch in $tohumMetin.ToCharArray()){ $tohum = ($tohum * 31 + [int]$ch) % 100000 }
$secim = $uygun[$tohum % $uygun.Count]
Write-Host ("Secilen: {0} | {1} / {2}" -f $secim.id, $secim.ders, $secim.kaynak)

# --- paylasim metni (Instagram/X icin hazir) ---
$dersAd = "$($secim.ders)"
$paylasimBaslik = "Günün Tuzağı"
$paylasimAlt = if($dersAd){ "$dersAd — bu soruda iki şık doğru gibi görünüyor." } else { "Bu soruda iki şık doğru gibi görünüyor." }
$paylasimKapanis = "Cevap ve hangi kanun maddesinden geldiği: tetikte.com/tuzak.html`n`nHer sorunun dayanağı yazılıdır. #SMMM #stajagiris #malimüşavir"

$rapor = [ordered]@{
  tarih       = (Get-Date -Format 'dd.MM.yyyy')
  gun         = $tohumMetin
  durum       = 'TAMAM'
  id          = "$($secim.id)"
  sinav       = "$($secim.sinav)"
  ders        = $dersAd
  konu        = "$($secim.konu)"
  soru        = "$($secim.soru)"
  siklar      = $secim.siklar
  dogru       = "$($secim.dogru)"
  aciklama    = $secim.aciklama
  kaynak      = "$($secim.kaynak)"
  paylasim    = [ordered]@{ baslik=$paylasimBaslik; alt=$paylasimAlt; kapanis=$paylasimKapanis }
  havuz       = [ordered]@{ kaynak=$kaynakEtiket; uygun_aday=$uygun.Count; yayindaki=$adaylar.Count; gecmiste=$gecmisKume.Count }
}
[IO.File]::WriteAllText($ciktiYol, (ConvertTo-Json -InputObject $rapor -Depth 6), (New-Object Text.UTF8Encoding($false)))

if($yaz){
  $yeniGecmis = @($gecmis) + @("$($secim.id)")
  [IO.File]::WriteAllText($gecmisYol, (ConvertTo-Json -InputObject ([ordered]@{
    aciklama='Gunun Tuzagi olarak paylasilmis soru kimlikleri - ayni soru iki kez paylasilmaz.'
    guncelleme=(Get-Date -Format 'dd.MM.yyyy HH:mm'); paylasilan=$yeniGecmis
  }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("Gecmise islendi. Toplam paylasilan: {0}" -f $yeniGecmis.Count)
} else {
  Write-Host "OLCUM modu - gecmise islenmedi (-yaz ile calistir)."
}
Write-Host "TAMAM: veri/gunun-tuzagi.json yazildi."
