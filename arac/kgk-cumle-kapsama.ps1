# ============================================================================
#  KGK STANDART — CÜMLE KAPSAMASI ÖLÇÜMÜ   16.09.2026
#  Cem "1.2.3 üçünü de yap" (GM önerisi 2).
#
#  NEDEN VAR: arac/kgk-hakikat-olcumu.ps1 yalnız paragraf NUMARALARINI kıyaslar. "EKSİK" çıkan standardı
#  "metin komşu parçada, yalnız etiket eksik" diye yorumlamıştık (15.09, 134/137 örneklem). 16.09'da iki
#  vaka bunu çürüttü: KYS 1 ambarda ESKİ SÜRÜMdü (resmî 1.055 cümlenin 260'ı yok), Etik Kurallar'ın
#  ~%36'sı hiç yoktu. Numara ölçüsü metnin kendisini görmez.
#
#  NE ÖLÇER: resmî PDF (hakikat ölçümüyle aynı adres) -> pdftotext -layout -> cümleler (≥50 kr, içindekiler
#  dolgusu hariç) -> her cümlenin HARF-yalnız 40 karakterlik başı ambardaki standart metninde (yalnız harfler,
#  küçük) geçiyor mu. Rakamlar atılır: layout'ta paragraf numarası cümlenin başına yapışır, ambarda yapışmaz.
#  Ambar kümesi = standart-yut süzgeciyle aynı: ad = "<std>" ya da "<std> *", "<std> Degisiklikleri*" hariç.
#
#  GÜRÜLTÜ TABANI (16.09 kalibrasyon, hakikatte TAM 8 standart: KYS 1, TMS 2/16/40, TFRS 16, BDS 200, TSRS 1, ETIK):
#  %0,2–%1,6. Sınıf eşiği %5:
#    METİN TAM   : bulunamayan cümle ≤ %5  -> hakikat EKSİK'i etiket sorunudur
#    METİN EKSİK : bulunamayan cümle > %5  -> resmî metinden yeniden yutulmalı (önce kuru prova + kapsama)
#  İlk ölçüm 16.09: hakikatte EKSİK 17 standardın 16'sı METİN TAM; tek METİN EKSİK TFRS 18 (ambarda yalnız özet).
#
#  Yazma yok (ambar), model yok, bedel 0. Çıktı: veri/kgk-cumle-kapsama.json (RaporYaz; -Yalniz verilince yazmaz).
#  Kullanım: powershell -NoProfile -Command "& .\arac\kgk-cumle-kapsama.ps1 [-Yalniz 'TFRS 9','TMS 36']"
#            (varsayılan: hakikat ölçümünde adresi olan TÜM standartlar)
# ============================================================================
param([string[]]$Yalniz = @())
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'rapor-yaz.ps1')
$pdftotext = @(
  'C:\Users\cemdi\AppData\Local\Microsoft\WinGet\Packages\oschwartz10612.Poppler_Microsoft.Winget.Source_8wekyb3d8bbwe\poppler-25.07.0\Library\bin\pdftotext.exe'
  (Get-Command pdftotext -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if(-not $pdftotext){ Write-Host 'pdftotext bulunamadı'; exit 1 }
$anahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'); if(-not $anahtar){ $anahtar = $env:SUPABASE_SERVICE_KEY }
if(-not $anahtar){ Write-Host 'SUPABASE_SERVICE_KEY yok'; exit 1 }
$basliklar = @{ apikey=$anahtar; Authorization="Bearer $anahtar"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$ambarUcu = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$gecici = Join-Path ([IO.Path]::GetTempPath()) 'kgk-kapsama'; New-Item -ItemType Directory -Force $gecici | Out-Null

$hakikat = Get-Content (Join-Path $depoKok 'veri\kgk-hakikat-olcumu.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$adresler = @{}; foreach($hs in $hakikat.standartlar){ $adresler["$($hs.standart)"] = "$($hs.adres)" }
# 16.09 akşam: hakikat 89/89 TAM olunca 'yalnız EKSİK' listesi boş kaldı ve rapor boşaldı → varsayılan: adresi olan TÜM standartlar
$liste = if($Yalniz.Count){ $Yalniz } else { @($hakikat.standartlar | Where-Object { "$($_.adres)" } | ForEach-Object { "$($_.standart)" }) }

# 16.09 kalibrasyon (TMS 2/16, TSRS 1 hakikatte TAM ama %15-23 'yok' çıktı): layout metninde cümlenin BAŞINA bölüm başlığı ve sayfa üst bilgisi
# ('Kapsam 2 Bu Standart…', '2 TMS 2 14 Üretim…') yapışıyor. Çare: (a) standart kısaltması iki taraftan da atılır, (b) cümle başı YA DA sonu (40 harf) bulunursa var sayılır.
function HarfYalniz([string]$metin){ return (((($metin -replace '[^\p{L}]+',' ') -replace '(?i)\b(tms|tfrs|bds|gds|tsrs|kys|sbds|ihs)\b',' ') -replace '\s+',' ').Trim().ToLowerInvariant()) }

function AmbarMetni([string]$std){
  if($std -eq 'ETIK'){ $suzgec = 'kaynak_ad=like.' + [uri]::EscapeDataString('Etik Kurallar*') }
  else {
    $suzgec = 'or=(kaynak_ad.eq.' + [uri]::EscapeDataString($std) + ',kaynak_ad.like.' + [uri]::EscapeDataString("$std *") + ')' +
              '&kaynak_ad=not.like.' + [uri]::EscapeDataString("$std Degisiklikleri*") + '&kaynak_ad=not.like.' + [uri]::EscapeDataString("$std Değişiklikleri*")
  }
  $parcalar = New-Object System.Collections.Generic.List[string]; $atla = 0
  do {
    $sayfaSayisi = 0
    foreach($kayit in (Invoke-RestMethod -Uri "$ambarUcu`?select=metin&$suzgec&order=id&limit=1000&offset=$atla" -Headers $basliklar -TimeoutSec 240)){ $parcalar.Add("$($kayit.metin)"); $sayfaSayisi++ }
    $atla += 1000
  } while($sayfaSayisi -eq 1000)
  return [pscustomobject]@{ parca=$parcalar.Count; karakter=(($parcalar | ForEach-Object { $_.Length }) | Measure-Object -Sum).Sum; metin=($parcalar -join ' ') }
}

$satirlar = New-Object System.Collections.Generic.List[object]
foreach($std in $liste){
  $kayit = [ordered]@{ standart=$std; adres=''; durum=''; resmi_cumle=0; bulunamayan=0; bulunamayan_kr=0; oran=0; ambar_parca=0; ambar_kr=0; ornek=@() }
  $adres = if($adresler.ContainsKey($std)){ $adresler[$std] } else { '' }
  $kayit.adres = $adres
  if(-not $adres){ $kayit.durum='ADRES YOK'; $satirlar.Add([pscustomobject]$kayit); continue }
  $pdf = Join-Path $gecici (($std -replace '[^A-Za-z0-9]','_') + '.pdf'); $txt = [IO.Path]::ChangeExtension($pdf,'.txt')
  try {
    $yanit = Invoke-WebRequest -UseBasicParsing -Uri $adres -TimeoutSec 180
    $bayt = $yanit.RawContentStream.ToArray(); [IO.File]::WriteAllBytes($pdf,$bayt)
    if([Text.Encoding]::ASCII.GetString($bayt,0,[Math]::Min(4,$bayt.Length)) -ne '%PDF'){ $kayit.durum='PDF DEĞİL'; $satirlar.Add([pscustomobject]$kayit); continue }
  } catch { $kayit.durum = "İNDİRME HATASI: $($_.Exception.Message)"; $satirlar.Add([pscustomobject]$kayit); continue }
  & $pdftotext -enc UTF-8 -nopgbrk -layout $pdf $txt 2>$null | Out-Null
  $resmi = [IO.File]::ReadAllText($txt,[Text.Encoding]::UTF8)
  $ambar = AmbarMetni $std
  $ambarHarf = HarfYalniz $ambar.metin
  $cumleler = @([regex]::Split(($resmi -replace '\s+',' '),'(?<=[.:;])\s+') | Where-Object { $_.Length -ge 50 -and $_ -notmatch '\.{5,}' })
  $yok = New-Object System.Collections.Generic.List[string]
  foreach($cumle in $cumleler){
    $harf = HarfYalniz $cumle
    if($harf.Length -lt 25){ continue }
    $bas = $harf.Substring(0,[Math]::Min(40,$harf.Length)); $son = $harf.Substring([Math]::Max(0,$harf.Length-40))
    if(-not $ambarHarf.Contains($bas) -and -not $ambarHarf.Contains($son)){ $yok.Add($cumle) }
  }
  $kayit.resmi_cumle = $cumleler.Count; $kayit.bulunamayan = $yok.Count
  $kayit.bulunamayan_kr = (($yok | ForEach-Object { $_.Length }) | Measure-Object -Sum).Sum
  $kayit.oran = if($cumleler.Count){ [math]::Round(100.0*$yok.Count/$cumleler.Count,1) } else { 0 }
  $kayit.ambar_parca = $ambar.parca; $kayit.ambar_kr = $ambar.karakter
  $kayit.ornek = @($yok | Select-Object -First 5 | ForEach-Object { $_.Substring(0,[Math]::Min(140,$_.Length)) })
  $kayit.durum = if($cumleler.Count -lt 20){ 'ÖLÇÜLEMEDİ' } elseif($kayit.oran -le 5){ 'METİN TAM' } else { 'METİN EKSİK' }
  $satirlar.Add([pscustomobject]$kayit)
  Write-Host ("{0,-9} resmî cümle {1,5} · ambarda yok {2,4} (%{3,5}) · {4,7} kr · ambar {5,4} parça/{6,8} kr · {7}" -f $std,$kayit.resmi_cumle,$kayit.bulunamayan,$kayit.oran,$kayit.bulunamayan_kr,$kayit.ambar_parca,$kayit.ambar_kr,$kayit.durum)
  Start-Sleep -Milliseconds 400
}
$sonuc = [ordered]@{
  olcum = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  kural = 'Resmî PDF cümlesinin (≥50 kr) harf-yalnız ilk VE son 40 karakterinin ikisi de ambardaki standart metninde yoksa "bulunamadı". METİN TAM ≤%5 (gürültü tabanı %0,2–1,6, 8 TAM standartta ölçüldü) · METİN EKSİK >%5.'
  ozet = [ordered]@{ olculen=@($satirlar | Where-Object { $_.durum -like 'METİN*' }).Count; TAM=@($satirlar | Where-Object durum -eq 'METİN TAM').Count; EKSIK=@($satirlar | Where-Object durum -eq 'METİN EKSİK').Count }
  standartlar = $satirlar.ToArray()
}
if(-not $Yalniz.Count){ [void](RaporYaz -Hedef (Join-Path $depoKok 'veri\kgk-cumle-kapsama.json') -Nesne $sonuc -Sessiz) }
"ÖZET: ölçülen {0} · METİN TAM {1} · METİN EKSİK {2}" -f $sonuc.ozet.olculen,$sonuc.ozet.TAM,$sonuc.ozet.EKSIK
