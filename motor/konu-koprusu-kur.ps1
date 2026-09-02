# ============================================================================
#  KONU KÖPRÜSÜ — V2 CANLI (02.09.2026 gece, Cem: "1 ve 2 yap" → 1 = köprü V2)
#
#  NEDEN VAR: İki taksonomi köprüsüz — bizim ders/konu adları ile çıkmış-arşiv
#  etiketleri ayrı evrenler; "eksik konu" ölçümü bu yüzden sahte-eksik üretiyor
#  (25.08: 66'nın 62'si sahteydi). Köprü = sınav>konu kanonik anahtarı +
#  bizim/çıkmış sayılar + durum + dayanak.
#
#  V1 (01.09) 31.08 Excel haritasını Excel COM ile okuyordu: masaüstünde donuk
#  bir dosya, üreticisi depoda yok, sayılar 31.08'in sayıları. V2 aynı şemayı
#  CANLI kaynaklardan türetir ve günlük robot olur (konu-koprusu.yml):
#     ÇIKMIŞ  : veri/sgs-analiz.json · smmm-analiz.json · kgk-analiz.json (konuSayim)
#     BİZİM   : soru_havuzu (sinav, ders, konu, kaynak) — canlı, sayfalı
#     KÖPRÜ   : veri/konu-eslesme.json sözlüğü (kasa etiketi → kitapçık konusu, 3.075)
#     DAYANAK : veri/kopru-dayanak-sozlugu.json — çıkmış konunun dayanağı 31.08
#               oturumunda K1-K4 yöntemleriyle bulunmuştu (6.700 konu); V2 sayıyı
#               canlı üretir, çıkmış dayanağını buradan okur. Sözlükte olmayan
#               yeni konu = dayanak "ÖLÇÜLMEDİ" (uydurulmaz).
#
#  ÇIKTI (V1 ile aynı şema, tüketiciler değişmedi — kalip-parti-uret.ps1, tek sayfa):
#   veri/fabrika/konu-koprusu.json  -> TAM köprü (gitignore içi; parti üretici okur)
#   veri/konu-koprusu-ozet.json     -> repo özeti: durum sayıları + ders köprüsü +
#                                      AĞIR BOŞLUK listesi (≥3 dönem) + V2 sağlık sayıları
#  0 USD · model yok · yalnız Supabase okuması.
# ============================================================================
param([switch]$Sessiz)
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent']='mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$depoKok=Split-Path -Parent $here
. (Join-Path $depoKok 'arac\dayanak-normalize.ps1')
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')

