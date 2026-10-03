#requires -Version 5.1
<#
================================================================================
  TÜRKÇE ONARIM (TurkceOnar) — ÖZ-SINAV  (03.10.2026)  AĞ YOK, PARA YOK

  NİYE VAR: motor/kaydir-coz.ps1 sayfa basarken ASCII kelimeyi korpustaki en sık Türkçe biçimle
  değiştiriyor. Sitedeki kasada üç hata sınıfı görüldü: kesmeden sonraki ek ('çocuk'tur → 'çocuk'tür),
  İngilizce metin (WHICH → WHİCH), anlamı belirsiz kelime (Esasi → Esası, bol → böl, hala → hâlâ).
  Sınav hem DÜZELTMESİ gerekeni (ayni → aynı, BORC → BORÇ, Isletme → İşletme) hem BOZMAMASI gerekeni ölçer.

  ⛔ REPLİKA YASAK: kaydir-coz.ps1'in "# ---- turkce-onar" … "# ---- /turkce-onar" bölgesi AYNEN yüklenir.
     Sözlük ($SOZ/$ENF/$IVAR) küçük ve sahtedir — işlevin mantığı sınanır, korpus değil.

  MUTASYON (KAPI KURMA KURALI 8): TO_MUTASYON=<ad> bölge metnindeki koruma koşulunu bilerek bozar; sınav
  KIRMIZI düşmelidir. -Mutasyon hepsini sırayla koşar: "N/M mutasyon KIRMIZI".
  Bozma hedefi metinde bulunamazsa çıkış 3 (mutasyon ÖLÇÜLEMEDİ — kırmızı sayılmaz).

  🚫 GÖRMEZ: gerçek sözlüğün içeriği (hangi kelimenin hangi biçime gittiği — eşdeğerlik provası ölçer) ·
     sayfa basımındaki öteki alan işleyicileri (OranYuzdeSatir, ThpTanim) · tırnaksız, işlev sözcüğü
     taşımayan kısa İngilizce parça (bilinen körlük; vakası aşağıda "GÖRMEZ" diye işaretli, beklenen = bugünkü davranış).

  KULLANIM
    powershell -NoProfile -File arac/turkce-onar-sinavi.ps1            # öz-sınav
    powershell -NoProfile -File arac/turkce-onar-sinavi.ps1 -Mutasyon  # bütün mutasyonlar
