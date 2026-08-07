# ============================================================================
#  DIL KUSURU TARAMASI (04.08.2026) — 0 USD, API YOK, YAZMA YOK
#
#  Cem'in bu gece taslakta yakaladigi UC dil kusurunu TEK kosuda olcer.
#  Amac: tek ornekten genelleme yapmamak (bu gecenin en pahali dersi).
#
#  1) UYDURMA SIKISTIRILMIS TERIM
#     Cem: "'cok donemli giderler' derken... bir neden varsa onlari yazmali."
#     Cem CUMLEYI "cok ONEMLI" diye okudu - bir SMMM yanlis okuyorsa aday
#     kesin yanlis okur. "Cok donemli gider" standart muhasebe Turkcesi
#     DEGILDIR; dogrusu "birden fazla donemi ilgilendiren giderler" ya da
#     dogrudan "pesin odenen giderler". Model resmi terim yerine kendi
#     kisaltmasini uyduruyor.
#
#  2) ESKI TERIM KEHRIBAR KARTTA
#     Acilis olcumu "genel imal" kalibini AKILDA KALSIN bolumunde 396 kez
#     buldu. Eski terim her yerde kotudur ama EZBERLENECEK kartta olmasi
#     en kotusudur.
#
#  3) TEKRARLAYAN SENARYO ISIMLERI
#     Mehmet Bey 276, Yildirim Makina 216, Mehmet Yilmaz 173, Yildirim
#     Mobilya 134... "Yildirim"in uc varyanti var - model favori isme
#     takilmis. Art arda ayni ismi goren aday makine izi sezer.
#
#  CIKTI: veri/dil-kusuru-raporu.json  ·  ENV: SUPABASE_SERVICE_KEY
#  07.08: -yaz modu (Cem gece yetkisi: 'bedava islere onay bekleme') -
#  jargon-yogun + eski-terim bulgulari BOS yayin_notu'lu sorulara
#  'dil-kusuru: ...' notu basar (dolu not EZILMEZ - asil kusur recetesi
#  oncelikli); onarimci or-secicisiyle bunlari da Haiku'ya tasir.
# ============================================================================
param([switch]$yaz)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/dil-kusuru-raporu.json'

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
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
# sb_secret tipi anahtar Bearer basligiyla 401 verir (karantina-tasi dersi):
# Bearer yalniz eski tip JWT'de eklenir; robot User-Agent her durumda sart.
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY }
if($env:SUPABASE_SERVICE_KEY -like 'eyJ*'){ $SB.Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  # PS5.1/7 farki sigortasi (06.08 dersi): 5.1'de CFJ diziyi TEK nesne dondurur
  return @(($m | ConvertFrom-Json) | ForEach-Object { $_ })
}
$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,soru,dogru,aciklama,hap,yayin_notu&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

