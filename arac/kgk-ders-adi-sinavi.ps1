#requires -Version 5.1
<#
  KGK DERS ADI + YAYIN ŞARTI — ÖZ-SINAV  (27.09.2026)  bedel 0, ağ yok
  arac/kgk-ders-adi.ps1 (modül haritası, eski hat deseni) ve arac/kgk-yayin-sarti.ps1 (KgkYayinSarti, KgkOnayHarita).
  Hem yakalaması gerekeni hem YANLIŞ yakalamaması gerekeni ölçer; ayrıca yerel KGK partilerinin TAMAMINDA dersi
  çözülemeyen soru var mı bakar (kapsam — "bakmadığını da söyle").
  MUTASYON (KAPI KURMA KURALI 8): KGK_MUTASYON=<ad> ile kapının kilit koşulu bilerek bozulur; sınav KIRMIZI düşmelidir.
    harita-tds   : 'tds' satırı silinir                 · harita-gds : 'gds' → Türkiye Denetim Standartları
    eski-hat     : eski hat deseni boşaltılır            · konu       : konu sözlüğü boşaltılır
    kimlik       : KgkYayinSarti'nin 'kgk-' kimlik şartı kaldırılır
    sart         : KgkYayinSarti her soruyu geçirir
    aciklama-hakemi : AhSecilemez her zaman $false (yeni soru açıklama hakemi kararsız geçer) — 02.10
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
. (Join-Path $buDizin 'kgk-ders-adi.ps1')
. (Join-Path $buDizin 'kgk-yayin-sarti.ps1')

$mutasyon = "$env:KGK_MUTASYON"
if ($mutasyon) { Write-Host "MUTASYON: $mutasyon (sınav KIRMIZI düşmeli)" -ForegroundColor Magenta }
switch ($mutasyon) {
  'harita-tds' { $script:KGK_DERS_KISA.Remove('tds') }
  'harita-gds' { $script:KGK_DERS_KISA['gds'] = 'Türkiye Denetim Standartları' }
  'eski-hat' { $script:KGK_ESKI_HAT = '^$ASLA^' }
  'konu' { $script:KGK_KONU_ES = @{} }
  'kimlik' { function KgkYayinSarti([string]$anahtar, $soruNesne, $onayHarita) { return (SmmmYayinSarti $anahtar $soruNesne $onayHarita) } }
  'sart' { function KgkYayinSarti([string]$anahtar, $soruNesne, $onayHarita) { return [pscustomobject]@{ gecer = $true; neden = 'mutasyon' } } }
  'aciklama-hakemi' { function AhSecilemez($v) { return $false } }   # 02.10: açıklama hakemi bağı koparılır
}

$kalan = New-Object System.Collections.Generic.List[string]
$gecen = 0; $toplam = 0
function Denetle([string]$ad, [bool]$kosul) {
  $script:toplam++
  if ($kosul) { $script:gecen++; if (-not $Sessiz) { "  OK    $ad" } } else { $kalan.Add($ad); if (-not $Sessiz) { "  DUSTU $ad" } }
}

# --- 1) etiketten modül ---
$vakaListesi = @(
  @{ e = 'kgk-gm-tms-r1'; b = 'Türkiye Muhasebe Standartları' }
  @{ e = 'kgk-o2-tds-zor'; b = 'Türkiye Denetim Standartları' }
  @{ e = 'kgk-olcum-tds-bds200'; b = 'Türkiye Denetim Standartları' }
  @{ e = 'kgk-a1-bds315'; b = 'Türkiye Denetim Standartları' }
  @{ e = 'kgk-x-kys1-zor'; b = 'Türkiye Denetim Standartları' }
  @{ e = 'kgk-gm-ky-r1'; b = 'Kurumsal Yönetim' }
  @{ e = 'kgk-x-fy-zor'; b = 'Finansal Yönetim' }
  @{ e = 'kgk-gm-spk-r1'; b = 'Sermaye Piyasası Mevzuatı' }
  @{ e = 'kgk-gm-bank-r1'; b = 'Bankacılık Mevzuatı' }
  @{ e = 'kgk-olcum-banka'; b = 'Bankacılık Mevzuatı' }
  @{ e = 'kgk-olcum-sigorta'; b = 'Sigortacılık ve Özel Emeklilik Mevzuatı' }
  @{ e = 'kgk-x-tsrs-kolay'; b = 'Kurumsal Sürdürülebilirlik Raporlaması' }
  @{ e = 'kgk-gm-gds-r1'; b = 'Sürdürülebilirlik Denetimi' }
  # YANLIŞ ÇÖZMEMELİ: karma parti etiketten TEK modüle atanmaz · kısaltma kelime içinde · SMMM etiketi
  @{ e = 'kgk-olcum-kyfy'; b = '' }
  @{ e = 'kgk-x-tmsler-kolay'; b = '' }
  @{ e = 'kgk-x-bankacilikk'; b = '' }
  @{ e = 'smmm-w6-yspk-zor'; b = '' }
)
foreach ($vk in $vakaListesi) { $cikan = KgkDersAdi $vk.e $null; Denetle ("etiket {0} -> '{1}' (çıkan '{2}')" -f $vk.e, $vk.b, $cikan) ($cikan -eq $vk.b) }

