# ============================================================================
#  SORU DENETCISI K2 v2 — BATCH TABANLI bagimsiz icerik dogrulamasi (%50)
#  25.07 kokten cozum: senkron istekler gunduz batch'leri islenirken SUREKLI 429
#  yiyordu (40 backoff bile yetmedi) -> K2 tamamen Batch API'ye tasindi.
#  Boylece: 429 derdi biter + %50 indirimli hat (kural: indirimsiz is yasak).
#  (Gemini denemesi kaldirildi: free-tier her kosuda 429 veriyordu; Haiku-batch
#  Cem'in 24.07 "alternatif onayi" kapsaminda.)
#  AKIS: fabrika dosyalarindan durum='katman1-temiz' adaylar -> tek batch (Haiku)
#   -> poll -> kararlar: cevap UYUSUYORSA kasaya (ifade nitpicki not olarak),
#   uyusmuyorsa karantina (GM okumasina; SILINMEZ) -> dosya-basi ara-kayit commit.
#  ENV: ANTHROPIC_API_KEY zorunlu.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$enc  = New-Object Text.UTF8Encoding($false)
$MODEL = "claude-haiku-4-5-20251001"

$AKEY = $env:ANTHROPIC_API_KEY
if(-not $AKEY){ Write-Host "ANTHROPIC_API_KEY yok - K2 atlandi."; exit 0 }

function JsonBul($t){ $m=[regex]::Match($t,'(?s)\{.*\}'); if($m.Success){ return $m.Value }; return $null }

# 1) adaylari topla
$dosyalar = Get-ChildItem (Join-Path $kok "veri/fabrika") -Filter *.json
$adaylar = @()
foreach($fd in $dosyalar){
  try {
    $j = Get-Content $fd.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($s in @($j.sorular | Where-Object { $_.durum -eq 'katman1-temiz' })){
      $siklarStr = (@('A','B','C','D','E') | Where-Object { $s.siklar.$_ } | ForEach-Object { "$_) $($s.siklar.$_)" }) -join "`n"
      $istem = @"
Sen bagimsiz bir SMMM/mali musavirlik sinav denetcisisin. Asagidaki coktan secmeli soruyu KENDI bilginle coz, sonra isaretli 'dogru cevabi' ELESTIREL bicimde denetle.
SORU: $($s.soru)
$siklarStr
Bu soruda dogru cevap olarak "$($s.dogru)" isaretlenmis. Dayanak: $($s.kaynak)
GOREV: 1) Soruyu kendin coz, dogru buldugun sikki belirt. 2) Isaretli cevap Turkiye mevzuatina gore SAVUNULABILIR mi? 3) Emin degilsen/yanlissa gecerli=false.
SADECE su JSON'u dondur (alan sirasi aynen boyle; sebep EN FAZLA 1 kisa cumle): {"gecerli": true veya false, "benimCevap": "A", "sebep": "tek cumle"}
"@
      $adaylar += [ordered]@{ id="$($s.id)"; istem=$istem }
    }
  } catch { Write-Host ("UYARI: {0} okunamadi" -f $fd.Name) }
}
Write-Host ("K2 adayi: {0}" -f $adaylar.Count)
if($adaylar.Count -eq 0){ Write-Host "Denetlenecek soru yok."; exit 0 }

