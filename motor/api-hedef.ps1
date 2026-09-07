# ============================================================================
#  API HEDEF KATMANI - UC HAT (Anthropic / AWS / OpenRouter)   (16.08.2026)
#
#  NEDEN: Anthropic Build tier 1.000 USD tavani doldu, self-servis acilmadi;
#  AWS Claude Platform kaydi da acilmadi. Cem karari (16.08): birincil hat
#  kendi Anthropic anahtarimiz kalsin; LIMIT/kota hatasi gelince istek
#  OTOMATIK olarak OpenRouter yedek hattina gecsin (ayni Claude modelleri,
#  Anthropic saglayicisina sabit, middle-out kirpma KAPALI -> kalite AYNI).
#
#  ONEMLI BICIM FARKI:
#    - Anthropic  : POST {taban}/v1/messages ; govde {model,max_tokens,messages}
#                   yanit r.content[0].text ; usage.input_tokens/output_tokens
#                   goruntu blogu {type:image, source:{type:base64,media_type,data}}
#    - OpenRouter : POST https://openrouter.ai/api/v1/chat/completions (OpenAI bicimi)
#                   Authorization: Bearer OPENROUTER_KEY
#                   yanit r.choices[0].message.content ; usage.prompt_tokens/completion_tokens
#                   goruntu blogu {type:image_url, image_url:{url:"data:...;base64,..."}}
#                   model adi 'anthropic/claude-haiku-4.5' gibi (nokta ile)
#  Bu dosya farki gizler: cagiran Anthropic bicimini verir, biz cevirir/geri ceviririz.
#
#  KULLANIM (ONERILEN - tek fonksiyon, yedek dahil):
#    . (Join-Path $PSScriptRoot 'api-hedef.ps1')
#    $r = Invoke-ClaudeMesaj -Model 'claude-haiku-4-5' -Icerik $icerikDizisi -MaxTok 6000
#    $r.metin  -> cevap metni (Turkce duzeltmesi yapilmis)
#    $r.girdi  -> girdi token ; $r.cikti -> cikti token ; $r.kaynak -> 'anthropic'|'aws'|'openrouter'
#    $r.dur    -> bitis sebebi ; 'max_tokens' = cevap KESILDI (iki hatta da ayni ad)
#    ($Icerik = Anthropic icerik blogu dizisi: @(@{type='text';text=...}, @{type='image';source=...})
#      ya da DUZ METIN: -Icerik $istem  -> icerde text blogua sarilir)
#
#  ESKI KULLANIM (batch API'si icin hala gecerli - Get-ApiHedef target dondurur):
#    $H = Get-ApiHedef ; $H.taban ; $H.basliklar ; $H.ad  (batch OpenRouter'da YOK)
#
#  SECIM SIRASI (Get-ApiHedef):
#    1. -zorla ('anthropic'|'aws'|'openrouter')
#    2. MEVZUAT_API_HEDEF ortam degiskeni
#    3. AWS uclusu tamsa -> aws ; degilse -> anthropic
#
#  ORTAM DEGISKENLERI (degerlerini gormeyiz - GitHub secret / User env):
#    ANTHROPIC_API_KEY          = birincil hat (kendi anahtarimiz)
#    OPENROUTER_KEY             = yedek hat (limit dolunca)
#    ANTHROPIC_AWS_API_KEY / AWS_REGION / ANTHROPIC_AWS_WORKSPACE_ID = AWS hat (opsiyonel)
# ============================================================================

# --- ortam degiskeni okuyucu (User -> Process -> Machine) --------------------
function Read-ApiEnv([string]$ad){
  $v = [Environment]::GetEnvironmentVariable($ad,'User')
  if(-not $v){ $v = [Environment]::GetEnvironmentVariable($ad,'Process') }
  if(-not $v){ $v = [Environment]::GetEnvironmentVariable($ad,'Machine') }
  return $v
}

function Test-AnthropicVar {
  if(Read-ApiEnv 'ANTHROPIC_API_KEY'){ return $true }
  if((Read-ApiEnv 'ANTHROPIC_AWS_API_KEY') -and (Read-ApiEnv 'AWS_REGION') -and (Read-ApiEnv 'ANTHROPIC_AWS_WORKSPACE_ID')){ return $true }
  # yerel gelistirici dosyasi (CI'da yok)
  if(Test-Path 'C:\Users\cemdi\.mevzuat-radar-api'){ return $true }
  return $false
}

