#requires -Version 5.1
<#
================================================================================
  SORU MADDEYE DEĞİYOR MU — ÖZ-SINAV   (23.09.2026) · bedel 0

  NİYE VAR: soru-dayanak nöbetçisi artık, paketinde değişen madde bulunan ama değişen kısma DEĞMEYEN soruyu
  çekmiyor (arac/mevzuat-degisti.ps1 MdAyirtEdici / MdSoruDegiyor). Kural yanlış kurulursa GERÇEK bir değişiklik
  (oran, süre, iptal edilen hüküm) sessizce yayında kalır — bu en pahalı hata. Sınav iki yönü de ölçer:
  YAKALAMALI (oran %18→%20, "on yıl"→"beş yıl", iptal edilen cümle, söz dizimi değişikliği → belirsiz = hepsini çek)
  ÇEKMEMELİ (ilgisiz konu, yalnız şerh/dipnot dili, metin aynı).
  Gerçek veri ölçümü (TTK geç. m.7, 23.09): 93 sorudan 14'ü işaretlendi, elle bulunan 2 gerçek etkilenenin 2'si yakalandı.
  ⛔ REPLİKA YOK: gerçek arac/mevzuat-degisti.ps1 dot-source edilir. MdAnahtar'ın madde-damga ile AYNI düzenli
     ifadeleri kullandığı ayrıca metin olarak denetlenir (ayrışırsa belirteçler yanlış maddeye yazılır).
================================================================================
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
. (Join-Path $buDizin 'mevzuat-degisti.ps1')
$gecti = 0; $dustu = New-Object System.Collections.Generic.List[string]
function T([string]$ad, [bool]$k) { if ($k) { $script:gecti++; if (-not $Sessiz) { Write-Host "  geçti $ad" } } else { $script:dustu.Add($ad) } }
function S([string]$soru, [string]$dogruSik = '', [string]$aciklama = '') { [pscustomobject]@{ soru = $soru; siklar = [pscustomobject]@{ A = $dogruSik; B = 'diğer'; C = 'başka'; D = 'yok'; E = 'hiçbiri' }; aciklama = $aciklama } }
function Degiyor($soru, $eski, $yeni) { $a = MdAyirtEdici $eski $yeni; if ($null -eq $a) { return 'BELIRSIZ' }; if (@(MdSoruDegiyor $soru $a).Count) { return 'DEGIYOR' } else { return 'DEGMIYOR' } }

