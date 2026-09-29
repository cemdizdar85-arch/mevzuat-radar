# KAPI-OM ÖZ-SINAVI (27.09.2026) — arac/ozel-maliyet-kapisi.ps1 OzelMaliyetKapisi
# Vakalar KISA, UYDURMA cümlelerdir (depo public; gerçek soru metni yok). Her vaka gerçek bir kasa bulgusunun kalıbını taşır.
# Ayrıca: (1) kapı dört yerde bağlı mı (FAZ A, FAZ GM, hazır soru denetimi, SMMM yayın şartı) — metin sayımı;
#         (2) MUTASYON: kapının kilit koşulları tek tek bozulur, her bozmada en az bir vaka DÜŞMELİ (CLAUDE.md kapı kuralı 8).
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
$kapiYol = Join-Path $buDizin 'ozel-maliyet-kapisi.ps1'
$kapiMetin = [IO.File]::ReadAllText($kapiYol, [Text.Encoding]::UTF8)

function Soru($alanlar) { $o = [pscustomobject]@{ soru = 'İşletme kiraladığı binaya özel maliyet harcaması yapmıştır. Buna göre itfa payı kaç TL''dir?'; siklar = [pscustomobject]@{ A = '10.000'; B = '12.000' }; dogru = 'A' }; foreach ($k in $alanlar.Keys) { $o | Add-Member -NotePropertyName $k -NotePropertyValue $alanlar[$k] -Force }; return $o }

