# ============================================================================
#  DEV PARCA BOLUCU — ambardaki buyuk satirlari YERINDE diliмler
#
#  NEDEN VAR (10.09.2026). Ambardaki dev satirlar aramada MIKNATIS gibi
#  calisiyor: cok kelime icerdikleri icin alakasiz sorgularda `kapsanan`
#  bonusunu topluyorlar ve kucuk, DOGRU maddeyi geciyorlar. Olculdu: tek satir
#  (146.979 karakter) 278 konunun 110'una cevap oluyordu.
#
#  SPK icin cozum kaynaktan yeniden yutmakti (PDF'ler diskte). AMA STANDART
#  (BOBI FRS, GDS, BDS), BDDK ve digerlerinin kaynak dosyalari YEREL DEGIL -
#  yeniden indirmeden yutulamiyorlar. Bu arac o bosluğu kapatir: metni
#  AMBARDAN okur, diliмler, yazar, eskisini siler. Kaynak dosyasi gerekmez.
#
#  KAYIP YOK: metin oldugu gibi tasinir, yalniz cumle sinirindan bolunur.
#  Dilimlerin toplam uzunlugu ile aslin uzunlugu KIYASLANIR; sapma varsa
#  satir ATLANIR ve raporlanir (02.08 dersi: her dilim sinirinda birkac
#  karakter kirpmak 30 dilimde birikip kapsamayi %92'ye dusurur).
#
#  ADLANDIRMA: "<ad> [n/m]". Zaten "[a/b]" ekiyle biten satirlar ATLANIR -
#  cunku "X [1/3]" ve "X [2/3]" ikisi de bolunse ayni yeni ada ("X [1/2]")
#  cikip CAKISIRDI. O satirlar kaynaktan yeniden yutularak duzeltilir.
#
#  YEDEK: silmeden once orijinaller C:\TETIKTE-YEDEK\ambar\ altina yazilir.
#
#  KOSMA: powershell -NoProfile -File arac/dev-parca-bol.ps1            (PROVA)
#         powershell -NoProfile -File arac/dev-parca-bol.ps1 -Yaz
#         powershell -NoProfile -File arac/dev-parca-bol.ps1 -Yaz -Esik 1800
# ============================================================================
param(
  [switch]$Yaz,
  [int]$Esik = 1800,     # ambarin standart parca boyu (mevzuat-yut/standart-yut/kgk-standart-yut hepsi 1800)
  [int]$Sayfa = 100
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$SB  = 'https://bjrleanjpyujtajmazxn.supabase.co'
$OKU = if($env:SB_PUBLISHABLE){ $env:SB_PUBLISHABLE } else { 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' }
$YAZ = $env:SUPABASE_SERVICE_KEY
if($Yaz -and -not $YAZ){ Write-Host 'KOR: SUPABASE_SERVICE_KEY yok - yazilamaz.' -ForegroundColor Red; exit 3 }
$HO = @{ apikey=$OKU; Authorization="Bearer $OKU" }
$HY = @{ apikey=$YAZ; Authorization="Bearer $YAZ" }

function Getir([string]$yol){
  foreach($d in 1..4){
    try { $r = Invoke-WebRequest -Uri ($SB+$yol) -Headers $HO -UseBasicParsing -UserAgent 'mevzuat-radar-robot/1.0' -TimeoutSec 180
          return ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json) }
    catch { if($d -eq 4){ throw "GET $yol : $($_.Exception.Message)" }; Start-Sleep -Seconds (2*$d) }
  }
}

# --- dilimleyici: kgk-standart-yut.ps1'deki ile AYNI davranis --------------
# Trim() YOK: her dilim sinirinda karakter kirpmak 30 dilimde birikir.
function Dilimle([string]$govde,[int]$boy){
  $liste = New-Object System.Collections.Generic.List[string]
  $kalan = $govde
  while($kalan.Length -gt $boy){
    $kes = $kalan.Substring(0,$boy)
    $kir = $kes.LastIndexOf('. ')
    if($kir -lt [int]($boy/2)){ $kir = $kes.LastIndexOf(' ') }
    if($kir -lt [int]($boy/2)){ $kir = $boy - 1 }
    $liste.Add($kalan.Substring(0,$kir+1))
    $kalan = $kalan.Substring($kir+1)
  }
  if($kalan.Length -gt 0){ $liste.Add($kalan) }
  return $liste
}

# --- 1) ambari tara, DEV satirlari topla ----------------------------------
Write-Host ("Ambar taraniyor (esik {0:N0} karakter)..." -f $Esik)
$dev = New-Object System.Collections.ArrayList
$eklisi = New-Object System.Collections.ArrayList   # zaten [n/m] ekli olanlar
$sonId=''; $bakilan=0
while($true){
  $yol = "/rest/v1/dokumanlar?select=id,tur,kaynak_ad,baslik,metin,kaynak_url,belge_tarihi&order=id&limit=$Sayfa"
  if($sonId){ $yol += "&id=gt.$sonId" }
  $s = @(Getir $yol | ForEach-Object { $_ })
  if($s.Count -eq 0){ break }
  foreach($x in $s){
    $bakilan++
    if("$($x.tur)" -like 'cikmis*'){ continue }          # madde_ara zaten eliyor
    $uz = "$($x.metin)".Length
    if($uz -le $Esik){ continue }
    if("$($x.kaynak_ad)" -match '\[\d+/\d+\]\s*$'){ [void]$eklisi.Add($x); continue }
    [void]$dev.Add($x)
  }
  $sonId = "$($s[$s.Count-1].id)"
  if($bakilan % 5000 -lt $Sayfa){ Write-Host ("  {0:N0} satir bakildi · dev {1}" -f $bakilan,$dev.Count) }
  Start-Sleep -Milliseconds 120
}
Write-Host ("Tarandi: {0:N0} satir · BOLUNECEK {1} · zaten [n/m] ekli (atlanan) {2}" -f $bakilan,$dev.Count,$eklisi.Count)
if($eklisi.Count -gt 0){
  Write-Host '  ATLANANLAR (kaynaktan yeniden yutulmali):' -ForegroundColor Yellow
  $eklisi | Select-Object -First 5 | ForEach-Object { Write-Host ("     {0,8:N0} krk  {1}" -f "$($_.metin)".Length, "$($_.kaynak_ad)") }
}
if($dev.Count -eq 0){ Write-Host 'Bolunecek satir yok.'; exit 0 }

# --- 2) plani cikar, KAYIP KONTROLU yap -----------------------------------
$plan = New-Object System.Collections.ArrayList
$sapan = New-Object System.Collections.ArrayList
foreach($x in $dev){
  $asil = "$($x.metin)"
  $dilimler = @(Dilimle $asil $Esik)
  $toplam = ($dilimler -join '').Length
  if($toplam -ne $asil.Length){ [void]$sapan.Add([pscustomobject]@{ ad="$($x.kaynak_ad)"; asil=$asil.Length; dilim=$toplam }); continue }
  [void]$plan.Add([pscustomobject]@{ satir=$x; dilimler=$dilimler })
}
Write-Host ''
Write-Host ("PLAN: {0} satir -> {1} dilim" -f $plan.Count, (($plan | ForEach-Object { $_.dilimler.Count } | Measure-Object -Sum).Sum))
$plan | Sort-Object { -("$($_.satir.metin)".Length) } | Select-Object -First 10 | ForEach-Object {
  Write-Host ("  {0,8:N0} krk -> {1,3} dilim  {2}" -f "$($_.satir.metin)".Length, $_.dilimler.Count, ("$($_.satir.kaynak_ad)".Substring(0,[Math]::Min(64,"$($_.satir.kaynak_ad)".Length))))
}
if($sapan.Count -gt 0){
  Write-Host ("  UYARI: {0} satirda dilim toplami asilla TUTMADI - ATLANDI (kayip riski)" -f $sapan.Count) -ForegroundColor Red
  $sapan | Select-Object -First 3 | ForEach-Object { Write-Host ("     {0}: asil {1} dilim {2}" -f $_.ad,$_.asil,$_.dilim) }
}

if(-not $Yaz){ Write-Host ''; Write-Host 'PROVA - ambara dokunulmadi. Yazmak icin: -Yaz' -ForegroundColor Yellow; exit 0 }

# --- 3) YEDEK (silmeden once) ---------------------------------------------
$yedekDir='C:\TETIKTE-YEDEK\ambar'; New-Item -ItemType Directory -Force -Path $yedekDir | Out-Null
$yedek = Join-Path $yedekDir ('dev-parca-bolunmeden-once-' + (Get-Date -Format 'yyyyMMdd-HHmm') + '.json')
@($plan | ForEach-Object { $_.satir }) | ConvertTo-Json -Depth 6 | Set-Content $yedek -Encoding UTF8
Write-Host ("YEDEK: {0} satir -> {1}" -f $plan.Count, (Split-Path $yedek -Leaf))

# --- 4) YAZ, sonra SIL (bosluk birakmamak icin bu sirayla) ----------------
$yazilan=0; $silinen=0; $hata=0
foreach($p in $plan){
  $x=$p.satir; $n=$p.dilimler.Count
  $yeni = @()
  for($i=0;$i -lt $n;$i++){
    $yeni += [ordered]@{
      tur          = "$($x.tur)"
      kaynak_ad    = ("{0} [{1}/{2}]" -f "$($x.kaynak_ad)", ($i+1), $n)
      baslik       = "$($x.baslik)"
      metin        = $p.dilimler[$i]
      kaynak_url   = "$($x.kaynak_url)"
      belge_tarihi = "$($x.belge_tarihi)"
    }
  }
  try {
    $bj = ($yeni | ConvertTo-Json -Depth 5); if($n -eq 1){ $bj = "[$bj]" }
    Invoke-RestMethod -Method Post -Uri "$SB/rest/v1/dokumanlar" -Headers ($HY + @{ Prefer='return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($bj)) -TimeoutSec 180 | Out-Null
    $yazilan += $n
    # Asil satir ANCAK dilimler yazildiktan sonra silinir.
    Invoke-RestMethod -Method Delete -Uri "$SB/rest/v1/dokumanlar?id=eq.$($x.id)" -Headers $HY -TimeoutSec 120 | Out-Null
    $silinen++
  } catch {
    $hata++
    Write-Host ("  KIRMIZI: {0} · {1}" -f "$($x.kaynak_ad)", $_.Exception.Message) -ForegroundColor Red
  }
  Start-Sleep -Milliseconds 150
}

Write-Host ''
Write-Host ("BITTI: {0} dilim yazildi · {1} asil satir silindi · {2} hata" -f $yazilan,$silinen,$hata)
if($hata -gt 0){ Write-Host 'Hatali satirlarin ASLI DURUYOR - veri kaybi yok, tekrar kosulabilir.' -ForegroundColor Yellow; exit 1 }