# --- 1) UYDURMA SIKISTIRILMIS TERIMLER (Cem'in "cok donemli" bulgusu) ---
#     Her biri: desen + dogrusu. Yalniz OLCULUR, degistirilmez.
$UYDURMA = @(
  @{ ad='cok donemli gider';       desen='(?i)çok\s+dönemli';                         dogrusu='birden fazla dönemi ilgilendiren / peşin ödenen' }
  @{ ad='cok yilli gider';         desen='(?i)çok\s+y[ıi]ll[ıi]\s+gider';             dogrusu='gelecek yıllara ait giderler' }
  @{ ad='donemsel gider';          desen='(?i)dönemsel\s+gider';                      dogrusu='döneme ait gider' }
  @{ ad='ileri donemli';           desen='(?i)ileri\s+dönemli';                       dogrusu='gelecek dönemlere ait' }
  @{ ad='pesinli gider';           desen='(?i)pe[şs]inli\s+gider';                    dogrusu='peşin ödenen gider' }
  @{ ad='kismi donemli';           desen='(?i)k[ıi]smi\s+dönemli';                    dogrusu='dönemin bir kısmına ait' }
  @{ ad='coklu donem';             desen='(?i)çoklu\s+dönem';                         dogrusu='birden fazla dönem' }
  @{ ad='gider yazimi (tek kelime)'; desen='(?i)giderle[şs]tirme\s+i[şs]lemi';        dogrusu='gider kaydı' }
  # 07.08 aksam (Cem "ara kara / kara bolme" vakasi): sapkasiz kar-dativ cumleyi
  # anlamsizlastiriyor ("baska bir kara bolme"). kara=toprak/renk anlamlariyla
  # karismasin diye yalniz mali baglamdaki on-ekli bicimler taranir.
  @{ ad='sapkasiz kar-dativ (ara/net/brut/donem kara)'; desen='(?i)\b(ara|net|br[üu]t|dönem)\s+kara\b'; dogrusu='... kâra (şapkalı; kâr kelimesinin -e hâli)' }
  @{ ad='kara bolme/bolunur (bozuk)';                   desen='(?i)\bkara\s+böl';                       dogrusu='kârı ...ya bölme (neye bölündüğü açıkça yazılır)' }
)
# --- 2) ESKI TERIMLER (ozellikle hap/kehribar kartta) ---
$ESKI = @(
  @{ ad='genel imal gideri'; desen='(?i)genel\s+imal';        dogrusu='genel üretim giderleri (THP 730)' }
  @{ ad='imal edilen emtia'; desen='(?i)imal\s+edilen\s+emtia'; dogrusu='üretilen mamul' }
  @{ ad='mubayaa';           desen='(?i)mubayaa';             dogrusu='satın alma' }
  @{ ad='mezkur';            desen='(?i)mezk[uû]r';           dogrusu='anılan / söz konusu' }
  @{ ad='isbu';              desen='(?i)\bi[şs]bu\b';         dogrusu='bu' }
  @{ ad='iptidai madde';     desen='(?i)iptidai\s+madde';     dogrusu='ilk madde ve malzeme (kanun alintisi istisna)' }
)
# --- 2b) JARGON YOGUNLUGU (#12-C, 06.08 Cem onayi - "annem bile anlasin"):
#     bir CUMLEDE 2+ teknik terim geciyor VE cumlede gunluk-karsilik isareti
#     (yani/demek/denir/anlamina/parantez) YOKSA isaretlenir. Yalniz OLCUM;
#     karar hakem/insanindir. Terim listesi muhafazakar tutuldu - mevzuat
#     sinavinda terim kacinilmazdir, olculen sey ACIKLAMASIZ yigilmadir.
$JARGON = @('tamlayan','iyelik eki','yuklem','ilgec','edat','zamir','ulac','fiilimsi',
            'muteselsil','iktisap','ruchan','temerrut','tereke','izafe','gayrikabili',
            'aktiflestir','amortisman ayirma','reeskont','iskonto','tahakkuk','mahsup',
            'mukayyet','emsal bedel','vergi ziyai','matrah','istisna ve muafiyet')
$reKarsilik = [regex]'(?i)yani|demek(tir)?|denir|denilen|anlam[ıi]na|g[uü]nl[uü]k dil|\('
$reKisi   = [regex]'(?i)\b([A-ZÇĞİÖŞÜ][a-zçğıöşü]+)\s+(Bey|Han[ıi]m)\b'
$reSirket = [regex]'(?i)\b([A-ZÇĞİÖŞÜ][a-zçğıöşü]+)\s+(Makina|Makine|Mobilya|G[ıi]da|Tekstil|Sanayi|Ticaret|In[şs]aat|Nakliyat|Elektronik)\b'

$uydurmaSay = @{}; $uydurmaOrnek = @{}
$eskiSay = @{};    $eskiHapSay = @{}
$kisiSay = @{};    $sirketSay = @{}
foreach($u in $UYDURMA){ $uydurmaSay[$u.ad] = 0; $uydurmaOrnek[$u.ad] = New-Object System.Collections.Generic.List[string] }
foreach($e in $ESKI){ $eskiSay[$e.ad] = 0; $eskiHapSay[$e.ad] = 0 }

