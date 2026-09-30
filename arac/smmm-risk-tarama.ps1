#requires -Version 5.1
# ============================================================================
#  BİTİRME (SMMM) YAYIN RİSK TARAMASI — 30.09.2026 (Cem "1.2.3": "en ciddi kontrol"; bedel 0, model YOK)
#
#  NEDEN: SGS risk taramasında (arac/sgs-risk-tarama.js, 29.09) elle okunan 1.744 sorunun 334'ü kusurlu çıktı.
#  Bitirme açılmadan önce SİTEDEKİ HER soru elle okunacak; bu betik okumadan ÖNCE makineyle görülebileni işaretler
#  ki okuyucu nereye bakacağını bilsin. HİÇBİR ŞEY ÇEKMEZ/YAZMAZ (ambar, kasa, elle ret) — yalnız liste üretir:
#    veri/sinav/smmm-risk-taramasi.json   (yalnız kimlik + sınıf + alan adı; soru metni YOK, depo public)
#  Taranan küme: KASA (paket_soru, sinav=smmm) = sitede duran sorular. İçerik yerel partiden (veri/fabrika/kalip-parti-smmm-*).
#  SINIFLAR (bir soru birden çok sınıfta olabilir):
#    R1 YIL-BAĞLI TUTAR/ORAN  (sgs-risk-tarama.js ile aynı desenler)
#    R2 MÜLGA KAYNAK          kaynak_adlar veri/sinav/ambar-mulga-maddeler.json'da
#    R3 DEĞİŞEN MADDE, ÇEKİLMEMİŞ  nöbetçinin "değmeyen" listesi
#    R4 HESAPLI               şıkların en az 4'ü sayı
#    R5 KAYITSIZ              kasada var, yerel partide yok (okunamadı = KÖR)
#    R6 KANUN NO–AD UYUŞMAZ   "N sayılı <ad>" — N bilinen bir kanunun, ad BAŞKA bilinen kanunun adı (ör. "6098 sayılı Türk Ticaret")
#    R7 ESKİ MEVZUAT ADI      yürürlükten kalkmış kanun no / eski SPK tebliğ serisi / yerini TFRS'ye bırakmış TMS
#    R8 ARİTMETİK SAPMA       öğrencinin gördüğü alanlardaki "a x b = c" işlemi yeniden hesaplanınca tutmuyor
#                             (çekirdek motor/aritmetik-kapisi.ps1 IslemDenetle — AYNEN yüklenir, kopya YOK)
#    R8y YUMUŞAK SAPMA       10'un kuvveti kadar fark (ondalık nokta / parantezli %) ya da binde 5 altı yuvarlama — öncelik 3
#    R9 KAPI-AS2 / KAPI-EK    açıklama kayması / bilinen eski kural (arac/soru-kalite-kapisi.js --parti)
#  🚫 GÖRMEZ: sözel anlam/mantık hatası · yanlış madde numarası (ad doğru, madde yanlış) · listede olmayan eski kural ·
#     karışık öncelikli işlem (a + b x c) · ambar–yerel parti farkı (önce parti-senkron -Indir). Bu sınıflar "taranmadı"
#     sayılır, "temiz" değil. Listede olmamak TEMİZ SERTİFİKASI DEĞİLDİR — tam okuma bunun için var.
#  Kullanım: powershell -NoProfile -File arac/smmm-risk-tarama.ps1 [-Sinav]
# ============================================================================
param([switch]$Sinav)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- R8 çekirdeği: motor/aritmetik-kapisi.ps1'in "cekirdek" bölgesi AYNEN (tek kaynak) ---
$aritMetin = [IO.File]::ReadAllText((Join-Path $depoKok 'motor/aritmetik-kapisi.ps1'), [Text.Encoding]::UTF8)
$aritEsle = [regex]::Match($aritMetin, '(?s)# -+ cekirdek.*?\r?\n(.*?)# -+ /cekirdek')
if (-not $aritEsle.Success) { throw 'motor/aritmetik-kapisi.ps1 cekirdek bölgesi bulunamadı — R8 KÖR, tarama durdu' }
. ([scriptblock]::Create($aritEsle.Groups[1].Value))

