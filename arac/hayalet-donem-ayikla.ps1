# ============================================================================
#  HAYALET DONEM AYIKLAYICI  - 13.09.2026   (BEDAVA: API yok, yalniz ilk bayt)
#
#  NEDEN: veri/smmm-analiz.json'da SMMM 2026/3 icin 8 ders "tamam, 20'ser soru"
#  duruyordu. 2026/3 sinavi yok: TESMER adresi 200+HTML donuyor. 28.07'de o 8
#  adrese 2026/2 Sermaye Piyasasi kitapcigi okunmus, Finansal Muhasebe'ye
#  "genel kurul cagri suresi, izahname sorumlulugu" konulari yazilmis.
#  Kapi motor/sinav-analiz.ps1'e eklendi (KAPI 0); bu arac AYNI kapiyi eldeki
#  veriye uygular - "kapi eklendiyse veri tazelenir" kurali.
#
#  Her analiz kaydi (sgs-analiz + smmm-analiz) icin:
#    1) kaynak PDF diskte mi (veri/{sgs,smmm}-arsiv/pdf)? -> imza + SHA256
#    2) diskte yoksa kaynak adresin ilk 8 bayti okunur -> '%PDF' mi?
#    3) HAYALET  = PDF degil
#       MUKERRER = ayni SHA256 baska (donem|ders) kaydinda da var
#  -Uygula yoksa KURU: yalniz rapor. -Uygula: hayalet/mukerrer kayit analizden
#  cikar, sinav-arsiv.json satiri durum='hayalet' olur, saglam kayda
#  pdfSha256 yazilir (analiz robotu yeni kitapcigi bununla kiyaslar).
#  ESDEGERLIK PROVASI: kalan her kaydin pdfSha256 disindaki alanlari
#  oncekiyle birebir kiyaslanir; tek fark varsa YAZMAZ.
# ============================================================================
param([switch]$Uygula)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot

function IlkBaytUzak([string]$adres){
  try {
    $istek = [System.Net.HttpWebRequest]::Create($adres)
    $istek.UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
    $istek.Timeout = 30000
    $istek.AddRange(0, 7)
    $yanit = $istek.GetResponse()
    $akis = $yanit.GetResponseStream()
    $tampon = New-Object byte[] 8
    $okunan = 0
    while($okunan -lt 8){ $n = $akis.Read($tampon, $okunan, 8 - $okunan); if($n -le 0){ break }; $okunan += $n }
    $turu = "$($yanit.ContentType)"
    $yanit.Close()
    return @{ imza = [Text.Encoding]::ASCII.GetString($tampon, 0, [Math]::Min(4, $okunan)); tur = $turu; hata = '' }
  } catch { return @{ imza = ''; tur = ''; hata = "$($_.Exception.Message)" } }
}

