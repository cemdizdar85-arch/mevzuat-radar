# ============================================================================
#  API CEVIRI TESTI (Katman 1 kapisi — her push'ta kosar, 0 USD, CAGRI YOK)
#
#  NEDEN VAR: 16.08'de Anthropic tavani dolunca istekler OpenRouter yedek
#  hattina geciyor (motor/api-hedef.ps1). Iki hattin GOVDE BICIMI farkli;
#  ceviri katmani sessizce bozulursa robot "calisti" der ama modele EKSIK
#  istem gider — parayi yakar, cikti cope gider. Bu tur sessiz kayip bu
#  depoda daha once uc kez olculdu; ceviri bir daha denetimsiz kalmayacak.
#
#  Bu test API'ye CAGRI YAPMAZ: yalniz saf cevirici fonksiyonlari olcer.
#  Canli hat probu ayridir: motor/api-test.ps1 (Actions -> "API Testi").
# ============================================================================
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'motor\api-hedef.ps1')

$gecti = 0; $kaldi = 0; $dusen = @()
function Kontrol([string]$ad, [scriptblock]$test){
  try {
    if(& $test){ Write-Host ("  gecti  : " + $ad); $script:gecti++ }
    else { Write-Host ("  KALDI  : " + $ad) -ForegroundColor Red; $script:kaldi++; $script:dusen += $ad }
  } catch {
    Write-Host ("  KALDI  : " + $ad + " -> " + $_.Exception.Message) -ForegroundColor Red
    $script:kaldi++; $script:dusen += $ad
  }
}

Write-Host 'API CEVIRI TESTI (cagri yok)'
Write-Host '1) Istem sarmalama'
Kontrol 'duz string -> text blogu' {
  $b = ConvertTo-IcerikBloklari 'merhaba'
  $b.Count -eq 1 -and $b[0].type -eq 'text' -and $b[0].text -eq 'merhaba'
}
Kontrol 'hazir blok dizisi bozulmadan geciyor' {
  $b = ConvertTo-IcerikBloklari @(@{type='text';text='a'}, @{type='text';text='b'})
  $b.Count -eq 2 -and $b[1].text -eq 'b'
}

Write-Host '2) OpenRouter (OpenAI bicimi) cevirisi'
Kontrol 'text -> text' {
  $o = ConvertTo-OpenAiIcerik @(@{type='text';text='soru'})
  $o[0].type -eq 'text' -and $o[0].text -eq 'soru'
}
Kontrol 'image -> image_url (data URI)' {
  $o = ConvertTo-OpenAiIcerik @(@{type='image';source=@{type='base64';media_type='image/png';data='QUJD'}})
  $o[0].type -eq 'image_url' -and $o[0].image_url.url -eq 'data:image/png;base64,QUJD'
}
Kontrol 'TANIMSIZ blok sessizce DUSMUYOR (hata firlatir)' {
  $firladi = $false
  try { ConvertTo-OpenAiIcerik @(@{type='tool_result';icerik='x'}) | Out-Null } catch { $firladi = $true }
  $firladi
}
Kontrol 'PDF kilidi KAPALI iken document durduruyor' {
  [Environment]::SetEnvironmentVariable('MEVZUAT_YEDEK_PDF',$null,'Process')
  $firladi = $false
  try { ConvertTo-OpenAiIcerik @(@{type='document';source=@{type='base64';media_type='application/pdf';data='JVBE'}}) | Out-Null } catch { $firladi = $true }
  $firladi
}
Kontrol 'PDF kilidi ACIK iken document -> file blogu' {
  [Environment]::SetEnvironmentVariable('MEVZUAT_YEDEK_PDF','1','Process')
  try {
    $o = ConvertTo-OpenAiIcerik @(@{type='document';source=@{type='base64';media_type='application/pdf';data='JVBE'};ad='kitapcik.pdf'})
    $o[0].type -eq 'file' -and $o[0].file.filename -eq 'kitapcik.pdf' -and $o[0].file.file_data -eq 'data:application/pdf;base64,JVBE'
  } finally { [Environment]::SetEnvironmentVariable('MEVZUAT_YEDEK_PDF',$null,'Process') }
}

Write-Host '3) Anthropic tarafi: ic alan "ad" govdeye sizmamali (400 sebebi)'
Kontrol '"ad" ayikleniyor, diger alanlar duruyor' {
  $a = ConvertTo-AnthropicIcerik @(@{type='document';source=@{type='base64';media_type='application/pdf';data='JVBE'};cache_control=@{type='ephemeral'};ad='x.pdf'})
  (-not $a[0].ContainsKey('ad')) -and $a[0].cache_control.type -eq 'ephemeral' -and $a[0].source.data -eq 'JVBE'
}
Kontrol '"ad" yoksa blok oldugu gibi geciyor' {
  $a = ConvertTo-AnthropicIcerik @(@{type='text';text='q'})
  $a[0].text -eq 'q'
}

Write-Host '4) Limit teshisi (yedek hatta gecis karari) - CAGRI YOK, yalniz metin eslemesi'
# 16.08: koprunun coktugu yer burasiydi. Anthropic tavani 429 degil HTTP 400
# "invalid_request_error" ile geliyor; metni asagidaki. Eski desen tutmuyordu.
function SahteHata([string]$govde){
  $e = New-Object psobject
  $e | Add-Member -NotePropertyName ErrorDetails -NotePropertyValue ([pscustomobject]@{ Message = $govde })
  $e | Add-Member -NotePropertyName Exception -NotePropertyValue ([pscustomobject]@{ Response = $null })
  return $e
}
Kontrol 'Anthropic tavan metni LIMIT sayiliyor' {
  Test-LimitHatasi (SahteHata '{"type":"error","error":{"type":"invalid_request_error","message":"You have reached your specified API usage limits. You will regain access on 2026-09-01 at 00:00 UTC."}}')
}
Kontrol 'kredi/fatura metni LIMIT sayiliyor' {
  Test-LimitHatasi (SahteHata '{"error":{"message":"Your credit balance is too low"}}')
}
Kontrol 'ALAKASIZ hata limit SAYILMIYOR (yedege bosuna gecmesin)' {
  -not (Test-LimitHatasi (SahteHata '{"error":{"type":"invalid_request_error","message":"messages.0.content.0.text: field required"}}'))
}

Write-Host '5) Model eslemesi'
Kontrol 'tarihli haiku -> anthropic/claude-haiku-4.5' { (ConvertTo-ORModel 'claude-haiku-4-5-20251001') -eq 'anthropic/claude-haiku-4.5' }
Kontrol 'sonnet-5 -> anthropic/claude-sonnet-5'       { (ConvertTo-ORModel 'claude-sonnet-5') -eq 'anthropic/claude-sonnet-5' }
Kontrol 'zaten OpenRouter slug ise dokunmuyor'        { (ConvertTo-ORModel 'anthropic/claude-haiku-4.5') -eq 'anthropic/claude-haiku-4.5' }

Write-Host ''
if($kaldi -gt 0){
  Write-Host ("API CEVIRI TESTI KIRMIZI: {0} gecti, {1} kaldi -> {2}" -f $gecti, $kaldi, ($dusen -join ' | ')) -ForegroundColor Red
  exit 1
}
Write-Host ("API ceviri testi yesil: {0}/{0} gecti." -f $gecti) -ForegroundColor Green
