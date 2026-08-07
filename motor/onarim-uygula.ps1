# ============================================================================
#  ONARIM UYGULAYICI — 07.08.2026 (boru hattinin son borusu)
#
#  Akis: ic-tutarlilik-onar taslaklari OZEL kovada bekler -> GM (Claude)
#  taslaklari OKUR -> onayli id listesi bu scripte verilir -> taslagin 'yeni'
#  govdesi kasaya yazilir. yayin=false KALIR + not 'onarildi-hakem bekliyor'
#  (yayina donus yalniz hakem+yayin kapisindan).
#
#  KURALLAR: onaysiz uygulama YOK (-onayliDosya sart; 'hepsi' kelimesi kabul
#  edilmez). Once OLCUM (varsayilan), -yaz ile gercek uygulama. PATCH kanali
#  TEK HttpClient baglantisi (07.08 ag dersi #3).
#
#  KULLANIM:
#    .\motor\onarim-uygula.ps1 -onayliDosya veri\gm-onay-0708.txt          # olcum
#    .\motor\onarim-uygula.ps1 -onayliDosya veri\gm-onay-0708.txt -yaz     # uygula
#  (onayliDosya: her satirda bir soru id'si; GM okumasi ciktisi)
# ============================================================================
param(
  [Parameter(Mandatory=$true)][string]$onayliDosya,
  [switch]$yaz
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$U    = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$STOR = 'https://bjrleanjpyujtajmazxn.supabase.co/storage/v1'
$KOVA = 'onarim-taslak'
$SB   = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
$raporYol = Join-Path $kok 'veri\onarim-uygula-raporu.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 5), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

$onayli = @(Get-Content $onayliDosya -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -notmatch '^#' })
Write-Host ("GM-onayli id: {0}" -f $onayli.Count)
if(-not $onayli.Count){ Write-Host 'onayli id yok - cikildi'; exit 0 }

# --- kovadaki taslak dosyalarini indeksle (etiket klasorleri)
$tmpL=[IO.Path]::GetTempFileName()
[IO.File]::WriteAllText($tmpL,'{"prefix":"ic-tutarlilik-onar","limit":100,"offset":0}')
$kokler = & curl.exe -s -X POST -H "apikey: $($env:SUPABASE_SERVICE_KEY)" -H "Authorization: Bearer $($env:SUPABASE_SERVICE_KEY)" -H "Content-Type: application/json" --data-binary "@$tmpL" "$STOR/object/list/$KOVA" | ConvertFrom-Json
$taslakYol = @{}
foreach($kk in @($kokler)){
  [IO.File]::WriteAllText($tmpL, ('{"prefix":"ic-tutarlilik-onar/' + $kk.name + '","limit":5000,"offset":0}'))
  $dl = & curl.exe -s -X POST -H "apikey: $($env:SUPABASE_SERVICE_KEY)" -H "Authorization: Bearer $($env:SUPABASE_SERVICE_KEY)" -H "Content-Type: application/json" --data-binary "@$tmpL" "$STOR/object/list/$KOVA" | ConvertFrom-Json
  foreach($ds in @($dl)){
    $id = "$($ds.name)" -replace '\.json$',''
    if(-not $taslakYol.ContainsKey($id)){ $taslakYol[$id] = 'ic-tutarlilik-onar/' + $kk.name + '/' + $ds.name }
  }
}
Remove-Item $tmpL -Force -ErrorAction SilentlyContinue
Write-Host ("kovada taslak: {0} tekil id" -f $taslakYol.Count)

Add-Type -AssemblyName System.Net.Http
$hc = New-Object System.Net.Http.HttpClient
$hc.Timeout=[TimeSpan]::FromSeconds(90)
$hc.DefaultRequestHeaders.Add('apikey', $env:SUPABASE_SERVICE_KEY)
$hc.DefaultRequestHeaders.Add('Authorization', "Bearer $($env:SUPABASE_SERVICE_KEY)")
$hc.DefaultRequestHeaders.UserAgent.ParseAdd('mevzuat-radar-robot/1.0')

$uygulanan=0; $taslakYok=@(); $hataLi=@()
foreach($id in $onayli){
  if(-not $taslakYol.ContainsKey($id)){ $taslakYok += $id; continue }
  # taslagi indir
  $t = $hc.GetStringAsync("$STOR/object/$KOVA/" + $taslakYol[$id]).GetAwaiter().GetResult() | ConvertFrom-Json
  $yeni = $t.yeni
  if($null -eq $yeni -or -not $yeni.soru){ $hataLi += ($id + '|taslak-bozuk'); continue }
  if(-not $yaz){ $uygulanan++; continue }   # olcum: yalniz sayar
  $gov = ConvertTo-Json -Depth 8 -Compress -InputObject ([ordered]@{
    soru="$($yeni.soru)"; siklar=$yeni.siklar; dogru="$($yeni.dogru)"; aciklama=$yeni.aciklama; hap="$($yeni.hap)"
    yayin=$false; yayin_notu=('onarildi ' + (Get-Date -Format 'dd.MM.yyyy') + ' (GM okudu, kusur: ' + ("$($t.kusur)".Substring(0,[Math]::Min(80,"$($t.kusur)".Length))) + ') - hakem yargisi bekliyor')
  })
  try {
    $istek = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::new('PATCH')), ("$U`?id=eq." + $id)
    $istek.Content = New-Object System.Net.Http.StringContent ($gov, [Text.Encoding]::UTF8, 'application/json')
    $istek.Headers.Add('Prefer','return=minimal')
    $cvp = $hc.SendAsync($istek).GetAwaiter().GetResult()
    if([int]$cvp.StatusCode -eq 204){ $uygulanan++ } else { $hataLi += ($id + '|http-' + [int]$cvp.StatusCode) }
    $cvp.Dispose(); $istek.Dispose()
  } catch { $hataLi += ($id + '|' + $_.Exception.Message.Substring(0,[Math]::Min(40,$_.Exception.Message.Length))) }
  Start-Sleep -Milliseconds 400
}
$hc.Dispose()
Write-Host ("{0}: {1} soru | taslagi-olmayan {2} | hata {3}" -f $(if($yaz){'UYGULANDI'}else{'OLCUM'}), $uygulanan, $taslakYok.Count, $hataLi.Count)
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$(if($yaz){'UYGULANDI'}else{'OLCUM'})
  onayli=$onayli.Count; uygulanan=$uygulanan; taslakYok=@($taslakYok | Select-Object -First 50); hatalar=@($hataLi | Select-Object -First 50)
  not='Uygulanan sorular yayin=false + onarildi notuyla HAKEM kuyrugunda; yayina donus hakem+yayin kapisindan.'
})