# 2) HAZIR BATCH DEVRALMA (26.07 kesfi: onceki kosu batch'i basariyla isletti ama sonuc
# indirme bayt-dizisi bug'iyla coptu - kararlar Anthropic'te 29 gun hazir duruyor;
# ayni adaylar icin YENIDEN ODEME YAPMA, once eski batch'i dene):
$b = $null
try {
  $rpEski = Get-Content (Join-Path $kok "veri/soru-denetci-rapor.json") -Raw -Encoding UTF8 | ConvertFrom-Json
  $sonK = @($rpEski) | Select-Object -Last 1
  if($sonK.batch -and [int]$sonK.islenen -eq 0){   # 27.07: hata>100 devralmasi TEK SEFERLIKTI (kesik-JSON kurtarmasi yapildi); kalanlar icin YENI batch acilmali
    $eb = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages/batches/$($sonK.batch)" `
          -Headers @{ "x-api-key"=$AKEY; "anthropic-version"="2023-06-01" } -TimeoutSec 60
    if($eb.processing_status -eq 'ended'){ $b = $eb; Write-Host ("Hazir batch devralindi: {0}" -f $b.id) }
  }
} catch { Write-Host "Eski batch devralinamadi - yenisi acilacak." }
if(-not $b){
  # 27.07: 400 token JSON'u ortasindan kesiyordu (2.079 sonuc "hata" sayildi) -> 700
  $istekler = @($adaylar | ForEach-Object { @{ custom_id=$_.id; params=@{ model=$MODEL; max_tokens=700; messages=@(@{ role='user'; content=$_.istem }) } } })
  $govde = @{ requests = $istekler } | ConvertTo-Json -Depth 8
  $b = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages/batches" `
        -Headers @{ "x-api-key"=$AKEY; "anthropic-version"="2023-06-01" } `
        -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 300
  Write-Host ("Batch gonderildi: {0} ({1} gorev)" -f $b.id, $adaylar.Count)
}

# 3) poll (240 dk tavan; devralinan batch zaten ended ise atlanir)
if($b.processing_status -ne 'ended'){
  $bekleme=0
  while($true){
    Start-Sleep -Seconds 60
    $bekleme++
    $b = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages/batches/$($b.id)" `
          -Headers @{ "x-api-key"=$AKEY; "anthropic-version"="2023-06-01" } -TimeoutSec 60
    if($b.processing_status -eq 'ended'){ break }
    if($bekleme -ge 240){ Write-Host "Poll tavani - sonraki kosu devralir (batch id raporda)."; break }
  }
}
if($b.processing_status -ne 'ended'){
  # rapora batch id'yi yaz ki sonraki kosu devralabilsin, sonra cik
  $ozetY = [ordered]@{ calisti=(Get-Date -Format "dd.MM.yyyy HH:mm"); islenen=0; kasaya=0; karantina=0; hata=0; onayci='haiku-batch'; batch=$b.id; kalan_katman1_temiz=$adaylar.Count; not='poll tavani - devral' }
  $rY = Join-Path $kok "veri/soru-denetci-rapor.json"; $gY=@(); if(Test-Path $rY){ try{ $gY=@(Get-Content $rY -Raw -Encoding UTF8 | ConvertFrom-Json) }catch{} }; $gY += $ozetY
  [IO.File]::WriteAllText($rY, ($gY | ConvertTo-Json -Depth 6), $enc)
  exit 0
}
# 26.07 BUG TAMIRI: .Content JSONL'de BAYT DIZISI donuyordu, split karakter-karakter
# patliyordu (hata=2.6M!). Sonuc artik DOSYAYA indirilir, satirlar dosyadan okunur.
$tmpf = Join-Path ([IO.Path]::GetTempPath()) "k2-results.jsonl"
Invoke-WebRequest -Uri $b.results_url -Headers @{ "x-api-key"=$AKEY; "anthropic-version"="2023-06-01" } -OutFile $tmpf -TimeoutSec 600 -UseBasicParsing
$satirlar = Get-Content $tmpf -Encoding UTF8 | Where-Object { $_.Trim() }
Write-Host ("Sonuc satiri: {0}" -f @($satirlar).Count)

