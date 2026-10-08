# ============================================================================
#  DIPNOT TAZELEMESI — HEDEFLI AMBAR YAZIMI (08.10.2026, Cem "evet başlat"; is emri 27)
#  motor/mevzuat-yut.ps1'e DipnotAyikla eklendi (sayfa-alti dipnotu madde govdesine karisiyordu: SPK m.108 ceza alt siniri).
#  Bu arac yutucunun ciktisini (YutmaHami -> Parcala) ambara YALNIZ su kosullarla yazar, kaynak bazinda (biri tutmazsa o kaynak
#  ATLANIR, digerleri yazilir):
#   - kaynak metin hash'i _durum.json ile AYNI (kanun metni degismedi)
#   - kaynak_ad dizisi AYNI (ekle/sil yok) -> soru baglari bozulmaz
#   - ambardan SILINEN her kelime ayiklanan dipnotlardan gelir; HIC kelime EKLENMEZ (yalniz dipnot cikar)
#   - elle onarilmis kayit: yeni yutma degistirmiyorsa korunur, degistiriyorsa kaynak ATLANIR (cakisma)
#   - nobetci: hash ayni -> yeniden_bolme (belirtecsiz); elle kayitli anahtarda gercek belirtec
#  Kullanim: [-Kaynak slug,slug] (yoksa dipnotu olan tum kaynaklar) · -Yaz (bulut-kosan-etiketler -Kati bos degilse DURUR)
#  Kopya kaynagi: arac/vgk-yeniden-yut-20261007.ps1 (07.10) - ayni yazim/geri okuma/isaret mantigi.
# ============================================================================
param([switch]$Yaz, [string[]]$Kaynak = @(), [string[]]$KoruZorla = @(), [string[]]$UstuneYaz = @(), [string[]]$Sil = @(), [string]$Rapor = '')
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path; $kok = Split-Path -Parent $here
$SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co'
$anahtarSb = $env:SUPABASE_SERVICE_KEY; if(-not $anahtarSb){ $anahtarSb = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $anahtarSb){ throw 'SUPABASE_SERVICE_KEY yok' }
$Hb = @{ apikey=$anahtarSb; Authorization="Bearer $anahtarSb"; 'User-Agent'='mevzuat-radar-robot/1.0' }
. (Join-Path $here 'mevzuat-degisti.ps1')
$tk=$null; $hata=$null
$ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $kok 'motor\mevzuat-yut.ps1'), [ref]$tk, [ref]$hata)
if($hata.Count){ throw "mevzuat-yut.ps1 ayristirilamadi: $($hata[0].Message)" }
foreach($st in $ast.EndBlock.Statements){ if($st -is [System.Management.Automation.Language.FunctionDefinitionAst] -or ($st.Extent.Text -like '$script:TR_HARF*') -or ($st.Extent.Text -like '$script:DIPNOT_*')){ . ([scriptblock]::Create($st.Extent.Text)) } }
$bugun = (Get-Date).ToString('yyyy-MM-dd'); $zaman = Get-Date -Format 'yyyyMMdd-HHmm'
function Bosluk([string]$x){ return (($x -replace '\s+',' ').Trim()) }
function Sha([string]$x){ $sha=[Security.Cryptography.SHA256]::Create(); ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($x))) -replace '-','').Substring(0,16) }
function KelimeKume([string]$x){ return ((@(($x -replace '\s+',' ').Trim() -split ' ' | Sort-Object)) -join ' ') }
function SbGet([string]$u){ for($d=1;;$d++){ try { $r = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $Hb -TimeoutSec 180; return @(([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())) | ConvertFrom-Json | ForEach-Object { $_ }) } catch { if($d -ge 3){ throw }; Start-Sleep -Seconds 10 } } }
# 08.10: sayfali okuma (PostgREST istek basina en cok 1000 satir doner; eski "limit=2000" TTK'yi kesiyordu)
function SbGetHepsi([string]$u){ $tum = New-Object System.Collections.Generic.List[object]; for($o=0;;$o+=1000){ $p = @(SbGet ("$u&limit=1000&offset=$o")); foreach($x in $p){ $tum.Add($x) }; if($p.Count -lt 1000){ break } }; return $tum.ToArray() }
function SbYaz([string]$yontem, [string]$u, $govde, [string]$tercih){ for($d=1;;$d++){ try { $bj = if($null -ne $govde){ (ConvertTo-Json -InputObject @($govde) -Depth 4) } else { $null }   # 07.10: dizgi tut - if ifadesinden atanan byte[] object[]e acilip "Empty or invalid json" veriyordu
      if($bj){ Invoke-RestMethod -Method $yontem -Uri $u -Headers ($Hb + @{ Prefer=$tercih }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($bj)) -TimeoutSec 300 | Out-Null } else { Invoke-RestMethod -Method $yontem -Uri $u -Headers ($Hb + @{ Prefer=$tercih }) -TimeoutSec 300 | Out-Null }; return } catch { if($d -ge 4){ if($bj){ [IO.File]::WriteAllText((Join-Path $env:TEMP "vgk-hatali-govde.json"), $bj) }; throw }; Start-Sleep -Seconds (15*$d) } } }

