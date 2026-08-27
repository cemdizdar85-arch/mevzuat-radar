# ============================================================================
#  YAYIN HAVUZU OLCUMU (13.08.2026) — 0 USD
#  CEM: "acilista en kotu 20 bin soru acmak istiyorum, bir olc."
#  SORU: kasadaki 30.569 sorunun kaci BEDAVA kapilarin HEPSINDEN temiz gecer?
#  (Simdiye kadar yayin filtresi yalniz K1-K10 idi; K11-K17 bulgulari
#   filtreye HIC baglanmamisti - pilotta cikan kusurlarin cogu bu yuzden sizdi.)
#  Bu betik TUM kapi raporlarini okur, id bazinda KARA LISTE cikarir ve
#  "hepsinden temiz" havuzun buyuklugunu olcer. YAZMA YOK.
#  Cikti: veri/yayin-havuzu-olcum.json
# ============================================================================
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$V = Join-Path $kok 'veri'
function Oku([string]$ad){ $y = Join-Path $V $ad; if(Test-Path $y){ return (Get-Content $y -Raw -Encoding UTF8 | ConvertFrom-Json) }; return $null }
function Ekle($set,[string]$id,[string]$sebep,$sayac){ if([string]::IsNullOrWhiteSpace($id)){ return }; if(-not $set.ContainsKey($id)){ $set[$id]=$sebep; $sayac[$sebep] = 1 + [int]$sayac[$sebep] } }

$kara = @{}; $sebepSayac = @{}
# --- K11 coklu dogru sik
$k11 = Oku 'k11-coklu-dogru-sik.json'
if($k11){ foreach($x in @($k11.riskli + $k11.bulgular + $k11.supheli)){ if($x){ Ekle $kara "$($x.id)" 'K11-coklu-dogru' $sebepSayac } } }
# --- K13 aritmetik
$k13 = Oku 'aritmetik-kapisi-raporu.json'
if($k13){
  # TAM id listesi varsa onu kullan (13.08 duzeltmesi); yoksa kirpili ornek listesine dus
  if($k13.bulgu_idler){ foreach($id in @($k13.bulgu_idler)){ Ekle $kara "$id" 'K13-aritmetik' $sebepSayac } }
  else { foreach($x in @($k13.bulgular)){ if($x){ Ekle $kara "$($x.id)" 'K13-aritmetik-ornek' $sebepSayac } } }
  foreach($alan in 'dengesizler','kaliplilar'){ foreach($x in @($k13.$alan)){ if($x){ Ekle $kara "$($x.id)" "K13-$alan" $sebepSayac } } }
}
# --- K16 tablo (TAM id listesi; yoksa ornek listesine duser)
$k16 = Oku 'k16-tablo-denetimi.json'
if($k16){
  foreach($alan in 'V2_yapi_bozuk','V4_tabloda_uydurma_rakam'){
    $kaynak = if($k16.$alan.idler){ @($k16.$alan.idler) } else { @($k16.$alan.ornek | ForEach-Object { $_.id }) }
    foreach($id in $kaynak){ Ekle $kara "$id" "K16-$alan" $sebepSayac }
  }
}
# --- K17 yazim kusuru (ipucu veren aileler: F1 mutlak, F2 hepsi, F3 uzunluk, F5 kelime)
$k17 = Oku 'k17-madde-yazim.json'
if($k17){
  foreach($alan in 'F1_mutlak_terim','F2_hepsi_hicbiri','F3_uzunluk_ipucu','F5_kelime_tekrari'){
    $kaynak = if($k17.$alan.idler){ @($k17.$alan.idler) } else { @($k17.$alan.ornek | ForEach-Object { $_.id }) }
    foreach($id in $kaynak){ Ekle $kara "$id" "K17-$alan" $sebepSayac }
  }
}
# --- GM okuyucu kusurlulari
$gm = Oku 'gm-okuyucu\kusurlu-idler.json'
if($gm){ foreach($id in @($gm.idler)){ Ekle $kara "$id" 'GM-okuyucu-kusurlu' $sebepSayac } }
# --- yakin kopya (her gruptan biri tutuldu, digerleri dislandi — 13.08 Cem onayi)
$kop = Oku 'kopya-dislanan.json'
if($kop){ foreach($id in @($kop.idler)){ Ekle $kara "$id" 'KOPYA-dislanan' $sebepSayac } }
# --- ic monolog sizintisi (25.08 gece — 50'lik orneklem idx12 dersi: uretici
#     modelin coken ic konusmasi aciklama olarak yayinlanmis; motor/ic-monolog-tarama.ps1)
$icm = Oku 'ic-monolog-raporu.json'
if($icm){ foreach($id in @($icm.idler)){ Ekle $kara "$id" 'IC-MONOLOG' $sebepSayac } }

# --- K1-K10 temiz liste
$temiz = Oku 'yayin-kapisi-temiz-idler.json'
$temizIdler = @($temiz.idler | ForEach-Object { $_.id })
$kalan = @($temizIdler | Where-Object { -not $kara.ContainsKey("$_") })

$rapor = [ordered]@{
  tarih=(Get-Date).ToString('dd.MM.yyyy HH:mm')
  kasa=$temiz.kasa
  k1_k10_temiz=$temizIdler.Count
  kara_liste_toplam=$kara.Count
  kara_liste_sebepleri=$sebepSayac
  hepsinden_temiz=$kalan.Count
  not='Bu sayi K1-K10 temiz kumesinden K11/K13/K16/K17/GM bulgulari dusuldukten sonra kalandir. Kapi raporlarinin bir kismi ORNEK listeler icerir (ilk 20-25); gercek kara liste daha buyuk olabilir - kesin sayi icin ilgili kapilar tam-liste ciktisiyla yeniden kosulmalidir.'
  idler=$kalan
}
[IO.File]::WriteAllText((Join-Path $V 'yayin-havuzu-olcum.json'), (ConvertTo-Json $rapor -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host ("K1-K10 temiz          : {0}" -f $temizIdler.Count)
Write-Host ("Kara liste (K11+K13+K16+K17+GM): {0}" -f $kara.Count)
foreach($s in ($sebepSayac.GetEnumerator() | Sort-Object Value -Descending)){ Write-Host ("   {0,-28} {1}" -f $s.Key, $s.Value) }
Write-Host ("HEPSINDEN TEMIZ       : {0}" -f $kalan.Count)
