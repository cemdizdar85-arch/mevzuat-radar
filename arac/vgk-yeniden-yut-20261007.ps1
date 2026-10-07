# ============================================================================
#  VUK · GVK · KDVK YENIDEN YUTMA (07.10.2026, Cem "evet başlat")
#  NEDEN: bu uc kanun 23.09'dan beri hic yeniden yutulmadi. O gun duzeltilen "Mulga; Yeniden duzenleme" kurali yuzunden
#  ambarda HIC OLMAYAN maddeler: GVK muk. m.121 (vergiye uyumlu mukellef %5 indirimi), muk. m.81 (deger artisi kazanci),
#  m.20, m.32, m.33; KDVK m.38 (hasilat esasli). Ayrica 06.10 baslik sizmasi: VUK 45 · GVK 24 · KDVK 16 madde sonunda
#  sonraki maddenin basligi. arac/baslik-tasima-20261006.ps1 bunlari yazamadi: ayna ad dizisi yeni ciktiyla ayni degil.
#  NE YAPAR (yalniz bu uc kaynak, motor/mevzuat-yut.ps1'in parcalayicisi):
#   - kaynak metin hash'i _durum.json ile AYNI olmali (metin degismedi)
#   - KORU: ambarda aynadan farkli (elle onarilmis) VE yeni yutmanin degistirmedigi kayit yazilmaz (VUK m.283, GVK m.103/104)
#   - -UstuneYaz: ambarda elle duran ama yeni ciktinin DOGRUSUNU bildigimiz kayitlar (or. VUK m.370 [1/3]: ayni metin + baslik)
#   - -Sil: yeni ciktida olmayan ambar adlari (bag tasimasi arac/kaynak-bolunme-etki.ps1 ile; yedek veri/fabrika/yedek-*.json)
#   - Listede olmayan bir cakisma/silme varsa DURUR (kuru kosu raporu gosterir).
#   - nobetci: anahtar bazinda eski (ambar) / yeni birlesik metnin KELIME kumesi ayniysa yeniden_bolme (belirtecsiz);
#     degilse MdAyirtEdici ile gercek belirtec (yeni eklenen fikra vb. sorulari cekebilir - dogru davranis).
#  Kullanim: -Kuru (varsayilan) · -Yaz   (bulut-kosan-etiketler -Kati bos degilse DURUR)
# ============================================================================
param([switch]$Yaz, [string[]]$UstuneYaz = @(), [string[]]$Sil = @(), [string]$Rapor = '')
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
foreach($st in $ast.EndBlock.Statements){ if($st -is [System.Management.Automation.Language.FunctionDefinitionAst] -or ($st.Extent.Text -like '$script:TR_HARF*')){ . ([scriptblock]::Create($st.Extent.Text)) } }
$bugun = (Get-Date).ToString('yyyy-MM-dd'); $zaman = Get-Date -Format 'yyyyMMdd-HHmm'
function Bosluk([string]$x){ return (($x -replace '\s+',' ').Trim()) }
function Sha([string]$x){ $sha=[Security.Cryptography.SHA256]::Create(); ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($x))) -replace '-','').Substring(0,16) }
function KelimeKume([string]$x){ return ((@(($x -replace '\s+',' ').Trim() -split ' ' | Sort-Object)) -join ' ') }
function SbGet([string]$u){ for($d=1;;$d++){ try { $r = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $Hb -TimeoutSec 180; return @(([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())) | ConvertFrom-Json | ForEach-Object { $_ }) } catch { if($d -ge 3){ throw }; Start-Sleep -Seconds 10 } } }
function SbYaz([string]$yontem, [string]$u, $govde, [string]$tercih){ for($d=1;;$d++){ try { $bj = if($null -ne $govde){ (ConvertTo-Json -InputObject @($govde) -Depth 4) } else { $null }   # 07.10: dizgi tut - if ifadesinden atanan byte[] object[]e acilip "Empty or invalid json" veriyordu
      if($bj){ Invoke-RestMethod -Method $yontem -Uri $u -Headers ($Hb + @{ Prefer=$tercih }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($bj)) -TimeoutSec 300 | Out-Null } else { Invoke-RestMethod -Method $yontem -Uri $u -Headers ($Hb + @{ Prefer=$tercih }) -TimeoutSec 300 | Out-Null }; return } catch { if($d -ge 4){ if($bj){ [IO.File]::WriteAllText((Join-Path $env:TEMP "vgk-hatali-govde.json"), $bj) }; throw }; Start-Sleep -Seconds (15*$d) } } }