$VAKALAR = @(
  # --- YAKALANMALI (kusur) ---
  @{ ad = 'hap: kira süresi beş yıldan uzunsa beş yılda'; bek = $true; s = (Soru @{ hap = 'Özel maliyetler kira süresinde, kira süresi beş yıldan uzunsa beş yılda eşit tutarlarla itfa edilir.' }) }
  @{ ad = 'teşhis iç içe: 5 yıldan fazla → 5 yılla sınırlanır'; bek = $true; s = (Soru @{ teshis = [pscustomobject]@{ A = [pscustomobject]@{ gercek = 'Kira süresi 5 yıldan fazla olduğundan itfa süresi 5 yılla sınırlanır.' } } }) }
  @{ ad = 'taktik: kira süresi mi beş yıl sınırı mı'; bek = $true; s = (Soru @{ sinav_taktigi = 'Önce özel maliyetin itfa süresini (kira süresi mi, beş yıl sınırı mı) belirle, sonra böl.' }) }
  @{ ad = 'dizi içinde: kira süresi ya da en çok beş yıl'; bek = $true; s = (Soru @{ konu_giris = [pscustomobject]@{ terimler = @([pscustomobject]@{ ad = 'süre'; tanim = 'İtfa süresi, kira süresi ya da en çok beş yıldır.' }) } }) }
  @{ ad = 'kira süresi veya beş yılda'; bek = $true; s = (Soru @{ konu_giris = [pscustomobject]@{ terimler = @([pscustomobject]@{ tanim = 'özel maliyetin kira süresi veya beş yılda eşit paylarla giderleştirilmesi' }) } }) }
  @{ ad = 'kanuni 5 yıl sınırı (açıklama şıkkı)'; bek = $true; s = (Soru @{ aciklama = [pscustomobject]@{ B = 'Kanuni 5 yıl sınırı nedeniyle 264 hesabı beş yılda itfa edilir.' } }) }
  @{ ad = 'cümle başında büyük İ (Linux İ/i)'; bek = $true; s = (Soru @{ adimlar = @([pscustomobject]@{ anlatim = 'İtfa süresi beş yıldan uzun kirada beş yıldır.' }) }) }
  @{ ad = 'kök: beş yıldan uzun olduğundan beş yılda itfa'; bek = $true; s = [pscustomobject]@{ soru = 'Kira süresi beş yıldan uzun olduğundan özel maliyet bedeli beş yılda eşit tutarlarla itfa edilmektedir. Buna göre 2026 itfa payı kaç TL''dir?'; siklar = [pscustomobject]@{ A = '1'; B = '2' }; dogru = 'A' } }
  # --- YAKALANMAMALI (yanlış alarm olmaz) ---
  @{ ad = 'güncel kural: beş yıl sınırı yoktur'; bek = $false; s = (Soru @{ hap = 'Özel maliyet VUK m.327''ye göre kira süresine göre itfa edilir; beş yıldan uzun kirada da beş yıl sınırı yoktur.' }) }
  @{ ad = 'kira tam 5 yıl (kural değil veri)'; bek = $false; s = (Soru @{ aciklama = [pscustomobject]@{ A = 'Kira süresi 5 yıl olup özel maliyet bu sürede eşit tutarlarla itfa edilmektedir.' } }) }
  @{ ad = 'TBK: beş yıldan uzun süreli kira sözleşmesi (itfa yok)'; bek = $false; s = (Soru @{ hap = 'Beş yıldan uzun süreli kira sözleşmelerinde kira bedeli hâkimce belirlenir.' }) }
  @{ ad = '263 AR-GE kendi 5 yılı, özel maliyet yok'; bek = $false; s = [pscustomobject]@{ soru = 'Aktifleştirilen araştırma gideri için itfa payı kaç TL''dir?'; siklar = [pscustomobject]@{ A = '1'; B = '2' }; dogru = 'A'; hap = '263 hesap 5 yıl içinde eşit taksitlerle itfa edilir.' } }
  @{ ad = '260 haklar: beş yılı aşmamak üzere itfa (özel maliyet yok)'; bek = $false; s = [pscustomobject]@{ soru = 'Satın alınan imtiyaz hakkı için ayrılacak itfa payı kaç TL''dir?'; siklar = [pscustomobject]@{ A = '1'; B = '2' }; dogru = 'A'; hap = 'Süresi belirsiz haklar beş yılı aşmamak üzere eşit tutarlarla itfa edilir.' } }
  @{ ad = 'iç alan: kaynak özeti eski kuralı alıntılıyor'; bek = $false; s = (Soru @{ kaynak_metin_ozet = 'THP 264: kira süresi beş yıldan fazla ise beş yılda eşit tutarlarla amorti edilir.'; hakem = [pscustomobject]@{ gerekce = 'kira süresi 5 yıldan uzunsa 5 yılda itfa' } }) }
  @{ ad = 'reddeden cümle: 2005''ten beri uygulanmaz'; bek = $false; s = (Soru @{ hap = 'THP 264''teki beş yıldan fazla kirada beş yılda itfa ifadesi 2005''ten beri vergide uygulanmaz.' }) }
  @{ ad = 'teori notu: beş yıldan uzunsa dahi kira süresinde'; bek = $false; s = (Soru @{ hap = 'Özel maliyetler kira süresinde, kira süresi beş yıldan uzunsa dahi kira süresinde eşit tutarlarla itfa edilir.' }) }
  @{ ad = 'beş yılda değil kira süresinde'; bek = $false; s = (Soru @{ aciklama = [pscustomobject]@{ C = 'Özel maliyeti 5 yılda değil kira süresi olan 7 yılda itfa et.' } }) }
)

