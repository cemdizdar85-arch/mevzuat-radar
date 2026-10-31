#requires -Version 5.1
<#
================================================================================
  ŞIK KARNESİ YÖNÜ + THP UYGULAMA NOTU — ÖZ-SINAV  (31.10.2026)  AĞ YOK, PARA YOK

  NİYE VAR: motor/kaydir-coz.ps1 şık karnesinin "Karar" etiketini (tablo · karar rozeti · hücre rengi · "Önce sen karar ver")
  yalnız adımın karar alanından basıyordu; kök yönü okunmuyordu. Olumsuz kökte ters yazılmış karar öğrenciye ters etiket
  gösterdi (sitede 25 SMMM sorusu, Ajan 22 ölçümü 31.10). Ayrıca THP tanımı 340 karakterde kesilirken sondaki
  "(31.10.2026 UYGULAMA NOTU: …)" düşüyordu (THP 122/137/322/337/422). Cem 31.10: "evet".

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
$bolge = [regex]::Match($kaynak, '(?s)# -+ sik-karne .*?\r?\n(.*?)# -+ /sik-karne')
if (-not $bolge.Success) { Write-Host 'motor/kaydir-coz.ps1 sik-karne bölgesi BULUNAMADI — sınav KÖR' -ForegroundColor Red; exit 1 }
$kod = $bolge.Groups[1].Value
$M = "$env:SK_MUTASYON"
if ($M) {
  if (-not $MUTASYONLAR.Contains($M)) { Write-Host "bilinmeyen SK_MUTASYON=$M" -ForegroundColor Red; exit 3 }
  $hedef = $MUTASYONLAR[$M][0]
  if (-not $kod.Contains($hedef)) { Write-Host "mutasyon hedefi bölgede yok: $hedef" -ForegroundColor Yellow; exit 3 }
  $kod = $kod.Replace($hedef, $MUTASYONLAR[$M][1])
}
. ([scriptblock]::Create($kod))
foreach ($gerekli in 'SikKokYonu', 'SikKarneDuzelt', 'ThpTanimKes') { if (-not (Get-Command $gerekli -CommandType Function -ErrorAction SilentlyContinue)) { Write-Host "bölgede $gerekli yok — sınav KÖR" -ForegroundColor Red; exit 1 } }

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
function Duzelt([string]$ad, [string]$kararlar, [string]$dogru, [string]$soru, [string]$etiket, [string]$beklenenKarne, [int]$beklenenCeliski) {
  $a = Adimlar $kararlar; $r = SikKarneDuzelt $a $dogru $soru $etiket
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