$man = Get-Content (Join-Path $kok 'veri\mevzuat-kaynaklar.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$durum = Get-Content (Join-Path $kok 'veri\mevzuat\_durum.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$ustune = New-Object 'System.Collections.Generic.HashSet[string]'; foreach($x in $UstuneYaz){ [void]$ustune.Add($x) }
$silK = New-Object 'System.Collections.Generic.HashSet[string]'; foreach($x in $Sil){ [void]$silK.Add($x) }
$isler = New-Object System.Collections.Generic.List[object]; $engel = New-Object System.Collections.Generic.List[string]
foreach($slug in 'vuk','gvk','kdv'){
  $law = @($man.kanunlar | Where-Object { $_.slug -eq $slug })[0]
  $hz = Join-Path $kok "veri\mevzuat-hazir\$slug.txt"; $tx = Join-Path $kok "_txt\$slug.txt"
  $txt = if(Test-Path $hz){ $hz } elseif(Test-Path $tx){ $tx } else { throw "$slug metni yok" }
  $raw = Get-Content $txt -Raw -Encoding UTF8; $flat = ($raw -replace "\r?\n"," ") -replace "\s+"," "
  if("$($durum.$slug.hash)" -ne (Sha $flat)){ $engel.Add("$slug hash farkli (metin degismis)"); continue }
  $yeni = @(Parcala (AralikliMaddeDuzelt $flat) "$($law.ad)" ("https://www.mevzuat.gov.tr/mevzuatmetin/$($law.pdfId).pdf") (BaslikSatirlari $raw))
  $aynaJ = Get-Content (Join-Path $kok "veri\mevzuat\$slug.json") -Raw -Encoding UTF8 | ConvertFrom-Json
  $ayna = @{}; foreach($b in @($aynaJ.belgeler)){ $ayna["$($b.kaynak_ad)"] = $b }
  $ambar = @{}; foreach($x in (SbGet ("$SB_URL/rest/v1/dokumanlar?select=id,tur,kaynak_ad,baslik,metin,kaynak_url,belge_tarihi&tur=eq.kanun-madde&kaynak_ad=like." + [uri]::EscapeDataString("$($law.ad) *") + "&order=id.asc&limit=2000"))){ if($ambar.ContainsKey("$($x.kaynak_ad)")){ $engel.Add("$slug ambarda cift ad: $($x.kaynak_ad)") }; $ambar["$($x.kaynak_ad)"] = $x }
  $yeniAd = @{}; foreach($b in $yeni){ $yeniAd["$($b.kaynak_ad)"] = $b }
  $guncelle = New-Object System.Collections.Generic.List[object]; $ekle = New-Object System.Collections.Generic.List[object]; $silinecek = New-Object System.Collections.Generic.List[object]; $koru = New-Object System.Collections.Generic.List[string]
  foreach($b in $yeni){
    $a = "$($b.kaynak_ad)"; $am = $ambar[$a]; $ay = $ayna[$a]
    if(-not $am){ $ekle.Add($b); continue }
    $ambarAynaAyni = ($ay -and (Bosluk $am.metin) -ceq (Bosluk $ay.metin) -and "$($am.baslik)" -ceq "$($ay.baslik)")
    $yeniAmbarAyni = ((Bosluk $am.metin) -ceq (Bosluk $b.metin) -and "$($am.baslik)" -ceq "$($b.baslik)")
    if($yeniAmbarAyni){ continue }
    if($ambarAynaAyni){ $guncelle.Add([pscustomobject]@{ id=$am.id; b=$b; am=$am }); continue }
    # ambar elle degismis
    $yeniAynaAyni = ($ay -and (Bosluk $ay.metin) -ceq (Bosluk $b.metin) -and "$($ay.baslik)" -ceq "$($b.baslik)")
    if($yeniAynaAyni){ $koru.Add($a); continue }
    if($ustune.Contains($a)){ $guncelle.Add([pscustomobject]@{ id=$am.id; b=$b; am=$am }); continue }
    $engel.Add("$slug CAKISMA (elle onarim + yeni yutma degistiriyor): $a")
  }
  foreach($a in $ambar.Keys){ if(-not $yeniAd.ContainsKey($a)){ if($silK.Contains($a)){ $silinecek.Add($ambar[$a]) } else { $engel.Add("$slug SILINECEK AD listede yok: $a") } } }
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
  $isler.Add([pscustomobject]@{ slug=$slug; law=$law; aynaJ=$aynaJ; yeni=$yeni; yaz=$guncelle; ekle=$ekle; sil=$silinecek; koru=$koru; isaret=$isaret; ambar=$ambar })
  Write-Host ("{0}: ambar {1} · yeni {2} · guncelle {3} · ekle {4} · sil {5} · koru {6} ({7}) · nobetci isaret {8} (yeniden_bolme {9}, gercek belirtec {10})" -f $slug, $ambar.PSBase.Count, $yeni.Count, $guncelle.Count, $ekle.Count, $silinecek.Count, $koru.Count, ($koru -join ' ; '), $isaret.PSBase.Count, @($isaret.Values | Where-Object { $_.yeniden_bolme }).Count, @($isaret.Values | Where-Object { -not $_.yeniden_bolme }).Count)
  foreach($k in $isaret.Keys){ if(-not $isaret[$k].yeniden_bolme){ Write-Host ("   gercek degisiklik {0}: belirsiz={1} belirtec={2}" -f $k, $isaret[$k].belirsiz, ((@($isaret[$k].belirtecler) | Select-Object -First 12) -join ',')) } }
  if($ekle.Count){ Write-Host ("   eklenecek: " + ((@($ekle | ForEach-Object { $_.kaynak_ad })) -join ' ; ')) }
  if($silinecek.Count){ Write-Host ("   silinecek: " + ((@($silinecek | ForEach-Object { $_.kaynak_ad })) -join ' ; ')) }
}
foreach($e in $engel){ Write-Host "ENGEL: $e" -ForegroundColor Red }
if($engel.Count){ Write-Host 'DURDU: engel var, hicbir sey yazilmadi.'; exit 2 }
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
  $son = @{}; foreach($x in (SbGet ("$SB_URL/rest/v1/dokumanlar?select=kaynak_ad,baslik,metin&tur=eq.kanun-madde&kaynak_ad=like." + [uri]::EscapeDataString("$($is.law.ad) *") + "&order=id.asc&limit=2000"))){ $son["$($x.kaynak_ad)"] = $x }
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
