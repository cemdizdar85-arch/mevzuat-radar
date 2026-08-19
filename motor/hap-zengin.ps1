# ============================================================================
#  HAP ZENGINLESTIRME (faz-2) — 4.640 kisa hap icin Haiku parti hatti.
#  (30.07.2026 hazirlik; 1 Agustos'ta emir #17 acilinca kosar.)
#
#  EMIR KAPISI: veri/uretim-emir.json'daki "HAP ZENGINLESTIRME" emri
#  onay=true + damgasiz degilse HICBIR SEY YAPMAZ (para harcayan tek kapi
#  emir dosyasidir). Push/cron bu betigi kossa bile kilitliyken bedava
#  "acik emir yok" cikisi verir.
#
#  AKIS: kasada kisa hap (<90) VE mekanik cikarilamayan sorulari YENIDEN
#  olcer (plan dosyasina degil canli kasaya guvenir - 274 mekanik tamir
#  uygulandiysa liste kendiliginden kuculur) -> Haiku batch gonderir
#  (custom_id = hap_<soruid>) -> PARTI KIMLIGINI ANINDA veri/bekleyen-hap-
#  partileri.json'a yazar (odenmis is asla kaybolmaz) -> sonucu bekler,
#  yetismezse acik notla cikar (-kurtar ile bedava hasat) -> kalite
#  kapilarindan gecenleri upsert eder (yayin alanina DOKUNMAZ).
#
#  KALITE KAPILARI (hasatta): 90-260 karakter · Turkce diakritik VAR
#  (kod noktali olcum - dil kapisi dersi) · yeni "NNNN sayili" atifi yok
#  (soru+gerekce metninde gecmeyen kanun numarasi = red) · eskisiyle ayni
#  degil. Dusen kayit rapora sayilir, kasaya YAZILMAZ.
#
#  MOD: varsayilan = uret+hasat. KURTAR=1 -> yeni parti GONDERMEZ, yalniz
#  bekleyen partileri hasat eder (GET ucretsiz).
#  ENV: SUPABASE_SERVICE_KEY + ANTHROPIC_API_KEY (zorunlu), KURTAR=1 (ops).
# ============================================================================
$ErrorActionPreference = "Stop"
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$AAPI   = "https://api.anthropic.com/v1"
$raporYol = Join-Path $kok "veri/hap-zengin-rapor.json"
$partiYol = Join-Path $kok "veri/bekleyen-hap-partileri.json"

function Rapor($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 5), (New-Object Text.UTF8Encoding($false))) }
trap {
  $govde = ""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $govde = $_.ErrorDetails.Message }  # pwsh7: hata govdesi BURADA (29.07 dersi)
  # 19.08 TAVAN BEKLEMESI: Anthropic aylik tavani (enforced_spend_limit_reached)
  # 1 Eylul'e kadar KALKMAZ ve OpenRouter yedegi Batch API'yi DESTEKLEMEZ -
  # bu robot o gune kadar isini yapamaz. Bilinen ve eylemsiz durum her gun
  # kirmizi yakmasin (her gun kirmizi yanan alarm, bakilmayan alarmdir);
  # rapor gercegi soyler, sabah raporu YENI sorunlara temiz kalir. Emir acik
  # kalir, tavan acilinca kaldigi yerden devam eder.
  if($govde -match 'enforced_spend_limit_reached|monthly API usage threshold'){
    Rapor ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="TAVAN-BEKLEMEDE"
      not="Anthropic aylik tavani dolu (1 Eylul 00:00 UTC'de acilir). Emir acik birakildi; bekleyen odenmis parti varsa o gun once hasat edilir." })
    Write-Host "Anthropic TAVANI dolu - 1 Eylul'e kadar BEKLEMEDE (kirmizi degil, is yapilmadi)."
    exit 0
  }
  Rapor ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="HATA"
    hata="$($_.Exception.Message)"; sunucu=$govde.Substring(0,[Math]::Min(400,$govde.Length)); satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1} | sunucu: {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $govde)
  exit 1
}

