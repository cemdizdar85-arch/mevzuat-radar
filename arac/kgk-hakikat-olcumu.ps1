# ============================================================================
#  KGK STANDART HAKİKAT ÖLÇÜMÜ — 15.09.2026
#  Cem "1.2.3 üçünüde yapalım" (GM önerisi 3: parasız onarım/ölçüm).
#
#  NEDEN VAR: arac/kgk-kaynak-olcumu.ps1 "tamlık"ı ambardaki paragraf NUMARA DİZİSİNİN deliğiyle ölçüyor.
#  Resmî metinde "[Silinmiştir]" olan paragraflar (TMS 40 p.3, p.6 …) hiç parça üretmediği için DELİK sayılıyor.
#  15.09 kuru prova: 14 "delikli" standardın 12'sinde resmî PDF'ten yeniden parçalama ambarla BİREBİR aynı çıktı
#  (TMS 40 ölçümde 18 delik, resmî numaralardan sapma 1) — yani etiket çoğunlukla ölçüm hatası.
#
#  NE ÖLÇER: her standart için resmî PDF (KGK) -> pdftotext -layout -> RESMÎ paragraf numaraları
#  (metniyle aynı satırda duran numara; "[Silinmiştir]" satırları ayrı sayılır) -> ambardaki parça numaralarıyla kıyas:
#   eksik  = resmî metinde VAR, ambarda parçası YOK (gerçek delik)
#   silinen = resmî metinde [Silinmiştir] (eksik sayılmaz)
#   fazla  = ambarda var, resmî numaralarda yok (bölme hatası adayı)
#  Numara biçimi: TMS/TFRS/TSRS "5   metin" (numara kendi sütununda) · BDS/GDS/İHS "5. metin" (satır başında noktalı).
#  Ek bölümleri (Ek 1 p.N) numara kümesine katılmaz (ekler kendi içinde 1'den başlar).
#
#  Yazma yok (ambar/depo), model yok, bedel 0. Çıktı: veri/kgk-hakikat-olcumu.json (RaporYaz).
#  Kullanım: powershell -NoProfile -File arac/kgk-hakikat-olcumu.ps1 [-Yalniz 'TMS 1','BDS 510']
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
$gecici = Join-Path ([IO.Path]::GetTempPath()) 'kgk-hakikat'; New-Item -ItemType Directory -Force $gecici | Out-Null
$kokAdres = 'https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2'

function ResmiAdres([string]$std){
  if($std -match '^(TMS|TFRS)\s'){ return "$kokAdres/TMS_TFRS_Setleri/2026/Kirmizi_Kitap/$(($std -split ' ')[0])/$std.pdf" }
  if($std -match '^(BDS|GDS|KYS)\s'){ return "$kokAdres/TDS/TDS_2025_Seti/${std}_2025.pdf" }   # 16.09: KYS 1/2 aynı sette (KYS%201_2025.pdf, 200)
  return ''
}
# 15.09 araştırma: KGK dosya adı kalıba uymayanlar (adında fazladan boşluk / Türkçe harf)
$ozelAdres = @{
  'TFRS 18' = 'https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2026/Kirmizi_Kitap/TFRS/TFRS%2018%20.pdf'
  'İHS 4400' = "$kokAdres/TDS/TDS_2025_Seti/%C4%B0HS%204400_2025.pdf"
  'TFRS 19' = 'https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2026/Kirmizi_Kitap/TFRS/TFRS%2019.pdf'
  'TMS 1' = "$kokAdres/TMS/TMS_1_Finansal%20Tablolar%C4%B1n%20Sunulu%C5%9Fu.pdf"   # 2026 Kırmızı Kitap klasöründe yok (302); ambardaki kaynak_url bu
  # 16.09: TSRS'nin RESMÎ yayımı RG 29.12.2023-32414 (1. mük.) kurul kararıdır ama o PDF TARANMIŞ GÖRÜNTÜ (metin katmanı yok, 3 MB'de 4 bin karakter).
  # Metinli tek resmî kopya KGK'nın kendi dosyası (02.01.2024). ⚠ 28.07.2026-33323 sera gazı değişikliği bu dosyalara İŞLENMEMİŞ —
  # ölçüm "ilk yayım metnine göre" tamlıktır; değişiklik ambarda ayrı kaynak olarak durur (manifest: kgk-tsrs2-degisiklik-2026).
  'TSRS 1' = "$kokAdres/Surdurulebilirlik/RaporlamaStandarti/TSRS%201.pdf"
  'TSRS 2' = "$kokAdres/Surdurulebilirlik/RaporlamaStandarti/TSRS%202.pdf"
  # 16.09: Etik Kurallar (Bağımsızlık Standartları Dâhil) — TDS 2025 seti, 11.08.2025 güncel metin. Aile kodu 'ETIK' (arac/kgk-kaynak-olcumu.ps1 ile aynı).
  'ETIK' = "$kokAdres/TDS/TDS_2025_Seti/BagimsizDenetcilerIcinEtik%20Kurallar_11_08_2025.pdf"
}

