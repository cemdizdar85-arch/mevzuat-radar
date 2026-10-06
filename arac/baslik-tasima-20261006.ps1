# ============================================================================
#  BASLIK TASIMA — HEDEFLI AMBAR TAZELEMESI (06.10.2026, Cem "1.2.3 ucunu de yap")
#  motor/mevzuat-yut.ps1'e baslik sizmasi kurali eklendi (madde basligi onceki maddenin sonuna yapisiyordu; is emri
#  veri/AMBAR-YUTMA-IS-EMRI-20260930.md satir 23). KAPI EKLENDIYSE VERI TAZELENIR — ama ZORLA ile tam yeniden yutma
#  GUVENLI DEGIL (06.10 olculdu): (1) 172 kaynakta onceki yutucu duzeltmeleri hic uygulanmamis, yeniden yutma 2.704
#  kaynak_ad'i siler (71 yayindaki soru o adlara bagli) — bu degisiklikten BAGIMSIZ, ayri is; (2) ambara dogrudan
#  yapilmis onarimlari (or. 02.10 VUK m.283 dipnotu) geri alir.
#  Bu arac YALNIZ su kayitlari yazar:
#   - kaynak metninin hash'i _durum.json ile AYNI (metin degismedi; fark yalniz parcalayicidan)
#   - yeni parcalama ile aynadaki (veri/mevzuat/<slug>.json) kaynak_ad dizisi BIREBIR ayni (soru baglari bozulmaz)
#   - aynadan yeniye hicbir kelime EKSILMEZ (yalniz yer degistirir / mulga parcayla atilan baslik geri gelir)
#   - ambardaki (Supabase) satirlarin metin+basligi aynayla BIREBIR ayni (elle onarilmis kaynak BUTUNUYLE atlanir;
#     tek satir atlanirsa kuyruk bir kayittan duser ama digerine eklenmezdi)
#  Yazar: ambar dokumanlar (metin, baslik; id ile upsert) + veri/mevzuat/<slug>.json + veri/mevzuat/_degisen-kokler.json
#  (yeniden_bolme=true, belirtec yok -> motor/soru-dayanak-nobetcisi.ps1 bu maddelere dayanan soruyu CEKMEZ).
#  Kullanim: -Kuru (varsayilan; yalniz sayar, rapor yazar)  ·  -Yaz (bulut-kosan-etiketler -Kati bos degilse DURUR)
#  BU ARAC SUNU GORMEZ: madde-damga'nin bu yazimdan sonraki ilk kosusu disinda baska bir anda ambara yazan isi.
# ============================================================================
param([switch]$Yaz, [string]$Rapor = '', [string]$Atla = '', [switch]$KosanVarAtlaIle)
# 06.10 Cem "etkilenmeyenleri simdi yaz": -Atla "slug,slug" = bulutta kosan partilerin soru kaynak baglarinin dustugu kaynaklar
#   (hazir soru planlarinda hazir dosyadaki kaynak_adlar). -KosanVarAtlaIle verilirse kosan parti varken DURMAZ, yalniz -Atla
#   listesini yazmaz. Liste bos verilemez.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path; $kok = Split-Path -Parent $here
$SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co'
$anahtarSb = $env:SUPABASE_SERVICE_KEY; if(-not $anahtarSb){ $anahtarSb = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $anahtarSb){ throw 'SUPABASE_SERVICE_KEY yok' }
$Hb = @{ apikey=$anahtarSb; Authorization="Bearer $anahtarSb"; 'User-Agent'='mevzuat-radar-robot/1.0' }
. (Join-Path $here 'mevzuat-degisti.ps1')   # MdAnahtar