# --- 0) EMIR KAPISI ---------------------------------------------------------
$emirDosya = Get-Content (Join-Path $kok "veri/uretim-emir.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$emir = @($emirDosya.emirler | Where-Object { "$($_.emir)" -match 'HAP ZENGINLESTIRME' }) | Select-Object -First 1
if(-not $emir -or $emir.onay -ne $true -or -not [string]::IsNullOrWhiteSpace("$($emir.uygulandi)")){
  Rapor ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="KILITLI"; not="HAP ZENGINLESTIRME emri acik degil (onay=false ya da damgali) - para harcanmadi." })
  Write-Host "Acik emir yok - cikis (0 USD)."; exit 0
}
$SBKEY = "$env:SUPABASE_SERVICE_KEY"; $AKEY = "$env:ANTHROPIC_API_KEY"
if([string]::IsNullOrWhiteSpace($SBKEY) -or [string]::IsNullOrWhiteSpace($AKEY)){
  Rapor ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="ATLANDI"; not="SUPABASE_SERVICE_KEY veya ANTHROPIC_API_KEY yok" })
  Write-Host "Anahtar eksik - cikis."; exit 0
}
$SBH = @{ apikey = $SBKEY; Authorization = "Bearer $SBKEY" }
$AH  = @{ "x-api-key" = $AKEY; "anthropic-version" = "2023-06-01"; "Content-Type" = "application/json" }
# 12.08 cift hat: AWS uclusu ortamdaysa $AAPI ve $AH oradan kurulur (api-hedef.ps1)
try {
  . (Join-Path $PSScriptRoot 'api-hedef.ps1')
  $hedefHZ = Get-ApiHedef
  $AAPI = $hedefHZ.taban + '/v1'
  $AH = @{}; foreach($hk in $hedefHZ.basliklar.Keys){ $AH[$hk] = $hedefHZ.basliklar[$hk] }
  $AH['Content-Type'] = 'application/json'
  $AKEY = $hedefHZ.anahtar
  Write-Host ("Claude hedefi: " + $hedefHZ.ad)
} catch { }   # anahtar yoksa yukaridaki ATLANDI dali zaten calisti
$MODEL = if("$($emir.model)"){ "$($emir.model)" } else { "claude-haiku-4-5-20251001" }
$KURTAR = ("$env:KURTAR" -eq '1')
# 01.08 cift-odeme sigortasi: onceki kosu parti gonderip yazamadan dustuyse
# (odenmis is bekliyor), normal kosu YENI GONDERIM yapmadan once o partileri
# bedava hasat eder. Basarili kosu sonunda dosya bosaltilir (asagida).
if(-not $KURTAR -and (Test-Path $partiYol)){
  try { $bekleyenP = @((Get-Content $partiYol -Raw -Encoding UTF8 | ConvertFrom-Json).partiler) } catch { $bekleyenP = @() }
  if($bekleyenP.Count){ $KURTAR = $true; Write-Host ("Bekleyen {0} odenmis parti bulundu - bu kosu YALNIZ HASAT (yeni gonderim/odeme YOK)." -f $bekleyenP.Count) }
}

# --- yardimcilar ------------------------------------------------------------
$trHarfler = ([char]0x011F,[char]0x00FC,[char]0x015F,[char]0x0131,[char]0x00F6,[char]0x00E7,[char]0x011E,[char]0x00DC,[char]0x015E,[char]0x0130,[char]0x00D6,[char]0x00C7)
function DiakritikVar([string]$s){ return ($s.IndexOfAny($trHarfler) -ge 0) }
$reKanunNo = [regex]'(\d{3,5})\s*say[iı]l[iı]'
$reAk = [regex]'(?:Akılda kalsın|AKILDA KALSIN|Akilda kalsin)\s*:\s*(.+)$'