$man = Get-Content (Join-Path $kok 'veri\mevzuat-kaynaklar.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$durum = Get-Content (Join-Path $kok 'veri\mevzuat\_durum.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$ustune = New-Object 'System.Collections.Generic.HashSet[string]'; foreach($x in $UstuneYaz){ [void]$ustune.Add($x) }
# 08.10: elle onarilmis kayit (or. VUK m.283, 02.10 dipnot duzeltmesi) yeni yutma degistirse de AMBARDAKI hali korunur
$koruZ = New-Object 'System.Collections.Generic.HashSet[string]'; foreach($x in $KoruZorla){ [void]$koruZ.Add($x) }
$silK = New-Object 'System.Collections.Generic.HashSet[string]'; foreach($x in $Sil){ [void]$silK.Add($x) }
$isler = New-Object System.Collections.Generic.List[object]; $engel = New-Object System.Collections.Generic.List[string]
$kaynakListe = if($Kaynak.Count){ $Kaynak } else { @($man.kanunlar | Where-Object { -not ($_.PSObject.Properties['parcalayici'] -and "$($_.parcalayici)" -eq 'kilavuz-bolum') } | ForEach-Object { $_.slug }) }
$atlanan = New-Object System.Collections.Generic.List[string]; $dipnotsuz = 0
foreach($slug in $kaynakListe){
  $kE = New-Object System.Collections.Generic.List[string]
  $law = @($man.kanunlar | Where-Object { $_.slug -eq $slug })[0]
  $hz = Join-Path $kok "veri\mevzuat-hazir\$slug.txt"; $tx = Join-Path $kok "_txt\$slug.txt"
  $txt = if(Test-Path $hz){ $hz } elseif(Test-Path $tx){ $tx } else { $null }; if(-not $txt -or -not (Test-Path (Join-Path $kok "veri\mevzuat\$slug.json"))){ continue }
  $raw = Get-Content $txt -Raw -Encoding UTF8; $flat = ($raw -replace "\r?\n"," ") -replace "\s+"," "
  if("$($durum.$slug.hash)" -ne (Sha $flat)){ $atlanan.Add("$slug hash farkli (metin degismis)"); continue }
  $dn = YutmaHami $raw; if(-not $dn.sayi){ $dipnotsuz++; continue }
  # 08.10: parcalama DIPNOTLU metinle (adlar degismez), dipnot sonra parcalardan cikarilir - yutucuyla AYNI sira
  $yeni = @(Parcala (AralikliMaddeDuzelt $flat) "$($law.ad)" ("https://www.mevzuat.gov.tr/mevzuatmetin/$($law.pdfId).pdf") (BaslikSatirlari $raw))
  $dcS = DipnotlariCikar $yeni $dn.ayiklanan
  if($yeni.Count -lt 5){ $atlanan.Add("$slug madde deseni tutmadi (bolum yolu - bu arac yazmaz)"); continue }
  $aynaJ = Get-Content (Join-Path $kok "veri\mevzuat\$slug.json") -Raw -Encoding UTF8 | ConvertFrom-Json
  $ayna = @{}; foreach($b in @($aynaJ.belgeler)){ $ayna["$($b.kaynak_ad)"] = $b }
  $ambar = @{}; foreach($x in (SbGetHepsi ("$SB_URL/rest/v1/dokumanlar?select=id,tur,kaynak_ad,baslik,metin,kaynak_url,belge_tarihi&tur=eq.kanun-madde&kaynak_ad=like." + [uri]::EscapeDataString("$($law.ad) *") + "&order=id.asc"))){ if($ambar.ContainsKey("$($x.kaynak_ad)")){ $kE.Add("$slug ambarda cift ad: $($x.kaynak_ad)") }; $ambar["$($x.kaynak_ad)"] = $x }
  $yeniAd = @{}; foreach($b in $yeni){ $yeniAd["$($b.kaynak_ad)"] = $b }
  $guncelle = New-Object System.Collections.Generic.List[object]; $ekle = New-Object System.Collections.Generic.List[object]; $silinecek = New-Object System.Collections.Generic.List[object]; $koru = New-Object System.Collections.Generic.List[string]
  foreach($b in $yeni){
    $a = "$($b.kaynak_ad)"; $am = $ambar[$a]; $ay = $ayna[$a]
    if(-not $am){ $ekle.Add($b); continue }
    $ambarAynaAyni = ($ay -and (Bosluk $am.metin) -ceq (Bosluk $ay.metin) -and "$($am.baslik)" -ceq "$($ay.baslik)")
    $yeniAmbarAyni = ((Bosluk $am.metin) -ceq (Bosluk $b.metin) -and "$($am.baslik)" -ceq "$($b.baslik)")
    if($yeniAmbarAyni){ continue }
    if($koruZ.Contains($a)){ $koru.Add($a); continue }
    if($ambarAynaAyni){ $guncelle.Add([pscustomobject]@{ id=$am.id; b=$b; am=$am }); continue }
    # ambar elle degismis
    $yeniAynaAyni = ($ay -and (Bosluk $ay.metin) -ceq (Bosluk $b.metin) -and "$($ay.baslik)" -ceq "$($b.baslik)")
    if($yeniAynaAyni){ $koru.Add($a); continue }
    if($ustune.Contains($a)){ $guncelle.Add([pscustomobject]@{ id=$am.id; b=$b; am=$am }); continue }
    $kE.Add("$slug CAKISMA (elle onarim + yeni yutma degistiriyor): $a")
  }
  foreach($a in $ambar.Keys){ if(-not $yeniAd.ContainsKey($a)){ if($silK.Contains($a)){ $silinecek.Add($ambar[$a]) } else { $kE.Add("$slug ad dizisi farkli (silinecek): $a") } } }
  # nobetci anahtarlari: eski = ambar (koru dahil), yeni = yazim sonrasi ambar
  # 07.10: kanun metni hash'i AYNI -> fark yalniz bolmeden (baslik bir maddeden otekine gecer, kelime kumesi madde bazinda
  #   degisir ama hukum degismez) => yeniden_bolme. Gercek belirtec YALNIZ ambarda elle eklenmis/onarilmis kayit tasiyan anahtara.
  $elleAn = New-Object 'System.Collections.Generic.HashSet[string]'
  foreach($a in $ambar.Keys){ $ay2 = $ayna[$a]; if(-not $ay2 -or (Bosluk $ambar[$a].metin) -cne (Bosluk $ay2.metin)){ $k2 = MdAnahtar $a; if($k2){ [void]$elleAn.Add($k2) } } }
  $eM=@{}; foreach($a in $ambar.Keys){ $k = MdAnahtar $a; if($k){ $eM[$k] = "$($eM[$k]) $($ambar[$a].metin)" } }
  $yM=@{}; foreach($b in $yeni){ $a="$($b.kaynak_ad)"; $k = MdAnahtar $a; if($k){ $m = if($koru.Contains($a)){ $ambar[$a].metin } else { $b.metin }; $yM[$k] = "$($yM[$k]) $m" } }
  $isaret = @{}
  foreach($k in $eM.Keys){ if(-not $yM.ContainsKey($k)){ continue }; if((Bosluk $eM[$k]) -ceq (Bosluk $yM[$k])){ continue }
    if(-not $elleAn.Contains($k) -or (KelimeKume $eM[$k]) -ceq (KelimeKume $yM[$k])){ $isaret[$k] = [ordered]@{ belirsiz=$false; belirtecler=@(); yeniden_bolme=$true } }
    else { $af = MdAyirtEdici $eM[$k] $yM[$k]; $isaret[$k] = [ordered]@{ belirsiz=($null -eq $af); belirtecler=@($af); yeniden_bolme=$false } } }
  if($ekle.Count){ $kE.Add("$slug ad dizisi farkli (eklenecek $($ekle.Count))") }
  # kelime denetimi: silinen kelimeler dipnotlardan gelmeli, eklenen kelime olmamali
  $eskiK=@{}; foreach($a in $ambar.Keys){ foreach($w in ("$($ambar[$a].metin)" -split '\s+')){ if($w){ $eskiK[$w] = 1 + [int]$eskiK[$w] } } }
  $yeniK=@{}; foreach($b in $yeni){ $a="$($b.kaynak_ad)"; $m = if($koru.Contains($a)){ $ambar[$a].metin } else { $b.metin }; foreach($w in ("$m" -split '\s+')){ if($w){ $yeniK[$w] = 1 + [int]$yeniK[$w] } } }
  $dnK=@{}; foreach($t in $dn.ayiklanan){ foreach($w in ("$t" -split '\s+')){ if($w){ $dnK[$w] = 1 + [int]$dnK[$w] } } }
  $fazla = @($yeniK.Keys | Where-Object { [int]$yeniK[$_] -gt [int]$eskiK[$_] }); $yabanci = @($eskiK.Keys | Where-Object { ([int]$eskiK[$_] - [int]$yeniK[$_]) -gt [int]$dnK[$_] })
  if($fazla.Count){ $kE.Add("$slug eklenen kelime $($fazla.Count) (or. $(($fazla | Select-Object -First 3) -join ' '))") }
  if($yabanci.Count){ $kE.Add("$slug dipnot disi silinen kelime $($yabanci.Count) (or. $(($yabanci | Select-Object -First 3) -join ' '))") }
  if($kE.Count){ foreach($e in $kE){ $atlanan.Add($e) }; continue }
  if(-not ($guncelle.Count)){ continue }
  $isler.Add([pscustomobject]@{ slug=$slug; law=$law; aynaJ=$aynaJ; yeni=$yeni; yaz=$guncelle; ekle=$ekle; sil=$silinecek; koru=$koru; isaret=$isaret; ambar=$ambar })
  Write-Host ("{0}: ambar {1} · yeni {2} · guncelle {3} · ekle {4} · sil {5} · koru {6} ({7}) · nobetci isaret {8} (yeniden_bolme {9}, gercek belirtec {10})" -f $slug, $ambar.PSBase.Count, $yeni.Count, $guncelle.Count, $ekle.Count, $silinecek.Count, $koru.Count, ($koru -join ' ; '), $isaret.PSBase.Count, @($isaret.Values | Where-Object { $_.yeniden_bolme }).Count, @($isaret.Values | Where-Object { -not $_.yeniden_bolme }).Count)
  foreach($k in @()){ if(-not $isaret[$k].yeniden_bolme){ Write-Host ("   gercek degisiklik {0}: belirsiz={1} belirtec={2}" -f $k, $isaret[$k].belirsiz, ((@($isaret[$k].belirtecler) | Select-Object -First 12) -join ',')) } }
  if($false){ Write-Host ("   eklenecek: " + ((@($ekle | ForEach-Object { $_.kaynak_ad })) -join ' ; ')) }
  if($false){ Write-Host ("   silinecek: " + ((@($silinecek | ForEach-Object { $_.kaynak_ad })) -join ' ; ')) }
}
Write-Host ("OZET: yazilacak kaynak {0} · kayit {1} · dipnotsuz {2} · atlanan {3}" -f $isler.Count, (($isler | ForEach-Object { $_.yaz.Count }) | Measure-Object -Sum).Sum, $dipnotsuz, $atlanan.Count)
foreach($e in $atlanan){ Write-Host "  ATLANDI: $e" -ForegroundColor Yellow }
if(-not $isler.Count){ Write-Host 'Yazilacak kaynak yok.'; exit 0 }
if(-not $Yaz){ Write-Host 'KURU KOSU: ambara/dosyaya yazilmadi.'; exit 0 }

# ---------------- YAZ ----------------
$eapEski = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
$kosan = @(& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'bulut-kosan-etiketler.ps1') -Kati)
$kosanKod = $LASTEXITCODE; $ErrorActionPreference = $eapEski
if($kosanKod -ne 0 -or @($kosan | Where-Object { "$_".Trim() }).Count){ Write-Host ('DURDU: bulutta kosan parti var / okunamadi -> ' + (($kosan | Select-Object -First 5) -join ' ')); exit 3 }
$dkY = Join-Path $kok 'veri\mevzuat\_degisen-kokler.json'
$dk=[ordered]@{}; if(Test-Path $dkY){ foreach($pp in (Get-Content $dkY -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler.PSObject.Properties){ $dk[$pp.Name]=$pp.Value } }
foreach($is in $isler){
  # 1) yedek (bag tasimasi icin eski satirlar)
  $yedek = Join-Path $kok ("veri\fabrika\yedek-" + $is.slug.ToUpper() + "-$zaman.json")
  [IO.File]::WriteAllText($yedek, (ConvertTo-Json -InputObject @($is.ambar.Values | ForEach-Object { [ordered]@{ kaynak_ad=$_.kaynak_ad; baslik=$_.baslik; metin=$_.metin } }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
  # 2) guncelle (id ile upsert) · ekle (insert) · sil (id ile)
  $gd = @($is.yaz | ForEach-Object { [ordered]@{ id=$_.id; tur=$_.am.tur; kaynak_ad=$_.b.kaynak_ad; baslik="$($_.b.baslik)"; metin=$_.b.metin; kaynak_url=$_.am.kaynak_url; belge_tarihi=$_.am.belge_tarihi } })
  for($i=0; $i -lt $gd.Count; $i += 100){ SbYaz 'Post' "$SB_URL/rest/v1/dokumanlar?on_conflict=id" @($gd[$i..([Math]::Min($i+100,$gd.Count)-1)]) 'resolution=merge-duplicates,return=minimal' }
  $ed = @($is.ekle | ForEach-Object { [ordered]@{ tur='kanun-madde'; kaynak_ad=$_.kaynak_ad; baslik="$($_.baslik)"; metin=$_.metin; kaynak_url=$_.kaynak_url; belge_tarihi=$bugun } })
  if($ed.Count){ SbYaz 'Post' "$SB_URL/rest/v1/dokumanlar" $ed 'return=minimal' }
  foreach($s in $is.sil){ SbYaz 'Delete' "$SB_URL/rest/v1/dokumanlar?id=eq.$($s.id)" $null 'return=minimal' }
  # 3) geri oku: ambar ad kumesi = yeni ad kumesi; metin = yeni (koru haric)
  $son = @{}; foreach($x in (SbGetHepsi ("$SB_URL/rest/v1/dokumanlar?select=kaynak_ad,baslik,metin&tur=eq.kanun-madde&kaynak_ad=like." + [uri]::EscapeDataString("$($is.law.ad) *") + "&order=id.asc"))){ $son["$($x.kaynak_ad)"] = $x }
  $tutmayan = New-Object System.Collections.Generic.List[string]
  foreach($b in $is.yeni){ $a="$($b.kaynak_ad)"; $x = $son[$a]; if(-not $x){ $tutmayan.Add("YOK $a"); continue }
    if($is.koru.Contains($a)){ continue }
    if((Bosluk $x.metin) -cne (Bosluk $b.metin) -or "$($x.baslik)" -cne "$($b.baslik)"){ $tutmayan.Add("FARKLI $a") } }
  foreach($a in $son.Keys){ if(-not ($is.yeni | Where-Object { "$($_.kaynak_ad)" -eq $a })){ $tutmayan.Add("FAZLA $a") } }
  Write-Host ("{0} GERI OKUMA: ambar {1} satir · tutmayan {2} {3}" -f $is.slug, $son.PSBase.Count, $tutmayan.Count, (($tutmayan | Select-Object -First 5) -join ' ; '))
  if($tutmayan.Count){ throw "$($is.slug) geri okuma tutmadi" }
  # 4) ayna = yutucunun ciktisi (yutucu bicimi)
  $docs = @($is.yeni | ForEach-Object { [ordered]@{ tur='kanun-madde'; kaynak_ad=$_.kaynak_ad; baslik=$_.baslik; metin=$_.metin; kaynak_url=$_.kaynak_url; belge_tarihi=$bugun } })
  [IO.File]::WriteAllBytes((Join-Path $kok "veri\mevzuat\$($is.slug).json"), [Text.Encoding]::UTF8.GetBytes((@{ belgeler=$docs } | ConvertTo-Json -Depth 6)))
  # 5) nobetci isaretleri
  foreach($k in $is.isaret.Keys){ $v = $is.isaret[$k]
    if($dk.Contains($k) -and $dk[$k]){ $eskiE = $dk[$k]; $dk[$k] = [ordered]@{ tarih=(Get-Date -Format 'yyyy-MM-dd HH:mm'); kaynak=$is.slug; belirsiz=([bool]$eskiE.belirsiz -or $v.belirsiz); belirtecler=@(@($eskiE.belirtecler) + @($v.belirtecler) | Where-Object { $_ } | Select-Object -Unique); yeniden_bolme=$false } }
    else { $dk[$k] = [ordered]@{ tarih=(Get-Date -Format 'yyyy-MM-dd HH:mm'); kaynak=$is.slug; belirsiz=$v.belirsiz; belirtecler=@($v.belirtecler); yeniden_bolme=$v.yeniden_bolme } } }
  Write-Host ("{0} YAZILDI: guncelle {1} · ekle {2} · sil {3} · yedek {4}" -f $is.slug, $is.yaz.Count, $is.ekle.Count, $is.sil.Count, (Split-Path -Leaf $yedek))
}
[IO.File]::WriteAllText($dkY, (ConvertTo-Json -InputObject ([ordered]@{ aciklama='Madde metni değişince eski/yeni ayırt edici belirteçler (motor/mevzuat-yut.ps1). Nöbetçi, soru bu belirteçlerden hiçbirine değmiyorsa çekmez; belirsiz=true ise hepsini çeker.'; maddeler=$dk }) -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host 'TAMAM: ayna + _degisen-kokler yazildi. Simdi: commit + push, sonra arac/kaynak-bolunme-etki.ps1 (GVK yedegiyle) bag tasimasi.'
