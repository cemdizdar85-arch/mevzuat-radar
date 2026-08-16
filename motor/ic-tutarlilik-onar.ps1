# ============================================================================
#  IC-TUTARLILIK ONARIMCISI — 06.08.2026 (Cem onayi: "tamam kos 5 usd sorun degil")
#
#  Hedef: ic-tutarlilik denetiminin isaretledigi ~610 soru (yayin_notu
#  'ic-tutarlilik%'). Kusur turune gore reçete:
#   S1 ayni sik        -> kusurlu sikka YENI celdirici + tuzakli aciklama
#   S2 cevap sizintisi -> soru koku cevabi ele vermeyecek sekilde yeniden
#   S3 gecersiz dogru  -> aciklamalara gore dogru harf duzeltilir
#   S4 bos/eksik sik   -> eksik harflere celdirici yazilir
#   S5 aciklamasiz     -> dort parcali aciklama yazilir
#
#  GUVENLI YOL (03.08 dersi): cikti KASAYA YAZILMAZ - ozel 'onarim-taslak'
#  kovasina duser (ic-tutarlilik-onar/<etiket>/). Cem'in sarti: her onarilan
#  soru once hakem + GM okumasindan gececek, ancak ondan sonra kasaya uygulanir.
#
#  Model: Haiku 4.5 (onarim-motoru ile ayni). Maliyet olcumu API usage'dan;
#  EMNIYET KEMERI: 12 USD asilirsa parti kendini durdurur (tahmin ~5 USD).
#  Cikti kapilari deterministik: 5 dolu sik, S1/S2 tekrari yok, tuzak>=3,
#  Dogrusu>=3, dogru aciklama >=300, aritmetik sapma yok.
# ============================================================================
param([int]$sinir = 0)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/ic-tutarlilik-onar-raporu.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 5), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok - cikildi.'; exit 0 }
# 16.08 uc hat: Anthropic birincil, limit dolunca OTOMATIK OpenRouter yedegi (api-hedef.ps1)
. (Join-Path $here 'api-hedef.ps1')
if(-not $env:ANTHROPIC_API_KEY -and -not (Read-ApiEnv 'OPENROUTER_KEY')){
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KIRMIZI'; not='Hicbir Claude anahtari yok (ANTHROPIC_API_KEY / OPENROUTER_KEY); cagri yapilmadi, para harcanmadi.' })
  Write-Host 'Hicbir Claude anahtari yok - cikildi.'; exit 1
}

$U    = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$STOR = 'https://bjrleanjpyujtajmazxn.supabase.co/storage/v1'
$KOVA = 'onarim-taslak'
$SB   = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
# (Claude basliklari artik api-hedef.ps1 icinde kuruluyor - hangi hat acikca oraya bakar)
$MODEL = 'claude-haiku-4-5-20251001'
$FIY_IN = 1.0/1000000.0; $FIY_OUT = 5.0/1000000.0
$TAVAN_USD = 25.0   # 07.08: kapsam buyudu (610 + aritmetik ~700) - kemer 12->25; tahmin ~10-12 USD
$etiket = "ictut-$(Get-Date -Format 'ddMM-HHmm')"