# --- 1) HEDEF LISTESI: canli kasadan yeniden olc ---------------------------
$hedef = New-Object System.Collections.Generic.List[object]   # {id; soru; dogruMetin; dogruGerekce; eskiHap}
$offset = 0; $sayfa = 1000; $taranan = 0
while($true){
  $u = "$SB_URL/rest/v1/soru_havuzu?select=id,soru,siklar,dogru,aciklama,hap&order=id&limit=$sayfa&offset=$offset"
  $hw = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $SBH -TimeoutSec 120
  $gv = if($hw.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($hw.Content) } else { "$($hw.Content)" }
  $parti = @(); foreach($x in (ConvertFrom-Json $gv)){ $parti += $x }
  if(-not $parti.Count){ break }
  foreach($s in $parti){
    $taranan++
    $hapM = "$($s.hap)"
    if($hapM.Trim().Length -ge 90){ continue }
    # mekanik cikarilabilenler (>=90'lik hazir bolum) bu hatta GIRMEZ - onlar bedava kanaldan dolar
    $mekanik = $false
    if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){
      $m = $reAk.Match("$($p.Value)"); if($m.Success -and $m.Groups[1].Value.Trim().Length -ge 90){ $mekanik = $true; break } } }
    if($mekanik){ continue }
    $dg = ''; if($s.aciklama){ $pd = $s.aciklama.PSObject.Properties["$($s.dogru)"]; if($pd){ $dg = "$($pd.Value)" } }
    $dm = ''; if($s.siklar){ $ps = $s.siklar.PSObject.Properties["$($s.dogru)"]; if($ps){ $dm = "$($ps.Value)" } }
    $hedef.Add([pscustomobject]@{ id="$($s.id)"; soru="$($s.soru)"; dogruMetin=$dm; dogruGerekce=$dg; eskiHap=$hapM })
  }
  $offset += $sayfa
  if($parti.Count -lt $sayfa){ break }
}
if($emir.sinir -gt 0 -and $hedef.Count -gt $emir.sinir){ $hedef = [System.Collections.Generic.List[object]]($hedef | Select-Object -First $emir.sinir) }
Write-Host ("taranan {0} | hedef {1} (sinir {2})" -f $taranan, $hedef.Count, $emir.sinir)
if(-not $hedef.Count -and -not $KURTAR){
  Rapor ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="TAMAM"; not="Hedef kalmadi - kisa hap kalmamis ya da hepsi mekanik kanalda."; taranan=$taranan })
  Write-Host "Hedef yok."; exit 0
}

