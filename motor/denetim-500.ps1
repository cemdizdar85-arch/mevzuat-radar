# ============================================================================
#  BUYUK DENETIM — 500 SORU, DENGELI ORNEK + MAKINE KAPILARI (02.08.2026)
#  Cem: "bu 40 soru yetmez, bir 500 soru cozelim... her sik ayri mi,
#        kontrolsuz yapmak yok bundan sonra."
#
#  40'lik denetimde cikan ders: rastgele/esit-aralikli ornek YETMIYOR. 40 sorunun
#  23'u yalniz 4 maddeden gelmisti; 500'u ayni sekilde secersek yine ayni kurali
#  yuzlerce kez okuruz. Bu yuzden ornek IKI ELEKTEN gecer:
#    1) DERS DENGESI  - her ders havuzdaki agirligi kadar temsil edilir.
#    2) MADDE TAVANI  - ayni maddeden en fazla -maddeTavan soru alinir (vars. 3).
#  Boylece 500 soru ~170+ farkli maddeyi yoklar; kor okuma olmaz.
#
#  MAKINE KAPILARI (hepsi ucretsiz, LLM YOK - yalniz kural):
#    G1 dogrusu_eksik   : yanlis siklarin 3'unden azinda "Dogrusu:" var
#    G2 sik_kopya       : iki yanlis sikkin aciklamasi birbirinin kopyasi
#    G3 sik_ilgisiz     : sikkin aciklamasi kendi sikkindan hic soz etmiyor
#    G4 parca_eksik     : dogru sik aciklamasinda 4 parcadan biri yok
#    G5 yasakli_kalip   : "Bu sik yanlistir", "ezberleyin" gibi bos/kucumseyen dil
#    G6 etiket_uyumsuz  : dersin mevzuat ailesi ile kaynagin ailesi tutmuyor
#    G7 mukerrer_kural  : ayni kaynak+ayni dogru sik KASADA baska sorularda da var
#    G8 rakam_tutmuyor  : soruda hesap var ama dogru sik aciklamasinda o rakamlar yok
#    G9 dayanak_yok     : kaynak ambardan cozulemiyor
#  Her soruya kusur puani verilir, rapor PUANA GORE SIRALANIR: en supheli basta.
#  Makine "yanlis" demez - NEREYE BAKILACAGINI soyler. Karar insanindir.
#
#  PARA HARCAMAZ (Supabase okumasi + yerel ambar). ENV: SUPABASE_SERVICE_KEY
#  Cikti: veri/denetim-500.md (insan okur) + veri/denetim-500.json (makine)
#  KULLANIM: ./motor/denetim-500.ps1 [-adet 500] [-maddeTavan 3]
# ============================================================================
param([int]$adet = 500, [int]$maddeTavan = 3)
$ErrorActionPreference = 'Stop'
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
$mdYol   = Join-Path $kok 'veri/denetim-500.md'
$jsonYol = Join-Path $kok 'veri/denetim-500.json'

. (Join-Path $here 'madde-coz.ps1') -kutuphane

