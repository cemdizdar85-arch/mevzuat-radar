# ============================================================================
#  YENI-10: SGS FINANSAL MUHASEBE TABLOLU (01.09.2026, Cem: "TONU ONAYLIYORUM,
#  10 tane sinava giris icin yap - finansal muhasebe TABLOLU, YENI soru")
#
#  ILKELER (pazarliksiz):
#   - Konu secimi KOPRUDEN (en cok cikan; uydurma yok) - liste asagida donem'li.
#   - KAYNAK OKUNMADAN SORU YAZILMAZ: her konunun dayanak metni AMBARDAN cekilir
#     ve isteme gomulur. Kaynagi bulunamayan konu URETILMEZ, rapora duser.
#   - Tam kalip: kural 19-25 + cozum tablosu ZORUNLU + sema + GENC-DILI adimlar
#     (adim istemi son10-uret.ps1'den CANLI okunur - tek kaynak).
#   - Gorunum: son10-uret'in css/js sablonu CANLI okunur (kopya degil).
#   - ARITMETIK OZ-DOGRULAYICI: formullerdeki 'a/b=c' ve 'a*b=c' esitlikleri
#     hesaplanir; tutmayanlar rapora yazilir (Cem okumasina isaretli gider).
#   - KASAYA YAZILMAZ - onizleme sql-yerel/yeni10-sgs-fmuh.html.
#  Cache: veri/fabrika/yeni10-fmuh.json (kesinti guvenli).
# ============================================================================
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
. (Join-Path $here 'api-hedef.ps1')
$CACHE=Join-Path $kok 'veri\fabrika\yeni10-fmuh.json'
$HEDEF=Join-Path $kok 'sql-yerel\yeni10-sgs-fmuh.html'
$KEY=$env:SUPABASE_SERVICE_KEY
if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok - ambar okunamaz, kaynaksiz soru yazilmaz.' }
$SB=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' }