# --- 2) 'ders' alanı ve konu sözlüğü ---
Denetle "ders alanı 'b) Türkiye Denetim Standartları'" ((KgkDersAdi 'kgk-bilinmeyen' ([pscustomobject]@{ ders = 'b) Türkiye Denetim Standartları' })) -eq 'Türkiye Denetim Standartları')
Denetle "ders alanı 'e) Sigortacılık ve Özel Emeklilik' (kapsama biçimi)" ((KgkDersAdi 'kgk-bilinmeyen' ([pscustomobject]@{ ders = 'e) Sigortacılık ve Özel Emeklilik' })) -eq 'Sigortacılık ve Özel Emeklilik Mevzuatı')
Denetle "ders alanı 'Türkiye' tek başına çözülmez" ((KgkDersAdi 'kgk-bilinmeyen' ([pscustomobject]@{ ders = 'Türkiye' })) -eq '')
Denetle "konu 'yonetim kurulu komiteleri' -> Kurumsal Yönetim" ((KgkDersAdi 'kgk-olcum-kyfy' ([pscustomobject]@{ konu = 'yonetim kurulu komiteleri' })) -eq 'Kurumsal Yönetim')
Denetle "konu 'bilesik faiz hesabi' -> Finansal Yönetim" ((KgkDersAdi 'kgk-olcum-kyfy' ([pscustomobject]@{ konu = 'bilesik faiz hesabi' })) -eq 'Finansal Yönetim')
Denetle 'sözlükte olmayan konu boş döner (uydurmaz)' ((KgkDersAdi 'kgk-olcum-kyfy' ([pscustomobject]@{ konu = 'boyle bir konu yok xyz' })) -eq '')

# --- 3) slug + eski hat ---
$moduller = @('Türkiye Muhasebe Standartları', 'Türkiye Denetim Standartları', 'Kurumsal Yönetim', 'Finansal Yönetim', 'Sermaye Piyasası Mevzuatı', 'Bankacılık Mevzuatı', 'Sigortacılık ve Özel Emeklilik Mevzuatı', 'Kurumsal Sürdürülebilirlik Raporlaması', 'Sürdürülebilirlik Denetimi')
$sluglar = @($moduller | ForEach-Object { KgkDersSlug $_ })
Denetle '9 modülün 9 slug''ı var ve benzersiz' ((@($sluglar | Where-Object { $_ -match '^[a-z0-9-]+$' }).Count -eq 9) -and (@($sluglar | Sort-Object -Unique).Count -eq 9))
Denetle 'eski hat yakalanır: kgk-bosluk-* / kgk-kurfin-30 / kgk-muhstd-20' (('kgk-bosluk-trkiyedenetimstandartlar' -match $script:KGK_ESKI_HAT) -and ('kgk-kurfin-30' -match $script:KGK_ESKI_HAT) -and ('kgk-muhstd-20' -match $script:KGK_ESKI_HAT))
Denetle 'eski hat yakalamaz: kgk-gm-tms-r1 / kgk-o2-tds-zor / kgk-kurfin-31' (-not ('kgk-gm-tms-r1' -match $script:KGK_ESKI_HAT) -and -not ('kgk-o2-tds-zor' -match $script:KGK_ESKI_HAT) -and -not ('kgk-kurfin-31' -match $script:KGK_ESKI_HAT))

