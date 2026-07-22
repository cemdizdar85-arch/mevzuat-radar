# ============================================================================
#  SINAV ANALIZ ROBOTU — SGS kitapciklarini Claude'a PDF olarak okutur,
#  HER soruyu (no, ders, konu) etiketler. KALITE KAPILARI:
#   1) IKI BAGIMSIZ okuma; soru sayilari ve ders etiketleri karsilastirilir
#   2) Ders uyusmazligi >%10 ise donem RED (inceleme isaretlenir, yayinlanmaz)
#   3) Konu etiketi uyusmayanlar 3. hakem cagriyla tekillestirilir
#   4) Soru sayisi 90-140 araligi disindaysa RED
#  Cikti: veri/sgs-analiz.json (donem bazli ders/konu sayimlari + soru listesi)
#  Kitapcik METNI siteye kopyalanmaz — yalniz analiz yayinlanir (telif).
#  ENV: ANTHROPIC_API_KEY zorunlu. Kosumda en fazla $LIMIT donem islenir.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$MODEL = "claude-sonnet-5"
$LIMIT = 3
$key = $env:ANTHROPIC_API_KEY
if(-not $key){ Write-Host "ANTHROPIC_API_KEY yok - atlandi."; exit 0 }

$arsivYol = Join-Path $kok "veri/sinav-arsiv.json"
$analizYol = Join-Path $kok "veri/sgs-analiz.json"
$arsiv = Get-Content $arsivYol -Raw -Encoding UTF8 | ConvertFrom-Json
$analiz = if(Test-Path $analizYol){ Get-Content $analizYol -Raw -Encoding UTF8 | ConvertFrom-Json } else { [pscustomobject]@{ guncelleme=""; donemler=@() } }

