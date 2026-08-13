# ============================================================================
#  K17 - MADDE YAZIM KUSURU KAPISI (13.08.2026) — 0 USD, API YOK, YAZMA YOK
#
#  CEM: "ABD Ingiltere rakiplere bak, biz bu isin en iyisi olmaliyiz."
#  Dunya olcutu: NBME Item-Writing Guide (ABD tip sinavlarinin altin standardi;
#  AICPA/CPA bankalari da ayni ilkeleri kullanir). Iki kusur ailesi tanimlar:
#   (a) GEREKSIZ ZORLUK katanlar  (b) KURNAZ ADAYI KAYIRAN ipucu kusurlari.
#  Bizim K1-K16 kapilarimiz icerigi denetliyordu; MADDE YAZIM TEKNIGI acikti.
#
#  OLCTUKLERI (hepsi ipucu kusuru ailesi):
#   F1 MUTLAK TERIM  : sikta "her zaman/asla/daima/kesinlikle/hicbir zaman"
#                      (bu sikkar neredeyse hep yanlistir -> aday eler)
#   F2 HEPSI/HICBIRI : "yukaridakilerin hepsi/hicbiri" tipi siklar
#   F3 UZUNLUK IPUCU : dogru sik, digerlerinin ortalamasinin 1,6 kati+ uzun
#                      (tek soru bazinda; K15 kume bazinda olcer)
#   F4 SAYI SIRASI   : tum siklar sayisal ama artan/azalan sirada degil
#                      (adayin karsilastirma yukunu bosuna artirir)
#   F5 KELIME TEKRARI: soru kokundeki nadir kelime YALNIZ dogru sikta geciyor
#                      (klasik "word repeat" ipucu)
#   F6 OLUMSUZ KOK   : "degildir/yanlis/hangisi ... olamaz" vurgusuz yazilmis
#                      (NBME: olumsuz kok kacinilmazsa VURGULANMALI)
#
#  Kapsam: yayin adaylari (varsayilan) | -tumKasa   Cikti: veri/k17-madde-yazim.json
# ============================================================================
param([switch]$tumKasa)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ciktiYol = Join-Path $kok 'veri\k17-madde-yazim.json'
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok.'; exit 1 }
$B = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$ADRES = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'

$hedefSet = $null
if(-not $tumKasa){
  $liste = (Get-Content (Join-Path $kok 'veri\yayin-kapisi-temiz-idler.json') -Raw -Encoding UTF8 | ConvertFrom-Json).idler
  $hedefSet = @{}; foreach($x in $liste){ $hedefSet["$($x.id)"] = $true }
}
$kayitlar = New-Object System.Collections.Generic.List[object]
for($of=0; $of -lt 40000; $of+=500){
  $j = $null
  for($d=1; $d -le 3; $d++){
    try{ $r = Invoke-WebRequest -UseBasicParsing -Uri "$ADRES/soru_havuzu?select=id,ders,soru,siklar,dogru&order=id&limit=500&offset=$of" -Headers $B -TimeoutSec 180
         $j = ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json); break }
    catch { if($d -eq 3){ $j=@() } else { Start-Sleep -Seconds (2*$d) } }
  }
  if(@($j).Count -eq 0){ if($of -gt 30000){ break } else { continue } }
  foreach($s in $j){ if($null -eq $hedefSet -or $hedefSet.ContainsKey("$($s.id)")){ $kayitlar.Add($s) } }
  if(@($j).Count -lt 500){ break }
}
Write-Host ("Cekilen: {0} soru" -f $kayitlar.Count)