# ------------------------------------------------------------------ yardimcilar
function Kirp([string]$m, [int]$n){
  if([string]::IsNullOrEmpty($m)){ return "" }
  if($m.Length -le $n){ return $m }
  return $m.Substring(0, $n)
}
function Sade([string]$m){
  if([string]::IsNullOrWhiteSpace($m)){ return '' }
  $t = $m.ToLowerInvariant()
  $t = [regex]::Replace($t, '[0-9]+', ' ')
  $t = [regex]::Replace($t, '[^\p{L}\s]', ' ')
  $t = [regex]::Replace($t, '\s+', ' ')
  return $t.Trim()
}
# anlamli kelime kumesi (kisa baglaclar atilir - "ve/ile/bir" benzerligi sisirir)
function Kume([string]$m){
  $hx = New-Object 'System.Collections.Generic.HashSet[string]'
  foreach($w in (Sade $m) -split ' '){ if($w.Length -ge 5){ [void]$hx.Add($w) } }
  return $hx
}
function Jaccard($a, $b){
  if($a.Count -eq 0 -or $b.Count -eq 0){ return 0.0 }
  $kesisim = 0
  foreach($w in $a){ if($b.Contains($w)){ $kesisim++ } }
  $birlesim = $a.Count + $b.Count - $kesisim
  if($birlesim -le 0){ return 0.0 }
  return [math]::Round($kesisim / $birlesim, 3)
}
function Aile([string]$k){
  $t = "$k".ToUpperInvariant()
  if($t -match 'VUK|213|KDV|3065|GVK|193|KVK|5520|ÖTV|OTV|4760'){ return 'VERGI' }
  if($t -match 'TTK|6102')             { return 'TICARET' }
  if($t -match 'TBK|6098|BORCLAR')     { return 'BORCLAR' }
  if($t -match 'İŞ K|IS K|4857|SGK|5510|SOSYAL'){ return 'IS' }
  if($t -match 'TMS|TFRS|BOBI|KUMI|MSUGT|TEKDUZEN'){ return 'STANDART' }
  if($t -match 'BDS|KGK|KYS|GDS|SBDS'){ return 'DENETIM' }
  if($t -match 'İİK|IIK|2004')         { return 'ICRA' }
  if($t -match 'SMK|6769')             { return 'MARKA' }
  return 'DIGER'
}
function DersAile([string]$d){
  $t = "$d".ToLowerInvariant()
  if($t -match 'vergi')                                 { return @('VERGI') }
  if($t -match 'maliyet|finansal muhasebe|genel muhasebe|muhasebe'){ return @('VERGI','STANDART') }
  if($t -match 'mali tablo|finansal tablo|analiz')      { return @('STANDART','VERGI') }
  if($t -match 'denetim')                               { return @('DENETIM','STANDART') }
  if($t -match 'ticaret hukuku|sirketler|şirketler')    { return @('TICARET') }
  if($t -match 'borclar|borçlar')                       { return @('BORCLAR','TICARET') }
  if($t -match 'is ve sosyal|iş ve sosyal|sosyal g')    { return @('IS') }
  if($t -match 'hukuk')                                 { return @('TICARET','BORCLAR','IS','ICRA','MARKA') }
  if($t -match 'standart|tms|tfrs|raporlama')           { return @('STANDART') }
  return @()
}
$reDogrusu  = [regex]'(?i)do[ğg]rusu\s*:'
$reYasakli  = [regex]'(?i)bu\s+[sş][ıi]k\s+yanl[ıi][sş]|ezberley|ezberlemek|basit[çc]e\s+s[oö]ylemek|kolayca\s+anla[sş]'
$reHesapli  = [regex]'(?i)ka[çc]\s+TL|ne\s+kadar|tutar[ıi]n[ıi]|hesaplay|toplam\s+maliyet|amortisman\s+tutar'
$reSayi     = [regex]'\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d{4,}'

# ------------------------------------------------------------------ aday havuzu
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

$havuz = New-Object System.Collections.Generic.List[object]
$tumKasa = 0
$ofs = 0
while($true){
  $w = Invoke-WebRequest -Uri "${U}?select=id,sinav,ders,konu,soru,siklar,dogru,aciklama,kaynak,tablo,yevmiye&order=id&limit=1000&offset=$ofs" -Headers $SB -UseBasicParsing -TimeoutSec 180
  $ham = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
  $l = @($ham | ConvertFrom-Json); if($l.Count -eq 0){ break }
  foreach($s in $l){
    $tumKasa++
    $tam = "$($s.id)"; $kisa = if($tam.Length -ge 8){ $tam.Substring(0,8) } else { $tam }
    if($aday.Contains($tam) -or $aday.Contains($kisa)){ $havuz.Add($s) }
  }
  if($l.Count -lt 1000){ break }
  $ofs += 1000
}
Write-Host ("Kasa: {0} | yayina aday havuzu: {1}" -f $tumKasa, $havuz.Count)
if($havuz.Count -eq 0){ Write-Host "Aday yok - cikildi."; exit 0 }