function HakikatNumaralari([string]$metin, [string]$std){
  $gercek = New-Object System.Collections.Generic.HashSet[string]; $silinen = New-Object System.Collections.Generic.HashSet[string]
  $bdsKip = $std -match '^(BDS|GDS|İHS|KYS)\s'   # 16.09: KYS de '1. metin' biçiminde
  foreach($satir in ($metin -split "`r?`n")){
    if($std -eq 'ETIK'){
      # 16.09: Etik numarası 'A100.7' (ana hüküm) · '100.6' · '100.6 U1' (uygulama). Numaradan sonra küçük harf = satır başına düşmüş çapraz atıf, paragraf değil.
      $es = [regex]::Match($satir,'^\s{0,6}(A?\d{3}\.\d{1,3}(?:\s+U\d{1,2})?)\s{2,}(\S.*)$')
      if($es.Success -and $es.Groups[2].Value -cmatch '^[a-zçğıöşü]'){ continue }
      if($es.Success){ $no = ($es.Groups[1].Value -replace '\s+',' '); $govde = $es.Groups[2].Value; if($govde -match '^\[Silinmi'){ [void]$silinen.Add($no) } else { [void]$gercek.Add($no) } }
      continue
    }
    if($bdsKip){ $es = [regex]::Match($satir,'^\s{0,4}([A-Z]?\d{1,3}[A-Z]?)\.\s+(\S.*)$') }
    elseif($std -match '^TSRS\s'){ $es = [regex]::Match($satir,'^\s{0,10}([A-Z]{0,2}\d{1,3}[A-Z]{0,2})\s{2,}(\S.*)$') }   # 16.09: TSRS'de numara sütunu girintili
    else       { $es = [regex]::Match($satir,'^([A-Z]{0,2}\d{1,3}(?:\.\d{1,3}){0,3}[A-Z]{0,2})\s{2,}(\S.*)$') }   # TFRS 9 '4.1.1' noktalı numara
    if(-not $es.Success){ continue }
    $no = $es.Groups[1].Value; $govde = $es.Groups[2].Value
    if($govde -match '^\[Silinmi'){ [void]$silinen.Add($no) } else { [void]$gercek.Add($no) }
  }
  foreach($s in @($silinen)){ if($gercek.Contains($s)){ [void]$silinen.Remove($s) } }
  return [pscustomobject]@{ gercek=$gercek; silinen=$silinen }
}

# ambar adları (arac/kgk-kaynak-olcumu.ps1 önbelleği; -Tazele ile orada tazelenir)
$adOnbellek = Join-Path $depoKok 'veri\fabrika\kosucu-log\kgk-kaynak-adlar.json'
$adlar = Get-Content $adOnbellek -Raw -Encoding UTF8 | ConvertFrom-Json
$ambarNo = @{}
foreach($r in $adlar){
  $ad = "$($r.kaynak_ad)"
  $es = [regex]::Match($ad,'^((?:TMS|TFRS|BDS|GDS|İHS|TSRS|SBDS|KYS)\s\d+)\s(Ek\s\d+\s)?p\.([A-Z]{0,2}\d{1,3}(?:\.\d{1,3}){0,3}[A-Z]{0,2})(?:[\s\-]|$)')
  $etikEs = [regex]::Match($ad,'^Etik Kurallar p\.(A?\d{3}\.\d{1,3}(?: U\d{1,2})?)(?:\s|$)')   # 16.09
  if($etikEs.Success){ if(-not $ambarNo.ContainsKey('ETIK')){ $ambarNo['ETIK'] = New-Object System.Collections.Generic.HashSet[string] }; [void]$ambarNo['ETIK'].Add($etikEs.Groups[1].Value); continue }
  if(-not $es.Success -or $es.Groups[2].Value){ continue }
  $std = $es.Groups[1].Value
  if(-not $ambarNo.ContainsKey($std)){ $ambarNo[$std] = New-Object System.Collections.Generic.HashSet[string] }
  [void]$ambarNo[$std].Add($es.Groups[3].Value)
}
$liste = if($Yalniz.Count){ $Yalniz } else { @($ambarNo.Keys | Sort-Object { ($_ -split ' ')[0] }, { [int](($_ -split ' ')[1]) }) }