$reMutlak  = [regex]'(?i)\b(her ?zaman|asla|daima|kesinlikle|hi[çc]bir ?zaman|istisnas[ıi]z|mutlaka)\b'
$reHepsi   = [regex]'(?i)(yukar[ıi]dakiler(in|den)? (hepsi|hi[çc]biri)|hepsi do[ğg]ru|hi[çc]biri do[ğg]ru)'
$reOlumsuz = [regex]'(?i)(de[ğg]ildir|yanl[ıi][şs]t[ıi]r|olamaz|s[öo]ylenemez|hangisi yanl[ıi][şs]|hangisi ... de[ğg]il)'
$reVurgu   = [regex]'(<b>|<strong>|\bDE[ĞG][İI]LD[İI]R\b|\bYANLI[ŞS]\b|\bOLAMAZ\b|\bHANG[İI]S[İI] YANLI[ŞS]\b)'
# Turkce siklikta gecen kelimeler (kelime-tekrari ipucunda sayilmaz)
$stop = @('bir','ile','ve','veya','icin','için','olarak','olan','gore','göre','bu','da','de','en','her','tum','tüm','ise','ki','mi','mu','daha','sonra','once','önce','uzere','üzere','kadar','gibi','ancak','yani','tarafindan','tarafından','uzerinden','üzerinden','yapilan','yapılan','olmak','edilir','edilen')

