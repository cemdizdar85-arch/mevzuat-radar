# ============================================================================
#  KGK MEVZUAT TAMLIK ÖLÇÜMÜ (tebliğ · yönetmelik · rehber) — 16.09.2026
#  Cem "1.2.3 üçünüde yap": KGK Excel'inde 50 kaynak "AMBARDA VAR (tamlığı ölçülmedi)" idi.
#
#  NE YAPAR: her belge için ambardaki parçaların madde numaralarını RESMÎ METİNLE kıyaslar.
#   1) ambar adları veri/fabrika/kosucu-log/kgk-kaynak-adlar.json'dan (ambarın tamamı) belge köküne göre toplanır
#   2) belgenin kaynak_url'i ambardan okunur (1 satır), resmî PDF indirilir (mevzuat.gov.tr çerezli oturum / SPK api)
#   3) pdftotext ile metne dökülür, resmî MADDE başlıkları sayılır (aralıklı yazım "M A D D E" dahil; mülga maddeler ayrı)
#   4) eksik = resmî metinde var, ambarda parçası yok · fazla = ambarda var, resmî metinde yok
#  Standartlar (TMS/TFRS/BDS/GDS/İHS) bu betiğin işi DEĞİL: onlar arac/kgk-hakikat-olcumu.ps1'de ölçülür.
#
#  Yazma yok (ambar/depo), model yok, bedel 0. Çıktı: veri/kgk-mevzuat-tamlik.json
#  Kullanım: powershell -NoProfile -File arac/kgk-mevzuat-tamlik.ps1 [-Desen 'Tebligi|Yonetmeli'] [-Tavan 0]
# ============================================================================
param([string]$Desen = '', [int]$Tavan = 0)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'rapor-yaz.ps1')
$SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co'
$anahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')
if(-not $anahtar){ $anahtar = $env:SUPABASE_SERVICE_KEY }
if(-not $anahtar){ Write-Host 'SUPABASE_SERVICE_KEY yok'; exit 1 }
$H = @{ apikey=$anahtar; Authorization="Bearer $anahtar"; 'User-Agent'='mevzuat-radar-robot/1.0' }   # 07.08: UA'sız istek "tarayıcı" sayılıp reddediliyor
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
$pdftotext = @(
  'C:\Users\cemdi\AppData\Local\Microsoft\WinGet\Packages\oschwartz10612.Poppler_Microsoft.Winget.Source_8wekyb3d8bbwe\poppler-25.07.0\Library\bin\pdftotext.exe'
  (Get-Command pdftotext -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if(-not $pdftotext){ Write-Host 'pdftotext bulunamadı'; exit 1 }
$gecici = Join-Path ([IO.Path]::GetTempPath()) 'kgk-mevzuat-tamlik'; New-Item -ItemType Directory -Force $gecici | Out-Null

# 16.09 ÖLÇÜLDÜ: geniş desen ambardaki YÜZLERCE vergi tebliğini de (GVK GT 293-299…) çekiyordu; onlar KGK sınavında geçmiyor,
# üstelik mevzuat.gov.tr'yi gereksiz yoruyor. Varsayılan desen KGK derslerinin belgeleriyle sınırlı (çıkmış soru ölçümü:
# KGK-Sinav-Kaynak-Basim-Plani.xlsx, "AMBARDA VAR (tamlığı ölçülmedi)" satırları). -Desen ile genişletilebilir.
$VARSAYILAN_DESEN = '(?i)(SPK (Tebli[ğg]|Y[öo]netmelik|Rehber|Karar)|Tebli[ğg]i \((II|III|IV|V|VI|VII)-|Bankalar[ıi]n |BDDK |Sigorta|Sigortac[ıi]l[ıi]k|Emeklilik|Kurumsal Y[öo]netim Tebli|Ba[ğg][ıi]ms[ıi]z Denetim Y[öo]netmeli|Varl[ıi]k Y[öo]netim|Kitle Fonlamas|Yat[ıi]r[ıi]m (Fonlar|Hizmetleri|Kurulu[şs])|Portf[öo]y Y[öo]netim|Gayrimenkul Yat[ıi]r[ıi]m|Menkul K[ıi]ymet Yat[ıi]r[ıi]m|Giri[şs]im Sermayesi|Kira Sertifika|Teminatl[ıi] Menkul|Varl[ıi][ğg]a|Pay (Tebli|Al[ıi]m)|Bor[çc]lanma Ara[çc]lar|[İI]zahname|Kaydile[şs]tir|Merkezi Takas|Takas ve Saklama|Yat[ıi]r[ıi]mc[ıi] Tazmin|Borsalar ve Piyasa|Kredi (Riski|Sınıflandırma)|Kredilerin S[ıi]n[ıi]fland[ıi]r|G[üu]vence Hesab[ıi]|Teknik Kar[şs][ıi]l[ıi]k|Uzaktan Kimlik|Derecelendirme|Depo Sertifika|Repo|TSPB|T[üu]rkiye Sermaye Piyasalar)'
$belgeDeseni = if($Desen){ $Desen } else { $VARSAYILAN_DESEN }

function OturumAc {
  $s = $null
  try { Invoke-WebRequest -Uri 'https://www.mevzuat.gov.tr/' -UserAgent $UA -TimeoutSec 45 -UseBasicParsing -SessionVariable s | Out-Null } catch {}
  return $s
}
function PdfMi([string]$yol){ try{ $b=[IO.File]::ReadAllBytes($yol); if($b.Length -lt 400){ return $false }; return ([Text.Encoding]::ASCII.GetString($b,0,4) -eq '%PDF') }catch{ return $false } }
# resmî metindeki madde numaraları: "MADDE 12 –", "Madde 12 -", aralıklı "M A D D E1 2 -" (16.09 parçalayıcı dersi), mülga olanlar ayrı
function ResmiMaddeler([string]$metin){
  $duz = ($metin -replace "\r?\n"," ") -replace '\s+',' '
  $duz = [regex]::Replace($duz,'\b(?!MADDE)(?=M ?A ?D ?D ?E)M ?A ?D ?D ?E ?((?:\d ?){1,3})(?=[-–:(])', { param($es) 'MADDE ' + ($es.Groups[1].Value -replace ' ','') + ' ' })
  $var = New-Object System.Collections.Generic.HashSet[int]; $mulga = New-Object System.Collections.Generic.HashSet[int]
  foreach($es in [regex]::Matches($duz,'(?i)\b(?:EK\s+|GE[ÇC][İI]C[İI]\s+|M[ÜU]KERRER\s+)?MADDE\s+(\d{1,3})\s*(?:/\s*[A-Za-zÇĞİÖŞÜçğıöşü])?\s*[-–:(]')){
    $no = [int]$es.Groups[1].Value
    $onces = $duz.Substring([Math]::Max(0,$es.Index-30), [Math]::Min(30,$es.Index))
    if($onces -match '(?i)(ek|ge[çc]ici|m[üu]kerrer)\s*$'){ continue }   # ek/geçici madde ayrı diziyi izler
    $sonras = $duz.Substring($es.Index+$es.Length, [Math]::Min(60,$duz.Length-($es.Index+$es.Length)))
    if($sonras -match '(?i)^\s*\(?\s*M[üu]lga'){ [void]$mulga.Add($no) } else { [void]$var.Add($no) }
  }
  foreach($x in @($mulga)){ if($var.Contains($x)){ [void]$mulga.Remove($x) } }
  return [pscustomobject]@{ var=$var; mulga=$mulga }
}

# ---- ambar adları (ambarın tamamı)
$adlar = Get-Content (Join-Path $depoKok 'veri\fabrika\kosucu-log\kgk-kaynak-adlar.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$belgeler = @{}
foreach($r in $adlar){
  $ad = "$($r.kaynak_ad)"
  $kok = ($ad -replace '\s+(gec\.|ek|muk\.)?\s*m\.\d.*$','' -replace '\s*\[\d+/\d+\]$','' -replace '\s*\[giris\]$','').Trim()
  if(-not $kok -or $kok -match '^(TMS|TFRS|BDS|GDS|İHS|SBDS|KYS)\s'){ continue }
  # 16.09: desen BELGE ADINA bakar, parça adının tamamına değil — madde başlığında "Yönetmelik" geçen kanunlar (Avukatlık K.) yanlış giriyordu
  if($kok -notmatch $belgeDeseni){ continue }
  if(-not $belgeler.ContainsKey($kok)){ $belgeler[$kok] = New-Object System.Collections.Generic.HashSet[int] }
  $es = [regex]::Match($ad,'\sm\.(\d+)')
  if($es.Success -and $ad -notmatch '\s(gec\.|ek|muk\.)\s*m\.'){ [void]$belgeler[$kok].Add([int]$es.Groups[1].Value) }
}
$liste = @($belgeler.Keys | Where-Object { $belgeler[$_].Count -ge 5 } | Sort-Object)
if($Tavan -gt 0){ $liste = @($liste | Select-Object -First $Tavan) }
Write-Host "ölçülecek belge: $($liste.Count)"

$oturum = OturumAc
$satirlar = New-Object System.Collections.Generic.List[object]
foreach($kok in $liste){
  $kayit = [ordered]@{ belge=$kok; ambar_madde=$belgeler[$kok].Count; en_buyuk=0; resmi_madde=0; mulga=0; eksik=0; fazla=0; eksik_ornek=''; fazla_ornek=''; durum=''; adres_notu=''; url='' }
  # belgenin resmî adresi ambardan
  $url = ''
  try{
    $q = [uri]::EscapeDataString("$kok*")
    $ham = Invoke-RestMethod -Uri "$SB_URL/rest/v1/dokumanlar?select=kaynak_url&kaynak_ad=like.$q&kaynak_url=not.is.null&limit=1" -Headers $H -TimeoutSec 60
    foreach($x in $ham){ if("$($x.kaynak_url)"){ $url = "$($x.kaynak_url)"; break } }
  }catch{}
  # 16.09 KUSUR (ölçüldü): ambardaki kaynak_url'in bir kısmı BOZUK — "mevzuatmetin/G9:18527.pdf" gibi, pdfId ön eki yola yapıştırılmış.
  # Bu adres HTML hata sayfası döndürüyor (200 + text/html, 64.854 bayt). Doğrusu GeneratePdf sorgusudur; burada çevriliyor.
  # (Yutucu adresi manifest'ten kendisi kuruyor, o yüzden YUTMA etkilenmedi; bozuk olan yalnız kayıtlı adres.)
  $mBozuk = [regex]::Match("$url",'mevzuatmetin/G(\d+):(\d+)\.pdf')
  if($mBozuk.Success){
    $tur = switch($mBozuk.Groups[1].Value){ '7' { 'KurumVeKurulusYonetmeligi' } '9' { 'Teblig' } '19' { 'CumhurbaskanligiKararnamesi' } default { 'Teblig' } }
    $url = "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$($mBozuk.Groups[2].Value)&mevzuatTur=$tur&mevzuatTertip=5"
    $kayit.adres_notu = 'kayıtlı adres bozuk (mevzuatmetin/GN:no.pdf) → GeneratePdf ile alındı'
  }
  $kayit.url = $url
  if(-not $url){ $kayit.durum = 'ADRES YOK (ambarda kaynak_url boş)'; $satirlar.Add([pscustomobject]$kayit); Write-Host ("{0,-60} ADRES YOK" -f $kok.Substring(0,[Math]::Min(60,$kok.Length))); continue }
  $dosya = Join-Path $gecici (($kok -replace '[^A-Za-z0-9]','_') + '.pdf'); $txt = [IO.Path]::ChangeExtension($dosya,'.txt')
  $indi = $false
  for($deneme=1; $deneme -le 2 -and -not $indi; $deneme++){
    try{
      if($url -match 'mevzuat\.gov\.tr'){   # bot koruması: çerezli oturum şart (07.08 dersi)
        Invoke-WebRequest -Uri $url -OutFile $dosya -UserAgent $UA -Headers @{ Referer='https://www.mevzuat.gov.tr/' } -WebSession $oturum -TimeoutSec 90 -UseBasicParsing
      } else {   # SPK/BDDK/diğer hatlar: düz indirme (16.09 ölçüldü: mevzuat.spk.gov.tr/api/mevzuat/File/N doğrudan PDF verir)
        $null = curl.exe -s -L -A $UA -o $dosya $url
      }
      if(PdfMi $dosya){ $indi = $true } elseif($deneme -eq 1){ Start-Sleep -Seconds 6; $oturum = OturumAc }
    }catch{ if($deneme -eq 2){ $kayit.durum = "İNDİRME HATASI: $($_.Exception.Message)" } ; Start-Sleep -Seconds 4 }
  }
  if(-not $indi){
    if(-not $kayit.durum){ $kayit.durum = 'PDF DEĞİL (bot sayfası / adres bozuk)' }
    $satirlar.Add([pscustomobject]$kayit); Write-Host ("{0,-60} {1}" -f $kok.Substring(0,[Math]::Min(60,$kok.Length)),$kayit.durum); continue
  }
  & $pdftotext -enc UTF-8 -nopgbrk $dosya $txt 2>$null | Out-Null
  $metin = [IO.File]::ReadAllText($txt,[Text.Encoding]::UTF8)
  $r = ResmiMaddeler $metin
  $amb = $belgeler[$kok]
  $eksik = @($r.var | Where-Object { -not $amb.Contains($_) } | Sort-Object)
  $fazla = @($amb | Where-Object { -not $r.var.Contains($_) -and -not $r.mulga.Contains($_) } | Sort-Object)
  $kayit.resmi_madde = $r.var.Count; $kayit.mulga = $r.mulga.Count; $kayit.eksik = $eksik.Count; $kayit.fazla = $fazla.Count
  $kayit.en_buyuk = $(if($r.var.Count){ ($r.var | Measure-Object -Maximum).Maximum } else { 0 })
  $kayit.eksik_ornek = (@($eksik | Select-Object -First 20) -join ','); $kayit.fazla_ornek = (@($fazla | Select-Object -First 15) -join ',')
  $oran = if($r.var.Count){ 100.0*$eksik.Count/$r.var.Count } else { 100 }
  $kayit.durum = if($r.var.Count -lt 5){ 'ÖLÇÜLEMEDİ (resmî metinde madde bulunamadı)' } elseif($oran -le 5){ 'TAM' } else { 'EKSİK' }
  $satirlar.Add([pscustomobject]$kayit)
  Write-Host ("{0,-60} resmî {1,3} · mülga {2,2} · ambar {3,3} · eksik {4,3} · fazla {5,2} · {6}" -f $kok.Substring(0,[Math]::Min(60,$kok.Length)),$kayit.resmi_madde,$kayit.mulga,$kayit.ambar_madde,$kayit.eksik,$kayit.fazla,$kayit.durum)
  Start-Sleep -Milliseconds 700
}
$sonuc = [ordered]@{
  olcum = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  kural = 'TAM: resmî maddelerin ≤%5''i ambarda yok · EKSİK: >%5 · mülga maddeler eksik sayılmaz · ek/geçici maddeler ayrı dizidir, kıyasa girmez'
  ozet = [ordered]@{ olculen=@($satirlar | Where-Object { $_.durum -in 'TAM','EKSİK' }).Count; TAM=@($satirlar | Where-Object durum -eq 'TAM').Count; EKSIK=@($satirlar | Where-Object durum -eq 'EKSİK').Count; olculemedi=@($satirlar | Where-Object { $_.durum -notin 'TAM','EKSİK' }).Count }
  belgeler = $satirlar.ToArray()
}
# 16.09: süzgeçli koşu (-Desen/-Tavan) rapor dosyasını EZMEZ — tek belgelik deneme 101 satırlık ölçümü silmişti
if(-not $Desen -and -not $Tavan){ [void](RaporYaz -Hedef (Join-Path $depoKok 'veri\kgk-mevzuat-tamlik.json') -Nesne $sonuc -Sessiz) } else { Write-Host '  (süzgeçli koşu: rapor dosyasına yazılmadı)' -ForegroundColor DarkGray }
"ÖZET: ölçülen {0} · TAM {1} · EKSİK {2} · ölçülemedi {3}" -f $sonuc.ozet.olculen,$sonuc.ozet.TAM,$sonuc.ozet.EKSIK,$sonuc.ozet.olculemedi
