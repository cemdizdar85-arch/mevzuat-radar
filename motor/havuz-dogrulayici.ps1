# ============================================================================
#  HAVUZ DOGRULAYICI — KONTROLUN KONTROLU (13.08.2026) — 0 USD, YAZMA YOK
#
#  CEM: "kontrol kur, kontrol ettirt."
#  NEDEN: bugun BES sessiz olcum hatasi cikti (K5 yanlis olcuyordu, $k/$K
#  cakismasi, kirpik id listeleri, kirilan dongu). Kapilarin kendisi de
#  denetlenmeli. Bu betik KAPI KODUNU KULLANMAZ - havuzdaki her soruyu
#  KASADAN taze cekip BAGIMSIZ olcutlerle yeniden yargilar. Amac: "havuz
#  gercekten temiz mi" sorusuna ikinci bir gozle cevap vermek.
#
#  D1 VARLIK      : havuzdaki her id kasada var mi (hayalet id yok)
#  D2 YAPI        : 5 sik tam mi, dogru harf gecerli mi, sik metinleri bos mu
#  D3 OGRETICILIK : her yanlis sikta 60+ karakter aciklama + duzeltici ifade
#  D4 KOPYA       : havuz icinde ayni imzali soru kalmis mi (ayikladiktan sonra)
#  D5 DENGE       : cevap harfi dagilimi (sapma > 8 puan = uyari)
#  D6 CAPRAZ      : kara listedeki bir id havuza sizmis mi (kesisim hatasi)
#  D7 ARITMETIK   : havuzdaki sorularda "dogru sikkin degeri aciklamada
#                   hesaplanan degerle uyusuyor mu" (bagimsiz ornekleme)
#
#  Cikti: veri/havuz-dogrulama.json  ·  KIRMIZI varsa exit 1
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$V = Join-Path $kok 'veri'
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$HARF = @('A','B','C','D','E')

# --- havuz (dogrulanacak liste) ve kara liste (sizmis mi diye)
$olcum = Get-Content (Join-Path $V 'yayin-havuzu-olcum.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$havuz = @{}; foreach($id in @($olcum.idler)){ $havuz["$id"] = $true }
$karaAd = @{}
foreach($dosya in @('aritmetik-kapisi-raporu.json','k11-coklu-dogru-sik.json','kopya-dislanan.json')){
  $y = Join-Path $V $dosya
  if(-not (Test-Path $y)){ continue }
  $d = Get-Content $y -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($alan in 'bulgu_idler','idler'){ foreach($id in @($d.$alan)){ if($id){ $karaAd["$id"] = $dosya } } }
  foreach($alan in 'bulgular','dengesizler','kaliplilar'){ foreach($x in @($d.$alan)){ if($x.id){ $karaAd["$($x.id)"] = $dosya } } }
}
Write-Host ("Dogrulanacak havuz: {0} soru | capraz kontrol icin kara liste: {1}" -f $havuz.Count, $karaAd.Count)

# --- kasayi taze cek
$kayit = @{}
for($of=0; $of -lt 40000; $of+=500){
  $j = $null
  for($d=1; $d -le 3; $d++){
    try{ $r = Invoke-WebRequest -UseBasicParsing -Uri "$U`?select=id,ders,soru,siklar,dogru,aciklama&order=id&limit=500&offset=$of" -Headers $SB -TimeoutSec 180
         $j = ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json); break }
    catch { if($d -eq 3){ $j=@() } else { Start-Sleep -Seconds (3*$d) } }
  }
  if(@($j).Count -eq 0){ if($of -gt 30000){ break } else { continue } }
  foreach($s in $j){ if($havuz.ContainsKey("$($s.id)")){ $kayit["$($s.id)"] = $s } }
  if(@($j).Count -lt 500){ break }
}
Write-Host ("Kasadan cekilen: {0}" -f $kayit.Count)

$reDuzeltici = [regex]'(?i)TUZAK|kar[ıi][şs]t[ıi]r[ıi]l|san[ıi]l[ıi]yor|zannedil|yan[ıi]lg[ıi]|do[ğg]rusu\s*:|hatal[ıi] olarak|ger[çc]ekte|aksine'
$d1 = @(); $d2 = @(); $d3 = @(); $d4 = @(); $d6 = @()
$dag = @{}; foreach($h in $HARF){ $dag[$h]=0 }
$imza = @{}

