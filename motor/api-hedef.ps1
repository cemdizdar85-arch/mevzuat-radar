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
  $govde = @{ model=$model; max_tokens=$maxTok; messages=@(@{ role='user'; content=@($temiz) }) } | ConvertTo-Json -Depth 20
  $r = Invoke-RestMethod -Method Post -Uri ($hedef.taban + '/v1/messages') -Headers $hedef.basliklar -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType 'application/json' -TimeoutSec 240
  # content[0] her zaman metin DEGILDIR (dusunme blogu one gelebilir) -> tum metin bloklarini birlestir
  $metin = (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { "$($_.text)" }) -join ''
  # dur = bitis sebebi; 'max_tokens' ise cevap KESILMISTIR (onarim-motoru bunu okur)
  return @{ metin=$metin.Trim(); girdi=[int]"$($r.usage.input_tokens)"; cikti=[int]"$($r.usage.output_tokens)"; kaynak=$hedef.ad; dur="$($r.stop_reason)" }
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
  return @{ metin=("$c").Trim(); girdi=[int]"$($r.usage.prompt_tokens)"; cikti=[int]"$($r.usage.completion_tokens)"; kaynak='openrouter'; dur=$dur }
}

# limit/kota hatasi mi? (429/402 ya da fatura/limit iceren govde) -> yedege gec
function Test-LimitHatasi($err){
  $status = 0
  try { $status = [int]$err.Exception.Response.StatusCode } catch {}
  if($status -eq 429 -or $status -eq 402){ return $true }
  $body = ''
  try { $body = "$($err.ErrorDetails.Message)" } catch {}
  if(-not $body){
    try {
      $rs = $err.Exception.Response.GetResponseStream()
      $sr = New-Object System.IO.StreamReader($rs)
      $body = $sr.ReadToEnd()
    } catch {}
  }
  if($body -match '(?i)credit balance|spend limit|monthly limit|exceeded|quota|insufficient|billing|organization.{0,30}disabled|rate.?limit|too_many_requests'){ return $true }
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
        return (Repair-ClaudeMetin (Invoke-AnthropicAnlik $Model $Icerik $MaxTok $hedef))
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
    return (Repair-ClaudeMetin (Invoke-OpenRouterAnlik $Model $Icerik $MaxTok))
  }

  throw 'Hicbir anlik Claude hatti kullanilamiyor (ANTHROPIC_API_KEY tukendi/yok ve OPENROUTER_KEY yok).'
}
