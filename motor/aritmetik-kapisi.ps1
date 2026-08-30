# ============================================================================
#  ARITMETIK KAPISI — 06.08.2026 (Cem onayi #16)
#
#  NEDEN: uc orneklem denetiminde (06.08) desen yakalandi - model formulu
#  dogru kuruyor, ara islemleri dogru yapiyor, SON carpim/bolme sonucunu
#  isaretli sikka "yuvarlama/en yakin" bahanesiyle uyduruyor. SGS'de 63 hesap
#  kartinin 10'unda isaretli cevap matematiksel yanlisti; SMMM'de 110'da 11.
#
#  NE YAPAR: kasadaki her sorunun aciklama/sik/hap metnindeki "a x b = c"
#  islemlerini YENIDEN HESAPLAR; binde 5'ten fazla sapan bulgu olur. Yaninda
#  kalip avcisi: "en yakin sik/secenek/deger", "yuvarlama farki", "kabul
#  ediyoruz" gecen aciklama cevaba-uydurma suphelisidir. Yevmiye tablolarinda
#  borc=alacak dengesi de olculur.
#
#  Varsayilan OLCUM: rapora yalniz id + alan + sapma yazilir (icerik public
#  repoya SIZMAZ). -yaz ile bulgulu sorular yayin=false cekilir - once olc,
#  yanlis-pozitif oranini gor, sonra yaz (rakam disiplini).
#
#  Ayni denetim uretim aninda da kosuyor: motor/soru-uret-v2.ps1 ARITMETIK
#  KAPISI bolumu bu dosyanin ikizidir - birini degistirirsen ikisini degistir.
# ============================================================================
# 08.08 - SADECE FILTRESI (Cem: "kolay niye soru yapiyoruz" -> el yazimi partiler).
# Rapor 1.522 bulgunun yalnizca 400 ORNEGINI sakliyor ve uretim alani tasimiyor;
# bu yuzden yeni yazilan bir partinin TEMIZ oldugu KANITLANAMIYORDU. Artik
#   -sadece "gm-elle matematik#1"
# denirse yalniz o uretim damgasini tasiyan sorular taranir ve parti tek basina
# sinanabilir. Filtre verilmezse davranis eskisi gibi TUM KASADIR.
param([switch]$yaz, [string]$sadece = '')
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/aritmetik-kapisi-raporu.json'

function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 5), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

