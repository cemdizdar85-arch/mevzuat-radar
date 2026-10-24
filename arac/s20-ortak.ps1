# arac/s20-ortak.ps1 — SGS "Son 20 Gün" bulut işleri ORTAK PARÇASI (24.10.2026, Cem: kör kalibrasyon + açıklama hakemi banka adayları)
# Dot-source edilir (param() YOK — çağıranın değişkenini ezmez). Önce motor/api-hedef.ps1 dot-source edilmiş olmalı.
#   S20Json / S20JsonYaz            → UTF-8 (BOM'suz) oku/yaz
#   S20Fiyat $model                 → Get-BedelFiyat'tan EN UZUN önekle fiyat (Get-BedelOzet ile aynı eşleşme)
#   S20Tahmin $isler $ciktiJ        → iş başı tahmini + en kötü durum USD (toplu ×0,5; girdi jetonu = karakter/1,6 temkinli, 30.09 ölçümü)
#   S20DalgaKos                     → ÖNCE DALGA, SONRA HEPSİ: ilk dalga en kötü durumla tavana sığdırılır, gerçek bedel ölçülür,
#                                     kalan sorular ÖLÇÜLEN oran × güven payıyla öncelik sırasında tavana kadar gönderilir; sığmayan "bütçe yetmedi"
#   S20BedelYaz $etiket $ders $yazan → kesin satır bedel_kaydi'na (Save-BedelKesin) + ara kaydı kapatır
#   S20EmirIsle                     → emir kapısı (aciklama-yenile deseni): onaylı + damgasız emir koşar, bitince damgalanır
# 🚫 GÖRMEZ: ikinci dalga gönderildikten sonra gerçek bedelin tahmini aşması (toplu parti yarıda kesilemez; payı 1,25 ölçülen
#   orana uygulanır) · zaman aşımından sonra başka koşuda bedava hasat edilen cevabın bedeli (api-hedef bağlan yolu deftere yazmaz).

# .NET dosya çağrıları PS konumunu değil süreç dizinini esas alır → göreli yol PS konumuna göre mutlaklaştırılır (Linux'ta da)
function S20Yol([string]$yol) { if ([IO.Path]::IsPathRooted($yol)) { return $yol }; return (Join-Path (Get-Location).Path $yol) }
function S20Json([string]$yol) { return (ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((S20Yol $yol), [Text.Encoding]::UTF8))) }
function S20JsonYaz([string]$yol, $nesne, [int]$derinlik = 10) {
  $yol = S20Yol $yol; $dz = Split-Path $yol -Parent; if ($dz -and -not (Test-Path $dz)) { New-Item -ItemType Directory -Force $dz | Out-Null }
  [IO.File]::WriteAllText($yol, (ConvertTo-Json -InputObject $nesne -Depth $derinlik), [Text.UTF8Encoding]::new($false))
}

function S20Fiyat([string]$model) {
  $f = Get-BedelFiyat; $fy = $null; $kUz = -1
  foreach ($k in $f.Keys) { if ($model -like "$k*" -and $k.Length -gt $kUz) { $fy = $f[$k]; $kUz = $k.Length } }
  if (-not $fy) { throw "fiyatı bilinmeyen model: $model (bedel hesaplanamaz, gönderilmez)" }
  return $fy
}

# iş başı tahmin: girdi = istem karakteri / 1,6 · çıktı = ölçülmüş ortalama (en çok maxTok) · en kötü = çıktı maxTok'a kadar
function S20Tahmin([array]$isler, [int]$ciktiJ) {
  $t = @{}; $k = @{}
  foreach ($i in $isler) {
    $fy = S20Fiyat "$($i.model)"
    $kar = 0; foreach ($b in @($i.icerik)) { if ($b -is [string]) { $kar += $b.Length } elseif ($b -is [hashtable]) { $kar += "$($b['text'])".Length } else { $kar += "$($b.text)".Length } }
    $gJ = $kar / 1.6; $mt = [int]$i.maxTok
    $t["$($i.id)"] = 0.5 * (($gJ / 1e6) * $fy[0] + ([math]::Min($ciktiJ, $mt) / 1e6) * $fy[1])
    $k["$($i.id)"] = 0.5 * (($gJ / 1e6) * $fy[0] + ($mt / 1e6) * $fy[1])
  }
  return @{ tahmin = $t; enKotu = $k }
}
function S20Topla([hashtable]$h, [array]$idler) { $s = 0.0; foreach ($x in $idler) { $s += [double]$h["$x"] }; return $s }
function S20Harcanan { return [double](Get-BedelOzet).toplamUsd }