function YerelPdf([string]$sinavAdi, [string]$adres){
  $dosyaAdi = [IO.Path]::GetFileName(([Uri]$adres).AbsolutePath)
  if($sinavAdi -eq 'SMMM'){ $aday = Join-Path $depoKok ("veri\smmm-arsiv\pdf\" + $dosyaAdi) }
  else { $aday = Join-Path $depoKok ("veri\sgs-arsiv\pdf\" + ($dosyaAdi -replace '_grubu', '')) }
  if(Test-Path $aday){ return $aday }
  return $null
}

$kaynaklar = @(
  @{ sinav = 'SGS';  yol = (Join-Path $depoKok 'veri\sgs-analiz.json') },
  @{ sinav = 'SMMM'; yol = (Join-Path $depoKok 'veri\smmm-analiz.json') }
)
$kayitlar = New-Object System.Collections.Generic.List[object]
foreach($kay in $kaynaklar){
  $icerikNesne = [IO.File]::ReadAllText($kay.yol, [Text.Encoding]::UTF8) | ConvertFrom-Json
  $kay.nesne = $icerikNesne
  foreach($r in @($icerikNesne.donemler)){
    $kayitlar.Add([pscustomobject]@{ sinav = $kay.sinav; anahtar = "$($r.donem)|$($r.ders)"; donem = "$($r.donem)"; ders = "$($r.ders)"; adres = "$($r.kaynakUrl)"; yerel = $null; sha = ''; karar = 'SAGLAM'; not = ''; ref = $r })
  }
}
Write-Host ("Analiz kaydi: {0}" -f $kayitlar.Count)

foreach($k in $kayitlar){
  $k.yerel = YerelPdf $k.sinav $k.adres
  if($k.yerel){
    $ilk = [IO.File]::ReadAllBytes($k.yerel) | Select-Object -First 4
    if([Text.Encoding]::ASCII.GetString([byte[]]@($ilk)) -eq '%PDF'){
      $k.sha = (Get-FileHash -Path $k.yerel -Algorithm SHA256).Hash
      $k.not = 'diskte PDF'
      continue
    }
  }
  $uzak = IlkBaytUzak $k.adres
  if($uzak.imza -eq '%PDF'){ $k.not = 'diskte yok, kaynakta PDF' }
  elseif($uzak.hata){ $k.karar = 'OLCULEMEDI'; $k.not = "kaynak okunamadi: $($uzak.hata)" }
  else { $k.karar = 'HAYALET'; $k.not = "kaynak PDF degil (tur=$($uzak.tur), ilk bayt='$($uzak.imza)')" }
}

$shaGrup = $kayitlar | Where-Object { $_.sha } | Group-Object sha | Where-Object { $_.Count -gt 1 }
foreach($g in $shaGrup){
  foreach($k in $g.Group){ $k.karar = 'MUKERRER'; $k.not = 'ayni PDF: ' + (($g.Group | ForEach-Object { $_.anahtar }) -join ' = ') }
}

Write-Host ''
$kayitlar | Group-Object karar | ForEach-Object { Write-Host ("  {0,-11} {1}" -f $_.Name, $_.Count) }
$sorunlu = @($kayitlar | Where-Object { $_.karar -ne 'SAGLAM' })
foreach($k in $sorunlu){ Write-Host ("  {0} {1} {2} -> {3}" -f $k.karar, $k.sinav, $k.anahtar, $k.not) }

if(-not $Uygula){ Write-Host "`nKURU KOSU - hicbir dosya yazilmadi. Yazmak icin -Uygula."; exit 0 }
if(@($kayitlar | Where-Object { $_.karar -eq 'OLCULEMEDI' }).Count -gt 0){ Write-Host 'DUR: olculemeyen kayit var, karar verilemez.'; exit 1 }
if(@($kayitlar | Where-Object { $_.karar -eq 'MUKERRER' }).Count -gt 0){ Write-Host 'DUR: mukerrer var - hangisinin gercek oldugu elle incelenir, arac karar vermez.'; exit 1 }

$cikan = @($kayitlar | Where-Object { $_.karar -eq 'HAYALET' })
foreach($kay in $kaynaklar){
  $once = @($kay.nesne.donemler)
  $onceImza = @{}; foreach($r in $once){ $onceImza["$($r.donem)|$($r.ders)"] = ($r | ConvertTo-Json -Depth 8 -Compress) }
  $atilacak = @{}; foreach($k in $cikan){ if($k.sinav -eq $kay.sinav){ $atilacak[$k.anahtar] = 1 } }
  $kalan = New-Object System.Collections.Generic.List[object]
  $shaEklenen = 0
  foreach($r in $once){
    $anh = "$($r.donem)|$($r.ders)"
    if($atilacak.ContainsKey($anh)){ continue }
    $bul = $kayitlar | Where-Object { $_.ref -eq $r } | Select-Object -First 1
    if($bul.sha -and -not $r.PSObject.Properties['pdfSha256']){ $r | Add-Member -NotePropertyName pdfSha256 -NotePropertyValue $bul.sha; $shaEklenen++ }
    $kalan.Add($r)
  }
  # PROVA: kalan kayitlarda pdfSha256 disinda tek alan degismemeli
  $bozuk = 0
  foreach($r in $kalan){
    $kopya = $r | ConvertTo-Json -Depth 8 -Compress | ConvertFrom-Json
    if($kopya.PSObject.Properties['pdfSha256'] -and -not ($onceImza["$($r.donem)|$($r.ders)"] -match 'pdfSha256')){ $kopya.PSObject.Properties.Remove('pdfSha256') }
    if(($kopya | ConvertTo-Json -Depth 8 -Compress) -ne $onceImza["$($r.donem)|$($r.ders)"]){ $bozuk++ }
  }
  $beklenenKalan = $once.Count - $atilacak.Count
  Write-Host ("PROVA {0}: once {1} - cikan {2} - kalan {3} (beklenen {4}) - sha eklenen {5} - baska alan degisen {6}" -f $kay.sinav, $once.Count, $atilacak.Count, $kalan.Count, $beklenenKalan, $shaEklenen, $bozuk)
  if($bozuk -gt 0 -or $kalan.Count -ne $beklenenKalan){ Write-Host 'DUR: prova tutmadi, yazilmadi.'; exit 1 }
  $kay.nesne.donemler = $kalan.ToArray()
  [IO.File]::WriteAllText($kay.yol, (($kay.nesne | ConvertTo-Json -Depth 8) + "`r`n"), (New-Object Text.UTF8Encoding($true)))
}

# sinav-arsiv.json: bicimi bozmamak icin yalniz ilgili satirin durum alani degisir
$arsivYolu = Join-Path $depoKok 'veri\sinav-arsiv.json'
$arsivMetin = [IO.File]::ReadAllText($arsivYolu, [Text.Encoding]::UTF8)
$degisen = 0
foreach($k in $cikan){
  $desen = '("url"\s*:\s*"' + [regex]::Escape($k.adres) + '"\s*,\s*"durum"\s*:\s*)"[^"]*"'
  $esles = [regex]::Matches($arsivMetin, $desen).Count
  if($esles -ne 1){ Write-Host ("UYARI: sinav-arsiv.json'da {0} icin {1} eslesme - dokunulmadi" -f $k.adres, $esles); continue }
  $arsivMetin = [regex]::Replace($arsivMetin, $desen, '$1"hayalet"')
  $degisen++
}
[IO.File]::WriteAllText($arsivYolu, $arsivMetin, (New-Object Text.UTF8Encoding($true)))
Write-Host ("sinav-arsiv.json: {0} satir durum='hayalet'" -f $degisen)