# --- metin aynı / belirsiz
$ayniR = MdAyirtEdici 'Vergi oranı yüzde onsekizdir.' 'Vergi   oranı yüzde onsekizdir.'   # değişkene alınır (çağıranlar da böyle kullanır)
T 'metin aynı → boş liste (belirsiz DEĞİL)' (-not ($null -eq $ayniR) -and $ayniR.Count -eq 0)
T 'yalnız söz dizimi değişti → BELİRSİZ (nöbetçi hepsini çeker)' ($null -eq (MdAyirtEdici 'alacaklı borçluya bildirir' 'borçlu alacaklıya bildirir'))
# --- YAKALAMALI
$e = 'Katma değer vergisi oranı %18 olarak uygulanır ve beyanname ayın yirmisine kadar verilir.'; $y = 'Katma değer vergisi oranı %20 olarak uygulanır ve beyanname ayın yirmisine kadar verilir.'
T 'oran %18→%20: oranı soran soru DEĞİYOR' ((Degiyor (S 'KDV genel oranı kaçtır?' '%18') $e $y) -eq 'DEGIYOR')
T 'oran %18→%20: beyan süresini soran soru DEĞMİYOR' ((Degiyor (S 'Beyanname hangi güne kadar verilir?' 'ayın yirmisine kadar') $e $y) -eq 'DEGMIYOR')
$e = 'Alacak on yıllık zamanaşımına tabidir.'; $y = 'Alacak beş yıllık zamanaşımına tabidir.'
T 'süre "on yıl"→"beş yıl": süreyi soran soru DEĞİYOR (sayı sözcüğü belirteç)' ((Degiyor (S 'Alacak kaç yıllık zamanaşımına tabidir?' 'on yıl') $e $y) -eq 'DEGIYOR')
$e = 'Unvanı silinen şirketin malvarlığı on yıl sonra Hazineye intikal eder. Hazine bu şirketlerin borçlarından sorumlu tutulmaz. Tasfiye memurları sorumludur.'
$y = 'Unvanı silinen şirketin (…) (İptal ikinci ve üçüncü cümle: Anayasa Mahkemesinin 10/9/2025 tarihli kararı ile.) Tasfiye memurları sorumludur.'
T 'TTK geç. m.7 iptali: "Hazine borçlardan sorumlu tutulmaz" diyen soru DEĞİYOR' ((Degiyor (S 'Silinen şirketin borçlarından kim sorumlu tutulmaz?' 'Hazine sorumlu tutulmaz') $e $y) -eq 'DEGIYOR')
T 'TTK geç. m.7 iptali: "on yıl sonra intikal" soran soru DEĞİYOR' ((Degiyor (S 'Malvarlığı kaç yıl sonra Hazineye geçer?' 'on yıl') $e $y) -eq 'DEGIYOR')
# --- ÇEKMEMELİ
T 'TTK geç. m.7 iptali: ilgisiz acente sorusu DEĞMİYOR (23.09 mıknatıs vakası)' ((Degiyor (S 'Acente hangi durumda ücrete hak kazanır?' 'aracılık ettiği işlem kurulunca') $e $y) -eq 'DEGMIYOR')
# BİLİNEN KÖRLÜK (temkinli yön): 5 harflik kök 'borçlu' ile 'borçlarından'ı ayırmaz → FAZLA çeker, KAÇIRMAZ.
T 'kök çakışması borçlu↔borçlarından: DEĞİYOR sayılır (fazla çekme, belgelenmiş)' ((Degiyor (S 'Müteselsil borçlulukta alacaklı ifayı kimden isteyebilir?' 'borçlulardan herhangi birinden') $e $y) -eq 'DEGIYOR')
T 'yalnız şerh eklendi (iptal notu) → BELİRSİZ, hepsi çekilir (iptal şerhi gerçek değişikliğin habercisi olabilir)' ((Degiyor (S 'Herhangi bir soru?' 'x') 'Metin burada durur.' 'Metin burada durur. (İptal: Anayasa Mahkemesinin kararı ile.)') -eq 'BELIRSIZ')
T 'şerh sözcükleri belirteç sayılmaz (iptal/anayasa/karar)' (-not (MdBelirtecler 'iptal anayasa mahkemesi karar resmî gazete yürürlüğe girer').ContainsKey('iptal'))
# --- MdAnahtar ↔ madde-damga paritesi
$md = [IO.File]::ReadAllText((Join-Path $kok 'motor\madde-damga.ps1'), [Text.Encoding]::UTF8)
T 'MdAnahtar ile madde-damga aynı kanun/madde ifadelerini kullanıyor' ($md.Contains("'(?<![\d/])(\d{3,4})\s*(?:s\.|say[ıi]l[ıi])'") -and $md.Contains("'[^a-zA-Z0-9]m\.\s*(\d{1,4})(?!\d)'"))
T 'MdAnahtar örnekleri' ((MdAnahtar 'TTK (6102 s.K.) gec. m.7 [3/7]') -eq '6102|gec7' -and (MdAnahtar 'VUK (213 s.K.) m.370 - İzaha davet') -eq '213|370' -and (MdAnahtar 'GVK (193 s.K.) muk. m.121 [2/4]') -eq '193|121')
# --- nöbetçi kuralı yerinde mi (belirsiz / taban tarihi / SILINDI hariç)
$nb = [IO.File]::ReadAllText((Join-Path $kok 'motor\soru-dayanak-nobetcisi.ps1'), [Text.Encoding]::UTF8)
T 'nöbetçi: yalnız degisti + belirsiz değil + taban sonrası kayıtla atlar' ($nb.Contains("-eq 'degisti' -and `$dkE -and -not `$dkE.belirsiz -and") -and $nb.Contains('-ge $tabanTarihIso'))
# --- 24.09 TEORİ NOTU İZLEME (MdKaynakKoku / MdIzlenenAnahtar / MdDegisenKokEkle) — gerçek vaka: kollektif notu (TBK 623)
T 'kaynak kökü: kanun maddesi aynen (MdMaddeKoku)' ((MdKaynakKoku 'VUK (213 s.K.) m.370 [1/3]') -eq 'VUK (213 s.K.) m.370')
T 'kaynak kökü: teori notu TEORI:<ad>, parça eki atılır' ((MdKaynakKoku 'TEORI - Kollektif sirkette kar dagitimi [1/2]') -eq 'TEORI:TEORI - Kollektif sirkette kar dagitimi')
T 'kaynak kökü: madde numarasız standart/tebliğ adı → boş (izlenmez)' ((MdKaynakKoku 'BDS 570 İşletmenin Sürekliliği') -eq '')
T 'izlenen anahtar: kanun + teori evet, standart hayır' ((MdIzlenenAnahtar '6102|227') -and (MdIzlenenAnahtar 'ad|TEORI - Kollektif sirkette kar dagitimi') -and -not (MdIzlenenAnahtar 'ad|BDS 570'))
$ke = 'KAR-ZARAR DAGITIMI: Sozlesmede hukum yoksa kar ve zarar ortaklar arasinda SERMAYE PAYLARI ORANINDA paylasilir. SORUMLULUK: ortaklar sirket borclarindan MUTESELSILEN sorumludur.'
$ky = 'KAR-ZARAR DAGITIMI: Sozlesmede hukum yoksa her ortagin kar ve zarardaki payi ESITTIR (TBK m.623/1). SORUMLULUK: ortaklar sirket borclarindan MUTESELSILEN sorumludur.'
T 'teori: hüküm-yoksa kuralını soran soru DEĞER' ((Degiyor (S 'Kollektif sirkette sozlesmede hukum yoksa kar nasil paylasilir?' 'Sermaye paylari oraninda') $ke $ky) -eq 'DEGIYOR')
T 'teori: yalnız müteselsil sorumluluğu soran soru DEĞMEZ (çekilmez)' ((Degiyor (S 'Kollektif sirket ortaklarinin sirket borclarindan sorumlulugu nasildir?' 'Muteselsilen sorumludurlar') $ke $ky) -eq 'DEGMIYOR')
$dkT = Join-Path ([IO.Path]::GetTempPath()) ("dk-sinav-{0}.json" -f [guid]::NewGuid().ToString('N'))
$r1 = MdDegisenKokEkle $dkT 'ad|TEORI - X' 'ayni metin' 'ayni   metin' 'sinav'
$r2 = MdDegisenKokEkle $dkT 'ad|TEORI - X' $ke $ky 'sinav'
$r3 = MdDegisenKokEkle $dkT 'ad|TEORI - X' 'oran %18 uygulanir' 'oran %20 uygulanir' 'sinav'
$kayit = (Get-Content $dkT -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler.'ad|TEORI - X'
T 'belirteç kaydı: aynı metin yazılmaz, fark yazılır, ikinci değişiklik BİRLEŞİR' ($r1 -eq 'ayni' -and $r2 -eq 'yazildi' -and $r3 -eq 'yazildi' -and (@($kayit.belirtecler) -contains '#%20') -and (@($kayit.belirtecler) -contains 'serma') -and -not $kayit.belirsiz)
if (Test-Path $dkT) { [IO.File]::Delete($dkT) }
T 'nöbetçi: teori anahtarları izleniyor ve soru tarafı MdKaynakKoku ile eşleniyor' ($nb.Contains('Where-Object { MdIzlenenAnahtar $_ }') -and $nb.Contains('$mk = MdKaynakKoku "$ka"') -and $nb.Contains('$mk = MdKaynakKoku "$($kay.ad)"'))
$top = $gecti + $dustu.Count
Write-Host "SORU ETKİ ÖZ-SINAVI: $gecti/$top geçti"
if ($dustu.Count) { $dustu | ForEach-Object { Write-Host "  ✗ $_" }; exit 1 }
exit 0