$R1_RX = @(
  @('(?i)asgari\s+ücret', 'asgari ücret'),
  @('(?i)\b(had(di|ler)?|sınır(ı|lar)?|tavan(ı)?|taban(ı)?)\b[^.]{0,60}\d{1,3}(\.\d{3})+', 'had/sınır/tavan + tutar'),
  @('(?i)\d{1,3}(\.\d{3})+[^.]{0,60}\b(had(di)?|sınır(ı)?|tavan(ı)?|taban(ı)?)\b', 'tutar + had/sınır'),
  @('(?i)gecikme\s+(zammı|faizi)|tecil\s+faizi|reeskont\s+faiz|yasal\s+faiz', 'gecikme/tecil/reeskont faizi'),
  @('(?i)amortisman\s+oran', 'amortisman oranı'),
  @('(?i)(prime\s+esas\s+kazanç|pek)\b[^.]{0,40}(alt|üst)\s+sınır', 'SGK PEK sınırı'),
  @('(?i)\b(20[0-3]\d)\s+yılı(nda|na|nın)?\b[^.]{0,80}\d{1,3}(\.\d{3})+', 'yıl + tutar'),
  @('(?i)(vergi|stopaj|tevkifat|kdv|ötv|damga|harç)[^.]{0,30}%\s?\d|%\s?\d+[^.]{0,30}(vergi|stopaj|tevkifat|kdv|ötv|damga)', 'vergi oranı'),
  @('(?i)değerli\s+konut|emlak\s+vergisi\s+değer|yeniden\s+değerleme\s+oran', 'yıllık ilan edilen değer/oran')
)
# R6: bilinen kanun no → adının deseni. Uyuşmazlık = no bilinen, yanındaki ad BAŞKA bir bilinen kanunun deseni.
$KANUN = [ordered]@{
  '213' = 'Vergi Usul'; '193' = 'Gelir Vergisi'; '5520' = 'Kurumlar Vergisi'; '3065' = 'Katma Değer'; '4760' = 'Özel Tüketim'
  '488' = 'Damga Vergisi'; '492' = 'Harçlar'; '6183' = 'Amme Alacak'; '6102' = 'Türk Ticaret'; '6098' = 'Borçlar'
  '4857' = 'İş Kanunu'; '5510' = 'Sosyal Sigortalar'; '2577' = 'İdari Yargılama'; '3568' = 'Serbest Muhasebeci'; '6362' = 'Sermaye Piyasası'
  '2004' = 'İcra ve İflas'; '1319' = 'Emlak Vergisi'; '4721' = 'Medeni'; '6100' = 'Hukuk Muhakemeleri'; '3628' = 'Mal Bildirimi'
  '5411' = 'Bankacılık'; '6361' = 'Finansal Kiralama'; '5018' = 'Kamu Mali'; '7201' = 'Tebligat'; '2464' = 'Belediye Gelirleri'
}
# R7: yürürlükten kalkmış / yerini başkasına bırakmış (her satır: desen, ad, dayanak). İstisna: aynı cümlede tarihli/tarihsel anlatım.
$ESKI = @(
  @('\b6762\s*sayılı', '6762 s. eski TTK', '6102 s.K. 01.07.2012'),
  @('\b818\s*sayılı', '818 s. eski Borçlar K.', '6098 s.K. 01.07.2012'),
  @('\b2499\s*sayılı', '2499 s. eski SPK', '6362 s.K. 30.12.2012'),
  @('\b506\s*sayılı', '506 s. SSK Kanunu', '5510 s.K. 01.10.2008'),
  @('\b1479\s*sayılı', '1479 s. Bağ-Kur K.', '5510 s.K. 01.10.2008'),
  @('\b2926\s*sayılı', '2926 s. tarım Bağ-Kur K.', '5510 s.K. 01.10.2008'),
  @('\b5422\s*sayılı', '5422 s. eski KVK', '5520 s.K. 21.06.2006'),
  @('\b4389\s*sayılı', '4389 s. eski Bankalar K.', '5411 s.K. 2005'),
  @('\b1475\s*sayılı(?![^.]{0,80}(m\.\s*14|14\s*(üncü|\.)\s*madde|kıdem))', '1475 s. eski İş K. (m.14 kıdem hariç)', '4857 s.K. 10.06.2003'),
  @('(?i)Seri\s*:\s*XI\s*,?\s*No\s*:\s*29', 'SPK Seri XI No 29 (eski finansal raporlama tebliği)', 'SPK II-14.1'),
  @('(?i)Seri\s*:\s*X\s*,?\s*No\s*:\s*22', 'SPK Seri X No 22 (eski bağımsız denetim tebliği)', 'KGK düzenlemeleri'),
  @('(?i)\bTMS\s*39\b', 'TMS 39 (finansal araçlar büyük ölçüde TFRS 9)', 'TFRS 9, 2018'),
  @('(?i)\bTMS\s*(11|18)\b', 'TMS 11/18 (hasılat TFRS 15)', 'TFRS 15, 2018'),
  @('(?i)\bTMS\s*17\b', 'TMS 17 (kiralama TFRS 16)', 'TFRS 16, 2019')
)
$ESKI_ISTISNA = '(?i)yürürlükten\s+kalk|mülga|önceki\s+düzenleme|eski\s+(kanun|düzenleme|standart)|yerini\s+(alan|aldı)|yerine\s+geçen|ile\s+değiştiril'
# Öğrencinin görmediği (model/iç) alanlar taranmaz — hakem gerekçesinde eski kural geçmesi öğrenciyi yanıltmaz.
$IC_ALAN = @('hakem', 'hakem2', 'kor_cozum', 'simulasyon', 'simulasyon_sonnet', 'kaynak_metin_ozet', 'atif_genisletme', 'kaynak_adlar',
  'capa_metin', 'capa_kaynak', 'hesap_genisletme', 'notlandirici', 'pencere', 'pencere_kavram', 'son_donem', 'donem', 'konu', 'hesap_kod', 'aritmetik', 'kor_cozum_kaynakli')