$satirlar = New-Object System.Collections.Generic.List[object]
foreach($std in $liste){
  $adres = if($ozelAdres.ContainsKey($std)){ $ozelAdres[$std] } else { ResmiAdres $std }
  $kayit = [ordered]@{ standart=$std; adres=$adres; durum=''; resmi_paragraf=0; silinen=0; ambar_paragraf=0; eksik=0; fazla=0; eksik_ornek=''; fazla_ornek=''; silinen_ornek='' }
  if(-not $adres){ $kayit.durum='ADRES YOK'; $satirlar.Add([pscustomobject]$kayit); continue }
  $pdf = Join-Path $gecici ("{0}.pdf" -f ($std -replace '[^A-Za-z0-9]','_')); $txt = [IO.Path]::ChangeExtension($pdf,'.txt')
  try {
    $yanit = Invoke-WebRequest -UseBasicParsing -Uri $adres -TimeoutSec 180
    $bayt = $yanit.RawContentStream.ToArray(); [IO.File]::WriteAllBytes($pdf,$bayt)
    if([Text.Encoding]::ASCII.GetString($bayt,0,[Math]::Min(4,$bayt.Length)) -ne '%PDF'){ $kayit.durum='PDF DEĞİL (adres kalıbı tutmadı)'; $satirlar.Add([pscustomobject]$kayit); continue }
  } catch { $kayit.durum="İNDİRME HATASI: $($_.Exception.Message)"; $satirlar.Add([pscustomobject]$kayit); continue }
  & $pdftotext -enc UTF-8 -nopgbrk -layout $pdf $txt 2>$null | Out-Null
  $metin = [IO.File]::ReadAllText($txt,[Text.Encoding]::UTF8)
  $h = HakikatNumaralari $metin $std
  $amb = if($ambarNo.ContainsKey($std)){ $ambarNo[$std] } else { New-Object System.Collections.Generic.HashSet[string] }
  $eksik = @($h.gercek | Where-Object { -not $amb.Contains($_) })
  $fazla = @($amb | Where-Object { $_ -ne '0' -and -not $h.gercek.Contains($_) -and -not $h.silinen.Contains($_) })
  $kayit.resmi_paragraf=$h.gercek.Count; $kayit.silinen=$h.silinen.Count; $kayit.ambar_paragraf=$amb.Count
  $kayit.eksik=$eksik.Count; $kayit.fazla=$fazla.Count
  $kayit.eksik_ornek=(@($eksik | Select-Object -First 25) -join ','); $kayit.fazla_ornek=(@($fazla | Select-Object -First 15) -join ','); $kayit.silinen_ornek=(@($h.silinen | Select-Object -First 15) -join ',')
  $oran = if($h.gercek.Count){ 100.0*$eksik.Count/$h.gercek.Count } else { 100 }
  $kayit.durum = if($h.gercek.Count -lt 5){ 'ÖLÇÜLEMEDİ (resmî numara bulunamadı)' } elseif($oran -le 5){ 'TAM' } else { 'EKSİK' }
  $satirlar.Add([pscustomobject]$kayit)
  Write-Host ("{0,-9} resmî {1,4} · silinen {2,3} · ambar {3,4} · eksik {4,3} · fazla {5,3} · {6}" -f $std,$kayit.resmi_paragraf,$kayit.silinen,$kayit.ambar_paragraf,$kayit.eksik,$kayit.fazla,$kayit.durum)
  Start-Sleep -Milliseconds 400
}
$sonuc = [ordered]@{
  olcum = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  kural = 'TAM: resmî paragrafların ≤%5''i ambarda parçasız · EKSİK: >%5 · [Silinmiştir] eksik sayılmaz · Ek bölümleri kümeye katılmaz'
  ozet = [ordered]@{ olculen=@($satirlar | Where-Object { $_.durum -in 'TAM','EKSİK' }).Count; TAM=@($satirlar | Where-Object durum -eq 'TAM').Count; EKSIK=@($satirlar | Where-Object durum -eq 'EKSİK').Count; olculemedi=@($satirlar | Where-Object { $_.durum -notin 'TAM','EKSİK' }).Count }
  standartlar = $satirlar.ToArray()
}
if(-not $Yalniz.Count){ [void](RaporYaz -Hedef (Join-Path $depoKok 'veri\kgk-hakikat-olcumu.json') -Nesne $sonuc -Sessiz) }
"ÖZET: ölçülen {0} · TAM {1} · EKSİK {2} · ölçülemedi {3}" -f $sonuc.ozet.olculen,$sonuc.ozet.TAM,$sonuc.ozet.EKSIK,$sonuc.ozet.olculemedi
