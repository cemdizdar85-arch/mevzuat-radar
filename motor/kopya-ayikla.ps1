# ============================================================================
#  KOPYA AYIKLAYICI (13.08.2026) — 0 USD, KASAYA YAZMAZ
#  CEM: "83 yakin-kopya cifti - yap."
#  K15-T3 ayni normalize imzali (ilk 90 karakter) soru ciftlerini bulmustu ama
#  raporu 20 ornekle kirpiyordu. Bu betik TAM listeyi cikarir ve her gruptan
#  BIRINI TUTAR, digerlerini YAYIN DISI listesine yazar (kasa DEGISMEZ - soru
#  silinmez, yalniz yayin havuzundan dislanir; ileride onarilip geri alinabilir).
#
#  TUTULACAK SORU nasil secilir (sirayla):
#   1. Kara listede OLMAYAN tercih edilir (aritmetik/K17 bulgusu olan elenir)
#   2. Kaynak bilgisi tam olan (kanun_no + madde_no dolu)
#   3. Aciklamasi daha uzun olan (daha cok ogreten)
#   4. Esitlikte id'si kucuk olan (deterministik - her kosuda ayni sonuc)
#  Cikti: veri/kopya-dislanan.json
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$V = Join-Path $kok 'veri'
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok.'; exit 1 }
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'

# --- yayin havuzu (K1-K10 temiz) ve kara liste
$temiz = (Get-Content (Join-Path $V 'yayin-kapisi-temiz-idler.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
$havuz = @{}; foreach($x in @($temiz.idler)){ $havuz["$($x.id)"] = $true }
$kara = @{}
$olcum = Join-Path $V 'yayin-havuzu-olcum.json'
if(Test-Path $olcum){
  $o = Get-Content $olcum -Raw -Encoding UTF8 | ConvertFrom-Json
  $hepsindenTemiz = @{}; foreach($id in @($o.idler)){ $hepsindenTemiz["$id"] = $true }
  foreach($id in $havuz.Keys){ if(-not $hepsindenTemiz.ContainsKey($id)){ $kara[$id] = $true } }
}
Write-Host ("Havuz: {0} | kara listede: {1}" -f $havuz.Count, $kara.Count)

# --- kasayi cek (yalniz havuzdakiler)
$kayit = @{}
$SAYFA = 500
for($of=0; $of -lt 40000; $of+=$SAYFA){
  $j = $null
  for($d=1; $d -le 3; $d++){
    try{ $r = Invoke-WebRequest -UseBasicParsing -Uri "$U`?select=id,ders,soru,aciklama,kanun_no,madde_no&order=id&limit=$SAYFA&offset=$of" -Headers $SB -TimeoutSec 180
         $j = ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json); break }
    catch { if($d -eq 3){ $j=@() } else { Start-Sleep -Seconds (3*$d) } }
  }
  if(@($j).Count -eq 0){ if($of -gt 30000){ break } else { continue } }
  foreach($s in $j){ if($havuz.ContainsKey("$($s.id)")){ $kayit["$($s.id)"] = $s } }
  if(@($j).Count -lt $SAYFA){ break }
}
Write-Host ("Cekilen havuz sorusu: {0}" -f $kayit.Count)

# --- imza: normalize ilk 90 karakter
$grup = @{}
foreach($id in $kayit.Keys){
  $t = "$($kayit[$id].soru)".ToLowerInvariant() -replace '[^a-zçğıöşü0-9]',''
  if($t.Length -lt 40){ continue }
  $im = $t.Substring(0,[Math]::Min(90,$t.Length))
  if(-not $grup.ContainsKey($im)){ $grup[$im] = New-Object System.Collections.Generic.List[string] }
  $grup[$im].Add($id)
}
function AciklamaUzunluk($s){ $u=0; if($s.aciklama){ if($s.aciklama -is [string]){ $u=$s.aciklama.Length } else { foreach($p in $s.aciklama.PSObject.Properties){ $u += "$($p.Value)".Length } } }; return $u }

$dislanan = New-Object System.Collections.Generic.List[object]
$grupSayisi = 0
foreach($im in $grup.Keys){
  $uyeler = @($grup[$im])
  if($uyeler.Count -lt 2){ continue }
  $grupSayisi++
  # puanla: kara listede degil (100) + kaynak tam (10) + aciklama uzunlugu (0-9 normalize)
  $enIyi = $null; $enIyiPuan = -1
  foreach($id in ($uyeler | Sort-Object)){
    $s = $kayit[$id]
    $puan = 0
    if(-not $kara.ContainsKey($id)){ $puan += 100 }
    if("$($s.kanun_no)" -ne '' -and "$($s.madde_no)" -ne ''){ $puan += 10 }
    $puan += [Math]::Min(9, [int]((AciklamaUzunluk $s)/500))
    if($puan -gt $enIyiPuan){ $enIyiPuan = $puan; $enIyi = $id }
  }
  foreach($id in ($uyeler | Sort-Object)){
    if($id -eq $enIyi){ continue }
    $dislanan.Add([pscustomobject]@{ id=$id; tutulan=$enIyi; ders="$($kayit[$id].ders)"; kesit=("$($kayit[$id].soru)".Substring(0,[Math]::Min(70,"$($kayit[$id].soru)".Length))) })
  }
}
$rapor = [ordered]@{
  tarih=(Get-Date).ToString('dd.MM.yyyy HH:mm')
  havuz=$kayit.Count; kopya_grubu=$grupSayisi; dislanan=$dislanan.Count
  not='Kasa DEGISMEDI - sorular silinmedi. Bu idler yalniz YAYIN HAVUZUNDAN dislanir (yayina-al ve havuz olcumu okur). Her gruptan bir soru TUTULDU: kara listede olmayan > kaynagi tam > aciklamasi uzun > id kucuk.'
  ornek=@($dislanan | Select-Object -First 15)
  idler=@($dislanan | ForEach-Object { $_.id })
}
[IO.File]::WriteAllText((Join-Path $V 'kopya-dislanan.json'), (ConvertTo-Json $rapor -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host ("KOPYA GRUBU: {0} | DISLANAN: {1} -> veri\kopya-dislanan.json" -f $grupSayisi, $dislanan.Count)
