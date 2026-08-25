# ============================================================================
#  SORU NITELIGI — 07.08.2026 (Cem: "iki bedava isi yapalim")
#
#  IKI EKSIK KOLONU DETERMINISTIK OLARAK URETIR (AI YOK, 0 USD):
#
#  1) BENZER_GRUP — "ayni kurali olcen sorular". deneme.html'de benzerlik
#     kapisi YAZILMIS ama dayandigi kolon KASADA YOKTU; kapi fiilen hic
#     calismiyordu (07.08 bulgusu: aday ayni kurali ust uste cozebiliyor).
#     Imza = ders | konu | DOGRU SIKKIN normalize metni. Ayni konuda ayni
#     cevabi veren sorular ayni gruptur. TEK sorulu gruplar yazilmaz.
#
#  2) ZORLUK — kolay/orta/zor. Kasada zorluk kolonu HIC YOKTU; adaptif
#     motorun on sarti buydu. Puan olculebilir sinyallerden gelir:
#       - soru kokundeki sayi adedi (veri yuku)
#       - dogru aciklamadaki islem adedi (hesap adimi)
#       - yevmiye/tablo var mi
#       - SIK YAKINLIGI: sayisal siklarda en yakin celdiricinin dogruya
#         goreli uzakligi (yakin celdirici = zor soru)
#       - soru kokunun kelime sayisi
#     Puan 0-1 kolay(1) · 2-3 orta(2) · 4+ zor(3).
#     DURUST SINIR: bu bir YAPI zorlugu tahminidir, gercek zorluk degil.
#     Gercek zorluk canli deneme cevap istatistigi birikince kalibre edilir
#     (uydurma olasilik yasagi: siteye "zor" derken bu ayrim yazilir).
#
#  CIKTI: veri/soru-nitelik.json (yalniz id -> {g,z}; SORU ICERIGI YOK,
#  public repoya sizinti olmaz) + veri/soru-nitelik-raporu.json (sayilar).
#  -yaz verilirse kasadaki benzer_grup/zorluk kolonlarina da yazar
#  (kolonlar yoksa atlar ve raporda soyler). YAZMA RUNNER ISI (ag dersi #3).
# ============================================================================
param([switch]$yaz)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$raporYol = Join-Path $kok 'veri\soru-nitelik-raporu.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 6), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

Add-Type -AssemblyName System.Net.Http
$hc = New-Object System.Net.Http.HttpClient
$hc.Timeout = [TimeSpan]::FromSeconds(180)
$hc.DefaultRequestHeaders.Add('apikey', $env:SUPABASE_SERVICE_KEY)
$hc.DefaultRequestHeaders.Add('Authorization', "Bearer $($env:SUPABASE_SERVICE_KEY)")
$hc.DefaultRequestHeaders.UserAgent.ParseAdd('mevzuat-radar-robot/1.0')