function Get-ApiHedef {
  param([string]$zorla = '')

  $awsAnahtar = Read-ApiEnv 'ANTHROPIC_AWS_API_KEY'
  $awsBolge   = Read-ApiEnv 'AWS_REGION'
  $awsCalisma = Read-ApiEnv 'ANTHROPIC_AWS_WORKSPACE_ID'
  $antAnahtar = Read-ApiEnv 'ANTHROPIC_API_KEY'
  if(-not $antAnahtar){ try { $antAnahtar = (Get-Content 'C:\Users\cemdi\.mevzuat-radar-api' -Raw).Trim() } catch {} }
  $awsTam = ($awsAnahtar -and $awsBolge -and $awsCalisma)

  $sec = $zorla
  if(-not $sec){ $sec = Read-ApiEnv 'MEVZUAT_API_HEDEF' }
  if(-not $sec){ $sec = if($awsTam){ 'aws' } else { 'anthropic' } }
  $sec = $sec.ToLower()

  if($sec -eq 'openrouter'){
    $orAnahtar = Read-ApiEnv 'OPENROUTER_KEY'
    if(-not $orAnahtar){ throw 'OpenRouter hedefi istendi ama OPENROUTER_KEY yok.' }
    # NOT: OpenRouter Anthropic-native /v1/messages ve batch API'sini DESTEKLEMEZ.
    # Bu target yalniz Invoke-ClaudeMesaj (anlik) ile kullanilir; batch scriptleri kullanamaz.
    return [pscustomobject]@{
      ad='openrouter'; taban='https://openrouter.ai/api/v1'; anahtar=$orAnahtar
      basliklar=@{ 'Authorization'=('Bearer ' + $orAnahtar); 'X-Title'='Tetikte' }
    }
  }

  if($sec -eq 'aws'){
    $eksik = @()
    if(-not $awsAnahtar){ $eksik += 'ANTHROPIC_AWS_API_KEY' }
    if(-not $awsBolge){   $eksik += 'AWS_REGION' }
    if(-not $awsCalisma){ $eksik += 'ANTHROPIC_AWS_WORKSPACE_ID' }
    if($eksik.Count -gt 0){ throw ("AWS hedefi istendi ama ortam degiskeni eksik: {0}." -f ($eksik -join ', ')) }
    if($awsCalisma -notlike 'wrkspc_*'){ throw "ANTHROPIC_AWS_WORKSPACE_ID 'wrkspc_' ile baslamali." }
    return [pscustomobject]@{
      ad='aws'; taban=('https://aws-external-anthropic.{0}.api.aws' -f $awsBolge); anahtar=$awsAnahtar
      basliklar=@{ 'x-api-key'=$awsAnahtar; 'anthropic-version'='2023-06-01'; 'anthropic-workspace-id'=$awsCalisma }
    }
  }

  if(-not $antAnahtar){ throw 'Anthropic hedefi icin ANTHROPIC_API_KEY yok.' }
  return [pscustomobject]@{
    ad='anthropic'; taban='https://api.anthropic.com'; anahtar=$antAnahtar
    basliklar=@{ 'x-api-key'=$antAnahtar; 'anthropic-version'='2023-06-01' }
  }
}

# HttpClient kullanan betikler icin: basliklari istemciye tak
function Add-ApiBasliklar {
  param($istemci, $hedef)
  foreach($k in $hedef.basliklar.Keys){
    [void]$istemci.DefaultRequestHeaders.Remove($k)
    $istemci.DefaultRequestHeaders.Add($k, $hedef.basliklar[$k])
  }
}

# ============================================================================
#  ANLIK CAGRI KATMANI (Invoke-ClaudeMesaj) - yedek gecisli
# ============================================================================

# birincil hat bir kez 'tukendi' damgasi yerse ayni kosuda hep OpenRouter'a gider
# (her istekte once Anthropic'i deneyip 429 yemek gereksiz round-trip'tir)
$script:AnthropicTukendi = $false

# Anthropic model adi -> OpenRouter slug (nokta bicimi, anthropic/ onekli)
function ConvertTo-ORModel([string]$m){
  switch -Regex ($m){
    '^claude-haiku-4-5'  { return 'anthropic/claude-haiku-4.5' }
    '^claude-sonnet-5'   { return 'anthropic/claude-sonnet-5' }
    '^claude-sonnet-4-5' { return 'anthropic/claude-sonnet-4.5' }
    '^claude-opus-4-8'   { return 'anthropic/claude-opus-4.8' }
    '^claude-opus-5'     { return 'anthropic/claude-opus-5' }
    default {
      if($m -like 'anthropic/*'){ return $m }
      $t = $m -replace '(\d)-(\d)$','$1.$2'   # ...-4-5 -> ...-4.5
      return ('anthropic/' + $t)
    }
  }
}

