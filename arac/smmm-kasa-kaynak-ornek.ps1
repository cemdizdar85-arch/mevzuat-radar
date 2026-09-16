#requires -Version 5.1
# ============================================================================
#  BİTİRME (SMMM) KASA KAYNAK ÖRNEKLEMİ — "kasadaki sorunun künyesindeki madde soruyu gerçekten destekliyor mu?"   16.09.2026 (PARALI, TOPLU)
#
#  NEDEN (Cem 16.09 "1.2.3", GM 2): üretimdeki paketlerde ilgisiz kaynak ölçüldü (ön denemenin ~1/4'ü; köprü 'kdv'nin konusu' ← ÖTV m.1,
#  'etik ilkeler' ← 3568 m.45). Aynı bağlarla ÜRETİLMİŞ eski sorular kasada duruyor olabilir. Önce örneklem: ders başına N soru (tohumlu).
#  Her soru için künyedeki madde ambardan okunur (kaynak_ad tam ad ya da '<künye> [parça]'), soru + doğru şık + madde metni modele verilir:
#  "madde bu soruyu ve doğru cevabı destekliyor mu, konu ile ilgili mi?"
#  GİZLİLİK: depo HERKESE AÇIK — soru metni depoya YAZILMAZ; ayrıntı yalnız -Cikti (scratchpad) dosyasına gider.
#  Kullanım: powershell -NoProfile -File arac/smmm-kasa-kaynak-ornek.ps1 -DersBasi 25 -Cikti <scratchpad json> [-Kuru]
# ============================================================================
param([int]$DersBasi = 25, [int]$Tohum = 1609, [Parameter(Mandatory = $true)][string]$Cikti, [string]$Model = 'claude-sonnet-5', [int]$KaynakKr = 3000, [string]$Etiket = '', [string]$HasatBid = '', [switch]$Kuru)   # HasatBid: virgüllü toplu parti kimlikleri — bitmiş cevaplar BEDAVA toplanır, yalnız eksik istekler gönderilir
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'motor\api-hedef.ps1')
if (-not $env:MEVZUAT_TOPLU_BEKLE_DK) { $env:MEVZUAT_TOPLU_BEKLE_DK = '1440' }
$ANAHTAR_SB = "$($env:SUPABASE_SERVICE_KEY)".Trim(); if (-not $ANAHTAR_SB) { throw 'SUPABASE_SERVICE_KEY yok' }
$SB_BASLIK = @{ apikey = $ANAHTAR_SB; Authorization = "Bearer $ANAHTAR_SB"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$TABAN = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
function SbGet([string]$yol) {
  $r = Invoke-WebRequest -UseBasicParsing -Uri "$TABAN/$yol" -Headers $SB_BASLIK -TimeoutSec 120
  $m = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
  return @((ConvertFrom-Json -InputObject $m) | ForEach-Object { $_ })   # K2: dizi tek nesneye sarılmasın
}

# --- 1) evren: tüm SMMM soru kimlikleri (sıralı sayfalama) ---
$evren = New-Object System.Collections.Generic.List[object]
for ($bas = 0; ; $bas += 1000) {
  $s = SbGet "soru_havuzu?select=id,ders,yayin&sinav=eq.SMMM&order=id&offset=$bas&limit=1000"
  foreach ($x in $s) { $evren.Add($x) }
  if ($s.Count -lt 1000) { break }
}
"EVREN: $($evren.Count) SMMM sorusu"
$rnd = New-Object System.Random($Tohum)
$secim = New-Object System.Collections.Generic.List[string]
foreach ($g in @($evren.ToArray() | Group-Object ders | Sort-Object Name)) {
  $l = @($g.Group | Sort-Object { $rnd.Next() } | Select-Object -First $DersBasi)
  foreach ($x in $l) { $secim.Add("$($x.id)") }
  "  $($g.Name): evren $($g.Count) · örnek $($l.Count)"
}

# --- 2) seçilen soruların alanları + künyedeki madde metni ---
$sorular = New-Object System.Collections.Generic.List[object]
for ($i = 0; $i -lt $secim.Count; $i += 40) {
  $parca = $secim[$i..([math]::Min($i + 40, $secim.Count) - 1)] -join ','
  foreach ($x in (SbGet "soru_havuzu?select=id,ders,konu,soru,siklar,dogru,kaynak,yayin&id=in.($parca)")) { $sorular.Add($x) }
}
$kaynakOnbellek = @{}
function KaynakMetin([string]$kunye) {
  $k = "$kunye".Trim(); if (-not $k -or $k -eq 'YOK') { return '' }
  if ($kaynakOnbellek.ContainsKey($k)) { return $kaynakOnbellek[$k] }
  $parcalar = @(SbGet ("dokumanlar?select=kaynak_ad,metin&kaynak_ad=eq." + [uri]::EscapeDataString($k)))
  if (-not $parcalar.Count) { $parcalar = @(SbGet ("dokumanlar?select=kaynak_ad,metin&order=kaynak_ad&limit=4&kaynak_ad=ilike." + [uri]::EscapeDataString("$k [*"))) }
  $metin = (@($parcalar | ForEach-Object { "[$($_.kaynak_ad)] $($_.metin)" }) -join "`n") -replace '\s+', ' '
  if ($metin.Length -gt $KaynakKr) { $metin = $metin.Substring(0, $KaynakKr) }
  $kaynakOnbellek[$k] = $metin; return $metin
}
$isler = New-Object System.Collections.Generic.List[object]
$kayit = [ordered]@{}
foreach ($s in $sorular) {
  $id = "s$($isler.Count + $kayit.Count)"
  $km = KaynakMetin "$($s.kaynak)"
  $siklar = @(foreach ($p in $s.siklar.PSObject.Properties) { "$($p.Name)) $("$($p.Value)" -replace '\s+', ' ')" }) -join "`n"
  $kayit["q$($s.id)"] = [ordered]@{ id = "$($s.id)"; ders = "$($s.ders)"; konu = "$($s.konu)"; kaynak = "$($s.kaynak)"; yayin = [bool]$s.yayin; kaynakBulundu = [bool]$km }
  if (-not $km) { continue }
  $istem = @"
Sen SMMM Yeterlilik (bitirme) soru bankasını denetleyen bir hakemsin. Sorunun künyesinde yazan kaynağın METNİ aşağıda.
DERS: $($s.ders)
KONU: $($s.konu)
SORU: $("$($s.soru)" -replace '\s+', ' ')
ŞIKLAR:
$siklar
DOĞRU ŞIK: $($s.dogru)
KÜNYE: $($s.kaynak)
KAYNAK METNİ (ilk $KaynakKr kr):
$km

Karar ver:
1) konuyla_ilgili: bu kaynak metni sorunun konusunu anlatıyor mu?
2) cevabi_destekliyor: doğru şıkkın doğruluğu bu kaynak metninden çıkarılabiliyor mu? (Muhasebe kaydı sorularında hesap planı/teori yeterli olabilir; kanun maddesi ilgisizse HAYIR.)
Emin değilsen false say.
YALNIZ şu JSON'u döndür: {"konuyla_ilgili":true/false,"cevabi_destekliyor":true/false,"gerekce":"en çok 20 kelime"}
"@
  $istem = $istem -replace "`r`n", "`n"   # 16.09: satır sonu dosyanın çekiliş biçimine bağlıydı (yerel LF / bulut CRLF) → parmak izi tutmuyordu; tek biçim
  $isler.Add(@{ id = "q$($s.id)"; model = $Model; maxTok = 300; icerik = @(@{ type = 'text'; text = $istem }) })
}
"ÖRNEK: $($sorular.Count) soru · künye metni bulunan $($isler.Count) · bulunamayan $($sorular.Count - $isler.Count)"
if (-not $Etiket) { $Etiket = "smmm-kasa-kaynak-ornek-$(Get-Date -Format yyyyMMdd-HHmm)" }   # 16.09: sabit etiket verilirse bulutta kuyruktaki partiye bağlanır
if ($Kuru) { foreach ($i in $isler) { "PARMAK $($i.id) $(Get-IcerikParmak $i.icerik)" }; $kar = 0; foreach ($i in $isler) { $kar += "$($i.icerik[0].text)".Length }; "KURU: istek gönderilmedi · istem $kar kr (~$([math]::Round($kar / 3.2)) jeton) · tahmini toplu ≈ $([math]::Round((($kar / 3.2) * 2 + $isler.Count * 60 * 10) / 1e6 / 2, 3)) USD"; exit 0 }
$sonuc = @{}
# 16.09 HASAT: iptal/yeniden başlatma sonrası bitmiş partinin cevapları kimlikle toplanır (bedel defterine bir kez yazılır), kalan istekler gönderilir
if ($HasatBid) {
  $hedefH = Get-TopluBasliklar
  foreach ($hb in @($HasatBid -split '[,\s]+' | Where-Object { $_ })) {
    $hs = Get-ClaudeTopluSonuc $hb $hedefH $Etiket
    if ($null -eq $hs) { "HASAT: $hb henüz bitmemiş — atlandı"; continue }
    $al = 0; foreach ($hk in @($hs.Keys)) { if ($hk -notlike '__*' -and ($isler | Where-Object { $_.id -eq $hk })) { $sonuc[$hk] = $hs[$hk]; $al++ } }
    "HASAT: $hb → $al cevap alındı"
  }
}
$kalanIs = @($isler | Where-Object { -not $sonuc.ContainsKey($_.id) })
"GÖNDERİLECEK: $($kalanIs.Count) istek (hasat edilen $($sonuc.Count))"
if ($kalanIs.Count) { $yeniS = Invoke-ClaudeToplu -Isler $kalanIs -Etiket $Etiket -BeklemeDk ([int]$env:MEVZUAT_TOPLU_BEKLE_DK) -OnbelleksizToplu; foreach ($yk in @($yeniS.Keys)) { $sonuc[$yk] = $yeniS[$yk] } }
if ($sonuc.ContainsKey('__zaman_asimi')) { throw "TOPLU ZAMAN AŞIMI — aynı komutla yeniden koşunca bedava hasat edilir. Çıktı YAZILMADI." }
$cikis = New-Object System.Collections.Generic.List[object]
foreach ($key in $kayit.Keys) {
  $k = $kayit[$key]; $il = $null; $de = $null; $ge = ''
  if ($sonuc.ContainsKey($key)) { try { $j = ConvertFrom-Json -InputObject ([regex]::Match("$($sonuc[$key].metin)", '(?s)\{.*\}').Value); $il = [bool]$j.konuyla_ilgili; $de = [bool]$j.cevabi_destekliyor; $ge = "$($j.gerekce)" } catch {} }
  $sinif = $(if (-not $k.kaynakBulundu) { 'KUNYE AMBARDA YOK' } elseif ($null -eq $de) { 'OLCULEMEDI' } elseif ($de) { 'DESTEKLIYOR' } elseif ($il) { 'ILGILI AMA DESTEKLEMIYOR' } else { 'ILGISIZ KAYNAK' })
  $o = [ordered]@{}; foreach ($kk in $k.Keys) { $o[$kk] = $k[$kk] }   # OrderedDictionary '+' ile birleşmez
  $o.sinif = $sinif; $o.konuylaIlgili = $il; $o.cevabiDestekliyor = $de; $o.gerekce = $ge
  $cikis.Add([pscustomobject]$o)
}
$bz = Get-BedelOzet
if ($bz.toplamUsd -gt 0) {
  $bedelSatir = ((ConvertTo-Json -InputObject ([ordered]@{ zaman = (Get-Date -Format 'yyyy-MM-dd HH:mm'); etiket = 'smmm-kasa-kaynak-ornek'; ders = 'SMMM kasa örneklemi'; toplamUsd = $bz.toplamUsd; varsayim = $bz.fiyatVarsayim; satirlar = $bz.satirlar }) -Compress -Depth 4) + "`n")
  $bmx = New-Object System.Threading.Mutex($false, 'Global\tetikte-bedel-kayit'); $bal = $false
  try { $bal = $bmx.WaitOne(20000) } catch { $bal = $true }
  try { [IO.File]::AppendAllText((Join-Path $depoKok 'veri\fabrika\bedel-kayit.jsonl'), $bedelSatir, [Text.UTF8Encoding]::new($false)) }
  finally { if ($bal) { try { $bmx.ReleaseMutex() } catch {} }; $bmx.Dispose() }
}
$dizi = $cikis.ToArray()
[IO.File]::WriteAllText($Cikti, (ConvertTo-Json -InputObject ([ordered]@{ olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm'); model = $Model; tohum = $Tohum; dersBasi = $DersBasi; bedelUsd = $bz.toplamUsd; sorular = $dizi }) -Depth 5), [Text.UTF8Encoding]::new($false))
"SONUÇ (bedel ≈ $($bz.toplamUsd) USD):"
foreach ($g in @($dizi | Group-Object sinif | Sort-Object Count -Descending)) { "  $($g.Name): $($g.Count) (yayında $(@($g.Group | Where-Object { $_.yayin }).Count))" }
"DERS DERS (destekleyen / ölçülen):"
foreach ($g in @($dizi | Group-Object ders | Sort-Object Name)) { $o = @($g.Group | Where-Object { $_.sinif -notin 'OLCULEMEDI', 'KUNYE AMBARDA YOK' }); "  $($g.Name): $(@($o | Where-Object { $_.sinif -eq 'DESTEKLIYOR' }).Count)/$($o.Count) · künyesi ambarda yok $(@($g.Group | Where-Object { $_.sinif -eq 'KUNYE AMBARDA YOK' }).Count)" }