# --- 2) PARTI: gonder ya da kurtar -----------------------------------------
$batchIdler = @()
if($KURTAR){
  if(Test-Path $partiYol){ $batchIdler = @((Get-Content $partiYol -Raw -Encoding UTF8 | ConvertFrom-Json).partiler) }
  if(-not $batchIdler.Count){ Write-Host "KURTAR: bekleyen parti yok."; exit 0 }
  Write-Host ("KURTAR: {0} parti hasat edilecek (yeni gonderim YOK)." -f $batchIdler.Count)
} else {
  # maliyet on-bildirimi (tasarruf kurali): olcume dayali kaba hesap, loga yazilir
  $inTok = [math]::Round($hedef.Count * 520 / 1000000.0, 2); $outTok = [math]::Round($hedef.Count * 90 / 1000000.0, 2)
  $tahmin = [math]::Round($inTok * 0.5 + $outTok * 2.5, 2)   # Haiku 4.5 batch: 0,5/2,5 USD/M
  Write-Host ("MALIYET ON-BILDIRIMI: ~{0} USD ({1} istek; girdi ~{2}M, cikti ~{3}M token)" -f $tahmin, $hedef.Count, $inTok, $outTok)
  $istekler = New-Object System.Collections.Generic.List[object]
  foreach($t in $hedef){
    $soruKisa = $t.soru; if($soruKisa.Length -gt 700){ $soruKisa = $soruKisa.Substring(0,700) }
    $gerekceKisa = $t.dogruGerekce; if($gerekceKisa.Length -gt 1100){ $gerekceKisa = $gerekceKisa.Substring(0,1100) }
    $istem = "SMMM/SGS sinav sorusunun AKILDA KALSIN notunu yaz. Bu not, sinav gunu hatirlanacak KALICI DERSTIR.`n" +
      "KURALLAR: (1) 90-220 karakter, en fazla iki cumle. (2) Gerekceyle CELISEMEZ - ayni ilkeyi damitir. " +
      "(3) Asagidaki metinlerde GECMEYEN hicbir kanun numarasi/oran/tarih YAZMA. (4) Turkce imla tam (diakritikli). " +
      "(5) Yalnizca JSON dondur: {`"hap`":`"...`"}`n`n" +
      "SORU: " + $soruKisa + "`nDOGRU SIK: " + $t.dogruMetin + "`nGEREKCE: " + $gerekceKisa
    $istekler.Add([ordered]@{ custom_id = "hap_" + $t.id
      params = [ordered]@{ model = $MODEL; max_tokens = 300
        messages = @([ordered]@{ role = "user"; content = $istem }) } })
  }
  $govde = ConvertTo-Json -InputObject ([ordered]@{ requests = [object[]]$istekler }) -Depth 8 -Compress
  $yanit = Invoke-RestMethod -Method Post -Uri "$AAPI/messages/batches" -Headers $AH -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 300
  $batchIdler = @("$($yanit.id)")
  # PARTI KIMLIGI ANINDA DISKE (29.07 dersi: id kaydedilmeyen odenmis parti 39 USD'yi riske atti)
  [IO.File]::WriteAllText($partiYol, (ConvertTo-Json -InputObject ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); partiler=[object[]]$batchIdler; istek=$hedef.Count }) -Depth 3), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("PARTI GONDERILDI: {0} ({1} istek) - kimlik diske yazildi." -f $yanit.id, $hedef.Count)
}

# --- 3) BEKLE + HASAT -------------------------------------------------------
$sonuclar = @{}   # soruId -> yeniHap
foreach($bid in $batchIdler){
  $bekleme = 0
  while($true){
    $d = Invoke-RestMethod -Uri "$AAPI/messages/batches/$bid" -Headers $AH -TimeoutSec 60
    if("$($d.processing_status)" -eq 'ended'){ break }
    $bekleme += 60
    if($bekleme -gt 2400){
      Rapor ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="BEKLEMEDE"
        not="Parti(ler) 40 dakikada bitmedi - is KAYIP DEGIL, kimlikler bekleyen-hap-partileri.json'da. KURTAR=1 ile bedava hasat edilir."; partiler=[object[]]$batchIdler })
      Write-Host "Parti bitmedi - kimlikler kayitli, KURTAR=1 ile hasat."; exit 0
    }
    Start-Sleep -Seconds 60
  }
  $rw = Invoke-WebRequest -UseBasicParsing -Uri "$AAPI/messages/batches/$bid/results" -Headers $AH -TimeoutSec 300
  $metin = if($rw.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($rw.Content) } else { "$($rw.Content)" }
  foreach($satir in ($metin -split "`n")){
    if([string]::IsNullOrWhiteSpace($satir)){ continue }
    $j = ConvertFrom-Json $satir
    if("$($j.result.type)" -ne 'succeeded'){ continue }
    $cid = "$($j.custom_id)"; if(-not $cid.StartsWith('hap_')){ continue }
    $ic = "$($j.result.message.content[0].text)"
    $m = [regex]::Match($ic, '\{[\s\S]*\}')
    if(-not $m.Success){ continue }
    try { $o = ConvertFrom-Json $m.Value } catch { continue }
    $sonuclar[$cid.Substring(4)] = "$($o.hap)".Trim()
  }
}
Write-Host ("hasat: {0} cevap" -f $sonuclar.Count)