# --- kasa (PS5.1 dizi tuzagi: ForEach-Object ile duzlestir)
# 24.08 ONARIMI - bu betik 20.08'den beri OLUYDU (500/57014 statement timeout).
# IKI SEBEP UST USTE bindi, ikisi de kapatildi:
#   (1) OFFSET sayfalamasi: offset buyudukce Postgres o kadar satiri atlayarak
#       tarar (yayin-kapisi.ps1 19.08 dersi). -> anahtar-takipli (id=gt.sonId).
#   (2) SAYFA AGIRLIGI: bu select `aciklama`yi da cekiyor; sik basina ayri
#       ogretici metin oldugu icin 1000 satir ~2,7 MB ve OLCULDU: 6,9 saniye,
#       sunucunun 8 sn'lik statement_timeout sinirinin DIBINDE. 500 satir 0,96 sn.
#       -> sayfa 500. (Olcum 24.08: 1000=6866ms · 500=958ms · 250=502ms)
# DERS: hafif select ile agir select ayni sayfa boyunu kaldirmaz.
$SAYFA = 500
$kasa = New-Object System.Collections.Generic.List[object]
$sonId = ''
for($sayfa=0; $sayfa -lt 200; $sayfa++){
  $filtre = if($sonId){ "&id=gt." + [uri]::EscapeDataString($sonId) } else { "" }
  $r = @(($hc.GetStringAsync("$U`?select=id,sinav,ders,konu,soru,siklar,dogru,aciklama,tablo,yevmiye&order=id&limit=$SAYFA$filtre").GetAwaiter().GetResult() | ConvertFrom-Json) | ForEach-Object { $_ })
  if(-not $r.Count){ break }
  foreach($x in $r){ $kasa.Add($x) }
  $sonId = "$(@($r)[-1].id)"
  if($r.Count -lt $SAYFA){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)
if($kasa.Count -lt 1000){ throw "Kasa kucuk gorundu ($($kasa.Count)) - sayfalama kirilmis olabilir; eksik kasa uzerinden benzer_grup/zorluk YAZILMAZ." }

function Normalize([string]$t){
  $t = "$t".ToLowerInvariant()
  $t = $t -replace '[^\p{L}\p{Nd}]+',' '
  return ($t.Trim() -replace '\s+',' ')
}
function TrSayi([string]$s){
  $s = "$s".Trim().TrimStart('%').Trim()
  if($s -eq ''){ return $null }
  $s = ($s -replace '\.','') -replace ',','.'
  $d = 0.0
  if([double]::TryParse($s, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)){ return $d }
  return $null
}
function Kisalt([string]$s){
  $sha = [Security.Cryptography.SHA256]::Create()
  return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($s))) -replace '-','').Substring(0,10).ToLowerInvariant()
}

# ---------- 1) BENZER GRUP ----------
$imzaKova = @{}
foreach($s in $kasa){
  $d = "$($s.dogru)".Trim().ToUpperInvariant()
  if($d -notmatch '^[A-E]$'){ continue }
  $sik = $null; try { $sik = $s.siklar.$d } catch {}
  $sikN = Normalize "$sik"
  if($sikN.Length -lt 2){ continue }
  if($sikN.Length -gt 60){ $sikN = $sikN.Substring(0,60) }
  $imza = (Normalize "$($s.ders)") + '|' + (Normalize "$($s.konu)") + '|' + $sikN
  if(-not $imzaKova.ContainsKey($imza)){ $imzaKova[$imza] = New-Object System.Collections.Generic.List[string] }
  $imzaKova[$imza].Add("$($s.id)")
}
$grupHarita = @{}
$grupSayisi = 0; $grupluSoru = 0; $enBuyuk = 0; $enBuyukImza = ''
foreach($kv in $imzaKova.GetEnumerator()){
  if($kv.Value.Count -lt 2){ continue }
  $grupSayisi++
  $gk = 'g' + (Kisalt $kv.Key)
  foreach($id in $kv.Value){ $grupHarita[$id] = $gk }
  $grupluSoru += $kv.Value.Count
  if($kv.Value.Count -gt $enBuyuk){ $enBuyuk = $kv.Value.Count; $enBuyukImza = $kv.Key }
}
Write-Host ("BENZER GRUP: {0} grup / {1} soru (en buyuk grup {2} soru)" -f $grupSayisi, $grupluSoru, $enBuyuk)

