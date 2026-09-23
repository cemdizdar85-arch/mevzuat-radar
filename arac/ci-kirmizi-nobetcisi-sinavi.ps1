# ============================================================================
#  CI KIRMIZI NOBETCISI - OZ-SINAV
#
#  NEDEN VAR (21.09.2026): nobetci "ust uste N kirmizi" olcusuyle calisiyordu
#  ve bu olcu ILK YESILDE duruyor. kaynak.yml'in son 10 kosusu
#  "F S F S F S F S F S" idi - sabah kosusu 5 gun ust uste dustu, aksam
#  kosusu hep yesildi, seri HEP 1'de kaldi, nobetci arizayi HIC gormedi.
#  O bosluktan 4 gunluk hasat kayboldu. Ikinci olcu (oran) eklendi.
#
#  23.09.2026: ikinci korluk. 'cancelled' ve 'skipped' kosular "kirmizi degil"
#  sayiliyordu; yayin-bas.yml 5 gun (38 dusus, arada 26 iptal + 26 atlandi)
#  gorulmedi. Artik karar vermeyen kosu elenir (G vakalari).
#
#  REPLIKA YOK (23.09): karar mantigi nobetcinin KENDI dosyasindan AST ile
#  cikarilip kosulur (KararVerir + AlarmOlcusu). Nobetci degisirse sinav
#  otomatik olarak yenisini olcer; kopya eskiyemez.
# ============================================================================

$UstUste     = 2
$OranPencere = 10
$OranEsik    = 3

$nobetciYol = Join-Path $PSScriptRoot 'ci-kirmizi-nobetcisi.ps1'
$tok = $null; $hata = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($nobetciYol, [ref]$tok, [ref]$hata)
if ($hata.Count) { Write-Host "NOBETCI AYRISTIRILAMADI: $($hata[0].Message)"; exit 1 }
foreach ($ad in @('KararVerir', 'AlarmOlcusu')) {
  $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $ad }, $true) | Select-Object -First 1
  if (-not $fn) { Write-Host "NOBETCIDE '$ad' fonksiyonu YOK - sinav kosamaz"; exit 1 }
  . ([scriptblock]::Create($fn.Extent.Text))
}

function AlarmVerir([string[]]$kosular) { return (AlarmOlcusu $kosular $UstUste $OranPencere $OranEsik).tur }

$F = 'failure'; $S = 'success'; $T = 'timed_out'; $C = 'cancelled'; $K = 'skipped'
function Tekrar($x, [int]$n) { return @(1..$n | ForEach-Object { $x }) }

# vaka = @(ad, kosu dizisi (yeniden eskiye), beklenen)
$vakalar = @(
  @('A1 GERCEK VAKA kaynak.yml: donusumlu sabah-kirmizi',
    @($F,$S,$F,$S,$F,$S,$F,$S,$F,$S), 'oran'),
  @('A2 donusumlu ama pencere DOLMAMIS (yeni workflow) -> yanlis alarm YOK',
    @($F,$S,$F), 'sessiz'),
  @('B1 klasik kalici kirmizi (ust uste 2)',
    @($F,$F,$S,$S,$S,$S,$S,$S,$S,$S), 'ust_uste'),
  @('B2 timed_out da kirmizi sayilir',
    @($T,$T,$S,$S,$S,$S,$S,$S,$S,$S), 'ust_uste'),
  @('C1 TEK seferlik gecici ariza -> SESSIZ (yanlis alarm olmasin)',
    @($F,$S,$S,$S,$S,$S,$S,$S,$S,$S), 'sessiz'),
  @('C2 iki dagitik ariza (2/10) -> esik alti, SESSIZ',
    @($F,$S,$S,$S,$F,$S,$S,$S,$S,$S), 'sessiz'),
  @('C3 tam esikte (3/10) -> ALARM',
    @($F,$S,$S,$F,$S,$S,$F,$S,$S,$S), 'oran'),
  @('D1 hepsi yesil -> SESSIZ',
    @($S,$S,$S,$S,$S,$S,$S,$S,$S,$S), 'sessiz'),
  @('D2 hepsi kirmizi -> ust_uste (oran degil; en siddetli olcu kazanir)',
    @($F,$F,$F,$F,$F,$F,$F,$F,$F,$F), 'ust_uste'),
  @('E1 son kosu YESIL ama gecmis cogunlukla kirmizi -> oran yakalar',
    @($S,$F,$F,$S,$F,$F,$S,$F,$S,$S), 'oran'),
  @('G1 GERCEK VAKA yayin-bas.yml 23.09: son 12 kosu atlandi, oncesi dusus+iptal -> ALARM',
    @((Tekrar $K 12) + @($F,$C,$C,$F,$C,$F,$F,$C,$F,$S)), 'ust_uste'),
  @('G2 dususlerin arasina iptal girer (F C F C F) -> seri 3, ALARM',
    @($F,$C,$F,$C,$F,$S,$S,$S,$S,$S,$S,$S), 'ust_uste'),
  @('G3 iptaller arasinda TEK dusus -> SESSIZ (yanlis alarm olmasin)',
    @($C,$F,$C,$S,$C,$S,$S,$S,$S,$S,$S,$S,$S), 'sessiz'),
  @('G4 yalniz iptal/atlandi (karar yok) -> SESSIZ (bilinen korluk, basta yazili)',
    @($C,$K,$C,$K,$C,$K,$C,$K,$C,$K), 'sessiz'),
  @('G5 atlananlar pencereyi SULANDIRMAZ: 3/10 karar veren kirmizi -> oran',
    @($K,$K,$K,$F,$S,$K,$S,$F,$S,$S,$K,$F,$S,$S,$S), 'oran'),
  @('G6 atlanan cok ama karar veren az (pencere dolmamis) -> SESSIZ',
    @($K,$F,$K,$S,$K,$F,$K,$S), 'sessiz')
)