# --- 4) yayın şartı (sentetik soru; SMMM şartının KGK'da BİREBİR işlediğini ölçer) ---
function TamSoru {
  return ([pscustomobject]@{
      soru = 'BDS 200 kapsamında bağımsız denetçinin genel amacı aşağıdakilerden hangisidir?'; konu = 'bds 200 genel amaclar'; donem = 1
      siklar = [pscustomobject]@{ A = 'Makul güvence elde etmek'; B = 'Kesin güvence vermek'; C = 'Hile soruşturması yapmak'; D = 'Vergi beyannamesi hazırlamak'; E = 'Yönetimin yerine karar almak' }
      dogru = 'A'
      aciklama = [pscustomobject]@{ A = 'Doğru: makul güvence.'; B = 'Kesin güvence verilemez.'; C = 'Soruşturma amaç değildir.'; D = 'Beyanname denetçinin işi değildir.'; E = 'Karar yönetimindir.' }
      teshis = [pscustomobject]@{ B = 't'; C = 't'; D = 't'; E = 't' }
      sade = [pscustomobject]@{ dogru = 'Denetçi makul güvence arar.' }; adimlar = @('adım'); dayanak = 'BDS 200 p.11'
      hakem = [pscustomobject]@{ karar = 'EVET' }; hakem2 = [pscustomobject]@{ karar = 'EVET' }
      kor_cozum = [pscustomobject]@{ dogru_mu = $true; cevap = 'A' }; simulasyon_sonnet = [pscustomobject]@{ dogru_mu = $true }
      kaynak_adlar = @('BDS 200') })
}
$bos = @{}
$script:MD_LISTE = @{}; $script:HAD_HARITA = @{}   # sentetik: repo engel/had listelerinden bağımsız
Denetle 'tam KGK sorusu yayın şartını geçer' ((KgkYayinSarti 'kgk-sinav/kp-01' (TamSoru) $bos).gecer)
Denetle 'KGK dışı kimlik (smmm-) KGK şartından geçmez' (-not (KgkYayinSarti 'smmm-sinav/kp-01' (TamSoru) $bos).gecer)
$bozmalar = [ordered]@{
  'hakem HAYIR'          = { param($q) $q.hakem.karar = 'HAYIR' }
  'hakem2 yok'           = { param($q) $q.hakem2 = $null }
  'kör çözüm yanlış'     = { param($q) $q.kor_cozum.dogru_mu = $false }
  'simülasyon yanlış'    = { param($q) $q.simulasyon_sonnet.dogru_mu = $false }
  'simülasyon koşmamış'  = { param($q) $q.simulasyon_sonnet = $null }
  'HESAP-YANLIS'         = { param($q) $q.hakem | Add-Member -NotePropertyName hesap_uyum -NotePropertyValue 'HESAP-YANLIS' }
  'KONU-DISI'            = { param($q) $q.hakem | Add-Member -NotePropertyName konu_uyum -NotePropertyValue 'KONU-DISI' }
  'yanlış şık teşhisi yok (KAPI-KC)' = { param($q) $q.teshis = [pscustomobject]@{ B = 't' } }
  'sade anlatım yok (KAPI-KC)' = { param($q) $q.sade = $null }
}
foreach ($bz in $bozmalar.GetEnumerator()) { $q = TamSoru; & $bz.Value $q; Denetle "düşer: $($bz.Key)" (-not (KgkYayinSarti 'kgk-sinav/kp-01' $q $bos).gecer) }
# 02.10 (Cem "kgk açıklama hakemine bağla"): KGK şartı SmmmYayinSarti → SmmmKaliteNeden → AhSecilemez yoluyla AÇIKLAMA HAKEMİNİ
#   zaten taşıyor (02.10 gerçek soruyla ölçüldü: kgk-d1-tds-cokzor-1/kp-01). Bu vakalar o bağın sessizce kopmasını yakalar.
#   YENİ soru = kör/hakem2 tarihi >= 2026-10-01 (arac/aciklama-hakemi-uretim.ps1 AhYeniMi). Eski soru etkilenmez.
$ahYeni = { param($q, $karar) $q.kor_cozum | Add-Member -NotePropertyName tarih -NotePropertyValue '2026-10-02' -Force
  if ($karar) { $q | Add-Member -NotePropertyName aciklama_hakem -NotePropertyValue ([pscustomobject]@{ karar = $karar }) -Force } }