function Metinler($o, [string]$yol, $liste) {
  if ($null -eq $o) { return }
  if ($o -is [string]) { if ($o.Trim()) { $liste.Add([pscustomobject]@{ alan = $yol; metin = $o }) }; return }
  if ($o -is [ValueType]) { return }
  if ($o -is [Collections.IEnumerable]) { $i = 0; foreach ($x in $o) { Metinler $x "$yol[$i]" $liste; $i++ }; return }
  foreach ($p in $o.PSObject.Properties) { Metinler $p.Value $(if ($yol) { "$yol.$($p.Name)" } else { $p.Name }) $liste }
}
function OgrenciMetinleri($soruNesne) {
  $liste = New-Object System.Collections.Generic.List[object]
  foreach ($p in $soruNesne.PSObject.Properties) { if ($IC_ALAN -notcontains $p.Name) { Metinler $p.Value $p.Name $liste } }
  return $liste
}
function R1Bul($soruNesne) {
  $t = (@("$($soruNesne.soru)") + @($(if ($soruNesne.siklar) { $soruNesne.siklar.PSObject.Properties | ForEach-Object { "$($_.Value)" } }))) -join " `n "
  return @($R1_RX | Where-Object { $t -match $_[0] } | ForEach-Object { $_[1] })
}
function R4Mu($soruNesne) {
  if (-not $soruNesne.siklar) { return $false }
  return (@($soruNesne.siklar.PSObject.Properties | Where-Object { "$($_.Value)".Trim() -match '^[-+]?[\d.,\s%₺TL]+$' -and "$($_.Value)" -match '\d' }).Count -ge 4)
}
function R6Bul($metinler) {
  $b = New-Object System.Collections.Generic.List[string]
  foreach ($m in $metinler) {
    foreach ($e in [regex]::Matches($m.metin, '\b(\d{3,4})\s*sayılı\s+([^,.;()\n]{3,70})')) {
      $no = $e.Groups[1].Value; $ad = $e.Groups[2].Value
      if (-not $KANUN.Contains($no)) { continue }
      if ($ad -match [regex]::Escape($KANUN[$no])) { continue }
      $baska = @($KANUN.Keys | Where-Object { $_ -ne $no -and $ad -match [regex]::Escape($KANUN[$_]) })
      if ($baska.Count) { $b.Add("$($m.alan): $no sayılı ≠ $($KANUN[$baska[0]]) ($($baska[0]))") }
    }
  }
  return @($b)
}
function R7Bul($metinler) {
  $b = New-Object System.Collections.Generic.List[string]
  foreach ($m in $metinler) {
    foreach ($cumle in ($m.metin -split '(?<=[.!?])\s+')) {
      if ($cumle -match $ESKI_ISTISNA) { continue }
      foreach ($k in $ESKI) { if ($cumle -match $k[0]) { $b.Add("$($m.alan): $($k[1]) → $($k[2])") } }
    }
  }
  return @($b | Select-Object -Unique)
}
# R8 iki sınıf (30.09 ilk koşu 251 bulgu, örneklem okundu): beklenen/yazan oranı 10'un kuvveti ise çoğunlukla ondalık NOKTA
# ("590.000*0.25=147.500": işlem doğru, 0,25 yazılmamış) ya da çekirdeğin parantezli %'yi bölmemesi ("(a + b) × %20") → R8y (yazım/yanlış
# alarm şüphesi, öncelik 3). Binde 5 altı sapma yuvarlama → R8y. Kalanı gerçek aritmetik sapma şüphesi → R8 (öncelik 1).
function R8Bul($metinler) {
  $b = New-Object System.Collections.Generic.List[string]
  foreach ($m in $metinler) {
    foreach ($x in @(IslemDenetle $m.metin)) {
      $yumusak = $false
      if ([double]$x.yazan -ne 0 -and [double]$x.beklenen -ne 0) {
        $us = [math]::Log10([math]::Abs([double]$x.beklenen / [double]$x.yazan))
        if ([math]::Abs($us - [math]::Round($us)) -lt 0.002 -and [math]::Round($us) -ne 0) { $yumusak = $true }
      }
      if ([double]$x.sapmaYuzde -lt 0.5) { $yumusak = $true }
      $b.Add("$(if ($yumusak) { 'Y:' })$($m.alan): beklenen $($x.beklenen) yazan $($x.yazan) (%$($x.sapmaYuzde))")
    }
  }
  return @($b)
}