function ClaudePdf($b64, $istem, $maxtok){
  $body = @{ model=$MODEL; max_tokens=$maxtok; messages=@(@{ role="user"; content=@(
    @{ type="document"; source=@{ type="base64"; media_type="application/pdf"; data=$b64 } },
    @{ type="text"; text=$istem }) }) } | ConvertTo-Json -Depth 8 -Compress
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" `
        -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } `
        -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -TimeoutSec 900
  return (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
}
function ClaudeTxt($istem, $maxtok){
  $body = @{ model=$MODEL; max_tokens=$maxtok; messages=@(@{ role="user"; content=$istem }) } | ConvertTo-Json -Depth 6 -Compress
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" `
        -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } `
        -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -TimeoutSec 300
  return (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
}
function JsonBul($t){ $m=[regex]::Match($t,'(?s)\[.*\]'); if($m.Success){ return $m.Value }; return $null }
function Fold($s){ return ("$s".ToLowerInvariant().Trim() -replace 'ç','c' -replace 'ğ','g' -replace 'ı','i' -replace 'ö','o' -replace 'ş','s' -replace 'ü','u' -replace '\s+',' ') }

$ISTEM = @"
Bu bir TURMOB-TESMER Staja Giris Sinavi soru kitapcigidir. GOREV: kitapciktaki HER COKTAN SECMELI SORUYU tek tek bul ve etiketle.
Her soru icin: no (kitapciktaki soru numarasi), ders (kitapciktaki bolume sadik kal; su listeden sec: Genel Kultur-Genel Yetenek, Muhasebe, Ekonomi, Maliye, Hukuk, Matematik-Istatistik, Yabanci Dil), konu (2-4 kelimelik SPESIFIK etiket, ornek: amortisman ayirma, KDV tevkifat, ihbar suresi, arz-talep esnekligi, butce ilkeleri, kiymetli evrak).
KURALLAR: Soru atlamak YASAK. Soru metnini KOPYALAMA - yalniz no/ders/konu. Emin olmadigin konuya en yakin genel etiketi ver.
SADECE su formatta JSON dizisi dondur, baska hicbir metin yazma:
[{"no":1,"ders":"...","konu":"..."}]
"@

$islenen = 0
foreach($d in $arsiv.donemler){
  if($d.durum -ne 'bekliyor'){ continue }
  if($islenen -ge $LIMIT){ break }
  Write-Host ("=== {0} ({1}) isleniyor..." -f $d.donem, $d.tarih)
  $tmp = Join-Path ([IO.Path]::GetTempPath()) "sgs.pdf"
  try { Invoke-WebRequest -Uri $d.url -OutFile $tmp -UserAgent "Mozilla/5.0" -TimeoutSec 180 -UseBasicParsing } catch { Write-Host "  indirilemedi, atlandi"; continue }
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($tmp))
  Write-Host ("  pdf {0} KB, okuma 1/2..." -f [math]::Round((Get-Item $tmp).Length/1KB))

  # KAPI 1: iki bagimsiz okuma
  $o1 = $null; $o2 = $null
  try { $o1 = (JsonBul (ClaudePdf $b64 $ISTEM 16000)) | ConvertFrom-Json } catch { Write-Host "  okuma1 hata: $($_.Exception.Message)" }
  Write-Host "  okuma 2/2..."
  try { $o2 = (JsonBul (ClaudePdf $b64 $ISTEM 16000)) | ConvertFrom-Json } catch { Write-Host "  okuma2 hata: $($_.Exception.Message)" }
  if(-not $o1 -or -not $o2){ Write-Host "  RED: okuma basarisiz"; $d.durum='hata'; $islenen++; continue }

  # KAPI 4: soru sayisi makul mu
  $n1=@($o1).Count; $n2=@($o2).Count
  Write-Host ("  okuma1={0} soru, okuma2={1} soru" -f $n1,$n2)
  if($n1 -lt 90 -or $n1 -gt 140 -or $n2 -lt 90 -or $n2 -gt 140 -or [math]::Abs($n1-$n2) -gt 8){
    Write-Host "  RED: soru sayisi guvensiz"; $d.durum='inceleme'; $islenen++; continue }

  # KAPI 2: ders uyusmasi (no bazinda)
  $h2=@{}; foreach($s in $o2){ $h2["$($s.no)"]=$s }
  $dersUyusmaz=0; $konuCift=New-Object System.Collections.Generic.List[object]; $sorular=New-Object System.Collections.Generic.List[object]
  foreach($s in $o1){
    $e=$h2["$($s.no)"]
    if(-not $e){ $dersUyusmaz++; continue }
    if((Fold $s.ders) -ne (Fold $e.ders)){ $dersUyusmaz++; continue }
    if((Fold $s.konu) -eq (Fold $e.konu)){
      $sorular.Add(@{ no=$s.no; ders=$s.ders; konu=(Fold $s.konu) })
    } else {
      $konuCift.Add(@{ no=$s.no; ders=$s.ders; a=$s.konu; b=$e.konu })
    }
  }
  $oran = $dersUyusmaz / [double]$n1
  Write-Host ("  ders uyusmayan: {0} (%{1}) · konu farkli: {2}" -f $dersUyusmaz, [math]::Round($oran*100), $konuCift.Count)
  if($oran -gt 0.10){ Write-Host "  RED: ders uyusmazligi >%10"; $d.durum='inceleme'; $islenen++; continue }

  # KAPI 3: konu uyusmayanlara hakem (tek toplu cagri)
  if($konuCift.Count -gt 0){
    $liste = ($konuCift | ForEach-Object { "no=$($_.no) ders=$($_.ders) A='$($_.a)' B='$($_.b)'" }) -join "`n"
    $hIstem = "Ayni sinav sorusu icin iki okuma farkli konu etiketi verdi. Her satir icin TEK dogru/kapsayici etiketi sec (A, B veya daha iyi kisa bir birlesik etiket).`n$liste`nSADECE JSON dizisi: [{`"no`":1,`"konu`":`"...`"}]"
    try {
      $hk = (JsonBul (ClaudeTxt $hIstem 4000)) | ConvertFrom-Json
      $hkMap=@{}; foreach($x in $hk){ $hkMap["$($x.no)"]="$($x.konu)" }
      foreach($c in $konuCift){ $k=$hkMap["$($c.no)"]; if(-not $k){ $k=$c.a }; $sorular.Add(@{ no=$c.no; ders=$c.ders; konu=(Fold $k) }) }
    } catch { foreach($c in $konuCift){ $sorular.Add(@{ no=$c.no; ders=$c.ders; konu=(Fold $c.a) }) } }
  }

  # sayimlar
  $dersSayim=@{}; $konuSayim=@{}
  foreach($s in $sorular){ $dersSayim[$s.ders]=1+[int]$dersSayim[$s.ders]; $kk="$($s.ders)|$($s.konu)"; $konuSayim[$kk]=1+[int]$konuSayim[$kk] }
  $yeni = [pscustomobject]@{ donem=$d.donem; tarih=$d.tarih; kaynakUrl=$d.url; toplamSoru=$sorular.Count;
    dersSayim=$dersSayim; konuSayim=$konuSayim; analizTarihi=(Get-Date -Format "dd.MM.yyyy"); yontem="cift okuma + hakem" }
  $dl = New-Object System.Collections.Generic.List[object]
  foreach($x in @($analiz.donemler)){ if($x.donem -ne $d.donem){ $dl.Add($x) } }
  $dl.Add($yeni); $analiz.donemler = $dl.ToArray()
  $analiz.guncelleme = (Get-Date -Format "dd.MM.yyyy HH:mm")
  $d.durum = 'tamam'
  Write-Host ("  TAMAM: {0} soru etiketlendi, {1} ders" -f $sorular.Count, $dersSayim.Keys.Count)
  $islenen++
}

[IO.File]::WriteAllText($arsivYol, ($arsiv | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
[IO.File]::WriteAllText($analizYol, ($analiz | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
Write-Host ("BITTI: bu kosuda {0} donem islendi." -f $islenen)
exit 0