function S20DalgaKos {
  param([Parameter(Mandatory = $true)][array]$Isler, [Parameter(Mandatory = $true)][hashtable]$Tahmin, [Parameter(Mandatory = $true)][hashtable]$EnKotu,
    [Parameter(Mandatory = $true)][double]$Tavan, [Parameter(Mandatory = $true)][string]$Etiket, [int]$IlkDalga = 30, [bool]$Onbelleksiz = $false,
    [int]$BeklemeDk = 290, [string]$ParmakTuz = '', [double]$Pay = 1.25, [double]$OncekiHarcama = 0)
  $don = @{ sonuc = @{}; hata = @{}; butce_yok = (New-Object System.Collections.Generic.List[string]); zaman_asimi = ''; oran = $null; gonderilen = 0 }
  $kalan = New-Object System.Collections.Generic.List[object]; foreach ($i in $Isler) { $kalan.Add($i) }
  if (-not $kalan.Count) { return $don }
  # --- DALGA 1: EN KÖTÜ DURUMLA tavana sığan ilk IlkDalga iş (gönderilen hiçbir parti tavanı aşamaz) ---
  $d1 = New-Object System.Collections.Generic.List[object]; $cum = 0.0; $h0 = $OncekiHarcama + (S20Harcanan)
  foreach ($i in $kalan) { if ($d1.Count -ge $IlkDalga) { break }; $e = [double]$EnKotu["$($i.id)"]; if ($h0 + $cum + $e -gt $Tavan) { break }; $cum += $e; $d1.Add($i) }
  if (-not $d1.Count) { foreach ($i in $kalan) { $don.butce_yok.Add("$($i.id)") }; Write-Host "  DALGA 1: tavan ($Tavan USD) tek işin en kötü durumunu bile karşılamıyor — GÖNDERİLMEDİ" -ForegroundColor Red; return $don }
  Write-Host ("  DALGA 1: {0} iş · tahmini {1:N3} USD · en kötü {2:N3} USD · tavan {3} USD" -f $d1.Count, (S20Topla $Tahmin @($d1 | ForEach-Object { $_.id })), $cum, $Tavan) -ForegroundColor Cyan
  $y1 = Invoke-ClaudeToplu -Isler $d1.ToArray() -Etiket $Etiket -BeklemeDk $BeklemeDk -OnbelleksizToplu:$Onbelleksiz -ParmakTuz $ParmakTuz
  $don.gonderilen += $d1.Count
  S20SonucAl $don $y1
  foreach ($i in $d1) { [void]$kalan.Remove($i) }
  if ($don.zaman_asimi) { return $don }
  # --- ÖLÇÜLEN ORAN: gerçek bedel / tahmin (cevabı gelen işler). Bedava hasatta artış 0 → oran tahmine eşit (1) sayılır ---
  $h1 = $OncekiHarcama + (S20Harcanan); $cevapli = @($d1 | Where-Object { $don.sonuc.ContainsKey("$($_.id)") } | ForEach-Object { "$($_.id)" })
  $tCev = S20Topla $Tahmin $cevapli
  $oran = $(if (($h1 - $h0) -gt 0 -and $tCev -gt 0) { ($h1 - $h0) / $tCev } else { 1.0 }); $don.oran = [math]::Round($oran, 3)
  Write-Host ("  DALGA 1 ÖLÇÜLDÜ: gerçek {0:N3} USD / tahmin {1:N3} USD → oran {2:N2} (kalan sorulara ×{3} güven payıyla uygulanır)" -f ($h1 - $h0), $tCev, $oran, $Pay) -ForegroundColor Cyan
  if (-not $kalan.Count) { return $don }
  # --- DALGA 2: öncelik sırasında, ölçülen oran × pay ile tavana sığan önek; ilk sığmayanda DUR ---
  $d2 = New-Object System.Collections.Generic.List[object]; $cum2 = 0.0; $dur = $false
  foreach ($i in $kalan) { if (-not $dur) { $e = [double]$Tahmin["$($i.id)"] * $oran * $Pay; if ($h1 + $cum2 + $e -le $Tavan) { $cum2 += $e; $d2.Add($i); continue } else { $dur = $true } }; $don.butce_yok.Add("$($i.id)") }
  if ($don.butce_yok.Count) { Write-Host ("  BÜTÇE: {0} iş tavana sığmadı → GÖNDERİLMEDİ ('bütçe yetmedi')" -f $don.butce_yok.Count) -ForegroundColor Yellow }
  if (-not $d2.Count) { return $don }
  Write-Host ("  DALGA 2: {0} iş · ölçülen oranla tahmini {1:N3} USD · harcanan {2:N3} USD · tavan {3} USD" -f $d2.Count, $cum2, $h1, $Tavan) -ForegroundColor Cyan
  $y2 = Invoke-ClaudeToplu -Isler $d2.ToArray() -Etiket $Etiket -BeklemeDk $BeklemeDk -OnbelleksizToplu:$Onbelleksiz -ParmakTuz $ParmakTuz
  $don.gonderilen += $d2.Count
  S20SonucAl $don $y2
  return $don
}
function S20SonucAl($don, $y) {
  if (-not $y) { return }
  foreach ($k in @($y.Keys)) {
    if ($k -eq '__hata') { foreach ($hk in @($y[$k].Keys)) { $don.hata[$hk] = $y[$k][$hk] } }
    elseif ($k -eq '__zaman_asimi') { $don.zaman_asimi = "$($y[$k])" }
    elseif ($k -notlike '__*') { $don.sonuc[$k] = $y[$k] }
  }
}