$hapliSoru = 0
$jargonYogunSoru = 0; $jargonOrnek = New-Object System.Collections.Generic.List[string]
$yazHedef = New-Object System.Collections.Generic.List[object]   # -yaz icin TAM liste (id + kusur + notlu-mu)
foreach($s in $kasa){
  $dh = "$($s.dogru)".Trim().ToUpper()
  $ac = ''
  try { if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){ $ac += ' ' + "$($p.Value)" } } } catch {}
  $hap = "$($s.hap)"
  $tum = "$($s.soru) $ac $hap"
  if($hap.Trim().Length -gt 3){ $hapliSoru++ }

  foreach($u in $UYDURMA){
    if([regex]::IsMatch($tum, $u.desen)){
      $uydurmaSay[$u.ad]++
      if($uydurmaOrnek[$u.ad].Count -lt 5){ $uydurmaOrnek[$u.ad].Add("$($s.id)") }
    }
  }
  foreach($e in $ESKI){
    if([regex]::IsMatch($tum, $e.desen)){
      $eskiSay[$e.ad]++
      $yazHedef.Add([pscustomobject]@{ id="$($s.id)"; kusur=('eski-terim: ' + $e.ad); notlu=([bool]("$($s.yayin_notu)".Trim())) })
    }
    if($hap.Trim().Length -gt 3 -and [regex]::IsMatch($hap, $e.desen)){ $eskiHapSay[$e.ad]++ }
  }
  # 2b jargon-yogunluk: aciklama+hap cumle cumle
  $jarBuldu = $false
  foreach($cumle in (($ac + ' ' + $hap) -split '[.!?]')){
    if($cumle.Trim().Length -lt 20){ continue }
    $vurus = 0
    foreach($j in $JARGON){ if($cumle -match ('(?i)' + [regex]::Escape($j))){ $vurus++ } }
    if($vurus -ge 2 -and -not $reKarsilik.IsMatch($cumle)){ $jarBuldu = $true; break }
  }
  if($jarBuldu){
    $jargonYogunSoru++
    if($jargonOrnek.Count -lt 10){ $jargonOrnek.Add("$($s.id)") }
    $yazHedef.Add([pscustomobject]@{ id="$($s.id)"; kusur='jargon-yogun'; notlu=([bool]("$($s.yayin_notu)".Trim())) })
  }
  foreach($m in $reKisi.Matches("$($s.soru)")){
    $ad = $m.Groups[1].Value
    if(-not $kisiSay.ContainsKey($ad)){ $kisiSay[$ad]=0 }; $kisiSay[$ad]++
  }
  foreach($m in $reSirket.Matches("$($s.soru)")){
    $ad = $m.Groups[1].Value
    if(-not $sirketSay.ContainsKey($ad)){ $sirketSay[$ad]=0 }; $sirketSay[$ad]++
  }
}

function Liste($tablo, $adet){
  $l = New-Object System.Collections.Generic.List[object]
  foreach($k in ($tablo.Keys | Sort-Object { -$tablo[$_] } | Select-Object -First $adet)){
    if($tablo[$k] -le 0){ continue }
    $l.Add([ordered]@{ ad=$k; soru=$tablo[$k]; yuzde=[Math]::Round(100.0*$tablo[$k]/$kasa.Count,2) })
  }
  return $l.ToArray()
}
$uydurmaRapor = New-Object System.Collections.Generic.List[object]
foreach($u in $UYDURMA){
  if($uydurmaSay[$u.ad] -le 0){ continue }
  $uydurmaRapor.Add([ordered]@{ terim=$u.ad; soru=$uydurmaSay[$u.ad]; dogrusu=$u.dogrusu; ornek_id=@($uydurmaOrnek[$u.ad]) })
}
$eskiRapor = New-Object System.Collections.Generic.List[object]
foreach($e in $ESKI){
  if($eskiSay[$e.ad] -le 0 -and $eskiHapSay[$e.ad] -le 0){ continue }
  $eskiRapor.Add([ordered]@{ terim=$e.ad; toplam_soru=$eskiSay[$e.ad]; KEHRIBAR_KARTTA=$eskiHapSay[$e.ad]; dogrusu=$e.dogrusu })
}
$kisiTop = ($kisiSay.Values | Measure-Object -Sum).Sum
$sirketTop = ($sirketSay.Values | Measure-Object -Sum).Sum

RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'; mod='OLCUM (0 USD, yazma yok)'
  kasa=$kasa.Count; kehribar_karti_olan=$hapliSoru
  bir_uydurma_terim=$uydurmaRapor.ToArray()
  iki_eski_terim=$eskiRapor.ToArray()
  ikib_jargon_yogun=[ordered]@{ soru=$jargonYogunSoru; yuzde=[Math]::Round(100.0*$jargonYogunSoru/[Math]::Max(1,$kasa.Count),2); ornek_id=@($jargonOrnek); olcut='bir cumlede 2+ teknik terim + gunluk-karsilik isareti yok (#12-C)' }
  uc_senaryo_isimleri=[ordered]@{
    farkli_kisi_adi=$kisiSay.Count; toplam_kisi_gecis=$kisiTop
    farkli_sirket_adi=$sirketSay.Count; toplam_sirket_gecis=$sirketTop
    en_sik_kisi=(Liste $kisiSay 15)
    en_sik_sirket=(Liste $sirketSay 15)
  }
  not='Yalniz OLCUM - kasaya dokunulmadi. "KEHRIBAR_KARTTA" sutunu onemlidir: eski terim her yerde kotudur ama ogrencinin EZBERLEYECEGI kartta olmasi en kotusudur.'
})
Write-Host "`n=== DIL KUSURU TARAMASI ==="
Write-Host "  1) UYDURMA TERIM:"
foreach($r in $uydurmaRapor){ Write-Host ("     {0,-26} {1,5} soru  -> dogrusu: {2}" -f $r.terim, $r.soru, $r.dogrusu) }
Write-Host "  2) ESKI TERIM (toplam / kehribar kartta):"
foreach($r in $eskiRapor){ Write-Host ("     {0,-26} {1,5} / {2,4}  -> dogrusu: {3}" -f $r.terim, $r.toplam_soru, $r.KEHRIBAR_KARTTA, $r.dogrusu) }
Write-Host ("  3) SENARYO ADI: {0} farkli kisi / {1} farkli sirket" -f $kisiSay.Count, $sirketSay.Count)