================================================================================
#>
param([switch]$Mutasyon, [switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin

$MUTASYONLAR = [ordered]@{
  'kesme'     = @('if($ix -ge 2 -and $TURKCE_ONAR_KESME.IndexOf', 'if($false -and $ix -ge 2 -and $TURKCE_ONAR_KESME.IndexOf')
  'liste'     = @('if($TURKCE_ONAR_KORU.ContainsKey($kucukW)){ return $w }', 'if($false){ return $w }')
  'en-kelime' = @('if($TURKCE_ONAR_EN_KESIN.Contains($w)){ return $w }', 'if($false){ return $w }')
  'en-harf'   = @('if($w -match ''[wqx]''){ return $w }', 'if($false){ return $w }')
  'en-parca'  = @('foreach($pm in $TURKCE_ONAR_PARCA_RX.Matches($t))', 'foreach($pm in @())')
  'en-yogun'  = @('if(TurkceOnarEnMi (TurkceOnarEnSay $t) $false)', 'if($false)')
  'en-tirnak' = @('$(if($tirnakli){1}else{2})', '2')
  'en-tr-kanit' = @('-and $say[3] -le $(if($tirnakli){$say[0]}else{$say[0]/2}))', ')')
  'en-tr-yari' = @('else{$say[0]/2}', 'else{$say[0]}')
  'i-basi'    = @('-and $SOZ[$k0].StartsWith(''i'')', '-and $false')
}

if ($Mutasyon) {
  # CI (Linux) runner'da 'powershell' yok, 'pwsh' var (02.10 dersi, aciklama-hakemi-uretim-sinavi.ps1)
  $psExe = if (Get-Command powershell -ErrorAction SilentlyContinue) { 'powershell' } else { 'pwsh' }
  $kirmizi = 0; $olculemedi = 0
  foreach ($mAd in $MUTASYONLAR.Keys) {
    $env:TO_MUTASYON = $mAd
    & $psExe -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -Sessiz | Out-Null
    $kod = $LASTEXITCODE
    if ($kod -eq 1) { $kirmizi++; "  mutasyon {0,-10} KIRMIZI (doğru)" -f $mAd }
    elseif ($kod -eq 3) { $olculemedi++; "  mutasyon {0,-10} ÖLÇÜLEMEDİ (bozma hedefi bölgede yok)" -f $mAd }
    else { "  mutasyon {0,-10} YEŞİL (YANLIŞ — sınav bu korumayı görmüyor)" -f $mAd }
  }
  $env:TO_MUTASYON = $null
  "$kirmizi/$($MUTASYONLAR.Count) mutasyon KIRMIZI$(if($olculemedi){" · $olculemedi ÖLÇÜLEMEDİ"})"
  if ($kirmizi -ne $MUTASYONLAR.Count) { exit 1 }; exit 0
}

# --- gerçek bölgeyi yükle ---
$kaynak = [IO.File]::ReadAllText((Join-Path $depoKok 'motor/kaydir-coz.ps1'), [Text.Encoding]::UTF8)
$bolge = [regex]::Match($kaynak, '(?s)# -+ turkce-onar.*?\r?\n(.*?)# -+ /turkce-onar')
if (-not $bolge.Success) { Write-Host 'motor/kaydir-coz.ps1 turkce-onar bölgesi BULUNAMADI — sınav KÖR' -ForegroundColor Red; exit 1 }
$kod = $bolge.Groups[1].Value
$M = "$env:TO_MUTASYON"
if ($M) {
  if (-not $MUTASYONLAR.Contains($M)) { Write-Host "bilinmeyen TO_MUTASYON=$M" -ForegroundColor Red; exit 3 }
  $hedef = $MUTASYONLAR[$M][0]
  if (-not $kod.Contains($hedef)) { Write-Host "mutasyon hedefi bölgede yok: $hedef" -ForegroundColor Yellow; exit 3 }
  $kod = $kod.Replace($hedef, $MUTASYONLAR[$M][1])
}
. ([scriptblock]::Create($kod))
foreach ($gerekli in 'Katla', 'TurkceOnar') { if (-not (Get-Command $gerekli -CommandType Function -ErrorAction SilentlyContinue)) { Write-Host "bölgede $gerekli yok — sınav KÖR" -ForegroundColor Red; exit 1 } }

# --- küçük sahte sözlük (kaydir-coz.ps1'deki biçim: SOZ katlanmış→Türkçe · ENF en sık biçim · IVAR i ile başlayan biçim var) ---
$SOZ = @{ ayni = 'aynı'; ogrenci = 'öğrenci'; kayit = 'kayıt'; icin = 'için'; borc = 'borç'; isletme = 'işletme'; cumlesini = 'cümlesini'
  bicimde = 'biçimde'; hatayi = 'hatayı'; cumleyi = 'cümleyi'; yanlis = 'yanlış'; cevirir = 'çevirir'; dogru = 'doğru'; ceviri = 'çeviri'; kalir = 'kalır'
  tur = 'tür'; uncu = 'üncü'; bol = 'böl'; hala = 'hâlâ'; asli = 'aslı'; esasi = 'esası'; ucu = 'üçü'; kara = 'kâra'; asil = 'asıl'; kati = 'katı'
  sure = 'süre'; cumlede = 'cümlede'; tesvike = 'teşvike'; ragmen = 'rağmen'; zitlik = 'zıtlık'; anlatilir = 'anlatılır'; bosluga = 'boşluğa'; cumle = 'cümle'; anlamli = 'anlamlı' }
$ENF = @{ ayni = 'aynı'; borc = 'borç'; which = 'which'; this = 'this'; quiz = 'quiz'; isletme = 'işletme'; kara = 'kâra'; esasi = 'esası'; sure = 'süre'; hisse = 'hisse' }
$IVAR = @{ isletme = $true; iptal = $true }

$gecen = 0; $toplam = 0; $dusen = New-Object System.Collections.Generic.List[string]
function Vaka([string]$ad, [string]$girdi, [string]$beklenen) {
  $script:toplam++
  $cikan = TurkceOnar $girdi
  if ($cikan -ceq $beklenen) { $script:gecen++; if (-not $Sessiz) { "  OK    $ad" } }
  else { $script:dusen.Add("$ad → beklenen «$beklenen», çıkan «$cikan»"); if (-not $Sessiz) { "  DÜŞTÜ $ad`n        beklenen «$beklenen»`n        çıkan    «$cikan»" } }
}

# --- DÜZELTMESİ gerekenler ---
Vaka 'ASCII → Türkçe (ayni)' 'ayni' 'aynı'
Vaka 'ASCII → Türkçe (ogrenci, cümle başı büyük)' 'Ogrenci ayni kayit icin' 'Öğrenci aynı kayıt için'
Vaka 'TÜMÜ BÜYÜK tr-TR (BORC → BORÇ)' '100 KASA (BORC)' '100 KASA (BORÇ)'
Vaka 'TÜMÜ BÜYÜK İ (HISSE → HİSSE)' 'HISSE' 'HİSSE'
Vaka 'I ile başlayan (Isletme → İşletme)' 'Isletme' 'İşletme'
Vaka 'kesmeden ÖNCEKİ kök düzelir (borc''un)' 'borc''un' 'borç''un'
Vaka 'Türkçe açıklama + tırnaklı İngilizce cümle: dışı düzelir, tırnak içi kalır' 'Ogrenci "Sure the price rose" cumlesini ayni bicimde okur.' 'Öğrenci "Sure the price rose" cümlesini aynı biçimde okur.'
Vaka 'Türkçe açıklama + tırnaksız İngilizce cümle: Türkçe kısım düzelir, İngilizce cümle kalır' 'Ogrenci ayni hatayi yapar ve cumleyi yanlis cevirir: I am sure that the rate will rise. Dogru ceviri gelecek zaman kipidir ve ayni kalir.' 'Öğrenci aynı hatayı yapar ve cümleyi yanlış çevirir: I am sure that the rate will rise. Doğru çeviri gelecek zaman kipidir ve aynı kalır.'
Vaka 'yabancı dil AÇIKLAMASI (İngilizce sözcük sayan Türkçe cümle) onarılır — Türkçe kanıtı' 'Because/because of/since/as SEBEP bildirir; cumlede sebep değil, tesvike ragmen olumsuz tepki (zitlik) anlatilir.' 'Because/because of/since/as SEBEP bildirir; cümlede sebep değil, teşvike rağmen olumsuz tepki (zıtlık) anlatılır.'
Vaka 'yabancı dil AÇIKLAMASI, tırnaklı İngilizce sözcüklerle — Türkçe kısım onarılır' 'Bosluga ''who is'' veya ''who has'' koyup cumle anlamli oluyor mu?' 'Boşluğa ''who is'' veya ''who has'' koyup cümle anlamlı oluyor mu?'
Vaka 'kısaltma açımı korunur (FIFO)' 'FIFO' 'ilk giren ilk çıkar (FIFO)'

# --- BOZMAMASI gerekenler ---
Vaka 'kesme sonrası ek (''çocuk''tur)' '''çocuk''tur' '''çocuk''tur'
Vaka 'kesme sonrası ek, rakam (9''uncu)' '9''uncu madde' '9''uncu madde'
Vaka 'kesme sonrası ek, tipografik (9 U+2019 uncu)' ("9$([char]0x2019)uncu madde") ("9$([char]0x2019)uncu madde")   # ’ tek tırnaklı dizeyi KAPATIR, [char] ile
Vaka 'belirsiz: Kanun-i Esasi' 'Kanun-i Esasi' 'Kanun-i Esasi'
Vaka 'belirsiz: bol' 'bol miktarda' 'bol miktarda'
Vaka 'belirsiz: hala' 'hala ve teyze' 'hala ve teyze'
Vaka 'belirsiz: asli' 'asli unsur' 'asli unsur'
Vaka 'belirsiz: ucu' 'kalemin ucu' 'kalemin ucu'
Vaka 'belirsiz: kara (TÜMÜ BÜYÜK dahil)' 'kara para · KARA PARA' 'kara para · KARA PARA'
Vaka 'belirsiz: tur' 'ikinci tur' 'ikinci tur'
Vaka 'belirsiz: asil' 'asil üye' 'asil üye'
Vaka 'belirsiz: kati' 'kati hüküm' 'kati hüküm'
Vaka 'İngilizce işlev sözcüğü TÜMÜ BÜYÜK (WHICH)' 'Soruda WHICH kelimesi var' 'Soruda WHICH kelimesi var'
Vaka 'İngilizce işlev sözcüğü, w/q/x yok (THIS)' 'Soruda THIS kelimesi var' 'Soruda THIS kelimesi var'
Vaka 'Türk alfabesinde olmayan harf (QUIZ)' 'Bu bölümde QUIZ var' 'Bu bölümde QUIZ var'
Vaka 'İngilizce cümle' 'The firm is sure that the rate will rise.' 'The firm is sure that the rate will rise.'
Vaka 'İngilizce dize, parçalar kısa (yoğunluk)' 'Sure. The rate will rise; it is clear.' 'Sure. The rate will rise; it is clear.'
# GÖRMEZ (bilinen körlük — beklenen = bugünkü davranış; düzelirse bu vaka güncellenir): tırnaksız, işlev sözcüğü taşımayan İngilizce parça
Vaka 'GÖRMEZ: Türkçe cümlede tırnaksız tek İngilizce kelime (sure) — bugün süre olur' 'Bu cümlede sure kelimesi geçer.' 'Bu cümlede süre kelimesi geçer.'

''
$durum = $(if ($gecen -eq $toplam) { 'YEŞİL' } else { 'KIRMIZI' })
"TÜRKÇE ONARIM ÖZ-SINAVI: $durum — $gecen/$toplam$(if($M){" · TO_MUTASYON=$M"})"
if ($dusen.Count) { if (-not $Sessiz) { foreach ($d in $dusen) { Write-Host "  KIRMIZI: $d" -ForegroundColor Red } }; exit 1 }
exit 0