# Cagiran duz metin de verebilir ("...istem...") ya da tek blok. Hepsini
# Anthropic blok dizisine cevir - yoksa OpenAI cevirisi bos content uretir
# (16.08: 14 anlik betigin cogu content olarak duz string veriyordu).
function ConvertTo-IcerikBloklari($icerik){
  $out = @()
  foreach($blok in @($icerik)){
    if($null -eq $blok){ continue }
    if($blok -is [string]){ $out += @{ type='text'; text=$blok } }
    else { $out += $blok }
  }
  return ,$out
}

# Anthropic icerik blogu dizisi -> OpenAI content dizisi
# KURAL: tanimadigi blogu SESSIZCE DUSURMEZ, hata firlatir. Sessiz dusurme
# 16.08'de yakalandi: sinav-analiz PDF'i 'document' blogu ile yolluyordu,
# cevirici onu atiyordu -> model bos istem gorup "analiz edemedim" diyecekti.
function ConvertTo-OpenAiIcerik($icerik){
  $out = @()
  foreach($blok in @($icerik)){
    if($blok.type -eq 'text'){
      # cache_control yedek hatta tasinmaz: sonuc AYNI, girdi maliyeti tam odenir.
      # Kosu basina bir kez uyar (her cagrida bagirmasin).
      if($blok.cache_control -and -not $script:OnbellekUyarisi){
        $script:OnbellekUyarisi = $true
        Write-Host '  [!] Yedek hatta prompt onbellegi (cache_control) yok - girdi maliyeti tam odenir, cikti kalitesi ayni.' -ForegroundColor Yellow
      }
      $out += @{ type='text'; text=[string]$blok.text }
    } elseif($blok.type -eq 'image'){
      $src = $blok.source
      $url = ('data:{0};base64,{1}' -f $src.media_type, $src.data)
      $out += @{ type='image_url'; image_url=@{ url=$url } }
    } elseif($blok.type -eq 'document'){
      # OpenRouter PDF: {type:'file', file:{filename, file_data:'data:...;base64,...'}}
      # DIKKAT: bu yol CANLI OLCULMEDI (yalniz Anthropic hattinda kosuldu). PDF
      # kosulari pahalidir (sayfa basina token); kor bir kosunun 169 kitapcigi
      # cope yazmasindansa DURUR. Tek PDF'lik prob yapilip dogrulaninca
      # MEVZUAT_YEDEK_PDF=1 verilir ve bu yol acilir.
      if((Read-ApiEnv 'MEVZUAT_YEDEK_PDF') -ne '1'){
        throw 'PDF (document) blogu yedek hattan (OpenRouter) gecirilmek istendi ama bu yol henuz OLCULMEDI. Once tek PDF ile prob yap, sonra MEVZUAT_YEDEK_PDF=1 ver. (Anthropic hatti acikken bu hata cikmaz.)'
      }
      if($blok.cache_control){ Write-Host '  [!] Yedek hatta PDF onbellegi (cache_control) tasinmadi - girdi maliyeti tam odenir.' -ForegroundColor Yellow }
      $src = $blok.source
      $url = ('data:{0};base64,{1}' -f $src.media_type, $src.data)
      $ad  = if($blok.ad){ [string]$blok.ad } else { 'belge.pdf' }
      $out += @{ type='file'; file=@{ filename=$ad; file_data=$url } }
    } else {
      throw ("OpenRouter cevirisi taniyamadigi icerik blogu ile karsilasti: '{0}'. Sessizce dusurmek yerine durduruldu - cevirici genisletilmeli." -f $blok.type)
    }
  }
  return ,$out
}

# PS 5.1: Invoke-RestMethod UTF-8'i Latin-1 sanar -> geri cevir. pwsh 7 dogru cozer.
function Repair-ClaudeMetin($r){
  if($PSVersionTable.PSVersion.Major -le 5 -and $r.metin){
    $r.metin = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding('ISO-8859-1').GetBytes($r.metin))
  }
  return $r
}

