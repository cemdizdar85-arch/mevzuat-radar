# ============================================================================
#  RG NOBETI — KATMAN 3'UN SON HALKASI   29.07.2026   (PARA HARCAMAZ)
#
#  ZINCIR SU ANA KADAR SOYLEYDI:
#    madde-damga.ps1  -> hangi maddenin metni degisti, biliyor
#    kasa-bag.ps1     -> hangi sorunun hangi maddeye dayandigi, biliyor (4.101)
#    yayin kapisi     -> bir soruyu silmeden durdurabiliyor
#  Ama ARALARINDA BAG YOKTU. Uc parca da calisiyordu, zincir calismiyordu.
#  Bu betik o halkayi kapatiyor.
#
#  NE YAPAR: veri/madde-degisim.json'daki DEGISEN maddeleri alir, kasada o
#  maddeye dayanan sorulari bulur ve YAYINDAN CEKER (silmez). Sebebi
#  yayin_notu'na yazar: hangi madde, ne zaman degisti.
#
#  NIYE OTOMATIK CEKIYORUZ: madde degisince soru MUTLAKA yanlis olmaz - ama
#  DOGRU OLDUGU DA BILINMEZ. Bilinmeyen soru ogrenciye gitmemeli. Cekmek geri
#  alinabilir; yanlis ogretmek alinamaz. Bugun bulunan uc gercek hatanin ucu de
#  (SGK prim orani, AATUHK suresi, 3568 suresi) tam bu tipti: soru YAZILDIGI GUN
#  DOGRUYDU.
#
#  KACAK KAPANI: bir kanun toptan degisirse yuzlerce soru birden dusebilir ve
#  havuz bir gecede bosalir. O yuzden esik var: cekilecek soru sayisi esigi
#  asarsa HICBIRI CEKILMEZ, alarm verilir, insan bakar. Sessizce havuzu
#  bosaltmaktansa gurultuyle durmak iyidir.
# ============================================================================
param(
  [switch]$uygula,          # gercekten yayindan cek (varsayilan: yalniz olcum)
  [int]$esik = 250          # bundan fazla soru dusecekse DURDUR
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - RG nobeti atlandi."; exit 0 }
$H  = @{ apikey=$KEY; Authorization="Bearer $KEY" }
$HW = $H + @{ Prefer="return=minimal" }

$degYol = Join-Path $kok "veri/madde-degisim.json"
if(-not (Test-Path $degYol)){ Write-Host "madde-degisim.json yok - once madde-damga.ps1 kosmali."; exit 0 }
$deg = Get-Content $degYol -Raw -Encoding UTF8 | ConvertFrom-Json
if($deg.ilk_kurulum){ Write-Host "Damga ILK KURULUM raporu - karsilastirilacak onceki hal yok, nobet atlandi."; exit 0 }
$degisen = @($deg.degisen)
Write-Host ("DEGISEN MADDE: {0}" -f $degisen.Count)
if($degisen.Count -eq 0){ Write-Host "Degisen madde yok - yapilacak is yok."; exit 0 }

# --- degisen maddelere dayanan sorulari bul
# Anahtar bicimi: "<kanun>|<seri><madde>"  ornek "213|234", "2709|gec1"
$hedef = New-Object System.Collections.Generic.List[object]
foreach($d in $degisen){
  $par = "$($d.anahtar)" -split '\|'
  if($par.Count -lt 2){ continue }
  $kn = $par[0]; $mn = $par[1]
  # 'ad|...' anahtarli kayitlar (teblig/standart/rehber) kanun-madde degil; onlar
  # bu yoldan baglanmamis, dolayisiyla cekilecek soru da yok.
  if($kn -eq 'ad'){ continue }
  $u = "$SB_URL/rest/v1/soru_havuzu?select=id,ders,konu,yayin&kanun_no=eq." + [uri]::EscapeDataString($kn) + "&madde_no=eq." + [uri]::EscapeDataString($mn)
  try { $r = @(Invoke-RestMethod -Uri $u -Headers $H -TimeoutSec 60) } catch { Write-Host ("  sorgu hatasi {0}: {1}" -f $d.anahtar, $_.Exception.Message); continue }
  foreach($s in $r){
    if("$($s.yayin)" -eq 'False' -or $s.yayin -eq $false){ continue }   # zaten cekili
    $hedef.Add([pscustomobject]@{ id="$($s.id)"; ders="$($s.ders)"; konu="$($s.konu)"; anahtar="$($d.anahtar)"; ad="$($d.ad)" })
  }
}
Write-Host ("ETKILENEN YAYINDAKI SORU: {0}" -f $hedef.Count)
foreach($g in ($hedef | Group-Object anahtar | Sort-Object Count -Descending | Select-Object -First 15)){
  Write-Host ("   {0,4} soru <- {1}" -f $g.Count, $g.Name)
}

$rapYol = Join-Path $kok "veri/rg-nobeti.json"
function Rapor($durum, $mesaj){
  [IO.File]::WriteAllText($rapYol, ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$durum; mesaj=$mesaj
    degisen_madde=$degisen.Count; etkilenen_soru=$hedef.Count; esik=$esik
    ornekler=@($hedef | Select-Object -First 40)
  } | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
  Write-Host "-> veri/rg-nobeti.json"
}

if($hedef.Count -eq 0){ Rapor 'temiz' 'Degisen maddelere dayanan yayindaki soru yok.'; exit 0 }

# --- KACAK KAPANI
if($hedef.Count -gt $esik){
  Write-Host ""
  Write-Host ("KIRMIZI: {0} soru dusecekti, esik {1}. HICBIRI CEKILMEDI." -f $hedef.Count, $esik)
  Write-Host "Bu kadar sorunun birden dusmesi ya buyuk bir mevzuat degisikligi ya da"
  Write-Host "bizim tarafimizda bir hata demektir (ornegin hasat bozuk metin yutmus)."
  Write-Host "Havuzu sessizce bosaltmaktansa gurultuyle duruyoruz - insan baksin."
  Rapor 'esik-asildi' "Etkilenen soru sayisi esigi asti; cekme YAPILMADI."
  exit 2
}

if(-not $uygula){ Rapor 'olcum' 'Olcum modu - hicbir soru cekilmedi.'; Write-Host "OLCUM MODU - cekmek icin -uygula."; exit 0 }

# --- yayindan cek
$zaman = (Get-Date -Format 'dd.MM.yyyy HH:mm')
$cekilen = 0; $hata = 0
foreach($t in $hedef){
  $not = "RG NOBETI $zaman - dayandigi madde DEGISTI ($($t.ad)). Soru yanlis olmak zorunda degil ama dogru oldugu da bilinmiyor; GM okuyup guncelleyene kadar yayindan cekildi."
  $govde = @{ yayin=$false; yayin_notu=$not } | ConvertTo-Json -Compress
  try {
    Invoke-RestMethod -Method Patch -Uri "$SB_URL/rest/v1/soru_havuzu?id=eq.$($t.id)" -Headers $HW `
      -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 60 | Out-Null
    $cekilen++
  } catch { $hata++ }
}
Write-Host ("CEKILEN: {0}   hata: {1}" -f $cekilen, $hata)

# --- MUTABAKAT: gercekten cekildi mi
$kalan = 0
foreach($t in $hedef){
  try { $r = @(Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=yayin&id=eq.$($t.id)" -Headers $H -TimeoutSec 30)
    if($r.Count -and ($r[0].yayin -eq $true)){ $kalan++ } } catch {}
}
Write-Host ("MUTABAKAT: hala yayinda kalan {0} (0 olmali)" -f $kalan)
Rapor $(if($kalan -eq 0){'uygulandi'}else{'eksik'}) "Cekilen $cekilen, hata $hata, hala yayinda $kalan."
if($kalan -gt 0){ exit 1 }
exit 0
