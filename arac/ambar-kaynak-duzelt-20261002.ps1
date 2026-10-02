#requires -Version 5.1
# ============================================================================
#  AMBAR KAYNAK DÜZELTMESİ — 02.10.2026 · BEDEL 0 (Cem "hallet")
#
#  NEDEN: 677 kusurlu sorunun elle onarımında (02.10 gece, 28 parça) ajanlar ambarın kendisinin resmî kaynakla
#  çeliştiğini buldu; bu kayıtlar yeni üretime aynı hatayı taşıyordu:
#   · TEORI "Satıştan iadeler"   : iade KDV'si 191'in borcuna (THP 391: işlemden vazgeçilen mal KDV'si 391'de, düzeltmeler 391'e BORÇ;
#                                  THP 191: düzeltmeler ALACAK) → 391
#   · TEORI "Döviz kredisi"      : kredi kur farkı 656 (THP 656: borçlanma kur farkı bu hesaba alınmaz; THP 780: kur farkları) → 780
#   · TEORI "Amortisman yöntemleri": kıst yalnız binek (VUK m.320/3, 7338 s.K.: öteki yeni kıymetlerde gün esası seçimlik)
#   · TEORI "Denetim kanıtı türleri": yazılı temsil mektubu "düşük güvenilirlik" (BDS 500 p.A35: belge sözlüden güvenilir;
#                                  BDS 580: tek başına yeterli değil)
#   · TEORI "Alacak senetleri reeskontu": "VUK iç iskontoyu ister" (VUK m.281 yalnız 'kıymetine irca' der, yöntem koymaz)
#   · VUK (213 s.K.) m.283       : sayfa altındaki m.281 dipnotu (91) + m.284 başlığı ("Kasa mevcudu:") madde metnine yapışmış
#  YÖNTEM (arac/teori-notu-duzelt-20260925.ps1 ile aynı): silmeden YERİNDE metin değişikliği; her eski ifade ambar satırında
#  TAM 1 kez aranır, biri tutmazsa HİÇBİR ŞEY yazılmaz. Eski metin _yerel-veri-kasasi/teori-yedek/ altına; PATCH; geri okuma.
#  ETKİ (KURU koşuda ÖLÇÜLÜR): soru-dayanak nöbetçisi değişen notu/maddeyi anan soruları, eski↔yeni AYIRT EDİCİ belirteçlerden
#   birini taşıyorsa yayından çeker; belirteç yoksa ('belirsiz') notu anan HEPSİNİ çeker. Kuru koşu her düzeltme için belirteçleri
#   ve yayındaki (kasa paket_soru) kaç sorunun çekileceğini yazar; belirsiz ya da -EtkiTavani'nı aşan düzeltme -Uygula'da DURUR.
#  🚫 GÖRMEZ: yerel partide olmayan soru (KÖR sayılır, yazılır) · kasada olmayan (yayın dışı) soru etkisi sayılmaz ·
#   VUK m.283'ün kaynağı veri/mevzuat-hazir/vuk.txt robot çıktısıdır — yutucu yeniden yutarsa dipnot geri gelebilir
#   (TAZELEME BEKLİYOR: mevzuat yutucusuna sayfa-altı dipnot süzgeci; iş emri). THP 652/398 ayrı betik değil, aşağıda -Thp.
#  -Uygula yoksa KURU.
# ============================================================================
param([switch]$Uygula, [int]$EtkiTavani = 20, [switch]$Thp)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'mevzuat-degisti.ps1')
$anahtarSb = "$($env:SUPABASE_SERVICE_KEY)".Trim(); if (-not $anahtarSb) { $anahtarSb = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $anahtarSb) { throw 'SUPABASE_SERVICE_KEY yok' }
$basliklarSb = @{ apikey = $anahtarSb; Authorization = "Bearer $anahtarSb"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$sbKok = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
$tabloAdr = "$sbKok/dokumanlar"
$yedekKlasor = Join-Path (Split-Path -Parent $depoKok) '_yerel-veri-kasasi\teori-yedek'
$dkYol = Join-Path $depoKok 'veri\mevzuat\_degisen-kokler.json'
$tablo = Join-Path $PSScriptRoot 'ambar-kaynak-duzelt-20261002.json'   # düzeltme listesi (yalnız ifade, soru metni yok)
$duzeltmeler = @((Get-Content $tablo -Raw -Encoding UTF8 | ConvertFrom-Json).duzeltmeler | ForEach-Object { $_ })

function SayIfade([string]$metin, [string]$ifade) { $n = 0; $i = 0; while (($i = $metin.IndexOf($ifade, $i, [StringComparison]::Ordinal)) -ge 0) { $n++; $i += $ifade.Length }; return $n }
function SbGet([string]$yol) { $r = Invoke-WebRequest -UseBasicParsing -Uri "$sbKok/$yol" -Headers $basliklarSb -TimeoutSec 180; return (ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()))) }