# 4) kararlar haritasi (+ 27.07: kesik-JSON kurtarma ve hata kirilimi)
$kararlar = @{}
$hata = 0; $tipHata = 0; $jsonYok = 0; $kurtarilan = 0; $ornekler = @()
foreach($ln in $satirlar){
  try {
    $rj = $ln | ConvertFrom-Json
    if($rj.result.type -ne 'succeeded'){ $hata++; $tipHata++; if($ornekler.Count -lt 3){ $ornekler += "tip=$($rj.result.type) id=$($rj.custom_id)" }; continue }
    $metin = (@($rj.result.message.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
    $js = JsonBul $metin
    if($js){
      $kararlar[$rj.custom_id] = ($js | ConvertFrom-Json)
    } else {
      # kesik cevap kurtarma: max_tokens JSON'u kesmisse gecerli+benimCevap coklukla
      # sebep'ten ONCE geldigi icin metinde saglam durur - regex'le cek
      $mg = [regex]::Match($metin, '"gecerli"\s*:\s*(true|false)')
      $mc = [regex]::Match($metin, '"benimCevap"\s*:\s*"([A-E])"')
      if($mg.Success -and $mc.Success){
        $kararlar[$rj.custom_id] = [pscustomobject]@{ gecerli = ($mg.Groups[1].Value -eq 'true'); benimCevap = $mc.Groups[1].Value; sebep = '(kesik cevap - alanlar kurtarildi)' }
        $kurtarilan++
      } else {
        $hata++; $jsonYok++
        if($ornekler.Count -lt 3){ $ornekler += ("json-yok id={0} stop={1} uzunluk={2}" -f $rj.custom_id, $rj.result.message.stop_reason, $metin.Length) }
      }
    }
  } catch { $hata++ }
}
Write-Host ("Karar geldi: {0} (kurtarilan: {1}) | sonuc-hatasi: {2} (tip: {3}, json-yok: {4})" -f $kararlar.Count, $kurtarilan, $hata, $tipHata, $jsonYok)
$ornekler | ForEach-Object { Write-Host ("  ornek: {0}" -f $_) }

# 5) dosya dosya uygula + ara-kayit (rebase cakismasina karsi dosya-basi commit)
$gecti=0; $karantina=0; $rapor=@()
foreach($fd in $dosyalar){
  $j = Get-Content $fd.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  $degisti=$false
  foreach($s in @($j.sorular)){
    if($s.durum -ne 'katman1-temiz'){ continue }
    $kr = $kararlar["$($s.id)"]
    if(-not $kr){ continue }
    $cevapUyar = ("$($kr.benimCevap)".Trim().ToUpper() -eq "$($s.dogru)".Trim().ToUpper())
    if($cevapUyar){
      $s.durum = 'paket-havuzu'
      $damga = if($kr.gecerli -eq $true){ 'haiku-batch-onay' } else { 'haiku-batch-onay-ifade-notu' }
      $s | Add-Member -NotePropertyName 'katman2' -NotePropertyValue $damga -Force
      if($kr.gecerli -ne $true){ $s | Add-Member -NotePropertyName 'ifadeNotu' -NotePropertyValue "$($kr.sebep)" -Force }
      $gecti++
    } else {
      $s.durum = 'karantina'
      $s | Add-Member -NotePropertyName 'redSebep' -NotePropertyValue ("katman2-haiku: cevap-anlasmazligi, dogru=$($s.dogru) haiku=$($kr.benimCevap), sebep=$($kr.sebep)") -Force
      $karantina++
      $rapor += "KARANTINA [$($s.ders)/$($s.konu)] dogru=$($s.dogru) haiku=$($kr.benimCevap): $($kr.sebep)"
    }
    $degisti=$true
  }
  if($degisti){
    [IO.File]::WriteAllText($fd.FullName, ($j | ConvertTo-Json -Depth 8), $enc)
    if($env:GITHUB_ACTIONS -eq 'true'){
      try {
        git add -- $fd.FullName 2>$null
        git commit -m ("K2 ara kayit: " + $fd.Name + " denetlendi") 2>$null | Out-Null
        $pushOldu = $false
        foreach($den in 1..4){
          git pull --rebase origin main 2>$null | Out-Null
          if($LASTEXITCODE -ne 0){ git rebase --abort 2>$null; git pull --no-rebase -s recursive -X ours origin main 2>$null | Out-Null }
          git push origin HEAD:main 2>$null | Out-Null
          if($LASTEXITCODE -eq 0){ $pushOldu = $true; break }
          Start-Sleep -Seconds 8
        }
        if(-not $pushOldu){ Write-Host ("UYARI: ara kayit pushlanamadi (" + $fd.Name + ")") }
      } catch { Write-Host ("ara kayit hatasi: " + $_.Exception.Message) }
    }
  }
}

# 6) rapor
$kalan=0; Get-ChildItem (Join-Path $kok "veri/fabrika") -Filter *.json | ForEach-Object { try{ $kalan += @((Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json).sorular | Where-Object { $_.durum -eq 'katman1-temiz' }).Count }catch{} }
$ozet = [ordered]@{
  calisti = (Get-Date -Format "dd.MM.yyyy HH:mm")
  islenen = $kararlar.Count; kasaya = $gecti; karantina = $karantina; hata = $hata
  onayci = 'haiku-batch'; batch = $b.id
  kalan_katman1_temiz = $kalan
  karantina_ornekleri = @($rapor | Select-Object -First 40)
}
$raporYol = Join-Path $kok "veri/soru-denetci-rapor.json"
$gecmis = @(); if(Test-Path $raporYol){ try{ $gecmis = @(Get-Content $raporYol -Raw -Encoding UTF8 | ConvertFrom-Json) }catch{} }
$gecmis += $ozet
[IO.File]::WriteAllText($raporYol, ($gecmis | ConvertTo-Json -Depth 6), $enc)
Write-Host "==== K2 v2 (BATCH) SONUC ===="
Write-Host ("Islenen: {0} | Kasaya: {1} | Karantina: {2} | Hata: {3} | Kalan: {4}" -f $kararlar.Count,$gecti,$karantina,$hata,$kalan)
exit 0
# tani 08:26
# tetik 27.07 02:26:32