$f1=@(); $f2=@(); $f3=@(); $f4=@(); $f5=@(); $f6=@()
foreach($s in $kayitlar){
  if(-not $s.siklar){ continue }
  $d0 = "$($s.dogru)".Trim().ToUpper()
  $sik = @{}
  foreach($p in $s.siklar.PSObject.Properties){ $sik[$p.Name.ToUpper()] = "$($p.Value)" }
  if(-not $sik.ContainsKey($d0) -or $sik.Count -lt 4){ continue }
  $dogruMetin = $sik[$d0]

  # F1 mutlak terim
  $mut = @($sik.GetEnumerator() | Where-Object { $reMutlak.IsMatch($_.Value) } | ForEach-Object { $_.Key })
  if($mut.Count -gt 0 -and $mut.Count -lt $sik.Count){ $f1 += [pscustomobject]@{ id="$($s.id)"; ders="$($s.ders)"; siklar=($mut -join ','); dogru=$d0; dogruda_var=($mut -contains $d0) }
  }
  # F2 hepsi/hicbiri
  $hep = @($sik.GetEnumerator() | Where-Object { $reHepsi.IsMatch($_.Value) } | ForEach-Object { $_.Key })
  if($hep.Count -gt 0){ $f2 += [pscustomobject]@{ id="$($s.id)"; ders="$($s.ders)"; siklar=($hep -join ',') } }
  # F3 uzunluk ipucu (tek soru bazinda)
  $digerUz = @($sik.GetEnumerator() | Where-Object { $_.Key -ne $d0 } | ForEach-Object { $_.Value.Length })
  $ort = ($digerUz | Measure-Object -Average).Average
  if($ort -gt 0 -and $dogruMetin.Length -ge 40 -and ($dogruMetin.Length / $ort) -ge 1.6){
    $f3 += [pscustomobject]@{ id="$($s.id)"; ders="$($s.ders)"; dogru_uzunluk=$dogruMetin.Length; diger_ort=[math]::Round($ort,0); kat=[math]::Round($dogruMetin.Length/$ort,2) }
  }
  # F4 sayi sirasi
  $sayi = @(); $hepsiSayi = $true
  foreach($k in ($sik.Keys | Sort-Object)){
    $t = ($sik[$k] -replace '[^\d,\.]','') -replace '\.','' -replace ',','.'
    if($t -match '^\d+(\.\d+)?$' -and $sik[$k].Length -le 30){ $sayi += [double]$t } else { $hepsiSayi = $false; break }
  }
  if($hepsiSayi -and $sayi.Count -ge 4){
    $artan = $true; $azalan = $true
    for($i=1;$i -lt $sayi.Count;$i++){ if($sayi[$i] -lt $sayi[$i-1]){ $artan=$false }; if($sayi[$i] -gt $sayi[$i-1]){ $azalan=$false } }
    if(-not $artan -and -not $azalan){ $f4 += [pscustomobject]@{ id="$($s.id)"; ders="$($s.ders)"; degerler=($sayi -join ' | ') } }
  }
  # F5 kelime tekrari ipucu
  $kokKelime = @([regex]::Matches("$($s.soru)".ToLowerInvariant(),'[a-zçğıöşü]{6,}') | ForEach-Object { $_.Value } | Where-Object { $stop -notcontains $_ } | Select-Object -Unique)
  $ipucu = @()
  foreach($kk in $kokKelime){
    $gecen = @($sik.GetEnumerator() | Where-Object { $_.Value.ToLowerInvariant().Contains($kk) } | ForEach-Object { $_.Key })
    if($gecen.Count -eq 1 -and $gecen[0] -eq $d0){ $ipucu += $kk }
  }
  if($ipucu.Count -ge 2){ $f5 += [pscustomobject]@{ id="$($s.id)"; ders="$($s.ders)"; kelimeler=(($ipucu | Select-Object -First 4) -join ', ') } }
  # F6 olumsuz kok vurgusuz
  if($reOlumsuz.IsMatch("$($s.soru)") -and -not $reVurgu.IsMatch("$($s.soru)")){
    $f6 += [pscustomobject]@{ id="$($s.id)"; ders="$($s.ders)" }
  }
}
$n = $kayitlar.Count
function Yuzde($a){ if($n){ [math]::Round(100.0*$a/$n,1) } else { 0 } }
$rapor = [ordered]@{
  tarih=(Get-Date).ToString('dd.MM.yyyy HH:mm'); kapsam=$(if($tumKasa){'tum-kasa'}else{'yayin-adaylari'}); soru=$n
  olcut='NBME Item-Writing Guide (ABD) ipucu-kusuru aileleri, Turkceye uyarlandi'
  F1_mutlak_terim=[ordered]@{ adet=$f1.Count; yuzde=(Yuzde $f1.Count); ornek=@($f1 | Select-Object -First 20) }
  F2_hepsi_hicbiri=[ordered]@{ adet=$f2.Count; yuzde=(Yuzde $f2.Count); ornek=@($f2 | Select-Object -First 20) }
  F3_uzunluk_ipucu=[ordered]@{ adet=$f3.Count; yuzde=(Yuzde $f3.Count); ornek=@($f3 | Select-Object -First 20) }
  F4_sayi_sirasi=[ordered]@{ adet=$f4.Count; yuzde=(Yuzde $f4.Count); ornek=@($f4 | Select-Object -First 20) }
  F5_kelime_tekrari=[ordered]@{ adet=$f5.Count; yuzde=(Yuzde $f5.Count); ornek=@($f5 | Select-Object -First 20) }
  F6_olumsuz_kok_vurgusuz=[ordered]@{ adet=$f6.Count; yuzde=(Yuzde $f6.Count); ornek=@($f6 | Select-Object -First 20) }
  not='K17 OLCER, karar vermez. F1/F2 yeniden yazim ister; F3 sik dengeleme; F4 siralama (mekanik, guvenli); F5 kok/sik kelime revizyonu; F6 vurgu eklenmesi.'
}
[IO.File]::WriteAllText($ciktiYol, (ConvertTo-Json $rapor -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ''
Write-Host ("F1 mutlak terim        : {0} (%{1})" -f $f1.Count, (Yuzde $f1.Count))
Write-Host ("F2 hepsi/hicbiri sikki : {0} (%{1})" -f $f2.Count, (Yuzde $f2.Count))
Write-Host ("F3 uzunluk ipucu       : {0} (%{1})" -f $f3.Count, (Yuzde $f3.Count))
Write-Host ("F4 sayi sirasi bozuk   : {0} (%{1})" -f $f4.Count, (Yuzde $f4.Count))
Write-Host ("F5 kelime tekrari ipucu: {0} (%{1})" -f $f5.Count, (Yuzde $f5.Count))
Write-Host ("F6 olumsuz kok vurgusuz: {0} (%{1})" -f $f6.Count, (Yuzde $f6.Count))
Write-Host ("-> {0}" -f $ciktiYol)
