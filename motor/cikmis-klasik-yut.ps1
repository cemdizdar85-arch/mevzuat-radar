# ============================================================================
#  KLASIK (ACIK UCLU) CIKMIS SINAV KITAPCIKLARINI AMBARA YUT  - 23.08.2026
#
#  NEDEN AYRI BETIK: TESMER Yeterlilik (staj bitirme) sinavi 2026/1'e kadar
#  KLASIK idi. 23.08 olcumu: TESMER bu donemler icin SORU KITAPCIGI YAYIMLAMIYOR -
#  yayimlanan PDF'lerin 48/48'i "SINAV KOMISYONU CEVAPLARI" ile basliyor, soru
#  metni HIC YOK (soru_smmm_*, *_soru.pdf, sorular/ gibi 8 adres deseni denendi,
#  hepsi HTML hata sayfasi dondu). Elimizdeki KOMISYONUN RESMI COZUMU: yevmiye
#  kayitlari, matrah hesaplari, hukuki gerekce. Deger yuksek ama bu SORU DEGIL -
#  o yuzden tur adi da 'cikmis-soru' degil 'cikmis-komisyon-cevabi'.
#
#  NEDEN AYRI TUR (tur='cikmis-komisyon-cevabi'):
#  Bu belgeler tek satirda 60 bin+ karakter. Ayni ture konursa Net Cevap'in
#  tam-metin aramasini kazanip mevzuat maddelerini bastirirlar - 21.08'de
#  tam bu yasandi (8 sorgunun 6'sini cikmis sinav metinleri kazanmisti).
#
#  Girdi : bir txt klasoru (varsayilan veri/smmm-arsiv/txt)
#  Cikti : veri/cikmis-klasik-rapor.json
#  BEDAVA.
# ============================================================================
param(
  [string]$Klasor = '',
  [string]$Desen = 'smmm_*.txt',
  [switch]$yaz,
  [int]$Tavan = 0
)
$ErrorActionPreference='Continue'
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$kok = Split-Path -Parent $PSScriptRoot
if($Klasor -eq ''){ $Klasor = Join-Path $kok 'veri\smmm-arsiv\txt' }
if(-not (Test-Path $Klasor)){ Write-Host "Klasor yok: $Klasor"; exit 1 }

$DERS = @{
  '01'='Finansal Muhasebe'; '02'='Finansal Tablolar ve Analizi'; '03'='Maliyet Muhasebesi'
  '04'='Muhasebe Denetimi';  '05'='Vergi Mevzuatı ve Uygulaması'; '06'='Hukuk'
  '07'='Muh. ve Mali Müş. Meslek Hukuku'; '08'='Sermaye Piyasası Mevzuatı'
}
$AMBAR = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

$dosyalar = @(Get-ChildItem -LiteralPath $Klasor -Filter $Desen | Sort-Object Name)
if($Tavan -gt 0){ $dosyalar = @($dosyalar | Select-Object -First $Tavan) }
Write-Host ("Kitapcik: {0}" -f $dosyalar.Count)