if ($Sinav) {
  $T = { param($ek) $o = [ordered]@{ soru = 'Net kâr kaçtır?'; siklar = [ordered]@{ A = 'a'; B = 'b'; C = 'c'; D = 'd'; E = 'e' }; dogru = 'A' }; foreach ($k in $ek.Keys) { $o[$k] = $ek[$k] }; return ([pscustomobject]$o | ConvertTo-Json -Depth 6 | ConvertFrom-Json) }
  $VAKA = @(
    @('R6 yanlış ad', { @(R6Bul (OgrenciMetinleri (& $T @{ aciklama = [ordered]@{ A = '6098 sayılı Türk Ticaret Kanunu uyarınca pay devredilir.' } }))).Count -eq 1 }),
    @('R6 doğru ad geçer', { @(R6Bul (OgrenciMetinleri (& $T @{ aciklama = [ordered]@{ A = '6102 sayılı Türk Ticaret Kanunu m.329.' } }))).Count -eq 0 }),
    @('R6 bilinmeyen no geçer', { @(R6Bul (OgrenciMetinleri (& $T @{ aciklama = [ordered]@{ A = '7338 sayılı Vergi Usul Kanunu ile Bazı Kanunlarda Değişiklik.' } }))).Count -eq 0 }),
    @('R7 6762 yakalanır', { @(R7Bul (OgrenciMetinleri (& $T @{ hap = '6762 sayılı Kanuna göre şirket feshedilir.' }))).Count -eq 1 }),
    @('R7 tarihsel anlatım geçer', { @(R7Bul (OgrenciMetinleri (& $T @{ hap = '6762 sayılı Kanun 2012de yürürlükten kalkmıştır.' }))).Count -eq 0 }),
    @('R7 1475 m.14 kıdem geçer', { @(R7Bul (OgrenciMetinleri (& $T @{ hap = '1475 sayılı Kanunun 14 üncü maddesi kıdem tazminatını düzenler.' }))).Count -eq 0 }),
    @('R7 TMS 18 yakalanır', { @(R7Bul (OgrenciMetinleri (& $T @{ sade = [ordered]@{ dogru = 'TMS 18 uyarınca hasılat kaydedilir.' } }))).Count -eq 1 }),
    @('R7 iç alan (hakem) taranmaz', { @(R7Bul (OgrenciMetinleri (& $T @{ hakem = [ordered]@{ gerekce = '6762 sayılı Kanun' } }))).Count -eq 0 }),
    @('R8 yanlış işlem', { @(R8Bul (OgrenciMetinleri (& $T @{ adimlar = @([ordered]@{ formul = '100.000 x %20 = 25.000' }) }))).Count -eq 1 }),
    @('R8y ondalık nokta yumuşak', { $x = @(R8Bul (OgrenciMetinleri (& $T @{ adimlar = @([ordered]@{ formul = '590.000*0.25=147.500' }) }))); $x.Count -eq 1 -and $x[0] -like 'Y:*' }),
    @('R8 gerçek sapma sert', { $x = @(R8Bul (OgrenciMetinleri (& $T @{ adimlar = @([ordered]@{ formul = '4.000 - 500 = 3.000' }) }))); $x.Count -eq 1 -and $x[0] -notlike 'Y:*' }),
    @('R8 doğru işlem geçer', { @(R8Bul (OgrenciMetinleri (& $T @{ adimlar = @([ordered]@{ formul = '100.000 x %20 = 20.000' }) }))).Count -eq 0 }),
    @('R4 hesaplı', { R4Mu (& $T @{ siklar = [ordered]@{ A = '10.000'; B = '12.500'; C = '15.000'; D = '17.500'; E = 'Hiçbiri' } }) }),
    @('R1 asgari ücret', { @(R1Bul (& $T @{ soru = '2026 yılı asgari ücret brüt tutarı esas alınarak hesaplayınız.' })).Count -ge 1 })
  )
  $ok = 0; foreach ($vk in $VAKA) { $g = [bool](& $vk[1]); if ($g) { $ok++; "  YEŞİL  $($vk[0])" } else { Write-Host "  KIRMIZI $($vk[0])" -ForegroundColor Red } }
  if ($ok -ne $VAKA.Count) { Write-Host "SMMM RİSK TARAMA ÖZ-SINAVI KIRMIZI ($ok/$($VAKA.Count))" -ForegroundColor Red; exit 1 }
  "SMMM RİSK TARAMA ÖZ-SINAVI YEŞİL ($ok/$($VAKA.Count))"; exit 0
}

