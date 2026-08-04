# ============================================================================
#  TASLAK DENETIMI (04.08.2026) — 0 USD, API YOK, KASAYA YAZMAZ
#
#  NEDEN: Cem taslakta #45'te "sadece 2 adet yanlis cevap geldi" dedi (bes
#  sikli soruda dogru cevap D iken A/B/C/E gerekirken yalniz A ve B vardi).
#  Sonra: "sadece bu soru degil de digerlerini kontrol et."
#
#  TEK ORNEKTEN KARAR VERILMEZ. Bu betik PARTININ TAMAMINI (200 soru) tarar
#  ve OLCER. Motorun kendi sayaclari uretim aninda tutulur; bu ise BAGIMSIZ
#  bir SONRADAN denetimdir - taslagin gercekte ne icerdigine bakar.
#
#  NE OLCULUR (her soru icin, istenmis alanlar bazinda):
#   - dogrusu: yanlis siklarin HEPSINDE var mi? (dogru sikka yazilmaz)
#   - tuzak  : ayni sekilde
#   - dort_parca: istenmisse geldi mi, dort baslik tam mi
#   - tablo/yevmiye: istenmisse geldi mi
#   - gecersiz JSON (model uretemedi) kac tane
#
#  RAPOR SAYI VE HARF TASIR - SORU METNI TASIMAZ (03.08 sizinti dersi).
#
#  ENV: SUPABASE_SERVICE_KEY · Parametre: -dosya pilot-0408-1437.json
#  Cikti: veri/taslak-denetim-raporu.json
# ============================================================================
param([string]$dosya = '')
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/taslak-denetim-raporu.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 6
  if($j.Length -gt 40960){ $j = ConvertTo-Json -Depth 2 -InputObject @{ durum='KIRMIZI - rapor sismis'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 0 }
$KOVA = 'onarim-taslak'
$STOR = "https://bjrleanjpyujtajmazxn.supabase.co/storage/v1"
$U    = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SK   = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function Metin([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SK -UseBasicParsing -TimeoutSec 180
  if($h.RawContentStream){ return [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) }
  return "$($h.Content)"
}

# --- en yeni pilot dosyasi ---
if($dosya -eq ''){
  $lg = ConvertTo-Json -Compress -InputObject @{ prefix=''; limit=100; sortBy=@{ column='name'; order='desc' } }
  $r = Invoke-RestMethod -Uri "$STOR/object/list/$KOVA" -Method Post -Headers ($SK + @{ 'Content-Type'='application/json' }) -Body ([Text.Encoding]::UTF8.GetBytes($lg)) -TimeoutSec 60
  $aday = @($r | Where-Object { "$($_.name)" -like 'pilot-*.json' } | Sort-Object name -Descending)
  if($aday.Count -eq 0){ RaporYaz @{ durum='KIRMIZI'; sebep='pilot dosyasi yok' }; exit 1 }
  $dosya = "$($aday[0].name)"
}
Write-Host ("Denetlenen taslak: {0}" -f $dosya)
$taslak = @((Metin "$STOR/object/$KOVA/$dosya") | ConvertFrom-Json)
Write-Host ("Taslak satiri: {0}" -f $taslak.Count)

# --- asillari kasadan cek (dogru sik + hangi siklar dolu) ---
$idler = @($taslak | ForEach-Object { "$($_.soru_id)" } | Where-Object { $_ } | Select-Object -Unique)
$asil = @{}
for($b=0; $b -lt $idler.Count; $b+=50){
  $dilim = $idler[$b..([Math]::Min($b+49, $idler.Count-1))]
  $liste = ($dilim | ForEach-Object { '"' + $_ + '"' }) -join ','
  foreach($s in @((Metin "$U`?select=id,siklar,dogru&id=in.($liste)") | ConvertFrom-Json)){ if($null -ne $s){ $asil["$($s.id)"] = $s } }
}
Write-Host ("Kasadan eslesen: {0}" -f $asil.Count)

$gecersizJson = 0
$dogrusuIstenen = 0; $dogrusuTam = 0; $dogrusuEksikSoru = 0; $dogrusuEksikHarf = 0
$tuzakIstenen = 0;   $tuzakTam = 0;   $tuzakEksikSoru = 0;   $tuzakEksikHarf = 0
$dortIstenen = 0; $dortGelen = 0; $dortBaslikEksik = 0
$tabloIstenen = 0; $tabloGelen = 0
$yevmiyeIstenen = 0; $yevmiyeGelen = 0
$ornek = New-Object System.Collections.Generic.List[object]

$reNe=[regex]'(?i)ne\s+sorul'; $reKural=[regex]'(?i)(^|\n|\*|\||>)\s*kural\s*:'
$reOlay=[regex]'(?i)bu\s+olayda'; $reAkil=[regex]'(?i)ak[ıi]lda\s+kals[ıi]n'

foreach($t in $taslak){
  $sid = "$($t.soru_id)"
  if(-not $t.gecerli_json){ $gecersizJson++; continue }
  if(-not $asil.ContainsKey($sid)){ continue }
  $s = $asil[$sid]
  $dg = "$($s.dogru)".Trim().ToUpper()
  $yanlis = @()
  foreach($h in 'A','B','C','D','E'){
    if($s.siklar -and $s.siklar.PSObject.Properties[$h] -and "$($s.siklar.$h)".Trim() -ne '' -and $h -ne $dg){ $yanlis += $h }
  }
  $c = $t.cikti
  $eksikListe = @($t.eksik)

  foreach($par in @(@{ad='dogrusu';bayrak='D2_dogrusu'}, @{ad='tuzak';bayrak='D2_tuzak'})){
    if(-not ($eksikListe -contains $par.bayrak)){ continue }
    $v = $null; try { if($c.PSObject.Properties[$par.ad]){ $v = $c.$($par.ad) } } catch {}
    $eks = @()
    foreach($h in $yanlis){
      $m = ''; try { if($null -ne $v -and $v.PSObject.Properties[$h]){ $m = "$($v.$h)" } } catch {}
      if($m.Trim().Length -lt 15){ $eks += $h }
    }
    if($par.ad -eq 'dogrusu'){
      $dogrusuIstenen++
      if($eks.Count -eq 0){ $dogrusuTam++ } else { $dogrusuEksikSoru++; $dogrusuEksikHarf += $eks.Count }
    } else {
      $tuzakIstenen++
      if($eks.Count -eq 0){ $tuzakTam++ } else { $tuzakEksikSoru++; $tuzakEksikHarf += $eks.Count }
    }
    if($eks.Count -gt 0 -and $ornek.Count -lt 25){
      $ornek.Add([ordered]@{ soru_id=$sid; alan=$par.ad; dogru_sik=$dg; beklenen=($yanlis -join ''); eksik=($eks -join '') })
    }
  }

  if($eksikListe -contains 'D1_dort_parca'){
    $dortIstenen++
    $d = ''; try { if($c.PSObject.Properties['dort_parca']){ $d = "$($c.dort_parca)" } } catch {}
    if($d.Trim().Length -gt 30){
      $dortGelen++
      $p = 0
      if($reNe.IsMatch($d)){$p++}; if($reKural.IsMatch($d)){$p++}; if($reOlay.IsMatch($d)){$p++}; if($reAkil.IsMatch($d)){$p++}
      if($p -lt 4){ $dortBaslikEksik++ }
    }
  }
  if(($eksikListe -contains 'D7_tablo') -or ($eksikListe -contains 'D8_karsilastirma')){
    $tabloIstenen++
    try { if($c.PSObject.Properties['tablo'] -and $null -ne $c.tablo -and @($c.tablo.satirlar).Count -gt 0){ $tabloGelen++ } } catch {}
  }
  if($eksikListe -contains 'D7_yevmiye'){
    $yevmiyeIstenen++
    try { if($c.PSObject.Properties['yevmiye'] -and @($c.yevmiye).Count -gt 0){ $yevmiyeGelen++ } } catch {}
  }
}

function Yuzde($a,$b){ if($b -le 0){ return 0 }; return [Math]::Round(100.0*$a/$b,1) }
$rapor = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'; mod='DENETIM (0 USD, yazma yok)'
  taslak_dosyasi=$dosya; taslak_satiri=$taslak.Count; kasadan_eslesen=$asil.Count
  gecersiz_json=$gecersizJson

  dogrusu_istenen=$dogrusuIstenen
  dogrusu_TAM=$dogrusuTam
  dogrusu_EKSIK_soru=$dogrusuEksikSoru
  dogrusu_eksik_harf_toplam=$dogrusuEksikHarf
  dogrusu_tamlik_yuzde=(Yuzde $dogrusuTam $dogrusuIstenen)

  tuzak_istenen=$tuzakIstenen
  tuzak_TAM=$tuzakTam
  tuzak_EKSIK_soru=$tuzakEksikSoru
  tuzak_eksik_harf_toplam=$tuzakEksikHarf
  tuzak_tamlik_yuzde=(Yuzde $tuzakTam $tuzakIstenen)

  dort_parca_istenen=$dortIstenen; dort_parca_gelen=$dortGelen; dort_parca_baslik_eksik=$dortBaslikEksik
  tablo_istenen=$tabloIstenen; tablo_gelen=$tabloGelen
  yevmiye_istenen=$yevmiyeIstenen; yevmiye_gelen=$yevmiyeGelen

  ornekler=$ornek.ToArray()
  not='Yalniz OLCUM - taslaga ve kasaya dokunulmadi. Rapor SAYI ve HARF tasir, soru metni TASIMAZ. "eksik" sutunu: o alanda metni olmayan (ya da 15 karakterden kisa) yanlis sik harfleri.'
}
RaporYaz $rapor
Write-Host "`n=== TASLAK DENETIMI ==="
Write-Host ("  Gecersiz JSON            : {0}" -f $gecersizJson)
Write-Host ("  DOGRUSU istenen/tam/eksik: {0} / {1} / {2}  (tamlik %{3})" -f $dogrusuIstenen,$dogrusuTam,$dogrusuEksikSoru,$rapor.dogrusu_tamlik_yuzde)
Write-Host ("  TUZAK   istenen/tam/eksik: {0} / {1} / {2}  (tamlik %{3})" -f $tuzakIstenen,$tuzakTam,$tuzakEksikSoru,$rapor.tuzak_tamlik_yuzde)
Write-Host ("  DORT PARCA istenen/gelen : {0} / {1}  (baslik eksik {2})" -f $dortIstenen,$dortGelen,$dortBaslikEksik)
Write-Host ("  TABLO   istenen/gelen    : {0} / {1}" -f $tabloIstenen,$tabloGelen)
Write-Host ("  YEVMIYE istenen/gelen    : {0} / {1}" -f $yevmiyeIstenen,$yevmiyeGelen)