# kesin bedel satırı ambara (bedel_kaydi) — kalip-parti-uret.ps1 BedelDefterYaz ile aynı yol (Save-BedelKesin + ara kaydı kapat)
function S20BedelYaz([string]$etiket, [string]$ders, [string]$yazan) {
  $bz = Get-BedelOzet
  foreach ($s in @($bz.satirlar)) { Write-Host ("  BEDEL {0}: {1} çağrı · girdi {2} · çıktı {3} · ≈{4} USD" -f $s.model, $s.cagri, $s.girdi, $s.cikti, $s.usd) -ForegroundColor DarkCyan }
  if (-not @($bz.satirlar).Count -or [double]$bz.toplamUsd -le 0) { Write-Host "  BEDEL: bu koşuda ödenen istek yok (0 USD) — deftere satır yazılmadı"; return 0.0 }
  $z = Get-Date -Format 'yyyy-MM-dd HH:mm'
  if (Save-BedelKesin $z $etiket $ders ([double]$bz.toplamUsd) ([bool]$bz.fiyatVarsayim) $bz.satirlar $yazan) { Save-BedelAra $etiket $true; Write-Host "  BEDEL: bedel_kaydi'na yazıldı · $etiket · $($bz.toplamUsd) USD" -ForegroundColor Cyan }
  else { Write-Host "  !! BEDEL bedel_kaydi'na YAZILAMADI ($etiket, $($bz.toplamUsd) USD) — ara kayıt açık kaldı, arac/bedel-ara-kapat.ps1 yazar" -ForegroundColor Red }
  return [double]$bz.toplamUsd
}