# 'ad' bizim ic alanimiz (OpenRouter dosya adi icin). Anthropic bilmedigi alani
# 400 ile reddeder -> gondermeden once ayikla.
function ConvertTo-AnthropicIcerik($icerik){
  $out = @()
  foreach($blok in @($icerik)){
    if($blok -is [hashtable] -and $blok.ContainsKey('ad')){
      $kopya = @{}
      foreach($k in $blok.Keys){ if($k -ne 'ad'){ $kopya[$k] = $blok[$k] } }
      $out += $kopya
    } else { $out += $blok }
  }
  return ,$out
}

function Invoke-AnthropicAnlik([string]$model,[array]$icerik,[int]$maxTok,$hedef){
  $temiz = ConvertTo-AnthropicIcerik $icerik
  $g = @{ model=$model; max_tokens=$maxTok; messages=@(@{ role='user'; content=@($temiz) }) }
  # 07.09 ölçüldü (maliyet-zor2): Sonnet 5'te thinking verilmezse UYARLANABİLİR DÜŞÜNME açık ve düşünme jetonları max_tokens'tan
  # yenir → 20.000 çıktı jetonu harcanıp 2.588 karakter metin döndü, JSON kesildi. Sonnet 5 / Opus 5'te düşünme derinliği
  # effort=medium ile sınırlanır (GA, output_config içinde); MEVZUAT_EFFORT ortam değişkeniyle değiştirilebilir (low|medium|high).
  if($model -match 'sonnet-5|opus-5'){ $ef = Read-ApiEnv 'MEVZUAT_EFFORT'; if(-not $ef){ $ef = 'medium' }; $g.output_config = @{ effort = $ef } }
  $govde = $g | ConvertTo-Json -Depth 20
  $r = Invoke-RestMethod -Method Post -Uri ($hedef.taban + '/v1/messages') -Headers $hedef.basliklar -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType 'application/json' -TimeoutSec 240
  # content[0] her zaman metin DEGILDIR (dusunme blogu one gelebilir) -> tum metin bloklarini birlestir
  $metin = (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { "$($_.text)" }) -join ''
  # dur = bitis sebebi; 'max_tokens' ise cevap KESILMISTIR (onarim-motoru bunu okur)
  # 17.08 ONBELLEK MUHASEBESI. Anthropic'te input_tokens YALNIZ son onbellek
  # sinirindan SONRAKI jetonlari sayar; gercek toplam sudur:
  #     toplam = cache_read + cache_creation + input_tokens
  # Bu alanlar dondurulmezse cache_control ekleyen her betik girdiyi EKSIK
  # raporlar (maliyet olcumu sessizce yanlis cikar) ve onbellegin calisip
  # calismadigi DOGRULANAMAZ. Dokumanin kendi kontrolu: onbellek isabet
  # ediyorsa onbellekOkuma > 0 olur.
  # 'girdi' ANLAMI KORUNUR (ham input_tokens) - eski cagiranlar bozulmasin;
  # gercek toplam icin 'girdiToplam' kullanilir.
  $oYaz = 0; $oOku = 0
  try { $oYaz = [int]"$($r.usage.cache_creation_input_tokens)" } catch {}
  try { $oOku = [int]"$($r.usage.cache_read_input_tokens)" } catch {}
  $ham = 0; try { $ham = [int]"$($r.usage.input_tokens)" } catch {}
  return @{ metin=$metin.Trim(); girdi=$ham; cikti=[int]"$($r.usage.output_tokens)";
            onbellekYazma=$oYaz; onbellekOkuma=$oOku; girdiToplam=($ham + $oYaz + $oOku)
            kaynak=$hedef.ad; dur="$($r.stop_reason)" }
}