# --------------------------------------------- G7 icin: KASA CAPINDA kural sayimi
# Kural parmak izi = kaynak(madde) + dogru sikkin RAKAMSIZ metni. Ayni parmak izi
# birden fazla soruda gorunuyorsa ayni kural kilik degistirerek tekrar etmis
# demektir; 60-karakter mukerrer kapisi bunu goremiyordu.
function ParmakIzi($s){
  $k = ("$($s.kaynak)" -split ' - ')[0].Trim()
  $harf = "$($s.dogru)".Trim().ToUpperInvariant()
  $dm = if($harf.Length -gt 0 -and $s.siklar){ "$($s.siklar.$harf)" } else { '' }
  $sd = Sade $dm
  if($sd.Length -gt 80){ $sd = $sd.Substring(0,80) }
  return "$k|$sd"
}
$izSayim = @{}
foreach($s in $havuz){ $iz = ParmakIzi $s; $izSayim[$iz] = 1 + [int]$izSayim[$iz] }

# ------------------------------------------------------------ DENGELI ORNEKLEME
# 1) ders dagilimi
$dersHavuz = @{}
foreach($s in $havuz){
  $d = "$($s.ders)"; if($d.Trim().Length -eq 0){ $d = '(dersi bos)' }
  if(-not $dersHavuz.ContainsKey($d)){ $dersHavuz[$d] = New-Object System.Collections.Generic.List[object] }
  $dersHavuz[$d].Add($s)
}
# 2) her derse kota: havuzdaki agirligi kadar, en az 10
$dersKota = @{}
$kalan = $adet
$dersler = @($dersHavuz.Keys | Sort-Object)
foreach($d in $dersler){
  $pay = [math]::Max(10, [math]::Floor($adet * $dersHavuz[$d].Count / $havuz.Count))
  $pay = [math]::Min($pay, $dersHavuz[$d].Count)
  $dersKota[$d] = $pay
}
# 3) madde tavanli secim; kota dolmazsa tavan gevsetilir (500'e ulasilsin diye)
$sec = New-Object System.Collections.Generic.List[object]
$maddeSayim = @{}
$secId = New-Object 'System.Collections.Generic.HashSet[string]'   # -contains yerine: O(1)
$dersMevcut = @{}
foreach($tavan in @($maddeTavan, ($maddeTavan+2), ($maddeTavan+5), 999)){
  foreach($d in $dersler){
    $hedef = [int]$dersKota[$d]
    $mevcut = [int]$dersMevcut[$d]
    if($mevcut -ge $hedef){ continue }
    foreach($s in $dersHavuz[$d]){
      if($sec.Count -ge $adet){ break }
      if($mevcut -ge $hedef){ break }
      if($secId.Contains("$($s.id)")){ continue }
      $k = ("$($s.kaynak)" -split ' - ')[0].Trim()
      if($k.Length -eq 0){ $k = '(kaynaksiz)' }
      if([int]$maddeSayim[$k] -ge $tavan){ continue }
      $maddeSayim[$k] = 1 + [int]$maddeSayim[$k]
      $sec.Add($s); [void]$secId.Add("$($s.id)"); $mevcut++
    }
    $dersMevcut[$d] = $mevcut
  }
  if($sec.Count -ge $adet){ break }
}
Write-Host ("Secilen ornek: {0} soru | farkli madde: {1} | ders: {2}" -f $sec.Count, $maddeSayim.Count, $dersler.Count)

