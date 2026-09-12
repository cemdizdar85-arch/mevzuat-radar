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

# 08.09 İSTEM ÖNBELLEĞİ (Cem "önbelleği aç"; pilot6: "önbellek okuma 0"). Tek metin bloğu iki parçaya bölünür: ÖNEK (kural bloğu, her soruda
# aynı) cache_control=ephemeral ile gider (okuma girdi fiyatının %10'u, yazma %125), KALAN (soru/kaynak) normal. Bölme yeri: çağıran metne
# $global:MEVZUAT_ONBELLEK_SINIR işaretini koyar; işaret yoksa ilk "\n=== " bölüm başlığı. Önek eşiğin altındaysa (Sonnet/Opus ≈1.024 jeton
# ≈3.500 kr, Haiku ≈2.048 jeton ≈7.000 kr) bölünmez (Anthropic kısa öneği zaten önbelleğe almaz). MEVZUAT_ONBELLEK=0 kapatır.
$global:MEVZUAT_ONBELLEK_SINIR = '<<<DEGISKEN>>>'
function Split-OnbellekBloklari([array]$icerik,[string]$model){
  $bloklar = @(ConvertTo-IcerikBloklari $icerik | ForEach-Object { $_ })   # ",$out" dönüşü @() ile iç içe dizi oluyor (ölçüldü: [0] Object[]) → boru düzleştirir
  $kapali = ("$(Read-ApiEnv 'MEVZUAT_ONBELLEK')" -eq '0')
  if($bloklar.Count -ne 1 -or -not ($bloklar[0] -is [hashtable]) -or -not $bloklar[0].ContainsKey('text')){ return ,$bloklar }
  $t = [string]$bloklar[0].text; $sinir = $global:MEVZUAT_ONBELLEK_SINIR
  $on = ''; $kal = $t
  $i = $t.IndexOf($sinir)
  if($i -ge 0){ $on = $t.Substring(0,$i); $kal = $t.Substring($i + $sinir.Length) }
  else { $j = $t.IndexOf("`n=== "); if($j -gt 0){ $on = $t.Substring(0,$j); $kal = $t.Substring($j) } }
  # 09.09 ÖLÇÜLDÜ: önbelleğe alınabilir EN KISA önek modele bağlı ve JETON cinsinden — Opus 5: 512, Sonnet 5: 1.024, Haiku 4.5: 4.096 jeton.
  # Kısa önek SESSİZCE önbelleğe girmez (hata yok, yalnız cache_creation_input_tokens 0). Oran count_tokens ile ÖLÇÜLDÜ (tahmin değil):
  # istemlerimizde 1 jeton ≈ 1,72 karakter (FAZ A öneki 6.566 kr = 3.807 jeton · FAZ B öneki 13.376 kr = 7.691 jeton).
  # Eşikler: Sonnet 1.024 j ≈ 1.761 kr → 2.000 · Haiku 4.096 j ≈ 7.045 kr → 7.300 · Opus 512 j ≈ 880 kr → 1.000.
  # Sonnet eşiği 3.500'den 2.000'e indi: giriş (2.909 kr ≈ 1.691 j), teori adım (2.021 kr) ve uyarlama (1.940 kr) istemleri
  # 1.024 jeton sınırının ÜSTÜNDE olduğu hâlde eski eşik yüzünden hiç önbelleğe girmiyordu.
  $esik = $(if($model -match 'haiku'){ 7300 } elseif($model -match 'opus'){ 1000 } else { 2000 })
  if($kapali -or -not $on -or $on.Length -lt $esik){ return ,@(@{ type='text'; text=($on + $kal) }) }
  return ,@(@{ type='text'; text=$on; cache_control=@{ type='ephemeral' } }, @{ type='text'; text=$kal })
}

