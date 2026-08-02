# ============================================================================
#  ACIKLAMA SOZLESMESI OLCUMU (02.08.2026) — 0 USD, API CAGRISI YOK
#
#  CEM'IN SORUSU: "sorulara ya da cevaplara ekleyecegimiz baska sey var miydi?
#  tekrar tekrar yapmayalim diye soruyorum."
#
#  DOGRU SORU. "Dogrusu:" cumlesinin 26.991 soruda eksik oldugunu olctuk ama
#  SINAV-KURALLARI'ndaki diger sozlesme maddelerinin kac soruda eksik oldugunu
#  HIC OLCMEDIK. Olcmeden parali kosu kurmak, iki ay sonra "bunda akilda kalsin
#  yokmus" deyip IKINCI KEZ para vermek demektir.
#
#  NE SAYAR (SINAV-KURALLARI D1/D2/D7 + I2):
#   1. D1 dort parca  : dogru sikta "Ne soruluyor / Kural / Bu olayda / Akilda kalsin"
#   2. D2 tuzak adi   : yanlis siklarda "TUZAK:" ya da "karistiril..." kalibi (>=3 sik)
#   3. D2 Dogrusu     : yanlis siklarda "Dogrusu:" (>=3 sik)
#   4. D7 tablo       : hesapli soruda tablo verisi
#   5. D7 yevmiye     : kayit sorusunda yevmiye verisi
#   6. D7 karsilastirma: "hangisi dogrudur" tipi soruda tablo
#
#  CIKTI: veri/aciklama-sozlesme-olcum.json — hem sayilar hem ILK 200 ornek id
#  (parali motor bu listelerden calisacak; her soruya BIR KEZ dokunulacak).
#  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/aciklama-sozlesme-olcum.json'

trap {
  $g = ""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g = $_.ErrorDetails.Message }
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 4 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber }))
  Write-Host ("HATA (satir {0}): {1} | {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g)
  exit 1
}

if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }

# --- kasayi cek (order SART: order'siz sayfalama satir tekrarlatir/atlatir) ---
$kasa = New-Object System.Collections.Generic.List[object]
for($o = 0; $o -lt 60000; $o += 1000){
  $r = @(Invoke-RestMethod -Uri "$U`?select=id,ders,soru,dogru,aciklama,tablo,yevmiye&order=id&limit=1000&offset=$o" -Headers $SB -TimeoutSec 120 | Where-Object { $null -ne $_ })
  if($r.Count -eq 0){ break }
  foreach($x in $r){ $kasa.Add($x) }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

# --- desenler (Turkce aksan toleransli: gövde ara, ek arama) ---
$reNe      = [regex]'(?i)ne\s+sorul'
$reKural   = [regex]'(?i)(^|\n|\*|\||>)\s*kural\s*:'
$reOlay    = [regex]'(?i)bu\s+olayda'
$reAkil    = [regex]'(?i)ak[ıi]lda\s+kals[ıi]n'
$reTuzak   = [regex]'(?i)tuzak\s*:|kar[ıi][sş]t[ıi]r'
$reDogrusu = [regex]'(?i)do[ğg]rusu\s*:'
$reHesapli = [regex]'(?i)ka[çc]\s*TL|ne\s+kadar|hesapla|tutar[ıi]n[ıi]|maliyet bedeli|amortisman|toplam[ıi]'
$reKayit   = [regex]'(?i)yevmiye|kay[ıi]t|kaydeder|muhasebele[şs]tir|bor[çc]land|alacakland'
$reKarsi   = [regex]'(?i)hangisi\s+do[ğg]rudur|a[şs]a[ğg][ıi]dakilerden\s+hangisi'

function Dolu($v){
  if($null -eq $v){ return $false }
  $s = "$v"
  if($s.Trim().Length -lt 5){ return $false }
  if($s -eq '{}' -or $s -eq '[]' -or $s -eq 'null'){ return $false }
  return $true
}

$say = [ordered]@{ dortparca=0; tuzak=0; dogrusu=0; tablo=0; yevmiye=0; karsilastirma=0 }
$orn = @{}; foreach($k in @($say.Keys)){ $orn[$k] = New-Object System.Collections.Generic.List[string] }
$hesapliToplam = 0; $kayitToplam = 0; $karsiToplam = 0; $aciklamaYok = 0

foreach($s in $kasa){
  $id = "$($s.id)"
  $dogruHarf = "$($s.dogru)".Trim().ToUpper()
  $a = $s.aciklama
  if($null -eq $a){ $aciklamaYok++; continue }

  # dogru sikkin aciklamasi
  $dogruMetin = ""
  try { if($a.PSObject.Properties[$dogruHarf]){ $dogruMetin = "$($a.$dogruHarf)" } } catch {}

  # 1) D1 dort parca — dogru sikta dordu de olacak
  $parca = 0
  if($reNe.IsMatch($dogruMetin)){ $parca++ }
  if($reKural.IsMatch($dogruMetin)){ $parca++ }
  if($reOlay.IsMatch($dogruMetin)){ $parca++ }
  if($reAkil.IsMatch($dogruMetin)){ $parca++ }
  if($parca -lt 4){ $say.dortparca++; if($orn.dortparca.Count -lt 200){ $orn.dortparca.Add($id) } }

  # 2-3) D2 — yanlis siklarda tuzak adi ve "Dogrusu:" (>=3 sik sarti)
  $tuzakVar = 0; $dogrusuVar = 0
  foreach($h in 'A','B','C','D','E'){
    if($h -eq $dogruHarf){ continue }
    $m = ""; try { if($a.PSObject.Properties[$h]){ $m = "$($a.$h)" } } catch {}
    if($m.Length -lt 5){ continue }
    if($reTuzak.IsMatch($m)){ $tuzakVar++ }
    if($reDogrusu.IsMatch($m)){ $dogrusuVar++ }
  }
  if($tuzakVar -lt 3){ $say.tuzak++; if($orn.tuzak.Count -lt 200){ $orn.tuzak.Add($id) } }
  if($dogrusuVar -lt 3){ $say.dogrusu++; if($orn.dogrusu.Count -lt 200){ $orn.dogrusu.Add($id) } }

  # 4-5) D7 gorsel sarti — yalniz ILGILI soru tipinde eksik sayilir
  $govde = "$($s.soru)"
  if($reHesapli.IsMatch($govde)){
    $hesapliToplam++
    if(-not (Dolu $s.tablo)){ $say.tablo++; if($orn.tablo.Count -lt 200){ $orn.tablo.Add($id) } }
  }
  if($reKayit.IsMatch($govde)){
    $kayitToplam++
    if(-not (Dolu $s.yevmiye)){ $say.yevmiye++; if($orn.yevmiye.Count -lt 200){ $orn.yevmiye.Add($id) } }
  }
  # 6) karsilastirma tipi soruda tablo
  if($reKarsi.IsMatch($govde) -and -not $reHesapli.IsMatch($govde)){
    $karsiToplam++
    if(-not (Dolu $s.tablo)){ $say.karsilastirma++; if($orn.karsilastirma.Count -lt 200){ $orn.karsilastirma.Add($id) } }
  }
}

# EN AZ BIR eksigi olan soru sayisi degil, kalem kalem sayim veriyoruz;
# parali motor her soruya BIR KEZ dokunacagi icin asil onemli olan BIRLESIK kume.
$rapor = [ordered]@{
  tarih   = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  durum   = 'TAMAM'
  kasa    = $kasa.Count
  aciklama_alani_bos = $aciklamaYok
  eksik = [ordered]@{
    d1_dort_parca        = $say.dortparca
    d2_tuzak_adlandirma  = $say.tuzak
    d2_dogrusu_cumlesi   = $say.dogrusu
    d7_tablo_hesapli     = $say.tablo
    d7_yevmiye_kayit     = $say.yevmiye
    d7_karsilastirma     = $say.karsilastirma
  }
  ilgili_soru_sayisi = [ordered]@{
    hesapli_soru      = $hesapliToplam
    kayit_sorusu      = $kayitToplam
    karsilastirma_tipi = $karsiToplam
  }
  ornek_idler = [ordered]@{
    d1_dort_parca       = @($orn.dortparca)
    d2_tuzak            = @($orn.tuzak)
    d2_dogrusu          = @($orn.dogrusu)
    d7_tablo            = @($orn.tablo)
    d7_yevmiye          = @($orn.yevmiye)
    d7_karsilastirma    = @($orn.karsilastirma)
  }
  not = 'OLCUM - hicbir API cagrisi yapilmadi, 0 USD. Desenler metin tabanlidir: bir soruda parca BASKA kelimelerle yazilmissa eksik sayilmis olabilir (yanlis alarm). Parali motor kurulmadan once ornek idlerden 10 tanesi gozle dogrulanmalidir.'
}
Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json -InputObject $rapor -Depth 5) -Encoding UTF8 -NoNewline
Write-Host "=== ACIKLAMA SOZLESMESI EKSIKLERI ==="
foreach($k in $rapor.eksik.Keys){ Write-Host ("  {0,-22} {1}" -f $k, $rapor.eksik[$k]) }
Write-Host ("-> {0}" -f $raporYol)
