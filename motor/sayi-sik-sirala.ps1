# ============================================================================
#  SAYISAL SIK SIRALAYICI (13.08.2026) — 0 USD, MODEL YOK
#  NBME kurali: sayisal siklar artan (ya da azalan) sirada verilir; sirasiz
#  siklar adaya gereksiz karsilastirma yuku bindirir (K17-F4: 354 soru).
#  NE YAPAR: tum siklari saf sayi olan sorularda siklari ARTAN siraya dizer,
#  dogru cevabin harfini yeni yerine tasir, ACIKLAMA anahtarlarini ayni
#  esleme ile tasir. Metin DEGISMEZ - yalnizca harf-esleme degisir.
#  EMNIYET:
#   - Aciklama/soru metninde HARF ATFI ("B sikki", "C secenegi") varsa DOKUNMAZ.
#   - Zaten sirali olan soruya dokunmaz. Varsayilan OLCUM; yazmak icin -uygula.
#   - Yazma sonrasi GERI OKUR ve sirali olma oranini yeniden olcer.
#  Cikti: veri/sayi-sik-sirala.json
# ============================================================================
param([switch]$uygula)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok.'; exit 1 }
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$HARF = @('A','B','C','D','E')
$reAtif = [regex]"(?i)\b[A-E]\s*[)\-']|\b[A-E]\s+([sş][ıi]kk?[ıi]|se[çc]ene[ğg]i)|\b[A-E]['’]"

function SayiCoz([string]$m){
  $t = ($m -replace '[^\d,\.]','')
  if($t -notmatch '\d'){ return $null }
  # Turk formati: nokta binlik, virgul ondalik
  $t = $t -replace '\.',''
  $t = $t -replace ',','.'
  $x = 0.0
  if([double]::TryParse($t,[ref]$x)){ return $x }
  return $null
}

$aday=0; $atifli=0; $zatenSirali=0; $duzelen=0; $hata=0
$degisenler = New-Object System.Collections.Generic.List[object]
for($of=0; $of -lt 40000; $of+=500){
  $r = Invoke-WebRequest -UseBasicParsing -Uri "$U`?select=id,soru,siklar,dogru,aciklama&order=id&limit=500&offset=$of" -Headers $SB -TimeoutSec 180
  $j = ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json)
  if(@($j).Count -eq 0){ break }
  foreach($s in $j){
    if(-not $s.siklar){ continue }
    $d = "$($s.dogru)".Trim().ToUpper()
    if($HARF -notcontains $d){ continue }
    $sik = @{}; $tamam = $true
    foreach($h in $HARF){
      $v = $null; try { if($s.siklar.PSObject.Properties[$h]){ $v = "$($s.siklar.$h)" } } catch {}
      if($null -eq $v -or $v.Trim() -eq ''){ $tamam = $false; break }
      $sik[$h] = $v
    }
    if(-not $tamam){ continue }
    # tum siklar SAF SAYI mi (kisa ve sayisal)
    $deger = @{}; $hepsiSayi = $true
    foreach($h in $HARF){
      if($sik[$h].Length -gt 30){ $hepsiSayi=$false; break }
      $x = SayiCoz $sik[$h]
      if($null -eq $x){ $hepsiSayi=$false; break }
      $deger[$h] = $x
    }
    if(-not $hepsiSayi){ continue }
    # zaten sirali mi
    $mevcut = @($HARF | ForEach-Object { $deger[$_] })
    $artan=$true; $azalan=$true
    for($i=1;$i -lt $mevcut.Count;$i++){ if($mevcut[$i] -lt $mevcut[$i-1]){$artan=$false}; if($mevcut[$i] -gt $mevcut[$i-1]){$azalan=$false} }
    if($artan -or $azalan){ $zatenSirali++; continue }
    $aday++
    # harf atfi varsa dokunma
    $metin = "$($s.soru)"
    if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){ $metin += ' ' + "$($p.Value)" } }
    if($reAtif.IsMatch($metin)){ $atifli++; continue }
    # ARTAN siraya diz
    $sirali = @($HARF | Sort-Object { $deger[$_] })
    $yeniSik = @{}; $yeniAcik = @{}; $yeniDogru = ''
    for($i=0;$i -lt 5;$i++){
      $kaynakH = $sirali[$i]; $hedefH = $HARF[$i]
      $yeniSik[$hedefH] = $sik[$kaynakH]
      $av=''; try { if($s.aciklama -and $s.aciklama.PSObject.Properties[$kaynakH]){ $av = "$($s.aciklama.$kaynakH)" } } catch {}
      $yeniAcik[$hedefH] = $av
      if($kaynakH -eq $d){ $yeniDogru = $hedefH }
    }
    if($yeniDogru -eq ''){ continue }
    if(-not $uygula){ $duzelen++; continue }
    $govde = [ordered]@{ siklar=$yeniSik; aciklama=$yeniAcik; dogru=$yeniDogru } | ConvertTo-Json -Depth 5
    try{
      Invoke-RestMethod -Method Patch -Uri "$U`?id=eq.$($s.id)" -Headers ($SB + @{ 'Content-Type'='application/json'; Prefer='return=minimal' }) -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 60 | Out-Null
      $duzelen++
      if($degisenler.Count -lt 30){ $degisenler.Add([pscustomobject]@{ id="$($s.id)"; eski_dogru=$d; yeni_dogru=$yeniDogru }) }
    } catch { $hata++ }
  }
  if(@($j).Count -lt 500){ break }
}
$rapor = [ordered]@{ tarih=(Get-Date).ToString('dd.MM.yyyy HH:mm'); mod=$(if($uygula){'uygula'}else{'olcum'})
  sirasiz_aday=$aday; harf_atifli_dokunulmadi=$atifli; zaten_sirali=$zatenSirali; duzelen=$duzelen; hata=$hata; ornek=$degisenler.ToArray()
  not='Metin degismez, yalnizca sik harflerinin esleme sirasi degisir. Harf atifli sorulara dokunulmaz.' }
[IO.File]::WriteAllText((Join-Path $kok 'veri\sayi-sik-sirala.json'), (ConvertTo-Json $rapor -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host ("SIRASIZ aday: {0} | harf-atifli (dokunulmadi): {1} | zaten sirali: {2} | duzelen: {3} | hata: {4}" -f $aday,$atifli,$zatenSirali,$duzelen,$hata)
