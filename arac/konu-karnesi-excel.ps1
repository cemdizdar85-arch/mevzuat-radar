#requires -Version 5.1
<#
================================================================================
  KONU KARNESİ — EXCEL   "sınavda ne kadar çıktı, biz ne kadar bastık"

  12.09.2026, Cem: "soru basımları bittikten sonra konu konu yaptığımız excele
  sınavda ne kadar çıktı biz ne kadar bastık yapalım orda birlikte karar
  verelim" (5.700 hedefi için ÖLÇÜT kararı bu tabloda verilecek).

  NE YAPAR: her konu için yan yana koyar —
    çıkmış sınavda kaç soru · kaç dönemde · son görüldüğü yıl
    ölçütün çarpanı (kat) · hedef · BİZİM BASTIĞIMIZ (canlı) · eksik
  ve ÖZET sayfasında çarpan senaryolarını hesaplar (kat×1 … kat×4), böylece
  "5.700'e hangi çarpanla varılır" sorusu tabloda görünür.

  ⛔ `mevcut` alanı PLANDAN OKUNMAZ — CANLI SAYILIR. Ölçüldü 12.09: plan
     'ortak maliyet dagitimi' için mevcut=3 diyordu, gerçek 10'du (plan A
     koşusundan önce hesaplanmış, bayat). Bayat sayıyla ölçüt kararı verilemez.

  ⛔ EXCEL COM KULLANILMAZ — arac/xlsx-yaz.ps1 (.xlsx = zip + XML). Gerekçe
     arac/yil-analizi-excel.ps1 başında: COM iki kez OutOfMemory ile düştü.

  KAYNAKLAR
    veri/sgs-analiz.json                        çıkmış sınav (dönem dönem konuSayım)
    veri/sinav/plan-siklik.json                 ölçütün çarpanı + hedefi (çekirdek konular)
    veri/sinav/kaydir-secim/sgs-650-secim.json  BİZİM BASTIĞIMIZ (canlı, yayına seçilmiş)

  KULLANIM
    powershell -NoProfile -File arac/konu-karnesi-excel.ps1
    powershell -NoProfile -File arac/konu-karnesi-excel.ps1 -Hedef "C:\yol\x.xlsx"
  BEDEL 0.
================================================================================
#>
param(
  [string]$Hedef = '',
  [int]$AcilisHedefi = 5700
)
$ErrorActionPreference='Stop'
$BU_DIZIN=Split-Path -Parent $MyInvocation.MyCommand.Path
$DEPO_KOK=Split-Path -Parent $BU_DIZIN
. (Join-Path $BU_DIZIN 'xlsx-yaz.ps1')

if(-not $Hedef){
  $Hedef=Join-Path ([Environment]::GetFolderPath('Desktop')) ("TETIKTE-KONU-KARNESI-" + (Get-Date -Format 'yyyyMMdd-HHmm') + ".xlsx")
}