$ANAHTAR=if($env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY } else { [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $ANAHTAR){ throw 'SUPABASE_SERVICE_KEY yok - kasa okunamaz, köprü kurulamaz (sessiz "boş" DENMEZ).' }
$KASA_URL='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$BASLIKLAR=@{ apikey=$ANAHTAR; Authorization="Bearer $ANAHTAR" }

# Türkçe-toleranslı normalize (siklik-kunyesi.ps1 ile BİREBİR aynı — anahtarlar tutmalı)
function Norm([string]$metin){
  $s="$metin".Replace([char]0x0130,'I').Replace([char]0x0131,'i').Replace([char]0x015E,'S').Replace([char]0x015F,'s').Replace([char]0x011E,'G').Replace([char]0x011F,'g').Replace([char]0x00DC,'U').Replace([char]0x00FC,'u').Replace([char]0x00D6,'O').Replace([char]0x00F6,'o').Replace([char]0x00C7,'C').Replace([char]0x00E7,'c').ToLowerInvariant()
  $s=$s -replace '[çÇ]','c' -replace '[ğĞ]','g' -replace '[ıİİ]','i' -replace '[öÖ]','o' -replace '[şŞ]','s' -replace '[üÜ]','u'
  $s=$s -replace '[^a-z0-9| ]',' ' -replace '\s+',' '
  return $s.Trim()
}
function Yukle([string]$yol){ $tam=Join-Path $depoKok $yol; if(-not (Test-Path $tam)){ return $null }; return (Get-Content $tam -Raw -Encoding UTF8 | ConvertFrom-Json) }
function Cogunluk([hashtable]$sayim){ if($sayim.Count -eq 0){ return '' }; return ($sayim.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key }

# --- 1) ÇIKMIŞ: üç analiz dosyası ----------------------------------------------
$ARSIV=@(@('SGS','veri\sgs-analiz.json'),@('SMMM','veri\smmm-analiz.json'),@('KGK','veri\kgk-analiz.json'))
$cikmis=@{}      # 'SINAV|normkonu' -> @{ soru; donemler(hash); arsivDers(hash); ad }
$arsivDamga=@{}
foreach($cift in $ARSIV){
  $sinavAd=$cift[0]; $analiz=Yukle $cift[1]
  if(-not $analiz){ Write-Host "  UYARI: $($cift[1]) yok - $sinavAd çıkmış tarafı BOŞ kalır" -ForegroundColor Yellow; continue }
  $arsivDamga[$sinavAd]="$($analiz.guncelleme)"
  # KARANTİNA KAPISI (02.09 gece, ölçüldü): SMMM 2026/3'te 8 dersin kitapçığı AYNI sermaye
  # piyasası içeriğiydi (TESMER bağlantıları aynı/bozuk dosyayı vermiş), analiz her dosyayı
  # kendi dersiyle etiketlemişti → 7 derse 140 yanlış çıkmış-konu girdi, "Muhasebe Denetimi"
  # partisi sermaye piyasası sorusu üretti. Kural: aynı dönemde ≥3 ders girdisi birbiriyle
  # ≥%50 aynı konuyu taşıyorsa o dönemin ders etiketleri güvenilmezdir → dönem ATLANIR ve
  # özete yazılır. Veri elle düzeltilmez; sinav-analiz o dönemi yeniden indirince kendiliğinden açılır.
  $donemGrup=@{}
  foreach($donem in @($analiz.donemler)){ if(-not $donem.konuSayim){ continue }; $dk="$($donem.donem)"; if(-not $donemGrup.ContainsKey($dk)){ $donemGrup[$dk]=New-Object System.Collections.Generic.List[object] }; $donemGrup[$dk].Add($donem) }
  $karantinaDonem=@{}
  foreach($dk in $donemGrup.Keys){
    $girdiler=@($donemGrup[$dk]); if($girdiler.Count -lt 3){ continue }
    $kumeler=@($girdiler | ForEach-Object { ,@($_.konuSayim.PSObject.Properties | ForEach-Object { Norm (("$($_.Name)" -split '\|',2)[1]) }) })
    $supheli=0
    for($i=0;$i -lt $kumeler.Count;$i++){
      $enYuksek=0
      for($j=0;$j -lt $kumeler.Count;$j++){ if($i -eq $j -or $kumeler[$i].Count -eq 0){ continue }; $ortak=@($kumeler[$i] | Where-Object { $kumeler[$j] -contains $_ }).Count; $oran=100*$ortak/[Math]::Max(1,$kumeler[$i].Count); if($oran -gt $enYuksek){ $enYuksek=$oran } }
      if($enYuksek -ge 50){ $supheli++ }
    }
    if($supheli -ge 3){ $karantinaDonem[$dk]="$supheli/$($girdiler.Count) ders girdisi birbirinin aynısı (ders etiketi güvenilmez)"; Write-Host "  KARANTİNA $sinavAd $dk : $($karantinaDonem[$dk])" -ForegroundColor Yellow }
  }
  if(-not $script:KARANTINA){ $script:KARANTINA=New-Object System.Collections.Generic.List[object] }
  foreach($dk in $karantinaDonem.Keys){ $script:KARANTINA.Add([pscustomobject]@{ sinav=$sinavAd; donem=$dk; sebep=$karantinaDonem[$dk]; atlanan_girdi=@($donemGrup[$dk]).Count }) }
  $donemSay=0
  foreach($donem in @($analiz.donemler)){
    if(-not $donem.konuSayim){ continue }
    if($karantinaDonem.ContainsKey("$($donem.donem)")){ continue }
    $donemSay++
    $donemKimlik="$($donem.donem)"
    foreach($p in $donem.konuSayim.PSObject.Properties){
      $parca="$($p.Name)" -split '\|',2
      if($parca.Count -lt 2){ continue }
      $dersHam=$parca[0].Trim(); $konuHam=$parca[1].Trim()
      $nk=Norm $konuHam; if(-not $nk){ continue }
      $anahtar="$sinavAd|$nk"
      if(-not $cikmis.ContainsKey($anahtar)){ $cikmis[$anahtar]=@{ soru=0; donemler=@{}; arsivDers=@{}; ad=$konuHam } }
      $cikmis[$anahtar].soru += [int]$p.Value
      $cikmis[$anahtar].donemler[$donemKimlik]=1
      if(-not $cikmis[$anahtar].arsivDers.ContainsKey($dersHam)){ $cikmis[$anahtar].arsivDers[$dersHam]=0 }
      $cikmis[$anahtar].arsivDers[$dersHam] += [int]$p.Value
    }
  }
  Write-Host "  çıkmış $sinavAd : $donemSay dönem okundu"
}
Write-Host "  çıkmış tekil konu: $($cikmis.Count)"

# --- 2) BİZİM: kasa (sayfalı) ----------------------------------------------------
$eslesme=Yukle 'veri\konu-eslesme.json'
$sozluk=@{}
if($eslesme -and $eslesme.sozluk){ foreach($p in $eslesme.sozluk.PSObject.Properties){ $sozluk[$p.Name]="$($p.Value.hedef)" } }
Write-Host "  konu-eşleşme sözlüğü: $($sozluk.Count) kayıt"

$bizim=@{}       # 'SINAV|normkonu(hedef)' -> @{ soru; ders(hash); kaynak(hash); ad }
$okunan=0; $bas=0
while($true){
  $sayfa=$null
  # PS 5.1 TUZAĞI (02.09 gece, kapı yakaladı: "kasa 1 soru döndü"): Invoke-RestMethod
  # 1.000'lik JSON dizisini TEK nesne diye verdi. Ham metin okunup ConvertFrom-Json
  # ile açılır (kasa-sayim/konu-eslesme aynı yolu kullanır).
  foreach($deneme in 1..3){
    try{
      $ham=Invoke-WebRequest -UseBasicParsing -Uri "$KASA_URL`?select=id,sinav,ders,konu,kaynak&order=id&offset=$bas&limit=1000" -Headers $BASLIKLAR -UserAgent 'mevzuat-radar-robot/1.0' -TimeoutSec 180
      $metin=if($ham.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($ham.Content) } else { "$($ham.Content)" }
      $sayfa=@(($metin | ConvertFrom-Json) | ForEach-Object { $_ }); break
    }
    catch{ if($deneme -eq 3){ throw "kasa okunamadı (offset $bas): $($_.Exception.Message)" }; Start-Sleep -Seconds (5*$deneme) }
  }
  if($sayfa.Count -eq 0){ break }
  foreach($soru in $sayfa){
    $okunan++
    $sinavAd="$($soru.sinav)".Trim(); $dersHam="$($soru.ders)".Trim(); $konuHam="$($soru.konu)".Trim()
    if(-not $sinavAd -or -not $konuHam){ continue }
    # köprü: kasa "ders|konu" sözlükte varsa kitapçık konusuna geç; yoksa konu adı doğrudan
    $kasaAnahtar=Norm "$dersHam|$konuHam"
    $hedefKonu=Norm $konuHam
    if($sozluk.ContainsKey($kasaAnahtar)){ $hp="$($sozluk[$kasaAnahtar])" -split '\|',2; if($hp.Count -eq 2 -and $hp[1].Trim()){ $hedefKonu=Norm $hp[1] } }
    if(-not $hedefKonu){ continue }
    $anahtar="$sinavAd|$hedefKonu"
    if(-not $bizim.ContainsKey($anahtar)){ $bizim[$anahtar]=@{ soru=0; ders=@{}; kaynak=@{}; ad=$konuHam } }
    $bizim[$anahtar].soru++
    if(-not $bizim[$anahtar].ders.ContainsKey($dersHam)){ $bizim[$anahtar].ders[$dersHam]=0 }; $bizim[$anahtar].ders[$dersHam]++
    $kaynakHam="$($soru.kaynak)".Trim()
    if($kaynakHam -and $kaynakHam -ne 'YOK'){ if(-not $bizim[$anahtar].kaynak.ContainsKey($kaynakHam)){ $bizim[$anahtar].kaynak[$kaynakHam]=0 }; $bizim[$anahtar].kaynak[$kaynakHam]++ }
  }
  $bas+=1000
  if($sayfa.Count -lt 1000){ break }
}
Write-Host "  kasa: $okunan soru okundu · bizim tekil konu: $($bizim.Count)"
if($okunan -lt 1000){ throw "kasa $okunan soru döndü - sayfalama/yetki sorunu; köprü YAZILMADI." }

# --- 3) DAYANAK SÖZLÜĞÜ (31.08 tohumu) --------------------------------------------
$daySoz=@{}
$ds=Yukle 'veri\kopru-dayanak-sozlugu.json'
if($ds -and $ds.sozluk){ foreach($p in $ds.sozluk.PSObject.Properties){ $daySoz[$p.Name]=$p.Value } }
Write-Host "  çıkmış dayanak sözlüğü: $($daySoz.Count) konu"

# --- 4) BİRLEŞTİR --------------------------------------------------------------------
$kayitlar=New-Object System.Collections.Generic.List[object]
$tumAnahtarlar=New-Object System.Collections.Generic.HashSet[string]
foreach($k in $cikmis.Keys){ [void]$tumAnahtarlar.Add($k) }
foreach($k in $bizim.Keys){ [void]$tumAnahtarlar.Add($k) }
$dayanakOlculmedi=0
foreach($anahtar in $tumAnahtarlar){
  $parca=$anahtar -split '\|',2; $sinavAd=$parca[0]
  $c=$null; if($cikmis.ContainsKey($anahtar)){ $c=$cikmis[$anahtar] }
  $b=$null; if($bizim.ContainsKey($anahtar)){ $b=$bizim[$anahtar] }
  $cikmisSoru=if($c){ [int]$c.soru } else { 0 }
  $bizimSoru=if($b){ [int]$b.soru } else { 0 }
  $donem=if($c){ $c.donemler.Count } else { 0 }
  $durum=if($cikmisSoru -gt 0 -and $bizimSoru -gt 0){ 'IKISI DE VAR' } elseif($cikmisSoru -gt 0){ 'BOSLUK - cikmisda var, bizde YOK' } else { 'YALNIZ BIZDE' }
  $konuAd=if($c){ $c.ad } else { $b.ad }
  $arsivDers=if($c){ (@($c.arsivDers.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { $_.Key }) -join ' / ') } else { '' }
  $bizimDers=if($b){ Cogunluk $b.ders } else { '' }
  $dayanak=if($b){ Cogunluk $b.kaynak } else { '' }
  $cikmisDayanak=''; $guc=''
  if($cikmisSoru -gt 0){
    if($daySoz.ContainsKey($anahtar)){ $cikmisDayanak="$($daySoz[$anahtar].d)"; $guc="$($daySoz[$anahtar].g)" }
    else { $guc='OLCULMEDI'; $dayanakOlculmedi++ }
  }
  $kayitlar.Add([pscustomobject]@{
    sinav=$sinavAd; konu=$konuAd; bizim_ders=$bizimDers; arsiv_ders=$arsivDers
    bizim=$bizimSoru; cikmis=$cikmisSoru; durum=$durum; dayanak=$dayanak
    cikmis_dayanak=$cikmisDayanak; guc=$guc; donem=$donem
    dayanak_anahtar=(DayanakAnahtar $dayanak); cikmis_dayanak_anahtar=(DayanakAnahtar $cikmisDayanak)
  })
}
$kayitlar=[System.Collections.Generic.List[object]]@($kayitlar | Sort-Object sinav, @{Expression='donem';Descending=$true}, konu)

# --- TAM köprü (fabrika) ---
$fab=Join-Path $depoKok 'veri\fabrika'
if(-not (Test-Path $fab)){ New-Item -ItemType Directory -Path $fab -Force | Out-Null }
[IO.File]::WriteAllText((Join-Path $fab 'konu-koprusu.json'),(ConvertTo-Json -InputObject $kayitlar.ToArray() -Depth 3 -Compress),[Text.UTF8Encoding]::new($false))
Write-Host "  TAM köprü yazıldı: veri/fabrika/konu-koprusu.json ($($kayitlar.Count) konu)"

# --- ÖZET (repo) ---
$durumSay=[ordered]@{ 'YALNIZ BIZDE'=0; 'BOSLUK - cikmisda var, bizde YOK'=0; 'IKISI DE VAR'=0 }
$dersKoprusu=@{}
$agir=New-Object System.Collections.Generic.List[object]
foreach($x in $kayitlar){
  $durumSay[$x.durum]++
  if($x.arsiv_ders){
    foreach($ad in ($x.arsiv_ders -split ' / ')){
      # arşiv ders etiketi üç türlü yazılı ("Genel Hukuk Mevzuatı" / "Mevzuati" / küçük harf):
      # Norm ile TEK satıra indir, ilk görülen yazımı göster (V1'de 165 satırın çoğu ikizdi)
      $dk="$($x.sinav)|$(Norm $ad)"
      if(-not $dersKoprusu.ContainsKey($dk)){ $dersKoprusu[$dk]=@{ bizim=@{}; konu=0; ad=$ad } }
      $dersKoprusu[$dk].konu++
      if($x.bizim_ders){ if(-not $dersKoprusu[$dk].bizim.ContainsKey($x.bizim_ders)){ $dersKoprusu[$dk].bizim[$x.bizim_ders]=0 }; $dersKoprusu[$dk].bizim[$x.bizim_ders]++ }
    }
  }
  if($x.durum -like 'BOSLUK*' -and $x.donem -ge 3){
    $agir.Add([pscustomobject]@{ sinav=$x.sinav; konu=$x.konu; donem=$x.donem; cikmis=$x.cikmis; arsiv_ders=$x.arsiv_ders; dayanak=$x.cikmis_dayanak; guc=$x.guc })
  }
}
$dersListe=New-Object System.Collections.Generic.List[object]
foreach($dk in ($dersKoprusu.Keys | Sort-Object)){
  $p=$dk -split '\|',2
  $dersListe.Add([pscustomobject]@{ sinav=$p[0]; arsiv_ders=$dersKoprusu[$dk].ad; bizim_ders=(Cogunluk $dersKoprusu[$dk].bizim); konu_sayisi=$dersKoprusu[$dk].konu })
}
$sinavSay=@{}
foreach($x in $kayitlar){ if(-not $sinavSay.ContainsKey($x.sinav)){ $sinavSay[$x.sinav]=@{ konu=0; bizim=0; cikmis=0 } }; $sinavSay[$x.sinav].konu++; $sinavSay[$x.sinav].bizim+=$x.bizim; $sinavSay[$x.sinav].cikmis+=$x.cikmis }
$sinavOzet=New-Object System.Collections.Generic.List[object]
foreach($s in ($sinavSay.Keys | Sort-Object)){ $sinavOzet.Add([pscustomobject]@{ sinav=$s; konu=$sinavSay[$s].konu; bizim_soru=$sinavSay[$s].bizim; cikmis_soru=$sinavSay[$s].cikmis }) }

# PS 5.1: [ordered] literalinde @($liste) patlar -> boş açılır, tek tek atanır
$ozet=[ordered]@{}
$ozet['olcum']=(Get-Date -Format 'dd.MM.yyyy HH:mm')
$ozet['kaynak']='V2 CANLI: soru_havuzu (kasa) + sgs/smmm/kgk-analiz.json (çıkmış) + konu-eslesme.json sözlüğü + kopru-dayanak-sozlugu.json (31.08 tohumu). Günlük robot: konu-koprusu.yml'
$ozet['konu_sayisi']=$kayitlar.Count
$ozet['durum']=$durumSay
$ozet['sinav_ozeti']=$sinavOzet.ToArray()
$ozet['kasa_okunan_soru']=$okunan
$ozet['arsiv_damgasi']=$arsivDamga
$ozet['sozlukle_koprulenen_kasa_etiketi']=$sozluk.Count
$ozet['cikmis_dayanak_olculmedi']=$dayanakOlculmedi
$ozet['karantina_donem']=$(if($script:KARANTINA){ $script:KARANTINA.ToArray() } else { @() })
$ozet['ders_koprusu']=$dersListe.ToArray()
$ozet['agir_bosluk_sayisi']=$agir.Count
$ozet['agir_bosluklar']=@($agir | Sort-Object donem -Descending)
$ozet['not']='V2: sayılar canlı; çıkmış dayanağı 31.08 sözlüğünden (sözlükte olmayan konu guc=OLCULMEDI, uydurulmaz). Konu anahtarı = SINAV|Norm(konu) - siklik-kunyesi ile aynı Norm.'
$null=RaporYaz -Hedef (Join-Path $depoKok 'veri\konu-koprusu-ozet.json') -Nesne $ozet -Derinlik 6
Write-Host ("  ÖZET: {0} konu | YALNIZ BIZDE {1} · BOSLUK {2} · IKISI DE VAR {3} | ders köprüsü {4} | ağır boşluk {5} | dayanak ölçülmedi {6}" -f $kayitlar.Count,$durumSay['YALNIZ BIZDE'],$durumSay['BOSLUK - cikmisda var, bizde YOK'],$durumSay['IKISI DE VAR'],$dersListe.Count,$agir.Count,$dayanakOlculmedi)