function VakaKos([string]$kapiKaynak) {
  # kapıyı temiz bir kapsamda yükler, her vakanın sonucunu döndürür (true = beklenen)
  $sb = [scriptblock]::Create("param(`$vakalar)`n" + $kapiKaynak + "`n" + @'
foreach ($v in $vakalar) { $sonuc = @(OzelMaliyetKapisi $v.s).Count -gt 0; [pscustomobject]@{ ad = $v.ad; bek = $v.bek; bulundu = $sonuc; tamam = ($sonuc -eq $v.bek) } }
'@)
  return @(& $sb $VAKALAR)
}

$kirmizi = 0
foreach ($r in (VakaKos $kapiMetin)) {
  if ($r.tamam) { "  YEŞİL  $($r.ad)" } else { $kirmizi++; Write-Host "  KIRMIZI $($r.ad) (beklenen $(if ($r.bek) { 'YAKALA' } else { 'GEÇ' }), sonuç $(if ($r.bulundu) { 'YAKALADI' } else { 'GEÇTİ' }))" -ForegroundColor Red }
}

# (1) bağlantı: kapı dört yerde çağrılıyor mu
$baglar = @(
  @{ dosya = 'motor\kalip-parti-uret.ps1'; desen = 'OzelMaliyetKapisi\s+\$aday'; ad = 'FAZ A (model yazımı)' }
  @{ dosya = 'motor\kalip-parti-uret.ps1'; desen = 'OzelMaliyetKapisi\s+\$e\b'; ad = 'FAZ GM (hazır soru)' }
  @{ dosya = 'arac\hazir-soru-denetle.ps1'; desen = 'OzelMaliyetKapisi'; ad = 'hazır soru ön denetimi' }
  @{ dosya = 'arac\smmm-yayin-sarti.ps1'; desen = 'OzelMaliyetKapisi'; ad = 'SMMM yayın şartı' }
)
foreach ($b in $baglar) {
  $yol = Join-Path $depoKok ($b.dosya -replace '\\', [IO.Path]::DirectorySeparatorChar)
  $say = ([regex]::Matches([IO.File]::ReadAllText($yol, [Text.Encoding]::UTF8), $b.desen)).Count
  if ($say -lt 1) { $kirmizi++; Write-Host "  KIRMIZI kapı bağlı değil: $($b.ad) ($($b.dosya))" -ForegroundColor Red } else { "  YEŞİL  kapı bağlı: $($b.ad)" }
}

# (2) mutasyon: her bozma en az bir vakayı düşürmeli
$MUTASYONLAR = @(
  @{ ad = 'eski kural deseni hiçbir şey tutmaz'; eski = '$script:OM_ESKI_KURAL = '''; yeni = '$script:OM_ESKI_KURAL = ''(?!)''; $null = ''' }
  @{ ad = 'ret sözcükleri her cümleyi reddeder'; eski = '$script:OM_RED = '''; yeni = '$script:OM_RED = ''.|' }
  @{ ad = 'cümle bağlamı kontrolü kapalı'; eski = 'if ($cumle -notmatch $script:OM_CUMLE_BAGLAM) { continue }'; yeni = 'if ($false) { continue }' }
  @{ ad = 'iç alan listesi boş'; eski = '$script:OM_IC_ALAN = @('; yeni = '$script:OM_IC_ALAN = @(); $null = @(' }
  @{ ad = 'metin bağlamı (özel maliyet/264) kontrolü kapalı'; eski = 'if ($tum -notmatch $script:OM_BAGLAM) { return $out }'; yeni = 'if ($false) { return $out }' }
)
foreach ($m in $MUTASYONLAR) {
  if (-not $kapiMetin.Contains($m.eski)) { $kirmizi++; Write-Host "  KIRMIZI mutasyon kurulamadı (kapı metni değişmiş): $($m.ad)" -ForegroundColor Red; continue }
  $dusen = @((VakaKos ($kapiMetin.Replace($m.eski, $m.yeni))) | Where-Object { -not $_.tamam }).Count
  if ($dusen -lt 1) { $kirmizi++; Write-Host "  KIRMIZI mutasyon sınavı düşürmedi: $($m.ad)" -ForegroundColor Red } else { "  YEŞİL  mutasyon '$($m.ad)' → $dusen vaka düştü" }
}

$toplam = $VAKALAR.Count + $baglar.Count + $MUTASYONLAR.Count
if ($kirmizi) { Write-Host "KAPI-OM ÖZ-SINAVI KIRMIZI ($kirmizi / $toplam)" -ForegroundColor Red; exit 1 }
"KAPI-OM ÖZ-SINAVI YEŞİL ($toplam vaka: $($VAKALAR.Count) cümle · $($baglar.Count) bağlantı · $($MUTASYONLAR.Count) mutasyon)"