$q = TamSoru; & $ahYeni $q $null;     $r = KgkYayinSarti 'kgk-sinav/kp-01' $q $bos; Denetle "düşer: YENİ soru, açıklama hakemi kararı yok ($($r.neden))" ((-not $r.gecer) -and "$($r.neden)" -like 'AÇIKLAMA HAKEMİ*')
$q = TamSoru; & $ahYeni $q 'KUSURLU'; $r = KgkYayinSarti 'kgk-sinav/kp-01' $q $bos; Denetle "düşer: YENİ soru, açıklama hakemi KUSURLU ($($r.neden))" ((-not $r.gecer) -and "$($r.neden)" -like 'AÇIKLAMA HAKEMİ*')
$q = TamSoru; & $ahYeni $q 'TEMIZ';   $r = KgkYayinSarti 'kgk-sinav/kp-01' $q $bos; Denetle "açıklama hakemi TEMIZ olan YENİ soru hakem yüzünden düşmez ($($r.neden))" ("$($r.neden)" -notlike 'AÇIKLAMA HAKEMİ*')
$q = TamSoru;                          $r = KgkYayinSarti 'kgk-sinav/kp-01' $q $bos; Denetle 'ESKİ soru (tarihsiz) açıklama hakemi aranmadan geçer' ($r.gecer)
# eski mevzuat: dayandığı madde değişen soru (motor/soru-dayanak-nobetcisi.ps1 listesi) geçmez; soru yeniden yazılınca (iz değişir) geçer
$q = TamSoru; $script:MD_LISTE = @{ 'kgk-sinav/kp-01' = [pscustomobject]@{ anahtar = 'kgk-sinav/kp-01'; iz = (MdIcerikIzi $q); kaynak = 'ad|BDS 200'; tur = 'degisti'; tarih = '27.09.2026' } }
Denetle 'düşer: mevzuat değişti (eski standart metni)' (-not (KgkYayinSarti 'kgk-sinav/kp-01' $q $bos).gecer)
$q2 = TamSoru; $q2.soru = $q2.soru + ' (yeniden yazıldı)'
Denetle 'geçer: soru yeniden yazılınca mevzuat engeli kalkar' ((KgkYayinSarti 'kgk-sinav/kp-01' $q2 $bos).gecer)
$script:MD_LISTE = @{}
# onay dosyası: KGK yolu smmm onayını okumaz; kgk dışı anahtar yok sayılır
$geciciKok = Join-Path ([IO.Path]::GetTempPath()) ("kgk-onay-sinav-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force (Join-Path $geciciKok 'veri\sinav') | Out-Null
try {
  Denetle 'onay dosyası yoksa boş harita (kör istisnası KAPALI)' ((KgkOnayHarita $geciciKok).Count -eq 0)
  [IO.File]::WriteAllText((Join-Path $geciciKok 'veri\sinav\smmm-insan-onay.json'), '[{"anahtar":"kgk-x/kp-01","karar":"ONAY"}]', [Text.UTF8Encoding]::new($false))
  Denetle 'KGK onayı smmm-insan-onay.json''u OKUMAZ' ((KgkOnayHarita $geciciKok).Count -eq 0)
  [IO.File]::WriteAllText((Join-Path $geciciKok 'veri\sinav\kgk-insan-onay.json'), '[{"anahtar":"kgk-x/kp-01","karar":"ONAY"},{"anahtar":"smmm-y/kp-02","karar":"ONAY"}]', [Text.UTF8Encoding]::new($false))
  $oh = KgkOnayHarita $geciciKok
  Denetle 'kgk-insan-onay.json okunur, kgk dışı anahtar yok sayılır' ($oh.Count -eq 1 -and $oh.ContainsKey('kgk-x/kp-01'))
} finally { Remove-Item -Recurse -Force $geciciKok -ErrorAction SilentlyContinue }

# --- 5) KAPSAM: yerel KGK partilerinin (eski hat/pilot hariç) her sorusunun modülü çözülüyor mu ---
$fab = Join-Path (Split-Path -Parent $buDizin) 'veri\fabrika'
$korSoru = New-Object System.Collections.Generic.List[string]; $bakilanParti = 0; $bakilanSoru = 0
if (Test-Path $fab) {
  foreach ($dosya in @(Get-ChildItem $fab -Filter 'kalip-parti-kgk-*.json' -ErrorAction SilentlyContinue)) {
    $etk = $dosya.BaseName -replace '^kalip-parti-', ''
    if ($etk -match '(^|-)pilot\d*(-|$)' -or $etk -match $script:KGK_ESKI_HAT) { continue }
    $bakilanParti++
    $parti = Get-Content $dosya.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($oz in $parti.PSObject.Properties) {
      if (-not ($oz.Value -and $oz.Value.PSObject.Properties['soru'] -and $oz.Value.soru)) { continue }
      $bakilanSoru++
      if (-not (KgkDersAdi $etk $oz.Value)) { $korSoru.Add("$etk/$($oz.Name)") }
    }
  }
}
''
if ($bakilanParti) {
  "KAPSAM: yerel KGK partisi {0} · soru {1} (eski hat/pilot hariç) · modülü ÇÖZÜLEMEYEN {2}" -f $bakilanParti, $bakilanSoru, $korSoru.Count
  if ($korSoru.Count) { $kalan.Add("$($korSoru.Count) yerel KGK sorusunun modülü çözülemiyor (ilk: $(@($korSoru | Select-Object -First 3) -join ', ')) — arac/kgk-ders-adi.ps1'e satır ekle") }
} else { 'KAPSAM: yerel KGK parti dosyası YOK — kapsam ölçülmedi (KÖR)' }

''
"KGK DERS ADI + YAYIN ŞARTI ÖZ-SINAVI: {0}/{1} geçti" -f $gecen, $toplam
if ($kalan.Count) { foreach ($k in $kalan) { Write-Host "  KIRMIZI: $k" -ForegroundColor Red }; exit 1 }
Write-Host 'YESIL' -ForegroundColor Green
exit 0
