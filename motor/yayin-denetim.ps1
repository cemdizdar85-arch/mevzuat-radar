# ============================================================================
#  YAYIN DENETIMI — INSAN GOZU (02.08.2026)
#  Cem: "kalite odun yok, sitede yanlis bir cevap olmayacak; yanlis cevabi ILK
#        BIZ gorecegiz, onu cozmeden siteye sokmayacagiz."
#
#  DURUM: yayindaki sorularin hicbirini insan okumadi - hepsi robot kapilarindan
#  gecti (uretim kapilari + hakem 3/3 + alinti dogrulamasi). Robot kapilari
#  KUSURSUZ DEGIL: hakem bugun 12.996 hukmun 630'unda kendi alintisini uydurdu.
#  Bu betik, yayindaki sorulari DAYANAK METNIYLE YAN YANA dokup okunabilir hale
#  getirir. Boylece yanlis cevabi ogrenciden ONCE biz goruruz.
#
#  PARA HARCAMAZ (yalniz Supabase okumasi). Cikti:
#    veri/yayin-denetim.json  (makine)  +  veri/yayin-denetim.md  (insan okur)
#  ENV: SUPABASE_SERVICE_KEY
#  KULLANIM: ./motor/yayin-denetim.ps1 [-adet 50] [-ders "Finansal Muhasebe"]
# ============================================================================
param([int]$adet = 50, [string]$ders = '')
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$jsonYol = Join-Path $kok 'veri/yayin-denetim.json'
$mdYol   = Join-Path $kok 'veri/yayin-denetim.md'

function Kirp([string]$m, [int]$n){
  if([string]::IsNullOrEmpty($m)){ return "" }
  if($m.Length -le $n){ return $m }
  return $m.Substring(0, $n)
}

. (Join-Path $here 'madde-coz.ps1') -kutuphane

$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }

# 02.08 (perde indikten sonra): artik yayinda soru YOK. Okunacak kume
# "YAYINA ADAY"lar: hakemden 3/3 gecmis ve alintisi dogrulanmis sorular.
# Insan okumasi bunlarin uzerinde yapilir; temiz cikan parti yayina acilir.
$aday = New-Object 'System.Collections.Generic.HashSet[string]'
foreach($f in (Get-ChildItem (Join-Path $kok 'veri') -Filter 'profesor-rapor-*.json' -ErrorAction SilentlyContinue)){
  try { $r = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($x in @($r.sonuclar)){
    if("$($x.destek)" -ne 'evet'){ continue }
    if("$($x.tek_dogru)" -ne 'evet'){ continue }
    if("$($x.celiski)" -ne 'hayir'){ continue }
    if($x.PSObject.Properties['alinti_dogrulandi'] -and $x.alinti_dogrulandi -ne $true){ continue }
    [void]$aday.Add("$($x.id)")
  }
}
Write-Host ("Hakemden 3/3 gecen aday: {0}" -f $aday.Count)

$sorgu = "${U}?select=id,ders,konu,soru,siklar,dogru,aciklama,kaynak,sinav,yayin&order=id&limit=1000"
if($ders){ $sorgu += "&ders=eq." + [uri]::EscapeDataString($ders) }
$yayinda = New-Object System.Collections.Generic.List[object]
$ofs = 0
while($true){
  $w = Invoke-WebRequest -Uri ($sorgu + "&offset=$ofs") -Headers $SB -UseBasicParsing -TimeoutSec 120
  $ham = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
  $l = @($ham | ConvertFrom-Json); if($l.Count -eq 0){ break }
  foreach($s in $l){
    $tam = "$($s.id)"; $kisa = if($tam.Length -ge 8){ $tam.Substring(0,8) } else { $tam }
    if($aday.Contains($tam) -or $aday.Contains($kisa)){ $yayinda.Add($s) }
  }
  if($l.Count -lt 1000){ break }
  $ofs += 1000
}
Write-Host ("Okunacak aday havuzu: {0} soru" -f $yayinda.Count)
if($yayinda.Count -eq 0){ Write-Host "Aday soru yok."; exit 0 }

# TEMSILI ORNEK: bastan degil, esit araliklarla secilir (tek ders/tek parti
# yiginlarina takilmamak icin). Boylece ornek butun kasayi temsil eder.
$sec = New-Object System.Collections.Generic.List[object]
$aralik = [Math]::Max(1, [Math]::Floor($yayinda.Count / $adet))
for($i = 0; $i -lt $yayinda.Count -and $sec.Count -lt $adet; $i += $aralik){ $sec.Add($yayinda[$i]) }
Write-Host ("Denetlenecek ornek: {0} (her {1} soruda bir)" -f $sec.Count, $aralik)

$sb = New-Object Text.StringBuilder
[void]$sb.AppendLine("# YAYIN DENETIMI - insan gozu okumasi")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Tarih: " + (Get-Date -Format 'dd.MM.yyyy HH:mm') + " | Aday havuzu: " + $yayinda.Count + " | Ornek: " + $sec.Count)
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Kural (Cem 02.08): **sitede yanlis cevap olmayacak.** Asagidaki her soruda")
[void]$sb.AppendLine("cevap, aciklama ve DAYANAK METNI yan yana. Kusur gorulen soru yayindan cekilir.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## OKUMA OLCUTLERI (her soru icin ikisi de saglanmali)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("**A) CEVAP DOGRU MU?**")
[void]$sb.AppendLine("1. Isaretli sik, dayanak metninin soyledigi seyi mi soyluyor?")
[void]$sb.AppendLine("2. Baska bir sik da dogru olabilir mi? (iki dogru sik = kusur)")
[void]$sb.AppendLine("3. Soru govdesi eksik/celiskili veri iceriyor mu?")
[void]$sb.AppendLine("4. Kaynak atfi DOGRU madde/nota mi? (dogru cevap + yanlis dayanak yine kusurdur)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("**B) ACIKLAMA OGRETIYOR MU?** (Tetikte aciklama standardi)")
[void]$sb.AppendLine("5. Dort parca var mi: NE SORULUYOR / KURAL / BU OLAYDA / AKILDA KALSIN?")
[void]$sb.AppendLine("6. YANLIS siklarin NEDEN yanlis oldugu tek tek anlatiliyor mu?")
[void]$sb.AppendLine("   (Aday konuyu nasil yanlis ogrendiyse tam orada duzeltiyoruz - kural bu.)")
[void]$sb.AppendLine("7. Tuzagin ADI konmus mu? ('vade farki KDV matrahina dahildir' gibi)")
[void]$sb.AppendLine("8. Ezber degil, anlatan bir dil mi? Aday bilmiyorsa bu metinden ogrenebilir mi?")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("A'da tek kusur = soru ELENIR. B'de kusur = soru yayina girmez, aciklama duzeltilir.")
[void]$sb.AppendLine("")

$kayit = New-Object System.Collections.Generic.List[object]
$metinsiz = 0
$n = 0
foreach($s in $sec){
  $n++
  $c = $null
  try { $c = KaynakCoz "$($s.kaynak)" "$($s.konu)" } catch {}
  $dayanak = if($c -and $c.metin){ Kirp "$($c.metin)" 1200 } else { "" }
  if(-not $dayanak){ $metinsiz++ }
  $etiket = if($c -and $c.ad){ "$($c.ad)" } else { "$($s.kaynak)" }

  [void]$sb.AppendLine("---")
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("## $n) [$($s.sinav) / $($s.ders)] $($s.konu)")
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("**SORU:** $($s.soru)")
  [void]$sb.AppendLine("")
  foreach($h in @('A','B','C','D','E')){
    $sik = "$($s.siklar.$h)"
    if($sik.Trim().Length -eq 0){ continue }
    $isaret = if("$($s.dogru)" -eq $h){ " **<-- ISARETLI DOGRU**" } else { "" }
    [void]$sb.AppendLine("- **$h)** $sik$isaret")
  }
  [void]$sb.AppendLine("")
  # 02.08 (Cem hatirlatmasi): "her cevaba karsilik adayin konuyu nasil
  # ogrenemedigini bilip ona gore ogretiyoruz". Yani denetimde iki soru sorulur:
  #   (1) cevap DOGRU mu?   (2) aciklama OGRETIYOR mu?
  # Ikincisi ancak HER SIKKIN aciklamasi ayri ayri gorulurse denetlenebilir.
  # Onceki surumde aciklama tek blok yazdiriliyordu (ustelik nesne oldugu icin
  # metin yerine tur adi basiliyordu) - ogretme kalitesi olculemezdi.
  [void]$sb.AppendLine("**ACIKLAMALAR (sik sik - ogretiyor mu?):**")
  [void]$sb.AppendLine("")
  $ackVar = $false
  foreach($h in @('A','B','C','D','E')){
    $ack = "$($s.aciklama.$h)"
    if($ack.Trim().Length -eq 0){ continue }
    $ackVar = $true
    $im = if("$($s.dogru)" -eq $h){ "DOGRU" } else { "yanlis" }
    [void]$sb.AppendLine("  - **$h ($im):** " + (Kirp $ack 700))
  }
  if(-not $ackVar){
    $duz = "$($s.aciklama)"
    if($duz -match '^System\.' -or $duz.Trim().Length -eq 0){ [void]$sb.AppendLine("  - **ACIKLAMA OKUNAMADI / BOS** - INCELE") }
    else { [void]$sb.AppendLine("  - " + (Kirp $duz 900)) }
  }
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("**KAYNAK ALANI:** $($s.kaynak)")
  [void]$sb.AppendLine("")
  if($dayanak){
    [void]$sb.AppendLine("**DAYANAK METNI ($etiket):**")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("> " + ($dayanak -replace "`n", "`n> "))
  } else {
    [void]$sb.AppendLine("**DAYANAK METNI: BULUNAMADI** - bu soru yayinda ama dayanagi ambardan cozulemiyor. INCELE.")
  }
  [void]$sb.AppendLine("")
  $kayit.Add([ordered]@{ sira=$n; id="$($s.id)"; ders="$($s.ders)"; konu="$($s.konu)"; dayanak_var=[bool]$dayanak; etiket=$etiket })
}

Set-Content -LiteralPath $mdYol -Value $sb.ToString() -Encoding UTF8
$ozet = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  maliyet = "0 USD - API cagrisi yok"
  aday_havuzu = $yayinda.Count
  denetlenen = $sec.Count
  dayanagi_cozulemeyen = $metinsiz
  kayitlar = $kayit.ToArray()
  not = "veri/yayin-denetim.md dosyasi insan okumasi icindir. Kusurlu bulunan sorunun kimligi motor/yayindan-cek.ps1 ile yayindan cekilir."
}
$j = ConvertTo-Json -InputObject $ozet -Depth 5
if($j -isnot [string]){ $j = ($j -join [Environment]::NewLine) }
Set-Content -LiteralPath $jsonYol -Value ([string]$j) -Encoding UTF8 -NoNewline
Write-Host ("Dayanagi cozulemeyen: {0}/{1}" -f $metinsiz, $sec.Count)
Write-Host ("-> {0}" -f $mdYol)