# ---------- 2) ZORLUK ----------
$reSayi  = [regex]'\d[\d\.]*(?:,\d+)?'
$reIslem = [regex]'[+\-−x×X*/÷]\s*%?\d'
$zorlukHarita = @{}
$dagilim = @{ 1=0; 2=0; 3=0 }
$ornekler = New-Object System.Collections.Generic.List[object]
foreach($s in $kasa){
  $soruM = "$($s.soru)"
  $puan = 0
  # (a) veri yuku
  $sayiAdet = $reSayi.Matches($soruM).Count
  if($sayiAdet -ge 6){ $puan += 2 } elseif($sayiAdet -ge 3){ $puan += 1 }
  # (b) hesap adimi (dogru sikkin aciklamasi)
  $d = "$($s.dogru)".Trim().ToUpperInvariant()
  $acik = ''
  if($d -match '^[A-E]$'){ try { $acik = "$($s.aciklama.$d)" } catch {} }
  $islemAdet = $reIslem.Matches($acik).Count
  if($islemAdet -ge 6){ $puan += 2 } elseif($islemAdet -ge 2){ $puan += 1 }
  # (c) yevmiye/tablo
  if(("$($s.yevmiye)".Trim()) -or ("$($s.tablo)".Trim())){ $puan += 1 }
  # (d) SIK YAKINLIGI - sayisal siklarda en yakin celdirici
  $sayisalSik = @()
  if($d -match '^[A-E]$'){
    foreach($h in 'A','B','C','D','E'){
      $v = $null; try { $v = "$($s.siklar.$h)" } catch {}
      if(-not $v){ continue }
      # 08.08 (2. onarim): sinir 40 -> 90 karakter. Iki rakam + aciklayici kelime
      # tasiyan sayisal siklar ("90 milyar TL fazla; 150 milyar TL operasyonel
      # acik" = 50 karakter) 40 sinirina takilip ELENIYORDU; boylece $sayisalSik
      # 4'e ulasmiyor ve celdirici yakinligi sinyali HIC calismiyordu.
      $m = $reSayi.Match($v)
      if($m.Success -and $v.Length -le 90){ $sayisalSik += [pscustomobject]@{ h=$h; v=(TrSayi $m.Value) } }
    }
  }
  $yakinlik = $null
  if(@($sayisalSik).Count -ge 4){
    $dv = @($sayisalSik | Where-Object { $_.h -eq $d })
    if($dv.Count -and $null -ne $dv[0].v -and $dv[0].v -ne 0){
      $dogruV = [double]$dv[0].v
      $farklar = @($sayisalSik | Where-Object { $_.h -ne $d -and $null -ne $_.v } | ForEach-Object { [math]::Abs(([double]$_.v) - $dogruV) / [math]::Abs($dogruV) })
      if($farklar.Count){
        $yakinlik = ($farklar | Measure-Object -Minimum).Minimum
        if($yakinlik -lt 0.03){ $puan += 2 } elseif($yakinlik -lt 0.08){ $puan += 1 }
      }
    }
  }
  # (e) uzun soru kokü
  $kelime = @($soruM -split '\s+' | Where-Object { $_ }).Count
  if($kelime -ge 90){ $puan += 1 }

  # ============================================================================
  # 08.08 CETVEL DUZELTMESI (Cem: "sinavi neden kolay yapmisiz?")
  # OLCUM: sayisal olmayan derslerde zorluk dagilimi Yabanci Dil %100 kolay,
  # Ticaret/Vergi %99, Borclar/Maliye %98 cikti. Sebep icerik degil CETVELDI:
  # (a)-(d) sinyalleri SAYIYA dayaniyor; sayi icermeyen bir hukuk/dil sorusu
  # en fazla 1 puan alabiliyor, yani "zor" damgasi almasi MATEMATIKSEL OLARAK
  # IMKANSIZDI. Asagidaki sinyaller sayisal olmayan zorlugu olcer.
  # ============================================================================
  $tumMetin = $soruM
  if($d -match '^[A-E]$'){ foreach($h in 'A','B','C','D','E'){ try { $tumMetin += ' ' + "$($s.siklar.$h)" } catch {} } }

  # (f) OLUMSUZ KOK: "hangisi YANLISTIR / degildir / soylenemez" - aday cift
  #     olumsuz kurmak zorunda kalir; olcum literaturunde en guclu zorluk
  #     isaretlerinden biridir.
  if($soruM -imatch '(yanl[ıi][şs]t[ıi]r|de[ğg]ildir|s[öo]ylenemez|olamaz|yer almaz|bulunmaz|gerekmez)'){ $puan += 1 }

  # (g) COKLU ONERME: "I, II, III ... hangileri" - birden fazla yargiyi ayri
  #     ayri degerlendirip birlestirmek gerekir.
  #     08.08 (2. onarim): sabit +2 yerine ONERME SAYISIYLA olceklendi. Dort
  #     onermeyi tek tek yargilamak, ikisini yargilamaktan olculebilir sekilde
  #     daha agirdir; eski hali ikisini de ayni puanliyordu.
  $onermeAdet = ([regex]::Matches($soruM, '(?m)^\s*(I{1,3}V?|IV|VI?)\s*[\.\)]\s')).Count
  if($onermeAdet -ge 4){ $puan += 3 }
  elseif($onermeAdet -eq 3){ $puan += 2 }
  elseif($onermeAdet -eq 2){ $puan += 1 }
  elseif($soruM -imatch '\bhangileri\b'){ $puan += 1 }

  # (h) ISTISNA/SART YOGUNLUGU: kural + istisna ayrimi gerektiren kokler.
  $istisna = ([regex]::Matches($tumMetin, '(?i)(ancak|istisna|sakl[ıi]d[ıi]r|d[ıi][şs][ıi]nda|hari[çc]|[şs]art[ıi]yla|ko[şs]uluyla)')).Count
  if($istisna -ge 4){ $puan += 2 } elseif($istisna -ge 2){ $puan += 1 }

  # (i) UZUN VE YAKIN SIKLAR: siklarin ortalama uzunlugu buyukse aday her
  #     sikki ayri ayri okuyup karsilastirmak zorundadir.
  $sikUz = @()
  if($d -match '^[A-E]$'){ foreach($h in 'A','B','C','D','E'){ try { $v="$($s.siklar.$h)"; if($v){ $sikUz += @($v -split '\s+' | Where-Object { $_ }).Count } } catch {} } }
  if($sikUz.Count -ge 4){
    $ortSik = ($sikUz | Measure-Object -Average).Average
    if($ortSik -ge 18){ $puan += 2 } elseif($ortSik -ge 10){ $puan += 1 }
  }

  # (j) SENARYO KOKU: olay anlatip hukuk uygulatan sorular, duz tanim
  #     sorularindan zordur. Isaret: kisi/sirket adi + fiil zinciri.
  #     08.08 (2. onarim): esik 45 -> 35 kelime ve tetikleyici liste genisletildi.
  #     Sayisal senaryo kokleri DOGASI GEREGI kisadir ("...Buna gore ulkenin
  #     birincil dengesi ile operasyonel acigi nedir?" = 39 kelime) ve 45
  #     esigine takiliyordu; oysa hesap yuku tasiyorlar.
  if($kelime -ge 35 -and $soruM -imatch '(buna g[öo]re|bu duruma? (g[öo]re|iliskin|ilgili)|s[öo]z konusu|bu olayda|nasil (degisir|adlandirilir|hesaplanir)|kac (TL|birim))'){ $puan += 1 }

  # ==========================================================================
  # 08.08 IKINCI CETVEL ONARIMI (Cem: "CETVELI ONAR")
  # OLCUM: el yazimi 30 ORTA/ZOR hedefli sorunun yarisi KOLAY dustu. Sebep
  # tek tek soktuldu: (a)(b)(d)(e)(i) sinyallerinin BESI DE aslinda HACIM
  # olcuyor. Ornek - "operasyonel acik" sorusu uc adimli hesap istiyor ama
  # siklari kisa sayisal ifadeler oldugu icin (d) ve (i) sifir, kok 39 kelime
  # oldugu icin (j) sifir; toplam 2 puan = KOLAY. Cetvel ZORLUGU degil
  # UZUNLUGU odullendiriyordu. Asagidaki iki sinyal hacimden BAGIMSIZDIR.
  # ==========================================================================

  # (k) HESAP ZINCIRI: dogru sikkin aciklamasinda kac ARA SONUC uretiliyor.
  #     Cok adimli hesap, tek adimlidan olculebilir sekilde zordur ve bu,
  #     sorunun ya da siklarin uzunlugundan tamamen bagimsizdir. Esitlik
  #     isareti her hesaplanmis ara sonucu isaretler.
  $zincir = ([regex]::Matches($acik, '=')).Count
  if($zincir -ge 5){ $puan += 2 } elseif($zincir -ge 3){ $puan += 1 }

  # (l) AYIRT ETME KOKU: iki kavrami/kalemi birbirinden ayirmayi ya da ikisini
  #     BIRLIKTE dogru vermeyi isteyen sorular, tek kavram hatirlatan
  #     sorulardan zordur (aday iki ekseni ayni anda tutmak zorundadir).
  if($soruM -imatch '(s[ıi]ras[ıi]yla|ayr[ıi]m[ıi]|birlikte do[ğg]ru|hangisinde do[ğg]ru|farkl?[ıi]l?[ıi]k|ile .{0,30} aras[ıi]ndaki)'){ $puan += 1 }

  # 08.08: esikler yeni sinyallerle birlikte yeniden ayarlandi (puan tavani
  # yukseldigi icin eski 1/3 esikleri her seyi "zor" gosterirdi).
  # 2. onarim - ESIK KALIBRASYONU: Ilk denemede esikler yeni sinyallerin
  # TEORIK TAVANINA gore 3 puan yukari cekildi ve dagilim %60 -> %75 kolaya
  # kaydi. Hata suydu: (k) ve (l) sorularin COGUNDA hic atesenmiyor, dolayisiyla
  # kazanc saglamayan her soru bir basamak ASAGI dusuyordu. Dogru kalibrasyon
  # esigi SABIT tutmaktir; boylece yeni sinyal yalnizca HAK EDEN soruyu yukari
  # tasir, digerlerinin puani aynen korunur.
  $z = if($puan -le 2){ 1 } elseif($puan -le 5){ 2 } else { 3 }
  $zorlukHarita["$($s.id)"] = $z
  $dagilim[$z]++
  if($ornekler.Count -lt 12){
    $ornekler.Add([ordered]@{ id="$($s.id)"; ders="$($s.ders)"; zorluk=$z; puan=$puan; sayi=$sayiAdet; islem=$islemAdet; kelime=$kelime; sikYakinlik=$(if($null -ne $yakinlik){ [math]::Round($yakinlik,4) } else { $null }) })
  }
}
Write-Host ("ZORLUK: kolay {0} | orta {1} | zor {2}" -f $dagilim[1], $dagilim[2], $dagilim[3])