# ---------- THP: hatalı kodlu yinelenen satırlar (652 → 657 · 398 → 397) — nöbetçi THP satırını izlemez (MdIzlenenAnahtar) ----------
if ($Thp) {
  $t = @{}; foreach ($k in '652', '657', '398', '397') { $r = @(SbGet "dokumanlar?select=id,kaynak_ad,metin&kaynak_ad=like.THP%20$k%20*" | ForEach-Object { $_ }); Write-Host ("  THP {0}: {1} satır" -f $k, $r.Count); if ($r.Count -ne 1) { throw "THP $k satırı tek değil ($($r.Count)) — dokunulmadı" }; $t[$k] = $r[0] }
  # 397'ye 398'in işleyiş metni taşınır (kod 397'ye çevrilerek); 652 ve 398 satırları yedeklenip silinir. 657'nin kendi metni yerinde.
  $govde397 = ("$($t['398'].metin)" -replace '398 SAYIM VE TESELLÜM FAZLALARI', '397 SAYIM VE TESELLÜM FAZLALARI')
  if ((SayIfade $govde397 '398') -ne 0) { throw '397 metninde 398 kaldı — dokunulmadı' }
  $yeni397 = $govde397 + ' (02.10.2026: işleyiş metni yanlış kodla kaydedilmiş satırdan taşındı; resmî kod 397.)'
  if (-not $Uygula) { "KURU (THP): 397 metni $("$($t['397'].metin)".Length) → $($yeni397.Length) kr olacak; 652 ve 398 satırları yedeklenip silinecek (-Uygula)"; return }
  New-Item -ItemType Directory -Force $yedekKlasor | Out-Null
  foreach ($k in '652', '398', '397') { [IO.File]::WriteAllText((Join-Path $yedekKlasor "THP-$k.satir.$(Get-Date -Format 'yyyyMMdd-HHmmss').json"), (ConvertTo-Json -InputObject $t[$k] -Depth 4), (New-Object Text.UTF8Encoding $false)) }
  Invoke-RestMethod -Method Patch -Uri "$tabloAdr`?id=eq.$($t['397'].id)" -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @{ metin = $yeni397 } -Compress))) -TimeoutSec 120 | Out-Null
  $g = "$((SbGet "dokumanlar?select=metin&id=eq.$($t['397'].id)")[0].metin)"; if ($g -ne $yeni397) { throw 'THP 397 geri okuma tutmadı — silme YAPILMADI' }
  foreach ($k in '652', '398') { Invoke-RestMethod -Method Delete -Uri "$tabloAdr`?id=eq.$($t[$k].id)" -Headers $basliklarSb -TimeoutSec 120 | Out-Null
    $kalan = @(SbGet "dokumanlar?select=id&id=eq.$($t[$k].id)" | ForEach-Object { $_ }).Count; if ($kalan -ne 0) { throw "THP $k silinemedi" }; Write-Host "  THP $k satırı silindi (yedek: teori-yedek\THP-$k.satir.*.json)" }
  "UYGULANDI (THP): 397 işleyiş metni + 652/398 satırları kaldırıldı"; return
}

