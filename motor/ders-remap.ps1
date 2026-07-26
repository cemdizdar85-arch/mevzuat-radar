# ============================================================================
#  DERS REMAP — kasadaki SGS sorularinin ders etiketini RESMI sinav kirilimina
#  oturtur. Kaynak: TURMOB YKK 17.07.2020/22 + TESMER Uygulama Yonergesi 2024 m.6.2:
#  GK-Yetenek 20 (Turkce 7, Matematik 8, Inkilap 5) + Yabanci Dil 10 + Alan 100
#  (Finansal Muhasebe 26, Maliyet Muh 8, Mali Tablolar Analizi 8, Denetim 16,
#   Ekonomi 6, Maliye 6, bes hukuk dali 6'sar).
#  Bizim kitapcik-analizi kaba etiketleri (Muhasebe 58 tek yigin, Hukuk 30 tek
#  yigin, GK icinde Turkce+Inkilap karisik) alt derslere ayrilir.
#  SOZLUK TABANLI - API'siz, ucretsiz, deterministik; konu adindan derse esler.
#  Eslesmeyen Hukuk sorusu 'Hukuk'ta kalir (yanlis tasima yok); Muhasebe ve GK'da
#  guvenli catch-all var (asagida gerekceli). SMMM dersleri zaten resmi listeyle
#  birebir - onlara DOKUNULMAZ. ENV: SUPABASE_SERVICE_KEY zorunlu.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$enc  = New-Object Text.UTF8Encoding($false)
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SERVICE key yok - atlandi."; exit 0 }
$H = @{ apikey=$KEY; Authorization="Bearer $KEY" }

function Fold($s){
  $t = "$s".ToLowerInvariant().Trim()
  $t = $t -replace [char]0x00E7,'c' -replace [char]0x011F,'g' -replace [char]0x0131,'i' -replace [char]0x00F6,'o' -replace [char]0x015F,'s' -replace [char]0x00FC,'u' -replace [char]0x0130,'i'
  return $t
}

# --- Muhasebe (58'lik yigin) -> 4 resmi ders. Sira ONEMLI: Denetim/Maliyet/Analiz
#     anahtar-kelime zengini, once onlar; kalan catch-all ile Finansal Muhasebe
#     (resmi tabloda da en buyuk blok 26 soru + TMS oradadir).
$MUH_ESLEME = @(
  @{ ders='Denetim';              desen='bds|denetim|denetci|orneklem|teyit|calisma kagit|kanit|gorus|kacinma|sartli|hile|onemlilik|ic kontrol|analitik|bagimsizlik|kalite kontrol|musteri kabul|yanlislik' },
  @{ ders='Maliyet Muhasebesi';   desen='maliyet|basabas|katki payi|gug|safha|siparis|birlesik uru|yan urun|standart maliy|direkt iscilik|direkt ilk madde|7/a|7/b|uretim gider|esdeger|dagitim anahtar|fire|kapasite sapma' },
  @{ ders='Mali Tablolar Analizi';desen='analiz|dikey yuzde|yatay|trend|oran(lar)?[ |]|likidite|cari oran|asit|nakit orani|kaldirac|devir hiz|calisma sermayesi|karlilik oran|finansman oran|deflat' },
  @{ ders='Finansal Muhasebe';    desen='.' }   # catch-all: kalan muhasebe = Finansal Muhasebe (TMS/TFRS/kayit/donem sonu/THP hepsi bu blokta)
)
# --- Hukuk (30'luk yigin) -> 5 resmi dal. Catch-all YOK: eslesmeyen 'Hukuk'ta kalir.
$HUK_ESLEME = @(
  @{ ders='Meslek Hukuku';                desen='meslek|3568|smmm|ymm|yeminli mali musavir|ruhsat|disiplin|etik|oda(lar)? |tesmer|staj|reklam yasag|tabela|buro edinme|ucret tarifes|mucadele kurulu' },
  @{ ders='Is ve Sosyal Guvenlik Hukuku'; desen='4857|is kanunu|is sozlesme|is iliskisi|kidem|ihbar|fesih|calisma sure|fazla calisma|yillik izin|sendika|grev|lokavt|toplu is|tesmil|5510|sigorta|sgk|prim|issizlik|analik|malul|yaslilik|emekli|olum aylig|goremezlik|fiili hizmet|istihdam buro|is kazasi|6331|isci|isveren|ucret hukum|ucretin ise' },
  @{ ders='Vergi Hukuku';                 desen='vuk|213|vergi|tarh|teblig|tahakkuk|tahsil|6183|amme alac|gvk|gelir vergi|kvk|kurumlar vergi|kdv|katma deger|otv|damga|beyanname|matrah|istisna|muafiyet|mukellef|uzlasma|pismanlik|idari yargi|vergi mahkeme|deger artis|emsal kira' },
  @{ ders='Ticaret Hukuku';               desen='ttk|6102|ticar|tacir|sirket|anonim|limited|kollektif|komandit|cek|bono|police|kiymetli evrak|ciro|kambiyo|tescil|unvan|sermaye art|sermaye azalt|bedelsiz pay|genel kurul|yonetim kurulu' },
  @{ ders='Borclar Hukuku';               desen='tbk|6098|borc|sozlesme|ibra|takas|yenileme|sebepsiz zengin|haksiz fiil|hayvan|yapi maliki|adam calistiran|kusursuz|tehlike sorumlulug|zamanasimi|temerrut|muteselsil|kefalet|genel islem|irade|hata|hile(?= ile)|gabin|temsil|oneri|icap|tek tarafli|yazili sekil|imza sart|kesin hukumsuz' }
)
# --- GK (Turkce+Inkilap karisik) -> Inkilap desenleri; kalan Turkce
#     (resmi tabloda GK yalniz bu iki dersten olusur, catch-all guvenli).
$INKILAP_DESEN = 'inkilap|ataturk|kurtulus|antlasma|lozan|sevr|mudanya|tbmm|cumhuriyet|milli mucadele|misak|erzurum|sivas|amasya|sakarya|dumlupinar|saltanat|hilafet|halifelik|tevhid|medeni kanun|harf devrimi|sapka|tekke|cephe'