function Invoke-OpenRouterAnlik([string]$model,[array]$icerik,[int]$maxTok){
  $key = Read-ApiEnv 'OPENROUTER_KEY'
  if(-not $key){ throw 'OPENROUTER_KEY yok - yedek hat kullanilamiyor.' }
  $orModel = ConvertTo-ORModel $model
  $oaIcerik = ConvertTo-OpenAiIcerik $icerik
  # provider: yalniz Anthropic (baska saglayiciya dusme) ; transforms: [] (middle-out kirpma KAPALI)
  $body = [ordered]@{
    model      = $orModel
    max_tokens = $maxTok
    messages   = @(@{ role='user'; content=@($oaIcerik) })
    provider   = @{ order=@('anthropic'); allow_fallbacks=$false }
  }
  $govde = $body | ConvertTo-Json -Depth 20
  # PS 5.1 bos diziyi bazen "" yapar; transforms:[] alanini elle, garantili ekle
  $govde = $govde -replace '\}\s*$', ',"transforms":[]}'
  $hdr = @{ 'Authorization'=('Bearer ' + $key); 'X-Title'='Tetikte' }
  $r = Invoke-RestMethod -Method Post -Uri 'https://openrouter.ai/api/v1/chat/completions' -Headers $hdr -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType 'application/json' -TimeoutSec 240
  $c = $r.choices[0].message.content
  if($c -is [array]){ $c = ($c | ForEach-Object { $_.text }) -join '' }
  # OpenAI bicimi finish_reason='length' der; Anthropic karsiligi 'max_tokens' (kesildi)
  $dur = "$($r.choices[0].finish_reason)"
  if($dur -eq 'length'){ $dur = 'max_tokens' } elseif($dur -eq 'stop'){ $dur = 'end_turn' }
  # Yedek hatta prompt onbellegi TASINMADIGI icin onbellek alanlari daima 0'dir
  # ve prompt_tokens ZATEN tam girdiyi sayar - girdiToplam = girdi.
  $hamO = 0; try { $hamO = [int]"$($r.usage.prompt_tokens)" } catch {}
  return @{ metin=("$c").Trim(); girdi=$hamO; cikti=[int]"$($r.usage.completion_tokens)";
            onbellekYazma=0; onbellekOkuma=0; girdiToplam=$hamO
            kaynak='openrouter'; dur=$dur }
}

# Birincil hat KULLANILAMAZ mi? (limit/kota YA DA gecersiz kimlik) -> yedege gec
function Test-LimitHatasi($err){
  $status = 0
  try { $status = [int]$err.Exception.Response.StatusCode } catch {}
  if($status -eq 429 -or $status -eq 402){ return $true }
  # 17.08 EKLENDI - 401/403 de yedege gecirtir.
  # Olculdu: yerel Anthropic anahtari 401 donduruyordu ve yedek hat DEVREYE
  # GIRMIYORDU (kosul yalniz 429/402'ydi). Anahtar iptal edilir ya da rotasyona
  # girerse butun robotlar sessizce olurdu - oysa OpenRouter'in kimligi AYRI,
  # calismaya devam edebilirdi. Kimlik hatasi da "bu hat kullanilamaz"dir.
  if($status -eq 401 -or $status -eq 403){ return $true }
  $body = ''
  try { $body = "$($err.ErrorDetails.Message)" } catch {}
  if(-not $body){
    try {
      $rs = $err.Exception.Response.GetResponseStream()
      $sr = New-Object System.IO.StreamReader($rs)
      $body = $sr.ReadToEnd()
    } catch {}
  }
  # 16.08 OLCULDU - KOPRUNUN COKTUGU YER BURASIYDI:
  # Anthropic tavan hatasini 429 DEGIL, HTTP 400 invalid_request_error olarak
  # veriyor ve metni su: "You have reached your specified API usage limits.
  # You will regain access on 2026-09-01 at 00:00 UTC."
  # Eski desen bu cumlenin HICBIR kelimesini tutmuyordu -> yedek hat hic
  # devreye girmedi, istek 400 ile oldu, 27 teblig kart uretemedi.
  if($body -match '(?i)credit balance|spend limit|monthly limit|usage limit|reached your specified|regain access|exceeded|quota|insufficient|billing|organization.{0,30}disabled|rate.?limit|too_many_requests'){ return $true }
  return $false
}