# ---------- 1) ÖN KONTROL + yeni metin ----------
$plan = New-Object System.Collections.Generic.List[object]
foreach ($dz in $duzeltmeler) {
  $satir = @(SbGet "dokumanlar?select=id,metin&kaynak_ad=eq.$([uri]::EscapeDataString($dz.ad))" | ForEach-Object { $_ })
  if ($satir.Count -ne 1) { throw "ÖN KONTROL: '$($dz.ad)' ambarda $($satir.Count) satır — hiçbir şey yazılmadı" }
  $eskiMetin = "$($satir[0].metin)"; $yeniMetin = $eskiMetin
  foreach ($d in @($dz.degisim)) { $n = SayIfade $yeniMetin $d.eski; if ($n -ne 1) { throw "ÖN KONTROL: '$($dz.ad)' ifade $n kez: $($d.eski.Substring(0, [Math]::Min(60, $d.eski.Length)))" }; $yeniMetin = $yeniMetin.Replace($d.eski, $d.yeni) }
  $af = MdAyirtEdici $eskiMetin $yeniMetin
  # HEDEFLİ BELİRTEÇ: otomatik ayırt ediciler bu düzeltmelerde genel kelimeler (işleyiş, kredi, yalnız, soru…) çıkardı ve
  #   kuru ölçümde yayındaki 257 sorunun çekilmesine yol açacaktı. Tablodaki 'belirtec' YANLIŞ KURALIN izini taşır (iade notunda
  #   #191, kur notunda #656, kıst, VUK m.283'te m.281 dipnotunun 'müstenit/mevduat'ı); nöbetçi notu anan sorulardan yalnız
  #   bunlardan birini taşıyanı çeker. Otomatik liste de yazdırılır (kıyas için).
  $hedef = @(@($dz.belirtec) | Where-Object { $_ })
  $plan.Add([pscustomobject]@{ dz = $dz; id = "$($satir[0].id)"; eski = $eskiMetin; yeni = $yeniMetin; af = $(if ($hedef.Count) { , $hedef } else { $af }); otomatik = $af; kok = (MdKaynakKoku "$($dz.ad)") })
}

# ---------- 2) ETKİ: yayındaki (kasa) sorulardan kaçı çekilir ----------
$yayin = @{}; foreach ($s in 'sgs', 'smmm', 'kgk') { for ($o = 0; ; $o += 1000) { $p = @(SbGet "paket_soru?select=id&sinav=eq.$s&order=id.asc&limit=1000&offset=$o" | ForEach-Object { $_ }); foreach ($x in $p) { $yayin["$($x.id)"] = 1 }; if ($p.Count -lt 1000) { break } } }
$etki = @{}; foreach ($p in $plan) { $etki[$p.kok] = [pscustomobject]@{ anan = 0; yayinda = 0; cekilir = 0; ornek = @() } }
$aday = @(Get-ChildItem (Join-Path $depoKok 'veri\fabrika') -Filter 'kalip-parti-*.json' | Where-Object { $_.Name -match '^kalip-parti-(sgs|smmm|kgk)-' })
$adlar = @($plan | ForEach-Object { MdAdKoku "$($_.dz.ad)" })
foreach ($f in $aday) {
  $ham = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
  if (-not ($adlar | Where-Object { $ham.Contains(($_ -split ' - ')[0]) -or $ham.Contains($_.Substring(0, [Math]::Min(30, $_.Length))) })) { continue }
  $c = ConvertFrom-Json -InputObject $ham; $et = $f.BaseName -replace '^kalip-parti-', ''
  foreach ($q in $c.PSObject.Properties) { $v = $q.Value; if (-not $v -or -not $v.PSObject.Properties['soru'] -or -not $v.soru) { continue }
    $koklar = @(@($v.kaynak_adlar) | ForEach-Object { MdKaynakKoku "$_" } | Select-Object -Unique)
    foreach ($p in $plan) { if ($koklar -notcontains $p.kok) { continue }
      $e = $etki[$p.kok]; $e.anan++; $id = "$et/$($q.Name)"; if (-not $yayin.ContainsKey($id)) { continue }; $e.yayinda++
      $cek = ($null -eq $p.af) -or (@(MdSoruDegiyor $v @($p.af)).Count -gt 0); if ($cek) { $e.cekilir++; if ($e.ornek.Count -lt 4) { $e.ornek += $id } } } } }
