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
$akey = $env:ANTHROPIC_API_KEY   # Cem 24.07 onayi: Gemini olmazsa %50 Haiku'ya dus (sistem durmasin)
$HAIKU_MODEL = "claude-haiku-4-5-20251001"
$HAIKU_TAVANI = 3500            # maliyet emniyeti: gecede en fazla bu kadar Haiku cagrisi
if(-not $gkey -and -not $akey){ Write-Host "Ne GEMINI ne ANTHROPIC anahtari var - K2 atlandi."; exit 0 }

function JsonBul($t){ $m=[regex]::Match($t,'(?s)\{.*\}'); if($m.Success){ return $m.Value }; return $null }

$script:geminiOlmez = (-not $gkey)   # Gemini denenmeden once yoksa dogrudan Haiku
$script:haikuSayac = 0
$script:geminiBasari = 0
$script:geminiHata = 0

function GeminiDenetle($istemMetni){
  $body = @{ contents=@(@{ parts=@(@{ text=$istemMetni }) }); generationConfig=@{ temperature=0.1 } } | ConvertTo-Json -Depth 8 -Compress
  $uri = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$gkey"
  $r = Invoke-RestMethod -Method Post -Uri $uri -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -TimeoutSec 60
  return (@($r.candidates[0].content.parts) | ForEach-Object { $_.text }) -join ""
}