function Coz([string]$txt){
  $tt="$txt".Trim() -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
  $c=$null; try{ $c=$tt|ConvertFrom-Json }catch{ $son=$tt.LastIndexOf('}'); if($son -gt 0){ try{ $c=$tt.Substring(0,$son+1)|ConvertFrom-Json }catch{} } }
  return $c
}
function K([string]$t){ return "$t".Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;') }
function AmbarCek([string[]]$desenler,[int]$tavan=9000){
  $topla=New-Object System.Collections.Generic.List[string]
  $adlar=New-Object System.Collections.Generic.List[string]
  foreach($d in $desenler){
    $u='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike.'+[uri]::EscapeDataString($d)+'&limit=6'
    try{ $r=Invoke-RestMethod -Uri $u -Headers $SB -TimeoutSec 60 }catch{ continue }
    foreach($x in @($r)){
      if($adlar -notcontains $x.kaynak_ad){
        $adlar.Add($x.kaynak_ad)
        $topla.Add("[$($x.kaynak_ad)] $($x.metin)")
      }
    }
  }
  $m=($topla -join "`n---`n")
  if($m.Length -gt $tavan){ $m=$m.Substring(0,$tavan) }
  return @{ metin=$m; adlar=@($adlar) }
}

# --- KONULAR (kopruden; donem = kac donemde cikti) ---------------------------
$KONULAR=@(
  @{ id='y10-01'; konu='net isletme sermayesi';        donem=8; desen=@('%net i%letme sermayesi%','%isletme sermayesi%') }
  @{ id='y10-02'; konu='sermaye artirimi';             donem=7; desen=@('TTK (6102 s.K.) m.456%','TTK (6102 s.K.) m.457%','TTK (6102 s.K.) m.459%','TTK (6102 s.K.) m.460%') }
  @{ id='y10-03'; konu='nakit akis tablosu';           donem=7; desen=@('TMS 7 p.6%','TMS 7 p.10%','TMS 7 p.13%','TMS 7 p.14%','TMS 7 p.16%','TMS 7 p.17%','TMS 7 p.20%','TMS 7 p.21%') }
  @{ id='y10-04'; konu='hisse senedi ihrac primi';     donem=7; desen=@('%520%HISSE SENED% IHRA%','%520 H%SSE%','%hisse senedi ihra% prim%','TTK (6102 s.K.) m.347%') }
  @{ id='y10-05'; konu='kar dagitimi kaydi';           donem=5; desen=@('TTK (6102 s.K.) m.519%','TTK (6102 s.K.) m.523%') }
  @{ id='y10-06'; konu='tms 2 stoklar (maliyet ve NGD)'; donem=5; desen=@('TMS 2 p.6%','TMS 2 p.9%','TMS 2 p.10%','TMS 2 p.25%','TMS 2 p.28%','TMS 2 p.30%') }
  @{ id='y10-07'; konu='tms 12 ertelenmis vergi';      donem=5; desen=@('TMS 12 p.5%','TMS 12 p.15%','TMS 12 p.24%','TMS 12 p.47%') }
  @{ id='y10-08'; konu='duran varlik satisi';          donem=4; desen=@('VUK (213 s.K.) m.328%','VUK (213 s.K.) m.329%') }
  @{ id='y10-09'; konu='azalan bakiyeler amortismani'; donem=4; desen=@('VUK (213 s.K.) muk. m.315%','VUK (213 s.K.) m.315%','VUK (213 s.K.) m.313%') }
  @{ id='y10-10'; konu='kasa sayim farki';             donem=4; desen=@('%197%SAYIM%','%397%SAYIM%','%SAYIM VE TESEL%') }
)

# --- cache ---
$don=[ordered]@{}
if(Test-Path $CACHE){ foreach($p in (Get-Content $CACHE -Raw -Encoding UTF8|ConvertFrom-Json).PSObject.Properties){ $don[$p.Name]=$p.Value } }
"cache: $($don.Count) hazir"

# --- son10-uret'ten CANLI cekilenler: genc-dili adim istemi + css + js sablon ---
$son10=Get-Content (Join-Path $here 'son10-uret.ps1') -Raw -Encoding UTF8
$adimIstem=[regex]::Match($son10,"(?s)\`$adimIstem=@'(.*?)'@").Groups[1].Value
if($adimIstem.Length -lt 500){ throw 'adimIstem son10-uret icinden cekilemedi' }
$css=[regex]::Match($son10,"(?s)\`$css=@'(.*?)'@").Groups[1].Value
if($css.Length -lt 500){ throw 'css cekilemedi' }
# TabloHtml/SemaHtml fonksiyonlarini canli yukle
Invoke-Expression ([regex]::Match($son10,'(?s)function TabloHtml.*?\n\}\r?\n').Value)
Invoke-Expression ([regex]::Match($son10,'(?s)function SemaHtml.*?\n\}\r?\n(?=\r?\n)').Value)
$jsSablon=[regex]::Match($son10,'(?s)<script>\r?\nconst ADIMMAP=.*?</script>').Value
if($jsSablon.Length -lt 500){ throw 'js sablonu cekilemedi' }

# --- FAZ A: soru uretimi (kaynakli) -----------------------------------------
$soruIstem=@'
Sen "Nobetci" adli hoca-yazarsin. SGS (SMMM Staja Giris) FINANSAL MUHASEBE dersinden, verilen KONUda, SIFIRDAN bir HESAPLI/TABLOLU sinav sorusu uret. Universite mezunu gence, gercek sinav ayarinda.
KURALLAR (kural 19-25 kilitli seti):
1. YALNIZ asagidaki KAYNAK METNINE dayan. Kaynakta olmayan oran/tutar/kural UYDURMA. Parasal buyuklukler senaryo geregi serbest (or. 120.000 TL) ama MUHASEBE KURALI kaynaktan.
2. Soru metni verili sayilarla net; 5 sik (A-E), TEK dogru. Sik degerleri tuzaklardan turetilir (her yanlis sik BIR tuzagin sonucudur).
3. Aciklama takimi: her sik icin "Ne soruluyor / Kural (kural-koyucunun derdiyle acilir, kunye SONDA parantezde, tum sette en fazla 2 kunye) / [Tuzak Adi] Tuzagi: hesapli izahi / Dogrusu: kunyesiz saf dil". Dogru sikta Hesap: zinciri.
4. COZUM TABLOSU ZORUNLU: {"basliklar":[...],"satirlar":[[...]]} - kalem kolonu ilk kolon, SON SATIR SONUC. Yevmiye gerekiyorsa sema tur=yevmiye.
5. sinav_taktigi (1 cumle pratik), notlandirici (adaylarin en cok kaybettigi nokta), hap (tek cumle kalici kural).
6. SEMA: soruya uygun TEK tur (yevmiye kaydi soran soruda yevmiye ZORUNLU; akis/eleme/karar da olabilir) - SORUNUN KENDI SAYILARIYLA.
7. Rakamlar TUTARLI olsun: sik degerleri, tablo, aciklama hesaplari BIREBIR ayni.
Cevap YALNIZ JSON:
{"soru":"...","siklar":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"dogru":"X","aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"hap":"...","sinav_taktigi":"...","notlandirici":"...","sema":{...},"cozum_tablo":{...},"dayanak":"kisa kunye"}
=== KONU === {KONU}   (SGS'de {DONEM} ayri donemde soruldu - onemli konu)
=== KAYNAK METNI (ambardan) === {KAYNAK}
'@

$rapor=New-Object System.Collections.Generic.List[string]
foreach($kk in $KONULAR){
  $id=$kk.id
  if($don.Contains($id) -and $don[$id].soru){ continue }
  $amb=AmbarCek $kk.desen
  if(-not $amb.metin -or $amb.metin.Length -lt 300){
    $rapor.Add("URETILMEDI (kaynak bulunamadi): $($kk.konu) - denenen: $($kk.desen -join ' | ')")
    Write-Host "  KAYNAK YOK: $($kk.konu)" -ForegroundColor Yellow
    continue
  }
  Write-Host "  kaynak OK ($($amb.adlar.Count) kayit): $($kk.konu) <- $((@($amb.adlar) | Select-Object -First 3) -join '; ')"
  $ist=$soruIstem.Replace('{KONU}',$kk.konu).Replace('{DONEM}',"$($kk.donem)").Replace('{KAYNAK}',$amb.metin)
  $y=$null
  foreach($d in 1..3){ try{ $y=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $ist -MaxTok 20000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (10*$d) } }
  $cvp=Coz $y.metin
  if($cvp -and $cvp.soru -and $cvp.cozum_tablo){
    $cvp | Add-Member -NotePropertyName konu -NotePropertyValue $kk.konu -Force
    $cvp | Add-Member -NotePropertyName donem -NotePropertyValue $kk.donem -Force
    $cvp | Add-Member -NotePropertyName kaynak_adlar -NotePropertyValue @($amb.adlar) -Force
    $don[$id]=$cvp
    $dN=[ordered]@{}; foreach($x in ($don.Keys|Sort-Object)){ $dN[$x]=$don[$x] }
    [IO.File]::WriteAllText($CACHE,(ConvertTo-Json -InputObject $dN -Depth 10),[Text.UTF8Encoding]::new($false))
    Write-Host "  SORU OK [$($don.Count)/10] $id $($kk.konu)"
  } else { $rapor.Add("BOZUK CIKTI: $($kk.konu)"); Write-Host "  BOZUK: $id" -ForegroundColor Yellow }
}

# --- FAZ B: genc-dili adim senaryolari (son10'un istemiyle) ------------------
foreach($id in @($don.Keys)){
  $cvp=$don[$id]
  if($cvp.PSObject.Properties['adimlar'] -and $cvp.adimlar -and $cvp.PSObject.Properties['verilen']){ continue }
  if(-not $cvp.cozum_tablo){ continue }
  $ist2=$adimIstem.Replace('{SORUM}',"$($cvp.soru)").Replace('{TABLO}',(ConvertTo-Json -InputObject $cvp.cozum_tablo -Depth 5 -Compress)).Replace('{ACIK}',"$($cvp.aciklama.$($cvp.dogru))")
  $y2=$null
  foreach($d in 1..3){ try{ $y2=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $ist2 -MaxTok 12000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (10*$d) } }
  $a2=Coz $y2.metin
  if($a2 -and $a2.adimlar){
    $cvp | Add-Member -NotePropertyName adimlar -NotePropertyValue $a2.adimlar -Force
    $cvp | Add-Member -NotePropertyName verilen -NotePropertyValue @($a2.verilen) -Force
    $dN=[ordered]@{}; foreach($x in ($don.Keys|Sort-Object)){ $dN[$x]=$don[$x] }
    [IO.File]::WriteAllText($CACHE,(ConvertTo-Json -InputObject $dN -Depth 10),[Text.UTF8Encoding]::new($false))
    Write-Host "  ADIM OK $id ($(@($a2.adimlar).Count) adim)"
  } else { $rapor.Add("ADIM BOZUK: $id") }
}

# --- ARITMETIK OZ-DOGRULAYICI ------------------------------------------------
# Formullerdeki "a / b = c" ve "a x b = c" esitliklerini hesapla; tutmayani isaretle.
function SayiCoz([string]$s){ $t=$s -replace '\.','' -replace ',','.'; $v=0.0; if([double]::TryParse($t,[Globalization.NumberStyles]::Any,[Globalization.CultureInfo]::InvariantCulture,[ref]$v)){ return $v }; return $null }
$aritUyari=New-Object System.Collections.Generic.List[string]
foreach($id in @($don.Keys)){
  $cvp=$don[$id]
  foreach($a in @($cvp.adimlar)){
    foreach($m in [regex]::Matches("$($a.formul)",'([\d\.,]+)\s*(?:\([^)]*\))?\s*([x*/+\-])\s*([\d\.,]+)\s*(?:\([^)]*\))?\s*=\s*([\d\.,]+)')){
      $a1=SayiCoz $m.Groups[1].Value; $b1=SayiCoz $m.Groups[3].Value; $c1=SayiCoz $m.Groups[4].Value
      if($null -eq $a1 -or $null -eq $b1 -or $null -eq $c1){ continue }
      $hes=switch($m.Groups[2].Value){ '/'{ if($b1 -ne 0){$a1/$b1}else{$null} } 'x'{$a1*$b1} '*'{$a1*$b1} '+'{$a1+$b1} '-'{$a1-$b1} }
      if($null -ne $hes -and [Math]::Abs($hes-$c1) -gt [Math]::Max(0.51,[Math]::Abs($c1)*0.001)){
        $aritUyari.Add("$id : '$($m.Value)' -> hesap $hes")
      }
    }
  }
}
"aritmetik uyari: $($aritUyari.Count)"
$aritUyari | ForEach-Object { Write-Host "  ARITMETIK: $_" -ForegroundColor Yellow }

# --- SAYFA -------------------------------------------------------------------
$sb=[Text.StringBuilder]::new()
[void]$sb.Append("<!doctype html><html lang=""tr""><head><meta charset=""utf-8""><title>YENİ 10 — SGS Finansal Muhasebe (tablolu)</title><style>$css</style></head><body>")
[void]$sb.Append("<h1>YENİ 10 — SGS Finansal Muhasebe, tablolu — SIFIRDAN üretim, GENÇ DİLİ onaylı ton</h1><p style='color:#aaa;font-size:13.5px'>01.09.2026 · konular köprüden (en çok çıkan) · kaynaklar ambardan okundu · KASAYA YAZILMADI.</p>")
if($rapor.Count){ [void]$sb.Append("<p style='color:#e0a458;font-size:12.5px'>Üretilemeyenler: $(K ($rapor -join ' · '))</p>") }
if($aritUyari.Count){ [void]$sb.Append("<p style='color:#ff8080;font-size:12.5px'>⚠ Aritmetik uyarı ($($aritUyari.Count)): $(K (($aritUyari|Select-Object -First 5) -join ' · '))</p>") }
$adet=0
$amap=[ordered]@{}; $vmap=[ordered]@{}
foreach($id in ($don.Keys|Sort-Object)){
  $cvp=$don[$id]
  if(-not $cvp.soru){ continue }
  $adet++
  $adVar=($cvp.PSObject.Properties['adimlar'] -and $cvp.adimlar)
  [void]$sb.Append("<div class='soru' data-sid='$id'><span class='tip'>YENİ</span><span class='konu'>#$adet · Finansal Muhasebe · $(K $cvp.konu) · $($cvp.donem) dönemde çıktı · kaynak: $(K ((@($cvp.kaynak_adlar)|Select-Object -First 2) -join '; '))</span>")
  [void]$sb.Append("<p><b>$(K $cvp.soru)</b></p>")
  foreach($hh in 'A','B','C','D','E'){
    $cls='sik'; if("$($cvp.dogru)" -eq $hh){ $cls='sik dogru' }
    [void]$sb.Append("<div class='$cls'>$hh) $(K $cvp.siklar.$hh)</div>")
  }
  [void]$sb.Append("<div class='ac'>")
  foreach($hh in 'A','B','C','D','E'){
    $isr=''; if("$($cvp.dogru)" -eq $hh){ $isr=' ✓' }
    [void]$sb.Append("<p><b>$hh$isr)</b> $(K $cvp.aciklama.$hh)</p>")
  }
  if($adVar){ [void]$sb.Append("<div><button class='padim'>🎬 Bu çözümü adım adım yaşa</button><div class='panlat'><div class='psayac'></div><div class='pformul'></div><div class='pmetin' style='margin-top:6px;font-size:.93em'></div><button class='padim pileri' style='margin-top:8px;padding:6px 12px;font-size:.85em'>İleri →</button></div></div>") }
  $verList=$null; if($cvp.PSObject.Properties['verilen']){ $verList=$cvp.verilen }
  [void]$sb.Append((TabloHtml $cvp.cozum_tablo $verList))
  [void]$sb.Append((SemaHtml $cvp.sema))
  if($cvp.sinav_taktigi){ [void]$sb.Append("<div class='kutu'>🎯 <b>Sınav taktiği:</b> $(K $cvp.sinav_taktigi)</div>") }
  if($cvp.notlandirici){ [void]$sb.Append("<div class='kutu2'>⚖️ <b>Notlandırıcı gözü:</b> $(K $cvp.notlandirici)</div>") }
  if($cvp.hap){ [void]$sb.Append("<div class='kutu2'><b>HAP:</b> $(K $cvp.hap)</div>") }
  [void]$sb.Append("</div></div>")
  if($adVar){ $amap[$id]=@($cvp.adimlar) }
  if($cvp.PSObject.Properties['verilen'] -and $cvp.verilen -and $cvp.cozum_tablo){
    $vb=[Text.StringBuilder]::new()
    [void]$vb.Append("<div style='font-weight:800;font-size:.8em;margin-bottom:4px'>📋 SORUNUN VERDİKLERİ</div><table class='vtab'><tr><th>Kalem</th><th>Alan</th><th>Değer</th></tr>")
    $ok=$true
    foreach($vv in @($cvp.verilen)){
      $r=@($vv)[0]; $c=@($vv)[1]
      $sat=@(@($cvp.cozum_tablo.satirlar)[$r])
      if($null -eq $sat -or $c -ge @($sat).Count){ $ok=$false; break }
      [void]$vb.Append("<tr><td>$(K $sat[0])</td><td>$(K @($cvp.cozum_tablo.basliklar)[$c])</td><td>$(K $sat[$c])</td></tr>")
    }
    [void]$vb.Append('</table>')
    if($ok){ $vmap[$id]=$vb.ToString() }
  }
}
$amapJson='{}'; if($amap.Count){ $amapJson=ConvertTo-Json -InputObject $amap -Depth 7 -Compress }
$vmapJson='{}'; if($vmap.Count){ $vmapJson=ConvertTo-Json -InputObject $vmap -Depth 3 -Compress }
$js=$jsSablon -replace 'const ADIMMAP=\$amapJson;',"const ADIMMAP=$amapJson;" -replace 'const VTMAP=\$vmapJson;',"const VTMAP=$vmapJson;"
[void]$sb.Append($js)
[void]$sb.Append("</body></html>")
[IO.File]::WriteAllText($HEDEF,$sb.ToString(),[Text.UTF8Encoding]::new($false))
"yazildi: yeni10-sgs-fmuh.html ($adet soru) | uretilemeyen: $($rapor.Count) | aritmetik uyari: $($aritUyari.Count)"