# ---------- cekirdek: TR sayi + islem dogrulayici (soru-uret-v2 ile IKIZ) ----------
function TrSayi([string]$s){
  $s = "$s".Trim().TrimStart('%').Trim()
  if($s -eq ''){ return $null }
  $s = ($s -replace '\.','') -replace ',','.'
  $d = 0.0
  if([double]::TryParse($s, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)){ return $d }
  return $null
}
$reIslem = [regex]'(?<ifade>%?\d[\d\.]*(?:,\d+)?(?:\s*[+\-−x×X*/÷]\s*%?\d[\d\.]*(?:,\d+)?)+)\s*(?<esit>[=≈~])\s*(?<sonuc>-?%?\d[\d\.]*(?:,\d+)?)'
$reToken = [regex]'(?<op>[+\-−x×X*/÷])|(?<say>%?\d[\d\.]*(?:,\d+)?)'
# 07.08 (Cem'e soz: net rakam): PARANTEZ DESTEGI - "(a ± b) / c = d" kalibi
# (ortalama/fark-boluk hesabi) once ayri dogrulanir, sonra metinden cikarilir;
# yoksa duz desen paranteze yarim girip yanlis alarm uretiyordu ((4,5+5,6)/2 vakasi).
$reParen = [regex]'\(\s*(?<a>%?\d[\d\.]*(?:,\d+)?)\s*(?<op1>[+\-−])\s*(?<b>%?\d[\d\.]*(?:,\d+)?)\s*\)\s*(?<op2>[x×X*/÷])\s*(?<c>%?\d[\d\.]*(?:,\d+)?)\s*(?<esit>[=≈~])\s*(?<son>-?%?\d[\d\.]*(?:,\d+)?)'
$reKalip = [regex]'(?i)(en yak[ıi]n\s+([şs][ıi]k|se[çc]enek|de[ğg]er)|yuvarlama\s+fark|kabul\s+ediyoruz|oldu[ğg]una\s+g[öo]re\s+kabul|[şs][ıi]klardaki\s+en\s+yak[ıi]n|\(\s*yuvarlanm[ıi][şs]\s*\))'
# 07.08 AKSAM (Cem %17,42 vakasi): ORAN DESENI - "(a / b) x 100 = %p" ve
# parantezsiz "a / b x 100 = %p". Bu kalip UC kor noktadan kaciyordu:
# reParen op1'i yalniz +/- taniyor; satir "ic-parantezleri sil" ifadeyi yok
# ediyor; parantezsiz hali karisik-oncelik diye atlaniyordu. Ayrica yuzde
# sonuclarda binde-5 toleransi 0,02'lik sapmayi yutuyordu - oranda tolerans
# yazilan ondalik hane sayisina gore (yarim birim + pay), cok daha siki.
$reOran = [regex]'\(?\s*(?<a>\d[\d\.]*(?:,\d+)?)\s*[/÷]\s*(?<b>\d[\d\.]*(?:,\d+)?)\s*\)?\s*[x×X*]\s*100\s*[=≈~]\s*%?\s*(?<son>\d[\d\.]*(?:,\d+)?)'
function OranTol([string]$yazilan){
  $hane = 0
  if($yazilan -match ',(\d+)\s*$'){ $hane = $Matches[1].Length }
  return [math]::Max(0.6 * [math]::Pow(10, -$hane), 0.006)
}
# 07.08 AKSAM-2 (Cem 322.490/120=2.695 vakasi): binde-5 GORELI tolerans buyuk
# tutarlarda TL bazinda kocaman sapmayi yutuyordu (2.687,42'ye 13 TL pay!).
# Yeni kural: '=' isareti SIKI hane-duyarli (tam sayida ±1,02 - kirpma payi;
# virgullu yazimda yarim birim + pay); '≈/~' isareti eski gevsek toleransi korur.
function EsitTol([string]$op, [string]$yazilan, [double]$beklenen){
  if($op -ne '='){ return [math]::Max([math]::Abs($beklenen)*0.005, 0.02) }
  $hane = 0
  if($yazilan -match ',(\d+)\s*$'){ $hane = $Matches[1].Length }
  if($hane -eq 0){ return 1.02 }
  return [math]::Max(0.6 * [math]::Pow(10, -$hane), 0.006)
}

