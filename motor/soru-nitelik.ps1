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
$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 80000; $o+=1000){
  $r = @(($hc.GetStringAsync("$U`?select=id,sinav,ders,konu,soru,siklar,dogru,aciklama,tablo,yevmiye&order=id&limit=1000&offset=$o").GetAwaiter().GetResult() | ConvertFrom-Json) | ForEach-Object { $_ })
  if(-not $r.Count){ break }
  foreach($x in $r){ $kasa.Add($x) }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

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
      $m = $reSayi.Match($v)
      if($m.Success -and $v.Length -le 40){ $sayisalSik += [pscustomobject]@{ h=$h; v=(TrSayi $m.Value) } }
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

  $z = if($puan -le 1){ 1 } elseif($puan -le 3){ 2 } else { 3 }
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
