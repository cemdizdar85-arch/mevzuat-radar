# ============================================================================
#  SORU DENETCISI — Katman-2 (BAGIMSIZ ICERIK DOGRULAMASI, bedava Gemini)
#  Cem karari 24.07 ("1"): Katman-1'i (yapisal) gecen durum='katman1-temiz'
#  sinav sorularini BAGIMSIZ bir yapay zeka (Gemini 2.0 Flash) kendi bilgisiyle
#  cozer ve isaretli dogru cevabi CURUTMEYE calisir.
#   - Gemini "gecerli + benim cevabim da ayni sik" -> durum='paket-havuzu' (kasaya hazir)
#   - Gemini suphe/itiraz -> durum='karantina' (SILINMEZ - GM sabah okumasina)
#  Kota (RESOURCE_EXHAUSTED/429) gelince zarifce durur, ilerlemeyi kaydeder,
#  exit 0 -> ertesi gun kaldigi yerden devam (idempotent: yalniz katman1-temiz islenir).
#  ENV: GEMINI_API_KEY zorunlu (yoksa atlar). Ucretsiz - "indirimsiz-yasak" kuralina uyar.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$enc  = New-Object Text.UTF8Encoding($false)
$BEKLEME_MS = 4500      # ~13 istek/dk (free tier 15 RPM sinirinin altinda)
$KOSU_TAVANI = 1400     # gunluk free kota (~1500 RPD) icinde kal; kalani ertesi gun

$gkey = $env:GEMINI_API_KEY
if(-not $gkey){ Write-Host "GEMINI_API_KEY yok - Soru Denetcisi K2 atlandi."; exit 0 }

function JsonBul($t){ $m=[regex]::Match($t,'(?s)\{.*\}'); if($m.Success){ return $m.Value }; return $null }

function GeminiDenetle($istemMetni){
  $body = @{ contents=@(@{ parts=@(@{ text=$istemMetni }) }); generationConfig=@{ temperature=0.1 } } | ConvertTo-Json -Depth 8 -Compress
  $uri = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$gkey"
  $r = Invoke-RestMethod -Method Post -Uri $uri -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -TimeoutSec 60
  return (@($r.candidates[0].content.parts) | ForEach-Object { $_.text }) -join ""
}

$dosyalar = Get-ChildItem (Join-Path $kok "veri/fabrika") -Filter *.json
$islenen=0; $gecti=0; $karantina=0; $hata=0; $kotaBitti=$false
$rapor = @()

foreach($fd in $dosyalar){
  if($kotaBitti){ break }
  $j = Get-Content $fd.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  $degisti=$false
  foreach($s in @($j.sorular)){
    if($kotaBitti){ break }
    if($s.durum -ne 'katman1-temiz'){ continue }
    if($islenen -ge $KOSU_TAVANI){ $kotaBitti=$true; break }

    $siklarStr = (@('A','B','C','D','E') | Where-Object { $s.siklar.$_ } | ForEach-Object { "$_) $($s.siklar.$_)" }) -join "`n"
    $istem = @"
Sen bagimsiz bir SMMM/mali musavirlik sinav denetcisisin. Asagidaki coktan secmeli soruyu KENDI bilginle coz, sonra isaretli 'dogru cevabi' ELESTIREL bicimde denetle.
SORU: $($s.soru)
$siklarStr
Bu soruda dogru cevap olarak "$($s.dogru)" isaretlenmis. Dayanak: $($s.kaynak)
GOREV:
1) Soruyu kendin coz, senin dogru buldugun sikki belirt.
2) Isaretli cevap ("$($s.dogru)") Turkiye mevzuatina gore SAVUNULABILIR mi? Acik bir hata, yanlis oran/sure/madde ya da mantik hatasi var mi?
3) Emin degilsen ya da isaretli cevap yanlissa "gecerli": false de. Tereddutte false.
SADECE su JSON'u dondur: {"gecerli": true veya false, "benimCevap": "A", "sebep": "kisa gerekce"}
"@
    try {
      $yanit = GeminiDenetle $istem
      $islenen++
      $js = JsonBul $yanit
      if(-not $js){ $hata++; Start-Sleep -Milliseconds $BEKLEME_MS; continue }
      $d = $js | ConvertFrom-Json
      $onay = ($d.gecerli -eq $true) -and ("$($d.benimCevap)".Trim().ToUpper() -eq "$($s.dogru)".Trim().ToUpper())
      if($onay){
        $s.durum = 'paket-havuzu'
        $s | Add-Member -NotePropertyName 'katman2' -NotePropertyValue 'gemini-onay' -Force
        $gecti++
      } else {
        $s.durum = 'karantina'
        $s | Add-Member -NotePropertyName 'redSebep' -NotePropertyValue ("katman2-gemini: gecerli=$($d.gecerli), gemini-cevap=$($d.benimCevap), sebep=$($d.sebep)") -Force
        $karantina++
        $rapor += "KARANTINA [$($s.ders)/$($s.konu)] dogru=$($s.dogru) gemini=$($d.benimCevap): $($d.sebep)"
      }
      $degisti=$true
      Start-Sleep -Milliseconds $BEKLEME_MS
    } catch {
      $mesaj = "$($_.Exception.Message)"
      if($mesaj -match '429|quota|RESOURCE_EXHAUSTED|Too Many|exhausted'){
        Write-Host "Gemini gunluk kota doldu - kaldigi yerde durduruldu (ertesi gun devam)."
        $kotaBitti=$true; break
      }
      $hata++
      Start-Sleep -Milliseconds $BEKLEME_MS
    }
  }
  if($degisti){ [IO.File]::WriteAllText($fd.FullName, ($j | ConvertTo-Json -Depth 8), $enc) }
}

$kalan=0; Get-ChildItem (Join-Path $kok "veri/fabrika") -Filter *.json | ForEach-Object { try{ $kalan += @((Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json).sorular | Where-Object { $_.durum -eq 'katman1-temiz' }).Count }catch{} }

$ozet = [ordered]@{
  calisti = (Get-Date -Format "dd.MM.yyyy HH:mm")
  islenen = $islenen; kasaya = $gecti; karantina = $karantina; hata = $hata
  kalan_katman1_temiz = $kalan; kota_bitti = $kotaBitti
  karantina_ornekleri = @($rapor | Select-Object -First 40)
}
$raporYol = Join-Path $kok "veri/soru-denetci-rapor.json"
$gecmis = @(); if(Test-Path $raporYol){ try{ $gecmis = @(Get-Content $raporYol -Raw -Encoding UTF8 | ConvertFrom-Json) }catch{} }
$gecmis += $ozet
[IO.File]::WriteAllText($raporYol, ($gecmis | ConvertTo-Json -Depth 6), $enc)

Write-Host "==== SORU DENETCISI K2 SONUC ===="
Write-Host ("Islenen: {0} | Kasaya: {1} | Karantina: {2} | Hata: {3} | Kalan: {4}" -f $islenen,$gecti,$karantina,$hata,$kalan)
exit 0
