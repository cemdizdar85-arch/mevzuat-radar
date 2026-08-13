# ============================================================================
#  K15 - SINAV TEKNIGI KAPISI (13.08.2026) — 0 USD, API YOK, YAZMA YOK
#
#  CEM: "aklimizdan kacan koymamiz gereken kontrol varsa koyalim onu da."
#  Kacan sinif buydu: tek tek sorular dogru olsa bile KUME sinav teknigi
#  acigi verebilir. Uc olcum:
#   T1) CEVAP ANAHTARI DAGILIMI: dogru cevaplar A-E arasinda dengeli mi?
#       (hepsi C'ye yigilirsa ogrenci taktikle gecer; beklenen ~%20/sik,
#        sapma > 8 puan = uyari, > 15 puan = KIRMIZI)
#   T2) DOGRU-SIK-UZUNLUK DESENI: dogru sik, ortalama kac soruda EN UZUN sik?
#       (YZ uretiminin klasik izi; > %45 = KIRMIZI - taktikci "en uzunu isaretle"
#        ile iceriksiz gecer. Rastgele beklenen ~%20)
#   T3) KUME-ICI YAKIN KOPYA: soru metninin normalize ilk 90 karakteri ayni
#       olan cift var mi? (ayni denemede iki kopya soru cikmasin)
#
#  KAPSAM: varsayilan yayin-kapisi-temiz-idler kumesi (yayin adaylari);
#  -tumKasa ile 30K'nin tamami. Cikti: veri/k15-sinav-teknigi.json
# ============================================================================
param([switch]$tumKasa)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ciktiYol = Join-Path $kok 'veri\k15-sinav-teknigi.json'
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok.'; exit 1 }
$B = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$ADRES = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'

# hedef kume
$hedefSet = $null
if(-not $tumKasa){
  $liste = (Get-Content (Join-Path $kok 'veri\yayin-kapisi-temiz-idler.json') -Raw -Encoding UTF8 | ConvertFrom-Json).idler
  $hedefSet = @{}; foreach($x in $liste){ $hedefSet["$($x.id)"] = $true }
  Write-Host ("Kapsam: yayin adayi {0} soru" -f $hedefSet.Count)
} else { Write-Host 'Kapsam: TUM KASA' }

# kasayi sayfalayarak cek (yalniz gerekli kolonlar)
$kayitlar = New-Object System.Collections.Generic.List[object]
for($of=0; $of -lt 40000; $of+=1000){
  $r = Invoke-WebRequest -UseBasicParsing -Uri "$ADRES/soru_havuzu?select=id,sinav,ders,soru,siklar,dogru&order=id&limit=1000&offset=$of" -Headers $B -TimeoutSec 120
  $j = ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json)
  if(@($j).Count -eq 0){ break }
  foreach($s in $j){ if($null -eq $hedefSet -or $hedefSet.ContainsKey("$($s.id)")){ $kayitlar.Add($s) } }
  if(@($j).Count -lt 1000){ break }
}
Write-Host ("Cekilen: {0} soru" -f $kayitlar.Count)
if($kayitlar.Count -eq 0){ Write-Host 'Olculecek soru yok.'; exit 0 }

# --- T1: cevap dagilimi (genel + ders bazli) ---
$dag = @{}; foreach($h in 'A','B','C','D','E'){ $dag[$h]=0 }
$dersDag = @{}
foreach($s in $kayitlar){
  $d0 = "$($s.dogru)".Trim().ToUpper()
  if($dag.ContainsKey($d0)){ $dag[$d0]++ }
  $dk = "$($s.ders)"; if(-not $dersDag.ContainsKey($dk)){ $dersDag[$dk] = @{A=0;B=0;C=0;D=0;E=0;n=0} }
  if($dersDag[$dk].ContainsKey($d0)){ $dersDag[$dk][$d0]++ }; $dersDag[$dk].n++
}
$n = $kayitlar.Count
$t1 = [ordered]@{}; $t1sapma = 0
foreach($h in 'A','B','C','D','E'){ $y = [math]::Round(100.0*$dag[$h]/$n,1); $t1[$h] = "$($dag[$h]) (%$y)"; $s2=[math]::Abs($y-20); if($s2 -gt $t1sapma){ $t1sapma = $s2 } }
$t1durum = if($t1sapma -gt 15){ 'KIRMIZI' } elseif($t1sapma -gt 8){ 'UYARI' } else { 'YESIL' }