# 23.09: ZAMANLI vakalar - vaka = @(ad, kosu dizisi, yas dizisi (gun, ayni sira), beklenen). Pencere 14 gun.
$zamanli = @(
  @('H1 GERCEK VAKA karne.yml: son kosu YESIL (1 gun), eski dususler 20-60 gun once -> SESSIZ (eskiden oran)',
    @($S,$F,$F,$F,$S,$F,$S,$F,$S,$F), @(1,20,25,30,35,40,45,50,55,60), 'sessiz'),
  @('H2 GERCEK VAKA 12.09 toplu 500: son 4 kosu kirmizi, en yenisi 15 gun once -> UYUYAN (alarm degil, gizli de degil)',
    @($F,$F,$F,$F,$S), @(15,27,33,40,48), 'uyuyan'),
  @('H3 taze kalici kirmizi (0,5 ve 1 gun) -> ust_uste (uyuyan DEGIL)',
    @($F,$F,$S), @(0.5,1,2), 'ust_uste'),
  @('H4 donusumlu ariza pencere icinde (5 gunde 10 kosu) -> oran (zaman suzgeci A1i bozmaz)',
    @($F,$S,$F,$S,$F,$S,$F,$S,$F,$S), @(0.2,0.7,1.2,1.7,2.2,2.7,3.2,3.7,4.2,4.7), 'oran'),
  @('H5 sinir: en yeni kirmizi 13 gun once, oncesi 20 -> ust_uste (pencere icinde)',
    @($F,$F), @(13,20), 'ust_uste'),
  @('H6 sinir: en yeni kirmizi 15 gun once -> uyuyan',
    @($F,$F), @(15,16), 'uyuyan'),
  @('H7 atlanan kosu en yeni ama karar veren kirmizilar eski -> uyuyan (yas karar verenden alinir)',
    @($K,$K,$F,$F), @(1,2,20,21), 'uyuyan')
)

$gecen = 0; $kalan = 0
Write-Host "== CI KIRMIZI NOBETCISI OZ-SINAVI (gercek fonksiyon: $nobetciYol) =="
Write-Host ("   olculer: ust uste >= {0}  |  oran >= {1}/{2}  |  iptal/atlandi elenir" -f $UstUste, $OranEsik, $OranPencere)
Write-Host ""
foreach ($v in $vakalar) {
  $cikan = AlarmVerir $v[1]
  $ok = ($cikan -eq $v[2])
  if ($ok) { $gecen++ } else { $kalan++ }
  $isaret = if ($ok) { 'GECTI' } else { 'KALDI' }
  Write-Host ("  [{0}] {1}" -f $isaret, $v[0])
  if (-not $ok) { Write-Host ("          beklenen='{0}' cikan='{1}'" -f $v[2], $cikan) }
}
foreach ($v in $zamanli) {
  $cikan = (AlarmOlcusu $v[1] $UstUste $OranPencere $OranEsik ([double[]]$v[2]) 14).tur
  $ok = ($cikan -eq $v[3])
  if ($ok) { $gecen++ } else { $kalan++ }
  $isaret = if ($ok) { 'GECTI' } else { 'KALDI' }
  Write-Host ("  [{0}] {1}" -f $isaret, $v[0])
  if (-not $ok) { Write-Host ("          beklenen='{0}' cikan='{1}'" -f $v[3], $cikan) }
}
Write-Host ""
Write-Host ("SONUC: {0} gecti / {1} kaldi (toplam {2})" -f $gecen, $kalan, ($vakalar.Count + $zamanli.Count))
if ($kalan -gt 0) { exit 1 } else { exit 0 }