# ------------------------------------------------------------------- KAPILAR
$parcalar = @('ne soruluyor','kural','bu olayda','ak[ıi]lda kals[ıi]n')
$agirlik = @{ G1=3; G2=3; G3=3; G4=2; G5=1; G6=4; G7=4; G8=2; G9=5 }
$sonuc = New-Object System.Collections.Generic.List[object]
$kapiSayim = @{}
$cozumHata = @{}   # cozum hatalari GORUNUR tutulur (kor kalma kurali)
foreach($s in $sec){
  $bayrak = New-Object System.Collections.Generic.List[string]
  $harf = "$($s.dogru)".Trim().ToUpperInvariant()
  $yanlisSik = @('A','B','C','D','E') | Where-Object { $_ -ne $harf }

  # G9 + dayanak metni. KOR KALMA KURALI: cozum hatasi SESSIZCE YUTULMAZ -
  # ilk kosuda catch{} bostu ve 499/500 "cozulemedi" cikti; yerelde ayni 267
  # kaynak 267/267 cozuluyordu. Hata mesaji gorunmeden teshis imkansizdi.
  $c = $null
  try { $c = KaynakCoz "$($s.kaynak)" "$($s.konu)" }
  catch {
    $hm = "$($_.Exception.Message)"; if($hm.Length -gt 160){ $hm = $hm.Substring(0,160) }
    $cozumHata[$hm] = 1 + [int]$cozumHata[$hm]
  }
  if($c -and -not $c.metin){ $d9 = "durum=$($c.durum)"; $cozumHata[$d9] = 1 + [int]$cozumHata[$d9] }
  $dayanak = if($c -and $c.metin){ "$($c.metin)" } else { '' }
  if(-not $dayanak){ [void]$bayrak.Add('G9') }

  # G1
  $dgSay = 0; $doluYanlis = 0
  foreach($hx in $yanlisSik){
    $a = "$($s.aciklama.$hx)"; if($a.Trim().Length -eq 0){ continue }
    $doluYanlis++
    if($reDogrusu.IsMatch($a)){ $dgSay++ }
  }
  if($dgSay -lt 3){ [void]$bayrak.Add('G1') }

  # G2 - yanlis sik aciklamalari birbirinin kopyasi mi
  $kopya = $false
  for($i=0; $i -lt $yanlisSik.Count; $i++){
    for($j=$i+1; $j -lt $yanlisSik.Count; $j++){
      $a1 = "$($s.aciklama.$($yanlisSik[$i]))"; $a2 = "$($s.aciklama.$($yanlisSik[$j]))"
      if($a1.Trim().Length -lt 40 -or $a2.Trim().Length -lt 40){ continue }
      # 0,65 esigi yerelde olculdu: tek kelime degistirilmis iki aciklama 0,667
      # veriyor. Esik yuksek olursa kopya kacar. Bu kapi soruyu REDDETMEZ,
      # "buna bak" der - yanlis alarm, kacirmaktan ucuzdur.
      if((Jaccard (Kume $a1) (Kume $a2)) -ge 0.65){ $kopya = $true }
    }
  }
  if($kopya){ [void]$bayrak.Add('G2') }

  # G3 - sikkin aciklamasi kendi sikkindan soz ediyor mu
  $ilgisiz = 0
  foreach($hx in @('A','B','C','D','E')){
    $sik = "$($s.siklar.$hx)"; $ack = "$($s.aciklama.$hx)"
    if($sik.Trim().Length -lt 12 -or $ack.Trim().Length -lt 40){ continue }
    $ks = Kume $sik
    if($ks.Count -eq 0){ continue }
    if((Jaccard $ks (Kume $ack)) -le 0.0){ $ilgisiz++ }
  }
  if($ilgisiz -ge 2){ [void]$bayrak.Add('G3') }

  # G4 - dogru sikkin 4 parcasi
  $dAck = "$($s.aciklama.$harf)"
  $eksikParca = 0
  foreach($p in $parcalar){ if($dAck -notmatch "(?i)$p"){ $eksikParca++ } }
  if($eksikParca -ge 1){ [void]$bayrak.Add('G4') }

  # G5 - yasakli kalip (tum aciklamalarda)
  $hepsi = ''
  foreach($hx in @('A','B','C','D','E')){ $hepsi += " " + "$($s.aciklama.$hx)" }
  if($reYasakli.IsMatch($hepsi)){ [void]$bayrak.Add('G5') }

  # G6 - etiket/kaynak ailesi
  $bek = DersAile "$($s.ders)"
  $ger = Aile "$($s.kaynak)"
  if($bek.Count -gt 0 -and $ger -ne 'DIGER' -and $bek -notcontains $ger){ [void]$bayrak.Add('G6') }

  # G7 - kural mukerreri
  $iz = ParmakIzi $s
  $izN = [int]$izSayim[$iz]
  if($izN -ge 2){ [void]$bayrak.Add('G7') }

  # G8 - hesap sorusu ama dogru aciklamada rakam yok
  if($reHesapli.IsMatch("$($s.soru)")){
    $sorudaki = @($reSayi.Matches("$($s.soru)") | ForEach-Object { $_.Value })
    if($sorudaki.Count -ge 1){
      $bulundu = $false
      foreach($r in $sorudaki){ if($dAck -like "*$r*"){ $bulundu = $true; break } }
      if(-not $bulundu){ [void]$bayrak.Add('G8') }
    }
  }

  $puan = 0
  foreach($b in $bayrak){ $puan += [int]$agirlik[$b]; $kapiSayim[$b] = 1 + [int]$kapiSayim[$b] }
  $sonuc.Add([ordered]@{
    s = $s; puan = $puan; bayrak = $bayrak.ToArray(); dayanak = $dayanak
    etiket = $(if($c -and $c.ad){ "$($c.ad)" } else { "$($s.kaynak)" })
    izN = $izN
  })
}