# --- 1) sitedeki küme: kasa (yalnız kimlik + sayfa; içerik çekilmez) ---
$KEY = "$($env:SUPABASE_SERVICE_KEY)".Trim(); if (-not $KEY) { $KEY = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $KEY) { throw 'SUPABASE_SERVICE_KEY yok — sitedeki küme okunamaz, tarama durdu' }
$SB = @{ apikey = $KEY; Authorization = "Bearer $KEY"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$kasa = New-Object System.Collections.Generic.List[object]
for ($ofs = 0; ; $ofs += 1000) {
  # K2: PS 5.1 Invoke-RestMethod JSON dizisini TEK nesne (Object[]) döndürür; @() sarması onu 1 sayar (30.09 ilk koşu: "kasada 1") → foreach ile say
  $r = Invoke-RestMethod -UseBasicParsing "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=id,sayfa&sinav=eq.smmm&order=id.asc&limit=1000&offset=$ofs" -Headers $SB -TimeoutSec 90
  $gelen = 0; foreach ($x in $r) { if ($x.id) { $kasa.Add($x); $gelen++ } }
  if ($gelen -lt 1000) { break }
}
if (-not $kasa.Count) { throw 'kasada SMMM sorusu okunamadı (0) — tarama durdu' }

# --- 2) yardımcı listeler ---
$mulgaY = Join-Path $depoKok 'veri/sinav/ambar-mulga-maddeler.json'
$mulga = @{}; if (Test-Path $mulgaY) { foreach ($m in @((Get-Content $mulgaY -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler)) { $mulga["$($m.kaynak_ad)"] = 1 } }
$degY = Join-Path $depoKok 'veri/sinav/mevzuat-degisti-degmeyen.json'
$degmeyen = @{}; if (Test-Path $degY) { foreach ($k in @((Get-Content $degY -Raw -Encoding UTF8 | ConvertFrom-Json).kayitlar)) { if ("$($k.anahtar)" -like 'smmm-*') { $degmeyen["$($k.anahtar)"] = "$($k.madde)" } } }
$retJ = Get-Content (Join-Path $depoKok 'veri/sinav/smmm-elle-ret.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$elleRet = @{}; foreach ($p in $retJ.kayitlar.PSObject.Properties) { $elleRet[$p.Name] = 1 }
$kaliteJs = Join-Path $depoKok 'arac/soru-kalite-kapisi.js'

# --- 3) tarama ---
$partiOnb = @{}; $kaliteOnb = @{}; $kaliteKor = 0
$satir = New-Object System.Collections.Generic.List[object]
$say = [ordered]@{ R1 = 0; R2 = 0; R3 = 0; R4 = 0; R5 = 0; R6 = 0; R7 = 0; R8 = 0; R8y = 0; R9 = 0 }
$retteki = 0
foreach ($k in $kasa) {
  $anahtar = "$($k.id)"
  if ($elleRet.ContainsKey($anahtar)) { $retteki++; continue }
  $et, $kp = $anahtar -split '/', 2
  if (-not $partiOnb.ContainsKey($et)) {
    $py = Join-Path $depoKok "veri/fabrika/kalip-parti-$et.json"
    $partiOnb[$et] = $(if (Test-Path $py) { Get-Content $py -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null })
    $kaliteOnb[$et] = @{}
    if ($partiOnb[$et]) {
      $j = (& node $kaliteJs --parti $py) -join ''
      if ($LASTEXITCODE -ne 0) { $kaliteKor++ } else { $jo = ConvertFrom-Json $j; foreach ($p in $jo.PSObject.Properties) { $kaliteOnb[$et][$p.Name] = @($p.Value) } }
    }
  }
  $q = $(if ($partiOnb[$et]) { $partiOnb[$et].$kp } else { $null })
  $sin = New-Object System.Collections.Generic.List[string]; $neden = New-Object System.Collections.Generic.List[string]
  if (-not $q) { $sin.Add('R5'); $neden.Add('R5: yerel partide kayıt yok') }
  else {
    $om = OgrenciMetinleri $q
    $a = @(R1Bul $q); if ($a.Count) { $sin.Add('R1'); $neden.Add('R1: ' + ($a -join ', ')) }
    $m2 = @(@($q.kaynak_adlar) | Where-Object { $mulga.ContainsKey("$_") }); if ($m2.Count) { $sin.Add('R2'); $neden.Add('R2: ' + ($m2 -join '; ')) }
    if ($degmeyen.ContainsKey($anahtar)) { $sin.Add('R3'); $neden.Add('R3: ' + $degmeyen[$anahtar]) }
    if (R4Mu $q) { $sin.Add('R4') }
    $a6 = @(R6Bul $om); if ($a6.Count) { $sin.Add('R6'); $neden.Add('R6: ' + ($a6 -join ' | ')) }
    $a7 = @(R7Bul $om); if ($a7.Count) { $sin.Add('R7'); $neden.Add('R7: ' + ($a7 -join ' | ')) }
    $a8 = @(R8Bul $om); $a8s = @($a8 | Where-Object { $_ -notlike 'Y:*' })
    if ($a8s.Count) { $sin.Add('R8'); $neden.Add('R8: ' + ($a8s -join ' | ')) } elseif ($a8.Count) { $sin.Add('R8y'); $neden.Add('R8y: ' + ($a8 -join ' | ')) }
    if ($kaliteOnb[$et].ContainsKey($kp)) { $sin.Add('R9'); $neden.Add('R9: ' + (@($kaliteOnb[$et][$kp]) -join ' · ')) }
  }
  foreach ($s in $sin) { $say[$s]++ }
  $onc = $(if (@($sin | Where-Object { $_ -in 'R2', 'R3', 'R6', 'R8', 'R9' }).Count) { 1 } elseif (@($sin | Where-Object { $_ -in 'R1', 'R5', 'R7' }).Count) { 2 } elseif ($sin.Count) { 3 } else { 4 })
  $satir.Add([ordered]@{ anahtar = $anahtar; sayfa = ("$($k.sayfa)" -replace '^kaydir/smmm/|\.html$', ''); siniflar = @($sin); neden = ($neden -join ' || '); oncelik = $onc })
}
$sirali = @($satir | Sort-Object { $_.oncelik }, { $_.anahtar })
$ozet = [ordered]@{
  kasada = $kasa.Count; elle_rette_atlanan = $retteki; taranan = $satir.Count; siniflar = $say
  oncelik1 = @($sirali | Where-Object { $_.oncelik -eq 1 }).Count; oncelik2 = @($sirali | Where-Object { $_.oncelik -eq 2 }).Count
  oncelik3 = @($sirali | Where-Object { $_.oncelik -eq 3 }).Count; isaretsiz = @($sirali | Where-Object { $_.oncelik -eq 4 }).Count
  kalite_kor_parti = $kaliteKor
  taranmayan = 'sözel anlam/mantık hatası · yanlış madde no (ad doğru) · listede olmayan eski kural · karışık öncelikli işlem · ambar-yerel parti farkı'
}
. (Join-Path $PSScriptRoot 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri/sinav/smmm-risk-taramasi.json') -Nesne ([ordered]@{
    aciklama = 'Bitirme yayın risk taraması (arac/smmm-risk-tarama.ps1). Sitedeki (kasa) HER soru listede; oncelik 4 = makine işaret koymadı, TEMİZ DEMEK DEĞİL — tam okuma gerekir.'
    olcum = (Get-Date -Format 'yyyy-MM-dd'); ozet = $ozet; satir = $sirali })
$ozet | ConvertTo-Json -Compress
