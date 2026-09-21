# ============================================================================
#  CI KIRMIZI NOBETCISI - OZ-SINAV
#
#  NEDEN VAR (21.09.2026): nobetci "ust uste N kirmizi" olcusuyle calisiyordu
#  ve bu olcu ILK YESILDE duruyor. kaynak.yml'in son 10 kosusu
#  "F S F S F S F S F S" idi - sabah kosusu 5 gun ust uste dustu, aksam
#  kosusu hep yesildi, seri HEP 1'de kaldi, nobetci arizayi HIC gormedi.
#  O bosluktan 4 gunluk hasat kayboldu. Ikinci olcu (oran) eklendi.
#  Bu sinav iki olcunun de dogru calistigini ve YANLIS ALARM uretmedigini
#  olcer. Mantik nobetciden BIREBIR kopyadir; nobetci degisirse bu da degisir.
# ============================================================================

$UstUste     = 2
$OranPencere = 10
$OranEsik    = 3

function KirmiziMi($c){ return ($c -eq 'failure' -or $c -eq 'timed_out') }

# Nobetcideki karar mantiginin birebir ayni hali
function AlarmVerir([string[]]$kosular) {
  $seri = 0
  foreach ($c in $kosular) { if (KirmiziMi $c) { $seri++ } else { break } }
  $pencere = @($kosular | Select-Object -First $OranPencere)
  $oranKirmizi = @($pencere | Where-Object { KirmiziMi $_ }).Count
  $oranGecerli = ($pencere.Count -ge $OranPencere) -and ($oranKirmizi -ge $OranEsik)
  if ($seri -ge $UstUste) { return 'ust_uste' }
  if ($oranGecerli)       { return 'oran' }
  return 'sessiz'
}

$F = 'failure'; $S = 'success'; $T = 'timed_out'

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
    @($S,$F,$F,$S,$F,$F,$S,$F,$S,$S), 'oran')
)

$gecen = 0; $kalan = 0
Write-Host "== CI KIRMIZI NOBETCISI OZ-SINAVI =="
Write-Host ("   olculer: ust uste >= {0}  |  oran >= {1}/{2}" -f $UstUste, $OranEsik, $OranPencere)
Write-Host ""
foreach ($v in $vakalar) {
  $cikan = AlarmVerir $v[1]
  $ok = ($cikan -eq $v[2])
  if ($ok) { $gecen++ } else { $kalan++ }
  $isaret = if ($ok) { 'GECTI' } else { 'KALDI' }
  Write-Host ("  [{0}] {1}" -f $isaret, $v[0])
  if (-not $ok) { Write-Host ("          beklenen='{0}' cikan='{1}'" -f $v[2], $cikan) }
}
Write-Host ""
Write-Host ("SONUC: {0} gecti / {1} kaldi (toplam {2})" -f $gecen, $kalan, $vakalar.Count)
if ($kalan -gt 0) { exit 1 } else { exit 0 }