# ---- -yaz MODU (07.08, v2): dil kusurlulari onarim havuzuna isaretle ----
# Ilk kosunun dersi: kasadaki notlarin cogu ESKI DURUM notu (gm-onay vb.) -
# "dolu notu atla" kurali 3.584 kaydin hepsini atladi. v2: not EKLENIR
# (' | dil-kusuru: ...'), ezilmez; kapsam SIMDILIK yalniz jargon-yogun
# (eski-terim hacmi 245+ soru = onarim partisini buyutur -> UCRETLI genisleme,
# Cem onayina sunulacak; rakamlar sabah raporunda).
if($yaz){
  # 07.08 AG DERSI #3: modem, supabase.co'ya SERI halinde acilan YENI TLS
  # baglantilarini kesiyor (tek istek OK, seri curl 000 / IRM 400). Cozum:
  # TEK HttpClient (keep-alive) uzerinden butun PATCH'ler - tek baglanti.
  Add-Type -AssemblyName System.Net.Http
  $hc = New-Object System.Net.Http.HttpClient
  $hc.Timeout = [TimeSpan]::FromSeconds(60)
  $hc.DefaultRequestHeaders.Add('apikey', $env:SUPABASE_SERVICE_KEY)
  # 07.08 KOK (runner 158 hata): Authorization eksikti -> istek anon sayilip
  # RLS PATCH'i bloke ediyordu. $SB ile ayni kosul: JWT tipi anahtara Bearer.
  if($env:SUPABASE_SERVICE_KEY -like 'eyJ*'){ $hc.DefaultRequestHeaders.Add('Authorization', "Bearer $($env:SUPABASE_SERVICE_KEY)") }
  $hc.DefaultRequestHeaders.Add('Prefer', 'return=minimal')
  $hc.DefaultRequestHeaders.UserAgent.ParseAdd('mevzuat-radar-robot/1.0')
  $HW = $SB + @{ Prefer='return=minimal'; 'Content-Type'='application/json' }
  $notHarita = @{}
  foreach($s in $kasa){ $notHarita["$($s.id)"] = "$($s.yayin_notu)" }
  Write-Host ("  [debug] yazHedef toplam: {0}" -f $yazHedef.Count)
  $yazHedef | Group-Object kusur | ForEach-Object { Write-Host ("  [debug] kusur '{0}': {1}" -f $_.Name, $_.Count) }
  $tekil = @{}
  foreach($h in $yazHedef){ if($h.kusur -like 'jargon*' -and -not $tekil.ContainsKey($h.id)){ $tekil[$h.id]=$h } }
  Write-Host ("  [debug] tekil jargon: {0}" -f $tekil.Count)
  $isaret=0; $zatenVar=0; $hataSay=0
  foreach($h in $tekil.Values){
    $eskiNot = $notHarita[$h.id]
    if($eskiNot -match 'dil-kusuru'){ $zatenVar++; continue }
    $yeniNot = if($eskiNot.Trim()){ $eskiNot + ' | dil-kusuru: ' + $h.kusur } else { 'dil-kusuru 07.08: ' + $h.kusur + ' - onarim bekliyor' }
    $gov = ConvertTo-Json -Compress -InputObject @{ yayin=$false; yayin_notu=$yeniNot }
    # 07.08 AG DERSI: PS IRM PATCH'i bu agda modem tarafindan 'SessionTimeout'
    # sayfasiyla kesiliyor (tek istek gecer, script serisi gecmez); curl.exe
    # ayni istegi sorunsuz atiyor (204). PATCH kanali curl'e tasindi.
    # tek HttpClient baglantisi uzerinden PATCH (ag dersi #3); 500ms fren,
    # basarisizda 5 sn soguma + bir tekrar
    $kod = 0; $hataDetay = ''
    for($dn2=1; $dn2 -le 2; $dn2++){
      try {
        $istek = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::new('PATCH')), ("$U`?id=eq." + $h.id)
        $istek.Content = New-Object System.Net.Http.StringContent ($gov, [Text.Encoding]::UTF8, 'application/json')
        $cvp = $hc.SendAsync($istek).GetAwaiter().GetResult()
        $kod = [int]$cvp.StatusCode
        # 07.08 KOR-KALMA: 204 disi cevabin GOVDESI okunur - runner loglari
        # kilitliyken sebep ancak rapora yazilirsa gorulur (158-hata bilmecesi).
        if($kod -ne 204){ try { $hataDetay = $cvp.Content.ReadAsStringAsync().GetAwaiter().GetResult() } catch {} }
        $cvp.Dispose(); $istek.Dispose()
      } catch { $kod = -1; $hataDetay = $_.Exception.Message }
      if($kod -eq 204){ break }
      Start-Sleep -Seconds 5
    }
    if($kod -eq 204){ $isaret++ }
    else {
      $hataSay++
      if(-not $script:hataOrnekleri){ $script:hataOrnekleri = New-Object System.Collections.Generic.List[object] }
      if($script:hataOrnekleri.Count -lt 3){
        $script:hataOrnekleri.Add([ordered]@{ id=$h.id; kod=$kod; cevap=("$hataDetay".Substring(0,[Math]::Min(220,"$hataDetay".Length))) })
      }
      if($hataSay -le 3){ Write-Host ("  [debug] PATCH HATA #{0} ({1}): kod {2} | {3}" -f $hataSay, $h.id, $kod, $hataDetay) }
    }
    Start-Sleep -Milliseconds 500
  }
  Write-Host ("  -yaz v3: {0} isaretlendi, {1} zaten isaretli, {2} hata" -f $isaret, $zatenVar, $hataSay)
  try {
    $rj = Get-Content $raporYol -Raw -Encoding UTF8 | ConvertFrom-Json
    $rj | Add-Member -NotePropertyName yaz_metrik -NotePropertyValue ([ordered]@{ isaretlenen=$isaret; zatenVar=$zatenVar; hata=$hataSay; ornek_hatalar=$(if($script:hataOrnekleri){ $script:hataOrnekleri.ToArray() } else { @() }); kanal='HttpClient tek-baglanti'; zaman=(Get-Date -Format 'dd.MM.yyyy HH:mm') }) -Force
    [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $rj -Depth 6), (New-Object Text.UTF8Encoding($false)))
  } catch {}
  $hc.Dispose()
}