$dur = $false
foreach ($p in $plan) { $e = $etki[$p.kok]
  $bel = $(if ($null -eq $p.af) { 'BELİRSİZ (hepsi çekilir)' } else { "hedef belirteç: $((@($p.af) | Select-Object -First 12) -join ' ') (otomatik $(@($p.otomatik).Count))" })
  Write-Host ("  {0}`n     {1}`n     anan {2} · yayında {3} · ÇEKİLİR {4} {5}" -f $p.kok, $bel, $e.anan, $e.yayinda, $e.cekilir, ($e.ornek -join ','))
  if ($null -eq $p.af -or $e.cekilir -gt $EtkiTavani) { $dur = $true } }
if (-not $Uygula) { "KURU: $($plan.Count) düzeltme ölçüldü — yazılmadı (-Uygula)"; return }
if ($dur) { throw "ETKİ TAVANI ($EtkiTavani) aşıldı ya da belirsiz düzeltme var — hiçbir şey yazılmadı" }

# ---------- 3) YAZ — yedek, belirteç kaydı, PATCH, geri okuma ----------
New-Item -ItemType Directory -Force $yedekKlasor | Out-Null
foreach ($p in $plan) {
  $yedekAd = ("$($p.dz.ad)" -replace '[^\w\-]+', '_'); if ($yedekAd.Length -gt 90) { $yedekAd = $yedekAd.Substring(0, 90) }
  [IO.File]::WriteAllText((Join-Path $yedekKlasor "$yedekAd.metin.$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"), $p.eski, (New-Object Text.UTF8Encoding $false))
  # belirteç kaydı MdDegisenKokEkle biçiminde, ama HEDEFLİ liste ile (aynı anahtarda önceki kayıt varsa birleşir)
  $dk = [ordered]@{}; $dkAc = 'Madde/not metni değişince eski/yeni ayırt edici belirteçler (motor/mevzuat-yut.ps1, arac/teori-notu-duzelt-*.ps1).'
  if (Test-Path $dkYol) { $dkHam = Get-Content $dkYol -Raw -Encoding UTF8 | ConvertFrom-Json; if ($dkHam.aciklama) { $dkAc = "$($dkHam.aciklama)" }; foreach ($pp in $dkHam.maddeler.PSObject.Properties) { $dk[$pp.Name] = $pp.Value } }
  $an = "$($p.dz.anahtar)"; $dizi = @(@($p.af) | Where-Object { $_ }); $bel = $false
  if ($dk.Contains($an) -and $dk[$an]) { if ($dk[$an].belirsiz) { $bel = $true }; $dizi = @(@($dizi) + @($dk[$an].belirtecler) | Where-Object { $_ } | Select-Object -Unique) }
  $dk[$an] = [ordered]@{ tarih = (Get-Date -Format 'yyyy-MM-dd HH:mm'); kaynak = (Split-Path -Leaf $PSCommandPath); belirsiz = $bel; belirtecler = $dizi }
  [IO.File]::WriteAllText($dkYol, (ConvertTo-Json -InputObject ([ordered]@{ aciklama = $dkAc; maddeler = $dk }) -Depth 6), (New-Object Text.UTF8Encoding $false))
  Write-Host "  belirteç kaydı: $an → $($dizi -join ' ')"
  Invoke-RestMethod -Method Patch -Uri "$tabloAdr`?id=eq.$($p.id)" -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @{ metin = $p.yeni } -Compress))) -TimeoutSec 120 | Out-Null
  $geri = "$((SbGet "dokumanlar?select=metin&id=eq.$($p.id)")[0].metin)"
  if ($geri -ne $p.yeni) { throw "GERİ OKUMA TUTMADI: $($p.dz.ad)" }
  Write-Host "  YAZILDI + geri okundu: $($p.kok)"
}
"UYGULANDI: $($plan.Count) düzeltme (ambar)"