# 1) kasayi sayfali cek (limit/offset — Range basligi PS7 HttpClient'ta sorunlu)
$hepsi = @(); $sayfa = 0
while($true){
  $u = "$SB_URL/rest/v1/soru_havuzu?select=id,sinav,ders,konu&order=id&limit=1000&offset=$($sayfa*1000)"
  $r = Invoke-RestMethod -Uri $u -Headers $H -TimeoutSec 60
  $hepsi += @($r)
  if(@($r).Count -lt 1000){ break }
  $sayfa++; if($sayfa -gt 60){ break }
}
Write-Host ("Kasa: {0} soru" -f $hepsi.Count)

function HedefDers($ders, $konu){
  $fd = Fold $ders; $fk = Fold $konu
  if($fd -eq 'muhasebe'){
    foreach($e in $MUH_ESLEME){ if($fk -match $e.desen){ return $e.ders } }
    return 'Finansal Muhasebe'
  }
  if($fd -eq 'hukuk'){
    foreach($e in $HUK_ESLEME){ if($fk -match $e.desen){ return $e.ders } }
    return $null
  }
  if($fd -eq 'genel kultur-genel yetenek'){
    if($fk -match $INKILAP_DESEN){ return 'Ataturk Ilke ve Inkilap Tarihi' }
    return 'Turkce'
  }
  if($fd -eq 'matematik-istatistik'){ return 'Matematik' }
  return $null
}

# 2) remap hesapla (yalniz SGS; SMMM'e dokunma)
$updates = New-Object System.Collections.Generic.List[object]
$sayim = @{}
foreach($s in $hepsi){
  if("$($s.sinav)" -ne 'SGS'){ continue }
  $yeni = HedefDers "$($s.ders)" "$($s.konu)"
  if($yeni -and $yeni -ne "$($s.ders)"){
    $updates.Add([ordered]@{ id=$s.id; ders=$yeni })
    $sayim[$yeni] = 1 + [int]$sayim[$yeni]
  }
}
Write-Host ("Remap edilecek: {0}" -f $updates.Count)
$sayim.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { Write-Host ("  {0}: {1}" -f $_.Key, $_.Value) }

# 3) ders basina PATCH (gercek UPDATE — kismi kolonlu upsert NOT NULL kolonlara
#    takilir: ON CONFLICT guncellemeye donmeden once eksik satir INSERT diye
#    denetlenir, 23502 firlatir. 26.07 kosusu dersi.)
$y=0
if($updates.Count -gt 0){
  $HP = @{ apikey=$KEY; Authorization="Bearer $KEY"; Prefer="return=minimal" }
  $gruplar = $updates | Group-Object { $_.ders }
  foreach($gr in $gruplar){
    $ids = @($gr.Group | ForEach-Object { $_.id })
    $govde = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @{ ders = $gr.Name } -Compress))
    for($i=0; $i -lt $ids.Count; $i += 200){
      $dilim = @($ids[$i..([Math]::Min($i+199, $ids.Count-1))])
      $filtre = "id=in.(" + (($dilim | ForEach-Object { '"' + $_ + '"' }) -join ',') + ")"
      Invoke-RestMethod -Method Patch -Uri "$SB_URL/rest/v1/soru_havuzu?$filtre" -Headers $HP `
        -ContentType "application/json; charset=utf-8" -Body $govde -TimeoutSec 120 | Out-Null
      $y += $dilim.Count
    }
    Write-Host ("PATCH {0}: {1} soru" -f $gr.Name, $ids.Count)
  }
}

# 4) rapor
$ozet = [ordered]@{ calisti=(Get-Date -Format "dd.MM.yyyy HH:mm"); taranan=$hepsi.Count; remap=$updates.Count; dagilim=$sayim }
$rp = Join-Path $kok "veri/ders-remap-rapor.json"
$g2=@(); if(Test-Path $rp){ try{ $g2=@(Get-Content $rp -Raw -Encoding UTF8 | ConvertFrom-Json) }catch{} }
$g2 += $ozet
[IO.File]::WriteAllText($rp, (ConvertTo-Json -InputObject $g2 -Depth 5), $enc)
Write-Host ("TAMAM: {0} soru resmi derse tasindi." -f $y)
exit 0
