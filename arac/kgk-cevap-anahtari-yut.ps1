# ============================================================================
#  KGK CEVAP ANAHTARLARINI AMBARA YUT   16.09.2026 (Cem "1.2.3 üçünüde yap", GM 1)
#
#  NEDEN: çıkmış sınav karnesi KGK'da "diskte 112 · ambarda 108" diyordu. Fark soru kitapçığı değil,
#  29.06.2019 sınavının AYRI yayımlanan 4 cevap anahtarı (10202_*-CEVAPANAHTARI). Soru ayrıştırıcısı
#  (motor/cikmis-soru-ayristir.ps1) "SORU N" bloğu aramadığı için bu dosyaları hiç ambara koymadı.
#  Anahtarlar motor/kgk-cevap-anahtari.ps1 ile zaten ayrıştırılmış (veri/kgk-cevap-anahtari.json).
#
#  NE YAPAR (bedel 0, model yok):
#   - veri/kgk-arsiv/txt'de adı "CEVAPANAHTARI" geçen ve ambarda karşılığı olmayan her dosya için bir belge yazar:
#       tur='cikmis-soru' · kaynak_ad = "CIKMIS SINAV - KGK CEVAP (<dosya kökü>)" (karne diskle bu parantezden eşler)
#       metin = RESMÎ metin (pdftotext çıktısı, olduğu gibi) + "AYRIŞTIRILMIŞ CEVAPLAR" bölümü (json'dan, modül modül)
#       kaynak_url = veri/kgk-arsiv/pdf-links.tsv'deki resmî adres
#   - Var olanı ezmez (aynı ad ambarda varsa atlar). Yazdıktan sonra geri okur.
#  Varsayılan KURU PROVA. Yazmak için -Yaz.
# ============================================================================
param([switch]$Yaz)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
$sbAnahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'); if(-not $sbAnahtar){ $sbAnahtar = $env:SUPABASE_SERVICE_KEY }
if(-not $sbAnahtar){ Write-Host 'SUPABASE_SERVICE_KEY yok'; exit 1 }
$sbBasliklar = @{ apikey=$sbAnahtar; Authorization="Bearer $sbAnahtar"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$ambarUcu = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$txtKlasoru = Join-Path $depoKok 'veri\kgk-arsiv\txt'
if(-not (Test-Path $txtKlasoru)){ Write-Host 'KÖR: veri/kgk-arsiv/txt yok (yalnız yerelde).'; exit 0 }

$anahtarDosyasi = Get-Content (Join-Path $depoKok 'veri\kgk-cevap-anahtari.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$baglantilar = @(Get-Content (Join-Path $depoKok 'veri\kgk-arsiv\pdf-links.tsv') -Encoding UTF8 | Where-Object { $_.Trim() })

$ambardakiAdlar = New-Object System.Collections.Generic.HashSet[string]
foreach($kayit in (Invoke-RestMethod -Uri ("$ambarUcu`?select=kaynak_ad&tur=eq.cikmis-soru&kaynak_ad=like." + [uri]::EscapeDataString('CIKMIS SINAV - KGK*') + '&limit=1000') -Headers $sbBasliklar -TimeoutSec 120)){ [void]$ambardakiAdlar.Add("$($kayit.kaynak_ad)") }
$ambardakiKokler = New-Object System.Collections.Generic.HashSet[string]
foreach($ad in $ambardakiAdlar){ $es = [regex]::Match($ad,'\(([^)]+)\)\s*$'); if($es.Success){ [void]$ambardakiKokler.Add($es.Groups[1].Value.Trim()) } }

$yazilacak = New-Object System.Collections.Generic.List[object]
foreach($dosya in (Get-ChildItem $txtKlasoru -Filter '*CEVAPANAHTARI*.txt' | Sort-Object Name)){
  $kokAd = $dosya.BaseName
  if($ambardakiKokler.Contains($kokAd)){ Write-Host "  zaten ambarda: $kokAd"; continue }
  $resmiMetin = ([IO.File]::ReadAllText($dosya.FullName,[Text.Encoding]::UTF8)).Trim()
  $oturum = $anahtarDosyasi.oturumlar.$kokAd
  $ek = New-Object System.Text.StringBuilder
  if($oturum){
    [void]$ek.AppendLine(''); [void]$ek.AppendLine('AYRIŞTIRILMIŞ CEVAPLAR (motor/kgk-cevap-anahtari.ps1)')
    [void]$ek.AppendLine("Sınav tarihi: $($oturum.tarih) · Kitapçık: $($oturum.kitapcik) · Oturum: $($oturum.oturum)")
    foreach($modul in $oturum.moduller.PSObject.Properties){
      $siralı = @($modul.Value.PSObject.Properties | Sort-Object { [int]$_.Name } | ForEach-Object { "$($_.Name)-$($_.Value)" })
      [void]$ek.AppendLine("$($modul.Name) ($($siralı.Count) soru): $($siralı -join ', ')")
    }
    if("$($oturum.uyari)"){ [void]$ek.AppendLine("Uyarı: $($oturum.uyari)") }
  } else { Write-Host "  ⚠ $kokAd için ayrıştırılmış anahtar yok — yalnız resmî metin yazılacak" }
  # resmî adres: dosya adındaki kitapçık (A/B) ve oturum (SABAH/ÖĞLEDENSONRA) ile eşlenir
  $kitapcikHarfi = [regex]::Match($kokAd,'_([AB])_').Groups[1].Value
  $sabahMi = $kokAd -match '(?i)SABAH'
  $adres = ''
  foreach($satir in $baglantilar){
    $parcalar = $satir -split "`t"; if($parcalar.Count -lt 3){ continue }
    $cozulmus = [uri]::UnescapeDataString($parcalar[2])
    if($parcalar[0].Trim() -ne ($kokAd -split '_')[0]){ continue }
    if($cozulmus -notmatch 'CEVAPANAHTARI'){ continue }
    if($cozulmus -notmatch "(^|/)$kitapcikHarfi[ _-]K"){ continue }
    if($sabahMi -ne [bool]($cozulmus -match '(?i)SABAH')){ continue }
    $adres = $parcalar[2]; break
  }
  $yazilacak.Add([ordered]@{ tur='cikmis-soru'; kaynak_ad="CIKMIS SINAV - KGK CEVAP ($kokAd)"; baslik="KGK cevap anahtarı $($oturum.tarih) $kitapcikHarfi $(if($sabahMi){'sabah'}else{'öğleden sonra'}) - 0 soru"; metin=($resmiMetin + $ek.ToString()); kaynak_url=$adres })
  Write-Host ("  yazılacak: {0} · {1:N0} kr · adres {2}" -f $kokAd,($resmiMetin + $ek.ToString()).Length,$(if($adres){'VAR'}else{'YOK'}))
}
if($yazilacak.Count -eq 0){ Write-Host 'Yazılacak cevap anahtarı yok.'; exit 0 }
if(-not $Yaz){ Write-Host "KURU PROVA — $($yazilacak.Count) belge. Yazmak için -Yaz"; exit 0 }
$govde = ConvertTo-Json -InputObject @($yazilacak.ToArray()) -Depth 4
if($govde.TrimStart()[0] -ne '['){ $govde = "[$govde]" }
$null = Invoke-RestMethod -Method Post -Uri $ambarUcu -Headers ($sbBasliklar + @{ Prefer='return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120
$dogru = 0
foreach($belge in $yazilacak){
  $geri = @(Invoke-RestMethod -Uri ("$ambarUcu`?select=metin&kaynak_ad=eq." + [uri]::EscapeDataString($belge.kaynak_ad)) -Headers $sbBasliklar -TimeoutSec 120)
  if($geri.Count -eq 1 -and "$($geri[0].metin)" -ceq $belge.metin){ $dogru++ } else { Write-Host "  !! GERİ OKUMA TUTMADI: $($belge.kaynak_ad) (kayıt $($geri.Count))" -ForegroundColor Red }
}
Write-Host ("YAZILDI: {0} belge · geri okuma birebir {1}" -f $yazilacak.Count,$dogru)