# ---------- cikti: id -> {g,z} (ICERIK YOK) ----------
$cikti = @{}
foreach($s in $kasa){
  $id = "$($s.id)"
  $kayit = @{ z = $zorlukHarita[$id] }
  if($grupHarita.ContainsKey($id)){ $kayit['g'] = $grupHarita[$id] }
  $cikti[$id] = $kayit
}
[IO.File]::WriteAllText((Join-Path $kok 'veri\soru-nitelik.json'), (ConvertTo-Json -InputObject $cikti -Depth 4 -Compress), (New-Object Text.UTF8Encoding($false)))

# ---------- kolonlara yazma (istege bagli; kolon yoksa atlar) ----------
$yazilan = 0; $kolonVar = $true; $yazHata = 0
if($yaz){
  $deneme = $kasa[0]
  $gov = ConvertTo-Json -Compress -InputObject @{ zorluk = [int]$zorlukHarita["$($deneme.id)"] }
  $istek = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::new('PATCH')), ("$U`?id=eq." + $deneme.id)
  $istek.Content = New-Object System.Net.Http.StringContent ($gov, [Text.Encoding]::UTF8, 'application/json')
  $istek.Headers.Add('Prefer','return=minimal')
  $cvp = $hc.SendAsync($istek).GetAwaiter().GetResult()
  if([int]$cvp.StatusCode -ne 204){
    $kolonVar = $false
    Write-Host ("KOLON YOK (kod {0}) - SQL calistirilmadan yazilamaz; JSON ciktisi yine de uretildi." -f [int]$cvp.StatusCode)
  }
  $cvp.Dispose(); $istek.Dispose()
  if($kolonVar){
    # 08.08 DERSI (iki kere ogrenildi): tek tek PATCH 30 bin satirda 150 dk
    # surer, workflow tavani 120 dk. TOPLU UPSERT (POST merge-duplicates) ise
    # 23502 verir: PostgREST upsert'i INSERT..ON CONFLICT'tir, INSERT tarafi
    # NOT NULL kolonlari (sinav, ders...) ister; kismi govde gecmez.
    # DOGRU ALET: DEGER BAZLI TOPLU PATCH - ayni degeri paylasan id'ler tek
    # istekte id=in.(...) filtresiyle guncellenir. Zorluk 3 deger, grup ~1.400
    # deger => ~1.450 istek (30.398 yerine).
    function TopluPatch([string]$alan, $deger, [string[]]$idler){
      for($b=0; $b -lt $idler.Count; $b+=300){
        $dilim = $idler[$b..([Math]::Min($b+299, $idler.Count-1))]
        $gov = if($null -eq $deger){ '{"' + $alan + '":null}' } elseif($deger -is [int]){ '{"' + $alan + '":' + $deger + '}' } else { '{"' + $alan + '":"' + $deger + '"}' }
        $ok = $false
        for($dn=1; $dn -le 2 -and -not $ok; $dn++){
          try {
            $i2 = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::new('PATCH')), ($script:U + '?id=in.(' + ($dilim -join ',') + ')')
            $i2.Content = New-Object System.Net.Http.StringContent ($gov, [Text.Encoding]::UTF8, 'application/json')
            $i2.Headers.Add('Prefer','return=minimal')
            $c2 = $script:hc.SendAsync($i2).GetAwaiter().GetResult()
            if([int]$c2.StatusCode -eq 204){ $ok = $true; $script:yazilan += $dilim.Count }
            elseif($script:yazHata -lt 3){ Write-Host ("  PATCH HATA kod {0}: {1}" -f [int]$c2.StatusCode, ($c2.Content.ReadAsStringAsync().GetAwaiter().GetResult())) }
            $c2.Dispose(); $i2.Dispose()
          } catch { if($dn -eq 2 -and $script:yazHata -lt 3){ Write-Host ('  PATCH istisna: ' + $_.Exception.Message) } }
          if(-not $ok){ Start-Sleep -Seconds 3 }
        }
        if(-not $ok){ $script:yazHata += $dilim.Count }
        Start-Sleep -Milliseconds 150
      }
    }
    # zorluk: 3 deger
    foreach($z in 1,2,3){
      $idler = @($zorlukHarita.GetEnumerator() | Where-Object { $_.Value -eq $z } | ForEach-Object { $_.Key })
      Write-Host ("  zorluk={0}: {1} soru" -f $z, $idler.Count)
      TopluPatch 'zorluk' ([int]$z) $idler
    }
    # benzer_grup: grup basina
    $grupTers = @{}
    foreach($kv in $grupHarita.GetEnumerator()){
      if(-not $grupTers.ContainsKey($kv.Value)){ $grupTers[$kv.Value] = New-Object System.Collections.Generic.List[string] }
      $grupTers[$kv.Value].Add($kv.Key)
    }
    $gs=0
    foreach($kv in $grupTers.GetEnumerator()){
      TopluPatch 'benzer_grup' $kv.Key @($kv.Value.ToArray())
      $gs++
      if(($gs % 200) -eq 0){ Write-Host ("  grup yazildi: {0}/{1}" -f $gs, $grupTers.Count) }
    }
  }
}
$hc.Dispose()

RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$(if($yaz){ if($kolonVar){'YAZILDI'}else{'KOLON-YOK'} } else {'OLCUM'})
  kasa=$kasa.Count
  benzer_grup=[ordered]@{ grup=$grupSayisi; gruplu_soru=$grupluSoru; en_buyuk_grup=$enBuyuk; en_buyuk_imza=$enBuyukImza }
  zorluk=[ordered]@{ kolay=$dagilim[1]; orta=$dagilim[2]; zor=$dagilim[3] }
  ornekler=$ornekler.ToArray()
  yazilan=$yazilan; yazma_hatasi=$yazHata
  durust_sinir='Zorluk YAPI tahminidir (veri yuku + hesap adimi + sik yakinligi). Gercek zorluk canli deneme cevap istatistigi birikince kalibre edilecek; siteye "zor" denirken bu ayrim yazilir.'
})
Write-Host 'TAMAM'
