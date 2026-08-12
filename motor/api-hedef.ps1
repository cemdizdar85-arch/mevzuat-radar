# ============================================================================
#  API HEDEF KATMANI - CIFT HAT                             (12.08.2026, 0 USD)
#
#  NEDEN: Anthropic Build tier 1.000 USD tavani doldu (10.08). Cem karari:
#  "acmazsa tasinacagiz". Claude Platform on AWS = ANTHROPIC ISLETIR, ayni
#  modeller, ayni API (/v1/...), Batch API dahil; fatura AWS Marketplace.
#  Resmi belge 12.08 okundu: platform.claude.com/docs/en/build-with-claude/
#  claude-platform-on-aws.md
#
#  DEGISEN UC SEY (baska hicbir sey degismez):
#    1. Taban adres : https://aws-external-anthropic.{bolge}.api.aws
#    2. Anahtar     : AWS Konsolu > Claude Platform on AWS > API keys
#                     (yine x-api-key basligiyla gider; SigV4 GEREKMEZ)
#    3. Ek baslik   : anthropic-workspace-id: wrkspc_...  (ZORUNLU)
#
#  KULLANIM (betik basinda):
#    . (Join-Path $PSScriptRoot 'api-hedef.ps1')
#    $H = Get-ApiHedef                # veya Get-ApiHedef -zorla 'aws'
#    $H.taban    -> 'https://...'     (sonunda / YOK; '/v1/messages' eklenir)
#    $H.basliklar-> @{ 'x-api-key'=..; 'anthropic-version'=..; [workspace] }
#    $H.ad       -> 'aws' | 'anthropic'
#
#  SECIM SIRASI:
#    1. -zorla parametresi
#    2. MEVZUAT_API_HEDEF ortam degiskeni ('aws' ya da 'anthropic')
#    3. AWS uclusu tamsa (ANTHROPIC_AWS_API_KEY + AWS_REGION +
#       ANTHROPIC_AWS_WORKSPACE_ID) -> aws; degilse -> anthropic
#
#  CEM'IN GIRECEGI ORTAM DEGISKENLERI (degerlerini ben gormem):
#    ANTHROPIC_AWS_API_KEY      = AWS Konsolundan uretilen anahtar
#    AWS_REGION                 = workspace'in bolgesi (or. us-west-2 / eu-central-1)
#    ANTHROPIC_AWS_WORKSPACE_ID = wrkspc_ ile baslayan kimlik
#
#  BILINEN TUZAKLAR (resmi belgeden):
#    - Ilk API cagrisinda "Outbound web identity federation is disabled"
#      cikarsa AWS hesabinda federasyon BIR KEZ etkinlestirilecek.
#    - Workspace TEK bolgeye baglidir; bolge yanlissa 403/404.
#    - Yeni organizasyon START katmaninda basar - hiz limiti dusuk olabilir,
#      parti boyutu kucuk tutulur, gerekirse temsilciden artis istenir.
#    - anthropic-beta basliklari AYNEN calisir (Bedrock degil!).
# ============================================================================

function Get-ApiHedef {
  param([string]$zorla = '')

  $oku = {
    param($ad)
    $v = [Environment]::GetEnvironmentVariable($ad,'User')
    if(-not $v){ $v = [Environment]::GetEnvironmentVariable($ad,'Process') }
    if(-not $v){ $v = [Environment]::GetEnvironmentVariable($ad,'Machine') }
    return $v
  }

  $awsAnahtar = & $oku 'ANTHROPIC_AWS_API_KEY'
  $awsBolge   = & $oku 'AWS_REGION'
  $awsCalisma = & $oku 'ANTHROPIC_AWS_WORKSPACE_ID'
  $antAnahtar = & $oku 'ANTHROPIC_API_KEY'
  $awsTam = ($awsAnahtar -and $awsBolge -and $awsCalisma)

  $sec = $zorla
  if(-not $sec){ $sec = & $oku 'MEVZUAT_API_HEDEF' }
  if(-not $sec){ $sec = if($awsTam){ 'aws' } else { 'anthropic' } }
  $sec = $sec.ToLower()

  if($sec -eq 'aws'){
    $eksik = @()
    if(-not $awsAnahtar){ $eksik += 'ANTHROPIC_AWS_API_KEY' }
    if(-not $awsBolge){   $eksik += 'AWS_REGION' }
    if(-not $awsCalisma){ $eksik += 'ANTHROPIC_AWS_WORKSPACE_ID' }
    if($eksik.Count -gt 0){
      throw ("AWS hedefi istendi ama ortam degiskeni eksik: {0}. Cem'in AWS Konsolundan anahtar uretip bu degiskenleri girmesi gerekir." -f ($eksik -join ', '))
    }
    if($awsCalisma -notlike 'wrkspc_*'){
      throw ("ANTHROPIC_AWS_WORKSPACE_ID 'wrkspc_' ile baslamali; girilen deger farkli gorunuyor (deger gizli tutuldu).")
    }
    return [pscustomobject]@{
      ad        = 'aws'
      taban     = ('https://aws-external-anthropic.{0}.api.aws' -f $awsBolge)
      anahtar   = $awsAnahtar
      basliklar = @{
        'x-api-key'              = $awsAnahtar
        'anthropic-version'      = '2023-06-01'
        'anthropic-workspace-id' = $awsCalisma
      }
    }
  }

  if(-not $antAnahtar){
    throw 'Anthropic hedefi icin ANTHROPIC_API_KEY yok (AWS hedefi icin de ucul eksik). Hicbir kanal kullanilamiyor.'
  }
  return [pscustomobject]@{
    ad        = 'anthropic'
    taban     = 'https://api.anthropic.com'
    anahtar   = $antAnahtar
    basliklar = @{
      'x-api-key'         = $antAnahtar
      'anthropic-version' = '2023-06-01'
    }
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