# ---------- ARITMETIK CEKIRDEGI (aritmetik-kapisi.ps1 ile IKIZ, kisa surum) ----------
function TrSayi([string]$s){
  $s = "$s".Trim().TrimStart('%').Trim(); if($s -eq ''){ return $null }
  $s = ($s -replace '\.','') -replace ',','.'
  $d = 0.0
  if([double]::TryParse($s,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$d)){ return $d }
  return $null
}
$reIslem = [regex]'(?<ifade>%?\d[\d\.]*(?:,\d+)?(?:\s*[+\-−x×X*/÷]\s*%?\d[\d\.]*(?:,\d+)?)+)\s*[=≈~]\s*(?<sonuc>-?%?\d[\d\.]*(?:,\d+)?)'
$reToken = [regex]'(?<op>[+\-−x×X*/÷])|(?<say>%?\d[\d\.]*(?:,\d+)?)'
$reParen = [regex]'\(\s*(?<a>%?\d[\d\.]*(?:,\d+)?)\s*(?<op1>[+\-−])\s*(?<b>%?\d[\d\.]*(?:,\d+)?)\s*\)\s*(?<op2>[x×X*/÷])\s*(?<c>%?\d[\d\.]*(?:,\d+)?)\s*[=≈~]\s*(?<son>-?%?\d[\d\.]*(?:,\d+)?)'
function IslemSapmasiVar([string]$metin){
  $metin = "$metin"
  foreach($pm in $reParen.Matches($metin)){
    $devam = $metin.Substring($pm.Index + $pm.Length)
    if($devam -match '^\s*[x×X*/÷+\-−]\s*%?\d'){ continue }   # zincir korumasi (07.08)
    $a=TrSayi $pm.Groups['a'].Value; $b=TrSayi $pm.Groups['b'].Value; $c=TrSayi $pm.Groups['c'].Value; $sn=TrSayi $pm.Groups['son'].Value
    if($null -eq $a -or $null -eq $b -or $null -eq $c -or $null -eq $sn -or $c -eq 0){ continue }
    $ic = if($pm.Groups['op1'].Value -eq '+'){ $a + $b } else { $a - $b }
    $bk = if($pm.Groups['op2'].Value -match '[x×X*]'){ $ic * $c } else { $ic / $c }
    if($pm.Groups['son'].Value -like '%*' -and [math]::Abs($bk) -lt 1.5){ $bk = $bk * 100.0 }
    if([math]::Abs($bk - $sn) -gt [math]::Max([math]::Abs($bk)*0.005, 0.02)){ return $true }
  }
  $metin = $reParen.Replace($metin, ' ')
  $metin = $metin -replace '\([^()]*\)', ' '
  foreach($m in $reIslem.Matches("$metin")){
    $devam2 = $metin.Substring($m.Index + $m.Length)
    if($devam2 -match '^\s*[x×X*/÷+\-−]\s*%?\d'){ continue }   # zincir korumasi
    $sayilar=@(); $opler=@()
    foreach($t in $reToken.Matches($m.Groups['ifade'].Value)){
      if($t.Groups['say'].Success){ $sayilar += $t.Groups['say'].Value } elseif($t.Groups['op'].Success){ $opler += $t.Groups['op'].Value }
    }
    if($sayilar.Count -lt 2 -or $opler.Count -ne $sayilar.Count-1){ continue }
    $n = @($opler | ForEach-Object { $_ -replace '[x×X*]','*' -replace '[÷]','/' -replace '[−]','-' })
    $carpma = @($n | Where-Object { $_ -in @('*','/') })
    if($carpma.Count -and (@($n | Select-Object -Unique).Count -gt 1)){ continue }
    $yuzdeler = @($sayilar | Where-Object { $_ -like '%*' })
    $hepsiYuzde = ($yuzdeler.Count -eq $sayilar.Count)
    $deger=@()
    foreach($sx in $sayilar){ $v=TrSayi $sx; if($null -eq $v){ $deger=@(); break }; if((-not $hepsiYuzde) -and $sx -like '%*' -and $carpma.Count){ $v=$v/100.0 }; $deger += $v }
    if($deger.Count -lt 2){ continue }
    $b=$deger[0]
    for($i2=0;$i2 -lt $n.Count;$i2++){ switch($n[$i2]){ '+'{$b+=$deger[$i2+1]} '-'{$b-=$deger[$i2+1]} '*'{$b*=$deger[$i2+1]} '/'{ if($deger[$i2+1] -eq 0){$b=[double]::NaN} else {$b/=$deger[$i2+1]} } } }
    if([double]::IsNaN($b)){ continue }
    $sv = TrSayi $m.Groups['sonuc'].Value; if($null -eq $sv){ continue }
    if($m.Groups['sonuc'].Value -like '%*' -and -not $hepsiYuzde -and [math]::Abs($b) -lt 1.5){ $b = $b*100.0 }
    if([math]::Abs($b-$sv) -gt [math]::Max([math]::Abs($b)*0.005,0.02)){ return $true }
  }
  return $false
}
# ---------- /cekirdek ----------
function SikNorm([string]$t){ $t = "$t".ToLowerInvariant() -replace '\s+',' '; return ($t -replace '[\.\,\;\:\!\?\(\)"]','').Trim() }

