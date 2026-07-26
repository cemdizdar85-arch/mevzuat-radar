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
SADECE su JSON'u dondur: {"gecerli": true veya false, "benimCevap": "A", "sebep": "kisa gerekce"}
"@
      $adaylar += [ordered]@{ id="$($s.id)"; istem=$istem }
    }
  } catch { Write-Host ("UYARI: {0} okunamadi" -f $fd.Name) }
}
Write-Host ("K2 adayi: {0}" -f $adaylar.Count)
if($adaylar.Count -eq 0){ Write-Host "Denetlenecek soru yok."; exit 0 }

# 2) tek batch gonder (%50, Haiku)
$istekler = @($adaylar | ForEach-Object { @{ custom_id=$_.id; params=@{ model=$MODEL; max_tokens=400; messages=@(@{ role='user'; content=$_.istem }) } } })
$govde = @{ requests = $istekler } | ConvertTo-Json -Depth 8
$b = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages/batches" `
      -Headers @{ "x-api-key"=$AKEY; "anthropic-version"="2023-06-01" } `
      -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 300
Write-Host ("Batch gonderildi: {0} ({1} gorev)" -f $b.id, $istekler.Count)

# 3) poll (240 dk tavan)
$bekleme=0
while($true){
  Start-Sleep -Seconds 60
  $bekleme++
  $d = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages/batches/$($b.id)" `
        -Headers @{ "x-api-key"=$AKEY; "anthropic-version"="2023-06-01" } -TimeoutSec 60
  if($d.processing_status -eq 'ended'){ break }
  if($bekleme -ge 240){ Write-Host "Poll tavani - batch surse de kosu birakiyor (sonraki cron yeni batch acar)."; exit 0 }
}
$sonuclar = Invoke-WebRequest -Uri $d.results_url -Headers @{ "x-api-key"=$AKEY; "anthropic-version"="2023-06-01" } -TimeoutSec 600 -UseBasicParsing
$satirlar = ($sonuclar.Content -split "`n") | Where-Object { $_.Trim() }

# 4) kararlar haritasi
$kararlar = @{}
$hata = 0
foreach($ln in $satirlar){
  try {
    $rj = $ln | ConvertFrom-Json
    if($rj.result.type -ne 'succeeded'){ $hata++; continue }
    $metin = (@($rj.result.message.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
    $js = JsonBul $metin
    if(-not $js){ $hata++; continue }
    $kararlar[$rj.custom_id] = ($js | ConvertFrom-Json)
  } catch { $hata++ }
}
Write-Host ("Karar geldi: {0} | sonuc-hatasi: {1}" -f $kararlar.Count, $hata)

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