# ANA GIRIS NOKTASI: anlik Claude cagrisi, yedek gecisli.
#   -Model  : Anthropic adi (claude-haiku-4-5, claude-sonnet-5 ...)
#   -Icerik : Anthropic icerik blogu dizisi (@{type=text/image ...})
#   -MaxTok : cikti token tavani
# doner: @{ metin; girdi; cikti; kaynak }
function Invoke-ClaudeMesaj {
  param(
    [Parameter(Mandatory=$true)][string]$Model,
    [Parameter(Mandatory=$true)][array]$Icerik,
    [int]$MaxTok = 4000,
    [switch]$YalnizOpenRouter
  )
  $orVar  = [bool](Read-ApiEnv 'OPENROUTER_KEY')
  $antVar = Test-AnthropicVar
  $Icerik = ConvertTo-IcerikBloklari $Icerik   # duz metin de kabul

  if(-not $YalnizOpenRouter -and -not $script:AnthropicTukendi -and $antVar){
    try {
      $hedef = Get-ApiHedef
      if($hedef.ad -ne 'openrouter'){
        $ySon = Repair-ClaudeMetin (Invoke-AnthropicAnlik $Model $Icerik $MaxTok $hedef)
        Add-BedelKaydi $Model $ySon
        return $ySon
      }
    } catch {
      if((Test-LimitHatasi $_) -and $orVar){
        $script:AnthropicTukendi = $true
        Write-Host '  [!] Anthropic limiti/kotasi doldu -> OpenRouter yedek hattina gecildi.' -ForegroundColor Yellow
      } else {
        throw
      }
    }
  }

  if($orVar){
    $ySon = Repair-ClaudeMetin (Invoke-OpenRouterAnlik $Model $Icerik $MaxTok)
    Add-BedelKaydi $Model $ySon
    return $ySon
  }

  throw 'Hicbir anlik Claude hatti kullanilamiyor (ANTHROPIC_API_KEY tukendi/yok ve OPENROUTER_KEY yok).'
}