# 08.09 ölçüldü (pilot6): adım fazında çıktı jetonlarının %76–86'sı DÜŞÜNME (5.648 jeton çıktı, 772 jeton metin); giriş fazında da öyle.
# Çıktı fiyatı girdinin 5 katı → düşünme, bedelin en büyük kalemi. Derinlik artık ÇAĞRI BAZINDA verilir: -Effort low|medium|high;
# verilmezse MEVZUAT_EFFORT, o da yoksa medium. Hesap tasarımı yapan fazlar (soru, ikiz, kör) medium kalır; anlatım/yargı fazları low.
function Get-EffortDegeri([string]$istenen){ if($istenen){ return $istenen }; $ef = Read-ApiEnv 'MEVZUAT_EFFORT'; if(-not $ef){ $ef = 'medium' }; return $ef }
function Invoke-AnthropicAnlik([string]$model,[array]$icerik,[int]$maxTok,$hedef,[string]$effort=''){
  $temiz = ConvertTo-AnthropicIcerik (Split-OnbellekBloklari $icerik $model)
  $g = @{ model=$model; max_tokens=$maxTok; messages=@(@{ role='user'; content=@($temiz) }) }
  # 07.09 ölçüldü (maliyet-zor2): Sonnet 5'te thinking verilmezse UYARLANABİLİR DÜŞÜNME açık ve düşünme jetonları max_tokens'tan
  # yenir → 20.000 çıktı jetonu harcanıp 2.588 karakter metin döndü, JSON kesildi. Sonnet 5 / Opus 5'te düşünme derinliği
  # effort ile sınırlanır (GA, output_config içinde).
  if($model -match 'sonnet-5|opus-5'){ $g.output_config = @{ effort = (Get-EffortDegeri $effort) } }
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
    [switch]$YalnizOpenRouter,
    [string]$Effort = ''      # 08.09: low|medium|high (Sonnet 5 / Opus 5 düşünme derinliği); boş = MEVZUAT_EFFORT ya da medium
  )
  $orVar  = [bool](Read-ApiEnv 'OPENROUTER_KEY')
  $antVar = Test-AnthropicVar
  $Icerik = ConvertTo-IcerikBloklari $Icerik   # duz metin de kabul

  if(-not $YalnizOpenRouter -and -not $script:AnthropicTukendi -and $antVar){
    # 08.09 Tur 1 kazası 3 (09:48): "Uzak ad çözülemedi: api.anthropic.com" (DNS/ağ kesintisi) — çağıranların 3×10-30 sn tekrarı yetmedi,
    # üç üretici süreci aynı anda öldü, koşucu sonraki derse geçti (192'lik üç FMuh etiketi yarım kaldı). GEÇİCİ hatalar (DNS, zaman aşımı,
    # bağlantı, 429, 5xx/529 overloaded) burada merkezi olarak 8 kez, 15 sn → 5 dk artan beklemeyle denenir (≈17 dk tolerans). Limit/kimlik
    # hataları (Test-LimitHatasi) ve 400 gibi kalıcı hatalar hemen fırlatılır.
    $bekle = @(15,30,60,120,240,300,300,300)
    for($dn = 0; $dn -le $bekle.Count; $dn++){
      try {
        $hedef = Get-ApiHedef
        if($hedef.ad -ne 'openrouter'){
          $ySon = Repair-ClaudeMetin (Invoke-AnthropicAnlik $Model $Icerik $MaxTok $hedef $Effort)
          Add-BedelKaydi $Model $ySon
          return $ySon
        }
        break
      } catch {
        $e = $_
        if((Test-LimitHatasi $e) -and $orVar){
          $script:AnthropicTukendi = $true
          Write-Host '  [!] Anthropic limiti/kotasi doldu -> OpenRouter yedek hattina gecildi.' -ForegroundColor Yellow
          break
        }
        $st = 0; try { $st = [int]$e.Exception.Response.StatusCode } catch {}
        $msg = "$($e.Exception.Message)"
        $gecici = ($st -eq 429 -or $st -eq 408 -or $st -ge 500 -or ($st -eq 0 -and $msg -match '(?i)Uzak ad|remote name|could not be resolved|zaman aşımı|timed out|timeout|bağlantı|connection|underlying connection|SSL|TLS|overloaded|temporarily'))
        if($gecici -and $dn -lt $bekle.Count){
          Write-Host ("  [ağ/geçici hata {0}/{1}] {2} -> {3} sn sonra tekrar" -f ($dn+1),$bekle.Count,$msg.Substring(0,[Math]::Min(90,$msg.Length)),$bekle[$dn]) -ForegroundColor DarkYellow
          Start-Sleep -Seconds $bekle[$dn]; continue
        }
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
# 08.09 Tur 1 kazası: 4 koşucu aynı anda yazınca dosya TEK BOŞ KAYDA indi, 4 ödenmiş partinin kimliği kayboldu → makine çapında adlandırılmış
# kilit (Mutex) ile oku-değiştir-yaz; kimlik ayrıca üretici loguna da yazılıyor (yedek).
function Invoke-BekleyenKilitli([scriptblock]$is){
  $mx = New-Object System.Threading.Mutex($false,'Global\tetikte-bekleyen-partiler'); $al = $false
  try{ $al = $mx.WaitOne(15000); & $is }catch{}finally{ if($al){ $mx.ReleaseMutex() }; $mx.Dispose() }
}
# 10.09 ÖLÇÜLDÜ (GM Borçlar t2b): bedava hasat YALNIZ (etiket, faz, kp-id) ile anahtarlanıyordu, isteğin İÇERİĞİ hesaba katılmıyordu.
# Sonuç: bir soru düzeltilip -RedYenile ile yeniden yargılatıldığında, o faz için bitmiş bir parti duruyorsa ESKİ karar geri geliyor ve
# log taze çağrı yapılmış gibi jeton satırı basıyor. Kanıt: çok zor kp-05'in HAKEM2 jetonu iki koşuda birebir aynı (2115/1122) çıktı,
# oysa şıklar tamamen değişmişti; 2. hakemin gerekçesi silinmiş ifadeleri alıntılamayı sürdürdü. Yani "düzelt ve yeniden yargılat"
# döngüsü sessizce çalışmıyordu. Çözüm: gönderilen her işin İÇERİK PARMAK İZİ parti kaydına yazılır, hasatta karşılaştırılır.
function Get-IcerikParmak($icerik){
  $s = $(if($icerik -is [array]){ (@($icerik) | ForEach-Object { if($_ -is [hashtable] -and $_.ContainsKey('text')){ "$($_['text'])" } elseif($_ -and $_.PSObject.Properties['text']){ "$($_.text)" } else { "$_" } }) -join "`n" } else { "$icerik" })
  $sha = [Security.Cryptography.SHA1]::Create()
  try{ return (([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($s))) -replace '-','').Substring(0,16)) }finally{ $sha.Dispose() }
}
function Add-BekleyenParti([string]$bid,[string]$etiket,$parmak=$null){
  Invoke-BekleyenKilitli { $kok = Split-Path -Parent $PSScriptRoot; $y = Join-Path $kok 'veri\bekleyen-partiler.json'; $bek = @()
    if(Test-Path $y){ foreach($x in @(ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($y)))){ if($x -and "$($x.id)"){ $bek += $x } } }
    $kayit = [pscustomobject]@{ id=$bid; etiket=$etiket; zaman=(Get-Date -Format 'yyyy-MM-dd HH:mm'); durum='gonderildi' }
    if($parmak){ $kayit | Add-Member -NotePropertyName parmak -NotePropertyValue ([pscustomobject]$parmak) -Force }
    $bek += $kayit
    [IO.File]::WriteAllText($y,(ConvertTo-Json -InputObject @($bek) -Depth 4),(New-Object Text.UTF8Encoding($false))) }
}
function Set-BekleyenPartiDurum([string]$bid,[string]$durum){
  Invoke-BekleyenKilitli { $kok = Split-Path -Parent $PSScriptRoot; $y = Join-Path $kok 'veri\bekleyen-partiler.json'; if(-not (Test-Path $y)){ return }
    $bek = @(ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($y))) | Where-Object { $_ -and "$($_.id)" }; foreach($x in $bek){ if("$($x.id)" -eq $bid){ $x | Add-Member -NotePropertyName durum -NotePropertyValue $durum -Force } }
    [IO.File]::WriteAllText($y,(ConvertTo-Json -InputObject @($bek) -Depth 3),(New-Object Text.UTF8Encoding($false))) }
}
function Get-BekleyenPartiler([string]$etiket=''){
  # 08.09: aynı etiket/faz için daha önce GÖNDERİLMİŞ partiler (yeniden başlatmada bedava hasat; en yenisi önce)
  try{ $kok = Split-Path -Parent $PSScriptRoot; $y = Join-Path $kok 'veri\bekleyen-partiler.json'; if(-not (Test-Path $y)){ return @() }
    # PS 5.1 tuzağı (08.09 ölçüldü): @(ConvertFrom-Json <dizi>) diziyi TEK öğe sayar → etiket süzgeci hiç tutmuyordu, hasat hiç çalışmadı (parti iki kez ödendi)
    $lst = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($y)); if($lst -isnot [array]){ $lst = @($lst) }
    $bek = @(); foreach($x in $lst){ if($x -and (-not $etiket -or "$($x.etiket)" -eq $etiket)){ $bek += $x } }
    return @($bek | Sort-Object { "$($_.zaman)" } -Descending) }catch{ return @() }
}
function Get-ClaudeTopluSonuc([string]$bid,$hedef,[string]$etiket,[bool]$bedelYaz=$true){
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
    # 08.09 TUR 1 KAZASI: sonuç dosyası yukarıda BAYT olarak alınıp UTF-8 çözüldü; buna bir de Repair-ClaudeMetin (Latin-1 → UTF-8 hilesi) uygulanınca
    # her Türkçe harf U+FFFD (�) oldu: "çerçevesinde" → "�er�evesinde" → KAPI-K parça kelime saydı (200+ sahte tekrar), 14 soru bozuk kaydedildi.
    # Anlık hat (Invoke-RestMethod Latin-1 sanır) onarım ister, toplu hat İSTEMEZ. Yalnız gerçekten mojibake varsa ("Ã", "Å") onar.
    if("$($y.metin)" -match 'Ã|Å|Ä±|Ä'){ $y = Repair-ClaudeMetin $y }
    if($bedelYaz){ Add-BedelKaydi ("$($m.model)" + '|toplu') $y }   # yeniden hasatta bedel defterine ikinci kez yazılmaz (zaten ödendi)
    $out[$cid] = $y
  }
  Set-BekleyenPartiDurum $bid 'hasat edildi'
  return $out
}
function Invoke-ClaudeToplu {
  # ⛔⭐ 12.09.2026 — YOKLAMA 30 sn -> 10 sn (Cem onayi: "bosa bekliyor olabilir miyiz").
  #   OLCULDU: bir parti YEDI sirali kuyruk turu geciyor (H·K·H2·B·S·G·C) ve asagidaki
  #   dongu her turda ONCE uyuyor, SONRA soruyor. Yani her turda en fazla YoklamaSn
  #   kadar, ortalama yarisi kadar BOSA bekleniyor:
  #     30 sn ile: 7 tur x ~15 sn = ~1,8 dk/parti     10 sn ile: ~35 sn/parti
  #   100 dakikalik kosuda ~%1-2; kucuk ama bedeli SIFIR ve toplu kipin zaten
  #   kacinilmaz olan beklemesinin ustune BIZIM ekledigimiz tek gecikme buydu.
  #   ⚠ YUK: yoklama TOKEN YAKMAZ (yalnizca batch durum ucu). 63 es zamanli parti
  #   10 sn'de bir sorarsa ~378 istek/dk olur. 429 gorulurse once bunu yukselt:
  #   MEVZUAT_TOPLU_YOKLAMA_SN ortam degiskeni kod degistirmeden ezer.
  param([Parameter(Mandatory=$true)][array]$Isler,[string]$Etiket='',[int]$BeklemeDk=180,
        [int]$YoklamaSn=$(if("$env:MEVZUAT_TOPLU_YOKLAMA_SN" -match '^\d+$' -and [int]$env:MEVZUAT_TOPLU_YOKLAMA_SN -ge 1){ [int]$env:MEVZUAT_TOPLU_YOKLAMA_SN } else { 10 }))
  if(-not @($Isler).Count){ return @{} }
  $hedef = Get-TopluBasliklar
  $req = @()
  $parmakHep = @{}   # 10.09: iş -> içerik parmak izi; parti kaydına yazılır, hasatta doğrulanır (bayat cevap dönmesin)
  foreach($i in @($Isler)){
    $temiz = ConvertTo-AnthropicIcerik (Split-OnbellekBloklari $i.icerik "$($i.model)")   # 08.09 önbellek: toplu istekte de önek işaretli
    $g = @{ model="$($i.model)"; max_tokens=[int]$i.maxTok; messages=@(@{ role='user'; content=@($temiz) }) }
    if("$($i.model)" -match 'sonnet-5|opus-5'){ $g.output_config = @{ effort = (Get-EffortDegeri "$(if($i -is [hashtable]){ $i['effort'] } else { $i.effort })") } }   # 08.09: iş kaydında 'effort' alanı
    $req += @{ custom_id="$($i.id)"; params=$g }
    $parmakHep["$($i.id)"] = (Get-IcerikParmak $i.icerik)
  }
  # 09.09 09:35 ÖLÇÜLDÜ (Cem "hızlı olsun diye 3 partiye atabiliriz"): 8/30/36/83 istekli partiler 3–15 dk'da işlendi, 62 ve 96 istekli partiler
  # 20 dk'da sıfırdı (08–09.09 gece de 24+ istekliler takıldı). Kuyruk küçük partileri öne alıyor → istekler en çok MEVZUAT_TOPLU_PARCA (varsayılan 30)
  # isteklik PARÇALARA bölünür, hepsi birden gönderilir, birlikte yoklanır; biten parça hemen hasat edilir; zaman aşımında biten parçalar döner,
  # bitmeyenler bekleyen-partiler.json'da kalır (yeniden başlatmada BEDAVA hasat), eksik id'ler anlık koşar.
  $parcaBoy = $(if("$env:MEVZUAT_TOPLU_PARCA" -match '^\d+$' -and [int]$env:MEVZUAT_TOPLU_PARCA -ge 1){ [int]$env:MEVZUAT_TOPLU_PARCA } else { 30 })
  $parcalar = @(); for($pi=0; $pi -lt $req.Count; $pi+=$parcaBoy){ $parcalar += ,@($req[$pi..([Math]::Min($pi+$parcaBoy,$req.Count)-1)]) }
  $bidler = New-Object System.Collections.Generic.List[string]
  foreach($pr in $parcalar){
    $govde = @{ requests=@($pr) } | ConvertTo-Json -Depth 20
    $b = Invoke-RestMethod -Method Post -Uri ($hedef.taban + '/v1/messages/batches') -Headers $hedef.basliklar -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 240
    $bid = "$($b.id)"; $bidler.Add($bid)
    $pm = @{}; foreach($r in @($pr)){ $cid = "$($r.custom_id)"; if($parmakHep.ContainsKey($cid)){ $pm[$cid] = $parmakHep[$cid] } }
    Add-BekleyenParti $bid $Etiket $pm
    Write-Host ("  TOPLU PARTİ gönderildi: {0} istek · id {1} · {2} KB · etiket {3} · parça {4}/{5}" -f @($pr).Count,$bid,[math]::Round($govde.Length/1024),$Etiket,$bidler.Count,$parcalar.Count) -ForegroundColor Cyan
  }
  $t0 = Get-Date; $out = @{}; $biten = New-Object 'System.Collections.Generic.HashSet[string]'
  while($true){
    Start-Sleep -Seconds $YoklamaSn
    $toplamOk = 0
    foreach($bid in $bidler){
      if($biten.Contains($bid)){ continue }
      $st = $null; try{ $st = Invoke-RestMethod -Uri ($hedef.taban + "/v1/messages/batches/$bid") -Headers $hedef.basliklar -TimeoutSec 60 }catch{ Write-Host "  toplu durum sorgusu düştü, tekrar: $($_.Exception.Message)" -ForegroundColor DarkYellow; continue }
      $c = $st.request_counts; $toplamOk += [int]$c.succeeded
      if($st.processing_status -eq 'ended'){
        Write-Host ("  TOPLU PARTİ bitti ({0} dk): başarılı {1} · hata {2} · süresi dolan {3} · {4}" -f [int]((Get-Date)-$t0).TotalMinutes,$c.succeeded,$c.errored,$c.expired,$bid) -ForegroundColor Cyan
        [void]$biten.Add($bid)
        $h1 = Get-ClaudeTopluSonuc $bid $hedef $Etiket; foreach($k1 in @($h1.Keys)){ $out[$k1] = $h1[$k1] }
      }
    }
    if($biten.Count -ge $bidler.Count){ break }
    if(((Get-Date)-$t0).TotalMinutes -ge $BeklemeDk){
      $kalan = @($bidler | Where-Object { -not $biten.Contains($_) })
      Write-Host "  TOPLU PARTİ ZAMAN AŞIMI ($BeklemeDk dk): $($kalan.Count)/$($bidler.Count) parça bitmedi, sonuçları ÇEKİLMEDİ (bekleyen-partiler.json'da; yeniden başlatmada bedava hasat); biten $($biten.Count) parçanın $($out.Count) cevabı kullanılıyor, kalan işler anlık" -ForegroundColor Red
      foreach($bid in $kalan){ Set-BekleyenPartiDurum $bid 'zaman asimi - hasat bekliyor' }
      $out['__zaman_asimi'] = ($kalan -join ','); $out['__hata'] = @{}
      return $out
    }
    if(((Get-Date)-$t0).TotalSeconds % 300 -lt $YoklamaSn){ Write-Host ("  toplu: {0}/{1} parça bitti · işlenen {2}/{3} · {4} dk" -f $biten.Count,$bidler.Count,($toplamOk + $out.Count),@($Isler).Count,[int]((Get-Date)-$t0).TotalMinutes) -ForegroundColor DarkGray }
  }
  return $out
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
    # 08.09 ölçüldü: $y hashtable → PSObject.Properties anahtarları görmez, önbellek jetonları hiç sayılmıyordu ("hiç okunmadı" notu sahteydi)
    $oOkuV = $(if($y -is [hashtable]){ $y['onbellekOkuma'] } else { $y.onbellekOkuma }); if($null -ne $oOkuV){ $b.onOku += [int]"$oOkuV" }
    $oYazV = $(if($y -is [hashtable]){ $y['onbellekYazma'] } else { $y.onbellekYazma }); if($null -ne $oYazV){ $b.onYaz += [int]"$oYazV" }
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
