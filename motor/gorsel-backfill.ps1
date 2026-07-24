# ============================================================================
#  GORSEL BACKFILL — kasadaki TABLOSUZ analiz sorularina exhibit tablosu uretir.
#  Cem karari 24.07: "sadece bunda degil digerlerinde de yok - hepsinde olsun,
#  bilanco/nakit akis da gosterelim." Yeni uretim zaten zorunlu-tablolu (7b);
#  bu robot ESKI kasayi ayni seviyeye ceker.
#  AKIS: kasadan tablo=null + analiz-konulu sorulari cek (SERVICE key, sayfali)
#   -> Batch API'ye (%50, Haiku) tablo-uretim gorevleri -> poll -> dogrula
#   -> yalniz {id, tablo} upsert (diger kolonlara DOKUNMAZ) -> rapor.
#  Tanim sorulari icin model "null" dondurur -> atlanir (zorla tablo YOK).
#  ENV: SUPABASE_SERVICE_KEY + ANTHROPIC_API_KEY zorunlu.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$enc  = New-Object Text.UTF8Encoding($false)
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$MODEL = "claude-haiku-4-5-20251001"
$KOSU_TAVANI = 1500   # tek kosuda en fazla bu kadar soru islenir (maliyet freni)

$KEY = $env:SUPABASE_SERVICE_KEY
$AKEY = $env:ANTHROPIC_API_KEY
if(-not $KEY -or -not $AKEY){ Write-Host "SERVICE/ANTHROPIC anahtari eksik - atlandi."; exit 0 }
$H = @{ apikey=$KEY; Authorization="Bearer $KEY" }

function JsonBul($t){ $m=[regex]::Match($t,'(?s)\{.*\}'); if($m.Success){ return $m.Value }; return $null }

# 1) kasayi sayfali cek (yalniz gerekli kolonlar)
$hepsi = @()
$sayfa = 0
while($true){
  $bas = $sayfa*1000; $son = $bas+999
  $hh = $H.Clone(); $hh['Range'] = "$bas-$son"
  $r = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id,ders,konu,soru,siklar,dogru,tablo&order=id" -Headers $hh -TimeoutSec 60
  $hepsi += @($r)
  if(@($r).Count -lt 1000){ break }
  $sayfa++
  if($sayfa -gt 30){ break }
}
Write-Host ("Kasa tarandi: {0} soru" -f $hepsi.Count)

# 2) aday suz: tablosuz + hesap/analiz-konulu
$desen = 'analiz|nakit|bilanco|oran|maliyet|amortisman|sermaye|deflator|kar\b|satis|yuzde|esneklik|gsyh|butce|prim|hesapla|tutar|deger'
$adaylar = @($hepsi | Where-Object { (-not $_.tablo) -and ( (("$($_.konu)" -replace 'ı','i' -replace 'ö','o' -replace 'ü','u' -replace 'ş','s' -replace 'ç','c' -replace 'ğ','g').ToLower() -match $desen) -or ("$($_.soru)" -match '\d{3}[\.\d]* TL|%\d') ) })
if($adaylar.Count -gt $KOSU_TAVANI){ $adaylar = @($adaylar | Select-Object -First $KOSU_TAVANI) }
Write-Host ("Tablosuz analiz-adayi: {0}" -f $adaylar.Count)
if($adaylar.Count -eq 0){ Write-Host "Backfill gerektiren soru yok."; exit 0 }