# Bir metindeki tum islemleri dogrular; sapma listesi dondurur.
# Kurallar: TR bicim (nokta binlik, virgul ondalik). %'li carpan /100 sayilir
# (hepsi %'liyse duz sayi). Karisik +- soldan saga; * veya / karisiksa atlanir.
function IslemDenetle([string]$metin){
  $bulgu = @()
  $metin = "$metin"
  # 07.08: ORAN KALIBI once - "(a/b) x 100 = %p" dogrula ve metinden cikar
  foreach($om in $reOran.Matches($metin)){
    $devam0 = $metin.Substring($om.Index + $om.Length)
    if($devam0 -match '^\s*[x×X*/÷+\-−]\s*%?\d'){ continue }   # zincir korumasi
    $a=TrSayi $om.Groups['a'].Value; $b=TrSayi $om.Groups['b'].Value; $sn=TrSayi $om.Groups['son'].Value
    if($null -eq $a -or $null -eq $b -or $null -eq $sn -or $b -eq 0){ continue }
    $bk = ($a / $b) * 100.0
    $farkO = [math]::Abs($bk - $sn)
    if($farkO -gt (OranTol $om.Groups['son'].Value)){
      $bulgu += [pscustomobject]@{ ifade=($om.Value -replace '\s+',' '); beklenen=[math]::Round($bk,4); yazan=$sn; sapmaYuzde=[math]::Round(100*$farkO/[math]::Max([math]::Abs($bk),0.0001),2); tur='oran' }
    }
  }
  $metin = $reOran.Replace($metin, ' ')
  # once parantezli kaliplar: dogrula ve metinden cikar
  foreach($pm in $reParen.Matches($metin)){
    # ZINCIR KORUMASI (07.08): "(a-b) x c = ARA = SONUC" yazivinda ilk '='
    # ara adimdir; sonucun hemen ardindan islem geliyorsa bu eslesme atlanir
    $devam = $metin.Substring($pm.Index + $pm.Length)
    if($devam -match '^\s*[x×X*/÷+\-−]\s*%?\d'){ continue }
    # 08.08 GERIYE DOGRU ZINCIR KORUMASI: koruma tek yonluydu - eslesmeden
    # SONRA operator gelip gelmedigine bakiyor ama ONCE gelip gelmedigine
    # BAKMIYORDU. Ilk parca atlaninca regex kalan KUYRUGU ayri bir ifade
    # saniyor: "20 x (3+60)/2 = 630" -> bastaki "20 x" dusuyor, (3+60)/2=31,5
    # ile karsilastirilip %1900 sahte sapma uretiliyordu. Ifadenin BASINDA
    # operator/rakam/kapali parantez varsa bu bir zincir parcasidir, atlanir.
    if($pm.Index -gt 0 -and $metin.Substring(0,$pm.Index) -match '(?:[x×X*/÷+\-−]\s*$|[A-Za-z\^]\s*$)'){ continue }
    $a=TrSayi $pm.Groups['a'].Value; $b=TrSayi $pm.Groups['b'].Value; $c=TrSayi $pm.Groups['c'].Value; $sn=TrSayi $pm.Groups['son'].Value
    if($null -eq $a -or $null -eq $b -or $null -eq $c -or $null -eq $sn -or $c -eq 0){ continue }
    $ic = if($pm.Groups['op1'].Value -eq '+'){ $a + $b } else { $a - $b }
    $bk = if($pm.Groups['op2'].Value -match '[x×X*]'){ $ic * $c } else { $ic / $c }
    if($pm.Groups['son'].Value -like '%*' -and [math]::Abs($bk) -lt 1.5){ $bk = $bk * 100.0 }
    $fark2 = [math]::Abs($bk - $sn)
    if($fark2 -gt (EsitTol $pm.Groups['esit'].Value $pm.Groups['son'].Value $bk)){
      $bulgu += [pscustomobject]@{ ifade=($pm.Value -replace '\s+',' '); beklenen=[math]::Round($bk,4); yazan=$sn; sapmaYuzde=[math]::Round(100*$fark2/[math]::Max([math]::Abs($bk),0.0001),2) }
    }
  }
  $metin = $reParen.Replace($metin, ' ')
  # kalan parantezli karma ifadeler duz desene YARIM girmesin: ic-parantezleri sil
  $metin = $metin -replace '\([^()]*\)', ' '
  foreach($m in $reIslem.Matches("$metin")){
    $devam2 = $metin.Substring($m.Index + $m.Length)
    if($devam2 -match '^\s*[x×X*/÷+\-−]\s*%?\d'){ continue }   # zincir korumasi (ileri)
    # 08.08 GERIYE DOGRU ZINCIR KORUMASI - bkz. yukaridaki ayrintili not.
    # Ornekler: "40 + 10 + 10 = 60" icinden "10 + 10 = 60" kopuyordu (%200);
    # "-1/2 = -0,5" icinden "1/2 = -0,5" kopuyordu (%200). Ifadenin hemen
    # oncesinde operator varsa eslesme bir ZINCIR PARCASIDIR, dogrulanmaz.
    if($m.Index -gt 0 -and $metin.Substring(0,$m.Index) -match '(?:[x×X*/÷+\-−]\s*$|[A-Za-z\^]\s*$)'){ continue }
    $ifade = $m.Groups['ifade'].Value
    $sonS  = $m.Groups['sonuc'].Value
    $sayilar = New-Object System.Collections.Generic.List[object]
    $opler   = New-Object System.Collections.Generic.List[string]
    foreach($t in $reToken.Matches($ifade)){
      if($t.Groups['say'].Success){ $sayilar.Add($t.Groups['say'].Value) }
      elseif($t.Groups['op'].Success){ $opler.Add($t.Groups['op'].Value) }
    }
    if($sayilar.Count -lt 2 -or $opler.Count -ne $sayilar.Count-1){ continue }
    $n = @($opler | ForEach-Object { $_ -replace '[x×X*]','*' -replace '[÷]','/' -replace '[−]','-' })
    $carpma = @($n | Where-Object { $_ -in @('*','/') })
    if($carpma.Count -and (@($n | Select-Object -Unique).Count -gt 1)){ continue }   # karisik oncelik: atla
    $yuzdeler = @($sayilar | Where-Object { $_ -like '%*' })
    $hepsiYuzde = ($yuzdeler.Count -eq $sayilar.Count)
    $deger = @()
    foreach($s in $sayilar){
      $v = TrSayi $s
      if($null -eq $v){ $deger = @(); break }
      if((-not $hepsiYuzde) -and $s -like '%*' -and $carpma.Count){ $v = $v / 100.0 }
      $deger += $v
    }
    if($deger.Count -lt 2){ continue }
    $b = $deger[0]
    for($i2=0; $i2 -lt $n.Count; $i2++){
      switch($n[$i2]){
        '+' { $b += $deger[$i2+1] }
        '-' { $b -= $deger[$i2+1] }
        '*' { $b *= $deger[$i2+1] }
        '/' { if($deger[$i2+1] -eq 0){ $b=[double]::NaN } else { $b /= $deger[$i2+1] } }
      }
    }
    if([double]::IsNaN($b)){ continue }
    $sv = TrSayi $sonS
    if($null -eq $sv){ continue }
    # sonuc %'li, islenenler degilse: oran yuzdesi olabilir (0,2855 -> %28,55)
    if($sonS -like '%*' -and -not $hepsiYuzde -and [math]::Abs($b) -lt 1.5){ $b = $b * 100.0 }
    $fark = [math]::Abs($b - $sv)
    $tol  = EsitTol $m.Groups['esit'].Value $sonS $b
    if($fark -gt $tol){
      $bulgu += [pscustomobject]@{ ifade=($m.Value -replace '\s+',' '); beklenen=[math]::Round($b,4); yazan=$sv; sapmaYuzde=[math]::Round(100*$fark/[math]::Max([math]::Abs($b),0.0001),2) }
    }
  }
  # DIKKAT: 'return ,$bulgu' YAZMA - virgul sarmalayici bos listeyi @(cmd)
  # baglaminda 1 saydiriyor (07.08 test bataryasi dersi). Duz donus dogru:
  # bos -> 0 oge, n bulgu -> n oge.
  return $bulgu
}
# ---------- /cekirdek ----------

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok - cikildi.'; exit 0 }
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$H = @{ apikey=$KEY }
if($KEY -like 'eyJ*'){ $H.Authorization = "Bearer $KEY" }