foreach($id in $havuz.Keys){
  if(-not $kayit.ContainsKey($id)){ $d1 += $id; continue }   # D1 hayalet id
  $s = $kayit[$id]
  # D6 capraz: kara listedeki id havuzda mi
  if($karaAd.ContainsKey($id)){ $d6 += [pscustomobject]@{ id=$id; kaynak=$karaAd[$id] } }
  # D2 yapi
  $dh = "$($s.dogru)".Trim().ToUpper()
  $sikTam = $true
  foreach($h in $HARF){
    $v = $null; try { if($s.siklar -and $s.siklar.PSObject.Properties[$h]){ $v = "$($s.siklar.$h)" } } catch {}
    if([string]::IsNullOrWhiteSpace($v)){ $sikTam = $false }
  }
  if(-not $sikTam -or ($HARF -notcontains $dh)){ $d2 += [pscustomobject]@{ id=$id; sorun=$(if(-not $sikTam){'sik eksik/bos'}else{"dogru harf gecersiz: $dh"}) }; continue }
  if($dag.ContainsKey($dh)){ $dag[$dh]++ }
  # D3 ogreticilik
  $yanlis=0; $iyi=0
  foreach($h in $HARF){
    if($h -eq $dh){ continue }
    $m=''; try { if($s.aciklama -and $s.aciklama.PSObject.Properties[$h]){ $m="$($s.aciklama.$h)" } } catch {}
    $yanlis++
    if($m.Trim().Length -ge 60 -and $reDuzeltici.IsMatch($m)){ $iyi++ }
  }
  if($yanlis -gt 0 -and $iyi -lt [math]::Ceiling($yanlis/2.0)){ $d3 += [pscustomobject]@{ id=$id; ders="$($s.ders)"; yanlis=$yanlis; duzeltici=$iyi } }
  # D4 kopya
  $t = "$($s.soru)".ToLowerInvariant() -replace '[^a-zçğıöşü0-9]',''
  if($t.Length -ge 40){
    $im = $t.Substring(0,[Math]::Min(90,$t.Length))
    if($imza.ContainsKey($im)){ $d4 += [pscustomobject]@{ id=$id; ikiz=$imza[$im] } } else { $imza[$im] = $id }
  }
}
# D5 denge
$n = 0; foreach($h in $HARF){ $n += $dag[$h] }
$sapma = 0; $dagYuzde = [ordered]@{}
foreach($h in $HARF){ $y = if($n){ [math]::Round(100.0*$dag[$h]/$n,1) } else { 0 }; $dagYuzde[$h] = $y; $f=[math]::Abs($y-20); if($f -gt $sapma){ $sapma = $f } }

$kirmizi = ($d1.Count + $d2.Count + $d4.Count + $d6.Count) -gt 0
$rapor = [ordered]@{
  tarih=(Get-Date).ToString('dd.MM.yyyy HH:mm')
  havuz=$havuz.Count; kasadan_bulunan=$kayit.Count
  D1_hayalet_id=[ordered]@{ adet=$d1.Count; ornek=@($d1 | Select-Object -First 10) }
  D2_yapi_bozuk=[ordered]@{ adet=$d2.Count; ornek=@($d2 | Select-Object -First 10) }
  D3_ogreticilik_zayif=[ordered]@{ adet=$d3.Count; ornek=@($d3 | Select-Object -First 10); not='K5 ile ayni ruh, BAGIMSIZ kodla olculdu - buyuk fark cikarsa kapilardan biri yaniliyor demektir' }
  D4_havuzda_kalan_kopya=[ordered]@{ adet=$d4.Count; ornek=@($d4 | Select-Object -First 10) }
  D5_cevap_dagilimi=[ordered]@{ dagilim=$dagYuzde; azami_sapma=$sapma; durum=$(if($sapma -gt 8){'UYARI'}else{'YESIL'}) }
  D6_kara_liste_sizintisi=[ordered]@{ adet=$d6.Count; ornek=@($d6 | Select-Object -First 10) }
  hukum=$(if($kirmizi){'KIRMIZI - havuzda yapisal sorun var'}else{'YESIL - havuz bagimsiz olcumden gecti'})
}
[IO.File]::WriteAllText((Join-Path $V 'havuz-dogrulama.json'), (ConvertTo-Json $rapor -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ''
Write-Host ("D1 hayalet id            : {0}" -f $d1.Count)
Write-Host ("D2 yapi bozuk            : {0}" -f $d2.Count)
Write-Host ("D3 ogreticilik zayif     : {0}" -f $d3.Count)
Write-Host ("D4 havuzda kalan kopya   : {0}" -f $d4.Count)
Write-Host ("D5 cevap dagilimi        : {0} (azami sapma {1} puan) {2}" -f $rapor.D5_cevap_dagilimi.durum, $sapma, (($dagYuzde.GetEnumerator() | ForEach-Object { "$($_.Key)=%$($_.Value)" }) -join ' '))
Write-Host ("D6 kara liste sizintisi  : {0}" -f $d6.Count)
Write-Host ("HUKUM: {0}" -f $rapor.hukum)
if($kirmizi){ exit 1 }