# 3) batch istekleri (%50)
$istekler = @($adaylar | ForEach-Object {
  $s = $_
  $siklarStr = (@('A','B','C','D','E') | Where-Object { $s.siklar.$_ } | ForEach-Object { "$_) $($s.siklar.$_)" }) -join "`n"
  $istem = @"
Bir sinav sorusuna EXHIBIT tablosu ureteceksin (UWorld tarzi: hesap lafla degil tablo ustunde gorunsun).
SORU ($($s.ders) / $($s.konu)): $($s.soru)
$siklarStr
DOGRU CEVAP: $($s.dogru)
GOREV: Bu sorunun cozumunu GOSTEREN mini tabloyu uret. Kurallar:
- Sayilar SORUDAKILERLE birebir ayni olacak; yeni sayi UYDURMA.
- Cevabin ciktigi satirin SON hucresine ' ←' ekle.
- 2-8 satir; kisa ve net. Nakit akis sorusunda dolayli-serit (Net Kar -> duzeltmeler -> nakit), bilanco sorusunda donem basi/sonu, oran sorusunda pay/payda/sonuc satirlari kullan.
- Soru SAF TANIM/kavram sorusuysa ve gosterilecek hesap yoksa SADECE null yaz.
SADECE su JSON'u (ya da null) dondur: {"baslik":"...","kolonlar":["...","..."],"satirlar":[["...","..."],["...","... ←"]]}
"@
  @{ custom_id = "$($s.id)"; params = @{ model=$MODEL; max_tokens=500; messages=@(@{ role='user'; content=$istem }) } }
})
$govde = @{ requests = $istekler } | ConvertTo-Json -Depth 8
$b = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages/batches" `
      -Headers @{ "x-api-key"=$AKEY; "anthropic-version"="2023-06-01" } `
      -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 120
Write-Host ("Batch gonderildi: {0} ({1} gorev)" -f $b.id, $istekler.Count)

# 4) poll
$bekleme = 0
while($true){
  Start-Sleep -Seconds 60
  $bekleme++
  $d = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages/batches/$($b.id)" `
        -Headers @{ "x-api-key"=$AKEY; "anthropic-version"="2023-06-01" } -TimeoutSec 60
  if($d.processing_status -eq 'ended'){ break }
  if($bekleme -ge 150){ Write-Host "Poll zaman asimi - batch devam ediyor, sonraki kosu alir."; exit 0 }
}
$sonuclar = Invoke-WebRequest -Uri $d.results_url -Headers @{ "x-api-key"=$AKEY; "anthropic-version"="2023-06-01" } -TimeoutSec 300 -UseBasicParsing
$satirlar = ($sonuclar.Content -split "`n") | Where-Object { $_.Trim() }

# 5) dogrula + upsert (yalniz id+tablo; parti parti)
$yazilan=0; $nullSayisi=0; $bozuk=0
$upsertler = @()
foreach($ln in $satirlar){
  try {
    $rj = $ln | ConvertFrom-Json
    if($rj.result.type -ne 'succeeded'){ $bozuk++; continue }
    $metin = (@($rj.result.message.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
    if($metin.Trim() -match '^null$'){ $nullSayisi++; continue }
    $js = JsonBul $metin
    if(-not $js){ $bozuk++; continue }
    $tb = $js | ConvertFrom-Json
    if(-not $tb.baslik -or -not $tb.satirlar -or @($tb.satirlar).Count -lt 2 -or @($tb.satirlar).Count -gt 10){ $bozuk++; continue }
    $upsertler += [ordered]@{ id = $rj.custom_id; tablo = $tb }
  } catch { $bozuk++ }
}
Write-Host ("Uretilen tablo: {0} | tanim(null): {1} | bozuk: {2}" -f $upsertler.Count, $nullSayisi, $bozuk)
$HU = @{ apikey=$KEY; Authorization="Bearer $KEY"; Prefer="resolution=merge-duplicates,return=minimal" }
for($i=0; $i -lt $upsertler.Count; $i += 200){
  $dilim = @($upsertler[$i..([Math]::Min($i+199, $upsertler.Count-1))])
  $g = ConvertTo-Json -InputObject $dilim -Depth 8
  Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/soru_havuzu?on_conflict=id" -Headers $HU `
    -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($g)) -TimeoutSec 120 | Out-Null
  $yazilan += $dilim.Count
  Write-Host ("upsert parti: {0}/{1}" -f $yazilan, $upsertler.Count)
}

# 6) rapor
$ozet = [ordered]@{ calisti=(Get-Date -Format "dd.MM.yyyy HH:mm"); taranan=$hepsi.Count; aday=$adaylar.Count; tablo_yazilan=$yazilan; tanim_null=$nullSayisi; bozuk=$bozuk; batch=$b.id }
$rp = Join-Path $kok "veri/gorsel-backfill-rapor.json"
$g2 = @(); if(Test-Path $rp){ try{ $g2=@(Get-Content $rp -Raw -Encoding UTF8 | ConvertFrom-Json) }catch{} }
$g2 += $ozet
[IO.File]::WriteAllText($rp, ($g2 | ConvertTo-Json -Depth 5), $enc)
Write-Host ("TAMAM: {0} soruya gorsel tablo islendi." -f $yazilan)
exit 0