$taranan=0; $islemli=0
$bulgular = New-Object System.Collections.Generic.List[object]
$kalipli  = New-Object System.Collections.Generic.List[object]
$dengesiz = New-Object System.Collections.Generic.List[object]
$bas=0
while($true){
  # PS5.1/7 farki: 5.1'de IRM buyuk diziyi TEK nesne olarak dondurur - boru
  # her iki surumde de tek tek acar (06.08 yerel kosu dersi, "taranan: 1" vakasi)
  $suz = ''
  if($sadece -ne ''){ $suz = '&uretim=like.' + [uri]::EscapeDataString($sadece + '*') }
  $r = @(Invoke-RestMethod -Uri "$U`?select=id,sinav,ders,konu,soru,siklar,dogru,aciklama,hap,yevmiye,yayin&order=id&limit=500&offset=$bas$suz" -Headers $H -TimeoutSec 300 | ForEach-Object { $_ })
  if($r.Count -eq 0){ break }
  foreach($s in $r){
    if($null -eq $s){ continue }
    $taranan++
    $alanlar = [ordered]@{ soru="$($s.soru)"; hap="$($s.hap)" }
    foreach($hf in 'A','B','C','D','E'){
      try { $alanlar["sik$hf"] = "$($s.siklar.$hf)" } catch {}
      try { if($s.aciklama -and $s.aciklama.PSObject.Properties[$hf]){ $alanlar["aciklama$hf"] = "$($s.aciklama.$hf)" } } catch {}
    }
    $soruBulgu=@(); $soruKalip=@(); $islemVar=$false
    foreach($ad in @($alanlar.Keys)){
      $t = $alanlar[$ad]
      $bl = IslemDenetle $t
      if($reIslem.IsMatch($t)){ $islemVar=$true }
      foreach($b in $bl){ $soruBulgu += [pscustomobject]@{ alan=$ad; ifade=$b.ifade; beklenen=$b.beklenen; yazan=$b.yazan; sapmaYuzde=$b.sapmaYuzde } }
      $km = $reKalip.Match($t)
      if($km.Success){ $soruKalip += [pscustomobject]@{ alan=$ad; kalip=$km.Value } }
    }
    if($islemVar){ $islemli++ }
    # yevmiye dengesi
    if($s.yevmiye){
      $tb=0.0; $ta=0.0
      foreach($sat in @($s.yevmiye)){
        $vb = TrSayi "$($sat.borc)"; $va = TrSayi "$($sat.alacak)"
        if($null -ne $vb){ $tb += $vb }; if($null -ne $va){ $ta += $va }
      }
      if(($tb -gt 0 -or $ta -gt 0) -and [math]::Abs($tb-$ta) -gt [math]::Max(($tb+$ta)*0.0025,0.02)){
        $dengesiz.Add([pscustomobject]@{ id=$s.id; sinav=$s.sinav; borc=[math]::Round($tb,2); alacak=[math]::Round($ta,2) })
      }
    }
    if($soruBulgu.Count){ $bulgular.Add([pscustomobject]@{ id=$s.id; sinav=$s.sinav; ders=$s.ders; konu=$s.konu; yayin=[bool]$s.yayin; sapmalar=$soruBulgu }) }
    if($soruKalip.Count){ $kalipli.Add([pscustomobject]@{ id=$s.id; sinav=$s.sinav; ders=$s.ders; konu=$s.konu; yayin=[bool]$s.yayin; kaliplar=$soruKalip }) }
  }
  if($r.Count -lt 500){ break }
  $bas += 500
  Write-Host ("  ... {0} tarandi" -f $taranan)
}
Write-Host ("Taranan: {0} | islemli: {1} | aritmetik bulgulu: {2} | kalipli: {3} | dengesiz yevmiye: {4}" -f $taranan,$islemli,$bulgular.Count,$kalipli.Count,$dengesiz.Count)