# YEDEK ONAYCI: Haiku (%50 degil ama en ucuz model; sabit yonerge onbellekli -> girdi ~%90 duser)
$HAIKU_YONERGE = "Sen bagimsiz bir SMMM/mali musavirlik sinav denetcisisin. Verilen coktan secmeli soruyu KENDI bilginle coz, sonra isaretli dogru cevabi elestirel denetle. Isaretli cevap Turkiye mevzuatina gore savunulabilir mi, acik hata/yanlis oran/yanlis madde/mantik hatasi var mi? Emin degilsen ya da yanlissa gecerli=false. SADECE su JSON'u dondur: {`"gecerli`": true veya false, `"benimCevap`": `"A`", `"sebep`": `"kisa`"}"
function HaikuDenetle($degiskenMetin){
  $body = @{ model=$HAIKU_MODEL; max_tokens=400; messages=@(@{ role="user"; content=@(
    @{ type="text"; text=$HAIKU_YONERGE; cache_control=@{ type="ephemeral" } },
    @{ type="text"; text=$degiskenMetin }) }) } | ConvertTo-Json -Depth 8 -Compress
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" `
        -Headers @{ "x-api-key"=$akey; "anthropic-version"="2023-06-01" } `
        -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -TimeoutSec 120
  $script:haikuSayac++
  return (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
}

# Tek denetim: Gemini calisirsa onu, olmazsa Haiku'yu kullan. Yaniti (json metni) dondur.
function Denetle($istemMetni){
  if(-not $script:geminiOlmez){
    try { return (GeminiDenetle $istemMetni) }
    catch {
      $m = "$($_.Exception.Message)"
      if($m -match 'RESOURCE_EXHAUSTED|quota|Too Many Requests' -and $script:geminiBasari -ge 1){ throw "GEMINI_KOTA" }
      # ilk isteklerde surekli hata -> Gemini bu kosuda olmez, Haiku'ya gec
      $script:geminiHata++
      if($script:geminiHata -ge 2){ Write-Host "Gemini calismiyor - Haiku yedegine gecildi."; $script:geminiOlmez = $true }
      else { throw "GEMINI_GECICI" }
    }
  }
  if(-not $akey){ throw "YEDEK_YOK" }
  if($script:haikuSayac -ge $HAIKU_TAVANI){ throw "HAIKU_TAVAN" }
  return (HaikuDenetle $istemMetni)
}

$dosyalar = Get-ChildItem (Join-Path $kok "veri/fabrika") -Filter *.json
$islenen=0; $gecti=0; $karantina=0; $hata=0; $kotaBitti=$false
$rapor = @()
$tanilar = @()   # ilk hatalarin HAM mesajlari (teshis icin)

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
      $haikuMuydu = $script:geminiOlmez
      $yanit = Denetle $istem
      $islenen++
      if(-not $script:geminiOlmez){ $script:geminiBasari++ }
      $js = JsonBul $yanit
      if(-not $js){ $hata++; continue }
      $d = $js | ConvertFrom-Json
      $onayci = if($script:geminiOlmez -or $haikuMuydu){ 'haiku' } else { 'gemini' }
      $onay = ($d.gecerli -eq $true) -and ("$($d.benimCevap)".Trim().ToUpper() -eq "$($s.dogru)".Trim().ToUpper())
      if($onay){
        $s.durum = 'paket-havuzu'
        $s | Add-Member -NotePropertyName 'katman2' -NotePropertyValue "$onayci-onay" -Force
        $gecti++
      } else {
        $s.durum = 'karantina'
        $s | Add-Member -NotePropertyName 'redSebep' -NotePropertyValue ("katman2-${onaycı}: gecerli=$($d.gecerli), cevap=$($d.benimCevap), sebep=$($d.sebep)") -Force
        $karantina++
        $rapor += "KARANTINA [$($s.ders)/$($s.konu)] dogru=$($s.dogru) $onayci=$($d.benimCevap): $($d.sebep)"
      }
      $degisti=$true
      if(-not $script:geminiOlmez){ Start-Sleep -Milliseconds $BEKLEME_MS }   # yalniz Gemini icin hiz sinir bekleme
    } catch {
      $mesaj = "$($_.Exception.Message)"
      if($tanilar.Count -lt 5){ $tanilar += $mesaj }
      if($mesaj -match 'GEMINI_KOTA'){ Write-Host "Gemini kotasi doldu - Haiku yedegine geciliyor."; $script:geminiOlmez=$true; continue }
      if($mesaj -match 'HAIKU_TAVAN'){ Write-Host "Haiku gece tavani doldu - durduruldu (yarin devam)."; $kotaBitti=$true; break }
      if($mesaj -match 'YEDEK_YOK'){ Write-Host "Gemini yok, ANTHROPIC yedegi de yok - durduruldu."; $kotaBitti=$true; break }
      $hata++
      if($hata -ge 5 -and $islenen -eq 0){ Write-Host "Ilk isteklerde surekli hata - durduruldu."; $kotaBitti=$true; break }
      Start-Sleep -Milliseconds 1500
    }
  }
  if($degisti){ [IO.File]::WriteAllText($fd.FullName, ($j | ConvertTo-Json -Depth 8), $enc) }
}

$kalan=0; Get-ChildItem (Join-Path $kok "veri/fabrika") -Filter *.json | ForEach-Object { try{ $kalan += @((Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json).sorular | Where-Object { $_.durum -eq 'katman1-temiz' }).Count }catch{} }

$ozet = [ordered]@{
  calisti = (Get-Date -Format "dd.MM.yyyy HH:mm")
  islenen = $islenen; kasaya = $gecti; karantina = $karantina; hata = $hata
  gemini_basari = $script:geminiBasari; haiku_cagri = $script:haikuSayac; onayci = $(if($script:geminiOlmez){'haiku-yedek'}else{'gemini'})
  kalan_katman1_temiz = $kalan; kota_bitti = $kotaBitti
  ham_hata_tanilari = @($tanilar)
  karantina_ornekleri = @($rapor | Select-Object -First 40)
}
$raporYol = Join-Path $kok "veri/soru-denetci-rapor.json"
$gecmis = @(); if(Test-Path $raporYol){ try{ $gecmis = @(Get-Content $raporYol -Raw -Encoding UTF8 | ConvertFrom-Json) }catch{} }
$gecmis += $ozet
[IO.File]::WriteAllText($raporYol, ($gecmis | ConvertTo-Json -Depth 6), $enc)

Write-Host "==== SORU DENETCISI K2 SONUC ===="
Write-Host ("Islenen: {0} | Kasaya: {1} | Karantina: {2} | Hata: {3} | Kalan: {4}" -f $islenen,$gecti,$karantina,$hata,$kalan)
exit 0