# ------------------------------------------------------------------- RAPOR
$sirali = @($sonuc | Sort-Object -Property @{Expression={$_.puan}; Descending=$true})
$temiz = @($sonuc | Where-Object { $_.puan -eq 0 }).Count

$sb = New-Object Text.StringBuilder
[void]$sb.AppendLine("# BUYUK DENETIM - 500 SORU")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Tarih: $(Get-Date -Format 'dd.MM.yyyy HH:mm') | Aday havuzu: $($havuz.Count) | Okunacak ornek: $($sec.Count)")
[void]$sb.AppendLine("Farkli madde: $($maddeSayim.Count) | Madde tavani: $maddeTavan | Kusursuz (0 puan): $temiz")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## NASIL OKUNUR")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Her soruda IKI soru sorulur:")
[void]$sb.AppendLine("**(A) Cevap DOGRU mu?** - dayanak metni asagida, yan yana.")
[void]$sb.AppendLine("**(B) Aciklama OGRETIYOR mu?** - dogruyu bilene NEDEN dogru, yanlisi isaretleyene NEDEN yanlis ve DOGRUSU NE.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Sorular KUSUR PUANINA gore sirali - en supheli en ustte. Puan makinenin suphesidir, hukmu degil.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Kapi | Anlami | Kac soruda |")
[void]$sb.AppendLine("|---|---|---|")
$kapiAd = [ordered]@{
  G9='Dayanak ambardan cozulemedi'; G7='Ayni kural baska sorularda da var (mukerrer)'
  G6='Ders etiketi ile kaynak ailesi tutmuyor'; G1='"Dogrusu:" 3 yanlis sikta yok'
  G2='Iki yanlis sikkin aciklamasi birbirinin kopyasi'; G3='Sik aciklamasi kendi sikkindan soz etmiyor'
  G4='Dogru sik aciklamasinda 4 parcadan biri eksik'; G8='Hesap sorusu ama aciklamada rakam yok'
  G5='Yasakli/kucumseyen kalip'
}
foreach($k in $kapiAd.Keys){ [void]$sb.AppendLine("| $k | $($kapiAd[$k]) | $([int]$kapiSayim[$k]) |") }
[void]$sb.AppendLine("")