# ---------------------------------------------------------------------------
# 1) ÇIKMIŞ SINAV — konu konu kaç soru, kaç dönem, son yıl
# ---------------------------------------------------------------------------
# ⛔ önce değişkene al, sonra sar (PS 5.1 @(...|ConvertFrom-Json) tuzağı)
# ⛔⭐ 12.09 DUZELTILDI — BIRLESIM YALNIZ KONU ADIYLA YAPILIR, DERSLE DEGIL.
#   Ilk surum "Ders|konu" ile birlestiriyordu ve FELAKET bir yanlis uretti:
#   "1.409 soru sinavda olmayan konuda" dedim. YANLISTI.
#   OLCULDU: cikmis analizi ders adini GENIS GRUP olarak tutuyor -
#     Muhasebe (2.013 kayit) · Hukuk (1.033) · Genel Kultur-Genel Yetenek ·
#     Matematik-Istatistik · Yabanci Dil · Ekonomi · Maliye
#   Bizim sorular ise INCE ders adi tasiyor (Finansal Muhasebe, Vergi Hukuku).
#   Yani "Vergi Hukuku|kdv matrahi" ile "Hukuk|kdv matrahi" ASLA eslesmez.
#   Yalniz KONU ADIYLA birlestirince gercek ortaya cikti:
#     2.004 sorumuzun 2.003'u cikmis sinavda adi gecen konularda (tek istisna
#     'ic kontrol ic denetim').
#   Ders adi bilgi olarak TASINIR ama ANAHTAR DEGILDIR.
$ANALIZ_HAM=Get-Content (Join-Path $DEPO_KOK 'veri\sgs-analiz.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$DONEMLER=@($ANALIZ_HAM.donemler)
$CIKMIS=@{}       # konu (ders YOK) -> @{ soru; donem; sonYil; grup }
foreach($D in $DONEMLER){
  if("$($D.donem)" -notmatch '^(\d{4})/(\d)$'){ continue }
  $YIL=[int]$Matches[1]
  foreach($P in $D.konuSayim.PSObject.Properties){
    $PARCA="$($P.Name)" -split '\|'
    $GRUP=$PARCA[0]
    $K=$(if($PARCA.Count -gt 1){ $PARCA[1] } else { '' })
    if(-not $K){ continue }
    if(-not $CIKMIS.ContainsKey($K)){ $CIKMIS[$K]=@{ soru=0; donem=0; sonYil=0; grup=$GRUP } }
    $CIKMIS[$K].soru  += [int]$P.Value
    $CIKMIS[$K].donem += 1
    if($YIL -gt $CIKMIS[$K].sonYil){ $CIKMIS[$K].sonYil=$YIL }
  }
}

# ---------------------------------------------------------------------------
# 2) ÖLÇÜT — çekirdek konuların çarpanı ve hedefi
# ---------------------------------------------------------------------------
$PLAN_HAM=Get-Content (Join-Path $DEPO_KOK 'veri\sinav\plan-siklik.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$PLAN=@($PLAN_HAM)
$OLCUT=@{}
foreach($P in $PLAN){ $OLCUT[("$($P.konu)")]=$P }   # anahtar KONU (bkz. birlesim notu)

# ---------------------------------------------------------------------------
# 3) BİZİM BASTIĞIMIZ — canlı sayım (yayına seçilmiş sorular)
# ---------------------------------------------------------------------------
$SECIM_YOL=Join-Path $DEPO_KOK 'veri\sinav\kaydir-secim\sgs-650-secim.json'
if(-not (Test-Path $SECIM_YOL)){ throw "yayin secim dosyasi yok: $SECIM_YOL" }
$SECIM_HAM=Get-Content $SECIM_YOL -Raw -Encoding UTF8 | ConvertFrom-Json
$SECIM=@($SECIM_HAM)
$BASTIGIMIZ=@{}
$BIZIM_DERS=@{}
foreach($S in $SECIM){ $A="$($S.konu)"; $BASTIGIMIZ[$A]=[int]$BASTIGIMIZ[$A]+1; if(-not $BIZIM_DERS.ContainsKey($A)){ $BIZIM_DERS[$A]="$($S.ders)" } }

# ---------------------------------------------------------------------------
# 4) BİRLEŞİK KONU LİSTESİ — çıkmışta olan + bizim bastığımız
# ---------------------------------------------------------------------------
# ⛔ 12.09 DUZELTILDI: OLCUT (cekirdek) konulari da birlesime GIRER.
#   Ilk surumde birlesim yalniz "cikmista olan" + "bastigimiz" idi. Sonuc:
#   ne cikmis analizinde ADI gecen ne de basilmis bir cekirdek konu tabloya
#   HIC girmiyordu. Olculdu: "hic basilmamis cekirdek" 7 satir cikti, oysa
#   281 plan konusunun 104'u yayinda yok. Yani is emri sayfasi 97 konuyu
#   SESSIZCE kaciriyordu - tam da Cem'in karar vermek icin bakacagi sayfa.
$TUM_ANAHTAR=@{}
foreach($A in $CIKMIS.Keys){ $TUM_ANAHTAR[$A]=$true }
foreach($A in $BASTIGIMIZ.Keys){ $TUM_ANAHTAR[$A]=$true }
foreach($A in $OLCUT.Keys){ $TUM_ANAHTAR[$A]=$true }

$SATIR=New-Object System.Collections.Generic.List[object]
foreach($A in $TUM_ANAHTAR.Keys){
  $KONU=$A
  $DERS=$(if($BIZIM_DERS.ContainsKey($A)){ $BIZIM_DERS[$A] } elseif($CIKMIS.ContainsKey($A)){ $CIKMIS[$A].grup } else { '?' })
  $C=$(if($CIKMIS.ContainsKey($A)){ $CIKMIS[$A] } else { $null })
  $O=$(if($OLCUT.ContainsKey($A)){ $OLCUT[$A] } else { $null })
  $B=[int]$BASTIGIMIZ[$A]
  $CS=$(if($C){ [int]$C.soru } else { 0 })
  $CD=$(if($C){ [int]$C.donem } else { 0 })
  $CY=$(if($C){ [int]$C.sonYil } else { 0 })
  $KAT=$(if($O){ [int]$O.kat } else { 0 })
  $HED=$(if($O){ [int]$O.hedef } else { 0 })
  $DURUM = if(-not $C){ 'SINAVDA YOK - biz basmisiz' }
           elseif(-not $O){ 'olcut disi (cekirdek degil)' }
           elseif($B -ge $HED){ 'TAMAM' }
           elseif($B -eq 0){ 'HIC BASILMAMIS' }
           else{ 'eksik' }
  $SATIR.Add([pscustomobject]@{
    ders=$DERS; konu=$KONU; cikmisSoru=$CS; donem=$CD; sonYil=$CY
    cekirdek=$(if($O){ 'EVET' }else{ '-' }); kat=$KAT; hedef=$HED
    bastigimiz=$B; eksik=[Math]::Max(0,$HED-$B); durum=$DURUM
  })
}
$SIRALI=@($SATIR.ToArray() | Sort-Object @{e={$_.cikmisSoru};Descending=$true},@{e={$_.bastigimiz};Descending=$true},ders,konu)

# ---------------------------------------------------------------------------
# 5) ÖZET + ÇARPAN SENARYOLARI
# ---------------------------------------------------------------------------
$CEK=@($SIRALI | Where-Object{ $_.cekirdek -eq 'EVET' })
$TOP_BASILI=0; foreach($X in $SIRALI){ $TOP_BASILI+=[int]$X.bastigimiz }
$TOP_HEDEF=0;  foreach($X in $CEK){ $TOP_HEDEF+=[int]$X.hedef }
$TOP_CIKMIS=0; foreach($X in $SIRALI){ $TOP_CIKMIS+=[int]$X.cikmisSoru }

$ozet=New-Object System.Collections.Generic.List[object]
$ozet.Add(@('TETİKTE · KONU KARNESİ — "sınavda ne kadar çıktı, biz ne kadar bastık"'))
$ozet.Add(@(("Ölçüm " + (Get-Date -Format 'dd.MM.yyyy HH:mm') + " · çıkmış sınav: " + $DONEMLER.Count + " dönem · bastığımız: CANLI sayım (yayına seçilmiş " + $SECIM.Count + " soru)")))
$ozet.Add(@('Bu tablo 5.700 hedefi için ÖLÇÜT kararını vermek üzere hazırlandı (Cem 12.09).'))
$ozet.Add(@(''))
$ozet.Add(@('GENEL'))
$ozet.Add(@('Konu (çıkmışta olan + bastığımız)',$SIRALI.Count))
$ozet.Add(@('Çekirdek konu (ölçüt kapsamı)',$CEK.Count))
$ozet.Add(@('Çıkmış sınavda toplam soru',$TOP_CIKMIS))
$ozet.Add(@('Ölçütün hedefi (bugünkü çarpanla)',$TOP_HEDEF))
$ozet.Add(@('BİZİM BASTIĞIMIZ (yayında)',$TOP_BASILI))
$ozet.Add(@('Açılış hedefi (Cem)',$AcilisHedefi))
$ozet.Add(@('Hedefe kalan',[Math]::Max(0,$AcilisHedefi-$TOP_BASILI)))
$ozet.Add(@(''))
$ozet.Add(@('ÇARPAN SENARYOLARI — "kat" kaça çıkarsa toplam hedef ne olur'))
$ozet.Add(@('Senaryo','Çekirdek hedefi','+ plan dışı basılı','TOPLAM BANKA','Açılış hedefine'))
foreach($CARP in @(1.0,1.5,2.0,2.5,3.0,4.0)){
  $H=0; foreach($X in $CEK){ $H+=[int][Math]::Round([int]$X.hedef*$CARP) }
  $PLANDISI=0; foreach($X in $SIRALI){ if($X.cekirdek -ne 'EVET'){ $PLANDISI+=[int]$X.bastigimiz } }
  $TOPLAM=$H+$PLANDISI
  $FARK=$TOPLAM-$AcilisHedefi
  $ozet.Add(@(("kat × " + $CARP.ToString('0.0')),$H,$PLANDISI,$TOPLAM,$(if($FARK -ge 0){ "+$FARK (YETER)" }else{ "$FARK (yetmez)" })))
}
$ozet.Add(@(''))
$ozet.Add(@('DERS DERS'))
$ozet.Add(@('Ders','Konu','Çıkmışta soru','Hedef','Bastığımız','Eksik'))
foreach($G in (@($SIRALI | Group-Object ders) | Sort-Object{ -(($_.Group|Measure-Object cikmisSoru -Sum).Sum) })){
  $ozet.Add(@($G.Name,$G.Count,
    [int](($G.Group|Measure-Object cikmisSoru -Sum).Sum),
    [int](($G.Group|Measure-Object hedef -Sum).Sum),
    [int](($G.Group|Measure-Object bastigimiz -Sum).Sum),
    [int](($G.Group|Measure-Object eksik -Sum).Sum)))
}
$ozet.Add(@(''))
$ozet.Add(@('DURUM DAĞILIMI'))
$ozet.Add(@('Durum','Konu','Bastığımız soru'))
foreach($G in (@($SIRALI | Group-Object durum) | Sort-Object Count -Descending)){
  $ozet.Add(@($G.Name,$G.Count,[int](($G.Group|Measure-Object bastigimiz -Sum).Sum)))
}
$ozet.Add(@(''))
$ozet.Add(@('NOT'))
$ozet.Add(@('"Çarpan" (kat) bugünkü ölçüt: konu çıkmış sınavda kaç DÖNEMDE görüldüyse ona göre 3/4/5. Hedef = kat × (o konunun ağırlığı).'))
$ozet.Add(@('"Bastığımız" PLANDAN değil CANLI sayılır: plan bayatlayabiliyor (12.09 ölçümü: plan 3 diyordu, gerçek 10).'))
$ozet.Add(@('"SINAVDA YOK - biz basmisiz" satırları: çıkmış sınav analizinde o konu adı yok. Ad farkı da olabilir, gerçek fazlalık da.'))
$ozet.Add(@('Üretici: arac/konu-karnesi-excel.ps1 · Excel kurulu olmadan yazar · bedel 0, istendiğinde yeniden koşar.'))

# --- KONU KARNESİ sayfası ---------------------------------------------------
$karne=New-Object System.Collections.Generic.List[object]
$karne.Add(@('Ders','Konu','Çıkmışta soru','Kaç dönemde','Son çıkış yılı','Çekirdek','Çarpan','Hedef','BASTIĞIMIZ','Eksik','Durum'))
foreach($X in $SIRALI){
  $karne.Add(@($X.ders,$X.konu,[int]$X.cikmisSoru,[int]$X.donem,
    $(if($X.sonYil -gt 0){ [int]$X.sonYil }else{ $null }),
    $X.cekirdek,$(if($X.kat -gt 0){ [int]$X.kat }else{ $null }),
    $(if($X.hedef -gt 0){ [int]$X.hedef }else{ $null }),
    [int]$X.bastigimiz,$(if($X.eksik -gt 0){ [int]$X.eksik }else{ $null }),$X.durum))
}

# --- HİÇ BASILMAMIŞ ÇEKİRDEK (iş emri) -------------------------------------
$bos=New-Object System.Collections.Generic.List[object]
$bos.Add(@('Ders','Konu','Çıkmışta soru','Kaç dönemde','Çarpan','Hedef'))
foreach($X in ($CEK | Where-Object{ [int]$_.bastigimiz -eq 0 } | Sort-Object{ -[int]$_.cikmisSoru })){
  $bos.Add(@($X.ders,$X.konu,[int]$X.cikmisSoru,[int]$X.donem,[int]$X.kat,[int]$X.hedef))
}

$dosya=XlsxYaz -Hedef $Hedef -Sayfalar @(
  @{ ad='OZET';          satirlar=$ozet.ToArray() }
  @{ ad='KONU KARNESI';  satirlar=$karne.ToArray() }
  @{ ad='HIC BASILMAMIS';satirlar=$bos.ToArray() }
) -DonukSatir 1

Write-Host ""
Write-Host ("YAZILDI: {0}" -f $dosya.FullName) -ForegroundColor Green
Write-Host ("  {0:N0} KB · KONU KARNESI {1:N0} satir · HIC BASILMAMIS {2:N0} satir" -f ($dosya.Length/1KB),$SIRALI.Count,($bos.Count-1)) -ForegroundColor Green
Write-Host ("  bastigimiz {0:N0} soru · cekirdek hedefi {1:N0} · acilis hedefi {2:N0}" -f $TOP_BASILI,$TOP_HEDEF,$AcilisHedefi) -ForegroundColor Cyan