# yutucunun parcalayici islevleri (AST) — tek dogru kaynak motor/mevzuat-yut.ps1
$tk=$null; $hata=$null
$ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $kok 'motor\mevzuat-yut.ps1'), [ref]$tk, [ref]$hata)
if($hata.Count){ throw "mevzuat-yut.ps1 ayristirilamadi: $($hata[0].Message)" }
foreach($st in $ast.EndBlock.Statements){
  if($st -is [System.Management.Automation.Language.FunctionDefinitionAst] -or ($st.Extent.Text -like '$script:TR_HARF*')){ . ([scriptblock]::Create($st.Extent.Text)) }
}
$bugun = (Get-Date).ToString('yyyy-MM-dd')
function Bosluk([string]$x){ return (($x -replace '\s+',' ').Trim()) }
function Sha([string]$x){ $sha=[Security.Cryptography.SHA256]::Create(); ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($x))) -replace '-','').Substring(0,16) }
function KelimeSay($dizi){ $c=@{}; foreach($m in $dizi){ foreach($w in ("$m" -split '\s+')){ if($w){ $c[$w] = 1 + $(if($c.ContainsKey($w)){ $c[$w] } else { 0 }) } } }; return $c }

$man = Get-Content (Join-Path $kok 'veri\mevzuat-kaynaklar.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$durum = Get-Content (Join-Path $kok 'veri\mevzuat\_durum.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$atlaKume = New-Object 'System.Collections.Generic.HashSet[string]'; foreach($x in ($Atla -split ',')){ if($x.Trim()){ [void]$atlaKume.Add($x.Trim()) } }
if($KosanVarAtlaIle -and -not $atlaKume.Count){ throw '-KosanVarAtlaIle icin -Atla listesi gerekli' }
$say = [ordered]@{ kaynak=0; metin_yok=0; hash_farkli=0; kilavuz_bolum=0; degisiklik_yok=0; ad_farkli=0; kelime_eksilen=0; ambar_farkli=0; ambar_okunamadi=0; yazilacak_kaynak=0; yazilacak_kayit=0; baslik_dolan=0; anahtar=0 }
$atlanan = New-Object System.Collections.Generic.List[object]; $plan = New-Object System.Collections.Generic.List[object]
foreach($law in $man.kanunlar){
  $hz = Join-Path $kok "veri\mevzuat-hazir\$($law.slug).txt"; $tx = Join-Path $kok "_txt\$($law.slug).txt"; $ay = Join-Path $kok "veri\mevzuat\$($law.slug).json"
  $txt = if(Test-Path $hz){ $hz } elseif(Test-Path $tx){ $tx } else { $null }
  if(-not $txt -or -not (Test-Path $ay)){ $say.metin_yok++; continue }
  $say.kaynak++
  if($atlaKume.Contains("$($law.slug)")){ $atlanan.Add([pscustomobject]@{ slug=$law.slug; neden='bulutta kosan parti kaynagi (-Atla)' }); continue }
  if($law.PSObject.Properties['parcalayici'] -and "$($law.parcalayici)" -eq 'kilavuz-bolum'){ $say.kilavuz_bolum++; continue }
  $raw = Get-Content $txt -Raw -Encoding UTF8
  $flat = ($raw -replace "\r?\n"," ") -replace "\s+"," "
  $d = $durum.PSObject.Properties[$law.slug]
  if(-not $d -or "$($d.Value.hash)" -ne (Sha $flat)){ $say.hash_farkli++; $atlanan.Add([pscustomobject]@{ slug=$law.slug; neden='hash farkli (metin degismis: normal yutma isi)' }); continue }
  $flat = AralikliMaddeDuzelt $flat
  $yeni = @(Parcala $flat "$($law.ad)" 'u' (BaslikSatirlari $raw))
  if($yeni.Count -lt 5){ $say.degisiklik_yok++; continue }   # bolum parcalayicisi yolu: bu kural dokunmaz
  $aynaJ = Get-Content $ay -Raw -Encoding UTF8 | ConvertFrom-Json; $ayna = @($aynaJ.belgeler)
  if($ayna.Count -ne $yeni.Count -or (@(for($i=0;$i -lt $ayna.Count;$i++){ if("$($ayna[$i].kaynak_ad)" -cne "$($yeni[$i].kaynak_ad)"){ 1 } })).Count){
    $say.ad_farkli++; $atlanan.Add([pscustomobject]@{ slug=$law.slug; neden='kaynak_ad dizisi farkli (onceki yutucu duzeltmeleri - ayri is)' }); continue }
  $degisen = New-Object System.Collections.Generic.List[int]
  for($i=0;$i -lt $ayna.Count;$i++){ if((Bosluk $ayna[$i].metin) -cne (Bosluk $yeni[$i].metin) -or "$($ayna[$i].baslik)" -cne "$($yeni[$i].baslik)"){ $degisen.Add($i) } }
  if(-not $degisen.Count){ $say.degisiklik_yok++; continue }
  $ka = KelimeSay @($ayna | ForEach-Object { $_.metin }); $kyy = KelimeSay @($yeni | ForEach-Object { $_.metin })
  $eksik = @($ka.Keys | Where-Object { -not $kyy.ContainsKey($_) -or $kyy[$_] -lt $ka[$_] })
  if($eksik.Count){ $say.kelime_eksilen++; $atlanan.Add([pscustomobject]@{ slug=$law.slug; neden="kelime eksiliyor ($($eksik.Count) cesit)" }); continue }
  $plan.Add([pscustomobject]@{ law=$law; ayna=$aynaJ; yeni=$yeni; degisen=$degisen })
}
# ambar karsilastirmasi (yalniz okuma): kaynagin TUM satirlari aynayla ayni olmali
$yazilacak = New-Object System.Collections.Generic.List[object]
foreach($p in $plan){
  $q = [uri]::EscapeDataString("$($p.law.ad)*"); $satir = New-Object System.Collections.Generic.List[object]; $okundu = $true
  try {
    for($o=0;;$o+=1000){
      $r = Invoke-WebRequest -UseBasicParsing -Uri "$SB_URL/rest/v1/dokumanlar?select=id,kaynak_ad,baslik,metin,tur,kaynak_url,belge_tarihi&tur=eq.kanun-madde&kaynak_ad=like.$q&order=id.asc&limit=1000&offset=$o" -Headers $Hb -TimeoutSec 180
      $parca = @(([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())) | ConvertFrom-Json | ForEach-Object { $_ })
      foreach($x in $parca){ $satir.Add($x) }; if($parca.Count -lt 1000){ break }
    }
  } catch { $okundu = $false }
  if(-not $okundu){ $say.ambar_okunamadi++; $atlanan.Add([pscustomobject]@{ slug=$p.law.slug; neden='ambar okunamadi' }); continue }
  # ad onekiyle baska kaynak da eslesebilir (or. "TTK" / "TTK Yon.") -> yalniz aynadaki adlar
  $adlar = @{}; foreach($b in @($p.ayna.belgeler)){ $adlar["$($b.kaynak_ad)"] = $b }
  $ambarAd = @{}; $cift = $false
  foreach($x in $satir){ $a = "$($x.kaynak_ad)"; if(-not $adlar.ContainsKey($a)){ continue }; if($ambarAd.ContainsKey($a)){ $cift = $true }; $ambarAd[$a] = $x }
  $esit = (-not $cift) -and ($ambarAd.PSBase.Count -eq $adlar.PSBase.Count)
  if($esit){ foreach($a in $adlar.Keys){ if((Bosluk $ambarAd[$a].metin) -cne (Bosluk $adlar[$a].metin) -or "$($ambarAd[$a].baslik)" -cne "$($adlar[$a].baslik)"){ $esit = $false; break } } }
  if(-not $esit){ $say.ambar_farkli++; $atlanan.Add([pscustomobject]@{ slug=$p.law.slug; neden=$(if($cift){'ambarda ayni adla iki satir'}else{'ambar aynayla ayni degil (elle onarim / eksik satir)'}) }); continue }
  $say.yazilacak_kaynak++
  foreach($i in $p.degisen){
    $y = $p.yeni[$i]; $am = $ambarAd["$($y.kaynak_ad)"]
    if(-not "$($p.ayna.belgeler[$i].baslik)" -and $y.baslik){ $say.baslik_dolan++ }
    $yazilacak.Add([pscustomobject]@{ slug=$p.law.slug; i=$i; id=$am.id; kaynak_ad=$y.kaynak_ad; baslik="$($y.baslik)"; metin=$y.metin; tur=$am.tur; kaynak_url=$am.kaynak_url; belge_tarihi=$am.belge_tarihi; eski=$am.metin })
  }
}
$say.yazilacak_kayit = $yazilacak.Count
# degisen madde anahtarlari (nobetci): eski/yeni birlesik metin farkli olan MdAnahtar
$anahtarlar = @{}
foreach($p in $plan){ if(-not @($yazilacak | Where-Object { $_.slug -eq $p.law.slug }).Count){ continue }
  $eM=@{}; $yM=@{}
  foreach($b in @($p.ayna.belgeler)){ $a = MdAnahtar "$($b.kaynak_ad)"; if($a){ $eM[$a] = "$($eM[$a]) $($b.metin)" } }
  foreach($b in $p.yeni){ $a = MdAnahtar "$($b.kaynak_ad)"; if($a){ $yM[$a] = "$($yM[$a]) $($b.metin)" } }
  foreach($a in $eM.Keys){ if($yM.ContainsKey($a) -and (Bosluk $eM[$a]) -cne (Bosluk $yM[$a])){ $anahtarlar[$a] = $p.law.slug } } }
$say.anahtar = $anahtarlar.PSBase.Count
$ozet = [ordered]@{ tarih=(Get-Date -Format 'yyyy-MM-dd HH:mm'); kip=$(if($Yaz){'YAZ'}else{'KURU'}); sayim=$say
  atlanan_neden = @($atlanan | Group-Object neden | ForEach-Object { [ordered]@{ neden=$_.Name; kaynak=$_.Count; ornek=(@($_.Group | Select-Object -First 8 | ForEach-Object { $_.slug }) -join ', ') } })
  yazilacak_kaynak = @($yazilacak | Group-Object slug | Sort-Object Count -Descending | ForEach-Object { "$($_.Name) $($_.Count)" }) }
if($Rapor){ [IO.File]::WriteAllText($Rapor, (ConvertTo-Json -InputObject ([ordered]@{ ozet=$ozet; kayitlar=@($yazilacak | ForEach-Object { [ordered]@{ slug=$_.slug; kaynak_ad=$_.kaynak_ad; id=$_.id; baslik=$_.baslik } }); anahtarlar=@($anahtarlar.Keys | Sort-Object) }) -Depth 6), (New-Object Text.UTF8Encoding($false))) }
Write-Host ("SAYIM: " + (($say.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ' · '))
foreach($g in $ozet.atlanan_neden){ Write-Host ("  ATLANDI [{0}] {1} kaynak: {2}" -f $g.neden, $g.kaynak, $g.ornek) }
if(-not $Yaz){ Write-Host 'KURU KOSU: ambara/dosyaya yazilmadi.'; exit 0 }

# ---------------- YAZ ----------------
$eapEski = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
$kosan = @(& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'bulut-kosan-etiketler.ps1') -Kati)
$kosanKod = $LASTEXITCODE; $ErrorActionPreference = $eapEski
if($kosanKod -ne 0 -or (-not $KosanVarAtlaIle -and @($kosan | Where-Object { "$_".Trim() }).Count)){ Write-Host ('DURDU: bulutta kosan parti var / okunamadi -> ' + (($kosan | Select-Object -First 5) -join ' ')); exit 2 }
$govdeDizi = @($yazilacak | ForEach-Object { [ordered]@{ id=$_.id; tur=$_.tur; kaynak_ad=$_.kaynak_ad; baslik=$_.baslik; metin=$_.metin; kaynak_url=$_.kaynak_url; belge_tarihi=$_.belge_tarihi } })
for($i=0; $i -lt $govdeDizi.Count; $i += 400){
  $dilim = @($govdeDizi[$i..([Math]::Min($i+400,$govdeDizi.Count)-1)])
  $bj = ConvertTo-Json -InputObject $dilim -Depth 4
  Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/dokumanlar?on_conflict=id" -Headers ($Hb + @{ Prefer='resolution=merge-duplicates,return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($bj)) -TimeoutSec 300 | Out-Null
}
# geri oku
$tutan = 0; $tutmayan = New-Object System.Collections.Generic.List[string]
$idler = @($yazilacak | ForEach-Object { $_.id }); $bek = @{}; foreach($y in $yazilacak){ $bek["$($y.id)"] = $y }
for($i=0; $i -lt $idler.Count; $i += 150){
  $in = (@($idler[$i..([Math]::Min($i+150,$idler.Count)-1)]) | ForEach-Object { $_ }) -join ','
  $r = Invoke-WebRequest -UseBasicParsing -Uri "$SB_URL/rest/v1/dokumanlar?select=id,baslik,metin&id=in.($in)" -Headers $Hb -TimeoutSec 180
  foreach($x in @(([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())) | ConvertFrom-Json | ForEach-Object { $_ })){
    $b = $bek["$($x.id)"]; if((Bosluk $x.metin) -ceq (Bosluk $b.metin) -and "$($x.baslik)" -ceq $b.baslik){ $tutan++ } else { $tutmayan.Add($b.kaynak_ad) } }
}
Write-Host ("GERI OKUMA: {0}/{1} tutuyor{2}" -f $tutan, $yazilacak.Count, $(if($tutmayan.Count){ " · TUTMAYAN: " + (($tutmayan | Select-Object -First 5) -join ' ; ') } else { '' }))
# ayna dosyalari (yutucunun bicimiyle)
foreach($g in ($yazilacak | Group-Object slug)){
  $p = @($plan | Where-Object { $_.law.slug -eq $g.Name })[0]
  foreach($y in $g.Group){ $p.ayna.belgeler[$y.i].metin = $y.metin; $p.ayna.belgeler[$y.i].baslik = $y.baslik }
  [IO.File]::WriteAllBytes((Join-Path $kok "veri\mevzuat\$($g.Name).json"), [Text.Encoding]::UTF8.GetBytes((@{ belgeler=$p.ayna.belgeler } | ConvertTo-Json -Depth 6)))
}
# nobetci: yeniden bolme isareti (belirtecsiz) — bekleyen gercek degisiklik varsa ona dokunulmaz
$dkY = Join-Path $kok 'veri\mevzuat\_degisen-kokler.json'
$dk=[ordered]@{}; if(Test-Path $dkY){ foreach($pp in (Get-Content $dkY -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler.PSObject.Properties){ $dk[$pp.Name]=$pp.Value } }
$yeniIsaret = 0
foreach($a in $anahtarlar.Keys){ if($dk.Contains($a) -and $dk[$a]){ continue }; $dk[$a] = [ordered]@{ tarih=(Get-Date -Format 'yyyy-MM-dd HH:mm'); kaynak=$anahtarlar[$a]; belirsiz=$false; belirtecler=@(); yeniden_bolme=$true }; $yeniIsaret++ }
[IO.File]::WriteAllText($dkY, (ConvertTo-Json -InputObject ([ordered]@{ aciklama='Madde metni değişince eski/yeni ayırt edici belirteçler (motor/mevzuat-yut.ps1). Nöbetçi, soru bu belirteçlerden hiçbirine değmiyorsa çekmez; belirsiz=true ise hepsini çeker.'; maddeler=$dk }) -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host ("YAZILDI: {0} kayit / {1} kaynak · ayna dosyasi {2} · yeniden bolme isareti {3} madde" -f $yazilacak.Count, $say.yazilacak_kaynak, @($yazilacak | Group-Object slug).Count, $yeniIsaret)
if($tutmayan.Count){ exit 1 }