# --- 4) KALITE KAPILARI + YAZIM --------------------------------------------
$gecen = New-Object System.Collections.Generic.List[object]
$redK = @{ uzunluk=0; diakritik=0; atif=0; ayni=0 }
$hedefIdx = @{}; foreach($t in $hedef){ $hedefIdx[$t.id] = $t }
foreach($sid in $sonuclar.Keys){
  $yeni = $sonuclar[$sid]; $t = $hedefIdx[$sid]
  if(-not $t){ continue }
  if($yeni.Length -lt 90 -or $yeni.Length -gt 260){ $redK.uzunluk++; continue }
  if(-not (DiakritikVar $yeni)){ $redK.diakritik++; continue }
  $kaynakMetin = "$($t.soru) $($t.dogruGerekce) $($t.dogruMetin)"
  $temiz = $true
  foreach($mm in $reKanunNo.Matches($yeni)){ if(-not $kaynakMetin.Contains($mm.Groups[1].Value)){ $temiz = $false; break } }
  if(-not $temiz){ $redK.atif++; continue }
  if($yeni -eq $t.eskiHap.Trim()){ $redK.ayni++; continue }
  $gecen.Add([pscustomobject]@{ id = $sid; hap = $yeni })
}
Write-Host ("kapilar: gecen {0} | red uzunluk {1} diakritik {2} atif {3} ayni {4}" -f $gecen.Count, $redK.uzunluk, $redK.diakritik, $redK.atif, $redK.ayni)

# 01.08 KOK NEDEN (uc arizali kosunun dersi): PostgREST KISMI upsert tuzagi.
# Yalniz {id, hap} gonderilince Postgres, satir VAR OLSA BILE once eksik
# kolonlari bos birakip ekleme satiri kurar; 'sinav' gibi zorunlu kolonlarda
# 23502 patlar. Kismi alan yazmak icin dogru alet upsert DEGIL, guncellemedir:
# PATCH id=eq.X yalniz o kolonu gunceller, olmayan id'de sessizce 0 satir
# doner (yaris da kendiliginden cozulur).
$yazilan = 0
if($gecen.Count){
  $ct = $SBH + @{ 'Content-Type'='application/json'; Prefer='return=minimal' }
  $sayac = 0
  foreach($g in $gecen){
    $gb = ConvertTo-Json -InputObject @{ hap = $g.hap } -Compress
    $yr = Invoke-WebRequest -Method Patch -Uri "$SB_URL/rest/v1/soru_havuzu?id=eq.$($g.id)" `
      -Headers $ct -Body ([Text.Encoding]::UTF8.GetBytes($gb)) -TimeoutSec 60 -SkipHttpErrorCheck
    if([int]$yr.StatusCode -ge 300){
      $govde2 = "$($yr.Content)"
      throw ("Supabase PATCH HTTP {0} (id {1}): {2}" -f $yr.StatusCode, $g.id, $govde2.Substring(0,[Math]::Min(400,$govde2.Length)))
    }
    $yazilan++; $sayac++
    if(($sayac % 500) -eq 0){ Write-Host ("... {0}/{1} hap yazildi" -f $sayac, $gecen.Count) }
  }
}

# Basari: bekleyen partiler hasat edilip yazildi - dosyayi BOSALT (silme:
# workflow'un commit adimi yalniz var olan dosyayi stage'ler, silinme yansimaz).
[IO.File]::WriteAllText($partiYol, (ConvertTo-Json -InputObject ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); partiler=@(); istek=0; not="hasat tamamlandi" }) -Depth 3), (New-Object Text.UTF8Encoding($false)))

Rapor ([ordered]@{
  tarih = (Get-Date -Format "dd.MM.yyyy HH:mm"); durum = "TAMAM"
  mod = $(if($KURTAR){'KURTARMA'}else{'URETIM'})
  hedef = $hedef.Count; hasat = $sonuclar.Count; yazilan = $yazilan
  red = $redK; partiler = [object[]]$batchIdler
  not = "Yazilan hap'ler yayin durumunu DEGISTIRMEZ. Dusenler bir sonraki kalite taramasinda yeniden sayilir."
})
Write-Host ("TAMAM: hedef {0}, hasat {1}, yazilan {2}." -f $hedef.Count, $sonuclar.Count, $yazilan)