$VAROLAN = @{}
if($yaz){
  if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
  Add-Type -AssemblyName System.Net.Http
  $hc=New-Object System.Net.Http.HttpClient
  $hc.Timeout=[TimeSpan]::FromSeconds(180)
  $hc.DefaultRequestHeaders.Add('apikey',$env:SUPABASE_SERVICE_KEY)
  $hc.DefaultRequestHeaders.Add('Authorization',('Bearer '+$env:SUPABASE_SERVICE_KEY))
  try {
    $m = Invoke-RestMethod -Uri ($AMBAR + '?select=kaynak_ad&tur=eq.cikmis-komisyon-cevabi&limit=5000') `
         -Headers @{apikey=$env:SUPABASE_SERVICE_KEY; Authorization=('Bearer '+$env:SUPABASE_SERVICE_KEY)}
    foreach($x in @($m)){ $VAROLAN["$($x.kaynak_ad)"] = 1 }
    Write-Host ("Ambarda zaten olan klasik belge: {0}" -f $VAROLAN.Count)
  } catch { Write-Host ('UYARI: mevcut liste cekilemedi - ' + $_.Exception.Message); exit 1 }
}

$rapor = New-Object System.Collections.Generic.List[object]
$yazilan=0; $zaten=0; $kisa=0; $hata=0; $test=0
foreach($f in $dosyalar){
  $m = [regex]::Match($f.BaseName, '^smmm_(\d{4})_(\d)_(\d{2})$')
  if(-not $m.Success){ continue }
  $yil=$m.Groups[1].Value; $don=$m.Groups[2].Value; $dk=$m.Groups[3].Value
  $dersAd = if($DERS.ContainsKey($dk)){ $DERS[$dk] } else { ('ders ' + $dk) }
  $boy = $f.Length
  if($boy -lt 800){ $kisa++; $rapor.Add([pscustomobject]@{ dosya=$f.BaseName; durum='KISA'; bayt=$boy }); continue }
  $metin = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  # 2026/1'den itibaren yeterlilik TEST formatinda: bu dosyalar GERCEK SORU
  # tasir ve coktan secmeli hatta (cikmis-soru-ayristir.ps1) aittir.
  # AYRIM BASLIKTAN YAPILMAZ: olculdu, klasik donemde uc ayri baslik var -
  # "SINAV KOMISYONU CEVAPLARI", "SINAV KOMISYONUCEVAPLARI" (bosluksuz),
  # duz "CEVAPLAR". Basliga bakan suzgec 48 dosyanin 5'ini yanlisla test sandi.
  # Guvenilir olcut ICERIK: test kitapciginda onlarca "E)" sik isareti vardir,
  # klasik komisyon cevabinda yok denecek kadar az.
  $sikSayisi = ([regex]::Matches($metin, '(?<![A-Za-z0-9])E\)\s')).Count
  if($sikSayisi -ge 10){
    $test++; $rapor.Add([pscustomobject]@{ dosya=$f.BaseName; durum='TEST-FORMATI-ATLANDI'; bayt=$boy; sik=$sikSayisi }); continue
  }
  # sayfa besleme ve asiri bosluk temizligi - ambarda tek blok duracak
  $metin = ($metin -replace "`f", "`n") -replace '[ \t]{3,}', '  '
  $kad = ('CIKMIS SINAV KOMISYON CEVABI - SMMM {0}/{1} {2} ({3})' -f $yil,$don,$dersAd,$f.BaseName)
  $rapor.Add([pscustomobject]@{ dosya=$f.BaseName; durum='HAZIR'; bayt=$boy; ders=$dersAd })
  if(-not $yaz){ continue }
  if($VAROLAN.ContainsKey($kad)){ $zaten++; continue }
  $govde=[ordered]@{
    id=([guid]::NewGuid().ToString())
    kaynak_ad=$kad
    baslik=('Sinav komisyonu resmi cevaplari (klasik donem) - SMMM Yeterlilik {0}/{1} - {2}' -f $yil,$don,$dersAd)
    tur='cikmis-komisyon-cevabi'
    metin=$metin
  }
  $j = ConvertTo-Json -InputObject $govde -Depth 4 -Compress
  $i2 = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::Post),$AMBAR
  $i2.Content = New-Object System.Net.Http.StringContent ($j,[Text.Encoding]::UTF8,'application/json')
  $i2.Headers.Add('Prefer','return=minimal')
  $c = $hc.SendAsync($i2).GetAwaiter().GetResult()
  if([int]$c.StatusCode -eq 201){ $yazilan++ } else { $hata++; if($hata -le 3){ Write-Host ('  YAZMA HATASI ' + [int]$c.StatusCode + ' - ' + $c.Content.ReadAsStringAsync().GetAwaiter().GetResult()) } }
  $c.Dispose(); $i2.Dispose()
  if($yazilan % 25 -eq 0 -and $yazilan -gt 0){ Write-Host ("  ... {0} yazildi" -f $yazilan) }
}
Write-Host ("`nHAZIR {0} | YAZILAN {1} | ZATEN VARDI {2} | KISA {3} | TEST-FORMATI(atlandi) {4} | HATA {5}" -f @($rapor|Where-Object{$_.durum -eq "HAZIR"}).Count,$yazilan,$zaten,$kisa,$test,$hata)
[IO.File]::WriteAllText((Join-Path $kok 'veri\cikmis-klasik-rapor.json'),
  (ConvertTo-Json -InputObject ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); yazilan=$yazilan; zaten=$zaten; kisa=$kisa; hata=$hata; kayitlar=$rapor.ToArray() }) -Depth 4),
  (New-Object Text.UTF8Encoding($false)))
Write-Host 'Rapor: veri/cikmis-klasik-rapor.json'