# EMİR KAPISI. $Kos: { param($em, [bool]$odeme) ... } → @{ durum='tamam'|'kuru'|'bekliyor'; usd; cikti }
#   onay:true + damgasız + -Calistir → PARALI; aksi her durumda KURU (0 USD). 'bekliyor' (toplu zaman aşımı) damgalanmaz, 75 ile biter.
function S20EmirIsle([string]$EmirYol, [bool]$CalistirIzni, [scriptblock]$Kos) {
  if (-not (Test-Path $EmirYol)) { throw "emir dosyası yok: $EmirYol" }
  $ev = S20Json $EmirYol; $kod = 0
  $acik = @($ev.emirler | Where-Object { $_ -and -not $_.uygulandi })
  if (-not $acik.Count) { Write-Host "Damgasız emir yok — 0 USD."; return 0 }
  foreach ($em in $acik) {
    $odeme = ($CalistirIzni -and $em.onay -eq $true)
    Write-Host ""
    Write-Host ("===== EMİR #{0} · onay {1} · tavan {2} USD · {3}" -f $em.no, $em.onay, $em.tavan_usd, $(if ($odeme) { 'PARALI' } else { 'KURU (0 USD)' })) -ForegroundColor Cyan
    $r = $null; $ok = $true
    try { $r = & $Kos $em $odeme } catch { $ok = $false; Write-Host ("DÜŞTÜ: {0}" -f $_.Exception.Message) -ForegroundColor Red }
    if (-not $odeme) { continue }   # KURU emir dosyasına dokunmaz
    if ($ok -and $r -and "$($r.durum)" -eq 'tamam') {
      $em | Add-Member -NotePropertyName uygulandi -NotePropertyValue (Get-Date -Format 'dd.MM.yyyy HH:mm') -Force
      $em | Add-Member -NotePropertyName gercek_usd -NotePropertyValue ([math]::Round([double]$r.usd, 3)) -Force
      $em | Add-Member -NotePropertyName sonuc -NotePropertyValue "$($r.cikti)" -Force
    } elseif ($ok -and $r -and "$($r.durum)" -eq 'bekliyor') {
      $hu = 0.0; if ($em.PSObject.Properties['harcanan_usd']) { $hu = [double]$em.harcanan_usd }
      $em | Add-Member -NotePropertyName harcanan_usd -NotePropertyValue ([math]::Round($hu + [double]$r.usd, 3)) -Force
      $em | Add-Member -NotePropertyName durum -NotePropertyValue ("toplu kuyruk bitmedi ({0}) — aynı emir yeniden koşunca kuyruktaki partiye bağlanır/bedava hasat eder" -f (Get-Date -Format 'dd.MM.yyyy HH:mm')) -Force
      S20JsonYaz $EmirYol $ev; Write-Host "Toplu kuyruk bitmedi — emir damgalanmadı, 75 ile çıkılıyor (sonraki emirlere geçilmez)." -ForegroundColor Yellow
      return 75
    } else {
      $d = 0; if ($em.PSObject.Properties['deneme']) { $d = [int]$em.deneme }; $d++
      $em | Add-Member -NotePropertyName deneme -NotePropertyValue $d -Force
      if ($d -ge 3) { $em | Add-Member -NotePropertyName uygulandi -NotePropertyValue "KAPATILDI: 3 denemede koşmadı" -Force }
      S20JsonYaz $EmirYol $ev; Write-Host "Emir düştü — SONRAKİNE GEÇİLMİYOR (aynı kusur onu da düşürür, üst üste para yakar)." -ForegroundColor Red
      return 1
    }
    S20JsonYaz $EmirYol $ev
  }
  return $kod
}