$kayit = New-Object System.Collections.Generic.List[object]
$n = 0
foreach($r in $sirali){
  $n++; $s = $r.s
  [void]$sb.AppendLine("---")
  [void]$sb.AppendLine("")
  $bayrakStr = if($r.bayrak.Count -gt 0){ ($r.bayrak -join ', ') } else { 'temiz' }
  [void]$sb.AppendLine("## $n) [$($s.sinav) / $($s.ders)] $($s.konu)  -  KUSUR $($r.puan) ($bayrakStr)")
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("**SORU:** $($s.soru)")
  [void]$sb.AppendLine("")
  foreach($hx in @('A','B','C','D','E')){
    $sik = "$($s.siklar.$hx)"; if($sik.Trim().Length -eq 0){ continue }
    $isaret = if("$($s.dogru)" -eq $hx){ " **<-- ISARETLI DOGRU**" } else { "" }
    [void]$sb.AppendLine("- **$hx)** $sik$isaret")
  }
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("**ACIKLAMALAR (sik sik):**")
  [void]$sb.AppendLine("")
  $ackVar = $false
  foreach($hx in @('A','B','C','D','E')){
    $ack = "$($s.aciklama.$hx)"; if($ack.Trim().Length -eq 0){ continue }
    $ackVar = $true
    $im = if("$($s.dogru)" -eq $hx){ "DOGRU" } else { "yanlis" }
    [void]$sb.AppendLine("  - **$hx ($im):** " + (Kirp $ack 800))
  }
  if(-not $ackVar){ [void]$sb.AppendLine("  - **ACIKLAMA OKUNAMADI / BOS** - INCELE") }
  [void]$sb.AppendLine("")
  # 03.08 BASKI DUZELTMESI: "$($s.yevmiye)" PS stringlestirmesi diziyi
  # "260002600026000", nesneyi "@{...System.Object[]}" diye basiyordu; 500
  # okumasinda "bozuk alan" sanilan sey RAPORUN kendi hatasiydi. JSON bas.
  if($s.yevmiye){ $yj = $(try { ConvertTo-Json $s.yevmiye -Depth 6 -Compress } catch { "$($s.yevmiye)" })
    if("$yj".Trim().Length -gt 5){ [void]$sb.AppendLine("**YEVMIYE VERISI:** " + (Kirp "$yj" 600)); [void]$sb.AppendLine("") } }
  if($s.tablo){ $tj = $(try { ConvertTo-Json $s.tablo -Depth 6 -Compress } catch { "$($s.tablo)" })
    if("$tj".Trim().Length -gt 5){ [void]$sb.AppendLine("**TABLO VERISI:** " + (Kirp "$tj" 600)); [void]$sb.AppendLine("") } }
  [void]$sb.AppendLine("**KAYNAK ALANI:** $($s.kaynak)" + $(if($r.izN -ge 2){ "  _(bu kural havuzda $($r.izN) soruda)_" } else { "" }))
  [void]$sb.AppendLine("")
  if($r.dayanak){
    [void]$sb.AppendLine("**DAYANAK METNI ($($r.etiket)):**")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("> " + ((Kirp $r.dayanak 1400) -replace "`n", "`n> "))
  } else {
    [void]$sb.AppendLine("**DAYANAK METNI: BULUNAMADI** - INCELE.")
  }
  [void]$sb.AppendLine("")
  $kayit.Add([ordered]@{
    sira=$n; id="$($s.id)"; sinav="$($s.sinav)"; ders="$($s.ders)"; konu="$($s.konu)"
    kaynak="$($s.kaynak)"; puan=$r.puan; bayrak=$r.bayrak; kural_tekrar=$r.izN
  })
}
Set-Content -LiteralPath $mdYol -Value $sb.ToString() -Encoding UTF8

$ozet = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  kasa = $tumKasa
  aday_havuz = $havuz.Count
  ornek = $sec.Count
  farkli_madde = $maddeSayim.Count
  madde_tavani = $maddeTavan
  kusursuz = $temiz
  kapi_sayim = ($kapiAd.Keys | ForEach-Object { [ordered]@{ kapi=$_; anlam=$kapiAd[$_]; adet=[int]$kapiSayim[$_] } })
  cozum_hatalari = ($cozumHata.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15 | ForEach-Object { [ordered]@{ hata=$_.Key; adet=$_.Value } })
  kayitlar = $kayit.ToArray()
}
$j = ConvertTo-Json -InputObject $ozet -Depth 6
if($j -isnot [string]){ $j = ($j -join [Environment]::NewLine) }
Set-Content -LiteralPath $jsonYol -Value ([string]$j) -Encoding UTF8 -NoNewline

Write-Host ""
if($cozumHata.Count -gt 0){
  Write-Host "COZUM HATALARI (kor kalma kurali - gorunur):"
  foreach($e in ($cozumHata.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10)){
    Write-Host ("  {0,4}x  {1}" -f $e.Value, $e.Key)
  }
}
Write-Host "KAPI SAYIMI:"
foreach($k in $kapiAd.Keys){ Write-Host ("  {0} {1,-48} {2}" -f $k, $kapiAd[$k], [int]$kapiSayim[$k]) }
Write-Host ("Kusursuz (0 puan): {0} / {1}" -f $temiz, $sec.Count)
Write-Host ("-> {0}" -f $mdYol)