# --- T2: dogru sik en uzun mu ---
$enUzunDogru = 0; $olculen = 0
foreach($s in $kayitlar){
  if(-not $s.siklar){ continue }
  $d0 = "$($s.dogru)".Trim().ToUpper()
  $uz = @{}; $ok = $true
  foreach($p in $s.siklar.PSObject.Properties){ $uz[$p.Name] = "$($p.Value)".Length }
  if(-not $uz.ContainsKey($d0) -or $uz.Count -lt 4){ continue }
  $olculen++
  $enB = ($uz.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1).Key
  if($enB -eq $d0){ $enUzunDogru++ }
}
$t2oran = if($olculen){ [math]::Round(100.0*$enUzunDogru/$olculen,1) } else { 0 }
$t2durum = if($t2oran -gt 45){ 'KIRMIZI' } elseif($t2oran -gt 33){ 'UYARI' } else { 'YESIL' }

# --- T3: kume-ici yakin kopya (normalize ilk 90 karakter imzasi) ---
$imza = @{}; $kopyalar = New-Object System.Collections.Generic.List[object]
foreach($s in $kayitlar){
  $t = "$($s.soru)".ToLowerInvariant() -replace '[^a-zçğıöşü0-9]',''
  if($t.Length -lt 40){ continue }
  $k = $t.Substring(0,[Math]::Min(90,$t.Length))
  if($imza.ContainsKey($k)){ $kopyalar.Add([pscustomobject]@{ a=$imza[$k]; b="$($s.id)"; ders="$($s.ders)" }) } else { $imza[$k] = "$($s.id)" }
}
$t3durum = if($kopyalar.Count -gt 0){ 'KIRMIZI' } else { 'YESIL' }

$rapor = [ordered]@{
  tarih=(Get-Date).ToString('dd.MM.yyyy HH:mm'); kapsam=$(if($tumKasa){'tum-kasa'}else{'yayin-adaylari'}); soru=$n
  T1_cevap_dagilimi=[ordered]@{ durum=$t1durum; azami_sapma_puan=$t1sapma; dagilim=$t1 }
  T2_dogru_sik_en_uzun=[ordered]@{ durum=$t2durum; oran_yuzde=$t2oran; olculen=$olculen; not='rastgele beklenen ~%20; %45 ustu taktikle gecilir' }
  T3_yakin_kopya=[ordered]@{ durum=$t3durum; cift=$kopyalar.Count; ornekler=@($kopyalar | Select-Object -First 20) }
  not='K15 OLCER, karar vermez. KIRMIZI cikan boyut yayin oncesi cozulur: T1/T2 icin sik karistirma (dogru cevabi rastgele sikka tasima) onarim hattinda yapilir; T3 ciftlerinden biri yayindan tutulur.'
}
[IO.File]::WriteAllText($ciktiYol, (ConvertTo-Json $rapor -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ''
Write-Host ("T1 CEVAP DAGILIMI : {0} (azami sapma {1} puan) {2}" -f $t1durum, $t1sapma, (($t1.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ' '))
Write-Host ("T2 EN-UZUN-DOGRU  : {0} (%{1}, {2} soruda olculdu)" -f $t2durum, $t2oran, $olculen)
Write-Host ("T3 YAKIN KOPYA    : {0} ({1} cift)" -f $t3durum, $kopyalar.Count)
Write-Host ("-> {0}" -f $ciktiYol)