# 08.09 TOPLU İSTEK (Message Batches; Cem "daha ucuza nasıl?" → %50 indirim + paralel işleme). Aynı yapıdaki N isteği tek partide gönderir,
# biter bitmez sonuçları custom_id ile eşler ve Invoke-ClaudeMesaj ile AYNI şekilde ({metin,girdi,cikti,dur,...}) döndürür; bedel defterine
# "toplu" damgasıyla yazar (Get-BedelOzet yarı fiyat uygular). Ödenen işin kimliği gönderilir gönderilmez veri/bekleyen-partiler.json'a yazılır
# (29.07 dersi: zaman aşımında sonuç ÇEKİLMEZ, kimlik kalır, sonra Get-ClaudeTopluSonuc ile bedava hasat). Yalnız Anthropic doğrudan hat (OpenRouter'da toplu yok).
#   $isler = @(@{ id='kp-01'; model='claude-sonnet-5'; icerik=$istem; maxTok=20000 }, ...)
#   $sonuc = Invoke-ClaudeToplu -Isler $isler -Etiket 'sgs-fmuh-p31/A1' -BeklemeDk 180   → hashtable id → cevap (yoksa anahtar yok; hata: $sonuc['__hata'][id])
function Get-TopluBasliklar {
  $hedef = Get-ApiHedef
  if($hedef.ad -eq 'openrouter'){ throw 'Toplu istek yalnız Anthropic doğrudan hatta çalışır (OpenRouter hedefi seçili).' }
  return $hedef
}
function Add-BekleyenParti([string]$bid,[string]$etiket){
  try{ $kok = Split-Path -Parent $PSScriptRoot; $y = Join-Path $kok 'veri\bekleyen-partiler.json'; $bek = @()
    if(Test-Path $y){ foreach($x in @(ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($y)))){ if($x){ $bek += $x } } }
    $bek += [pscustomobject]@{ id=$bid; etiket=$etiket; zaman=(Get-Date -Format 'yyyy-MM-dd HH:mm'); durum='gonderildi' }
    [IO.File]::WriteAllText($y,(ConvertTo-Json -InputObject @($bek) -Depth 3),(New-Object Text.UTF8Encoding($false))) }catch{}
}
function Set-BekleyenPartiDurum([string]$bid,[string]$durum){
  try{ $kok = Split-Path -Parent $PSScriptRoot; $y = Join-Path $kok 'veri\bekleyen-partiler.json'; if(-not (Test-Path $y)){ return }
    $bek = @(ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($y))); foreach($x in $bek){ if($x -and "$($x.id)" -eq $bid){ $x | Add-Member -NotePropertyName durum -NotePropertyValue $durum -Force } }
    [IO.File]::WriteAllText($y,(ConvertTo-Json -InputObject @($bek) -Depth 3),(New-Object Text.UTF8Encoding($false))) }catch{}
}
function Get-ClaudeTopluSonuc([string]$bid,$hedef,[string]$etiket){
  # bitmiş partinin sonuçlarını çeker; her satır custom_id → cevap
  $st = Invoke-RestMethod -Uri ($hedef.taban + "/v1/messages/batches/$bid") -Headers $hedef.basliklar -TimeoutSec 60
  if($st.processing_status -ne 'ended'){ return $null }
  $adres = $(if($st.results_url){ "$($st.results_url)" } else { $hedef.taban + "/v1/messages/batches/$bid/results" })
  $cev = Invoke-WebRequest -UseBasicParsing -Uri $adres -Headers $hedef.basliklar -TimeoutSec 600
  $ham = $(if($cev.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($cev.Content) } else { "$($cev.Content)" })
  $out = @{}; $out['__hata'] = @{}
  foreach($sat in ($ham -split "`n")){ if(-not $sat.Trim()){ continue }
    try{ $r = ConvertFrom-Json -InputObject $sat }catch{ continue }
    $cid = "$($r.custom_id)"; if(-not $cid){ continue }
    if("$($r.result.type)" -ne 'succeeded'){ $out['__hata'][$cid] = "$($r.result.type): $($r.result.error.message)"; continue }
    $m = $r.result.message
    $metin = (@($m.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { "$($_.text)" }) -join ''
    $oYaz = 0; $oOku = 0; $ham2 = 0; try { $oYaz = [int]"$($m.usage.cache_creation_input_tokens)" } catch {}; try { $oOku = [int]"$($m.usage.cache_read_input_tokens)" } catch {}; try { $ham2 = [int]"$($m.usage.input_tokens)" } catch {}
    $y = @{ metin=$metin.Trim(); girdi=$ham2; cikti=[int]"$($m.usage.output_tokens)"; onbellekYazma=$oYaz; onbellekOkuma=$oOku; girdiToplam=($ham2+$oYaz+$oOku); kaynak='anthropic-toplu'; dur="$($m.stop_reason)"; toplu=$true }
    $y = Repair-ClaudeMetin $y
    Add-BedelKaydi ("$($m.model)" + '|toplu') $y
    $out[$cid] = $y
  }
  Set-BekleyenPartiDurum $bid 'hasat edildi'
  return $out
}
function Invoke-ClaudeToplu {
  param([Parameter(Mandatory=$true)][array]$Isler,[string]$Etiket='',[int]$BeklemeDk=180,[int]$YoklamaSn=30)
  if(-not @($Isler).Count){ return @{} }
  $hedef = Get-TopluBasliklar
  $req = @()
  foreach($i in @($Isler)){
    $temiz = ConvertTo-AnthropicIcerik (ConvertTo-IcerikBloklari $i.icerik)
    $g = @{ model="$($i.model)"; max_tokens=[int]$i.maxTok; messages=@(@{ role='user'; content=@($temiz) }) }
    if("$($i.model)" -match 'sonnet-5|opus-5'){ $ef = Read-ApiEnv 'MEVZUAT_EFFORT'; if(-not $ef){ $ef = 'medium' }; $g.output_config = @{ effort = $ef } }
    $req += @{ custom_id="$($i.id)"; params=$g }
  }
  $govde = @{ requests=$req } | ConvertTo-Json -Depth 20
  $b = Invoke-RestMethod -Method Post -Uri ($hedef.taban + '/v1/messages/batches') -Headers $hedef.basliklar -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 240
  $bid = "$($b.id)"
  Add-BekleyenParti $bid $Etiket
  Write-Host ("  TOPLU PARTİ gönderildi: {0} istek · id {1} · {2} KB · etiket {3}" -f @($Isler).Count,$bid,[math]::Round($govde.Length/1024),$Etiket) -ForegroundColor Cyan
  $t0 = Get-Date
  while($true){
    Start-Sleep -Seconds $YoklamaSn
    $st = $null; try{ $st = Invoke-RestMethod -Uri ($hedef.taban + "/v1/messages/batches/$bid") -Headers $hedef.basliklar -TimeoutSec 60 }catch{ Write-Host "  toplu durum sorgusu düştü, tekrar: $($_.Exception.Message)" -ForegroundColor DarkYellow; continue }
    $c = $st.request_counts
    if($st.processing_status -eq 'ended'){ Write-Host ("  TOPLU PARTİ bitti ({0} dk): başarılı {1} · hata {2} · süresi dolan {3}" -f [int]((Get-Date)-$t0).TotalMinutes,$c.succeeded,$c.errored,$c.expired) -ForegroundColor Cyan; break }
    if(((Get-Date)-$t0).TotalMinutes -ge $BeklemeDk){ Write-Host "  TOPLU PARTİ ZAMAN AŞIMI ($BeklemeDk dk): sonuç ÇEKİLMEDİ, kimlik bekleyen-partiler.json'da ($bid); sonra Get-ClaudeTopluSonuc ile bedava hasat" -ForegroundColor Red; Set-BekleyenPartiDurum $bid 'zaman asimi - hasat bekliyor'; return @{ '__zaman_asimi'=$bid; '__hata'=@{} } }
    if(((Get-Date)-$t0).TotalSeconds % 300 -lt $YoklamaSn){ Write-Host ("  toplu: {0} · işlenen {1}/{2} · {3} dk" -f $st.processing_status,$c.succeeded,@($Isler).Count,[int]((Get-Date)-$t0).TotalMinutes) -ForegroundColor DarkGray }
  }
  return (Get-ClaudeTopluSonuc $bid $hedef $Etiket)
}

# 07.09 BEDEL MUHASEBESİ (Cem "her şeyde bedeli sor" + A kovası 9: yalnız üç faz jeton yazıyordu). Her çağrı model bazında toplanır;
# çağıran betik Get-BedelOzet ile satırları ve USD tahminini alır. Fiyat tablosu VARSAYIMdır (1M jeton başına USD, girdi/çıktı);
# MEVZUAT_FIYAT_JSON ortam değişkeni ({"claude-sonnet-5":[3,15],...}) ile ezilir. Önbellek okuma girdi fiyatının %10'u sayılır.
$global:MEVZUAT_BEDEL = @{}
function Add-BedelKaydi([string]$model,$y){
  try{
    if(-not $global:MEVZUAT_BEDEL.ContainsKey($model)){ $global:MEVZUAT_BEDEL[$model] = @{ cagri=0; girdi=0; cikti=0; onOku=0; onYaz=0 } }
    $b = $global:MEVZUAT_BEDEL[$model]; $b.cagri++
    $b.girdi += [int]"$($y.girdi)"; $b.cikti += [int]"$($y.cikti)"
    if($y.PSObject.Properties['onbellekOkuma']){ $b.onOku += [int]"$($y.onbellekOkuma)" }
    if($y.PSObject.Properties['onbellekYazma']){ $b.onYaz += [int]"$($y.onbellekYazma)" }
  }catch{}
}
function Get-BedelFiyat{
  $f = @{ 'claude-sonnet-5'=@(3,15); 'claude-opus-5'=@(15,75); 'claude-haiku-4-5-20251001'=@(1,5); 'claude-haiku-4-5'=@(1,5) }
  $ez = Read-ApiEnv 'MEVZUAT_FIYAT_JSON'
  if($ez){ try{ $j = ConvertFrom-Json -InputObject $ez; foreach($p in $j.PSObject.Properties){ $f[$p.Name] = @([double]$p.Value[0],[double]$p.Value[1]) } }catch{} }
  return $f
}
function Get-BedelOzet{
  $f = Get-BedelFiyat; $satir = @(); $toplam = 0.0; $bilinmeyen = @()
  foreach($m in ($global:MEVZUAT_BEDEL.Keys | Sort-Object)){
    $b = $global:MEVZUAT_BEDEL[$m]; $fy = $null; $mAd = ($m -replace '\|toplu$',''); foreach($k in $f.Keys){ if($mAd -like "$k*"){ $fy = $f[$k] } }
    $usd = $null
    $carpan = $(if($m -like '*|toplu'){ 0.5 } else { 1.0 })   # 08.09: toplu istek yarı fiyat (varsayım; konsoldan doğrulanır)
    if($fy){ $usd = $carpan * (($b.girdi/1e6)*$fy[0] + ($b.onOku/1e6)*$fy[0]*0.1 + ($b.onYaz/1e6)*$fy[0]*1.25 + ($b.cikti/1e6)*$fy[1]); $toplam += $usd } else { $bilinmeyen += $m }
    $satir += [pscustomobject]@{ model=$m; cagri=$b.cagri; girdi=$b.girdi; cikti=$b.cikti; onbellekOkuma=$b.onOku; onbellekYazma=$b.onYaz; usd=$(if($null -ne $usd){ [math]::Round($usd,3) } else { $null }) }
  }
  return [pscustomobject]@{ satirlar=$satir; toplamUsd=[math]::Round($toplam,2); fiyatVarsayim=(-not [bool](Read-ApiEnv 'MEVZUAT_FIYAT_JSON')); bilinmeyenModel=$bilinmeyen }
}
