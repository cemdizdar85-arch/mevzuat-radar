# ============================================================================
#  AWS ON KONTROL                                          (12.08.2026)
#
#  NE ZAMAN: Cem AWS hesabini acip uc ortam degiskenini girdikten sonra,
#  ATES-EMRI'nden ONCE calistirilir. Maliyeti birkac jeton (~sifir).
#
#  NE YAPAR (sirayla, ilk kirmizida durur):
#    1. Uc ortam degiskeni var mi (degerler ekrana YAZILMAZ)
#    2. bekleyen-partiler.json bos mu - ESKI hedefte odenmis parti varsa
#       once ORADAN hasat edilmeli (parti kimligi hedefler arasi TASINMAZ)
#    3. 1 jetonluk /v1/messages istegi -> model cevap veriyor mu
#    4. /v1/messages/batches listesi -> Batch API acik mi
#
#  BILINEN ILK-KOSU HATASI (resmi belgeden): "Outbound web identity
#  federation is disabled" -> AWS hesabinda federasyon BIR KEZ etkinlestirilir,
#  sonra tekrar denenir. Bu betik o hatayi yakalayip Turkce soyler.
#
#  Kullanim:  motor\aws-on-kontrol.ps1            (hedef otomatik: aws uclusu varsa aws)
#             motor\aws-on-kontrol.ps1 -model claude-opus-5
# ============================================================================
param([string]$model = 'claude-opus-5')
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$kok = Split-Path $PSScriptRoot -Parent

. (Join-Path $PSScriptRoot 'api-hedef.ps1')

Write-Host '=== AWS ON KONTROL ==='

# --- 1. hedef ve degiskenler -------------------------------------------------
$HEDEF = $null
try { $HEDEF = Get-ApiHedef -zorla 'aws' }
catch {
  Write-Host ("KIRMIZI (adim 1): {0}" -f $_.Exception.Message)
  Write-Host ''
  Write-Host 'Cem''in girmesi gerekenler (PowerShell''i YENIDEN ACMADAN once Sistem > Ortam Degiskenleri''nden ya da asagidaki komutlarla KALICI girilmeli):'
  Write-Host '  [Environment]::SetEnvironmentVariable(''ANTHROPIC_AWS_API_KEY'',''<anahtar>'',''User'')'
  Write-Host '  [Environment]::SetEnvironmentVariable(''AWS_REGION'',''<bolge or. us-west-2>'',''User'')'
  Write-Host '  [Environment]::SetEnvironmentVariable(''ANTHROPIC_AWS_WORKSPACE_ID'',''wrkspc_...'',''User'')'
  exit 1
}
Write-Host ("adim 1 TAMAM - hedef: {0}" -f $HEDEF.taban)

# --- 2. eski hedefte odenmis parti kalmis mi ----------------------------------
$byol = Join-Path $kok 'veri\bekleyen-partiler.json'
if(Test-Path $byol){
  $bek = @()
  try { $bek = @(ConvertFrom-Json ([IO.File]::ReadAllText($byol,[Text.Encoding]::UTF8))) } catch {}
  if($bek.Count -gt 0){
    Write-Host ("KIRMIZI (adim 2): bekleyen-partiler.json'da {0} parti kimligi var." -f $bek.Count)
    Write-Host 'Bunlar ESKI hedefte (Anthropic) odenmis is olabilir - parti kimligi AWS''ten cekilemez.'
    Write-Host 'Once: $env:MEVZUAT_API_HEDEF=''anthropic''; motor\parti-hasat.ps1 -temizle'
    Write-Host '(Anthropic tavani sadece YENI harcamayi keser; bitmis parti sonucunu indirmek harcama degildir, denenebilir.)'
    exit 1
  }
}
Write-Host 'adim 2 TAMAM - bekleyen parti yok'

# --- 3. tek jetonluk istek -----------------------------------------------------
try{
  $dene = @{ model=$model; max_tokens=1; messages=@(@{ role='user'; content='tamam' }) } | ConvertTo-Json -Depth 5
  $ok = Invoke-RestMethod -Method Post -Uri ($HEDEF.taban + '/v1/messages') -Headers $HEDEF.basliklar -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($dene)) -TimeoutSec 120
  Write-Host ("adim 3 TAMAM - model cevap verdi: {0}" -f $ok.model)
}catch{
  $mesaj = "$($_.Exception.Message)"
  $govde = ''
  try { $govde = (New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() } catch {}
  Write-Host ("KIRMIZI (adim 3): {0}" -f $mesaj)
  if($govde){ Write-Host ("  sunucu cevabi: {0}" -f $govde.Substring(0,[Math]::Min(400,$govde.Length))) }
  if(($mesaj + $govde) -match 'federation'){
    Write-Host ''
    Write-Host 'COZUM: ilk cagri tuzagi. AWS hesabinda "outbound web identity federation"'
    Write-Host 'BIR KEZ etkinlestirilecek (AWS Konsolu > Claude Platform on AWS sayfasi'
    Write-Host 'yonlendirir), sonra bu betik yeniden kosulur.'
  }
  if(($mesaj + $govde) -match '403|Forbidden'){
    Write-Host ''
    Write-Host 'IPUCU: 403 = istek sunucuya ULASTI ama reddedildi. Iki tipik sebep:'
    Write-Host '  - workspace kimligi yanlis ya da workspace BASKA bolgede (bolge=workspace bolgesi olmali)'
    Write-Host '  - anahtari ureten kullanicida CallWithBearerToken izni yok'
  }
  exit 1
}

# --- 4. Batch API --------------------------------------------------------------
try{
  $b = Invoke-RestMethod -Uri ($HEDEF.taban + '/v1/messages/batches?limit=1') -Headers $HEDEF.basliklar -TimeoutSec 60
  Write-Host 'adim 4 TAMAM - Batch API acik'
}catch{
  Write-Host ("KIRMIZI (adim 4): Batch API listelenemedi: {0}" -f $_.Exception.Message)
  Write-Host 'Uretim hatti Batch ile calisir - bu cozulmeden ATES-EMRI baslamaz.'
  exit 1
}

Write-Host ''
Write-Host '=== HEPSI YESIL - SIRA ATES-EMRI ==='
Write-Host 'Sonraki adim: ATES-EMRI.md adim 1 (20 soruluk olcum partisi):'
Write-Host '  motor\birlesik-yazim-olcum.ps1 -batch -adet 20'
Write-Host 'NOT: yeni AWS organizasyonu START katmaninda baslar - hiz limiti dusukse'
Write-Host 'partiBoyu kucultulur (or. -partiBoyu 50); limit artisi temsilciden istenir.'
