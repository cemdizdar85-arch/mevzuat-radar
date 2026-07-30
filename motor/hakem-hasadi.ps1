# ============================================================================
#  HAKEM HASADI — ödenmiş denetim yargılarını partilerden topla   (0 USD)
#
#  NEDEN VAR (29.07 gecesi): "Başarısız emir açık kalıyor" kusuru yüzünden
#  4.366 soruluk hakem denetimi bugün en az bir kez TAM gönderildi ve bütçeyi
#  bitirdi. Sonuçları partilerde "ended/succeeded" duruyor — SONUÇ ÇEKMEK
#  ÜCRETSİZDİR (ücret parti işlenirken alınır, o zaten alındı).
#
#  KİMLİK TAHMİNİ YOK — parti İÇERİĞİNDEN tanınır:
#  Bir partinin ilk sonucu (a) custom_id'si UUID biçimli ve (b) cevabı
#  '"destek"' alanı içeren JSON ise o parti HAKEM partisidir. Üretim
#  partileri (custom_id u0_1) ve başka koşular kendiliğinden elenir.
#  Kanıt: 16:01 partisi elle doğrulandı — çıktı {"destek","tek_dogru",
#  "celiski","dogru_sik","gerekce"} ve pilot-kuyruğu kesişimi 29/400
#  (4.366'lık kuyrukta beklenen ~32 ile uyumlu).
#
#  AYNI SORU İKİ PARTİDE OLABİLİR (kuyruk iki kez gönderildiyse):
#  parti oluşturulma sırasına göre EN SON yargı kazanır — en taze deneme.
#
#  Çıktı: veri/hakem-hasadi.json  (soru UUID -> yargı) + özet + kırmızı liste
#  Kasaya DOKUNMAZ — yargılar rapordur; yayından çekme kararını GM verir.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
try { Start-Transcript -Path (Join-Path $kok 'veri/hakem-hasadi-log.txt') -Force | Out-Null } catch {}

$AK = "$env:ANTHROPIC_API_KEY".Trim()
if(-not $AK){ Write-Host "ANTHROPIC_API_KEY yok - cikiliyor."; try{Stop-Transcript|Out-Null}catch{}; exit 1 }
$HDR = @{ 'x-api-key'=$AK; 'anthropic-version'='2023-06-01' }

$listeYol = Join-Path $kok 'veri/parti-listesi.json'
if(-not (Test-Path $listeYol)){ Write-Host "parti-listesi.json yok - once parti-liste kosmali."; try{Stop-Transcript|Out-Null}catch{}; exit 1 }
$ham = ConvertFrom-Json ([IO.File]::ReadAllText($listeYol, [Text.Encoding]::UTF8))
$adaylar = New-Object System.Collections.Generic.List[object]
foreach($x in $ham){
  if("$($x.durum)" -ne 'ended'){ continue }
  if([int]$x.basarili -lt 1){ continue }
  $adaylar.Add($x)
}
Write-Host ("Aday parti (ended+basarili): {0}" -f $adaylar.Count)

# olusturulma sirasina gore: eski -> yeni (son yazan kazansin diye)
$sirali = @($adaylar | Sort-Object { [datetime]::Parse("$($_.olusturuldu)") })

$yargi = @{}          # soru UUID -> yargi nesnesi
$hakemParti = 0; $atlanan = 0; $cekilemeyen = 0
foreach($b in $sirali){
  try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri "https://api.anthropic.com/v1/messages/batches/$($b.id)/results" -Headers $HDR -TimeoutSec 300
    $mt = if($r.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($r.Content) } else { "$($r.Content)" }
  } catch { $cekilemeyen++; continue }
  $satirlar = $mt -split "`r?`n"
  # ilk gecerli satirdan tur tespiti
  $ilkSat = $null
  foreach($s in $satirlar){ if("$s".Trim()){ $ilkSat = $s; break } }
  if(-not $ilkSat){ $atlanan++; continue }
  $uuidMi = $ilkSat -match '"custom_id"\s*:\s*"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"'
  $hakemMi = $ilkSat -match '\\"destek\\"|"destek"'
  if(-not ($uuidMi -and $hakemMi)){ $atlanan++; continue }
  $hakemParti++
  $partiYargi = 0
  foreach($s in $satirlar){
    if("$s".Trim().Length -eq 0){ continue }
    try { $j = $s | ConvertFrom-Json } catch { continue }
    if("$($j.result.type)" -ne 'succeeded'){ continue }
    $cid = "$($j.custom_id)"
    $metin = "$($j.result.message.content[0].text)"
    $jm = [regex]::Match($metin, '\{[\s\S]*\}')
    if(-not $jm.Success){ continue }
    try { $y = $jm.Value | ConvertFrom-Json } catch { continue }
    if(-not $y.PSObject.Properties['destek']){ continue }
    # son yazan kazanir (sirali eski->yeni gidiyor)
    $yargi[$cid] = [ordered]@{
      destek="$($y.destek)"; tek_dogru="$($y.tek_dogru)"; celiski="$($y.celiski)"
      dogru_sik="$($y.dogru_sik)"; gerekce="$($y.gerekce)"
      parti="$($b.id)"; parti_zamani="$($b.olusturuldu)"
    }
    $partiYargi++
  }
  Write-Host ("  HAKEM {0}  {1} yargi  ({2})" -f $b.id.Substring(0,24), $partiYargi, $b.olusturuldu)
}

Write-Host ""
Write-Host ("hakem partisi: {0}   atlanan (hakem degil): {1}   cekilemeyen: {2}" -f $hakemParti, $atlanan, $cekilemeyen)
Write-Host ("TEKIL YARGI: {0} soru" -f $yargi.Count)

# ozet + kirmizi liste
$say = [ordered]@{ destek_evet=0; destek_yetersiz=0; destek_hayir=0; celiski_evet=0; tek_dogru_sorunlu=0 }
$kirmizi = New-Object System.Collections.Generic.List[object]
foreach($k in $yargi.Keys){
  $y = $yargi[$k]
  switch -Regex ("$($y.destek)") {
    '^evet'      { $say.destek_evet++ }
    '^yetersiz'  { $say.destek_yetersiz++ }
    '^hayir|^hayır' { $say.destek_hayir++ }
  }
  if("$($y.celiski)" -match '^evet'){ $say.celiski_evet++ }
  if("$($y.tek_dogru)" -notmatch '^evet'){ $say.tek_dogru_sorunlu++ }
  if("$($y.destek)" -match '^hayir|^hayır' -or "$($y.celiski)" -match '^evet'){
    $kirmizi.Add([ordered]@{ id=$k; destek="$($y.destek)"; celiski="$($y.celiski)"; gerekce="$($y.gerekce)" })
  }
}
foreach($p in $say.Keys){ Write-Host ("  {0,-18} {1}" -f $p, $say[$p]) }
Write-Host ("  KIRMIZI (destek=hayir veya celiski=evet): {0}" -f $kirmizi.Count)

$cikti = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama = "Odenmis hakem denetiminin partilerden toplanmis yargilari. Ayni soru birden cok partideyse EN SON yargi alindi. Kasa DEGISTIRILMEDI - GM okur, yayin karari onundur."
  hakem_partisi = $hakemParti
  tekil_yargi = $yargi.Count
  ozet = $say
  kirmizi = $kirmizi
  yargilar = $yargi
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/hakem-hasadi.json'), ($cikti | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host ("-> veri/hakem-hasadi.json  ({0} yargi, {1} kirmizi)" -f $yargi.Count, $kirmizi.Count)
try{Stop-Transcript|Out-Null}catch{}