# ===== AÇIKLAMA HAKEMİ (banka) ORTAK PARÇALARI — s20-ah-banka.ps1 ve s20-esdegerlik-sinavi.ps1 aynı yolu kullanır =====
# --- üretimdeki ayarlar: AciklamaHakemUretim gövdesinden (model, maxTok, AciklamaHakemIs'e verilen effort, -OnbelleksizToplu) ---
function S20AhUretimAyari([string]$yol) {
  $tk = $null; $hh = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseFile($yol, [ref]$tk, [ref]$hh)
  if ($hh -and @($hh).Count) { throw "AH: üretim dosyası ayrıştırılamadı: $(@($hh)[0].Message)" }
  $fn = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'AciklamaHakemUretim' }, $true))
  if ($fn.Count -ne 1) { throw "AH: AciklamaHakemUretim $($fn.Count) kez bulundu" }
  $tekAta = { param($ad) $l = @($fn[0].Body.FindAll({ param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq $ad }, $true)); if ($l.Count -ne 1) { throw "AH: '$ad' ataması $($l.Count) kez" }; $l[0].Right.Expression.Value }
  $ahIs = @($fn[0].Body.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'AciklamaHakemIs' }, $true))
  if ($ahIs.Count -ne 1) { throw "AH: AciklamaHakemIs çağrısı $($ahIs.Count) kez" }
  $el = $ahIs[0].CommandElements
  if ($el.Count -ne 6 -or $el[3].Extent.Text -ne '$model' -or $el[5].Extent.Text -ne '$maxTok') { throw "AH: AciklamaHakemIs çağrı biçimi beklenen değil: $($ahIs[0].Extent.Text)" }
  $top = @($fn[0].Body.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Invoke-ClaudeToplu' }, $true))
  if ($top.Count -ne 1) { throw "AH: Invoke-ClaudeToplu çağrısı $($top.Count) kez" }
  $onb = [bool]@($top[0].CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'OnbelleksizToplu' }).Count
  return [pscustomobject]@{ model = [string](& $tekAta '$model'); maxTok = [int](& $tekAta '$maxTok'); effort = [string]$el[4].Value; onbelleksiz = $onb }
}
# --- ambar: yalnız istenen kayıtlar (etiket başına en çok 20 anahtar bir istekte) ---
function S20AmbarKayit([string[]]$soruIdler) {
  $anah = Get-SbAnahtar; if (-not $anah) { throw 'SUPABASE_SERVICE_KEY yok — kayıtlar okunamaz' }
  $bas = @{ apikey = $anah; Authorization = "Bearer $anah"; Accept = 'application/json'; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
  $grup = [ordered]@{}; foreach ($s in $soruIdler) { $p = $s -split '/', 2; if ($p.Count -ne 2 -or $p[0] -notmatch '^[A-Za-z0-9_.-]+$' -or $p[1] -notmatch '^[A-Za-z0-9_.-]+$') { continue }; if (-not $grup.Contains($p[0])) { $grup[$p[0]] = New-Object System.Collections.Generic.List[string] }; if (-not $grup[$p[0]].Contains($p[1])) { $grup[$p[0]].Add($p[1]) } }
  $out = @{}; $bayt = 0
  foreach ($et in $grup.Keys) {
    $kl = $grup[$et]
    for ($i = 0; $i -lt $kl.Count; $i += 20) {
      $parca = @($kl[$i..([math]::Min($i + 20, $kl.Count) - 1)])
      $sec = (@(for ($j = 0; $j -lt $parca.Count; $j++) { "q${j}:icerik->`"$($parca[$j])`"" }) -join ',')
      $u = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti?select=' + [uri]::EscapeDataString($sec) + '&etiket=eq.' + [uri]::EscapeDataString($et)
      $w = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $bas -TimeoutSec 120
      $ham = $(if ($w.Content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($w.Content) } else { [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) }); $bayt += $ham.Length
      $sat = @(ConvertFrom-Json -InputObject $ham | ForEach-Object { $_ })
      if (-not $sat.Count) { continue }
      for ($j = 0; $j -lt $parca.Count; $j++) { $v = $sat[0]."q$j"; if ($v) { $out["$et/$($parca[$j])"] = $v } }
    }
  }
  Write-Host ("AMBAR: {0} etiket · {1} kayıt istendi · {2} bulundu · ≈{3} KB indi (yalnız istenen kayıtlar)" -f $grup.Count, @($soruIdler).Count, $out.Count, [math]::Round($bayt / 1024))
  return $out
}
function S20AhId([string]$soruId) { return ($soruId -replace '/', '__') }

# ===== AMBAR SİSTEM SATIRI (hazir-senkron deseni) — depoya girmeyecek ayrıntı (kusur gerekçeleri) buraya =====
# kalip_parti satırı: etiket '__s20/<ad>', sinav 'SISTEM' (soru sayımları sinav=SGS/SMMM/KGK süzer, bu satır girmez). Yazılır, GERİ OKUNUR,
#   kanonik (anahtar sıralı) metinleri kıyaslanır; tutmazsa throw (çağıran depoya yazmaz, emir damgalanmaz).
function S20Kanonik($v) {
  if ($null -eq $v) { return 'null' }
  if ($v -is [datetime]) { return (ConvertTo-Json -InputObject $v.ToString('yyyy-MM-dd HH:mm') -Compress) }
  if ($v -is [string]) { return (ConvertTo-Json -InputObject $v -Compress) }
  if ($v -is [bool]) { return $(if ($v) { 'true' } else { 'false' }) }
  if ($v -is [ValueType]) { return ([double]$v).ToString('R', [Globalization.CultureInfo]::InvariantCulture) }
  if ($v -is [System.Collections.IDictionary]) { return '{' + ((@($v.Keys | ForEach-Object { "$_" }) | Sort-Object -CaseSensitive | ForEach-Object { (ConvertTo-Json -InputObject $_ -Compress) + ':' + (S20Kanonik $v[$_]) }) -join ',') + '}' }
  if ($v -is [System.Collections.IEnumerable]) { return '[' + ((@($v | ForEach-Object { S20Kanonik $_ })) -join ',') + ']' }
  $h = [ordered]@{}; foreach ($p in $v.PSObject.Properties) { $h[$p.Name] = $p.Value }; return (S20Kanonik $h)
}
function S20AmbarBaslik { $a = Get-SbAnahtar; if (-not $a) { throw 'SUPABASE_SERVICE_KEY yok' }; return @{ apikey = $a; Authorization = "Bearer $a"; Accept = 'application/json'; 'User-Agent' = 'mevzuat-radar-robot/1.0' } }
function S20AmbarSistemOku([string]$etiket) {
  $u = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti?select=etiket,sinav,icerik&etiket=eq.' + [uri]::EscapeDataString($etiket)
  $w = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers (S20AmbarBaslik) -TimeoutSec 120
  $sat = @(ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())) | ForEach-Object { $_ } | Where-Object { $_ })
  if (-not $sat.Count) { return $null }; $ic = $sat[0].icerik; if ($ic -is [string]) { $ic = ConvertFrom-Json -InputObject $ic }
  return [pscustomobject]@{ etiket = $sat[0].etiket; sinav = $sat[0].sinav; icerik = $ic }
}
function S20AmbarSistemYaz([string]$etiket, [string]$yazan, $icerik) {
  if ($etiket -notmatch '^__s20/[a-z0-9][a-z0-9-]{1,80}$') { throw "S20 ambar etiketi '__s20/<ad>' olmalı: '$etiket'" }
  $govde = [ordered]@{ etiket = $etiket; sinav = 'SISTEM'; yazan = $yazan; icerik = $icerik }
  $bayt = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $govde -Depth 12 -Compress))
  $bas = (S20AmbarBaslik) + @{ Prefer = 'resolution=merge-duplicates,return=minimal' }
  [void](Invoke-RestMethod -Method Post -Uri 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti?on_conflict=etiket' -Headers $bas -ContentType 'application/json; charset=utf-8' -Body $bayt -TimeoutSec 120)
  $geri = S20AmbarSistemOku $etiket
  if (-not $geri) { throw "AMBAR GERİ OKUMA: '$etiket' satırı yok" }
  if ("$($geri.sinav)" -ne 'SISTEM') { throw "AMBAR GERİ OKUMA: '$etiket' sinav '$($geri.sinav)' (SISTEM bekleniyordu)" }
  $k1 = S20Kanonik (ConvertFrom-Json -InputObject (ConvertTo-Json -InputObject $icerik -Depth 12 -Compress)); $k2 = S20Kanonik $geri.icerik
  if ($k1 -cne $k2) { throw "AMBAR GERİ OKUMA TUTMADI: '$etiket' (yazılan $($k1.Length) kr, okunan $($k2.Length) kr)" }
  Write-Host ("  AMBAR: '{0}' yazıldı + geri okundu, kanonik metin birebir ({1} kr, sha {2})" -f $etiket, $k1.Length, (S20Sha256 $k1).Substring(0, 12)) -ForegroundColor Cyan
  return $true
}
function S20Sha256([string]$m) { $s = [Security.Cryptography.SHA256]::Create(); try { return (($s.ComputeHash([Text.Encoding]::UTF8.GetBytes($m)) | ForEach-Object { $_.ToString('x2') }) -join '') } finally { $s.Dispose() } }