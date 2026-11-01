#requires -Version 5.1
<#
================================================================================
  ŞIK KARNESİ YÖNÜ + THP UYGULAMA NOTU — ÖZ-SINAV  (31.10.2026)  AĞ YOK, PARA YOK

  NİYE VAR: motor/kaydir-coz.ps1 şık karnesinin "Karar" etiketini (tablo · karar rozeti · hücre rengi · "Önce sen karar ver")
  yalnız adımın karar alanından basıyordu; kök yönü okunmuyordu. Olumsuz kökte ters yazılmış karar öğrenciye ters etiket
  gösterdi (sitede 25 SMMM sorusu, Ajan 22 ölçümü 31.10). Ayrıca THP tanımı 340 karakterde kesilirken sondaki
  "(31.10.2026 UYGULAMA NOTU: …)" düşüyordu (THP 122/137/322/337/422). Cem 31.10: "evet".

  01.11 (Ajan 37 ölçtü, Ajan 40): iki yanlış alarm → yön belirsiz, karar AYNEN: (1) şıklar Roma rakamlı öncül kümesi
  (KURAL2710_ONCUL; sgs-e16-ekonomi-zor/kp-08 B'yi "YANLIŞ ifade" basıyordu) · (2) "henüz … -mamıştır" kökü (smmm-olc2-b-vergi/kp-30).
  Mutasyon artık BÜTÜN dosyaya uygulanır: çağrı yeri (bölge dışı) şık metnini geçirmezse 'cagri-sik' KIRMIZI düşer.

  ⛔ REPLİKA YASAK: kaydir-coz.ps1'in "# ---- sik-karne" … "# ---- /sik-karne" bölgesi AYNEN yüklenir.

  MUTASYON (KAPI KURMA KURALI 8): SK_MUTASYON=<ad> bölgedeki koşulu bilerek bozar; sınav KIRMIZI düşmelidir.
  -Mutasyon hepsini sırayla koşar: "N/M mutasyon KIRMIZI". Bozma hedefi bölgede yoksa çıkış 3 (ÖLÇÜLEMEDİ).

  🚫 GÖRMEZ: tablo satırını basan kod (kaydir-coz.ps1 şık karnesi bloğu — bölge dışında; karar alanını okur, bölge o alanı
     düzeltir) · sayfadaki JS (rozet/renk/"karar ver" aynı karar alanını okur) · anlamca olumsuz ama eki olmayan kök
     ("hangisi istisnadır?" olumlu sayılır — vakası aşağıda GÖRMEZ diye işaretli) · adım harfi şıkla kaymış soru (adım A
     başka şıkkı anlatıyorsa rozet anahtara uyar ama anlatım uymaz) · ambardaki gerçek kökler (eşdeğerlik provası ölçer).

  KULLANIM
    powershell -NoProfile -File arac/sik-karne-sinavi.ps1            # öz-sınav
    powershell -NoProfile -File arac/sik-karne-sinavi.ps1 -Mutasyon  # bütün mutasyonlar
================================================================================
#>
param([switch]$Mutasyon, [switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin

$MUTASYONLAR = [ordered]@{
  'belirsiz-liste'  = @('foreach($r in $SIK_KOK_BELIRSIZ){', 'foreach($r in @()){')
  'olumsuz-liste'   = @('foreach($r in $SIK_KOK_OLUMSUZ){', 'foreach($r in @()){')
  'olumlu-sart'     = @(' -and $k -notmatch $SIK_KOK_OLUMSUZLUK', '')
  'yon-ters'        = @('if($yon -eq ''olumsuz''){ $h -ne $d } else { $h -eq $d }', 'if($yon -eq ''olumsuz''){ $h -eq $d } else { $h -ne $d }')
  'belirsiz-dokun'  = @('if($yon -eq ''belirsiz''){ return $sonuc }', 'if($false){ return $sonuc }')
  'dil-dersi'       = @('if("$etiket" -match $SIK_DIL_DERSI)', 'if($false)')
  'kac'             = @('''kaç\s'', ', '')
  'noktali-virgul'  = @("  ';',", '')
  'not-ayir'        = @('if($nm.Success){ $not=', 'if($false){ $not=')
  'not-ekle'        = @('if($not){ $m=$m.TrimEnd()', 'if($false){ $m=$m.TrimEnd()')
  # 01.11 (Ajan 40): öncül kümesi + "henüz" yanlış alarmları (Ajan 37 ölçümü: sgs-e16-ekonomi-zor/kp-08, smmm-olc2-b-vergi/kp-30)
  'oncul-belirsiz'  = @('elseif($sonuc.oncul){ ''belirsiz'' }', 'elseif($false){ ''belirsiz'' }')
  'oncul-esik'      = @('return ($n -ge 4)', 'return ($n -ge 3)')
  'oncul-nesne'     = @('{ $sikMetin[$h] } else { $sikMetin.$h }', '{ $sikMetin[$h] } else { $sikMetin[$h] }')
  'oncul-desen'     = @('$SIK_ONCUL_KUME=''^\s*(?:[Yy]aln[ıi]z\s+)?[IVX]+', '$SIK_ONCUL_KUME=''^\s*(?:[Yy]aln[ıi]z\s+)[IVX]+')
  'henuz'           = @('''henüz\s.*?', '''HENUZYOK\s.*?')
  'cagri-sik'       = @('"$($x.et)" $siklar', '"$($x.et)"')   # bölge DIŞI: çağrı yeri şık metnini geçirmezse öncül kapısı ölü
}

if ($Mutasyon) {
  $psExe = if (Get-Command powershell -ErrorAction SilentlyContinue) { 'powershell' } else { 'pwsh' }   # CI (Linux): pwsh
  $kirmizi = 0; $olculemedi = 0
  foreach ($mAd in $MUTASYONLAR.Keys) {
    $env:SK_MUTASYON = $mAd
    & $psExe -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -Sessiz | Out-Null
    $kod = $LASTEXITCODE
    if ($kod -eq 1) { $kirmizi++; "  mutasyon {0,-15} KIRMIZI (doğru)" -f $mAd }
    elseif ($kod -eq 3) { $olculemedi++; "  mutasyon {0,-15} ÖLÇÜLEMEDİ (bozma hedefi bölgede yok)" -f $mAd }
    else { "  mutasyon {0,-15} YEŞİL (YANLIŞ — sınav bu koşulu görmüyor)" -f $mAd }
  }
  $env:SK_MUTASYON = $null
  "$kirmizi/$($MUTASYONLAR.Count) mutasyon KIRMIZI$(if($olculemedi){" · $olculemedi ÖLÇÜLEMEDİ"})"
  if ($kirmizi -ne $MUTASYONLAR.Count) { exit 1 }; exit 0
}

# --- gerçek bölgeyi yükle ---
$kaynak = [IO.File]::ReadAllText((Join-Path $depoKok 'motor/kaydir-coz.ps1'), [Text.Encoding]::UTF8)
$M = "$env:SK_MUTASYON"
if ($M) {   # 01.11: mutasyon BÜTÜN dosyaya uygulanır (çağrı yeri bölge dışında), sonra bölge kesilir
  if (-not $MUTASYONLAR.Contains($M)) { Write-Host "bilinmeyen SK_MUTASYON=$M" -ForegroundColor Red; exit 3 }
  $hedef = $MUTASYONLAR[$M][0]
  if (-not $kaynak.Contains($hedef)) { Write-Host "mutasyon hedefi kaydir-coz.ps1'de yok: $hedef" -ForegroundColor Yellow; exit 3 }
  $kaynak = $kaynak.Replace($hedef, $MUTASYONLAR[$M][1])
}
$bolge = [regex]::Match($kaynak, '(?s)# -+ sik-karne .*?\r?\n(.*?)# -+ /sik-karne')
if (-not $bolge.Success) { Write-Host 'motor/kaydir-coz.ps1 sik-karne bölgesi BULUNAMADI — sınav KÖR' -ForegroundColor Red; exit 1 }
$kod = $bolge.Groups[1].Value
. ([scriptblock]::Create($kod))
foreach ($gerekli in 'SikKokYonu', 'SikKarneDuzelt', 'SikOnculKumesi', 'ThpTanimKes') { if (-not (Get-Command $gerekli -CommandType Function -ErrorAction SilentlyContinue)) { Write-Host "bölgede $gerekli yok — sınav KÖR" -ForegroundColor Red; exit 1 } }

$gecen = 0; $toplam = 0; $dusen = New-Object System.Collections.Generic.List[string]
function Sonuc([string]$ad, [string]$beklenen, [string]$cikan) {
  $script:toplam++
  if ($cikan -ceq $beklenen) { $script:gecen++; if (-not $Sessiz) { "  OK    $ad" } }
  else { $script:dusen.Add("$ad → beklenen «$beklenen», çıkan «$cikan»"); if (-not $Sessiz) { "  DÜŞTÜ $ad`n        beklenen «$beklenen»`n        çıkan    «$cikan»" } }
}
function Yon([string]$ad, [string]$soru, [string]$beklenen) { Sonuc "yön: $ad" $beklenen (SikKokYonu $soru) }
# beş şık adımı; $kararlar = 'DYYYY' gibi (A..E sırası), '-' = karar alanı yok
function Adimlar([string]$kararlar) {
  $l = @(); $i = 0
  foreach ($h in 'A', 'B', 'C', 'D', 'E') { $c = "$($kararlar[$i])"; $i++; $a = @{ anlatim = ''; formul = "Şık $h"; sik = $h }; if ($c -eq 'Y') { $a.karar = 'yanlış' } elseif ($c -eq 'D') { $a.karar = 'doğru' }; $l += $a }
  , $l
}
function Karne($adimlar) { ($adimlar | ForEach-Object { if ($_.ContainsKey('karar')) { if ("$($_.karar)" -match '^(?i)y') { 'Y' } else { 'D' } } else { '-' } }) -join '' }
function Duzelt([string]$ad, [string]$kararlar, [string]$dogru, [string]$soru, [string]$etiket, [string]$beklenenKarne, [int]$beklenenCeliski, $sikKume = $null) {
  $a = Adimlar $kararlar; $r = SikKarneDuzelt $a $dogru $soru $etiket $sikKume
  Sonuc "düzelt: $ad" "$beklenenKarne/$beklenenCeliski" "$(Karne $a)/$($r.celiski)"
}

# --- KÖK YÖNÜ: olumsuz ---
Yon 'doğru değildir'            'Vergi Usul Kanunu''na göre aşağıdakilerden hangisi doğru değildir?' 'olumsuz'
Yon 'yanlıştır'                 'Buna göre aşağıdaki ifadelerden hangisi yanlıştır?' 'olumsuz'
Yon 'sayılmaz'                  'Aşağıdakilerden hangisi ticari iş sayılmaz?' 'olumsuz'
Yon '-amaz (konulamaz)'         'Hangisi ayni sermaye olarak şirkete konulamaz?' 'olumsuz'
Yon '-mamıştır'                 'Aşağıdaki gelişmelerden hangisi bu dönemde yaşanmamıştır?' 'olumsuz'
Yon 'BÜYÜK HARF DEĞİLDİR'       'Aşağıdakilerden hangisi denetim ekibinin sorumluluklarından biri DEĞİLDİR?' 'olumsuz'
Yon '-mayan … hangisidir'       'Çekte bulunması zorunlu unsurlardan biri sayılmayan husus aşağıdakilerden hangisidir?' 'olumsuz'
Yon 'yanlış verilmiştir'        'Aşağıdakilerden hangisinde çalışma ile aşama yanlış verilmiştir?' 'olumsuz'
Yon 'yanlış olduğu soruluyor'   'Beş ifadeden hangisinin yanlış olduğu soruluyor.' 'olumsuz'
Yon 'söylenemez'                'Bu olay için aşağıdakilerden hangisi söylenemez?' 'olumsuz'
# --- olumlu ---
Yon 'doğrudur'                  'Buna göre aşağıdaki ifadelerden hangisi doğrudur?' 'olumlu'
Yon 'hangisidir'                'Bu fiile uygulanacak ceza aşağıdakilerden hangisidir?' 'olumlu'
Yon 'çok cümleli olay + kök'    'A A.Ş. 2025 yılında mal satmıştır. Satış bedeli tahsil edilmemiştir. Bu durumda denetçi hangi görüşü verir?' 'olumlu'
Yon 'GÖRMEZ: anlamca olumsuz, eki yok (istisnadır) — olumlu sayılır' 'Aşağıdakilerden hangisi KDV''den istisnadır?' 'olumlu'
# --- belirsiz ---
Yon 'aykırıdır'                 'Aşağıdakilerden hangisi kanuna aykırıdır?' 'belirsiz'
Yon 'yasaktır'                  'Meslek mensubu için aşağıdakilerden hangisi yasaktır?' 'belirsiz'
Yon 'aykırı olduğu soruluyor'   'Beş ifadeden hangisinin kanun metnine aykırı olduğu soruluyor?' 'belirsiz'
Yon 'iki yönlü: değil, …-dır'   'Aşağıdakilerden hangisi bu kapsamda denetim ekibinin değil, denetim şirketi düzeyinde yapılan bir iştir?' 'belirsiz'
Yon 'iki yönlü: SAYILMAYAN, …'  'Kişisel çıkar tehdidi örnekleri arasında SAYILMAYAN, başka bir tehdit türüne ait örnek aşağıdakilerden hangisidir?' 'belirsiz'
Yon 'iki yönlü: ; ile'          'Aşağıdakilerden hangisi bu sürecin HER ZAMAN girdisi niteliğindedir; hiçbir aşamanın çıktısı olmaz?' 'belirsiz'
Yon 'öncül: hangileri'          'Yukarıdaki önermelerden hangileri doğrudur?' 'belirsiz'
Yon 'sayma: kaç yıl … -emez'    'Denetçi kaç yıl geçmedikçe o şirkette yeniden denetçi olarak seçilemez?' 'belirsiz'
Yon 'hata soruluyor: yazım yanlışı yoktur' 'Aşağıdaki cümlelerin hangisinde bir yazım yanlışı yoktur?' 'belirsiz'
Yon 'olumsuzluk eki var, olumsuz bitmiyor' 'Beyannamesini vermeyen mükellef için aşağıdakilerden hangisi doğrudur?' 'belirsiz'
Yon 'kök soru değil (boşluk doldurma)' 'Mükellef beyannamesini ____ gün içinde verir' 'belirsiz'
# --- 01.11 "henüz" kalıbı (Ajan 37 ölçümü: smmm-olc2-b-vergi/kp-30) — sorulan bir DURUM, olumsuz kök değil → belirsiz ---
Yon 'henüz dolmamıştır (kp-30)'  'Buna göre, 01.10.2026 tarihi itibarıyla, 213 sayılı VUK''un 253. maddesine göre yukarıdakilerden hangisinin muhafaza süresi henüz dolmamıştır?' 'belirsiz'
Yon 'henüz yerine getirmemiştir' 'Buna göre aday, 3568 sayılı Kanun''un 5. maddesindeki özel şartlardan hangisini henüz yerine getirmemiştir?' 'belirsiz'
Yon 'henüz … olmayan … hangisidir' 'Ara dönemde düzenlenen ve henüz mali tabloların dayanağı olmayan mizan aşağıdakilerden hangisidir?' 'belirsiz'
Yon 'henüz -mamaktadır'           'Aşağıdaki şirketlerden hangisi henüz tescil edilmemektedir?' 'belirsiz'
Yon 'henüz -maz'                  'Aşağıdaki alacaklardan hangisi henüz zamanaşımına uğramaz?' 'belirsiz'
Yon 'henüz var ama kök yanlıştır → olumsuz kalır' 'Henüz kurulmuş bir girişim şirketine ilişkin olarak aşağıdakilerden hangisi yanlıştır?' 'olumsuz'
Yon 'henüz önceki cümlede → son cümle olumsuz kalır' 'Şirketin denetimi henüz tamamlanmamıştır. Aşağıdakilerden hangisi ticari iş sayılmaz?' 'olumsuz'
Yon '"henüz"süz -mamıştır → olumsuz kalır (GÖRMEZ: anlamca olumlu olabilir)' 'Yukarıdakilerden hangisinin muhafaza süresi dolmamıştır?' 'olumsuz'

# --- KARAR DÜZELTME (anahtar C) ---
$olumsuz = 'Aşağıdakilerden hangisi ticari iş sayılmaz?'; $olumlu = 'Aşağıdakilerden hangisi doğrudur?'; $belirsiz = 'Aşağıdakilerden hangisi kanuna aykırıdır?'
Duzelt 'olumsuz kök, ters karar → anahtara göre'      'YYDYY' 'C' $olumsuz 'smmm-x-yhukuk-kolay' 'DDYDD' 5
Duzelt 'olumsuz kök, doğru karar → dokunulmaz'        'DDYDD' 'C' $olumsuz 'smmm-x-yhukuk-kolay' 'DDYDD' 0
Duzelt 'olumsuz kök, tek şık ters → yalnız o'         'DDYDY' 'C' $olumsuz 'smmm-x-yhukuk-kolay' 'DDYDD' 1
Duzelt 'olumlu kök, ters karar → anahtara göre'       'DDYDD' 'C' $olumlu 'smmm-x-yhukuk-kolay' 'YYDYY' 5
Duzelt 'olumlu kök, doğru karar → dokunulmaz'         'YYDYY' 'C' $olumlu 'smmm-x-yhukuk-kolay' 'YYDYY' 0
Duzelt 'belirsiz kök, olumlu biçimli karar → AYNEN'   'YYDYY' 'C' $belirsiz 'smmm-x-yhukuk-kolay' 'YYDYY' 0
Duzelt 'belirsiz kök, olumsuz biçimli karar → AYNEN'  'DDYDD' 'C' $belirsiz 'smmm-x-yhukuk-kolay' 'DDYDD' 0
Duzelt 'dil dersi (SGS Türkçe) olumsuz kök → AYNEN'   'YYDYY' 'C' $olumsuz 'sgs-t1-genel-turkce-kolay' 'YYDYY' 0
Duzelt 'SGS kaydı (ticaret) olumsuz ters → düzelir'   'YYDYY' 'C' $olumsuz 'sgs-t1-ticaret-kolay' 'DDYDD' 5
Duzelt 'karar alanı boş şık → dokunulmaz, - kalır'    'YY-YY' 'C' $olumsuz 'smmm-x-yhukuk-kolay' 'DD-DD' 4
Duzelt 'anahtar yok → dokunulmaz'                     'YYDYY' ''  $olumsuz 'smmm-x-yhukuk-kolay' 'YYDYY' 0
$a0 = Adimlar 'YYDYY'; [void](SikKarneDuzelt $a0 'C' $olumsuz 'smmm-x'); Sonuc 'düzeltilen karar metni (doğru/doğru/yanlış)' 'doğru|doğru|yanlış' "$($a0[0].karar)|$($a0[1].karar)|$($a0[2].karar)"
$bos = @(@{ anlatim = 'kayıt adımı'; formul = 'Kayıt' }); $rb = SikKarneDuzelt $bos 'C' $olumsuz 'smmm-x'; Sonuc 'şık adımı olmayan soru → yön bakılmaz' '/0/0' "$($rb.yon)/$($rb.sik)/$($rb.celiski)"

# --- 01.11 ÖNCÜL KÜMESİ (KURAL2710_ONCUL: şık adımı "Şık B (Yalnız II): … bu mu?" — karar "bu küme cevap mı") → yön belirsiz, karar AYNEN ---
$kp08 = 'I. Çekirdek enflasyon hesabında işlenmemiş gıda, enerji, alkol-tütün ve altın kalemleri sepetten çıkarılır. II. Çekirdek enflasyon her zaman manşet enflasyondan düşük çıkar. III. Enflasyon hedefi manşet enflasyon üzerinden ilan edilir. Yukarıdakilerden hangisi yanlıştır?'
$oncul = @{ A = 'Yalnız I'; B = 'Yalnız II'; C = 'I ve II'; D = 'II ve III'; E = 'I, II ve III' }
Duzelt 'öncül + "yanlıştır" (sgs-e16-ekonomi-zor/kp-08) → AYNEN' 'YDYYY' 'B' $kp08 'sgs-e16-ekonomi-zor' 'YDYYY' 0 $oncul
Duzelt 'öncül + olumlu kök, ters yazılmış küme kararı → AYNEN (GÖRMEZ)' 'DYDDD' 'B' 'Yukarıdakilerden hangisi doğrudur?' 'smmm-x' 'DYDDD' 0 $oncul
Duzelt 'öncül + olumsuz kök "sayılmaz" → AYNEN'        'YDYYY' 'B' $olumsuz 'smmm-x-yhukuk-kolay' 'YDYYY' 0 $oncul
$onculNesne = [pscustomobject]@{ A = 'Yalnız I'; B = 'Yalnız II'; C = 'I ve III'; D = 'II ve III'; E = 'I, II ve III' }
Duzelt 'öncül şıkları NESNE (ambar JSON) → AYNEN'      'YDYYY' 'B' $kp08 'sgs-e16-ekonomi-zor' 'YDYYY' 0 $onculNesne
$onculDort = @{ A = 'Yalnız I'; B = 'I ve II'; C = 'I, II ve III'; D = 'II ve IV'; E = 'Hiçbiri' }
Duzelt 'öncül 4/5 Roma (eşik) → AYNEN'                 'YDYYY' 'B' $kp08 'smmm-x' 'YDYYY' 0 $onculDort
$ucRoma = @{ A = 'Yalnız I'; B = 'I ve II'; C = 'II ve III'; D = 'Hepsi'; E = 'Hiçbiri' }
Duzelt '3/5 Roma (eşik altı) → öncül değil, düzelir'    'YDYYY' 'B' $kp08 'smmm-x' 'DYDDD' 5 $ucRoma
$sultan = @{ A = 'Abdülaziz'; B = 'V. Murat'; C = 'II. Abdülhamit'; D = 'V. Mehmet Reşat'; E = 'VI. Mehmet Vahdettin' }
Duzelt 'Roma rakamlı AD ("V. Murat") → öncül değil, düzelir' 'YYDYY' 'C' 'Aşağıdakilerden hangisi bu dönemde yaşanmamıştır?' 'sgs-t1-genel-inkilap-zor' 'DDYDD' 5 $sultan
$onculSiz = @{ A = 'Vergi dairesi'; B = 'Mükellef'; C = 'Vergi sorumlusu'; D = 'Kefil'; E = 'Mirasçı' }
Duzelt 'düz metin şıklar → eski davranış (düzelir)'     'YYDYY' 'C' $olumsuz 'smmm-x-yhukuk-kolay' 'DDYDD' 5 $onculSiz
Duzelt 'şık metni verilmedi ($null) → eski davranış'   'YYDYY' 'C' $olumsuz 'smmm-x-yhukuk-kolay' 'DDYDD' 5
Duzelt 'henüz dolmamıştır (kp-30), anahtar doğru → AYNEN' 'YYDYY' 'C' 'Buna göre yukarıdakilerden hangisinin muhafaza süresi henüz dolmamıştır?' 'smmm-olc2-b-vergi' 'YYDYY' 0 $onculSiz
$ro = SikKarneDuzelt (Adimlar 'YDYYY') 'B' $kp08 'sgs-e16-ekonomi-zor' $oncul; Sonuc 'öncül sonucu işaretli (oncul/yon)' 'True/belirsiz' "$($ro.oncul)/$($ro.yon)"
Sonuc 'öncül deseni: küçük harfli "yalnız i" değil, "Yalnız I" tutar' 'False/True' "$(SikOnculKumesi @{A='yalnız i';B='ii';C='iii';D='iv';E='v'})/$(SikOnculKumesi @{A='Yalnız I';B='Yalnız II';C='I ve II';D='I, II ve III';E='I-III'})"

# --- ÇAĞRI YERİ (bölge DIŞI, motor/kaydir-coz.ps1): şık metni geçirilmezse öncül kapısı ölüdür ---
Sonuc 'kaydir-coz.ps1 SikKarneDuzelt çağrısı şık metnini ($siklar) geçiriyor' 'True' "$($kaynak -match 'SikKarneDuzelt\s+\$adimlar\s+\$d\s+"\$\(\$v\.soru\)"\s+"\$\(\$x\.et\)"\s+\$siklar\b')"

# --- THP UYGULAMA NOTU ---
$not = '(31.10.2026 UYGULAMA NOTU: MSUGT Sıra No 2 (RG 16.12.1993/21790) ile 652→657 değişti, 647 Reeskont Faiz Gelirleri açıldı; uygulamada karşı hesap 647/657.)'
$govde = ('Alacak senetlerinin reeskontu bu hesapta izlenir. ' * 9).Trim()   # ~440 karakter, ". " ile bölünebilir
function EskiKes([string]$m) { if ($m.Length -gt 340) { $kes = $m.LastIndexOf('. ', 340); if ($kes -gt 120) { $m = $m.Substring(0, $kes + 1) } else { $m = $m.Substring(0, 340) + '…' } }; $m }
$kisa = 'Senetli alacakların reeskontu izlenir.'
Sonuc 'not yok, kısa → aynı'                           $kisa (ThpTanimKes $kisa)
Sonuc 'not yok, uzun → eski kesimle AYNI'              (EskiKes $govde) (ThpTanimKes $govde)
$uzunNoktasiz = 'x' * 400
Sonuc 'not yok, noktasız uzun → eski kesimle AYNI (…)' (EskiKes $uzunNoktasiz) (ThpTanimKes $uzunNoktasiz)
$t = ThpTanimKes ("$govde $not")
Sonuc 'not var, uzun → not sonda TAM (iç parantez dahil)' 'True' "$($t.EndsWith($not))"
Sonuc 'not var, uzun → gövde eski kuralla kesilir'     ((EskiKes $govde) + ' ' + $not) $t
Sonuc 'not var, kısa → metin değişmez'                 "$kisa $not" (ThpTanimKes "$kisa $not")
Sonuc 'not ortadaysa sona alınır, metin kaybolmaz'     "Birinci cümle. Hesabın işleyişi şöyledir. $not" (ThpTanimKes "Birinci cümle. $not Hesabın işleyişi şöyledir.")

''
$durum = $(if ($gecen -eq $toplam) { 'YEŞİL' } else { 'KIRMIZI' })
"ŞIK KARNESİ + THP NOTU ÖZ-SINAVI: $durum — $gecen/$toplam$(if($M){" · SK_MUTASYON=$M"})"
if ($dusen.Count) { if (-not $Sessiz) { foreach ($d in $dusen) { Write-Host "  KIRMIZI: $d" -ForegroundColor Red } }; exit 1 }
exit 0
