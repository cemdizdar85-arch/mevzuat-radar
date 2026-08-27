# ============================================================================
#  CILA PARTISI - 1 EYLUL ANA KOSUSU (26.08.2026'da hazirlandi, Cem onayi)
#
#  NE: Aday havuz + K5-kirmizilarin ACIKLAMA katmanini Sonnet 5 + Anthropic
#      BATCH API ile v3 formatina cevirir (4 parca + tuzak paleti + Dogrusu +
#      sinav taktigi + dayanak + notlandirici + cozum tablosu/akis).
#  ISTEM TEK KAYNAK: motor/pilot-cila.ps1 icindeki $istemSablon buradan OKUNUR
#  (kopya tutulmaz - pilotta kanitlanan istem neyse parti onu kosar).
#
#  DORT ADIM (ayri ayri cagrilir, her adim kanit birakir):
#    -hazirla [-sinir N] : kapsami cikar, istekleri veri/fabrika/cila-istek-*.jsonl'e yaz
#    -gonder             : jsonl'leri 1.000'lik batch'ler halinde Anthropic'e yollar,
#                          batch id'leri veri/fabrika/cila-batch-idler.json'a kaydeder
#    -durum              : batch'lerin islenme durumunu sorar
#    -indir              : biten batch sonuclarini veri/fabrika/cila-sonuc-*.jsonl'e ceker
#    -uygula             : sonuclari KASAYA yazar (once sql-cila-v3-kolonlar.sql basilmis
#                          olmali) - her yazim GERI OKUMALI; JSON bozuk cikti kasaya GIRMEZ
#
#  GUVENLIK: -uygula soru/sik/dogru alanlarina ASLA dokunmaz; yalniz aciklama, hap,
#  sinav_taktigi, dayanak, notlandirici, cozum_tablo, akis, cila alanlarini yazar.
#  supheli_cevap=true cikan sorular kasaya YAZILMAZ, veri/fabrika/cila-supheli.json'a
#  duser (cevap-duzeyi inceleme kuyrugu).
#
#  ⚠ 26.08 NOTU: Batch gonderimi API tavani nedeniyle HENUZ CANLI TEST EDILMEDI
#  (KADEME 1 Eylul'de aciliyor). -hazirla adimi ve JSONL oz-sinavi bugun test
#  edildi; -gonder/-indir 1 Eylul sabahi once -sinir 5 ile provalanir.
# ============================================================================
param([switch]$hazirla, [switch]$gonder, [switch]$durum, [switch]$indir, [switch]$uygula,
      [switch]$tamamla,   # 26.08: max_tokens'a takilan/bozuk donenleri 16k tavanla yeniden gonderir
      [int]$sinir = 0, [string]$model = 'claude-sonnet-5')
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent']='mevzuat-radar-robot/1.0'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$SBKEY=$env:SUPABASE_SERVICE_KEY
$SBH=@{apikey=$SBKEY; Authorization="Bearer $SBKEY"}
$SBU='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
$FAB=Join-Path $kok 'veri\fabrika'
$ANT='https://api.anthropic.com/v1/messages/batches'
function AntBas(){
  $k=$env:ANTHROPIC_API_KEY; if(-not $k){ $k=[Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY','User') }
  if(-not $k){ throw 'ANTHROPIC_API_KEY yok' }
  return @{ 'x-api-key'=$k; 'anthropic-version'='2023-06-01'; 'content-type'='application/json' }
}

# --- istem sablonunu pilottan oku (tek kaynak) ---
function IstemSablonOku(){
  $t=Get-Content (Join-Path $here 'pilot-cila.ps1') -Raw -Encoding UTF8
  $m=[regex]::Match($t,"(?s)\`$istemSablon=@'(.*?)'@")
  if(-not $m.Success){ throw 'pilot-cila.ps1 icinde istem sablonu bulunamadi' }
  return $m.Groups[1].Value.Trim()
}
function DayanakMetni($s){
  try{
    if($s.kanun_no -and $s.madde_no){
      $q=[uri]::EscapeDataString("*$($s.kanun_no)*$($s.madde_no)*")
      $r=@(Invoke-RestMethod -Uri "$SBU/dokumanlar?select=metin&kaynak_ad=ilike.$q&limit=1" -Headers $SBH -TimeoutSec 30 | % { $_ })
      if($r.Count -ge 1){ return $r[0].metin }
    }
    if($s.kaynak){
      $ilk=("$($s.kaynak)" -split '[;,]')[0].Trim()
      if($ilk.Length -ge 4){
        $q=[uri]::EscapeDataString('*'+$ilk+'*')
        $r=@(Invoke-RestMethod -Uri "$SBU/dokumanlar?select=metin&kaynak_ad=ilike.$q&limit=1" -Headers $SBH -TimeoutSec 30 | % { $_ })
        if($r.Count -ge 1){ return $r[0].metin }
      }
    }
  }catch{}
  return ''
}
function IstemKur($sablon,$s,$dayanak){
  $sik=@(); foreach($k in 'A','B','C','D','E'){ if($s.siklar.PSObject.Properties[$k] -and $s.siklar.$k){ $sik+="$k) $($s.siklar.$k)" } }
  $eski=@(); foreach($k in 'A','B','C','D','E'){ if($s.aciklama -and $s.aciklama.PSObject.Properties[$k]){ $eski+="$k) $($s.aciklama.$k)" } }
  $kay=if([string]::IsNullOrWhiteSpace($dayanak)){'(kaynak metni bulunamadi - kural 4 ikinci cumle gecerli)'}else{$dayanak.Substring(0,[Math]::Min(3000,$dayanak.Length))}
  $t=$sablon
  $t=$t.Replace('{DERS}',"$($s.ders)").Replace('{KONU}',"$($s.konu)").Replace('{SORU}',"$($s.soru)")
  $t=$t.Replace('{SIKLAR}',($sik -join "`n")).Replace('{DOGRU}',"$($s.dogru)")
  $t=$t.Replace('{ESKI}',($eski -join "`n")).Replace('{KAYNAK}',$kay)
  return $t
}

# ============================ -hazirla ============================
if($hazirla){
  $sablon=IstemSablonOku
  # KAPSAM = aday havuz (yayin-havuzu-olcum idler'i). K5-kirmizilar D kalemi
  # olarak AYRI partide (dogrusu-ekle); burada cila kapsami aday havuzdur.
  $aday=(Get-Content (Join-Path $kok 'veri\yayin-havuzu-olcum.json') -Raw -Encoding UTF8 | ConvertFrom-Json).idler
  # pilotta cilalanan 75 gecerli soru yeniden uretilmez
  $pilotYol=Join-Path $FAB 'pilot-cila-20260826.json'
  $atla=@{}
  if(Test-Path $pilotYol){
    (Get-Content $pilotYol -Raw -Encoding UTF8 | ConvertFrom-Json).sonuclar |
      ? { $_.model -eq 'claude-sonnet-5' -and $_.jsonGecerli } | % { $atla[$_.id]=$true }
  }
  $hedef=@($aday | ? { -not $atla.ContainsKey($_) })
  if($sinir -gt 0){ $hedef=$hedef[0..([Math]::Min($sinir,$hedef.Count)-1)] }
  "kapsam: $($aday.Count) aday - $($atla.Count) pilotta bitti -> hedef $($hedef.Count)"
  $parcaNo=1; $yazilan=0; $sw=$null
  function YeniDosya([int]$no){ $y=Join-Path $FAB ("cila-istek-{0:d3}.jsonl" -f $no); if(Test-Path $y){ Remove-Item $y }; return [IO.StreamWriter]::new($y,$false,[Text.UTF8Encoding]::new($false)) }
  $sw=YeniDosya $parcaNo
  for($i=0;$i -lt $hedef.Count;$i+=100){
    $grup=$hedef[$i..([Math]::Min($i+99,$hedef.Count-1))]
    $filtre='id=in.(' + (($grup | % { '"'+$_+'"' }) -join ',') + ')'
    $sorular=@(Invoke-RestMethod -Uri "$SBU/soru_havuzu?select=id,ders,konu,soru,siklar,dogru,aciklama,kaynak,kanun_no,madde_no&$filtre" -Headers $SBH -TimeoutSec 180 | % { $_ })
    foreach($s in $sorular){
      $istek=[ordered]@{
        custom_id="$($s.id)"
        params=[ordered]@{
          model=$model; max_tokens=8000   # 26.08 prova dersi: 5000'de 4/10 dusunme payina takildi
          messages=@(@{ role='user'; content=(IstemKur $sablon $s (DayanakMetni $s)) })
        }
      }
      $sw.WriteLine(($istek | ConvertTo-Json -Depth 8 -Compress))
      $yazilan++
      if($yazilan % 1000 -eq 0){ $sw.Close(); $parcaNo++; $sw=YeniDosya $parcaNo }
    }
    if($i % 1000 -eq 0){ Write-Host "  ...$yazilan/$($hedef.Count)" }
  }
  $sw.Close()
  # OZ-SINAV: ilk dosyanin ilk 2 satiri gecerli JSON mu + zorunlu alanlar var mi
  $ilk=Get-Content (Join-Path $FAB 'cila-istek-001.jsonl') -TotalCount 2 -Encoding UTF8
  foreach($sat in $ilk){
    $j=$sat | ConvertFrom-Json
    if(-not $j.custom_id -or -not $j.params.model -or -not $j.params.messages[0].content){ throw 'OZ-SINAV KIRMIZI: istek yapisi bozuk' }
    if($j.params.messages[0].content -notmatch 'notlandirici'){ throw 'OZ-SINAV KIRMIZI: istem v3 alanlari yok (eski sablon?)' }
  }
  "OZ-SINAV GECTI - $yazilan istek, $parcaNo dosya (cila-istek-*.jsonl)"
}

# ============================ -tamamla ============================
# Sonuc dosyalarindaki GECERLI id'leri sayar; istek dosyalarindaki hedeflerden
# eksik kalanlari 16k tavanla yeni bir batch olarak gonderir. Kural: sessiz kayip yok.
if($tamamla){
  $gecerli=@{}
  foreach($f in (Get-ChildItem (Join-Path $FAB 'cila-sonuc-*.jsonl') -ErrorAction SilentlyContinue)){
    foreach($sat in (Get-Content $f.FullName -Encoding UTF8)){
      $r=$sat | ConvertFrom-Json
      if($r.result.type -ne 'succeeded'){ continue }
      $txt=(@($r.result.message.content) | ? { $_.type -eq 'text' } | Select-Object -Last 1).text
      if(-not $txt){ continue }
      $tt=$txt.Trim() -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
      try{ $p=$tt | ConvertFrom-Json; if($p -and $p.aciklama){ $gecerli[$r.custom_id]=$true } }catch{}
    }
  }
  $hedefler=@{}
  foreach($f in (Get-ChildItem (Join-Path $FAB 'cila-istek-*.jsonl'))){
    foreach($sat in (Get-Content $f.FullName -Encoding UTF8)){ $j=$sat | ConvertFrom-Json; $hedefler[$j.custom_id]=$true }
  }
  $eksik=@($hedefler.Keys | ? { -not $gecerli.ContainsKey($_) })
  "hedef $($hedefler.Count) / gecerli $($gecerli.Count) / EKSIK $($eksik.Count)"
  if($eksik.Count -eq 0){ 'tamamlanacak yok.'; }
  else{
    $sablon=IstemSablonOku
    $istekler=@()
    for($i=0;$i -lt $eksik.Count;$i+=50){
      $grup=$eksik[$i..([Math]::Min($i+49,$eksik.Count-1))]
      $filtre='id=in.(' + (($grup | % { '"'+$_+'"' }) -join ',') + ')'
      $sorular=@(Invoke-RestMethod -Uri "$SBU/soru_havuzu?select=id,ders,konu,soru,siklar,dogru,aciklama,kaynak,kanun_no,madde_no&$filtre" -Headers $SBH -TimeoutSec 180 | % { $_ })
      foreach($s in $sorular){
        $istekler += [ordered]@{ custom_id="$($s.id)"; params=[ordered]@{ model=$model; max_tokens=16000; messages=@(@{ role='user'; content=(IstemKur $sablon $s (DayanakMetni $s)) }) } }
      }
    }
    $H=AntBas
    $govde=@{ requests=$istekler } | ConvertTo-Json -Depth 10 -Compress
    $r=Invoke-RestMethod -Method Post -Uri $ANT -Headers $H -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 300
    "tamamlama batch: $($r.id) ($($istekler.Count) istek, tavan 16k)"
    $mevcut=@(); $iy=Join-Path $FAB 'cila-batch-idler.json'
    if(Test-Path $iy){ $mevcut=@(Get-Content $iy -Raw -Encoding UTF8 | ConvertFrom-Json) }
    $mevcut += [pscustomobject]@{ dosya='(tamamlama)'; batch=$r.id; adet=$istekler.Count; tarih=(Get-Date -Format 's') }
    $mevcut | ConvertTo-Json -Depth 3 | Out-File $iy -Encoding utf8
  }
}

# ============================ -gonder ============================
if($gonder){
  $H=AntBas
  $idler=@()
  foreach($f in (Get-ChildItem (Join-Path $FAB 'cila-istek-*.jsonl') | Sort-Object Name)){
    $istekler=@(Get-Content $f.FullName -Encoding UTF8 | % { $_ | ConvertFrom-Json })
    $govde=@{ requests=$istekler } | ConvertTo-Json -Depth 10 -Compress
    $r=Invoke-RestMethod -Method Post -Uri $ANT -Headers $H -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 300
    "gonderildi: $($f.Name) -> batch $($r.id) ($($istekler.Count) istek)"
    $idler+=[pscustomobject]@{ dosya=$f.Name; batch=$r.id; adet=$istekler.Count; tarih=(Get-Date -Format 's') }
    Start-Sleep -Seconds 2
  }
  $idler | ConvertTo-Json -Depth 3 | Out-File (Join-Path $FAB 'cila-batch-idler.json') -Encoding utf8
  "-> cila-batch-idler.json ($($idler.Count) batch)"
}

# ============================ -durum ============================
if($durum){
  $H=AntBas
  foreach($b in (Get-Content (Join-Path $FAB 'cila-batch-idler.json') -Raw -Encoding UTF8 | ConvertFrom-Json)){
    $r=Invoke-RestMethod -Uri "$ANT/$($b.batch)" -Headers $H -TimeoutSec 60
    "{0}  {1}  islenen {2}/{3}  hata {4}" -f $b.batch, $r.processing_status, $r.request_counts.succeeded, $b.adet, $r.request_counts.errored
  }
}

# ============================ -indir ============================
if($indir){
  $H=AntBas
  foreach($b in (Get-Content (Join-Path $FAB 'cila-batch-idler.json') -Raw -Encoding UTF8 | ConvertFrom-Json)){
    $r=Invoke-RestMethod -Uri "$ANT/$($b.batch)" -Headers $H -TimeoutSec 60
    if($r.processing_status -ne 'ended'){ "atla (bitmedi): $($b.batch) [$($r.processing_status)]"; continue }
    $hedefY=Join-Path $FAB ("cila-sonuc-{0}.jsonl" -f $b.batch)
    Invoke-WebRequest -Uri $r.results_url -Headers $H -OutFile $hedefY -TimeoutSec 600
    "indirildi: $($b.batch) -> $(Split-Path $hedefY -Leaf) ($([math]::Round((Get-Item $hedefY).Length/1KB)) KB)"
  }
}

# ============================ -uygula ============================
if($uygula){
  # kolonlar var mi? (sql-cila-v3-kolonlar.sql basilmadan kosma)
  try{ Invoke-RestMethod -Uri "$SBU/soru_havuzu?select=cila&limit=1" -Headers $SBH -TimeoutSec 30 | Out-Null }
  catch{ throw 'KOLONLAR YOK - once veri/sql-cila-v3-kolonlar.sql Supabase''de basilmali.' }
  $damga='cila-v3 ' + (Get-Date -Format 'dd.MM.yyyy')
  $yaz=0; $bozuk=0; $supheli=New-Object System.Collections.Generic.List[object]
  $govdeIhbar=New-Object System.Collections.Generic.List[object]   # 26.08: gormediklerimiz agi
  foreach($f in (Get-ChildItem (Join-Path $FAB 'cila-sonuc-*.jsonl'))){
    foreach($sat in (Get-Content $f.FullName -Encoding UTF8)){
      $r=$sat | ConvertFrom-Json
      if($r.result.type -ne 'succeeded'){ $bozuk++; continue }
      $ham=($r.result.message.content | ? { $_.type -eq 'text' } | Select-Object -First 1).text
      $ham=$ham.Trim() -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
      $c=$null; try{ $c=$ham | ConvertFrom-Json }catch{}
      if(-not $c -or -not $c.aciklama){ $bozuk++; continue }
      if($c.govde_kusuru -and "$($c.govde_kusuru)".Trim() -ne ''){ $govdeIhbar.Add(@{ id=$r.custom_id; not="$($c.govde_kusuru)" }) }
      if($c.supheli_cevap){ $supheli.Add(@{ id=$r.custom_id; not=$c.supheli_not }); continue }
      $g=[ordered]@{ aciklama=$c.aciklama; hap=$c.hap; cila=$damga }
      if($c.sinav_taktigi){ $g.sinav_taktigi=$c.sinav_taktigi }
      if($c.dayanak){ $g.dayanak=$c.dayanak }
      if($c.notlandirici){ $g.notlandirici=$c.notlandirici }
      if($c.cozum_tablo -and $c.cozum_tablo.satirlar -and $c.cozum_tablo.satirlar.Count){ $g.cozum_tablo=$c.cozum_tablo }
      if($c.akis -and $c.akis.Count){ $g.akis=$c.akis }
      $b=$g | ConvertTo-Json -Depth 8
      Invoke-RestMethod -Method Patch -Uri "$SBU/soru_havuzu?id=eq.$($r.custom_id)" -Headers ($SBH+@{Prefer='return=minimal'}) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($b)) -TimeoutSec 60 | Out-Null
      # geri okuma (hap uzunlugu esiyle hizli teyit)
      $t=@(Invoke-RestMethod -Uri "$SBU/soru_havuzu?select=hap,cila&id=eq.$($r.custom_id)" -Headers $SBH -TimeoutSec 60 | % { $_ })
      if($t.Count -eq 1 -and $t[0].cila -eq $damga -and "$($t[0].hap)" -eq "$($c.hap)"){ $yaz++ } else { $bozuk++; Write-Host "  !!! geri okuma farki: $($r.custom_id)" }
      if(($yaz+$bozuk) % 500 -eq 0){ Write-Host "  ...yazilan $yaz / sorunlu $bozuk" }
    }
  }
  if($supheli.Count){ $supheli | ConvertTo-Json -Depth 3 | Out-File (Join-Path $FAB 'cila-supheli.json') -Encoding utf8 }
  if($govdeIhbar.Count){ $govdeIhbar | ConvertTo-Json -Depth 3 | Out-File (Join-Path $FAB 'cila-govde-ihbar.json') -Encoding utf8; "  govde ihbari: $($govdeIhbar.Count) -> cila-govde-ihbar.json (kasaya yazilmadi, GM okuyacak)" }
  ''
  '======== UYGULAMA SONU ========'
  "  kasaya yazilan (geri okumali) : $yaz"
  "  bozuk/atlanan                 : $bozuk"
  "  supheli_cevap (yazilMADI)     : $($supheli.Count) -> cila-supheli.json"
  '  SIRADA: yayin-kapisi + aritmetik-kapisi + yayin-havuzu-olcum yeniden kosulmali.'
}