$cekilen=0
if($yaz){
  $HW = $H + @{ Prefer='return=minimal'; 'Content-Type'='application/json' }
  # 07.08 Cem: "bunlari onar" - dengesiz yevmiyeler de kapsamda; not KUSUR TURUNU
  # tasir ki onarimci (ic-tutarlilik-onar) dogru receteyi uygulasin.
  $notlar = @{}
  foreach($x in $bulgular){ $notlar["$($x.id)"] = 'islem-sapmasi' }
  foreach($x in $kalipli){ $k="$($x.id)"; if($notlar.ContainsKey($k)){ $notlar[$k] += '+uyduru-kalip' } else { $notlar[$k]='uyduru-kalip' } }
  foreach($x in $dengesiz){ $k="$($x.id)"; if($notlar.ContainsKey($k)){ $notlar[$k] += '+dengesiz-yevmiye' } else { $notlar[$k]='dengesiz-yevmiye' } }
  foreach($id in $notlar.Keys){
    $gov = ConvertTo-Json -InputObject @{ yayin=$false; yayin_notu=('aritmetik kapisi 07.08: ' + $notlar[$id] + ' - onarim + hakem bekliyor') } -Compress
    try { Invoke-RestMethod -Method Patch -Uri ("$U`?id=eq." + $id) -Headers $HW -Body ([Text.Encoding]::UTF8.GetBytes($gov)) -TimeoutSec 60 | Out-Null; $cekilen++ } catch {}
  }
  Write-Host ("Cekilen: {0}" -f $cekilen)
}

RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$(if($yaz){'YAZILDI'}else{'OLCUM'})
  taranan=$taranan; islemliSoru=$islemli
  aritmetikBulgulu=$bulgular.Count; kalipli=$kalipli.Count; dengesizYevmiye=$dengesiz.Count; cekilen=$cekilen
  # 13.08: rapor 400'de kirpiliyordu -> kara liste kesisimi 1.302 bulgunun
#  yalniz 400'unu goruyordu (yayin havuzu eksik suzuluyordu). Ornek listesi
#  kirpili kalir ama TAM ID LISTESI ayrica yazilir.
  bulgular=@($bulgular | Select-Object -First 400)
  bulgu_idler=@($bulgular | ForEach-Object { $_.id } | Sort-Object -Unique)
  kaliplilar=@($kalipli | Select-Object -First 200)
  dengesizler=@($dengesiz | Select-Object -First 100)
})
Write-Host 'Bitti.'