# --- hedefleri cek (yayin_notu ic-tutarlilik% olanlar)
$hedef = New-Object System.Collections.Generic.List[object]
$bas=0
while($true){
  # 07.08 Cem "bunlari onar": aritmetik kapisinin isaretledikleri de kapsamda
  $r = @(Invoke-RestMethod -Uri "$U`?select=id,sinav,ders,konu,kaynak,soru,siklar,dogru,aciklama,hap,yayin_notu&or=(yayin_notu.like.ic-tutarlilik*,yayin_notu.like.aritmetik*,yayin_notu.like.*dil-kusuru*)&order=id&limit=500&offset=$bas" -Headers $SB -TimeoutSec 300 | ForEach-Object { $_ })
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($x){ $hedef.Add($x) } }
  if($r.Count -lt 500){ break }
  $bas += 500
}
Write-Host ("Hedef soru: {0}" -f $hedef.Count)
if($hedef.Count -eq 0){ RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='IS YOK'; not='ic-tutarlilik isaretli soru bulunamadi' }); exit 0 }
if($sinir -gt 0){ $hedef = $hedef | Select-Object -First $sinir }

# --- KALDIGI YERDEN DEVAM (07.08 dersi: 5 saatlik timeout iki kosuyu bastan
# baslatti, ilk ~490 soru IKI KEZ onarildi). Kovadaki TUM etiket klasorlerinde
# taslagi olan id'ler hedeften dusulur - tekrar odeme YOK.
$mevcutTaslak = @{}
try {
  $tmpL = [IO.Path]::GetTempFileName()
  [IO.File]::WriteAllText($tmpL, '{"prefix":"ic-tutarlilik-onar","limit":100,"offset":0}')
  $kokler = & curl.exe -s -X POST -H "apikey: $($env:SUPABASE_SERVICE_KEY)" -H "Authorization: Bearer $($env:SUPABASE_SERVICE_KEY)" -H "Content-Type: application/json" --data-binary "@$tmpL" "$STOR/object/list/$KOVA" | ConvertFrom-Json
  foreach($kk in @($kokler)){
    [IO.File]::WriteAllText($tmpL, ('{"prefix":"ic-tutarlilik-onar/' + $kk.name + '","limit":5000,"offset":0}'))
    $dosyalar = & curl.exe -s -X POST -H "apikey: $($env:SUPABASE_SERVICE_KEY)" -H "Authorization: Bearer $($env:SUPABASE_SERVICE_KEY)" -H "Content-Type: application/json" --data-binary "@$tmpL" "$STOR/object/list/$KOVA" | ConvertFrom-Json
    foreach($ds in @($dosyalar)){ $mevcutTaslak[("$($ds.name)" -replace '\.json$','')] = 1 }
  }
  Remove-Item $tmpL -Force -ErrorAction SilentlyContinue
} catch { Write-Host ('taslak listesi okunamadi (devam korumasiz): ' + $_.Exception.Message) }
$onceki = $hedef.Count
$hedef = @($hedef | Where-Object { -not $mevcutTaslak.ContainsKey("$($_.id)") })
Write-Host ("Kaldigi yerden: {0} zaten taslakli atlandi, kalan {1}" -f ($onceki - $hedef.Count), $hedef.Count)
if($hedef.Count -eq 0){ RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'; not='tum hedeflerin taslagi zaten kovada - yeni cagri yok, 0 USD' }); exit 0 }

# IC SURE BEKCISI: is 265 dakikayi asarsa temiz kapan, rapor YAZ (timeout
# iptali rapor adimini olduruyordu - kor kalma yasak).
$basZaman = Get-Date

# --- ucus oncesi: kova OZEL mi + deneme yazmasi (03.08 dersi: para gitmeden dogrula)
try {
  $kh = Invoke-WebRequest -Uri "$STOR/bucket/$KOVA" -Headers $SB -UseBasicParsing -TimeoutSec 60
  $km = if($kh.RawContentStream){ [Text.Encoding]::UTF8.GetString($kh.RawContentStream.ToArray()) } else { "$($kh.Content)" }
  $kv = $km | ConvertFrom-Json
  if($kv.public -eq $true){ throw 'kova PUBLIC - parali icerik acik yere yazilamaz' }
  $dGovde = ConvertTo-Json -Compress -InputObject @{ deneme=$true; etiket=$etiket }
  Invoke-RestMethod -Uri "$STOR/object/$KOVA/_deneme.json" -Method Post -Headers ($SB + @{ 'Content-Type'='application/json'; 'x-upsert'='true' }) -Body ([Text.Encoding]::UTF8.GetBytes($dGovde)) -TimeoutSec 60 | Out-Null
  $dh = Invoke-WebRequest -Uri "$STOR/object/$KOVA/_deneme.json" -Headers $SB -UseBasicParsing -TimeoutSec 60
  $dm = if($dh.RawContentStream){ [Text.Encoding]::UTF8.GetString($dh.RawContentStream.ToArray()) } else { "$($dh.Content)" }
  if(($dm | ConvertFrom-Json).etiket -ne $etiket){ throw 'deneme yazmasi geri okunamadi' }
  Write-Host 'Ucus oncesi: kova OZEL ve yazilabilir.'
} catch {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KIRMIZI'; maliyet_usd=0; sebep="ucus oncesi: $($_.Exception.Message)"; not='Hicbir API cagrisi yapilmadi.' })
  Write-Host ('!! UCUS ONCESI BASARISIZ: ' + $_.Exception.Message); exit 1
}

$tIn=0; $tOut=0; $basarili=0; $kapiRed=0; $islenmeyen=@(); $harcKesildi=$false
for($n=0; $n -lt $hedef.Count; $n++){
  $s = $hedef[$n]
  if(((Get-Date) - $basZaman).TotalMinutes -gt 265){ $harcKesildi=$true; Write-Host ('!! SURE BEKCISI: 265 dk doldu, temiz kapanis (kalan {0} sonraki kosuda).' -f ($hedef.Count - $n)); break }
  $maliyet = $tIn*$FIY_IN + $tOut*$FIY_OUT
  if($maliyet -gt $TAVAN_USD){ $harcKesildi=$true; Write-Host ('!! EMNIYET KEMERI: {0:N2} USD asildi, parti durdu.' -f $maliyet); break }
  $kusur = "$($s.yayin_notu)" -replace '^ic-tutarlilik denetimi [\d\.]+:\s*','' -replace '^aritmetik kapisi [\d\.]+:\s*','ARITMETIK: ' -replace '^dil-kusuru [\d\.]+:\s*','DIL: '
  $soruJson = ConvertTo-Json -Depth 6 -InputObject ([ordered]@{ soru="$($s.soru)"; siklar=$s.siklar; dogru="$($s.dogru)"; aciklama=$s.aciklama; hap="$($s.hap)"; kaynak="$($s.kaynak)" })
  $istem = @"
Sen SMMM/KGK sinav sorusu editorusun. Asagidaki soruda MAKINEYLE OLCULMUS su kusur(lar) var:
KUSUR: $kusur

SORU (JSON):
$soruJson

GOREV: YALNIZ kusurlu kisimlari onar; kusursuz alanlari KELIMESI KELIMESINE aynen koru.
Kurallar:
- S1 (ayni sik): kusurlu harfe mevcut siklardan FARKLI, makul bir celdirici yaz; o harfin aciklamasina tuzagi adlandiran ("tuzak/karistiriliyor/saniliyor" kelimeli) aciklama + "Dogrusu: ..." cumlesi ekle.
- S2 (cevap sizintisi): soru kokunu, dogru sikkin metnini ELE VERMEYECEK sekilde yeniden yaz; anlam ve zorluk ayni kalsin.
- S3 (gecersiz dogru): aciklamalari oku, icerige gore dogru harfi belirle ve 'dogru' alanini duzelt; gerekiyorsa aciklamalari harflerle uyumlu hale getir.
- S4 (bos/eksik sik): bos harflere celdirici yaz + her birine tuzak adlandiran aciklama + "Dogrusu: ...".
- S5 (aciklamasiz dogru): dogru sikka su iskeletle 400-700 karakter aciklama yaz: "Ne soruluyor: ... Kural: ... Bu olayda: ... Akilda kalsin: ...".
- ARITMETIK islem-sapmasi: metindeki HER islemi (a x b = c) yeniden hesapla; sonuc yanlissa dogru sonucu yaz, gerekiyorsa dogru sikki ve celdiricileri hesaba gore duzelt. Islemler kagit-kalemle yapilabilir kalsin.
- ARITMETIK uyduru-kalip: "en yakin secenek/yuvarlama farkiyla/kabul ediyoruz" gibi cevaba-uydurma cumlelerini SIL; hesabi bastan dogru kur, sik degeriyle birebir tutur.
- ARITMETIK dengesiz-yevmiye: yevmiye kaydinda borc toplami = alacak toplami olacak sekilde kaydi duzelt (hesap adlari THP'ye uygun kalsin). Yevmiye alanini degistiremiyorsan aciklamada dogru kaydi ver.
- DIL jargon-yogun: iki+ teknik terimin ust uste yigildigi cumleleri BOL ve her terime gunluk-dil karsiligi ekle ("... yani ...", parantezle); once anlam, terim sonra. Icerik/hesap DEGISMEZ, yalniz dil.
- DIL eski-terim: eski terimi guncel karsiligiyla degistir (genel imal->genel uretim giderleri, iptidai madde->ilk madde ve malzeme, mezkur->soz konusu); kanun metninden BIREBIR alinti cumlesiyse alintiyi koru, yanina parantezle guncelini yaz.
- Rakam uydurma YASAK: kaynakta/mevcut metinde olmayan kanun no, oran, tarih ekleme.
- Hesap iceren metinlerde islemler DOGRU olmali (a x b = c gercekten tutmali).
- Turkce, sinav dili; yapay-zeka klisesi yok ("bu baglamda", "onem arz etmektedir" yasak).
CIKTI: yalniz su alanlarla KAPALI TEK JSON nesnesi dondur, baska hicbir sey yazma:
{"soru":"...","siklar":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"dogru":"X","aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"hap":"..."}
"@
  $obj=$null
  for($deneme=1; $deneme -le 3; $deneme++){
    $tavan = if($deneme -eq 1){ 4000 } else { 8000 }
    $istemBu = if($deneme -eq 1){ $istem } else { $istem + "`n`nUYARI: onceki cevabin gecerli JSON degildi. YALNIZ kapali, gecerli TEK JSON nesnesi dondur." }
    try { $c = Invoke-ClaudeMesaj -Model $MODEL -Icerik $istemBu -MaxTok $tavan }
    catch { if($deneme -eq 3){ $islenmeyen += "$($s.id)|cagri-hatasi" }; continue }
    $tIn += $c.girdi; $tOut += $c.cikti
    $metin = $c.metin
    $temiz = ($metin -replace '(?s)^\s*```(?:json)?\s*','' -replace '(?s)\s*```\s*$','').Trim()
    try { $obj = $temiz | ConvertFrom-Json } catch { $obj = $null }
    if($null -ne $obj){ break }
  }
  if($null -eq $obj){ if($islenmeyen -notcontains "$($s.id)|cagri-hatasi"){ $islenmeyen += "$($s.id)|json-bozuk" }; continue }

  # --- CIKTI KAPILARI (deterministik; kusur tekrar ediyorsa taslak KABUL EDILMEZ)
  $harfler=@('A','B','C','D','E'); $red=@()
  $ySik=@{}; foreach($h2 in $harfler){ $v=''; try { $v="$($obj.siklar.$h2)" } catch {}; $ySik[$h2]=$v }
  $yDogru = "$($obj.dogru)".Trim()
  if(@($harfler | Where-Object { $ySik[$_].Trim().Length -le 2 }).Count){ $red += 'bos-sik' }
  $g2=@{}; foreach($h2 in $harfler){ $n2=SikNorm $ySik[$h2]; if($n2.Length -ge 2){ if($g2.ContainsKey($n2)){ $red += 'ayni-sik' } else { $g2[$n2]=$h2 } } }
  if($yDogru -notin $harfler){ $red += 'gecersiz-dogru' }
  else {
    $dm2 = SikNorm $ySik[$yDogru]
    if($dm2.Length -ge 12 -and (SikNorm "$($obj.soru)").Contains($dm2)){ $red += 'sizinti' }
    $ac2=''; try { if($obj.aciklama.PSObject.Properties[$yDogru]){ $ac2="$($obj.aciklama.$yDogru)" } } catch {}
    if($ac2.Trim().Length -lt 300){ $red += 'dogru-aciklama-kisa' }
    $tuzakli=0; $dogrusulu=0
    foreach($h2 in ($harfler | Where-Object { $_ -ne $yDogru })){
      $a3=''; try { if($obj.aciklama.PSObject.Properties[$h2]){ $a3="$($obj.aciklama.$h2)" } } catch {}
      if($a3 -match '(?i)tuzak|kar[ıi][sş]t[ıi]r|san[ıi]l|zannedil|yan[ıi]lg|atlan|unutul|g[oö]zden ka[cç]'){ $tuzakli++ }
      if($a3 -match '(?i)do[gğ]rusu\s*:'){ $dogrusulu++ }
    }
    if($tuzakli -lt 3){ $red += 'tuzak-eksik' }
    if($dogrusulu -lt 3){ $red += 'dogrusu-eksik' }
  }
  $tumYeni = "$($obj.soru) $($obj.hap)"; foreach($h2 in $harfler){ $tumYeni += " $($ySik[$h2])"; try { $tumYeni += " $($obj.aciklama.$h2)" } catch {} }
  if(IslemSapmasiVar $tumYeni){ $red += 'aritmetik-sapma' }
  if($red.Count){ $kapiRed++; $islenmeyen += ("$($s.id)|kapi:" + (($red | Select-Object -Unique) -join ',')); continue }

  # --- taslagi kovaya yaz (eski + yeni + kusur)
  $taslak = ConvertTo-Json -Depth 8 -InputObject ([ordered]@{ id="$($s.id)"; sinav="$($s.sinav)"; ders="$($s.ders)"; konu="$($s.konu)"; kusur=$kusur; eski=([ordered]@{ soru="$($s.soru)"; siklar=$s.siklar; dogru="$($s.dogru)"; aciklama=$s.aciklama; hap="$($s.hap)" }); yeni=$obj })
  try {
    Invoke-RestMethod -Uri "$STOR/object/$KOVA/ic-tutarlilik-onar/$etiket/$($s.id).json" -Method Post -Headers ($SB + @{ 'Content-Type'='application/json'; 'x-upsert'='true' }) -Body ([Text.Encoding]::UTF8.GetBytes($taslak)) -TimeoutSec 60 | Out-Null
    $basarili++
  } catch { $islenmeyen += "$($s.id)|kova-yazma" }
  if((($n+1) % 25) -eq 0){ Write-Host ("  {0}/{1} | taslak {2} | {3:N2} USD" -f ($n+1), $hedef.Count, $basarili, ($tIn*$FIY_IN + $tOut*$FIY_OUT)) }
}

$maliyetSon = [math]::Round($tIn*$FIY_IN + $tOut*$FIY_OUT, 2)
Write-Host ("BITTI: taslak {0} | kapi reddi {1} | islenmeyen {2} | maliyet {3} USD" -f $basarili, $kapiRed, $islenmeyen.Count, $maliyetSon)
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$(if($harcKesildi){'EMNIYET-KEMERI'}else{'TAMAM'})
  etiket=$etiket; hedef=$hedef.Count; taslak=$basarili; kapiRed=$kapiRed
  maliyet_usd=$maliyetSon; girisTok=$tIn; cikisTok=$tOut
  islenmeyen=@($islenmeyen | Select-Object -First 300)
  not='Taslaklar onarim-taslak kovasinda (ic-tutarlilik-onar/' + $etiket + '/). Kasaya UYGULANMADI - hakem + GM okumasi bekliyor.'
})
